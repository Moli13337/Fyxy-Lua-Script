local _keys = {refId=1,job=2,pos=3,icon=4,iconBg=5}
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
[101]=_set({101,1,"1","guild_skill_icon_2","guild_skill_btn_2"},_mt),
[102]=_set({102,1,"2","guild_skill_icon_1","guild_skill_btn_2"},_mt),
[103]=_set({103,1,"3","guild_skill_icon_4","guild_skill_btn_2"},_mt),
[104]=_set({104,1,"4","guild_skill_icon_5","guild_skill_btn_2"},_mt),
[105]=_set({105,1,"5","guild_skill_icon_3","guild_skill_btn_2"},_mt),
[106]=_set({106,1,"6","guild_skill_icon_6","guild_skill_btn_2"},_mt),
[201]=_set({201,2,"1","guild_skill_icon_2","guild_skill_btn_1"},_mt),
[202]=_set({202,2,"2","guild_skill_icon_1","guild_skill_btn_1"},_mt),
[203]=_set({203,2,"3","guild_skill_icon_4","guild_skill_btn_1"},_mt),
[204]=_set({204,2,"4","guild_skill_icon_5","guild_skill_btn_1"},_mt),
[205]=_set({205,2,"5","guild_skill_icon_3","guild_skill_btn_1"},_mt),
[206]=_set({206,2,"6","guild_skill_icon_6","guild_skill_btn_1"},_mt),
[301]=_set({301,3,"1","guild_skill_icon_2","guild_skill_btn_3"},_mt),
[302]=_set({302,3,"2","guild_skill_icon_1","guild_skill_btn_3"},_mt),
[303]=_set({303,3,"3","guild_skill_icon_9","guild_skill_btn_3"},_mt),
[304]=_set({304,3,"4","guild_skill_icon_8","guild_skill_btn_3"},_mt),
[305]=_set({305,3,"5","guild_skill_icon_3","guild_skill_btn_3"},_mt),
[306]=_set({306,3,"6","guild_skill_icon_10","guild_skill_btn_3"},_mt),
[401]=_set({401,4,"1","guild_skill_icon_2","guild_skill_btn_4"},_mt),
[402]=_set({402,4,"2","guild_skill_icon_1","guild_skill_btn_4"},_mt),
[403]=_set({403,4,"3","guild_skill_icon_9","guild_skill_btn_4"},_mt),
[404]=_set({404,4,"4","guild_skill_icon_8","guild_skill_btn_4"},_mt),
[405]=_set({405,4,"5","guild_skill_icon_3","guild_skill_btn_4"},_mt),
[406]=_set({406,4,"6","guild_skill_icon_7","guild_skill_btn_4"},_mt)
}

return _datas