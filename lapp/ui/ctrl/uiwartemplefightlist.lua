---
--- Created by wzz.
--- DateTime: 2024/5/10 10:34:14
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWarTempleFightList:LWnd
local UIWarTempleFightList = LxWndClass("UIWarTempleFightList", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWarTempleFightList:UIWarTempleFightList()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWarTempleFightList:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWarTempleFightList:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWarTempleFightList:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()


	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitTexts()
	self:InitEvents()
	self:RefreshEmptyTips()


	self:TimerStartImpl({
		callOnStart = true,
		key = "RefreshTime",
		loopcnt = -1,
		interval = 1,
		func = function()
			self:RefreshTime()
		end
	})

	self:Refresh()
end

-- 是否为快速挑战
function UIWarTempleFightList:IsFastFight(monsterRefId, npcId)
	local ref = gModelHero:GetMonsterFormationRefByRefId(monsterRefId)
	local per = GameTable.BattleTempleConfigRef.overPercent
	local monster = ref.monsterPower
	local myPower = gModelPower:GetMainCityPower()
	myPower = tonumber(myPower)
	per = 1 + per / 100
	if myPower >= monster * per then
		gModelWarTemple:WarTempleQuickFightReq(npcId)
		return true
	end

	return false
end

-- 点击头像
function UIWarTempleFightList:OnClickPlayer(playerId)
	if playerId == 0 then
		GF.ShowMessage(ccClientText(42040))
		return
	end
	gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_WAR_TEMPLE, LPlayerShowConst.OTHER_SYSTEM)
end

-- 初始界面化文本
function UIWarTempleFightList:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(42033))
end

-- 刷新空列表
function UIWarTempleFightList:RefreshEmptyTips()
	local text = self.mEmptyText
	local emptyList = self:GetCommonEmptyList("_empty")
	local data =
	{
		refId = 37002,
		IntroTran = text,
		--TextBgTran,
		--IconTran,
		--GetBtn,
		--GetBtnText
		--ButtonRoot,
	}
	emptyList:RefreshUI(data)
end

-- 点击刷新
function UIWarTempleFightList:OnClickBtnConfirm()
	local leftTime = gModelWarTemple:GetLeftRefreshRecordTime()
	if leftTime > 0 then
		GF.ShowMessage(ccClientText(42038, leftTime))
		return
	end

	gModelWarTemple:WarTempleChallengeListUpdateReq()
	gModelWarTemple:SaveRefreshRecordTime()
	self:RefreshTime()
end

-- 初始事件
function UIWarTempleFightList:InitEvents()
	self:SetWndClick(self.mBtnConfirm, function() self:OnClickBtnConfirm() end)
	self:SetWndClick(self.mReturnBtn, function() self:WndClose() end)
	self:SetWndClick(self.mMask, function() self:WndClose() end)

	self:WndEventRecv(EventNames.WARTEMPLE_CHALLENGE_LIST_RETURN, function(...) self:Refresh(...) end)
end

-- 刷新倒计时
function UIWarTempleFightList:RefreshTime()
	local leftTime = gModelWarTemple:GetLeftRefreshRecordTime()
	if leftTime > 0 then
		self:SetWndButtonText(self.mBtnConfirm, ccClientText(42071, leftTime))
	else
		self:SetWndButtonText(self.mBtnConfirm, ccClientText(42035))
	end
	self:SetWndButtonGray(self.mBtnConfirm, leftTime > 0)
end

-- 刷新界面
function UIWarTempleFightList:Refresh()
	local dataList = gModelWarTemple:GetChallengeList()
	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList

		uiList:Create(self.mList, dataList, function(...)
			self:OnDrawListItem(...)
		end, UIItemList.SUPER_GRID)
	else
		self._uiList:RefreshList(dataList)
		self._uiList:DrawAllItems()
	end

	CS.ShowObject(self.mNoRecord, #dataList == 0)
end

-- 点击挑战
function UIWarTempleFightList:OnClickBtnFight(itemData)
	local baseInfo = gModelWarTemple:GetBaseInfo()
	local leftTime = baseInfo.challengeCnt + baseInfo.freeChallengeCnt
	if leftTime <= 0 then
		if baseInfo.buyChallengeCnt <= 0 then
			GF.ShowMessage(ccClientText(42016))
			return
		end
		GF.OpenWnd("UIWarTempleBuyTimes")
		return
	end

	local targetId = itemData.npcId
	local monsterRefId = 0
	local playerId, otherLevel, otherName, otherPlayerHead
	if targetId == 0 then
		targetId = itemData.info.playerId
		playerId = targetId
		otherLevel = itemData.info.level
		otherName = itemData.info.name
		otherPlayerHead = itemData.info.head
	else
		monsterRefId = GameTable.BattleTempleDefendRef[targetId].monster
		if self:IsFastFight(monsterRefId, targetId) then
			return
		end
	end


	gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_WAR_TEMPLE, {
		wndType = 1,
		targetId = targetId,
		playerId = playerId,
		otherName = otherName,
		otherPlayerHead = otherPlayerHead,
		otherLevel = otherLevel,
		monsterRefId = monsterRefId,
		returnFunc = function()
			GF.OpenWnd("UIWarTemple")
			-- GF.OpenWnd("UIWarTempleFightList")
		end,
	})
