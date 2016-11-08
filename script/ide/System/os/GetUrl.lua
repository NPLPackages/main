--[[
Title: get/post url
Author(s): LiXizhi
Date: 2016/1/25
Desc: helper class to get/post url content. It offers no progress function. 
For large files with progress, please use NPL.AsyncDownload. 
However, this function can be useful to get URL headers only for large HTTP files. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/os/GetUrl.lua");
-- down file or making standard request
System.os.GetUrl("https://github.com/LiXizhi/HourOfCode/archive/master.zip", echo);
-- get headers only with "-I" option. 
System.os.GetUrl("https://github.com/LiXizhi/HourOfCode/archive/master.zip", function(err, msg, data)  echo(msg) end, "-I");
-- send form KV pairs with http post
System.os.GetUrl({url = "http://localhost:8099/ajax/console?action=getparams", form = {key="value",} }, function(err, msg, data)		echo(data)	end);
-- send multi-part binary forms with http post
System.os.GetUrl({url = "http://localhost:8099/ajax/console?action=printrequest", form = {name = {file="dummy.html",	data="<html><bold>bold</bold></html>", type="text/html"}, } }, function(err, msg, data)		echo(data)	end);
-- To send any binary data, one can use 
System.os.GetUrl({url = "http://localhost:8099/ajax/console?action=printrequest", headers={["content-type"]="application/json"}, postfields='{"key":"value"}' }, function(err, msg, data)		echo(data)	end);
-- To simplify json encoding, we can send form as json string using following shortcut
System.os.GetUrl({url = "http://localhost:8099/ajax/console?action=getparams", json = true, form = {key="value", key2 ={subtable="subvalue"} } }, function(err, msg, data)		echo(data)  end);
-- sending email via smtp
System.os.SendEmail({
	url="smtp://smtp.exmail.qq.com", 
	username="lixizhi@paraengine.com", password="1234567", 
	-- ca_info = "/path/to/certificate.pem",
	from="lixizhi@paraengine.com", to="lixizhi@yeah.net", cc="xizhi.li@gmail.com", 
	subject = "title here",
	body = "any body context here. can be very long",
}, function(err, msg) echo(msg) end);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/Json.lua");
local os = commonlib.gettable("System.os");

local npl_thread_name = __rts__:GetName();
if(npl_thread_name == "main") then
	npl_thread_name = "";
end

local function GetUrlSync(url)
	local c = cURL.easy_init()
	local result;
	-- setup url
	c:setopt_url(url)
	-- perform, invokes callbacks
	c:perform({writefunction = function(str) 
			if(result) then
				result = result..str;
			else
				result = str;
			end	
			end})
	return result;
end

----------------------------------------
-- url request 
----------------------------------------
local requests = {};
local Request = commonlib.inherit(nil, {});

local id = 0;

function Request:init(options, callbackFunc)
	id = (id + 1)%100;
	self.id = id;
	self.options = options;
	if(options.json) then
		self:SetHeader('content-type', 'application/json');
		if(options.form and not options.postfields) then
			-- encoding data in json and sent via postfields
			options.postfields = commonlib.Json.Encode(options.form);
		end
	end
	if(options.qs) then
		options.url = NPL.EncodeURLQuery(options.url, options.qs);
	end
	self.callbackFunc = callbackFunc;
	self.url = options.url or "";
	requests[self.id] = self;
	return self;
end

-- @param value: if nil, key is added as a headerline.
function Request:SetHeader(key, value)
	local headers = self.options.headers; 
	if(not headers) then
		headers = {};
		self.options.headers = headers;
	end
	if(value) then
		headers[key] = value;
	else
		headers[#headers+1] = key;
	end
end

function Request:SetResponse(msg)
	self.response = msg;
	if(msg and msg.data) then
		if(self.options.json and msg.header) then
			if(type(msg.data) == "string") then
				msg.data = commonlib.Json.Decode(msg.data) or msg.data;
			end
		end
	end
end

function Request:InvokeCallback()
	if(self.response and self.callbackFunc) then
		self.callbackFunc(self.response.rcode, self.response, self.response.data);
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

local function GetUrlOptions(url, option)
	local options;
	if(type(url) == "table") then
		options = url;
		url = options.url;
	else
		options = {};
	end
	if(option) then
		url = option.." "..url;
	end
	options.url = url;
	return options;
end

-- return the content of a given url. 
-- e.g.  echo(NPL.GetURL("www.paraengine.com"))
-- @param url: url string or a options table of {url=string, postfields=string, form={key=value}, headers={key=value, "line strings"}, json=bool, qs={}}
-- if .json is true, code will be decoded as json.
-- if .qs is query string table
-- if .postfields is a binary string to be passed in the request body. If this is present, form parameter will be ignored. 
-- @param callbackFunc: a function(rcode, msg, data) end, if nil, the function will not return until result is returned(sync call).
--  `rcode` is http return code, such as 200 for success, which is same as `msg.rcode`
--  `msg` is the raw HTTP message {header, code=0, rcode=200, data}
--  `data` contains the translated response data if data format is a known format like json
--    or it contains the binary response body from server, which is same as `msg.data`
-- @param option: mostly nil. "-I" for headers only
-- @return: return nil if callbackFunc is a function. or the string content in sync call. 
function os.GetUrl(url, callbackFunc, option)
	local options = GetUrlOptions(url, option);

	if(not callbackFunc) then
		-- NOT recommended
		return GetUrlSync(options.url);
	end
	
	local req = Request:new():init(options, callbackFunc);

	-- async call. 
	NPL.AppendURLRequest(options, format("(%s)CallbackURLRequest__(%d)", npl_thread_name, req.id), nil, "r");
end


--[[ send an email message via smtp protocol
@param params: {
	url="smtp://mail.paraengine.com", 
	username="LiXizhi", password="1234567", 
	-- ca_info = "/path/to/certificate.pem", date = "Mon, 29 Nov 2010 21:54:29 +1100",
	from="lixizhi@paraengine.com", to="lixizhi@yeah.net", cc="xizhi.li@gmail.com", 
	subject = "title here",
	body = "any body context here. can be very long",
}
]]
function os.SendEmail(params, callbackFunc)
	local lines = {};
	if(params.date) then
		lines[#lines+1] = "Date: "..params.date;
	end
	if(params.to) then
		lines[#lines+1] = "To: "..params.to;
	end
	if(params.from) then
		lines[#lines+1] = "From: "..params.from;
	end
	if(params.cc) then
		lines[#lines+1] = "Cc: "..params.cc;
	end
	lines[#lines+1] = "Subject: "..(params.subject or "from NPL");
	-- empty line to divide headers from body, see RFC5322 
	lines[#lines+1] = "";
	lines[#lines+1] = params.body or "hello";

	local contents = table.concat(lines, "\r\n");
	return os.GetUrl({
		url = params.url,
		options = {
			CURLOPT_USERNAME = params.username,
			CURLOPT_PASSWORD = params.password,
			CURLOPT_CAINFO = params.ca_info,
			CURLOPT_CAPATH = params.ca_path,
			CURLOPT_MAIL_FROM = params.from,
			CURLOPT_VERBOSE = 1,
			CURLOPT_UPLOAD = 1,
			CURLOPT_MAIL_RCPT = {params.to, params.cc},
			CURLOPT_READDATA = contents,
		},
	}, callbackFunc);
end