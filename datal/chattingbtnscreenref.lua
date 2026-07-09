local _keys = {refId=1,type=2,rank=3,name=4,icon=5,iconChecked=6,race=7,itemPage=8}
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
[1001]=_set({1001,2,1,"chattingbtnscreen_0_1001","public_race_0","chat_btn_on_3",0,0},_mt),
[1002]=_set({1002,2,4,"chattingbtnscreen_0_1002","public_race_icon_1","chat_btn_on_3",1,0},_mt),
[1003]=_set({1003,2,5,"chattingbtnscreen_0_1003","public_race_icon_2","chat_btn_on_3",2,0},_mt),
[1004]=_set({1004,2,6,"chattingbtnscreen_0_1004","public_race_icon_3","chat_btn_on_3",3,0},_mt),
[1005]=_set({1005,2,2,"chattingbtnscreen_0_1005","public_race_icon_4","chat_btn_on_3",4,0},_mt),
[1006]=_set({1006,2,3,"chattingbtnscreen_0_1006","public_race_icon_5","chat_btn_on_3",5,0},_mt),
[1007]=_set({1007,2,7,"chattingbtnscreen_0_1007","public_race_icon_6","chat_btn_on_3",6,0},_mt),
[2001]=_set({2001,3,1,"chattingbtnscreen_0_2001","public_race_0","chat_btn_on_3",0,101},_mt),
[2002]=_set({2002,3,2,"chattingbtnscreen_0_2002","shop_btn_icon_1","chat_btn_on_3",0,201},_mt),
[2003]=_set({2003,3,3,"chattingbtnscreen_0_2003","shop_btn_icon_2","chat_btn_on_3",0,202},_mt),
[2004]=_set({2004,3,4,"chattingbtnscreen_0_2004","shop_btn_icon_3","chat_btn_on_3",0,203},_mt),
[2005]=_set({2005,3,5,"chattingbtnscreen_0_2005","shop_btn_icon_4","chat_btn_on_3",0,204},_mt),
[2006]=_set({2006,3,8,"chattingbtnscreen_0_2006","shop_btn_icon_5","chat_btn_on_3",0,205},_mt)
}

return _datas