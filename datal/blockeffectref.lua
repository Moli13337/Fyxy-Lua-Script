local _keys = {refId=1,name=2,animation=3,tpye=4,attackEffect=5,attackSound=6,bulletEffect=7,bulletTrack=8,bulletTime=9,hitEffect=10,hitSound=11,skillTime=12}
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
[10011]=_set({10011,"小怪1普攻","attack1",1,"fx_munaiyi01_attack1",0,"",0,300,"fx_munaiyi01_attack1_hit","",500},_mt),
[10021]=_set({10021,"小怪2普攻","attack1",1,"fx_chaiquan01_attack",0,"",0,300,"fx_chaiquan01_attack_hit","",500},_mt),
[10031]=_set({10031,"小怪3普攻","attack1",2,"fx_nainiu01_attack1",0,"fx_nainiu01_attack1_bullet",100,300,"fx_nainiu01_attack1_hit","",500},_mt),
[10041]=_set({10041,"小怪4普攻","attack1",1,"fx_anubisi01_attack",0,"",0,300,"fx_anubisi01_attack_hit","",500},_mt),
[10051]=_set({10051,"小怪5普攻","attack1",2,"fx_daiyanjingshuijie01_attack",0,"fx_daiyanjingshuijie01_attack_bullet",100,300,"fx_daiyanjingshuijie01_attack_hit","",500},_mt),
[10012]=_set({10012,"小怪1技能","skill1",1,"fx_munaiyi01_skill1",0,"",0,300,"fx_munaiyi01_skill1_hit","",500},_mt),
[10022]=_set({10022,"小怪2技能","skill1",1,"fx_chaiquan01_skill1",0,"",0,300,"fx_chaiquan01_skill1_hit","",500},_mt),
[10032]=_set({10032,"小怪3技能","skill1",2,"fx_nainiu01_skill1",0,"fx_nainiu01_skill1_1_bullet",100,300,"fx_nainiu01_skill1_1_hit","",500},_mt),
[10042]=_set({10042,"小怪4技能","skill1",1,"fx_anubisi01_skill1",0,"",0,300,"fx_anubisi01_skill1_hit","",500},_mt),
[10052]=_set({10052,"小怪5技能","skill1",2,"fx_daiyanjingshuijie01_skill2",0,"",0,300,"fx_daiyanjingshuijie01_skill2_hit","",500},_mt),
[10981]=_set({10981,"己方防禦塔普攻","attack1",2,"fx_tianshi01_attack1",0,"fx_tianshi01_attack1_bullet",100,300,"fx_tianshi01_attack1_hit","",500},_mt),
[10991]=_set({10991,"敌方防禦塔普攻","attack1",2,"fx_meimo01_attack1",0,"fx_meimo01_attack1_bullet",100,300,"fx_meimo01_attack1_hit","",500},_mt),
[10982]=_set({10982,"己方防禦塔技能","skill1",2,"fx_tianshi01_skill1",0,"",0,300,"fx_tianshi01_skill1_hit","",500},_mt),
[10992]=_set({10992,"敌方防禦塔技能","skill1",2,"fx_meimo01_skill1",0,"fx_meimo01_skill1_bullet",100,300,"fx_meimo01_skill1_hit","",500},_mt)
}

return _datas