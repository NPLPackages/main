--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/text/TextBreakIterator.lua");
local LazyLineBreakIterator = commonlib.gettable("System.Windows.mcml.platform.text.LazyLineBreakIterator");
------------------------------------------------------------
]]
local LazyLineBreakIterator = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.platform.text.LazyLineBreakIterator"));

function LazyLineBreakIterator:ctor()
	self.string = nil;
    self.length = 0;
    self.locale = nil;
    self.iterator = nil;
end

function LazyLineBreakIterator:init(string, length, locale)
	self.string = string;
    self.length = length;
    self.locale = locale;

	return self;
end

function LazyLineBreakIterator:String()
	return self.string;
end

function LazyLineBreakIterator:Length()
	return self.length;
end

function LazyLineBreakIterator:Reset(string, length, locale)
	self.string = string;
    self.length = length;
    self.locale = locale;
    self.iterator = nil;
end
