local _keys = {refId=1,btnType1=2,btnType2=3,nextId=4,btnTxt=5,title=6,text=7}
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
[1]=_set({1,99,7,0,"updatepopwindow_0_1","updatepopwindow_1_1","updatepopwindow_2_1"},_mt),
[2]=_set({2,2,4,0,"updatepopwindow_0_2","updatepopwindow_1_2","updatepopwindow_2_2"},_mt),
[3]=_set({3,2,9,0,"updatepopwindow_0_3","updatepopwindow_1_3","updatepopwindow_2_3"},_mt),
[4]=_set({4,2,9,0,"updatepopwindow_0_4","updatepopwindow_1_4","updatepopwindow_2_4"},_mt),
[5]=_set({5,2,9,0,"updatepopwindow_0_5","updatepopwindow_1_5","updatepopwindow_2_5"},_mt),
[6]=_set({6,2,3,0,"updatepopwindow_0_6","updatepopwindow_1_6","updatepopwindow_2_6"},_mt),
[7]=_set({7,2,3,0,"updatepopwindow_0_7","updatepopwindow_1_7","updatepopwindow_2_7"},_mt),
[8]=_set({8,2,3,0,"updatepopwindow_0_8","updatepopwindow_1_8","updatepopwindow_2_8"},_mt),
[9]=_set({9,2,5,0,"updatepopwindow_0_9","updatepopwindow_1_9","updatepopwindow_2_9"},_mt),
[10]=_set({10,2,5,0,"updatepopwindow_0_10","updatepopwindow_1_10","updatepopwindow_2_10"},_mt),
[11]=_set({11,2,5,0,"updatepopwindow_0_11","updatepopwindow_1_11","updatepopwindow_2_11"},_mt),
[12]=_set({12,2,9,0,"updatepopwindow_0_12","updatepopwindow_1_12","updatepopwindow_2_12"},_mt),
[13]=_set({13,2,8,0,"updatepopwindow_0_13","updatepopwindow_1_13","updatepopwindow_2_13"},_mt),
[14]=_set({14,2,9,0,"updatepopwindow_0_14","updatepopwindow_1_14","updatepopwindow_2_14"},_mt),
[15]=_set({15,99,2,0,"updatepopwindow_0_15","updatepopwindow_1_15","updatepopwindow_2_15"},_mt),
[16]=_set({16,2,6,0,"updatepopwindow_0_16","updatepopwindow_1_16","updatepopwindow_2_16"},_mt),
[17]=_set({17,2,10,0,"updatepopwindow_0_17","updatepopwindow_1_17","updatepopwindow_2_17"},_mt),
[18]=_set({18,0,0,0,"updatepopwindow_0_18","updatepopwindow_1_18","updatepopwindow_2_18"},_mt)
}

return _datas