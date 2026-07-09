local _keys = {refId=1,sort=2,name=3}
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
[1]=_set({1,1,"growthconfig_0_1"},_mt),
[2]=_set({2,2,"growthconfig_0_2"},_mt),
[3]=_set({3,3,"growthconfig_0_3"},_mt)
}

return _datas