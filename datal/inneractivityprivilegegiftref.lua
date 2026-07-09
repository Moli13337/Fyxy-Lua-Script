local _keys = {refId=1,name=2,jumpId=3,icon=4,iconSmall=5,namePng=6,nameTitle=7,signPng=8,description2=9,sort=10,openCondition=11,limit=12,condResetType=13,earlyResetTime=14,showReward=15,descriptionIcon=16,rule=17,channelText=18,limitTop=19,extraReward=20}
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
[1]=_set({1,"inneractivityprivilegegift_0_1",0,"privilegeshop_icon_2","privilegeshop_icon_2_small","privilegeshop_cell_2","privilegeshop_cell_2_txt","privilegeshop_icon_2","inneractivityprivilegegift_1_1",1,10401131,1,1,0,"1=100212=1=0,1=100211=10=0,1=100105=5=0","0=0=0",0,"",0,""},_mt),
[2]=_set({2,"inneractivityprivilegegift_0_2",10401111,"privilegeshop_icon_1","privilegeshop_icon_1_small","privilegeshop_cell_1","privilegeshop_cell_1_txt","privilegeshop_icon_1","inneractivityprivilegegift_1_2",3,10401111,1,5,0,"1=105001=680=0,1=100211=10=0,1=100110=1000=0,1=100120=10=0","0=0=0=0",0,"",0,""},_mt),
[4]=_set({4,"inneractivityprivilegegift_0_4",10401141,"privilegeshop_icon_7","privilegeshop_icon_7_small","privilegeshop_cell_7","privilegeshop_cell_7_txt","privilegeshop_icon_7","inneractivityprivilegegift_1_4",2,10401141,1,1,0,"1=105001=680=0,1=1505003=1=0,1=102001=680=0,1=102001=200=0,1=190002=1=0,1=100212=1=0","0=0=0=1=2=2",0,"",0,""},_mt),
[5]=_set({5,"inneractivityprivilegegift_0_5",10401151,"privilegeshop_icon_9","privilegeshop_icon_9_small","privilegeshop_cell_9","privilegeshop_cell_9_txt","privilegeshop_icon_9","inneractivityprivilegegift_1_5",4,10401151,1,5,0,"1=105001=180=0,1=1504002=1=0,1=1506017=1=0,1=100110=100=0,1=104001=100000=0,1=101001=200000=0","0=0=0=1=1=1",0,"",3,""},_mt),
[9]=_set({9,"inneractivityprivilegegift_0_9",10401161,"privilegeshop_icon_11","privilegeshop_icon_11_small","privilegeshop_cell_11","privilegeshop_cell_11_txt","privilegeshop_icon_11","inneractivityprivilegegift_1_9",5,10401161,1,5,0,"1=105001=680=0,1=100212=5=0,1=100213=300=0,1=102001=1000=0,1=100212=1=0,1=100213=100=0","0=0=0=0=1=1",0,"",0,""},_mt),
[10]=_set({10,"inneractivityprivilegegift_0_10",10401162,"privilegeshop_icon_13","privilegeshop_icon_13_small","privilegeshop_cell_13","privilegeshop_cell_13_txt","privilegeshop_icon_13","inneractivityprivilegegift_1_10",6,10401162,1,5,0,"1=105001=1280=0,1=1800002=500=0,1=1800001=20=0,1=1800002=100=0,1=1800001=2=0","0=0=0=1=1",0,"",0,""},_mt),
[11]=_set({11,"inneractivityprivilegegift_0_11",10401163,"privilegeshop_icon_14","privilegeshop_icon_14_small","privilegeshop_cell_14","privilegeshop_cell_14_txt","privilegeshop_icon_14","inneractivityprivilegegift_1_11",7,10401163,1,5,0,"1=105001=1280=0,1=1800002=500=0,1=1800001=20=0,1=1800002=100=0,1=1800001=2=0","0=0=0=1=1",0,"",0,""},_mt)
}

return _datas