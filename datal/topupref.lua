local _keys = {refId=1,name=2,icon=3,welfareId=4,rmbNeed=5,getDiamonds=6,vip=7,first=8,commonGive=9,rank=10}
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
[1]=_set({1,"topup_0_1","vip_icon_recharge_1",1,6,"60","60","180","0",1},_mt),
[2]=_set({2,"topup_0_2","vip_icon_recharge_2",2,30,"300","300","900","0",2},_mt),
[3]=_set({3,"topup_0_3","vip_icon_recharge_3",3,68,"680","680","2040","0",3},_mt),
[4]=_set({4,"topup_0_4","vip_icon_recharge_4",4,128,"1280","1280","3840","0",4},_mt),
[5]=_set({5,"topup_0_5","vip_icon_recharge_5",5,198,"1980","1980","5940","0",5},_mt),
[6]=_set({6,"topup_0_6","vip_icon_recharge_6",6,328,"3280","3280","9840","0",6},_mt),
[7]=_set({7,"topup_0_7","vip_icon_recharge_7",7,648,"6480","6480","19440","0",7},_mt)
}

return _datas