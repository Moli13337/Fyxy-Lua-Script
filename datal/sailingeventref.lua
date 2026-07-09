local _keys = {refId=1,type=2,map=3,name=4,priority=5,showType=6,overlayType=7,skipType=8,resType=9,res=10,resSite=11,resSize=12,prefab=13,prefabSize=14,monster=15,monsterType=16,reward=17,parameter=18,choose=19,plot=20,star=21,image=22,config=23,gameHelperReward=24}
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
[1101]=_set({1101,1,1,"sailingevent_0_1101",0,1,0,0,2,"XR_Baige01","0;0","0.8","XR_Baige01","2","2=1001",1,1101,"","10001",0,"","","",1101},_mt),
[1102]=_set({1102,1,1,"sailingevent_0_1102",0,1,0,0,2,"XR_Huli01","0;0","0.8","XR_Huli01","2","2=1001",1,1101,"","10001",0,"","","",1101},_mt),
[1103]=_set({1103,1,1,"sailingevent_0_1103",0,1,0,0,2,"XR_Jiangshiniang01","0;0","0.8","XR_Jiangshiniang01","2","2=1001",1,1101,"","10001",0,"","","",1101},_mt),
[1121]=_set({1121,1,1,"sailingevent_0_1121",0,1,0,0,2,"XR_Tuzi01","0;0","0.8","XR_Tuzi01","2","2=1002",2,1121,"","10001",0,"","","",1121},_mt),
[1303]=_set({1303,14,1,"sailingevent_0_1303",0,0,0,0,1,"dreamTrip_icon_17","0;12","1.1","dreamTrip_icon_17","2","",0,1303,"","10002",0,"","","",1303},_mt),
[1304]=_set({1304,14,1,"sailingevent_0_1304",0,0,0,0,1,"dreamTrip_icon_17","0;12","1.1","dreamTrip_icon_17","2","",0,1304,"","10002",0,"","","",1304},_mt),
[1307]=_set({1307,14,1,"sailingevent_0_1307",0,0,0,0,1,"dreamTrip_icon_17","0;12","1.1","dreamTrip_icon_17","2","",0,1307,"","10002",0,"","","",1307},_mt),
[1701]=_set({1701,7,1,"sailingevent_0_1701",0,0,0,0,1,"dreamTrip_icon_10_1","0;23","0.8","dreamTrip_icon_10_1","1.2","",0,0,"0.5;2=250;3=250;4=250;5=250","10003",0,"","","",0},_mt),
[2301]=_set({2301,13,1,"sailingevent_0_2301",1,0,0,1,2,"XR_Heishanyang01","0;0","1.2","XR_Heishanyang01","2","2=1003",3,0,"","10004",0,"","","",0},_mt),
[2601]=_set({2601,20,1,"sailingevent_0_2601",1,0,0,0,1,"dreamTrip_role_2","0;27","0.4","dreamTrip_role_2","1","",0,2601,"2602","10005",0,"","","",2602},_mt),
[3601]=_set({3601,27,1,"sailingevent_0_3601",1,0,0,0,1,"dreamTrip_FlyEvent_icon_1","0;10","0.4","dreamTrip_FlyEvent_icon_1","2","",0,0,"","10006",0,"","","",0},_mt),
[21101]=_set({21101,1,2,"sailingevent_0_21101",0,1,0,0,2,"XR_Baige01","0;0","0.8","XR_Baige01","2","2=1001",1,1101,"","20001",0,"","","",1101},_mt),
[21102]=_set({21102,1,2,"sailingevent_0_21102",0,1,0,0,2,"XR_Huli01","0;0","0.8","XR_Huli01","2","2=1001",1,1101,"","20001",0,"","","",1101},_mt),
[21103]=_set({21103,1,2,"sailingevent_0_21103",0,1,0,0,2,"XR_Jiangshiniang01","0;0","0.8","XR_Jiangshiniang01","2","2=1001",1,1101,"","20001",0,"","","",1101},_mt),
[21121]=_set({21121,1,2,"sailingevent_0_21121",0,1,0,0,2,"XR_Tuzi01","0;0","0.8","XR_Tuzi01","2","2=1002",2,1121,"","20001",0,"","","",1121},_mt),
[22301]=_set({22301,13,2,"sailingevent_0_22301",1,0,0,1,2,"XR_Heishanyang01","0;0","1.2","XR_Heishanyang01","2","2=1003",3,0,"","20002",0,"","","",0},_mt),
[22404]=_set({22404,21,2,"sailingevent_0_22404",1,0,0,0,1,"dreamTrip_icon_36","0;14","1","dreamTrip_icon_36","2","",0,6001,"6002","20003",0,"","","",6002},_mt),
[22405]=_set({22405,22,2,"sailingevent_0_22405",1,0,0,0,1,"dreamTrip_icon_3_1","0;27","0.8","dreamTrip_icon_3_1","2","",0,9001,"9002","20004",0,"","","",9002},_mt),
[21304]=_set({21304,14,2,"sailingevent_0_21304",0,0,0,0,1,"dreamTrip_icon_17","0;12","1","dreamTrip_icon_17","2","",0,1303,"","20005",0,"","","",1303},_mt),
[21305]=_set({21305,14,2,"sailingevent_0_21305",0,0,0,0,1,"dreamTrip_icon_17","0;12","1","dreamTrip_icon_17","2","",0,1304,"","20005",0,"","","",1304},_mt),
[21306]=_set({21306,14,2,"sailingevent_0_21306",0,0,0,0,1,"dreamTrip_icon_17","0;12","1","dreamTrip_icon_17","2","",0,1307,"","20005",0,"","","",1307},_mt),
[21307]=_set({21307,27,1,"sailingevent_0_21307",1,0,0,0,1,"dreamTrip_FlyEvent_icon_1","0;10","0.4","dreamTrip_FlyEvent_icon_1","2","",0,0,"","20006",0,"","","",0},_mt)
}

return _datas