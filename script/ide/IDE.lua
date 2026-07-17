--[[
Title: All common libraries in IDE
Author:LiXizhi
Date : 2008.10.25
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/IDE.lua");
-------------------------------------------------------
]]

-- tricky: all NPL.load in this file will be loaded after this file function is returned to prevent too deep call stack depth, on emscripten js. 
local IsRecursiveLoadFile = __rts__:GetField("IsRecursiveLoadFile", true);
__rts__:SetField("IsRecursiveLoadFile", false);

--
-- base IDE lib
--
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included
NPL.load("(gl)script/ide/common_control.lua");

NPL.load("(gl)script/sqlite/sqlite3.lua");
NPL.load("(gl)script/ide/TreeView.lua");
NPL.load("(gl)script/ide/property_control.lua");
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");

NPL.load("(gl)script/ide/Debugger/NPLProfiler.lua"); -- perf
NPL.load("(gl)script/ide/Locale.lua");
NPL.load("(gl)script/lang/lang.lua"); -- default IDE language localizations: this may be removed
NPL.load("(gl)script/ide/gui_helper.lua");
NPL.load("(gl)script/ide/headon_speech.lua");
NPL.load("(gl)script/ide/event_mapping.lua");
NPL.load("(gl)script/ide/action_table.lua");
NPL.load("(gl)script/ide/os.lua");
NPL.load("(gl)script/ide/object_editor.lua");
NPL.load("(gl)script/ide/sandbox.lua");
NPL.load("(gl)script/ide/ParaEngineExtension.lua"); -- NPLExtension also included within
NPL.load("(gl)script/ide/AudioEngine/AudioEngine.lua");
NPL.load("(gl)script/ide/System/Core/Core.lua");
NPL.load("(gl)script/ide/System/Windows/Window.lua");

--
-- mcml related
--
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/PageCtrl.lua");


__rts__:SetField("IsRecursiveLoadFile", IsRecursiveLoadFile);