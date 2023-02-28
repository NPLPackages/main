
# Api

本文档 API 皆为script标签脚本的全局接口, 类似浏览器网页script标签的全局接口.

## Http 请求

http 请求是客户端与服务器交互常见用法之一. 接口使用示例如下:

```lua
-- 新建 Http 实例
Http:new():Init(config);
-- demo
local http = Http:new():Init({
    -- url 前缀
    baseURL = "https://api.keepwork.com/core/v0/",
    -- 请求头
    headers = {
        ["content-type"] = "application/json", 
    },
    -- 请求预处理
    transformRequest = function(request)
        request.headers["Authorization"] = string.format("Bearer %s", commonlib.getfield("System.User.keepworktoken"));
    end,
    -- 响应预处理
    transformResponse = function(response)
    end,

    -- 常用的重写字段
    -- 请求方法
    method = "GET",
    -- 请求数据
    data = {},
    -- 其它 ...
});

-- 拉取数据 常用 Get 请求
http:Get(url, config);

-- 新建数据
http:Post(url, data, config);

-- 更新数据
http:Put(url, data, config);

-- 删除数据 
http:Delete(url, config);

-- config 同 http:new():Init(config) 参考该实例重写相关字段即可

-- http请求为异步, 返回的结果为一个Promise对象, 可以使用 Promise API 对其链式处理, 如
http:Get("keepworks/currentTime"):Then(function(response)
    -- 请求成功
    echo({
        response.status,  -- 响应码
        response.header,  -- 响应头
        response.data,    -- 响应数据
    });
end):Catch(function(response)
    -- 请求失败
end);
```

## Promise

异步逻辑同步写法辅助类, 用法参考: https://www.runoob.com/w3cnote/javascript-promise-object.html

## Date

```lua
-- 构建日期对象
local date = Date:new():Init(t);     -- t 等同 ostime(t)
-- 获取日期
date:GetDate(fmt);                   -- os.date(fmt)  
date:GetTimeStamp();                 -- 获取 date 对应的时间戳(单位秒)
date:SetTimeStamp(timestamp);        -- 设置 date 时间戳(单位秒) 
```
