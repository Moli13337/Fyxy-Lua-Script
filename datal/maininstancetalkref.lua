local _keys = {refId=1,des=2,level=3,weight=4}
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
[1]=_set({1,"maininstancetalk_0_1",1,100},_mt),
[2]=_set({2,"maininstancetalk_0_2",1,100},_mt),
[3]=_set({3,"maininstancetalk_0_3",1,100},_mt),
[4]=_set({4,"maininstancetalk_0_4",1,100},_mt),
[5]=_set({5,"maininstancetalk_0_5",1,100},_mt),
[6]=_set({6,"maininstancetalk_0_6",1,100},_mt),
[7]=_set({7,"maininstancetalk_0_7",20,500},_mt),
[8]=_set({8,"maininstancetalk_0_8",20,500},_mt),
[9]=_set({9,"maininstancetalk_0_9",20,500},_mt),
[10]=_set({10,"maininstancetalk_0_10",20,500},_mt),
[11]=_set({11,"maininstancetalk_0_11",20,500},_mt),
[12]=_set({12,"maininstancetalk_0_12",20,500},_mt),
[13]=_set({13,"maininstancetalk_0_13",20,500},_mt)
}

return _datas