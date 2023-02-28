--[[
Title: Connection
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Connection = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Connection.lua");
-------------------------------------------------------
]]

local Connection = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local ConnectionDebug = GGS.Debug.GetModuleDebug("ConnectionDebug").Enable();   --Enable  Disable

Connection:Property("Connection");        -- 连接的链接 
Connection:Property("Block");             -- 所属块
Connection:Property("Check");             -- 连接核对 是否可以链接
Connection:Property("Type");              -- 类型 statement  value
Connection:Property("OnDisconnectionCallback")
function Connection:ctor()
    self.left, self.top, self.width, self.height = 0, 0, 0, 0;
    self.centerX, self.centerY, self.halfWidth, self.halfHeight = 0, 0, 0, 0;
end

function Connection:Init(block, typ, check)
    self:SetBlock(block);
    self:SetType(typ);
    if (type(check) == "string") then 
        if (check == "") then
            check = nil;
        else
            check = commonlib.split(check, ' '); 
        end
    end 
    if (type(check) == "boolean") then check = nil end
    self:SetCheck(check);

    return self;
end

function Connection:SetGeometry(left, top, width, height)
    self.left, self.top, self.width, self.height = left, top, width, height;
    self.halfWidth, self.halfHeight = self.width / 2, self.height / 2;
    self.centerX, self.centerY = self.left + self.halfWidth, self.top + self.halfHeight;
end

function Connection:IsIntersect(connection)
    return math.abs(self.centerX - connection.centerX) <= (self.halfWidth + connection.halfWidth) and math.abs(self.centerY - connection.centerY) <= (self.halfHeight + connection.halfHeight);
end

function Connection:IsMatch(connection)
    if (not connection) then return false end
    local self_type = self:GetType();
    local conn_type = connection:GetType();
    if (self_type == "previous_connection" and conn_type ~= "next_connection") then return false end
    if (self_type == "next_connection" and conn_type ~= "previous_connection") then return false end
    if (self_type == "output_connection" and conn_type ~= "input_connection") then return false end
    if (self_type == "input_connection" and conn_type ~= "output_connection") then return false end
    local self_check, conn_check = self:GetCheck(), connection:GetCheck();
    if (self_check or conn_check) then
        if (not self_check or not conn_check) then return false end
        for _, self_type in ipairs(self_check) do
            for _, conn_type in ipairs(conn_check) do
                if (self_type == conn_type) then 
                    return self:IsIntersect(connection);
                end                
            end
        end
        return false;
    end
    return self:IsIntersect(connection);
end

function Connection:IsConnection()
    return self:GetConnection() ~= nil;
end

-- 连接
function Connection:Connection(connection)
    self:SetConnection(connection);
    if (connection) then connection:SetConnection(self) end
end

-- 解除连接
function Connection:Disconnection()
    local connection = self:GetConnection();
    if (connection == nil) then return nil end

    self:SetConnection(nil);
    self:OnDisconnection(connection);
    connection:SetConnection(nil);
    connection:OnDisconnection(self);

    return connection;
end

function Connection:OnDisconnection()
    local OnDisconnectionCallback = self:GetOnDisconnectionCallback();
    if (type(OnDisconnectionCallback) == "function") then
        OnDisconnectionCallback();
    end
end

-- 获取连接块
function Connection:GetConnectionBlock()
    local connection = self:GetConnection();
    return connection and connection:GetBlock();
end

function Connection:Debug()
    local offsetX, offsetY = self:GetBlock():GetLeftTopUnitCount();
    ConnectionDebug.Format("connection = %s, block = %s, ConnectionConnection = %s", tostring(self), tostring(self:GetBlock()), tostring(self:GetConnection()));
    ConnectionDebug.Format("blockId = %s, offsetX = %s, offsetY = %s, left = %s, top = %s, width = %s, height = %s", self:GetBlock():GetId(), offsetX, offsetY, self.left, self.top, self.width, self.height);
end
