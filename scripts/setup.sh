#!/bin/bash

# API Gateway Setup Script
echo "Setting up API Gateway environment..."

# Check if OpenResty is installed (needed for Nginx with Lua)
if ! command -v openresty &> /dev/null; then
    echo "OpenResty is not installed. Installing OpenResty..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux setup
        sudo apt-get update
        sudo apt-get install -y libpcre3-dev libssl-dev perl make build-essential curl
        
        # Add OpenResty repository
        wget -qO - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
        echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/openresty.list
        sudo apt-get update
        sudo apt-get install -y openresty
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS setup with Homebrew
        if ! command -v brew &> /dev/null; then
            echo "Homebrew is not installed. Please install Homebrew first."
            exit 1
        fi
        brew update
        brew install openresty/brew/openresty
    else
        echo "Unsupported operating system. Please install OpenResty manually."
        exit 1
    fi
    
    echo "OpenResty installed successfully."
fi

# Create symbolic links to our configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Creating symbolic links for configuration..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # For Linux
    sudo mkdir -p /usr/local/openresty/nginx/conf
    sudo ln -sf "$PROJECT_ROOT/nginx/nginx.conf" /usr/local/openresty/nginx/conf/nginx.conf
    sudo ln -sf "$PROJECT_ROOT/nginx/conf.d" /usr/local/openresty/nginx/conf/conf.d
    sudo ln -sf "$PROJECT_ROOT/nginx/lua" /usr/local/openresty/nginx/conf/lua
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # For macOS
    mkdir -p /usr/local/etc/openresty/
    ln -sf "$PROJECT_ROOT/nginx/nginx.conf" /usr/local/etc/openresty/nginx.conf
    mkdir -p /usr/local/etc/openresty/conf.d
    ln -sf "$PROJECT_ROOT/nginx/conf.d/default.conf" /usr/local/etc/openresty/conf.d/default.conf
    mkdir -p /usr/local/etc/openresty/lua
    ln -sf "$PROJECT_ROOT/nginx/lua/gateway.lua" /usr/local/etc/openresty/lua/gateway.lua
    ln -sf "$PROJECT_ROOT/nginx/lua/utils.lua" /usr/local/etc/openresty/lua/utils.lua
fi

echo "Starting mock backend services for testing..."
# These would be your actual microservices in a real environment
# For demo purposes, we'll create a simple script to simulate them

cat > "$PROJECT_ROOT/scripts/mock_services.sh" << 'EOF'
#!/bin/bash

# Simple HTTP server using netcat to simulate backend services
simulate_service() {
    local port=$1
    local service_name=$2
    
    while true; do
        echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n{\"service\":\"$service_name\",\"status\":\"ok\"}" | nc -l -p $port
    done
}

# Start mock services in the background
simulate_service 8001 "users" &
simulate_service 8002 "products" &
simulate_service 8003 "orders" &

echo "Mock services started on ports 8001, 8002, and 8003"
echo "Press Ctrl+C to stop"
wait
EOF

chmod +x "$PROJECT_ROOT/scripts/mock_services.sh"

echo "Setup completed successfully!"
echo "To start the API gateway, run: openresty"
echo "To start mock backend services for testing, run: ./scripts/mock_services.sh"