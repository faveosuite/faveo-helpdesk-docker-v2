#!/bin/bash

# Colour variables for the script.
red=`tput setaf 1`

green=`tput setaf 2`

yellow=`tput setaf 11`

skyblue=`tput setaf 14`

white=`tput setaf 15`

reset=`tput sgr0`

usage() {
    cat <<'EOF'
Faveo Invoicing Docker Setup Script

Usage:
  ./faveo-run.sh -domainname <domain> -email <email> -ssl <A|B|C>

Required arguments:
  -domainname <domain>   Domain name to serve Faveo Invoicing from (e.g. Invoicing.example.com)
  -email <email>         Email address used for Let's Encrypt registration/notifications
  -ssl <A|B|C>           SSL certificate option:
                           A  Let's Encrypt SSL (automatically obtained for -domainname)
                           B  Self-Signed SSL (generated locally)
                           C  Paid/Custom SSL (you will be prompted for cert, key, and CA bundle paths)

Other options:
  -h, --help             Show this help message and exit

Example:
  ./faveo-run.sh -domainname Invoicing.example.com -email admin@example.com -ssl A

Notes:
  - Run as a user with privileges to install packages and manage Docker (e.g. via sudo).
  - Requires Docker and Docker Compose to already be installed.
  - Clones https://github.com/faveosuite/faveo-invoicing-community.git (master branch) into ./faveo.
EOF
}

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            usage
            exit 0
            ;;
    esac
done

# Faveo Banner.

echo -e "$skyblue                                                                                                                    $reset"
sleep 0.05
echo -e "$skyblue                                   _______ _______ _     _ _______ _______                                          $reset"
sleep 0.05
echo -e "$skyblue                                  (_______|_______|_)   (_|_______|_______)                                         $reset"
sleep 0.05
echo -e "$skyblue                                   _____   _______ _     _ _____   _     _                                          $reset"
sleep 0.05
echo -e "$skyblue                                  |  ___) |  ___  | |   | |  ___) | |   | |                                         $reset"
sleep 0.05
echo -e "$skyblue                                  | |     | |   | |\ \ / /| |_____| |___| |                                         $reset"
sleep 0.05
echo -e "$skyblue                                  |_|     |_|   |_| \___/ |_______)\_____/                                          $reset"
sleep 0.05
echo -e "$skyblue                                                                                                                    $reset"
sleep 0.05
echo -e "$skyblue                         _     _ _______ _       ______ ______  _______  ______ _     _                            $reset"
sleep 0.05
echo -e "$skyblue                        (_)   (_|_______|_)     (_____ (______)(_______)/ _____|_)   | |                            $reset"
sleep 0.05
echo -e "$skyblue                         _______ _____   _       _____) )     _ _____  ( (____  _____| |                            $reset"
sleep 0.05
echo -e "$skyblue                        |  ___  |  ___) | |     |  ____/ |   | |  ___)  \____ \|  _   _)                            $reset"
sleep 0.05
echo -e "$skyblue                        | |   | | |_____| |_____| |    | |__/ /| |_____ _____) ) |  \ \                             $reset"
sleep 0.05
echo -e "$skyblue                        |_|   |_|_______)_______)_|    |_____/ |_______|______/|_|   \_)                            $reset"
sleep 0.05
echo -e "$skyblue                                                                                                                    $reset"
sleep 0.05
echo -e "$skyblue                                                                                                                    $reset"
                                                                                        

