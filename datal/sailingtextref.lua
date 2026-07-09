local _keys = {refId=1,dec=2}
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
[10001]=_set({10001,"sailingtext_0_10001"},_mt),
[10002]=_set({10002,"sailingtext_0_10002"},_mt),
[10003]=_set({10003,"sailingtext_0_10003"},_mt),
[10004]=_set({10004,"sailingtext_0_10004"},_mt),
[10005]=_set({10005,"sailingtext_0_10005"},_mt),
[10006]=_set({10006,"sailingtext_0_10006"},_mt),
[20001]=_set({20001,"sailingtext_0_20001"},_mt),
[20002]=_set({20002,"sailingtext_0_20002"},_mt),
[20003]=_set({20003,"sailingtext_0_20003"},_mt),
[20004]=_set({20004,"sailingtext_0_20004"},_mt),
[20005]=_set({20005,"sailingtext_0_20005"},_mt),
[20006]=_set({20006,"sailingtext_0_20006"},_mt)
}

return _datas