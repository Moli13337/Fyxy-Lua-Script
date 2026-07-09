local _keys = {refId=1,type=2,sort=3,icon=4,name=5,des=6,jump=7}
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
[1]=_set({1,1,1,"icon_item_104001","growthcompare_0_1","growthcompare_1_1","10300000;16502000"},_mt),
[2]=_set({2,2,3,"icon_equip_203165","growthcompare_0_2","growthcompare_1_2","10300000"},_mt),
[3]=_set({3,3,2,"icon_item_star","growthcompare_0_3","growthcompare_1_3","10300000"},_mt),
[4]=_set({4,4,4,"icon_item_160008","growthcompare_0_4","growthcompare_1_4","10300000"},_mt),
[5]=_set({5,5,5,"icon_item_skill","growthcompare_0_5","growthcompare_1_5","12101000"},_mt),
[6]=_set({6,6,6,"icon_item_1800001","growthcompare_0_6","growthcompare_1_6","17400000"},_mt)
}

return _datas