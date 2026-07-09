local _keys = {refId=1,type=2,grad=3,gradReward=4}
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
[1]=_set({1,1,50,"1=170001=10=0"},_mt),
[2]=_set({2,1,100,"1=170001=20=0"},_mt),
[3]=_set({3,1,150,"1=100212=1=0"},_mt),
[4]=_set({4,1,250,"1=170011=20=0"},_mt),
[5]=_set({5,2,50,"1=170001=10=0"},_mt),
[6]=_set({6,2,100,"1=170001=20=0"},_mt),
[7]=_set({7,2,150,"1=100212=1=0"},_mt),
[8]=_set({8,2,250,"1=170012=20=0"},_mt),
[9]=_set({9,3,50,"1=170001=10=0"},_mt),
[10]=_set({10,3,100,"1=170001=20=0"},_mt),
[11]=_set({11,3,150,"1=100212=1=0"},_mt),
[12]=_set({12,3,250,"1=170013=20=0"},_mt)
}

return _datas