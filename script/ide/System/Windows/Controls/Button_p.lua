--[[
Title: Button
Author(s): LiPeng
Date: 2017/10/18
Desc: because Button class is too big, we will move private functions to this file.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
local Button = commonlib.gettable("System.Windows.Controls.Button");
------------------------------------------------------------
]]
local Color = commonlib.gettable("System.Core.Color");
local Button = commonlib.gettable("System.Windows.Controls.Button");

function Button:initPolygonPensInfo()
	self:initNormalPens();

--	self.polygon_styles.none = 
--	{
--		["pens"] = {
--			["pen"] = "#ffffff00"
--		}
--	};
end

local normal = {
	["outline_border1"] = "#171717",
	["outline_border2"] = "#737373",
	["background"] = "#434343"
};

local check = {
	["outline_border"] = "#000000",
	["background"] = "#242424"
};
local over = {
	["color"] = "ffffff33"
};

local down = {
	["outline_border"] = "#000000",
	["background"] = "#242424"
};

function Button:initNormalPens()
	self.polygon_styles.normal = {
		["pens"] = {
			["normal"] = normal,
			["check"] = check,
			["over"] = over,
			["down"] = down,
		}
	};
end

--function Button:initCheckboxPens()
--
--	local pens = {
--		["border"] = "#9c9c9c",
--		["check"] = "#000000",
--	}
--
--	self.polygon_styles.checkox = 
--	{
--		pens = pens,
--	};
--end

function Button:MultiplyBackgroundColor(color)
	for _,polygon_info in pairs(self.polygon_styles) do
		local pens = polygon_info.pens;
		for k,v in pairs(pens) do
			for key, pen_color in pairs(v) do
				if(key ~= "over") then
					v[key] = Color.Multiply(pen_color, color);
				end
			end
		end
	end
end

function Button:isUsingPolygon()
	local value = true;
	if(self.Background and self.Background ~= "") then
		value = false;
	elseif(self.BackgroundDown and self.BackgroundDown ~= "") then
		value = false;
	elseif(self.BackgroundOver and self.BackgroundOver ~= "") then
		value = false;
	end
	return value;
end

function Button:paintBackground(painter)
	if(self:isUsingPolygon()) then
		self:paintWithPolygon(painter);
	else
		self:paintWithTexture(painter);
	end
end

function Button:paintWithTexture(painter)
	local x, y = self:x(), self:y();
	local background = self.Background;
	if (self.down or self.menuOpen) then
		-- suken state
		background = self.BackgroundDown or background;
	end
	if(self.checked) then
		-- checked state
		background = self.BackgroundChecked or background;
	else
		-- normal raised
	end
	if(background and background~="") then
		painter:SetPen(self:GetBackgroundColor());
		painter:DrawRectTexture(x, y, self:width(), self:height(), background);
	end

	if(self:underMouse()) then
		if(self.BackgroundOver) then
			painter:SetPen("#ffffff");
			painter:DrawRectTexture(x+2, y+2, self:width()-4, self:height()-4, self.BackgroundOver);
		end
	end
end

function Button:paintWithPolygon(painter)
	if(self.polygon_style == "none") then
		painter:SetPen(self:GetBackgroundColor());
		painter:DrawRectTexture(self:x(), self:y(), self:width(), self:height(), self:GetBackground());
	elseif(self.polygon_style == "normal") then
		self:paintNormalButton(painter);
	elseif(self.polygon_style == "check") then
		self:paintCheckButton(painter);
	elseif(self.polygon_style == "narrow") then
		self:paintNarrowButton(painter);
	elseif(self.polygon_style == "radio") then
		self:paintRadioButton(painter);
	end
end

function Button:paintNormalButton(painter)
	local pens = self.polygon_styles.normal.pens;
	local x, y = self:x(), self:y();
	if (self.down or self.menuOpen) then
		-- BackgroundDown
		--painter:SetPen("#000000");
		painter:SetPen(pens.down.outline_border);
		painter:DrawRectTexture(x, y, self:width(), self:height(), "");
			
		--painter:SetPen("#242424");
		painter:SetPen(pens.down.background);
		painter:DrawRectTexture(x + 1, y + 1, self:width() - 2, self:height() - 2, "");
	elseif(self.checked) then
		-- BackgroundChecked
		--painter:SetPen("#000000");
		painter:SetPen(pens.check.outline_border);
		painter:DrawRectTexture(x, y, self:width(), self:height(), "");
			
		--painter:SetPen("#242424");
		painter:SetPen(pens.check.background);
		painter:DrawRectTexture(x + 1, y + 1, self:width() - 2, self:height() - 2, "");
	else
		-- Background
		--painter:SetPen("#171717");
		painter:SetPen(pens.normal.outline_border1);
		painter:DrawRectTexture(x, y, self:width(), self:height(), "");
			
		--painter:SetPen("#737373");
		painter:SetPen(pens.normal.outline_border2);
		painter:DrawRectTexture(x + 1, y + 1, self:width() - 2, self:height() - 2, "");
			
		--painter:SetPen("#434343");
		painter:SetPen(pens.normal.background);
		painter:DrawRectTexture(x + 2, y + 2, self:width() - 3, self:height() - 3, "");
	end

	-- BackgourdOver
	if(self:underMouse()) then
		painter:SetPen("#ffffff33");
		painter:DrawRectTexture(x+2, y+2, self:width()-4, self:height()-4, "");
	end
