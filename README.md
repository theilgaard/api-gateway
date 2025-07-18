# Nginx + Lua API Gateway

[![CI](https://github.com/theilgaard/api-gateway/actions/workflows/ci.yml/badge.svg)](https://github.com/theilgaard/api-gateway/actions/workflows/ci.yml)
[![Code Quality](https://github.com/theilgaard/api-gateway/actions/workflows/code-quality.yml/badge.svg)](https://github.com/theilgaard/api-gateway/actions/workflows/code-quality.yml)
[![Build and Release](https://github.com/theilgaard/api-gateway/actions/workflows/release.yml/badge.svg)](https://github.com/theilgaard/api-gateway/actions/workflows/release.yml)

A flexible, lightweight API Gateway implementation using Nginx and Lua.

## Features

- **Dynamic Routing**: Route API requests to appropriate backend services based on URL patterns
- **Authentication**: API key validation with support for JWT tokens (custom implementation needed)
- **Rate Limiting**: Basic rate limiting functionality to protect backend services
- **Request Logging**: Comprehensive request logging for monitoring and debugging
- **Health Checks**: Health check endpoint for monitoring
- **Extensible Architecture**: Easy to extend with additional middleware functionality

## Prerequisites

- OpenResty (Nginx with Lua support) - *not required if using Docker*
- Basic knowledge of Nginx configuration
- Lua knowledge (for extending functionality)
- Docker and Docker Compose (for containerized deployment)

## Installation

### Option 1: Local Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/api-gateway.git
   cd api-gateway
   ```

2. Run the setup script:
   ```
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```
   
   This script will:
   - Check for OpenResty installation and install it if necessary
   - Set up configuration symbolic links
   - Create mock backend services for testing

### Option 2: Docker Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/api-gateway.git
   cd api-gateway
   ```

2. Build and start using Docker Compose:
   ```
   docker-compose up -d
   ```

   This will:
   - Build the API gateway Docker image
   - Start the API gateway container
   - Start mock backend service containers for testing
   - Connect all services on the same network

## Configuration

### Main Components

- **nginx/nginx.conf** - Main Nginx configuration file
- **nginx/conf.d/default.conf** - Default server block configuration
- **nginx/lua/gateway.lua** - Main API Gateway Lua module
- **nginx/lua/utils.lua** - Utility functions for authentication, rate limiting, etc.

### Backend Service Configuration

Backend service routing is configured in `nginx/lua/gateway.lua`. Modify the `services` table to add or remove services:

```lua
local services = {
    users = {
        host = "127.0.0.1",
        port = 8001,
        routes = {
            ["^/api/users.*"] = true
        }
    },
    -- Add more services here
}
```

## Usage

### Starting the API Gateway

1. Make sure OpenResty is installed (the setup script does this for you)
2. Run OpenResty:
   ```
   openresty
   ```
   or if using a non-standard configuration path:
   ```
   openresty -p /path/to/api-gateway -c nginx/nginx.conf
   ```

### Starting Mock Backend Services (for testing)

Run the mock services script:
```
chmod +x scripts/mock_services.sh
./scripts/mock_services.sh
```

### Testing the API Gateway

Run the test script to verify functionality:
```
chmod +x scripts/test.sh
./scripts/test.sh
```

### Making API Requests

All API requests should be sent to `http://localhost/api/*` with an Authentication header:

```
curl -H "Authorization: Bearer test-api-key" http://localhost/api/users
```

## Extending the Gateway

### Adding Authentication Methods

Modify the `authenticate` function in `nginx/lua/utils.lua` to add your own authentication logic.

### Adding Middleware

You can add custom middleware by extending the `run_gateway` function in `nginx/lua/gateway.lua`.

### Adding Metrics and Monitoring

Implement custom metrics collection by adding Lua code to track request counts, response times, etc.

## Performance Tuning

- Adjust `worker_processes` and `worker_connections` in `nginx.conf` based on your hardware
- Optimize Lua code to minimize execution time
- Consider using LuaJIT for better performance
- Use caching where appropriate to reduce load on backend services

## Production Considerations

For production deployment, consider:

1. Configuring SSL/TLS certificates
2. Setting up proper monitoring and logging
3. Using Docker for containerization
4. Implementing proper authentication mechanisms
5. Adding more comprehensive rate limiting
6. Setting up high availability with multiple instances

## License

MIT