local _keys = {refId=1,name=2,btnIcon=3,code=4,closeAll=5,tip=6}
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
[1001]=_set({1001,"sourceconfig_0_1001","public_btn_1_1",1001,0,""},_mt),
[1002]=_set({1002,"sourceconfig_0_1002","public_btn_1_2",1002,0,""},_mt),
[1003]=_set({1003,"sourceconfig_0_1003","public_btn_1_2",1003,0,""},_mt),
[1004]=_set({1004,"sourceconfig_0_1004","public_btn_1_2",1004,0,""},_mt),
[1005]=_set({1005,"sourceconfig_0_1005","public_btn_1_2",1005,0,""},_mt),
[1006]=_set({1006,"sourceconfig_0_1006","public_btn_1_2",1006,0,""},_mt),
[1007]=_set({1007,"sourceconfig_0_1007","public_btn_1_2",1007,0,""},_mt),
[1008]=_set({1008,"sourceconfig_0_1008","public_btn_1_3",1008,0,""},_mt),
[1009]=_set({1009,"sourceconfig_0_1009","public_btn_1_2",1009,0,""},_mt),
[1010]=_set({1010,"sourceconfig_0_1010","public_btn_1_3",1010,0,""},_mt),
[1011]=_set({1011,"sourceconfig_0_1011","public_btn_1_1",1011,0,""},_mt),
[1012]=_set({1012,"sourceconfig_0_1012","public_btn_1_2",1012,0,""},_mt),
[1013]=_set({1013,"sourceconfig_0_1013","public_btn_1_2",1013,0,""},_mt),
[1014]=_set({1014,"sourceconfig_0_1014","public_btn_1_2",1014,0,""},_mt),
[1015]=_set({1015,"sourceconfig_0_1015","public_btn_1_2",1015,0,""},_mt),
[1016]=_set({1016,"sourceconfig_0_1016","public_btn_1_2",1016,0,""},_mt),
[1017]=_set({1017,"sourceconfig_0_1017","public_btn_1_2",1017,0,""},_mt),
[1018]=_set({1018,"sourceconfig_0_1018","public_btn_1_1",1018,0,""},_mt),
[1019]=_set({1019,"sourceconfig_0_1019","public_btn_1_2",1019,0,""},_mt),
[1020]=_set({1020,"sourceconfig_0_1020","public_btn_1_1",1018,0,""},_mt),
[1021]=_set({1021,"sourceconfig_0_1021","public_btn_1_2",1021,0,""},_mt),
[1022]=_set({1022,"sourceconfig_0_1022","public_btn_1_2",1022,0,""},_mt),
[1023]=_set({1023,"sourceconfig_0_1023","public_btn_1_2",1023,0,""},_mt),
[1024]=_set({1024,"sourceconfig_0_1024","public_btn_1_2",1024,0,""},_mt),
[1025]=_set({1025,"sourceconfig_0_1025","public_btn_1_2",1025,0,""},_mt),
[1026]=_set({1026,"sourceconfig_0_1026","public_btn_1_1",1026,0,""},_mt),
[1027]=_set({1027,"sourceconfig_0_1027","public_btn_1_2",1027,0,""},_mt),
[1028]=_set({1028,"sourceconfig_0_1028","public_btn_1_3",1028,0,""},_mt),
[1029]=_set({1029,"sourceconfig_0_1029","public_btn_1_2",1029,0,""},_mt),
[1030]=_set({1030,"sourceconfig_0_1030","public_btn_1_2",1030,0,""},_mt),
[1031]=_set({1031,"sourceconfig_0_1031","public_btn_1_2",1031,0,""},_mt),
[1032]=_set({1032,"sourceconfig_0_1032","public_btn_1_3",1032,0,""},_mt),
[1033]=_set({1033,"sourceconfig_0_1033","public_btn_1_3",1033,0,""},_mt),
[1034]=_set({1034,"sourceconfig_0_1034","public_btn_1_1",1034,0,""},_mt),
[1035]=_set({1035,"sourceconfig_0_1035","public_btn_1_1",1035,0,""},_mt),
[1036]=_set({1036,"sourceconfig_0_1036","public_btn_1_1",1036,0,""},_mt),
[1037]=_set({1037,"sourceconfig_0_1037","public_btn_1_2",1037,0,""},_mt),
[1038]=_set({1038,"sourceconfig_0_1038","public_btn_1_3",1038,0,""},_mt),
[1039]=_set({1039,"sourceconfig_0_1039","public_btn_1_3",1039,0,""},_mt),
[1040]=_set({1040,"sourceconfig_0_1040","public_btn_1_2",1040,0,""},_mt),
[1041]=_set({1041,"sourceconfig_0_1041","public_btn_1_2",1041,0,""},_mt),
[1042]=_set({1042,"sourceconfig_0_1042","public_btn_1_3",1042,0,""},_mt)
}

return _datas