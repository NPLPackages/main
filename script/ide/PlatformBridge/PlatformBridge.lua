--[[
Title: lua调用平台代码
Author(s): hyz
Date: 2022/7/4
Desc: 
Use Lib:
-------------------------------------------------------
local PlatformBridge = NPL.load("(gl)script/ide/PlatformBridge/PlatformBridge.lua");
-------------------------------------------------------
]]

local PlatformBridge = NPL.export()

--获取设备信息
function PlatformBridge.getDeviceInfo()
    local out={};
    if not ParaMisc.LuaCallNative then
        return out
    end

    local ok, errinfo = pcall(function()
        local jsonStr = ParaMisc.LuaCallNative("getDeviceInfo")
        if(not NPL.FromJson(jsonStr, out)) then
            -- print("解析json失败","getDeviceInfo")
        end
    end)
    if not ok then
        out.errinfo = errinfo
    end
    return out
end

--获取应用信息
function PlatformBridge.getAppInfo()
    local out={};
    if not ParaMisc.LuaCallNative then
        return out
    end
    local ok, errinfo = pcall(function()
        local jsonStr = ParaMisc.LuaCallNative("getAppInfo")

        if(not NPL.FromJson(jsonStr, out)) then
            -- print("解析json失败","getDeviceInfo")
        end
    end)
    if not ok then
        out.errinfo = errinfo
    end
    return out
end

--移动端不同的发行渠道
function PlatformBridge.getMobileChannelId()
    if not ParaMisc.LuaCallNative then
        return nil
    end
    local channelId = ParaMisc.LuaCallNative("getChannelId") --平台代码待实现
    if channelId=="" then
        return nil 
    end
    return channelId
end


function PlatformBridge.call_native(key,params,onCallback)
    if not ParaMisc.LuaCallNative then
        return nil
    end
    local luafile, callbackIdx;
    if type(onCallback)=="function" then
        luafile, callbackIdx = LuaCallbackHandler.createHandler(function(msg)
            if onCallback then
                onCallback(msg)
            end
        end)
    end
    local jsonParam = ""
    if type(params)=="table" then
        jsonParam = NPL.ToJson(params)
    elseif params~=nil then
        jsonParam = tostring(params)
    end
    local ret = ParaMisc.LuaCallNative({
        key = key,
        jsonParam = jsonParam,
        luafile = luafile,
        callbackIdx = callbackIdx
    })

    return ret;
end
--[[
    {
        x = 400,y = 100,
        width = 1520,
        height = 880,
        alpha = 0.95,
        url = "www.baidu.com",
        ignoreCloseWhenClickBack= true,
        withTouchMask = true,
    }
]]
function PlatformBridge.open_webview(params)
    if params==nil or params.url==nil then
        return
    end
    local webviewId = PlatformBridge.call_native("show_weview",params)
    return webviewId
end

function PlatformBridge.close_webview(webviewId)
    PlatformBridge.call_native("close_webview",{
        webviewId = webviewId
    })
end

function PlatformBridge.setVisible_webview(webviewId,visible)
    PlatformBridge.call_native("setVisible_webview",{
        webviewId = webviewId,
        visible = visible,
    })
end

--同意了用户协议和隐私政策
function PlatformBridge.onAgreeUserPrivacy()
    PlatformBridge.call_native("onAgreeUserPrivacy")
end