end

function Button:paintCheckButton(painter)
	self:UpdateCheckboxGeometry();
	local size = self:GetSize();
	local x, y, w, h = self:x() + (self:width() - size)/2, self:y() + (self:height() - size)/2, size, size;
	
	painter:SetPen("#9c9c9c");
	painter:DrawRectTexture(x, y, w, h, "");
			
	painter:SetPen("#e0e0e0");
	painter:DrawRectTexture(x + 2, y + 2, w - 4, h - 4, "");

	if(self.down or self.menuOpen or self.checked) then
		painter:SetPen("#000000");
		painter:SetPen({width = 2, color = "#000000"});

		local lines = self.polygon_styles.check.lines;

		painter:DrawLineList(lines);
	end

	-- BackgourdOver
	if(self:underMouse()) then
		painter:SetPen("#ffffff33");
		painter:DrawRectTexture(x+2, y+2, w - 4, h - 4, "");
	end
end

function Button:paintNarrowButton(painter)
	self:UpdateNarrowGeometry();
	local out_triangle = self.polygon_styles.narrow.triangles[self.direction or "right"]["out"];
	local inner_triangle = self.polygon_styles.narrow.triangles[self.direction or "right"]["inner"];

	if (self.down or self.menuOpen or self.checked) then
		painter:SetPen("#000000");
		painter:DrawTriangleList(out_triangle);

		painter:SetPen("#242424");
		painter:DrawTriangleList(inner_triangle);
	else
		painter:SetPen("#171717");
		painter:DrawTriangleList(out_triangle);

		painter:SetPen("#434343");
		painter:DrawTriangleList(inner_triangle);
	end

	local x, y = self:x(), self:y();
	-- BackgourdOver
	if(self:underMouse()) then
		painter:SetPen("#ffffff33");
		painter:DrawTriangleList(inner_triangle);
	end
end

function Button:CountPolygon(recount)
	self:UpdateNarrowGeometry(recount);
	self:UpdateCheckboxGeometry(recount);
end

function Button:emitPositionChanged()
	Button._super.emitPositionChanged(self);
	self:CountPolygon(true);
end

function Button:emitSizeChanged()
	Button._super.emitSizeChanged(self);
	self:CountPolygon(true);
end

-- count the checkbox button check line
function Button:UpdateCheckboxGeometry(recount)
	if(self.polygon_style ~= "check") then
		return;
	end

	self.polygon_styles.check = self.polygon_styles.check or {["lines"] = nil};

	if(self.polygon_styles.check.lines) then
		if(not recount) then
			return;
		end
	else
		self.polygon_styles.check.lines = {};
	end

	local lines = self.polygon_styles.check.lines;

	local size = self:GetSize();
	local x, y, w, h = self:x() + (self:width() - size)/2, self:y() + (self:height() - size)/2, size, size;

	for i = 1, 4 do
		lines[i] = lines[i] or {};
		if(i == 1) then
			lines[i][1] = math.ceil(x + w*1/4);
			lines[i][2] = math.ceil(y + h/2);
			lines[i][3] = 0;
		elseif(i == 2 or i == 3) then
			lines[i][1] = math.ceil(x + w/2);
			lines[i][2] = math.ceil(y + h*3/4);
			lines[i][3] = 0;
		else
			lines[i][1] = math.ceil(x + w*3/4);
			lines[i][2] = math.ceil(y + h/4);
			lines[i][3] = 0;
		end
	end
end