if [[ $# -lt 6 ]]; then
    echo "Please run the script by passing all the required arguments."
    exit 1;
fi

echo "Checking Prerequisites....."

if command -v apt >/dev/null; then
    apt update && apt install -y unzip curl git
elif command -v yum >/dev/null; then
    yum install -y unzip curl git
fi

DockerVersion=$(docker --version)

if [[ $? != 0 ]]; then
echo -e "\n";
echo -e "Docker is not found in this server, Please install Docker and try again."
echo -e "\n";
exit 1;
else 
echo -e "\n";
echo $DockerVersion
echo -e "\n";
fi

DockerComposeVersion=$(docker compose version)

if [[ $? != 0 ]]; then
echo -e "\n";
echo -e "Docker Compose is not found in this server please install Docker Compose and try again."
echo -e "\n";
exit 1;
else 
echo -e "\n";
echo $DockerComposeVersion
echo -e "\n";
fi

if [[ $? -eq 0 ]]; then

    echo  -e "\n";
    echo "Prerequisites check completed."
    echo -e "\n";
else
    echo -e "\n";
    echo "Check failed please make sure to execute the script as sudo user and also check your Internet connectivity."
    echo  -e "\n";
    exit 1;
fi



lets() {
    echo "Calling lets() function..."
    if [ ! -d $CUR_DIR/certbot/html ]; then
        mkdir -p $CUR_DIR/certbot/html
    elif [ ! -e $CUR_DIR/certbot/html ]; then
        exit 0;
    fi;

echo "<h1>Obtain SSL Certs</h1>" > $CUR_DIR/certbot/html/index.html

echo -e "Initializing Temporary Apache container to obtain SSL Certificates..."

docker run -dti -p 80:80 -v $CUR_DIR/certbot/html:/usr/local/apache2/htdocs --name apache-cert httpd:2.4.33-alpine

if [[ $? -eq 0 ]]; then
    echo "Initializing Certbot Container to obtain SSL Certificates for $domainname"
    docker run -ti --rm -v $CUR_DIR/certbot/letsencrypt/etc/letsencrypt:/etc/letsencrypt -v $CUR_DIR/certbot/html:/data/letsencrypt --name certbot certbot/certbot certonly --webroot --email $email  --agree-tos --non-interactive  --no-eff-email --webroot-path=/data/letsencrypt -d $domainname
else
    echo "Temporary Container Failed to Initialise exiting..."
    exit 1;
fi;

docker rm -f apache-cert

crontab -l | { cat; echo "45 2 * * 6 docker run -ti --rm -v $CUR_DIR/certbot/letsencrypt/etc/letsencrypt:/etc/letsencrypt -v $CUR_DIR/faveo/public:/data/letsencrypt --name certbot certbot/certbot certonly --webroot --email $email   --agree-tos --non-interactive  --no-eff-email --webroot-path=/data/letsencrypt -d $domainname >/dev/null 2>&1"; } | crontab -

chown -R $USER:$USER $CUR_DIR/certbot

if [[ $? -eq 0 ]]; then
    echo "SSL Certificates for $domainname obtained Successfully."
else
    echo "Permission Issue."
    exit 1;
fi;
}

self() 
{
        echo "Calling self() function..."
        echo "<h1>Obtain SSL Certs</h1>" 

    if [[ $? -eq 0 ]]; then
        echo "Initializing SelfSigned SSL Certificates for $domainname"

        docker build --build-arg CN=$domainname -f dockerfile_selfsign_ssl -t selfsign_ssl .

        docker run -dti -p 8080:80 -p 8443:443 --name selfsign_ssl selfsign_ssl && docker cp selfsign_ssl:/etc/ssl/copy $CUR_DIR/ssl_copy
    else
        echo "Temporary Container Failed to Initialise exiting..."
        exit 1;
    fi;

    docker rm -f selfsign_ssl

    if [[ $? -eq 0 ]]; then
        echo "SSL Certificates for $domainname obtained Successfully."
    else
        echo "Permission Issue."
        exit 1;
    fi;
}

paid() 
{
DIR_NAME="ssl_copy"
if [ -d "$DIR_NAME" ]; then
    echo "Directory '$DIR_NAME' already exists."
else
    mkdir "$DIR_NAME"
    echo "Directory '$DIR_NAME' created successfully."
fi
touch "$DIR_NAME/faveolocal.crt"
touch "$DIR_NAME/private.key"
touch "$DIR_NAME/faveorootCA.crt"

echo "Empty files have been created in '$DIR_NAME':"
echo "$DIR_NAME/faveolocal.crt"
echo "$DIR_NAME/private.key"
echo "$DIR_NAME/faveorootCA.crt"
copy_file_content() {
    local file_desc="$1"
    local dest_file="$2"
    local source_path=""

    while true; do
        echo -n "Enter the path of the $file_desc file: "
        read source_path

        if [ -f "$source_path" ]; then
            cp "$source_path" "$dest_file"
            echo "Content of '$source_path' has been copied to '$dest_file'."
            break
        else
            echo -e "\e[31mError: '$source_path' does not exist. Please check the path and try again.\e[0m"
        fi
    done
}

copy_file_content "certificate.crt" "$DIR_NAME/faveolocal.crt"

copy_file_content "private.key" "$DIR_NAME/private.key"

copy_file_content "ca_bundle.crt" "$DIR_NAME/faveorootCA.crt"

echo "All files have been processed successfully."
}

CUR_DIR=$(pwd)
host_root_dir="faveo"
while test $# -gt 0; do
        case "$1" in
                -h|--help)
                    usage
                    exit 0
                    ;;
                -domainname)
                    shift
                    domainname=$1
                    shift
                    ;;
                -email)
                    shift
                    email=$1
                    shift
                    ;;
                -ssl)
                    shift
                    ssl_option=$1  
                    if [[ "$ssl_option" == "A" || "$ssl_option" == "B" || "$ssl_option" == "C" ]]; then
                        echo -e "\n"
                    else
                        echo "$ssl_option is not a valid SSL option. Please choose A, B, or C."
                        exit 1
                    fi
                    shift
                    ;;
                *)
                echo "$1 is not a recognized flag!"
                exit 1;
                ;;
        esac
