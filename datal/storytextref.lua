local _keys = {refId=1,text=2,soundP=3}
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
[3]=_set({3,"storytext_0_3","SoundX_1"},_mt),
[4]=_set({4,"storytext_0_4","SoundX_2"},_mt),
[5]=_set({5,"storytext_0_5","SoundX_3"},_mt),
[6]=_set({6,"storytext_0_6","SoundX_4"},_mt),
[7]=_set({7,"storytext_0_7","SoundX_5"},_mt),
[8]=_set({8,"storytext_0_8","SoundX_6"},_mt),
[9]=_set({9,"storytext_0_9","SoundX_7"},_mt),
[10]=_set({10,"storytext_0_10","SoundX_8"},_mt),
[11]=_set({11,"storytext_0_11","SoundX_9"},_mt),
[12]=_set({12,"storytext_0_12","SoundX_10"},_mt),
[13]=_set({13,"storytext_0_13","SoundX_21"},_mt),
[14]=_set({14,"storytext_0_14","SoundX_22"},_mt),
[15]=_set({15,"storytext_0_15","SoundX_13"},_mt),
[16]=_set({16,"storytext_0_16","SoundX_14"},_mt),
[17]=_set({17,"storytext_0_17","SoundX_15"},_mt),
[18]=_set({18,"storytext_0_18","SoundX_16"},_mt),
[19]=_set({19,"storytext_0_19","SoundX_17"},_mt),
[20]=_set({20,"storytext_0_20","SoundX_18"},_mt),
[21]=_set({21,"storytext_0_21","SoundX_19"},_mt),
[22]=_set({22,"storytext_0_22","SoundX_20"},_mt),
[23]=_set({23,"storytext_0_23","SoundX_11"},_mt),
[24]=_set({24,"storytext_0_24","SoundX_12"},_mt)
}

return _datas