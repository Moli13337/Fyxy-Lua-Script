local _keys = {refId=1,min=2,max=3,expend=4}
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
[1]=_set({1,0,600,"1=102001=10"},_mt),
[2]=_set({2,601,3600,"1=102001=50"},_mt),
[3]=_set({3,3601,7200,"1=102001=60"},_mt),
[4]=_set({4,7201,14400,"1=102001=70"},_mt),
[5]=_set({5,14401,21600,"1=102001=80"},_mt),
[6]=_set({6,21601,28800,"1=102001=90"},_mt),
[7]=_set({7,28801,999999,"1=102001=100"},_mt)
}

return _datas