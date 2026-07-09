local _keys = {refId=1,name=2,nameIcon=3,icon=4,bg=5,description=6,nameEffect=7,sort=8,openDay=9,race=10,dailyPass=11,combatTyep=12,rankRefId=13,floor=14,redpoint=15}
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
[1]=_set({1,"snaketowerpattern_0_1","trial1_ad_5_bg","trial1_ad_5","trial_bg_5","snaketowerpattern_1_1","",1,"1;2;3;4;5;6;7","1;2;3;4;5;6",-1,7,3,2700,16400011},_mt),
[2]=_set({2,"snaketowerpattern_0_2","trial1_ad_1_bg","trial1_ad_1","trial_bg_1","snaketowerpattern_1_2","fx_slzt_shui",2,"1;5;7","1",10,71,901,700,16400012},_mt),
[3]=_set({3,"snaketowerpattern_0_3","trial1_ad_2_bg","trial1_ad_2","trial_bg_2","snaketowerpattern_1_3","fx_slzt_huo",3,"2;5;7","2",10,72,902,700,16400013},_mt),
[4]=_set({4,"snaketowerpattern_0_4","trial1_ad_3_bg","trial1_ad_3","trial_bg_3","snaketowerpattern_1_4","fx_slzt_feng",4,"3;6;7","3",10,73,903,700,16400014},_mt),
[5]=_set({5,"snaketowerpattern_0_5","trial1_ad_4_bg","trial1_ad_4","trial_bg_4","snaketowerpattern_1_5","fx_slzt_guangan",5,"4;6;7","4;5",10,74,904,700,16400015},_mt),
[99]=_set({99,"snaketowerpattern_0_99","trial1_ad_99_bg","trial1_ad_99","trial_bg_99","snaketowerpattern_1_99","",99,"1;2;3;4;5;6;7","1;2;3;4;5;6",20,75,905,800,16400016},_mt)
}

return _datas