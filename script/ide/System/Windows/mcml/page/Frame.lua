--[[
Title: Frame
Author(s): LiPeng
Date: 2019/3/12
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/page/Frame.lua");
local Frame = commonlib.gettable("System.Windows.mcml.page.Frame");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/ScrollView.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/PaintInfo.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntPoint.lua");
NPL.load("(gl)script/ide/System/Windows/Application.lua");
NPL.load("(gl)script/ide/System/Core/Event.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/page/FrameView.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/loader/FrameLoader.lua");
local FrameLoader = commonlib.gettable("System.Windows.mcml.loader.FrameLoader");
local FrameView = commonlib.gettable("System.Windows.mcml.page.FrameView");
local Event = commonlib.gettable("System.Core.Event");
local Application = commonlib.gettable("System.Windows.Application");
local Point = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");
local PaintInfo = commonlib.gettable("System.Windows.mcml.layout.PaintInfo");
local ScrollView = commonlib.gettable("System.Windows.mcml.platform.ScrollView");
local LayoutSize = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");

local LayoutRect = Rect;

local Frame = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.page.Frame"));

function Frame:ctor()
	self.m_page = nil;
	self.m_view = nil;
	self.m_doc = nil;
	-- HTMLFrameOwnerElement* m_ownerElement;
	self.m_ownerElement = nil;
--	self.m_eventHandler = nil;
--	self.m_script = nil;
--	self.m_domWindow = nil;
--	self.m_treeNode = nil;

	self.m_loader = nil;

	self.m_isDisconnected = false;
end

function Frame:init(page, ownerElement, client)
	self.m_page = page;
	self.m_ownerElement = ownerElement;
	self.m_loader = FrameLoader:new():init(self, client);
	if(ownerElement) then
		self.m_ownerElement:SetContentFrame(self);
	end
	return self;
end

--PassRefPtr<Frame> Frame::create(Page* page, HTMLFrameOwnerElement* ownerElement, FrameLoaderClient* client)
function Frame.Create(page, ownerElement, client)
    local frame = Frame:new():init(page, ownerElement, client);
--    if (not ownerElement) then
--        page:SetMainFrame(frame);
--	end
	page:SetMainFrame(frame);
	return frame;
end

function Frame:Page()
	return self.m_page;
end

function Frame:View()
	return self.m_view;
end

function Frame:Document()
	return self.m_doc;
end

function Frame:OwnerElement()
	return self.m_ownerElement;
end

function Frame:Loader()
	return self.m_loader;
end

function Frame:SetView(view)
	self.m_view = view;
end

function Frame:SetDocument(newDoc)
	self.m_doc = newDoc;

	if (self.m_doc and not self.m_doc:Attached()) then
        self.m_doc:Attach();
	end
end

function Frame:DisconnectOwnerElement()
	if (self.m_ownerElement) then
--        if (Document* doc = document())
--            doc->clearAXObjectCache();
		self.m_ownerElement:SetContentFrame(nil);
--        if (m_page)
--            m_page->decrementFrameCount();
    end
    self.m_ownerElement = nil;
end

--inline bool Frame::isDisconnected() const
function Frame:IsDisconnected()
    return self.m_isDisconnected;
end

--inline void Frame::setIsDisconnected(bool isDisconnected)
function Frame:SetIsDisconnected(isDisconnected)
    self.m_isDisconnected = isDisconnected;
end

--inline void Frame::detachFromPage()
function Frame:DetachFromPage()
    self.m_page = nil;
end

--RenderView* Frame::contentRenderer() const
function Frame:ContentRenderer()
    local doc = self:Document();
    if (not doc) then
        return nil;
	end
    local object = doc:Renderer();
    if (not object) then
        return nil;
	end
    --ASSERT(object->isRenderView());
    return object:ToRenderView();
end

--void Frame::createView(const IntSize& viewportSize,
--                       const Color& backgroundColor, bool transparent,
--                       const IntSize& fixedLayoutSize, bool useFixedLayout,
--                       ScrollbarMode horizontalScrollbarMode, bool horizontalLock,
--                       ScrollbarMode verticalScrollbarMode, bool verticalLock)
function Frame:CreateView(viewportSize)
--    ASSERT(this);
--    ASSERT(m_page);

    local isMainFrame = self == self.m_page:MainFrame();

    if (isMainFrame and self:View()) then
        --self:View():SetParentVisible(false);
	end
    self:SetView(nil);

    local frameView;
    if (isMainFrame) then
        frameView = FrameView.Create(self, viewportSize);
--        frameView->setFixedLayoutSize(fixedLayoutSize);
--        frameView->setUseFixedLayout(useFixedLayout);
    else
        frameView = FrameView.Create(self);
	end

    --frameView->setScrollbarModes(horizontalScrollbarMode, verticalScrollbarMode, horizontalLock, verticalLock);

    self:SetView(frameView);

--    if (backgroundColor.isValid())
--        frameView->updateBackgroundRecursively(backgroundColor, transparent);
--
--    if (isMainFrame)
--        frameView->setParentVisible(true);

	-- TODO: Later add for the "iframe" tag 
    if (self:OwnerRenderer()) then
        self:OwnerRenderer():SetWidget(frameView);
	end

--    if (HTMLFrameOwnerElement* owner = ownerElement())
--        view()->setCanHaveScrollbars(owner->scrollingMode() != ScrollbarAlwaysOff);
	return frameView;
end

--RenderPart* Frame::ownerRenderer() const
function Frame:OwnerRenderer()
    local ownerElement = self.m_ownerElement;
    if (not ownerElement) then
        return nil;
	end
    local object = ownerElement:Renderer();
    if (not object) then
        return nil;
	end
    -- FIXME: If <object> is ever fixed to disassociate itself from frames
    -- that it has started but canceled, then this can turn into an ASSERT
    -- since m_ownerElement would be 0 when the load is canceled.
    -- https://bugs.webkit.org/show_bug.cgi?id=18585
    if (not object:IsRenderPart()) then
        return nil;
	end
    return object:ToRenderPart();
end