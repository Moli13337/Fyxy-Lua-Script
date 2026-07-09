local _keys = {refId=1,type=2,para=3,bonus=4}
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
[101]=_set({101,1,"1=2",0.1},_mt),
[102]=_set({102,1,"2=2",0.1},_mt),
[103]=_set({103,1,"3=2",0.1},_mt),
[104]=_set({104,1,"4=2",0.1},_mt),
[105]=_set({105,1,"5=2",0.1},_mt)
}

return _datas