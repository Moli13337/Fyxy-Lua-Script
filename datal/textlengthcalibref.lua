local _keys = {refId=1,zhtw=2,zhcn=3,enus=4,vie=5,ja=6,kr=7,ru=8}
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
[1]=_set({1,2,2,1,1,2,2,2},_mt),
[2]=_set({2,2,2,1,1,2,2,1},_mt),
[3]=_set({3,1,1,1,1,1,1,1},_mt),
[4]=_set({4,1,1,1,1,1,1,1},_mt)
}

return _datas