local _keys = {refId=1,name=2,img2=3,unclock=4,showLH=5,showLHPos=6,showLHSize=7,showLHflip=8,showAd=9,itemId=10,description=11,rankId=12,questDay=13,questWeek=14}
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
[1]=_set({1,"academytheme_0_1","dreamcollege_ui_on_0",17701000,"LH_Baige05","0,60","1","0","dreamcollege_txt_6",100226,"academytheme_1_1",1300,"",""},_mt),
[2]=_set({2,"academytheme_0_2","dreamcollege_ui_on_2",17701001,"LH_Mao01","0,60","1","0","dreamcollege_txt_7",100227,"academytheme_1_2",1301,"",""},_mt),
[3]=_set({3,"academytheme_0_3","dreamcollege_ui_on_3",17701002,"LH_RenB01","0,60","1","0","dreamcollege_txt_7",100228,"academytheme_1_3",1302,"",""},_mt)
}

return _datas