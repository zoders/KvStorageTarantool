docker login -u $DOCKER_USER -p $DOCKER_PASS
docker build -f Dockerfile -t $TRAVIS_REPO_SLUG:latest .
docker push $TRAVIS_REPO_SLUG
