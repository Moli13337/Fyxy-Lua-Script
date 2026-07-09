---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIJNInfo:LWnd
local UIJNInfo = LxWndClass("UIJNInfo", LWnd)

UIJNInfo.NORMAL = 1
UIJNInfo.SIMPLE = 2


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIJNInfo:UIJNInfo()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIJNInfo:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIJNInfo:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIJNInfo:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mTitleTxt,ccClientText(20126))
	self:InitData()
	self:InitEvent()

	if not self._skillRef then
		return
	end

	if self._wndType == UIJNInfo.NORMAL then
		if not self._other then
			self:RefreshView()
		else
			self:ShowSimpleSkillInfo()
		end
	else
		self:ShowSimpleSkillInfo()
	end

	self:InitTextLineWithLanguage(self.mStatusTxt,-30)

end

function UIJNInfo:ShowSimpleSkillInfo()
	local lv = self._skillLv or 1
	local needGrade = self._needGrade or 1
	local skillRef = self._skillRef
	local skillId = self._skillId
	local skillIconTrans = CS.FindTrans(self.mSkillInfo,"SkillIcon")
	local baseClass = SkillIcon:New(self)
	baseClass:SetSkillInfo(lv,false,needGrade,1)
	baseClass:Create(skillIconTrans,skillId)

	local skillName = ccLngText(skillRef.name)
	local skillLv = skillRef.level
	local str = ccClientText(10066)
	str = string.replace(str,skillName,skillLv)
	self:SetXUITextText(self.mNameTxt,str)

	str = ccClientText(11305)
	local skillType = skillRef.type
	if skillType == 1 then
		str = string.replace(str,ccClientText(10039))
	else
		str = string.replace(str,ccClientText(10040))
	end
	self:SetXUITextText(self.mNumTxt,str)
	-- 技能描述
	local desc = ccLngText(skillRef.description)
	if self._descPara then
		desc = string.replace(desc,unpack(self._descPara))
	end
	self:SetXUITextText(self.mDescTxt,desc)
	-- 释放描述
	str = ccLngText(skillRef.description2)
	self:SetXUITextText(self.mCoolingTxt,str)
	--if string.isempty(str) then
		--CS.ShowObject(self.mCoolDiv,false)
	--end

	-- buff描述
	local stateDes = ccLngText(skillRef.stateDes)
	self:SetXUITextText(self.mBuffName,stateDes)
	if string.isempty(stateDes) then
		CS.ShowObject(self.mBuffBg,false)
	else
		CS.ShowObject(self.mBuffBg,true)
	end

	CS.ShowObject(self.mStatusBg,false)
end

