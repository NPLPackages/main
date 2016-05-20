--[[
Title: Error code
Author(s): LiXizhi, 
Date: 2016/5/11
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Database/ErrorCode.lua");
local ErrorCode = commonlib.gettable("System.Database.ErrorCode");
------------------------------------------------------------
]]
local ErrorCode = commonlib.inherit(nil, commonlib.gettable("System.Database.ErrorCode"));

ErrorCode.ok = nil;
ErrorCode.error = 1;
ErrorCode.queue_full = 2;


