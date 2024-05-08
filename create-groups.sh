#!/bin/bash

set -u # Exit if an unset variable is used

# Function to send POST request to create status page group
create_status_page_group() {
    local name=$1
    local is_expanded=true

    local curl_cmd="curl --request POST \
        --url https://oneuptime.$DOMAIN/api/status-page-group \
        --header \"ApiKey: $API_KEY\" \
        --header \"ProjectID: $PROJECT_ID\" \
        --header 'content-type: application/json' \
        --data @- << EOF
{
    \"data\": {
        \"projectId\": {
            \"_type\": \"ObjectID\",
            \"value\": \"$PROJECT_ID\"
        },
        \"statusPageId\": {
            \"_type\": \"ObjectID\",
            \"value\": \"$STATUS_PAGE_ID\"
        },
        \"name\": \"$name\",
        \"isExpandedByDefault\": $is_expanded
    },
    \"miscDataProps\": {}
}
EOF"

    # Send the curl command and store the response
    local response=$(eval "$curl_cmd")

    # Extract the status page group ID from the response
    local group_id=$(echo "$response" | jq -r '._id')

    # Return the group ID
    echo "$group_id"
}

# Function to display usage
display_usage() {
    echo "Usage: $0 <CSV_FILE>"
    echo "Example: $0 groups.csv"
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
echo "STATUS_PAGE_ID: $STATUS_PAGE_ID"

# Create a new CSV file for storing the status page group IDs
output_file="created-$(basename "$1" .csv).csv"

# Process each line in the CSV file
while IFS=',' read -r name; do
    if [ "$name" = "name" ]; then
        # Skip the header line
        continue
    fi

    # Create status page group
    group_id=$(create_status_page_group "$name")

    # Save the ID to the new CSV file
    echo "$name,$group_id" >> "$output_file"
done < "$1"

echo "Status page groups created and IDs stored in $output_file"
