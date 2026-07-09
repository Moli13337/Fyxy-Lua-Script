local _keys = {refId=1,type=2,name=3,icon=4,heroId=5,skinId=6,skinIdDmm=7}
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
[20001]=_set({20001,2,"characterskin_0_20001","heroskin_show_1",0,"370503,470503,273103","370503,470503,273103"},_mt),
[20101]=_set({20101,2,"characterskin_0_20101","heroskin_show_2",0,"170303,270303,470603","170303,270303,470603"},_mt),
[20301]=_set({20301,2,"characterskin_0_20301","heroskin_show_4",0,"270403,570503,370303","270403,570503,370303"},_mt),
[20501]=_set({20501,2,"characterskin_0_20501","heroskin_show_6",0,"470303,470203","470303,470203"},_mt),
[20601]=_set({20601,2,"characterskin_0_20601","heroskin_show_7",0,"470103,570303,170404,270304","470103,570303,170404,270304"},_mt),
[20701]=_set({20701,2,"characterskin_0_20701","heroskin_show_8",0,"370403,270203,473703","370403,270203,473703"},_mt),
[20801]=_set({20801,2,"characterskin_0_20801","heroskin_show_9",0,"570803,470703,173103,470804","570803,470703,173103,470804"},_mt),
[20901]=_set({20901,2,"characterskin_0_20901","heroskin_show_10",0,"570703,570804","570703,570804"},_mt),
[21101]=_set({21101,2,"characterskin_0_21101","heroskin_show_12",0,"170503,173203","170503,173203"},_mt),
[21201]=_set({21201,2,"characterskin_0_21201","heroskin_show_13",0,"470803,570903","470803,570903"},_mt),
[21301]=_set({21301,2,"characterskin_0_21301","heroskin_show_5",0,"473203,570603","473203,570603"},_mt),
[21501]=_set({21501,2,"characterskin_0_21501","heroskin_show_15",0,"571203,571003,570403","571203,571003,570403"},_mt),
[21701]=_set({21701,2,"characterskin_0_21701","heroskin_show_17",0,"471103","471103"},_mt)
}

return _datas