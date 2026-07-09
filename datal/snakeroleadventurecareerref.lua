local _keys = {refId=1,description=2,type=3,showType=4,sort=5,eventId=6,sign=7,desc=8}
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

}

return _datas