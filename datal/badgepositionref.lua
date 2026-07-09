local _keys = {refId=1,page=2,star=3}
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
[1]=_set({1,1,"1=6"},_mt),
[2]=_set({2,1,"1=6"},_mt),
[3]=_set({3,1,"1=8"},_mt),
[4]=_set({4,1,"1=9"},_mt),
[5]=_set({5,1,"1=10"},_mt),
[6]=_set({6,1,"1=11"},_mt),
[7]=_set({7,1,"1=12"},_mt),
[8]=_set({8,1,"1=13"},_mt)
}

return _datas