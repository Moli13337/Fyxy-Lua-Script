---
--- Created by wzz.
--- DateTime: 2024/3/19 20:29:21
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReRecastJNSel:LWnd
local UIReRecastJNSel = LxWndClass("UIReRecastJNSel", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReRecastJNSel:UIReRecastJNSel()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReRecastJNSel:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReRecastJNSel:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReRecastJNSel:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	local argList = self:GetWndArgList()
	self._runeData = argList.runeData
	self._processMax, self._processCur = self:GetRecastNum()

	self:InitTexts()
	self:InitHandler()
	self:InitSkillList(self._runeData.skillId)
	self:SetRunIcon(self.mRuneIcon, self._runeData)
	self:Refresh()
end

-- 刷新界面
function UIReRecastJNSel:Refresh()
	local serverData = self._runeData
	if not serverData then return end
	local refId = serverData.refId
	local runeRef = gModelRune:GetRuneInfoByRefId(refId)

	local name = ccLngText(runeRef.name)
	self:SetWndText(self.mTxtRuneName, name)
	local quality = runeRef.quality
	local color = gModelItem:GetColorByQualityId(quality)
	self:SetXUITextTransColor(self.mTxtRuneName, color)
end

function UIReRecastJNSel:InitHandler()
	self:SetWndClick(self.mReturnBtn, function() self:WndClose() end)
	self:SetWndClick(self.mMask, function() self:WndClose() end)
end

function UIReRecastJNSel:OpenSkillTips(skillData)
	if not skillData then return end
	local skillType = skillData.skillType
	local refId = skillData.refId
	gModelRune:OpenNewRuneSkillWnd(refId, skillType)
end

function UIReRecastJNSel:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(24940))
	self:SetWndText(self.mTxtTips, ccClientText(24941))
end

function UIReRecastJNSel:GetRecastNum()
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

function UIReRecastJNSel:InitSkillList(skillList)
	local uiSkillList = self._uiSkillList
	if not uiSkillList then
		uiSkillList = UIListEasy:New()
		uiSkillList:Create(self, self.mSkillList)
		uiSkillList:SetFuncOnItemDraw(function(...)
			self:OnDrawSkillCell(...)
		end)
		self._uiSkillList = uiSkillList
	end
	uiSkillList:RemoveAll()
	for i, v in ipairs(skillList) do
		uiSkillList:AddData(i, v)
	end
	uiSkillList:RefreshList()
end

function UIReRecastJNSel:SetRunIcon(runeIconTrans, runeData)
	local runeIconCls = self._runeIconCls
	if not runeIconCls then
		runeIconCls = CommonIcon:New()
		self._runeIconCls = runeIconCls
		runeIconCls:Create(runeIconTrans)
	end
	runeIconCls:SetRuneData(runeData)
	runeIconCls:DoApply()
end

function UIReRecastJNSel:OnDrawSkillCell(list, item, itemdata, itempos, fromHeadTail)
	local skillData = gModelRune:GetSkillInfoByRefId(itemdata)
	if skillData then
		local skill = tonumber(skillData.SkillId)
		local skillTrans = CS.FindTrans(item, "Skill")
		if skillTrans then
			local SkillIconTrans = CS.FindTrans(skillTrans, "SkillIcon")
			if SkillIconTrans then
				local baseClass = SkillIcon:New(self)
				baseClass:Create(SkillIconTrans, skill, function()
					self:OpenSkillTips(skillData)
				end)
			end
		end
		local skillRef = gModelHero:GetSkillByStarId(skill)
		if skillRef then
			local SkillNameTrans = CS.FindTrans(item, "SkillName")
			if SkillNameTrans then
				local skillName = ccLngText(skillRef.name)
				local quality = skillData.quality
				local qualityRef =  GameTable.RarityRef[quality + 2]
				self:SetWndText(SkillNameTrans, skillName) -- ssssadfadsf
				self:SetXUITextTransColor(SkillNameTrans,qualityRef.nameColor)
			end
			local SkillDescTrans = CS.FindTrans(item, "SkillDesc")
			if SkillDescTrans then
				local desc = ccLngText(skillRef.description)
				self:SetWndText(SkillDescTrans, desc)
			end
		end

		local txtProcessTrans = CS.FindTrans(item, "TxtProcess")
		if txtProcessTrans then
			local str
			if self._processMax > self._processCur then
				str = ccClientText(24943)
				str = string.replace(str, self._processCur, self._processMax)
			else
				str = ccClientText(24944)
				str = string.replace(str, self._processCur, self._processMax)
			end
			self:SetWndText(txtProcessTrans, str)
		end
		local btnGoTrans = CS.FindTrans(item, "BtnGo")
		if btnGoTrans then
			self:SetWndClick(btnGoTrans, function()
				self:OnClickBtnGo(itemdata, itempos)
			end)
			self:SetWndButtonText(btnGoTrans, ccClientText(24942), nil, nil, -30)
		end


		-- self:SetWndClick(item, function()
		-- 	self:OpenSkillTips(skillData)
		-- end)
	end
end

function UIReRecastJNSel:OnClickBtnGo(itemdata, pos)
	GF.OpenWnd("UIReRecastJNSelConfirm", {runeData = self._runeData, skillRefId = itemdata, pos = pos})

	-- local serverData = self._runeData
	-- if not serverData then return end
	-- local refId = serverData.refId
	-- local ref = gModelRune:GetRuneInfoByRefId(refId)
	-- if not ref then return end
	-- local accumulateFixedSkill = ref.accumulateFixedSkill
	-- local payList,itemType = self:GetSkillRecastItemList()
	-- if not itemType then
	-- 	if LOG_INFO_ENABLED then printInfoNR("没有配置的技能选择类型") end
	-- 	return
	-- end
	-- GF.OpenWnd("UIReJNSel",{runeId = serverData.id,selectType = ModelRune.RECASTTYPE_4,skillList = accumulateFixedSkill,useItemType = itemType})
end

------------------------------------------------------------------
return UIReRecastJNSel