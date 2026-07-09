local _keys = {refId=1,name=2,description=3,pushType=4,pushValue=5,content=6}
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
[1]=_set({1,"pushmessage_0_1","",1,"480","pushmessage_2_1"},_mt),
[2]=_set({2,"pushmessage_0_2","",2,"12:00:00","pushmessage_2_2"},_mt),
[3]=_set({3,"pushmessage_0_3","",2,"19:00:00","pushmessage_2_3"},_mt),
[4]=_set({4,"pushmessage_0_4","",3,"2=10:00:00","pushmessage_2_4"},_mt),
[5]=_set({5,"pushmessage_0_5","",3,"2=20:00:00","pushmessage_2_5"},_mt),
[101]=_set({101,"pushmessage_0_101","pushmessage_1_101",4,"","pushmessage_2_101"},_mt),
[104]=_set({104,"pushmessage_0_104","pushmessage_1_104",7,"","pushmessage_2_104"},_mt),
[105]=_set({105,"pushmessage_0_105","pushmessage_1_105",9,"","pushmessage_2_105"},_mt),
[106]=_set({106,"pushmessage_0_106","pushmessage_1_106",10,"","pushmessage_2_106"},_mt),
[107]=_set({107,"pushmessage_0_107","pushmessage_1_107",11,"","pushmessage_2_107"},_mt)
}

return _datas