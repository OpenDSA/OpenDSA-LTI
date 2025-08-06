#!/bin/bash
  
container_name=opendsa-lti

echo "Stop Container: $container_name"
docker container stop $container_name

echo "Remove Container: $container_name"
docker container rm $container_name

echo "Build Container: $container_name"

docker build -t $container_name . --build-arg RAILS_ENV='development'

echo "Start Container: $container_name"
docker run --name $container_name -p 8080:80 $container_name:latest

#docker container ps
#docker exec -it $container_name /bin/bash



#docker build -t opendsa-lti . --build-arg RAILS_ENV='development'
#docker run -p 3000:3000  -it opendsa-lti /bin/bash
#
#bundle exec thin start --ssl --ssl-key-file server.key --ssl-cert-file server.crt -p 3000
#bundle exec thin start  -p 3000
