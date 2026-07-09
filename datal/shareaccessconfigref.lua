local _keys = {refId=1,name=2,channelIdGroup=3,text=4}
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
[1]=_set({1,"shareaccessconfig_0_1","2,3,4","shareaccessconfig_1_1"},_mt),
[2]=_set({2,"shareaccessconfig_0_2","2,3,4","shareaccessconfig_1_2"},_mt),
[3]=_set({3,"shareaccessconfig_0_3","2,3,4","shareaccessconfig_1_3"},_mt),
[4]=_set({4,"shareaccessconfig_0_4","2,3,4","shareaccessconfig_1_4"},_mt),
[6]=_set({6,"shareaccessconfig_0_6","2,3,4","shareaccessconfig_1_6"},_mt),
[7]=_set({7,"shareaccessconfig_0_7","2,3,4","shareaccessconfig_1_7"},_mt),
[8]=_set({8,"shareaccessconfig_0_8","2,3,4","shareaccessconfig_1_8"},_mt),
[10]=_set({10,"shareaccessconfig_0_10","2,3,4","shareaccessconfig_1_10"},_mt),
[11]=_set({11,"shareaccessconfig_0_11","2,3,4","shareaccessconfig_1_11"},_mt),
[13]=_set({13,"shareaccessconfig_0_13","2,3,4","shareaccessconfig_1_13"},_mt),
[14]=_set({14,"shareaccessconfig_0_14","2,3,4","shareaccessconfig_1_14"},_mt),
[15]=_set({15,"shareaccessconfig_0_15","2,3,4","shareaccessconfig_1_15"},_mt),
[17]=_set({17,"shareaccessconfig_0_17","2,3,4","shareaccessconfig_1_17"},_mt),
[18]=_set({18,"shareaccessconfig_0_18","2,3,4","shareaccessconfig_1_18"},_mt),
[21]=_set({21,"shareaccessconfig_0_21","2,3,4","shareaccessconfig_1_21"},_mt),
[23]=_set({23,"shareaccessconfig_0_23","2,3,4","shareaccessconfig_1_23"},_mt),
[24]=_set({24,"shareaccessconfig_0_24","2,3,4","shareaccessconfig_1_24"},_mt),
[26]=_set({26,"shareaccessconfig_0_26","29,2,3,4","shareaccessconfig_1_26"},_mt),
[27]=_set({27,"shareaccessconfig_0_27","29,2,3,4","shareaccessconfig_1_27"},_mt),
[28]=_set({28,"shareaccessconfig_0_28","29,2,3,4","shareaccessconfig_1_28"},_mt),
[29]=_set({29,"shareaccessconfig_0_29","29,2,3,4","shareaccessconfig_1_29"},_mt),
[30]=_set({30,"shareaccessconfig_0_30","29,2,3,4","shareaccessconfig_1_30"},_mt),
[32]=_set({32,"shareaccessconfig_0_32","2,3,4","shareaccessconfig_1_32"},_mt),
[33]=_set({33,"shareaccessconfig_0_33","2,3,4","shareaccessconfig_1_33"},_mt),
[34]=_set({34,"shareaccessconfig_0_34","2,3,4","shareaccessconfig_1_34"},_mt),
[36]=_set({36,"shareaccessconfig_0_36","2,3,4","shareaccessconfig_1_36"},_mt),
[40]=_set({40,"shareaccessconfig_0_40","2,3,4","shareaccessconfig_1_40"},_mt),
[41]=_set({41,"shareaccessconfig_0_41","2,3,4","shareaccessconfig_1_41"},_mt),
[42]=_set({42,"shareaccessconfig_0_42","2,3,4","shareaccessconfig_1_42"},_mt),
[43]=_set({43,"shareaccessconfig_0_43","2,3","shareaccessconfig_1_43"},_mt),
[44]=_set({44,"shareaccessconfig_0_44","2,3,4","shareaccessconfig_1_44"},_mt)
}

return _datas