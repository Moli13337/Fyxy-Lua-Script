local _keys = {refId=1,name=2,pAvoidHurtValue=3,mAvoidHurtValue=4,jobIcon=5,formationg=6}
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
[1]=_set({1,"charactercareer_0_1",0.26,0.26,"public_career_icon_1","3,2"},_mt),
[2]=_set({2,"charactercareer_0_2",0.26,0.26,"public_career_icon_2","3,2"},_mt),
[3]=_set({3,"charactercareer_0_3",0.22,0.22,"public_career_icon_3","1,2"},_mt),
[4]=_set({4,"charactercareer_0_4",0.245,0.245,"public_career_icon_4","1,2"},_mt)
}

return _datas