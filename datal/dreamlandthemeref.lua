local _keys = {refId=1,name=2,pattern=3,patternName=4,roleRes=5,pic=6,battleScene=7,platform=8,platformEffect=9,endEvent=10,reward=11}
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
[1]=_set({1,"dreamlandtheme_0_1",1,"dreamlandtheme_1_1","XR_Tuzi01","wonderLand_bg_big_1",1003,"fx_ui_aiyu_heye_idle,fx_ui_aiyu_heye_die","",2201,""},_mt),
[2]=_set({2,"dreamlandtheme_0_2",2,"dreamlandtheme_1_2","XR_Tuzi01","wonderLand_bg_big_1",1003,"fx_ui_aiyu_heye_idle,fx_ui_aiyu_heye_die","",2201,""},_mt),
[3]=_set({3,"dreamlandtheme_0_3",3,"dreamlandtheme_1_3","XR_Tuzi01","wonderLand_bg_big_1",1003,"fx_ui_aiyu_heye_idle,fx_ui_aiyu_heye_die","",2201,""},_mt)
}

return _datas