
# Sandbox

```lua
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCode.lua");
local EntityCode = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCode")
local entityCode = EntityCode:new({item_id = 219, bx = 0,by = 0, bz = 0});
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlock.lua");
local CodeBlock = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlock");
local codeBlock = CodeBlock:new():Init(entityCode);
entity:SetCommand('print(1)');
codeBlock:Run();
```
