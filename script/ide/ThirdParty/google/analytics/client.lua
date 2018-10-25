--[[
title: google analytics client
author: chenqh
date: 2018/10/25
desc: a simple google analytics client for npl, support both website and mobile app

-------------------------------------------------------------------------------------------
useage:
-------------------------------------------------------------------------------------------
NPL.load("(gl)script/ide/ThirdParty/google/analytics/client.lua")

GAClient = commonlib.gettable("System.ThirdParty.Google.Analytics.Client")

UA = 'UA-127983943-1' -- your ua number

client = GAClient:new():init(UA)

options = {
    location = 'www.keepwork.com/lesson',
    language = 'zh-CN',
    category = 'test',
    action = 'create',
    label = 'keepwork',
    value = 123
}

client:send_event(options)

options = {
    location = 'www.keepwork.com/lesson',
    title = 'keepwork',
    page = '/'
}

client:send_page(options)

options = {
    app_version = 'v1.0.0',
    title = 'keepwork',
    screen = 'home'
}

client:send_screen(options)

]]

local _M = commonlib.inherit(nil, commonlib.gettable("System.ThirdParty.Google.Analytics.Client"))

local table_concat = table.concat
local rand = math.random
local http_get = System.os.GetUrl

local GA_URL = 'www.google-analytics.com/r/collect'

local function encode_params(params)
    local arr = {}
    for k, v in pairs(params) do
        if v ~= nil then
            arr[#arr+1] = k .. '=' .. v
        end
    end
    return table_concat(arr, '&')
end

local function create_req_url(params)
    return tostring(GA_URL .. '?' .. encode_params(params))
end

function _M:ctor()
end

function _M:init(ua)
    self.ua = ua
    self.latest_updated = os.time()
    self:reset()

    return self
end

function _M:reset()
    self.client_id = rand(1000000000, 9999999999) .. '.' .. rand(1000000000, 9999999999)
end

function _M:update_clock()
    local now = os.time()
    -- client id will be changed if there's no new update in 30 mins
    if (now - self.latest_updated > 60 * 30) then
        self:reset()
    end
    self.latest_updated = now
end

function _M:new_params(options)
    -- https://www.cheatography.com/dmpg-tom/cheat-sheets/google-universal-analytics-url-collect-parameters/
    return {
        v = 1,
        a = rand(1000000000, 2147483647), -- a random number
        t = nil, -- the type of tracking call this (eg pageview, event)
        dl = options.location, -- the document location
        cd = nil, -- screen name, mainly use for app
        dp = nil, -- document path
        ul = options.language, -- language
        de = 'utf-8', -- document encode type
        dt = nil, -- document title
        ec = nil, -- event
        ea = nil, --- event action
        el = nil, -- event label
        ev = nil, -- event value
        aid = nil, -- Applic­ation ID
        aiid = nil, -- Applic­ation Installer ID
        an = nil, -- Applic­ation Name
        av = nil, -- Applic­ation Version
        cid = self.client_id, -- client id number
        tid = self.ua, -- tracking id (your ua number)
    }
end

function _M:send(params, options)
    tracking_url = create_req_url(params)
    print(tracking_url)
    return http_get({
        url = tracking_url,
        headers = {
            ['User-Agent'] = options.user_agent or 'npl analytics/1.0',
            ['Referer'] = params.dl
        }
    })
end

function _M:send_event(options)
    if (not options or not options.category or not options.action) then return end
    local params = self:new_params(options)
    params.t = 'event'
    params.ec = options.category
    params.ea = options.action
    params.el = options.label
    params.ev = options.value

    self:send(params, options)
end

-- use for website
function _M:send_page(options)
    if (not options or not options.page) then return end

    local params = self:new_params(options)
    params.t = 'pageview'
    params.dp = options.page
    params.dt = options.title

    self:send(params, options)
end

-- use for app
function _M:send_screen(options)
    if (not options or not options.screen) then return end

    local params = self:new_params(options)
    params.t = 'screenview'
    params.cd = options.screen
    params.dt = options.title
    params.aid = options.app_id
    params.aiid = options.app_install_id
    params.an = options.app_name
    params.av = options.app_version

    self:send(params, options)
end
