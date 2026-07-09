local _keys = {refId=1,level=2,exp=3}
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
[1001]=_set({1001,1,50},_mt),
[1002]=_set({1002,2,100},_mt),
[1003]=_set({1003,3,150},_mt),
[1004]=_set({1004,4,250},_mt),
[1005]=_set({1005,5,350},_mt),
[1006]=_set({1006,6,470},_mt),
[1007]=_set({1007,7,590},_mt),
[1008]=_set({1008,8,710},_mt),
[1009]=_set({1009,9,850},_mt),
[1010]=_set({1010,10,990},_mt),
[1011]=_set({1011,11,1130},_mt),
[1012]=_set({1012,12,1290},_mt),
[1013]=_set({1013,13,1450},_mt),
[1014]=_set({1014,14,1610},_mt),
[1015]=_set({1015,15,1790},_mt),
[1016]=_set({1016,16,1970},_mt),
[1017]=_set({1017,17,2150},_mt),
[1018]=_set({1018,18,2350},_mt),
[1019]=_set({1019,19,2550},_mt),
[1020]=_set({1020,20,2750},_mt)
}

return _datas