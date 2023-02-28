--[[
Title: Const
Author(s): wxa
Date: 2020/6/30
Desc: Const
use the lib:
-------------------------------------------------------
local Helper = NPL.load("script/ide/System/UI/Blockly/Helper.lua");
-------------------------------------------------------
]]

local Helper = NPL.export();
local Encoding = commonlib.gettable("commonlib.Encoding");

function Helper.XmlString2Lua(xmlString)
    return ParaXML.LuaXML_ParseString(xmlString);
end

function Helper.Lua2XmlString(input, bBeautify, sortByKey)
	if(not input) then return end
	local output = {};
	local indent = 0;
	local function OutputNode(inTable)
		if(not inTable) then return end
        if(type(inTable) == "string") then 
            if (bBeautify) then
                table.insert(output, "\n" .. string.rep("\t", indent) .. Encoding.EncodeHTMLInnerTextWithSpace(inTable))
            else
                table.insert(output, Encoding.EncodeHTMLInnerTextWithSpace(inTable))
            end
		elseif(type(inTable) == "table") then 	
			local nodeXML;
			if(inTable.name) then
				local indentStr;
				
				if(inTable.name == "![CDATA[") then
					nodeXML = "<"..inTable.name;
					table.insert(output, nodeXML)
				
					for i, childNode in ipairs(inTable) do
						if(type(childNode)=="string") then
							table.insert(output, childNode)
						end
					end
					table.insert(output, "]]>")
					return 
				else
					if(bBeautify) then
						indentStr = "\n"..string.rep("\t", indent);
					end
					nodeXML = (indentStr or "").."<"..inTable.name;
					table.insert(output, nodeXML)
				
					if(inTable.attr) then
						local name, value
						
						if sortByKey then
							local sortTable = {};
							for name, value in pairs(inTable.attr) do
								table.insert(sortTable, {key = name, value = value});
							end
							
							table.sort(sortTable, function(a, b) return a.key < b.key; end);	

							for _, att in ipairs(sortTable) do
								table.insert(output, string.format(" %s=\"%s\"", att.key, Encoding.EncodeStr(att.value)))
							end
							
						else
							
							for name, value in pairs(inTable.attr) do
								table.insert(output, string.format(" %s=\"%s\"", name, Encoding.EncodeStr(value)))
							end
						end
						
					end
					
				end
			end	
			local nChildSize = table.getn(inTable);
			if(nChildSize>0) then
				if(nodeXML) then
					table.insert(output, ">");
				end	
				indent = indent+1;
				for i, childNode in ipairs(inTable) do
					OutputNode(childNode);
				end
				indent = indent-1;
				
				if(nodeXML) then
					local indentStr;
					if(bBeautify) then
						indentStr = "\n"..string.rep("\t", indent);
					end
					table.insert(output, (indentStr or "").."</"..inTable.name..">");
				end	
			else
				if(nodeXML) then
					table.insert(output, "/>");
				end	
			end
		end
	end
	OutputNode(input)
	return table.concat(output);
end