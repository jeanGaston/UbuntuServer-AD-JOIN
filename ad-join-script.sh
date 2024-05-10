#!/bin/bash
# Prompt the user for the hostname
read -p "Enter the hostname for the server: " hostname
echo

# Prompt the user for the necessary information
read -p "Administrator username (AdminUser): " admin_user
read -s -p "Administrator password: " admin_password
echo  # To move to the next line
read -p "Active Directory domain name: " domain_name
read -p "Active Directory group for sudo access: " ad_group

# Prompt for DNS server IP and verify DNS resolution
while true; do
    read -p "DNS server IP: " dns_server
    if nslookup $domain_name $dns_server; then
        break
    else
        echo "DNS resolution failed. Please enter a valid DNS server IP."
    fi
done
# Install the necessary packages with a loading bar
echo "Installing required packages..."
apt -y install realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit
# Display hostname change information
echo "Changing the hostname to: $hostname.$domain_name"

# Change the hostname
hostnamectl set-hostname $hostname
echo "$hostname.$domain_name" | sudo tee /etc/hostname

# Change the DNS server settings in /etc/resolv.conf
echo "Changing DNS server to: $dns_server"
echo "nameserver $dns_server" | sudo tee /etc/resolv.conf

# Install the necessary packages with a loading bar
echo "Installing required packages..."
apt -y install realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit & loading_bar

# Discover the domain and join, registering DNS
echo "Joining the domain and registering DNS..."
echo $admin_password | realm join --user=$admin_user $domain_name

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
