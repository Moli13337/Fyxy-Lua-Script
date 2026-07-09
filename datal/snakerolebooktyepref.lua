local _keys = {refId=1,sort=2,name=3,icon=4,iconSelect=5,funcId=6}
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