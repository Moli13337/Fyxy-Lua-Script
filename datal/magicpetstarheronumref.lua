local _keys = {refId=1,num=2}
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
[1]=_set({1,0},_mt),
[2]=_set({2,10},_mt),
[3]=_set({3,20},_mt),
[4]=_set({4,30},_mt)
}

return _datas