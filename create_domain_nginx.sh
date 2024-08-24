#!/bin/bash

# Base path for Nginx and web root
NGINX_PATH="/etc/nginx/sites-available"
ENABLED_PATH="/etc/nginx/sites-enabled"
WEB_ROOT_PATH="/var/www"

# 1. Select the project
echo "Select the project:"
dirs=($(ls -d "$NGINX_PATH"/*/ 2>/dev/null | xargs -n 1 basename))
select PROJECT in "${dirs[@]}"; do
    if [ -n "$PROJECT" ]; then
        echo "Selected project: $PROJECT"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# 2. Select the base configuration file
echo "Select the base configuration file:"
files=($(ls "$NGINX_PATH/$PROJECT"/domain_*.conf 2>/dev/null | xargs -n 1 basename))
if [ ${#files[@]} -eq 0 ]; then
    echo "No base configuration file found in $NGINX_PATH/$PROJECT."
    exit 1
fi
select BASE_CONFIG in "${files[@]}"; do
    if [ -n "$BASE_CONFIG" ]; then
        echo "Selected base configuration file: $BASE_CONFIG"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# 3. Select the ROOT_PATH
echo "Select the ROOT_PATH for the domain:"
dirs=($(ls -d "$WEB_ROOT_PATH"/*/ 2>/dev/null | xargs -n 1 basename))
select ROOT_PATH in "${dirs[@]}"; do
    if [ -n "$ROOT_PATH" ]; then
        echo "Selected ROOT_PATH: $ROOT_PATH"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# 4. Create Nginx configuration
read -p "Enter the domain name(s) (e.g., www.mysite.com mysite.com): " DOMAIN_NAMES
BASE_DOMAIN=$(echo "$DOMAIN_NAMES" | awk '{print $1}' | sed 's/www.//')

CONFIG_PATH="$NGINX_PATH/$PROJECT/$BASE_DOMAIN.conf"
ENABLED_LINK="$ENABLED_PATH/$BASE_DOMAIN.conf"

# Check if the configuration file already exists and delete it if necessary
if [ -f "$CONFIG_PATH" ]; then
    echo "Configuration file for $BASE_DOMAIN already exists. Deleting..."
    sudo rm -f "$CONFIG_PATH"
    if [ -f "$ENABLED_LINK" ]; then
        echo "Deleting symbolic link in $ENABLED_PATH"
        sudo rm -f "$ENABLED_LINK"
    fi
fi

echo "Copying base configuration file from $NGINX_PATH/$PROJECT/$BASE_CONFIG to $CONFIG_PATH"
cp "$NGINX_PATH/$PROJECT/$BASE_CONFIG" "$CONFIG_PATH"
if [ $? -ne 0 ]; then
    echo "Error copying the base configuration file."
    exit 1
fi

echo "Replacing ROOT_PATH and DOMAIN_NAME in $CONFIG_PATH"
sed -i "s|ROOT_PATH|$ROOT_PATH|g" "$CONFIG_PATH"
sed -i "s|DOMAIN_NAME|$DOMAIN_NAMES|g" "$CONFIG_PATH"

echo "Configuration file created at $CONFIG_PATH"

# Create symbolic link in sites-enabled
echo "Creating symbolic link in $ENABLED_PATH"
ln -s "$CONFIG_PATH" "$ENABLED_LINK"
if [ $? -ne 0 ]; then
    echo "Error creating the symbolic link in $ENABLED_PATH."
    exit 1
fi

echo "Symbolic link created at $ENABLED_LINK"

# 5. Configure SSL
nginx -t
if [ $? -ne 0 ]; then
    echo "Error in Nginx configuration. Please check the configuration file."
    exit 1
fi

sudo systemctl reload nginx

# Check if the domain is resolving to the server before attempting to generate the certificate
if ping -c 1 -W 2 "$BASE_DOMAIN" &> /dev/null; then
    sudo certbot --nginx $(echo $DOMAIN_NAMES | awk '{for (i=1; i<=NF; i++) printf " -d %s", $i}')
else
    echo "Domain $BASE_DOMAIN is not pointing to this server. SSL certificate was not generated."
fi

echo "Process completed."
