#!/bin/bash

INPUT_FILE="urls.txt"

printf "%-40s %-25s %-30s %-25s %-25s\n" "URL" "Hostname:Port" "Issuer O" "Valid From" "Valid To"

while IFS= read -r url
do
    proto="$(echo "$url" | sed -E 's,^(.*://).*,\1,g')"
    hostport="$(echo "$url" | sed -E 's,^[a-z]+://,,g')"
    host="$(echo "$hostport" | cut -d: -f1)"
    port="$(echo "$hostport" | cut -s -d: -f2)"
    port="${port:-443}"

    if [[ "$proto" != "https://" ]]; then
        printf "%-40s %-25s %-30s %-25s %-25s\n" "$url" "$host:$port" "NOT HTTPS" "-" "-"
        continue
    fi

    cert_info=$(echo | openssl s_client -servername "$host" -connect "$host:$port" 2>/dev/null | openssl x509 -noout -issuer -startdate -enddate)
    
    if [[ -z "$cert_info" ]]; then
        printf "%-40s %-25s %-30s %-25s %-25s\n" "$url" "$host:$port" "ERROR" "-" "-"
        continue
    fi

    # Extract Issuer O
    issuer_line=$(echo "$cert_info" | grep "^issuer=")
    issuer_o=$(echo "$issuer_line" | sed -n 's/.*O=\([^,]*\).*/\1/p')
    issuer_o="${issuer_o:-Unknown}"

    # Extract Valid From
    valid_from=$(echo "$cert_info" | grep "^notBefore=" | cut -d= -f2-)
    # Extract Valid To
    valid_to=$(echo "$cert_info" | grep "^notAfter=" | cut -d= -f2-)

    printf "%-40s %-25s %-30s %-25s %-25s\n" "$url" "$host:$port" "$issuer_o" "$valid_from" "$valid_to"

done < "$INPUT_FILE"
