local _keys = {refId=1,type=2,name=3,hideType=4,overlayType=5,res=6,prefab=7,prefabSize=8,resType=9,resSite=10,resSize=11,monsterType=12,reward=13,exchange=14,parameter=15,choose=16}
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
[1101]=_set({1101,1,"dreamlandevent_0_1101",0,0,"","XR_Yehuaniang01","LH_Yehuaniang01",2,"0;0",0.9,"1=1=1001","1=11010|2=11011|3=11012","","1=0.6;2=0.64;3=0.68","dreamlandevent_1_1101"},_mt),
[1201]=_set({1201,1,"dreamlandevent_0_1201",0,0,"","XR_Songshuniang01","LH_Songshuniang01",2,"0;0",0.9,"1=2=2001","1=12010|2=12011|3=12012","","1=0.66;2=0.7;3=0.74","dreamlandevent_1_1201"},_mt),
[1301]=_set({1301,1,"dreamlandevent_0_1301",0,0,"","XR_Meiguiniang01","LH_Meiguiniang01",2,"0;0",0.9,"1=3=3001","1=13010|2=13011|3=13012","","1=0.76;2=0.8;3=0.82","dreamlandevent_1_1301"},_mt),
[2201]=_set({2201,3,"dreamlandevent_0_2201",0,0,"wonderLand_icon_3","","",1,"0;0",0.9,"","1=21010|2=21011|3=21012","","",""},_mt),
[2202]=_set({2202,3,"dreamlandevent_0_2202",0,0,"wonderLand_icon_3","","",1,"0;0",0.9,"","1=11010|2=11011|3=11012","","",""},_mt)
}

return _datas