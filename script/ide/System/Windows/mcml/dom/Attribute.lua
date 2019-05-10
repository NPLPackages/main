--[[
Title: Attribute
Author(s): LiPeng
Date: 2019/5/9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/dom/Attribute.lua");
local Attribute = commonlib.gettable("System.Windows.mcml.dom.Attribute");
------------------------------------------------------------
]]

local Attribute = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.dom.Attribute"));

function Attribute:ctor()
	self.m_name = nil;
	self.m_value = nil;
end

function Attribute:init(name, value)
	self.m_name = name;
	self.m_value = value;
	return self;
end

function Attribute:Name()
	return self.m_name;
end

function Attribute:Value()
	return self.m_value;
end

function Attribute:SetValue(value)
	self.m_value = value;
end