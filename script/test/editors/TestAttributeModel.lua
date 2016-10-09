--[[
Author: LiXizhi
Date: 2015/1/24
Desc: testing NPL related functions.
-----------------------------------------------
NPL.load("(gl)script/test/editors/TestAttributeModel.lua");
local TestAttributeModel = commonlib.gettable("tests.TestAttributeModel");
TestAttributeModel.PrintAll();
TestAttributeModel.PrintScene();
-----------------------------------------------
]]
NPL.load("(gl)script/ide/LuaXML.lua");
local TestAttributeModel = commonlib.gettable("tests.TestAttributeModel");

function TestAttributeModel.PrintAll()
	local attr = ParaEngine.GetAttributeObject();
	local xmlNode = TestAttributeModel.SerializeAttributeObjectToXMLNode(attr);
	commonlib.log.log_long(commonlib.Lua2XmlString(xmlNode, true));
end

function TestAttributeModel.PrintScene()
	local scene = ParaScene.GetObject("<root>");
	local attr = scene:GetAttributeObject();
	local xmlNode = TestAttributeModel.SerializeAttributeObjectToXMLNode(attr);
	commonlib.log.log_long(commonlib.Lua2XmlString(xmlNode, true));
end

function TestAttributeModel.PrintAssetManager()
	local attr = ParaEngine.GetAttributeObject():GetChild("AssetManager");
	local xmlNode = TestAttributeModel.SerializeAttributeObjectToXMLNode(attr);
	commonlib.log.log_long(commonlib.Lua2XmlString(xmlNode, true));
end

function TestAttributeModel.PrintGUI()
	local attr = ParaEngine.GetAttributeObject():GetChild("GUI");
	local xmlNode = TestAttributeModel.SerializeAttributeObjectToXMLNode(attr);
	commonlib.log.log_long(commonlib.Lua2XmlString(xmlNode, true));
end

function TestAttributeModel.PrintViewport()
	local attr = ParaEngine.GetAttributeObject():GetChild("ViewportManager");
	local xmlNode = TestAttributeModel.SerializeAttributeObjectToXMLNode(attr);
	commonlib.log.log_long(commonlib.Lua2XmlString(xmlNode, true));
end

-- only output attribute class and all child nodes recursively, it does not print data fields. 
function TestAttributeModel.SerializeAttributeObjectToXMLNode(attr, xmlNode)
	xmlNode = xmlNode or {};
	xmlNode.name = attr:GetField("ClassName", "unknown");
	xmlNode.attr = xmlNode.attr or {};
	xmlNode.attr.classid = attr:GetField("ClassID", 0);
	xmlNode.attr.id = attr:GetField("id", "");
	xmlNode.attr.name = attr:GetField("name", "");
	
	local nColCount = attr:GetColumnCount();
	for cols=0, nColCount-1 do
		local nRowCount = attr:GetChildCount(cols);
		if(nRowCount > 0) then
			local node = xmlNode;
			if(nColCount > 1) then
				node = {name="child", attr={cols_index=cols, row_count=nRowCount}};
				xmlNode[#xmlNode+1] = node;
			end
			for rows = 0, nRowCount-1  do
				local child = attr:GetChildAt(rows, cols);
				if(child:IsValid()) then
					local childNode = TestAttributeModel.SerializeAttributeObjectToXMLNode(child);
					childNode.attr.index = format("%d,%d", rows, cols);
					node[#node+1] = childNode;
				end
			end
		end
	end
	return xmlNode;
end