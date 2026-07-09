local _keys = {refId=1,rankSectionMax=2,rankSectionMin=3,intervalSection=4}
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
[1]=_set({1,1,15,"1,1"},_mt),
[2]=_set({2,16,50,"1,3"},_mt),
[3]=_set({3,51,150,"2,6"},_mt),
[4]=_set({4,151,350,"4,8"},_mt),
[5]=_set({5,351,650,"6,12"},_mt),
[6]=_set({6,651,850,"7,16"},_mt),
[7]=_set({7,851,1050,"10,20"},_mt)
}

return _datas