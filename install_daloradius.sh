#!/bin/bash

# Exit on any error
set -e

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update packages and install prerequisites
sudo apt update -y
sudo apt install freeradius freeradius-mysql mysql-server apache2 php php-common php-gd php-curl php-mysql git unzip -y

# Ensure MySQL and Apache are running
sudo systemctl enable mysql
sudo systemctl start mysql
sudo systemctl enable apache2
sudo systemctl start apache2

# Create MySQL database and user for FreeRADIUS and daloRADIUS
DB_NAME="radius"
DB_USER="radius"
DB_PASS="password"

# Check if MySQL root password is correct
echo "Enter MySQL root password for creating the database:"
sudo mysql -u root -p -e "exit"
if [ $? -ne 0 ]; then
  echo "MySQL root authentication failed."
  exit 1
fi

# Create the database and user
sudo mysql -u root -p<<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
FLUSH PRIVILEGES;
exit;
MYSQL_SCRIPT

# Import FreeRADIUS schema into MySQL
sudo mysql -u root -p ${DB_NAME} < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql
if [ $? -ne 0 ]; then
  echo "Failed to import FreeRADIUS schema into MySQL."
  exit 1
fi

# Configure FreeRADIUS to use MySQL
SQL_CONFIG_FILE="/etc/freeradius/3.0/mods-available/sql"
if [ -f "$SQL_CONFIG_FILE" ]; then
  sudo sed -i 's/driver = "rlm_sql_null"/driver = "rlm_sql_mysql"/g' $SQL_CONFIG_FILE
  sudo sed -i 's/dialect = "sqlite"/dialect = "mysql"/g' $SQL_CONFIG_FILE
  sudo sed -i 's/#.*login = "radius"/login = "radius"/g' $SQL_CONFIG_FILE
  sudo sed -i 's/#.*password = "radpass"/password = "password"/g' $SQL_CONFIG_FILE
  sudo sed -i 's/#.*radius_db = "radius"/radius_db = "radius"/g' $SQL_CONFIG_FILE
else
  echo "$SQL_CONFIG_FILE not found. FreeRADIUS SQL configuration might fail."
  exit 1
fi

# Enable SQL module in FreeRADIUS
if [ ! -L /etc/freeradius/3.0/mods-enabled/sql ]; then
  sudo ln -s /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/
fi

# Restart FreeRADIUS service
sudo systemctl restart freeradius
if [ $? -ne 0 ]; then
  echo "Failed to restart FreeRADIUS."
  exit 1
fi

# Download and install daloRADIUS
cd /var/www/html
if [ ! -d "daloradius" ]; then
  sudo git clone https://github.com/lirantal/daloradius.git
else
  echo "daloRADIUS already exists. Skipping git clone."
fi
sudo chown -R www-data:www-data daloradius

# Import daloRADIUS schema into the MySQL database
sudo mysql -u root -p ${DB_NAME} < /var/www/html/daloradius/contrib/db/mysql-daloradius.sql
if [ $? -ne 0 ]; then
  echo "Failed to import daloRADIUS schema into MySQL."
  exit 1
fi

# Configure Apache for daloRADIUS
APACHE_CONFIG_FILE="/etc/apache2/sites-available/daloradius.conf"
if [ ! -f "$APACHE_CONFIG_FILE" ]; then
  sudo bash -c 'cat > /etc/apache2/sites-available/daloradius.conf <<EOF
<VirtualHost *:80>
    DocumentRoot /var/www/html/daloradius
    <Directory /var/www/html/daloradius/>
        Options FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF'
  sudo a2ensite daloradius.conf
fi

# Restart Apache to apply changes
sudo systemctl restart apache2
if [ $? -ne 0 ]; then
  echo "Failed to restart Apache."
  exit 1
fi

# Set the appropriate permissions for the web files
sudo chown -R www-data:www-data /var/www/html/daloradius

# Final message
echo "Installation of daloRADIUS and FreeRADIUS is complete."
echo "You can now access the daloRADIUS web interface using the following URL:"
echo "http://<YOUR_SERVER_IP>/daloradius"
echo "Default username: administrator"
echo "Default password: radius"