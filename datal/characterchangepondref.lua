local _keys = {refId=1,condition=2,level=3,name=4,getHero=5,rate=6}
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
[10001]=_set({10001,"1=4",1,"characterchangepond_0_10001",1403,100000},_mt),
[10002]=_set({10002,"1=4",1,"characterchangepond_0_10002",1402,100000},_mt),
[10003]=_set({10003,"1=4",1,"characterchangepond_0_10003",1401,100000},_mt),
[20001]=_set({20001,"1=5",1,"characterchangepond_0_20001",1501,60000},_mt),
[20002]=_set({20002,"1=5",1,"characterchangepond_0_20002",1502,60000},_mt),
[20003]=_set({20003,"1=5",1,"characterchangepond_0_20003",1601,11666},_mt),
[20004]=_set({20004,"1=5",1,"characterchangepond_0_20004",1602,11666},_mt),
[20005]=_set({20005,"1=5",1,"characterchangepond_0_20005",1603,11666},_mt),
[20006]=_set({20006,"1=5",1,"characterchangepond_0_20006",1701,1250},_mt),
[20007]=_set({20007,"1=5",1,"characterchangepond_0_20007",1702,1250},_mt),
[20008]=_set({20008,"1=5",1,"characterchangepond_0_20008",1703,1250},_mt),
[20009]=_set({20009,"1=5",1,"characterchangepond_0_20009",1704,1250},_mt),
[30001]=_set({30001,"2=4",1,"characterchangepond_0_30001",2401,100000},_mt),
[30002]=_set({30002,"2=4",1,"characterchangepond_0_30002",2402,100000},_mt),
[30003]=_set({30003,"2=4",1,"characterchangepond_0_30003",2403,100000},_mt),
[40001]=_set({40001,"2=5",1,"characterchangepond_0_40001",2501,60000},_mt),
[40002]=_set({40002,"2=5",1,"characterchangepond_0_40002",2502,60000},_mt),
[40003]=_set({40003,"2=5",1,"characterchangepond_0_40003",2601,11666},_mt),
[40004]=_set({40004,"2=5",1,"characterchangepond_0_40004",2602,11666},_mt),
[40005]=_set({40005,"2=5",1,"characterchangepond_0_40005",2603,11666},_mt),
[40006]=_set({40006,"2=5",1,"characterchangepond_0_40006",2701,1250},_mt),
[40007]=_set({40007,"2=5",1,"characterchangepond_0_40007",2703,1250},_mt),
[40008]=_set({40008,"2=5",1,"characterchangepond_0_40008",2704,1250},_mt),
[40009]=_set({40009,"2=5",1,"characterchangepond_0_40009",2705,1250},_mt),
[50001]=_set({50001,"3=4",1,"characterchangepond_0_50001",3401,100000},_mt),
[50002]=_set({50002,"3=4",1,"characterchangepond_0_50002",3402,100000},_mt),
[50003]=_set({50003,"3=4",1,"characterchangepond_0_50003",3403,100000},_mt),
[60001]=_set({60001,"3=5",1,"characterchangepond_0_60001",3501,60000},_mt),
[60002]=_set({60002,"3=5",1,"characterchangepond_0_60002",3502,60000},_mt),
[60003]=_set({60003,"3=5",1,"characterchangepond_0_60003",3601,11666},_mt),
[60004]=_set({60004,"3=5",1,"characterchangepond_0_60004",3602,11666},_mt),
[60005]=_set({60005,"3=5",1,"characterchangepond_0_60005",3603,11666},_mt),
[60006]=_set({60006,"3=5",1,"characterchangepond_0_60006",3701,1250},_mt),
[60007]=_set({60007,"3=5",1,"characterchangepond_0_60007",3702,1250},_mt),
[60008]=_set({60008,"3=5",1,"characterchangepond_0_60008",3705,1250},_mt),
[60009]=_set({60009,"3=5",1,"characterchangepond_0_60009",3703,1250},_mt)
}

return _datas