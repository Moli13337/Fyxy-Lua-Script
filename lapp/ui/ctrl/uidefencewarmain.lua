---
--- Created by wzz.
--- DateTime: 2025/3/3 14:42:10
--- 保卫战主界面
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDefenceWarMain:LWnd
local UIDefenceWarMain = LxWndClass("UIDefenceWarMain", LWnd)
------------------------------------------------------------------
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")

local FuncIdEnum = {
	Main = 4, -- 主界面
	Hero = 3, -- 英雄列表
	Rank = 2, -- 排行榜
	Task = 1, -- 任务
}

-- 底部tab列表
local TabList = {
	[4] = { funcId = FuncIdEnum.Main, title = ccClientText(46812), icon = "MoeCity_icon_1" },
	[3] = { funcId = FuncIdEnum.Hero, title = ccClientText(46813), icon = "MoeCity_icon_2" },
	[2] = { funcId = FuncIdEnum.Rank, title = ccClientText(46814), icon = "MoeCity_icon_3" },
	[1] = { funcId = FuncIdEnum.Task, title = ccClientText(46815), icon = "MoeCity_icon_4" },
}


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDefenceWarMain:UIDefenceWarMain()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDefenceWarMain:OnWndClose()
	LUtil.ClearHashTable(self._heroMap)
	self._heroMap = nil

	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDefenceWarMain:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDefenceWarMain:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitTexts()
	self:InitEvents()
	self:InitTimer()
	self:InitTabList()
	self:InitRank()
	self:Refresh()
end

-- 获取排行榜奖励
function UIDefenceWarMain:GetRankAwardList()
	local activityData = gModelDefenceWar:GetActivityData()
	if not activityData then
		return {}
	end
	local sid = activityData.sid
	local _pages = self._pages

	local _rankRewardId = self._rankRewardId or 3
	local _rewardList = nil
	local page = _pages[_rankRewardId]
	if page then
		_rewardList = LxDataHelper.SevenParseRewardList(sid, page)
	end
	return _rewardList
end

-- 刷新tab列表
function UIDefenceWarMain:RefreshTabList()
	local uiTabList = self:GetUIScroll("mTabScroll")
	uiTabList:ResetList(TabList)
end

-- 初始化数据
function UIDefenceWarMain:InitData()
	self._curFuncId = self:GetWndArg("FuncId") or FuncIdEnum.Main
	self._curStageId = self:GetWndArg("StageId") or gModelDefenceWar:GetCurStageId()

	local activityData = gModelDefenceWar:GetActivityData()

	local sid = activityData.sid
	gModelActivity:OnActivityPageReq(sid)
end

function UIDefenceWarMain:InitRank()
	local activityWebData = gModelDefenceWar:GetWebActivityData()
	local config = activityWebData.config

	local rankIds = string.split(config.rankId, "=")
	local rankId = tonumber(rankIds[1])
	local rankRewardId = tonumber(rankIds[2])

	self._rankId = rankId
	self._rankRewardId = rankRewardId

	gModelRank:OnRankReq(2, rankId, 1, 3, activityWebData.sid)

	self:InitRankBaseInfo()
end

-- 底部列表 item
function UIDefenceWarMain:OnDrawTabItem(list, item, itemdata, itempos)
	local funcId = itemdata.funcId
	local tab = self._uiTabItemList[funcId]
	if not tab then
		tab = {}
		tab.item = item
		self._uiTabItemList[funcId] = tab
	end
	self:SetWndTabText(tab.item, itemdata.title)
	self:SetWndTabIcon(tab.item, itemdata.icon)
	self:SetWndClick(tab.item, function() self:OnClickTab(funcId) end)

	self:SetWndTabStatus(tab.item, self._curFuncId == funcId and LWnd.StateOn or LWnd.StateOff, itempos)

	self:UpdateTabRed(funcId)
end

-- 点击战斗
function UIDefenceWarMain:OnClickBtnFight()
	-- gModelDefenceWar:EnterMap(self._curStageId)

	self._lastClickTime = self._lastClickTime or 0
	if os.clock() - self._lastClickTime < 0.5 then
		return
	end
	self._lastClickTime = os.clock()
	gModelDefenceWar:ProtectCityBattleReq(self._curStageId)
end

