#!/bin/bash

set -euo pipefail

CF_API="https://api.cloudflare.com/client/v4"

ZONE=$(tr -d '\r\n' < /config/zone.txt)
HOSTNAME=$(tr -d '\r\n' < /config/hostname.txt)

echo "Zone: ${ZONE}"
echo "Hostname: ${HOSTNAME}"


if [ -z "${CF_API_TOKEN:-}" ]; then
    echo "ERROR: CF_API_TOKEN is missing"
    exit 1
fi

safe_curl() {
    local response
    response=$(curl -fsSL "$@" 2>&1) || {
        echo "CURL_ERROR:$response"
        return 0
    }
    echo "$response"
}

get_public_ip() {
    IP=$(safe_curl -4 --max-time 10 https://api.ipify.org)

    if [[ "$IP" == "CURL_ERROR:"* ]] || [ -z "$IP" ] || [ "$IP" = "0.0.0.0" ]; then
        echo ""
    else
        echo "$IP"
    fi
}


echo "Finding Cloudflare zone..."

ZONE_RESPONSE=$(curl -fsSL \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    "${CF_API}/zones?name=${ZONE}")


ZONE_ID=$(echo "$ZONE_RESPONSE" | jq -r '.result[0].id // empty')


if [ -z "$ZONE_ID" ]; then
    echo "ERROR: Zone not found"
    echo "$ZONE_RESPONSE"
    exit 1
fi


echo "Zone ID: ${ZONE_ID}"


echo "Finding DNS record..."


RECORD_RESPONSE=$(curl -fsSL \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    "${CF_API}/zones/${ZONE_ID}/dns_records?type=A&name=${HOSTNAME}")


RECORD_ID=$(echo "$RECORD_RESPONSE" | jq -r '.result[0].id // empty')


if [ -z "$RECORD_ID" ]; then

    echo "DNS record does not exist"

    IP=$(get_public_ip)

    if [ -z "$IP" ]; then
        echo "ERROR: Could not determine public IP"
        exit 1
    fi


    echo "Creating ${HOSTNAME} -> ${IP}"


    CREATE_RESPONSE=$(curl -fsSL -X POST \
        "${CF_API}/zones/${ZONE_ID}/dns_records" \
        -H "Authorization: Bearer ${CF_API_TOKEN}" \
        -H "Content-Type: application/json" \
        --data "{
            \"type\":\"A\",
            \"name\":\"${HOSTNAME}\",
            \"content\":\"${IP}\",
            \"ttl\":60,
            \"proxied\":false
        }")


    RECORD_ID=$(echo "$CREATE_RESPONSE" | jq -r '.result.id // empty')


    if [ -z "$RECORD_ID" ]; then
        echo "ERROR: Failed creating DNS record"
        echo "$CREATE_RESPONSE"
        exit 1
    fi


    echo "Created record ID: ${RECORD_ID}"

else

    echo "Record ID: ${RECORD_ID}"

fi



while true
do

    IP=$(get_public_ip)


    if [ -z "$IP" ]; then
        echo "Could not determine public IP, retrying in 60s..."
        sleep 60
        continue
    fi


    CURRENT_RESPONSE=$(safe_curl \
        -H "Authorization: Bearer ${CF_API_TOKEN}" \
        -H "Content-Type: application/json" \
        "${CF_API}/zones/${ZONE_ID}/dns_records/${RECORD_ID}")

    if [[ "$CURRENT_RESPONSE" == "CURL_ERROR:"* ]]; then
        echo "Cloudflare API error occurred (e.g. 521 Server Error). Retrying in 60s..."
        echo "${CURRENT_RESPONSE#CURL_ERROR:}"
        sleep 60
        continue
    fi

    CURRENT=$(echo "$CURRENT_RESPONSE" | jq -r '.result.content // empty')


    if [ "$IP" != "$CURRENT" ]; then

        echo "Updating ${HOSTNAME}: ${CURRENT} -> ${IP}"


        UPDATE_RESPONSE=$(safe_curl -X PUT \
            "${CF_API}/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
            -H "Authorization: Bearer ${CF_API_TOKEN}" \
            -H "Content-Type: application/json" \
            --data "{
                \"type\":\"A\",
                \"name\":\"${HOSTNAME}\",
                \"content\":\"${IP}\",
                \"ttl\":60,
                \"proxied\":false
            }")

        if [[ "$UPDATE_RESPONSE" == "CURL_ERROR:"* ]]; then
            echo "Failed to connect to Cloudflare during update. Retrying in 60s..."
            sleep 60
            continue
    	fi

        SUCCESS=$(echo "$UPDATE_RESPONSE" | jq -r '.success')


        if [ "$SUCCESS" != "true" ]; then
            echo "Cloudflare update failed:"
            echo "$UPDATE_RESPONSE"
        else
            echo "DNS updated successfully"
        fi

    else

        echo "IP unchanged: ${IP}"

    fi


    sleep 60

done
