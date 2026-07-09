local _keys = {refId=1,name=2,time=3,map=4,leading=5,leadingType=6,pic=7,platform=8,platformEffect=9,battleScene=10,cameraScope=11,initialPtion=12,count=13,endPlatform=14,endEvent=15,open=16,themeTips=17,dice=18}
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
[1]=_set({1,"sailingmap_0_1","2,4","108=100","XR_Shayu01","3","MapDT_1","MapDT_ui_1;MapDT_ui_1_on","effect_mjzl_gezi_1;effect_mjzl_gezi_2;effect_mjzl4_gezi_daoda;effect_mjzl4_gezi_jingguo;effect_mjzl4_yidong",1005,"-6.40,6.40;-7.1,7.1","0,-4",51,50,2301,1,77,1},_mt),
[2]=_set({2,"sailingmap_0_2","6","1009=100","XR_Shayu01","3","MapDT_2","MapDT_ui_2;MapDT_ui_2_on","effect_mjzl2_gezi_1;effect_mjzl2_gezi_2;effect_mjzl2_gezi_daoda;effect_mjzl2_gezi_jingguo;effect_mjzl2_yidong",1002,"-6.40,6.40;-7.1,7.1","0,-4",41,40,22301,1,77,2},_mt)
}

return _datas