done
echo -e "\n";
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[1;36m'
NC='\033[0m'

echo -e "${CYAN}Confirm the Entered Invoicing details:${NC}"
echo -e "${CYAN}-------------------------------------${NC}\n"

echo -e "${YELLOW}Domain Name    :${NC} ${GREEN}$domainname${NC}"
echo -e "${YELLOW}Email          :${NC} ${GREEN}$email${NC}"

echo ""

if [ "$ssl_option" == "A" ]; then
    echo -e "${YELLOW}SSL Option     :${NC} ${GREEN}A - Let's Encrypt SSL${NC}"
elif [ "$ssl_option" == "B" ]; then
    echo -e "${YELLOW}SSL Option     :${NC} ${GREEN}B - Self-Signed SSL${NC}"
elif [ "$ssl_option" == "C" ]; then
    echo -e "${YELLOW}SSL Option     :${NC} ${GREEN}C - Paid SSL${NC}"
else
    echo -e "${YELLOW}SSL Option     :${NC} ${RED}Invalid SSL option selected${NC}"
fi

echo ""

echo -e "\n"


read -p "Continue (y/n)?" REPLY

if [[ ! $REPLY =~ ^(yes|y|Yes|YES|Y) ]]; then
        exit 1;
fi;

case "$ssl_option" in
    A)
        lets
        ;;
    B)
        self
        ;;
    C)
        paid
        ;;
esac


echo -e "\n";
echo "Cloning Faveo Invoicing (Community Edition)"

if [ -d $CUR_DIR/$host_root_dir ]; then
    rm -rf $CUR_DIR/$host_root_dir
fi

git clone -b master https://github.com/faveosuite/faveo-invoicing-community.git $host_root_dir

if [[ $? -eq 0 ]]; then
    echo "Clone Successfull";
else
    echo "Clone Failed. Please check the repository URL and your Internet connectivity."
    exit 1;
fi;

if [ $? -eq 0 ]; then
    chown -R 33:33 $host_root_dir
    find $host_root_dir -type d -exec chmod 755 {} \;
    find $host_root_dir -type f -exec chmod 644 {} \;
    echo "Cloned"
else
    echo "Clone failure."
fi

db_root_pw=$(openssl rand -base64 12)
db_name=faveo
db_user=faveo
db_user_pw=$(openssl rand -base64 12)



