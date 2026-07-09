local _keys = {refId=1,type=2,rewardShow=3,reward1=4,reward2=5,reward3=6,effectReward=7,time=8,expend=9,expendExtra=10,btnPng=11,moreText=12,moreText1=13}
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
[1]=_set({1,1,1,"1=100212=1=0,1=100211=10=0,1=100105=5=0","","","1,2",-1,"1=102001=1980","","public_btn_1_2","inneractivityprivilegedata_0_1","privilegeshop_txt_12"},_mt),
[2]=_set({2,2,1,"1=105001=680=0,1=100211=10=0,1=100110=1000=0,1=100120=10=0","","","3,6",43200,"301","312","public_btn_1_2","inneractivityprivilegedata_0_2","privilegeshop_txt_11"},_mt),
[3]=_set({3,4,1,"1=105001=680=0,1=1505003=1=0,1=102001=680=0,1=102001=200=0,1=190002=1=0,1=100212=1=0","1=102001=200=0","1=190002=1=0,1=100212=1=0","",-1,"302","","public_btn_1_2","inneractivityprivilegedata_0_3","privilegeshop_txt_12"},_mt),
[4]=_set({4,5,1,"1=105001=180=0,1=1504002=1=0,1=1506017=1=0,1=100110=100=0,1=104001=100000=0,1=101001=200000=0","1=100110=100=0,1=104001=100000=0,1=101001=200000=0","","7,8,9",43200,"303","311","public_btn_1_2","inneractivityprivilegedata_0_4","privilegeshop_txt_11"},_mt),
[5]=_set({5,9,1,"1=105001=680=0,1=100212=5=0,1=100213=300=0,1=102001=1000=0,1=100212=1=0,1=100213=100=0","1=100212=1=0,1=100213=100=0","","",10080,"304","","public_btn_1_2","inneractivityprivilegedata_0_5","privilegeshop_txt_10"},_mt),
[6]=_set({6,10,1,"1=105001=1280=0,1=1800002=500=0,1=1800001=20=0,1=1800002=100=0,1=1800001=2=0","1=1800002=100=0,1=1800001=2=0","","102",43200,"305","","public_btn_1_2","inneractivityprivilegedata_0_6","privilegeshop_txt_11"},_mt),
[7]=_set({7,11,1,"1=105001=1280=0,1=3430201=10=0,1=3400001=20=0,1=3430201=2=0,1=3400001=2=0","1=3430201=2=0,1=3400001=2=0","","103",43200,"306","","public_btn_1_2","inneractivityprivilegedata_0_7","privilegeshop_txt_11"},_mt)
}

return _datas