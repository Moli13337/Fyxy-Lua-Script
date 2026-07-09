local _keys = {refId=1,type1=2,type2=3,value=4}
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
[111]=_set({111,1,1,600},_mt),
[112]=_set({112,1,2,300},_mt),
[211]=_set({211,2,1,3000},_mt),
[212]=_set({212,2,2,1500},_mt)
}

return _datas