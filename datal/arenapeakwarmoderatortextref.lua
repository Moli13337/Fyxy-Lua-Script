local _keys = {refId=1,departureTime=2,textId=3}
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
[101]=_set({101,0,11838},_mt),
[102]=_set({102,60,11839},_mt),
[103]=_set({103,0,11840},_mt)
}

return _datas