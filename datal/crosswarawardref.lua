local _keys = {refId=1,sort=2,finishCond=3,reward=4}
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
[1]=_set({1,1,1,"1=112003=40=0,1=101001=50000=0"},_mt),
[2]=_set({2,2,2,"1=112003=80=0,1=104001=20000=0"},_mt),
[3]=_set({3,3,3,"1=112003=120=0,1=102001=50=0"},_mt),
[4]=_set({4,4,4,"1=112003=160=0,1=100105=3=0"},_mt),
[5]=_set({5,5,5,"1=112003=200=0,1=100211=1=0"},_mt)
}

return _datas