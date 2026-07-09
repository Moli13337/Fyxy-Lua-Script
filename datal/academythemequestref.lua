local _keys = {refId=1,themeType=2,questType=3,name=4,sort=5}
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
[101]=_set({101,1,41,"academythemequest_0_101",1},_mt),
[102]=_set({102,1,42,"academythemequest_0_102",2},_mt),
[201]=_set({201,2,43,"academythemequest_0_201",3},_mt),
[202]=_set({202,2,44,"academythemequest_0_202",4},_mt),
[203]=_set({203,2,45,"academythemequest_0_203",5},_mt),
[301]=_set({301,3,46,"academythemequest_0_301",6},_mt),
[302]=_set({302,3,47,"academythemequest_0_302",7},_mt),
[303]=_set({303,3,48,"academythemequest_0_303",8},_mt)
}

return _datas