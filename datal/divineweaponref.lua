local _keys = {refId=1,name=2,effetcType=3,quality=4,qualityTxt=5,qualityBg=6,sort=7,icon=8,effect=9,logoTxt=10,logoIcon=11,item=12,itemSell=13,linkType=14,linkGoal=15,img=16,skillTxt=17,imgBg=18}
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
[3401401]=_set({3401401,"divineweapon_0_3401401",1,4,"divineweapon_1_3401401","",1,"weapon_icon_1","fx_sw_01_da","divineweapon_2_3401401","draconic_cell_8|draconic_cell_7",3411401,"1=3400101=20=0",0,nil,"weaponf_img8","weaponf_txt8","weaponf_zise"},_mt),
[3401402]=_set({3401402,"divineweapon_0_3401402",1,4,"divineweapon_1_3401402","",2,"weapon_icon_2","fx_sw_02_da","divineweapon_2_3401402","draconic_cell_6|draconic_cell_9",3411402,"1=3400101=20=0",0,nil,"weaponf_img5","weaponf_txt5","weaponf_zise"},_mt),
[3401403]=_set({3401403,"divineweapon_0_3401403",1,4,"divineweapon_1_3401403","",3,"weapon_icon_3","fx_sw_03_da","divineweapon_2_3401403","draconic_cell_8|draconic_cell_7",3411403,"1=3400101=20=0",0,nil,"weaponf_img6","weaponf_txt6","weaponf_zise"},_mt),
[3401404]=_set({3401404,"divineweapon_0_3401404",1,4,"divineweapon_1_3401404","",4,"weapon_icon_4","fx_sw_04_da","divineweapon_2_3401404","draconic_cell_6|draconic_cell_9",3411404,"1=3400101=20=0",0,nil,"weaponf_img11","weaponf_txt11","weaponf_zise"},_mt),
[3401501]=_set({3401501,"divineweapon_0_3401501",1,5,"divineweapon_1_3401501","",5,"weapon_icon_5","fx_sw_05_da","divineweapon_2_3401501","draconic_cell_6|draconic_cell_9|draconic_cell_10",3411501,"1=3400102=20=0",0,nil,"weaponf_img1","weaponf_txt1","weaponf_cse"},_mt),
[3401502]=_set({3401502,"divineweapon_0_3401502",1,5,"divineweapon_1_3401502","",6,"weapon_icon_6","fx_sw_06_da","divineweapon_2_3401502","draconic_cell_6|draconic_cell_3",3411502,"1=3400102=20=0",0,nil,"weaponf_img2","weaponf_txt2","weaponf_cse"},_mt),
[3401503]=_set({3401503,"divineweapon_0_3401503",1,5,"divineweapon_1_3401503","",7,"weapon_icon_7","fx_sw_07_da","divineweapon_2_3401503","draconic_cell_3|draconic_cell_3",3411503,"1=3400102=20=0",0,nil,"weaponf_img14","weaponf_txt14","weaponf_cse"},_mt),
[3401504]=_set({3401504,"divineweapon_0_3401504",1,5,"divineweapon_1_3401504","",8,"weapon_icon_8","fx_sw_08_da","divineweapon_2_3401504","draconic_cell_9|draconic_cell_5",3411504,"1=3400102=20=0",0,nil,"weaponf_img7","weaponf_txt7","weaponf_cse"},_mt),
[3401601]=_set({3401601,"divineweapon_0_3401601",1,6,"divineweapon_1_3401601","",9,"weapon_icon_9","fx_sw_09_da","divineweapon_2_3401601","draconic_cell_9|draconic_cell_10",3411601,"1=3400103=20=0",0,nil,"weaponf_img9","weaponf_txt9","weaponf_hongse"},_mt),
[3401602]=_set({3401602,"divineweapon_0_3401602",1,6,"divineweapon_1_3401602","",10,"weapon_icon_10","fx_sw_10_da","divineweapon_2_3401602","draconic_cell_9|draconic_cell_7",3411602,"1=3400103=20=0",0,nil,"weaponf_img4","weaponf_txt4","weaponf_hongse"},_mt),
[3401603]=_set({3401603,"divineweapon_0_3401603",1,6,"divineweapon_1_3401603","",11,"weapon_icon_11","fx_sw_11_da","divineweapon_2_3401603","draconic_cell_3|draconic_cell_3",3411603,"1=3400103=20=0",0,nil,"weaponf_img12","weaponf_txt12","weaponf_hongse"},_mt),
[3401604]=_set({3401604,"divineweapon_0_3401604",1,6,"divineweapon_1_3401604","",12,"weapon_icon_12","fx_sw_12_da","divineweapon_2_3401604","draconic_cell_10|draconic_cell_3",3411604,"1=3400103=20=0",0,nil,"weaponf_img3","weaponf_txt3","weaponf_hongse"},_mt),
[3401605]=_set({3401605,"divineweapon_0_3401605",1,6,"divineweapon_1_3401605","",13,"weapon_icon_13","fx_sw_13_da","divineweapon_2_3401605","draconic_cell_10|draconic_cell_7",3411605,"1=3400103=20=0",0,nil,"weaponf_img13","weaponf_txt13","weaponf_hongse"},_mt),
[3401606]=_set({3401606,"divineweapon_0_3401606",1,6,"divineweapon_1_3401606","",14,"weapon_icon_14","fx_sw_14_da","divineweapon_2_3401606","draconic_cell_9|draconic_cell_7",3411606,"1=3400103=20=0",0,nil,"weaponf_img10","weaponf_txt10","weaponf_hongse"},_mt)
}

return _datas