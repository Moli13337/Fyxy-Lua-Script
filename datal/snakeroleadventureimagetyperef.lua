local _keys = {refId=1,bigType=2,type=3,name=4,sortOpen=5}
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
[101]=_set({101,1,1,"snakeroleadventureimagetype_0_101",0},_mt),
[102]=_set({102,1,2,"snakeroleadventureimagetype_0_102",0},_mt),
[103]=_set({103,1,3,"snakeroleadventureimagetype_0_103",0},_mt),
[201]=_set({201,2,1,"snakeroleadventureimagetype_0_201",0},_mt),
[202]=_set({202,2,2,"snakeroleadventureimagetype_0_202",0},_mt),
[301]=_set({301,3,1,"snakeroleadventureimagetype_0_301",0},_mt),
[401]=_set({401,4,1,"snakeroleadventureimagetype_0_401",0},_mt),
[402]=_set({402,4,3,"snakeroleadventureimagetype_0_402",0},_mt),
[403]=_set({403,4,4,"snakeroleadventureimagetype_0_403",0},_mt),
[404]=_set({404,4,2,"snakeroleadventureimagetype_0_404",0},_mt),
[701]=_set({701,7,1,"snakeroleadventureimagetype_0_701",0},_mt),
[801]=_set({801,8,1,"snakeroleadventureimagetype_0_801",0},_mt)
}

return _datas