local _keys = {refId=1,sort=2,text1=3,text2=4,text3=5,text4=6,text5=7,text6=8,text7=9,text8=10,text9=11}
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
[1001]=_set({1001,1,"supportteaching_0_1001","supportteaching_1_1001","supportteaching_2_1001","supportteaching_3_1001","","","","",""},_mt),
[1002]=_set({1002,2,"supportteaching_0_1002","supportteaching_1_1002","supportteaching_2_1002","supportteaching_3_1002","supportteaching_4_1002","supportteaching_5_1002","","",""},_mt),
[1003]=_set({1003,3,"supportteaching_0_1003","supportteaching_1_1003","supportteaching_2_1003","supportteaching_3_1003","supportteaching_4_1003","","","",""},_mt),
[1004]=_set({1004,4,"supportteaching_0_1004","supportteaching_1_1004","supportteaching_2_1004","supportteaching_3_1004","","","","",""},_mt),
[1005]=_set({1005,5,"supportteaching_0_1005","supportteaching_1_1005","supportteaching_2_1005","supportteaching_3_1005","supportteaching_4_1005","supportteaching_5_1005","","",""},_mt),
[1006]=_set({1006,6,"supportteaching_0_1006","supportteaching_1_1006","supportteaching_2_1006","supportteaching_3_1006","supportteaching_4_1006","supportteaching_5_1006","","",""},_mt),
[1007]=_set({1007,7,"supportteaching_0_1007","supportteaching_1_1007","supportteaching_2_1007","supportteaching_3_1007","supportteaching_4_1007","supportteaching_5_1007","supportteaching_6_1007","",""},_mt)
}

return _datas