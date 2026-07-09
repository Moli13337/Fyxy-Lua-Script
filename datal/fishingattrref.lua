local _keys = {refId=1,name=2}
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
[1]=_set({1,"fishingattr_0_1"},_mt),
[2]=_set({2,"fishingattr_0_2"},_mt),
[3]=_set({3,"fishingattr_0_3"},_mt),
[4]=_set({4,"fishingattr_0_4"},_mt),
[5]=_set({5,"fishingattr_0_5"},_mt),
[6]=_set({6,"fishingattr_0_6"},_mt),
[7]=_set({7,"fishingattr_0_7"},_mt),
[8]=_set({8,"fishingattr_0_8"},_mt),
[9]=_set({9,"fishingattr_0_9"},_mt),
[10]=_set({10,"fishingattr_0_10"},_mt),
[11]=_set({11,"fishingattr_0_11"},_mt),
[12]=_set({12,"fishingattr_0_12"},_mt),
[13]=_set({13,"fishingattr_0_13"},_mt)
}

return _datas