-- 刷新英雄列表
function UIDefenceWarMain:RefreshHero()
	local dataList = gModelDefenceWar:GetHeroDataList(true)

	if not self._uiList then
		local uiList = self:GetUIScroll("mHeroList")
		self._uiList = uiList

		uiList:Create(self.mHeroList, dataList, function(...)
			self:OnDrawHeroCard(...)
		end, UIItemList.SUPER_GRID, true)
	else
		self._uiList:RefreshData(dataList, true)
		self._uiList:DrawAllItems()
	end
	self:RefreshCoreHp()
end

-- 刷新tab红点
function UIDefenceWarMain:UpdateTabRed(funcId)
	local list = {}
	if not funcId then
		list = { FuncIdEnum.Task, FuncIdEnum.Hero }
	else
		list = { funcId }
	end
	for _, id in ipairs(list) do
		if self._uiTabItemList[id] then
			local showRed = false
			if id == FuncIdEnum.Hero then
				showRed = gModelDefenceWar:HasHeroCanUp()
			elseif id == FuncIdEnum.Task then
				local activityData = gModelDefenceWar:GetActivityData()
				if activityData then
					showRed = gModelRedPoint:GetActivityRedPointPage(activityData.sid, 2)
				end
			end
			self:SetRed(self._uiTabItemList[id].item, showRed)
		end
	end
end

-- 点击右边

function UIDefenceWarMain:OnClickBtnRight()
	local passMax = gModelDefenceWar:GetPassMaxStageId()
	if self._curStageId + 1 > passMax + 1 then
		GF.ShowMessage(ccClientText(46820))
		return
	end
	self._curStageId = self._curStageId + 1

	local maxRefId = gModelDefenceWar:GetMaxStageId()
	if self._curStageId > maxRefId then
		self._curStageId = maxRefId
	end
	self:Refresh()
end

-- 奖励列表 item
function UIDefenceWarMain:OnDrawAwardItem(uilist, root, data)
	if not uilist then
		uilist = {}
		uilist.itemRoot = CS.FindTrans(root, "ItemRoot")
		uilist.mask = CS.FindTrans(root, "Mask")
	end
	CS.ShowObject(uilist.mask, self._hadPass)

	self:CreateCommonIconImpl(uilist.itemRoot, data, { showNum = true })
	return uilist
end

-- 刷新界面
function UIDefenceWarMain:Refresh()
	self:RefreshTabList()

	CS.ShowObject(self.mMain, self._curFuncId == FuncIdEnum.Main)
	CS.ShowObject(self.mHero, self._curFuncId == FuncIdEnum.Hero)

	if self._curFuncId == FuncIdEnum.Main then
		self:RefreshMain()
	elseif self._curFuncId == FuncIdEnum.Hero then
		self:RefreshHero()
	end

	CS.ShowObject(self.mBg2, self._curFuncId == FuncIdEnum.Hero)

	self:RefreshActivity()
	self:UpdateTabRed()
end

-- 初始化底部列表
function UIDefenceWarMain:InitTabList()
	self._uiTabItemList = {}
	local uiTabList = self:GetUIScroll("mTabScroll")
	uiTabList:Create(self.mTabScroll, TabList, function(...) self:OnDrawTabItem(...) end)
end

-- 刷新核心生命
function UIDefenceWarMain:RefreshCoreHp()
	local hpMax = gModelDefenceWar:GetCoreMaxHp()
	self:SetWndText(self.mTxtHp, ccClientText(46821, hpMax))
end

-- 点击帮助
function UIDefenceWarMain:OnClickBtnHelp()
	local activityData = gModelDefenceWar:GetActivityData()
	if not activityData then
		return
	end

	local activityWebData = gModelActivity:GetWebActivityDataById(activityData.sid)
	if not activityWebData then
		return
	end

	local config = activityWebData.config
	local strTips = config.roguelikeHelpText
	if string.isempty(strTips) then
		return
	end

	GF.OpenWnd("UIBzTips", { title = config.roguelikeName, text = strTips })
end

