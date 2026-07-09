local _keys = {refId=1,name=2,icon=3,welfareId=4,rmbNeed=5,item=6,rank=7,show=8}
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
[1]=_set({1,"topuppay_0_1","vip_icon_7",101,6,"1=100304=6",101,0},_mt),
[2]=_set({2,"topuppay_0_2","vip_icon_7",102,30,"1=100304=30",102,0},_mt),
[3]=_set({3,"topuppay_0_3","vip_icon_7",103,68,"1=100304=68",103,0},_mt),
[4]=_set({4,"topuppay_0_4","vip_icon_7",104,128,"1=100304=128",104,0},_mt),
[5]=_set({5,"topuppay_0_5","vip_icon_7",105,198,"1=100304=198",105,0},_mt),
[6]=_set({6,"topuppay_0_6","vip_icon_7",106,328,"1=100304=328",106,0},_mt),
[7]=_set({7,"topuppay_0_7","vip_icon_7",107,648,"1=100304=648",107,1},_mt)
}

return _datas