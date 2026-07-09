local _keys = {refId=1,description=2}
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
[10]=_set({10,"simulatematchbalance_0_10"},_mt),
[11]=_set({11,"simulatematchbalance_0_11"},_mt),
[12]=_set({12,"simulatematchbalance_0_12"},_mt),
[13]=_set({13,"simulatematchbalance_0_13"},_mt),
[14]=_set({14,"simulatematchbalance_0_14"},_mt),
[15]=_set({15,"simulatematchbalance_0_15"},_mt),
[16]=_set({16,"simulatematchbalance_0_16"},_mt),
[17]=_set({17,"simulatematchbalance_0_17"},_mt),
[18]=_set({18,"simulatematchbalance_0_18"},_mt),
[19]=_set({19,"simulatematchbalance_0_19"},_mt),
[20]=_set({20,"simulatematchbalance_0_20"},_mt)
}

return _datas