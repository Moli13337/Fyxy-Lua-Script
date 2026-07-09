local _keys = {refId=1,combatTyep=2,type=3,openType=4,name=5,everydayMax=6,race=7,maxCheckpointGap=8,time=9,rotateSort=10,rankRefId=11,initialCheckpoint=12,limitDesc=13,noticeDesc=14,recommendHero=15,recommendIcon=16}
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
[1001]=_set({1001,12,1,1,"eternal_0_1001","-1","1,2,3,4,5,6",9,-1,0,701,1,"","","1701,3705,4702,2704,1703,3603",""},_mt),
[1002]=_set({1002,121,2,2,"eternal_0_1002","35","1",9,259200,1,702,2001,"","eternal_2_1002","1701,1702,1703,1601,1602,1603","trialcopy_icon_2"},_mt),
[1003]=_set({1003,122,3,2,"eternal_0_1003","35","2",9,259200,2,703,4001,"","eternal_2_1003","2701,2703,2704,2705,2602,2601","trialcopy_icon_3"},_mt),
[1004]=_set({1004,123,4,2,"eternal_0_1004","35","3",9,259200,3,704,6001,"","eternal_2_1004","3701,3702,3705,3601,3602,3603","trialcopy_icon_4"},_mt),
[1005]=_set({1005,124,5,2,"eternal_0_1005","35","4,5",9,259200,4,705,8001,"","eternal_2_1005","5701,5704,4702,4705,4706,5705","trialcopy_icon_5"},_mt)
}

return _datas