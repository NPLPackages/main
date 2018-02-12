local UrlRequest = commonlib.inherit(nil, "System.os.UrlRequest")
local requests = {}
local id = 0
local MAX_REQUEST_ID = 10000000

function UrlRequest:init(options, callbackFunc)
    id = (id + 1) % MAX_REQUEST_ID
    self.id = id
    self.options = options
    if (options.json) then
        self:SetHeader("content-type", "application/json")
        if (options.form and not options.postfields) then
            -- encoding data in json and sent via postfields
            options.postfields = commonlib.Json.Encode(options.form)
        end
    end
    if (options.qs) then
        options.url = NPL.EncodeURLQuery(options.url, options.qs)
    end
    self.callbackFunc = callbackFunc
    self.url = options.url or ""
    requests[self.id] = self
    return self
end

-- @param value: if nil, key is added as a headerline.
function UrlRequest:SetHeader(key, value)
    local headers = self.options.headers
    if (not headers) then
        headers = {}
        self.options.headers = headers
    end
    if (value) then
        headers[key] = value
    else
        headers[#headers + 1] = key
    end
end

function UrlRequest:SetResponse(msg)
    self.response = msg
    if (msg and msg.data) then
        if (type(msg.header) == "string") then
            local input_type_lower = msg.header:lower():match("content%-type:%s*([^\r\n]+)")
            if (input_type_lower) then
                if (input_type_lower:find("application/json", 1, true)) then
                    if (type(msg.data) == "string") then
                        msg.data = commonlib.Json.Decode(msg.data) or msg.data
                    end
                elseif (input_type_lower:find("x-www-form-urlencoded", 1, true)) then
                -- TODO:
                end
            end
        end
    end
end

function UrlRequest:InvokeCallback()
    if (self.response and self.callbackFunc) then
        self.callbackFunc(self.response.rcode, self.response, self.response.data)
    end
end

----------------------------------
-- os function
----------------------------------
function CallbackURLRequest__(id)
	local request = requests[id];
	if(request) then
		if(request.id == id) then
			request:SetResponse(msg);
			request:InvokeCallback();
		end
		requests[id] = nil;
	end
end