local _keys = {refId=1,type=2,their=3,txt=4,open=5}
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
[1001]=_set({1001,1,1,"chattingset_0_1001",1},_mt),
[1002]=_set({1002,2,2,"chattingset_0_1002",1},_mt),
[1003]=_set({1003,3,2,"chattingset_0_1003",1},_mt),
[1004]=_set({1004,4,2,"chattingset_0_1004",1},_mt),
[1005]=_set({1005,5,2,"chattingset_0_1005",1},_mt),
[1007]=_set({1007,7,3,"chattingset_0_1007",1},_mt),
[1008]=_set({1008,8,4,"chattingset_0_1008",0},_mt),
[1009]=_set({1009,9,4,"chattingset_0_1009",1},_mt),
[1010]=_set({1010,10,4,"chattingset_0_1010",1},_mt),
[1012]=_set({1012,12,4,"chattingset_0_1012",1},_mt),
[1013]=_set({1013,13,4,"chattingset_0_1013",1},_mt),
[1014]=_set({1014,14,4,"chattingset_0_1014",1},_mt),
[2001]=_set({2001,15,5,"chattingset_0_2001",0},_mt),
[2002]=_set({2002,16,5,"chattingset_0_2002",0},_mt),
[3001]=_set({3001,18,6,"chattingset_0_3001",1},_mt)
}

return _datas