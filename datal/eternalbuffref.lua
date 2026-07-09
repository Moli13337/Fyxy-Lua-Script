local _keys = {refId=1,bufftype=2,name=3,buffDesc=4,battleBuffDesc=5,iconBg=6,icon=7,addAttrSkill=8,effectiveRound=9,skillReleaseRound=10}
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
[1]=_set({1,1,"eternalbuff_0_1","eternalbuff_1_1","eternalbuff_2_1","rank_bg_1_2","trialcopy_buff_icon_1",140001,"5",1},_mt),
[2]=_set({2,1,"eternalbuff_0_2","eternalbuff_1_2","eternalbuff_2_2","rank_bg_1_2","trialcopy_buff_icon_2",140002,"5",1},_mt),
[3]=_set({3,1,"eternalbuff_0_3","eternalbuff_1_3","eternalbuff_2_3","rank_bg_1_2","trialcopy_buff_icon_3",140003,"5",1},_mt),
[4]=_set({4,1,"eternalbuff_0_4","eternalbuff_1_4","eternalbuff_2_4","rank_bg_1_2","trialcopy_buff_icon_4",140004,"5",1},_mt),
[5]=_set({5,2,"eternalbuff_0_5","eternalbuff_1_5","eternalbuff_2_5","rank_bg_1_2","trialcopy_buff_icon_5",140005,"5",1},_mt),
[6]=_set({6,2,"eternalbuff_0_6","eternalbuff_1_6","eternalbuff_2_6","rank_bg_1_2","trialcopy_buff_icon_6",140006,"5",1},_mt),
[7]=_set({7,2,"eternalbuff_0_7","eternalbuff_1_7","eternalbuff_2_7","rank_bg_1_2","trialcopy_buff_icon_7",140007,"5",1},_mt),
[8]=_set({8,2,"eternalbuff_0_8","eternalbuff_1_8","eternalbuff_2_8","rank_bg_1_2","trialcopy_buff_icon_8",140008,"5",1},_mt),
[9]=_set({9,3,"eternalbuff_0_9","eternalbuff_1_9","eternalbuff_2_9","rank_bg_1_2","trialcopy_buff_icon_9",140009,"5",1},_mt),
[10]=_set({10,3,"eternalbuff_0_10","eternalbuff_1_10","eternalbuff_2_10","rank_bg_1_2","trialcopy_buff_icon_11",140010,"1",1},_mt)
}

return _datas