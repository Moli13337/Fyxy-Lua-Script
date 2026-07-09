---
--- Created by Administrator.
--- DateTime: 2023/10/24 16:51:31
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaSimpleTip:LWnd
local UISagaSimpleTip = LxWndClass("UISagaSimpleTip", LWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaSimpleTip:UISagaSimpleTip()
	---@type CommonIcon
	self._heroIconCls = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaSimpleTip:OnWndClose()
	if self._heroIconCls then
		self._heroIconCls:Destroy()
		self._heroIconCls = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaSimpleTip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaSimpleTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetXUITextText(self.mSkillText,ccClientText(10046))
	self:InitData()
	self:InitEvent()
	self:Refresh()
end

function UISagaSimpleTip:Refresh()
	local refId = self._refId

	local hBaseClass = self._heroIconCls
	if not hBaseClass then
		hBaseClass = CommonIcon:New(self)
		self._heroIconCls = hBaseClass
		hBaseClass:Create(self.mHeroIcon)
	end
	hBaseClass:SetCommonReward(LItemTypeConst.TYPE_HERO, refId, 1)
	hBaseClass:DoApply()

	local ref = gModelHero:GetHeroRef(refId)
	if ref then
		local star = ref.initStar
		local name = gModelHero:GetHeroNameByRefId(refId,star)
		self:SetWndText(self.mNameTxt,name)
		local color = gModelHero:GetHeroColorByStar(star)
		self:SetXUITextTransColor(self.mNameTxt,color)

		local quaId = gModelHero:GetHeroQualityByRefId(refId,star)
		local heroMessage = gModelItem:GetHeroMessQualityById(quaId)
		if heroMessage then self:SetWndEasyImage(self.mHeadImg,heroMessage) end

		local careerType = ref.careerType
		local careerRef = GameTable.CharacterCareerRef[careerType]
		local careerImg = careerRef.jobIcon
		self:SetWndEasyImage(self.mJobIcon,careerImg)

		--local initStar = ref.initStar
		--local starId = gModelHero:GetStarId(starType,initStar)
		--if starRef then
		local effectId = gModelHero:GetHeroEffectId(refId)
		local effRef = gModelHero:GetShowEffectById(effectId)
		if effRef then
			local location = "[" .. ccLngText(effRef.location) .. "]"
			self:SetXUITextText(self.mJobTxt,location)
		end
		--end

		local skillIdList = gModelHero:GetSkillListByRefIdAndStar(refId,star)
		local skillTransList = self._skillTransList
		for i,v in ipairs(skillTransList) do
			CS.ShowObject(v,true)
			local skillData = skillIdList[i]
			local skillIconTrans = CS.FindTrans(v,"SkillIcon")
			local baseClass = SkillIcon:New(self)
			if skillData then
				local grade = 0
				local skillId = skillData.skillId
				local openClass = skillData.openClass
				if self._openAllSkill then
					local maxStar = ref.maxStar
					local maxSkillList = gModelHero:GetSkillListByRefIdAndStar(refId,maxStar)
					if maxSkillList and maxSkillList[i] then
						skillData = maxSkillList[i]
						skillId = skillData.skillId
						openClass = skillData.openClass
					end
					grade = 10
				end
				baseClass:SetSkillInfo(grade,false,openClass,1)
				baseClass:Create(skillIconTrans,skillId,function()
					local hero = {refId = refId,star = star,grade = grade}
					GF.OpenWndTop("UIJNInfo",{skillId = skillId,needGrade = openClass,index = i,heroData = hero})
				end)
			else
				baseClass:SetShowIcon(false,false)
				baseClass:Create(skillIconTrans,0)
			end
		end
	end
end

function UISagaSimpleTip:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
end

function UISagaSimpleTip:InitData()
	self._refId = self:GetWndArg("refId")
	self._openAllSkill = self:GetWndArg("openAllSkill")
	self._skillTransList = {
		self.mSkill1,
		self.mSkill2,
		self.mSkill3,
		self.mSkill4,
	}
end

------------------------------------------------------------------
return UISagaSimpleTip


