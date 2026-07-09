local _keys = {refId=1,extractType=2,sort=3,title=4,separate=5,text=6,specialExplain=7,callRefId=8,jackpotId=9}
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
[1001]=_set({1001,1,1,"summontext_0_1001",0,11658,"",0,0},_mt),
[1002]=_set({1002,1,2,"summontext_0_1002",1,27807,"27808,27809,27810,27811,27812",1002,1002},_mt),
[1003]=_set({1003,1,3,"summontext_0_1003",1,27818,"27819,27820,27821,27822",1003,1003},_mt),
[1004]=_set({1004,1,4,"summontext_0_1004",1,27813,"27814,27815,27816,27817",1001,1001},_mt),
[1005]=_set({1005,1,5,"summontext_0_1005",1,27841,"27842,27843",1004,1004},_mt),
[1006]=_set({1006,2,1,"summontext_0_1006",0,27851,"27852,27853,27854,27855",0,0},_mt),
[1007]=_set({1007,2,2,"summontext_0_1007",1,11664,"",2001,2001},_mt),
[1008]=_set({1008,2,3,"summontext_0_1008",1,11665,"",2002,2002},_mt),
[1009]=_set({1009,2,4,"summontext_0_1009",1,11666,"",2003,2003},_mt),
[1010]=_set({1010,2,5,"summontext_0_1010",1,11667,"",2004,2004},_mt),
[2010]=_set({2010,0,0,"summontext_0_2010",0,27823,"27824,27825,27826,27827",0,0},_mt),
[2020]=_set({2020,0,0,"summontext_0_2020",0,27831,"27832,27833,27834,27835,27838,27839,27840",0,0},_mt),
[3001]=_set({3001,0,0,"summontext_0_3001",1,27881,"",3001,3001},_mt),
[4001]=_set({4001,0,0,"summontext_0_4001",1,38301,"",4001,4100},_mt)
}

return _datas