local _keys = {refId=1,replaceAct=2}
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
idle=_set({"idle","idle_shield"},_mt),
calm=_set({"calm","idle_shield"},_mt)
}

return _datas