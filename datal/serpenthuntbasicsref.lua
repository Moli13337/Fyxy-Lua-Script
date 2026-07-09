local _keys = {refId=1,round=2,openTime=3,continuedTime=4,bossTime=5,bossBg=6,bossSpineBg=7,bossSpineHd=8,bossName=9,bossShowReward=10,bossPrefab=11,simpleStrategy=12,showSkill=13,animationSkill=14,Strategy=15,icon=16}
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
[1]=_set({1,1,0,259200,259140,"hero_bg_big_1","","","serpenthuntbasics_0_1","1=102001=1=0,1=1800002=1=0,1=101001=1=0","LH_Heilong01","serpenthuntbasics_1_1","180102,180103,180104","180102,180103,180104","serpenthuntbasics_2_1","icon_hero_100101"},_mt),
[2]=_set({2,2,259200,259200,259140,"hero_bg_big_4","","","serpenthuntbasics_0_2","1=102001=1=0,1=1800002=1=0,1=101001=1=0","LH_Bailong01","serpenthuntbasics_1_2","180202,180203,180204","180202,180203,180204","serpenthuntbasics_2_2","icon_hero_100103"},_mt),
[3]=_set({3,3,604800,259200,259140,"hero_bg_big_5","","","serpenthuntbasics_0_3","1=102001=1=0,1=1800002=1=0,1=101001=1=0","LH_Honglong01","serpenthuntbasics_1_3","180302,180303,180304","180302,180303,180304","serpenthuntbasics_2_3","icon_hero_100102"},_mt),
[4]=_set({4,4,864000,259200,259140,"hero_bg_big_3","LH_Lanlong01_bg","","serpenthuntbasics_0_4","1=102001=1=0,1=1800002=1=0,1=101001=1=0","LH_Lanlong01","serpenthuntbasics_1_4","180402,180403,180404","180402,180403,180404","serpenthuntbasics_2_4","icon_hero_100104"},_mt)
}

return _datas