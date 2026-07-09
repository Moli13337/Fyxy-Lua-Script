local _keys = {refId=1,type=2,weight=3,beginType=4,begin=5}
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
[1002]=_set({1002,1,10000,2,1034},_mt)
}

return _datas