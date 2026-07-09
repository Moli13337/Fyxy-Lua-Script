local _keys = {refId=1,time=2,timeReward=3,reward=4}
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
[1001]=_set({1001,10,3,"1=101001=30000"},_mt),
[1003]=_set({1003,1,1,"1=112008=500"},_mt),
[1004]=_set({1004,3,3,"1=101001=30000"},_mt),
[1005]=_set({1005,1,1,"1=112008=500"},_mt),
[2201]=_set({2201,10,3,"1=112003=50"},_mt),
[3001]=_set({3001,3,3,"1=101001=30000"},_mt)
}

return _datas