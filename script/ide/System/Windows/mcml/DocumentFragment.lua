--[[
Title: document fragment element
Author(s): LiPeng
Date: 2019/2/22
Desc: it isn't a html tag.we use it when innerhtml
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/DocumentFragment.lua");
local DocumentFragment = commonlib.gettable("System.Windows.mcml.DocumentFragment");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
local DocumentFragment = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.DocumentFragment"));

DocumentFragment:Property("Name", "DocumentFragment");

function DocumentFragment:ctor()
	
end

function DocumentFragment:NodeType()
	return "DOCUMENT_FRAGMENT_NODE";
end
