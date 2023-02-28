
local Button = NPL.load("./Button.lua", IsDevEnv);
local Workspace = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Workspace:Property("MatataLab");         -- 所属mata
Workspace:Property("RowCount");          -- 行数
Workspace:Property("ColCount");          -- 列数
Workspace:Property("UnitWidth");         -- 单元格宽度
Workspace:Property("UnitHeight");        -- 单元格高度

local START_BTN_ICON = "kaishi_62x60_32bits.png#0 0 62 60";
local STOP_BTN_ICON = "tingzhi_61x60_32bits.png#0 0 61 60";
local RUNNING_BTN_ICON = "jinxing_61x63_32bits.png#0 0 61 63";

function Workspace:ctor()
    self.__x__, self.__y__, self.__width__, self.__height__ = 0, 0, 0, 0;
    self.__padding_left__, self.__padding_top__ = 7, 205 + 7;
    self.__block_list__ = {};
end

function Workspace:Init(matatalab, opt)
    opt = opt or {};

    self:SetMatataLab(matatalab);
    self:SetRowCount(opt.row_count or 3);
    self:SetColCount(opt.col_count or 6);
    local RowCount = self:GetRowCount();
    local ColCount = self:GetColCount();
    local BlockWidth = matatalab:GetBlockWidth();
    local BlockHeight = matatalab:GetBlockHeight();
    local NumberBlockWidth = matatalab:GetNumberBlockWidth();
    local NumberBlockHeight = matatalab:GetNumberBlockHeight();
    local UnitWidth = math.max(BlockWidth, NumberBlockWidth);
    local UnitHeight = BlockHeight + NumberBlockHeight;

    self:SetUnitWidth(UnitWidth);
    self:SetUnitHeight(UnitHeight);

    self.__state_btn__ = Button:new():Init({
        icon = matatalab:GetIconPathPrefix() .. START_BTN_ICON,
        callback = function(btn) 
            self:ClickStateBtn();
        end,
    });
    self.__state_btn__:SetPosition(0, 0, 60, 60);

    self.__x__, self.__y__, self.__width__, self.__height__ = opt.x or 0, opt.y or 0, ColCount * UnitWidth, RowCount * UnitHeight;
    for i = 1, RowCount do
        self.__block_list__[i] = {};
    end

    self:SetXY(self.__x__, self.__y__);

    return self;
end

function Workspace:ClickStateBtn()
    local matatalab = self:GetMatataLab();
    local IconPathPrefix = matatalab:GetIconPathPrefix();
    local matatalab_option = matatalab:GetOption();
    local OnStart = matatalab_option.OnStart;
    local OnStop = matatalab_option.OnStop;
    local curIcon = self.__state_btn__:GetIcon();

    if (curIcon == (IconPathPrefix .. START_BTN_ICON)) then
        self.__state_btn__:SetIcon(IconPathPrefix .. STOP_BTN_ICON);
        if (type(OnStart) == "function") then OnStart(matatalab) end
    elseif (curIcon == (IconPathPrefix .. STOP_BTN_ICON)) then
        self.__state_btn__:SetIcon(IconPathPrefix .. START_BTN_ICON);
        if (type(OnStop) == "function") then OnStop(matatalab) end
    end
end

function Workspace:SetXY(x, y)
    self.__x__, self.__y__ = x, y;
    local matatalab = self:GetMatataLab();
    local UnitWidth = self:GetUnitWidth();
    local UnitHeight = self:GetUnitHeight();
    local RowCount = self:GetRowCount();
    local ColCount = self:GetColCount();  

    self.__state_btn__:SetPosition(self.__x__ + self.__padding_left__ + 175, self.__y__ + self.__padding_top__ + RowCount * UnitHeight);

    for i = 1, RowCount do
        for j = 1, ColCount do
            local block = self.__block_list__[i][j];
            if (block) then
                block:SetXY((j - 1) * UnitWidth + self.__x__ + self.__padding_left__, (i - 1) * UnitHeight + self.__y__ + self.__padding_top__);
            end
        end
    end
end

function Workspace:GetPosition()
    return self.__x__, self.__y__, self.__width__, self.__height__;
end

