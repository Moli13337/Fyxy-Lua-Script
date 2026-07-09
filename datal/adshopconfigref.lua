local _keys = {key=1,value=2}
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
banner=_set({"banner","activity_40_banner_1"},_mt),
privilegeGiftId=_set({"privilegeGiftId","12"},_mt)
}

return _datas