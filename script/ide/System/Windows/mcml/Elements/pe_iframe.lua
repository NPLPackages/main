--[[
Title: iframe
Author(s): LiPeng
Date: 2018/1/4
Desc: it handles HTML tags of <iframe> . 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_iframe.lua");
System.Windows.mcml.Elements.pe_iframe:RegisterAs("iframe");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_div.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutIFrame.lua");
NPL.load("(gl)script/ide/System/Windows/Shapes/Rectangle.lua");
local Rectangle = commonlib.gettable("System.Windows.Shapes.Rectangle");
local LayoutIFrame = commonlib.gettable("System.Windows.mcml.layout.LayoutIFrame");
local pe_iframe = commonlib.inherit(commonlib.gettable("System.Windows.mcml.Elements.pe_div"), commonlib.gettable("System.Windows.mcml.Elements.pe_iframe"));
pe_iframe:Property({"class_name", "pe:iframe"});

function pe_iframe:ctor()
	self.m_contentFrame = nil;

	self.m_frameName = nil;
	self.m_URL = nil;

	self.m_marginWidth = 0;
    self.m_marginHeight = 0;
end

-- skip child node parsing.
function pe_iframe:createFromXmlNode(o)
	return self:new(o);
end

function pe_iframe:CreateControl()
	local parentElem = self:GetParentControl();
	local _this = Rectangle:new():init(parentElem);
	self:SetControl(_this);
end

function pe_iframe:SetControl(control)
	pe_iframe._super.SetControl(self, control)

	if(self.m_contentFrame and self.m_contentFrame:View()) then
		self.m_contentFrame:View():SetUIElement(control)
	end
end

function pe_iframe:IsFrameOwnerElement() 
	return true; 
end

function pe_iframe:ContentFrame() 
	return self.m_contentFrame; 
end

function pe_iframe:SetContentFrame(frame) 
	self.m_contentFrame = frame;
end

--RenderPart* HTMLFrameOwnerElement::renderPart() const
function pe_iframe:RenderPart()
    -- HTMLObjectElement and HTMLEmbedElement may return arbitrary renderers
    -- when using fallback content.
    if (not self:Renderer() or not self:Renderer():IsRenderPart()) then
		
        return nil;
	end
    return self:Renderer():ToRenderPart();
end

function pe_iframe:ContentDocument()
	if(self.m_contentFrame) then
		return self.m_contentFrame:Document();
	end
end


function pe_iframe:InsertedIntoDocument()
	pe_iframe._super.InsertedIntoDocument(self)
	if (not self:Document():Frame()) then
        return;
	end

	self:LazyAttach("DoNotSetAttached");
    self:SetNameAndOpenURL();
end

function pe_iframe:SetNameAndOpenURL()
    self.m_frameName = self:GetAttribute("name", nil);
    if (self.m_frameName == nil) then
        self.m_frameName = self:GetAttribute("id", nil);
	end

    self:OpenURL();
end

function pe_iframe:OpenURL()
	local parentFrame = self:Document():Frame();
    if (not parentFrame) then
        return;
	end

	parentFrame:Loader():SubframeLoader():RequestFrame(self, self.m_URL, self.m_frameName);
end

function pe_iframe:attachLayoutTree()
	pe_iframe._super.attachLayoutTree(self);
	local part = self:RenderPart();
	if (part) then
		local frame = self:ContentFrame();
        if (frame) then
            part:SetWidget(frame:View());
		end
    end
end

function pe_iframe:CreateLayoutObject(arena, style)
    return LayoutIFrame:new():init(self);
end

function pe_iframe:FramePage()
	return self.page;
end

function pe_iframe:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	local url = self:GetAbsoluteURL(self:GetAttributeWithCode("src",nil,true));
	self.m_URL = url;

	local srcPage = System.Windows.mcml.Page:new({name = self:GetAttributeWithCode("name",nil,true), parentpage = self:GetPageCtrl()});
	self.page = srcPage;

	self:InsertedIntoDocument();

	srcPage:Init(url);

	pe_iframe._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css);
end

