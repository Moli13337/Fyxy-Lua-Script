local _keys = {refId=1,type=2,text=3}
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
[1001]=_set({1001,1,"storedesctext_0_1001"},_mt),
[1002]=_set({1002,1,"storedesctext_0_1002"},_mt),
[1003]=_set({1003,1,"storedesctext_0_1003"},_mt),
[1004]=_set({1004,1,"storedesctext_0_1004"},_mt)
}

return _datas