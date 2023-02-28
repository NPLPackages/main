
local Match = NPL.load("./Match.lua");

local Block = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());


Block:Property("MatataLab");    -- 所有对象
Block:Property("ToolBoxBlock", false, "IsToolBoxBlock");         -- 是否是工具块
-- Block:Property("WorkspaceBlock", false, "IsWorkspaceBlock");     -- 是否是工作区块
Block:Property("NumberBlock");  -- 数字块
Block:Property("Type");         -- 图块类型
Block:Property("Code");         -- 图块代码
Block:Property("Icon");         -- 图标
Block:Property("Match");        -- 匹配类型

function Block:ctor()
    self.__x__, self.__y__, self.__width__, self.__height__ = 0, 0, 0, 0;
end

function Block:Init(matatalab, opt)
    opt = opt or {};

    self:SetMatataLab(matatalab);
    self:SetType(opt.type);
    self:SetIcon(opt.icon);

    local code = opt.code or "";
    code = string.gsub(code, "^%s*", "");
    code = string.gsub(code, "[%s]*$", "");
    self:SetCode(code .. "\n");

    self.__width__ = matatalab:GetBlockWidth();
    self.__height__ = matatalab:GetBlockHeight();

    self:SetMatch(Match:new():Init(opt.match));
    return self;
end

function Block:SetXY(x, y)
    self.__x__, self.__y__ = x, y;
    local number_block = self:GetNumberBlock();
    if (number_block) then
        number_block:SetXY(self.__x__, self.__y__ + self.__height__);
    end
end

function Block:GetXY()
    return self.__x__, self.__y__;
end

function Block:GetWorkspace()
    return self:GetMatataLab():GetWorkspace();
end

function Block:Render(painter)
    local matatalab = self:GetMatataLab();
    local icon = self:GetIcon();
    local padding = 6;
    if (icon) then
        painter:SetPen("#ffffffff");
        painter:DrawRectTexture(self.__x__ + padding - 1, self.__y__ + padding - 1, 69, 51, icon);
    else
        painter:SetPen("#cccccc80");
        painter:DrawRect(self.__x__, self.__y__, self.__width__, self.__height__);
        painter:SetPen("#000000ff");
        painter:DrawText(self.__x__, self.__y__, self:GetType());
    end
    
    local number_block = self:GetNumberBlock();
    if (number_block) then number_block:Render(painter) end 
end

function Block:OnMouseDown(event)
    local matatalab = self:GetMatataLab();
    local block = self;

    if (self:IsToolBoxBlock()) then 
        block = matatalab:GetBlockByType(self:GetType());
        block:SetToolBoxBlock(false);
    end 
    
    local x, y = matatalab:GetGloablXY(event);
    block.__start_mouse_x__, block.__start_mouse_y__ = x, y;
    block.__start_x__, block.__start_y__ = self.__x__, self.__y__;
    block.__x__, block.__y__ = self.__x__, self.__y__;
    block.__is_mouse_down__ = true;

    local rel_x, rel_y = matatalab:GetLocalXY(event);
    matatalab:GetWorkspace():SetBlockByXY(rel_x, rel_y);
    matatalab:SetDraggingBlock(block);
    matatalab:SetMouseCaptureUI(block);
end

function Block:OnMouseMove(event)
    if (not self.__is_mouse_down__) then return end 
    local x, y = self:GetMatataLab():GetGloablXY(event);
    self:SetXY(x - self.__start_mouse_x__ + self.__start_x__, y - self.__start_mouse_y__ + self.__start_y__);
end

function Block:OnMouseUp(event)
    self.__is_mouse_down__ = false;
    local x, y = self:GetMatataLab():GetLocalXY(event);
    self:GetWorkspace():SetBlockByXY(x, y, self);
    self:GetMatataLab():SetDraggingBlock(nil);
end

function Block:GetMouseUI(x, y)
    return (y < (self.__y__ + self.__height__)) and self or self:GetNumberBlock();
end

-- return Block;