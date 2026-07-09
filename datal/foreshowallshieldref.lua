local _keys = {refId=1,name=2,sort=3,functionOpen=4,bg=5,title=6,quest=7,helpTxt1=8,helpTxt2=9,reward=10}
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
[102]=_set({102,"foreshowallshield_0_102",1,16200000,"functionPreview_ad_3","functionPreview_txt_1","1=310008,2=310009,3=310010","foreshowallshield_1_102","","1=102001=10=0,1=100110=5=0,1=104001=500=0,1=101001=500=0"},_mt),
[103]=_set({103,"foreshowallshield_0_103",2,27000000,"functionPreview_ad_2","functionPreview_txt_2","1=310008,2=310009,3=310010","foreshowallshield_1_103","","1=102001=10=0,1=100110=5=0,1=104001=500=0,1=101001=500=0"},_mt),
[104]=_set({104,"foreshowallshield_0_104",3,14700001,"functionPreview_ad_6","functionPreview_txt_3","1=310008,2=310009,3=310010","foreshowallshield_1_104","","1=102001=10=0,1=100110=5=0,1=104001=500=0,1=101001=500=0"},_mt),
[105]=_set({105,"foreshowallshield_0_105",4,17200001,"functionPreview_ad_6","functionPreview_txt_4","1=310008,2=310009,3=310010","foreshowallshield_1_105","","1=102001=10=0,1=100110=5=0,1=104001=500=0,1=101001=500=0"},_mt),
[107]=_set({107,"foreshowallshield_0_107",5,13100000,"functionPreview_ad_5","functionPreview_txt_5","1=310008,2=310009,3=310010","foreshowallshield_1_107","","1=102001=10=0,1=100110=5=0,1=104001=500=0,1=101001=500=0"},_mt),
[108]=_set({108,"foreshowallshield_0_108",6,15700001,"functionPreview_ad_2","functionPreview_txt_6","1=310008,2=310009,3=310010","foreshowallshield_1_108","","1=102001=10=0,1=100110=5=0,1=104001=500=0,1=101001=500=0"},_mt),
[109]=_set({109,"foreshowallshield_0_109",7,10308000,"functionPreview_ad_7","functionPreview_txt_7","1=310008,2=310009,3=310010","foreshowallshield_1_109","","1=102001=20=0,1=100110=10=0,1=104001=1000=0,1=101001=1000=0"},_mt),
[110]=_set({110,"foreshowallshield_0_110",8,17700000,"functionPreview_ad_2","functionPreview_txt_8","1=310008,2=310009,3=310010","foreshowallshield_1_110","","1=102001=20=0,1=100110=10=0,1=104001=1000=0,1=101001=1000=0"},_mt),
[111]=_set({111,"foreshowallshield_0_111",9,16400000,"functionPreview_ad_7","functionPreview_txt_9","1=310008,2=310009,3=310010","foreshowallshield_1_111","","1=102001=20=0,1=100110=10=0,1=104001=1000=0,1=101001=1000=0"},_mt),
[112]=_set({112,"foreshowallshield_0_112",10,11900000,"functionPreview_ad_5","functionPreview_txt_10","1=310008,2=310009,3=310010","foreshowallshield_1_112","","1=102001=20=0,1=100110=10=0,1=104001=1000=0,1=101001=1000=0"},_mt),
[113]=_set({113,"foreshowallshield_0_113",11,12300000,"functionPreview_ad_4","functionPreview_txt_11","1=310008,2=310009,3=310010","foreshowallshield_1_113","","1=102001=20=0,1=100110=10=0,1=104001=1000=0,1=101001=1000=0"},_mt),
[114]=_set({114,"foreshowallshield_0_114",12,13800000,"functionPreview_ad_1","functionPreview_txt_12","1=310008,2=310009,3=310010","foreshowallshield_1_114","","1=102001=20=0,1=100110=10=0,1=104001=1000=0,1=101001=1000=0"},_mt),
[115]=_set({115,"foreshowallshield_0_115",13,15600001,"functionPreview_ad_3","functionPreview_txt_13","1=310008,2=310009,3=310010","foreshowallshield_1_115","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[116]=_set({116,"foreshowallshield_0_116",14,10200010,"functionPreview_ad_7","functionPreview_txt_14","1=310008,2=310009,3=310010","foreshowallshield_1_116","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[117]=_set({117,"foreshowallshield_0_117",15,34000001,"functionPreview_ad_5","functionPreview_txt_15","1=310008,2=310009,3=310010","foreshowallshield_1_117","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[118]=_set({118,"foreshowallshield_0_118",16,12400000,"functionPreview_ad_1","functionPreview_txt_16","1=310008,2=310009,3=310010","foreshowallshield_1_118","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[119]=_set({119,"foreshowallshield_0_119",17,12100000,"functionPreview_ad_5","functionPreview_txt_17","1=310008,2=310009,3=310010","foreshowallshield_1_119","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[120]=_set({120,"foreshowallshield_0_120",18,12106000,"functionPreview_ad_4","functionPreview_txt_18","1=310008,2=310009,3=310010","foreshowallshield_1_120","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[121]=_set({121,"foreshowallshield_0_121",19,12102000,"functionPreview_ad_4","functionPreview_txt_19","1=310008,2=310009,3=310010","foreshowallshield_1_121","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[122]=_set({122,"foreshowallshield_0_122",20,12109000,"functionPreview_ad_4","functionPreview_txt_20","1=310008,2=310009,3=310010","foreshowallshield_1_122","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[123]=_set({123,"foreshowallshield_0_123",21,12111000,"functionPreview_ad_6","functionPreview_txt_33","1=310008,2=310009,3=310010","foreshowallshield_1_123","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[124]=_set({124,"foreshowallshield_0_124",26,21000000,"functionPreview_ad_7","functionPreview_txt_21","1=310008,2=310009,3=310010","foreshowallshield_1_124","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[125]=_set({125,"foreshowallshield_0_125",22,32000001,"functionPreview_ad_7","functionPreview_txt_22","1=310008,2=310009,3=310010","foreshowallshield_1_125","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[126]=_set({126,"foreshowallshield_0_126",23,33000001,"functionPreview_ad_1","functionPreview_txt_34","1=310008,2=310009,3=310010","foreshowallshield_1_126","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[127]=_set({127,"foreshowallshield_0_127",24,13600000,"functionPreview_ad_5","functionPreview_txt_23","1=310008,2=310009,3=310010","foreshowallshield_1_127","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[128]=_set({128,"foreshowallshield_0_128",25,13200000,"functionPreview_ad_4","functionPreview_txt_24","1=310008,2=310009,3=310010","foreshowallshield_1_128","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[129]=_set({129,"foreshowallshield_0_129",27,35000000,"functionPreview_ad_2","functionPreview_txt_35","1=310008,2=310009,3=310010","foreshowallshield_1_129","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[130]=_set({130,"foreshowallshield_0_130",28,16500000,"functionPreview_ad_1","functionPreview_txt_25","1=310008,2=310009,3=310010","foreshowallshield_1_130","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[131]=_set({131,"foreshowallshield_0_131",29,17100010,"functionPreview_ad_2","functionPreview_txt_26","1=310008,2=310009,3=310010","foreshowallshield_1_131","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[132]=_set({132,"foreshowallshield_0_132",30,18200000,"functionPreview_ad_6","functionPreview_txt_27","1=310008,2=310009,3=310010","foreshowallshield_1_132","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[133]=_set({133,"foreshowallshield_0_133",31,17400000,"functionPreview_ad_2","functionPreview_txt_28","1=310008,2=310009,3=310010","foreshowallshield_1_133","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[134]=_set({134,"foreshowallshield_0_134",32,16302000,"functionPreview_ad_3","functionPreview_txt_29","1=310008,2=310009,3=310010","foreshowallshield_1_134","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[135]=_set({135,"foreshowallshield_0_135",33,16105000,"functionPreview_ad_3","functionPreview_txt_31","1=310008,2=310009,3=310010","foreshowallshield_1_135","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[136]=_set({136,"foreshowallshield_0_136",37,13911000,"functionPreview_ad_4","functionPreview_txt_36","1=310008,2=310009,3=310010","foreshowallshield_1_136","","1=102001=50=0,1=100110=25=0,1=104001=2500=0,1=101001=2500=0"},_mt),
[139]=_set({139,"foreshowallshield_0_139",33,21008000,"functionPreview_ad_2","functionPreview_txt_38","1=310008,2=310009,3=310010","foreshowallshield_1_139","","1=102001=100=0,1=100110=50=0,1=104001=5000=0,1=101001=5000=0"},_mt),
[141]=_set({141,"foreshowallshield_0_141",35,31000003,"functionPreview_ad_5","functionPreview_txt_40","1=310008,2=310009,3=310010","foreshowallshield_1_141","","1=102001=100=0,1=100110=50=0,1=104001=5000=0,1=101001=5000=0"},_mt)
}

return _datas