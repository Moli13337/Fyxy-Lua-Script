local _keys = {refId=1,text=2,quality=3}
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
[410101]=_set({410101,"fishingtask_0_410101",2},_mt),
[410102]=_set({410102,"fishingtask_0_410102",3},_mt),
[410103]=_set({410103,"fishingtask_0_410103",4},_mt),
[410104]=_set({410104,"fishingtask_0_410104",5},_mt),
[410105]=_set({410105,"fishingtask_0_410105",6},_mt),
[410201]=_set({410201,"fishingtask_0_410201",2},_mt),
[410202]=_set({410202,"fishingtask_0_410202",3},_mt),
[410203]=_set({410203,"fishingtask_0_410203",4},_mt),
[410204]=_set({410204,"fishingtask_0_410204",5},_mt),
[410205]=_set({410205,"fishingtask_0_410205",6},_mt),
[410301]=_set({410301,"fishingtask_0_410301",2},_mt),
[410302]=_set({410302,"fishingtask_0_410302",3},_mt),
[410303]=_set({410303,"fishingtask_0_410303",4},_mt),
[410304]=_set({410304,"fishingtask_0_410304",5},_mt),
[410305]=_set({410305,"fishingtask_0_410305",6},_mt),
[410402]=_set({410402,"fishingtask_0_410402",3},_mt),
[410403]=_set({410403,"fishingtask_0_410403",4},_mt),
[410404]=_set({410404,"fishingtask_0_410404",5},_mt),
[410405]=_set({410405,"fishingtask_0_410405",6},_mt),
[410501]=_set({410501,"fishingtask_0_410501",2},_mt),
[410502]=_set({410502,"fishingtask_0_410502",3},_mt),
[410503]=_set({410503,"fishingtask_0_410503",4},_mt),
[410504]=_set({410504,"fishingtask_0_410504",5},_mt),
[410505]=_set({410505,"fishingtask_0_410505",6},_mt),
[410602]=_set({410602,"fishingtask_0_410602",3},_mt),
[410603]=_set({410603,"fishingtask_0_410603",4},_mt),
[410604]=_set({410604,"fishingtask_0_410604",5},_mt),
[410605]=_set({410605,"fishingtask_0_410605",6},_mt),
[410701]=_set({410701,"fishingtask_0_410701",2},_mt),
[410702]=_set({410702,"fishingtask_0_410702",3},_mt),
[410703]=_set({410703,"fishingtask_0_410703",4},_mt),
[410704]=_set({410704,"fishingtask_0_410704",5},_mt),
[410705]=_set({410705,"fishingtask_0_410705",6},_mt),
[410801]=_set({410801,"fishingtask_0_410801",2},_mt),
[410802]=_set({410802,"fishingtask_0_410802",3},_mt),
[410803]=_set({410803,"fishingtask_0_410803",4},_mt),
[410804]=_set({410804,"fishingtask_0_410804",5},_mt),
[410805]=_set({410805,"fishingtask_0_410805",6},_mt),
[410903]=_set({410903,"fishingtask_0_410903",4},_mt),
[410904]=_set({410904,"fishingtask_0_410904",5},_mt),
[410905]=_set({410905,"fishingtask_0_410905",6},_mt),
[411003]=_set({411003,"fishingtask_0_411003",4},_mt),
[411004]=_set({411004,"fishingtask_0_411004",5},_mt),
[411005]=_set({411005,"fishingtask_0_411005",6},_mt)
}

return _datas