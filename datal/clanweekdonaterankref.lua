local _keys = {refId=1,rank=2,reward=3}
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
[1]=_set({1,"1,1","1=108202=1000=0"},_mt),
[2]=_set({2,"2,2","1=108202=900=0"},_mt),
[3]=_set({3,"3,3","1=108202=800=0"},_mt),
[4]=_set({4,"4,5","1=108202=700=0"},_mt),
[5]=_set({5,"6,10","1=108202=600=0"},_mt),
[6]=_set({6,"11,25","1=108202=550=0"},_mt),
[7]=_set({7,"26,50","1=108202=500=0"},_mt)
}

return _datas