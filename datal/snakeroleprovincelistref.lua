local _keys = {refId=1,name=2,provinceId=3}
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
[1]=_set({1,"snakeroleprovincelist_0_1",1},_mt),
[2]=_set({2,"snakeroleprovincelist_0_2",2},_mt),
[3]=_set({3,"snakeroleprovincelist_0_3",3},_mt),
[4]=_set({4,"snakeroleprovincelist_0_4",4},_mt),
[5]=_set({5,"snakeroleprovincelist_0_5",5},_mt),
[6]=_set({6,"snakeroleprovincelist_0_6",6},_mt),
[7]=_set({7,"snakeroleprovincelist_0_7",7},_mt),
[8]=_set({8,"snakeroleprovincelist_0_8",8},_mt),
[9]=_set({9,"snakeroleprovincelist_0_9",9},_mt),
[10]=_set({10,"snakeroleprovincelist_0_10",10},_mt),
[11]=_set({11,"snakeroleprovincelist_0_11",11},_mt),
[12]=_set({12,"snakeroleprovincelist_0_12",12},_mt),
[13]=_set({13,"snakeroleprovincelist_0_13",13},_mt),
[14]=_set({14,"snakeroleprovincelist_0_14",14},_mt),
[15]=_set({15,"snakeroleprovincelist_0_15",15},_mt),
[16]=_set({16,"snakeroleprovincelist_0_16",16},_mt),
[17]=_set({17,"snakeroleprovincelist_0_17",17},_mt),
[18]=_set({18,"snakeroleprovincelist_0_18",18},_mt),
[19]=_set({19,"snakeroleprovincelist_0_19",19},_mt),
[20]=_set({20,"snakeroleprovincelist_0_20",20},_mt),
[21]=_set({21,"snakeroleprovincelist_0_21",21},_mt),
[22]=_set({22,"snakeroleprovincelist_0_22",22},_mt),
[23]=_set({23,"snakeroleprovincelist_0_23",23},_mt),
[24]=_set({24,"snakeroleprovincelist_0_24",24},_mt),
[25]=_set({25,"snakeroleprovincelist_0_25",25},_mt),
[26]=_set({26,"snakeroleprovincelist_0_26",26},_mt),
[27]=_set({27,"snakeroleprovincelist_0_27",27},_mt),
[28]=_set({28,"snakeroleprovincelist_0_28",28},_mt),
[29]=_set({29,"snakeroleprovincelist_0_29",29},_mt),
[30]=_set({30,"snakeroleprovincelist_0_30",30},_mt),
[31]=_set({31,"snakeroleprovincelist_0_31",31},_mt),
[32]=_set({32,"snakeroleprovincelist_0_32",32},_mt),
[33]=_set({33,"snakeroleprovincelist_0_33",33},_mt),
[34]=_set({34,"snakeroleprovincelist_0_34",34},_mt)
}

return _datas