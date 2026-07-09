local _keys = {refId=1,name=2,desc=3,googleMark=4,icon=5,initial=6}
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
zhcn=_set({"zhcn","简体中文","简体","cn","public_txt_21",1},_mt)
}

return _datas