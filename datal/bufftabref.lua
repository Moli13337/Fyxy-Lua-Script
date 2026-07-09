local _keys = {refId=1,name=2,sort=3}
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
[1]=_set({1,"bufftab_0_1",1},_mt),
[3]=_set({3,"bufftab_0_3",2},_mt),
[4]=_set({4,"bufftab_0_4",3},_mt),
[5]=_set({5,"bufftab_0_5",5},_mt),
[6]=_set({6,"bufftab_0_6",4},_mt)
}

return _datas