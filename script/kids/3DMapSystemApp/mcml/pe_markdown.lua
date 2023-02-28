--[[
    author:{pbb}
    time:2022-02-21 20:33:23
]]

-----------------------------------
-- pe_markdown: pure text
-----------------------------------
NPL.load("(gl)script/ide/System/Util/MarkDown.lua");
local MarkDown = commonlib.gettable("System.Util.MarkDown");
local pe_markdown = commonlib.gettable("Map3DSystem.mcml_controls.pe_markdown");

local function strings_split(str, sep) 
	local list = {}
	local str = str .. sep
	for word in string.gmatch(str, '([^' .. sep .. ']*)' .. sep) do
		list[#list+1] = word
	end
	return list
end
-- it will create text in available position as single lined, or as multilined in new line position. 
-- the control takes up whatever vertical space needed to display the text as a paragraph,
-- param mcmlNode: is a text
-- param css: nil or a table containing css style, such as {color=string, href=string}. This is a style object to be associated with each node.
function pe_markdown.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, css, parentLayout)
    if mcmlNode then
        MarkDown.SetTextProperty(left, top, width, height)
        local markStr = mcmlNode:GetInnerText()
        local value = mcmlNode:GetAttributeWithCode("markdown_text",nil,true)
        markStr = value ~= nil and value or markStr
        if markStr and markStr ~= "" then
			local pageCtrl = mcmlNode:GetPageCtrl();
			if(pageCtrl) then
				local pe_script = commonlib.gettable("System.mcml_controls.pe_script");
				pe_script.SetPageScope(pageCtrl);
				pe_script.BeginCode(mcmlNode);
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
				pe_script.EndCode(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, css, parentLayout);
			end	
        end
    end
end