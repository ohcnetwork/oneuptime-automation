#!/bin/bash

set -u # Exit if an unset variable is used

# Function to send POST request
send_request() {
    local monitor_id=$1
    local display_name=$2

    local curl_cmd="curl --request POST \
        --url https://oneuptime.$DOMAIN/api/status-page-resource \
        --header \"ApiKey: $API_KEY\" \
        --header \"ProjectID: $PROJECT_ID\" \
        --header 'content-type: application/json' \
        --data @- << EOF
{
    \"data\": {
        \"statusPageId\": {
            \"_type\": \"ObjectID\",
            \"value\": \"$STATUS_PAGE_ID\"
        },
        \"monitor\": {
            \"_id\": \"$monitor_id\"
        },
        \"statusPageGroupId\": {
            \"_type\": \"ObjectID\",
            \"value\": \"$STATUS_PAGE_GROUP_ID\"
        },
        \"displayName\": \"${display_name#"${display_name%%[! ]*}"}\",
        \"showCurrentStatus\": true,
        \"showUptimePercent\": true,
        \"uptimePercentPrecision\": \"99.9% (One Decimal)\",
        \"showStatusHistoryChart\": true
    },
    \"miscDataProps\": {}
}
EOF"

    log_curl_command "$curl_cmd"
    eval "$curl_cmd"
}

# Function to log cURL command to a file
log_curl_command() {
    local curl_command=$1
    echo "$curl_command" >> curl.log
}

# Function to display usage
display_usage() {
    echo "Usage: $0 <CSV_FILE> <CUSTOM_ENV_FILE>"
    echo "Example: $0 monitors.csv custom.env"
}

# Check if CSV file and custom env file are provided as arguments
if [ "$#" -ne 2 ]; then
    echo "Error: Incorrect number of arguments!"
    display_usage
    exit 1
fi

# Load environment variables from custom env file
if [ -f "$2" ]; then
    source "$2"
    echo "STATUS_PAGE_GROUP_ID from custom env file: $STATUS_PAGE_GROUP_ID"
else
    echo "Error: Custom env file not found!"
    exit 1
fi

# Load environment variables from .env file
if [ -f .env ]; then
    source .env
    echo "STATUS_PAGE_GROUP_ID from .env: $STATUS_PAGE_GROUP_ID"
else
    echo "Error: .env file not found!"
    exit 1
fi

# Print all environment variables to verify they are loaded correctly
echo "API_KEY: $API_KEY"
echo "PROJECT_ID: $PROJECT_ID"
echo "STATUS_PAGE_ID: $STATUS_PAGE_ID"

# Read monitors from CSV and add them
while IFS=',' read -r monitor_id display_name; do
    send_request "$monitor_id" "$display_name"
done < "$1"
