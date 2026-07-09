local _keys = {refId=1,order=2,item1=3,item2=4,more=5}
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
[10001]=_set({10001,10001,"1=181005=1","1=180905=4",1},_mt),
[10002]=_set({10002,10002,"1=181006=1","1=180906=4",1},_mt),
[10003]=_set({10003,10003,"1=181007=1","1=180907=4",1},_mt),
[20001]=_set({20001,20001,"1=180905=1","1=180906=1,1=100213=100",1},_mt),
[20002]=_set({20002,20002,"1=180906=1","1=180905=1,1=100213=100",1},_mt)
}

return _datas