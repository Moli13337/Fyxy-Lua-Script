---
--- Created by BY.
--- DateTime: 2023/10/17 17:48:40
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMalCopySowPop:LWnd
local UIMalCopySowPop = LxWndClass("UIMalCopySowPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMalCopySowPop:UIMalCopySowPop()
	self._skillTrList = {}
	self._heroIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMalCopySowPop:OnWndClose()
	self:ClearCommonIconList(self._heroIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMalCopySowPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMalCopySowPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end
function UIMalCopySowPop:HeroListItem(list, item, itemdata, itempos)
	local heroIcon = self:FindWndTrans(item,"HeroIcon")
	local nameText = self:FindWndTrans(item,"NameText")

	local refId		= itemdata.hero
	local heroData =
	{
		refId = refId,
		star = gModelHero:GetHeroRef(refId).initStar,
	}
	local instanceID = item:GetInstanceID()
	local name = gModelHero:GetHeroNameByRefId(heroData.refId,heroData.star)

	local baseClass = self._heroIconList[instanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._heroIconList[instanceID] = baseClass
		baseClass:Create(heroIcon)
		self:SetIconClickScale(heroIcon, true)
	end
	baseClass:SetHeroDataSet(heroData)
	baseClass:SetNoShowLv(true)
	baseClass:DoApply()

	self:SetWndText(nameText, name)
	self:InitTextShowWithLanguage(nameText)

	self:SetWndClick(heroIcon,function ()
		gModelGeneral:OpenHeroSimpleTip(refId)
	end)
end

function UIMalCopySowPop:SkillListItem(list, item, itemdata, itempos)
	local skillIcon = self:FindWndTrans(item,"SkillIcon")
	local selImg = self:FindWndTrans(item,"SelImg")
	local skill = itemdata.skill
	self._skillTrList[skill] = selImg

	CS.ShowObject(skillIcon,skill > 0)
	if skill > 0 then
		local ref = gModelHero:GetSkillByStarId(skill)
		self:SetWndEasyImage(skillIcon,ref.icon)
	end
	self:SetWndClick(item,function ()
		if skill > 0 then
			self:OnClickSkill(skill)
		end
	end)
end

function UIMalCopySowPop:OnClickSkill(skill)
	local _skillTrList = self._skillTrList or {}
	local _skill = self._skill
	if _skill then
		local tr = _skillTrList[_skill]
		CS.ShowObject(tr,false)
	end
	self._skill = skill
	local tr = _skillTrList[skill]
	CS.ShowObject(tr,true)
	self:RefreshSkill()
end
function UIMalCopySowPop:InitCommand()
	local bossItem = self:GetWndArg("boss")

	local entryCfg = bossItem.entryCfg
	if not entryCfg then return end

	local show,showPos,showSize,name,skill,moreInfoW,method
	= entryCfg.show,entryCfg.showPos,entryCfg.showSize,entryCfg.name,entryCfg.skill,entryCfg.moreInfo,entryCfg.method
	local arr = string.split(moreInfoW,"|")
	showPos = arr[5]
	if not string.isempty(method) then
		local des = string.gsub(method,"\\n","\n")
		self:SetWndText(self.mBossDesText,des)
	end
	if not string.isempty(show) then
		local heroImageArr = string.split(show,"=")
		local type = heroImageArr[1]
		local heroImage = heroImageArr[2] or heroImageArr
		local parent
		if type == "1" or not heroImageArr[2] then
			parent = self.mHeroImg
			self:SetWndEasyImage(parent,heroImage,nil,true)
		else
			parent = self.mHeroSpine
			self:CreateWndSpine(parent,heroImage,heroImage,false)
		end
		parent.localScale = Vector2.New(showSize/10,showSize/10)
		CS.ShowObject(parent,true)
		if not string.isempty(showPos) then
			local pos = LxDataHelper.ParseVector2NotEmpty(showPos)
			self:SetAnchorPos(parent, pos)
		end
	end
	local bossName = arr[4]
	if not string.isempty(bossName) then
		local prant = self.mBossText
		if LxUiHelper.IsImgPathValid(bossName) then
			prant = self.mBossNameImg
			self:SetWndEasyImage(prant,bossName,nil,true)
		else
			prant = self.mBossText
			self:SetWndText(prant,bossName)
		end
		CS.ShowObject(prant,true)
	end
	if not string.isempty(skill) then
		local skillArr = string.split(skill,",")
		local list = {}
		for i = 1, 4 do
			local skillId = skillArr[i]
			table.insert(list,{skill = skillId and tonumber(skillId) or 0})
		end
		local uiSkillList = self:GetUIScroll("UIMalCopySowPop_mSkillScroll")
		uiSkillList:Create(self.mSkillScroll,list,function(...) self:SkillListItem(...) end)
		self:OnClickSkill(list[1].skill)
	end
	if not string.isempty(arr[3]) then
		local heroArr = string.split(arr[3],"=")
		local list = {}
		for i, v in ipairs(heroArr) do
			table.insert(list,{hero = tonumber(v)})
		end
		local uiHeroList = self:GetUIScroll("UIMalCopySowPop_mHeroScroll")
		uiHeroList:Create(self.mHeroScroll,list,function(...) self:HeroListItem(...) end)
	end
end

function UIMalCopySowPop:RefreshSkill()
	local skill = self._skill
	if not skill then return end
	local ref = gModelHero:GetSkillByStarId(skill)

	local name,description = ref.name,ref.description
	self:SetWndText(self.mSkillNameText,ccLngText(name))
	self:SetWndText(self.mSkillDesText,ccLngText(description))
end

function UIMalCopySowPop:InitEvent()
	self:SetWndText(self.mTitle1Text,ccClientText(27615))
	self:SetWndText(self.mTitle2Text,ccClientText(27616))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:SetWndClick(self.mBg,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
end
------------------------------------------------------------------
return UIMalCopySowPop


