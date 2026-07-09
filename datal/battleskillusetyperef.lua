local _keys = {refId=1,releaseObj=2,type=3,sort=4}
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
[101]=_set({101,1,1,1000},_mt),
[201]=_set({201,1,1,900},_mt),
[203]=_set({203,2,1,890},_mt),
[401]=_set({401,1,1,800},_mt),
[402]=_set({402,2,3,1200},_mt),
[501]=_set({501,1,1,850},_mt),
[601]=_set({601,2,3,1300},_mt),
[701]=_set({701,2,1,950},_mt),
[801]=_set({801,2,1,1150},_mt),
[1101]=_set({1101,1,1,800},_mt),
[1201]=_set({1201,1,1,1050},_mt),
[1401]=_set({1401,1,1,1200},_mt),
[1501]=_set({1501,1,1,1001},_mt)
}

return _datas