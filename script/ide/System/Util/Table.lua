--[[
Title: Table
Author(s):  wxa
Date: 2020-06-12
Desc: Table 兼容实现, 由于各个平台lua编译器不同, 导致系统table相关方法缺失, 写此文件兼容
use the lib:
------------------------------------------------------------
local Table = NPL.load("script/ide/System/Util/Table.lua");
------------------------------------------------------------
]]

local Table = NPL.export();

function Table.Pack(...)
    local n = select("#", ...);
    local obj = {n = n};
    for i = 1, n do
        obj[i] = select(i, ...);
    end
    return obj;
end

function Table.Unpack(obj)
    if (obj.n == 1) then return obj[1] 
    elseif (obj.n == 2) then return obj[1], obj[2] 
    elseif (obj.n == 3) then return obj[1], obj[2], obj[3] 
    elseif (obj.n == 4) then return obj[1], obj[2], obj[3], obj[4]
    elseif (obj.n == 5) then return obj[1], obj[2], obj[3], obj[4], obj[5]
    elseif (obj.n == 6) then return obj[1], obj[2], obj[3], obj[4], obj[5], obj[6]
    elseif (obj.n == 7) then return obj[1], obj[2], obj[3], obj[4], obj[5], obj[6], obj[7]
    elseif (obj.n == 8) then return obj[1], obj[2], obj[3], obj[4], obj[5], obj[6], obj[7], obj[8]
    elseif (obj.n == 9) then return obj[1], obj[2], obj[3], obj[4], obj[5], obj[6], obj[7], obj[8], obj[9]
    else end
end

function Table.Sort(list, comp)
    comp = comp or function(n1, n2) return n1 > n2 end

	for i = 1, #list do
        for j = i + 1, #list do 
            if (comp(list[i], list[j])) then
                list[i], list[j] = list[j], list[i];
            end
        end
    end
end
