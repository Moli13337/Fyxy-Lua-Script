local _keys = {refId=1,name=2,levelMax=3,sort=4,paint=5,monster=6,reward1=7,num=8,map=9,wall=10,wallEffect=11,winText=12,loseText=13}
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
[1]=_set({1,"moecitystage_0_1",20,1,"LH_Shilaimu03",100001,"1=102001=50=0,1=1830102=30=0",100,"MoeCity_bigbg_4","MoeCity_bg_4","fx_ui_bwmnc_weiqiang_01","moecitystage_1_1","moecitystage_2_1"},_mt),
[2]=_set({2,"moecitystage_0_2",20,2,"LH_Shayu03",100002,"1=102001=100=0,1=1830102=50=0",100,"MoeCity_bigbg_2","MoeCity_bg_5","fx_ui_bwmnc_weiqiang_02","moecitystage_1_2","moecitystage_2_2"},_mt),
[3]=_set({3,"moecitystage_0_3",20,3,"LH_Tuzi03",100003,"1=102001=150=0,1=1830102=80=0",100,"MoeCity_bigbg_3","MoeCity_bg_6","fx_ui_bwmnc_weiqiang_03","moecitystage_1_3","moecitystage_2_3"},_mt),
[4]=_set({4,"moecitystage_0_4",20,4,"LH_Shuijingling03",100004,"1=102001=200=0,1=1830102=120=0",100,"MoeCity_bigbg_4","MoeCity_bg_4","fx_ui_bwmnc_weiqiang_01","moecitystage_1_4","moecitystage_2_4"},_mt),
[5]=_set({5,"moecitystage_0_5",20,5,"LH_Meiguiniang01",100005,"1=102001=250=0,1=1830102=160=0",100,"MoeCity_bigbg_2","MoeCity_bg_5","fx_ui_bwmnc_weiqiang_02","moecitystage_1_5","moecitystage_2_5"},_mt),
[6]=_set({6,"moecitystage_0_6",20,6,"LH_Shilaimu03",100006,"1=102001=300=0,1=1830102=200=0",100,"MoeCity_bigbg_3","MoeCity_bg_6","fx_ui_bwmnc_weiqiang_03","moecitystage_1_6","moecitystage_2_6"},_mt),
[7]=_set({7,"moecitystage_0_7",20,7,"LH_Shayu03",100007,"1=102001=350=0,1=1830102=240=0",100,"MoeCity_bigbg_4","MoeCity_bg_4","fx_ui_bwmnc_weiqiang_01","moecitystage_1_7","moecitystage_2_7"},_mt),
[8]=_set({8,"moecitystage_0_8",20,8,"LH_Tuzi03",100008,"1=102001=400=0,1=1830102=280=0",100,"MoeCity_bigbg_2","MoeCity_bg_5","fx_ui_bwmnc_weiqiang_02","moecitystage_1_8","moecitystage_2_8"},_mt),
[9]=_set({9,"moecitystage_0_9",20,9,"LH_Shuijingling03",100009,"1=102001=450=0,1=1830102=320=0",100,"MoeCity_bigbg_3","MoeCity_bg_6","fx_ui_bwmnc_weiqiang_03","moecitystage_1_9","moecitystage_2_9"},_mt),
[10]=_set({10,"moecitystage_0_10",20,10,"LH_Meiguiniang01",100010,"1=102001=500=0,1=1830102=360=0",100,"MoeCity_bigbg_4","MoeCity_bg_4","fx_ui_bwmnc_weiqiang_01","moecitystage_1_10","moecitystage_2_10"},_mt),
[11]=_set({11,"moecitystage_0_11",20,11,"LH_Shayu03",100011,"1=102001=600=0,1=1830102=400=0",100,"MoeCity_bigbg_4","MoeCity_bg_4","fx_ui_bwmnc_weiqiang_01","moecitystage_1_11","moecitystage_2_11"},_mt),
[12]=_set({12,"moecitystage_0_12",20,12,"LH_Tuzi03",100012,"1=102001=700=0,1=1830102=450=0",100,"MoeCity_bigbg_2","MoeCity_bg_5","fx_ui_bwmnc_weiqiang_02","moecitystage_1_12","moecitystage_2_12"},_mt),
[13]=_set({13,"moecitystage_0_13",20,13,"LH_Shuijingling03",100013,"1=102001=800=0,1=1830102=500=0",100,"MoeCity_bigbg_3","MoeCity_bg_6","fx_ui_bwmnc_weiqiang_03","moecitystage_1_13","moecitystage_2_13"},_mt),
[14]=_set({14,"moecitystage_0_14",20,14,"LH_Meiguiniang01",100014,"1=102001=1000=0,1=1830102=600=0",100,"MoeCity_bigbg_4","MoeCity_bg_4","fx_ui_bwmnc_weiqiang_01","moecitystage_1_14","moecitystage_2_14"},_mt)
}

return _datas