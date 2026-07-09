local _keys = {refId=1,group=2,sort=3,tipText=4,helpText=5,image=6,text1=7,alignment1=8,textPos1=9}
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