local _keys = {refId=1,name=2,icon=3,sort=4,functionOpenRefId=5}
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
[1]=_set({1,"inneractivitytype_0_1","activity_btn_2",1,"10401000"},_mt),
[2]=_set({2,"inneractivitytype_0_2","activity_btn_3",2,"10402000"},_mt),
[3]=_set({3,"inneractivitytype_0_3","activity_btn_1",3,"10403000"},_mt)
}

return _datas