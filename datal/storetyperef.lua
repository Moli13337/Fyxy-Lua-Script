local _keys = {refId=1,title=2,functionOpenRefId=3}
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
[1]=_set({1,"常規商店",14500000},_mt),
[2]=_set({2,"積分商店",14600000},_mt)
}

return _datas