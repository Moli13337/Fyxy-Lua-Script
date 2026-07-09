local _keys = {refId=1,type=2,name=3,sort=4,icon=5,attr=6,attrShow=7,attrShowType=8,showImgPos=9,SkillId=10,golemDrawing=11,suitText=12,suitText1=13,power=14}
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
[1000]=_set({1000,1,"golemsuit_0_1000",1,"icon_item_270111","1=2=0.05=1","golem_icon_001",1,"0,-20",1050121,"golem_icon_001","golemsuit_1_1000","golemsuit_2_1000",40000},_mt),
[2000]=_set({2000,2,"golemsuit_0_2000",2,"icon_item_270211","204=1=0.05=1","golem_icon_002",1,"0,-20",1050221,"golem_icon_002","golemsuit_1_2000","golemsuit_2_2000",40000},_mt),
[3000]=_set({3000,3,"golemsuit_0_3000",3,"icon_item_270311","5=2=0.05=1","golem_icon_003",1,"0,-20",1050321,"golem_icon_003","golemsuit_1_3000","golemsuit_2_3000",40000},_mt),
[4000]=_set({4000,4,"golemsuit_0_4000",4,"icon_item_270411","203=1=0.1=1","golem_icon_004",1,"0,-20",1050421,"golem_icon_004","golemsuit_1_4000","golemsuit_2_4000",40000},_mt),
[5000]=_set({5000,5,"golemsuit_0_5000",5,"icon_item_270511","101=1=0.05=1","golem_icon_005",1,"0,-20",1060121,"golem_icon_005","golemsuit_1_5000","golemsuit_2_5000",40000},_mt),
[6000]=_set({6000,6,"golemsuit_0_6000",6,"icon_item_270611","4=2=0.05=1","golem_icon_006",1,"0,-20",1053121,"golem_icon_006","golemsuit_1_6000","golemsuit_2_6000",40000},_mt),
[7000]=_set({7000,7,"golemsuit_0_7000",7,"icon_item_270711","102=1=0.05=1","golem_icon_007",1,"0,-20",1053221,"golem_icon_007","golemsuit_1_7000","golemsuit_2_7000",40000},_mt),
[8000]=_set({8000,8,"golemsuit_0_8000",8,"icon_item_270811","3=2=0.05=1","golem_icon_008",1,"0,-20",1053321,"golem_icon_008","golemsuit_1_8000","golemsuit_2_8000",40000},_mt),
[9000]=_set({9000,9,"golemsuit_0_9000",9,"icon_item_270911","205=1=0.05=1","golem_icon_009",1,"0,-20",1053421,"golem_icon_009","golemsuit_1_9000","golemsuit_2_9000",40000},_mt),
[10000]=_set({10000,10,"golemsuit_0_10000",10,"icon_item_271011","214=1=0.1=1","golem_icon_010",1,"0,-20",1063121,"golem_icon_010","golemsuit_1_10000","golemsuit_2_10000",40000},_mt),
[11000]=_set({11000,11,"golemsuit_0_11000",11,"icon_item_271111","1=2=0.05=1","golem_icon_011",1,"0,-20",1056121,"golem_icon_011","golemsuit_1_11000","golemsuit_2_11000",40000},_mt),
[12000]=_set({12000,12,"golemsuit_0_12000",12,"icon_item_271211","201=1=0.05=1","golem_icon_012",1,"0,-20",1056221,"golem_icon_012","golemsuit_1_12000","golemsuit_2_12000",40000},_mt),
[13000]=_set({13000,13,"golemsuit_0_13000",13,"icon_item_271311","1=2=0.05=1","golem_icon_013",1,"0,-20",1056321,"golem_icon_013","golemsuit_1_13000","golemsuit_2_13000",40000},_mt),
[14000]=_set({14000,14,"golemsuit_0_14000",14,"icon_item_271411","3=2=0.05=1","golem_icon_014",1,"0,-20",1056421,"golem_icon_014","golemsuit_1_14000","golemsuit_2_14000",40000},_mt),
[15000]=_set({15000,15,"golemsuit_0_15000",15,"icon_item_271511","1=2=0.05=1","golem_icon_015",1,"0,-20",1066121,"golem_icon_015","golemsuit_1_15000","golemsuit_2_15000",40000},_mt),
[16000]=_set({16000,16,"golemsuit_0_16000",16,"icon_item_271611","204=1=0.01=1,5=2=0.01=1,1=2=0.01=1,205=1=0.01=1,102=1=0.01=1,104=1=0.01=1","golem_icon_016",1,"0,-20",1068121,"golem_icon_016","golemsuit_1_16000","golemsuit_2_16000",40000},_mt)
}

return _datas