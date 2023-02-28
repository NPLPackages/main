--[[
    Title: a simple markdown text parsing
    author:{pbb}
    time:2022-03-02 16:51:04
    uselib:
        NPL.load("(gl)script/ide/System/Util/MarkDown.lua");
        local MarkDown = commonlib.gettable("System.Util.MarkDown");
]]

local MarkDown = commonlib.inherit(nil, commonlib.gettable("System.Util.MarkDown"))
MarkDown.x = 0
MarkDown.y = 0
MarkDown.width = 0
MarkDown.height = 0
MarkDown.emptyLineSpacing = 22;
-- #， ##， ###， decrease by 1 in font size
MarkDown.Header1FontSize = 27;
-- main body text
MarkDown.ContentFontSize = MarkDown.Header1FontSize - 3;
local self = MarkDown

local function strings_substring(str, s, e) 
	return string.sub(str, s, e)
end

local function strings_indexOf(str, substr) 
	for i = 1, #str do
		if strings_substring(str, i, i + #substr - 1) == substr  then
			return i
		end
	end
	return nil
end

local function strings_trim(str)
	return string.match(str, '^%s*(.-)%s*$')
end

 --是否是空行
 local function is_empty_list(line) 
	if strings_trim(line or "") == "" then
		return true
	end
	return false
end

-- 是否是列表 
local function is_list(line) 
	if strings_indexOf(line, "* ") == 1 or
			strings_indexOf(line, "- ") == 1 or
			strings_indexOf(line, "+ ") == 1 or 
			(string.match(line, '^%d+. ')) then
		return true
	end
	return false
end

-- 是否是标题
local header_list = {
    "# ",
    "## ",
    "### ",
    "#### ",
    "##### ",
    "###### ",
}
local function is_header(line) 
	for _, str in ipairs(header_list) do
		if strings_indexOf(line, str) == 1 then
			return true
		end
	end
	return false
end

local function get_header_num(text) 
    local hn = 0
	for idx, line in ipairs(header_list) do 
		if strings_indexOf(text, line) == 1 then
			hn = idx
			break
		end
	end
    return hn
end

-- 是否是图片
local function is_picture(line)
    local reg_str = '(!%[(.-)%]%((.-)%))'
    if string.find(line,reg_str) then
        return true
    end
    return false
end

-- 是否是图文混合
local function is_picture1(line)
    local reg_str = '(!%[(.-)%]%[(.-)%]%((.-)%))'
    if string.find(line,reg_str) then
        return true
    end
    return false
end

-- 是否是链接
local function isLink(line)
    local reg_str = '(%[(.-)%]%((.-)%))'
    if string.find(line,reg_str) then
        return true
    end
    return false
end

-- 是否代码块
local function iscode(text)
    local flag_str = '```'
	if strings_indexOf(text, flag_str) == 1 then
		return true
	end
    return false
end

local function ismcml(text)
    if string.find(text,'(%<(.-)%>(.-)%</(.-)%>)') or string.find(text,'(%<(.-)/%>)') or string.find(text,'(%<(.-)%>)') then
        return true
    end
    return false
end

function MarkDown.SetTextProperty(x,y,width,height) --这个方法必须要调用
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.view_width = self.width - self.x
end

function MarkDown.GetLineStr(text)
    if ismcml(text) then
        return text
    end
    if is_header(text) then
        return MarkDown.GetHeader(text)
    end
    if is_empty_list(text) then
        return MarkDown.GetEmptyLine(text)--"<pe:br></pe:br>"
    end
    if is_picture(text) then
        return MarkDown.GetImage(text)
    end
    if isLink(text) then
        return MarkDown.GetLink(text)
    end
    return MarkDown.GetText(text)
end

function MarkDown.GetEmptyLine(text)
    return string.format([[<div style="width:%dpx;height:%dpx"></div>]],self.view_width, MarkDown.emptyLineSpacing)
end

function MarkDown.GetHeader(text)
    local hn = get_header_num(text) 
    local hStr = header_list[hn]
    text = string.gsub(text,hStr,"")
    if isLink(text) then
        return MarkDown.GetLink(text,hn)
    end
    return MarkDown.GetText(text,hn)
end

function MarkDown.GetLink(text,hn)
    local reg_str = '(%[(.-)%]%((.-)%))'
    local match_str, link_text, link_href = string.match(text, reg_str)
    local hn = hn or 0
    local base_font_size = MarkDown.Header1FontSize
    local font_weight = (hn > 0)  and "bold" or "norm"
    local font_size = base_font_size - hn + 1
    if hn == 0 then
        font_size = MarkDown.ContentFontSize
    end
    return string.format([[<a href = "%s" style="font-weight:%s;font-size:%dpx">%s</a>]],link_href,font_weight,font_size,link_text)
end

function MarkDown.GetText(text,hn)
    local hn = hn or 0
    local base_font_size = MarkDown.Header1FontSize
    local font_weight = (hn > 0)  and "bold" or "norm"
    local font_size = base_font_size - hn + 1
    if hn == 0 then
        font_size = MarkDown.ContentFontSize
    end
    local line_height = font_size + 2
    local font = string.format("%s;%d;%s", "System", font_size, font_weight);
    local buttonText = string.gsub(text, "nbsp;", " ")
    return string.format([[<div style="font-weight:%s;font-size:%dpx;line-height:%dpx">%s</div>]],font_weight,font_size,font_size,text)
end

function MarkDown.GetImage(text)
    local reg_str = '(!%[(.-)%]%((.-)%))'
    local match_str, image_text, image_href = string.match(text, reg_str)
    if not match_str then
        return 
    end
    local is3DModel = false
    if string.find(image_href,"%.bmax") or string.find(image_href,"%.blocks%.xml") or string.find(image_href,"%.x") then
        is3DModel = true
        return 
    end
    local img_attr = commonlib.split(image_text, "x X")
	local width,height = 32,32
	if img_attr and #img_attr >= 2 then
		width = tonumber(img_attr[1]) or 32
		height = tonumber(img_attr[2]) or 32
	end
    if width > self.width then
        local scale = width/self.width
        width = width /scale
        height = height / scale
    end
    if string.find(image_href,"http") then --http的图片得用img标签
        return string.format([[<img src="%s" style="width:%dpx;height:%dpx;" />]],image_href,width,height)
    end
    if not string.find(image_href,"Texture") then
		local worldPath = GameLogic.GetWorldDirectory() --显示世界目录的图片
		image_href = worldPath..image_href
	end

    return string.format([[<div style="width:%dpx;height:%dpx;background:url(%s);"></div>]],width,height,image_href)
end