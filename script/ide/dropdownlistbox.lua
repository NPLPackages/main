--[[
Title: a dropdown listbox control using a textbox, a button and a listbox
Author(s): LiXizhi
Date: 2007/4/1
Note: because the listbox is displayed as a toplevel control, this dropdown list control can not be inside another top level container
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/dropdownlistbox.lua");
local ctl = CommonCtrl.dropdownlistbox:new{
	name = "dropdownlistbox1",
	alignment = "_lt",
	left=0, top=0,
	width = 300,
	height = 26,
	parent = nil,
	items = {"line1", "line2", "line3", "line4", values=nil,},
};
ctl:Show();
-------------------------------------------------------
]]

-- common control library
NPL.load("(gl)script/ide/common_control.lua");

-- define a new control in the common control libary

-- default member attributes
local dropdownlistbox = {
	-- the top level control name
	name = "dropdownlistbox1",
	-- normal window size
	alignment = "_lt",
	left = 0,
	top = 0,
	width = 300,
	height = 26, 
	buttonwidth = 20, -- the drop down button width
	dropdownheight = 150, -- the drop down list box height.
	parent = nil,
	-- appearance
	container_bg = nil, -- the background of container that contains the editbox and the dropdown button.
	editbox_bg = nil, -- edit box background texture
	dropdownbutton_bg = "Texture/DropDownBox.png:4 5 4 5",-- drop down button background texture
	-- a filter function(btn_bg, btn_width, btn_height) end, which should return a bg texture filename based on size. 
	dropdownbutton_bg_filter = function(btn_bg, btn_width, btn_height) 
		return btn_bg;
	end, 
	-- if not nil, it will centered inside buttonwidth and height
	dropdownbutton_width = nil,
	dropdownbutton_height = nil,
	listbox_bg = nil, -- list box background texture
	listbox_container_bg = "", 
	-- data
	-- an array of text, one needs to call RefreshListBox() manually, if one changes the items after the list box is displayed for the first time.
	-- items.values can be nil or a table mapping items name to item value. if items.values is nil, the GetValue() method will default to GetText().
	items = {values=nil,}, 
	text = "", -- current text
	-- onchange event, it can be nil, a string to be executed or a function of type void ()(sCtrlName, item)
	-- it will be called when the user select an item or pressed Enter in the editbox. One may call GetText() to retrieve text in the handler
	onselect= nil,
	-- it is a function to format the a selected item text to be displayed in the editbox. It takes a string and returns a string, such as fucntion(text) return text.." Seconds" end
	-- if this is nil, the original item text is displayed at the editbox.
	FuncTextFormat=nil,
	-- whether we allow user to enter text into the editbox
	AllowUserEdit = true,
	-- if true the drop down list box button is disabled. 
	IsReadonly = nil,
	listbox_cont_id = -1,
	listbox_id = -1,
	button_id = -1,
	editbox_id = -1,
	onremove = nil,
	emptyText = "",
}
CommonCtrl.dropdownlistbox = dropdownlistbox;

-- constructor
function dropdownlistbox:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- Destroy the UI control
function dropdownlistbox:Destroy()
	if(self.id) then
		ParaUI.Destroy(self.id);
	end
	ParaUI.Destroy(self.listbox_cont_id);
end

