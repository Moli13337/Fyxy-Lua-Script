local _keys = {refId=1,name=2,type=3,condition=4,nextSkin=5,range=6,previewPicture=7,showIcon=8,description=9,typeShow=10,item=11,time=12,prefab=13,soundName=14,spine=15,effect=16}
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
[1001]=_set({1001,"castleskin_0_1001",101,"1=22",1002,1,"cityskin_icon_1001","main_city_bg_big_1","castleskin_1_1001",1,"",0,"MapCity","SoundM_1","",""},_mt),
[1002]=_set({1002,"castleskin_0_1002",101,"1=7",1001,2,"cityskin_icon_1001","main_city_bg_big_2","",0,"",0,"MapCity","SoundM_1","",""},_mt),
[1003]=_set({1003,"castleskin_0_1003",102,"",0,3,"cityskin_icon_1001","main_city_bg_big_3","",0,"1=2600001=1",0,"MapCity","SoundM_1","",""},_mt),
[1004]=_set({1004,"castleskin_0_1004",103,"",0,4,"cityskin_icon_1001","main_city_bg_big_4","",1,"1=2600002=1",0,"MapCity","SoundM_1","","fx_ui_shengdanjie_xuehua"},_mt),
[1005]=_set({1005,"castleskin_0_1005",104,"",0,5,"cityskin_icon_1001","main_city_bg_big_5","",1,"1=2600003=1",0,"MapCity","SoundM_1","","fx_zhucheng_chunjie"},_mt),
[1006]=_set({1006,"castleskin_0_1006",105,"",0,6,"cityskin_icon_1001","main_city_bg_big_6","",1,"1=2600004=1",0,"MapCity","SoundM_1","","fx_zhucheng_xiari_1"},_mt),
[1008]=_set({1008,"castleskin_0_1008",107,"",0,8,"cityskin_icon_1001","main_city_bg_big_8","",1,"1=2600006=1",0,"MapCity","SoundM_1","","fx_zhucheng_yinghuahai"},_mt)
}

return _datas