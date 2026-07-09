local _keys = {refId=1,runeClass=2,nextClass=3,upItem=4,freeUpItem=5,desc=6,upQuality=7,effectType=8,needQuality=9}
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
[1]=_set({1,0,2,"1=161008=30=0","206401=1","magicrunequenchingclass_0_1",206502,"1=5|1=6|2=7",206501},_mt),
[2]=_set({2,1,3,"1=161008=60=0","206401=2","magicrunequenchingclass_0_2",206503,"1=51|1=61|1=7|4=1=1",206502},_mt),
[3]=_set({3,2,4,"1=161008=90=0","206401=3","magicrunequenchingclass_0_3",206504,"1=52|1=62|1=71|4=2=1",206503},_mt),
[4]=_set({4,3,-1,"","","",0,"",0},_mt)
}

return _datas