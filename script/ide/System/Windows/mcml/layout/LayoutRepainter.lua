--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutRepainter.lua");
local LayoutRepainter = commonlib.gettable("System.Windows.mcml.layout.LayoutRepainter");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObject.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
local IntRect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
local LayoutRepainter = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.LayoutRepainter"));

function LayoutRepainter:ctor()
	self.object = nil;
    self.repaintContainer = nil;
    self.oldBounds = IntRect:new();
    self.oldOutlineBox = IntRect:new();
    self.checkForRepaint = false;
end

--function LayoutRepainter:init(RenderObject&, bool checkForRepaint, const IntRect* oldBounds = 0)
function LayoutRepainter:init(object, checkForRepaint, oldBounds)
	self.object = object;
	self.checkForRepaint = checkForRepaint;

	if(self.checkForRepaint) then
		self.repaintContainer = self.object:ContainerForRepaint();
		self.oldBounds = if_else(oldBounds, oldBounds ,self.object:ClippedOverflowRectForRepaint(self.repaintContainer));
		self.oldOutlineBox = self.object:OutlineBoundsForRepaint(self.repaintContainer)
	end

	return self;
end

function LayoutRepainter:CheckForRepaint()
	return self.checkForRepaint;
end

-- Return true if it repainted.
function LayoutRepainter:RepaintAfterLayout()
	if(self.checkForRepaint) then
		self.object:RepaintAfterLayoutIfNeeded(self.repaintContainer, self.oldBounds, self.oldOutlineBox)
	end
	return false;
	
end