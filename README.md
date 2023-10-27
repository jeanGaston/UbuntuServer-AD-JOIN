# Active Directory Join Script for Ubuntu Server

This script automates the process of joining an Ubuntu Server to an Active Directory (AD) domain using the `sssd` package. It prompts the user to provide the necessary information, installs required packages, discovers the AD domain, joins the domain, configures SSSD, restarts the service, adds the user to the sudoers file, and checks the success of the domain join.

## Prerequisites

- You need administrative privileges to run this script, so use `sudo` to execute it.

## Usage

1. Clone or download this repository to your Ubuntu Server.

2. Open a terminal and navigate to the directory containing the script.

3. Make the script executable:
```chmod +x ad-join-script.sh```

4. Run the script:
```./ad-join-script.sh```


5. Follow the prompts to provide the necessary information:
- Administrator username (AdminUser)
- Administrator password
- Active Directory domain name

6. The script will install the required packages, discover the domain, join the domain, configure SSSD, restart the service, add the user to the sudoers file, and verify the domain join.

7. If the script completes successfully, your server will be joined to the Active Directory domain.

## Disclaimer

This script is provided as-is and without any warranty. Use it at your own risk. Be sure to have valid credentials and administrative access to your Active Directory domain before running the script.

## License

This script is open-source and available under the MIT License. See the [LICENSE](LICENSE) file for details.
