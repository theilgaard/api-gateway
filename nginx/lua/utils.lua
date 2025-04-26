local _M = {}

-- Shared dictionaries for caching and rate limiting
local cache_dict = ngx.shared.api_gateway_cache
local rate_limit_dict = ngx.shared.api_rate_limiting

-- Generate a unique request ID
function _M.generate_request_id()
    return ngx.var.remote_addr .. "-" .. ngx.now() .. "-" .. math.random(1000, 9999)
end

-- Simple authentication function
-- This is a placeholder. In a real implementation, you would verify tokens
-- against a proper authentication service or database
function _M.authenticate(headers)
    local auth_header = headers["authorization"]
    
    -- Allow health check and documentation endpoints to bypass auth
    if ngx.var.uri == "/health" or string.match(ngx.var.uri, "^/docs") then
        return true
    end
    
    if not auth_header then
        return false, "Missing Authorization header"
    end
    
    -- Extract token from Authorization: Bearer <token>
    local _, _, token = string.find(auth_header, "Bearer%s+(.+)")
    if not token then
        return false, "Invalid authorization format"
    end
    
    -- Here you would validate the token against your auth system
    -- For this example, we'll just check for a fixed token
    if token == "test-api-key" then
        return true
    end
    
    -- Check cache for valid tokens to reduce external calls
    local cached_result = cache_dict:get(token)
    if cached_result == "valid" then
        return true
    elseif cached_result == "invalid" then
        return false, "Invalid token"
    end
    
    -- TODO: In a real implementation, validate the token with your auth service
    -- For demo, we'll consider tokens starting with "valid-" as valid
    local is_valid = string.match(token, "^valid%-") ~= nil
    
    -- Cache the result
    if is_valid then
        cache_dict:set(token, "valid", 300)  -- Cache for 5 minutes
        return true
    else
        cache_dict:set(token, "invalid", 60)  -- Cache for 1 minute
        return false, "Invalid token"
    end
end

-- Rate limiting function
-- Simple implementation that limits each token to 10 requests per minute
function _M.check_rate_limit(auth_header)
    -- If no auth header, use IP address as identifier
    local identifier = auth_header or ngx.var.remote_addr
    
    -- Get current count
    local current = rate_limit_dict:get(identifier) or 0
    
    -- Check if over limit
    if current >= 10 then
        return false
    end
    
    -- Increment the counter with TTL of 60 seconds
    local success, err, forcible = rate_limit_dict:incr(identifier, 1, 0, 60)
    if not success then
        ngx.log(ngx.ERR, "Failed to increment rate limit counter: ", err)
        -- If we can't track the rate, allow the request to proceed
        return true
    end
    
    return true
end

-- Find the appropriate service for a given URI
function _M.find_service(uri, services)
    for _, service in pairs(services) do
        for pattern, _ in pairs(service.routes) do
            if ngx.re.match(uri, pattern, "jo") then
                return service
            end
        end
    end
    return nil
end

-- Respond with an error
function _M.respond_with_error(status_code, message)
    ngx.status = status_code
    ngx.header.content_type = "application/json"
    ngx.say(string.format('{"error": "%s", "status": %d}', message, status_code))
    return ngx.exit(ngx.HTTP_OK)
end

return _M