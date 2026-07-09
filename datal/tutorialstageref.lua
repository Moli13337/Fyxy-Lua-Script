local _keys = {refId=1,name=2,functionOpen=3,openText=4,extraReward=5,sort=6,tabIcon=7,bg=8,desc=9}
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
[1]=_set({1,"tutorialstage_0_1",19101001,"","1=102001=200",1,"college_btn_5","college_ad_5","tutorialstage_2_1"},_mt),
[2]=_set({2,"tutorialstage_0_2",19101002,"","1=102001=400",2,"college_btn_3","college_ad_5","tutorialstage_2_2"},_mt)
}

return _datas