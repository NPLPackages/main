--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBoxModelObject.lua");
local LayoutBoxModelObject = commonlib.gettable("System.Windows.mcml.layout.LayoutBoxModelObject");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObject.lua");
local LayoutBoxModelObject = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutObject"), commonlib.gettable("System.Windows.mcml.layout.LayoutBoxModelObject"));

function LayoutBoxModelObject:ctor()
--	self.border = nil;
--	self.content = nil;
--
--
--		-- the next available renderable position 
--	self.availableX = 0;
--	self.availableY = 0;
--	-- the next new line position
--	self.newlineX = 0;
--	self.newlineY = 0;
--	-- the current preferred size of the container control. It may be enlarged by child controls. 
--	self.width = 0;
--	self.height = 0;
--	-- the min region in the container control which is occupied by its child controls
--	self.usedWidth = 0;
--	self.usedHeight = 0;
--	-- the real region in the container control which is occupied by its child controls
--	self.realWidth = 0;
--	self.realHeight = 0;
--
end

----param new_child: a LayoutObject
--function LayoutBoxModelObject:AddChild(new_child)
--	
--end

function LayoutBoxModelObject:BorderTop()
	return self:Style():BorderTopWidth();
end

function LayoutBoxModelObject:BorderBottom()
	return self:Style():BorderBottomWidth();
end

function LayoutBoxModelObject:BorderLeft()
	return self:Style():BorderLeftWidth();
end

function LayoutBoxModelObject:BorderRight()
	return self:Style():BorderRightWidth();
end

function LayoutBoxModelObject:BorderBefore()
	return self:Style():BorderBeforeWidth();
end

function LayoutBoxModelObject:BorderAfter()
	return self:Style():BorderAfterWidth();
end

function LayoutBoxModelObject:BorderStart()
	return self:Style():BorderStartWidth();
end

function LayoutBoxModelObject:BorderEnd()
	return self:Style():BorderEndWidth();
end

function LayoutBoxModelObject:BorderAndPaddingHeight()
	return self:BorderTop() + self:BorderBottom() + self:PaddingTop() + self:PaddingBottom();
end

function LayoutBoxModelObject:BorderAndPaddingWidth()
	return self:BorderLeft() + self:BorderRight() + self:PaddingLeft() + self:PaddingRight();
end

function LayoutBoxModelObject:BorderAndPaddingLogicalHeight()
	return self:BorderBefore() + self:BorderAfter() + self:PaddingBefore() + self:PaddingAfter();
end

function LayoutBoxModelObject:BorderAndPaddingLogicalWidth()
	return self:BorderStart() + self:BorderEnd() + self:PaddingStart() + self:PaddingEnd();
end

function LayoutBoxModelObject:BorderAndPaddingLogicalLeft()
	local left = self:BorderLeft() + self:PaddingLeft();
	if(not self:Style():IsHorizontalWritingMode()) then
		left = self:BorderTop() + self:PaddingTop();
	end
	return left;
	--return self:Style():IsHorizontalWritingMode() ? self:BorderLeft() + self:PaddingLeft() : self:BorderTop() + self:PaddingTop();
end

function LayoutBoxModelObject:BorderAndPaddingStart()
	return self:BorderStart() + self:PaddingStart();
end

function LayoutBoxModelObject:BorderLogicalLeft()
	local left = self:BorderLeft();
	if(not self:Style():IsHorizontalWritingMode()) then
		left = self:BorderTop();
	end
	return left;
	--return self:Style():IsHorizontalWritingMode() ? self:BorderLeft() : self:BorderTop();
end

function LayoutBoxModelObject:BorderLogicalRight()
	local right = self:BorderRight();
	if(not self:Style():IsHorizontalWritingMode()) then
		right = self:BorderBottom();
	end
	return right;
	--return self:Style():IsHorizontalWritingMode() ? self:BorderRight() : self:BorderBottom();
end

function LayoutBoxModelObject:PaddingLeft()
	return self:Style():PaddingLeft();
end

function LayoutBoxModelObject:PaddingTop()
	return self:Style():PaddingTop();
end

function LayoutBoxModelObject:PaddingRight()
	return self:Style():PaddingRight();
end

function LayoutBoxModelObject:PaddingBottom()
	return self:Style():PaddingBottom();
end

function LayoutBoxModelObject:PaddingBefore(includeIntrinsicPadding)
	return self:Style():PaddingBefore();
end

function LayoutBoxModelObject:PaddingAfter(includeIntrinsicPadding)
	return self:Style():PaddingAfter();
end

function LayoutBoxModelObject:PaddingStart(includeIntrinsicPadding)
	return self:Style():PaddingStart();
end

function LayoutBoxModelObject:PaddingEnd(includeIntrinsicPadding)
	return self:Style():PaddingEnd();
end


function LayoutBoxModelObject:MarginLeft()
	--return self:Style():MarginLeft();
end

function LayoutBoxModelObject:MarginTop()
	--return self:Style():MarginTop();
end

function LayoutBoxModelObject:MarginRight()
	--return self:Style():MarginRight();
end

function LayoutBoxModelObject:MarginBottom()
	--return self:Style():MarginBottom();
end

function LayoutBoxModelObject:Float()
	return self:Style():Float();
end

function LayoutBoxModelObject:Left()
	return self:Style():Left();
end

function LayoutBoxModelObject:Top()
	return self:Style():Top();
end

function LayoutBoxModelObject:Right()
	return self:Style():Right();
end

function LayoutBoxModelObject:Bottom()
	return self:Style():Bottom();
end

function LayoutBoxModelObject:BeWidthAuto()
	if(self:Style():Width() or self.pageElement:GetAttribute("width", nil)) then
		return false;
	end
	return true;
end

function LayoutBoxModelObject:BeHeightAuto()
	if(self:Style():Height() or self.pageElement:GetAttribute("height", nil)) then
		return false;
	end
	return true;
end

function LayoutBoxModelObject:beFixedLayout()
	local css = self:Style();
	local css_width, css_height = css:Width(), css:Height();
	if(type(css_width) == "number" and type(css_height) == "number") then
		return true;
	end
	return false;
end

-- virtual function
function LayoutBoxModelObject:BorderBoundingBox()
	
end

-- The HashMap for storing continuation pointers.
-- An inline can be split with blocks occuring in between the inline content.
-- When this occurs we need a pointer to the next object. We can basically be
-- split into a sequence of inlines and blocks. The continuation will either be
-- an anonymous block (that houses other blocks) or it will be an inline flow.
-- <b><i><p>Hello</p></i></b>. In this example the <i> will have a block as
-- its continuation but the <b> will just have an inline as its continuation.
local continuationMap = nil;

function LayoutBoxModelObject:Continuation()
	if(not continuationMap) then
		return;
	end
	return continuationMap[self];
end