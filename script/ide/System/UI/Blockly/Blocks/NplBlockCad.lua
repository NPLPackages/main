local NplBlockCad = NPL.export();

local all_categorie_list = {
    {
        name = "Shapes", 
        text = "图形", 
        color = "#764bcc", 
        blocktypes = {
            "createNode", "pushNode", "cube", "box", "sphere", "cylinder", "cone", "torus", "prism", "ellipsoid", "wedge", "trapezoid", "plane", "circle", "ellipse", "regularPolygon", "polygon", "text3d", "importStl", 
        },
    },
    {
        name = "ShapeOperators", 
        text = "修改", 
        color = "#0078d7", 
        blocktypes = {
            "move", "rotate", "rotateFromPivot", "moveNode", "rotateNode", "rotateNodeFromPivot", "cloneNodeByName", "cloneNode", "deleteNode", "fillet", "filletNode", "getEdgeCount", "chamfer", "extrude", "revolve", "mirror", "mirrorNode", "deflection",    
        }
    },
    {
        name = "ObjectName", 
        text = "名称", 
        color = "#ff8c1a", 
        blocktypes = {},
    },
    {
        name = "Control", 
        text = "控制", 
        color = "#d83b01", 
        blocktypes = {
            "repeat_count", "control_if", "if_else", 
        },
    },
    {
        name = "Math", 
        text = "运算", 
        color = "#569138", 
        blocktypes = {
            "math_op", "random",  "math_compared", "not", "mod", "round",  "math_oneop",
        },
    },
    {
        name = "Data", 
        text = "数据", 
        color = "#459197", 
        blocktypes = {
            "getLocalVariable", "createLocalVariable", "assign", "getString", "getBoolean", "getNumber", "newEmptyTable", "getTableValue", "defineFunction", "callFunction", "code_comment", "code_comment_full", "setMaxTrianglesCnt", "jsonToObj",   
        }
    },
    {
        name = "Skeleton", 
        text = "骨骼", 
        color = "#9ab4cd", 
        blocktypes = {
            "createJointRoot", "createJoint", "bindNodeByName", "rotateJoint", "startBoneNameConstraint", "setBoneConstraint", "setBoneConstraint_rotAxis", "setBoneConstraint_hidden",   
        }
    },
    {
        name = "Animation", 
        text = "动画", 
        color = "#717171", 
        blocktypes = {
            "createAnimation", "addChannel", "setAnimationTimeValue_Translate", "setAnimationTimeValue_Scale", "setAnimationTimeValue_Rotate", "animationiNames", 
        }
    },
};

local boolean_op_options = {
    { "+", "union" },
    { "-", "difference" },
    { "x", "intersection" },
};

local axis_options = {
    { "x轴", "x" },
    { "y轴", "y" },
    { "z轴", "z" },
}

local axis_axis_plane_options = {
    { L"全部边", "xyz" },
    { L"x轴", "x" },
    { L"y轴", "y" },
    { L"z轴", "z" },
    { L"xy平面", "xy" },
    { L"xz平面", "xz" },
    { L"yz平面", "yz" },
}

local bone_options = {
    { L"头", "Head" },
    { L"脖子", "Neck" },
    { L"左大臂", "L_UpperArm" },
    { L"右大臂", "R_UpperArm" },
    { L"左前臂", "L_Forearm" },
    { L"右前臂", "R_Forearm" },
    { L"左手", "L_Hand" },
    { L"右手", "R_Hand" },
    { L"脊柱", "Spine" },
    { L"骨盆", "Pelvis" },
    { L"左大腿", "L_Thigh" },
    { L"右大腿", "R_Thigh" },
    { L"左小腿", "L_Calf" },
    { L"右小腿", "R_Calf" },
    { L"左脚", "L_Foot" },
    { L"右脚", "R_Foot" },
}

