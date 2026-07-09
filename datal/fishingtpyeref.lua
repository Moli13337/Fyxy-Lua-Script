local _keys = {refId=1,name=2,icon=3}
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
[1]=_set({1,"fishingtpye_0_1","fish_txt_1"},_mt),
[2]=_set({2,"fishingtpye_0_2","fish_txt_2"},_mt),
[3]=_set({3,"fishingtpye_0_3","fish_txt_3"},_mt),
[4]=_set({4,"fishingtpye_0_4","fish_txt_4"},_mt),
[5]=_set({5,"fishingtpye_0_5","fish_txt_5"},_mt),
[6]=_set({6,"fishingtpye_0_6","fish_txt_6"},_mt)
}

return _datas