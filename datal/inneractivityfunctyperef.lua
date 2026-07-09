local _keys = {refId=1,name=2,icon=3,type=4,sort=5,eModel=6,uniqueJump=7,functionOpenRefId=8,limitLv=9,redPoint=10,eff=11,packId=12}
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
[1]=_set({1,"inneractivityfunctype_0_1","mainui_privilege_1",5,120,9999,99990001,10401101,9999,10401102,"",""},_mt),
[2]=_set({2,"inneractivityfunctype_0_2","mainui_privishop",4,120,9999,99990001,10401101,50,0,"",""},_mt),
[6]=_set({6,"inneractivityfunctype_0_6","mainui_dreamcollege_1",4,5,10000,17700000,17700000,9999,0,"",""},_mt),
[12]=_set({12,"inneractivityfunctype_0_12","activity_icon_bind",1,120,9993,99930001,10401601,9999,0,"",""},_mt),
[17]=_set({17,"inneractivityfunctype_0_17","mainui_3chuzhi",4,2,9990,99900001,10401701,9999,0,"",""},_mt),
[18]=_set({18,"inneractivityfunctype_0_18","icon_popup_7",6,2,10001,10405101,10405101,1,0,"1=fx_tehuishangdian",""},_mt),
[19]=_set({19,"inneractivityfunctype_0_19","icon_popup_7",6,2,164,10405131,10405131,9999,0,"1=fx_tehuishangdian",""},_mt),
[20]=_set({20,"inneractivityfunctype_0_20","mainui_icon_weChat_2",4,2,10003,100030001,10010005,9999,0,"",""},_mt),
[21]=_set({21,"inneractivityfunctype_0_21","mainui_icon_weChat_1",4,2,10005,100030002,10010006,9999,0,"",""},_mt),
[22]=_set({22,"inneractivityfunctype_0_22","mainui_feed",4,3,10009,0,10010007,9999,0,"",""},_mt)
}

return _datas