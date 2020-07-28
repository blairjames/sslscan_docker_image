#!/usr/bin/env bash

# Env Vars for SSH
source /root/.ssh/agent/root || . /root/.ssh/agent/root

# Log file
log="/var/log/messages"

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

# Print
print () {
    printf "$1\n" || except "Printf failed in the print function!"
    echo "$1" >> $log || except "Echo failed in the print function!"
}

# Test the build of SSLScan works.
test () {
  docker run --rm $1 https://google.com.au || return 1
}

# Run the build and push to Git and Docker.
run () {
    docker build /home/docker/sslscan/sslscan_docker_image/ -t blairy/sslscan:$ts || except "Docker build failed!" 
    if test blairy/sslscan:$ts; then   
        git="/usr/bin/git -C /home/docker/sslscan/sslscan_docker_image/"
        $git pull && \
        $git add --all && \
        $git commit -a -m "Automatic build $ts" && \ 
        $git push || except "Git Failed!"
        docker push blairy/sslscan:$ts || except "Docker push failed!"
    else
        except "SSLScan Test Failed!"
    fi
}

# Manage execution
if run; then
    print "Build and Push successfull!"
else
    except "Run Failed!"
    exit 1
fi

# Complete
exit 0