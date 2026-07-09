local _keys = {refId=1,sort=2,finishCond=3,box=4,reward=5}
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
[1]=_set({1,1,50,"guild_box1,guild_box1_1","1=108202=100=0,1=101001=5000=0"},_mt),
[2]=_set({2,2,100,"guild_box2,guild_box2_1","1=108202=100=0,1=101001=10000=0"},_mt),
[3]=_set({3,3,300,"guild_box3,guild_box3_1","1=108202=200=0,1=101001=15000=0"},_mt),
[4]=_set({4,4,500,"guild_box4,guild_box4_1","1=108202=200=0,1=101001=20000=0"},_mt)
}

return _datas