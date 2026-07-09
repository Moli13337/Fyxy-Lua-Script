local _keys = {refId=1,icon=2}
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
[1]=_set({1,"chat_bigface_110"},_mt),
[2]=_set({2,"chat_bigface_111"},_mt),
[3]=_set({3,"chat_bigface_113"},_mt),
[4]=_set({4,"chat_bigface_114"},_mt),
[5]=_set({5,"chat_bigface_119"},_mt),
[6]=_set({6,"chat_bigface_120"},_mt)
}

return _datas