--[[
Title: Page
Author(s): LiXizhi
Date: 2015/4/27
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Page.lua");
local Page = commonlib.gettable("System.Windows.mcml.Page");
local page = Page:new();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/PageLayout.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/Style.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/BindingContext.lua");
local BindingContext = commonlib.gettable("System.Windows.mcml.BindingContext");
local Style = commonlib.gettable("System.Windows.mcml.Style");
local mcml = commonlib.gettable("System.Windows.mcml");
local Elements = commonlib.gettable("System.Windows.mcml.Elements");
local PageLayout = commonlib.gettable("System.Windows.mcml.PageLayout");

local Page = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.createtable("System.Windows.mcml.Page", {
	name = nil,
	-- nil means not started downloading. 1 means ready. 0 means downloading. 2 means not able to download page.  3 means <pe:mcml> node not found in page body.
	status = nil,
	-- the status string message
	status_line = nil,
	-- the <pe:mcml> node
	mcmlNode = nil,
	-- a function to be called when a new page is downloaded.
	OnPageDownloaded = nil,
	-- default policy if no one is specified.
	cache_policy = System.localserver.CachePolicy:new("access plus 1 hour"),
	-- default refresh page delay time in seconds. More information, please see Refresh() method.
	DefaultRefreshDelayTime = 1,
	-- default page redirect delay time in seconds. More information, please see Redirect() method.
	DefaultRedirectDelayTime = 1,
	-- time remaining till next refresh page update. More information, please see Refresh() method.
	RefreshCountDown = nil,
	-- the init url, if this is not provided at first, one needs to call Init(url) before calling Create()
	url = nil,
	-- we will keep all opened url in a stack, so that we can move back or forward. This is just a simple table array for all opened urls.
	opened_urls = nil,
	-- if nil it means the last one in opened_urls, otherwise, the index of the current url in opened_urls
	opened_url_index = nil,
	-- mcml page to be displayed when an error occurs.
	errorpage = nil,
	-- in case this page is inside an iframe, the parentpage contains the page control that created the iframe. use GetParentPage() function to get it.
	parentpage = nil,
	-- the window object containing the page control. CloseWindow() function will close this window object.
	window = nil,
	-- this is a user-defined call back function (bDestroy) end. it is called whenever the page is closed by its container window. Please note, if the page is not inside a MCMLBrowserWnd() this function may not be called.
	OnClose = nil,
	-- whether the page will paint on to its own render target.
	SelfPaint = nil,
	-- this is a user-defined call back function (filelist) end. it is called whenever user drop files on this page.
	-- note return true to tell dispatcher we're interested in this message, otherwise return false.
	OnDropFiles = nil,
}));
Page:Property("Name", "Page");
Page:Signal("created");

-- make jquery-like invoke
getmetatable(Page:new()).__call = function(self, ...)
	return self:jquery(...)
end

function Page:ctor()
	-- this will prevent recursive calls to self:Refresh(), which makes self:Refresh(0) pretty safe.
	self.refresh_depth = 0;
	self.hotkeyNodes = {};
	self.tabIndexNodes = {};
	self.currentTabNode = nil;
end

-- Init control with a MCML treenode or page url. If a local version is found, it will be used regardless of whether it is expired or not.
-- It does not create UI until Page:Create() is called.
-- _NOTE_: Calling this function with different urls after Page:Create() will refresh the UI by latest url.
--@param url: the url of the MCML page. It must contain one <pe:mcml> node. Page should be UTF-8 encoded. It will automatically replace %params% in url if any
-- if url is nil, content will be cleared. if it is a table, it will be the mcmlNode to open.
--@param cache_policy: cache policy object. if nil, default is used.
--@param bRefresh: whether to refresh if url is already loaded before.
function Page:Init(url, cache_policy, bRefresh)
	if(url == nil or url=="") then
		-- clear all
		self.status = nil;
		self.mcmlNode = nil;
		self.style = nil;
		self:OnRefresh();
		return
	elseif(type(url) == "table" and table.getn(url)>0) then
		-- url is actually mcmlNode
		self.url="";
		Page.OnPageDownloaded_CallBack(url, nil, self)
		return
	end

	self.url = url;
	-- downloading
	self.status = 0;

	if(string.find(url, "^http://")) then
		self.status_line = "正在刷新页面请等待......";
		self:OnRefresh();
		-- for remote url, use the local server to retrieve the data
		local ls = System.localserver.CreateStore(nil, 2);
		if(ls)then
			ls:CallXML(cache_policy or self.cache_policy, url, Page.OnPageDownloaded_CallBack, self)
		end
	else
		-- for local file, open it directly
		-- remove requery string when parsing file.
		local filename = string.gsub(url, "%?.*$", "")

		local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
		if(type(xmlRoot)=="table" and table.getn(xmlRoot)>0) then
			Page.OnPageDownloaded_CallBack(xmlRoot, nil, self)
		else
			self.status_line = "无法打开页面......";
			self:OnRefresh();
			log("warning: unable to open local page "..url.."\n")
		end
	end
end

-- go to a given url or move backward or forward. This function can NOT be called in embedded page code. In page script, use Redirect() instead.
--@param url: it can be the url or string "backward", "forward". If it is url path, its page must contain one <pe:mcml> node. Page should be UTF-8 encoded. It will automatically replace %params% in url if any
-- if url is nil, content will be cleared. if it is a table, it will be the mcmlNode to open.
--@param cache_policy: cache policy object. if nil, default is used.
--@param bRefresh: whether to refresh if url is already loaded before.
--@return true if it is processing to the next stage.
function Page:Goto(url, cache_policy, bRefresh)
	if(url == "refresh") then
		url = self.url;
	end
	if(self.opened_urls and type(url) == "string") then
		if(url == "backward") then
			-- first search any inner iframe's pagectrl
			local InnerPageCtrl;
			if(self.mcmlNode) then
				local iframeNodes = self.mcmlNode:GetAllChildWithName("iframe");
				if(iframeNodes) then
					local index, framenode;
					for index, framenode in ipairs(iframeNodes) do
						if(framenode.pageCtrl) then
							local tabNode = framenode:GetParent("pe:tab-item");
							if(tabNode) then
								if(tabNode:GetBool("selected"))then
									InnerPageCtrl = framenode.pageCtrl
									break;
								end
							else
								InnerPageCtrl = framenode.pageCtrl
								break;
							end
						end
					end
				end
			end
			if(InnerPageCtrl) then
				if(InnerPageCtrl:Goto(url, cache_policy, bRefresh)) then
					return true;
				end
			end
			self.opened_url_index = self.opened_url_index or #self.opened_urls
			url = self.opened_urls[self.opened_url_index-1];
			if(not url) then return end
			self.opened_url_index = self.opened_url_index-1;
		elseif(url == "forward") then
			self.opened_url_index = self.opened_url_index or #self.opened_urls
			url = self.opened_urls[self.opened_url_index+1];
			if(not url) then return end
			self.opened_url_index = self.opened_url_index+1;
		end
	else
		if(url == "backward" or url == "forward") then
			return
		end
	end
	self:Init(url, cache_policy, bRefresh)
	return true;
end

-- rebuild the page. this is slow. It will delete and reparse the entire html text.
-- any local or global paramters defined in in-page code block will not survive during rebuild.
-- Use self:Refresh() which is fast and all local and global paramters will survive during refresh.
--	this will allow you programatically alter the content of the page.
-- all paramter can be nil.
-- @param url: if nil it is the current url.
function Page:Rebuild(url, cache_policy, bRefresh)
	self:Goto(url or "refresh", cache_policy, bRefresh);
end

-- close and destory all UI objects created by this page.
-- only call this function if self.name is a global name.
function Page:Close()
	if(self.name) then
		ParaUI.Destroy(self.name)
	end
end

-- in case this page is inside an iframe, the parentpage contains the page control that created the iframe.
function Page:GetParentPage()
	return self.parentpage
end

-- Get the top most root page
function Page:GetRootPage()
	if(self.parentpage) then
		return self.parentpage:GetRootPage();
	else
		return self;
	end
end

-- get the parent window containing this page.
function Page:GetWindow()
	if(self.layout) then
		local window = self.layout:widget();
		if(window) then
			return window:GetWindow();
		end
	else
		if(self:GetParentPage()) then
			return self:GetParentPage():GetWindow();
		end
	end
end

-- a safe method to decide if the page is visible or not.
-- @return true if page is visible.
function Page:IsVisible()
end

-- get the parent ui object
function Page:GetParentUIObject()
end

-- close the containing window
-- @param bDestroy: if true or nil, it will destroy the window, otherwise it will just hide it.
function Page:CloseWindow(bDestroy)
	local wnd = self:GetWindow();
	if(wnd) then
		wnd:CloseWindow(bDestroy);
	end
end

-- set the text and/or icon of the page's container window
function Page:SetWindowText(text,icon)
	local wnd = self:GetWindow();
	if(wnd) then
		-- wnd:SetWindowText(text,icon);
	end
end

-------------------------------------
-- overridable functions
-------------------------------------

-- this function is overridable. it is called before page UI is about to be created.
-- You cannot use view-state information within this event; it is not populated yet.
-- @param self.mcmlNode: the root pe:mcml node, one can modify it here before the UI is created, such as filling in default data.
function Page:OnLoad()
end

-- this function is overridable. it is called after page UI is created.
-- One can perform any processing steps that are set to occur on each page request. You can access view state information. You can also access controls within the page's control hierarchy.
-- In other words, one can have direct access to UI object created in the page control. Note that some UI are lazy created
-- such as treeview item and tab view items. They may not be available here yet.
function Page:OnCreate()
end

-- forcing a repaint in the next frame. this function does nothing if SelfPaint is false.
function Page:InvalidateRect()
	if(self.SelfPaint) then
		local parent = self:GetParentUIObject()
		if(parent) then
			parent:InvalidateRect();
		end
	end
end
-- get the used size of the page. This is called to obtain the actual size used to render the mcml page.
function Page:GetUsedSize()
	return self.used_width, self.used_height;
end

-- add current opened url to the opened urls stack so that we can move forward or backward.
-- if the last url is the same as current, url will not be added.
-- @param url; nil or url string to add. if nil, self.url is used.
function Page:AddOpenedUrl(url)
	url = url or self.url;
	self.opened_urls = self.opened_urls or {};
	self.opened_url_index = self.opened_url_index or #self.opened_urls;
	if(self.opened_urls[self.opened_url_index] ~= url) then
		self.opened_url_index = self.opened_url_index + 1;
		self.opened_urls[self.opened_url_index] = url;
	end
end

--------------------------------------
-- public method: for accessing mcml node, UI, and databinding objects in the page.
--------------------------------------

-- refresh the entire page after DelayTime seconds. Please note that during the delay time period,
-- if there is another call to this function with a longer delay time, the actual refresh page activation will be further delayed
-- Note: This function is usually used with a design pattern when the MCML page contains asynchronous content such as pe:name, etc.
-- whenever an asychronous tag is created, it will first check if data for display is available at that moment. if yes, it will
-- just display it as static content; if not, it will retrieve the data with a callback function. In the callback function,
-- it calls this Refresh method of the associated page with a delay time. Hence, when the last delay time is reached, the page is rebuilt
-- and the dynamic content will be accessible by then.
-- @param DelayTime: if nil, it will default to self.DefaultRefreshDelayTime (usually 1.5 second).
-- tip: If one set this to a negative value, it may causes an immediate page refresh.
function Page:Refresh(DelayTime)

	DelayTime = DelayTime or self.DefaultRefreshDelayTime;
	self.RefreshCountDown = (self.RefreshCountDown or 0);
	if(self.RefreshCountDown < DelayTime) then
		self.RefreshCountDown = DelayTime;
	end
	if(self.RefreshCountDown<=0) then
		self:OnRefresh();
	else
		self:ChangeTimer(DelayTime*1000);
	end
end

-- virtual: do refresh page if there is a request
function Page:OnTick()
	-- in case there is page error in previous page load, this will recover the refresh depth.
	self.refresh_depth = 0;

	if(self.RedirectCountDown) then
		self.RedirectCountDown = nil;
		if(self.redirectParams) then
			self:Goto(self.redirectParams.url, self.redirectParams.cache_policy, self.redirectParams.bRefresh);
			self.redirectParams = nil;
			self.RefreshCountDown = nil;
		end
	end
	if(self.RefreshCountDown) then
		self.RefreshCountDown = nil;
		self:OnRefresh();
	end
end

-- Same as Goto(), except that it contains a delay time. this function is safe to be called via embedded page code.
-- it will redirect page in DelayTime second
-- @param url: relative or absolute url, like you did in a src tag
-- if url is nil, content will be cleared. if it is a table, it will be the mcmlNode to open.
-- @param cache_policy: cache policy object. if nil, default is used.
-- @param bRefresh: whether to refresh if url is already loaded before.
-- @param DelayTime: if nil, it will default to self.DefaultRedirectDelayTime(usually 1 second). we do not allow immediate redirection, even delayTime is 0
function Page:Redirect(url, cache_policy, bRefresh, DelayTime)
	if(self.mcmlNode) then
		url = self.mcmlNode:GetAbsoluteURL(url);
	end

	self.RedirectCountDown = DelayTime or self.DefaultRedirectDelayTime;
	-- we do not allow immediate redirection, even delayTime is 0
	self.redirectParams = {url=url, cache_policy=cache_policy, bRefresh=bRefresh};
	self:ChangeTimer(DelayTime*1000);
end

-- get the url request of the mcml node if any. It will search for "request_url" attribtue field in the ancestor of this node.
-- Page and BrowserWnd will automatically insert "request_url" attribtue field to the root MCML node before instantiate them.
-- @return: nil or the request_url is returned. we can extract requery string parameters using regular expressions or using GetRequestParam
function Page:GetRequestURL()
	return self.mcmlNode:GetAttribute("request_url");
end

-- if you want to modify request_url and then refresh the page. call this function.
function Page:SetURL(url)
	self.url = url;
	if(self.mcmlNode) then
		self.mcmlNode:SetAttribute("request_url", url)
	end
end


-- get request url parameter by its name. for example if page url is "www.paraengine.com/user?id=10&time=20", then GetRequestParam("id") will be 10.
-- @param paramName: if nil, it will return a table containing all name,value pairs.
-- @return: nil or string value or a table.
function Page:GetRequestParam(paramName)
	local request_url = self:GetRequestURL();
	local params = self.mcmlNode:GetAttribute("request_params");
	if(not params or params.url__ ~= request_url) then
		params = System.localserver.UrlHelper.url_getparams_table(request_url) or {};
		params.url__ = request_url;
		self.mcmlNode:SetAttribute("request_params", params);
	end
	if(params) then
		if(paramName) then
			return params[paramName];
		else
			return params;
		end
	end
end

-- Binds current data source to the all page controls
function Page:DataBind()
end

-- Gets the first data item by its name in the data-binding context of this page.
function Page:GetDataItem(name)
end

-- Sets the focus to the control with the specified name.
-- @param name: The name of the control to set focus to
function Page:SetFocus(name)
end

-- Searches the page naming container for a server control with the specified identifier.
-- @note: this function is NOT available in OnInit(). use this function in OnCreate()
-- @return: It returns the ParaUIObject or CommonCtrl object depending on the type of the control found.
function Page:FindControl(name)
	local node = self:GetNode(name)
	if(node and self.name) then
		return node:GetControl(self.name);
	end
end

-- same as FindControl, except that it only returns UI object.
function Page:FindUIControl(name)
	local node = self:GetNode(name)
	if(node and self.name) then
		return node:GetUIControl(self.name);
	end
end

-- Get bindingtext context
function Page:GetBindingContext()
	self.bindingContext = self.bindingContext or BindingContext:new():Init(self);
	return self.bindingContext;
end

-- get the root node. it may return nil if page is not finished yet.
function Page:GetRoot()
	return self.mcmlNode
end

-- provide jquery-like syntax to find all nodes that match a given name pattern and then use the returned object to invoke a method on all returned nodes.
--  e.g. node:jquery("a"):show();
-- @param pattern: The valid format is [tag_name][#name_id][.class_name].
--  e.g. "div#name.class_name", "#some_name", ".some_class", "div"
function Page:jquery(...)
	if(self.mcmlNode) then
		return self.mcmlNode:jquery(...);
	end
end

-- get a mcmlNode by its name.
-- @return: the first mcmlNode found or nil is returned.
function Page:GetNode(name)
	if(self.mcmlNode and name) then
		return self.mcmlNode:SearchChildByAttribute("name", name)
	end
end

-- get a mcmlNode by its id.  if not found we will get by name
-- @param id: id or name of the node.
-- @return: the first mcmlNode found or nil is returned.
function Page:GetNodeByID(id)
	if(self.mcmlNode and id) then
		local node = self.mcmlNode:SearchChildByAttribute("id", id)
		if(node) then
			return node;
		else
			return self.mcmlNode:SearchChildByAttribute("name", id)
		end
	end
end

-- set the inner text of a mcmlNode by its name.
-- this function is usually used to change the text of a node before it is created, such as in the OnLoad event.
function Page:SetNodeText(name, text)
	local node = self:GetNode(name)
	if(node) then
		node:SetInnerText(text);
	end
end

-- set a MCML node value by its name
-- @param name: name of the node
-- @param value: value to be set
function Page:SetNodeValue(name, value)
	local node = self:GetNode(name);
	if(node) then
		node:SetValue(value);
	end
end

-- Get a MCML node value by its name
-- @param name: name of the node
-- @return: the value is returned
function Page:GetNodeValue(name)
	local node = self:GetNode(name);
	if(node) then
		return node:GetValue();
	end
end

-- set a MCML node UI value by its name. Currently support: text input
-- @param name: name of the node
-- @param value: value to be set
function Page:SetUIValue(name, value)
	local node = self:GetNode(name);
	if(node) then
		node:SetUIValue(value);
	else
		-- log("warning: mcml page item "..tostring(name).."not found in SetUIValue \n")
	end
end

-- Get a MCML node UI value by its name. Currently support: text input
-- @param name: name of the node
-- @return: the value is returned
function Page:GetUIValue(name)
	local node = self:GetNode(name);
	if(node) then
		return node:GetUIValue(self.name);
	else
		LOG.std(nil, "debug", "mcml",  "mcml page item "..tostring(name).."not found in SetUIValue")
	end
end

-- Get UI value if UI can be found or get Node value
function Page:GetValue(name, value)
	local value_ = self:GetUIValue(name);
	if(value_==nil) then
		return self:GetNodeValue(name, value);
	else
		return value_;
	end
end

-- set node value and set UI value if UI can be found.
function Page:SetValue(name, value)
	self:SetNodeValue(name,value)
	self:SetUIValue(name,value)
end

-- set node value and set UI value if UI can be found.
function Page:SetUIEnabled(name, value)
	local node = self:GetNode(name);
	if(node) then
		node:SetUIEnabled(self.name, value);
	end
end

-- Get UI background if UI can be found or get Node value
function Page:GetUIBackground(name)
	local node = self:GetNode(name);
	if(node) then
		return node:GetUIBackground(self.name);
	else
		LOG.std(nil, "debug", "mcml", "mcml page item "..tostring(name).."not found in GetUIBackground");
	end
end

-- set node value and set UI backgroud if UI can be found.
function Page:SetUIBackground(name, value)
	local node = self:GetNode(name);
	if(node) then
		node:SetUIBackground(self.name, value);
	else
		LOG.std(nil, "debug", "mcml", "mcml page item "..tostring(name).."not found in SetUIBackground");
	end
end

-- call a page control method
-- @param name: name of the node
-- @param methodName: name of the method
-- @return: the value from method is returned
function Page:CallMethod(name, methodName, ...)
	local node = self:GetNode(name);
	if(node) then
		return node:CallMethod(self.name, methodName, ...);
	else
		LOG.std(nil, "debug", "mcml",  "mcml page item:"..tostring(name).." not found in CallMethod")
	end
end

-- create or get page scope
function Page:GetPageScope()
	if(not self._PAGESCRIPT) then
		self._PAGESCRIPT = {
			-- evaluate a value in page scope
			Eval = Elements.pe_script.PageScope.Eval,
			-- evaluate a value in page scope. supports hierachy such as "Book/Title", "Book.Title"
			XPath = Elements.pe_script.PageScope.XPath,
			-- the page control object
			Page = self,
		};
		-- SECURITY NOTE:
		-- expose global environment to the inline script via meta table
		local meta = getmetatable (self._PAGESCRIPT)
		if not meta then
			meta = {}
			setmetatable (self._PAGESCRIPT, meta)
		end
		meta.__index = self:GetPageGlobalTable() or _G;
	end
	return self._PAGESCRIPT;
end

function Page:SetPageGlobalTable(globals)
	self.globals = globals;
end

function Page:GetPageGlobalTable()
	return self.globals;
end

--------------------------------------
-- private method
--------------------------------------

-- called when page is downloaded
function Page.OnPageDownloaded_CallBack(xmlRoot, entry, self)
	if(self and (not entry or self.status~=1))then
		-- NOTE: only update if page is not ready yet. this will ignore expired remote page update.
		if(xmlRoot) then
			local mcmlNode = commonlib.XPath.selectNode(xmlRoot, "//pe:mcml");

			if(mcmlNode) then
				self:LoadFromXmlNode(mcmlNode);
			else
				self.status=3;
				self.status_line = "网页中没有可以显示的mcml数据。[提示]你的网页至少要包含一个<pe:mcml>";
				self:OnRefresh();
			end
			if(type(self.OnPageDownloaded) == "function") then
				self.OnPageDownloaded();
			elseif (type(self.OnPageDownloaded) == "string") then
				NPL.DoString(self.OnPageDownloaded);
			end
		end
	end
end

-- load the page from xml Node
function Page:LoadFromXmlNode(xmlNode)
	-- ready status
	self.status=1;
	self.style = nil;
	self.mcmlNode = mcml:createFromXmlNode(xmlNode);
	self._PAGESCRIPT = nil; -- clear page scope
	-- rebuild UI
	self:OnRefresh();
end

-- refresh the page UI. It will remove all previous UI and rebuild (render) from current MCML page data.
-- it will call the OnLoad method.
-- _Note_ One can override this method to owner draw this control.
-- @param _parent: if nil, it will get using the self.name.
-- @return: the parent container of page ctrl is returned.
function Page:OnRefresh()
	self.RefreshCountDown = nil;
	local layout = self.layout;
	if(not layout) then
		return;
	end
	local uiElem = layout:widget();

	if(self.refresh_depth > 0) then
		-- if we are refreshing a page within a page, we will automatically delay it.
		LOG.std("", "warning", "mcml", "recursive page refresh is detected for page %s. Please use page:Refresh() instead of Refresh(0).", tostring(self.url));
		-- self:Refresh(0.01);
		return;
	end
	self.refresh_depth = self.refresh_depth + 1;

	if(self.status== 1 and self.mcmlNode) then
		-- call OnLoad
		self:OnLoad();

		-- create the mcml UI controls.
		local width, height = uiElem:width(), uiElem:height();
		-- secretely inject the "request_url" in it, so that we can make href using relative to site or url path.
		self.mcmlNode:SetAttribute("request_url", self.url);
		-- secretely put this page control object into page_ctrl field, so that we can refresh this page with a different url, such as in pe_a or form submit button.
		self.mcmlNode:SetAttribute("page_ctrl", self);

		self.layout:invalidate();
		self:LoadComponent();
		self.layout:activate();

		self.used_width, self.used_height = layout:GetUsedSize();

		self:OnCreate();
		-- add url
		self:AddOpenedUrl();
	else
		-- TODO: display an animated background in _parent for other self.status values, such as downloading or error.
		-- TODO: we can also display a user defined self.errorpage page.
		-- log("warning:"..tostring(self.status_line).."\n")
	end
	self.refresh_depth = self.refresh_depth - 1;
end

-- create all ui elements recursively using the layout.
function Page:LoadComponent()
	local layout = self.layout;
	if(self.bindingContext) then
		self.bindingContext:Clear();
	end
	if(layout and self.mcmlNode) then
		local parentElem = layout:widget();
		if(parentElem) then
			self.mcmlNode:LoadComponent(parentElem, layout, nil);
		end
	end
end

-- Get the page style object
function Page:GetStyle()
	if(not self.style) then
		self.style = Style:new():init(self);
		self.style:AddReference(mcml:GetStyle(), "mcss");
	end
	return self.style;
end

-- create (instance) the page UI. It will create UI immediately after the page is downloaded. If page is local, it immediately load.
-- @param name: name of the control. it should be globally unique if page is asynchronous. and it can be anything, if page is local.
function Page:Create(name, _parent, alignment, left, top, width, height, bForceDisabled)
	-- obsoleted: create empty window instead to make it API compatible with old version.
	-- TODO:
end

function Page:Attach(uiElement)
	if(uiElement) then
		uiElement:deleteChildren();
		if(uiElement.layout) then
			uiElement.layout = nil;
		end
		self:Detach();
		self.layout = PageLayout:new();
		self.layout:SetPage(self, uiElement);
		uiElement.layout = self.layout;
	end
end

function Page:Detach()
	if(self.layout) then
		local uiElem = self.layout:widget();
		if(uiElem) then
			uiElem:deleteChildren();
			uiElem.layout = nil;
		end
		self.layout = nil;
	end
end


function Page:AddHotkeyNode(node, hotkey, func)
	if(not func) then
		func = node.OnClick;
	end
	self.hotkeyNodes[hotkey] = {node = node, func = func};
end

function Page:RemoveHotkeyNode(node, hotkey)
	local hotkeyNode = self.hotkeyNodes[hotkey];
	if(hotkeyNode and hotkeyNode.node == node) then
		self.hotkeyNodes[hotkey] = nil;
	end
end

function Page:HandlHotkeyEvent(hotkey)
	-- 支持组合按键识别
	local ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
	local alt_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU);
	local shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
	local comboKeyStr = "";
	if ctrl_pressed and hotkey ~= "DIK_LCONTROL" and hotkey ~= "DIK_RCONTROL" then
		comboKeyStr = comboKeyStr .. "DIK_CONTROL + ";
	elseif alt_pressed and hotkey ~= "DIK_LMENU" and hotkey ~= "DIK_RMENU" then
		comboKeyStr = comboKeyStr .. "DIK_MENU + ";
	elseif shift_pressed and hotkey ~= "DIK_LSHIFT" and hotkey ~= "DIK_RSHIFT" then
		comboKeyStr = comboKeyStr .. "DIK_SHIFT + ";
	end
	hotkey = comboKeyStr .. hotkey;

	local hotkeyNode = self.hotkeyNodes[hotkey];
	if(hotkeyNode and hotkeyNode.func) then
		hotkeyNode.func(hotkeyNode.node);
		return true;
	end
	return false;
end

function Page:AddTabIndexNode(index, node)
	local insert_pos;
	for pos, node in ipairs(self.tabIndexNodes) do
		local node_index = node:TabIndex();
		if(index < node_index) then
			insert_pos = pos;
		end
	end
	if(insert_pos) then
		table.insert(self.tabIndexNodes, insert_pos, node);
	else
		table.insert(self.tabIndexNodes, node);
	end
end

function Page:FocusNode()
	return self.currentTabNode;
end

function Page:SetFocusNode(node)
	self.currentTabNode = node;
end

function Page:NextTabNode()
	if(not self.currentTabNode and #self.tabIndexNodes ~= 0) then
		return self.tabIndexNodes[1];
	end

	if(not self.currentTabNode) then
		return self.mcmlNode:NextTabNode();
	end

	local size = #self.tabIndexNodes;
	if(self.currentTabNode:TabIndex() ~= 0) then
		-- self.currentTabNode isn't the last node in self.tabIndexNodes;
		for i = 1, size do
			local node = self.tabIndexNodes[i];
			if(self.currentTabNode == node) then
				if(i < size) then
					return self.tabIndexNodes[i + 1];
				else
					return self.mcmlNode:NextTabNode();
				end
			end
		end
	end

	return self.currentTabNode:NextTabNode()
end

function Page:HandlKeyPressEvent(key)
	if(self:HandlHotkeyEvent(key)) then
		return true;
	end

	if(key == "DIK_TAB") then
		if(self.currentTabNode and not self.currentTabNode:TabLostFocus()) then
			return false;
		end
		self.currentTabNode = self:NextTabNode();
		if(not self.currentTabNode) then
			self.currentTabNode = self:NextTabNode();
		end
		if (self.currentTabNode) then
			self.currentTabNode:SetFocus();
		end
		return true;
	end

	return false;
end