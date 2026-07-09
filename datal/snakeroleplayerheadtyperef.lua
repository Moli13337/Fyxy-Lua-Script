local _keys = {refId=1,sort=2,type=3,title=4,openId=5}
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
[101]=_set({101,1,1,"snakeroleplayerheadtype_0_101",17500000},_mt),
[201]=_set({201,2,2,"snakeroleplayerheadtype_0_201",17500000},_mt),
[301]=_set({301,3,3,"snakeroleplayerheadtype_0_301",17500000},_mt),
[701]=_set({701,7,7,"snakeroleplayerheadtype_0_701",17500000},_mt),
[801]=_set({801,8,8,"snakeroleplayerheadtype_0_801",17500000},_mt)
}

return _datas