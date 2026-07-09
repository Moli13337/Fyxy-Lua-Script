local _keys = {refId=1,bg=2,nameIcon=3}
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
[1]=_set({1,"simulate_tips_bg_1","simulate_tips_txt_1"},_mt),
[2]=_set({2,"simulate_tips_bg_3","simulate_tips_txt_3"},_mt),
[3]=_set({3,"simulate_tips_bg_4","simulate_tips_txt_4"},_mt),
[4]=_set({4,"simulate_tips_bg_2","simulate_tips_txt_2"},_mt)
}

return _datas