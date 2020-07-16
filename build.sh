#!/bin/sh

timestamp() {
  date +"%Y%m%d_%H%M"
}

ts=$(timestamp)
echo "$ts"

docker build . -t blairy/sslscan:$ts
git pull && \
git add --all && \ 
git commit -a -m "Automatic build $ts" && \ 
git push
docker push blairy/sslscan:$ts
