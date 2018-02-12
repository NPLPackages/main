--[[
Title: HttpClient
Author: Chenqh
Date: 2018/2/12
desc: A helper class to handle restful http request(base on script/ide/System/os/GetUrl.lua).
NPL will generate a global default HttpClient instance automatically if you load HttpClient,
you can update the settings and customize it by yourself.
If you need two or more clients, just generate them locally and keep the global one.
-----------------------------------------------------
useage:
-----------------------------------------------------
NPL.load("(gl)script/ide/System/os/HttpClient.lua")

HttpClient({
    url = "api.keepwork.com/v1/sign_in",
    method = "POST", -- default is GET
    json = true,
    data = {},
    headers = {},
    callback = function() end
})

HttpClient:http({
    url = "api.keepwork.com/v1/sign_in",
    method = "POST", -- default is GET
    json = true,
    data = {},
    headers = {},
    callback = function() end
})

HttpClient:get("url", {data={}}, function() end)
HttpClient:head("url", {data={}}, function() end)
HttpClient:post("url", {data={}}, function() end)
HttpClient:put("url", {data={}}, function() end)
HttpClient:delete("url", {data={}}, function() end)

]]
NPL.load("(gl)script/ide/System/os/GetUrl.lua")

local GetUrl = commonlib.gettable("System.os.GetUrl")
local _M = commonlib.inherit(nil, "System.os.HttpClient")

local function merge_options(options, url, method, callback, option)
    options = options or {}
    options.url = url
    options.method = method
    options.callback = callback
    options.option = option
    return options
end

local function rearrange_options(options)
    local callback = options.callback
    local option = options.option
    options.callback = nil
    if options.data then
        if options.method == "GET" then
            options.qs = data
        else
            option.form = data
        end
        options.data = nil
    end
    return options, callback
end

function _M:ctor()
    self.ssl_enabled = false -- disable ssl as default
    self.base_uri = "/" -- use local server as default
    local metatable = getmetatable(self)
    metatable.__call = function(self, options) -- extend metatable, add __call
        return self:http(options)
    end
    setmetatable(self, metatable)
end

function _M:set_base_uri(uri)
    self.base_uri = uri
    return self
end

function _M:set_default_options(default_options)
    self.default_options = default_options
    return self
end

function _M:set_ssl(cert, key, ca_info)
    self.ssl = {
        cert = cert,
        key = key,
        ca_info = ca_info
    }
    self.ssl_enabled = true
    return self
end

function _M:append_ssl(options)
    if self.ssl_enabled then
        options.CURLOPT_SSLCERT = self.ssl.cert
        options.CURLOPT_SSLKEY = self.ssl.key
        options.CURLOPT_CAINFO = self.ssl.ca_info
    end
    return options
end

function _M:append_base_uri(options)
    local url = options.url or ""

    if self.base_uri and not url:match("^https?://") then
        options.url = self.base_uri .. url
    end
    return options
end

function _M:append_default_options(options)
    if self.default_options then
        for k, v in pairs(self.default_options) do
            options[k] = options[k] or v
        end
    end
    options.method = options.method or "GET"
    return options
end

function _M:http(options)
    assert(type(options) == "table")
    self:append_default_options(options)
    self:append_base_uri(options)
    self:append_ssl(options)
    return GetUrl(rearrange_options(options))
end

function _M:get(url, options, callback)
    return _M:http(merge_options(options, url, "GET", callback))
end

function _M:head(url, options, callback)
    return self:http(merge_options(options, url, "GET", callback, "-I"))
end

function _M:post(url, options, callback)
    return self:http(merge_options(options, url, "POST", callback))
end

function _M:put(url, options, callback)
    return self:http(merge_options(options, url, "PUT", callback))
end

function _M:delete(url, options, callback)
    return self:http(merge_options(options, url, "DELETE", callback))
end

-- add a global default HttpClient
HttpClient = _M:new()
