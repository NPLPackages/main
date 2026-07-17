--[[
Title: MQTT Logger
Author(s): [pbb]
Date: 2025/[6]/[4]
Desc: MQTT消息日志记录模块，支持按天存储日志并控制保留时间


使用方法：
-------------------------------------------------------
NPL.load("(gl)script/ide/System/os/network/MQTT/mqtt_logger.lua");
local mqtt_logger = commonlib.gettable("System.os.network.mqtt.logger");

-- 初始化日志记录器
mqtt_logger.Init({
    enabled = true,           -- 是否启用日志记录
    log_dir = "logs/mqtt",    -- 日志存储目录
    retention_days = 7,       -- 日志保留天数
    log_level = "INFO"        -- 日志级别：DEBUG, INFO, WARN, ERROR
});

-- 记录发送的消息
mqtt_logger.LogPublish(topic, payload, qos, retain);

-- 记录接收的消息
mqtt_logger.LogReceive(topic, payload, qos, retain);
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/os/network/MQTT/mqtt_client.lua");
NPL.load("(gl)script/ide/LOG.lua");

local mqtt_logger = commonlib.gettable("System.os.network.mqtt.logger");

-- 默认配置
local config = {
    enabled = false,          -- 默认不启用日志记录
    log_dir = "logs/mqtt",    -- 默认日志存储目录
    retention_days = 7,       -- 默认日志保留天数
    log_level = "INFO",       -- 默认日志级别
    log_file_prefix = "mqtt_" -- 日志文件前缀
};

-- 日志级别定义
local LOG_LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
};

-- 当前日志文件句柄
local current_log_file = nil;
-- 当前日志日期
local current_log_date = nil;

-- 初始化日志记录器
function mqtt_logger.Init(options)
    if options then
        for k, v in pairs(options) do
            config[k] = v;
        end
    end
    
    -- 创建日志目录
    if config.enabled then
        ParaIO.CreateDirectory(config.log_dir);
        mqtt_logger.CleanupOldLogs();
        mqtt_logger.Log("DEBUG", "MQTT Logger initialized with config: " .. commonlib.serialize_compact(config));
    end
    
    return mqtt_logger;
end

-- 获取当前日期字符串（YYYY-MM-DD格式）
function mqtt_logger.GetCurrentDate()
    return ParaGlobal.GetDateFormat("yyyy-MM-dd");
end

-- 获取当前时间字符串（HH:MM:SS格式）
function mqtt_logger.GetCurrentTime()
    return ParaGlobal.GetTimeFormat(nil);
end

-- 获取当前日志文件路径
function mqtt_logger.GetLogFilePath()
    local date = mqtt_logger.GetCurrentDate();
    return config.log_dir .. "/" .. config.log_file_prefix .. date .. ".csv";
end

-- 确保日志文件已打开
function mqtt_logger.EnsureLogFileOpen()
    local date = mqtt_logger.GetCurrentDate();
    
    -- 如果日期变了或者文件未打开，则打开新的日志文件
    if current_log_date ~= date or not current_log_file then
        -- 关闭之前的文件
        if current_log_file then
            current_log_file:close();
            current_log_file = nil;
        end
        
        -- 打开新的日志文件（追加模式）
        local file_path = mqtt_logger.GetLogFilePath();
        if not ParaIO.DoesFileExist(file_path) then
            ParaIO.CreateDirectory(file_path);
        end

        current_log_file = ParaIO.open(file_path, "a");
        current_log_date = date;
        
        -- 如果是新文件，添加标题行
        if current_log_file:GetFileSize() == 0 then
            current_log_file:WriteString("时间,日志类型,消息类型,主题,QoS,Retain,消息内容\n");
        end
    end
    
    return current_log_file;
end

-- 记录日志
function mqtt_logger.Log(level, message)
    if not config.enabled or LOG_LEVELS[level] < LOG_LEVELS[config.log_level] then
        return;
    end
    
    local file = mqtt_logger.EnsureLogFileOpen();
    if file then
        local timestamp = mqtt_logger.GetCurrentDate() .. " " .. mqtt_logger.GetCurrentTime();
        file:WriteString(timestamp .. "," .. level .. "," .. message .. "\n");
        --file:flush(); -- 确保立即写入磁盘
    end
end

-- 记录发送的消息
function mqtt_logger.LogPublish(topic, payload, qos, retain)
    if not config.enabled then return end
    
    local retain_str = retain and "true" or "false";
    local message = string.format("PUBLISH,%s,%d,%s,%s", 
        topic or "", 
        qos or 0, 
        retain_str, 
        mqtt_logger.EscapeCsvField(payload or ""));
    
    mqtt_logger.Log("INFO", message);
end

-- 记录接收的消息
function mqtt_logger.LogReceive(topic, payload, qos, retain)
    if not config.enabled then return end
    
    local retain_str = retain and "true" or "false";
    local message = string.format("RECEIVE,%s,%d,%s,%s", 
        topic or "", 
        qos or 0, 
        retain_str, 
        mqtt_logger.EscapeCsvField(payload or ""));
    
    mqtt_logger.Log("INFO", message);
end

-- 转义CSV字段中的特殊字符
function mqtt_logger.EscapeCsvField(field)
    if type(field) ~= "string" then
        field = tostring(field);
    end
    
    -- 如果字段包含逗号、引号或换行符，则用引号括起来并将引号转义
    if string.find(field, '[",\n]') then
        field = '"' .. string.gsub(field, '"', '""') .. '"';
    end
    
    return field;
end

-- 清理过期的日志文件
function mqtt_logger.CleanupOldLogs()
    if not config.enabled or config.retention_days <= 0 then
        return;
    end
    
    local log_dir = config.log_dir;
    local files = commonlib.Files.Find({}, log_dir, 0, 1000, '*.log')
    --ParaIO.GetFileList(log_dir, "*.log", 0, 1000);
    local prefix_len = #config.log_file_prefix;
    local current_date = mqtt_logger.GetCurrentDate();
    
    -- 计算截止日期（当前日期减去保留天数）
    local cutoff_date = os.time() - (config.retention_days * 86400); -- 86400秒=1天
    
    for _, file in ipairs(files) do
        local filename = file.filename;
        -- 检查是否是MQTT日志文件
        if string.sub(filename, 1, prefix_len) == config.log_file_prefix then
            -- 从文件名中提取日期（格式：mqtt_YYYY-MM-DD.log）
            local date_str = string.sub(filename, prefix_len + 1, -5); -- 去掉前缀和.log后缀
            local year, month, day = string.match(date_str, "(%d+)-(%d+)-(%d+)");
            
            if year and month and day then
                local file_date = os.time({year=tonumber(year), month=tonumber(month), day=tonumber(day)});
                
                -- 如果文件日期早于截止日期，则删除文件
                if file_date < cutoff_date then
                    local file_path = log_dir .. "/" .. filename;
                    if ParaIO.DeleteFile(file_path) then
                        LOG.std(nil, "INFO", "MQTT_Logger", "Deleted old MQTT log file: %s", filename);
                    else
                        LOG.std(nil, "WARN", "MQTT_Logger", "Failed to delete old MQTT log file: %s", filename);
                    end
                end
            end
        end
    end
end

-- 关闭日志记录器
function mqtt_logger.Close()
    if current_log_file then
        current_log_file:close();
        current_log_file = nil;
        current_log_date = nil;
    end
end

-- 设置日志级别
function mqtt_logger.SetLogLevel(level)
    if LOG_LEVELS[level] then
        config.log_level = level;
    end
end

-- 设置日志保留天数
function mqtt_logger.SetRetentionDays(days)
    if type(days) == "number" and days >= 0 then
        config.retention_days = days;
        mqtt_logger.CleanupOldLogs();
    end
end

-- 启用或禁用日志记录
function mqtt_logger.SetEnabled(enabled)
    config.enabled = (enabled == true);
    if config.enabled then
        ParaIO.CreateDirectory(config.log_dir);
    else
        mqtt_logger.Close();
    end
end

-- 获取当前配置
function mqtt_logger.GetConfig()
    return config;
end