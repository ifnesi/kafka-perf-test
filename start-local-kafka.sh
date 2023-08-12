#!/bin/bash

source ./.env

echo
echo "Check if docker is running..."
if (! docker stats --no-stream > /dev/null 2>&1); then
    echo "ERROR: Please start Docker Desktop, then run the '$0' script"
    echo ""
    exit 1
fi
echo

echo "Starting up docker compose (Confluent Platform version $CP_VERSION)..."
docker-compose up -d

echo
echo -n "Waiting for Kafka cluster to be ready..."
waiting_counter=0
while [ "$(curl -s -w '%{http_code}' -o /dev/null 'http://localhost:9021/clusters')" -ne 200 ]; do
    echo -n "."
    sleep 5
    waiting_counter=$((waiting_counter+1))
    if [ $waiting_counter -eq 45 ]; then
        echo ""
        echo ""
        echo "ERROR: Unable to start the Kafka cluster!"
        echo ""
        sleep 1
        ./stop.sh
        echo ""
        exit 1
    fi
done

echo
echo "Ready! Go to http://localhost:9021 to access Confluent Control Center"
echo