if [[ $? -eq 0 ]]; then
    rm -f .env
    cp example.env .env
    sed -i 's:MYSQL_ROOT_PASSWORD=:&'$db_root_pw':' .env
    sed -i 's/MYSQL_DATABASE=/&'$db_name'/' .env
    sed -i 's/MYSQL_USER=/&'$db_user'/' .env
    sed -i 's:MYSQL_PASSWORD=:&'$db_user_pw':' .env
    sed -i 's/DOMAINNAME=/&'$domainname'/' .env

    sed -i '/ServerName/c\    ServerName '$domainname'' ./letsapache/000-default.conf
    sed -i '/ServerName/c\    ServerName '$domainname'' ./apache/000-default.conf  
    
    sed -i 's:domainrewrite:'$domainname':g' ./letsapache/000-default.conf
    sed -i 's:domainrewrite:'$domainname':g' ./apache/000-default.conf
    
    sed -i 's/HOST_ROOT_DIR=/&'$host_root_dir'/' .env
    sed -i 's:CUR_DIR=:&'$PWD':' .env

else
    echo "Database Password Generation Failed"
fi
    


if [[ $? -eq 0 ]]; then
    docker volume create --name ${domainname}-faveoDB
fi

docker network rm ${domainname}-faveo >/dev/null 2>&1 || true

docker network create --subnet=172.24.0.0/16 ${domainname}-faveo --driver=bridge

if [[ $? -eq 0 ]]; then
    echo " Faveo Docker Network ${domainname}-faveo Created"
else
    echo " Faveo Docker Network Creation failed"
    exit 1;
fi


case "$ssl_option" in
    "A")
        echo "You selected Option A: Let's Encrypt SSL"

        sed -i 's|.*000-default.conf:/etc/apache2/sites-available/000-default.conf|      - ./letsapache/000-default.conf:/etc/apache2/sites-available/000-default.conf|' docker-compose.yml
        sed -i 's|.*faveolocal.crt:/etc/ssl/certs/faveolocal.crt|      - ${CUR_DIR}/certbot/letsencrypt/etc/letsencrypt/live/${DOMAINNAME}/cert.pem:/var/imported/ssl/cert.pem|' docker-compose.yml
        sed -i 's|.*private.key:/etc/ssl/private/private.key|      - ${CUR_DIR}/certbot/letsencrypt/etc/letsencrypt/live/${DOMAINNAME}/privkey.pem:/var/imported/ssl/privkey.pem|' docker-compose.yml
        sed -i 's|.*faveorootCA.crt:/usr/local/share/ca-certificates/faveorootCA.crt|      - ${CUR_DIR}/certbot/letsencrypt/etc/letsencrypt/live/${DOMAINNAME}/fullchain.pem:/var/imported/ssl/fullchain.pem|' docker-compose.yml
        ;;
    *)
        ;;
esac


if [ ! -d "$CUR_DIR/storage" ]; then
    mkdir -p "$CUR_DIR/storage"
else
    echo "Storage directory already exists."
fi
sudo chown -R 33:33 "$CUR_DIR/storage"
chmod -R 755 "$CUR_DIR/storage"

echo "Starting Docker Compose..."
docker compose up -d

echo -e "\n";
###############################################################################

if [[ $? -eq 0 ]]; then
    echo -e "\n"
    echo "#########################################################################"
    echo -e "\n"
    echo "Faveo Docker installed successfully. Visit https://$domainname from your browser."
    echo "Please save the following credentials."
    echo "Database Hostname: faveo-mysql"
    echo "Mysql Database root password: $db_root_pw"
    echo "Faveo Invoicing DB name: $db_name"
    echo "Faveo Invoicing DB User: $db_user"
    echo "Faveo Invoicing DB Password: $db_user_pw"
    echo -e "\n"
    echo "#########################################################################"
###################Credentials File Creation####################
    echo "Faveo Invoicing Docker Setup Credentials" > credentials.txt
    echo "----------------------------------------" >> credentials.txt
    echo "Faveo Docker installed successfully. Visit https://$domainname from your browser." >> credentials.txt
    echo "Database Hostname: faveo-mysql" >> credentials.txt
    echo "Mysql Database root password: $db_root_pw" >> credentials.txt
    echo "Faveo Invoicing DB name: $db_name" >> credentials.txt
    echo "Faveo Invoicing DB User: $db_user" >> credentials.txt
    echo "Faveo Invoicing DB Password: $db_user_pw" >> credentials.txt
    echo -e "\n"
    echo "Credentials are saved in the file 'credentials.txt'."
else
    echo "Script Failed unknown error."
    exit 1;
fi


