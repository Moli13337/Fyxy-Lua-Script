local _keys = {refId=1,quality=2,sort=3,icon=4,heroType=5,desc=6,effect=7}
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
[1]=_set({1,2,6,"hero_txt_quality_2",0,"characterqualitydesc_0_1","characterqualitydesc_1_1"},_mt),
[2]=_set({2,3,5,"hero_txt_quality_3",0,"characterqualitydesc_0_2","characterqualitydesc_1_2"},_mt),
[3]=_set({3,4,4,"hero_txt_quality_4",0,"characterqualitydesc_0_3","characterqualitydesc_1_3"},_mt),
[4]=_set({4,5,3,"hero_txt_quality_5",0,"characterqualitydesc_0_4","characterqualitydesc_1_4"},_mt),
[5]=_set({5,6,2,"hero_txt_quality_6",0,"characterqualitydesc_0_5","characterqualitydesc_1_5"},_mt),
[6]=_set({6,7,1,"hero_txt_quality_7",0,"characterqualitydesc_0_6","characterqualitydesc_1_6"},_mt),
[7]=_set({7,8,0,"hero_txt_quality_8",1,"characterqualitydesc_0_7","characterqualitydesc_1_7"},_mt)
}

return _datas