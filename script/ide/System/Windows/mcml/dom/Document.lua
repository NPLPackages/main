--[[
Title: document fragment element
Author(s): LiPeng
Date: 2019/2/22
Desc: it isn't a html tag.we use it when innerhtml
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/dom/Document.lua");
local Document = commonlib.gettable("System.Windows.mcml.dom.Document");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleSelector.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutView.lua");
NPL.load("(gl)script/ide/System/Windows/Shapes/Rectangle.lua");
local Rectangle = commonlib.gettable("System.Windows.Shapes.Rectangle");
local LayoutView = commonlib.gettable("System.Windows.mcml.layout.LayoutView");
local CSSStyleSelector = commonlib.gettable("System.Windows.mcml.css.CSSStyleSelector");
local PageElement = commonlib.gettable("System.Windows.mcml.PageElement");
local Document = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.dom.Document"));

Document:Property("Name", "Document");

local StyleChangeEnum = PageElement.StyleChangeEnum;

local CompatibilityMode = 
{
	["QuirksMode"] = 1, 
	["LimitedQuirksMode"] = 2, 
	["NoQuirksMode"] = 3,
}


local docID = 0;

local function getDocId()
	id = docID;
	docID = docID + 1;
	return id;
end

function Document:ctor()
	self.m_frame = nil;
	self.m_url = nil;
	self.m_createRenderers = true;
	self.m_document = self;
	self.m_styleSelector = nil;

	self.m_documentElement = nil;
	self.m_focusedNode = nil;
    self.m_hoverNode = nil;
    self.m_activeNode = nil;

	self.m_inStyleRecalc = false;

	self.m_usesFirstLineRules = false;
	self.m_compatibilityMode = CompatibilityMode.NoQuirksMode;

	self:SetInDocument();

    self.m_docID = getDocId();
end

function Document:init(frame, url)
	--Document._super.init(self);
	self.m_frame = frame;
	self.m_url = url;
	return self;
end



function Document:NodeType()
	return "DOCUMENT_NODE";
end

function Document:Frame()
	return self.m_frame;
end

function Document:SetFrame(frame)
	self.m_frame = frame;
end

--FrameView* Document::view() const
function Document:View()
	if(self.m_frame) then
		return self.m_frame:View();
	end
	return nil;
end

--Page* Document::page() const
function Document:Page()
	if(self.m_frame) then
		return self.m_frame:Page();
	end
	return nil;
    --return m_frame ? m_frame->page() : 0;    
end

function Document:RecalcStyle(change)
	if (self:View() and self:View():IsPainting()) then
        --ASSERT(!view()->isPainting());
        return;
    end

	if(self.m_inStyleRecalc) then
		return;
	end

	self.m_inStyleRecalc = true;

	local frameView = self:View();
    if (frameView) then
        --frameView:PauseScheduledEvents();
        frameView:BeginDeferredRepaints();
    end

--	if (change == StyleChangeEnum.Force) then
--        -- style selector may set this again during recalc
--        --m_hasNodesWithPlaceholderStyle = false;
--        
--        RefPtr<RenderStyle> documentStyle = CSSStyleSelector::styleForDocument(this);
--        StyleChange ch = diff(documentStyle.get(), renderer()->style());
--        if (ch != NoChange)
--            renderer()->setStyle(documentStyle.release());
--    end

	local node = self:FirstChild();
	while(node) do
--        if (!n->isElementNode())
--            continue;
        local element = node;
        if (change >= StyleChangeEnum.Inherit or element:NeedsStyleRecalc() or element:ChildNeedsStyleRecalc()) then
            element:RecalcStyle(change);
		end

		node = node:NextSibling();
    end

	self:ClearNeedsStyleRecalc();
	self:ClearChildNeedsStyleRecalc();
--    unscheduleStyleRecalc();

	self.m_inStyleRecalc = false;

	if (frameView) then
        --frameView->resumeScheduledEvents();
        frameView:EndDeferredRepaints();
    end
end

function Document:UpdateStyleIfNeeded()
	--recalcStyle(NoChange);
	self:RecalcStyle(StyleChangeEnum.NoChange);
end

--CSSStyleSelector* styleSelector()
function Document:StyleSelector()
    if (not self.m_styleSelector) then
        self:CreateStyleSelector();
	end
    return self.m_styleSelector;
end

function Document:CreateStyleSelector()
	self.m_styleSelector = CSSStyleSelector:new();
end

function Document:CreateRendererIfNeeded()
	self:SetRenderer(LayoutView:new():init(self, self:View()));
	local documentStyle = CSSStyleSelector.StyleForDocument(self);
    self:Renderer():SetStyle(documentStyle);
end

function Document:UsesFirstLineRules() 
	return self.m_usesFirstLineRules;
end

function Document:InNoQuirksMode()
	return self.m_compatibilityMode == CompatibilityMode.NoQuirksMode; 
end

function Document:InQuirksMode()
	return self.m_compatibilityMode == CompatibilityMode.QuirksMode;
end

function Document:DocumentElement()
	if (not self.m_documentElement) then
		self:CacheDocumentElement();
	end
	return self.m_documentElement;
end

--void Document::cacheDocumentElement() const
function Document:CacheDocumentElement()
    --ASSERT(!m_documentElement);
    self.m_documentElement = self:FirstElementChild(self);
end

function Document:FocusedNode()
	return self.m_focusedNode;
end

function Document:HoverNode()
	return self.m_hoverNode;
end

function Document:ActiveNode()
	return self.m_activeNode;
end

function Document:SetHoverNode(newHoverNode)
    self.m_hoverNode = newHoverNode;
end

function Document:SetActiveNode(newActiveNode)
    self.m_activeNode = newActiveNode;
end

function Document:GetParentControl()
	if(self.m_frame:OwnerElement()) then
		return self.m_frame:OwnerElement():GetControl();
	end

	if(self:View()) then
		return self:View():widget();
	end
	return;
end

function Document:CreateControl()
	local parentElem = self:GetParentControl();
	local _this = Rectangle:new():init(parentElem);
	self:SetControl(_this);
end