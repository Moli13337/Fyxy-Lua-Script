local _keys = {refId=1,type=2,channel=3,name=4,welfareId=5,rmbNeed=6,item=7,rebate=8}
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
[1]=_set({1,100,"herocomes.pack1.mycard","topupbaiao_0_1",151,6,"1=100304=30",""},_mt),
[2]=_set({2,100,"herocomes.pack2.mycard","topupbaiao_0_2",152,10,"1=100304=50",""},_mt),
[3]=_set({3,100,"herocomes.pack3.mycard","topupbaiao_0_3",153,18,"1=100304=90",""},_mt),
[4]=_set({4,100,"herocomes.pack4.mycard","topupbaiao_0_4",154,30,"1=100304=150",""},_mt),
[5]=_set({5,100,"herocomes.pack5.mycard","topupbaiao_0_5",155,34,"1=100304=170",""},_mt),
[6]=_set({6,100,"herocomes.pack6.mycard","topupbaiao_0_6",156,60,"1=100304=300",""},_mt),
[7]=_set({7,100,"herocomes.pack7.mycard","topupbaiao_0_7",157,70,"1=100304=350",""},_mt),
[8]=_set({8,100,"herocomes.pack8.mycard","topupbaiao_0_8",158,80,"1=100304=400",""},_mt),
[9]=_set({9,100,"herocomes.pack9.mycard","topupbaiao_0_9",159,90,"1=100304=450",""},_mt),
[10]=_set({10,100,"herocomes.pack10.mycard","topupbaiao_0_10",160,100,"1=100304=500","1=100211=1,1=102001=50,1=101001=300000"},_mt),
[11]=_set({11,100,"herocomes.pack11.mycard","topupbaiao_0_11",161,150,"1=100304=750",""},_mt),
[12]=_set({12,100,"herocomes.pack12.mycard","topupbaiao_0_12",162,200,"1=100304=1000","1=100211=2,1=102001=100,1=101001=600000"},_mt),
[13]=_set({13,100,"herocomes.pack13.mycard","topupbaiao_0_13",163,230,"1=100304=1150",""},_mt),
[14]=_set({14,100,"herocomes.pack14.mycard","topupbaiao_0_14",164,298,"1=100304=1490",""},_mt),
[15]=_set({15,100,"herocomes.pack15.mycard","topupbaiao_0_15",165,328,"1=100304=1690",""},_mt),
[16]=_set({16,100,"herocomes.pack16.mycard","topupbaiao_0_16",166,400,"1=100304=2000",""},_mt),
[17]=_set({17,100,"herocomes.pack17.mycard","topupbaiao_0_17",167,500,"1=100304=2500",""},_mt),
[18]=_set({18,100,"herocomes.pack18.mycard","topupbaiao_0_18",168,600,"1=100304=3000","1=100211=6,1=102001=300,1=1702002=1"},_mt),
[19]=_set({19,100,"herocomes.pack19.mycard","topupbaiao_0_19",169,648,"1=100304=3290",""},_mt),
[20]=_set({20,100,"herocomes.pack20.mycard","topupbaiao_0_20",170,1000,"1=100304=5000","1=100211=10,1=102001=500,1=1702003=1"},_mt),
[21]=_set({21,100,"herocomes.pack21.mycard","topupbaiao_0_21",171,2000,"1=100304=10000","1=100211=20,1=102001=1000,1=1702003=2"},_mt),
[101]=_set({101,900,"herocomes.pack1.paypal","topupbaiao_0_101",175,6,"1=100304=33",""},_mt),
[102]=_set({102,900,"herocomes.pack2.paypal","topupbaiao_0_102",176,12,"1=100304=70",""},_mt),
[103]=_set({103,900,"herocomes.pack3.paypal","topupbaiao_0_103",177,18,"1=100304=100",""},_mt),
[104]=_set({104,900,"herocomes.pack4.paypal","topupbaiao_0_104",178,30,"1=100304=170",""},_mt),
[105]=_set({105,900,"herocomes.pack5.paypal","topupbaiao_0_105",179,68,"1=100304=330",""},_mt),
[106]=_set({106,900,"herocomes.pack6.paypal","topupbaiao_0_106",180,98,"1=100304=490",""},_mt),
[107]=_set({107,900,"herocomes.pack7.paypal","topupbaiao_0_107",181,128,"1=100304=670",""},_mt),
[108]=_set({108,900,"herocomes.pack8.paypal","topupbaiao_0_108",182,198,"1=100304=990",""},_mt),
[109]=_set({109,900,"herocomes.pack9.paypal","topupbaiao_0_109",183,328,"1=100304=1690",""},_mt),
[110]=_set({110,900,"herocomes.pack10.paypal","topupbaiao_0_110",184,448,"1=100304=2290",""},_mt),
[111]=_set({111,900,"herocomes.pack11.paypal","topupbaiao_0_111",185,648,"1=100304=3290",""},_mt),
[201]=_set({201,1200,"herocomes.pack1.xsolla","topupbaiao_0_201",186,6,"1=100304=33",""},_mt),
[202]=_set({202,1200,"herocomes.pack2.xsolla","topupbaiao_0_202",187,12,"1=100304=70",""},_mt),
[203]=_set({203,1200,"herocomes.pack3.xsolla","topupbaiao_0_203",188,18,"1=100304=100",""},_mt),
[204]=_set({204,1200,"herocomes.pack4.xsolla","topupbaiao_0_204",189,30,"1=100304=170",""},_mt),
[205]=_set({205,1200,"herocomes.pack5.xsolla","topupbaiao_0_205",190,68,"1=100304=330",""},_mt),
[206]=_set({206,1200,"herocomes.pack6.xsolla","topupbaiao_0_206",191,98,"1=100304=490",""},_mt),
[207]=_set({207,1200,"herocomes.pack7.xsolla","topupbaiao_0_207",192,128,"1=100304=670",""},_mt),
[208]=_set({208,1200,"herocomes.pack8.xsolla","topupbaiao_0_208",193,198,"1=100304=990",""},_mt),
[209]=_set({209,1200,"herocomes.pack9.xsolla","topupbaiao_0_209",194,328,"1=100304=1690",""},_mt),
[210]=_set({210,1200,"herocomes.pack10.xsolla","topupbaiao_0_210",195,448,"1=100304=2290",""},_mt),
[211]=_set({211,1200,"herocomes.pack11.xsolla","topupbaiao_0_211",196,648,"1=100304=3290",""},_mt),
[301]=_set({301,100,"herocomes.pack1.gift.mycard","topupbaiao_0_301",111,6,"1=100211=10,1=1800001=10,1=110025=1,1=105001=60",""},_mt),
[302]=_set({302,100,"herocomes.pack2.gift.mycard","topupbaiao_0_302",112,18,"1=100212=1,1=1200005=20,1=1200004=90,1=105001=180",""},_mt),
[303]=_set({303,100,"herocomes.pack3.gift.mycard","topupbaiao_0_303",113,34,"1=100212=2,1=1200005=30,1=110033=15,1=105001=300",""},_mt),
[304]=_set({304,100,"herocomes.pack4.gift.mycard","topupbaiao_0_304",114,328,"1=102001=3280,1=100211=40,1=120802=1,1=105001=3280",""},_mt),
[401]=_set({401,1200,"herocomes.pack1.gift.xsolla","topupbaiao_0_401",121,6,"1=100211=10,1=1800001=10,1=110025=1,1=105001=60",""},_mt),
[402]=_set({402,1200,"herocomes.pack2.gift.xsolla","topupbaiao_0_402",122,18,"1=100212=1,1=1200005=20,1=1200004=90,1=105001=180",""},_mt),
[403]=_set({403,1200,"herocomes.pack3.gift.xsolla","topupbaiao_0_403",123,30,"1=100212=2,1=1200005=30,1=110033=15,1=105001=300",""},_mt),
[404]=_set({404,1200,"herocomes.pack4.gift.xsolla","topupbaiao_0_404",124,328,"1=102001=3280,1=100211=40,1=120802=1,1=105001=3280",""},_mt)
}

return _datas