-- 点击tab
function UIDefenceWarMain:OnClickTab(funcId)
	if funcId == self._curFuncId then
		return
	end

	if funcId == FuncIdEnum.Rank then
		local activityData = gModelDefenceWar:GetActivityData()
		if not activityData then
			return
		end
		local sid = activityData.sid

		local param = {}
		param.sid = sid
		param.refId = self._rankId
		param.rewardList = self:GetRankAwardList()
		param.rankBaseInfo = self._rankBaseInfo
		param.rankRewardId = self._rankRewardId
		GF.OpenWndBottom("UIRkPop", param)
		return
	elseif funcId == FuncIdEnum.Task then
		local activityData = gModelDefenceWar:GetActivityData()
		if not activityData then
			return
		end
		local activityWebData = gModelDefenceWar:GetWebActivityData()
		if not activityWebData then
			return
		end

		GF.OpenWndBottom("UIFairylandTask", {
			sid = activityData.sid,
			data = activityWebData.config,
			mainData = activityData,
			pageId = 2,
			pageAccumulateId = 2,
			closeFunc = function()

			end
		})
		return
	end

	self._curFuncId = funcId
	self:Refresh()
end

-- 点击英雄卡片
function UIDefenceWarMain:OnClickHeroCard(heroId, lev)
	if lev == 0 and gModelDefenceWar:HeroCanUp(heroId, false) then
		gModelDefenceWar:ProtectCityUpLevelHeroReq(heroId, 1)
		return
	end

	GF.OpenWnd("UIDefenceWarHeroUp", { heroId = heroId })
end

function UIDefenceWarMain:InitRankBaseInfo()
	if self._rankBaseInfo then
		return
	end

	local activityWebData = gModelDefenceWar:GetWebActivityData()
	local config = activityWebData.config
	local limitRank_temp = config.rankLimit

	if string.isempty(limitRank_temp) then
		return
	end

	limitRank_temp = string.split(limitRank_temp, "|")
	local limitRankText = config.rankTxt
	self._rankBaseInfo = {}
	for k, v in ipairs(limitRank_temp) do
		local temp = string.split(v, "=")
		local score = tonumber(temp[2])
		local lev = math.floor(score / 1000)
		local progress = score - lev * 1000
		self._rankBaseInfo[checknumber(temp[1])] = {}
		self._rankBaseInfo[checknumber(temp[1])].score = score
		self._rankBaseInfo[checknumber(temp[1])].notEnoughDes = string.replace(limitRankText, lev, progress)
	end
end

-- 刷新活动
function UIDefenceWarMain:RefreshActivity()
	local activityData = gModelDefenceWar:GetActivityData()
	if not activityData then
		return
	end

	local activityWebData = gModelDefenceWar:GetWebActivityData()
	if not activityWebData then
		return
	end

	local config = activityWebData.config
	self:SetWndText(self.mTxtTitle, ccLngText(config.roguelikeName))

	local strTips = config.roguelikeHelpText
	local isEmpty = string.isempty(strTips)
	CS.ShowObject(self.mBtnHelp, not isEmpty)

	self:RefreshTimes()
end

-- 刷新主界面
function UIDefenceWarMain:RefreshMain()
	local refId     = self._curStageId
	local stageRef  = gModelDefenceWar:GetStageRef(refId)
	local passRefId = gModelDefenceWar:GetPassMaxStageId()
	local minRefId  = 1
	local maxRefId  = gModelDefenceWar:GetMaxStageId()
	self._hadPass   = refId <= passRefId

	self:SetWndText(self.mTxtLevel, ccLngText(stageRef.name))

	self._heroMap = self._heroMap or {}
	local paint = stageRef.paint
	local heroObj = self._heroMap[paint]
	if not heroObj then
		heroObj = LUIHeroObject:New(self)
		self._heroMap[paint] = heroObj

		heroObj:Create(self.mMainIcon, paint, paint)
		heroObj:StartLoad()
	end
	for k, heroObj in pairs(self._heroMap) do
		heroObj:ShowHero(k == paint)
	end

	-- self:CreateWndSpine(self.mMainIcon, stageRef.paint, stageRef.paint, false, function(dpSpine)
	-- end)

	-- 奖励
	local itemList = LUtil.GetRefItemDataList(stageRef.reward1)
	self:SetComList(self.mAwardList, itemList, function(...) return self:OnDrawAwardItem(...) end)

	CS.ShowObject(self.mBtnLeft, refId ~= minRefId)
	CS.ShowObject(self.mBtnRight, refId ~= maxRefId)

	-- 消耗
	local costItemId = gModelDefenceWar:GetCostItemData()
	if costItemId then
		local iconPath = gModelItem:GetItemImgByRefId(costItemId)
		self:SetWndEasyImage(self.mCostIcon1, iconPath)
		self:SetWndText(self.mCostValue1, stageRef.num)
	end

	self:RefreshTopAsset()
