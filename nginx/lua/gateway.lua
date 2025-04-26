local utils = require "utils"

-- Configuration for backend services
local services = {
    users = {
        host = "127.0.0.1",
        port = 8001,
        routes = {
            ["^/api/users.*"] = true
        }
    },
    products = {
        host = "127.0.0.1",
        port = 8002,
        routes = {
            ["^/api/products.*"] = true
        }
    },
    orders = {
        host = "127.0.0.1",
        port = 8003,
        routes = {
            ["^/api/orders.*"] = true
        }
    }
}

-- API Gateway main function
local function run_gateway()
    -- Get request information
    local uri = ngx.var.uri
    local method = ngx.req.get_method()
    local headers = ngx.req.get_headers()

    -- Add request ID for tracing
    local request_id = utils.generate_request_id()
    ngx.req.set_header("X-Request-ID", request_id)
    
    -- Authenticate the request
    local auth_result, auth_error = utils.authenticate(headers)
    if not auth_result then
        utils.respond_with_error(401, auth_error or "Unauthorized")
        return
    end
    
    -- Rate limiting
    if not utils.check_rate_limit(headers["authorization"]) then
        utils.respond_with_error(429, "Too many requests")
        return
    end
    
    -- Route to appropriate backend service
    local target_service = utils.find_service(uri, services)
    if not target_service then
        utils.respond_with_error(404, "Service not found")
        return
    end
    
    -- Modify target URL to route to the appropriate backend
    local target_host = target_service.host
    local target_port = target_service.port
    ngx.var.proxy_pass = "http://" .. target_host .. ":" .. target_port
    
    -- Log the routing
    ngx.log(ngx.INFO, string.format("[API Gateway] Routing %s %s to %s:%s", 
                                    method, uri, target_host, target_port))
end

-- Execute gateway logic
run_gateway()

return {
    run_gateway = run_gateway
}