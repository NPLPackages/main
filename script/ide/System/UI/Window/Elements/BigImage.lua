--[[
Title: BigImage
Author(s): wxa
Date: 2020/8/14
Desc: 图片
-------------------------------------------------------
local BigImage = NPL.load("script/ide/System/UI/Window/Elements/BigImage.lua");
-------------------------------------------------------
]]


local Element = NPL.load("../Element.lua");
local BigImage = commonlib.inherit(Element, NPL.export());

BigImage:Property("Name", "BigImage");

function BigImage:ctor()
    self.bg_x, self.bg_y = 0, 0;
    self.bg_offset_x, self.bg_offset_y = 0, 0;
end

function BigImage:GetBackground()
    return self:GetAttrStringValue("src") or Image._super.GetBackground(self);
end

function BigImage:GetBGArea()
    local bg_area_x = self:GetAttrNumberValue("x", 0);
    local bg_area_y = self:GetAttrNumberValue("y", 0);
    local bg_area_w = self:GetAttrNumberValue("w", 0);
    local bg_area_h = self:GetAttrNumberValue("h", 0);
    return bg_area_x, bg_area_y, bg_area_w, bg_area_h;
end

function BigImage:Init(xmlNode, window, parent)
    BigImage._super.Init(self, xmlNode, window, parent);
    
    return self;
end

function BigImage:RenderBackground(painter)
    local background, backgroundColor = self:GetBackground(), self:GetBackgroundColor();
    local x, y, w, h = self:GetGeometry();
    local bg_area_x, bg_area_y, bg_area_w, bg_area_h = self:GetBGArea();
    local left = bg_area_x + self.bg_x + self.bg_offset_x;
    local top = bg_area_y + self.bg_y + self.bg_offset_y;
    local width = math.min(w, bg_area_w);
    local height = math.min(h, bg_area_h);
    painter:SetPen(backgroundColor or "#ffffff");
    -- print(x, y, w, h, left, top, width, height);
    if (width < w and height < h) then
        painter:DrawRectTexture(x + (w - width) / 2 , y + (h - height) / 2, width, height, string.format("%s#%s %s %s %s", background, left, top, width, height));
    elseif (width < w and height >= h) then
        painter:DrawRectTexture(x + (w - width) / 2 , y, width, h, string.format("%s#%s %s %s %s", background, left, top, width, height));
    elseif (width >= w and height < h) then
        painter:DrawRectTexture(x, y + (h - height) / 2, w, height, string.format("%s#%s %s %s %s", background, left, top, width, height));
    else
        painter:DrawRectTexture(x, y, w, h, string.format("%s#%s %s %s %s", background, left, top, width, height));
    end
end


function BigImage:OnMouseDown(event)
    BigImage._super.OnMouseDown(self, event);
    local x, y, w, h = self:GetGeometry();
    local bg_area_x, bg_area_y, bg_area_w, bg_area_h = self:GetBGArea();
    if (h >= bg_area_h) then return end

    -- 默认拖拽处理
    if(event:IsLeftButton()) then
        self.isMouseDown = true;
        self.isDragging = false;
        if (self:IsWindow()) then
            self.startDragX, self.startDragY = event:GetScreenXY();
        else 
            self.startDragX, self.startDragY = event:GetWindowXY();
        end
        self.startDragElementX, self.startDragElementY = self:GetPosition();
        self.startDragScreenX, self.startDragScreenY = self:GetWindow():GetScreenPosition();
        event:Accept();
    end
end

function BigImage:OnMouseMove(event)
    BigImage._super.OnMouseMove(self, event);
    local x, y, w, h = self:GetGeometry();
    local bg_area_x, bg_area_y, bg_area_w, bg_area_h = self:GetBGArea();

    if(self.isMouseDown and event:IsLeftButton()) then
        if(not self.isDragging and not event:IsMove()) then return end
        
        if (self:IsWindow()) then 
            self.DragMoveX, self.DragMoveY = event:GetScreenXY();
        else
            self.DragMoveX, self.DragMoveY = event:GetWindowXY();
        end

        -- self.bg_offset_x = math.floor(self.DragMoveX - self.startDragX);
        self.bg_offset_y = math.floor(self.DragMoveY - self.startDragY);
        if ((self.bg_y + self.bg_offset_y + h) > bg_area_h) then self.bg_offset_y = bg_area_h - h - self.bg_y end
        if ((self.bg_y + self.bg_offset_y) < 0) then self.bg_offset_y = - self.bg_y end

        self.isDragging = true;
        self:CaptureMouse();
        event:Accept();
    end

end

function BigImage:OnMouseUp(event)
    BigImage._super.OnMouseMove(self, event);
    
    if(self.isDragging) then
        self.isDragging = false;
        self:ReleaseMouseCapture();
        self.bg_x = self.bg_x + self.bg_offset_x;
        self.bg_y = self.bg_y + self.bg_offset_y;
        self.bg_offset_x, self.bg_offset_y = 0, 0;
        event:Accept();
    end

    self.isMouseDown = false;
end

function BigImage:OnMouseWheel(event)
    local delta = event:GetDelta();  -- 1 向上滚动  -1 向下滚动
    local h = self:GetHeight();
    local bg_area_x, bg_area_y, bg_area_w, bg_area_h = self:GetBGArea();
    self.bg_y = self.bg_y - math.floor(h * delta / 10);
    self.bg_y = self.bg_y < 0 and 0 or self.bg_y;
    if ((self.bg_y + h) > bg_area_h) then self.bg_y = bg_area_h - h end
end
