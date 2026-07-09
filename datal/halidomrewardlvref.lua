local _keys = {refId=1,num=2,weight=3}
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
[1]=_set({1,0,"101=250,102=200,103=100,104=8,105=200,106=200,107=42"},_mt),
[2]=_set({2,300,"201=250,202=200,203=100,204=8,205=200,206=200,207=42"},_mt),
[3]=_set({3,1000,"301=250,302=200,303=100,304=8,305=200,306=200,307=42"},_mt)
}

return _datas