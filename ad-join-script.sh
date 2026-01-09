#!/bin/bash
set -euo pipefail

hostname="${ADJOIN_HOSTNAME:-}"
admin_user="${ADJOIN_ADMIN_USER:-}"
admin_password="${ADJOIN_ADMIN_PASSWORD:-}"
domain_name="${ADJOIN_DOMAIN_NAME:-}"
ad_group="${ADJOIN_AD_GROUP:-}"
dns_servers_raw="${ADJOIN_DNS_SERVERS:-${ADJOIN_DNS_SERVER:-}}"
dns_interface="${ADJOIN_DNS_INTERFACE:-}"

configure_dns() {
    local domain="$1"
    shift
    local -a servers=("$@")

    if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet systemd-resolved; then
        echo "Configuring DNS via systemd-resolved..."
        sudo mkdir -p /etc/systemd/resolved.conf.d
        {
            echo "[Resolve]"
            echo "DNS=${servers[*]}"
            echo "Domains=$domain"
        } | sudo tee /etc/systemd/resolved.conf.d/ad-join.conf >/dev/null
        sudo systemctl restart systemd-resolved
        return 0
    fi

    if command -v resolvectl >/dev/null 2>&1; then
        local iface="$dns_interface"
        if [ -z "$iface" ] && command -v ip >/dev/null 2>&1; then
            iface="$(ip route show default 2>/dev/null | awk '{print $5; exit}')"
        fi
        if [ -n "$iface" ]; then
            echo "Configuring DNS via resolvectl on interface: $iface"
            sudo resolvectl dns "$iface" "${servers[@]}"
            sudo resolvectl domain "$iface" "$domain"
            return 0
        fi
    fi

    echo "Configuring DNS via /etc/resolv.conf..."
    {
        for server in "${servers[@]}"; do
            echo "nameserver $server"
        done
    } | sudo tee /etc/resolv.conf >/dev/null
}

if [ -z "$hostname" ]; then
    read -p "Enter the hostname for the server: " hostname
    echo
fi

# Prompt the user for the necessary information
if [ -z "$admin_user" ]; then
    read -p "Administrator username (AdminUser): " admin_user
fi
if [ -z "$admin_password" ]; then
    read -s -p "Administrator password: " admin_password
    echo  # To move to the next line
fi
if [ -z "$domain_name" ]; then
    read -p "Active Directory domain name: " domain_name
fi
if [ -z "$ad_group" ]; then
    read -p "Active Directory group for sudo access: " ad_group
fi

# Prompt for DNS server IP(s) and verify DNS resolution
if [ -z "$dns_servers_raw" ]; then
    while true; do
        read -p "DNS server IP(s) (comma or space separated): " dns_servers_raw
        dns_servers_raw="${dns_servers_raw//,/ }"
        read -r -a dns_servers <<<"$dns_servers_raw"

        dns_ok=false
        for server in "${dns_servers[@]}"; do
            if nslookup "$domain_name" "$server" >/dev/null 2>&1; then
                dns_ok=true
                break
            fi
        done

        if [ "$dns_ok" = true ]; then
            break
        fi
        echo "DNS resolution failed using provided server(s). Please try again."
    done
else
    dns_servers_raw="${dns_servers_raw//,/ }"
    read -r -a dns_servers <<<"$dns_servers_raw"

    dns_ok=false
    for server in "${dns_servers[@]}"; do
        if nslookup "$domain_name" "$server" >/dev/null 2>&1; then
            dns_ok=true
            break
        fi
    done

    if [ "$dns_ok" != true ]; then
        echo "DNS resolution failed using provided server(s): ${dns_servers[*]}" >&2
        exit 1
    fi
fi

# Install the necessary packages with a loading bar
echo "Installing required packages..."
apt -y install realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit
# Display hostname change information
echo "Changing the hostname to: $hostname.$domain_name"

# Change the hostname
hostnamectl set-hostname "$hostname.$domain_name"
echo "$hostname.$domain_name" | sudo tee /etc/hostname

# Change DNS settings
echo "Setting DNS server(s) to: ${dns_servers[*]}"
configure_dns "$domain_name" "${dns_servers[@]}"

# Discover the domain and join, registering DNS
echo "Joining the domain and registering DNS..."
printf '%s\n' "$admin_password" | realm join --user="$admin_user" "$domain_name"

# Modify the sssd.conf configuration to enable dynamic DNS updates
echo "Configuring dynamic DNS updates..."
cat <<EOF | sudo tee -a /etc/sssd/sssd.conf
[domain/$domain_name]
id_provider = ad
auth_provider = ad
chpass_provider = ad
access_provider = ad
ldap_schema = ad
dyndns_update = true
dyndns_refresh_interval = 43200
dyndns_update_ptr = true
dyndns_ttl = 3600
EOF

# Modify the sssd.conf configuration
echo "Modifying sssd.conf..."
sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf

# Restart the SSSD service
echo "Restarting the SSSD service..."
systemctl restart sssd

# Add the user and AD group to the sudoers file
echo "Adding the user and AD group to the sudoers file..."
echo "$admin_user ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers
echo "%$ad_group ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers

# Verify successful domain join by looking up the user
echo "Verifying domain join..."
if id $admin_user; then
    echo "The server has been successfully joined to the Active Directory domain."
else
    echo "Domain join failed. Please check the provided information."
fi
