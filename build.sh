#!/usr/bin/env bash

# Env Vars for SSH
source /root/.ssh/agent/root || . /root/.ssh/agent/root

# Log file
log="/var/log/messages"

# Build current timestamp
timestamp () {
  date +"%Y%m%d_%H%M"
}

# Exception Catcher
except () {
    print $1
    return 1
}

# Print
printer () {
    printf "$1\n" || except "Printf failed in the print function!"
    echo "$1" >> $log || except "Echo failed in the print function!"
}
if ! printer; then
    except "Print Failed!"
    exit 1
fi

# Static start time.
ts=$(timestamp)

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