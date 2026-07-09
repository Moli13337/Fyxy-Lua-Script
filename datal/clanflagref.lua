local _keys = {refId=1,type=2,res=3,color=4}
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
[1001]=_set({1001,1,"guild_ad_bg_1","guild_flag1"},_mt),
[1002]=_set({1002,1,"guild_ad_bg_2","guild_flag2"},_mt),
[1003]=_set({1003,1,"guild_ad_bg_3","guild_flag3"},_mt),
[1004]=_set({1004,1,"guild_ad_bg_4","guild_flag4"},_mt),
[1005]=_set({1005,1,"guild_ad_bg_5","guild_flag5"},_mt),
[1006]=_set({1006,1,"guild_ad_bg_6","guild_flag6"},_mt),
[1007]=_set({1007,1,"guild_ad_bg_7","guild_flag7"},_mt),
[1008]=_set({1008,1,"guild_ad_bg_8","guild_flag8"},_mt),
[2001]=_set({2001,2,"guild_ad_icon_1",""},_mt),
[2002]=_set({2002,2,"guild_ad_icon_2",""},_mt),
[2003]=_set({2003,2,"guild_ad_icon_3",""},_mt),
[2004]=_set({2004,2,"guild_ad_icon_4",""},_mt),
[2005]=_set({2005,2,"guild_ad_icon_5",""},_mt),
[2006]=_set({2006,2,"guild_ad_icon_6",""},_mt),
[2007]=_set({2007,2,"guild_ad_icon_7",""},_mt),
[2008]=_set({2008,2,"guild_ad_icon_8",""},_mt),
[2009]=_set({2009,2,"guild_ad_icon_9",""},_mt)
}

return _datas