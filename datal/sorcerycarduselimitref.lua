local _keys = {refId=1,name=2,suitRace=3,suitCareer=4,suitHeroInitQuality=5,suitGender=6,suitHero=7}
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
[1]=_set({1,"sorcerycarduselimit_0_1","","1","","",""},_mt),
[2]=_set({2,"sorcerycarduselimit_0_2","","2","","",""},_mt),
[3]=_set({3,"sorcerycarduselimit_0_3","","3","","",""},_mt),
[4]=_set({4,"sorcerycarduselimit_0_4","","4","","",""},_mt),
[5]=_set({5,"sorcerycarduselimit_0_5","","1|2","","",""},_mt),
[6]=_set({6,"sorcerycarduselimit_0_6","","3|4","","",""},_mt),
[7]=_set({7,"sorcerycarduselimit_0_7","","","","",""},_mt)
}

return _datas