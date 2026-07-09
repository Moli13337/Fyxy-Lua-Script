local _keys = {refId=1,needItem=2,attr=3,addTime=4}
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
[1]=_set({1,"1=102001=20","1=2=0.02=1",14400},_mt),
[2]=_set({2,"1=102001=20","1=2=0.04=1",7200},_mt),
[3]=_set({3,"1=102001=20","1=2=0.06=1",7200},_mt),
[4]=_set({4,"1=102001=20","1=2=0.08=1",7200},_mt),
[5]=_set({5,"1=102001=20","1=2=0.10=1",7200},_mt),
[6]=_set({6,"1=102001=20","1=2=0.12=1",7200},_mt),
[7]=_set({7,"1=102001=20","1=2=0.14=1",7200},_mt),
[8]=_set({8,"1=102001=20","1=2=0.16=1",7200},_mt),
[9]=_set({9,"1=102001=20","1=2=0.18=1",7200},_mt),
[10]=_set({10,"1=102001=20","1=2=0.20=1",7200},_mt)
}

return _datas