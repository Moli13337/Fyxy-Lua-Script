local _keys = {refId=1,type=2,name=3,lv=4,Desc=5,addAttrSkill=6,skillRound=7,eliminatedmobs=8}
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
[2]=_set({2,2,"clanwarbuff_0_2","Lv.1","clanwarbuff_1_2",160002,0,2},_mt),
[3]=_set({3,2,"clanwarbuff_0_3","Lv.2","clanwarbuff_1_3",160003,0,4},_mt),
[4]=_set({4,2,"clanwarbuff_0_4","Lv.3","clanwarbuff_1_4",160004,0,6},_mt),
[5]=_set({5,2,"clanwarbuff_0_5","Lv.4","clanwarbuff_1_5",160005,0,8},_mt),
[6]=_set({6,2,"clanwarbuff_0_6","Lv.5","clanwarbuff_1_6",160006,0,10},_mt),
[7]=_set({7,2,"clanwarbuff_0_7","Lv.6","clanwarbuff_1_7",160007,0,12},_mt),
[8]=_set({8,2,"clanwarbuff_0_8","Lv.7","clanwarbuff_1_8",160008,0,14},_mt),
[9]=_set({9,2,"clanwarbuff_0_9","Lv.8","clanwarbuff_1_9",160009,0,16},_mt),
[10]=_set({10,2,"clanwarbuff_0_10","Lv.9","clanwarbuff_1_10",160010,0,18},_mt),
[11]=_set({11,2,"clanwarbuff_0_11","Lv.10","clanwarbuff_1_11",160011,0,20},_mt)
}

return _datas