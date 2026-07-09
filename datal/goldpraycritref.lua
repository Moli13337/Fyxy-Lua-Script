local _keys = {refId=1,type=2,buyNumSection=3,critSection=4}
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
[1001]=_set({1001,1,"0,999","1,1.2"},_mt),
[2001]=_set({2001,2,"0,999","1,1.5"},_mt),
[3001]=_set({3001,3,"0,999","1,2"},_mt)
}

return _datas