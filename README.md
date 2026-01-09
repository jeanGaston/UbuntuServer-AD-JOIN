# Active Directory Join Script for Ubuntu Server

This script automates the process of joining an Ubuntu Server to an Active Directory (AD) domain using the `sssd` package. It prompts the user to provide the necessary information, installs required packages, discovers the AD domain, joins the domain, configures SSSD, restarts the service, adds the user to the sudoers file, and checks the success of the domain join.

## Prerequisites

- You need administrative privileges to run this script, so use `sudo` to execute it.

## Usage

1. Clone or download this repository to your Ubuntu Server:  
```git clone https://github.com/jeanGaston/UbuntuServer-AD-JOIN```

3. Open a terminal and navigate to the directory containing the script.

4. Make the script executable:
```chmod +x ad-join-script.sh```

5. Run the script:
```./ad-join-script.sh```


6. Follow the prompts to provide the necessary information:
- Hostname without domain
- AD Administrator username (AdminUser)
- AD Administrator password
- Active Directory domain name
- AD Group to add to the sudoers file
- Verify the DNS resolution by providing the DNS server IP address. If DNS resolution fails, you will be prompted to enter the DNS server IP.

6. The script will install the required packages, discover the domain, join the domain, configure SSSD, restart the service, add the user and group to the sudoers file, and verify the domain join.

7. If the script completes successfully, your server will be joined to the Active Directory domain.
8. You might need to reboot for the authentication with AD credentials to work

### Non-interactive usage

You can also run the script without prompts by setting environment variables:

- `ADJOIN_HOSTNAME`
- `ADJOIN_ADMIN_USER`
- `ADJOIN_ADMIN_PASSWORD`
- `ADJOIN_DOMAIN_NAME`
- `ADJOIN_AD_GROUP`
- `ADJOIN_DNS_SERVERS` (preferred; comma/space separated)
- `ADJOIN_DNS_SERVER` (backward compatible single server)
- `ADJOIN_DNS_INTERFACE` (optional; interface name for `resolvectl`, e.g. `eth0`)

### DNS management note

This script needs to be able to set DNS for domain discovery/join. It tries `systemd-resolved` first, then falls back to writing `/etc/resolv.conf`.

If your DNS is managed by another component (e.g. NetworkManager, netplan, resolvconf, or cloud-init), you may need to adapt DNS configuration for your environment or the join can fail.

## Ansible 

An Ansible role and example playbook are included under `ansible/` to deploy and run the script non-interactively (all inputs are passed as variables, suitable for Semaphore).

See `ansible/README.md` for required variables and usage.

## Disclaimer

This script is provided as-is and without any warranty. Use it at your own risk. Be sure to have valid credentials and administrative access to your Active Directory domain before running the script.

## License

This script is open-source and available under the MIT License. See the [LICENSE](LICENSE) file for details.
