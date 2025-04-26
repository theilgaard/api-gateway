-- API Gateway Tests
-- This file contains unit tests for the API gateway Lua code

local lu = require "luaunit"

-- Mock NGX environment for testing
local ngx = {
    shared = {
        api_gateway_cache = {},
        api_rate_limiting = {}
    },
    var = {
        uri = "/api/users",
        remote_addr = "127.0.0.1"
    },
    req = {
        get_method = function() return "GET" end,
        get_headers = function() return { authorization = "Bearer test-api-key" } end,
        set_header = function(name, value) end
    },
    header = {},
    status = 200,
    log = function(level, msg) end,
    INFO = 4,
    ERR = 3,
    say = function(msg) end,
    exit = function(status) end,
    HTTP_OK = 200,
    re = {
        match = function(uri, pattern)
            if uri == "/api/users" and pattern == "^/api/users.*" then
                return true
            elseif uri == "/api/products" and pattern == "^/api/products.*" then
                return true
            elseif uri == "/api/orders" and pattern == "^/api/orders.*" then
                return true
            end
            return nil
        end
    },
    now = function() return 1619433600 end
}
_G.ngx = ngx

-- Import the modules under test
package.path = "../nginx/lua/?.lua;" .. package.path
local utils = require "utils"

-- Test suite
TestGateway = {}

function TestGateway:setUp()
    -- Reset our mock environment before each test
    ngx.status = 200
    ngx.var.uri = "/api/users"
    ngx.var.remote_addr = "127.0.0.1"
    ngx.shared.api_gateway_cache = {}
    ngx.shared.api_rate_limiting = {}
    
    -- Add methods to our mock shared dictionaries
    ngx.shared.api_gateway_cache.get = function(self, key) return self[key] end
    ngx.shared.api_gateway_cache.set = function(self, key, value, ttl) self[key] = value end
    
    ngx.shared.api_rate_limiting.get = function(self, key) return self[key] end
    ngx.shared.api_rate_limiting.set = function(self, key, value, ttl) self[key] = value end
    ngx.shared.api_rate_limiting.incr = function(self, key, value, init, ttl)
        self[key] = (self[key] or 0) + value
        return self[key], nil, false
    end
end

-- Test authentication function
function TestGateway:test_authenticate()
    -- Test with health endpoint (should bypass auth)
    ngx.var.uri = "/health"
    local result = utils.authenticate({})
    lu.assertEquals(result, true)
    
    -- Test with docs endpoint (should bypass auth)
    ngx.var.uri = "/docs"
    result = utils.authenticate({})
    lu.assertEquals(result, true)
    
    -- Test with missing auth header
    ngx.var.uri = "/api/users"
    result, err = utils.authenticate({})
    lu.assertEquals(result, false)
    lu.assertEquals(err, "Missing Authorization header")
    
    -- Test with invalid auth format
    result, err = utils.authenticate({authorization = "InvalidFormat"})
    lu.assertEquals(result, false)
    lu.assertEquals(err, "Invalid authorization format")
    
    -- Test with test key
    result, err = utils.authenticate({authorization = "Bearer test-api-key"})
    lu.assertEquals(result, true)
    
    -- Test with valid prefix
    result, err = utils.authenticate({authorization = "Bearer valid-token"})
    lu.assertEquals(result, true)
    
    -- Test with invalid token
    result, err = utils.authenticate({authorization = "Bearer invalid-token"})
    lu.assertEquals(result, false)
    
    -- Test cache behavior
    ngx.shared.api_gateway_cache["token123"] = "valid"
    result, err = utils.authenticate({authorization = "Bearer token123"})
    lu.assertEquals(result, true)
    
    ngx.shared.api_gateway_cache["token456"] = "invalid"
    result, err = utils.authenticate({authorization = "Bearer token456"})
    lu.assertEquals(result, false)
end

-- Test rate limiting function
function TestGateway:test_rate_limit()
    -- Test with fresh identifier
    local result = utils.check_rate_limit("Bearer test-token")
    lu.assertEquals(result, true)
    lu.assertEquals(ngx.shared.api_rate_limiting["Bearer test-token"], 1)
    
    -- Simulate 9 more requests (total 10)
    for i = 2, 10 do
        ngx.shared.api_rate_limiting["Bearer test-token"] = i
    end
    
    -- Should still be allowed (at limit)
    result = utils.check_rate_limit("Bearer test-token")
    lu.assertEquals(result, true)
    
    -- One more request should be rate limited
    ngx.shared.api_rate_limiting["Bearer test-token"] = 11
    result = utils.check_rate_limit("Bearer test-token")
    lu.assertEquals(result, false)
end

-- Test service routing
function TestGateway:test_find_service()
    -- Define test services
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
        }
    }
    
    -- Test valid routes
    ngx.var.uri = "/api/users"
    local service = utils.find_service(ngx.var.uri, services)
    lu.assertNotNil(service)
    lu.assertEquals(service.port, 8001)
    
    ngx.var.uri = "/api/products"
    service = utils.find_service(ngx.var.uri, services)
    lu.assertNotNil(service)
    lu.assertEquals(service.port, 8002)
    
    -- Test invalid route
    ngx.var.uri = "/api/invalid"
    service = utils.find_service(ngx.var.uri, services)
    lu.assertNil(service)
end

-- Run the tests
os.exit(lu.LuaUnit.run())