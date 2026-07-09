local _keys = {refId=1,name=2,functionId=3,sort=4,bg=5,combatType=6,titleIcon=7,desc=8}
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
[1001]=_set({1001,"tutorialfunctionlist_0_1001",19101000,1,"college_ad_1",19,"college_icon1","tutorialfunctionlist_1_1001"},_mt),
[2001]=_set({2001,"tutorialfunctionlist_0_2001",19102000,3,"college_ad_2",191,"college_icon2","tutorialfunctionlist_1_2001"},_mt),
[3001]=_set({3001,"tutorialfunctionlist_0_3001",19103000,2,"college_ad_3",192,"college_icon3","tutorialfunctionlist_1_3001"},_mt),
[4001]=_set({4001,"tutorialfunctionlist_0_4001",12000000,4,"college_ad_4",0,"college_icon4","tutorialfunctionlist_1_4001"},_mt)
}

return _datas