local _keys = {refId=1,name=2,bg=3,petId=4,attr=5}
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
[1001]=_set({1001,"magicpetrelation_0_1001","public_cell_17_5","1910101,1910102","1=1=263=1,3=1=3288=1,104=1=0.02=1"},_mt),
[1002]=_set({1002,"magicpetrelation_0_1002","public_cell_17_5","1910103,1910104","1=1=263=1,3=1=3288=1,103=1=0.02=1"},_mt),
[2001]=_set({2001,"magicpetrelation_0_2001","public_cell_17_6","1910201","1=1=526=1,3=1=6576=1,105=1=0.02=1"},_mt),
[2002]=_set({2002,"magicpetrelation_0_2002","public_cell_17_6","1910202","1=1=526=1,3=1=6576=1,106=1=0.02=1"},_mt),
[2003]=_set({2003,"magicpetrelation_0_2003","public_cell_17_6","1910203","1=1=526=1,3=1=6576=1,204=1=0.03=1"},_mt),
[2004]=_set({2004,"magicpetrelation_0_2004","public_cell_17_6","1910204","1=1=526=1,3=1=6576=1,205=1=0.03=1"},_mt),
[3001]=_set({3001,"magicpetrelation_0_3001","public_cell_17_7","1910301","1=1=1052=1,3=1=13152=1,101=1=0.04=1"},_mt),
[3002]=_set({3002,"magicpetrelation_0_3002","public_cell_17_7","1910302","1=1=1052=1,3=1=13152=1,102=1=0.04=1"},_mt),
[3003]=_set({3003,"magicpetrelation_0_3003","public_cell_17_7","1910303","1=1=1052=1,3=1=13152=1,204=1=0.04=1"},_mt),
[3004]=_set({3004,"magicpetrelation_0_3004","public_cell_17_7","1910304","1=1=1052=1,3=1=13152=1,205=1=0.04=1"},_mt)
}

return _datas