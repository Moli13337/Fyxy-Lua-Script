local _keys = {refId=1,round=2,monstet=3,noticeHurt=4,attrAddType=5}
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
[1001]=_set({1001,1,90001,999000000,1},_mt),
[2001]=_set({2001,2,90002,999000000,2},_mt),
[3001]=_set({3001,3,90003,999000000,3},_mt),
[4001]=_set({4001,4,90004,999000000,4},_mt)
}

return _datas