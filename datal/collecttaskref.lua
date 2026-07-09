local _keys = {refId=1,name=2,questClassify=3}
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
[1]=_set({1,"collecttask_0_1",110},_mt),
[2]=_set({2,"collecttask_0_2",111},_mt),
[3]=_set({3,"collecttask_0_3",112},_mt),
[4]=_set({4,"collecttask_0_4",113},_mt)
}

return _datas