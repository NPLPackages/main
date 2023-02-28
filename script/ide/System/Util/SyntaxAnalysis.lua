--[[
Title: Syntax Analysis class
Author(s): LiPeng, 
Date: 2018/6/1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/SyntaxAnalysis.lua");
local SyntaxAnalysis = commonlib.gettable("System.Util.SyntaxAnalysis");

------------------------------------------------------------
]]

local SyntaxAnalysis = commonlib.inherit(nil, commonlib.gettable("System.Util.SyntaxAnalysis"));

function SyntaxAnalysis:ctor()
	self.text_ctrl = nil
	self.language = nil;	
end

function SyntaxAnalysis:init(text_ctrl)
	self.text_ctrl = text_ctrl
	self.language = text_ctrl.language;
	return self;
end

function SyntaxAnalysis.CreateAnalyzer(text_ctrl)
	local language = text_ctrl.language
	if(language == "lua" or language == "npl") then
		return SyntaxAnalysis:new():init(text_ctrl);
	end
end

local KEY_WORDS = {
	["and"] = true,
	["break"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["false"] = true,
	["for"] = true,
	["function"] = true,
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["nil"] = true,
	["not"] = true,
	["or"] = true,
	["repeat"] = true,
	["return"] = true,
	["then"] = true,
	["true"] = true,
	["until"] = true,
	["while"] = true,
}

local function beQuote(c)
	return c == "'" or c == '"';
end

local function beStringStart(uniStr, pos)
	local c = uniStr[pos];
	if(beQuote(c)) then
		return true, true, c;
	end
	if(c == "[") then
		if(uniStr[pos + 1] == "[") then
			return true, false, c;
		end
	end
	return false, nil, nil;
end

local function beStringEnd(uniStr, pos, start_c)
	local c = uniStr[pos];
	if(beQuote(start_c) and c == start_c) then
		return true, true;
	end
	if(start_c == "[" and c == "]") then
		if(uniStr[pos + 1] == "]") then
			return true, false;
		end
	end
	return false, nil;
end

local function beCommentStart(uniStr, pos)
	local beComment = false;
	local beSingle = true;
	local equal_symbol
	if(uniStr[pos] == "-") then
		if(uniStr[pos + 1] == "-") then
			beComment = true;
			if(uniStr[pos + 2] == "[") then
				if(uniStr[pos + 3] == "[") then
					beSingle = false;
				else
					local uni_text = uniStr:GetText()
					equal_symbol = string.match(uni_text, '%[(=+)%[')
					if equal_symbol then
						beSingle = false;
					end
				end
			end
		end
	end
	return beComment, beSingle, equal_symbol;
end

local function beCommentEnd(uniStr, pos)
	if(uniStr[pos] == "]") then
		if(uniStr[pos + 1] == "]") then
			return true;
		end
	end
	return false;
end

local function nextIdentifier(uniStr, len, pos)
	local start_pos, end_pos;
	local is_identifier = false;
	while(pos <= len) do
		local c = uniStr[pos];
		local c_num = string.byte(c);
		local is_letter = (c_num > 64 and c_num < 91) or  (c_num >96 and c_num < 123);
		if(not start_pos) then
			if(is_letter or c == "_") then
				start_pos = pos;
				is_identifier = true;
			elseif(c == "'" or c == "\"") then
				end_pos = pos - 1;
				break;
			elseif(c == "-") then
				local is_comment = beCommentStart(uniStr, pos);
				if(is_comment) then
					end_pos = pos - 1;
					break;
				end
			end
		else
			local is_number = c_num > 47 and c_num < 58;
			if(not is_letter and c ~= "_" and not is_number) then
				end_pos = pos - 1;
				break;
			end
		end
		pos = pos + 1;
	end
	if(start_pos) then
		return start_pos, end_pos or pos;
	end
	return nil, end_pos or pos;
end

local function tokenWrapper(type, spos, epos, color, bold)
	return {type = type, spos = spos, epos = epos, color = color, bold = bold};
end

local LUA_TEXT_CONFIG = {
	["comment"] = {color = "#008000", bold = false},
	["string"] = {color = "#808080", bold = false},
	["keyword"] = {color = "#0000FF", bold = false},
	["function"] = {color = "#800000", bold = false},
}

function SyntaxAnalysis:Reset()
	self.hasMultiComment = false
end

function SyntaxAnalysis:GetToken(lineItem, lineIndex)
--local function getToken(uniStr)
	local uniStr = lineItem.text;
	local pos = 0;
	local len = uniStr:length();
	local start_pos = 0;
	return function()
		pos = pos + 1;
		if(pos > len) then
			if len == 0 then
				self:SetEmptyLineItemMutilCommentState(lineItem, lineIndex)
			end
			
			return;
		end
		-- 多行注释结尾
		local uni_text = uniStr:GetText()
		local is_normal_symbol = string.find(uni_text, "]]")
		local equal_symbol = string.match(uni_text, '%](=+)%]')
		if is_normal_symbol or equal_symbol then
			local find_comment_pos = pos
			while(find_comment_pos < len) do
				if(beCommentEnd(uniStr, find_comment_pos) or equal_symbol) then
					-- 能不能成为注释结尾 还得根据
					local in_multi_comment = lineItem.in_multi_comment
					lineItem.has_multi_comment_end = true
					-- if equal_symbol then
					-- 	lineItem.equal_symbol = equal_symbol
					-- end
					local is_in_multi_comment = self:CheckIsInMultiComment(lineItem, lineIndex)
					if not lineItem.is_multi_comment_end and is_in_multi_comment then
						-- 这里得多一层判断 判断注释类型是否匹配 是“[[”类型的 还是"[==["类型
						lineItem.in_multi_comment = true
						local last_item = self:GetLastNoEmptyItems(self.text_ctrl:GetItems(), lineIndex)
						if equal_symbol == last_item.equal_symbol then
							
							lineItem.is_multi_comment_end = true
							self:SetItemInMultiConmet(lineIndex + 1, nil, false)
						end
						
						return tokenWrapper("comment", 1, len, LUA_TEXT_CONFIG["comment"]["color"], LUA_TEXT_CONFIG["comment"]["bold"]);
					end
					break
					-- return tokenWrapper()
				end
				find_comment_pos = find_comment_pos + 1;
			end
		elseif lineItem.has_multi_comment_end then -- 多行注释取消结尾
			lineItem.has_multi_comment_end = false
			if lineItem.is_multi_comment_end then
				lineItem.is_multi_comment_end = false
				self:SetItemInMultiConmet(lineIndex + 1, nil, true, lineItem.equal_symbol)
			end
			-- lineItem.is_multi_comment_end = false
			-- if lineItem.in_multi_comment then
			-- 	self:SetItemInMultiConmet(lineIndex + 1, nil, true, lineItem.equal_symbol)
			-- end
		end
		
		--c = uniStr[pos];
		--local c_num = string.byte(c);
		local is_string_start, is_quote, start_char = beStringStart(uniStr, pos);
		if(is_string_start) then
			start_pos = pos;
			pos = if_else(is_quote, pos, pos + 1);
			while(pos <= len) do
				pos = pos + 1;
				if(beStringEnd(uniStr, pos, start_char)) then
					pos = if_else(is_quote, pos, pos + 1);
					break;
				end
			end
			return tokenWrapper("string", start_pos, pos, LUA_TEXT_CONFIG["string"]["color"], LUA_TEXT_CONFIG["string"]["bold"]);
		end
		
		local beComment, beSingle, equal_symbol = beCommentStart(uniStr, pos);
		if(beComment) then
			if(not beSingle) then
				lineItem.has_multi_comment_start = true
				local last_equal_symbol = lineItem.equal_symbol
				local last_item = self:GetLastNoEmptyItems(self.text_ctrl:GetItems(), lineIndex)
				-- 上个item是否在多行注释中
				if not last_item or not last_item.in_multi_comment then
					self.hasMultiComment = true
					if not lineItem.in_multi_comment or (last_equal_symbol ~= equal_symbol and lineItem.is_multi_comment_start) then
						-- lineItem.equal_symbol = equal_symbol
						lineItem.is_multi_comment_start = true
						self:SetItemInMultiConmet(lineIndex, nil, true, equal_symbol)
					end
				end
			elseif lineItem.has_multi_comment_start then
				lineItem.has_multi_comment_start = false
				if lineItem.is_multi_comment_start then
					lineItem.is_multi_comment_start = false
					self:SetItemInMultiConmet(lineIndex, nil, false)
				end
			end
			local start_pos = pos;
			pos = len;
			
			return tokenWrapper("comment", start_pos, len, LUA_TEXT_CONFIG["comment"]["color"], LUA_TEXT_CONFIG["comment"]["bold"]);
		elseif lineItem.has_multi_comment_start then -- 多行注释取消开头
			lineItem.has_multi_comment_start = false
			if lineItem.is_multi_comment_start then
				lineItem.is_multi_comment_start = false
				self:SetItemInMultiConmet(lineIndex, nil, false, lineItem.equal_symbol)
			end
		end
		local is_in_multi_comment = self:CheckIsInMultiComment(lineItem, lineIndex)
		if is_in_multi_comment then
			lineItem.in_multi_comment = true
			
			local last_item = self:GetLastNoEmptyItems(self.text_ctrl:GetItems(), lineIndex)
			if last_item then
				lineItem.equal_symbol = last_item.equal_symbol
			end
			
			return tokenWrapper("comment", 1, len, LUA_TEXT_CONFIG["comment"]["color"], LUA_TEXT_CONFIG["comment"]["bold"]);
		end

		start_pos, pos = nextIdentifier(uniStr, len, pos);
		if(start_pos) then
			local identifier = uniStr:substr(start_pos, pos);
			if(KEY_WORDS[identifier]) then
				return tokenWrapper("keyword", start_pos, pos, LUA_TEXT_CONFIG["keyword"]["color"], LUA_TEXT_CONFIG["keyword"]["bold"]);	
			end
			-- is function
			if(uniStr[pos + 1] == "(") then
				return tokenWrapper("function", start_pos, pos, LUA_TEXT_CONFIG["function"]["color"], LUA_TEXT_CONFIG["function"]["bold"]);	
			end
		end
		if(pos < len) then
			return tokenWrapper();	
		end
		return;	
	end
end

function SyntaxAnalysis:GetTextControl()
	return self.text_ctrl
end

-- 设置多行注释的状态
function SyntaxAnalysis:SetItemInMultiConmet(from_line, to_line, flag, equal_symbol)
	local items = self.text_ctrl:GetItems()
	if not items or items:empty() then
		return
	end
	from_line = from_line or 1
	to_line = to_line or #items
	interval = 1
	local last_item
	local test = items:get(from_line)
	local target_flag = flag
	local target_equal_symbol = equal_symbol
	for i = from_line, to_line, interval do
		local item = items:get(i);	
		if item then
			if not flag then
				if not item.in_multi_comment then
					break
				end
			end
			local item_equal_symbol = target_equal_symbol
			if last_item and last_item.equal_symbol then
				item_equal_symbol = last_item.equal_symbol
			end

			-- 取消注释的过程中 如果遇到其他开头注释
			
			if not flag and item.has_multi_comment_start then
				
				local item_text = item.text:GetText()
				target_equal_symbol = string.match(item_text, '%[(=+)%[')
				item_equal_symbol = target_equal_symbol
				target_flag = true
				item.is_multi_comment_start = true
			end
			item.changed = true
			item.in_multi_comment = target_flag
			item.equal_symbol = item_equal_symbol
			if target_flag and item.has_multi_comment_end then
				local item_text = item.text:GetText()
				if item_equal_symbol == string.match(item_text, '%](=+)%]') then
					item.is_multi_comment_end = true
					target_flag = flag
					if target_flag then
						break
					end
					-- break
				end
			end
		end
	end
end

function SyntaxAnalysis:CheckIsInMultiComment(lineItem, lineIndex)
	if not self.hasMultiComment then
		return false
	end

	if lineItem.in_multi_comment then
		return true
	end

	-- 在注释区中间写入的 判断上一行
	local items = self.text_ctrl:GetItems()
	if not items or items:empty() then
		return false
	end

	local item = self:GetLastNoEmptyItems(items, lineIndex)
	if item then
		return item.in_multi_comment and not item.is_multi_comment_end
	end

	return false
end

function SyntaxAnalysis:GetLastNoEmptyItems(items, lineIndex, deep)
	if lineIndex <= 0 then
		return
	end
	-- 限制递归深度
	deep = deep or 1
	
	if deep > 50 then
		return
	end

	local last_index = lineIndex - 1
	local last_item = items:get(last_index)
	if not last_item or last_item.text:length() == 0 then
		deep = deep + 1
		return self:GetLastNoEmptyItems(items, last_index, deep)
	end
	return last_item
end

function SyntaxAnalysis:SetEmptyLineItemMutilCommentState(lineItem, lineIndex)
	if not lineItem then
		return
	end

	lineItem.in_multi_comment = self:CheckIsInMultiComment(lineItem, lineIndex)
	if lineItem.is_multi_comment_start then
		lineItem.is_multi_comment_start = false
		self:SetItemInMultiConmet(lineIndex, nil, false)
	end

	if lineItem.is_multi_comment_end then
		lineItem.is_multi_comment_end = false
		if lineItem.in_multi_comment then
			self:SetItemInMultiConmet(lineIndex + 1, nil, true)
		end
	end
end