end

-- 绘制列表item项
function UIWarTempleFightList:OnDrawListItem(list, item, itemData, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			txtResult  = CS.FindTrans(item, "AniRoot/Img0/TxtResult"),
			roleHead   = CS.FindTrans(item, "AniRoot/RoleHead"),
			btnFight   = CS.FindTrans(item, "AniRoot/BtnFight"),
			name       = CS.FindTrans(item, "AniRoot/Name"),
			headIcon   = CS.FindTrans(item, "AniRoot/HeadIcon"),
			itemNum1   = CS.FindTrans(item, "AniRoot/item/ItemNum1"),
			itemRoot1  = CS.FindTrans(item, "AniRoot/item/ItemNum1/ItemIcon"),
			itemNum2   = CS.FindTrans(item, "AniRoot/item/ItemNum2"),
			itemRoot2  = CS.FindTrans(item, "AniRoot/item/ItemNum2/ItemIcon"),
			prowerText = CS.FindTrans(item, "AniRoot/ProwerBg/ProwerText"),
		}

		--根据语言环境换下控件
		if self._isEnus then
			itemCache.txtResult= CS.FindTrans(item, "AniRoot/Img0_en/TxtResult_en")
			itemCache.itemNum1= CS.FindTrans(item, "AniRoot/item_en/ItemNum1")
			itemCache.itemRoot1= CS.FindTrans(item, "AniRoot/item_en/ItemNum1/ItemIcon")
			itemCache.itemNum2= CS.FindTrans(item, "AniRoot/item_en/ItemNum2")
			itemCache.itemRoot2= CS.FindTrans(item, "AniRoot/item_en/ItemNum2/ItemIcon")
		end
		self:SetComponentCache(instanceID, itemCache)
		self:SetWndButtonText(itemCache.btnFight, ccClientText(42034))

		itemCache.headIconClass = HeadIcon:New(self)


	end

	local strName
	local headData = {
		roleId = 0,
		trans = itemCache.headIcon,
	}

	local palace = itemData.palace
	local power = itemData.power
	if itemData.npcId == 0 then
		local roleInfo = itemData.info
		strName = roleInfo.name
		headData.roleId = roleInfo.playerId
		headData.icon = roleInfo.head
	else
		local ref = GameTable.BattleTempleDefendRef[itemData.npcId]
		local monsterRef = GameTable.MonsterFormationRef[ref.monster]
		palace = ref.PalacerId
		power = monsterRef.monsterPower
		local heroRefId, name = gModelWarTemple:GetShowHeroRefId(itemData.npcId)
		local head = gModelWarTemple:GetHeroHeadByRefId(heroRefId)
		strName = name
		headData.icon = head
	end
	local placeRef = GameTable.BattleTemplePalaceRef[palace]

	self:SetWndText(itemCache.prowerText, LUtil.NumberCoversion(power))
	self:SetWndText(itemCache.name, strName)
	self:SetWndText(itemCache.txtResult, ccClientText(42037, ccLngText(placeRef.name), itemData.rank))

	local itemList = gModelWarTemple:GetDailyRewardItem(palace, itemData.rank)
	self:CreateCommonIconImpl(itemCache.itemRoot1, itemList[1], { showNum = false, showBg = false })
	self:SetWndText(itemCache.itemNum1, ccClientText(42036, itemList[1].count))

	if itemList[2] then
		self:CreateCommonIconImpl(itemCache.itemRoot2, itemList[2], { showNum = false, showBg = false })
		self:SetWndText(itemCache.itemNum2, ccClientText(42036, itemList[2].count))
	end
	CS.ShowObject(itemCache.itemNum2, itemList[2] ~= nil)


	itemCache.headIconClass:SetHeadData(headData)
	self:SetWndClick(headData.trans, function(...)
		self:OnClickPlayer(headData.roleId)
	end)
	self:SetWndClick(itemCache.btnFight, function() self:OnClickBtnFight(itemData) end)

	if self.jpj then
		self:InitTextSizeWithLanguage(itemCache.itemNum1,-2)
		self:InitTextSizeWithLanguage(itemCache.itemNum2,-2)
		self:SetAnchorPos(itemCache.itemRoot1,Vector2.New(-23,-0))
		self:SetAnchorPos(itemCache.itemRoot2,Vector2.New(-23,-0))
	end
end

------------------------------------------------------------------
return UIWarTempleFightList