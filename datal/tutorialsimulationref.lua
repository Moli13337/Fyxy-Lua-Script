local _keys = {refId=1,name=2,sort=3,tabIcon=4,monster=5,desc=6}
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
[1]=_set({1,"tutorialsimulation_0_1",1,"college_ad_3",111001,"tutorialsimulation_1_1"},_mt),
[2]=_set({2,"tutorialsimulation_0_2",2,"college_ad_4",111002,"tutorialsimulation_1_2"},_mt),
[3]=_set({3,"tutorialsimulation_0_3",3,"college_ad_5",0,"tutorialsimulation_1_3"},_mt)
}

return _datas