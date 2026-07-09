local _keys = {refId=1,name=2,type=3,show=4}
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
[1]=_set({1,"leaderboardingtype_0_1",1,1},_mt),
[2]=_set({2,"leaderboardingtype_0_2",2,1},_mt),
[3]=_set({3,"leaderboardingtype_0_3",3,1},_mt),
[4]=_set({4,"leaderboardingtype_0_4",4,2},_mt)
}

return _datas