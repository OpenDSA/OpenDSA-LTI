#!/bin/bash
  
container_name=opendsa-lti

echo "Stop Container: $container_name"
docker container stop $container_name

echo "Remove Container: $container_name"
docker container rm $container_name

