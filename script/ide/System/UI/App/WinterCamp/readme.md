冬奥会主世界：        (开发版：114607)   rls环境：待上传
程序课程Demo世界：     (开发版：114611)  rls环境：待上传

用户登录后先调一下11000这个兑换，就可以获得40008物品，之前的记录物品是这样获取的
夏令营世界ID: 70351

local clientData = KeepWorkItemManager.GetClientData(gsid) or {};
KeepWorkItemManager.SetClientData(gsid, clientData, function()
    ActRedhat.ShowPage();
end);

character/common/headarrow/headarrow.x"

character/CC/05effect/fireglowingcircle.x

## TODO

[ ] 冬令营
[ ] win10 触屏无法点击
[ ] 局域网活动模型同步


local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");

Page.ShowVueTestPage(nil, {width = 1024, height = 600, url = "%ui%/App/WinterCamp/CoursePanel.html"})