---
--- Created by wzz.
--- DateTime: 2024/5/9 22:04:54
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWarTempleReport:LWnd
local UIWarTempleReport = LxWndClass("UIWarTempleReport", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWarTempleReport:UIWarTempleReport()
	gModelWarTemple:WarTempleBattleRecordReq()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWarTempleReport:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWarTempleReport:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWarTempleReport:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitTexts()
	self:InitEvents()
	self:InitList()
	self:RefreshEmptyTips()

	self:Refresh()
end

function UIWarTempleReport:OnPlayEnd()
	GF.CloseWndByName("UIFight")
	GF.ChangeMap("LCityMap")

	GF.OpenWndBottom("UIWarTemple")
	GF.OpenWnd("UIWarTempleReport")
end

-- 初始界面化文本
function UIWarTempleReport:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(42028))
end

-- 初始事件
function UIWarTempleReport:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mReturnBtn, function() self:WndClose() end)

	self:WndEventRecv(EventNames.WARTEMPLE_REPORT_RETURN, function(...) self:Refresh(...) end)
end

-- 点击查看按钮
function UIWarTempleReport:OnClickBtnLook(reportUrl)
	local mapRes = gModelBattle:GetBattleMapRes({combatType = LCombatTypeConst.COMBAT_WAR_TEMPLE})

	local combatExtraDatas =
	{
		battleEndfun = function() self:OnPlayEnd()  end,
		canSkip = true,
		battleMapName =mapRes,
		videoType = LVideoTypeConst.NORMAL,
	}
	gLFightManager:OnPlayBattleVideo(reportUrl,combatExtraDatas)
	GF.CloseWndByName("UIWarTemple")
	self:WndClose()
end

-- 刷新空列表
function UIWarTempleReport:RefreshEmptyTips()
	local text = self.mEmptyText
	local emptyList = self:GetCommonEmptyList("_empty")
	local data =
	{
		refId= 37001,
		IntroTran= text,
		--TextBgTran,
		--IconTran,
		--GetBtn,
		--GetBtnText
		--ButtonRoot,
	}
	emptyList:RefreshUI(data)
end

-- 初始化列表
function UIWarTempleReport:InitList()
	local uiList = self:GetUIScroll("mList")
	self._uiList = uiList

	uiList:Create(self.mList, {}, function(...)
		self:OnDrawListItem(...)
	end, UIItemList.SUPER_GRID)
end

-- 绘制列表item项
function UIWarTempleReport:OnDrawListItem(list, item, itemData, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			txtResult  = CS.FindTrans(item, "AniRoot/TxtResult"),
			headIcon   = CS.FindTrans(item, "AniRoot/HeadIcon"),
			name       = CS.FindTrans(item, "AniRoot/Name"),
			tips       = CS.FindTrans(item, "AniRoot/Tips"),
			up         = CS.FindTrans(item, "AniRoot/Tips/Up"),
			down       = CS.FindTrans(item, "AniRoot/Tips/Down"),
			btnLook    = CS.FindTrans(item, "AniRoot/BtnLook"),
			prowerText = CS.FindTrans(item, "AniRoot/ProwerBg/ProwerText"),
		}

		itemCache.headIconClass = HeadIcon:New(self)

		self:SetComponentCache(instanceID, itemCache)
		self:SetTextTile(itemCache.btnLook, ccClientText(42032))
	end

	local roleInfo = itemData.roleInfo
	local strName = ""
	local power = itemData.power
	local headData = {
		roleId = 0,
		trans = itemCache.headIcon,
	}

	if itemData.npcId == 0 then
		headData.roleId = roleInfo.playerId
		headData.icon = roleInfo.head
		strName = roleInfo.name
	else

		local ref = GameTable.BattleTempleDefendRef[itemData.npcId]
		if not ref then
			return
		end
		local monsterRef = GameTable.MonsterFormationRef[ref.monster]
		power = monsterRef.monsterPower

		local heroRefId, name = gModelWarTemple:GetShowHeroRefId(itemData.npcId)
		local head = gModelWarTemple:GetHeroHeadByRefId(heroRefId)
		strName = name
		headData.icon = head
	end

	local strResult, rank = "", itemData.rankChange
	if itemData.battleResult == 1 then
		strResult = ccClientText(42029)
	elseif itemData.battleResult == 2 then
		strResult = ccClientText(42030)
		rank = -rank
	elseif itemData.battleResult == 3 then
		strResult = ccClientText(42047)
	else
		strResult = ccClientText(42048)
		rank = -rank
	end

	local strTips = ccClientText(42031)
	if rank == 0 then
		strTips = ccClientText(42049)
	elseif rank > 0 then
		self:SetTextTile(itemCache.up, "+" .. rank)
	else
		self:SetTextTile(itemCache.down, rank)
	end

	self:SetWndText(itemCache.txtResult, strResult)
	self:SetWndText(itemCache.name, strName)
	self:SetWndText(itemCache.tips, strTips)
	self:SetWndText(itemCache.prowerText, LUtil.NumberCoversion(power))
	CS.ShowObject(itemCache.up, rank > 0)
	CS.ShowObject(itemCache.down, rank < 0)

	itemCache.headIconClass.SetHeadData(itemCache.headIconClass, headData)
	self:SetWndClick(headData.trans, function (...)
		self:OnClickPlayer(headData.roleId)
	end)

	self:SetWndClick(itemCache.btnLook, function() self:OnClickBtnLook(itemData.reportUrl) end)

end

-- 刷新界面
function UIWarTempleReport:Refresh()
	local dataList = gModelWarTemple:GetRecordInfos()
	self._uiList:RefreshList(dataList)
	CS.ShowObject(self.mNoRecord, #dataList == 0)
end

-- 点击头像
function UIWarTempleReport:OnClickPlayer(playerId)
	if playerId == 0 then
		GF.ShowMessage(ccClientText(42040))
		return
	end
	gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_WAR_TEMPLE, LPlayerShowConst.OTHER_SYSTEM)
end

------------------------------------------------------------------
return UIWarTempleReport