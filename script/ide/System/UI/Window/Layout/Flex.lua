--[[
Title: Flex
Author(s): wxa
Date: 2020/6/30
Desc: 弹性布局类
use the lib:
-------------------------------------------------------
local Flex = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Layout/Flex.lua");
-------------------------------------------------------
]]

local Flex = NPL.export();
local FlexDebug = GGS.Debug.GetModuleDebug("FlexDebug").Enable(); --Enable  Disable


local function LayoutElementFilter(el)
	local layout = el:GetLayout();
	return layout:IsLayout() and layout:IsUseSpace();
end 

-- 重新布局子元素
local function RelayoutChildrenElement(element, relayoutReason)
	for child in element:ChildElementIterator(true, LayoutElementFilter) do
		local childLayout = element:GetLayout();
		-- 元素宽度改变而子元素非固定宽度
		if (relayoutReason == "width_change" and not childLayout:IsFixedWidth()) then child:UpdateLayout() end
		if (relayoutReason == "height_change" and not childLayout:IsFixedHeight()) then child:UpdateLayout() end
	end
end 

local function UpdateRow(layout, style)
	local contentOffsetX, contentOffsetY = layout:GetContentOffset();
    local _, _, width, height = layout:GetContentGeometry();
	local lines, line = {}, {layouts = {}, width = 0, height = 0, flexGrow = 0};
	table.insert(lines, line);
	for child in layout:GetElement():ChildElementIterator(true, LayoutElementFilter) do
		local childLayout, childStyle = child:GetLayout(), child:GetStyle();
		local childSpaceWidth, childSpaceHeight = childLayout:GetSpaceWidthHeight();

		if (width and (line.width + childSpaceWidth) > width) then
			line = {layouts = {}, width = 0, height = 0, flexGrow = 0};
			table.insert(lines, line);
		end

		line.flexGrow = line.flexGrow + (childStyle["flex-grow"] or 0);
		line.width = line.width + childSpaceWidth;
		line.height = math.max(line.height, childSpaceHeight);
		table.insert(line.layouts, childLayout);
	end

	-- local totalHeight = 0;
    local offsetLeft, offsetTop, HGap, VGap = 0, 0, 0, 0;
    local contentWidth, contentHeight = 0, 0;
    local function UpdateChildLayoutPos(line)
        for _, childLayout in ipairs(line.layouts) do
			local spaceWidth, spaceHeight = childLayout:GetSpaceWidthHeight();
			local childMarginTop, childMarginRight, childMarginBottom, childMarginLeft = childLayout:GetMargin();
			local alignSelf = childLayout:GetStyle()["align-self"];
			local lineHeight = line.height;
			if (alignSelf == "center") then
				childLayout:SetPos(contentOffsetX + offsetLeft + childMarginLeft, contentOffsetY + offsetTop + childMarginTop + (lineHeight - spaceHeight) / 2);
			elseif (alignSelf == "flex-end") then
				childLayout:SetPos(contentOffsetX + offsetLeft + childMarginLeft, contentOffsetY + offsetTop + childMarginTop + lineHeight - spaceHeight);
			else
				childLayout:SetPos(contentOffsetX + offsetLeft + childMarginLeft, contentOffsetY + offsetTop + childMarginTop);
			end
			-- FlexDebug.Format("child layout left = %s, top = %s, spaceWidth = %s, hgap = %s, count = %s", offsetLeft, offsetTop, spaceWidth, HGap, #line.layouts);
            offsetLeft = offsetLeft + spaceWidth + HGap;
        end
    end

    if (height) then
        local totalHeight = 0;
        for _, line in ipairs(lines) do totalHeight = totalHeight + line.height end
        local remainHeight = height - totalHeight;
        if (style["align-items"] == "center") then 
            offsetTop = remainHeight / 2; 
        elseif (style["align-items"] == "flex-end") then 
            offsetTop = remainHeight; 
        elseif (style["align-items"] == "space-between") then 
            local gapCount = #(line.layouts) - 1;
            if (gapCount > 0) then VGap = remainHeight / gapCount end
        elseif (style["align-items"] == "space-around") then 
            local gapCount = #(line.layouts) + 1;
            VGap = remainHeight / gapCount;
            offsetTop = VGap;
        end 
    end
	-- FlexDebug(lines);
	for no, line in ipairs(lines) do
		if (width) then
			local remainWidth = width - line.width;
			if (line.flexGrow > 0) then
				for _, childLayout in ipairs(line.layouts) do
					childLayout:SetPos(contentOffsetX + offsetLeft, contentOffsetY + offsetTop);
					local spaceWidth = childLayout:GetSpaceWidthHeight();
					local flexGrow = childLayout:GetStyle()["flex-grow"] or 0;
					if (childLayout:IsFixedWidth() or flexGrow == 0) then
						offsetLeft = offsetLeft + spaceWidth;
					else 
						local autoWidth= remainWidth * flexGrow / line.flexGrow;
						offsetLeft = offsetLeft + spaceWidth + autoWidth;
						local width, height = childLayout:GetWidthHeight();
						childLayout:SetWidthHeight(width + autoWidth, height); 
						if (autoWidth ~= 0) then RelayoutChildrenElement(childLayout:GetElement(), "width_change") end
						-- 是否重新更新子布局
					end
				end
			else
                if (style["justify-content"] == "center") then 
                    offsetLeft = remainWidth / 2; 
                elseif (style["justify-content"] == "flex-end") then 
                    offsetLeft = remainWidth; 
				elseif (style["justify-content"] == "space-between") then 
					local gapCount = #(line.layouts) - 1;
					if (gapCount > 0) then HGap = remainWidth / gapCount end
                elseif (style["justify-content"] == "space-around") then 
					local gapCount = #(line.layouts) + 1;
					HGap = remainWidth / gapCount;
					offsetLeft = HGap;
				end 
				-- FlexDebug.Format("no = %s, hgap = %s, contentWidth = %s, width = %s, count = %s", no, HGap, line.width, width, #line.layouts);
				UpdateChildLayoutPos(line);
			end
		else 
			UpdateChildLayoutPos(line);
		end
        contentWidth = math.max(contentWidth, offsetLeft - HGap);
		offsetLeft, HGap = 0, 0;
        offsetTop = offsetTop + line.height + VGap;
        contentHeight = math.max(contentHeight, offsetTop - VGap);
	end

	-- FlexDebug.Format("left = %s, top = %s, width = %s, height = %s, contentWidth = %s, contentHeight = %s", left, top, width, height, contentWidth, contentHeight);
    layout:SetRealContentWidthHeight(contentWidth, contentHeight);
end

local function UpdateCol(layout, style)
	local contentOffsetX, contentOffsetY = layout:GetContentOffset();
	local _, _, width, height = layout:GetContentGeometry();
	local lines, line = {}, {layouts = {}, width = 0, height = 0, flexGrow = 0};
	-- FlexDebug.Format("element left = %s, top = %s, width = %s, height = %s", left, top, width, height);
	table.insert(lines, line);
	for child in layout:GetElement():ChildElementIterator(true, LayoutElementFilter) do
		local childLayout, childStyle = child:GetLayout(), child:GetStyle();
		local childSpaceWidth, childSpaceHeight = childLayout:GetSpaceWidthHeight();

		if (height and (line.height + childSpaceHeight) > height) then
			line = {layouts = {}, width = 0, height = 0, flexGrow = 0};
			table.insert(lines, line);
		end

		line.flexGrow = line.flexGrow + (childStyle["flex-grow"] or 0);
		line.height = line.height + childSpaceHeight;
		line.width = math.max(line.width, childSpaceWidth);
		table.insert(line.layouts, childLayout);
		-- FlexDebug.Format("childSpaceWidth = %s, childSpaceHeight = %s, width = %s, height = %s, childCount = %s", childSpaceWidth, childSpaceHeight, width, height, #line.layouts);
	end

	-- local totalHeight = 0;
    local offsetLeft, offsetTop, HGap, VGap = 0, 0, 0, 0;
    local contentWidth, contentHeight = 0, 0;
    local function UpdateChildLayoutPos(line)
        for _, childLayout in ipairs(line.layouts) do
			local spaceWidth, spaceHeight = childLayout:GetSpaceWidthHeight();
			local childMarginTop, childMarginRight, childMarginBottom, childMarginLeft = childLayout:GetMargin();
			local alignSelf = childLayout:GetStyle()["align-self"];
			local lineWidth = line.width;
			if (alignSelf == "center") then
				childLayout:SetPos(contentOffsetX + offsetLeft + childMarginLeft + (lineWidth - spaceWidth) / 2, contentOffsetY + offsetTop + childMarginTop);
			elseif (alignSelf == "flex-end") then
				childLayout:SetPos(contentOffsetX + offsetLeft + childMarginLeft + lineWidth - spaceWidth, contentOffsetY + offsetTop + childMarginTop);
			else
				childLayout:SetPos(contentOffsetX + offsetLeft + childMarginLeft, contentOffsetY + offsetTop + childMarginTop);
			end
			offsetTop = offsetTop + spaceHeight + VGap;
			-- FlexDebug.Format("child layout left = %s, top = %s, spaceHeight = %s, vgap = %s, count = %s", offsetLeft, offsetTop, spaceHeight, VGap, #line.layouts);
        end
    end

    if (width) then
        local totalWidth = 0;
        for _, line in ipairs(lines) do totalWidth = totalWidth + line.width end
        local remainWidth = width - totalWidth;
        if (style["align-items"] == "center") then 
            offsetLeft = remainWidth / 2; 
        elseif (style["align-items"] == "flex-end") then 
            offsetLeft = remainWidth; 
        elseif (style["align-items"] == "space-between") then 
            local gapCount = #(line.layouts) - 1;
            if (gapCount > 0) then HGap = remainWidth / gapCount end
        elseif (style["align-items"] == "space-around") then 
            local gapCount = #(line.layouts) + 1;
            HGap = remainWidth / gapCount;
            offsetLeft = HGap;
        end 
    end
    
	for _, line in ipairs(lines) do
		if (height) then
			local remainHeight = height - line.height;
			if (line.flexGrow > 0) then
				for _, childLayout in ipairs(line.layouts) do
					childLayout:SetPos(contentOffsetX + offsetLeft, contentOffsetY + offsetTop);
					local spaceWidth, spaceHeight = childLayout:GetSpaceWidthHeight();
					local flexGrow = childLayout:GetStyle()["flex-grow"] or 0;
					if (childLayout:IsFixedHeight() or flexGrow == 0) then
						offsetTop = offsetTop + spaceHeight;
					else 
						local autoHeight= remainHeight * flexGrow / line.flexGrow;
						offsetTop = offsetTop + spaceHeight + autoHeight;
						local width, height = childLayout:GetWidthHeight();
						childLayout:SetWidthHeight(width, height + autoHeight); 
						if (autoHeight ~= 0) then RelayoutChildrenElement(childLayout:GetElement(), "height_change") end

						-- 是否重新更新子布局
					end
				end
			else
                if (style["justify-content"] == "center") then 
                    offsetTop = remainHeight / 2; 
                elseif (style["justify-content"] == "flex-end") then 
                    offsetTop = remainHeight; 
				elseif (style["justify-content"] == "space-between") then 
					local gapCount = #(line.layouts) - 1;
					if (gapCount > 0) then VGap = remainHeight / gapCount end
                elseif (style["justify-content"] == "space-around") then 
					local gapCount = #(line.layouts) + 1;
					VGap = remainHeight / gapCount;
					offsetTop = VGap;
				end 
				UpdateChildLayoutPos(line);
			end
		else 
			UpdateChildLayoutPos(line);
        end
        contentHeight = math.max(contentHeight, offsetTop - VGap);
        offsetTop, VGap = 0, 0;
        offsetLeft = offsetLeft + line.width + HGap;
        contentWidth = math.max(contentWidth, offsetLeft - HGap);
    end
    layout:SetRealContentWidthHeight(contentWidth, contentHeight);
end

local function Update(layout)
    local style = layout:GetStyle();
    if (style.display ~= "flex" and style.display ~= "inline-flex") then return end

	local flexDirection = style["flex-direction"] or "row";
    if (flexDirection == "row" or flexDirection == "row-reverse") then
        UpdateRow(layout, style);
    end

    if (flexDirection == "column" or flexDirection == "column-reverse") then
        UpdateCol(layout, style);
    end
end

function Flex.Update(layout)
    Update(layout);
	return layout;
end
