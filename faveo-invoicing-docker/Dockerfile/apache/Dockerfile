# Use the official Ubuntu base image
FROM ubuntu:24.04

# Set environment variables
ENV TZ=Asia/Kolkata \
    DEBIAN_FRONTEND=noninteractive 

# Define PHP and Node.js versions
ENV PHP_VERSION=8.4 \
    NODE_VERSION=22

### IMPORTANT When you chage the PHP VERSION, make sure to change the ioncube loader version in the RUN command below as well.

# Update package lists and install initial packages
RUN apt-get update && \
    apt install -y mysql-client && \
    apt-get install -y \
    tzdata \
    software-properties-common \
    ca-certificates \
    git \
    wget \
    curl \
    unzip \
    nano \
    zip && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf \
        /var/lib/apt/lists/* \
        /var/cache/apt/* \
        /tmp/* \
        /var/tmp/*

# Add PPA repositories for Apache2 and PHP
RUN add-apt-repository ppa:ondrej/apache2 && \
    add-apt-repository ppa:ondrej/php && \
    apt-get update

# Install Apache2
RUN apt-get install -y apache2

# Install PHP and necessary extensions
RUN apt-get install -y \
    php${PHP_VERSION} \
    libapache2-mod-php${PHP_VERSION} \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-imap \
    php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-gmp \
    php${PHP_VERSION}-redis \
    php${PHP_VERSION}-memcached 

# Update PHP configuration for all configurations
RUN for config in fpm cli apache2; do \
        sed -i -e 's/^file_uploads = .*/file_uploads = On/' \
               -e 's/^allow_url_fopen = .*/allow_url_fopen = On/' \
               -e 's/^short_open_tag = .*/short_open_tag = On/' \
               -e 's/^memory_limit = .*/memory_limit = 256M/' \
               -e 's/^;cgi.fix_pathinfo=1.*/cgi.fix_pathinfo = 0/' \
               -e 's/^upload_max_filesize = .*/upload_max_filesize = 100M/' \
               -e 's/^post_max_size = .*/post_max_size = 100M/' \
               -e 's/^max_execution_time = .*/max_execution_time = 360/' \
            /etc/php/${PHP_VERSION}/$config/php.ini; \
    done

# Download and install ionCube Loader
RUN extension_dir=$(php -i | grep ^extension_dir | awk '{print $3}') && \
    curl -fsSL https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -o ioncube_loaders.tar.gz && \
    tar -xzf ioncube_loaders.tar.gz && \
    mv ioncube/ioncube_loader_lin_${PHP_VERSION}.so "$extension_dir" && \
    for config in apache2 cli fpm; do \
        sed -i "2 a zend_extension=${extension_dir}/ioncube_loader_lin_${PHP_VERSION}.so" /etc/php/${PHP_VERSION}/$config/php.ini; \
    done && \
    rm -rf ioncube_loaders.tar.gz ioncube

# Install wkhtmltopdf
RUN apt-get update && \
    apt-get install -y wkhtmltopdf

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs

# Install Puppeteer
RUN npm install --location=global --unsafe-perm puppeteer@^24.33.0

# Install additional dependencies for Puppeteer
RUN apt-get update && apt-get install -y --no-install-recommends chromium ca-certificates fonts-liberation libasound2t64 libatk-bridge2.0-0 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc-s1 libgdk-pixbuf-2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxshmfence1 libxss1 libxtst6 xdg-utils wget && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the working directory and backup dir
RUN mkdir -p /var/www/storage
WORKDIR /var/www/html

# Add ServerName directive to Apache configuration
RUN echo "ServerName 127.0.0.1" >> /etc/apache2/apache2.conf

# Copy the start-services script into the container
COPY start-services.sh /usr/local/bin/start-services.sh

# Make the script executable
RUN chmod +x /usr/local/bin/start-services.sh

# Enable necessary Apache modules and configurations
RUN a2enmod \
    ssl \
    proxy \
    proxy_http \
    proxy_wstunnel \
    proxy_fcgi \
    setenvif \
    rewrite \
    headers && \
    a2enconf php${PHP_VERSION}-fpm

RUN service php${PHP_VERSION}-fpm restart && \
    service apache2 restart

# Expose ports 80 and 443
EXPOSE 80
EXPOSE 443

# Start both Apache2 and PHP-FPM using the shell script
CMD ["/usr/local/bin/start-services.sh"]
