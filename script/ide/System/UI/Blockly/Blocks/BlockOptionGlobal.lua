
local MacroBlock = NPL.load("./MacroBlock.lua", IsDevEnv);
local ListBlock = NPL.load("./ListBlock.lua", IsDevEnv);
local UIBlock = NPL.load("./UIBlock.lua", IsDevEnv);

local BlockOptionGlobal = commonlib.inherit(nil, NPL.export());

local function ExtendBlock(SrcMap, DstMap)
    for key, block in pairs(SrcMap) do
        DstMap[key] = block;
    end
end


function BlockOptionGlobal:ctor()
    self.__default_options__ = {};
    self.__overwirte_options__ = {};
    self.__G__ = setmetatable({}, {__index = _G});
end

function BlockOptionGlobal:Init()
    -- 内置启动块
    self.__default_options__.System_Main = {
        type = "System_Main",
        category = "事件",
        color = "#2E9BEF",
        output = false,
        previousStatement = false, 
        nextStatement = true,
        message = "程序入口",
        code_description = [[]],
        arg = {  },
    }
    
    ExtendBlock(MacroBlock, self.__default_options__);
    ExtendBlock(ListBlock, self.__default_options__);
    ExtendBlock(UIBlock, self.__default_options__);

    return self;
end


function BlockOptionGlobal:GetDefaultOption(block_type)
    return self.__default_options__[block_type];
end

function BlockOptionGlobal:GetOverWriteOption(block_type)
    return self.__overwirte_options__[block_type];
end

function BlockOptionGlobal:DefineGlobalOption(block_type, option)
    self.__G__[block_type] = option;
end

function BlockOptionGlobal:GetG()
    return self.__G__;
end

