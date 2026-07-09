---
--- Created by wzz.
--- DateTime: 2024/5/14 14:10:31
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWarTempleShowList:LWnd
local UIWarTempleShowList = LxWndClass("UIWarTempleShowList", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWarTempleShowList:UIWarTempleShowList()
	self.noNeedRegisterRed = true
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWarTempleShowList:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWarTempleShowList:OnCreate()
	local refId = self:GetWndArg("refId")
	self._ref = GameTable.BattleTemplePalaceRef[refId]
	self:WndEventRecv(EventNames.WARTEMPLE_SHOW_LIST_RETURN, function(...) self:OnReturnShowList(...) end)
	gModelWarTemple:WarTempleShowReq(refId)

	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWarTempleShowList:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()
	
	self._initUI = true

	self:InitTexts()
	self:InitEvents()

	self:Refresh()
end

-- 展示列表，数据返回
function UIWarTempleShowList:OnReturnShowList(data)
	self._dataList = data
	if self._initUI then
		self:Refresh()
	end
end

-- 点击确认
function UIWarTempleShowList:OnClickBtnConfirm()
	if gModelRank:IsLikeLimit(self._ref.like, true) then
		return
	end
	local playerId = gModelPlayer:GetPlayerId()
	gModelRank:OnPlayerLikeReq(playerId, self._ref.like)
end

-- 绘制列表item项
function UIWarTempleShowList:OnDrawListItem(list, item, itemData, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			txtResult  = CS.FindTrans(item, "AniRoot/Img0/TxtResult"),
			roleHead   = CS.FindTrans(item, "AniRoot/RoleHead"),
			-- btnFight   = CS.FindTrans(item, "AniRoot/BtnFight"),
			name       = CS.FindTrans(item, "AniRoot/Name"),
			headIcon   = CS.FindTrans(item, "AniRoot/HeadIcon"),
			itemNum1   = CS.FindTrans(item, "AniRoot/item/ItemNum1"),
			itemRoot1  = CS.FindTrans(item, "AniRoot/item/ItemNum1/ItemIcon"),
			itemNum2   = CS.FindTrans(item, "AniRoot/item/ItemNum2"),
			itemRoot2  = CS.FindTrans(item, "AniRoot/item/ItemNum2/ItemIcon"),
			prowerText = CS.FindTrans(item, "AniRoot/ProwerBg/ProwerText"),
		}
		self:SetComponentCache(instanceID, itemCache)
		-- self:SetWndButtonText(itemCache.btnFight, ccClientText(42034))

		--根据语言环境换下控件
		if self._isEnus then
			itemCache.txtResult= CS.FindTrans(item, "AniRoot/Img0_en/TxtResult_en")
			itemCache.itemNum1= CS.FindTrans(item, "AniRoot/item_en/ItemNum1")
			itemCache.itemRoot1= CS.FindTrans(item, "AniRoot/item_en/ItemNum1/ItemIcon")
			itemCache.itemNum2= CS.FindTrans(item, "AniRoot/item_en/ItemNum2")
			itemCache.itemRoot2= CS.FindTrans(item, "AniRoot/item_en/ItemNum2/ItemIcon")
		end

		itemCache.headIconClass = HeadIcon:New(self)

		if gLGameLanguage:IsJapanVersion() then
			self:InitTextSizeWithLanguage(itemCache.itemNum1,-2)
			self:InitTextSizeWithLanguage(itemCache.itemNum2,-2)
		end
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


	itemCache.headIconClass.SetHeadData(itemCache.headIconClass, headData)
	self:SetWndClick(headData.trans, function(...)
		self:OnClickPlayer(headData.roleId)
	end)
	-- self:SetWndClick(itemCache.btnFight, function() self:OnClickBtnFight(itemData) end)
end

-- 初始界面化文本
function UIWarTempleShowList:InitTexts()
	local ref = self._ref
	self:SetWndText(self.mTitle, ccLngText(ref.name))
	self:SetWndButtonText(self.mBtnConfirm, ccClientText(42060))

	CS.ShowObject(self.mBtnConfirm, ref.like > 0)

	local initH = self.mListRoot.rect.height
	local h = initH - 55
	if ref.like == 0 then
		h = initH
	end
	LxUiHelper.SetSizeWithCurAnchor(self.mListRoot, 1, h)
end

-- 刷新界面
function UIWarTempleShowList:Refresh()
	if not self._dataList then
		return
	end

	local dataList = self._dataList
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
	self:RefreshBtn()
end

-- 点击挑战
function UIWarTempleShowList:OnClickBtnFight(itemData)
	local targetId = itemData.npcId
	local monsterRefId = 0
	if targetId == 0 then
		targetId = itemData.info.roleId
	else
		monsterRefId = GameTable.BattleTempleDefendRef[targetId].monster
	end

	gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_WAR_TEMPLE, {
		wndType = 2,
		targetId = targetId,
		monsterRefId = monsterRefId,
	})
end

-- 点击头像
function UIWarTempleShowList:OnClickPlayer(playerId)
	if playerId == 0 then
		GF.ShowMessage(ccClientText(42040))
		return
	end
	gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_WAR_TEMPLE, LPlayerShowConst.OTHER_SYSTEM)
end

-- 初始事件
function UIWarTempleShowList:InitEvents()
	self:SetWndClick(self.mBtnConfirm, function() self:OnClickBtnConfirm() end)
	self:SetWndClick(self.mReturnBtn, function() self:WndClose() end)
	self:SetWndClick(self.mMask, function() self:WndClose() end)

	self:WndEventRecv(EventNames.ON_LIKE_RETURN, function(...) self:RefreshBtn(...) end)
end

-- 刷新按钮
function UIWarTempleShowList:RefreshBtn()
	if self._ref.like > 0 then
		local limit = gModelRank:IsLikeLimit(self._ref.like, false)
		self:SetRed(self.mBtnConfirm, not limit)
		self:SetWndButtonGray(self.mBtnConfirm, limit)
	end
end

------------------------------------------------------------------
return UIWarTempleShowList