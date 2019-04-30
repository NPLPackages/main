--[[
Title: sub frame load
Author(s): LiPeng
Date: 2019/3/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/loader/SubFrameLoader.lua");
local SubFrameLoader = commonlib.gettable("System.Windows.mcml.loader.SubFrameLoader");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
local LayoutSize = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local SubFrameLoader = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.loader.SubFrameLoader"));

function SubFrameLoader:ctor()
	self.m_frame = nil;

end

function SubFrameLoader:init(frame)
	self.m_frame = frame;

	return self;
end

function SubFrameLoader:Document()
	return self.m_frame:Document();
end

function SubFrameLoader:Frame()
	return self.m_frame;
end

--Frame* SubframeLoader::loadSubframe(HTMLFrameOwnerElement* ownerElement, const KURL& url, const String& name, const String& referrer)
function SubFrameLoader:LoadSubframe(ownerElement, url, name)
    local frame = self.m_frame:Loader():Client():CreateSubFrame(url, name, ownerElement);

    if (not frame)  then
        return nil;
    end
   
    local renderer = ownerElement:Renderer();
    local view = frame:View();
    if (renderer and renderer:IsWidget() and view) then
        renderer:ToRenderWidget():SetWidget(view);
	end

    return frame;
end

--Frame* SubframeLoader::loadOrRedirectSubframe(HTMLFrameOwnerElement* ownerElement, const KURL& url, const AtomicString& frameName, bool lockHistory, bool lockBackForwardList)
function SubFrameLoader:LoadOrRedirectSubframe(ownerElement, url, frameName)
    local frame = ownerElement:ContentFrame();
	if (not frame) then
		frame = self:LoadSubframe(ownerElement, url, frameName);
	end
--    if (frame) then
--        frame->navigationScheduler()->scheduleLocationChange(m_frame->document()->securityOrigin(), url.string(), m_frame->loader()->outgoingReferrer(), lockHistory, lockBackForwardList);
--    else
--        frame = loadSubframe(ownerElement, url, frameName, m_frame->loader()->outgoingReferrer());
--	end
    return frame;
end

--bool SubframeLoader::requestFrame(HTMLFrameOwnerElement* ownerElement, const String& urlString, const AtomicString& frameName, bool lockHistory, bool lockBackForwardList)
function SubFrameLoader:RequestFrame(ownerElement, urlString, frameName)
    local frame = self:LoadOrRedirectSubframe(ownerElement, url, frameName);
    if (not frame) then
        return false;
	end

--    if (!scriptURL.isEmpty())
--        frame->script()->executeIfJavaScriptURL(scriptURL);

    return true;
end