local _keys = {refId=1,icon=2,emptylcon=3}
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
[1]=_set({1,"golem_num1","puppet_icon_bg_1"},_mt),
[2]=_set({2,"golem_num2","puppet_icon_bg_1"},_mt),
[3]=_set({3,"golem_num3","puppet_icon_bg_1"},_mt),
[4]=_set({4,"golem_num4","puppet_icon_bg_1"},_mt)
}

return _datas