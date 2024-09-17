# daloradius
Overview
This repository contains a Bash script that automates the installation and configuration of daloRADIUS and FreeRADIUS on a Linux system. The script configures MySQL as the backend for FreeRADIUS and sets up Apache as the web server for daloRADIUS.

This script has built-in error handling, ensuring minimal issues during installation, and checks for essential services and files throughout the process.

Prerequisites
Before running the script, ensure the following requirements are met:

Operating System: Ubuntu 20.04 (or later) or any Debian-based distribution.
Root Privileges: You must run the script as root or with sudo.
Internet Access: The system must have internet access to download the necessary packages.
Installation Steps
Download the Script

Save the script as install_daloradius.sh on your server.

You can use a text editor like nano:

bash
Copy code
nano install_daloradius.sh
Then, paste the content of the script provided into the file.

Make the Script Executable

To give the script executable permissions, run:

bash
Copy code
chmod +x install_daloradius.sh
Run the Script

Execute the script using sudo:

bash
Copy code
sudo ./install_daloradius.sh
Follow the Prompts

The script will ask for the MySQL root password during the installation process to create the necessary database and user for FreeRADIUS and daloRADIUS.
If any errors occur, the script will display detailed error messages and stop execution. Review the error message and correct any issues before rerunning the script.
Default Credentials
After installation, access the daloRADIUS web interface via the following URL:

arduino
Copy code
http://<YOUR_SERVER_IP>/daloradius
The default credentials are:

Username: administrator
Password: radius
You should change these credentials after the first login for security purposes.

Customization
If you want to customize the MySQL database name, user, or password, modify the following variables at the top of the script before running it:

bash
Copy code
DB_NAME="radius"
DB_USER="radius"
DB_PASS="password"
Error Handling and Troubleshooting
This script is designed to handle most errors during the installation process. Some of the key points of error handling include:

Root Privileges: The script checks if it’s being run as root and exits if not.
MySQL Authentication: If the provided MySQL root password is incorrect, the script will stop and prompt you to enter the correct password.
File and Directory Checks: The script checks if files and directories (such as daloRADIUS or Apache configuration) already exist, preventing overwriting or duplication.
Service Restarts: After each significant configuration change, the script restarts the relevant services (FreeRADIUS, Apache) and checks if the restart was successful.
If the script fails at any point, you will see an error message indicating where the issue occurred. You can resolve the issue and rerun the script.

Additional Notes
Ensure that port 80 is open if you plan to access the daloRADIUS web interface remotely.
For security purposes, consider updating the default MySQL password after installation.
To increase security further, enable SSL/TLS on your Apache web server to encrypt web traffic to daloRADIUS.

Support
If you encounter any issues during installation, feel free to open an issue or contact the repository owner for support.

This README now includes comprehensive information about the script, steps to execute, and how to handle errors, making it easier to manage potential issues and customize the installation.
