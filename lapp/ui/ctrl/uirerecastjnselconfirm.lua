---
--- Created by wzz.
--- DateTime: 2024/3/20 14:33:31
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReRecastJNSelConfirm:LWnd
local UIReRecastJNSelConfirm = LxWndClass("UIReRecastJNSelConfirm", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReRecastJNSelConfirm:UIReRecastJNSelConfirm()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReRecastJNSelConfirm:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReRecastJNSelConfirm:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReRecastJNSelConfirm:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isVie = gLGameLanguage:IsVieVersion()
	local argList = self:GetWndArgList()
	self._runeData = argList.runeData
	self._leftSkillRefId = argList.skillRefId
	self._pos = argList.pos

	self:InitTexts()
	self:InitHandler()
	self:InitSkillList()
	self:Refresh()
	self:RefreshForeign()
end

function UIReRecastJNSelConfirm:GetRecastNum()
	local serverData = self._runeData
	if not serverData then return end
	local refId = serverData.refId
	local ref = gModelRune:GetRuneInfoByRefId(refId)
	if not ref then return end
	local recastNum = ref.recastNum
	local tRecastNum = recastNum - 1
	local recast = serverData.recast
	return tRecastNum, recast
end

function UIReRecastJNSelConfirm:InitHandler()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mReturnBtn, function() self:WndClose() end)
	self:SetWndClick(self.mBtnGo, function() self:OnClickBtnConfirm() end)
end

function UIReRecastJNSelConfirm:OpenSkillTips(skillData)
	if not skillData then return end
	local skillType = skillData.skillType
	local refId = skillData.refId
	gModelRune:OpenNewRuneSkillWnd(refId, skillType)
end

function UIReRecastJNSelConfirm:RefreshForeign()
	if self._isVie then
		self:InitTextLineWithLanguage(self.mTxtLeftTips,0)
		self:InitTextLineWithLanguage(self.mTxtRightTips,0)
		self:InitTextSizeWithLanguage(self.mTxtLeftTips,-1)
		self:InitTextSizeWithLanguage(self.mTxtRightTips,-1)

		local textTran = CS.FindTrans(self.mBtnGo,"Light/Text")
		self:InitTextSizeWithLanguage(textTran,-5)
		 textTran = CS.FindTrans(self.mBtnGo,"Gray/Text")
		self:InitTextSizeWithLanguage(textTran,-5)
	end
end

function UIReRecastJNSelConfirm:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(24945))
	self:SetWndText(self.mTxtLeftTips, ccClientText(24946))
	self:SetWndText(self.mTxtRightTips, ccClientText(24947))
	self:SetWndText(self.mTxtTips, ccClientText(24948))

	self:SetWndButtonText(self.mBtnGo, ccClientText(24949))
end

function UIReRecastJNSelConfirm:Refresh()
	local max, cur = self:GetRecastNum()
	if max > cur then
		str = ccClientText(24943)
		str = string.replace(str, cur, max)
	else
		str = ccClientText(24944)
		str = string.replace(str, cur, max)
	end
	self:SetWndText(self.mTxtProcess, str)

	self:RefreshLeftIcon()
	self:RefreshRightIcon()
end

function UIReRecastJNSelConfirm:OnClickSkillIconFunc(skillId)
	if self._skillId == skillId then
		return
	end
	self._skillId = skillId

	self:InitSkillList()

	self:RefreshRightIcon()
end

function UIReRecastJNSelConfirm:OnDrawSkillCell(list, item, itemdata, itempos)
	local skill = tonumber(itemdata.SkillId)
	local skillRef = gModelHero:GetSkillByStarId(skill)
	if not skillRef then return end
	local SkillTrans = self:FindWndTrans(item, "Skill")
	local SkillIconTrans = self:FindWndTrans(SkillTrans, "SkillIcon")
	local SkillNameTrans = self:FindWndTrans(item, "SkillName")
	local SignImgTrans = self:FindWndTrans(item, "SignImg")
	local SignTextTrans = self:FindWndTrans(item, "SignText")
	local SelImgTrans = self:FindWndTrans(item, "SelImg")

	local skillIconList = self._skillIconList
	if not skillIconList then
		skillIconList = {}
		self._skillIconList = skillIconList
	end
	local InstanceID = item:GetInstanceID()
	local baseClass = skillIconList[InstanceID]
	if not baseClass then
		baseClass = SkillIcon:New(self)
	end
	skillIconList[InstanceID] = baseClass
	baseClass:Create(SkillIconTrans, skill, function()
		local skillType = itemdata.skillType
		local refId = itemdata.refId
		gModelRune:OpenNewRuneSkillWnd(refId, skillType)
	end)
	local skillName = ccLngText(skillRef.name)
	self:SetWndText(SkillNameTrans, skillName)

	local quality = itemdata.quality
	local qualityRef =  GameTable.RarityRef[quality + 2]
	self:SetXUITextTransColor(SkillNameTrans,qualityRef.nameColor)

	CS.ShowObject(SkillNameTrans, true)

	local skillId = itemdata.refId
	local textId = 13269
	local sign = tonumber(itemdata.sign)
	local showSign = sign ~= 0
	CS.ShowObject(SignImgTrans, showSign)
	if showSign then
		local img = "public_bg_di_13"
		if sign == 2 then
			img = "activity_zygift_ui_3"
			textId = 13268
		end
		self:SetWndEasyImage(SignImgTrans, img)
	end
	self:SetWndText(SignTextTrans, ccClientText(textId))
	CS.ShowObject(SignTextTrans, showSign)

	self:SetWndClick(SkillIconTrans, function()
		self:OnClickSkillIconFunc(tonumber(itemdata.refId))
	end)
	self:SetWndLongClick(SkillIconTrans, function()
		gModelRune:OpenNewRuneSkillWnd(itemdata.refId, itemdata.skillType)
	end, 0.2, true)
	local isSel = self._skillId == tonumber(itemdata.refId)
	CS.ShowObject(SelImgTrans, isSel)
