local _keys = {refId=1,sort=2,hero=3,finishCond=4,name=5,description=6,warReport=7}
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
[1]=_set({1,1,"2601,3602,2704,1602,1601,3603",290021,"growthlineup_0_1","growthlineup_1_1",1001},_mt),
[2]=_set({2,2,"1701,3705,4702,2704,1703,3603",290022,"growthlineup_0_2","growthlineup_1_2",1001},_mt),
[3]=_set({3,3,"1701,1702,1703,1601,1602,1603",290023,"growthlineup_0_3","growthlineup_1_3",1001},_mt),
[4]=_set({4,4,"2701,2703,2704,2705,2602,4702",290024,"growthlineup_0_4","growthlineup_1_4",1001},_mt),
[5]=_set({5,5,"3701,3702,3705,3601,3602,3603",290025,"growthlineup_0_5","growthlineup_1_5",1001},_mt),
[6]=_set({6,6,"5701,5704,4702,4705,4706,5705",290026,"growthlineup_0_6","growthlineup_1_6",1001},_mt)
}

return _datas