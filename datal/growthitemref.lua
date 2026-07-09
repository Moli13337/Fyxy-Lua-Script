local _keys = {refId=1,sort=2,type=3,icon=4,name=5,description=6}
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
[1]=_set({1,1,1,"icon_item_girl","growthitem_0_1","growthitem_1_1"},_mt),
[2]=_set({2,2,2,"icon_item_dia","growthitem_0_2","growthitem_1_2"},_mt),
[3]=_set({3,3,3,"icon_item_gold","growthitem_0_3","growthitem_1_3"},_mt),
[4]=_set({4,4,4,"icon_item_100110","growthitem_0_4","growthitem_1_4"},_mt),
[5]=_set({5,5,5,"icon_item_104001","growthitem_0_5","growthitem_1_5"},_mt),
[6]=_set({6,6,6,"icon_equip_203165","growthitem_0_6","growthitem_1_6"},_mt),
[7]=_set({7,7,7,"icon_item_160008","growthitem_0_7","growthitem_1_7"},_mt),
[8]=_set({8,8,8,"icon_item_1800001","growthitem_0_8","growthitem_1_8"},_mt),
[9]=_set({9,9,9,"icon_item_108202","growthitem_0_9","growthitem_1_9"},_mt)
}

return _datas