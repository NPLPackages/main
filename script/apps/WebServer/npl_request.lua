--[[
Title: npl HTTP request
Author: LiXizhi
Date: 2015/6/8
Desc: 
Methods:
	request:get(name)    get/post param value
	request:getparams()
	request:url()
	request:getpeername()   ip address
	request:get_cookie(name)
	request:GetNid()
	request:discard()
	request:GetHost()
	request:GetMethod()
	request:GetBody()
-----------------------------------------------
NPL.load("(gl)script/apps/WebServer/npl_request.lua");
local request = commonlib.gettable("WebServer.request");
-----------------------------------------------
]]
NPL.load("(gl)script/ide/Json.lua");
NPL.load("(gl)script/ide/LuaXML.lua");
NPL.load("(gl)script/apps/WebServer/npl_response.lua");
NPL.load("(gl)script/ide/socket/url.lua");
NPL.load("(gl)script/apps/WebServer/npl_util.lua");
local util = commonlib.gettable("WebServer.util");
local url = commonlib.gettable("commonlib.socket.url")
local response = commonlib.gettable("WebServer.response");

local tostring = tostring;
local lower = string.lower;
local type = type;

local request = commonlib.inherit(nil, commonlib.gettable("WebServer.request"));

-- command method
request.cmd_mth = "GET";
-- relative path
request.relpath = "";

-- whether to dump all incoming stream;
request.dump_stream = false;

function request:ctor()
	self.response = response:new():init(self);
end

-- get the response object. 
function request:GetResponse()
	return self.response;
end

-- get the nid where the request is from. 
function request:GetNid()
	return self.nid;
end

function request:errorEvent(msg)
    msg = tostring(msg)
	LOG.std(nil, "error", "npl_http", "NPLWebServer Error nid:%s: %s", tostring(self.nid), msg);
	self.response:send(string.format ([[
<html><head><title>NPL_http Error!</title></head>
<body>
<h1>NPL_http Error!</h1>
<p>%s</p>
</body></html>
]], string.gsub (msg, "\n", "<br/>\n")));
end

function request:tostring()
	return commonlib.serialize_compact(self.headers);
end

function request:redirect(d)
	self.headers ["Location"] = d
	self.statusline = "HTTP/1.1 302 Found"
	self.content = "redirect"
end

-- original request url
function request:url()
	return self.headers.url or self.relpath;
end

function request:parse_url()
	local def_url = string.format ("http://%s%s", self.headers.host or "", self.cmd_url or "")
	self.parsed_url = url.parse (def_url or '')
	self.parsed_url.port = self.parsed_url.port or 0
	self.built_url = url.build (self.parsed_url)
	self.relpath = url.unescape (self.parsed_url.path or '')
	--self.relpath = self.headers.url;
	--self.built_url = string.format ("http://%s%s", self.headers.host or "", self.headers.cmd_url or "")
end

-- headers actually is the raw message containing everything.
-- just incase one wants to clone the request and forward it to some other threads or network process. 
function request:GetMsg()
	return self.headers;
end

local function get_boundary(content_type)
	local boundary = string.match(content_type, "boundary%=(.-)$")
	return "--" .. tostring(boundary)
end

local function insert_field(tab, name, value, overwrite)
	if (overwrite or not tab[name]) then
		tab[name] = value
	else
		local t = type(tab[name])
		if t == "table" then
			table.insert(tab[name], value)
		else
			tab[name] = { tab[name], value }
		end
	end
end

local function break_headers(header_data)
	local headers = {}
	for type, val in string.gmatch(header_data, '([^%c%s:]+):%s+([^\n]+)') do
		type = lower(type)
		headers[type] = val
	end
	return headers
end

local function read_field_headers(input, pos)
	local EOH = "\r?\n\r?\n"
	local s, e = string.find(input, EOH, pos)
	if s then
		return break_headers(string.sub(input, pos, s-1)), e+1
	else 
		return nil, pos 
	end
end

local function split_filename(path)
	local name_patt = "[/\\]?([^/\\]+)$"
	return (string.match(path, name_patt))
end

local function get_field_names(headers)
	local disp_header = headers["content-disposition"] or ""
	local attrs = {}
	for attr, val in string.gmatch(disp_header, ';%s*([^%s=]+)="(.-)"') do
		attrs[attr] = val
	end
	return attrs.name, attrs.filename and split_filename(attrs.filename)
end

local function read_field_contents(input, boundary, pos)
	local boundaryline = "\n" .. boundary
	local s, e = string.find(input, boundaryline, pos, true)
	if s then
		if(input:byte(s-1) == 13) then  -- '\r' == 0x0d == 13
			s = s - 1
		end
		return string.sub(input, pos, s-1), s-pos, e+1
	else 
		return nil, 0, pos 
	end
end

local function file_value(file_contents, file_name, file_size, headers)
	local value = { contents = file_contents, name = file_name,	size = file_size }
	for h, v in pairs(headers) do
		if h ~= "content-disposition" then
			value[h] = v
		end
	end
	return value
end

local function fields(input, boundary)
	local state, _ = { }

	_, state.pos = string.find(input, boundary, 1, true)
	if(not state.pos) then
		return function() end;
	end
	state.pos = state.pos + 1
	return function (state, _)
		local headers, name, file_name, value, size
		headers, state.pos = read_field_headers(input, state.pos)
		if headers then
			name, file_name = get_field_names(headers)
			if file_name then
				value, size, state.pos = read_field_contents(input, boundary, state.pos)
				value = file_value(value, file_name, size, headers)
			else
				value, size, state.pos = read_field_contents(input, boundary, state.pos)
			end
		end
		return name, value
	end, state
