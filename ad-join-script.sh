#!/bin/bash

# Enable verbose output
set -x

# Prompt the user for the hostname
read -p "Enter the hostname for the server: " hostname
echo

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

# Display hostname change information
echo "Changing the hostname to: $hostname.$domain_name"

# Change the hostname
hostnamectl set-hostname $hostname
echo "$hostname.$domain_name" | sudo tee -a /etc/hostname

# Change the DNS server settings in /etc/resolv.conf
echo "Changing DNS server to: $dns_server"
echo "nameserver $dns_server" | sudo tee /etc/resolv.conf

# Install the necessary packages
echo "Installing required packages..."
apt -y install realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit

# Discover the domain
echo "Discovering the domain..."
realm discover $domain_name

# Join the domain using the provided information
echo "Joining the domain..."
echo $admin_password | realm join -U $admin_user $domain_name --computer-ou=OU=Computers,DC=example,DC=com

# Modify the sssd.conf configuration
echo "Modifying sssd.conf..."
sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf

# Restart the SSSD service
echo "Restarting the SSSD service..."
systemctl restart sssd

# Add the user to the sudoers file
echo "Adding the user to the sudoers file..."
echo "$admin_user ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers

# Verify successful domain join by looking up the user
echo "Verifying domain join..."
if id $admin_user; then
    echo "The server has been successfully joined to the Active Directory domain."
else
    echo "Domain join failed. Please check the provided information."
fi
