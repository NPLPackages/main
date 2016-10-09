--[[
Author: Li,Xizhi
Date: 2008-11-24
Desc: testing lib-curl and NPL.AppendURLRequest
Use NPL.AppendURLRequest if you want asynchronous URL request interface. 

More information, please see http://curl.haxx.se/libcurl/
-----------------------------------------------
NPL.load("(gl)script/test/TestCurl.lua");
-----------------------------------------------
]]

-- call this function to open the cUrl. This is usually loaded by default. 
luaopen_cURL();

--[[
Easy interface
	cURL.easy_init() 
returns a new easy handle. 
	cURL.version_info() 
returns a table containing version info and features/protocols sub table 
	easy:escape(string) 
return URL encoded string 
	easy:unescape(string) 
return URL decoded string 
	easy:setopt*(value) 
libcurl properties an options are mapped to individual functions: 
	easy:setopt_url(string) 
	easy:setopt_verbose(number) 
	easy:setopt_proxytype(string) 
	easy:setopt_share(share) (See: share) 
... 
easy:perform(table) 
Perform the transfer as described in the options, using an optional callback table.The callback table indices are named after the equivalent cURL callbacks: 
	writefunction = function(str) 
	readfunction = function() 
	headerfunction = function(str) 
easy:post(table) 
Prepare a multipart/formdata post. The table indices are named after the form fields and should map to string values:

	{field1 = value1,
	 field2 = value1}
or more generic descriptions in tables:

{field1 = {file="/tmp/test.txt",
           type="text/plain"},
{field2 = {file="dummy.html",
           data="<html><bold>bold</bold></html>,
           type="text/html"}}

]]
-- Example 1: Fetch the example.com homepage
-- %TESTCASE{"curl_test_easy_simple_get", func = "curl_test_easy_simple_get", input = {url="http://www.example.com/"},}%
function curl_test_easy_simple_get(input)
	local url = input.url or "http://www.example.com/";
	
	log("fetching "..url.."\n")
	local c = cURL.easy_init()
	-- setup url
	c:setopt_url(url)
	-- perform, invokes callbacks
	c:perform({writefunction = function(str) 
			log("-->:"..str.."\r\n")
		 end})
	log("\r\nDone!\r\n")
end

--  Example 2: "On-The-Fly" file upload
-- %TESTCASE{"curl_test_easy_fileupload", func = "curl_test_easy_fileupload", input = {url="ftp://name:password@192.168.0.200/file.dat"},}%
function curl_test_easy_fileupload(input)
	local url = input.url or "ftp://name:password@192.168.0.200/file.dat";
	
	log("file upload"..url.."\n")
	local c = cURL.easy_init()
	
	c:setopt_url(url)
	c:setopt_upload(1)
	
	local count=0
	c:perform({readfunction=function(n) 
				   count = count + 1
				   if (count < 10)  then
					  return "Line " .. count .. "\n"
				   end
				   return nil
				end})
	
	log("\r\nFileupload done!\r\n")
end

-- Example 3: "Posting" data
-- %TESTCASE{"curl_test_easy_PostMultiPart", func = "curl_test_easy_PostMultiPart", input = {url="http://localhost"},}%
function curl_test_easy_PostMultiPart(input)
	local url = input.url or "http://localhost";
	
	log("post "..url.."\n")
	local c = cURL.easy_init()
	
	c:setopt_url(url)
	local postdata = {  
	   -- post file from filesystem
	   name = {file="readme.txt",
		   type="text/plain"},
	   -- post file from data variable
	   name2 = {file="dummy.html",
			data="<html><bold>bold</bold></html>",
			type="text/html"}
	}
	c:post(postdata)
	c:perform()
	
	log("\r\nDone!\r\n")
end

--[[
Multi interface

	cURL.multi_init() 
		returns a new multi handle 
	multi:add_handle(easy) 
		add an easy handle to a multi session 
	multi:perform() 
		returns an iterator function that, each time it is called, returns the next data, type and corresponding easy handle:

data: 
	data returned by the cURL library 
type 
	type of data returned ("header" or "data") 
easy 
	corresponding easy handle of the data returned 
]]
-- Example 1: "On-The-Fly" XML parsing
-- %TESTCASE{"curl_test_multi_parsing", func = "curl_test_multi_parsing", input = {url="http://www.lua.org/news.rss"},}%
function curl_test_multi_parsing(input)
	local url = input.url or "http://www.lua.org/news.rss";
	
	-- create and setup easy handle
	local c = cURL.easy_init()
	c:setopt_url(url)

	local m = cURL.multi_init()
	m:add_handle(c)

	log("Begin\n")
	
	for data,type, easy in m:perform() do 
		-- ign "header"
		if (type == "data") then 
			commonlib.echo(data)
		elseif (type == "header") then 	  
			commonlib.echo(data)
		else
			log("--> polling\n");
		end
	end

	log("Done!\n")

end


--[[
Share interface
	cURL.share_init() 
returns a new share handle 
	share:setopt_share(string) 
		specifies the type of data that should be shared ("DNS" or "COOKIE") 
		Since Lua is single-threaded, there is no mapping for the lock options.
]]
-- %TESTCASE{"curl_test_share_cookie", func = "curl_test_share_cookie", input = {url="http://targethost/login.php?username=foo&password=bar", url2="http://targethost/download.php?id=test"},}%
function curl_test_share_cookie(input)
	local url = input.url or "http://targethost/login.php?username=foo&password=bar";
	local url2 = input.url2 or "http://targethost/download.php?id=test";
	
	-- create share handle (share COOKIE and DNS Cache)
	local s = cURL.share_init()
	s:setopt_share("COOKIE")
	s:setopt_share("DNS")

	-- create first easy handle to do the login
	local c = cURL.easy_init()
	c:setopt_share(s)
	c:setopt_url("http://targethost/login.php?username=foo&password=bar")

	-- create second easy handle to do the download
	local c2 = cURL.easy_init()
	c2:setopt_share(s)
	c2:setopt_url("http://targethost/download.php?id=test")

	--login
	c:perform()

	--download			
	c2:perform()

	log("Done!\n")
end

--[[ this is the msg.code return code. 
typedef enum {
  CURLE_OK = 0,
  CURLE_UNSUPPORTED_PROTOCOL,    /* 1 */
  CURLE_FAILED_INIT,             /* 2 */
  CURLE_URL_MALFORMAT,           /* 3 */
  CURLE_OBSOLETE4,               /* 4 - NOT USED */
  CURLE_COULDNT_RESOLVE_PROXY,   /* 5 */
  CURLE_COULDNT_RESOLVE_HOST,    /* 6 */
  CURLE_COULDNT_CONNECT,         /* 7 */
  CURLE_FTP_WEIRD_SERVER_REPLY,  /* 8 */
  CURLE_REMOTE_ACCESS_DENIED,    /* 9 a service was denied by the server
                                    due to lack of access - when login fails
                                    this is not returned. */
  CURLE_OBSOLETE10,              /* 10 - NOT USED */
  CURLE_FTP_WEIRD_PASS_REPLY,    /* 11 */
  CURLE_OBSOLETE12,              /* 12 - NOT USED */
  CURLE_FTP_WEIRD_PASV_REPLY,    /* 13 */
  CURLE_FTP_WEIRD_227_FORMAT,    /* 14 */
  CURLE_FTP_CANT_GET_HOST,       /* 15 */
  CURLE_OBSOLETE16,              /* 16 - NOT USED */
  CURLE_FTP_COULDNT_SET_TYPE,    /* 17 */
  CURLE_PARTIAL_FILE,            /* 18 */
  CURLE_FTP_COULDNT_RETR_FILE,   /* 19 */
  CURLE_OBSOLETE20,              /* 20 - NOT USED */
  CURLE_QUOTE_ERROR,             /* 21 - quote command failure */
  CURLE_HTTP_RETURNED_ERROR,     /* 22 */
  CURLE_WRITE_ERROR,             /* 23 */
  CURLE_OBSOLETE24,              /* 24 - NOT USED */
  CURLE_UPLOAD_FAILED,           /* 25 - failed upload "command" */
  CURLE_READ_ERROR,              /* 26 - couldn't open/read from file */
  CURLE_OUT_OF_MEMORY,           /* 27 */
  /* Note: CURLE_OUT_OF_MEMORY may sometimes indicate a conversion error
           instead of a memory allocation error if CURL_DOES_CONVERSIONS
           is defined
  */
  CURLE_OPERATION_TIMEDOUT,      /* 28 - the timeout time was reached */
  CURLE_OBSOLETE29,              /* 29 - NOT USED */
  CURLE_FTP_PORT_FAILED,         /* 30 - FTP PORT operation failed */
  CURLE_FTP_COULDNT_USE_REST,    /* 31 - the REST command failed */
  CURLE_OBSOLETE32,              /* 32 - NOT USED */
  CURLE_RANGE_ERROR,             /* 33 - RANGE "command" didn't work */
  CURLE_HTTP_POST_ERROR,         /* 34 */
  CURLE_SSL_CONNECT_ERROR,       /* 35 - wrong when connecting with SSL */
  CURLE_BAD_DOWNLOAD_RESUME,     /* 36 - couldn't resume download */
  CURLE_FILE_COULDNT_READ_FILE,  /* 37 */
  CURLE_LDAP_CANNOT_BIND,        /* 38 */
  CURLE_LDAP_SEARCH_FAILED,      /* 39 */
  CURLE_OBSOLETE40,              /* 40 - NOT USED */
  CURLE_FUNCTION_NOT_FOUND,      /* 41 */
  CURLE_ABORTED_BY_CALLBACK,     /* 42 */
  CURLE_BAD_FUNCTION_ARGUMENT,   /* 43 */
  CURLE_OBSOLETE44,              /* 44 - NOT USED */
  CURLE_INTERFACE_FAILED,        /* 45 - CURLOPT_INTERFACE failed */
  CURLE_OBSOLETE46,              /* 46 - NOT USED */
  CURLE_TOO_MANY_REDIRECTS ,     /* 47 - catch endless re-direct loops */
  CURLE_UNKNOWN_TELNET_OPTION,   /* 48 - User specified an unknown option */
  CURLE_TELNET_OPTION_SYNTAX ,   /* 49 - Malformed telnet option */
  CURLE_OBSOLETE50,              /* 50 - NOT USED */
  CURLE_PEER_FAILED_VERIFICATION, /* 51 - peer's certificate or fingerprint
                                     wasn't verified fine */
  CURLE_GOT_NOTHING,             /* 52 - when this is a specific error */
  CURLE_SSL_ENGINE_NOTFOUND,     /* 53 - SSL crypto engine not found */
  CURLE_SSL_ENGINE_SETFAILED,    /* 54 - can not set SSL crypto engine as
                                    default */
  CURLE_SEND_ERROR,              /* 55 - failed sending network data */
  CURLE_RECV_ERROR,              /* 56 - failure in receiving network data */
  CURLE_OBSOLETE57,              /* 57 - NOT IN USE */
  CURLE_SSL_CERTPROBLEM,         /* 58 - problem with the local certificate */
  CURLE_SSL_CIPHER,              /* 59 - couldn't use specified cipher */
  CURLE_SSL_CACERT,              /* 60 - problem with the CA cert (path?) */
  CURLE_BAD_CONTENT_ENCODING,    /* 61 - Unrecognized transfer encoding */
  CURLE_LDAP_INVALID_URL,        /* 62 - Invalid LDAP URL */
  CURLE_FILESIZE_EXCEEDED,       /* 63 - Maximum file size exceeded */
  CURLE_USE_SSL_FAILED,          /* 64 - Requested FTP SSL level failed */
  CURLE_SEND_FAIL_REWIND,        /* 65 - Sending the data requires a rewind
                                    that failed */
  CURLE_SSL_ENGINE_INITFAILED,   /* 66 - failed to initialise ENGINE */
  CURLE_LOGIN_DENIED,            /* 67 - user, password or similar was not
                                    accepted and we failed to login */
  CURLE_TFTP_NOTFOUND,           /* 68 - file not found on server */
  CURLE_TFTP_PERM,               /* 69 - permission problem on server */
  CURLE_REMOTE_DISK_FULL,        /* 70 - out of disk space on server */
  CURLE_TFTP_ILLEGAL,            /* 71 - Illegal TFTP operation */
  CURLE_TFTP_UNKNOWNID,          /* 72 - Unknown transfer ID */
  CURLE_REMOTE_FILE_EXISTS,      /* 73 - File already exists */
  CURLE_TFTP_NOSUCHUSER,         /* 74 - No such user */
  CURLE_CONV_FAILED,             /* 75 - conversion failed */
  CURLE_CONV_REQD,               /* 76 - caller must register conversion
                                    callbacks using curl_easy_setopt options
                                    CURLOPT_CONV_FROM_NETWORK_FUNCTION,
                                    CURLOPT_CONV_TO_NETWORK_FUNCTION, and
                                    CURLOPT_CONV_FROM_UTF8_FUNCTION */
  CURLE_SSL_CACERT_BADFILE,      /* 77 - could not load CACERT file, missing
                                    or wrong format */
  CURLE_REMOTE_FILE_NOT_FOUND,   /* 78 - remote file not found */
  CURLE_SSH,                     /* 79 - error from the SSH layer, somewhat
                                    generic so the error message will be of
                                    interest when this has happened */

  CURLE_SSL_SHUTDOWN_FAILED,     /* 80 - Failed to shut down the SSL
                                    connection */
  CURLE_AGAIN,                   /* 81 - socket is not ready for send/recv,
                                    wait till it's ready and try again (Added
                                    in 7.18.2) */
  CURLE_SSL_CRL_BADFILE,         /* 82 - could not load CRL file, missing or
                                    wrong format (Added in 7.19.0) */
  CURLE_SSL_ISSUER_ERROR,        /* 83 - Issuer check failed.  (Added in
                                    7.19.0) */
  CURL_LAST /* never use! */
} CURLcode;
]]
-- NPL curl interface
-- %TESTCASE{"NPL_test_url_REST", func = "NPL_test_url_REST", input = {urls="www.paraengine.com;www.google.com;", },}%
function NPL_test_url_REST(input)
	local urls = input.urls
	log("begin!\n")
	
	local url
	for url in string.gfind(urls, "([^;]+)") do
		commonlib.log("get url --> %s\n", url)
		
		NPL.AppendURLRequest(url, "NPL_test_url_REST_callback()", nil, "r");
	end
	log("Done!\n")
end

-- testing url with HTTP GET params
-- %TESTCASE{"NPL_test_url_HTTP_GET_params", func = "NPL_test_url_HTTP_GET_params", input = {urls="http://api.test.pala5.cn/Auth/AuthUser.ashx", name1="username", value1="LiXizhi2", name2="password", value2="1234567", name3="", value3=""},}%
function NPL_test_url_HTTP_GET_params(input)
	local urls = input.urls
	log("begin!\n")
	local url
	for url in string.gfind(urls, "([^;]+)") do
		commonlib.log("get url --> %s\n", url)
		-- HTTP GET is used. because the input msg is an array of name, value in sequence. 
		NPL.AppendURLRequest(url, "NPL_test_url_REST_callback()", 
			{input.name1, input.value1, input.name2, input.value2,input.name3, input.value3,}, "r");
	end
	log("Done!\n")
end

-- testing url with HTTP POST
-- %TESTCASE{"NPL_test_url_HTTP_POST_params", func = "NPL_test_url_HTTP_POST_params", input = {urls="http://api.test.pala5.cn/Auth/AuthUser.ashx", username="LiXizhi2", password="1234567", format="1"},}%
function NPL_test_url_HTTP_POST_params(input)
	local urls = input.urls
	log("begin!\n")
	local url
	for url in string.gfind(urls, "([^;]+)") do
		commonlib.log("get url --> %s\n", url)
		-- HTTP POST is used. because the input msg contains name value pairs.
		NPL.AppendURLRequest(url, "NPL_test_url_REST_callback()", input, "r");
	end
	log("Done!\n")
end

-- testing url with HTTP POST
-- %TESTCASE{"NPL_test_url_HTTPS_POST_params", func = "NPL_test_url_HTTPS_POST_params", input = {urls="http://api.test.pala5.cn/Auth/AuthUser.ashx", username="LiXizhi2", password="1234567", format="1"},}%
function NPL_test_url_HTTPS_POST_params(input)
	local urls = "https://developer.mozilla.org/en-US/docs/HTTP_access_control";
	log("begin!\n")
	local url
	for url in string.gfind(urls, "([^;]+)") do
		commonlib.log("get url --> %s\n", url)
		-- HTTP POST is used. because the input msg contains name value pairs.
		NPL.AppendURLRequest(url, "NPL_test_url_REST_callback()", input, "r");
	end
	log("Done!\n")
end


-- testing url with HTTP POST File(upload)
-- %TESTCASE{"NPL_test_url_HTTP_POST_file", func = "NPL_test_url_HTTP_POST_file", input = {urls="http://api.test.pala5.cn/Auth/AuthUser.ashx", file="config/config.txt", type="text/plain", data="blablabla"},}%
function NPL_test_url_HTTP_POST_file(input)
	local urls = input.urls
	log("begin!\n")
	for url in string.gfind(urls, "([^;]+)") do
		commonlib.log("get url --> %s\n", url)
		-- HTTP POST File is used. because the input msg contains name value pairs.
		NPL.AppendURLRequest(url, "NPL_test_url_REST_callback()", {
			otherfields="anything", 
			thisisafile = {file=input.file, type=input.type, data=input.data}
		}, "r");
	end
	log("Done!\n")
end

-- it will send as "multipart/form-data"
function NPL_test_url_HTTP_POST_BinaryFile()
	-- "r" means using the default rest thread to send the request. 
	NPL.AppendURLRequest("http://127.0.0.1/upload", "NPL_test_url_REST_callback()", {
		key="this is a key", 
		["x:customNameABC"] = "some custom data",
		token="this is token",
		crc32="1234567",
		file = {file="A_binary_file.bin", type="application/octet-stream", data="binary data:\0\0\0 end of file"},
	}, "r");
end

-- msg = {header, data, code}
function NPL_test_url_REST_callback()
	if(msg.code ~= 0) then
		log("-->error occurs\n")
	else	
		log("-->succeeded\n")
	end
	commonlib.log("-->code:");
	commonlib.log(msg.code);
	commonlib.log("  HTTP/FTP status code:");
	commonlib.log(msg.rcode);
	commonlib.log("\nheader:\n");
	commonlib.log(msg.header);
	commonlib.log("\ndata:\n");
	commonlib.log(msg.data);
end

-- testing HTTP texture. 
-- %TESTCASE{"NPL_test_url_HTTP_Texture", func = "NPL_test_url_HTTP_Texture", input = {url="http://www.paraengine.com/images/index_01.png", },}%
function NPL_test_url_HTTP_Texture(input)
	local url = input.url
	
	_this = ParaUI.GetUIObject("NPL_test_url_HTTP_Texture");
	if(_this:IsValid() == false) then
		_this = ParaUI.CreateUIObject("container", "NPL_test_url_HTTP_Texture", "_lt", 100, 100, 150, 300);
		_this:AttachToRoot();
	end
	_this.background = url;
	log("Done! Check the popup UI control \n")
end

-- testing auto sync texture. when url is not found on local disk, we will try to locate it from our server. 
-- %TESTCASE{"NPL_test_url_AutoSync_Texture", func = "NPL_test_url_AutoSync_Texture", input = {AssetServer = "http://asset.test.pala5.cn/", url="Texture/tileset/generic/soil.dds", },}%
function NPL_test_url_AutoSync_Texture(input)
	ParaAsset.SetAssetServerUrl(input.AssetServer);
	
	local url = input.url
	
	_this = ParaUI.GetUIObject("NPL_test_url_AutoSync_Texture");
	if(_this:IsValid() == false) then
		_this = ParaUI.CreateUIObject("container", "NPL_test_url_AutoSync_Texture", "_lt", 100, 100, 150, 300);
		_this:AttachToRoot();
	end
	_this.background = url;
	log("Done! Check the popup UI control \n")
end

-- suppose the remote file server uses the same system default encoding as the client computer, we can do a post like below. 
function NPL_test_autosync_mesh_model()
	local url = commonlib.Encoding.Utf8ToDefault("http://www.paraengine.com/model/05plants/03shrub/ÂÌÉ«¹àÄ¾1_a.x")
	NPL.AppendURLRequest(url, "commonlib.echo(msg);", nil, "r");
end

-- testing url get with many at the same time: the speed is very fast in the background mode.  
-- %TESTCASE{"NPL_test_url_HTTP_POST_Many", func = "NPL_test_url_HTTP_POST_Many", input = {urls="http://api.test.pala5.cn/Auth/AuthUser.ashx", username="LiXizhi2", password="1234567", format="1", iterations=30},}%
function NPL_test_url_HTTP_POST_Many(input)
	local urls = input.urls
	log("begin!\n")
	local iterations = input.iterations or 1;
	
	local i
	for i=1, iterations do 
		commonlib.log("--->iteration %d\n", i);
		local url
		for url in string.gfind(urls, "([^;]+)") do
			commonlib.log("get url --> %s\n", url)
			-- HTTP POST is used. because the input msg contains name value pairs.
			NPL.AppendURLRequest(url, "NPL_test_url_REST_callback()", input, "r");
		end
	end
	log("Done!\n")
end

-- testing url get with many at the same time and write to local server at the same time. 
-- %TESTCASE{"NPL_test_url_HTTP_POST_localserver", func = "NPL_test_url_HTTP_POST_localserver", input = {iterations=20},}%
function NPL_test_url_HTTP_POST_localserver(input)
	local urls = input.urls
	log("begin!\n")
	local iterations = input.iterations or 1;
	
	local i
	for i=1, iterations do 
		commonlib.log("--->iteration %d\n", i);
		paraworld.users.getInfo({nids="001", fields="userid,nid,username", cache_policy="access plus 0 day"}, "test"..i, function(msg)
			commonlib.echo(msg);
		end);
	end
	log("Done!\n")
end

-- testing url get with many at the same time and read from local server at the same time. 
-- %TESTCASE{"NPL_test_url_localserver_readonly", func = "NPL_test_url_localserver_readonly", input = {iterations=50},}%
function NPL_test_url_localserver_readonly(input)
	local urls = input.urls
	commonlib.log("begin! %s\n", ParaGlobal.timeGetTime())
	local iterations = input.iterations or 1;
	
	local i
	for i=1, iterations do 
		commonlib.log("--->iteration %d\n", i);
		paraworld.users.getInfo({nids="001", fields="userid,nid,username", cache_policy="access plus 1 year"}, "test"..i, function(msg)
			commonlib.echo(msg);
		end);
	end
	commonlib.log("Done! %s\n", ParaGlobal.timeGetTime())
end