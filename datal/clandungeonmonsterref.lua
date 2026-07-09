local _keys = {refId=1,nextId=2,name=3,show=4,skillShow=5,scale=6,moveXY=7,trailerScale=8,trailerXY=9,HeadIconShow=10,reward=11,randomReward=12,showReward=13,challengeLimit=14,bgImage=15,map=16,survivalTime=17}
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
[1]=_set({1,2,"clandungeonmonster_0_1","LH_Heishanyang01_zhcn","2701131|2701231|2701331|2701431",1,"0,60",1,"0,110","icon_hero_2701","1=108202=30,1=101001=50000","6001;6002","1=108201=10000,1=108202=100,1=102001=25",10,"warTemple_big_bg_1",1001,172800},_mt),
[2]=_set({2,3,"clandungeonmonster_0_2","LH_Lu01_zhcn","2705131|2705231|2705331|2705431",1,"0,60",1,"0,110","icon_hero_2705","1=108202=30,1=101001=50000","6001;6002","1=108201=10000,1=108202=100,1=102001=25",10,"warTemple_big_bg_1",1001,172800},_mt),
[3]=_set({3,4,"clandungeonmonster_0_3","LH_Baiquan01_zhcn","2703131|2703231|2703331|2703431",1,"0,60",1,"0,110","icon_hero_2703","1=108202=30,1=101001=50000","6001;6002","1=108201=10000,1=108202=100,1=102001=25",10,"warTemple_big_bg_1",1001,172800},_mt),
[4]=_set({4,5,"clandungeonmonster_0_4","LH_Shilaimu01_zhcn","1701131|1701231|1701331|1701431",1,"0,60",1,"0,110","icon_hero_1701","1=108202=30,1=101001=50000","6001;6002","1=108201=10000,1=108202=100,1=102001=25",10,"warTemple_big_bg_1",1001,172800},_mt),
[5]=_set({5,6,"clandungeonmonster_0_5","LH_Meimo01_zhcn","5705131|5705231|5705331|5705431",1,"0,60",1,"0,110","icon_hero_5705","1=108202=30,1=101001=50000","6001;6002","1=108201=10000,1=108202=100,1=102001=25",10,"warTemple_big_bg_1",1001,172800},_mt),
[6]=_set({6,1,"clandungeonmonster_0_6","LH_Nainiu01_zhcn","3705131|3705231|3705331|3705431",1,"0,60",1,"0,110","icon_hero_3705","1=108202=30,1=101001=50000","6001;6002","1=108201=10000,1=108202=100,1=102001=25",10,"warTemple_big_bg_1",1001,172800},_mt)
}

return _datas