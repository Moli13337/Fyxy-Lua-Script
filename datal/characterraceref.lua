local _keys = {refId=1,name=2,rank=3,restrainDetails=4,restrainDetailsEff=5,icon=6,heroBg=7,heroBookScreenBg=8,heroRaceImage=9,heroShareBg=10,treasureRaceShow=11}
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
[1]=_set({1,"characterrace_0_1",3,"2","204=1=0.25,103=1=0.2","public_race_icon_1","hero_bg_big_1","","hero_txt_3","core_bg_race_1",0},_mt),
[2]=_set({2,"characterrace_0_2",4,"3","204=1=0.25,103=1=0.2","public_race_icon_2","hero_bg_big_2","","hero_txt_3","core_bg_race_2",0},_mt),
[3]=_set({3,"characterrace_0_3",5,"1","204=1=0.25,103=1=0.2","public_race_icon_3","hero_bg_big_3","","hero_txt_3","core_bg_race_3",0},_mt),
[4]=_set({4,"characterrace_0_4",1,"5","204=1=0.25,103=1=0.2","public_race_icon_4","hero_bg_big_4","","hero_txt_6","core_bg_race_4",0},_mt),
[5]=_set({5,"characterrace_0_5",2,"4","204=1=0.25,103=1=0.2","public_race_icon_5","hero_bg_big_5","","hero_txt_6","core_bg_race_5",0},_mt),
[6]=_set({6,"characterrace_0_6",6,"","","public_race_icon_6","hero_bg_big_5","","","core_bg_race_5",0},_mt)
}

return _datas