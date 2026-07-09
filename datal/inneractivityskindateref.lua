local _keys = {refId=1,sort=2,reward=3,saleOnShop=4,race=5,frame=6,efficacy=7,hero=8,skin=9,expend=10}
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
[101]=_set({101,101,"1=13570101=1=0",0,5,6,"",5701,570103,"1=100218=100=0"},_mt),
[102]=_set({102,102,"1=13170301=1=0",0,1,5,"",1703,170303,"1=100218=60=0"},_mt),
[103]=_set({103,103,"1=13270301=1=0",0,2,5,"",2703,270303,"1=100218=60=0"},_mt),
[104]=_set({104,104,"1=13170401=1=0",0,1,4,"",1704,170403,"1=100218=20=0"},_mt),
[105]=_set({105,105,"1=13370301=1=0",0,3,4,"",3703,370303,"1=100218=20=0"},_mt)
}

return _datas