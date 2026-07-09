local _keys = {refId=1,name=2,theme=3,quality=4,cardFace=5,icon=6,fightIcon=7,fightEff=8,fightSpecEff=9,frameRes=10,linkCard=11,attrBonusObj=12,attrBonusDesc=13,equipLimit=14,equipLimitTxt=15,skillGroup=16,substitute=17,associateItem=18,sellLimitLevel=19}
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
[601]=_set({601,"sorcerycard_0_601",1,6,"","card_icon_16","card_fightIcon_16","fx_bmp_hong","","card_di_5","1",7,"sorcerycard_1_601",6,"sorcerycard_2_601",9601,3320004,3310601,5},_mt),
[501]=_set({501,"sorcerycard_0_501",1,5,"","card_icon_15","card_fightIcon_15","fx_bmp_cheng","","card_di_1","1",7,"sorcerycard_1_501",5,"sorcerycard_2_501",9501,3320003,3310501,10},_mt),
[602]=_set({602,"sorcerycard_0_602",1,6,"","card_icon_14","card_fightIcon_14","fx_bmp_hong","","card_di_5","2",7,"sorcerycard_1_602",5,"sorcerycard_2_602",9602,3320004,3310602,5},_mt),
[502]=_set({502,"sorcerycard_0_502",1,5,"","card_icon_13","card_fightIcon_13","fx_bmp_cheng","","card_di_1","2",7,"sorcerycard_1_502",5,"sorcerycard_2_502",9502,3320003,3310502,10},_mt),
[401]=_set({401,"sorcerycard_0_401",1,4,"","card_icon_12","card_fightIcon_12","fx_bmp_zi","","card_di_3","2",7,"sorcerycard_1_401",7,"sorcerycard_2_401",9401,3320002,3310401,20},_mt),
[503]=_set({503,"sorcerycard_0_503",1,5,"","card_icon_11","card_fightIcon_11","fx_bmp_cheng","","card_di_1","3",7,"sorcerycard_1_503",3,"sorcerycard_2_503",9503,3320003,3310503,10},_mt),
[402]=_set({402,"sorcerycard_0_402",1,4,"","card_icon_10","card_fightIcon_10","fx_bmp_zi","","card_di_3","3",7,"sorcerycard_1_402",4,"sorcerycard_2_402",9402,3320002,3310402,20},_mt),
[403]=_set({403,"sorcerycard_0_403",1,4,"","card_icon_09","card_fightIcon_09","fx_bmp_zi","","card_di_3","4",7,"sorcerycard_1_403",5,"sorcerycard_2_403",9403,3320002,3310403,20},_mt),
[301]=_set({301,"sorcerycard_0_301",1,3,"","card_icon_08","card_fightIcon_08","fx_bmp_lan","","card_di_2","4",7,"sorcerycard_1_301",6,"sorcerycard_2_301",9301,3320001,3310301,80},_mt),
[404]=_set({404,"sorcerycard_0_404",1,4,"","card_icon_07","card_fightIcon_07","fx_bmp_zi","","card_di_3","5",7,"sorcerycard_1_404",7,"sorcerycard_2_404",9404,3320002,3310404,20},_mt),
[302]=_set({302,"sorcerycard_0_302",1,3,"","card_icon_06","card_fightIcon_06","fx_bmp_lan","","card_di_2","5",7,"sorcerycard_1_302",5,"sorcerycard_2_302",9302,3320001,3310302,80},_mt),
[303]=_set({303,"sorcerycard_0_303",1,3,"","card_icon_05","card_fightIcon_05","fx_bmp_lan","","card_di_2","5",7,"sorcerycard_1_303",6,"sorcerycard_2_303",9303,3320001,3310303,80},_mt),
[304]=_set({304,"sorcerycard_0_304",1,3,"","card_icon_04","card_fightIcon_04","fx_bmp_lan","","card_di_2","6",7,"sorcerycard_1_304",7,"sorcerycard_2_304",9304,3320001,3310304,80},_mt),
[405]=_set({405,"sorcerycard_0_405",1,4,"","card_icon_03","card_fightIcon_03","fx_bmp_zi","","card_di_3","6",7,"sorcerycard_1_405",7,"sorcerycard_2_405",9405,3320002,3310405,20},_mt),
[305]=_set({305,"sorcerycard_0_305",1,3,"","card_icon_02","card_fightIcon_02","fx_bmp_lan","","card_di_2","7",7,"sorcerycard_1_305",6,"sorcerycard_2_305",9305,3320001,3310305,80},_mt),
[306]=_set({306,"sorcerycard_0_306",1,3,"","card_icon_01","card_fightIcon_01","fx_bmp_lan","","card_di_2","7",7,"sorcerycard_1_306",5,"sorcerycard_2_306",9306,3320001,3310306,80},_mt),
[603]=_set({603,"sorcerycard_0_603",2,6,"","card_icon_17","card_fightIcon_17","fx_bmp_hong","fx_baimeipai_01","card_di_5","8",7,"sorcerycard_1_603",7,"sorcerycard_2_603",9603,3320004,3310603,5},_mt),
[504]=_set({504,"sorcerycard_0_504",2,5,"","card_icon_18","card_fightIcon_18","fx_bmp_cheng","fx_baimeipai_02","card_di_1","8",7,"sorcerycard_1_504",5,"sorcerycard_2_504",9504,3320003,3310504,10},_mt),
[406]=_set({406,"sorcerycard_0_406",2,4,"","card_icon_19","card_fightIcon_19","fx_bmp_zi","fx_baimeipai_03","card_di_3","8",7,"sorcerycard_1_406",6,"sorcerycard_2_406",9406,3320002,3310406,20},_mt),
[604]=_set({604,"sorcerycard_0_604",2,6,"","card_icon_20","card_fightIcon_20","fx_bmp_hong","","card_di_5","9",7,"sorcerycard_1_604",5,"sorcerycard_2_604",9604,3320004,3310604,5},_mt),
[505]=_set({505,"sorcerycard_0_505",2,5,"","card_icon_21","card_fightIcon_21","fx_bmp_cheng","","card_di_1","9",7,"sorcerycard_1_505",6,"sorcerycard_2_505",9505,3320003,3310505,10},_mt),
[407]=_set({407,"sorcerycard_0_407",2,4,"","card_icon_22","card_fightIcon_22","fx_bmp_zi","","card_di_3","9",7,"sorcerycard_1_407",7,"sorcerycard_2_407",9407,3320002,3310407,20},_mt)
}

return _datas