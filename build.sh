#!/usr/bin/env bash
# Build Executer for SSLScan Docker Image CI/CD.
# Run via cron, build, test, push, fail fast.

# Env Vars for SSH
source /root/.ssh/agent/root || . /root/.ssh/agent/root

# Log file
log="/home/docker/sslscan/sslscan_docker_image/log_build.log"

# Build current timestamp
timestamp () {
  date +"%Y%m%d_%H%M"
}

# Static start time.
ts=$(timestamp)

# Exception Catcher
except () {
    logger $1
    return 1
}

# log and print to stdout
# logger is called by except so to avoid infinte loops do not call except from logger.
logger () {
    echo $1 || printf "\nError! logger function failed to stdout.\n"
    echo $1 >> $log || printf "\nError! logger function failed to file.\n"
}

# Test the build of SSLScan works.
test () {
  docker run --rm $1 https://google.com.au | tee $log || return 1
}

# Run the build and push to Git and Docker.
run () {
    docker build /home/docker/sslscan/sslscan_docker_image/ -t blairy/sslscan:$ts | tee $log || except "Docker build failed!"
    if test blairy/sslscan:$ts
    then   
        git="/usr/bin/git -C /home/docker/sslscan/sslscan_docker_image/"
        $git pull && \
        $git add --all && \
        $git commit -a -m "Automatic build $ts" && \ 
        $git push | tee $log || except "Git Failed!"
        docker push blairy/sslscan:$ts | tee $log || except "Docker push failed!"
    else
        except "SSLScan Test Failed!"
    fi
}

# Manage execution
if run; then
    logger "Build and Push successfull!"
else
    except "Run Failed!"
    exit 1
fi

# Complete
exit 0