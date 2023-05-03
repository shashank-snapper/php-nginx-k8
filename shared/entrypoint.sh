#!/usr/bin/env bash

arg1=${1:-app}

cd /srv
php bin/console cache:clear

case $arg1 in
app) echo "I am an app pod" ;;
queue) echo "I am a queue pod" ;;
scheduler) echo "I am a scheduler pod" ;;
esac

service nginx start
php-fpm
