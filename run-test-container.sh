#!/bin/bash

# System Vars
MIN_CONSUMERS=1
MAX_CONSUMERS=100

# Validate input arguments
if [ $# -ge 2 ]; then
    if [ ! -f $1 ]; then
        echo
        echo "Kafka Configuration file not found: $1"
        echo
        exit 1
    elif [[ $1 != *.config ]]; then
        echo
        echo "Invalid Kafka Configuration file (extension must be *.config): $1"
        echo
        exit 1
    fi
    if [ ! -f $2 ]; then
        echo
        echo "Client YAML file not found: $2"
        echo
        exit 1
    elif [[ $2 != *.yaml ]]; then
        echo
        echo "Invalid Client YAML file (extension must be *.yaml): $2"
        echo
        exit 1
    fi
    if [ $# -eq 2 ]; then
        CONSUMERS=3
    else
        if [[ "$3" =~ ^[0-9]+$ ]]; then
            CONSUMERS=$3
            CONSUMERS=$((CONSUMERS>MAX_CONSUMERS ? MAX_CONSUMERS : CONSUMERS))
            CONSUMERS=$((CONSUMERS<MIN_CONSUMERS ? MIN_CONSUMERS : CONSUMERS))
        else
            echo
            echo "Number of consumers must be an integer between $MIN_CONSUMERS and $MAX_CONSUMERS"
            echo
            exit 1
        fi
    fi
else
    echo
    echo "ERROR: Missing command line arguments!"
    echo "> Usage: $0 {kafka_config_file} {client_yaml_file} {number_of_consumers: 3 default}"
    echo
    exit 1
fi

TESTER_ID=`echo $(date +%s)-$RANDOM`

docker run --name "test_container_$TESTER_ID" --network perf-test -d confluentinc/cp-kafka tail -f /dev/null > /dev/null
docker cp $1 "test_container_$TESTER_ID:/tmp/kafka.config" > /dev/null
docker cp $2 "test_container_$TESTER_ID:/tmp/client.yaml" > /dev/null
docker cp ./scripts/kafka-perf-test.sh "test_container_$TESTER_ID:/tmp/kafka-perf-test.sh" > /dev/null
docker exec "test_container_$TESTER_ID" bash -c "/tmp/kafka-perf-test.sh $TESTER_ID $CONSUMERS"
docker rm -f "test_container_$TESTER_ID" > /dev/null
