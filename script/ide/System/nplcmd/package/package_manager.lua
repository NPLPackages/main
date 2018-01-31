NPL.PackageManager = {}

local _M = NPL.PackageManager

function _M.init(packages)
    _M.packages = packages
end

function _M.package_info(package_name)
    for _, package in pairs(_M.packages or {}) do
        if package.name == package_name then
            return package
        end
    end
end

return _M
