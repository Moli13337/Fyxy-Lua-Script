local _keys = {refId=1,exp=2,text1=3,text2=4,spAction=5,SpActionSound=6,SpActionDesc=7,unlockHeroPlayItemSpAction=8,unlockHeroCloseUpSpActionSound=9,unlockStoryNum=10,spCharacter=11}
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
[0]=_set({0,0,"","characterfavorability_1_0","","RoleRef","RoleRefTxt","","","1","1|0|0|0"},_mt),
[1]=_set({1,50,"","characterfavorability_1_1","","skillSound1","skillSound1Desc","","","1","1|1|0|0"},_mt),
[2]=_set({2,100,"","characterfavorability_1_2","","skillSound2","skillSound2Desc","","","1","1|1|0|0"},_mt),
[3]=_set({3,250,"characterfavorability_0_3","characterfavorability_1_3","heroClickSpAction","heroClickSpActionSound","heroClickSpActionDesc","","","1|2","1|1|0|0"},_mt),
[4]=_set({4,400,"","","","","","","","1|2","1|1|1|0"},_mt),
[5]=_set({5,550,"","characterfavorability_1_5","","heroStarUpSound","heroStarUpDesc","","","1|2","1|1|1|0"},_mt),
[6]=_set({6,700,"characterfavorability_0_6","characterfavorability_1_6","heroPlayItemSpAction","heroPlayItemSpActionSound","heroPlayItemSpActionDesc","","","1|2|3","1|1|1|0"},_mt),
[7]=_set({7,850,"","","","","","","","1|2|3","1|1|1|1"},_mt),
[8]=_set({8,1000,"","characterfavorability_1_8","","heroWinMVPSound","descriptionVictory","","","1|2|3","1|1|1|1"},_mt),
[9]=_set({9,1000,"characterfavorability_0_9","characterfavorability_1_9","heroCloseUpSpAction","heroCloseUpSpActionSound","heroCloseUpSpActionDesc","","","1|2|3|4","1|1|1|1"},_mt),
[10]=_set({10,1000,"","characterfavorability_1_10","","heroAsmrSound","heroAsmrSoundDesc","","","1|2|3|4","1|1|1|1"},_mt),
[11]=_set({11,1000,"","","","","","","","1|2|3|4","1|1|1|1"},_mt),
[12]=_set({12,1500,"","","","","","","","1|2|3|4","1|1|1|1"},_mt),
[13]=_set({13,1500,"","","","","","","","1|2|3|4","1|1|1|1"},_mt),
[14]=_set({14,2000,"","","","","","","","1|2|3|4","1|1|1|1"},_mt),
[15]=_set({15,2000,"","","","","","","","1|2|3|4","1|1|1|1"},_mt)
}

return _datas