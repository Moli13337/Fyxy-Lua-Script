local _keys = {refId=1,name=2}
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
[101]=_set({101,"MapBattle1002"},_mt),
[1001]=_set({1001,"MapBattle1001"},_mt),
[1002]=_set({1002,"MapBattle1002"},_mt),
[1003]=_set({1003,"MapBattle1003"},_mt),
[1004]=_set({1004,"MapBattle1004"},_mt),
[1005]=_set({1005,"MapBattle1005"},_mt),
[1006]=_set({1006,"MapBattle1007"},_mt),
[2001]=_set({2001,"MapBattle1006"},_mt),
[3001]=_set({3001,"MapBattle1002"},_mt),
[3002]=_set({3002,"MapBattle1002"},_mt),
[4001]=_set({4001,"MapBattle1006"},_mt),
[4002]=_set({4002,"MapBattle1006"},_mt)
}

return _datas