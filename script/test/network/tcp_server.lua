--[[
Author: LiXizhi@yeah.net
Date: 2018-1-25
Desc: testing tcp server
-----------------------------------------------
NPL.load("(gl)script/test/network/tcp_server.lua");
test_tcp_server();
test_tcp_client();
test_websocket_client2();
-----------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included


function test_tcp_server(input)
	-- -30 is a predefined file id for web socket. this is needed on both client and server
	NPL.AddPublicFile("script/test/network/tcp_server.lua", -30);
	-- a server that listen on 8099 for all IP addresses
	NPL.StartNetServer("0.0.0.0", "8099");
end

function test_tcp_client()
	-- this only needs to called once to name a remote TCP server
	-- -30 is a predefined file id for web socket. this is needed on both client and server
	NPL.AddPublicFile("script/test/network/tcp_server.lua", -30);
	NPL.StartNetServer("0.0.0.0", "0");
	local server_nid = "myserver01";
	NPL.AddNPLRuntimeAddress({host = "127.0.0.1", port = "8099", nid = server_nid})
	

	local server_addr = string.format("%s:tcp", server_nid);

	-- connect with 2 seconds timeout
	-- if the first message begins with \0 or non-char character, we will automatically use a custom TCP connection
	if(NPL.activate_with_timeout(2, server_addr, "\0first_binary_message") == 0) then
		-- now let us send some arbitrary binary message
		for i = 1, 10 do
			NPL.activate(server_addr, "i=\0"..i);
		end
	end
end

--[[
    https://tools.ietf.org/html/rfc6455#page-6
GET /chat HTTP/1.1
Host: server.example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Origin: http://example.com
Sec-WebSocket-Protocol: chat, superchat
Sec-WebSocket-Version: 13
--]]
function test_websocket_client()
    local url = "http://localhost:8099/ajax/nplsocketsample?action=handshake&user_id=user12";
    local headers = {
        ["Host"] = "localhost:8099",
        ["Upgrade"] = "websocket",
        ["Connection"] = "Upgrade",
        ["Sec-WebSocket-Key"] = "dGhlIHNhbXBsZSBub25jZQ==",
        ["Origin"] = "http://localhost:8099",
        ["Sec-WebSocket-Version"] = "13",
    }
    System.os.GetUrl({
        url = url, 
        headers = headers, 
    }, 
    function(err, msg, data)		
        commonlib.echo("===============data");
        commonlib.echo(err);
        commonlib.echo(msg);
        commonlib.echo(data);

		NPL.activate(string.format("%s:tcp", "user12"), {"hello world"});
    end);
end



function test_websocket_client2()

    local function get_headers(statusline, headers)
	    local out = {};
        statusline = statusline or "GET / HTTP/1.1"
        out[#out+1] = statusline;
	    out[#out+1] = "\r\n";
	    if(headers) then
		    for name, value in pairs(headers) do
			    if(type(value) == "table") then
				    -- mostly for Set-Cookie
				    for i=1, #value do
					    out[#out+1] = format("%s: %s\r\n", name, value[i]);
				    end
			    else
				    out[#out+1] = format("%s: %s\r\n", name, value);
			    end
		    end
	    end
	    out[#out+1] = "\r\n";

        local s = table.concat(out);
        return s;
    end

    local url = "/ajax/nplsocketsample?action=handshake&user_id=user12";
    local headers = {
        ["Host"] = "localhost:8099",
        ["Upgrade"] = "websocket",
        ["Connection"] = "Upgrade",
        ["Sec-WebSocket-Key"] = "dGhlIHNhbXBsZSBub25jZQ==",
        ["Origin"] = "http://localhost:8099",
        ["Sec-WebSocket-Version"] = "13",
        ["method"] = "GET",
        ["url"] = url,
    }
    NPL.AddPublicFile("script/test/network/tcp_server.lua", -20);
	NPL.StartNetServer("0.0.0.0", "0");
	local server_nid = "myserver02";
	NPL.AddNPLRuntimeAddress({host = "127.0.0.1", port = "8099", nid = server_nid})
	

	local server_addr = string.format("%s:tcp", server_nid);

    if(NPL.activate_with_timeout(2, server_addr, "\0first_binary_message") == 0) then
        local s = get_headers(nil,headers);
        commonlib.echo("================s");
        commonlib.echo(s);
    	NPL.activate(server_addr, s);
	end


end
local function activate()
	local user_id = msg.tid or msg.nid;
	local binary_data = msg[1];
	echo("partial data received:"..binary_data);
	if(math.random() < 0.5) then
		-- this is how server can send a message back to client
		NPL.activate(format("%s:tcp", user_id), "replied"..binary_data);
	end
end
NPL.this(activate)