--[[
Title: Painting context
Author(s): LiXizhi
Date: 2015/4/20
Desc: wrapper to ParaPainter. It can also be used as an PaintEvent
---++ On Coordinate System
The 2D API uses Y axis downward coordinate; where as the 3D API uses Y up axis.
Both APIs can be used together. The final world matrix is calculated as thus:
	finalMatrix = mat2DFinal * matInvertY * mat3DFinal;	
	mat2DFinal is the final matrix by all the 2d api like scale, translate, rotate
	mat3DFinal is the final matrix by all the 3d api like PushMatrix, TranslateMatrix, etc.
Please note, mat3DFinal only takes effect when 3d mode is enabled, such as during rendering head on display or overlays.
When you are rendering 3D triangles mixed with 2D GUI, it is good practice to restore mat2DFinal to identity matrix after
drawing 2D GUI.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Core/PainterContext2.lua");
local PainterContext = commonlib.gettable("System.Core.PainterContext2");
local painter = System.Core.PainterContext:new():init(parent);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/Matrix4.lua");
NPL.load("(gl)script/ide/System/Scene/Overlays/ShapesDrawer.lua");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");

local PainterContext = commonlib.inherit(commonlib.gettable("System.Core.Event"), commonlib.gettable("System.Core.PainterContext2"));
local painter = PainterContext; -- just for NPLDoc, since most PainterContext is called painter in function parameter. 

PainterContext.event_type = "paintEvent";
local ParaPainter = ParaPainter;
local isBatchCmdMode = false;
local string_format = string.format;
-- static : composition mode. default is usually SourceBlend
painter.CompositionMode = {
	SourceBlend= 0,
	SourceOver= 1,
	DestinationOver = 2,
	Clear = 3,
	Source = 4,
	Destination = 5,
	SourceIn = 6,
	DestinationIn = 7,
	SourceOut = 8,
	DestinationOut = 9,
	SourceAtop = 10,
	DestinationAtop = 11,
	Xor = 12,
	Plus = 13,
	PlusSourceBlend = 14
}

painter.m_cmd_state = {};
painter.m_cmds = {};
painter.m_cmds_size = 0;

function painter:ctor()
end

function painter:EnableCmdMode() 
	if (type(ParaPainter.FlushCmdList) ~= "function") then return end
	isBatchCmdMode = true;
	self.m_cmd_state = {};
	self.m_cmds = {};
	self.m_cmds_size = 0;
end

function painter:DisableCmdMode()
	isBatchCmdMode = false;
end

function painter:IsCmdMode() 
	return isBatchCmdMode;
end

function painter:FlushCmdList(cmds_text)
	if (ParaPainter.FlushCmdList and type(cmds_text) == "string" and cmds_text ~= "") then ParaPainter.FlushCmdList(cmds_text) end
	-- if (not isBatchCmdMode) then return self.m_cmds, self.m_cmds_size end
	-- -- ParaPainter.FlushCmdList(table.concat(self.m_cmds, "\n"));
	-- -- _G.PainterCmds = self.m_cmds;
	-- -- _G.__cmds__ = self.m_cmds;
	-- -- _G.__cmds_size__ = self.m_cmds_size;
	-- -- _G.__test_cmds__ = function()
	-- -- 	local begin_time = os.clock();
	-- -- 	local text = "";
	-- -- 	for i = 1, _G.__cmds_size__ do
	-- -- 		local cmd = _G.__cmds__[i];
	-- -- 		text = text .. (type(cmd) == "string" and cmd or string_format(unpack(cmd))) .. "\n";
	-- -- 	end
	-- -- 	local elapsed_time = os.clock() - begin_time;
	-- -- 	print(string.format("FlushCmdList elapsed time: %f ms, cmd count %d", elapsed_time * 1000, _G.__cmds_size__));
	-- -- end

	-- self.m_cmd_state = {};
	-- self.m_cmds = {};
	-- self.m_cmds_size = 0;
	-- return self.m_cmds, self.m_cmds_size;
end

local function EncodeCmdArgCallBack(c) 
	return string.format("%%%02X", string.byte(c));
end

function painter:EncodeCmdArg(str)
	return string.gsub(str, "([%%%s])", EncodeCmdArgCallBack);
	-- return string.gsub(str, "([^%w])", EncodeCmdArgCallBack);
end

function painter:AppendCmd(cmd, ...)
	if (type(cmd) ~= "string") then return end
	
	local size = select("#", ...)
    for i = 1, size do
        local v = select(i, ...)
		local v_type = type(v);
		if (v_type == "string") then
			cmd = cmd .. " " .. v;
		elseif (v_type == "number") then
			cmd = cmd .. " " .. tostring(v);
		elseif (v_type == "boolean") then
			cmd = cmd .. " " .. (v and "1" or "0");
		elseif (v_type == "table") then
			for _, value in ipairs(v) do
				cmd = cmd .. " " .. tonumber(value);
			end			
		end
    end
	
	self:AppendCmdNoArgs(cmd);
end

function painter:AppendCmdNoArgs(cmd)
	if (not cmd) then return end
	self.m_cmds_size = self.m_cmds_size + 1;
	self.m_cmds[self.m_cmds_size] = cmd;
end

-- TODO:
function painter:rect()
	return self.m_rect;
end

-- TODO:
function painter:region()
	return self.m_region;
end

function painter:init(parentWindow)
	self.parentWindow = parentWindow;
	return self;
end

function painter:GetWindow()
	return self.parentWindow;
end

function painter:Begin(paintDevice)
	return ParaPainter.Begin(paintDevice);
end

function painter:End()
	return ParaPainter.End();
end

function painter:Flush()
	if (isBatchCmdMode) then
		self:AppendCmdNoArgs("Flush");
		return;
	end
	ParaPainter.Flush();
end

function painter:Save()
	if (isBatchCmdMode) then
		self:AppendCmdNoArgs("Save");
		return;
	end
	
	ParaPainter.Save();
end

function painter:Restore()
	if (isBatchCmdMode) then
		self:AppendCmdNoArgs("Restore");
		return;
	end
	
	ParaPainter.Restore();
end

-- @param mode: number from self.CompositionMode
-- self.CompositionMode.SourceBlend = 0
-- self.CompositionMode.SourceOver = 1
function painter:SetCompositionMode(mode)
	if (isBatchCmdMode) then
		self.m_cmd_state.m_composition_mode = mode;
		-- self:AppendCmdNoArgs(string_format("%s %d", "SetCompositionMode", mode));
		self:AppendCmdNoArgs({"%s %d", "SetCompositionMode", mode});
		return;
	end
	
	ParaPainter.SetCompositionMode(mode);
end

function painter:GetCompositionMode()
	if (isBatchCmdMode) then
		if (self.m_cmd_state.m_composition_mode ~= nil) then return self.m_cmd_state.m_composition_mode end
		return ParaPainter.GetCompositionMode();
	end
	return ParaPainter.GetCompositionMode();
end

-- set current font 
-- @param font: {family="System", size=10, bold=true}
-- or it can be string "System;14;" or "System;14;bold"
function painter:SetFont(font)
	if (isBatchCmdMode) then
		if (type(font) == "string") then
			if (self.m_cmd_state.m_font == font) then return end
			self.m_cmd_state.m_font = font;
			self.m_cmd_state.m_font_family = nil;
			self.m_cmd_state.m_font_size = nil
			self.m_cmd_state.m_font_bold = nil
			-- self:AppendCmdNoArgs(string_format("%s %s", "SetFont", font));
			self:AppendCmdNoArgs({"%s %s", "SetFont", font});
		elseif (type(font) == "table") then
			local font_family = font.family or "System";
			local font_size = font.size or 10;
			local font_bold = font.bold == true;
			if (self.m_cmd_state.m_font_family == font_family and self.m_cmd_state.m_font_size == font_size and self.m_cmd_state.m_font_bold == font_bold) then return end
			self.m_cmd_state.m_font_family = font_family;
			self.m_cmd_state.m_font_size = font_size;
			self.m_cmd_state.m_font_bold = font_bold
			self.m_cmd_state.m_font = nil;
			-- self:AppendCmdNoArgs(string_format("%s %s;%s;%s", "SetFont", font_family, tostring(font_size), font_bold and "bold" or ""));
			self:AppendCmdNoArgs({"%s %s;%s;%s", "SetFont", font_family, tostring(font_size), font_bold and "bold" or ""});
		end
		return;
	end
	ParaPainter.SetFont(font);
end

-- set current pen
-- @param pen: { width=1, brush = {color="#00000000", texture="filename or texture asset"}, }
-- or it can be {width=1, color="#000000", texture="filename or texture asset"}
-- or it can be pen color "#ff000000" or "255 255 255" or DWORD
function painter:SetPen(pen)
	if (isBatchCmdMode) then
		if (type(pen) == "string") or type(pen) == "number" then
			if (self.m_cmd_state.m_pen == pen) then return end
			self.m_cmd_state.m_pen = pen;
			self.m_cmd_state.m_pen_color = nil;
			self.m_cmd_state.m_pen_width = nil;
			self.m_cmd_state.m_pen_texture = nil;
			-- self:AppendCmdNoArgs(string_format("%s %s", "SetPen", self:EncodeCmdArg(pen)));
			self:AppendCmdNoArgs({"%s %s", "SetPen", self:EncodeCmdArg(pen)});
		elseif (type(pen) == "table") then
			if (pen.brush) then self:SetBrush(pen.brush) end
			local pen_color = pen.color or "#000000";
			local pen_width = pen.width or 0;
			local pen_texture = pen.texture or "";
			if (self.m_cmd_state.m_pen_color == pen_color and self.m_cmd_state.m_pen_width == pen_width and self.m_cmd_state.m_pen_texture == pen_texture) then return end
			self.m_cmd_state.m_pen_color = pen_color;
			self.m_cmd_state.m_pen_width = pen_width;
			self.m_cmd_state.m_pen_texture = pen_texture;
			self.m_cmd_state.m_pen = nil;
			-- self:AppendCmdNoArgs(string_format("%s %s %s %s", "SetPen", self:EncodeCmdArg(pen_color), tostring(pen_width), self:EncodeCmdArg(pen_texture)));
			self:AppendCmdNoArgs({"%s %s %s %s", "SetPen", self:EncodeCmdArg(pen_color), tostring(pen_width), self:EncodeCmdArg(pen_texture)});
		end
		return;
	end
	ParaPainter.SetPen(pen);
end

-- set current brush (texture and color)
-- @param brush: { color="#00000000", texture="filename or texture asset"} 
-- or it can be pen color "#ff000000" or "255 255 255" or DWORD
function painter:SetBrush(brush)
	if (isBatchCmdMode) then
		if (type(brush) == "string" or type(brush) == "number") then 
			if (self.m_cmd_state.m_brush == brush) then return end
			self.m_cmd_state.m_brush = brush;
			self.m_cmd_state.m_brush_color = nil;
			self.m_cmd_state.m_brush_texture = nil;
			-- self:AppendCmdNoArgs(string_format("%s %s", "SetBrush", self:EncodeCmdArg(brush)));
			self:AppendCmdNoArgs({"%s %s", "SetBrush", self:EncodeCmdArg(brush)});
		elseif (type(brush) == "table") then
			local brush_color = brush.color or "#000000";
			local brush_texture = brush.texture or ""
			if (self.m_cmd_state.m_brush_color == brush_color and self.m_cmd_state.m_brush_texture == brush_texture) then return end
			self.m_cmd_state.m_brush_color = brush_color;
			self.m_cmd_state.m_brush_texture = brush_texture;
			self.m_cmd_state.m_brush = nil;
			-- self:AppendCmdNoArgs(string_format("%s %s %s", "SetBrush", self:EncodeCmdArg(brush_color), self:EncodeCmdArg(brush_texture)));
			self:AppendCmdNoArgs({"%s %s %s", "SetBrush", self:EncodeCmdArg(brush_color), self:EncodeCmdArg(brush_texture)});
		end
		return;
	end
	ParaPainter.SetBrush(brush);
end

function painter:SetBrushOrigin(x, y)
	if (isBatchCmdMode) then 
		-- self:AppendCmdNoArgs(string_format("%s %d %d", "SetBrushOrigin", x or 0, y or 0));
		self:AppendCmdNoArgs({"%s %d %d", "SetBrushOrigin", x or 0, y or 0});
		return 
	end
	ParaPainter.SetBrushOrigin(x, y);
end

-- set current background brush
-- @param brush: { color="#00000000", texture="filename or texture asset"}
function painter:SetBackground(brush)
	if (isBatchCmdMode) then
		if (type(brush) == "string" or type(brush) == "number") then 
			-- self:AppendCmdNoArgs(string_format("%s %s", "SetBackground", self:EncodeCmdArg(brush)));
			self:AppendCmdNoArgs({"%s %s", "SetBackground", self:EncodeCmdArg(brush)});
		elseif (type(brush) == "table") then
			-- self:AppendCmdNoArgs(string_format("%s %s %s", "SetBackground", self:EncodeCmdArg(brush.color or "#000000"), self:EncodeCmdArg(brush.texture or "")));
			self:AppendCmdNoArgs({"%s %s %s", "SetBackground", self:EncodeCmdArg(brush.color or "#000000"), self:EncodeCmdArg(brush.texture or "")})
		end
		return;
	end
	ParaPainter.SetBackground(brush);
end

-- between [0,1]
function painter:SetOpacity(fOpacity)
	if (isBatchCmdMode) then 
		-- self:AppendCmdNoArgs(string_format("%s %d", "SetOpacity", fOpacity or 1));
		self:AppendCmdNoArgs({"%s %d", "SetOpacity", fOpacity or 1});
		return 
	end
	ParaPainter.SetOpacity(fOpacity);
end

function painter:SetClipRegion(x, y, w, h)
	if (isBatchCmdMode) then 
		-- self:AppendCmdNoArgs(string_format("%s %d %d %d %d", "SetClipRegion", x or 0, y or 0, w or 0, h or 0));
		self:AppendCmdNoArgs({"%s %d %d %d %d", "SetClipRegion", x or 0, y or 0, w or 0, h or 0});
		return 
	end
	ParaPainter.SetClipRegion(x, y, w, h);
end

function painter:SetClipping(enable)
	if (isBatchCmdMode) then 
		self.m_cmd_state.m_clipping = enable;
		-- self:AppendCmdNoArgs(string_format("%s %s", "SetClipping", enable and "1" or "0"));
		self:AppendCmdNoArgs({"%s %s", "SetClipping", enable and "1" or "0"});
		return 
	end
	ParaPainter.SetClipping(enable);
end

function painter:HasClipping()
	if (isBatchCmdMode) then 
		if (self.m_cmd_state.m_clipping ~= nil) then return self.m_cmd_state.m_clipping end
		return ParaPainter.HasClipping();
	end
	return ParaPainter.HasClipping();
end

-- Sets the world transformation matrix.
-- If combine is true, the specified matrix is combined with the current matrix; otherwise it replaces the current matrix.
function painter:SetTransform(trans, combine)
	ParaPainter.SetTransform(trans, combine);
end

function painter:GetTransform(out)
	return ParaPainter.GetTransform(out);
end

function painter:Scale(sx, sy)
	if (isBatchCmdMode) then 
		-- self:AppendCmdNoArgs(string_format("%s %d %d", "Scale", sx or 1, sy or 1));
		self:AppendCmdNoArgs({"%s %d %d", "Scale", sx or 1, sy or 1});
		return 
	end
	ParaPainter.Scale(sx, sy);
end

function painter:Shear(sh, sv)
	if (isBatchCmdMode) then 
		-- self:AppendCmdNoArgs(string_format("%s %d %d", "Shear", sh or 1, sv or 1));
		self:AppendCmdNoArgs({"%s %d %d", "Shear", sh or 1, sv or 1});
		return 
	end
	ParaPainter.Shear(sh, sv);
end

function painter:Rotate(a)
	if (isBatchCmdMode) then 
		-- self:AppendCmdNoArgs(string_format("%s %d", "Rotate", a or 0));
		self:AppendCmdNoArgs({"%s %d", "Rotate", a or 0});
		return 
	end
	ParaPainter.Rotate(a);
end

function painter:Translate(dx, dy)
	if (isBatchCmdMode) then 
		-- self:AppendCmdNoArgs(string_format("%s %d %d", "Translate", dx or 0, dy or 0));
		self:AppendCmdNoArgs({"%s %d %d", "Translate", dx or 0, dy or 0});
		return 
	end
	ParaPainter.Translate(dx, dy);
end

function painter:DrawPoint(x, y)
	if (isBatchCmdMode) then 
		-- self:AppendCmdNoArgs(string_format("%s %d %d", "DrawPoint", x or 0, y or 0));
		self:AppendCmdNoArgs({"%s %d %d", "DrawPoint", x or 0, y or 0});
		return 
	end
	ParaPainter.DrawPoint(x, y);
end

function painter:DrawLine(x1, y1, x2, y2)
	if (isBatchCmdMode) then 
		-- self:AppendCmdNoArgs(string_format("%s %d %d %d %d", "DrawLine", x1 or 0, y1 or 0, x2 or 0, y2 or 0));
		self:AppendCmdNoArgs({"%s %d %d %d %d", "DrawLine", x1 or 0, y1 or 0, x2 or 0, y2 or 0});
		return 
	end
	ParaPainter.DrawLine(x1, y1, x2, y2);
end

-- draw triangle List
--@param triangles: array of triangle vertices {{0,1,0}, {1,0,0}, {0,0,1}, ...}, 
--@param nTriangleCount: triangle count, default to #triangleList/ 3
--@param nIndexOffset: start index offset. default to 0.
function painter:DrawTriangleList(triangles, nTriangleCount, nIndexOffset)
	nTriangleCount = nTriangleCount or (#triangles) / 3;
	nIndexOffset = nIndexOffset or 0;
	if (isBatchCmdMode) then
		local cmd = "DrawTriangleList" .. " " .. tostring(nTriangleCount) .. " " .. tostring(nIndexOffset);
		local size = nTriangleCount * 3;
		if (type(triangles) == "table") then
			for i = 1, size do
				local v = triangles[i];
				-- cmd = cmd .. " " .. tostring(v[1]) .. " " .. tostring(v[2]) .. " " .. tostring(v[3]);
				cmd = string_format("%s %d %d %d", cmd, v[1] or 0, v[2] or 0, v[3] or 0);
			end
		else 
			for i = 0, size - 1 do
				local v = triangles[i];
				-- cmd = cmd .. " " .. tostring(v.x) .. " " .. tostring(v.y) .. " " .. tostring(v.z);
				cmd = string_format("%s %d %d %d", cmd, v.x or 0, v.y or 0, v.z or 0);
			end
		end
		self:AppendCmd(cmd);
		return;
	end
	ParaPainter.DrawTriangleList(triangles, nTriangleCount, nIndexOffset);
end

-- draw line List
--@param lineList: array of line vertices {{0,1,0}, {1,0,1},  ...}, 
--@param nlineCount: line count, default to #lineList/ 2
--@param nIndexOffset: start index offset. default to 0.
function painter:DrawLineList(lineList, nlineCount, nIndexOffset)
	nlineCount = nlineCount or (#lineList)/2;
	nIndexOffset = nIndexOffset or 0;
	if (isBatchCmdMode) then
		local cmd = "DrawLineList" .. " " .. tostring(nlineCount) .. " " .. tostring(nIndexOffset);
		local size = nlineCount * 2;
		if (type(lineList) == "table") then
			for i = 1, size do
				local v = lineList[i];
				-- cmd = cmd .. " " .. tostring(v[1]) .. " " .. tostring(v[2]) .. " " .. tostring(v[3]);
				cmd = string_format("%s %d %d %d", cmd, v[1] or 0, v[2] or 0, v[3] or 0);
			end
		else 
			for i = 0, size - 1 do
				local v = lineList[i];
				-- cmd = cmd .. " " .. tostring(v.x) .. " " .. tostring(v.y) .. " " .. tostring(v.z);
				cmd = string_format("%s %d %d %d", cmd, v.x or 0, v.y or 0, v.z or 0);
			end
		end
		self:AppendCmd(cmd);
		return;
	end
	ParaPainter.DrawLineList(lineList, nlineCount, nIndexOffset);
end

function painter:DrawRect(left, top, width, height)
	if(left and top and width and height) then
		if (isBatchCmdMode) then
			-- self:AppendCmdNoArgs(string_format("%s %d %d %d %d", "DrawRect", left, top, width, height));
			self:AppendCmdNoArgs({"%s %d %d %d %d", "DrawRect", left, top, width, height});
			return;
		end
		ParaPainter.DrawRect(left, top, width, height);
	else
		echo("invalid DrawRect:"..tostring(commonlib.debugstack(2, 5, 1)));
	end
end

function painter:DrawTexture(x, y, w, h, pTexture, sx, sy, sw, sh)
	if (isBatchCmdMode) then
		if (sx) then
			-- self:AppendCmdNoArgs(string_format("%s %d %d %d %d %s %d %d %d %d", "DrawTexture", x, y, w, h, self:EncodeCmdArg(pTexture), sx, sy, sw, sh));
			self:AppendCmdNoArgs({"%s %d %d %d %d %s %d %d %d %d", "DrawTexture", x, y, w, h, self:EncodeCmdArg(pTexture), sx, sy, sw, sh});
		else 
			-- self:AppendCmdNoArgs(string_format("%s %d %d %d %d %s", "DrawTexture", x, y, w, h, self:EncodeCmdArg(pTexture)));
			self:AppendCmdNoArgs({"%s %d %d %d %d %s", "DrawTexture", x, y, w, h, self:EncodeCmdArg(pTexture)});
		end
		return;
	end
	
	if(sx) then
		ParaPainter.DrawTexture(x, y, w, h, pTexture, sx, sy, sw, sh);
	else
		ParaPainter.DrawTexture(x, y, w, h, pTexture);
	end
end

-- @param w, h: if h is nil, w is the sText
function painter:DrawText(x, y, w, h, sText, textOption)
	if (isBatchCmdMode) then
		if (h and sText) then
			-- self:AppendCmdNoArgs(string_format("%s %d %d %d %d %s %s", "DrawText", x or 0, y or 0, w or -1, h or -1, sText and self:EncodeCmdArg(sText) or sText, tostring(textOption or "")));
			self:AppendCmdNoArgs({"%s %d %d %d %d %s %s", "DrawText", x or 0, y or 0, w or -1, h or -1, sText and self:EncodeCmdArg(sText) or sText, tostring(textOption or "")});
		else 
			-- self:AppendCmdNoArgs(string_format("%s %d %d %d %d %s", "DrawText", x or 0, y or 0, -1, -1, w and self:EncodeCmdArg(w) or w));
			self:AppendCmdNoArgs({"%s %d %d %d %d %s", "DrawText", x or 0, y or 0, -1, -1, w and self:EncodeCmdArg(w) or w});
		end
		return;
	end
	if(h and sText) then
		ParaPainter.DrawText(x, y, w, h, sText, textOption);
	else
		ParaPainter.DrawText(x, y, w);
	end
end

-- helper function:
-- @param scale: text scale. if nil or 1, it is same as DrawText()
function painter:DrawTextScaled(x, y, text, scale)
	if(text and text~="") then
		if(scale and scale~=1) then
			self:Save();
			self:Translate(x,y);
			self:Scale(scale, scale);
			self:DrawText(0,0, text);
			self:Restore();
		else
			self:DrawText(x,y, text);
		end
	end
end

-- Set the text align and other text displaying formats
-- @param alignment: It can be any combination of the following values.
-- DT_BOTTOM (0x00000008)
-- Justifies the text to the bottom of the rectangle. This value must be combined with DT_SINGLELINE.
-- DT_CALCRECT (0x00000400)
-- Determines the width and height of the rectangle. If there are multiple lines of text, ID3DXFont::DrawText uses the width of the rectangle pointed to by the pRect parameter and extends the base of the rectangle to bound the last line of text. If there is only one line of text, ID3DXFont::DrawText modifies the right side of the rectangle so that it bounds the last character in the line. In either case, ID3DXFont::DrawText returns the height of the formatted text but does not draw the text.
-- DT_CENTER (0x00000001)
-- Centers text horizontally in the rectangle.
-- DT_EXPANDTABS (0x00000040)
-- Expands tab characters. The default number of characters per tab is eight.
-- DT_LEFT (0x00000000)
-- Aligns text to the left.
-- DT_NOCLIP (0x00000100)
-- Draws without clipping. ID3DXFont::DrawText is somewhat faster when DT_NOCLIP is used.
-- DT_RIGHT (0x00000002)
-- Aligns text to the right.
-- DT_RTLREADING
-- Displays text in right-to-left reading order for bi-directional text when a Hebrew or Arabic font is selected. The default reading order for all text is left-to-right.
-- DT_SINGLELINE (0x00000020)
-- Displays text on a single line only. Carriage returns and line feeds do not break the line.
-- DT_TOP (0x00000000)
-- Top-justifies text.
-- DT_VCENTER (0x00000004)
-- Centers text vertically (single line only).
-- DT_WORDBREAK (0x00000010)
-- Breaks words. Lines are automatically broken between words if a word would extend past the edge of the rectangle specified by the pRect parameter. A carriage return/line feed sequence also breaks the line.
function painter:DrawTextScaledEx(x, y, width, height, text, alignment, scale)
	if(text and text~="") then
		if(scale and scale~=1) then
			self:Save();
			self:Translate(x,y);
			self:Scale(scale, scale);
			self:DrawText(0,0, width, height, tostring(text), alignment);
			self:Restore();
		else
			self:DrawText(x,y, width, height, text, alignment);
		end
	end
end


-- helper function: 
-- @param texture: if nil or "" or "Texture/whitedot.png", it will render with current pen color. 
-- otherwise it can also be single or 9-tiled texture
function painter:DrawRectTexture(x, y, width, height, texture)
	if(texture and texture~="" and texture~="Texture/whitedot.png") then
		self:DrawTexture(x, y, width, height, texture);
	else
		self:DrawRect(x, y, width, height);
	end
end

-- draw a scene object 
-- @param obj: can be a character or model object. 
-- @param nOption: default to 0, which renders using the transform of the scene object. 
function painter:DrawSceneObject(obj, nOption)
	ParaPainter.DrawSceneObject(obj, nOption or 0);
end

-----------------------------------
-- 3d transform related. only useful in 3d mode such as rendering overlays.
-----------------------------------

-- whether we are using the 3d world transform, this is always true for overlay and 3d text.
function painter:SetUseWorldMatrix(bEnable)
	if (isBatchCmdMode) then
		self.m_cmd_state.m_use_world_matrix = bEnable == true;
		-- self:AppendCmdNoArgs(string_format("%s %s", "SetUseWorldMatrix", self.m_cmd_state.m_use_world_matrix and "1" or "0"))
		self:AppendCmdNoArgs({"%s %s", "SetUseWorldMatrix", self.m_cmd_state.m_use_world_matrix and "1" or "0"});
		return;
	end
	ParaPainter.SetField("UseWorldMatrix", bEnable == true);
end

-- whether we are using the 3d world transform, this is always true for overlay and 3d text.
function painter:IsUseWorldMatrix()
	if (isBatchCmdMode) then
		if (self.m_cmd_state.m_use_world_matrix ~= nil) then return self.m_cmd_state.m_use_world_matrix end
		return ParaPainter.GetField("UseWorldMatrix", false);
	end
	return ParaPainter.GetField("UseWorldMatrix", false);
end

-- similar to glMatrixMode() in opengl. 
-- one usually needs to call self:LoadCurrentMatrix() immediately after this function.
-- @param nMode:  0 is world, 1 is view, 2 is projection. default to 0. 
function painter:SetMatrixMode(nMode)
	if (isBatchCmdMode) then
		self.m_cmd_state.m_matrix_mode = nMode;
		-- self:AppendCmdNoArgs(string_format("%s %s", "SetMatrixMode", tostring(nMode)));
		self:AppendCmdNoArgs({"%s %s", "SetMatrixMode", tostring(nMode)});
		return;
	end
	ParaPainter.SetField("MatrixMode", nMode);
end

function painter:GetMatrixMode()
	if (isBatchCmdMode) then
		if (self.m_cmd_state.m_matrix_mode ~= nil) then return self.m_cmd_state.m_matrix_mode end
		return ParaPainter.GetField("MatrixMode", 0);
	end
	return ParaPainter.GetField("MatrixMode", 0);
end
		
-- similar to glPushMatrix() in opengl.
function painter:PushMatrix()
	if (isBatchCmdMode) then
		self:AppendCmdNoArgs("PushMatrix");
		return;
	end
	ParaPainter.CallField("PushMatrix");
end

-- similar to glPopMatrix() in opengl.
function painter:PopMatrix()
	if (isBatchCmdMode) then
		self:AppendCmdNoArgs("PopMatrix");
		return;
	end
	ParaPainter.CallField("PopMatrix");
end

-- retrieve the current matrix. 
function painter:LoadCurrentMatrix()
	if (isBatchCmdMode) then
		self:AppendCmdNoArgs("LoadCurrentMatrix");
		return;
	end
	ParaPainter.CallField("LoadCurrentMatrix");
end

-- load identity matrix 
function painter:LoadIdentityMatrix()
	if (isBatchCmdMode) then
		self:AppendCmdNoArgs("LoadIdentityMatrix");
		return;
	end
	ParaPainter.CallField("LoadIdentityMatrix");
end

-- load billboard matrix, so that everything rendered (including text) always face the camera.
function painter:LoadBillboardMatrix()
	if (isBatchCmdMode) then
		self:AppendCmdNoArgs("LoadBillboardMatrix");
		return;
	end
	ParaPainter.CallField("LoadBillboardMatrix");
end

-- we use row-major matrix 
-- @param mat: both 4*3 or 4*4 matrix are fine
function painter:LoadMatrix(mat)
	if (isBatchCmdMode) then
		self:AppendCmd("LoadMatrix", mat);
		return;
	end
	ParaPainter.SetField("LoadMatrix", mat);
end

-- multiply the current matrix with the specified matrix. we use row-major matrix 
function painter:MultiplyMatrix(mat)
	if (isBatchCmdMode) then
		self:AppendCmd("MultiplyMatrix", mat);
		return;
	end
	ParaPainter.SetField("MultiplyMatrix", mat);
end

local tmpVec3d = {};
-- multiply the current matrix by a translation matrix 
function painter:TranslateMatrix(x, y, z)
	if (isBatchCmdMode) then
		-- self:AppendCmdNoArgs(string_format("%s %f %f %f", "TranslateMatrix", x or 0, y or 0, z or 0));
		self:AppendCmdNoArgs({"%s %f %f %f", "TranslateMatrix", x or 0, y or 0, z or 0});
		return;
	end
	tmpVec3d[1], tmpVec3d[2], tmpVec3d[3] = x, y, z;
	ParaPainter.SetField("TranslateMatrix", tmpVec3d);
end

local tmpVec4d = {};
-- multiply the current matrix by a rotation matrix 
function painter:RotateMatrix(angle, x, y, z)
	if (isBatchCmdMode) then
		-- self:AppendCmdNoArgs(string_format("%s %f %f %f %f", "RotateMatrix", angle or 0, x or 0, y or 0, z or 0));
		self:AppendCmdNoArgs({"%s %f %f %f %f", "RotateMatrix", angle or 0, x or 0, y or 0, z or 0});
		return ;
	end
	tmpVec4d[1], tmpVec4d[2], tmpVec4d[3], tmpVec4d[4] = angle, x, y, z;
	ParaPainter.SetField("RotateMatrix", tmpVec4d);
end

-- multiply the current matrix by a scaling matrix 
function painter:ScaleMatrix(x, y, z)
	if (isBatchCmdMode) then
		-- self:AppendCmdNoArgs(string_format("%s %f %f %f", "ScaleMatrix", x or 1, y or 1, z or 1));
		self:AppendCmdNoArgs({"%s %f %f %f", "ScaleMatrix", x or 1, y or 1, z or 1});
		return;
	end
	tmpVec3d[1], tmpVec3d[2], tmpVec3d[3] = x, y, z;
	ParaPainter.SetField("ScaleMatrix", tmpVec3d);
end

-- get current scaling. 
-- @return x,y,z of current scaling. 
function painter:GetScaling()
	return unpack(ParaPainter.GetField("Scaling", tmpVec3d));
end

-- get current matrix
-- @return a new Matrix4
function painter:GetCurrentMatrix()
	return ParaPainter.GetField("CurrentMatrix", Matrix4:new());
end

-- if enabled, the minimum line width is 1 pixel for 3d lines.
-- @param bEnable: if nil or true, it means true
function painter:EnableAutoLineWidth(bEnable)
	if (isBatchCmdMode) then
		-- self:AppendCmdNoArgs(string_format("%s %s", "EnableAutoLineWidth", bEnable~=false and "1" or "0"))
		self:AppendCmdNoArgs({"%s %s", "EnableAutoLineWidth", bEnable~=false and "1" or "0"});
		return;
	end
	ParaPainter.SetField("AutoLineWidth", bEnable~=false);
end


-- draw a circle perpendicular to a specified axis with center and radius
-- @param axis: "x", "y", "z". perpendicular to which axis
-- @param bFill: if true (default to nil), we will fill the circle with current brush 
-- @param segment: if nil, we will automatically determine segment by radius. 
-- @param fromAngle: default to 0;
-- @param toAngle: default to 2*math.pi;
-- @param center_offset: default to 0.
function painter:DrawCircle(cx,cy,cz, radius, axis, bFill, segment, fromAngle, toAngle, center_offset)
	ShapesDrawer.DrawCircle(self, cx,cy,cz, radius, axis, bFill, segment, fromAngle, toAngle, center_offset);
end