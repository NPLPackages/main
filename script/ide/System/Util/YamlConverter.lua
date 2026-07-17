--[[  
Title: YamlConverter
Author: pbb
Date: refined 2025/8/8
Desc: Convert lua table to YAML string and vice versa
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/YamlConverter.lua");
local YamlConverter = commonlib.gettable("System.Util.YamlConverter");
local yamlStr = YamlConverter.LuaToYAML({name="value", array={1,2,3}});
echo(yamlStr);
local luaTable = YamlConverter.YAMLToLua(yamlStr);
echo(luaTable);
-------------------------------------------------------
]]
local YamlConverter = commonlib.gettable("System.Util.YamlConverter");
local maxInlineArraySize = 31;
-- two spaces for each level
YamlConverter.defaultIndentSpaces = "  "; 

-- 判断表是否为数组
local function isArray(t)
    if type(t) ~= "table" then
        return false
    end
    
    -- 空表被认为是数组
    if next(t) == nil then
        return true
    end
    
    -- 检查所有键是否为连续的正整数
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
        if type(k) ~= "number" or k ~= math.floor(k) or k <= 0 then
            return false
        end
    end
    
    -- 检查键是否连续（从1开始）
    for i = 1, count do
        if t[i] == nil then
            return false
        end
    end
    
    return true
end

-- 格式化值
local function formatValue(value)
    if type(value) == "string" then
        -- 检查是否需要引号
        if value:find("[\n\r]") or value:find("^%s") or value:find("%s$") or 
           value:find(":") or value:find("#") or value == "" then
            return '"' .. value:gsub('"', '\\"') .. '"'
        else
            return value
        end
    elseif type(value) == "boolean" then
        return value and "true" or "false"
    elseif type(value) == "number" then
        return tostring(value)
    else
        return tostring(value or "")
    end
end


-- 将Lua表转换为YAML字符串
-- @param options: this can be nil, {indent=number} 指定当前缩进级别，默认为0
function YamlConverter.LuaToYAML(luaTable, options)
    if type(luaTable) ~= "table" then
        return tostring(luaTable or "")
    end
    
    local indent = options and options.indent or 0
    local useFrontMatter = options and options.useFrontMatter
    local hasContent = useFrontMatter and not isArray(luaTable) and luaTable.content ~= nil
    local indentStr = string.rep(" ", indent)
    local result = {}
    
    -- 检查是否为数组
    local isArrayResult = isArray(luaTable)
    
    if isArrayResult then
        -- 处理数组
        if #luaTable == 0 then
            return "[]"
        end
        
        -- 检查是否为数字数组且可以内联显示
        local canInline = true
        for i, v in ipairs(luaTable) do
            if type(v) == "table" or type(v) == "string" and v:find("\n") then
                canInline = false
                break
            end
        end
        
        if canInline and #luaTable <= maxInlineArraySize then
            -- 内联数组格式 [1,2,3]
            local items = {}
            for i, v in ipairs(luaTable) do
                if type(v) == "string" then
                    table.insert(items, '"' .. v:gsub('"', '\\"') .. '"')
                else
                    table.insert(items, tostring(v))
                end
            end
            return "[" .. table.concat(items, ",") .. "]"
        else
            -- 标准数组格式
            for i, v in ipairs(luaTable) do
                if type(v) == "table" then
                    local subYaml = YamlConverter.LuaToYAML(v)
                    if subYaml:find("\n") then
                        table.insert(result, indentStr .. "-")
                        for line in subYaml:gmatch("([^\n]*)\n?") do
                            if line ~= "" then
                                table.insert(result, indentStr .. YamlConverter.defaultIndentSpaces .. line)
                            end
                        end
                    elseif not subYaml:match("^%-") then
                        table.insert(result, indentStr .. "- " .. subYaml)
                    else
                        table.insert(result, indentStr .. "-")
                        table.insert(result, indentStr .. YamlConverter.defaultIndentSpaces .. subYaml)
                    end
                else
                    local valueStr = formatValue(v)
                    table.insert(result, indentStr .. "- " .. valueStr)
                end
            end
        end
    else
        -- 处理对象
        if next(luaTable) == nil then
            return "{}"
        end
        
        -- 获取排序后的键
        local keys = {}
        for k, _ in pairs(luaTable) do
            if not (hasContent and tostring(k) == "content") then
                table.insert(keys, k)
            end
        end
        table.sort(keys, function(a, b)
            return tostring(a) < tostring(b)
        end)
        
        for _, k in ipairs(keys) do
            local v = luaTable[k]
            local keyStr = tostring(k)
            
            if keyStr:find("[:{}%[%],%&%*%#%?%|%<%>%=%!%%%@%`]") or 
               keyStr:find("^%s") or keyStr:find("%s$") or keyStr == "" then
                keyStr = '"' .. keyStr:gsub('"', '\\"') .. '"'
            end
            
            if type(v) == "table" then
                local subYaml = YamlConverter.LuaToYAML(v)
                if subYaml == "{}" or subYaml == "[]" then
                    table.insert(result, indentStr .. keyStr .. ": " .. subYaml)
                elseif subYaml:find("\n") then
                    -- 对象类型且包含换行符：使用多行格式
                    table.insert(result, indentStr .. keyStr .. ":")
                    for line in subYaml:gmatch("([^\n]*)\n?") do
                        if line ~= "" then
                            table.insert(result, indentStr .. YamlConverter.defaultIndentSpaces .. line)
                        end
                    end
                else
                    if subYaml:match("^%-") then
                        table.insert(result, indentStr .. keyStr .. ":")
                        table.insert(result, indentStr .. YamlConverter.defaultIndentSpaces .. subYaml)
                    elseif subYaml:find(":") then
                        table.insert(result, indentStr .. keyStr .. ":")
                        table.insert(result, indentStr .. YamlConverter.defaultIndentSpaces .. subYaml)
                    else
                        table.insert(result, indentStr .. keyStr .. ": " .. subYaml)
                    end
                end
            else
                local valueStr = formatValue(v)
                table.insert(result, indentStr .. keyStr .. ": " .. valueStr)
            end
        end
    end
    local yamlStr = table.concat(result, "\n")
    if hasContent then
        local contentStr = tostring(luaTable.content)
        if yamlStr ~= "" then
            return "---\n" .. yamlStr .. "\n---\n" .. contentStr
        else
            return "---\n---\n" .. contentStr
        end
    end
    return yamlStr
