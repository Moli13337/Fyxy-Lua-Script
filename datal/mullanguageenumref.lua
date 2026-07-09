local _keys = {refId=1,type=2,lanRes=3}
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
zh=_set({"zh",1,"zhcn"},_mt),
zhcn=_set({"zhcn",2,"zhcn"},_mt),
zhtw=_set({"zhtw",2,"zhcn"},_mt),
zhhk=_set({"zhhk",2,"zhcn"},_mt)
}

return _datas