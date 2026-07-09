local _keys = {refId=1,type=2,rank=3,name=4,channelIdGroup=5,screenPage=6}
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
[1]=_set({1,1,1,"chattingbtn_0_1","1,2,3,4,6,7,26,27,28,29",0},_mt),
[2]=_set({2,2,2,"chattingbtn_0_2","2,3,4,6,26,27,28,29",1},_mt),
[3]=_set({3,3,3,"chattingbtn_0_3","2,3,4,6,26,27,28,29",0},_mt),
[4]=_set({4,4,4,"chattingbtn_0_4","2,3,4,6,26,27,28,29",0},_mt)
}

return _datas