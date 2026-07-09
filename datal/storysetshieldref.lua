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
[10040]=_set({10040,1,1,"huiyizhuanchang","","0,0"},_mt),
[10041]=_set({10041,1,1,"fx_juqing_chongtu","","0,0"},_mt),
[10042]=_set({10042,1,1,"fx_juqing_zhengyanzhuanchang","","0,0"},_mt),
[20040]=_set({20040,2,1.4,"map_combat_2","SoundM_6","0,0"},_mt),
[22040]=_set({22040,2,1.4,"map_combat_2","SoundM_6","0,0"},_mt),
[21040]=_set({21040,2,1.4,"map_combat_2","SoundM_6","0,0"},_mt),
[23540]=_set({23540,2,1.4,"map_combat_2","SoundM_6","0,0"},_mt),
[24040]=_set({24040,2,1.4,"map_combat_3","SoundM_6","0,0"},_mt),
[25040]=_set({25040,2,1.4,"map_combat_3","SoundM_6","0,0"},_mt),
[26040]=_set({26040,2,1.4,"map_combat_3","SoundM_6","0,0"},_mt),
[27040]=_set({27040,2,1.4,"map_combat_3","SoundM_6","0,0"},_mt),
[28040]=_set({28040,2,1.4,"map_combat_3","SoundM_6","0,0"},_mt)
}

return _datas