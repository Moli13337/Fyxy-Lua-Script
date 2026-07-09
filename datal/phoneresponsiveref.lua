local _keys = {refId=1,manufacturer=2,model=3,resolution=4,high=5}
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
[4001]=_set({4001,"SHARP","FS8018","2040x1080",0},_mt),
[5001]=_set({5001,"Xiaomi","MI PLAY","2280x1080",50},_mt),
[5002]=_set({5002,"Xiaomi","MIX FOLD","2480x1860",50},_mt),
[5003]=_set({5003,"Xiaomi","PLAY","2280x1080",50},_mt),
[6001]=_set({6001,"motorola","XT1943-1","2246x1080",50},_mt),
[6002]=_set({6002,"motorola","XT1941-2","1520x720",50},_mt),
[7001]=_set({7001,"vivo","vivo x27 pro","2460x1080",50},_mt),
[7002]=_set({7002,"vivo","V1732A","1520x720",0},_mt),
[7003]=_set({7003,"vivo","V1813A","2280x1080",0},_mt),
[7004]=_set({7004,"vivo","V1730EA","2280x1080",0},_mt),
[7005]=_set({7005,"vivo","V1818CA","1520x720",0},_mt),
[7006]=_set({7006,"vivo","V1818A","1520x720",0},_mt),
[8001]=_set({8001,"xiaolajiao","R15","2246x1080",50},_mt),
[9001]=_set({9001,"meitu","T9","2244x1080",50},_mt),
[10001]=_set({10001,"realme","realme X","2340x1080",50},_mt),
[11001]=_set({11001,"ROG","ROG Phone5","2448x1080",50},_mt),
[12001]=_set({12001,"samsung","SM-G9700","2280x1080",0},_mt),
[13001]=_set({13001,"ZTE","ZTE A2019 Pro","2248x1080",0},_mt),
[14001]=_set({14001,"HMD Global","Nokia X7","2246x1080",0},_mt),
[15001]=_set({15001,"Meizu","M1852","2220x1080",0},_mt),
[16001]=_set({16001,"Xiaomi","MI 8 Lite","1080x2280",50},_mt)
}

return _datas