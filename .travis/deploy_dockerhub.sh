#!/bin/sh


# if [ "$TRAVIS_BRANCH" = "master" ]; then
#     TAG="latest"
# else
#     TAG="$TRAVIS_BRANCH"
# fi
# 
# echo "$DOCKER_PASS" | docker login -u $DOCKER_USER --password-stdin
# 
# export DOCKER_IMAGE=tarantool-test-task:$TAG
# 
# docker build --tag=$DOCKER_USER/$DOCKER_IMAGE .
# docker push $DOCKER_USER/$DOCKER_IMAGE
docker login -u $DOCKER_USER -p $DOCKER_PASS
docker build -f Dockerfile -t $TRAVIS_REPO_SLUG:latest .
docker push $TRAVIS_REPO_SLUG