end

-- @param input: input string
-- @param input_type: the content type containing the boundary text. 
-- @param tab: table of key value pairs, if nil a new table is created and returned. 
-- @return table of key value pairs
function request:ParseMultipartData(input, input_type, tab, overwrite)
	tab = tab or {}
	local boundary = get_boundary(input_type);
	if(boundary) then
		for name, value in fields(input, boundary) do
			insert_field(tab, name, value, overwrite)
		end
	end
	return tab;
end

function request:ParsePostData()
	local body = self.headers.body;
	if(body and body~="") then
		local input_type = self:header("Content-Type");
		if(input_type) then
			input_type_lower = lower(input_type);
			if(input_type_lower:find("x-www-form-urlencoded", 1, true)) then
				self.params = util.parse_str(body, self.params);	
			elseif(input_type_lower:find("multipart/form-data", 1, true)) then
				self.params = self:ParseMultipartData(body, input_type, self.params, true);
			elseif(input_type_lower:find("application/json", 1, true)) then
				-- please note: this will overwrite parameters in url.
				self.params = commonlib.Json.Decode(body) or self.params or {};
			else
				self.params = util.parse_str(body, self.params);	
			end
			self.data = self.params;
		end
	end
end

-- get the request body. if the body is known datetype, such as "application/json", it may already be converted to table
-- One can always get the raw http request body string using self.headers.body. 
function request:GetBody()
	return self.data or self.headers.body;
end

-- get url parameters: both url post/get are supported
-- return a table of name, value pairs
function request:getparams()
	if (not self.params) then 
		self:ParsePostData();
		if (self.parsed_url.query) then 
			self.params = util.parse_str(self.parsed_url.query, self.params);	
		end
		self.params = self.params or {};
	end
	return self.params;
end

function request:IsJsonBody()
	local contentType =self.headers["Content-Type"];
	if(contentType and contentType:match("^application/json")) then
		return true;
	end
end


-- get host name from header. usually checking for the http origin for cross-domain request or not. 
function request:GetHost()
	return self.headers.Host;
end

-- in headers  'GET', 'HEAD', 'POST', 'PUT', 'OPTIONS' etc
function request:GetMethod()
	return self.headers.method;
end

-- get the value of given header
-- @param name: "method", "Host", or any of other custom header fields
function request:header(name)
	return self.headers[name];
end

-- get a given url get/post param by name
-- @param name: if name is nil or 'json', we will return table object passed in from headers.body (json http post)
-- if you post data as json, you can also access json encoded html body directly with key name. 
function request:get(name)
	if(not name or name=="json") then
		return commonlib.Json.Decode(self.headers.body);
	else
		local params = self:getparams();
		if(params) then
			return params[name];
		end
	end
end

-- get ip address as string
function request:getpeername()
	self.ip = self.ip or NPL.GetIP(self.nid);
	return self.ip;
end

-- drop this request, so that nothing is sent to client at the moment. 
-- we use this function to delegate a request from one thread to another in npl script handler
function request:discard()
	self.response:discard();
end

-- send/route the request to another processor: possibly another npl file in another thread or another machine. 
function request:send(address)
	self:discard();
	local msg = self.headers;
	NPL.activate(address, self.headers);
	-- TODO: add cross machine routing, since nid will change.  
end

-- get cookies or a given cookie entry value by name
-- @param name: if nil, entire cookies table is returned. if string, only cookies value of the given name is returned. 
function request:get_cookie(name)
	if(not self.cookies) then
		self.cookies = {};
		if(self.headers.Cookie) then
			local cookies = string.gsub(";" .. (self.headers.Cookie) .. ";", "%s*;%s*", ";")
			setmetatable(self.cookies, { __index = function (tab, name)
				local pattern = ";" .. name .."=(.-);"
				local cookie = string.match(cookies, pattern)
				cookie = util.url_decode(cookie)
				rawset(tab, name, cookie)
				return cookie
			end})
		end
	end
	if(not name) then
		return self.cookies;
	else
		return self.cookies[name];
	end
end

-- clear all cookies in case of rpc request, etc. 
function request:clear_cookie()
	if(self.cookies) then
		self.cookies = {};
	end
	if(self.headers.Cookie) then
		self.headers.Cookie = nil;
	end
end

-- mapping from lower case to case-sensitive headers
local lowercase_headers = {
["connection"] = "Connection",
["accept-encoding"] = "Accept-Encoding",
["cache-control"] = "Cache-Control",
["if-modified-since"] = "If-Modified-Since",
["user-agent"] = "User-Agent",
["referer"] = "Referer",
["content-type"] = "Content-Type",
["method"] = "method",
["host"] = "Host",
}

-- from case insensitive to case sensitive. 
function request:NormalizeHeaders(headers)
	local values;
	for name, value in pairs(headers) do
		local rightName = lowercase_headers[lower(name)];
		if(rightName and rightName~=name) then
			values = values or {};
			values[name] = rightName;
		end
	end
	if(values) then
		for name, newName in pairs(values) do
			headers[newName] = headers[name];
			headers[name] = nil;
		end
	end
	return headers;
end

-- request can be reused by calling this function. 
-- the request object is returned if succeed.
function request:init(msg)
	if(msg) then
		if(self.dump_stream) then
			echo(msg);
		end
		self.nid = msg.tid or msg.nid;
		self.headers= self:NormalizeHeaders(msg);
		self.cmd_url = msg.url;
		self.cmd_mth = msg.method;
		self:parse_url();
		self.response:init(self);	
		return self;
	end
end
