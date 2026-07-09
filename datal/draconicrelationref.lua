local _keys = {refId=1,name=2,sort=3,draconicId=4}
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
[1001]=_set({1001,"draconicrelation_0_1001",1,{1802402,1802403}},_mt),
[1002]=_set({1002,"draconicrelation_0_1002",2,{1802401,1802404}},_mt),
[2001]=_set({2001,"draconicrelation_0_2001",3,{1802502,1802504}},_mt),
[2002]=_set({2002,"draconicrelation_0_2002",4,{1802501,1802503}},_mt),
[3001]=_set({3001,"draconicrelation_0_3001",5,{1801601,1801602}},_mt),
[3002]=_set({3002,"draconicrelation_0_3002",6,{1802602,1802603}},_mt),
[3003]=_set({3003,"draconicrelation_0_3003",7,{1802601,1802604}},_mt),
[4001]=_set({4001,"draconicrelation_0_4001",8,{1802701,1802702}},_mt),
[4002]=_set({4002,"draconicrelation_0_4002",9,{1802703,1802704}},_mt)
}

return _datas