--@param bShow: boolean to show or hide. if nil, it will toggle current setting. 
function dropdownlistbox:Show(bShow)
	local _this, _parent;

	if(self.id) then
		_this=ParaUI.GetUIObject(self.id);
	end

	if (not _this or not _this:IsValid()) and bShow ~= false then
		_this = ParaUI.CreateUIObject("container",self.name,self.alignment,self.left,self.top,self.width,self.height);
		self.id = _this.id
		if(self.container_bg~=nil) then
			_this.background=self.container_bg;
		else
			_this.background="Texture/whitedot.png;0 0 0 0";
		end	
		_parent = _this;

		if(self.parent==nil) then
			_this:AttachToRoot();
		else
			self.parent:AddChild(_this);
		end
		CommonCtrl.AddControl(self.uiname or self.name, self);

		-- create the editbox
		local left, top, width, height = 0, 0, self.buttonwidth or 124, self.height or 32;
		_this = ParaUI.CreateUIObject("imeeditbox", "e", "_mt", 0, 0, width, height);
		_this:GetAttributeObject():SetField("EmptyText", self.emptyText);
		_parent:AddChild(_this);

		self.editbox_id = _this.id;
		_this.text = self.text;

		if not self.AllowUserEdit then
			_this.enabled = false;
		end

		_this:SetScript("onchange", function()
			self:handleEvent("OnTextChange");
		end)

		if self.editbox_bg~=nil then
			_this.background = self.editbox_bg;
		end

		-- create the dropdown button
		_this = ParaUI.CreateUIObject(
			"button",
			"b",
			"_rt",
			-width + (width - (self.dropdownbutton_width or width)) * 0.5,
			(height - (self.dropdownbutton_height or height)) * 0.5,
			self.dropdownbutton_width or width, self.dropdownbutton_height or height
		);

		_parent:AddChild(_this);

		self.button_id = _this.id;

		_this:SetScript("onclick", function()
			self:handleEvent("OnClickDropDownButton");
		end);

		local dropdownbutton_bg = self.dropdownbutton_bg_filter(self.dropdownbutton_bg, self.dropdownbutton_width or width, self.dropdownbutton_height or height);

		if dropdownbutton_bg and dropdownbutton_bg ~= "" then
			_this.background = dropdownbutton_bg;
		else
			_this.text = "▼";
		end	

		if(self.IsReadonly) then
			_this.enabled = false;
		end
		
		-- destroy the previous dropdown object if any. 
		ParaUI.Destroy(self.listbox_cont_id);
		
		_this = _parent;
	else
		if(bShow == nil) then
			if(_this.visible == true) then
				_this.visible = false;
			else
				_this.visible = true;
			end
		else
			_this.visible = bShow;
		end
	end	
end

-- @param eventName: "OnClickDropDownButton", "OnTextChange", "OnMouseUpListBoxCont", "OnMouseUpClose" and like virtual event
function dropdownlistbox:handleEvent(eventName, ...)
	local func = self[eventName];
	if(func) then
		func(self, ...);
	end
	if(dropdownlistbox.__onuievent__) then
		dropdownlistbox.__onuievent__(self, eventName, ...);
	end
end


--returns the text of the selected item, return "" if nothing is selected.
function dropdownlistbox:GetText()
	local _this=ParaUI.GetUIObject(self.editbox_id);
	if(_this:IsValid())then 
		return _this.text;
	else
		return "";
	end	
end

-- set text
function dropdownlistbox:SetText(text)
	local _this=ParaUI.GetUIObject(self.editbox_id);
	if(_this:IsValid())then 
		if(not self.FuncTextFormat) then
			_this.text = tostring(text or "");
		else
			_this.text = self.FuncTextFormat(text);
		end	
	end	
end

-- get the value if items.values is a table. 
function dropdownlistbox:GetValue()
	if(self.items and self.items.values) then
		local text = self:GetText();
		local value = self.items.values[text];
		if(value == nil) then
			return text
		else
			return value;	
		end
	else
		return self:GetText();	
	end
end

-- set the value if items.values is a table. 
function dropdownlistbox:SetValue(value)
	if(self.items and self.items.values) then
		local bFound;
		local text, value_;
		for text, value_ in pairs(self.items.values) do
			if(value_ == value) then
				bFound = true;
				self:SetText(text);
				break;
			end
		end
		if(not bFound) then
			self:SetText(value);
		end
	else
		self:SetText(value);
	end
end

-- return whether the listbox is enabled
function dropdownlistbox:GetEnabled()
	return ParaUI.GetUIObject(self.editbox_id).enabled;
end

-- set whether the listbox is enabled
function dropdownlistbox:SetEnabled(bEnable)
	ParaUI.GetUIObject(self.editbox_id).enabled = (bEnable and self.AllowUserEdit);
	ParaUI.GetUIObject(self.button_id).enabled = bEnable;
end

-- OBSOLETED: this function is not needed any more. It does nothing. 
function dropdownlistbox:RefreshListBox()
end

