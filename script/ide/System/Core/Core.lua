--[[
Title: Core
Author(s): LiXizhi, 
Date: 2015/7/19
Desc: include core files (only some)
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Core/Core.lua");
------------------------------------------------------------
]]
-- tricky: all NPL.load in this file will be loaded after this file function is returned to prevent too deep call stack depth, on emscripten js. 
local IsRecursiveLoadFile = __rts__:GetField("IsRecursiveLoadFile", true);
__rts__:SetField("IsRecursiveLoadFile", false);

NPL.load("(gl)script/ide/ParaEngineExtension.lua");
NPL.load("(gl)script/ide/System/Util/Debug.lua");
NPL.load("(gl)script/ide/System/Core/Variable.lua");
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/System/Core/Event.lua");
NPL.load("(gl)script/ide/System/Windows/MouseEvent.lua");
NPL.load("(gl)script/ide/System/Windows/KeyEvent.lua");
NPL.load("(gl)script/ide/System/Core/Attribute.lua");
NPL.load("(gl)script/ide/System/Core/AttributeObject.lua");
NPL.load("(gl)script/ide/System/Core/Action.lua");
NPL.load("(gl)script/ide/System/Core/ActionGroup.lua");
NPL.load("(gl)script/ide/System/Core/DOM.lua");
NPL.load("(gl)script/ide/System/Core/Filters.lua");
NPL.load("(gl)script/ide/System/Core/Namespace.lua");
NPL.load("(gl)script/ide/System/Core/SceneContext.lua");
NPL.load("(gl)script/ide/System/Core/TableAttribute.lua");
NPL.load("(gl)script/ide/System/os/os.lua");
NPL.load("(gl)script/ide/System/Concurrent/Concurrent.lua");
NPL.load("(gl)script/ide/System/Core/Scene.lua");
NPL.load("(gl)script/ide/System/Core/SceneContextManager.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");

__rts__:SetField("IsRecursiveLoadFile", IsRecursiveLoadFile);