local _keys = {refId=1,jobType=2,name=3,sort=4,tabIcon=5,icon=6}
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
[1001]=_set({1001,1,"clanskilljob_0_1001",1,"public_career_icon_1","guild_skill_ui_2"},_mt),
[1002]=_set({1002,2,"clanskilljob_0_1002",2,"public_career_icon_2","guild_skill_ui_1"},_mt),
[1003]=_set({1003,3,"clanskilljob_0_1003",3,"public_career_icon_3","guild_skill_ui_3"},_mt),
[1004]=_set({1004,4,"clanskilljob_0_1004",4,"public_career_icon_4","guild_skill_ui_4"},_mt)
}

return _datas