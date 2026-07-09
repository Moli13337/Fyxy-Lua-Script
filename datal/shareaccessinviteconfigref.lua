local _keys = {refId=1,shareTextWindow=2,shareText=3,downloadText=4,shareImage=5,shareImageBtn=6,shareImageText=7,onlySave=8,shareUiMessage=9,weixinShow=10,showTwitter=11,showLabel=12,showLineup=13,showLog=14}
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
[1]=_set({1,"shareaccessinviteconfig_0_1","","shareaccessinviteconfig_1_1","activity_invite_bg_big_1;activity_invite_bg_big_2;activity_invite_bg_big_3;activity_invite_bg_big_4;activity_invite_bg_big_5;activity_invite_bg_big_6","activity_invite_icon_1_2;activity_invite_icon_3_1;activity_invite_icon_1_1;activity_invite_icon_5_1;activity_invite_icon_4_1;activity_invite_icon_2_1","activity_invite_txt_6;activity_invite_txt_5;activity_invite_txt_6;activity_invite_txt_5;activity_invite_txt_5;activity_invite_txt_5",0,0,0,0,0,0,1},_mt)
}

return _datas