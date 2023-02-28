# 神通杯

```lua
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");

-- 赛事报名
Page.Show(nil, {
    draggable = false,
    fixedRootScreenWidth = 1280, fixedRootScreenHeight = 720,
    url = "%ui%/App/RedSummerCamp/Competition.html", 
});

-- 赛事章程
Page.Show(nil, {
    draggable = false,
    fixedRootScreenWidth = 1280, fixedRootScreenHeight = 720,
    url = "%ui%/App/RedSummerCamp/Constitution.html", 
});

-- 赛事课程
Page.Show(nil, {
    draggable = false,
    fixedRootScreenWidth = 1280, fixedRootScreenHeight = 720,
    url = "%ui%/App/RedSummerCamp/Course.html",
});

-- 赛事资质
Page.Show(nil, {
    draggable = false,
    fixedRootScreenWidth = 1280, fixedRootScreenHeight = 720,
    url = "%ui%/App/RedSummerCamp/Qualification.html", 
});

-- fixedRootScreenWidth = 1280, fixedRootScreenHeight = 720, 为自动缩放基准值, 不填不自动缩放
```
