local _keys = {refId=1,name=2,sort=3,condition=4,desc=5}
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
[1]=_set({1,"halidomtype_0_1",1,0,""},_mt),
[2]=_set({2,"halidomtype_0_2",2,2,"halidomtype_1_2"},_mt),
[3]=_set({3,"halidomtype_0_3",3,3,"halidomtype_1_3"},_mt),
[4]=_set({4,"halidomtype_0_4",4,0,""},_mt)
}

return _datas