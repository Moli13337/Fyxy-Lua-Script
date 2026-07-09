local _keys = {refId=1,collectionDegree=2,desc=3,attr=4}
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
[1]=_set({1,50,"magiccollection_0_1","204=1=0.01=1"},_mt),
[2]=_set({2,100,"magiccollection_0_2","205=1=0.01=1"},_mt),
[3]=_set({3,150,"magiccollection_0_3","204=1=0.01=1"},_mt),
[4]=_set({4,200,"magiccollection_0_4","205=1=0.01=1"},_mt),
[5]=_set({5,250,"magiccollection_0_5","204=1=0.01=1"},_mt),
[6]=_set({6,300,"magiccollection_0_6","205=1=0.01=1"},_mt),
[7]=_set({7,400,"magiccollection_0_7","204=1=0.01=1,205=1=0.01=1"},_mt),
[8]=_set({8,500,"magiccollection_0_8","204=1=0.01=1,205=1=0.01=1"},_mt),
[9]=_set({9,600,"magiccollection_0_9","204=1=0.01=1,205=1=0.01=1"},_mt),
[10]=_set({10,700,"magiccollection_0_10","204=1=0.01=1,205=1=0.01=1"},_mt),
[11]=_set({11,800,"magiccollection_0_11","204=1=0.01=1,205=1=0.01=1"},_mt),
[12]=_set({12,900,"magiccollection_0_12","204=1=0.01=1,205=1=0.01=1"},_mt),
[13]=_set({13,1000,"magiccollection_0_13","204=1=0.01=1,205=1=0.01=1"},_mt),
[14]=_set({14,1100,"magiccollection_0_14","1=2=0.003=1,3=2=0.003=1"},_mt),
[15]=_set({15,1200,"magiccollection_0_15","1=2=0.003=1,3=2=0.003=1"},_mt),
[16]=_set({16,1300,"magiccollection_0_16","1=2=0.003=1,3=2=0.003=1"},_mt),
[17]=_set({17,1400,"magiccollection_0_17","1=2=0.003=1,3=2=0.003=1"},_mt),
[18]=_set({18,1500,"magiccollection_0_18","1=2=0.003=1,3=2=0.003=1"},_mt),
[19]=_set({19,1600,"magiccollection_0_19","1=2=0.003=1,3=2=0.003=1"},_mt),
[20]=_set({20,1700,"magiccollection_0_20","1=2=0.003=1,3=2=0.003=1"},_mt),
[21]=_set({21,1800,"magiccollection_0_21","1=2=0.003=1,3=2=0.003=1"},_mt),
[22]=_set({22,1900,"magiccollection_0_22","1=2=0.003=1,3=2=0.003=1"},_mt),
[23]=_set({23,2000,"magiccollection_0_23","1=2=0.003=1,3=2=0.003=1"},_mt),
[24]=_set({24,2200,"magiccollection_0_24","1=2=0.003=1,3=2=0.003=1"},_mt),
[25]=_set({25,2400,"magiccollection_0_25","1=2=0.003=1,3=2=0.003=1"},_mt),
[26]=_set({26,2600,"magiccollection_0_26","1=2=0.003=1,3=2=0.003=1"},_mt),
[27]=_set({27,2800,"magiccollection_0_27","1=2=0.003=1,3=2=0.003=1"},_mt),
[28]=_set({28,3000,"magiccollection_0_28","1=2=0.003=1,3=2=0.003=1"},_mt),
[29]=_set({29,3200,"magiccollection_0_29","1=2=0.003=1,3=2=0.003=1"},_mt),
[30]=_set({30,3400,"magiccollection_0_30","1=2=0.003=1,3=2=0.003=1"},_mt),
[31]=_set({31,3600,"magiccollection_0_31","1=2=0.003=1,3=2=0.003=1"},_mt),
[32]=_set({32,3800,"magiccollection_0_32","1=2=0.003=1,3=2=0.003=1"},_mt),
[33]=_set({33,4000,"magiccollection_0_33","1=2=0.003=1,3=2=0.003=1"},_mt),
[34]=_set({34,4200,"magiccollection_0_34","1=2=0.003=1,3=2=0.003=1"},_mt),
[35]=_set({35,4400,"magiccollection_0_35","1=2=0.003=1,3=2=0.003=1"},_mt),
[36]=_set({36,4600,"magiccollection_0_36","1=2=0.003=1,3=2=0.003=1"},_mt),
[37]=_set({37,4800,"magiccollection_0_37","1=2=0.003=1,3=2=0.003=1"},_mt),
[38]=_set({38,5000,"magiccollection_0_38","1=2=0.003=1,3=2=0.003=1"},_mt)
}

return _datas