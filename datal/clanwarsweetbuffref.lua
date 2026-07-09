local _keys = {refId=1,type=2,level=3,count=4,name=5,desc=6,addAttrSkill=7,icon=8}
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
[1]=_set({1,2,0,0,"clanwarsweetbuff_0_1","clanwarsweetbuff_1_1",0,0},_mt),
[2]=_set({2,2,1,1,"clanwarsweetbuff_0_2","clanwarsweetbuff_1_2",160002,0},_mt),
[3]=_set({3,2,2,2,"clanwarsweetbuff_0_3","clanwarsweetbuff_1_3",160003,0},_mt),
[4]=_set({4,2,3,3,"clanwarsweetbuff_0_4","clanwarsweetbuff_1_4",160004,0},_mt),
[5]=_set({5,2,4,4,"clanwarsweetbuff_0_5","clanwarsweetbuff_1_5",160005,0},_mt),
[6]=_set({6,2,5,5,"clanwarsweetbuff_0_6","clanwarsweetbuff_1_6",160006,0},_mt),
[7]=_set({7,2,6,6,"clanwarsweetbuff_0_7","clanwarsweetbuff_1_7",160007,0},_mt),
[8]=_set({8,2,7,7,"clanwarsweetbuff_0_8","clanwarsweetbuff_1_8",160008,0},_mt),
[9]=_set({9,2,8,8,"clanwarsweetbuff_0_9","clanwarsweetbuff_1_9",160009,0},_mt),
[10]=_set({10,2,9,9,"clanwarsweetbuff_0_10","clanwarsweetbuff_1_10",160010,0},_mt),
[11]=_set({11,2,10,10,"clanwarsweetbuff_0_11","clanwarsweetbuff_1_11",160011,0},_mt)
}

return _datas