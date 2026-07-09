local _keys = {refId=1,name=2,type=3,num=4,lock=5,sort=6,sortType=7,filterType=8}
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
[1001]=_set({1001,"mediatype_0_1001",1,20,0,2,1,1000},_mt),
[1002]=_set({1002,"mediatype_0_1002",1,20,0,1,2,1000},_mt),
[1003]=_set({1003,"mediatype_0_1003",1,20,12900000,10,1,1001},_mt),
[1004]=_set({1004,"mediatype_0_1004",1,20,13100000,3,1,1006},_mt),
[1005]=_set({1005,"mediatype_0_1005",1,63,13200000,12,1,1003},_mt),
[1006]=_set({1006,"mediatype_0_1006",1,20,12106000,6,1,1004},_mt),
[1009]=_set({1009,"mediatype_0_1009",2,20,13600000,11,1,1000},_mt),
[1011]=_set({1011,"mediatype_0_1011",1,20,13800000,7,1,1001},_mt),
[1012]=_set({1012,"mediatype_0_1012",1,20,13900000,8,1,1001},_mt),
[1013]=_set({1013,"mediatype_0_1013",1,20,12111000,9,1,1001},_mt)
}

return _datas