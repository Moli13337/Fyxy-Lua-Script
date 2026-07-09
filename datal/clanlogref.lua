local _keys = {refId=1,type=2,content=3,paraType=4}
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
[1]=_set({1,1,"clanlog_0_1",""},_mt),
[2]=_set({2,1,"clanlog_0_2",""},_mt),
[3]=_set({3,1,"clanlog_0_3",""},_mt),
[4]=_set({4,1,"clanlog_0_4",""},_mt),
[5]=_set({5,1,"clanlog_0_5",""},_mt),
[6]=_set({6,1,"clanlog_0_6",""},_mt),
[9]=_set({9,4,"clanlog_0_9","2=2"},_mt),
[10]=_set({10,4,"clanlog_0_10",""},_mt),
[11]=_set({11,4,"clanlog_0_11","2=2"},_mt),
[12]=_set({12,4,"clanlog_0_12",""},_mt),
[13]=_set({13,4,"clanlog_0_13",""},_mt),
[15]=_set({15,2,"clanlog_0_15","2=3"},_mt),
[19]=_set({19,3,"clanlog_0_19","2=1|3=1|5=2"},_mt),
[23]=_set({23,6,"clanlog_0_23","2=3"},_mt),
[24]=_set({24,6,"clanlog_0_24","2=1|3=1|5=2"},_mt),
[25]=_set({25,6,"clanlog_0_25","2=3"},_mt),
[26]=_set({26,6,"clanlog_0_26","2=3"},_mt),
[27]=_set({27,6,"clanlog_0_27","2=3"},_mt)
}

return _datas