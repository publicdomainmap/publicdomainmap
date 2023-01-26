#!/bin/bash

# Script adapted from https://github.com/wmnnd/nginx-certbot

if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed.' >&2
  exit 1
fi

domains=(
  publicdomainmap.org
  www.publicdomainmap.org
  featureserv.publicdomainmap.org
)

rsa_key_size=4096
data_path="../cert"
email="jmc+publicdomainmap@loc8.us" # Adding a valid address is strongly recommended
staging=0 # Set to 1 if you're testing your setup to avoid hitting request limits

# #################################################################
# Code
# #################################################################

for domain in "${domains[@]}"; do
  if [ -d "$data_path" ]; then
    read -p "Existing data found for $domain. Continue and replace existing certificate? (y/N) " decision
    if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
      exit
    fi
  fi


  if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
    echo "### Downloading recommended TLS parameters ..."
    mkdir -p "$data_path/conf"
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
    echo
  fi

  echo "### Creating dummy certificate for $domain ..."
  path="/etc/letsencrypt/live/$domain"
  mkdir -p "$data_path/conf/live/$domain"
  docker-compose run --rm --entrypoint "\
    openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1\
      -keyout '$path/privkey.pem' \
      -out '$path/fullchain.pem' \
      -subj '/CN=localhost'" certbot
  echo
done

echo "### Starting nginx ..."
docker-compose --file ./ssl-docker-compose.yml up --force-recreate -d --no-deps nginx
echo

for domain in "${domains[@]}"; do
  echo "### Deleting dummy certificate for $domain ..."
  docker-compose run --rm --entrypoint "\
    rm -Rf /etc/letsencrypt/live/$domain && \
    rm -Rf /etc/letsencrypt/archive/$domain && \
    rm -Rf /etc/letsencrypt/renewal/$domain.conf" certbot
  echo

  # Select appropriate email arg
  case "$email" in
    "") email_arg="--register-unsafely-without-email" ;;
    *) email_arg="--email $email" ;;
  esac

  # Enable staging mode if needed
  if [ $staging != "0" ]; then staging_arg="--staging"; fi

  echo "### Requesting Let's Encrypt certificate for $domain ..."
  echo "### using staging $staging_arg ..."
  echo "### using emails $email_args ..."
  echo "### Starting certbot docker ..."
  docker-compose run --rm --entrypoint "\
    certbot certonly --webroot -w /var/www/certbot \
      $staging_arg \
      $email_arg \
      -d $domain \
      --rsa-key-size $rsa_key_size \
      --agree-tos \
      --force-renewal" certbot
  echo
done

echo "### Reloading nginx ..."
docker-compose exec nginx nginx -s reload
