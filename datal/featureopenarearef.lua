local _keys = {refId=1,openState=2,show=3,openTips=4}
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
[23000100]=_set({23000100,0,0,"featureopenarea_0_23000100"},_mt),
[21006000]=_set({21006000,0,0,"featureopenarea_0_21006000"},_mt),
[13910000]=_set({13910000,0,0,"featureopenarea_0_13910000"},_mt),
[27003000]=_set({27003000,0,0,"featureopenarea_0_27003000"},_mt),
[16800000]=_set({16800000,0,0,"featureopenarea_0_16800000"},_mt),
[14911003]=_set({14911003,0,0,"featureopenarea_0_14911003"},_mt),
[14600011]=_set({14600011,0,0,"featureopenarea_0_14600011"},_mt),
[10403701]=_set({10403701,0,0,"featureopenarea_0_10403701"},_mt),
[17701001]=_set({17701001,0,0,"featureopenarea_0_17701001"},_mt),
[17701002]=_set({17701002,0,0,"featureopenarea_0_17701002"},_mt),
[28000000]=_set({28000000,0,0,"featureopenarea_0_28000000"},_mt),
[28000001]=_set({28000001,0,0,"featureopenarea_0_28000001"},_mt),
[28000002]=_set({28000002,0,0,"featureopenarea_0_28000002"},_mt),
[28000003]=_set({28000003,0,0,"featureopenarea_0_28000003"},_mt),
[28000004]=_set({28000004,0,0,"featureopenarea_0_28000004"},_mt),
[28000005]=_set({28000005,0,0,"featureopenarea_0_28000005"},_mt),
[28000006]=_set({28000006,0,0,"featureopenarea_0_28000006"},_mt),
[28000100]=_set({28000100,0,0,"featureopenarea_0_28000100"},_mt),
[24000000]=_set({24000000,0,0,"featureopenarea_0_24000000"},_mt),
[16503000]=_set({16503000,0,0,"featureopenarea_0_16503000"},_mt),
[36000000]=_set({36000000,0,0,"featureopenarea_0_36000000"},_mt),
[36000010]=_set({36000010,0,0,"featureopenarea_0_36000010"},_mt),
[31000003]=_set({31000003,0,0,"featureopenarea_0_31000003"},_mt),
[31000001]=_set({31000001,0,0,"featureopenarea_0_31000001"},_mt),
[10401163]=_set({10401163,0,0,"featureopenarea_0_10401163"},_mt),
[29000000]=_set({29000000,0,0,"featureopenarea_0_29000000"},_mt),
[32000003]=_set({32000003,0,0,"featureopenarea_0_32000003"},_mt),
[37000001]=_set({37000001,0,0,"featureopenarea_0_37000001"},_mt),
[37000002]=_set({37000002,0,0,"featureopenarea_0_37000002"},_mt),
[14600151]=_set({14600151,0,0,"featureopenarea_0_14600151"},_mt)
}

return _datas