function UIJNInfo:RefreshView()
	local skillRef = self._skillRef
	if not skillRef then return end

	local heroData = self._heroData
	local isGuild = self._isGuild
	local skillId = self._skillId
	local heroId = self._heroId
	local form
	local grade,refId,star,initStar,maxStar,starType,needGrade,needLevel,job,guildSkillType
	if isGuild then
		grade,refId,star,needGrade,needLevel,job,guildSkillType = heroData.grade,heroData.refId,heroData.star,self._needGrade,heroData.needLevel,heroData.job,heroData.skillType
	else
		if not heroId then
			grade = heroData.grade
			refId = heroData.refId
			star = heroData.star
			form = heroData.form
		else
			local serverData = gModelHero:GetHeroServerDataById(heroId)
			grade = serverData.grade
			refId = serverData.refId
			star = serverData.star
			form = serverData.form
		end
		local heroRef = gModelHero:GetHeroRef(refId)
		initStar,maxStar = heroRef.initStar,heroRef.maxStar
		starType = gModelHero:GetHeroStarType(refId,form)

		needGrade = 0
		local skillIdList = gModelHero:GetSkillListByRefIdAndStar(refId,star,form)
		for i,v in ipairs(skillIdList) do
			if v.skillId == skillId then
				needGrade = v.openClass
			end
		end
	end

	local skillIconTrans = CS.FindTrans(self.mSkillInfo,"SkillIcon")
	local baseClass = SkillIcon:New(self)
	baseClass:SetSkillInfo(grade,false,needGrade,1,isGuild)
	baseClass:Create(skillIconTrans,skillId)

	local skillName = ccLngText(skillRef.name)
	local skillLv = skillRef.level
	local str = ccClientText(10066)
	str = string.replace(str,skillName,skillLv)
	self:SetXUITextText(self.mNameTxt,str)

	str = ccClientText(11305)
	local skillType = skillRef.type
	if skillType == 1 then
		str = string.replace(str,ccClientText(10039))
	else
		str = string.replace(str,ccClientText(10040))
	end
	self:SetXUITextText(self.mNumTxt,str)
	-- 技能描述
	local desc = ccLngText(skillRef.description)
	if self._descPara then
		desc = string.replace(desc,unpack(self._descPara))
	end

	self:SetXUITextText(self.mDescTxt,desc)
	-- 释放描述
    str = ccLngText(skillRef.description2)
    self:SetXUITextText(self.mCoolingTxt,str)
	if string.isempty(str) then
		CS.ShowObject(self.mCoolDiv,false)
	end

    -- buff描述
	local stateDes = ccLngText(skillRef.stateDes)
	self:SetXUITextText(self.mBuffName,stateDes)
	if string.isempty(stateDes) then
		CS.ShowObject(self.mBuffBg,false)
	else
		CS.ShowObject(self.mBuffBg,true)
	end
	if isGuild then
		local jobName=gModelGuild:GetGuildSkillJobRefNameByJobType(job)
		if(needGrade >grade)then
			str = string.replace(ccClientText(13313),jobName,needLevel)
		else
			local lv= gModelGuild:GetGuildSkillRefBoolMaxLvByTypeAndNeedLv(job , guildSkillType ,grade)
			if(lv~=0)then
				str = string.replace(ccClientText(13315),jobName,lv)
			else
				str=ccClientText(10044)
			end
		end
		-- 公会激活条件
		self:SetXUITextText(self.mStatusTxt,str)
	else
		-- 当需要的阶级高于英雄的阶级时，显示激活条件
		if self._needGrade > grade then
			local needLv = 0
			local heroRef = gModelHero:GetHeroRef(refId)
			local classType = heroRef.classType
			local classId = gModelHero:ConvertToHeroGradeId(classType,self._needGrade - 1)
			local classRef = gModelHero:GetHeroClassById(classId)
			if classRef then needLv = classRef.needLevel end
			str = string.replace(ccClientText(10064),needLv)
			self:SetXUITextText(self.mStatusTxt,str)
		else
			local skillList = {}
			for i = initStar,maxStar do
				local tempStarId = gModelHero:GetStarId(starType,i)
				local tempRef = gModelHero:GetHeroStarById(tempStarId)
				if tempRef then
					table.insert(skillList,tempRef)
				end
			end

			local maxId,skillMaxStar
			for i,v in ipairs(skillList) do
				local temp = string.split(v.skillGroup,",")
				local selData = temp[self._skillIndex]
				local selDataList = string.split(selData,"=")
				local tSkillId,tNeedGrade = tonumber(selDataList[1]),tonumber(selDataList[2])
				if tSkillId > self._skillId then
					maxId = tSkillId
					skillMaxStar = v.star
					break
				end
			end
			if maxId and skillMaxStar then
				str = ccClientText(10043)
				str = string.replace(str,skillMaxStar)
				self:SetXUITextText(self.mStatusTxt,str)
			else
				str = ccClientText(10044)
				self:SetXUITextText(self.mStatusTxt,str)
			end
		end
	end
end

function UIJNInfo:InitEvent()
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end)
end

function UIJNInfo:InitData()

	self._wndType = self:GetWndArg("wndType") or UIJNInfo.NORMAL

	self._skillId = self:GetWndArg("skillId") 			-- 技能id
	self._heroId = self:GetWndArg("heroId") 				-- 英雄id
	self._needGrade = self:GetWndArg("needGrade") 		-- 激活需要的阶级
	self._skillIndex = self:GetWndArg("index") 			-- 技能里的第几个
	self._isGuild = self:GetWndArg("Guild") 				-- 公会技能
	self._heroData = self:GetWndArg("heroData") 			-- 没有heroId时传，也可使用与公会技能
	self._other = self:GetWndArg("other")
	self._descPara = self:GetWndArg("descPara")          --描述显示参数
	self._skillRef = gModelHero:GetSkillByStarId(self._skillId)
	self._skillLv = self:GetWndArg("skillLv") --技能等级
	if self._other then
		self._skillLv = self._other.lv
	end
end
------------------------------------------------------------------
return UIJNInfo


