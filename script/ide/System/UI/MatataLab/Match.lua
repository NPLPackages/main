
local Match = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());


function Match:ctor()
    self.__match_items__ = {};
    self.__match_all__ = false;
end

function Match:Init(match_type)

    if (match_type == nil) then
        self.__match_all__ = true;
    elseif (type(match_type) == "string") then
        self.__match_items__[#self.__match_items__ + 1] = match_type;
    elseif (type(match_type) == "table") then
        for _, _type in ipairs(match_type) do
            self.__match_items__[#self.__match_items__ + 1] = _type;
        end
    end

    return self;
end


function Match:IsMatch(match)
    if (self.__match_all__ or match.__match_all__) then return true end

    for _, mt1 in ipairs(self.__match_items__) do
        for _, mt2 in ipairs(match.__match_items__) do
            if (mt1 == mt2) then return true end 
        end
    end

    return false;
end
