--[[
Title: TableEditor
-------------------------------------------------------
_G.IsDevEnv = true;
NPL.load("script/ide/System/UI/TableEditor/TableEditor.lua");
local TableEditor = commonlib.gettable("System.UI.TableEditor.TableEditor");
TableEditor:Show({
    fields = {
        {
            name = "name",
            title = "姓名",
            description = "姓名",
            type = "string",
            default = "张三",
        },
        {
            name = "age",
            title = "年龄",
            description = "年龄",
            type = "number",
            default = 18,
        },
        {
            name = "gender",
            title = "性别",
            description= "性别",
            type = "string",
            options = {"男", "女"},
            default = "男",
        },
    },
    object = {
        name = "李四",
        age = 28,
        gender = "男",
    },
});
-------------------------------------------------------
]]

local TableEditor = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.UI.TableEditor.TableEditor"));
local Vue = NPL.load("script/ide/System/UI/Vue/Vue.lua");
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");


function TableEditor:ctor()

end

function TableEditor:ParseTableConfig(table_config)
	local fields = table_config.fields;
    local object = table_config.object or {};
    local field_config_list = {};
    local field_config_map = {};
    for _, field in ipairs(fields) do
        local field_config = {};
        field_config.name = field.name;
        field_config.key = field.key or field.name;
        field_config.title = field.title;
        field_config.description = field.description;
        field_config.options = field.options;
        field_config.order = field.order;
        if (field_config.key) then
            local default = field.default;
            local object_field_value = self:GetFieldValue(object, field_config.key)
            if (object_field_value ~= nil) then default = object_field_value end

            if (default == nil) then
                field_config.type = field.type or "string";
                field_config.default = self:GetTypeDefaultValue(field_config.type);
            else
                field_config.default = default
            end

            if (field.type == nil) then
                field_config.type = self:GetValueDefaultType(field_config.default);
            else
                field_config.type = field.type;
            end
        end
        if (field_config.default ~= nil and field_config.type ~= nil and field_config.key ~= nil) then
            table.insert(field_config_list, field_config);
            field_config_map[field_config.key] = field_config;
        end
    end

    CommonLib.Table.Sort(field_config_list, function(a, b)
        local a_order = a.order or 0;
        local b_order = b.order or 0;
        if (a_order == b_order) then
            return string.lower(a.key) > string.lower(b.key);
        else
            return a_order > b_order;            
        end
    end);

    self.m_field_config_list = field_config_list;
    self.m_field_config_map = field_config_map;
    self.m_object = object;
end

function TableEditor:GetFieldValue(object, key)
    if(not key) then return end
	for w, d in string.gfind(key, "([%w_]+)(.?)") do
        if (type(object) ~= "table") then return end
		if d == "." then      
			object[w] = object[w] or {};   
			object = object[w];           
		else                  
			return object[w];            
		end
	end
end

function TableEditor:SetFieldValue(object, key, value)
    if(not key) then return end
	for w, d in string.gfind(key, "([%w_]+)(.?)") do
        if (type(object) ~= "table") then return end
		if d == "." then      
			object[w] = object[w] or {};   
			object = object[w];        
		else                  
			object[w] = value;          
		end
	end
end

function TableEditor:StringToTypeValue(value, type)
    if (type == "string") then
        return value;
    elseif (type == "number") then
        return tonumber(value);
    elseif (type == "boolean") then
        return value == "true";
    else
        return nil;
    end
end

function TableEditor:SaveObject(obj)
    for key, value in pairs(obj) do
        local field_config = self.m_field_config_map[key];
        local field_value = self:StringToTypeValue(value, field_config.type);
        self:SetFieldValue(self.m_object, key, field_value);
    end
    self.m_window:CloseWindow();
end

function TableEditor:GetTypeDefaultValue(type)
    if (type == "string") then
        return "";
    elseif (type == "number") then
        return 0;
    elseif (type == "boolean") then
        return false;
    elseif (type == "table") then
        return {};
    else
        return nil;
    end
end

function TableEditor:GetValueDefaultType(value)
    if (type(value) == "string") then
        return "string";
    elseif (type(value) == "number") then
        return "number";
    elseif (type(value) == "boolean") then
        return "boolean";
    elseif (type(value) == "table") then
        return "table";
    else
        return nil;
    end
end

function TableEditor:Show(table_config)
    table_config = table_config or {};

    if (self.m_window) then
        self.m_window:CloseWindow();
    else 
        self.m_window = Vue:new();
    end
    
    self:ParseTableConfig(table_config);
    
    local object = {};
    local changed = false;
    local params = {
        url = "%ui%/TableEditor/TableEditor.html",
        name = "TableEditor",
        width = 800,
        height = 600,
        draggable = false,
        G = {
            window_title = table_config.title or "对象编辑器",
            field_config_list = self.m_field_config_list or {},

            onsave = function() 
                -- print("onsave", changed)
                if (changed) then
                    self:SaveObject(object);

                    if (table_config.callback) then
                        table_config.callback(self.m_object);
                    end
                end
            end,

            setfield = function(key, value)
                changed = true;
                object[key] = value;
            end,
        },
    };
    self.m_window:Show(params);
end

