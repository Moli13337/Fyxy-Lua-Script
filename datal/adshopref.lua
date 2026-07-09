local _keys = {refId=1,type=2,configByModule1=3,configByModule2=4,resetType=5,redPointConfig=6}
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
[10101]=_set({10101,101,"1=1","",1,12103001},_mt),
[10102]=_set({10102,101,"3=1","",1,12103001},_mt),
[20101]=_set({20101,201,"1001=1=2","1=102001=25",1,14500011},_mt),
[20102]=_set({20102,201,"1005=2=2","1=102001=50",2,14500011},_mt),
[20201]=_set({20201,202,"1001=1","",1,14500011},_mt),
[20202]=_set({20202,202,"1005=1","",3,14500011},_mt),
[30101]=_set({30101,301,"2=1","",9,14700000},_mt),
[40101]=_set({40101,401,"100401=1","",4,0},_mt),
[50101]=_set({50101,501,"1001=5","",1,15500021},_mt)
}

return _datas