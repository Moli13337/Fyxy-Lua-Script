local _keys = {refId=1,monsterPower=2,heroId=3,name=4,type=5,scale=6,effectId=7,lv=8,commonSkill=9,activeSkill=10,pasvSkill=11,belongSkillGroup=12,quality=13,starLv=14,raceType=15,careerType=16,Atk=17,MaxHP=18,Def=19,Speed=20,Crit=21,DefCrit=22,Hit=23,Dodge=24,Ctrl=25,DefCtrl=26,Treat=27,BeTreat=28,CritRatio=29,AddHurt=30,AvoidHurt=31,PHurt=32,PAvoidHurt=33,MHurt=34,MAvoidHurt=35,AddHurt1=36,AddHurt2=37,AddHurt3=38,AddHurt4=39,AvoidCrit=40,Strike=41,DefStrike=42,BreakDef=43,AddHurtFinal=44,AvoidHurtFinal=45,genderType=46}
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
[3000001]=_set({3000001,0,2705,"",1,1,2705,1,2705011,"2705111=1","","",5,5,1,1,21,90,4,30,0,0,1,0,0,0,0,0,1.5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},_mt)
}

return _datas