local _keys = {refId=1,condition=2,description=3}
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
[1]=_set({1,"1=star=1","investigatecondition_0_1"},_mt),
[2]=_set({2,"1=star=2","investigatecondition_0_2"},_mt),
[3]=_set({3,"1=star=3","investigatecondition_0_3"},_mt),
[4]=_set({4,"1=star=4","investigatecondition_0_4"},_mt),
[5]=_set({5,"1=star=5","investigatecondition_0_5"},_mt),
[6]=_set({6,"1=star=6","investigatecondition_0_6"},_mt),
[7]=_set({7,"1=star=7","investigatecondition_0_7"},_mt),
[8]=_set({8,"1=star=8","investigatecondition_0_8"},_mt),
[9]=_set({9,"1=star=9","investigatecondition_0_9"},_mt),
[10]=_set({10,"1=star=10","investigatecondition_0_10"},_mt),
[101]=_set({101,"1=race=1","investigatecondition_0_101"},_mt),
[102]=_set({102,"1=race=2","investigatecondition_0_102"},_mt),
[103]=_set({103,"1=race=3","investigatecondition_0_103"},_mt),
[104]=_set({104,"1=race=4","investigatecondition_0_104"},_mt),
[105]=_set({105,"1=race=5","investigatecondition_0_105"},_mt)
}

return _datas