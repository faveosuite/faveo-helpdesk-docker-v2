#!/bin/bash

# Update CA certificates
update-ca-certificates

# Reload Apache configuration
service apache2 reload

# Start PHP-FPM service
service php8.4-fpm start

# Start Apache in the foreground
apache2ctl -D FOREGROUND