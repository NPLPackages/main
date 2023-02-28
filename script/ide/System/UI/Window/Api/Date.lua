--[[
Author: wxa
Date: 2020-10-26
Desc: Date 
-----------------------------------------------
local Date = NPL.load("script/ide/System/UI/Window/Api/Date.lua");
-----------------------------------------------
]]

local Date = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Date:Property("TimeStamp");  -- 时间戳

function Date:ctor()
    self:SetTimeStamp(os.time());
end

function Date:Init(t)
    self:SetTimeStamp(os.time(t));
    return self;
end

-- os.date
function Date:GetDate(fmt)
    return os.date(fmt, self:GetTimeStamp());
end

function Date.Test()
end

--[[
os.date ([format [, time\]\])

由原型可以看出可以省略第二个参数也可以省略两个参数，

只省略第二个参数函数会使用当前时间作为第二个参数，

如果两个参数都省略则按当前系统的设置返回格式化的字符串，做以下等价替换 os.date() <=> os.date("%c")。

如果format以 “!” 开头，则按格林尼治时间进行格式化。

**如果format是一个 “t” **，将返一个带year(4位)，month(1-12)， day (1--31)， hour (0-23)， min (0-59)，sec (0-61)，wday (星期几， 星期天为1)， yday (年内天数)和isdst (是否为日光节约时间true/false)的带键名的表;

**如果format不是 “t” **，os.date会将日期格式化为一个字符串，具体如下：

格式符	含义	具体示例
%a	一星期中天数的简写	os.date("%a") => Fri
%A	一星期中天数的全称	(Wednesday)
%b	月份的简写	(Sep)
%B	月份的全称	(May)
%c	日期和时间	(09/16/98 23:48:10)
%d	一个月中的第几天	(28)[0 - 31]
%H	24小时制中的小时数	(18)[00 - 23]
%I	12小时制中的小时数	(10)[01 - 12]
%j	一年中的第几天	(209) [01 - 366]
%M	分钟数	(48)[00 - 59]
%m	月份数	(09)[01 - 12]
%P	上午或下午	(pm)[am - pm]
%S	一分钟之内秒数	(10)[00 - 59]
%w	一星期中的第几天	(3)[0 - 6 = 星期天 - 星期六]
%W	一年中的第几个星期	(2)0 - 52
%x	日期	(09/16/98)
%X	时间	(23:48:10)
%y	两位数的年份	(16)[00 - 99]
%Y	完整的年份	(2016)
%%	字符串'%'	(%)
*t	返回一个table，里面包含全部的数据	hour 14

https://www.cnblogs.com/zhaoqingqing/p/9892694.html
]]