--[[
Title: 
Author(s): LiPeng
Date: 2018/1/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutButton.lua");
local LayoutButton = commonlib.gettable("System.Windows.mcml.layout.LayoutButton");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutDeprecatedFlexibleBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutText.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local LayoutText = commonlib.gettable("System.Windows.mcml.layout.LayoutText");
local LayoutButton = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutDeprecatedFlexibleBox"), commonlib.gettable("System.Windows.mcml.layout.LayoutButton"));

local OverflowEnum = ComputedStyleConstants.OverflowEnum;
local DisplayEnum = ComputedStyleConstants.DisplayEnum;

function LayoutButton:ctor()
	self.name = "LayoutButton";

	--RenderTextFragment* m_buttonText;
	self.m_buttonText = nil;
    --RenderBlock* m_inner;
	self.m_inner = nil;

    --OwnPtr<Timer<RenderButton> > m_timer;
	self.m_timer = nil;
    --bool m_default;
	self.m_default = false;
end

function LayoutButton:GetName()
	return "LayoutButton";
end


function LayoutButton:IsLayoutButton()
	return true;
end

-- void RenderButton::addChild(RenderObject* newChild, RenderObject* beforeChild)
function LayoutButton:AddChild(newChild, beforeChild)
	if (not self.m_inner) then
        -- Create an anonymous block.
        --ASSERT(!firstChild());
		local display = self:Style():Display();
        local isFlexibleBox = display == DisplayEnum.BOX or display == DisplayEnum.INLINE_BOX;
        self.m_inner = self:CreateAnonymousBlock(isFlexibleBox);
        self:SetupInnerStyle(self.m_inner:Style());
        LayoutButton._super.AddChild(self, self.m_inner);
    end
    
    self.m_inner:AddChild(newChild, beforeChild);
end

-- void RenderButton::removeChild(RenderObject* oldChild)
function LayoutButton:RemoveChild(oldChild)
	if (oldChild == self.m_inner or not self.m_inner) then
        LayoutButton._super.RemoveChild(self, oldChild);
        self.m_inner = nil;
    else
        self.m_inner:RemoveChild(oldChild);
	end
end

function LayoutButton:RemoveLeftoverAnonymousBlock(child)

end

function LayoutButton:CreatesAnonymousWrapper()
	return true;
end


function LayoutButton:SetupInnerStyle(innerStyle)
	--ASSERT(innerStyle->refCount() == 1);
    -- RenderBlock::createAnonymousBlock creates a new RenderStyle, so this is
    -- safe to modify.
    innerStyle:SetBoxFlex(1);
    innerStyle:SetBoxOrient(self:Style():BoxOrient());

--	innerStyle:SetOverflowX(OverflowEnum.OHIDDEN);
--	innerStyle:SetOverflowY(OverflowEnum.OHIDDEN);
end

function LayoutButton:UpdateFromElement()
	-- If we're an input element, we may need to change our button text.
    --if (node()->hasTagName(inputTag)) {
	if(self:Node() and self:Node():HasTagName("input")) then
        --HTMLInputElement* input = static_cast<HTMLInputElement*>(node());
		local input = self:Node();
       -- String value = input->valueWithDefault();
        self:SetText(input:ValueWithDefault());
    end
end

--function LayoutButton:UpdateBeforeAfterContent(PseudoId);

function LayoutButton:HasControlClip()
	return true;
end

--function LayoutButton:ControlClipRect(const IntPoint&) const;

function LayoutButton:SetText(str)
	if (not str or str == "") then
        if (self.m_buttonText) then
            self.m_buttonText:Destroy();
            self.m_buttonText = nil;
        end
    else
        if (self.m_buttonText) then
            self.m_buttonText:SetText(str);
        else
            self.m_buttonText = LayoutText:new():init(nil, str);
            self.m_buttonText:SetStyle(self:Style());
            self:AddChild(self.m_buttonText);
        end
    end
end

function LayoutButton:Text()
	if(self.m_buttonText) then
		return self.m_buttonText:Text();
	end
end

function LayoutButton:CanHaveChildren()
	if(self:Node()) then
		return not self:Node():HasTagName("input");
	end
	return LayoutButton._super.CanHaveChildren(self);
end

function LayoutButton:StyleWillChange(diff, newStyle)
	if (self.m_inner) then
        -- RenderBlock::setStyle is going to apply a new style to the inner block, which
        -- will have the initial box flex value, 0. The current value is 1, because we set
        -- it right below. Here we change it back to 0 to avoid getting a spurious layout hint
        -- because of the difference.
        self.m_inner:Style():SetBoxFlex(0);
    end
    LayoutButton._super.StyleWillChange(self, diff, newStyle);
end

function LayoutButton:StyleDidChange(diff, oldStyle)
	LayoutButton._super.StyleDidChange(self, diff, oldStyle);

    if (self.m_buttonText) then
        self.m_buttonText:SetStyle(self:Style());
	end
    if (self.m_inner) then -- RenderBlock handled updating the anonymous block's style.
        self:SetupInnerStyle(self.m_inner:Style());
	end

--    if (!m_default && theme()->isDefault(this)) {
--        if (!m_timer)
--            m_timer = adoptPtr(new Timer<RenderButton>(this, &RenderButton::timerFired));
--        m_timer->startRepeating(0.03);
--        m_default = true;
--    } else if (m_default && !theme()->isDefault(this)) {
--        m_default = false;
--        m_timer.clear();
--    }
end

function LayoutButton:HasLineIfEmpty()
	return true;
end


function LayoutButton:RequiresForcedStyleRecalcPropagation()
	return true;
end


--void timerFired(Timer<RenderButton>*);