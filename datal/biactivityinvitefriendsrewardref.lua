local _keys = {refId=1,nume=2,inviteText=3,reward=4}
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
[1]=_set({1,"biactivityinvitefriendsreward_0_1","biactivityinvitefriendsreward_1_1","1=102001=666"},_mt),
[2]=_set({2,"biactivityinvitefriendsreward_0_2","biactivityinvitefriendsreward_1_2","1=102001=666"},_mt),
[3]=_set({3,"biactivityinvitefriendsreward_0_3","biactivityinvitefriendsreward_1_3","1=102001=666"},_mt),
[4]=_set({4,"biactivityinvitefriendsreward_0_4","biactivityinvitefriendsreward_1_4","1=102001=666"},_mt),
[5]=_set({5,"biactivityinvitefriendsreward_0_5","biactivityinvitefriendsreward_1_5","1=102001=666"},_mt)
}

return _datas