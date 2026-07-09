local _keys = {refId=1,type=2,name=3,typeName=4,functionOpen=5}
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
[1]=_set({1,1,"clanlogtype_0_1","clanlogtype_1_1",12100000},_mt),
[2]=_set({2,2,"clanlogtype_0_2","clanlogtype_1_2",12100000},_mt),
[3]=_set({3,3,"clanlogtype_0_3","clanlogtype_1_3",12100000},_mt),
[4]=_set({4,4,"clanlogtype_0_4","clanlogtype_1_4",12100000},_mt)
}

return _datas