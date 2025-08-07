#!/bin/bash

# file containing list of urls
INPUT_FILE="urls.txt"

# Print table header
printf "%-40s %-25s %-30s %-25s %-25s\n" "URL" "Hostname:Port" "Issuer O" "Valid From" "Valid To"

while IFS= read -r url
do
    # Parse scheme, host, and port using grep/sed/awk and bash
    proto="$(echo "$url" | sed -E 's,^(.*://).*,\1,g')"
    hostport="$(echo "$url" | sed -E 's,^[a-z]+://,,g')"
    host="$(echo "$hostport" | cut -d: -f1)"
    port="$(echo "$hostport" | cut -s -d: -f2)"
    port="${port:-443}"

    if [[ "$proto" != "https://" ]]; then
        printf "%-40s %-25s %-30s %-25s %-25s\n" "$url" "$host:$port" "NOT HTTPS" "-" "-"
        continue
    fi

    # Get certificate using openssl
    cert=$(echo | openssl s_client -servername "$host" -connect "$host:$port" 2>/dev/null | openssl x509 -noout -issuer -startdate -enddate)

    if [[ -z "$cert" ]]; then
        printf "%-40s %-25s %-30s %-25s %-25s\n" "$url" "$host:$port" "ERROR" "-" "-"
        continue
    fi

    # Extract issuer organization
    issuer=$(echo "$cert" | grep "issuer=")
    issuer_o=$(echo "$issuer" | sed -n 's/.*O=\([^,]*\).*/\1/p')
    issuer_o="${issuer_o:-Unknown}"

    # Extract validity
    start=$(echo "$cert" | grep "start" | cut -d= -f2-)
    end=$(echo "$cert" | grep "end" | cut -d= -f2-)

    printf "%-40s %-25s %-30s %-25s %-25s\n" "$url" "$host:$port" "$issuer_o" "$start" "$end"
done < "$INPUT_FILE"