local all_block_list = {
    {
        type = "createNode", 
        message = "创建 %1 %2 %3",
        arg = {
            {
                name = "name",
                type = "field_variable",
                vartype = "object",
                text = "object",
                isAutoIncrement = true,
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
            {
                name = "value",
                type = "field_dropdown",
                options = {
                    { L"合并", "true" },
                    { L"不合并", "false" },
                },
            },
        },
        category = "Shapes", 
        nextStatement = true,
        code_description = 'createNode("${name}", "${color}", ${value})',
    },

    {
        type = "pushNode", 
        message = L"%1 创建 %2 %3 %4 %5",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "name",
                type = "field_variable",
                vartype = "object",
                text = "object",
                isAutoIncrement = true,
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
            {
                name = "value",
                type = "field_dropdown",
                options = {{ "合并", "true" }, { "不合并", "false" }},
            },
            {
                name = "input",
                type = "input_statement",
            },
        },
        category = "Shapes", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'pushNode("${op}","${name}", "${color}", ${value})\n${input}\npopNode()',
    },

    {
        type = "cube", 
        message = " %1 正方体 %2 %3",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "size",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'cube("${op}", ${size}, "${color}")',
    },

    {
        type = "box", 
        message = " %1 长方体 X %2 Y %3 Z %4 %5",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "x",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
            {
                name = "y",
                type = "input_value",
                shadowType = "math_number",
                text = 2, 
            },
            {
                name = "z",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'box("${op}", ${x}, ${y}, ${z},"${color}")',
    },
   
    {
    	type = "sphere", 
    	message = L"%1 球体 半径 %2 %3",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
    			name = "radius",
    			type = "input_value",
                shadowType = "math_number",
    			text = 1, 
    		},
    		{
    			name = "color",
    			type = "input_value",
                shadowType = "field_color",
    			text = "#ffc658", 
    		},
    	},
        previousStatement = true,
    	nextStatement = true,
    	category = "Shapes", 
        code_description = 'sphere("${op}", ${radius}, "${color}")',
    },

    {
        type = "cylinder", 
        message = L"%1 柱体 半径 %2 高 %3 %4",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
    			name = "radius",
    			type = "input_value",
                shadowType = "math_number",
    			text = 1, 
    		},
            {
                name = "height",
                type = "input_value",
                shadowType = "math_number",
                text = 10, 
            },
    		{
    			name = "color",
    			type = "input_value",
                shadowType = "field_color",
    			text = "#ffc658", 
    		},
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'cylinder("${op}", ${radius}, ${height}, "${color}")',
    },

    {
        type = "cone", 
        message = "%1 圆锥体 顶部半径 %2 底部半径 %3 高 %4 %5",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "radius1",
                type = "input_value",
                shadowType = "math_number",
                text = 2, 
            },
            {
                name = "radius2",
                type = "input_value",
                shadowType = "math_number",
                text = 4, 
            },
            {
                name = "height",
                type = "input_value",
                shadowType = "math_number",
                text = 10, 
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'cone("${op}", ${radius1}, ${radius2}, ${height}, "${color}")',
    },

    {
        type = "torus", 
        message = L"%1 圆环 半径 %2 管道半径 %3 %4",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "radius1",
                type = "input_value",
                shadowType = "math_number",
                text = 10, 
            },
            {
                name = "radius2",
                type = "input_value",
                shadowType = "math_number",
                text = 0.5, 
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
            
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'torus("${op}", ${radius1}, ${radius2}, "${color}")',
    },

    {
        type = "prism", 
        message = "%1 棱柱 边 %2 半径 %3 高 %4 %5",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "p",
                type = "input_value",
                shadowType = "math_number",
                text = 6, 
            },
            {
                name = "c",
                type = "input_value",
                shadowType = "math_number",
                text = 2, 
            },
            {
                name = "h",
                type = "input_value",
                shadowType = "math_number",
                text = 10, 
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'prism("${op}", ${p}, ${c}, ${h}, "${color}")',
    },

    {
        type = "ellipsoid", 
        message = "%1 椭圆体 X半径 %2 Z半径 %3 Y半径 %4 %5",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "r_x",
                type = "input_value",
                shadowType = "math_number",
                text = 2, 
            },
            {
                name = "r_z",
                type = "input_value",
                shadowType = "math_number",
                text = 4, 
            },
            {
                name = "r_y",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'ellipsoid("${op}", ${r_x}, ${r_z}, ${r_y}, "${color}")',
    },

    {
        type = "wedge", 
        message = "%1 楔体 X %2 Z %3 Y %4 %5",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "x",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
            {
                name = "z",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
            {
                name = "y",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'wedge("${op}", ${x}, ${z}, ${y}, "${color}")',
    },

    {
        type = "trapezoid", 
        message = "%1 梯形 顶宽 %2 底宽 %3 高 %4 厚 %5 %6",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "top_w",
                type = "input_value",
                shadowType = "math_number",
                text = 2, 
            },
            {
                name = "bottom_w",
                type = "input_value",
                shadowType = "math_number",
                text = 10, 
            },
            {
                name = "hight",
                type = "input_value",
                shadowType = "math_number",
                text = 10, 
            },
            {
                name = "depth",
                type = "input_value",
                shadowType = "math_number",
                text = 0.5, 
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
        
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'trapezoid("${op}", ${top_w}, ${bottom_w}, ${hight}, ${depth}, "${color}")',
    },

    {
        type = "importStl", 
        message = "引用Stl %1 %2 %3 YZ互换 %4",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "filename",
                type = "input_value",
                shadowType = "field_dropdown",
                options = {
                    { "Arm01.stl", "Mod/NplCad2/stl/RobotArm/Arm01.stl" },
                    { "Arm02.stl", "Mod/NplCad2/stl/RobotArm/Arm02.stl" },
                    { "Arm03.stl", "Mod/NplCad2/stl/RobotArm/Arm03.stl" },
                    { "Base.stl", "Mod/NplCad2/stl/RobotArm/Base.stl" },
                    { "Gripper_Assembly.stl", "Mod/NplCad2/stl/RobotArm/Gripper_Assembly.stl" },
                    { "Servo_Motor_MG996R.stl", "Mod/NplCad2/stl/RobotArm/Servo_Motor_MG996R.stl" },
                    { "Servo_Motor_Micro_9g.stl", "Mod/NplCad2/stl/RobotArm/Servo_Motor_Micro_9g.stl" },
                    { "Waist.stl", "Mod/NplCad2/stl/RobotArm/Waist.stl" },
                },
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
            {
                name = "swapYZ",
                type = "field_dropdown",
                options = {
                    { L"false", "false" },
                    { L"true", "true" },
                },
            },
            
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'importStl("${op}", "${filename}", "${color}", ${swapYZ})',
    },

    {
        type = "plane", 
        message = " %1 平面 长 %2 宽 %3 %4",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "l",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
            {
                name = "w",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'plane("${op}", ${l}, ${w}, "${color}")',
    },

    {
        type = "circle", 
        message = L" %1 圆 半径 %2 角度1 %3 角度2 %4 %5",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "r",
                type = "input_value",
                shadowType = "math_number",
                text = 2, 
            },
            {
                name = "a1",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "a2",
                type = "input_value",
                shadowType = "math_number",
                text = 360, 
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
            
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'circle("${op}", ${r}, ${a1}, ${a2}, "${color}")',
    },

    {
        type = "ellipse", 
        message = " %1 椭圆 主半径 %2 次半径 %3 角度1 %4 角度2 %5 %6",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "r1",
                type = "input_value",
                shadowType = "math_number",
                text = 4, 
            },
            {
                name = "r2",
                type = "input_value",
                shadowType = "math_number",
                text = 2, 
            },
            {
                name = "a1",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "a2",
                type = "input_value",
                shadowType = "math_number",
                text = 360, 
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
            
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'ellipse("${op}", ${r1}, ${r2}, ${a1}, ${a2}, "${color}")',
    },

    {
        type = "regularPolygon", 
        message = " %1 正多边形 边数 %2 外接圆半径 %3 %4",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "p",
                type = "input_value",
                shadowType = "math_number",
                text = 6,
            },
            {
                name = "c",
                type = "input_value",
                shadowType = "math_number",
                text = 2,
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
            
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'regularPolygon("${op}", ${p}, ${c}, "${color}")',
    },

    {
        type = "polygon", 
        message = L" %1 多边形 %2 %3",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "p",
                type = "input_value",
                text = "{0,0,0, 1,0,0, 1,1,0}",
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
            
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'polygon("${op}", ${p}, "${color}")',
    },

    {
        type = "text3d", 
        message = L" %1 文字 %2 字体 %3 大小 %4 厚度 %5 %6",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "text",
                type = "field_input",
                text = "Paracraft",
            },
            {
                name = "fontname",
                type = "input_value",
                shadowType = "field_dropdown",
                options = {
                    { L"微软雅黑", "MSYH" },
                    { L"宋体", "SIMSUN" },
                    { L"仿宋", "SIMFANG" },
                    { L"楷体", "SIMKAI" },
                },
                text = "MSYH", 
            },
            {
                name = "size",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
            {
                name = "height",
                type = "input_value",
                shadowType = "math_number",
                text = 0.1, 
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
            
        },
        previousStatement = true,
        nextStatement = true,
        category = "Shapes", 
        code_description = 'text3d("${op}", "${text}", "${fontname}", ${size}, ${height}, "${color}")',
    },

    -- ShapeOperators
    {
        type = "move", 
        message = L"移动 %1 %2 %3",
        arg = {
            {
                name = "x",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "y",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "z",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            
        },
        category = "ShapeOperators", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'move(${x},${y},${z})',
    },
    {
        type = "scale", 
        message = L"缩放 %1 %2 %3",
        arg = {
            {
                name = "x",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
            {
                name = "y",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
            {
                name = "z",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
        },
        category = "ShapeOperators", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'scale(${x},${y},${z})',
    },
    {
        type = "rotate", 
        message = L"旋转 %1 %2 度",
        arg = {
            {
                name = "axis",
                type = "input_value",
                shadowType = "field_dropdown",
                options = axis_options,
                text = "x", 
            },
            {
                name = "angle",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
        },
        category = "ShapeOperators", 
        code_description = 'rotate("${axis}",${angle})',
        previousStatement = true,
        nextStatement = true,
    },
    
    {
        type = "rotateFromPivot", 
        message = L"旋转 %1 %2 度 中心点 %3 %4 %5",
        arg = {
            {
                name = "axis",
                type = "input_value",
                shadowType = "field_dropdown",
                options = axis_options,
                text = "x", 
            },
            {
                name = "angle",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "tx",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "ty",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "tz",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            
        },
        category = "ShapeOperators", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'rotateFromPivot("${axis}",${angle},${tx},${ty},${tz})',
    },
    
    {
        type = "moveNode", 
        message = L"移动对象 %1 %2 %3 %4",
        arg = {
            {
                name = "name",
                type = "field_variable",
                vartype = "object",
                text = "object",
            },
            {
                name = "x",
                type = "input_value",
                shadow = { type = "math_number", value = 0,},
                text = 0, 
            },
            {
                name = "y",
                type = "input_value",
                shadow = { type = "math_number", value = 0,},
                text = 0, 
            },
            {
                name = "z",
                type = "input_value",
                shadow = { type = "math_number", value = 0,},
                text = 0, 
            },
            
        },
        category = "ShapeOperators", 
        code_description = 'moveNode("${name}",${x},${y},${z})',
        previousStatement = true,
        nextStatement = true,
    },

    {
        type = "rotateNode", 
        message = L"旋转对象 %1 %2 %3 度",
        arg = {
            {
                name = "name",
                type = "field_variable",
                vartype = "object",
                text = "object",
            },
            {
                name = "axis",
                type = "input_value",
                shadowType = "field_dropdown",
                options = axis_options,
                text = "x", 
            },
            {
                name = "angle",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
        },
        category = "ShapeOperators", 
        code_description = 'rotateNode("${axis}", "${name}", ${angle})',
        previousStatement = true,
        nextStatement = true,
    },
    
    {
        type = "rotateNodeFromPivot", 
        message = L"旋转对象 %1 %2 %3 度 中心点 %4 %5 %6",
        arg = {
            {
                name = "name",
                type = "field_variable",
                vartype = "object",
                text = "object",
            },
            {
                name = "axis",
                type = "input_value",
                shadowType = "field_dropdown",
                options = axis_options,
                text = "x", 
            },
            {
                name = "angle",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "tx",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "ty",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "tz",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            
        },
        category = "ShapeOperators", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'rotateNodeFromPivot("${axis}", "${name}",${angle},${tx},${ty},${tz})',
    },

    {
        type = "cloneNodeByName", 
        message = L"%1 复制 %2 %3",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "name",
                type = "field_variable",
                vartype = "object",
                text = "object",
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
            
        },
        category = "ShapeOperators", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'cloneNodeByName("${op}", "${name}", "${color}")',
    },

    {
        type = "cloneNode", 
        message = L"%1 复制 %2",
        arg = {
            {
                name = "op",
                type = "field_dropdown",
                options = boolean_op_options,
                text = "union", 
            },
            {
                name = "color",
                type = "input_value",
                shadowType = "field_color",
                text = "#ffc658", 
            },
            
        },
        category = "ShapeOperators", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'cloneNode("${op}", "${color}")',
    },
 
    {
        type = "deleteNode", 
        message = L"删除 %1",
        arg = {
            {
                name = "name",
                type = "field_variable",
                vartype = "object",
                text = "object",
            },
        },
        category = "ShapeOperators", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'deleteNode("${name}")',
    },
    
    {
        type = "fillet", 
        message0 = L"圆角 %1 半径 %2",
        arg = {
            {
                name = "axis_axis_plane",
                type = "input_value",
                shadowType = "field_dropdown",
                options = axis_axis_plane_options,
                text = "xyz", 
            },
            {
                name = "radius",
                type = "input_value",
                shadowType = "math_number",
                text = 0.1, 
            },
        },
        category = "ShapeOperators", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'fillet("${axis_axis_plane}", ${radius})',
    },
    
    {
        type = "filletNode", 
        message = L"圆角 对象 %1 %2 半径 %3",
        arg = {
            {
                name = "name",
                type = "field_variable",
                vartype = "object",
                text = "object",
            },
            {
                name = "axis_axis_plane",
                type = "input_value",
                shadowType = "field_dropdown",
                options = axis_axis_plane_options,
                text = "xyz", 
            },
            {
                name = "radius",
                type = "input_value",
                shadowType = "math_number",
                text = 0.1, 
            },
        },
        category = "ShapeOperators", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'filletNode("${name}", "${axis_axis_plane}", ${radius})',
    },
    
    {
        type = "getEdgeCount", 
        message = L"总的边数",
        arg = {},
        output = true,
        category = "ShapeOperators", 
        code_description = 'getEdgeCount()',
    },
    
    {
        type = "chamfer", 
        message = L"倒角 %1 半径 %2",
        arg = {
            {
                name = "axis_axis_plane",
                type = "input_value",
                shadowType = "field_dropdown",
                options = axis_axis_plane_options,
                text = "xyz", 
            },
            {
                name = "radius",
                type = "input_value",
                shadowType = "math_number",
                text = 0.1, 
            },
        },
        category = "ShapeOperators", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'chamfer("${axis_axis_plane}", ${radius})',
    },
    
    {
        type = "extrude", 
        message = L"线性拉伸 长度 %1",
        arg = {
            {
                name = "height",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
        },
        category = "ShapeOperators", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'extrude(${height})',
    },
    
    {
        type = "revolve", 
        message = L"旋转拉伸 %1 角度 %2",
        arg = {
            {
                name = "axis",
                type = "input_value",
                shadowType = "field_dropdown",
                options = axis_options,
                text = "x", 
            },
            {
                name = "angle",
                type = "input_value",
                shadowType = "math_number",
                text = 360, 
            },
        },
        category = "ShapeOperators", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'revolve("${axis}", ${angle})',
    },
    
    {
        type = "mirror", 
        message = L"镜像 %1 中心点 %2 %3 %4",
        arg = {
            {
                name = "axis_plane",
                type = "input_value",
                shadowType = "field_dropdown",
                options = axis_axis_plane_options,
                text = "xy", 
            },
            {
                name = "x",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "y",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "z",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
        },
        category = "ShapeOperators", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'mirror("${axis_plane}", ${x}, ${y}, ${z})',
    },
    
    {
        type = "mirrorNode", 
        message = L"镜像对象 %1 %2 中心点 %3 %4 %5",
        arg = {
            {
                name = "name",
                type = "field_variable",
                vartype = "object",
                text = "object",
            },
            {
                name = "axis_plane",
                type = "input_value",
                shadowType = "field_dropdown",
                options = axis_axis_plane_options,
                text = "xy", 
            },
            {
                name = "x",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "y",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "z",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
        },
        category = "ShapeOperators", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'mirrorNode("${name}","${axis_plane}", ${x}, ${y}, ${z})',
    },
    
    {
        type = "deflection", 
        message = L"弦公差 %1 角度公差 %2",
        arg = {
            {
                name = "liner",
                type = "input_value",
                shadowType = "math_number",
                text = 0.5, 
            },
            {
                name = "angular",
                type = "input_value",
                shadowType = "math_number",
                text = 28.5, 
            },
            
        },
        category = "ShapeOperators", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'deflection( ${liner}, ${angular})',
    },

    -- Control
    {
        type = "repeat_count", 
        message = L"循环:变量%1从%2到%3 %4",
        arg = {
            {
                name = "var",
                type = "field_input",
                text = "i",
            },
            {
                name = "start_index",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
            {
                name = "end_index",
                type = "input_value",
                shadowType = "math_number",
                text = 10, 
            },
            {
                name = "input",
                type = "input_statement",
            },
        },
        category = "Control", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'for ${var} = ${start_index}, ${end_index} do\n${input}\nend',
    },
    
    {
        type = "control_if", 
        message = "如果%1那么%2",
        arg = {
            {
                name = "expression",
                type = "input_value",
            },
            {
                name = "input_true",
                type = "input_statement",
            },
        },
        category = "Control", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'if(${expression}) then\n${input_true}\nend',
    },
    
    {
        type = "if_else", 
        message = "如果%1那么%2否则%3",
        arg = {
            {
                name = "expression",
                type = "input_value",
            },
            {
                name = "input_true",
                type = "input_statement",
            },
            {
                name = "input_else",
                type = "input_statement",
            },
        },
        category = "Control", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'if(${expression}) then\n${input_true}\nelse\n${input_else}\nend',
    },


    -- Math
    {
        type = "math_op", 
        message = L"%1 %2 %3",
        arg = {
            {
                name = "left",
                type = "input_value",
                shadowType = "math_number",
            },
            {
                name = "op",
                type = "field_dropdown",
                options = {
                    { "+", "+" },{ "-", "-" },{ "*", "*" },{ "/", "/" },
                    { ">", ">" },{ "<", "<" },{ ">=", ">=" },{ "<=", "<=" },{ "==", "==" },{ "~=", "~=" },
                },
            },
            {
                name = "right",
                type = "input_value",
                shadowType = "math_number",
            },
        },
        output = true,
        category = "Math", 
        code_description = '((${left}) ${op} (${right}))',
    },
    
    {
        type = "random", 
        message = L"随机选择从%1到%2",
        arg = {
            {
                name = "from",
                type = "input_value",
                shadowType = "math_number",
                text = "1",
            },
            {
                name = "to",
                type = "input_value",
                shadowType = "math_number",
                text = "10",
            },
        },
        output = true,
        category = "Math", 
        code_description = 'math.random(${from}, ${to})',
    },
    
    {
        type = "math_compared", 
        message = L"%1 %2 %3",
        arg = {
            {
                name = "left",
                type = "input_value",
            },
            {
                name = "op",
                type = "field_dropdown",
                options = {
                    { L"并且", "and" },{ L"或", "or" },
                },
            },
            {
                name = "right",
                type = "input_value",
            },
        },
        output = true,
        category = "Math", 
        code_description = '(${left}) ${op} (${right})',
    },
    
    {
        type = "not", 
        message = L"不满足%1",
        arg = {
            {
                name = "left",
                type = "input_value",
            },
        },
        output = true,
        category = "Math", 
        code_description = '(not ${left})',
    },
    
    {
        type = "mod", 
        message = L"%1除以%2的余数",
        arg = {
            {
                name = "left",
                type = "input_value",
                shadowType = "math_number",
                text = "66",
            },
            {
                name = "right",
                type = "input_value",
                shadowType = "math_number",
                text = "10",
            },
        },
        output = true,
        category = "Math", 
        code_description = '(${left} % ${right})',
    },
    
    {
        type = "round", 
        message = L"四舍五入取整%1",
        arg = {
            {
                name = "left",
                type = "input_value",
                shadowType = "math_number",
                text = 5.5,
            },
        },
        output = true,
        category = "Math", 
        code_description = 'math.floor(${left}+0.5)',
    },
    
    {
        type = "math_oneop", 
        message = L"%1%2",
        arg = {
            {
                name = "name",
                type = "field_dropdown",
                options = {
                    { L"开根号", "sqrt" },
                    { "sin", "sin"},
                    { "cos", "cos"},
                    { L"绝对值", "abs"},
                    { "asin", "asin"},
                    { "acos", "acos"},
                    { L"向上取整", "ceil"},
                    { L"向下取整", "floor"},
                    { "tab", "tan"},
                    { "atan", "atan"},
                    { "log10", "log10"},
                    { "exp", "exp"},
                },
            },
            {
                name = "left",
                type = "input_value",
                shadowType = "math_number",
                text = 9,
            },
        },
        output = true,
        category = "Math", 
        code_description = 'math.${name}(${left})',
    },

    -- Data
    {
    	type = "getLocalVariable", 
    	message = L"%1",
    	arg = {
    		{
    			name = "var",
    			type = "field_variable",
                vartype = "local_variable",
    			text = "变量名",
    		},
    	},
    	output = true,
    	category = "Data", 
    	code_description = '${var}',
    },

    {
        type = "createLocalVariable", 
        message = L"新建本地%1为%2",
        arg = {
            {
    			name = "var",
    			type = "field_variable",
                vartype = "local_variable",
    			text = "变量名",
    		},
            {
                name = "value",
                type = "input_value",
                text = "0",
            },
        },
        category = "Data", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'local ${var} = ${value}',
    },

    {
        type = "assign", 
        message = L"%1赋值为%2",
        arg = {
            {
    			name = "var",
    			type = "field_variable",
                vartype = "local_variable",
    			text = "变量名",
    		},
            {
                name = "value",
                type = "input_value",
                text = "1",
            },
        },
        category = "Data", 
        previousStatement = true,
        nextStatement = true,
        code_description = '${var} = ${value}',
    },

    {
        type = "getString", 
        message = "\"%1\"",
        arg = {
            {
                name = "left",
                type = "field_input",
                text = "string",
            },
        },
        output = true,
        category = "Data", 
        code_description = '"${left}"',
    },

    {
        type = "getBoolean", 
        message = L"%1",
        arg = {
            {
                name = "value",
                type = "field_dropdown",
                options = {
                    { "true", "true" },
                    { "false", "false" },
                    { "nil", "nil" },
                }
            },
        },
        output = true,
        category = "Data", 
        code_description = '${value}',
    },

    {
        type = "getNumber", 
        message = L"%1",
        arg = {
            {
                name = "value",
                type = "field_number",
                text = "0",
            },
        },
        output = true,
        category = "Data", 
        code_description = '${value}',
    },

    {
        type = "newEmptyTable", 
        message0 = L"{%1}",
        arg0 = {
            {
                name = "value",
                type = "input_value_list",
                separator = ",",
            },
        },
        output = true,
        category = "Data", 
        code_description = '{${value}}',
    },

    {
        type = "getTableValue", 
        message = L"%1中的%2",
        arg = {
            {
                name = "table",
                type = "input_value",
                text = "_G", 
            },
            {
                name = "key",
                type = "input_value",
                text = "key", 
            },
        },
        output = true,
        category = "Data", 
        code_description = '${table}["${key}"]',
    },

    {
    	type = "defineFunction", 
    	message = L"定义函数%1(%2) %3",
    	arg = {
    		{
    			name = "name",
    			type = "field_input",
    			text = "", 
    		},
    		{
    			name = "param",
    			type = "field_input",
    			text = "", 
    		},
            {
    			name = "input",
    			type = "input_statement",
    		},
    	},
    	previousStatement = true,
    	nextStatement = true,
    	category = "Data", 
    	code_description = 'function ${name}(${param})\n${input}\nend',
    },

    {
    	type = "callFunction", 
    	message = L"调用函数%1(%2)",
    	arg = {
    		{
    			name = "name",
    			type = "field_input",
    			text = "log",
    		},
    		{
    			name = "param",
    			type = "input_value",
    			text = "",
    		},
    	},
    	previousStatement = true,
    	nextStatement = true,
    	category = "Data", 
    	code_description = '${name}(${param})',
    },

    {
    	type = "code_comment", 
    	message = L"-- %1",
    	arg = {
    		{
    			name = "value",
    			type = "field_input",
    			text = "",
    		},
    	},
    	category = "Data", 
    	previousStatement = true,
    	nextStatement = true,
    	code_description = '-- ${value}',
    },

    {
        type = "code_comment_full", 
        message = L"注释全部 %1",
        arg = {
            {
                name = "input",
                type = "input_statement",
            },
        },
        category = "Data", 
        previousStatement = true,
        nextStatement = true,
        code_description = '--[[\n${input}\n]]',
    },

    {
    	type = "setMaxTrianglesCnt", 
    	message = L"模型三角形最大数量: %1",
    	arg = {
    		{
    			name = "value",
    			type = "field_number",
    			text = "-1",
    		},
    	},
    	category = "Data", 
    	previousStatement = true,
    	nextStatement = true,
    	code_description = 'setMaxTrianglesCnt(${value})',
    },

    {
    	type = "jsonToObj", 
    	message = L"转换Json字符串 %1 为Lua Table",
    	arg = {
    		{
    			name = "value",
    			type = "field_input",
    			text = "",
    		},
    	},
    	category = "Data", 
    	previousStatement = true,
    	nextStatement = true,
    	code_description = 'jsonToObj("${value}")',
    },

    {
        type = "objToJson", 
        message = L"转换 %1 为Json字符串",
        arg = {
            {
                name = "value",
                type = "field_input",
                text = "",
            },
        },
        category = "Data", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'objToJson(${value})',
    },

    -- Skeleton
    {
        type = "createJointRoot", 
        message = L"骨骼根节点 %1",
        arg = {
            {
                name = "is_enabled",
                type = "field_dropdown",
                options = {
                    { L"有效", "true" },
                    { L"无效", "false" },
                },
            },
        },
        category = "Skeleton", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'createJointRoot(nil, ${is_enabled})',
    },
    
    {
        type = "createJoint", 
        message = L"骨骼 %1 %2 %3 %4 %5",
        arg = {
            {
                name = "name",
                type = "input_value",
                shadowType = "field_dropdown",
                options = bone_options,
                text = "Head",
            },
            {
                name = "x",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "y",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "z",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "input",
                type = "input_statement",
            },
        },
        category = "Skeleton", 
        previousStatement = true,
        nextStatement = true,
        funcName = "createJoint",
        code_description = 'createJoint("${name}", ${x}, ${y}, ${z})\n${input}\nendJoint()',
    },
    
    {
        type = "bindNodeByName", 
        message = L"绑定对象 %1",
        arg = {
            {
                name = "name",
                type = "field_variable",
                vartype = "object",
                text = "object",
            },
        },
        category = "Skeleton", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'bindNodeByName("${name}")',
    },
    
    {
        type = "rotateJoint", 
        message = L"旋转 %1 %2 度",
        arg = {
            {
                name = "axis",
                type = "input_value",
                shadowType = "field_dropdown",
                options = axis_options,
                text = "x", 
            },
            {
                name = "angle",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
        },
        category = "Skeleton", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'rotateJoint("${axis}", ${angle})',
    },
    
    {
        type = "startBoneNameConstraint", 
        message = L"约束骨骼属性 %1",
        arg = {
            {
                name = "input",
                type = "input_statement",
            },
        },
        category = "Skeleton", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'startBoneNameConstraint()\n${input}\nendBoneNameConstraint()',
    },
    
    {
        type = "setBoneConstraint_Name", 
        message = L"骨骼名称 %1",
        arg = {
            {
                name = "name",
                type = "input_value",
                shadowType = "field_dropdown",
                options = bone_options,
                text = "Head",
            },
        },
        category = "Skeleton", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'setBoneConstraint_Name("${name}")',
    },
    
    {
        type = "setBoneConstraint", 
        message = L"%1%2",
        arg = {
            {
                name = "name",
                type = "field_dropdown",
                options = {
                    { L"最小角度", "min" },
                    { L"最大角度", "max" },
                    { L"偏移角度", "servoOffset" },
                    { L"舵机通道", "servoId" },
                    { L"舵机缩放值", "servoScale" },
                    { L"IK", "IK" },
                },
            },
            {
                name = "value",
                type = "input_value",
                shadowType = "math_number",
                text = 0,
            },
        },
        category = "Skeleton", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'setBoneConstraint("${name}", ${value})',
    },
    
    {
        type = "setBoneConstraint_rotAxis", 
        message = L"旋转轴 %1",
        arg = {
            {
                name = "value",
                type = "field_dropdown",
                options = {
                    { L"x", "x" },
                    { L"y", "y" },
                    { L"z", "z" },
                },
            },
        },
        category = "Skeleton", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'setBoneConstraint("rotAxis", ${value})',
    },
    
    {
        type = "setBoneConstraint_hidden", 
        message = L"隐藏骨骼 %1",
        arg = {
            {
                name = "value",
                type = "field_dropdown",
                options = {
                    { L"false", "false" },
                    { L"true", "true" },
                },
            },
        },
        category = "Skeleton", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'setBoneConstraint("hidden", ${value})',
    },

    -- Animation
    {
        type = "createAnimation", 
        message = L"骨骼动画 %1 %2",
        arg = {
            {
                name = "name",
                type = "field_variable",
                vartype = "animation_name",
                text = "anim",
            },
             {
                name = "is_enabled",
                type = "field_dropdown",
                options = {
                    { L"有效", "true" },
                    { L"无效", "false" },
                },
            },
        },
        category = "Animation", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'createAnimation("${name}", ${is_enabled})',
    },
    
    {
        type = "addChannel", 
        message = L"动画通道 %1 %2 %3",
        arg = {
            {
                name = "name",
                type = "input_value",
                text = "",
            },
            {
                name = "type",
                type = "field_dropdown",
                options = {
                    { L"线性", "linear" }, 
                    { L"步", "step" },
                },
            },
            {
                name = "input",
                type = "input_statement",
            },
        },
        category = "Animation", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'addChannel("${name}", "${type}")\n${input}\nendChannel()',
    },
    
    {
        type = "setAnimationTimeValue_Translate", 
        message = L"时间 %1 移动 %2 %3 %4",
        arg = {
            {
                name = "time",
                type = "input_value",
                shadowType = "math_number",
                text = 0,
            },
            {
                name = "x",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "y",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            {
                name = "z",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            
        },
        category = "Animation", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'setAnimationTimeValue_Translate(${time}, ${x}, ${y}, ${z})',
    },
    
    {
        type = "setAnimationTimeValue_Scale", 
        message = L"时间 %1 缩放 %2 %3 %4",
        arg = {
            {
                name = "time",
                type = "input_value",
                shadowType = "math_number",
                text = 0,
            },
            {
                name = "x",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
            {
                name = "y",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
            {
                name = "z",
                type = "input_value",
                shadowType = "math_number",
                text = 1, 
            },
            
        },
        category = "Animation", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'setAnimationTimeValue_Scale(${time}, ${x}, ${y}, ${z})',
    },
  
    {
        type = "setAnimationTimeValue_Rotate", 
        message = L"时间 %1 旋转 %2 %3 度",
        arg = {
            {
                name = "time",
                type = "input_value",
                shadowType = "math_number",
                text = "0",
            },
            {
                name = "axis",
                type = "input_value",
                shadowType = "field_dropdown",
                options = axis_options,
                text = "x",
            },
            {
                name = "angle",
                type = "input_value",
                shadowType = "math_number",
                text = 0, 
            },
            
        },
        category = "Animation", 
        previousStatement = true,
        nextStatement = true,
        code_description = 'setAnimationTimeValue_Rotate(${time}, "${axis}", ${angle})',
    },

    {
        type = "animationiNames", 
        message = "%1",
        arg = {
            {
                name = "name",
                type = "field_dropdown",
                options = {
                    { L"待机", "'ParaAnimation_0'" },
                    { L"倒下", "'ParaAnimation_1'" },
                    { L"走路", "'ParaAnimation_4'" },
                    { L"跑步", "'ParaAnimation_5'" },
                },
            },
        },
        
        category = "Animation", 
        output = true,
        code_description = '"${name}"',
    },
}


function NplBlockCad.GetBlockMap()
    local all_block_map = {};
    for _, block in ipairs(all_block_list) do
        all_block_map[block.type] = block;
    end
	return all_block_map;
end

function NplBlockCad.GetCategoryListAndMap()
    local all_categorie_map = {};
    for _, category in ipairs(all_categorie_list) do
        all_categorie_map[category.name] = category;
    end
	return all_categorie_list, all_categorie_map;
end