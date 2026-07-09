local _keys = {refId=1,name=2,copyright=3,webNum=4,webWord=5}
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
[1]=_set({1,"测试数据","","",""},_mt)
}

return _datas