local _keys = {refId=1,conditionType=2,conditionText=3,conditionTextTip=4}
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
[1]=_set({1,1,"storeconditiontext_0_1","storeconditiontext_1_1"},_mt),
[2]=_set({2,2,"storeconditiontext_0_2","storeconditiontext_1_2"},_mt),
[3]=_set({3,3,"storeconditiontext_0_3","storeconditiontext_1_3"},_mt),
[4]=_set({4,4,"storeconditiontext_0_4","storeconditiontext_1_4"},_mt),
[5]=_set({5,5,"storeconditiontext_0_5","storeconditiontext_1_5"},_mt)
}

return _datas