--[[
Title: Button
Author(s): LiXizhi
Date: 2015/4/23
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
local Button = commonlib.gettable("System.Windows.Controls.Button");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/Primitives/ButtonBase.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Button_p.lua");
local Button = commonlib.inherit(commonlib.gettable("System.Windows.Controls.Primitives.ButtonBase"), commonlib.gettable("System.Windows.Controls.Button"));
Button:Property("Name", "Button");
Button:Property({"Background", nil, auto = true});
Button:Property({"BackgroundDown", nil, auto = true});
Button:Property({"BackgroundChecked", nil, auto = true});
Button:Property({"BackgroundOver", nil, auto = true});
-- the narrow direction
Button:Property({"direction", nil, nil, "SetDirection", auto=true});
-- check and narrow size
Button:Property({"Size", 12, auto = true});

function Button:ctor()
	self.polygon_style = "normal";
	self.polygon_styles = {
		["none"] = nil,
		["normal"] = nil,
		["check"] = nil,
		["narrow"] = nil,
		["radio"] = nil,
	};
	-- all direction value
	self.directions = {
		["up"] = true,
		["down"] = true,
		["left"] = true,
		["right"] = true,
	};
end

function Button:init(parent)
	Button._super.init(self, parent);
	self:initPolygonPensInfo();
	return self;
end

local styles = {
	["none"] = true,
	["normal"] = true,
	["check"] = true,
	["narrow"] = true,
	["radio"] = true,
};

function Button:SetPolygonStyle(style)
	if(style and styles[style]) then
		self.polygon_style = style;
	end
end

-- virtual: 
function Button:mousePressEvent(mouse_event)
	-- self:CaptureMouse();
	Button._super.mousePressEvent(self, mouse_event);
end

-- virtual: 
function Button:mouseReleaseEvent(mouse_event)
	-- self:ReleaseMouseCapture();
	Button._super.mouseReleaseEvent(self, mouse_event);
end

function Button:SetBackgroundColor(color)
	Button._super.SetBackgroundColor(self, color);
	self:MultiplyBackgroundColor(color);
end

function Button:setChecked(checked)
	Button._super.setChecked(self, checked)
	if(self.polygon_style == "narrow") then
		if(self.checked) then
			self.direction = "down";
		else
			self.direction = "right";
		end
	end
end

function Button:paintEvent(painter)
	self:paintBackground(painter);
	
	local x, y = self:x(), self:y();
	local text = self:GetText();
	if(text and text~="") then
		painter:SetFont(self:GetFont());
		painter:SetPen(self:GetColor());
		self:DrawTextScaledEx(painter, x+self.padding_left, y+self.padding_top, self:width()-self.padding_left-self.padding_right, self:height()-self.padding_top-self.padding_bottom, text, self:GetAlignment(), self:GetFontScaling());
	else
		local icon = self:GetIcon();
		if(icon and icon~="") then
			painter:SetPen(self:GetColor());
			painter:DrawRectTexture(x+self.padding_left, y+self.padding_top, self:width()-self.padding_left-self.padding_right, self:height()-self.padding_top-self.padding_bottom, icon);
		end
	end
end

function Button:ApplyCss(css)
	Button._super.ApplyCss(self, css);

	self.BackgroundChecked = css.background_checked;
	self.BackgroundDown = css.background_down;
	self.BackgroundOver = css.background_over;
end

function Button:SetDirection(direction)
	if(direction and self.directions[direction]) then
		self.direction = direction;
	end
end
