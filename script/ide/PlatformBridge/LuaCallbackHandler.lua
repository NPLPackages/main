--[[
Title: lua调c++注册回调
Author(s): hyz
Date: 2022/4/27
Desc: 
Use Lib:
-------------------------------------------------------
local LuaCallbackHandler = NPL.load("(gl)script/ide/PlatformBridge/LuaCallbackHandler.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/commonlib.lua");

local selfPath = "(gl)script/ide/PlatformBridge/LuaCallbackHandler.lua"

local System = System or Map3DSystem
local LuaCallbackHandler = commonlib.gettable("System.LuaCallbackHandler")

function LuaCallbackHandler.init()
    if LuaCallbackHandler._inited then
        return
    end
    LuaCallbackHandler._inited = true
    
    LuaCallbackHandler._acc = 0
    LuaCallbackHandler._handlerMap = {}

    NPL.this(LuaCallbackHandler.onCallback)
end

--c++回调回来
function LuaCallbackHandler.onCallback()
    if not msg or not msg._callbackIdx then
        return
    end
    
    local idx = msg._callbackIdx
    local info = LuaCallbackHandler._handlerMap[idx]
    if info then
        if info.target==nil then
            info.callback(msg)
        else
            info.callback(info.target,msg)
        end
    end
end

--将回调函数包装一下，再传给c++方法
function LuaCallbackHandler.createHandler(callback,target)
    if callback==nil then
        return nil
    end
    LuaCallbackHandler._acc = LuaCallbackHandler._acc + 1
    LuaCallbackHandler._handlerMap[LuaCallbackHandler._acc] = {
        callback = callback,
        target = target,
    }

    return selfPath,LuaCallbackHandler._acc
end

LuaCallbackHandler.init()

return LuaCallbackHandler