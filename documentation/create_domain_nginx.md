# Domain Creation Script for Nginx

This script automates the process of creating Nginx server blocks, organizing them by project directories, and generating SSL certificates for domains. It simplifies the management of domains by using a structured approach.

# Table of Contents
- [Introduction](#introduction)
- [Organization the Configuration Files](#organization-the-configuration-files)
- [Configuration File Templates](#configuration-file-templates)
  - [Example Configuration Files](#example-configuration-files)
- [Base Projects to ROOT_PATH](#base-projects-to-root_path)
- [Inputs domains to use in the domain.conf](#inputs-domains-to-use-in-the-domain.conf)
- [Running the Script](#running-the-script)

# Introduction
This script automates the process of creating Nginx server blocks, organizing them by project directories, and generating SSL certificates for domains. It simplifies the management of domains by using a structured approach.

## Key Points:

- Project-Based Organization: Nginx configuration files are organized into directories based on projects. For example, if you have a project named "my-company," all relevant configurations for this project will reside in a directory named /etc/nginx/sites-available/my-company.

- Configuration File Templates: Within each project directory, you should have one or more base configuration templates named following the pattern domain_*.conf. For instance, you might have domain_nodejs.conf for a Node.js application or domain_php7_2.conf for a PHP 7.2 application. These templates serve as the starting point for creating new server block configurations.

- Automated SSL Certificate Generation: The script also checks if the domain is correctly pointing to the server before attempting to generate an SSL certificate using Certbot. This prevents unnecessary certificate requests and ensures SSL is set up only for domains that are ready.

# Usage

## Organization the Configuration Files

Before running the script, make sure to create a subdirectory inside the ``sites-available`` directory for each of your projects. This subdirectory will store all domain configurations related to that specific project. For example, if your project is named "my-company," you should create a folder ``/etc/nginx/sites-available/my-company``. This organization helps manage multiple projects more efficiently by keeping all related domain configurations together in their respective folders.

```bash
sudo mkdir /etc/nginx/sites-available/my-company
```

## Configuration File Templates
Inside each project directory, you should have one or more base configuration templates named following the pattern ``domain_*.conf``. For instance, you might have ``domain_nodejs.conf`` for a Node.js application or ``domain_php7_2.conf`` for a PHP 7.2 application. These templates serve as the starting point for creating new server block configurations.

### Example Configuration Files

Below is an example of a base configuration file template you might place in ``/etc/nginx/sites-available/my-company/`` named ``domain_nodejs.conf``:

```nginx
server {
    listen 80;
    server_name DOMAIN_NAME;

    root /var/www/ROOT_PATH;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
        proxy_pass http://localhost:3000; # Adjust as necessary for your setup
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    error_page 404 /404.html;
    location = /404.html {
        internal;
    }
}
```

Example of a base configuration file template you might place in ``/etc/nginx/sites-available/my-company/`` named ``domain_php7_2.conf``:

```nginx
server {
    listen 80;
    server_name DOMAIN_NAME;

    root /var/www/ROOT_PATH;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.2-fpm.sock; # Adjust as necessary
    }

    error_page 404 /404.html;
    location = /404.html {
        internal;
    }
}
```
In these templates:

DOMAIN_NAME is a placeholder that will be replaced with the actual domain name(s) you provide when running the script. In the next section, you will see how to specify these domain names.
ROOT_PATH is a placeholder for the web root directory of your application. In the next section, you will see how to specify this path when running the script.

## Base Projects to ROOT_PATH
The ROOT_PATH in the configuration files should be replaced with the actual path to the web root directory of your application. This path will be used to create the necessary symbolic links to the web root directory when enabling the server block.

Follow the logic with before examples in the ``/var/www/my-company`` directory:

```bash
sudo mkdir -p /var/www/my-company
sudo chown -R $USER:$USER /var/www/my-company
sudo chmod -R 755 /var/www/my-company
```

This structure allows you to have ease when pointing domains.

## Inputs domains to use in the domain.conf

The script will prompt you to enter the domain name(s) you want to use for the server block. You can specify multiple domains separated by spaces. For example, if you want to create a server block for my-company.com and www.my-company.com, you would enter:

After informing the domains, the file that will be created will use the base of the first domain ignoring the www. In this example, the file name will be:

```bash
/etc/nginx/sites-available/my-company/my-acompany.com.conf
```

## Running the Script

To run the script, execute the following command:

```bash
sudo bash create_domain_nginx.sh
```