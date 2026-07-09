local _keys = {refId=1,type=2,grad=3,gradReward=4}
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
[1]=_set({1,0,5,"1=1900011=200=0"},_mt),
[2]=_set({2,0,10,"1=1900011=600=0"},_mt),
[3]=_set({3,0,20,"1=1930001=1=0"},_mt),
[4]=_set({4,0,30,"1=1930001=2=0"},_mt),
[5]=_set({5,1,5,"1=1900011=400=0"},_mt),
[6]=_set({6,1,10,"1=1900011=800=0"},_mt),
[7]=_set({7,1,20,"1=1930002=1=0"},_mt),
[8]=_set({8,1,30,"1=1930002=2=0"},_mt)
}

return _datas