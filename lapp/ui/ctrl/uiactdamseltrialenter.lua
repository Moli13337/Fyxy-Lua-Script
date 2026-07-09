---
--- Created by wzz.
--- DateTime: 2024/8/2 10:49:40
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActDamselTrialEnter:LWnd
local UIActDamselTrialEnter = LxWndClass("UIActDamselTrialEnter", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActDamselTrialEnter:UIActDamselTrialEnter()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActDamselTrialEnter:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActDamselTrialEnter:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActDamselTrialEnter:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._sid = self:GetWndArg("sid")
	self._pageId = self:GetWndArg("pageId")
	self._entry = self:GetWndArg("entry")

	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 初始事件
function UIActDamselTrialEnter:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mBtnFight, function() self:OnBtnFightClick() end)
end

-- 刷新条件
function UIActDamselTrialEnter:RefreshCondition()
	local conditionList = {}
	conditionList[1] = { desc = ccClientText(44828) }

	local BadgeGameCondRef = GameTable.BadgeGameCondRef
	for k, v in ipairs(self:GetConditionList()) do
		local ref = BadgeGameCondRef[v]
		if ref then
			table.insert(conditionList, { desc = ccLngText(ref.text) })
		end
	end

	self:SetComList(self.mConditionList, conditionList, function(...) return self:OnDrawConditionItem(...) end)
end

-- 刷新奖励
function UIActDamselTrialEnter:RefreshAward()
	if not self._itemUiList then
		local uiList = UIIconEasyList:New()
		uiList:Create(self, self.mItemList)
		uiList:SetShowNum(true)
		uiList:SetIconParentPath("itemRoot")
		self._itemUiList = uiList
	end

	local itemList = LUtil.GetRefItemDataList(self._entry.reward)
	self._itemUiList:RefreshList(itemList)
end

-- 初始界面化文本
function UIActDamselTrialEnter:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(44824, self._entry.id))
	self:SetWndText(self.mTxtTitle1, ccClientText(44825))
	self:SetWndText(self.mTxtTitle2, ccClientText(44826))
	self:SetWndText(self.mTxtTitle3, ccClientText(44827))
	self:SetWndButtonText(self.mBtnFight, ccClientText(44816))
	self:SetWndText(self.mCloseTip, ccClientText(10103))
end

-- 绘制条件列表项
function UIActDamselTrialEnter:OnDrawConditionItem(uilist, root, data)
	if not uilist then
		uilist = {}
	end
	self:SetTextTile(root, data.desc)
	return uilist
end

-- 点击挑战
function UIActDamselTrialEnter:OnBtnFightClick()
	local monsterRefId = self._entry.monster
	local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(monsterRefId)
	local power = monsterFormationRef.monsterPower

	local param = {
		targetId = monsterRefId,
		sid = self._sid,
		pageId = self._pageId,
		entryId = self._entry.id,
		-- otherName = self._entry.name,
		monsterPower = power,
		conditionList = self:GetConditionList(),
		monsterRefId = monsterRefId,

		-- returnFunc = function()
		-- 	GF.OpenWnd("UIActDamselTrial")
		-- 	GF.OpenWnd("UIActDamselTrialEnter")
		-- 	-- GF.OpenWnd("UIWarTempleFightList")
		-- end,
	}
	gLFightManager:SaveBattleParam(param)
	gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_ACTIVITY_155, param)
end

-- 绘制英雄列表项
function UIActDamselTrialEnter:OnDrawHeroItem(uilist, root, data)
	if not uilist then
		uilist = {}
	end

	local instanceId = root:GetInstanceID()
	local iconCls = self:GetCommonIcon(instanceId)
	iconCls:Create(root)

	iconCls:SetHeroDataSet(data)
	iconCls:SetNoShowLv(true)
	iconCls:SetShowLvMask(1)
	iconCls:DoApply()


	return uilist
end

-- 刷新界面
function UIActDamselTrialEnter:Refresh()
	self:RefreshHeroList()
	self:RefreshCondition()
	self:RefreshAward()
end

-- 获取条件id列表
function UIActDamselTrialEnter:GetConditionList()
	local moreInfo = self._entry.moreInfo
	local conditionList = {}
	local str = ""
	if string.find(moreInfo, "|") then
		local list = string.split(moreInfo, "|")
		str = list[2]
	else
		str = moreInfo
	end
	for k, v in ipairs(string.split(str, ",")) do
		conditionList[k] = tonumber(v)
	end
	-- conditionList[2] = 405
	return conditionList
end

-- 刷新英雄列表
function UIActDamselTrialEnter:RefreshHeroList()
	local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(self._entry.monster)
	local power = monsterFormationRef.monsterPower
	local heroDataList = {}
	for i = 1, 10 do
		local monster = monsterFormationRef["monster" .. i]
		if monster > 0 then
			local ref = gModelHero:GetMonsterAttrByRefId(monster)
			if ref then
				local tab = {
					id    = ref.refId,
					refId = ref.refId,
					lv    = ref.lv,
					star  = ref.starLv,
					isMon = true,
				}

				table.insert(heroDataList, tab)
			end
		end
	end
	self:SetWndText(self.mTxtPower, LUtil.PowerNumberCoversion(power))

	self:SetComList(self.mHeroList, heroDataList, function(...) return self:OnDrawHeroItem(...) end)
end

------------------------------------------------------------------
return UIActDamselTrialEnter