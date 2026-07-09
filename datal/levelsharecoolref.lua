local _keys = {refId=1,time=2,NeedItem=3,NeedDiamonds=4}
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
[1001]=_set({1001,64800,"1=100216=200","1=102001=200"},_mt),
[1002]=_set({1002,43200,"1=100216=150","1=102001=150"},_mt),
[1003]=_set({1003,21600,"1=100216=100","1=102001=100"},_mt),
[1004]=_set({1004,0,"1=100216=50","1=102001=50"},_mt)
}

return _datas