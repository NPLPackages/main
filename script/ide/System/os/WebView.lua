--[[
Title: WebView
Author(s): LanZhiHong
Date: 2018/5/18
Desc: create a view of webbrower
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/os/WebView.lua");
local WebView = commonlib.gettable("System.os.WebView");
local webView = WebView:new():init(); or local webView = WebView:new():init(x, y, w, h); 
webView:loadUrl("http://www.baidu.com");
webView:closeAndRelease() -- it will direct cloase and release view 
webView = nil; -- it will close and release view when system gc;
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/System/os/os.lua");

local NativeWebView = WebView;
local WebView = commonlib.inherit(nil, commonlib.gettable("System.os.WebView"));

function WebView:ctor()
	self._wv = nil;
end

function WebView:init(x, y, w, h, bSub)
	x = x or 0;
	y = y or 0;

	if (not w or not h) then
		-- // TODO: fix get screen resolution.
		local frame_size = ParaEngine.GetAttributeObject():GetField("ScreenResolution");
		w = frame_size[1];
		h = frame_size[2];
	end

	if bSub then
		self._wv = NativeWebView and NativeWebView.createSubViewView(x, y, w, h);
	else
		self._wv = NativeWebView and NativeWebView.createWebView(x, y, w, h);
	end

	self._att = self._wv and self._wv:GetAttributeObject();
	
	return self;
end

function WebView:loadUrl(url, bCleanCachedData)
	if (self._wv) then
		if (bCleanCachedData) then
			self._wv:loadUrl(url, true);
		else
			self._wv:loadUrl(url);
		end
	end
end

function WebView:closeAndRelease()
	if (self._wv) then
		self._wv:closeAndRelease();
		self._wv = nil;
		self._att = nil;
	end
end

function WebView:setAlpha(alpha)
	if (self._wv) then
		self._att:SetField("Alpha", alpha);
	end
end

function WebView:setVisible(bVisible)
	if (self._wv) then
		self._att:SetField("Visible", bVisible);
	end
end

function WebView:HideViewWhenClickBack(bHide)
	if (self._wv) then
		self._att:SetField("HideViewWhenClickBack", bHide);
	end
end

function WebView:move(x, y)
	if not self._wv then
		return false
	end

	self._att:SetField("move", {x, y})
end

function WebView:bringToTop()
	if not self._wv then
		return false
	end

	self._att:CallField("bringToTop")
end