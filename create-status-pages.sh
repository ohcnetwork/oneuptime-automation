#!/bin/bash

set -u # Exit if an unset variable is used

# Function to send POST request to create status page
create_status_page() {
    local name=$1
    local description=$2

    local curl_cmd="curl --request POST \
        --url https://oneuptime.$DOMAIN/api/status-page \
        --header \"ApiKey: $API_KEY\" \
        --header \"ProjectID: $PROJECT_ID\" \
        --header 'content-type: application/json' \
        --data @- << EOF
{
    \"data\": {
        \"name\": \"$name\",
        \"description\": \"$description\"
    },
    \"miscDataProps\": {}
}
EOF"

    # Send the curl command and store the response
    local response=$(eval "$curl_cmd")

    # Extract name and status page ID from the response
    local page_id=$(echo "$response" | jq -r '._id')

    # Return the ID
    echo "$page_id"
}

# Function to display usage
display_usage() {
    echo "Usage: $0 <CSV_FILE>"
    echo "Example: $0 input.csv"
}

# Check if CSV file is provided
if [ "$#" -ne 1 ]; then
    echo "Error: Incorrect number of arguments!"
    display_usage
    exit 1
fi

# Load environment variables from .env file
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found!"
    exit 1
fi

# Print all environment variables to verify they are loaded correctly
echo "API_KEY: $API_KEY"
echo "PROJECT_ID: $PROJECT_ID"

# Create a new CSV file for storing the status page IDs
output_file="created-$(basename "$1")"

# Process each line in the CSV file
while IFS=',' read -r name description; do
    # Create status page
    page_id=$(create_status_page "$name" "$description")

    # Save the ID to the new CSV file
    echo "$name,$description,$page_id" >> "$output_file"
done < "$1"

echo "Status pages created and IDs stored in $output_file"
