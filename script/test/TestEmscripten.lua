
print("========Test EMSCRIPTEN=========11")

NPL.AddNPLRuntimeAddress({host = "127.0.0.1", port = "9110", nid = "__emscripten__"});

NPL.AddPublicFile("script/test/TestEmscripten.lua", -30);

local address = string.format("(%s)%s:%s", "gl", "__emscripten__", "script/test/TestEmscripten.lua");

local intervals = {300, 500, 100, 1000, 1000, 1000, 1000}; -- intervals to try
local try_count = 0;
local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
    try_count = try_count + 1;
    if(NPL.activate(address, {key = "hello world"}) ~= 0) then
        if(intervals[try_count]) then
            timer:Change(intervals[try_count], nil);
        else
            print("----------------connenct failed--------------------------")
        end	
    else
        print("----------------connenct success--------------------------")
    end
end});

local function activate()
    print("========================1221")
    commonlib.echo(msg);
end

NPL.this(activate)

mytimer:Change(10, nil);

-- function KpChatChannel.PreloadSocketIOUrl(callback)
