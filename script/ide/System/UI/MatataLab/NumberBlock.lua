
local Match = NPL.load("./Match.lua");
local NumberBlock = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());


NumberBlock:Property("MatataLab");    -- 所有对象
NumberBlock:Property("ToolBoxBlock", false, "IsToolBoxBlock");         -- 是否是工具块
NumberBlock:Property("Block");        -- 所属块
NumberBlock:Property("Type");         -- 图块类型
NumberBlock:Property("Code");         -- 图块代码
NumberBlock:Property("Icon");         -- 图标
NumberBlock:Property("Match");        -- 匹配类型

function NumberBlock:ctor()
    self.__x__, self.__y__, self.__width__, self.__height__ = 0, 0, 0, 0;
    self.__is_match__ = true;
end

function NumberBlock:Init(matatalab, opt)
    opt = opt or {};

    self:SetMatataLab(matatalab);
    self:SetType(opt.type);
    self:SetCode(opt.code);
    self:SetIcon(opt.icon);

    self.__width__ = matatalab:GetNumberBlockWidth();
    self.__height__ = matatalab:GetNumberBlockHeight();

    self:SetMatch(Match:new():Init(opt.match));

    return self;
end

function NumberBlock:SetXY(x, y)
    self.__x__, self.__y__ = x, y;
end

function NumberBlock:GetWorkspace()
    return self:GetMatataLab():GetWorkspace();
end

function NumberBlock:Render(painter)
    local icon = self:GetIcon();
    if (icon) then
        if (self.__is_match__) then
            painter:SetPen("#ffffffff");
        else
            painter:SetPen("#ffffff80");
        end
        painter:DrawRectTexture(self.__x__ + 6 - 1, self.__y__ - 12, 69, 40, icon);
    else
        painter:SetPen("#cccccc80");
        painter:DrawRect(self.__x__, self.__y__, self.__width__, self.__height__);
        painter:SetPen("#000000ff");
        painter:DrawText(self.__x__, self.__y__, tostring(self:GetNumber()));
    end
end

function NumberBlock:OnMouseDown(event)
    local matatalab = self:GetMatataLab();
    local number_block = self;
    local x, y = matatalab:GetGloablXY(event);

    if (self:IsToolBoxBlock()) then 
        number_block = matatalab:GetBlockByType(self:GetType());
        number_block:SetToolBoxBlock(false);
    end 
    
    local block = number_block:GetBlock();
    if (block) then block:SetNumberBlock(nil) end 
    number_block:SetBlock(nil);

    number_block.__start_mouse_x__, number_block.__start_mouse_y__ = x, y;
    number_block.__start_x__, number_block.__start_y__ = self.__x__, self.__y__;
    number_block.__x__, number_block.__y__ = self.__x__, self.__y__;
    number_block.__is_mouse_down__ = true;
    number_block.__is_match__ = true;

    matatalab:SetDraggingBlock(number_block);
    matatalab:SetMouseCaptureUI(number_block);
end

function NumberBlock:OnMouseMove(event)
    if (not self.__is_mouse_down__) then return end 
    local matatalab = self:GetMatataLab();
    local x, y = matatalab:GetGloablXY(event);
    self.__x__, self.__y__ = x - self.__start_mouse_x__ + self.__start_x__, y - self.__start_mouse_y__ + self.__start_y__;
end

function NumberBlock:OnMouseUp(event)
    self.__is_mouse_down__ = false;
    local matatalab = self:GetMatataLab();
    local x, y = matatalab:GetLocalXY(event);
    matatalab:SetDraggingBlock(nil);

    local block = matatalab:GetWorkspace():GetBlockByXY(x, y);
    if (not block) then return end
    block:SetNumberBlock(self);
    self:SetBlock(block);
    block:SetXY(block:GetXY());

    if (not self:GetMatch():IsMatch(block:GetMatch())) then self.__is_match__ = false end 
end

-- return NumberBlock;