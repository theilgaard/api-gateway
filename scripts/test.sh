#!/bin/bash

# API Gateway Test Script
echo "Testing API Gateway functionality..."

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Test base URL
BASE_URL="http://localhost"

# Make a request and check the response
test_endpoint() {
    local endpoint=$1
    local expected_status=$2
    local auth_header=$3
    local description=$4
    
    echo -e "${YELLOW}Testing: ${description}${NC}"
    
    if [ -z "$auth_header" ]; then
        response=$(curl -s -w "%{http_code}" -o /tmp/api_response.txt "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "%{http_code}" -o /tmp/api_response.txt -H "Authorization: $auth_header" "$BASE_URL$endpoint")
    fi
    
    if [ "$response" -eq "$expected_status" ]; then
        echo -e "${GREEN}✓ Success: Got expected status code $expected_status${NC}"
        cat /tmp/api_response.txt
        echo ""
    else
        echo -e "${RED}✗ Failed: Expected status code $expected_status but got $response${NC}"
        cat /tmp/api_response.txt
        echo ""
    fi
}

# Run the tests
echo "====== Running API Gateway Tests ======"

# Health check (should work without auth)
test_endpoint "/health" 200 "" "Health check endpoint"

# API docs (should work without auth)
test_endpoint "/docs" 200 "" "API documentation endpoint"

# Test auth requirement
test_endpoint "/api/users" 401 "" "Missing authorization header"

# Test invalid auth
test_endpoint "/api/users" 401 "Bearer invalid-token" "Invalid authorization"

# Test valid auth with test key
test_endpoint "/api/users" 200 "Bearer test-api-key" "Valid authorization (test key)"

# Test valid auth with dynamic validation
test_endpoint "/api/users" 200 "Bearer valid-12345" "Valid authorization (dynamic validation)"

# Test routing to different services
test_endpoint "/api/users/1" 200 "Bearer test-api-key" "Users service routing"
test_endpoint "/api/products/1" 200 "Bearer test-api-key" "Products service routing"
test_endpoint "/api/orders/1" 200 "Bearer test-api-key" "Orders service routing"

# Test non-existent service
test_endpoint "/api/unknown/1" 404 "Bearer test-api-key" "Non-existent service"

# Test rate limiting (would need to make multiple requests)
echo -e "${YELLOW}Testing: Rate limiting${NC}"
echo "Making multiple requests to trigger rate limiting..."
for i in {1..11}; do
    if [ "$i" -eq 11 ]; then
        response=$(curl -s -w "%{http_code}" -o /tmp/api_response.txt -H "Authorization: Bearer rate-limit-test" "$BASE_URL/api/users")
        if [ "$response" -eq 429 ]; then
            echo -e "${GREEN}✓ Success: Rate limiting working correctly${NC}"
        else
            echo -e "${RED}✗ Failed: Rate limiting not triggered${NC}"
        fi
    else
        curl -s -o /dev/null -H "Authorization: Bearer rate-limit-test" "$BASE_URL/api/users"
        echo -n "."
    fi
done
echo ""

echo "====== API Gateway Tests Complete ======"