local _keys = {refId=1,path=2,default=3,music=4,spring=5,sea=6,halloween=7,fantasy=8}
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
[1]=_set({1,"Root","","","","root=MapCity2","root=MapCity3","root=MapCity4"},_mt),
[2]=_set({2,"LayerRoot/BuildingLayer/Layer2/adcard","","spine=fx_zhucheng_guanggaopai","","","",""},_mt),
[3]=_set({3,"LayerRoot/BuildingLayer/Layer2/adcard/BuildingAdCard","enable=1","enable=0","enable=1","enable=1","enable=1","enable=1"},_mt),
[4]=_set({4,"LayerRoot/BuildingLayer/Layer2/pengquan/spine","","spine=fx_zhucheng_penquandeng","","","",""},_mt),
[5]=_set({5,"LayerRoot/BuildingLayer/Layer2/musictheme/spine1","","spine=Baimawangzi7|music","","","",""},_mt),
[6]=_set({6,"LayerRoot/BuildingLayer/Layer2/musictheme/spine2","","spine=Xiaohongmao7|music","","","",""},_mt),
[7]=_set({7,"LayerRoot/BuildingLayer/Layer2/musictheme/spine3","","spine=Shendeng7|music","","","",""},_mt),
[8]=_set({8,"LayerRoot/BuildingLayer/Layer2/musictheme/spine4","","spine=Hailuogongzhu7|music","","","",""},_mt),
[9]=_set({9,"LayerRoot/BuildingLayer/Layer2/musictheme/spine5","","spine=Fengwaipo7|music","","","",""},_mt),
[10]=_set({10,"LayerRoot/BuildingLayer/Layer2/musictheme/eff1","","spine=fx_baimawangzi7_music|animation","","","",""},_mt),
[11]=_set({11,"LayerRoot/BuildingLayer/Layer2/musictheme/eff2","","spine=fx_xiaohongmao7_music|animation","","","",""},_mt),
[12]=_set({12,"LayerRoot/BuildingLayer/Layer2/musictheme/eff3","","spine=fx_shendeng7_music|animation","","","",""},_mt),
[13]=_set({13,"LayerRoot/BuildingLayer/Layer2/musictheme/eff4","","spine=fx_hailuogongzhu7_music|animation","","","",""},_mt),
[14]=_set({14,"LayerRoot/BuildingLayer/Layer2/musictheme/eff5","","spine=fx_fengwaipo7_music|animation","","","",""},_mt),
[15]=_set({15,"LayerRoot/EffectLayer/Layer2/music","","eff=fx_zc_yanhua","eff=fx_zc_chunjie_yanhua","","","eff=fx_zc_yanhua"},_mt)
}

return _datas