end

function UIReRecastJNSelConfirm:GetSkillList()
	if not self._skillList then
		local runeSkillRef = gModelRune:GetSkillInfoByRefId(self._leftSkillRefId)
		local list = {}
		local lev = runeSkillRef.skillLevel
		for k, v in pairs(GameTable.MagicRuneSkillRef) do
			if v.skillLevel == lev then
				table.insert(list, v)
			end
		end
		table.sort(list, function(skill1, skill2)
			local sign1, sign2 = skill1.sign, skill2.sign
			if sign1 ~= sign2 then
				return sign1 > sign2
			end
			if skill1 ~= skill2 then
				return skill1.sort < skill2.sort
			end
			return skill1.refId < skill2.refId
		end)
		self._skillList = list
		self._skillId = tonumber(list[1].refId)
	end
	return self._skillList
end

function UIReRecastJNSelConfirm:RefreshRightIcon()
	local runeSkillRef = gModelRune:GetSkillInfoByRefId(self._skillId)
	local skillRef = gModelRune:GetSkillRefByRuneSkillId(self._skillId)
	local skillName = ccLngText(skillRef.name)
	self:SetWndText(self.mTxtSkillNameRight, skillName)

	local color = gModelItem:GetColorByQualityId(runeSkillRef.quality + 2)
	self:SetXUITextTransColor(self.mTxtSkillNameRight, color)


	local baseClass = self._skillRightIcon
	if not baseClass then
		baseClass = SkillIcon:New(self)
		self._skillRightIcon = baseClass
	end
	baseClass:ShowLvl(true)
	baseClass:Create(self.mSkillIconRight, skillRef.refId, function()
		self:OpenSkillTips(runeSkillRef)
	end)
end

function UIReRecastJNSelConfirm:InitSkillList()
	local list = self:GetSkillList()
	local uiSkillList = self._uiSkillList
	if uiSkillList then
		uiSkillList:RefreshData(list)
	else
		uiSkillList = self:GetUIScroll("uiSkillList")
		self._uiSkillList = uiSkillList
		uiSkillList:Create(self.mSkillList, list, function(...) self:OnDrawSkillCell(...) end, UIItemList.WRAP)
	end
end

function UIReRecastJNSelConfirm:RefreshLeftIcon()
	local runeSkillRef = gModelRune:GetSkillInfoByRefId(self._leftSkillRefId)
	local skillRef = gModelRune:GetSkillRefByRuneSkillId(self._leftSkillRefId)
	local skillName = ccLngText(skillRef.name)
	self:SetWndText(self.mTxtSkillNameLeft, skillName)

	local color = gModelItem:GetColorByQualityId(runeSkillRef.quality + 2)
	self:SetXUITextTransColor(self.mTxtSkillNameLeft, color)

	local baseClass = self._skillLeftIcon
	if not baseClass then
		baseClass = SkillIcon:New(self)
		self._skillLeftIcon = baseClass
	end
	baseClass:ShowLvl(true)
	baseClass:Create(self.mSkillIconLeft, skillRef.refId, function()
		self:OpenSkillTips(runeSkillRef)
	end)
end


function UIReRecastJNSelConfirm:OnClickBtnConfirm()
	local max, cur = self:GetRecastNum()
	if cur < max then
		GF.ShowMessage(ccClientText(24950))
		return
	end
	gModelRune:OnRuneRecastReq(self._runeData.id, 4, self._skillId, 1, self._pos)
end

------------------------------------------------------------------
return UIReRecastJNSelConfirm