--[[
Author: wxa
Date: 2020-10-26
Desc: Http 
-----------------------------------------------
local Http = NPL.load("script/ide/System/UI/Window/Api/Http.lua");
-----------------------------------------------
]]

local Promise = NPL.load("./Promise.lua", IsDevEnv);

local Http = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Http:Property("Token");                    -- Bearer token
Http:Property("Config", {headers = {}});   -- 配置

local function HttpRequest(config, callback)
    -- echo(config, true)
    System.os.GetUrl(config, callback);
end

function Http:ctor()
    self:SetConfig({
        headers = {
            ["content-type"] = "application/json", 
        }
    });
end

function Http:Init(config)
    commonlib.partialcopy(self:GetConfig(), config);
    return self;
end

function Http:SetAuthorizationHeader(authorization)
    local headers = self:GetConfig().headers;
    headers["authorization"] = authorization;
end

function Http:GetMethod(config)
    return string.upper(config.method or self:GetConfig().method or "GET");
end

function Http:GetUrl(config)
    local url = config.url;

    if (string.match(url, "^http[s]?://")) then return url end
    local baseURL = config.baseURL or self:GetConfig().baseURL or "";

    return baseURL .. url;
end

function Http:GetHeaders(config)
    local headers = commonlib.deepcopy(self:GetConfig().headers or {});
    commonlib.partialcopy(headers, config.headers);
    return headers;
end

function Http:HandleTransformRequest(config, request)
    local transformRequest = config.transformRequest or self:GetConfig().transformRequest;
    if (type(transformRequest) ~= "function") then return request end
    return transformRequest(request) or request;
end

function Http:HandleTransformResponse(config, response)
    local transformResponse = config.transformResponse or self:GetConfig().transformResponse;
    if (type(transformResponse) ~= "function") then return response end
    return transformResponse(response) or response;
end

function Http:Request(config)
    return Promise:new():Init(function(resolve, reject)
        local method = self:GetMethod(config);
        local request = {
            method = method,
            url = self:GetUrl(config), 
            headers = self:GetHeaders(config),
            json = true,
            form = (method == "POST" or method == "PUT") and config.data or nil,
            qs = (method ~= "POST" and method ~= "PUT") and config.data or nil,
        }
        HttpRequest(self:HandleTransformRequest(config, request), function(status, msg, data)
            -- echo({status, msg, data})  
            local response = self:HandleTransformResponse(config, {status = status, header = msg.header, code = msg.code, data = data});
            if (status < 200 or status >= 300) then return reject(response) end
            resolve(response);
        end);
    end);
end

function Http:Get(url, config)
    config = config or {};
    config.method = "GET";
    config.url = url;
    return self:Request(config);
end

function Http:Post(url, data, config)
    config = config or {};
    config.method = "POST";
    config.url = url;
    config.data = data;
    return self:Request(config);
end

function Http:Put(url, data, config)
    config = config or {};
    config.method = "PUT";
    config.url = url;
    config.data = data;
    return self:Request(config);
end

function Http:Delete(url, config)
    config = config or {};
    config.method = "PUT";
    config.url = url;
    return self:Request(config);
end

function Http.Test()
    local http = Http:new();
    http:Get("https://api.keepwork.com/core/v0/keepworks/currentTime"):Then(function(response)
        -- echo(response.data)
    end);
end
