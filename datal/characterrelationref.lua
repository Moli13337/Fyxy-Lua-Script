local _keys = {refId=1,name=2,bgList=3,bgSelf=4,relationHero=5,relationHeroNum=6,listPrefabName=7,selfPrefabName=8,reward=9,attrType=10,relationStory=11}
local _mt = {
    __index = function(t, k)
        local idx = _keys[k]
        if not idx then return nil end
        return rawget(t, idx)
    end,
    __newindex = function(t, k)
    end
}
local _set = setmetatable
local _datas = {
[1001]=_set({1001,"characterrelation_0_1001","","","1701",1,"","","1=102001=200=0",1,""},_mt)
}

return _datas