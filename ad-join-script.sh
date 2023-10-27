#!/bin/bash

# Prompt the user for the necessary information
read -p "Administrator username (AdminUser): " admin_user
read -s -p "Administrator password: " admin_password
echo  # To move to the next line
read -p "Active Directory domain name: " domain_name

# Prompt for DNS server IP and verify DNS resolution
while true; do
    read -p "DNS server IP: " dns_server
    if nslookup $domain_name $dns_server; then
        break
    else
        echo "DNS resolution failed. Please enter a valid DNS server IP."
    fi
done

# Change the DNS server settings in /etc/resolv.conf
echo "nameserver $dns_server" | sudo tee /etc/resolv.conf

# Install the necessary packages
apt -y install realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit

# Discover the domain
realm discover $domain_name

# Join the domain using the provided information
echo $admin_password | realm join -U $admin_user $domain_name

# Modify the sssd.conf configuration
sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf

# Restart the SSSD service
systemctl restart sssd

# Add the user to the sudoers file
echo "$admin_user ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers

# Verify successful domain join by looking up the user
if id $admin_user; then
    echo "The server has been successfully joined to the Active Directory domain."
else
    echo "Domain join failed. Please check the provided information."
fi
