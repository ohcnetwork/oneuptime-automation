#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found!"
    exit 1
fi

# Run the cURL command and store the response in a variable
response=$(curl --request GET \
  --url "https://$DOMAIN/api/monitor/get-list?limit=50&skip=0" \
  --header "ApiKey: $API_KEY" \
  --header "ProjectID: $PROJECT_ID" \
  --header 'content-type: application/json' \
  --data '{
  "query": {
    "projectId": "'"$PROJECT_ID"'"
  },
  "select": {
    "_id": true,
    "name": true
  },
  "sort": {}
}')

# Check if the response is empty
if [ -z "$response" ]; then
    echo "Error: Empty response from server."
    exit 1
fi

# Parse the JSON response and extract id and monitor name
ids=$(echo "$response" | jq -r '.data[]["_id"]')
names=$(echo "$response" | jq -r '.data[]["name"]')

# Combine id and monitor name into CSV format
csv=$(paste -d ',' <(echo "$ids") <(echo "$names"))

# Output the CSV
echo "$csv" > monitors.csv
