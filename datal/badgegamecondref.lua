local _keys = {refId=1,type=2,value=3,text=4}
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
[101]=_set({101,1,"3","badgegamecond_0_101"},_mt),
[102]=_set({102,1,"4","badgegamecond_0_102"},_mt),
[103]=_set({103,1,"5","badgegamecond_0_103"},_mt),
[104]=_set({104,1,"6","badgegamecond_0_104"},_mt),
[201]=_set({201,2,"1","badgegamecond_0_201"},_mt),
[202]=_set({202,2,"2","badgegamecond_0_202"},_mt),
[203]=_set({203,2,"3","badgegamecond_0_203"},_mt),
[301]=_set({301,3,"0.2","badgegamecond_0_301"},_mt),
[302]=_set({302,3,"0.3","badgegamecond_0_302"},_mt),
[303]=_set({303,3,"0.5","badgegamecond_0_303"},_mt),
[304]=_set({304,3,"0.7","badgegamecond_0_304"},_mt),
[401]=_set({401,4,"0=3=2=0","badgegamecond_0_401"},_mt),
[402]=_set({402,4,"0=4=2=0","badgegamecond_0_402"},_mt),
[403]=_set({403,4,"0=3=2=0;2=0=2=1","badgegamecond_0_403"},_mt),
[404]=_set({404,4,"0=4=2=0;1|2=0=2=1","badgegamecond_0_404"},_mt),
[405]=_set({405,4,"1=0=1=1","badgegamecond_0_405"},_mt),
[406]=_set({406,4,"2=0=1=1","badgegamecond_0_406"},_mt),
[407]=_set({407,4,"3=0=1=1","badgegamecond_0_407"},_mt),
[408]=_set({408,4,"4|5=0=1=1","badgegamecond_0_408"},_mt),
[409]=_set({409,4,"1=0=1=2","badgegamecond_0_409"},_mt),
[410]=_set({410,4,"2=0=1=2","badgegamecond_0_410"},_mt),
[411]=_set({411,4,"3=0=1=2","badgegamecond_0_411"},_mt),
[412]=_set({412,4,"4|5=0=1=2","badgegamecond_0_412"},_mt)
}

return _datas