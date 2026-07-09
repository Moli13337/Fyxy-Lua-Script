local _keys = {refId=1,name=2,description=3,skill=4,icon=5}
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
[1]=_set({1,"simulatematchskill_0_1","simulatematchskill_1_1","201101","icon_skill_rune1154"},_mt),
[2]=_set({2,"simulatematchskill_0_2","simulatematchskill_1_2","201201","icon_skill_rune1144"},_mt),
[3]=_set({3,"simulatematchskill_0_3","simulatematchskill_1_3","201301","icon_skill_rune1124"},_mt),
[4]=_set({4,"simulatematchskill_0_4","simulatematchskill_1_4","201401","icon_skill_530511"},_mt),
[5]=_set({5,"simulatematchskill_0_5","simulatematchskill_1_5","201501","icon_skill_120221"},_mt),
[6]=_set({6,"simulatematchskill_0_6","simulatematchskill_1_6","201601","icon_skill_rune1244"},_mt),
[7]=_set({7,"simulatematchskill_0_7","simulatematchskill_1_7","201701","icon_skill_rune1214"},_mt),
[8]=_set({8,"simulatematchskill_0_8","simulatematchskill_1_8","201801","icon_skill_rune1404"},_mt),
[9]=_set({9,"simulatematchskill_0_9","simulatematchskill_1_9","201901","icon_skill_rune1464"},_mt),
[10]=_set({10,"simulatematchskill_0_10","simulatematchskill_1_10","202001","icon_skill_rune1444"},_mt)
}

return _datas