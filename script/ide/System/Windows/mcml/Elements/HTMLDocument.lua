--[[
Title: document node, the root of dom tree
Author(s): LiPeng
Date: 2019/3/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/HTMLDocument.lua");
local HTMLDocument = commonlib.gettable("System.Windows.mcml.Elements.HTMLDocument")
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/dom/Document.lua");

local HTMLDocument = commonlib.inherit(commonlib.gettable("System.Windows.mcml.dom.Document"), commonlib.gettable("System.Windows.mcml.Elements.HTMLDocument"));
HTMLDocument:Property({"class_name", "HTMLDocumentr"});

function HTMLDocument:ctor()

end
