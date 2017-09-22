--[[
Title: md5
Author(s): LiXizhi
Date: 2017.9.22, moved to system folder
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Encoding/md5.lua");
local Encoding = commonlib.gettable("System.Encoding");
assert(Encoding.md5('') == 'd41d8cd98f00b204e9800998ecf8427e')
assert(Encoding.md5('message digest') == 'f96b697d7cb7938d525a2f31aaf161d0')
-------------------------------------------------------
]]
local Encoding = commonlib.gettable("System.Encoding");

function Encoding.md5(text)
    return ParaMisc.md5(text or "");
end