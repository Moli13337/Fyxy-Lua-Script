local _keys = {refId=1,name=2,hero=3,icon=4,campIconEff=5,group=6,sort=7}
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
[1]=_set({1,"battlecamp_0_1",1,"public_race_icon_1","fx_ui_zhenying_buff_water",1,"1"},_mt),
[2]=_set({2,"battlecamp_0_2",2,"public_race_icon_2","fx_ui_zhenying_buff_fire",2,"2"},_mt),
[3]=_set({3,"battlecamp_0_3",3,"public_race_icon_3","fx_ui_zhenying_buff_wind",3,"3"},_mt),
[4]=_set({4,"battlecamp_0_4",4,"public_race_icon_4","fx_ui_zhenying_buff_light",4,"4"},_mt),
[5]=_set({5,"battlecamp_0_5",5,"public_race_icon_5","fx_ui_zhenying_buff_dark",5,"5"},_mt),
[7]=_set({7,"battlecamp_0_7",6,"public_race_icon_6","fx_ui_zhenying_buff_dark",7,"6"},_mt)
}

return _datas