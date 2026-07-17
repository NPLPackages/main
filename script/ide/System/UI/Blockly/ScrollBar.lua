
--[[
Title: ScrollBar
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local ScrollBar = NPL.load("script/ide/System/UI/Blockly/ScrollBar.lua");
-------------------------------------------------------
]]

local Const = NPL.load("./Const.lua");
local ScrollBar = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

ScrollBar:Property("Blockly");
ScrollBar:Property("Direction");  -- 方向        -- horizontal  vertical 

local ScrollBarSize = 2 * Const.UnitSize;

function ScrollBar:ctor()
    self.__track_width__, self.__track_height__ = 0, 0;
    self.__width__, self.__height__ = 0, 0;
    self.__offset_x__, self.__offset_y__ = 0, 0;
end

function ScrollBar:Init(blockly, direction)
    self:SetBlockly(blockly);
    self:SetDirection(direction);
    
    return self;
end

function ScrollBar:IsHorizontal()
    return self:GetDirection() == "horizontal";
end

function ScrollBar:Render(painter)
    local blockly = self:GetBlockly();
    local isHideToolBox = blockly.isHideToolBox;
    local toolboxWidth = isHideToolBox and 0 or blockly.ToolBoxWidth;
    local width, height = blockly:GetSize();
    local UnitSize = blockly:GetUnitSize();
    self.__track_width__, self.__track_height__ = width, height;
    self.__toolbox_width__ = toolboxWidth;
    width = width - toolboxWidth;

    local __content_left_unit_count__, __content_top_unit_count__, __content_right_unit_count__, __content_bottom_unit_count__ = blockly.__min_offset_x_count__, blockly.__min_offset_y_count__, blockly.__max_offset_x_count__, blockly.__max_offset_y_count__;
    local __offset_x_unit_count__, __offset_y_unit_count__ = blockly.__offset_x_unit_count__, blockly.__offset_y_unit_count__;
    local __view_width_unit_count__, __view_height_unit_count__ = math.floor(width / UnitSize), blockly.__height_unit_count__; 
    if (#(blockly.blocks) == 0) then return end 

    local __content_width_unit_count__ = __content_right_unit_count__ - __content_left_unit_count__;
    local __content_height_unit_count__ = __content_bottom_unit_count__ - __content_top_unit_count__;
    local __content_offset_x_unit_count__ = __offset_x_unit_count__ - __content_left_unit_count__;
    local __content_offset_y_unit_count__ = __offset_y_unit_count__ - __content_top_unit_count__;
    -- 防止偏移瞬时超界导致滑块画出轨道外(点不中)
    __content_offset_x_unit_count__ = math.min(math.max(__content_offset_x_unit_count__, 0), math.max(__content_width_unit_count__, 0));
    __content_offset_y_unit_count__ = math.min(math.max(__content_offset_y_unit_count__, 0), math.max(__content_height_unit_count__, 0));

    self.__content_left_unit_count__, self.__content_top_unit_count__, self.__content_right_unit_count__, self.__content_bottom_unit_count__ = __content_left_unit_count__, __content_top_unit_count__, __content_right_unit_count__, __content_bottom_unit_count__;
    self.__content_width_unit_count__, self.__content_height_unit_count__ = __content_width_unit_count__, __content_height_unit_count__;
    self.__view_width_unit_count__, self.__view_height_unit_count__ = __view_width_unit_count__, __view_height_unit_count__;
    -- print(1, __content_left_unit_count__, __content_top_unit_count__, __content_right_unit_count__, __content_bottom_unit_count__);
    -- print(2, __offset_x_unit_count__, __offset_y_unit_count__);
    -- print(3, __content_offset_x_unit_count__, __content_offset_y_unit_count__, __content_width_unit_count__, __content_height_unit_count__);
    painter:SetPen("#ffffff");
    -- painter:SetPen("#000000");
    -- offset 越大内容越向右(下)移, 视口看到的内容越靠左(上), 故滑块位置用 (1 - ratio) 反向映射
    local MinBarSize = 20;
    if (self:IsHorizontal()) then
        if (__content_width_unit_count__ <= 0) then return end
        self.__width__, self.__height__ = math.floor(width * width / (__content_width_unit_count__ * UnitSize)), ScrollBarSize;
        self.__width__ = math.min(math.max(self.__width__, MinBarSize), width);
        self.__offset_x__, self.__offset_y__ = toolboxWidth + math.floor((width - self.__width__) * (1 - __content_offset_x_unit_count__  / __content_width_unit_count__)), height - ScrollBarSize - 1;
        -- print(4, self.__offset_x__, self.__offset_y__, self.__width__, self.__height__)
        painter:DrawRect(toolboxWidth, height - ScrollBarSize - 2, width, ScrollBarSize + 2);
    else
        if (__content_height_unit_count__ <= 0) then return end
        self.__width__, self.__height__ = ScrollBarSize, math.floor(height * height / (__content_height_unit_count__ * UnitSize));
        self.__height__ = math.min(math.max(self.__height__, MinBarSize), height);
        self.__offset_x__, self.__offset_y__ = toolboxWidth + width - ScrollBarSize - 1, math.floor((height - self.__height__) * (1 - __content_offset_y_unit_count__  / __content_height_unit_count__));
        painter:DrawRect(toolboxWidth + width - ScrollBarSize - 2, 0, ScrollBarSize + 2, height);
        -- print(5, self.__offset_x__, self.__offset_y__, self.__width__, self.__height__)
    end
    -- painter:SetPen("#00000080");
    -- painter:SetPen("#ffffff");
    painter:SetPen("#cecece");
    painter:DrawRect(self.__offset_x__, self.__offset_y__, self.__width__, self.__height__);
    -- print(6, width, height, toolboxWidth);
end

function ScrollBar:GetMouseUI(x, y, event)
    local blockly = self:GetBlockly();
    x, y = blockly._super.GetRelPoint(blockly, event.x, event.y);
    if (x < blockly.ToolBoxWidth) then return nil end
    if (self:IsHorizontal()) then
        if (y < self.__track_height__ and y > (self.__track_height__ - ScrollBarSize - 2)) then return self end 
    else
        if (x < self.__track_width__ and x > (self.__track_width__ - ScrollBarSize - 2)) then return self end 
    end

    return nil;
end

function ScrollBar:OnMouseDown(event)
    local blockly = self:GetBlockly();
    local UnitSize = blockly:GetUnitSize();
    local x, y = blockly._super.GetRelPoint(blockly, event.x, event.y);         -- 防止减去偏移量
    blockly:CancelSmoothScroll();

    local HitTolerance = 4;   -- 滑块命中容差
    if (self:IsHorizontal()) then
        if (x > (self.__offset_x__ - HitTolerance) and x < (self.__offset_x__ + self.__width__ + HitTolerance)) then
            self.__drag_mouse_x__, self.__drag_mouse_y__ = event:GetScreenXY();
            self.__drag_blockly_offset_x_unit_count__ = blockly.__offset_x_unit_count__;
            self.__draging__ = true;
        else
            self.__draging__ = false;
            self.__offset_x__ = x;
            self.__offset_x__ = math.max(self.__toolbox_width__, self.__offset_x__);
            self.__offset_x__ = math.min(self.__offset_x__, self.__track_width__ - self.__width__);
            local track_size = self.__track_width__ - self.__toolbox_width__ - self.__width__;
            if (track_size <= 0) then return blockly:CaptureMouse(self) end
            local __content_offset_x_unit_count__ = (self.__content_width_unit_count__ or 0) * (1 - (self.__offset_x__ - self.__toolbox_width__) / track_size);
            __content_offset_x_unit_count__ = math.max(__content_offset_x_unit_count__, 0);
            __content_offset_x_unit_count__ = math.min(__content_offset_x_unit_count__, (self.__content_width_unit_count__ or 0));
            local __offset_x_unit_count__ = __content_offset_x_unit_count__ + (self.__content_left_unit_count__ or 0);
            blockly.__offset_x_unit_count__ = __offset_x_unit_count__;
            blockly.offsetX = __offset_x_unit_count__ * Const.UnitSize;
        end
    else
        if (y > (self.__offset_y__ - HitTolerance) and y < (self.__offset_y__ + self.__height__ + HitTolerance)) then
            self.__drag_mouse_x__, self.__drag_mouse_y__ = event:GetScreenXY();
            self.__drag_blockly_offset_y_unit_count__ = blockly.__offset_y_unit_count__;
            self.__draging__ = true;
        else
            self.__draging__ = false;
            self.__offset_y__ = y;
            self.__offset_y__ = math.max(0, self.__offset_y__);
            self.__offset_y__ = math.min(self.__offset_y__, self.__track_height__ - self.__height__);
            local track_size = self.__track_height__ - self.__height__;
            if (track_size <= 0) then return blockly:CaptureMouse(self) end
            local __content_offset_y_unit_count__ = self.__content_height_unit_count__ * (1 - self.__offset_y__ / track_size);
            __content_offset_y_unit_count__ = math.max(__content_offset_y_unit_count__, 0);
            __content_offset_y_unit_count__ = math.min(__content_offset_y_unit_count__, (self.__content_height_unit_count__ or 0));
            local __offset_y_unit_count__ = __content_offset_y_unit_count__ + (self.__content_top_unit_count__ or 0);
            blockly.__offset_y_unit_count__ = __offset_y_unit_count__;
            blockly.offsetY = __offset_y_unit_count__ * Const.UnitSize;
        end
    end
    blockly:OnOffsetChange();
    blockly:CaptureMouse(self);
end

function ScrollBar:OnMouseMove(event)
    if (not self.__draging__) then return end
    local blockly = self:GetBlockly();
    local mouse_x, mouse_y = event:GetScreenXY();
    -- 直接锚定按下时的内容偏移: 滑块每移动1px, 偏移反向移动 range/free_track 个单元, 避免经滑块位置往返换算
    if (self:IsHorizontal()) then
        local free_track_size = self.__track_width__ - self.__toolbox_width__ - self.__width__;
        local range = self.__content_width_unit_count__ or 0;
        if (free_track_size <= 0 or range <= 0 or not self.__drag_blockly_offset_x_unit_count__) then return end
        local offset_unit_count = self.__drag_blockly_offset_x_unit_count__ - (mouse_x - self.__drag_mouse_x__) * range / free_track_size;
        offset_unit_count = math.max(offset_unit_count, self.__content_left_unit_count__ or 0);
        offset_unit_count = math.min(offset_unit_count, self.__content_right_unit_count__ or 0);
        blockly.__offset_x_unit_count__ = offset_unit_count;
        blockly.offsetX = offset_unit_count * Const.UnitSize;
    else
        local free_track_size = self.__track_height__ - self.__height__;
        local range = self.__content_height_unit_count__ or 0;
        if (free_track_size <= 0 or range <= 0 or not self.__drag_blockly_offset_y_unit_count__) then return end
        local offset_unit_count = self.__drag_blockly_offset_y_unit_count__ - (mouse_y - self.__drag_mouse_y__) * range / free_track_size;
        offset_unit_count = math.max(offset_unit_count, self.__content_top_unit_count__ or 0);
        offset_unit_count = math.min(offset_unit_count, self.__content_bottom_unit_count__ or 0);
        blockly.__offset_y_unit_count__ = offset_unit_count;
        blockly.offsetY = offset_unit_count * Const.UnitSize;
    end
    blockly:OnOffsetChange();
end

function ScrollBar:OnMouseUp(event)
    self.__draging__ = false;
    local blockly = self:GetBlockly();
    blockly:ReleaseMouseCapture();
    blockly:OnOffsetChange();
end
