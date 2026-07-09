local _keys = {refId=1,imageType=2,scaling=3,image=4,sound=5,coord=6}
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
[10000]=_set({10000,2,1.4,"black","SoundM_3","0,0"},_mt),
[10001]=_set({10001,2,1.4,"story_bg_big_42","SoundM_6","0,0"},_mt),
[10010]=_set({10010,1,1,"fx_juqing_huiyi","","0,0"},_mt),
[10011]=_set({10011,1,1,"fx_juqing_aixinquanping","","0,0"},_mt),
[10012]=_set({10012,1,1,"fx_ui_shou_4","","0,0"},_mt),
[10013]=_set({10013,1,1,"fx_juqing_huiyi_2","","0,0"},_mt),
[10020]=_set({10020,3,1,"LH_Tuzi03","","0,0"},_mt),
[10021]=_set({10021,3,1,"LH_Shayu01","","0,0"},_mt),
[10022]=_set({10022,3,1,"LH_Hudie01","","0,0"},_mt),
[10023]=_set({10023,2,1.4,"black","","0,0"},_mt),
[10024]=_set({10024,2,1.4,"black","","0,0"},_mt),
[10040]=_set({10040,1,1,"huiyizhuanchang","","0,0"},_mt),
[10041]=_set({10041,1,1,"fx_juqing_chongtu","","0,0"},_mt),
[10042]=_set({10042,1,1,"fx_juqing_zhengyanzhuanchang","","0,0"},_mt),
[20000]=_set({20000,1,1,"fx_juqing_huiyi","","0,0"},_mt),
[20010]=_set({20010,1,1,"huiyizhuanchang","","0,0"},_mt),
[20020]=_set({20020,3,1,"LH_Munaiyi01","","0,0"},_mt),
[20030]=_set({20030,2,1.4,"hero_bg_big_5","","0,0"},_mt),
[20040]=_set({20040,2,1.4,"map_combat_2","SoundM_6","0,0"},_mt),
[22000]=_set({22000,1,1,"fx_juqing_huiyi","","0,0"},_mt),
[22010]=_set({22010,1,1,"huiyizhuanchang","","0,0"},_mt),
[22020]=_set({22020,3,1,"LH_Bailang01","","0,0"},_mt),
[22030]=_set({22030,2,1.4,"hero_bg_big_4","","0,0"},_mt),
[22040]=_set({22040,2,1.4,"map_combat_2","SoundM_6","0,0"},_mt),
[21000]=_set({21000,1,1,"fx_juqing_huiyi","","0,0"},_mt),
[21010]=_set({21010,1,1,"huiyizhuanchang","","0,0"},_mt),
[21020]=_set({21020,3,1,"LH_Huli01","","0,0"},_mt),
[21030]=_set({21030,2,1.4,"hero_bg_big_2","","0,0"},_mt),
[21040]=_set({21040,2,1.4,"map_combat_2","SoundM_6","0,0"},_mt),
[23000]=_set({23000,1,1,"fx_juqing_huiyi","","0,0"},_mt),
[23010]=_set({23010,1,1,"huiyizhuanchang","","0,0"},_mt),
[23020]=_set({23020,3,1,"LH_Daiyanjingshuijie01","","0,0"},_mt),
[23030]=_set({23030,2,1.4,"hero_bg_big_1","","0,0"},_mt),
[23040]=_set({23040,2,1.4,"map_combat_2","SoundM_6","0,0"},_mt),
[23500]=_set({23500,1,1,"fx_juqing_huiyi","","0,0"},_mt),
[23510]=_set({23510,1,1,"huiyizhuanchang","","0,0"},_mt),
[23520]=_set({23520,3,1,"LH_Daiyanjingshuijie01","","0,0"},_mt),
[23530]=_set({23530,2,1.4,"hero_bg_big_1","","0,0"},_mt),
[23540]=_set({23540,2,1.4,"map_combat_2","SoundM_6","0,0"},_mt),
[24000]=_set({24000,1,1,"fx_juqing_huiyi","","0,0"},_mt),
[24010]=_set({24010,1,1,"huiyizhuanchang","","0,0"},_mt),
[24020]=_set({24020,3,1,"LH_Baiquan01","","0,0"},_mt),
[24030]=_set({24030,2,1.4,"hero_bg_big_2","","0,0"},_mt),
[24040]=_set({24040,2,1.4,"map_combat_3","SoundM_6","0,0"},_mt),
[25000]=_set({25000,1,1,"fx_juqing_huiyi","","0,0"},_mt),
[25010]=_set({25010,1,1,"huiyizhuanchang","","0,0"},_mt),
[25020]=_set({25020,3,1,"LH_Chaiquan01","","0,0"},_mt),
[25030]=_set({25030,2,1.4,"hero_bg_big_2","","0,0"},_mt),
[25040]=_set({25040,2,1.4,"map_combat_3","SoundM_6","0,0"},_mt),
[26000]=_set({26000,1,1,"fx_juqing_huiyi","","0,0"},_mt),
[26010]=_set({26010,1,1,"huiyizhuanchang","","0,0"},_mt),
[26020]=_set({26020,3,1,"LH_Heishanyang01","","0,0"},_mt),
[26030]=_set({26030,2,1.4,"hero_bg_big_2","","0,0"},_mt),
[26040]=_set({26040,2,1.4,"map_combat_3","SoundM_6","0,0"},_mt),
[27000]=_set({27000,1,1,"fx_juqing_huiyi","","0,0"},_mt),
[27010]=_set({27010,1,1,"huiyizhuanchang","","0,0"},_mt),
[27020]=_set({27020,3,1,"LH_Renzhe01","","0,0"},_mt),
[27030]=_set({27030,2,1.4,"hero_bg_big_3","","0,0"},_mt),
[27040]=_set({27040,2,1.4,"map_combat_3","SoundM_6","0,0"},_mt),
[28000]=_set({28000,1,1,"fx_juqing_huiyi","","0,0"},_mt),
[28010]=_set({28010,1,1,"huiyizhuanchang","","0,0"},_mt),
[28020]=_set({28020,3,1,"LH_Anubisi01","","0,0"},_mt),
[28030]=_set({28030,2,1.4,"hero_bg_big_5","","0,0"},_mt),
[28040]=_set({28040,2,1.4,"map_combat_3","SoundM_6","0,0"},_mt)
}

return _datas