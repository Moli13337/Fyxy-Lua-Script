local _keys = {refId=1,tabId=2,open=3,name=4,executeName=5,functionType=6,functionDetails=7,desd=8,additionalData=9,displayingResults=10,titleDescription=11,desd1=12}
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
[1001]=_set({1001,101,"1=35","assistantfunction_0_1001","assistantfunction_1_1001","1","1","assistantfunction_2_1001","","1","",""},_mt),
[1002]=_set({1002,101,"1=35","assistantfunction_0_1002","assistantfunction_1_1002","1","1","assistantfunction_2_1002","","1","",""},_mt),
[1003]=_set({1003,101,"1=35","assistantfunction_0_1003","assistantfunction_1_1003","1","1","assistantfunction_2_1003","","1","",""},_mt),
[1021]=_set({1021,102,"1=35","assistantfunction_0_1021","assistantfunction_1_1021","1","1","assistantfunction_2_1021","","1","",""},_mt),
[1022]=_set({1022,102,"1=35","assistantfunction_0_1022","assistantfunction_1_1022","1","1","assistantfunction_2_1022","","1","",""},_mt),
[1023]=_set({1023,102,"1=35","assistantfunction_0_1023","assistantfunction_1_1023","1","1","assistantfunction_2_1023","","1","",""},_mt),
[1024]=_set({1024,102,"1=35","assistantfunction_0_1024","assistantfunction_1_1024","1","1","assistantfunction_2_1024","","1","",""},_mt),
[1031]=_set({1031,103,"1=35","assistantfunction_0_1031","assistantfunction_1_1031","1","1","assistantfunction_2_1031","","1","",""},_mt),
[1032]=_set({1032,103,"1=35","assistantfunction_0_1032","assistantfunction_1_1032","1","1","assistantfunction_2_1032","","1","",""},_mt),
[1033]=_set({1033,103,"1=35","assistantfunction_0_1033","assistantfunction_1_1033","1","1","assistantfunction_2_1033","","1","",""},_mt),
[1034]=_set({1034,103,"1=35","assistantfunction_0_1034","assistantfunction_1_1034","1","1","assistantfunction_2_1034","","1","",""},_mt),
[1035]=_set({1035,103,"1=35","assistantfunction_0_1035","assistantfunction_1_1035","1","1","assistantfunction_2_1035","","1","",""},_mt),
[1041]=_set({1041,104,"1=35","assistantfunction_0_1041","assistantfunction_1_1041","1","1","assistantfunction_2_1041","","1","",""},_mt),
[1051]=_set({1051,105,"1=35","assistantfunction_0_1051","assistantfunction_1_1051","1","1","assistantfunction_2_1051","","1","",""},_mt),
[1052]=_set({1052,105,"1=35","assistantfunction_0_1052","assistantfunction_1_1052","4","0","assistantfunction_2_1052","","1","",""},_mt),
[1053]=_set({1053,105,"1=35","assistantfunction_0_1053","assistantfunction_1_1053","4","0","assistantfunction_2_1053","","1","",""},_mt),
[1061]=_set({1061,106,"1=35","assistantfunction_0_1061","assistantfunction_1_1061","1","1","assistantfunction_2_1061","","1","",""},_mt),
[1062]=_set({1062,106,"1=35","assistantfunction_0_1062","assistantfunction_1_1062","1","1","assistantfunction_2_1062","","1","",""},_mt),
[1071]=_set({1071,107,"1=35","assistantfunction_0_1071","assistantfunction_1_1071","1","1","assistantfunction_2_1071","","1","",""},_mt),
[1072]=_set({1072,107,"1=35","assistantfunction_0_1072","assistantfunction_1_1072","4","0","assistantfunction_2_1072","","1","",""},_mt),
[1081]=_set({1081,107,"1=35","assistantfunction_0_1081","assistantfunction_1_1081","3","1|2|3|4|5|99","assistantfunction_2_1081","1|2|3|4|5|99","0","",""},_mt),
[1082]=_set({1082,107,"1=35","assistantfunction_0_1082","assistantfunction_1_1082","4","0","assistantfunction_2_1082","","0","",""},_mt),
[1083]=_set({1083,107,"1=35","assistantfunction_0_1083","assistantfunction_1_1083","1","1","assistantfunction_2_1083","","1","",""},_mt),
[1091]=_set({1091,109,"1=35","assistantfunction_0_1091","assistantfunction_1_1091","1","1","assistantfunction_2_1091","","1","",""},_mt),
[1092]=_set({1092,109,"1=35","assistantfunction_0_1092","assistantfunction_1_1092","2","1","assistantfunction_2_1092","","0","",""},_mt),
[1093]=_set({1093,109,"1=35","assistantfunction_0_1093","assistantfunction_1_1093","4","3","assistantfunction_2_1093","","0","",""},_mt),
[1101]=_set({1101,110,"1=50,5=1","assistantfunction_0_1101","assistantfunction_1_1101","4","0","assistantfunction_2_1101","","1","",""},_mt),
[1102]=_set({1102,110,"1=50,5=1","assistantfunction_0_1102","assistantfunction_1_1102","4","0","assistantfunction_2_1102","","1","",""},_mt),
[1103]=_set({1103,110,"1=50,5=1","assistantfunction_0_1103","assistantfunction_1_1103","4","0","assistantfunction_2_1103","","1","",""},_mt),
[1111]=_set({1111,111,"1=50,5=1","assistantfunction_0_1111","assistantfunction_1_1111","1","1","assistantfunction_2_1111","","1","",""},_mt),
[1112]=_set({1112,111,"1=50,5=1","assistantfunction_0_1112","assistantfunction_1_1112","4","1","assistantfunction_2_1112","","1","",""},_mt),
[1121]=_set({1121,112,"1=50","assistantfunction_0_1121","assistantfunction_1_1121","1","2","assistantfunction_2_1121","","1","",""},_mt),
[1122]=_set({1122,112,"1=50","assistantfunction_0_1122","assistantfunction_1_1122","4","2","assistantfunction_2_1122","","1","",""},_mt),
[1123]=_set({1123,112,"1=50","assistantfunction_0_1123","assistantfunction_1_1123","4","2","assistantfunction_2_1123","","1","",""},_mt),
[1124]=_set({1124,112,"1=50","assistantfunction_0_1124","assistantfunction_1_1124","4","2","assistantfunction_2_1124","","1","",""},_mt),
[1125]=_set({1125,112,"1=50","assistantfunction_0_1125","assistantfunction_1_1125","4","2","assistantfunction_2_1125","","1","",""},_mt),
[1131]=_set({1131,113,"1=40","assistantfunction_0_1131","assistantfunction_1_1131","4","5","assistantfunction_2_1131","","1","",""},_mt),
[1132]=_set({1132,113,"1=40","assistantfunction_0_1132","assistantfunction_1_1132","4","0","assistantfunction_2_1132","","0","",""},_mt),
[1141]=_set({1141,114,"1=50","assistantfunction_0_1141","","","","","","1","",""},_mt),
[1151]=_set({1151,115,"1=35","assistantfunction_0_1151","assistantfunction_1_1151","1","1","assistantfunction_2_1151","","1","",""},_mt),
[1152]=_set({1152,115,"1=35","assistantfunction_0_1152","assistantfunction_1_1152","1","1","assistantfunction_2_1152","","1","",""},_mt),
[1153]=_set({1153,115,"1=35","assistantfunction_0_1153","assistantfunction_1_1153","2","1","assistantfunction_2_1153","1001|1002|1003|1004|1005","1","",""},_mt),
[1154]=_set({1154,115,"1=35","assistantfunction_0_1154","assistantfunction_1_1154","2","1","assistantfunction_2_1154","","0","",""},_mt),
[1161]=_set({1161,116,"1=35","","","5","1001|1002|1003|1021|1022|1023|1024|1031|1032|1033|1034|1035|1041|1051","assistantfunction_2_1161","","0","",""},_mt)
}

return _datas