function dropdownlistbox:GetListBoxContainerOverlay()
	return ParaUI.GetUIObject(self.listbox_cont_id);
end

function dropdownlistbox:GetListBoxContainer()
	local _this
	if self.onremove then
		_this = ParaUI.GetUIObject(self.listbox_cont_id);
	else
		_this = ParaUI.GetUIObject(self.listbox_id);
	end
	return _this;
end

-- refill the listbox content using the items.
function dropdownlistbox:RefillListBox(width, height)
	local _this = self:GetListBoxContainer();

	if(_this:IsValid())then 
		_this:RemoveAll();
		if(self.items) then
			for index, value in ipairs(self.items) do
				if self.onremove then
					local buttonHeight = 25;

					if buttonHeight * index > height then
						break;
					end

					local _itemUI = ParaUI.CreateUIObject("container", "item", "_lt", 1 , buttonHeight * (index - 1), width - 2, buttonHeight);
					_itemUI.background = "Texture/whitedot.png"

					local _text = ParaUI.CreateUIObject("text", "textitem" .. index, "_lt", 5, 6, width, buttonHeight);
					_text.text = tostring(value);
					_text.font = "System;12;bold;false;"
					_text.shadow = false;
					_itemUI:AddChild(_text)

					local _remove = ParaUI.CreateUIObject("container", "removeitem" .. index, "_rt", -20, 11, 9, 8);
					_remove.background = "Texture/Aries/Common/Frame_Close_32bits.png; 4 4 9 8";
					_remove.shadow = false;
					_remove.visible = false;

					_itemUI:SetScript("onmouseenter", function()
						_remove.visible = true;
						_guihelper.SetUIColor(_itemUI, "233 233 233")
					end)

					_itemUI:SetScript("onmouseleave", function()
						_remove.visible = false;
						_guihelper.SetUIColor(_itemUI, "255 255 255")
					end)

					_itemUI:SetScript("onmouseup", function()
						-- change editbox text with the selection text
						local editbox = ParaUI.GetUIObject(self.editbox_id);
						if(editbox:IsValid()) then
							-- use some formatting if any.
							if(not self.FuncTextFormat) then
								editbox.text = tostring(value);
							else
								editbox.text = self.FuncTextFormat(tostring(value));
							end

							-- call the event handler if any
							if(self.onselect ~= nil)then
								if(type(self.onselect) == "string") then
									NPL.DoString(self.onselect);
								else
									self.onselect(self.name, self:GetValue());
								end
							end
						end

						ParaUI.Destroy(self.listbox_cont_id);
					end)

					_remove:SetScript("onmousedown", function()
						if type(self.onremove) == 'function' then
							self.onremove(value)
						end

						ParaUI.Destroy(self.listbox_cont_id);
					end)
					_itemUI:AddChild(_remove)

					_this:AddChild(_itemUI)
				else
					_this:AddTextItem(tostring(value));
				end
			end
		end	
	end
end

function dropdownlistbox:GetParentUIObject()
	if(self.id) then
		local _this = ParaUI.GetUIObject(self.id);
		if(_this:IsValid()) then
			return _this;
		end
	end
end