end

local function YamlToLuaParse(text)
    if not text or type(text) ~= "string" then
        return {}
    end
    
    local lines = {}
    for line in string.gmatch(text.."\n", "([^\n]*)\n") do
        table.insert(lines, line)
    end
    
    -- 去除注释和空行，参考JavaScript版本的过滤逻辑
    local cleanLines = {}
    for _, line in ipairs(lines) do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed ~= "" and not trimmed:match("^#") then
            local contentPart = line:match("^(.-)%s*#.*$") or line
            table.insert(cleanLines, contentPart)
        end
    end
    
    local function getIndent(line)
        local indent = string.match(line, "^(%s*)")
        return indent and #indent or 0
    end
    
    local function isArrayItem(line)
        -- 支持两种数组项写法：
        -- 1) "- " 内联值或键值对
        -- 2) "-" 独立一行，后续为缩进的嵌套对象/数组
        return string.match(line, "^%s*-%s") ~= nil or string.match(line, "^%s*-%s*$") ~= nil
    end
    
    -- 参考JavaScript版本的parseYamlValue方法改进值解析
    local function parseValue(value)
        if not value or value == "" then
            return nil
        end
        
        -- 处理引号包裹的字符串
        if (value:sub(1, 1) == '"' and value:sub(-1) == '"') or
           (value:sub(1, 1) == "'" and value:sub(-1) == "'") then
            local unquoted = value:sub(2, -2)
            -- 处理转义字符
            unquoted = unquoted:gsub('\\"', '"'):gsub("\\'", "'")
            return unquoted
        end
        
        -- 处理内联数组格式 [1,2,3]
        if value:match("^%[.*%]$") then
            local content = value:sub(2, -2):match("^%s*(.-)%s*$")
            if content == "" then
                return {}
            end
            
            local items = {}
            for item in string.gmatch(content .. ",", "([^,]*),") do
                local trimmedItem = item:match("^%s*(.-)%s*$")
                if trimmedItem ~= "" then
                    table.insert(items, parseValue(trimmedItem))
                end
            end
            return items
        end
        
        -- 处理布尔值
        if value == "true" then
            return true
        elseif value == "false" then
            return false
        end
        
        -- 处理数字
        local num = tonumber(value)
        if num then
            return num
        end
        
        return value
    end
    local function parseDocument(lines, startIndex, endIndex, baseIndent)
        local result = {}
        local i = startIndex or 1
        
        endIndex = endIndex or #lines
        baseIndent = baseIndent or 0
        
        local isArrayDocument = false
        if i <= endIndex and lines[i] then
            local firstLine = lines[i]
            local firstIndent = getIndent(firstLine)
            if firstIndent >= baseIndent and isArrayItem(firstLine) then
                isArrayDocument = true
            end
        end
        
        if isArrayDocument then
            local arrayItems = {}
            while i <= endIndex do
                local line = lines[i]
                if not line then
                    break
                end
                
                local indent = getIndent(line)
                local trimmed = line:match("^%s*(.-)%s*$")
                
                if indent < baseIndent then
                    break
                end
                
                if indent == baseIndent and isArrayItem(line) then
                    local itemValue = trimmed:match("^-%s+(.*)$") or ""
                    
                    if itemValue == "" then
                        local nestedLines = {}
                        local j = i + 1
                        local nextIndent = nil
                        while j <= endIndex and lines[j] do
                            local nestedIndent = getIndent(lines[j])
                            local nestedTrimmed = lines[j]:match("^%s*(.-)%s*$")
                            if nestedTrimmed ~= "" then
                                if nestedIndent <= indent then
                                    break
                                end
                                if nextIndent == nil then
                                    nextIndent = nestedIndent
                                end
                            end
                            table.insert(nestedLines, lines[j])
                            j = j + 1
                        end
                        
                        if #nestedLines > 0 and nextIndent then
                            local nestedResult = parseDocument(nestedLines, 1, #nestedLines, nextIndent)
                            table.insert(arrayItems, nestedResult)
                        else
                            table.insert(arrayItems, nil)
                        end
                        i = j - 1
                    elseif itemValue:find(":") then
                        local colonIndex = itemValue:find(":")
                        local key = itemValue:sub(1, colonIndex - 1):match("^%s*(.-)%s*$")
                        local value = itemValue:sub(colonIndex + 1):match("^%s*(.-)%s*$")
                        table.insert(arrayItems, {[key] = parseValue(value)})
                    else
                        table.insert(arrayItems, parseValue(itemValue))
                    end
                end
                i = i + 1
            end
            return arrayItems
        else
            while i <= endIndex do
                local line = lines[i]
                if not line then
                    break
                end
                
                local indent = getIndent(line)
                local trimmed = line:match("^%s*(.-)%s*$")
                
                if indent < baseIndent then
                    break
                end
                
                if indent == baseIndent and not isArrayItem(line) then
                    local colonIndex = trimmed:find(":")
                    if colonIndex and colonIndex > 0 then
                        local key = trimmed:sub(1, colonIndex - 1):match("^%s*(.-)%s*$")
                        local value = trimmed:sub(colonIndex + 1):match("^%s*(.-)%s*$")
                        
                        -- 处理引号包裹的键
                        if (key:sub(1, 1) == '"' and key:sub(-1) == '"') or
                           (key:sub(1, 1) == "'" and key:sub(-1) == "'") then
                            key = key:sub(2, -2)
                        end
                        
                        -- 尝试转换数字键
                        local numKey = tonumber(key)
                        if numKey and tostring(numKey) == key then
                            key = numKey
                        end
                        
                        if value == "" or value == "{}" or value == "[]" then
                            -- 检查嵌套内容
                            local nestedLines = {}
                            local j = i + 1
                            local nextIndent = nil
                            
                            -- 找到第一个非空行确定嵌套缩进
                            while j <= endIndex and lines[j] do
                                local nestedIndent = getIndent(lines[j])
                                local nestedTrimmed = lines[j]:match("^%s*(.-)%s*$")
                                if nestedTrimmed ~= "" then
                                    if nestedIndent <= indent then
                                        break
                                    end
                                    if nextIndent == nil then
                                        nextIndent = nestedIndent
                                    end
                                end
                                table.insert(nestedLines, lines[j])
                                j = j + 1
                            end
                            
                            if #nestedLines > 0 and nextIndent then
                                result[key] = parseDocument(nestedLines, 1, #nestedLines, nextIndent)
                            else
                                result[key] = (value == "[]") and {} or ((value == "{}") and {} or nil)
                            end
                            i = j - 1
                        else
                            result[key] = parseValue(value)
                        end
                    end
                end
                i = i + 1
            end
            return result
        end
    end
    
    return parseDocument(cleanLines, 1, #cleanLines, 0)
end

-- Parse front-matter format: ---\nyaml\n---\ncontent
-- The 'content' key stores raw text after the closing --- delimiter.
local function ParseFrontMatter(text)
    local lines = {}
    for line in string.gmatch(text .. "\n", "([^\n]*)\n") do
        table.insert(lines, line)
    end

    if not lines[1] or lines[1]:gsub("%s+$", "") ~= "---" then
        return nil
    end

    local closingLine = -1
    for i = 2, #lines do
        if lines[i]:gsub("%s+$", "") == "---" then
            closingLine = i
            break
        end
    end
    if closingLine == -1 then
        return nil
    end

    local frontMatterLines = {}
    for i = 2, closingLine - 1 do
        table.insert(frontMatterLines, lines[i])
    end

    local contentLines = {}
    for i = closingLine + 1, #lines do
        table.insert(contentLines, lines[i])
    end
    local contentStr = table.concat(contentLines, "\n")

    local result = {}
    local fmText = table.concat(frontMatterLines, "\n")
    if fmText:match("%S") then
        result = YamlToLuaParse(fmText) or {}
    end

    result.content = contentStr
    return result
end

-- 将YAML字符串转换为Lua表
-- @param options: {useFrontMatter=bool} when true, detect --- front-matter and extract 'content' from body
function YamlConverter.YAMLToLua(yamlStr, options)
    if not yamlStr or type(yamlStr) ~= "string" or yamlStr:match("^%s*$") then
        return {}
    end

    local useFrontMatter = options and options.useFrontMatter
    if useFrontMatter and (yamlStr:sub(1, 4) == "---\n" or yamlStr:sub(1, 5) == "---\r\n") then
        local fmResult = ParseFrontMatter(yamlStr)
        if fmResult then
            return fmResult
        end
    end

    return YamlToLuaParse(yamlStr)
end



