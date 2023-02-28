--[[
Author: wxa
Date: 2020-10-26
Desc: Promise 
-----------------------------------------------
local Promise = NPL.load("script/ide/System/UI/Window/Api/Promise.lua");
-----------------------------------------------

local promise = Promise:new():Init(function(resolve, reject)

end);
]]

local Promise = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Promise:Property("State", "pending");  -- 状态 resolved  rejected
Promise:Property("Result", nil);       -- 结果

local function IsPormise(obj)
    return type(obj) == "table" and obj.isa and obj:isa(Promise);
end

function Promise:ctor()
    self:SetState("pending");

    self.state_callback = nil;
end

function Promise:Init(callback)
    if (type(callback) ~= "function") then error("Promise:Init(callback) 参数 callback 必须为函数") end

    local function promise(state, data)
        if (self:GetState() ~= "pending") then return end
        self:SetResult(data);
        self:SetState(state);
        if (type(self.state_callback) == "function") then self.state_callback(state, data) end
    end

    local ok, errinfo = pcall(function()
        callback(function(data)
            -- resolved function
            promise("resolved", data);
        end, function(data)
            -- rejected function
            promise("rejected", data);
        end);
    end);
    if (not ok) then promise("rejected", errinfo) end

    return self;
end

function Promise:SetStateCallBack(typ, callback)
    return Promise:new():Init(function(resolve, reject)
        self.state_callback = function(state, data)
            if (typ == "then" and state == "rejected") then
                return reject(data);
            elseif (typ == "catch" and state == "resolved") then
                return resolve(data); 
            end

            if (type(callback) == "function") then 
                local ok, errinfo = pcall(function()
                    data = callback(data);
                end);
                if (not ok) then return reject(errinfo) end
            end

            if (IsPormise(data)) then
                -- 若结果为 Promise 则等待
                result:Then(function(resolve_data)
                    resolve(resolve_data);
                end):Catch(function(reject_data)
                    reject(reject_data);
                end);
            else
                resolve(data);
            end
        end
    end);
end

function Promise:Then(callback)
    if (type(callback) ~= "function") then error("Promise:Then(callback) 参数 callback 必须为函数") end

    if (self:GetState() == "resolved") then return Promise.Resolve(callback(self:GetResult())) end

    return self:SetStateCallBack("then", callback);
end

function Promise:Catch(callback)
    if (type(callback) ~= "function") then error("Promise:Catch(callback) 参数 callback 必须为函数") end

    if (self:GetState() == "rejected") then return callback(self:GetResult()) end

    return self:SetStateCallBack("catch", callback);
end

function Promise.Resolve(data)
    if (IsPormise(data)) then return data end

    local promise = Promise:new();
    promise:SetResult(data);
    promise:SetState("resolved");

    return promise;
end

function Promise.Reject(data)
    if (IsPormise(data)) then return data end

    local promise = Promise:new();
    promise:SetResult(data);
    promise:SetState("rejected");
    
    return promise;
end

function Promise:All(list)
    if (type(list) ~= "table") then error("Promise:All(list) 参数 list 必须为列表") end

    local results, states = {}, {};
    local count = #list;
    for i = 1, count do
        if (not IsPormise(list[i])) then
            list[i] = Promise.Resolve(list[i]);
        end
    end

    return Promise:new():Init(function(resolve, reject)
        for i = 1, count do
            (function(index)
                local p = list[index];
                p:Then(function(data)
                    results[index] = data;
                    states[index] = true;
                    for i = 1, count do
                        if (not states[i]) then return end
                    end
                    resolve(results);
                end):Catch(function(data)
                    reject(data);
                end);
            end)(i);
        end
    end);
end

function Promise:Race(list)
    if (type(list) ~= "table") then error("Promise:Race(list) 参数 list 必须为列表") end

    local count = #list;
    for i = 1, count do
        if (not IsPormise(list[i])) then
            list[i] = Promise.Resolve(list[i]);
        end
    end

    return Promise:new():Init(function(resolve, reject)
        for i = 1, count do
            list[i]:Then(function(data)
                resolve(data);
            end):Catch(function(data)
                reject(data);
            end);
        end
    end);
end


function Promise.Test()
    local promise = Promise:new():Init(function(resolve, reject)
        commonlib.TimerManager.SetTimeout(function()  
            reject("hello world");
            -- resolve("hello world");
        end, 2000);
    end):Then(function(data)
        print("==============1", data);
        return "this is a test"
    end):Then(function(data)
        print("==============2", data);
    end):Catch(function(errinfo)
        print("==============3", errinfo);
    end);
end