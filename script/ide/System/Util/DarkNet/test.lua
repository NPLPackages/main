--[[
NPL.load("(gl)script/ide/System/Util/DarkNet/test.lua", true);
]]

local DarkNet = NPL.load("(gl)script/ide/System/Util/DarkNet/DarkNet.lua", true);

function test_softmax()
    local net = ParaDarkNet(false);
    net:Load("D:/workspace/cpp/darknet/data/softmax/data");
    net:Test();
end

function text_yolo()
    local net = ParaDarkNet(false);
    net:Load("D:/workspace/cpp/darknet/data/yolo/data");
    net:Test();
end

function print_predict_results(results)
    for i = 1, #results do
        local result = results[i];
        print(result.m_class_index, result.m_probability, result.m_x, result.m_y, result.m_width, result.m_height);
    end
end
function predict_yolo()
    local net = ParaDarkNet(false);
    net:Load("D:/workspace/cpp/darknet/data/yolo/data");
    print_predict_results(net:Predict("D:/workspace/cpp/darknet/data/yolo/images/0001.jpg", true));
    print_predict_results(net:Predict("D:/workspace/program/ParacraftDev/worlds/DesignHouse/_user/xiaoyao/object-detect/images/train_data/1.png", true));
    print_predict_results(net:Predict("D:/workspace/program/ParacraftDev/worlds/DesignHouse/_user/xiaoyao/object-detect/images/train_data/2.png", true));
    print_predict_results(net:Predict("D:/workspace/program/ParacraftDev/worlds/DesignHouse/_user/xiaoyao/object-detect/images/train_data/3.png", true));
    print_predict_results(net:Predict("D:/workspace/program/ParacraftDev/worlds/DesignHouse/_user/xiaoyao/object-detect/images/train_data/4.png", true));
    print_predict_results(net:Predict("D:/workspace/program/ParacraftDev/worlds/DesignHouse/_user/xiaoyao/object-detect/images/train_data/5.png", true));
    print_predict_results(net:Predict("D:/workspace/program/ParacraftDev/worlds/DesignHouse/_user/xiaoyao/object-detect/images/train_data/6.png", true));
end

function test_darknet()
    local net = DarkNet:new():Init();
    net:Load("D:/workspace/cpp/darknet/data/yolo/models/model.lastest");
    print(net:Predict("D:/workspace/program/ParacraftDev/worlds/DesignHouse/_user/xiaoyao/object-detect/images/train_data/6.png", true))
end

test_darknet();