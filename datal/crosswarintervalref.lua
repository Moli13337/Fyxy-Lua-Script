local _keys = {refId=1,name=2,nameColor=3,sort=4,icon=5,iconEffect=6,des=7,nextStage=8,scoreDown=9,scoreUp=10,playerMax=11,integralReset=12,reward=13,endReward=14,titleReward=15}
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
[1]=_set({1,"crosswarinterval_0_1","139056FF",1,"crossGrading_icon_101","fx_duanwei_xiangshen_up,fx_duanwei_xiangshen_down","crosswarinterval_1_1",2,1000,1299,0,1000,"1=112003=250=0,1=102001=100=0","1=112003=900=0,1=102001=200=0,1=100211=3=0",""},_mt),
[2]=_set({2,"crosswarinterval_0_2","139056FF",2,"crossGrading_icon_102","fx_duanwei_xiangshen_up,fx_duanwei_xiangshen_down","crosswarinterval_1_2",3,1300,1699,0,1000,"1=112003=375=0,1=102001=150=0","1=112003=950=0,1=102001=250=0,1=100211=4=0",""},_mt),
[3]=_set({3,"crosswarinterval_0_3","139056FF",3,"crossGrading_icon_103","fx_duanwei_xiangshen_up,fx_duanwei_xiangshen_down","crosswarinterval_1_3",4,1700,1999,0,1000,"1=112003=500=0,1=102001=200=0","1=112003=1000=0,1=102001=300=0,1=100211=5=0",""},_mt),
[4]=_set({4,"crosswarinterval_0_4","1b62a3FF",4,"crossGrading_icon_104","fx_duanwei_nanjue_up,fx_duanwei_nanjue_down","crosswarinterval_1_4",5,2000,2299,0,1000,"1=112003=625=0,1=102001=250=0","1=112003=1100=0,1=102001=400=0,1=100211=6=0",""},_mt),
[5]=_set({5,"crosswarinterval_0_5","1b62a3FF",5,"crossGrading_icon_105","fx_duanwei_nanjue_up,fx_duanwei_nanjue_down","crosswarinterval_1_5",6,2300,2699,0,1000,"1=112003=750=0,1=102001=300=0,1=100211=2=0","1=112003=1200=0,1=102001=500=0,1=100211=7=0",""},_mt),
[6]=_set({6,"crosswarinterval_0_6","1b62a3FF",6,"crossGrading_icon_106","fx_duanwei_nanjue_up,fx_duanwei_nanjue_down","crosswarinterval_1_6",7,2700,2999,0,1300,"1=112003=875=0,1=102001=350=0","1=112003=1300=0,1=102001=600=0,1=100211=8=0",""},_mt),
[7]=_set({7,"crosswarinterval_0_7","9624abFF",7,"crossGrading_icon_107","fx_duanwei_zijue_up,fx_duanwei_zijue_down","crosswarinterval_1_7",8,3000,3299,0,1300,"1=112003=1000=0,1=102001=400=0","1=112003=1400=0,1=102001=700=0,1=100211=9=0",""},_mt),
[8]=_set({8,"crosswarinterval_0_8","9624abFF",8,"crossGrading_icon_108","fx_duanwei_zijue_up,fx_duanwei_zijue_down","crosswarinterval_1_8",9,3300,3699,0,1700,"1=112003=1125=0,1=102001=450=0","1=112003=1500=0,1=102001=800=0,1=100211=10=0",""},_mt),
[9]=_set({9,"crosswarinterval_0_9","9624abFF",9,"crossGrading_icon_109","fx_duanwei_zijue_up,fx_duanwei_zijue_down","crosswarinterval_1_9",10,3700,3999,0,2000,"1=112003=1250=0,1=102001=500=0","1=112003=1600=0,1=102001=900=0,1=100211=11=0",""},_mt),
[10]=_set({10,"crosswarinterval_0_10","d2730fFF",10,"crossGrading_icon_110","fx_duanwei_bojue_up,fx_duanwei_bojue_down","crosswarinterval_1_10",11,4000,4299,0,2300,"1=112003=1375=0,1=102001=550=0,1=1200005=50=0","1=112003=1800=0,1=102001=1000=0,1=100211=12=0",""},_mt),
[11]=_set({11,"crosswarinterval_0_11","d2730fFF",11,"crossGrading_icon_111","fx_duanwei_bojue_up,fx_duanwei_bojue_down","crosswarinterval_1_11",12,4300,4699,0,2700,"1=112003=1500=0,1=102001=600=0","1=112003=2000=0,1=102001=1200=0,1=100211=13=0",""},_mt),
[12]=_set({12,"crosswarinterval_0_12","d2730fFF",12,"crossGrading_icon_112","fx_duanwei_bojue_up,fx_duanwei_bojue_down","crosswarinterval_1_12",13,4700,4999,0,3000,"1=112003=1625=0,1=102001=650=0","1=112003=2200=0,1=102001=1400=0,1=100211=14=0",""},_mt),
[13]=_set({13,"crosswarinterval_0_13","c81313FF",13,"crossGrading_icon_113","fx_duanwei_houjue_up,fx_duanwei_houjue_down","crosswarinterval_1_13",14,5000,5299,0,3300,"1=112003=1750=0,1=102001=700=0","1=112003=2400=0,1=102001=1600=0,1=100211=16=0","1=1501006=1=0"},_mt),
[14]=_set({14,"crosswarinterval_0_14","c81313FF",14,"crossGrading_icon_114","fx_duanwei_gongjue_up,fx_duanwei_gongjue_down","crosswarinterval_1_14",15,5300,5699,0,3700,"1=112003=1875=0,1=102001=800=0","1=112003=2700=0,1=102001=1800=0,1=100211=18=0","1=1501005=1=0"},_mt),
[15]=_set({15,"crosswarinterval_0_15","817900FF",15,"crossGrading_icon_115","fx_duanwei_qinwang_up,fx_duanwei_qinwang_down","crosswarinterval_1_15",0,5700,-1,20,4000,"1=112003=2000=0,1=102001=1000=0,1=100212=2=0","1=112003=3000=0,1=102001=2000=0,1=100211=20=0","1=1501004=1=0"},_mt)
}

return _datas