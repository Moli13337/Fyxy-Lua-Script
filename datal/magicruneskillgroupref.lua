local _keys = {refId=1,skillGroupName=2,qualityNum=3,sign=4}
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
[0]=_set({0,"magicruneskillgroup_0_0","",""},_mt),
[1]=_set({1,"magicruneskillgroup_0_1","1=1","0,1,2"},_mt),
[2]=_set({2,"magicruneskillgroup_0_2","1=2","0,1,2"},_mt),
[3]=_set({3,"magicruneskillgroup_0_3","2=1","0,1,2"},_mt),
[4]=_set({4,"magicruneskillgroup_0_4","1=1,2=1","0,1,2"},_mt),
[5]=_set({5,"magicruneskillgroup_0_5","2=2","0,1,2"},_mt),
[6]=_set({6,"magicruneskillgroup_0_6","3=1","0,1,2"},_mt),
[7]=_set({7,"magicruneskillgroup_0_7","1=1,3=1","0,1,2"},_mt),
[8]=_set({8,"magicruneskillgroup_0_8","2=1,3=1","0,1,2"},_mt),
[9]=_set({9,"magicruneskillgroup_0_9","3=2","0,1,2"},_mt),
[10]=_set({10,"magicruneskillgroup_0_10","4=1,2=1","0,1,2"},_mt),
[11]=_set({11,"magicruneskillgroup_0_11","4=1,3=1","0,1,2"},_mt),
[12]=_set({12,"magicruneskillgroup_0_12","4=2","0,1,2"},_mt),
[100]=_set({100,"magicruneskillgroup_0_100","3=1","0,1,2"},_mt)
}

return _datas