function Workspace:Render(painter)
    local matatalab = self:GetMatataLab();
    local RowCount = self:GetRowCount();
    local ColCount = self:GetColCount();
    local BlockWidth = matatalab:GetBlockWidth();
    local BlockHeight = matatalab:GetBlockHeight();
    local NumberBlockWidth = matatalab:GetNumberBlockWidth();
    local NumberBlockHeight = matatalab:GetNumberBlockHeight();
    local UnitWidth = math.max(BlockWidth, NumberBlockWidth);
    local UnitHeight = BlockHeight + NumberBlockHeight;
    local IconPathPrefix = matatalab:GetIconPathPrefix();

    painter:SetPen("#FFFFFF");
    painter:DrawRectTexture(self.__x__, self.__y__,  414, 205, IconPathPrefix .. "kongzhida_414x205_32bits.png#0 0 414 205");
    painter:DrawRectTexture(self.__x__, self.__y__ + 205, 414, 517, IconPathPrefix .. "bianchengban_414x517_32bits.png#0 0 414 517");
    local padding = 6;
    for i = 1, RowCount do
        for j = 1, ColCount do
            local x = self.__x__ + self.__padding_left__ + (j - 1) * UnitWidth + padding;
            local y = self.__y__ + self.__padding_top__ + (i - 1) * UnitHeight + padding;
            painter:SetPen("#FFFFFF");
            painter:DrawRectTexture(x, y, 68, 78, IconPathPrefix .. "tuoyipos_68x78_32bits.png#0 0 68 78");
            local block = self.__block_list__[i][j];
            if (block) then
                block:Render(painter) 
            end 
        end
    end

    self.__state_btn__:Render(painter);
end

function Workspace:XYToRowCol(x, y)
    x = x - self.__x__ - self.__padding_left__;
    y = y - self.__y__ - self.__padding_top__;
    if (x <= 0 or x > self.__width__ or y <= 0 or y > self.__height__) then return end
    local matatalab = self:GetMatataLab();
    local UnitWidth = self:GetUnitWidth();
    local UnitHeight = self:GetUnitHeight();
    local RowIndex = math.ceil(y / UnitHeight);
    local ColIndex = math.ceil(x / UnitWidth);
    return RowIndex, ColIndex;
end

function Workspace:GetBlockByXY(x, y)
    local RowIndex, ColIndex = self:XYToRowCol(x, y);
    if (not RowIndex) then return end
    return self.__block_list__[RowIndex][ColIndex];
end

function Workspace:SetBlockByXY(x, y, block)
    local RowIndex, ColIndex = self:XYToRowCol(x, y);
    if (not RowIndex) then return end
    if (block) then
        local matatalab = self:GetMatataLab();
        local UnitWidth = self:GetUnitWidth();
        local UnitHeight = self:GetUnitHeight();
        block:SetXY((ColIndex - 1) * UnitWidth + self.__x__ + self.__padding_left__, (RowIndex - 1) * UnitHeight + self.__y__ + self.__padding_top__);
    end
    local old_block = self.__block_list__[RowIndex][ColIndex];
    self.__block_list__[RowIndex][ColIndex] = block;
    return old_block;
end

function Workspace:GetMouseUI(x, y)
    local ui = self.__state_btn__:GetMouseUI(x, y);
    if (ui) then return ui end

    if (x > (self.__x__ + self.__padding_left__ + self.__width__) or x < (self.__x__ + self.__padding_left__) or y > (self.__y__ + self.__padding_top__ + self.__height__) or y < (self.__y__ + self.__padding_top__)) then return nil end 
    local block = self:GetBlockByXY(x, y);
    return block and block:GetMouseUI(x, y);
end

function Workspace:GetCode()
    local argname = self:GetMatataLab():GetArgName();
    local RowCount = self:GetRowCount();
    local ColCount = self:GetColCount(); 
    local codetext = "local " .. argname .. " = nil\n";

    for i = 1, RowCount do
        for j = 1, ColCount do
            local block = self.__block_list__[i][j];
            if (block) then
                local number_block = block:GetNumberBlock();
                if (number_block) then 
                    codetext = codetext .. argname .. " = " .. number_block:GetCode() .. "\n";
                else 
                    codetext = codetext .. argname .. " = nil\n";
                end
                codetext = codetext .. block:GetCode();
            end
        end
    end

    return codetext;
end

-- return Workspace;