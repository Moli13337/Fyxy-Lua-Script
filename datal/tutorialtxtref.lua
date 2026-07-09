local _keys = {refId=1,type=2,text=3,icon=4,iconSize=5,IconPos=6}
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
[1001]=_set({1001,1,"tutorialtxt_0_1001","","",0},_mt),
[1002]=_set({1002,1,"tutorialtxt_0_1002","","",0},_mt),
[1003]=_set({1003,1,"tutorialtxt_0_1003","","",0},_mt),
[1004]=_set({1004,1,"tutorialtxt_0_1004","","",0},_mt),
[1005]=_set({1005,1,"tutorialtxt_0_1005","","",0},_mt),
[1006]=_set({1006,1,"tutorialtxt_0_1006","","",0},_mt),
[1007]=_set({1007,1,"tutorialtxt_0_1007","","",0},_mt),
[1008]=_set({1008,1,"tutorialtxt_0_1008","","",0},_mt),
[2001]=_set({2001,1,"tutorialtxt_0_2001","","",0},_mt),
[2002]=_set({2002,1,"tutorialtxt_0_2002","","",0},_mt),
[2003]=_set({2003,1,"tutorialtxt_0_2003","","",0},_mt),
[2004]=_set({2004,1,"tutorialtxt_0_2004","","",0},_mt),
[2005]=_set({2005,1,"tutorialtxt_0_2005","","",0},_mt)
}

return _datas