local _keys = {refId=1,diffValue=2,diffFixAttr=3}
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
[1]=_set({1,1,40000001},_mt),
[2]=_set({2,2,40000002},_mt),
[3]=_set({3,3,40000003},_mt),
[4]=_set({4,4,40000004},_mt),
[5]=_set({5,5,40000005},_mt),
[6]=_set({6,6,40000006},_mt),
[7]=_set({7,7,40000007},_mt),
[8]=_set({8,8,40000008},_mt)
}

return _datas