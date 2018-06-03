--[[
Title: 
Author(s): LiPeng
Date: 2018/2/1
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL/RingBuffer.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntPoint.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
local Size = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local Point = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");
local temp_pool = commonlib.RingBuffer:new(); 
local type = type;
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
Rect.__index = Rect;

-- create a new Rect
function Rect:new(x,y,width,height)
	local o = {};
	local x_, y_, width_, height_ = 0, 0, 0, 0;
	if(width) then
		x_, y_, width_, height_ = x, y, width, height;
	elseif (y) then
		x_, y_, width_, height_ = x:X(), x:Y(), y:Width(), y:Height();
	elseif (x) then
		x_, y_, width_, height_ = x:X(), x:Y(), x:Width(), x:Height();
	end
	o.location = Point:new(x_, y_);
	o.size = Size:new(width_, height_);
	setmetatable(o, self);
	return o;
end

function Rect:init(x,y,width,height)
	self:Reset(x_, y_, width_, height_);
	return self;
end

function Rect:Reset(x,y,width,height)
	local x_, y_, width_, height_ = 0, 0, 0, 0;
	if(width) then
		x_, y_, width_, height_ = x, y, width, height;
	elseif (y) then
		x_, y_, width_, height_ = x:X(), x:Y(), y:Width(), y:Height();
	elseif (x) then
		x_, y_, width_, height_ = x:X(), x:Y(), x:Width(), x:Height();
	end

	self.location:Reset(x_, y_);
	self.size:Reset(width_, height_);
end

-- this is actually a ring buffer of 200, pay attention not to reach over this value in recursive calls. 
function Rect:new_from_pool(x,y,width,height)
	if(temp_pool:size() >= 2000) then
		return temp_pool:next():Reset(x,y,width,height);
	else
		return temp_pool:add(Rect:new(x,y,width,height));
	end
end

--function Rect:Create(x,y,beFromPool)
--	if(beFromPool) then
--		return Point:new_from_pool(x,y);
--	end
--	return Point:new(x,y);
--end

-- make a clone 
function Rect:clone()
    return Rect:new(self.location, self.size);
end

function Rect:clone_from_pool()
	return self:new_from_pool(self.location, self.size);
end

function Rect:Location()
	return self.location;
end

function Rect:Size()
	return self.size;
end

function Rect:SetLocation(location)
	self.location = location;
end

function Rect:SetSize(size)
	self.size = size;
end

function Rect:X()
	return self.location:X();
end

function Rect:Y()
	return self.location:Y();
end

function Rect:SetX(x)
	return self.location:SetX(x);
end

function Rect:SetY(y)
	return self.location:SetY(y);
end

function Rect:Width()
	return self.size:Width();
end

function Rect:Height()
	return self.size:Height();
end

function Rect:SetWidth(width)
	return self.size:SetWidth(width);
end

function Rect:SetHeight(height)
	return self.size:SetHeight(height);
end

function Rect:MaxX()
	return self:X() + self:Width();
end

function Rect:MaxY()
	return self:Y() + self:Height();
end

function Rect:IsEmpty()
	return self.size:IsEmpty();
end

function Rect:Center()
	local x = math.round(self:X() + self:Width()/2);
	local y = math.round(self:Y() + self:Height()/2);
	return Point:new(x,y);
end

function Rect:Move(dx, dy)
	if(not dy) then
		local size = dx;
		dx = size:Width();
		dy = size:Height();
	end
	self.location:Move(dx,dy);
end

--@param offset: Point
function Rect:MoveBy(offset)
	self.location:Move(offset:X(),offset:Y());
end

function Rect:Expand(dw,dh)
	if(not dh) then
		local size = dw;
		dw = size:Width();
		dh = size:Height();
	end
	self.size:Expand(dw,dh);
end

function Rect:Contract(dw,dh)
	if(not dh) then
		local size = dw;
		dw = size:Width();
		dh = size:Height();
	end
	self.size:Expand(-dw,-dh);
end

function Rect:ShiftXEdgeTo(edge)
	local delta = edge - self:X();
	self:SetX(edge);
	self:SetWidth(math.max(0, self:Width() - delta));
end

function Rect:ShiftMaxXEdgeTo(edge)
	local delta = edge - self:MaxX();
	self:SetWidth(math.max(0, self:Width() + delta));
end

function Rect:ShiftYEdgeTo(edge)
	local delta = edge - self:Y();
	self:SetY(edge);
	self:SetHeight(math.max(0, self:Height() - delta));
end

function Rect:ShiftMaxYEdgeTo(edge)
	local delta = edge - self:MaxY();
	self:SetHeight(math.max(0, self:Height() + delta));
end

-- topleft
function Rect:MinXMinYCorner()
	return self.location;
end

function Rect:MaxXMinYCorner()
	local x = self.location:X() + self.size:Width();
	local y = self.location:Y();
	return Point:new(x,y);
end

function Rect:MinXMaxYCorner()
	local x = self.location:X();
	local y = self.location:Y() + self.size:Height();
	return Point:new(x,y);
end

function Rect:MaxXMaxYCorner()
	local x = self.location:X() + self.size:Width();
	local y = self.location:Y() + self.size:Height();
	return Point:new(x,y);
end

-- whether intersect with rect
function Rect:Intersects(rect)
	if(not self:IsEmpty() and not rect:IsEmpty()) then
		if(self:X() < rect:MaxX() and rect:X() < self:MaxX() and self:Y() < rect:MaxY() and rect:Y() < self:MaxY()) then
			return true;
		end
	end
	return false;
end

function Rect:ContainsRect(rect)
	return self:X() <= rect:X() and self:MaxX() >= rect:MaxX() and self:Y() <= rect:Y() and self:MaxY() >= rect:MaxY();
end

function Rect:Contains(px,py)
	if(px.location and px.size) then
		-- px is rect;
		return self:ContainsRect(px);
	elseif(not y) then
		local point = px;
		px = point:X();
		py = point:Y();
	end
	return px >= self:X() and px < self:MaxX() and py >= self:Y() and py < self:MaxY();
end

function Rect:Intersect(rect)
	local l = math.max(self:X(), rect:X());
    local t = math.max(self:Y(), rect:Y());
    local r = math.min(self:MaxX(), rect:MaxX());
    local b = math.min(self:MaxY(), rect:MaxY());

    -- Return a clean empty rectangle for non-intersecting cases.
    if (l >= r or t >= b) then
        l = 0;
        t = 0;
        r = 0;
        b = 0;
    end

    self.location:SetX(l);
    self.location:SetY(t);
    self.size:SetWidth(r - l);
    self.size:SetHeight(b - t);
end

function Rect:Unite(rect)
	if(rect:IsEmpty()) then
		return
	end
	if(self:IsEmpty()) then
		self.location = rect.location;
		self.size = rect.size;
		return;
	end

	local l = math.min(self:X(), rect:X());
    local t = math.min(self:Y(), rect:Y());
    local r = math.max(self:MaxX(), rect:MaxX());
    local b = math.max(self:MaxY(), rect:MaxY());

    self.location:SetX(l);
    self.location:SetY(t);
    self.size:SetWidth(r - l);
    self.size:SetHeight(b - t);
end

function Rect:UniteIfNonZero(rect)
	if(rect:IsZero()) then
		return
	end
	if(self:IsZero()) then
		self.location = rect.location;
		self.size = rect.size;
		return;
	end

	local l = math.min(self:X(), rect:X());
    local t = math.min(self:Y(), rect:Y());
    local r = math.max(self:MaxX(), rect:MaxX());
    local b = math.max(self:MaxY(), rect:MaxY());

    self.location:SetX(l);
    self.location:SetY(t);
    self.size:SetWidth(r - l);
    self.size:SetHeight(b - t);
end

function Rect:InflateX(dx)
	self.location:SetX(self.location:X() - dx);
	self.size:SetWidth(self.size:Width() + dx + dx);
end

function Rect:InflateY(dy)
	self.location:SetY(self.location:Y() - dy);
	self.size:SetHeight(self.size:Height() + dy + dy);
end

function Rect:Inflate(d)
	self:InflateX(d);
	self:InflateY(d);
end

function Rect:Scale(s)
	local x = math.round(self:X()*s);
	local y = math.round(self:Y()*s);
	local width = math.round(self:Width()*s);
	local height = math.round(self:Height()*s);
	self.location:SetX(x);
	self.location:SetY(y);
	self.size:SetWidth(width);
	self.size:SetHeight(height);
end

function Rect:TransposedRect()
	return Rect:new(self.location:TransposedPoint(), self.size:TransposedSize());
end

--inline IntRect intersection(const IntRect& a, const IntRect& b)
function Rect.Intersection(a, b)
    local c = a:clone();
    c:Intersect(b);
    return c;
end

-- inline IntRect unionRect(const IntRect& a, const IntRect& b)
-- IntRect unionRect(const Vector<IntRect>& rects)
function Rect.UnionRect(a, b)
	local rects = a;
	if(b) then
		rects = {a, b};
	end
	
	local result = Rect:new();
	for i = 1,#rects do
		result:Unite(rects[i]);
	end
	return result;
end

function Rect.__eq(a,b)
	return a.location == b.location and a.size == b.size;
end

function Rect:IsPoint()
	return false;
end

function Rect:IsSize()
	return false;
end

function Rect:IsRect()
	return true;
end

function Rect:Type()
	return "Rect";
end