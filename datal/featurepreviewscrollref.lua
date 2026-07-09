local _keys = {refId=1,name=2,sort=3,icon=4,iconTxt=5,cellBg=6,cellBgTxt=7,cellNameDec=8,functionOpen=9,helpTip=10,poster=11,cellImage=12,showTime=13,foreshowFunction=14,des=15,posterTxt1=16,activityFunction=17,activitySecTime=18,des2=19,posterTxt2=20}
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
[101]=_set({101,"featurepreviewscroll_0_101",10000,"foreshow_icon_1","foreshow_icon_1_txt","foreshow_cell_1","foreshow_cell_1_txt","featurepreviewscroll_1_101",13200000,56,"mainui_txt_projection_204","simulate_bg_23","00:00:00",24000000,"featurepreviewscroll_2_101","mainui_txt_bmz",12106100,"20:00:00","featurepreviewscroll_3_101","mainui_txt_jxz"},_mt),
[102]=_set({102,"featurepreviewscroll_0_102",10001,"foreshow_icon_3","foreshow_icon_3_txt","foreshow_cell_3","foreshow_cell_3_txt","featurepreviewscroll_1_102",12106000,9,"mainui_txt_projection_203","mainui_bg_notice_1","06:00:00",13201000,"featurepreviewscroll_2_102","mainui_txt_jxz",13202000,"","","mainui_txt_jxz"},_mt),
[103]=_set({103,"featurepreviewscroll_0_103",10002,"foreshow_icon_2","foreshow_icon_2_txt","foreshow_cell_2","foreshow_cell_2_txt","featurepreviewscroll_1_103",12111000,0,"","","",0,"","",0,"","",""},_mt),
[104]=_set({104,"featurepreviewscroll_0_104",10003,"foreshow_icon_13","foreshow_icon_13_txt","foreshow_cell_13","foreshow_cell_13_txt","",22000000,0,"","","",0,"","",0,"","",""},_mt),
[105]=_set({105,"featurepreviewscroll_0_105",9999,"foreshow_icon_105","foreshow_icon_105_txt","foreshow_cell_105","foreshow_cell_105_txt","",24000000,0,"","","",0,"","",0,"","",""},_mt)
}

return _datas