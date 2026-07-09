local _keys = {refId=1,type=2,name=3,icon=4,needLv=5,positionValue=6}
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
[1]=_set({1,1,"battleformation_0_1","formation_icon_1",1,"1=2,2=4,3=7,4=8,5=9,6=10"},_mt),
[2]=_set({2,1,"battleformation_0_2","formation_icon_2",20,"1=2,2=5,3=6,4=8,5=9,6=10"},_mt),
[3]=_set({3,1,"battleformation_0_3","formation_icon_3",30,"1=2,2=4,3=5,4=6,5=7,6=9"},_mt),
[4]=_set({4,1,"battleformation_0_4","formation_icon_4",40,"1=1,2=2,3=3,4=5,5=6,6=9"},_mt),
[5]=_set({5,1,"battleformation_0_5","formation_icon_5",50,"1=1,2=3,3=5,4=6,5=8,6=10"},_mt),
[6]=_set({6,1,"battleformation_0_6","formation_icon_6",60,"1=1,2=2,3=3,4=4,5=7,6=9"},_mt)
}

return _datas