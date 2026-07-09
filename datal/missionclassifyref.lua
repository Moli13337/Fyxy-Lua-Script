local _keys = {refId=1,title=2,frontEnd=3,finishTips=4,functionOpenRefId=5}
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
[1]=_set({1,"missionclassify_0_1",1,1,11500001},_mt),
[2]=_set({2,"missionclassify_0_2",1,1,11500002},_mt),
[3]=_set({3,"missionclassify_0_3",1,1,11500003},_mt),
[4]=_set({4,"missionclassify_0_4",0,0,11500002},_mt),
[5]=_set({5,"missionclassify_0_5",0,0,11500003},_mt),
[21]=_set({21,"missionclassify_0_21",1,1,11502002},_mt),
[22]=_set({22,"missionclassify_0_22",1,1,11502002},_mt),
[23]=_set({23,"missionclassify_0_23",1,1,11502002},_mt),
[31]=_set({31,"missionclassify_0_31",1,0,17200000},_mt),
[41]=_set({41,"missionclassify_0_41",1,0,17701000},_mt),
[42]=_set({42,"missionclassify_0_42",1,0,17701000},_mt),
[43]=_set({43,"missionclassify_0_43",1,0,17701001},_mt),
[44]=_set({44,"missionclassify_0_44",1,0,17701001},_mt),
[45]=_set({45,"missionclassify_0_45",1,0,17701001},_mt),
[46]=_set({46,"missionclassify_0_46",1,0,17701002},_mt),
[47]=_set({47,"missionclassify_0_47",1,0,17701002},_mt),
[48]=_set({48,"missionclassify_0_48",1,0,17701002},_mt),
[51]=_set({51,"missionclassify_0_51",1,0,17701000},_mt),
[52]=_set({52,"missionclassify_0_52",1,0,17701000},_mt),
[61]=_set({61,"missionclassify_0_61",1,0,12111000},_mt),
[62]=_set({62,"missionclassify_0_62",1,0,12111000},_mt),
[71]=_set({71,"missionclassify_0_71",1,0,11400000},_mt),
[72]=_set({72,"missionclassify_0_72",1,0,18003000},_mt),
[73]=_set({73,"missionclassify_0_73",1,1,11500002},_mt),
[82]=_set({82,"missionclassify_0_82",1,0,18004000},_mt),
[91]=_set({91,"missionclassify_0_91",1,0,22000000},_mt),
[92]=_set({92,"missionclassify_0_92",1,0,22000000},_mt),
[93]=_set({93,"missionclassify_0_93",1,0,22000000},_mt),
[110]=_set({110,"missionclassify_0_110",1,0,28000000},_mt),
[111]=_set({111,"missionclassify_0_111",1,0,28000000},_mt),
[112]=_set({112,"missionclassify_0_112",1,0,28000000},_mt),
[113]=_set({113,"missionclassify_0_113",1,0,28000000},_mt),
[151]=_set({151,"missionclassify_0_151",1,0,29000000},_mt),
[152]=_set({152,"missionclassify_0_152",1,0,29000000},_mt),
[161]=_set({161,"missionclassify_0_161",1,0,23000107},_mt),
[171]=_set({171,"missionclassify_0_171",1,0,23000111},_mt),
[180]=_set({180,"missionclassify_0_180",1,0,35000000},_mt),
[181]=_set({181,"missionclassify_0_181",1,0,35000000},_mt),
[182]=_set({182,"missionclassify_0_182",1,0,21008100},_mt),
[183]=_set({183,"missionclassify_0_183",1,0,16800000},_mt),
[184]=_set({184,"missionclassify_0_184",1,0,16800000},_mt),
[190]=_set({190,"missionclassify_0_190",1,0,10010005},_mt)
}

return _datas