-- count the narrow button triangle
function Button:UpdateNarrowGeometry(recount)
	if(self.polygon_style ~= "narrow") then
		return;
	end
	self.polygon_styles.narrow = self.polygon_styles.narrow or {["triangles"] = nil};
	
	if(self.polygon_styles.narrow.triangles) then
		if(not recount) then
			return;
		end
	else
		self.polygon_styles.narrow.triangles = {};
	end

	local triangles = self.polygon_styles.narrow.triangles;

	local centerX, centerY = self:x() + self:width()/2, self:y() + self:height()/2;
	local centerLineLength = math.sqrt(3) * self:GetSize() / 2;

	for direction, _ in pairs(self.directions) do
		
		triangles[direction] = triangles[direction] or {
			["out"] = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}},
			["inner"] = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}},
		};

		local out_triangle = triangles[direction]["out"];
		local inner_triangle = triangles[direction]["inner"];

		if(direction == "up") then
			out_triangle[1][1] = 0;
			out_triangle[1][2] = -math.ceil(centerLineLength *2 / 3);
			inner_triangle[1][1] = 0;
			inner_triangle[1][2] = out_triangle[1][2] + 1;

			out_triangle[2][1] = -math.ceil(self:GetSize() / 2);
			out_triangle[2][2] = math.ceil(centerLineLength / 3);
			inner_triangle[2][1] = out_triangle[2][1] + 1;
			inner_triangle[2][2] = math.ceil(centerLineLength / 3) - 1;

			out_triangle[3][1] = math.ceil(self:GetSize() / 2);
			out_triangle[3][2] = math.ceil(centerLineLength / 3);
			inner_triangle[3][1] = out_triangle[3][1] - 1;
			inner_triangle[3][2] = out_triangle[3][2] - 1;
		elseif(direction == "down") then
			out_triangle[1][1] = 0;
			out_triangle[1][2] = math.ceil(centerLineLength *2 / 3);
			inner_triangle[1][1] = 0;
			inner_triangle[1][2] = out_triangle[1][2] - 1;

			out_triangle[2][1] = -math.ceil(self:GetSize() / 2);
			out_triangle[2][2] = -math.ceil(centerLineLength / 3);
			inner_triangle[2][1] = out_triangle[2][1] + 1;
			inner_triangle[2][2] = out_triangle[2][2] + 1;

			out_triangle[3][1] = math.ceil(self:GetSize() / 2);
			out_triangle[3][2] = -math.ceil(centerLineLength / 3);
			inner_triangle[3][1] = out_triangle[3][1] - 1;
			inner_triangle[3][2] = out_triangle[3][2] + 1;
		elseif(direction == "left") then
			out_triangle[1][1] = -math.ceil(centerLineLength *2 / 3);
			out_triangle[1][2] = 0;
			inner_triangle[1][1] = out_triangle[1][1] + 1;
			inner_triangle[1][2] = 0;

			out_triangle[2][1] = math.ceil(centerLineLength / 3);
			out_triangle[2][2] = math.ceil(self:GetSize() / 2);
			inner_triangle[2][1] = out_triangle[2][1] - 1;
			inner_triangle[2][2] = out_triangle[2][2] - 1;

			out_triangle[3][1] = math.ceil(centerLineLength / 3);
			out_triangle[3][2] = -math.ceil(self:GetSize() / 2);
			inner_triangle[3][1] = out_triangle[3][1] - 1;
			inner_triangle[3][2] = out_triangle[3][2] + 1;
		elseif(direction == "right") then
			out_triangle[1][1] = math.ceil(centerLineLength *2 / 3);
			out_triangle[1][2] = 0;
			inner_triangle[1][1] = out_triangle[1][1] - 1;
			inner_triangle[1][2] = 0;

			out_triangle[2][1] = -math.ceil(centerLineLength / 3);
			out_triangle[2][2] = math.ceil(self:GetSize() / 2);
			inner_triangle[2][1] = out_triangle[2][1] + 1;
			inner_triangle[2][2] = out_triangle[2][2] - 1;

			out_triangle[3][1] = -math.ceil(centerLineLength / 3);
			out_triangle[3][2] = -math.ceil(self:GetSize() / 2);
			inner_triangle[3][1] = out_triangle[3][1] + 1;
			inner_triangle[3][2] = out_triangle[3][2] + 1;
		end
		for i = 1, #out_triangle do
			local vertex = out_triangle[i];
			vertex[1] = vertex[1] + centerX;
			vertex[2] = -(vertex[2] + centerY);
		end

		for i = 1, #inner_triangle do
			local vertex = inner_triangle[i];
			vertex[1] = vertex[1] + centerX;
			vertex[2] = -(vertex[2] + centerY);
		end
	end
end

function Button:paintRadioButton(painter)
	local size = self:GetSize();
	size = math.min(size, math.min(self:width(), self:height()));
	local radius = math.ceil(size/2);
	local x, y = self:x() + self:width()/2, self:y() + self:height()/2;
	
	painter:SetPen("#b5b5b5");
	painter:DrawCircle(x,y,0,radius,"z", true);

	painter:SetPen("#dedede");
	painter:DrawCircle(x,y,0,radius-2,"z",true);


	if(self.down or self.menuOpen or self.checked) then
		painter:SetPen("#666666");
		painter:DrawCircle(x,y,0,radius-3,"z",true);
	end

	-- BackgourdOver
	if(self:underMouse()) then
		painter:SetPen("#ffffff33");
		painter:DrawCircle(x,y,0,radius,"z");
	end
end