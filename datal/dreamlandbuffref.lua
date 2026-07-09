local _keys = {refId=1,type=2,name=3,group=4,lv=5,nextLv=6,quality=7,frame=8,frameMin=9,skill=10,resId=11,tag=12,desc=13,upgradeType=14,range=15,fight=16}
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
[1701011]=_set({1701011,2,"wonderbuff_0_1701011",1701010,1,130002,4,"frame_bg_4","",130001,"icon_wonderland_130001","wonderbuff_1_1701011","wonderbuff_2_1701011",1,"",0.0375},_mt)
}

return _datas