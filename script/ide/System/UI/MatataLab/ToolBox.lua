

local ToolBox = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

ToolBox:Property("ExistNumberBlock", false, "IsExistNumberBlock");  -- 是否存在数字块
ToolBox:Property("MatataLab");                                      -- 所属mata

local NumberBlockMarginTop = 72;

function ToolBox:ctor()
    self.__x__, self.__y__, self.__width__, self.__height__ = 0, 0, 0, 0;
    self.__block_list__ = {};
    self.__number_block_list__ = {};
    self.__offset_x__ = 0;
end

function ToolBox:Init(matatalab, opt)
    opt = opt or {};

    self:SetMatataLab(matatalab);

    self.__x__, self.__y__ = opt.x or 0, opt.y or 0;
    self.__width__, self.__height__ = opt.width or 9 * matatalab:GetBlockWidth(), opt.height or (matatalab:GetBlockHeight() + matatalab:GetNumberBlockHeight());

    return self;
end

function ToolBox:SetXY(x, y)
    self.__x__, self.__y__ = x, y;

    local matatalab = self:GetMatataLab();
    local BlockWidth = matatalab:GetBlockWidth();
    local BlockHeight = matatalab:GetBlockHeight();
    for i, block in ipairs(self.__block_list__) do
        block:SetXY(self.__x__ + (i - 1) * BlockWidth, self.__y__);
    end

    for i, block in ipairs(self.__number_block_list__) do
        block:SetXY(self.__x__ + (i - 1) * BlockWidth, self.__y__ + NumberBlockMarginTop);
    end
end

function ToolBox:GetXY()
    return self.__x__, self.__y__;
end

function ToolBox:SetBlockList(block_list, number_block_list)
    local matatalab = self:GetMatataLab();
    local x, y = self.__x__, self.__y__;
    self.__block_list__ = {};
    for i, block_type in ipairs(block_list) do
        local block = matatalab:GetBlockByType(block_type);
        if (block) then
            block:SetToolBoxBlock(true);
            table.insert(self.__block_list__, block);
        end
    end
    self.__number_block_list__ = {};
    for i, block_type in ipairs(number_block_list) do
        local block = matatalab:GetBlockByType(block_type);
        if (block) then
            block:SetToolBoxBlock(true);
            table.insert(self.__number_block_list__, block);
        end
    end
    self:SetXY(x, y);
end

function ToolBox:Render(painter)
    local matatalab = self:GetMatataLab();
    local IconPathPrefix = matatalab:GetIconPathPrefix();
    local BlockWidth = matatalab:GetBlockWidth();

    -- painter:SetPen("#000000");
    -- painter:DrawRect(self.__x__, self.__y__, self.__width__, self.__height__);
    painter:SetPen("#ffffffff");
    for i = 1, 9 do
        painter:DrawRectTexture(self.__x__ + (i - 1) * BlockWidth + 3, self.__y__ + 3, 74, 56, IconPathPrefix .. "shangdi_74x56_32bits.png#0 0 74 56");
        painter:DrawRectTexture(self.__x__ + (i - 1) * BlockWidth + 3, self.__y__ - 3 + NumberBlockMarginTop - 12, 74, 46, IconPathPrefix .. "xiadi_74x46_32bits.png#0 0 74 46");
    end

    for _, block in ipairs(self.__block_list__) do
        block:Render(painter);
    end

    for _, block in ipairs(self.__number_block_list__) do
        block:Render(painter);
    end
end

function ToolBox:GetMouseUI(x, y)
    if (x > (self.__x__ + self.__width__) or x < self.__x__ or y > (self.__y__ + self.__height__) or y < self.__y__) then return nil end 

    x = self.__offset_x__ + x - self.__x__;
    y = y - self.__y__;

    local matatalab = self:GetMatataLab();
    local BlockWidth = matatalab:GetBlockWidth();
    local BlockHeight = matatalab:GetBlockHeight();
    local NumberBlockHeight = matatalab:GetNumberBlockHeight();
    local index = math.ceil(x / BlockWidth);

    if (y < BlockHeight) then return self.__block_list__[index] end
    if ((self.__height__ - NumberBlockHeight) < y) then return self.__number_block_list__[index] end
    return nil;
end


-- return ToolBox;