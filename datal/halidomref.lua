local _keys = {refId=1,type=2,name=3,sort=4,icon=5,star=6,condition=7,num=8,desc=9}
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
[101]=_set({101,1,"halidom_0_101",101,"icon_item_170101",10,"602=0=3","1=170101=50=0","halidom_1_101"},_mt),
[102]=_set({102,1,"halidom_0_102",102,"icon_item_170102",10,"1=0=1","1=170102=50=0","halidom_1_102"},_mt),
[103]=_set({103,1,"halidom_0_103",103,"icon_item_170103",10,"1115=0=1","1=170103=50=0","halidom_1_103"},_mt),
[104]=_set({104,1,"halidom_0_104",104,"icon_item_170104",10,"609=0=5,1","1=170104=50=0","halidom_1_104"},_mt),
[201]=_set({201,2,"halidom_0_201",201,"icon_item_170201",10,"105=0=10","1=170201=50=0","halidom_1_201"},_mt),
[202]=_set({202,2,"halidom_0_202",202,"icon_item_170202",10,"2302=0=1","1=170202=50=0","halidom_1_202"},_mt),
[203]=_set({203,2,"halidom_0_203",203,"icon_item_170203",10,"658=0=1","1=170203=50=0","halidom_1_203"},_mt),
[204]=_set({204,2,"halidom_0_204",204,"icon_item_170204",10,"2103=0=1","1=170204=50=0","halidom_1_204"},_mt),
[205]=_set({205,2,"halidom_0_205",205,"icon_item_170205",10,"761=0=1","1=170205=50=0","halidom_1_205"},_mt),
[301]=_set({301,3,"halidom_0_301",301,"icon_item_170301",10,"","1=170301=50=0","halidom_1_301"},_mt),
[302]=_set({302,3,"halidom_0_302",302,"icon_item_170302",10,"","1=170302=50=0","halidom_1_302"},_mt),
[303]=_set({303,3,"halidom_0_303",303,"icon_item_170303",10,"","1=170303=50=0","halidom_1_303"},_mt),
[304]=_set({304,3,"halidom_0_304",304,"icon_item_170304",10,"","1=170304=50=0","halidom_1_304"},_mt),
[305]=_set({305,3,"halidom_0_305",305,"icon_item_170305",10,"","1=170305=50=0","halidom_1_305"},_mt),
[401]=_set({401,4,"halidom_0_401",401,"icon_item_170401",10,"","1=170401=50=0","halidom_1_401"},_mt),
[402]=_set({402,4,"halidom_0_402",402,"icon_item_170402",10,"","1=170402=50=0","halidom_1_402"},_mt),
[403]=_set({403,4,"halidom_0_403",403,"icon_item_170403",10,"","1=170403=50=0","halidom_1_403"},_mt),
[404]=_set({404,4,"halidom_0_404",404,"icon_item_170404",10,"","1=170404=50=0","halidom_1_404"},_mt),
[405]=_set({405,4,"halidom_0_405",405,"icon_item_170405",10,"","1=170405=50=0","halidom_1_405"},_mt),
[406]=_set({406,4,"halidom_0_406",406,"icon_item_170406",10,"","1=170406=50=0","halidom_1_406"},_mt)
}

return _datas