--[[
Author: gosling
Date: 2010-07-29
Desc: testing deleting old cache files not in asset_manifest.txt
-----------------------------------------------
NPL.load("(gl)script/test/TestCleanCache.lua");
-----------------------------------------------
]]

local manifest_md5 = {};

function LoadManifest()
	local line;
	local file = ParaIO.open("Assets_manifest.txt", "r");
	if(file:IsValid()) then
		line=file:readline();
		while line~=nil do 
				--commonlib.echo(line);
			local __,__,__, md5,_= string.find(line,"(.+),(.+),(.+)");
			if(md5) then
				--commonlib.echo(md5);
				manifest_md5[md5] = true;
			end
			line=file:readline();
		end
		file:close();
	end
end

function CleanOldCache()
	local files = {};
	commonlib.SearchFiles(files, "temp/cache/", "*", 0, 20000, true);
	--commonlib.echo(files);
	LoadManifest();
	local i=0;
	local count = 0;
	for i = 1, #files do 
		--commonlib.echo(files[i]);
		md5 = string.sub(files[i],1,32);
		if(manifest_md5[md5]) then
			log("useful file:\n");
			commonlib.echo(md5);
		else
			log("need clean:\n");
			commonlib.echo(files[i]);
			ParaIO.DeleteFile(files[i]);
			count = count + 1;
			if(count > 300) then
				break
			end
		end
	end
end


CleanOldCache();

