local _keys = {refId=1,type=2,shieldMin=3,shieldMax=4,functionOpen=5}
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