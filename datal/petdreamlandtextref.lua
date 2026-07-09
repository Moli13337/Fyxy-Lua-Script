local _keys = {refId=1,desc=2}
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
[1]=_set({1,"petdreamlandtext_0_1"},_mt),
[2]=_set({2,"petdreamlandtext_0_2"},_mt),
[3]=_set({3,"petdreamlandtext_0_3"},_mt),
[4]=_set({4,"petdreamlandtext_0_4"},_mt),
[6]=_set({6,"petdreamlandtext_0_6"},_mt),
[7]=_set({7,"petdreamlandtext_0_7"},_mt),
[8]=_set({8,"petdreamlandtext_0_8"},_mt),
[9]=_set({9,"petdreamlandtext_0_9"},_mt),
[10]=_set({10,"petdreamlandtext_0_10"},_mt)
}

return _datas