end

-- Update
function UIDefenceWarMain:Update()
	self:RefreshTimes()
end

-- 初始事件
function UIDefenceWarMain:InitEvents()
	self:SetWndClick(self.mCloseBtn, function() self:WndClose() end)
	self:SetWndClick(self.mBtnHelp, function() self:OnClickBtnHelp() end)
	self:SetWndClick(self.mBtnFight, function() self:OnClickBtnFight() end)
	self:SetWndClick(self.mBtnFormation, function() self:OnClickBtnFormation() end)
	self:SetWndClick(self.mBtnFormation2, function() self:OnClickBtnFormation() end)
	self:SetWndClick(self.mBtnLeft, function() self:OnClickBtnLeft() end)
	self:SetWndClick(self.mBtnRight, function() self:OnClickBtnRight() end)
	self:SetWndClick(self.mBtnMonster, function() self:OnClickBtnMonster() end)
	self:SetWndClick(self.mBtnAward, function() self:OnClickBtnAward() end)
	self:SetWndClick(self.mAssetItem, function() GF.OpenWnd("UIDefenceWarGift") end)



	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		local activityData = gModelDefenceWar:GetActivityData()

		local sid = pb.sid
		if activityData and activityData.sid == sid then
			self:ResetData(pb)
		end
	end)

	self:WndEventRecv(EventNames.DEFENCEWAR_BASE_INFO, function() self:Refresh() end)
	self:WndEventRecv(EventNames.On_Item_Change, function() self:Refresh() end)
	self:WndEventRecv(EventNames.DEFENCEWAR_FORMATION_CHANGE, function() self:RefreshCoreHp() end)
	self:WndEventRecv(EventNames.ON_ACT_PAGE_RED_CHANGE, function() self:UpdateTabRed() end)
end

-- 初始时间
function UIDefenceWarMain:InitTimer()
	local timePara = {
		key = 1,
		loopcnt = -1,
		interval = 1,
		timescale = false,
		func = function()
			self:RefreshTimes()
		end
	}
	self:TimerStartImpl(timePara)
end

-- 刷新倒计时
function UIDefenceWarMain:RefreshTimes()
	local activityData = gModelDefenceWar:GetActivityData()
	if not activityData then
		return
	end

	local endTime = activityData.endTime
	local curTime = GetTimestamp()
	local leftTime = endTime - curTime
	local strTime = ""
	if leftTime > 0 then
		strTime = ccClientText(46839, LUtil.FormatTimespanCn(leftTime))
	end

	self:SetWndText(self.mTxtTime, strTime)

	local costItemId, maxNum = gModelDefenceWar:GetCostItemData()
	local hasNum = gModelItem:GetNumByRefId(costItemId)
	if hasNum < maxNum then
		leftTime = gModelDefenceWar:GetNextRecoverTime() - curTime

		if leftTime <= 0 then
			if self._sendMsgTimer and self._sendMsgTimer < os.time() then
				self._sendMsgTimer = os.time() + 3
				gModelDefenceWar:ProtectCityInfoReq()
			else
				if not self._sendMsgTimer then
					self._sendMsgTimer = os.time() + 3
					gModelDefenceWar:ProtectCityInfoReq()
				end
			end
			leftTime = 0
		end
	else
		leftTime = 0
	end

	strTime = ""
	if leftTime > 0 then
		strTime = LUtil.FormatTimespanNumber(leftTime)
	end
	self:SetWndText(self.mTxtTime2, strTime)
end

-- 初始界面化文本
function UIDefenceWarMain:InitTexts()
	self:SetWndText(self.mTxtClose, ccClientText(42010))
	self:SetWndText(self.mTxtAwardTips, ccClientText(46817))
	self:SetTextTile(self.mBtnFormation, ccClientText(46816))
	self:SetTextTile(self.mBtnFormation2, ccClientText(46816))
	self:SetTextTile(self.mBtnAward, ccClientText(46818))
	self:SetTextTile(self.mBtnMonster, ccClientText(46819))
	self:SetTextTile(self.mBtnFight, ccClientText(46840))
