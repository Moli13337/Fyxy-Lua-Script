local _keys = {refId=1,name=2,tag=3,effectTxt=4,cardDetail=5,theme=6,sort=7}
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
[1]=_set({1,"sorcerycardrecomgroup_0_1","sorcerycardrecomgroup_1_1","sorcerycardrecomgroup_2_1","601,501","1",1},_mt),
[2]=_set({2,"sorcerycardrecomgroup_0_2","sorcerycardrecomgroup_1_2","sorcerycardrecomgroup_2_2","602,502,401","1",2},_mt),
[3]=_set({3,"sorcerycardrecomgroup_0_3","sorcerycardrecomgroup_1_3","sorcerycardrecomgroup_2_3","503,402","1",3},_mt),
[4]=_set({4,"sorcerycardrecomgroup_0_4","sorcerycardrecomgroup_1_4","sorcerycardrecomgroup_2_4","403,301","1",4},_mt),
[5]=_set({5,"sorcerycardrecomgroup_0_5","sorcerycardrecomgroup_1_5","sorcerycardrecomgroup_2_5","404,302,303","1",5},_mt),
[6]=_set({6,"sorcerycardrecomgroup_0_6","sorcerycardrecomgroup_1_6","sorcerycardrecomgroup_2_6","405,304","1",6},_mt),
[7]=_set({7,"sorcerycardrecomgroup_0_7","sorcerycardrecomgroup_1_7","sorcerycardrecomgroup_2_7","305,306","1",7},_mt),
[8]=_set({8,"sorcerycardrecomgroup_0_8","sorcerycardrecomgroup_1_8","sorcerycardrecomgroup_2_8","603,504,406","2",8},_mt),
[9]=_set({9,"sorcerycardrecomgroup_0_9","sorcerycardrecomgroup_1_9","sorcerycardrecomgroup_2_9","604,505,407","2",9},_mt)
}

return _datas