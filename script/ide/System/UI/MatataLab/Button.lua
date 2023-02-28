
local Button = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Button:Property("Icon");
Button:Property("ClickCallBack");

function Button:ctor()
    self.__x__, self.__y__, self.__width__, self.__height__ = 0, 0, 0, 0;
end

function Button:Init(opt)
    opt = opt or {};

    self:SetIcon(opt.icon);
    self:SetClickCallBack(opt.callback);
    
    return self;
end

function Button:SetPosition(x, y, w, h)
    self.__x__, self.__y__, self.__width__, self.__height__ = x or self.__x__, y or self.__y__, w or self.__width__, h or self.__height__;
end

function Button:Render(painter)
    painter:DrawRectTexture(self.__x__, self.__y__, self.__width__, self.__height__, self:GetIcon());
end

function Button:GetMouseUI(x, y)
    if (x > (self.__x__ + self.__width__) or x < self.__x__ or y > (self.__y__ + self.__height__) or y < self.__y__) then return nil end 
    return self;
end

function Button:OnMouseDown()
    local callback = self:GetClickCallBack();
    if (type(callback) == "function") then
        callback(self);
    end
end

function Button:OnMouseMove()
  
end

function Button:OnMouseUp()

end