local _keys = {refId=1,type=2}
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
soundb_=_set({"soundb_",0},_mt),
soundr_=_set({"soundr_",0},_mt),
soundp_=_set({"soundp_",0},_mt),
soundx_=_set({"soundx_",0},_mt)
}

return _datas