local _keys = {refId=1,sort=2,type=3,name=4,jump=5,description=6}
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
[101]=_set({101,101,1,"growthitemjump_0_101",15500021,"growthitemjump_1_101"},_mt),
[102]=_set({102,102,1,"growthitemjump_0_102",12430000,"growthitemjump_1_102"},_mt),
[103]=_set({103,103,1,"growthitemjump_0_103",10200000,"growthitemjump_1_103"},_mt),
[104]=_set({104,104,1,"growthitemjump_0_104",16400000,"growthitemjump_1_104"},_mt),
[105]=_set({105,105,1,"growthitemjump_0_105",14400000,"growthitemjump_1_105"},_mt),
[201]=_set({201,201,2,"growthitemjump_0_201",15200000,"growthitemjump_1_201"},_mt),
[202]=_set({202,202,2,"growthitemjump_0_202",10200000,"growthitemjump_1_202"},_mt),
[203]=_set({203,203,2,"growthitemjump_0_203",12300000,"growthitemjump_1_203"},_mt),
[204]=_set({204,204,2,"growthitemjump_0_204",11500002,"growthitemjump_1_204"},_mt),
[205]=_set({205,205,2,"growthitemjump_0_205",11500003,"growthitemjump_1_205"},_mt),
[206]=_set({206,206,2,"growthitemjump_0_206",13100000,"growthitemjump_1_206"},_mt),
[207]=_set({207,207,2,"growthitemjump_0_207",11500001,"growthitemjump_1_207"},_mt),
[208]=_set({208,208,2,"growthitemjump_0_208",17100010,"growthitemjump_1_208"},_mt),
[301]=_set({301,301,3,"growthitemjump_0_301",14700001,"growthitemjump_1_301"},_mt),
[302]=_set({302,302,3,"growthitemjump_0_302",10200000,"growthitemjump_1_302"},_mt),
[303]=_set({303,303,3,"growthitemjump_0_303",12410000,"growthitemjump_1_303"},_mt),
[304]=_set({304,304,3,"growthitemjump_0_304",16400000,"growthitemjump_1_304"},_mt),
[401]=_set({401,401,4,"growthitemjump_0_401",10200000,"growthitemjump_1_401"},_mt),
[402]=_set({402,402,4,"growthitemjump_0_402",16400000,"growthitemjump_1_402"},_mt),
[403]=_set({403,403,4,"growthitemjump_0_403",12410000,"growthitemjump_1_403"},_mt),
[404]=_set({404,404,4,"growthitemjump_0_404",14500011,"growthitemjump_1_404"},_mt),
[501]=_set({501,501,5,"growthitemjump_0_501",10200000,"growthitemjump_1_501"},_mt),
[502]=_set({502,502,5,"growthitemjump_0_502",16400000,"growthitemjump_1_502"},_mt),
[503]=_set({503,503,5,"growthitemjump_0_503",12420000,"growthitemjump_1_503"},_mt),
[504]=_set({504,504,5,"growthitemjump_0_504",16302000,"growthitemjump_1_504"},_mt),
[601]=_set({601,601,6,"growthitemjump_0_601",10200000,"growthitemjump_1_601"},_mt),
[602]=_set({602,602,6,"growthitemjump_0_602",16400000,"growthitemjump_1_602"},_mt),
[603]=_set({603,603,6,"growthitemjump_0_603",14400000,"growthitemjump_1_603"},_mt),
[604]=_set({604,604,6,"growthitemjump_0_604",16700001,"growthitemjump_1_604"},_mt),
[605]=_set({605,605,6,"growthitemjump_0_605",27001000,"growthitemjump_1_605"},_mt),
[701]=_set({701,701,7,"growthitemjump_0_701",10200000,"growthitemjump_1_701"},_mt),
[702]=_set({702,702,7,"growthitemjump_0_702",12450000,"growthitemjump_1_702"},_mt),
[801]=_set({801,801,8,"growthitemjump_0_801",17400001,"growthitemjump_1_801"},_mt),
[901]=_set({901,901,9,"growthitemjump_0_901",12103000,"growthitemjump_1_901"},_mt),
[902]=_set({902,902,9,"growthitemjump_0_902",12102000,"growthitemjump_1_902"},_mt),
[903]=_set({903,903,9,"growthitemjump_0_903",12106100,"growthitemjump_1_903"},_mt)
}

return _datas