local _keys = {refId=1,timeMix=2,timeMax=3,value=4}
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
[1]=_set({1,1,7200,"30,30"},_mt),
[2]=_set({2,7201,14400,"20,20"},_mt),
[3]=_set({3,14401,21600,"15,15"},_mt),
[4]=_set({4,21601,25200,"12,12"},_mt),
[5]=_set({5,25201,-1,"10,10"},_mt)
}

return _datas