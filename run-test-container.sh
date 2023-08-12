#!/bin/bash

# Validate input arguments
if [ $# -ge 2 ]; then
    if [ ! -f $1 ]; then
        echo
        echo "Broker Configuration file not found: $1"
        echo
        exit 1
    fi
    if [ ! -f $2 ]; then
        echo
        echo "Client Configuration file not found: $2"
        echo
        exit 1
    fi
    if [ $# -eq 2 ]; then
        CONSUMERS=3
    else
        if [[ "$3" =~ ^[0-9]+$ ]]; then
            CONSUMERS=$3
            CONSUMERS=$((CONSUMERS>=100 ? $3 : CONSUMERS))
            CONSUMERS=$((CONSUMERS<1 ? 1 : CONSUMERS))
        else
            echo
            echo "Number of consumers must be an integer between 1 and 100"
            echo
            exit 1
        fi
    fi
else
    echo
    echo "ERROR: Missing command line arguments!"
    echo "> Usage: $0 {kafka_config_file} {client_config_file} {number_of_consumers: 3 default}"
    echo
    exit 1
fi

TESTER_ID=`echo $(date +%s)-$RANDOM`

docker run --name "test_container_$TESTER_ID" --network perf-test -d confluentinc/cp-kafka tail -f /dev/null
docker cp $1 "test_container_$TESTER_ID:/tmp/kafka.ini"
docker cp $2 "test_container_$TESTER_ID:/tmp/client.ini"
docker cp ./scripts/kafka-perf-test.sh "test_container_$TESTER_ID:/tmp/kafka-perf-test.sh"
docker exec "test_container_$TESTER_ID" bash -c "/tmp/kafka-perf-test.sh $TESTER_ID $CONSUMERS"
docker rm -f "test_container_$TESTER_ID"