end

-- 点击左边
function UIDefenceWarMain:OnClickBtnLeft()
	self._curStageId = self._curStageId - 1
	if self._curStageId < 1 then
		self._curStageId = 1
	end
	self:Refresh()
end

-- 顶部资产
function UIDefenceWarMain:RefreshTopAsset()
	local costItemId, maxNum = gModelDefenceWar:GetCostItemData()
	if not costItemId then
		return
	end
	local assetIdList = { costItemId }
	local maxMap = {
		[costItemId] = maxNum
	}

	local iconPath = gModelItem:GetItemImgByRefId(costItemId)
	self:SetWndEasyImage(self.mCostIcon1, iconPath)

	self:SetTopAssetList(self.mTopAsset, assetIdList, maxMap)
end

-- 点击关卡列表
function UIDefenceWarMain:OnClickBtnMonster()
	GF.OpenWnd("UIDefenceWarStageList")
end

--
function UIDefenceWarMain:ResetData(pb)
	local _pages = self._pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		local pageId = page.pageId
		_pages[pageId] = page
	end
	self._pages = _pages
end

-- 点击奖励
function UIDefenceWarMain:OnClickBtnAward()
	GF.OpenWnd("UIDefenceWarAwardList")
end

-- 点击布阵
function UIDefenceWarMain:OnClickBtnFormation()
	GF.OpenWnd("UIDefenceWarFormation")
end

-- 卡片item
function UIDefenceWarMain:OnDrawHeroCard(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			card     = CS.FindTrans(item, "AniRoot/DefenceWarCard"),
			txtLev   = CS.FindTrans(item, "AniRoot/TxtLev"),
			mask     = CS.FindTrans(item, "AniRoot/Mask"),
			txtName  = CS.FindTrans(item, "AniRoot/Img0/TxtName"),
			txtMask  = CS.FindTrans(item, "AniRoot/Mask/1/UIText"),
			txtCost  = CS.FindTrans(item, "AniRoot/Mask/TxtCost"),
			costIcon = CS.FindTrans(item, "AniRoot/Mask/TxtCost/CostIcon"),
			canUp    = CS.FindTrans(item, "AniRoot/CanUp"),
		}
		self:SetWndText(itemCache.txtMask, ccClientText(46838))
		self:SetTextTile(itemCache.canUp, ccClientText(46846))
		self:SetComponentCache(instanceID, itemCache)
	end

	local lev = itemdata.lev
	local ref = itemdata.ref

	local heroId = ref.heroId
	local color = gModelItem:GetColorStringByQualityId(ref.quality)
	local strName = ccClientText(46842, color, ccLngText(ref.name))
	local strLv = lev > 0 and lev or ""

	CS.ShowObject(itemCache.mask, lev == 0)
	if lev == 0 then
		local heroLevRef = gModelDefenceWar:GetHeroLevRef(heroId, lev)
		local itemList   = LUtil.GetRefItemDataList(heroLevRef.upNeed)
		local data       = itemList[1]
		local strNum     = ""
		local needNum    = data.itemNum
		local haveNum    = gModelItem:GetNumByRefId(data.itemId)
		if needNum > haveNum then
			strNum = LUtil.FormatColorStr(haveNum, "lightRed") .. "/" .. needNum
		else
			strNum = LUtil.FormatColorStr(haveNum, "#6bfa24") .. "/" .. needNum
		end
		self:SetWndText(itemCache.txtCost, strNum)

		local iconPath = gModelItem:GetItemImgByRefId(data.itemId)
		self:SetWndEasyImage(itemCache.costIcon, iconPath)
	end

	self:SetWndText(itemCache.txtLev, strLv)
	self:SetWndText(itemCache.txtName, strName)

	gModelDefenceWar:DrawCard(self, itemCache.card, { heroId = heroId, lev = lev })
	self:SetWndClick(itemCache.card, function() self:OnClickHeroCard(heroId, lev) end)

	local canUp = gModelDefenceWar:HeroCanUp(heroId, false) and lev > 0
	CS.ShowObject(itemCache.canUp, canUp)
end

------------------------------------------------------------------
return UIDefenceWarMain