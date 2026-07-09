local _keys = {refId=1,showName=2,useShow=3}
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
UIMCity=_set({"UIMCity","ShowThemeUICityRef",1},_mt),
MapCity=_set({"MapCity","ShowThemeMapCityRef",1},_mt)
}

return _datas