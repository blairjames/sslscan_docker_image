#!/usr/bin/env bash

# ------------------------------------------------------------------------ #
# This script aims to make the output of SSLScan more useful in a          #
# CI context by adding logic which then integrates with the build tools    #
# allowing decisions to be made automatically based on the results         #
# provided by the tool.                                                    #
#                                                                          #
#  Inspiration about how results are calculated was derived from:          #                                                               #
#  https://github.com/ssllabs/research/wiki/SSL-Server-Rating-Guide        #                                                                 #
#                                                                          #
# ------------------------------------------------------------------------ #

# Parameter: XML File to output results to. 
XML_REPORT="$1";

# Parameter: URL to be scanned.
SCAN_URL="$2";

# Test that XML_REPORT and SCAN_URL are passed in, if not, inform and fail.
if [ $# -lt 2 ]; then
    printf "\nPlease specify an XML output file and URL to be scanned: \"run-sslscan.sh [filename.xml] [URL_to_be_scanned]\"\n\n"
    exit 1
fi

# Run SSLScan Command
sslscan --xml=$XML_REPORT $SCAN_URL

# File to write output to.
LOG="./sslscan_analysis.log";

# "BUILD_FAILURE" provides a String describing the reason for failure.
# Available outside script context for use by build tools.
declare -x BUILD_FAILURE="";

# Suboptimal configurations remove points from the "SCORE" integer resulting in a final grade.
# Available outside script context for use by build tools.
declare -xi SCORE=100;

# Function "timestamp" gets current date/time and formats into a timestamp String. 
function timestamp {
    date +"%Y%m%d_%H%M%S"
}

# Function "set_score" takes a single integer parameter and removes it from the existing value of $SCORE.
#   set_score [number of points to be removed from score] [reason for deduction] [resource for further research] 
function set_score {
    if [ "$SCORE" -eq "0" ]; then
        printf "\nWARNING: $2\nSCORE is zero due to previous critical failure!\nFor further information please see: $3\n"
    else
        printf "\nWARNING: $2\nSubtracting $1 from current score ($SCORE)\nFor further information please see: $3\n" | tee -a $LOG
        SCORE=$(($SCORE - $1))
    fi
}

# Function "critical_zero" logs the reason for failure and set the SCORE variable to zero.
# To be used for instances where vulnerabilities are present that warrant instant build failure.
#   critical_zero [reason for failure] [resource for further research]
function critical_zero {
    SCORE=0
    printf "\nCritical failure!: $1\n\nFor further information please see: $2\n\n" | tee -a $LOG
    BUILD_FAILURE=$1
}

printf "\n\n**************************************************\n"

if [[ $(xmllint $XML_REPORT --xpath //expired | grep ">true<") ]]; then
    critical_zero "Certificate is expired!" "https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Protection_Cheat_Sheet.html"
fi

# If SSLv2 or SSLv3 is enabled, instant fail.
if [[ $(xmllint $XML_REPORT --xpath //protocol | grep -i ssl | grep -i enabled=\"1\" | tee -a $LOG) ]]; then
    critical_zero "SSL is enabled!" "https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Protection_Cheat_Sheet.html"
fi

# If TLS1.0 enabled, instant fail.
if [[ $(xmllint $XML_REPORT --xpath //protocol | grep -i enabled=\"1\" | grep -i tls | grep version=\"1.0\" | tee -a $LOG) ]]; then
    critical_zero "TLS Version 1.0 is enabled!" "https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Protection_Cheat_Sheet.html"
fi

# If vulnerable to heartbleed, instant fail.
if [[ $(xmllint $XML_REPORT --xpath //heartbleed | grep "vulnerable=\"1\"") ]]; then
    critical_zero "Site is vulnerable to heartbleed!" "https://heartbleed.com/"
fi

# If certificate is self-signed instant fail.
if [[ $(xmllint $XML_REPORT --xpath //self-signed | grep ">true<") ]]; then
    critical_zero "Certificate is self-signed!" "https://www.globalsign.com/en-au/ssl-information-center/dangers-self-signed-certificates" 
fi

# If TLS1.1 enabled deduct 50
if [[ $(xmllint $XML_REPORT --xpath //protocol | grep -i enabled=\"1\" | grep -i tls | grep version=\"1.1\" | tee -a $LOG) ]]; then
    set_score 50 "TLS Version 1.1 is enabled!" "https://security.googleblog.com/2018/10/modernizing-transport-security.html"
fi

# If TLS1.3 not offered deduct 10
if [[ ! $(xmllint $XML_REPORT --xpath //protocol | grep -i enabled=\"1\" | grep -i tls | grep version=\"1.3\" | tee -a $LOG) ]]; then
    set_score 10 "TLS Version 1.3 is not enabled." "https://www.ssl.com/guide/ssl-best-practices/"
fi

function calculate_grade {
    case $SCORE in 
        100) GRADE="A" ;;
        9[0-9]) GRADE="A" ;; 
        8[0-9]) GRADE="A" ;;
        7[0-9]) GRADE="B" ;;
        6[5-9]) GRADE="B" ;;
        6[0-4]) GRADE="C" ;;
        5[0-9]) GRADE="C" ;;
        4[0-9]) GRADE="D" ;;
        3[5-9]) GRADE="D" ;;
        3[0-4]) GRADE="E" ;;
        2[0-9]) GRADE="E" ;;
        *) GRADE="F" ;;
    esac
}

calculate_grade;

printf "\n\nFinal Score is: $SCORE\n"
printf "\nGrade Awarded to \"$SCAN_URL\": $GRADE\n"
printf "\n**************************************************\n"

# If the site fails, exit non-zero to break build.
if [ $SCORE -lt 50 ]; then
    exit 33
fi


#Instant zeros
# Domain name mismatch
# Certificate not yet valid
# Certificate expired
# Use of a self-signed certificate
# Use of a certificate that is not trusted (unknown CA or some other validation error)
# Use of a revoked certificate
# Insecure certificate signature (MD2 or MD5)
# Insecure key
# If the sites certifiicate is expired, instant fail.
