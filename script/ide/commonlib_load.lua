

local NPL_load =  NPL.load;
local fileLoaded = {
    -- ["(gl)script/ide/commonlib.lua"] = true;
};
local filepaths = {}
local function ResolvePath(path)
    local parts = {}
    for part in string.gmatch(path, "[^\\/]+") do
        if part == "." then
            -- 忽略当前目录符号
        elseif part == ".." then
            -- 如果有上级目录，则移除最后一个部分
            if #parts > 0 then
                table.remove(parts)
            end
        else
            table.insert(parts, part)
        end
    end

    -- 重新组合路径
    local resolvedPath = table.concat(parts, "/")
    return resolvedPath
end

__rts__:SetField("IsLoadText", true);
_G.__npl_exports__ = {};
NPL.load = function(filename, ...)
    local filepath = filename;
    if (string.sub(filename, 1, 1)== ".") then
        local directory = string.gsub(filepaths[#filepaths] or "", "([^\\/]*)$", "")
        filepath = ResolvePath(directory .. filename);
        -- print("relative path:", filename);
    end
    if (fileLoaded[filepath] ~= nil) then return fileLoaded[filepath] end

    local ret = NPL_load(filepath, ...);
    fileLoaded[filepath] = ret;
    -- print("=======>", filename, _G.__npl_load_filepath__, ret, _G.__npl_load_text__ and _G.__npl_load_filepath__ and "true" or "false")
    local is_export = false;
    if (_G.__npl_load_text__ and _G.__npl_load_filepath__) then 
        if (string.find(_G.__npl_load_text__, "NPL.export", 1, true) ~= nil) then 
            _G.__npl_load_text__ = "_G.__npl_exports__[#(_G.__npl_exports__) + 1] = NPL.export();\n" .. _G.__npl_load_text__;
            is_export = true;
        end
        local code_func, errormsg = loadstring(_G.__npl_load_text__, _G.__npl_load_filepath__);
        if errormsg then 
            print("NPL.loadstring Failed", filename, errormsg) 
            return false;
        end
        filepaths[#filepaths + 1] = _G.__npl_load_filepath__;
        _G.__npl_load_text__ = nil;
        _G.__npl_load_filepath__ = nil;
        pcall(code_func);
        filepaths[#filepaths] = nil;
        if (is_export) then
            ret = _G.__npl_exports__[#(_G.__npl_exports__)];
            fileLoaded[filepath] = ret;
            _G.__npl_exports__[#(_G.__npl_exports__)] = nil;
        end
        current_filepath = nil;
        return ret;
    else
        if (not ret) then
            print("NPL.load failed: ", filename);
        end
        return ret;
    end

end