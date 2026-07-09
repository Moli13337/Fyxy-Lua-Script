local _keys = {refId=1,type=2,style=3,group=4,functionId=5,name=6,redPoint=7,sort=8,bg=9,icon=10,combatType=11,timeText=12,text1=13,text2=14}
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
[101]=_set({101,1,2,10102,16302000,"dailygameplay_0_101",0,1,"worldcopy_ad_1","mainui_ad_txt_7","12,121,122,123,124","dailygameplay_1_101","dailygameplay_2_101","dailygameplay_3_101"},_mt),
[102]=_set({102,1,2,10102,16800000,"dailygameplay_0_102",0,3,"worldcopy_ad_10","mainui_ad_txt_1","9","","dailygameplay_2_102","dailygameplay_3_102"},_mt),
[103]=_set({103,1,2,10101,17100010,"dailygameplay_0_103",0,3,"worldcopy_ad_7","","17","dailygameplay_1_103","dailygameplay_2_103","dailygameplay_3_103"},_mt),
[104]=_set({104,1,1,0,18201001,"dailygameplay_0_104",0,0,"","","18,181","dailygameplay_1_104","dailygameplay_2_104","dailygameplay_3_104"},_mt),
[106]=_set({106,1,1,0,32000001,"dailygameplay_0_106",0,0,"","","38","","dailygameplay_2_106","dailygameplay_3_106"},_mt),
[107]=_set({107,1,1,0,16400000,"dailygameplay_0_107",0,0,"","","7,71,72,73,74,75","","dailygameplay_2_107","dailygameplay_3_107"},_mt),
[108]=_set({108,1,2,10101,33000001,"dailygameplay_0_108",0,1,"worldcopy_ad_8","mainui_ad_txt_8","","","","dailygameplay_3_108"},_mt),
[109]=_set({109,1,1,0,12400000,"dailygameplay_0_109",1,0,"","","8","","","dailygameplay_3_109"},_mt),
[110]=_set({110,1,2,10101,35000000,"dailygameplay_0_110",0,2,"worldcopy_ad_7","mainui_ad_txt_9","","dailygameplay_1_110","dailygameplay_2_110","dailygameplay_3_110"},_mt),
[10101]=_set({10101,1,3,0,10000031,"dailygameplay_0_10101",1,0,"","","","","",""},_mt),
[10102]=_set({10102,1,3,0,10000032,"dailygameplay_0_10102",1,0,"","","","","",""},_mt),
[111]=_set({111,1,2,10102,36000010,"dailygameplay_0_111",1,4,"worldcopy_ad_9","mainui_ad_txt_6","47","","dailygameplay_2_111","dailygameplay_3_111"},_mt),
[112]=_set({112,1,2,10102,31000001,"dailygameplay_0_112",1,2,"worldcopy_ad_6","mainui_ad_txt_6","28","dailygameplay_1_112","dailygameplay_2_112","dailygameplay_3_112"},_mt),
[201]=_set({201,2,0,0,13100000,"dailygameplay_0_201",0,1,"pvpenter_bg_di_3","pvpenter_icon_4","2,3","dailygameplay_1_201","",""},_mt),
[202]=_set({202,2,0,0,13200000,"dailygameplay_0_202",0,5,"pvpenter_bg_di_4","pvpenter_icon_5","14","dailygameplay_1_202","dailygameplay_2_202",""},_mt),
[203]=_set({203,2,0,0,13600000,"dailygameplay_0_203",0,4,"pvpenter_bg_di_3","pvpenter_icon_6","20","","dailygameplay_2_203",""},_mt),
[205]=_set({205,2,0,0,13800000,"dailygameplay_0_205",0,2,"pvpenter_bg_di_3","pvpenter_icon_4","39,43","","dailygameplay_2_205",""},_mt),
[206]=_set({206,2,0,0,13900000,"dailygameplay_0_206",0,3,"pvpenter_bg_di_4","pvpenter_icon_5","40","dailygameplay_1_206","dailygameplay_2_206","dailygameplay_3_206"},_mt),
[207]=_set({207,2,0,0,24000000,"dailygameplay_0_207",0,3,"pvpenter_bg_di_4","pvpenter_icon_5","25","","",""},_mt),
[208]=_set({208,2,0,0,13910000,"dailygameplay_0_208",0,3,"pvpenter_bg_di_4","pvpenter_icon_5","41,42","dailygameplay_1_208","dailygameplay_2_208","dailygameplay_3_208"},_mt),
[209]=_set({209,2,0,0,19100000,"dailygameplay_0_209",0,8,"","","","","",""},_mt),
[301]=_set({301,3,0,0,36000003,"dailygameplay_0_301",0,1,"","","","","",""},_mt)
}

return _datas