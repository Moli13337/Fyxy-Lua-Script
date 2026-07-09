local _keys = {refId=1,desc=2,isShow=3}
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
[1]=_set({1,"premiumshow_0_1",""},_mt),
[2]=_set({2,"premiumshow_0_2","1=999"},_mt)
}

return _datas