-- called when the drop down button is clicked.
function dropdownlistbox.OnClickDropDownButton(self)
	-- calculate the position of drop down list box from the current position of the control
	local _this = ParaUI.GetUIObject(self.id);

	if(_this:IsValid() == false) then
		return;
	end

	local _, _, screenWidth, screenHeight = ParaUI.GetUIObject("root"):GetAbsPosition();
	local left, top, width, height = _this:GetAbsPosition();

	-- make the listbox appear at the right position
	if (top + height + self.dropdownheight) > screenHeight then
		-- float up display if there is no enough space for drop down display. 
		top = top - self.dropdownheight;
		if top < 0 then top = 0 end
	else
		-- drop down display
		top = top + height;
	end

	-- TODO: if there are few items in the list, there is no need to display the full drop down height.
	height = self.dropdownheight;

	local _this = ParaUI.GetUIObject(self.listbox_cont_id);

	if _this:IsValid() == false then
		local _parent;

		-- create the list box and its container if it has not yet been created before.
		_this = ParaUI.CreateUIObject("container", "c", "_lt", left, top, width, height);
		_this.background = self.listbox_container_bg;
		_this.zorder = 10000;
		_this:AttachToRoot();

		self.listbox_cont_id = _this.id;

		_this:SetScript("onmouseup", function()
			self:handleEvent("OnMouseUpListBoxCont");
		end);
		_this.visible = false;
		_parent = _this;

		if not self.onremove then
			_this = ParaUI.CreateUIObject("listbox","l","_fi",0,0,0,0);
			
			if(self.listbox_bg~=nil) then
				_this.background=self.listbox_bg;
			end	
			
			_parent:AddChild(_this);
			self.listbox_id = _this.id;

			_this:SetScript("onselect", function()
				self:handleEvent("OnSelectListBox");
			end)
		end

		-- refresh on first use
		self:RefillListBox(width, height);
		
		_this = _parent;
	else
		_this.x = left;
		_this.y = top;
		_this.width = width;
	end

	_this.visible = not _this.visible;

	if _this.visible then
		_this:BringToFront();
		_this:SetTopLevel(true);

		if KidsUI ~= nil then
			KidsUI.PushState(
				{
					name = "dropdownlistbox_listbox_cont",
					OnEscKey = function()
						dropdownlistbox.OnMouseUpListBoxCont(self);
					end
				}
			);
		end
	else
		if KidsUI ~= nil then
			KidsUI.PopState("dropdownlistbox_listbox_cont");
		end
	end
end


-- called when the user select a list box item
function dropdownlistbox.OnMouseUpListBoxCont(self)
	
	ParaUI.Destroy(self.listbox_cont_id);
	
	if(KidsUI~=nil) then
		KidsUI.PopState("dropdownlistbox_listbox_cont");
	end	
end

-- called when the text has changed
function dropdownlistbox.OnTextChange(self)
	--if(virtual_key == Event_Mapping.EM_KEY_RETURN or virtual_key == Event_Mapping.EM_KEY_NUMPADENTER) then
		-- call the event handler if any
		if(self.onselect~=nil)then
			if(type(self.onselect) == "string") then
				NPL.DoString(self.onselect);
			else
				self.onselect(self.name, self:GetValue());
			end
		end
	--end	
end


-- called when the user select a list box item
-- @param value: if nil, it will use current listbox value. otherwise it will force select this value. 
function dropdownlistbox.OnSelectListBox(self, value)
	local listbox = ParaUI.GetUIObject(self.listbox_id);
	if(listbox:IsValid()) then
		-- hide the listbox	container
		local listbox_cont = ParaUI.GetUIObject(self.listbox_cont_id);
		listbox_cont.visible = false;
	
		-- change editbox text with the selection text	
		local editbox = ParaUI.GetUIObject(self.editbox_id);
		if(editbox:IsValid()) then
			-- use some formatting if any.
			if(value) then
				self:SetValue(value)
			else
				if(not self.FuncTextFormat) then
					editbox.text = listbox.text;
				else
					editbox.text = self.FuncTextFormat(listbox.text);
				end	
			end
			
			-- call the event handler if any
			if(self.onselect~=nil)then
				if(type(self.onselect) == "string") then
					NPL.DoString(self.onselect);
				else
					self.onselect(self.name, value or self:GetValue());
				end
			end
		end
	end
end

-- insert item to back: if already exist, it does nothing.
-- @param item: string item 
-- @param bNoUpdate: if true, the list box is not refreshed even a new item is added. 
-- @return the index of the inserted item. 
function dropdownlistbox:InsertItem(item, bNoUpdate)
	if(type(item)~="string") then return end
	
	for i, v in ipairs(self.items) do
		if (v == item) then
			return i;
		end
	end
	
	local i = commonlib.insertArrayItem(self.items, nil, item);
	if(not bNoUpdate) then
		--self:RefreshListBox();
	end
	return i;
end

function dropdownlistbox:GetItemIndexByValue(value)
	if(self.items) then
		local valueMap = self.items.values;
		for i, v in ipairs(self.items) do
			if (v == value or (valueMap and valueMap[v] == value)) then
				return i;
			end
		end
	end
end