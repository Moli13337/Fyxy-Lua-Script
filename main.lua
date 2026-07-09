--保存刚开始的lua环境
local initG, initLoaded, initPreload
initG = {}
for k,v in pairs(_G) do
    initG[k] = true
end

initLoaded = {}
for k,v in pairs(package.loaded) do
    initLoaded[k] = true
end

initPreload = {}
for k,v in pairs(package.preload) do
    initPreload[k] = true
end

require("LApp.LxLauncher").Launcher({ initG = initG, initLoaded = initLoaded, initPreLoad = initPreload})