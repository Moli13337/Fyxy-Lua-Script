local _keys = {refId=1,round=2,myName=3,otherName=4,map=5,warReportFile=6,skip=7,accelerate=8,accelerateNum=9,hideUi=10,actionUi=11,speed=12}
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
[1001]=_set({1001,20,"battlereport_0_1001","battlereport_1_1001",1001,"FirstCharge_pb",1,1,4,0,1,2},_mt),
[2001]=_set({2001,20,"battlereport_0_2001","battlereport_1_2001",1001,"Mainline-01_pb",1,1,4,0,1,2},_mt)
}

return _datas