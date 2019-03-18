--[[
Title: main frame load
Author(s): LiPeng
Date: 2019/3/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/loader/FrameLoaderClient.lua");
local FrameLoaderClient = commonlib.gettable("System.Windows.mcml.loader.FrameLoaderClient");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/page/Frame.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
local LayoutSize = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local Frame = commonlib.gettable("System.Windows.mcml.page.Frame");
local FrameLoaderClient = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.loader.FrameLoaderClient"));

function FrameLoaderClient:ctor()
	self.m_frame = nil;
	self.m_page = nil;

	self.uiElement = nil
end

function FrameLoaderClient:init(uiElement, page)
	self.uiElement = uiElement;
	self.m_page = page;
	return self;
end

function FrameLoaderClient:Frame()
	return self.m_frame;
end

function FrameLoaderClient:SetFrame(frame)
	self.m_frame = frame;
end


--PassRefPtr<WebCore::Frame> FrameLoaderClient::createFrame(const WebCore::KURL& url, const WTF::String& name, WebCore::HTMLFrameOwnerElement* ownerElement, const WTF::String& referrer, bool allowsScrolling, int marginWidth, int marginHeight)
function FrameLoaderClient:CreateSubFrame(url, name, ownerElement)
	echo("FrameLoaderClient:CreateSubFrame")
	ownerElement:PrintNodeInfo();
	local page = ownerElement:FramePage();
    local loader = FrameLoaderClient:new():init(nil, page);
	local childFrame = Frame.Create(page, ownerElement, loader);
	loader:SetFrame(childFrame);
--	 m_frame->tree()->appendChild(childFrame);
--    childFrame->tree()->setName(name);
    --childFrame->init();
	--childFrame:Loader():Client():Load();

	return childFrame
end

function FrameLoaderClient:Load()
	local uiElement = self.uiElement;
	local size = LayoutSize:new();
	if(uiElement) then
		size = LayoutSize:new(uiElement:width(), uiElement:height());
	end
	local frameView = self.m_frame:CreateView(size);
	frameView:SetUIElement(uiElement);
	self.m_frame:Page():SetLayout(frameView);

	return frameView;
end