local _keys = {refId=1,description=2,condition=3,limit=4,parameter=5,shiftNumIndex=6,finishTips=7}
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