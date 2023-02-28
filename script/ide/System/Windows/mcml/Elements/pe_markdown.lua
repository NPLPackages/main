--[[
    author:{pbb}
    time:2022-03-01 11:19:16
    use the lib:
    ------------------------------------------------------------
    NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_markdown.lua");
    System.Windows.mcml.Elements.pe_markdown:RegisterAs("markdown","pe:markdown");
    ------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Util/MarkDown.lua");
local MarkDown = commonlib.gettable("System.Util.MarkDown");
NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
local pe_markdown = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_markdown"));
pe_markdown:Property({"class_name", "pe:markdown"})
local function strings_split(str, sep) 
	local list = {}
	local str = str .. sep
	for word in string.gmatch(str, '([^' .. sep .. ']*)' .. sep) do
		list[#list+1] = word
	end
	return list
end
function pe_markdown:ctor()
end

function pe_markdown:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
    local css2 = self:GetStyle(); --自身的style
    local node = self
    while not css2.width do
        node = node:GetParent()
        css2 = node:GetStyle()
    end
    --必须要获得控件显示的大小，不然获取不到需要显示的文本行数，否则会陷入死循环
    if css2.width <= 0 then
        return 
    end
    MarkDown.SetTextProperty(css2:margin_left(),css2:margin_top(),css2.width, css2.height)
    local markStr = self:GetInnerText()
    local value = self:GetAttributeWithCode("markdown_text",nil,true)
    markStr = value ~= nil and value or markStr
    if markStr and markStr ~= "" then
        local pageCtrl = self:GetPageCtrl();
        if(pageCtrl) then
            local pe_script = commonlib.gettable("System.Windows.mcml.Elements.pe_script")
            pe_script.SetPageScope(pageCtrl);
            pe_script.BeginCode(self);
            local htmlText = ""
            local lines = strings_split(markStr, "\n") 
            local start = 1
            local size = #lines
            while (start <= size) do
                local text = string.match(lines[start], '^%s*(.-)%s*$')
                htmlText = htmlText .. MarkDown.GetLineStr(text)
                start = start + 1 
            end
            document.write(htmlText)
            pe_script.EndCode(self);
        end	
    end
	pe_markdown._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css)
end