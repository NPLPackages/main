

WindowSize = "500X400";
WindowSizeOptions = {
    "500X400",
    "600X500",
    "1020X680",
    "1024X768",
    "1280X720",
    "1600X1200",
    "1920X1080",
}
TemplateCode = "";

function _G.SetTemplateCode(code)
    TemplateCode = code;
end

function OnWindowSizeChange(value)
    local width, height = string.match(value, "(%d+)[Xx](%d+)");
    if (type(_G.OnWindowSizeChange) == "function") then
        _G.OnWindowSizeChange(tonumber(width) + 4, tonumber(height) + 42);
    end
end
