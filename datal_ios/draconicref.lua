local _keys = {refId=1,name=2,heroId=3,effetcType=4,quality=5,qualityTxt=6,qualityBg=7,sort=8,icon=9,skillbg=10,skillIcon=11,logoTxt=12,logoIcon=13,callBg=14,callBgEff=15,callIcon=16,item=17,itemSell=18,linkType=19,linkGoal=20}
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
[1802401]=_set({1802401,"draconic_0_1802401",2403,1,4,"draconic_1_1802401","draconic_cell_12",401,"icon_draconicbook_2403","public_skill_bg","icon_skill_510111","draconic_2_1802401",{"draconic_cell_8","draconic_cell_6"},"draconic_bg_7","fx_huodelongwen_bj_zi","draconic_icon_6",1812401,"1=1800002=2=0",0,nil},_mt),
[1802402]=_set({1802402,"draconic_0_1802402",3401,1,4,"draconic_1_1802402","draconic_cell_12",402,"icon_draconicbook_3401","public_skill_bg","icon_skill_510211","draconic_2_1802402",{"draconic_cell_6","draconic_cell_10"},"draconic_bg_7","fx_huodelongwen_bj_zi","draconic_icon_6",1812402,"1=1800002=2=0",0,nil},_mt),
[1802403]=_set({1802403,"draconic_0_1802403",1301,1,4,"draconic_1_1802403","draconic_cell_12",403,"icon_draconicbook_1301","public_skill_bg","icon_skill_510311","draconic_2_1802403",{"draconic_cell_8","draconic_cell_10"},"draconic_bg_7","fx_huodelongwen_bj_zi","draconic_icon_6",1812403,"1=1800002=2=0",0,nil},_mt),
[1802404]=_set({1802404,"draconic_0_1802404",3301,1,4,"draconic_1_1802404","draconic_cell_12",404,"icon_draconicbook_3301","public_skill_bg","icon_skill_510411","draconic_2_1802404",{"draconic_cell_6","draconic_cell_7"},"draconic_bg_7","fx_huodelongwen_bj_zi","draconic_icon_6",1812404,"1=1800002=2=0",0,nil},_mt),
[1802501]=_set({1802501,"draconic_0_1802501",1603,1,5,"draconic_1_1802501","draconic_cell_4",501,"icon_draconicbook_1603","public_skill_bg","icon_skill_520111","draconic_2_1802501",{"draconic_cell_6","draconic_cell_11"},"draconic_bg_8","fx_huodelongwen_bj_cheng","draconic_icon_7",1812501,"1=1800002=5=0",0,nil},_mt),
[1802502]=_set({1802502,"draconic_0_1802502",1602,1,5,"draconic_1_1802502","draconic_cell_4",502,"icon_draconicbook_1602","public_skill_bg","icon_skill_520211","draconic_2_1802502",{"draconic_cell_8","draconic_cell_3"},"draconic_bg_8","fx_huodelongwen_bj_cheng","draconic_icon_7",1812502,"1=1800002=5=0",0,nil},_mt),
[1802503]=_set({1802503,"draconic_0_1802503",2603,1,5,"draconic_1_1802503","draconic_cell_4",503,"icon_draconicbook_2603","public_skill_bg","icon_skill_520311","draconic_2_1802503",{"draconic_cell_6","draconic_cell_9"},"draconic_bg_8","fx_huodelongwen_bj_cheng","draconic_icon_7",1812503,"1=1800002=5=0",0,nil},_mt),
[1802504]=_set({1802504,"draconic_0_1802504",3501,1,5,"draconic_1_1802504","draconic_cell_4",504,"icon_draconicbook_3501","public_skill_bg","icon_skill_520411","draconic_2_1802504",{"draconic_cell_3","draconic_cell_5"},"draconic_bg_8","fx_huodelongwen_bj_cheng","draconic_icon_7",1812504,"1=1800002=5=0",0,nil},_mt),
[1801601]=_set({1801601,"draconic_0_1801601",2601,2,6,"draconic_1_1801601","draconic_cell_13",601,"icon_draconicbook_2601","public_skill_bg","icon_skill_530111","draconic_2_1801601",{"draconic_cell_11","draconic_cell_3"},"draconic_bg_9","fx_huodelongwen_bj_hong","draconic_icon_8",1811601,"1=1800002=10=0",0,nil},_mt),
[1801602]=_set({1801602,"draconic_0_1801602",3701,2,6,"draconic_1_1801602","draconic_cell_13",602,"icon_draconicbook_3701","public_skill_bg","icon_skill_530211","draconic_2_1801602",{"draconic_cell_11","draconic_cell_5"},"draconic_bg_9","fx_huodelongwen_bj_hong","draconic_icon_8",1811602,"1=1800002=10=0",0,nil},_mt),
[1802601]=_set({1802601,"draconic_0_1802601",2705,1,6,"draconic_1_1802601","draconic_cell_13",603,"icon_draconicbook_2705","public_skill_bg","icon_skill_530311","draconic_2_1802601",{"draconic_cell_6","draconic_cell_10"},"draconic_bg_9","fx_huodelongwen_bj_hong","draconic_icon_8",1812601,"1=1800002=10=0",0,nil},_mt),
[1802602]=_set({1802602,"draconic_0_1802602",1703,1,6,"draconic_1_1802602","draconic_cell_13",604,"icon_draconicbook_1703","public_skill_bg","icon_skill_530411","draconic_2_1802602",{"draconic_cell_6","draconic_cell_7"},"draconic_bg_9","fx_huodelongwen_bj_hong","draconic_icon_8",1812602,"1=1800002=10=0",0,nil},_mt),
[1802603]=_set({1802603,"draconic_0_1802603",1601,1,6,"draconic_1_1802603","draconic_cell_13",605,"icon_draconicbook_1601","public_skill_bg","icon_skill_530511","draconic_2_1802603",{"draconic_cell_3","draconic_cell_11"},"draconic_bg_9","fx_huodelongwen_bj_hong","draconic_icon_8",1812603,"1=1800002=10=0",0,nil},_mt),
[1802604]=_set({1802604,"draconic_0_1802604",3705,1,6,"draconic_1_1802604","draconic_cell_13",606,"icon_draconicbook_3705","public_skill_bg","icon_skill_530611","draconic_2_1802604",{"draconic_cell_6","draconic_cell_5"},"draconic_bg_9","fx_huodelongwen_bj_hong","draconic_icon_8",1812604,"1=1800002=10=0",0,nil},_mt),
[1802701]=_set({1802701,"draconic_0_1802701",1704,1,7,"draconic_1_1802701","draconic_cell_13",701,"icon_draconicbook_1704","public_skill_bg","icon_skill_540111","draconic_2_1802701",{"draconic_cell_6","draconic_cell_11"},"draconic_bg_10","fx_huodelongwen_bj_huang","draconic_icon_9",1812701,"1=1800002=15=0",1,{1802604}},_mt),
[1802702]=_set({1802702,"draconic_0_1802702",4702,1,7,"draconic_1_1802702","draconic_cell_13",702,"icon_draconicbook_4702","public_skill_bg","icon_skill_540211","draconic_2_1802702",{"draconic_cell_3","draconic_cell_11"},"draconic_bg_10","fx_huodelongwen_bj_huang","draconic_icon_9",1812702,"1=1800002=15=0",1,{1802603}},_mt),
[1802703]=_set({1802703,"draconic_0_1802703",5703,1,7,"draconic_1_1802703","draconic_cell_13",703,"icon_draconicbook_5703","public_skill_bg","icon_skill_540311","draconic_2_1802703",{"draconic_cell_6","draconic_cell_7"},"draconic_bg_10","fx_huodelongwen_bj_huang","draconic_icon_9",1812703,"1=1800002=15=0",1,{1802601}},_mt),
[1802704]=_set({1802704,"draconic_0_1802704",4704,1,7,"draconic_1_1802704","draconic_cell_13",704,"icon_draconicbook_4704","public_skill_bg","icon_skill_540411","draconic_2_1802704",{"draconic_cell_8","draconic_cell_6"},"draconic_bg_10","fx_huodelongwen_bj_huang","draconic_icon_9",1812704,"1=1800002=15=0",1,{1802602}},_mt)
}

return _datas