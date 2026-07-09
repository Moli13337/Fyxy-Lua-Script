local _keys = {refId=1,channelId=2,sort=3,channel=4,channelTitle=5,tabBtn=6,newsNum=7,offNum=8,interval=9,channelType=10,barrageOpen=11,openId=12,sendKey=13,roleSpine=14,text=15,HeadShow=16,gradeLvShow=17,chatIcon=18,foldIcon=19,openIcon=20,textBottomCell=21}
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
[2]=_set({2,2,5,"chattingchannel_0_2","chattingchannel_1_2","chat_icon_6_1,chat_icon_6_2,chat_icon_6_2",0,30,5,1,0,"11702000","11702010","","","0=0",1,"mainui_btn_chat","chat_icon_11","chat_icon_11_1","chat_bg_cell_7"},_mt),
[3]=_set({3,3,4,"chattingchannel_0_3","chattingchannel_1_3","chat_icon_2_1,chat_icon_2_2,chat_icon_2_2",0,30,5,1,0,"11703000","11703010","","","0=0",1,"mainui_btn_chat","chat_icon_11","chat_icon_11_1","chat_bg_cell_7"},_mt),
[4]=_set({4,4,3,"chattingchannel_0_4","chattingchannel_1_4","chat_icon_7_1,chat_icon_7_2,chat_icon_7_2",0,30,5,1,0,"11704000","15900010","","","0=0",1,"mainui_btn_chat","chat_icon_11","chat_icon_11_1","chat_bg_cell_7"},_mt),
[5]=_set({5,5,2,"chattingchannel_0_5","chattingchannel_1_5","chat_icon_5_1,chat_icon_5_2,chat_icon_5_2",0,30,0,1,0,"11705000","11705000","","","0=0",0,"mainui_btn_chat","chat_icon_11","chat_icon_11_1","chat_bg_cell_7"},_mt),
[6]=_set({6,6,1,"chattingchannel_0_6","chattingchannel_1_6","chat_icon_3_1,chat_icon_3_2,chat_icon_3_2",20,30,5,1,0,"11706000","11706010","","","0=0",1,"mainui_btn_chat","chat_icon_11","chat_icon_11_1","chat_bg_cell_7"},_mt),
[20]=_set({20,20,20,"chattingchannel_0_20","chattingchannel_1_20","",0,30,5,2,0,"11720010","11720010","Xiaowangzi2","chattingchannel_2_20","0=0",0,"mainui_btn_chat","chat_icon_11","chat_icon_11_1","chat_bg_cell_7"},_mt),
[22]=_set({22,22,22,"chattingchannel_0_22","chattingchannel_1_22","",0,30,5,2,0,"11722000","11722010","Baixuegongzhu2","chattingchannel_2_22","0=0",0,"mainui_btn_chat","chat_icon_11","chat_icon_11_1","chat_bg_cell_7"},_mt),
[29]=_set({29,29,501,"chattingchannel_0_29","chattingchannel_1_29","chat_funtion_icon_11_1,chat_funtion_icon_11_2,chat_funtion_icon_11_2",0,30,5,1,0,"24000003","24000003","","","0=0",0,"mainui_btn_chat","chat_icon_11","chat_icon_11_1","chat_bg_cell_7"},_mt),
[30]=_set({30,30,601,"chattingchannel_0_30","chattingchannel_1_30","",0,30,5,2,0,"12111000","12111000","","","0=0",0,"mainui_btn_chat","chat_icon_11","chat_icon_11_1","chat_bg_cell_7"},_mt)
}

return _datas