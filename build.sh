#!/usr/bin/env bash

# Env Vars for SSH
source /root/.ssh/agent/root || . /root/.ssh/agent/root

# Print
print () {
    printf "$1\n"
}

# Build current timestamp
timestamp () {
  date +"%Y%m%d_%H%M"
}

# Static start time.
ts=$(timestamp)

# Exception Catcher
except () {
    print $1
    return 1
}

# Run the build and push to Git and Docker.
run () {
    docker build /home/docker/sslscan/sslscan_docker_image/ -t blairy/sslscan:$ts || except "Docker build failed!" 
    git="/usr/bin/git -C /home/docker/sslscan/sslscan_docker_image/"
    $git pull && \
    $git add --all && \
    $git commit -a -m "Automatic build $ts" && \ 
    $git push || except "Git Failed!"
    docker push blairy/sslscan:$ts || except "Docker push failed!"
}

# Manage execution
if run; then
    print "Build and Push successfull!"
else
    except "Run Failed!"
    exit 1
fi
exit 0