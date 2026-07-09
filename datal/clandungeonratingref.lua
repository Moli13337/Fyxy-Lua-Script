local _keys = {refId=1,name=2,interval=3,sort=4,ratingIcon=5}
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
[1]=_set({1,"clandungeonrating_0_1","-9999,51",1,"guilddungeon_icon_E"},_mt),
[2]=_set({2,"clandungeonrating_0_2","51,76",2,"guilddungeon_icon_D"},_mt),
[3]=_set({3,"clandungeonrating_0_3","76,101",3,"guilddungeon_icon_C"},_mt),
[4]=_set({4,"clandungeonrating_0_4","101,126",4,"guilddungeon_icon_B"},_mt),
[5]=_set({5,"clandungeonrating_0_5","126,151",5,"guilddungeon_icon_A"},_mt),
[6]=_set({6,"clandungeonrating_0_6","151,176",6,"guilddungeon_icon_S"},_mt),
[7]=_set({7,"clandungeonrating_0_7","176,221",7,"guilddungeon_icon_SS"},_mt),
[8]=_set({8,"clandungeonrating_0_8","221,9999",8,"guilddungeon_icon_SSS"},_mt)
}

return _datas