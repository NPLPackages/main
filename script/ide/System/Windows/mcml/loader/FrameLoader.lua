--[[
Title: main frame load
Author(s): LiPeng
Date: 2019/3/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/loader/FrameLoader.lua");
local FrameLoader = commonlib.gettable("System.Windows.mcml.loader.FrameLoader");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/loader/SubFrameLoader.lua");
local SubFrameLoader = commonlib.gettable("System.Windows.mcml.loader.SubFrameLoader");
local FrameLoader = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.loader.FrameLoader"));

function FrameLoader:ctor()
	self.m_frame = nil;
	self.m_client = nil;
	self.m_subframeLoader = nil;
	self.m_isComplete = false;

	self.uiElement = nil
end

function FrameLoader:init(frame, client)
	self.m_frame = frame;
	self.m_client = client;
	self.m_subframeLoader = SubFrameLoader:new():init(frame);
	--self.uiElement = uiElement;

	return self;
end

function FrameLoader:Client()
	return self.m_client;
end

function FrameLoader:SubframeLoader()
	return self.m_subframeLoader;
end

function FrameLoader:Frame()
	return self.m_frame;
end

--function FrameLoader:Load(uiElement)
--	self.uiElement = uiElement
--	local size = LayoutSize:new();
--	if(uiElement) then
--		size = LayoutSize:new(uiElement:width(), uiElement:height());
--	end
--	local frameView = self.m_frame:CreateView(size);
--	frameView:SetUIElement(uiElement);
--	self.m_frame:Page():SetLayout(frameView);
--
--	return frameView;
--end

--function FrameLoader:LoadURL(url)
--	local o = {{name="html"}, name="document"};
--	local document = mcml:createFromXmlNode(o)
--	
--	local htmlNode = document:FirstChild();
--	htmlNode:AppendChild(self.mcmlNode);
--
--	document:SetFrame(self.m_mainFrame)
--	self.m_mainFrame:SetDocument(document);
--end