function TableEditor:ShowLiveModelStaticPhysicsProperties(live_model)
	local obj = live_model:GetInnerObject();
    if (not obj) then return end
    obj:SetField("EnablePhysics", false);
    obj:SetField("EnableDynamicPhysics", true);
    local PhysicalPropertyObject = NPL.LoadTableFromString(obj:GetField("PhysicalProperty", ""));
    -- echo(PhysicalPropertyObject, true);

    local table_config = {
        title = "物理属性",
        fields = {
            {
                name = "Mass",
                key = "Mass",
                title = "质量",
                description = "质量(Mass) 是物体的一个基本物理属性，表示物体所含物质的数量。在物理仿真中，质量决定了物体如何响应外力和碰撞。",
                type = "number",
                default = 1,
                order = 0,
            },
            {
                name = "Friction",
                key = "Friction",
                title = "摩擦力",
                description = "摩擦力(Friction): 控制了物体滑动时的摩擦力。",
                type = "number",
                default = 0.5,
                order = 1,
            },
            {
                name = "RollingFriction",
                key = "RollingFriction",
                title = "滚轮摩擦力",
                description = "滚轮摩擦力(RollingFriction): 控制了物体碰撞时的滚轮摩擦力。",
                type = "number",
                default = 0,
                order = 2,
            },
            {
                name = "SpinningFriction",
                key = "SpinningFriction",
                title = "自旋摩擦力",
                description = "自旋摩擦力(SpinningFriction): 控制了物体自旋时的摩擦力。",
                type = "number",
                default = 0,
                order = 3,
            },
            {
                name = "Restitution",
                key = "Restitution",
                title = "弹性",
                description = "弹性(Restitution): 控制了物体在碰撞时如何保持运动。",
                type = "number",
                default = 0,
                order = 4,
            },
            {
                name = "ContactDamping",
                key = "ContactDamping",
                title = "接触阻尼",
                description = "接触阻尼(ContactDamping): 用于减少物体在碰撞时产生的速度变化。它模拟了摩擦力、空气阻力等效果，使得物体在碰撞后逐渐停止运动。",
                type = "number",
                default = 0.1,
                order = 5,
            },
            {
                name = "LinearDamping",
                key = "LinearDamping",
                title = "线性阻力",
                description = "线性阻力(LinearDamping): 用于减少物体的线性速度。它模拟了空气阻力、摩擦力等效果，使得物体在运动时逐渐减速，最终停止。",
                type = "number",
                default = 0,
                order = 6,
            },
            -- {
            --     name = "LinearVelocityX",
            --     key = "LinearVelocityX",
            --     title = "线性速度X",
            --     description = "线性速度X: 物体的水平速度，以米/秒为单位。",
            --     type = "number",
            --     default = 0,
            --     order = 3,
            -- },
            -- {
            --     name = "LinearVelocityY",
            --     key = "LinearVelocityY",
            --     title = "线性速度Y",
            --     description = "线性速度Y: 物体的垂直速度，以米/秒为单位。",
            --     type = "number",
            --     default = 0,
            --     order = 4,
            -- },
            -- {
            --     name = "LinearVelocityZ",
            --     key = "LinearVelocityZ",
            --     title = "线性速度Z",
            --     description = "线性速度Z: 物体的垂直速度，以米/秒为单位。",
            --     type = "number",
            --     default = 0,
            --     order = 5,
            -- },
            {
                name = "AngularDamping",
                key = "AngularDamping",
                title = "旋转阻力",
                description = "旋转阻力(AngularDamping): 用于减少物体的角速度。它模拟了空气阻力、摩擦力等效果，使得物体在旋转时逐渐减速，最终停止。",
                type = "number",
                default = 0,
                order = 7,
            },
            -- {
            --     name = "AngularVelocityX",
            --     key = "AngularVelocityX",
            --     title = "旋转速度X",
            --     description = "旋转速度X: 物体的水平旋转速度，以弧度/秒为单位。",
            --     type = "number",
            --     default = 0,
            --     order = 7,
            -- },
            -- {
            --     name = "AngularVelocityY",
            --     key = "AngularVelocityY",
            --     title = "旋转速度Y",
            --     description = "旋转速度Y: 物体的水平旋转速度，以弧度/秒为单位。",
            --     type = "number",
            --     default = 0,
            --     order = 8,
            -- },
            -- {
            --     name = "AngularVelocityZ",
            --     key = "AngularVelocityZ",
            --     title = "旋转速度Z",
            --     description = "旋转速度Z: 物体的水平旋转速度，以弧度/秒为单位。",
            --     type = "number",
            --     default = 0,
            --     order = 9,
            -- },
            -- {
            --     name = "GravityX",
            --     key = "GravityX",
            --     title = "重力X",
            --     description = "重力X: 物体的重力X轴方向，以米/秒^2为单位。",
            --     type = "number",
            --     default = 0,
            --     order = 10,
            -- }, 
            {
                name = "GravityY",
                key = "GravityY",
                title = "重力Y",
                description = "重力Y(GravityY): 物体的重力Y轴方向，以米/秒^2为单位。",
                type = "number",
                default = -10,
                order = 11,
            },
            -- {
            --     name = "GravityZ",
            --     key = "GravityZ",
            --     title = "重力Z",
            --     description = "重力Z: 物体的重力Z轴方向，以米/秒^2为单位。",
            --     type = "number",
            --     default = 0,
            --     order = 12,
            -- }
            -- {
            --     name = "CollisionFlags",
            --     key = "CollisionFlags",
            --     title = "碰撞标志",
            --     description = "碰撞行为: 0 无, 1 静止 2 运动学",
            --     type = "number",
            --     default = 0,
            --     order = 12,
            -- }
        },
        object = {},
        callback = function(object)
            print("===============SavePhysicalProperty=============");
            echo(object, true);
            obj:SetField("PhysicalProperty", commonlib.serialize_compact(object));
        end
    };
    if (type(PhysicalPropertyObject) == "table") then
        print("默认物理属性值:")
        echo(PhysicalPropertyObject, true)
        for _, field in ipairs(table_config.fields) do
            table_config.object[field.name] = PhysicalPropertyObject[field.name];
        end
    else
        print("默认物理属性值不存在!!!");
    end
    self:Show(table_config);
end

-- 初始化成单列模式
TableEditor:InitSingleton();