--[[
Title: http image loader
Author(s): LiPeng
Date: 2019/2/26
Desc: it used to load http image.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/ImageLoader.lua");
local ImageLoader = commonlib.gettable("System.Windows.mcml.ImageLoader");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/LocalCache.lua");
local LocalCache = commonlib.gettable("System.Windows.mcml.LocalCache");
local ImageLoader = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.ImageLoader"));

function ImageLoader:ctor()
	self.elements = commonlib.vector:new();
	self.url = nil;
	self.image = nil;
end

function ImageLoader:init(url, element)
	self.url = url;
	if(element) then
		self.elements:append(element);
	end
	return self;
end

function ImageLoader:destroy()
	self.url = nil;
	self.elements:clear();
	self.elements = nil;
end

function ImageLoader:GetPageCachePolicy()
	local cache_policy;
--	if(self.style and self.style.page) then
--		cache_policy =  self.style.page.cache_policy;
--	end
	return cache_policy or System.localserver.CachePolicy:new("access plus 1 hour");
end

function ImageLoader:load()
	LocalCache:GetRemoteTexture(self.url, self:GetPageCachePolicy(), function (entry)
		if(entry and entry.entry and entry.entry.url and entry.payload and entry.payload.cached_filepath) then
			self.image = entry.payload.cached_filepath;
			self:UpdateForElement();
		end
	end);
end

local urlToImageMap = {}
local urlToLoaderMap = {}

function ImageLoader:UpdateForElement()
	for i = 1, self.elements:size() do
		local element = self.elements[i];
		element:ApplyCss();
	end

	urlToImageMap[self.url] = self.image;

	self:destroy();

	urlToLoaderMap[self.url] = nil;
end

function ImageLoader.Create(url, element)
	local loader = urlToLoaderMap[url];
	if(not loader) then
		loader = ImageLoader:new():init(url, element);
		urlToLoaderMap[url] = loader;
	end
	return loader;
end

function ImageLoader.LoadHttpImage(url, element)
	if(url and string.match(url,"^http[s]?")) then
		local image = urlToImageMap[url];
		if(not image) then
			ImageLoader.Create(url, element)
		end
	end
end

