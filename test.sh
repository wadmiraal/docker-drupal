#!/bin/bash
# Small script to test builds.
TAG='local'
CONTAINER_NAME='local_wadmiraal_drupal_test_build'
DOCKER='sudo docker'

EXIT_CODE=0
echo -e "\e[32mStarting new build...\e[0m"

# Build the image, without any caching.
$DOCKER build -t wadmiraal/drupal:$TAG .

if [[ -z $? ]]; then
  echo -e "\e[31mBuild failed! Aborting.\e[0m"
  EXIT_CODE=1
else
  echo -e "\e[32mBuild succeeded. Starting a new container...\e[0m"
  $DOCKER run -d --name $CONTAINER_NAME wadmiraal/drupal:$TAG >> /dev/null

  RUNNING=$($DOCKER ps | grep $CONTAINER_NAME)
  if [[ -z $RUNNING ]]; then
    echo -e "\e[31mCouldn't start a new container! Aborting.\e[0m"
    EXIT_CODE=1
  else
    echo -e "\e[32mStarted container. Testing services are running...\e[0m"

    # Allow services to start.
    sleep 3

    echo -n "Supervisor: "
    RUNNING=$($DOCKER exec $CONTAINER_NAME bash -c 'pgrep "supervisor"')
    if [[ -z $RUNNING ]]; then
      echo -e "\e[31m✗ is not running!\e[0m"
      EXIT_CODE=1
    else
      echo -e "\e[32m✓ is running.\e[0m"
    fi

    echo -n "MySQL: "
    RUNNING=$($DOCKER exec $CONTAINER_NAME bash -c 'pgrep "mysql"')
    if [[ -z $RUNNING ]]; then
      echo -e "\e[31m✗ is not running!\e[0m"
      EXIT_CODE=1
    else
      echo -e "\e[32m✓ is running.\e[0m"
    fi

    echo -n "SSH: "
    RUNNING=$($DOCKER exec $CONTAINER_NAME bash -c 'pgrep "sshd"')
    if [[ -z $RUNNING ]]; then
      echo -e "\e[31m✗ is not running!\e[0m"
      EXIT_CODE=1
    else
      echo -e "\e[32m✓ is running.\e[0m"
    fi

    echo -n "Cron: "
    RUNNING=$($DOCKER exec $CONTAINER_NAME bash -c 'pgrep "cron"')
    if [[ -z $RUNNING ]]; then
      echo -e "\e[31m✗ is not running!\e[0m"
      EXIT_CODE=1
    else
      echo -e "\e[32m✓ is running.\e[0m"
    fi

    echo -n "Apache: "
    RUNNING=$($DOCKER exec $CONTAINER_NAME bash -c 'pgrep "apache2"')
    if [[ -z $RUNNING ]]; then
      echo -e "\e[31m✗ is not running!\e[0m"
      EXIT_CODE=1
    else
      echo -e "\e[32m✓ is running.\e[0m"
    fi

    echo -n "Drush: "
    RUNNING=$($DOCKER exec $CONTAINER_NAME bash -c 'drush status | grep "Drush version"')
    if [[ -z $RUNNING ]]; then
      echo -e "\e[31m✗ is not available!\e[0m"
      EXIT_CODE=1
    else
      echo -e "\e[32m✓ is available.\e[0m"
    fi

    echo -n "Drupal Console: "
    RUNNING=$($DOCKER exec $CONTAINER_NAME bash -c 'drupal about | grep "Drupal Console Launcher"')
    if [[ -z $RUNNING ]]; then
      echo -e "\e[31m✗ is not available!\e[0m"
      EXIT_CODE=1
    else
      echo -e "\e[32m✓ is available.\e[0m"
    fi

    echo "Drupal: "
    RUNNING=$($DOCKER exec $CONTAINER_NAME bash -c 'drush --root=/var/www status | grep "Drupal version"')
    if [[ -z $RUNNING ]]; then
      echo -e "\t\e[31m✗ is not installed!\e[0m"
      EXIT_CODE=1
    else
      echo -e "\t\e[32m✓ is installed.\e[0m"
    fi
    RUNNING=$($DOCKER exec $CONTAINER_NAME bash -c 'curl -s http://localhost | grep "Log in"')
    if [[ -z $RUNNING ]]; then
      echo -e "\t\e[31m✗ is not available!\e[0m"
      EXIT_CODE=1
    else
      echo -e "\t\e[32m✓ is available.\e[0m"
    fi

    echo "Removing test container..."
    $DOCKER stop $CONTAINER_NAME >> /dev/null
    $DOCKER rm $CONTAINER_NAME >> /dev/null

    echo
    if (($EXIT_CODE > 0)); then
      echo -e "\e[1;31mFinished build and tests. Some tests failed!\e[0m"
    else
      echo -e "\e[1;32mFinished build and tests. All systems green. Ready to tag and push to the registry.\e[0m"
    fi
  fi
fi
exit $EXIT_CODE

