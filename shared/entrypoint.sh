#!/usr/bin/env bash

arg1=${1:-app}

cd /srv

if grep -q ^MONGODB_URL= .env; then

  echo "Waiting for cache to be cleared..."
  ATTEMPTS_LEFT_TO_CLEAR_CACHE=5
  until [ $ATTEMPTS_LEFT_TO_CLEAR_CACHE -eq 0 ] || CACHE_ERROR=$(timeout 25s php bin/console cache:clear 2>&1); do
    if [ $? -eq 124 ] || [ $? -ne 0 ]; then
      # If the Doctrine command exits with 124, timeout error
      sleep 1
      ATTEMPTS_LEFT_TO_CLEAR_CACHE=$((ATTEMPTS_LEFT_TO_CLEAR_CACHE - 1))
      echo "Still waiting for redis to be ready... Or maybe the redis is not reachable. $ATTEMPTS_LEFT_TO_CLEAR_CACHE attempts left"

    else
      ATTEMPTS_LEFT_TO_CLEAR_CACHE=0
      break
    fi
    sleep 3
  done

  if [ $ATTEMPTS_LEFT_TO_CLEAR_CACHE -eq 0 ]; then
    echo "The redis is not up or not reachable:"
    echo "$CACHE_ERROR"
    exit 1
  else
    echo "The cache is now cleared and ready"
  fi

  echo "Waiting for db to be ready..."
  ATTEMPTS_LEFT_TO_REACH_DATABASE=60
  until [ $ATTEMPTS_LEFT_TO_REACH_DATABASE -eq 0 ] || DATABASE_ERROR=$(php bin/console doctrine:mongodb:query "SFP\Core\Document\User" "{}" 2>&1); do

    # Todo: Check the actual condition for the command to fail
    if [ $? -eq 0 ]; then
      # If the Doctrine command exits with 255, an unrecoverable error occurred
      ATTEMPTS_LEFT_TO_REACH_DATABASE=0
      break
    fi
    sleep 3
    echo "$DATABASE_ERROR"

    ATTEMPTS_LEFT_TO_REACH_DATABASE=$((ATTEMPTS_LEFT_TO_REACH_DATABASE - 1))
    echo "Still waiting for db to be ready... Or maybe the db is not reachable. $ATTEMPTS_LEFT_TO_REACH_DATABASE attempts left"
  done

  if [ $ATTEMPTS_LEFT_TO_REACH_DATABASE -eq 0 ]; then
    echo "The database is not up or not reachable:"
    echo "$DATABASE_ERROR"
    #    exit 1
  else
    echo "The db is now ready and reachable"
  fi

fi

case $arg1 in
app)
  echo "I am an app pod"
  service nginx start
  php-fpm
  ;;
queue)
  echo "I am a queue pod"
  sleep 10
  php bin/console sfp:core:queue:process:monitor
  exit
  ;;
scheduler)
  echo "I am a scheduler pod"
  php bin/console sfp:core:schedule
  exit
  ;;
esac
