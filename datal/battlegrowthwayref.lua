local _keys = {refId=1,type=2,name=3,order=4,icon=5,origin=6}
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
[1001]=_set({1001,0,"battlegrowthway_0_1001",1,"settlement_icon1",15500011},_mt),
[1002]=_set({1002,0,"battlegrowthway_0_1002",2,"settlement_icon2",10300000},_mt),
[1003]=_set({1003,0,"battlegrowthway_0_1003",3,"settlement_icon3",10300000},_mt),
[1004]=_set({1004,0,"battlegrowthway_0_1004",4,"settlement_icon4",17400000},_mt)
}

return _datas