local _keys = {refId=1,titlePic=2,sort=3,sweepExpend=4,name=5,functionID=6,positiveName=7,negativeName=8,icon=9}
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
[1]=_set({1,"dungeondaily_ad_2",1,"1=102001=50,1=102001=50","dundailytype_0_1",12420000,"dungeondaily_txt_2_1","dungeondaily_txt_2","dungeondaily_icon_2"},_mt),
[2]=_set({2,"dungeondaily_ad_1",2,"1=102001=50,1=102001=50","dundailytype_0_2",12410000,"dungeondaily_txt_1_1","dungeondaily_txt_1","dungeondaily_icon_1"},_mt),
[3]=_set({3,"dungeondaily_ad_3",3,"1=102001=50,1=102001=50","dundailytype_0_3",12430000,"dungeondaily_txt_3_1","dungeondaily_txt_3","dungeondaily_icon_3"},_mt),
[4]=_set({4,"dungeondaily_ad_4",4,"1=102001=50,1=102001=50","dundailytype_0_4",12440000,"dungeondaily_txt_4_1","dungeondaily_txt_4","dungeondaily_icon_4"},_mt)
}

return _datas