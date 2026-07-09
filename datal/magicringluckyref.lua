local _keys = {refId=1,type=2,grad=3,itemBg1=4,itemBg2=5,itemArrow=6,gradReward=7}
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
[1]=_set({1,0,200,"callhero_ui_air_4_2","callhero_ui_air_4_1","callhero_arrow_1","1=100105=5=0"},_mt),
[2]=_set({2,0,400,"callhero_ui_air_4_2","callhero_ui_air_4_1","callhero_arrow_1","1=100211=1=0"},_mt),
[3]=_set({3,0,700,"callhero_ui_air_1_2","callhero_ui_air_1_1","callhero_arrow_2","1=190002=1=0"},_mt),
[4]=_set({4,0,1000,"callhero_ui_air_1_2","callhero_ui_air_1_1","callhero_arrow_2","1=100212=1=0"},_mt),
[6]=_set({6,1,200,"callhero_ui_air_4_2","callhero_ui_air_4_1","callhero_arrow_1","1=190001=10=0"},_mt),
[7]=_set({7,1,400,"callhero_ui_air_1_2","callhero_ui_air_1_1","callhero_arrow_2","1=190002=3=0"},_mt),
[8]=_set({8,1,700,"callhero_ui_air_1_2","callhero_ui_air_1_1","callhero_arrow_2","1=100212=2=0"},_mt),
[9]=_set({9,1,1000,"callhero_ui_air_1_2","callhero_ui_air_1_1","callhero_arrow_2","1=100212=3=0"},_mt)
}

return _datas