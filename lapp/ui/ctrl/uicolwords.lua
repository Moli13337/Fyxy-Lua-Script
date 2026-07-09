--- 模板94 集字活动
--- Created by Ease.
--- DateTime: 2023/10/7 23:34:22
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIColWords:LWnd
local UIColWords = LxWndClass("UIColWords", LWnd)
UIColWords.CollectionPage = 1
UIColWords.ExchangePage = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIColWords:UIColWords()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIColWords:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIColWords:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIColWords:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitBtnEvent()
	self:InitEvent()
	self:InitMessage()
	self:InitData()
end

function UIColWords:SetBotList()
	local list = self._pageList
	local uiList = self._uiList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mBotBtnScroll")
		self._uiList = uiList
		uiList:Create(self.mTabScroll, list, function(...)
			self:OnBotList(...)
		end)
		self._uiList:EnableScroll(#list > 4, true)
	end
end

function UIColWords:InitData()
	self._sid = nil
	self._uiList = nil
	self._activityWebData = {}
	self.activityData = {}
	self._pageList = {}
	self._page = self:GetWndArg("page")
	self._pageId = self:GetWndArg("pageId")
	self._entryId = self:GetWndArg("entryId")
	self._sid = self:GetWndArg("sid")
	local subpage = self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end
	--self:CreateChildWnd(self.mChildRoot, "UISubCollectionCollection",{sid = self._sid})
	gModelActivity:ReqActivityConfigData(self._sid)

	self:SetWndText(self:FindWndTrans(self.mCloseBtn, "TxtClose"), ccClientText(30205))
end

function UIColWords:SetPageList(pb)
	self._pageList = {}
	local pbDataList = self._pbDataList or {}
	for i, v in ipairs(pb.pages) do
		local page = {}
		page = gModelActivity:GenerateActivePageDataFromPb(v)
		local isIns = false
		for k, j in pairs(pbDataList) do
			if (page.pageId == j.pageId) then
				pbDataList[k] = page
				isIns = true
			end
		end
		if not isIns then
			table.insert(pbDataList, page)
		end
	end
	self._pbDataList = pbDataList
	self:SetCfgPageList()
	self:SetBotList()
end

function UIColWords:InitBtnEvent()
	--返回按钮
	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UIColWords:InitEvent()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(data, sid)
		if sid ~= self._sid then
			return
		end
		self:OnActivityConfigData()
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
end

function UIColWords:InitNeedItem()
	if self.needList then
		self.needList:RefreshData(self.needItemList)
	else
		self.needList = self:GetUIScroll("uiNeedList")
		self.needList:Create(self.mNeedItemList, self.needItemList, function(...) self:OnDrawNeedItemCell(...) end)
	end
end
function UIColWords:ChackItemIsLack(expendArr)
	for i, v in pairs(expendArr) do
		local needArr = string.split(v, "=")
		local needId = needArr[2]
		local needCnt = needArr[3]
		local hadCnt = gModelItem:GetNumByRefId(tonumber(needId))
		if(tonumber(hadCnt) < tonumber(needCnt))then
			return true
		end
	end
end
function UIColWords:CheckRP(pageId)
	local cfgEntryList =  self._cfgEntryList
	if not cfgEntryList then return false end
	local pageCfgEntryList = cfgEntryList[pageId]
	if not pageCfgEntryList then return false end
	local pbDataList = self._pbDataList
	if not pbDataList then return false end
	local pagePdDataList = pbDataList[pageId]
	if not pagePdDataList then return false end
	local entries = pageCfgEntryList.entries or {}
	local pbEntry = pagePdDataList.entry or {}
	for i, v in pairs(entries) do
		local moreInfoArr = string.split(v.moreInfo,"|")
		local lvLimitArr = string.split(moreInfoArr[1], ",")
		local playerLV = gModelPlayer:GetPlayerLv()
		local isDisplay = true
		if(lvLimitArr and lvLimitArr[1] and lvLimitArr[2])then
			isDisplay = lvLimitArr and playerLV >= tonumber(lvLimitArr[1]) and playerLV <= tonumber(lvLimitArr[2])
		end
		local pbEntryData = pbEntry[i]
		local marketData = pbEntryData.MarketData
		local exCnt = marketData.personal
		local totalExCnt = marketData.personalGoal
		local needArr = string.split(v.expend2, ",")
		local isLack = self:ChackItemIsLack(needArr)
		local canBuy = totalExCnt - exCnt ~= 0 or totalExCnt == -1
		if(canBuy and not isLack and isDisplay)then
			return true
		end
	end
end

function UIColWords:OnDrawNeedItemCell(_, item, data)
	local IconTrans = self:FindWndTrans(item, "Icon")
	local NumTrans = self:FindWndTrans(item, "Num")
	local AddBtnTrans = self:FindWndTrans(item, "BtnDiv/AddBtn")
	local typeIcon = self:FindWndTrans(item, "TypeIcon")
	local refId = data.itemId
	if IconTrans then
		local icon = gModelItem:GetItemIconByRefId(refId)
		self:SetWndEasyImage(IconTrans, icon)
	end
	local itemRef = GameTable.PlayerItemRef[refId]
	if itemRef and not string.isempty(itemRef.race) then
		self:SetWndEasyImage(typeIcon, itemRef.race)
		CS.ShowObject(typeIcon, true)
	end
	if NumTrans then
		local haveNum = gModelItem:GetNumByRefId(refId)
		haveNum = LUtil.NumberCoversion(haveNum)
		self:SetWndText(NumTrans, haveNum)
	end
	if AddBtnTrans then
		self:SetWndClick(AddBtnTrans, function()
			gModelGeneral:OpenGetWayWnd({ itemId = refId, srcWnd = self:GetWndName() })
		end)
	end
end

function UIColWords:SetCfgPageList()
	self._pageList = {}
	local cfg = self._cfgData
	local menuSwitch = cfg.heroCollectBtn
	local menuArr = string.split(menuSwitch, "|")
	for i, v in pairs(menuArr) do
		self:SetPageDataByType(i, v)
	end
end

--设置选中底部按钮状态
function UIColWords:SetSeleBtn()
	if (not self._btnList or #self._btnList == 0) then
		return
	end
	for i, v in ipairs(self._btnList) do
		-- local seleBg = self:FindWndTrans(v.obj, "SelBg")
		-- local icon = self:FindWndTrans(v.obj, "Icon")
		-- self:SetWndEasyImage(icon, v.itemData.seleIcon)
		-- local pId = self._pageId
		-- local iconPath = v.itemData.pageId == pId and v.itemData.seleIcon or v.itemData.noSeleIcon
		-- self:SetWndEasyImage(icon, iconPath)
		-- CS.ShowObject(seleBg, v.itemData.pageId == pId)
		self:SetWndTabStatus(v.obj, v.itemData.pageId == self._pageId and 0 or 1)
	end
end

function UIColWords:SetPageDataByType(index,menuData)
	local data = {}
	local menuDataArr = string.split(menuData, "=")
	data.entryId = self._entryId
	data.id = tonumber(menuDataArr[1])
	data.wndName = data.id == UIColWords.CollectionPage and "UISubCollectionCollection" or "UISubCollectionExcGje"
	local pbData = self._pbDataList[data.id]
	data.seleIcon = menuDataArr[2]
	data.noSeleIcon = menuDataArr[3]
	data.name = menuDataArr[4]
	data.activityWebData = self._activityWebData
	data.pbData = pbData
	data.pageId = data.id
	data.func = function()
		self._pageId = data.id
		self:SetSeleBtn()
	end
	self._pageList = self._pageList and self._pageList or {}
	table.insert(self._pageList,data)
end

function UIColWords:OnBotList(list, item, itemdata, itempos)
	-- local nameTxt = self:FindWndTrans(item, "NameTxt")
	local rpTrans = self:FindWndTrans(item, "redPoint")
	self._btnList = self._btnList and self._btnList or {}
	self._btnList[itempos] = { itemData = itemdata, obj = item }
	local iconName = itemdata.name
	local isRed
	--if(itemdata.pageId == UIColWords.ExchangePage)then
	--	isRed = self:CheckRP(itemdata.pageId)
	--end
	isRed = self:CheckRP(itemdata.pageId)
	-----------定位红点页签 弃用
	--if(not self._pageId and isRed)then
	--	self._pageId = itemdata.pageId
	--end
	-------------------
	if itemdata.seleIcon then
		local On = self:FindWndTrans(item,"On")
		self:SetWndEasyImage(On,itemdata.seleIcon)
	end
	if itemdata.noSeleIcon then
		local Off = self:FindWndTrans(item,"Off")
		local Gray = self:FindWndTrans(item,"Gray")
		self:SetWndEasyImage(Off,itemdata.noSeleIcon)
		self:SetWndEasyImage(Gray,itemdata.noSeleIcon)
	end
	CS.ShowObject(rpTrans,isRed)
	-- self:SetWndText(nameTxt, iconName)
	self:SetWndTabText(item, iconName)
	self:SetWndClick(item, function()
		self:OnClickBotBtn(itempos,true)
	end)
end

function UIColWords:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		self:OnActivityPageResp(pb)    --分页数据返回
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityMarkeyBuyResp,function (pb)
		--self:SetBotList()
		--if(self._sid)then
		--	gModelActivity:OnActivityPageReq(self._sid)
		--end

		self:InitNeedItem()
	end)
	self:WndNetMsgRecv(LProtoIds.ItemChangeResp,function (pb)
		self:SetBotList()
	end)
end

function UIColWords:OnWndRefresh()
	self._page = self:GetWndArg("page") or self._page
	local subpage = self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
		gModelActivity:ReqActivityConfigData(self._sid)
		--self:OnClickBotBtn(page)
	end
end

function UIColWords:OnClickBotBtn(btnIndx,isClick)
	if(self._page)then
		btnIndx = self._page
	end
	local pageData = self._pageList[btnIndx or 1]
	if(isClick and self._pageId == pageData.pageId)then
		return
	end
	if (pageData) then
		if (self._pageId ~= btnIndx) then
			self:CloseAllChild()
			self._pageId = btnIndx
		end
		pageData.func()
		local entryId = pageData.entryId or nil
		self:CreateChildWnd(self.mChildRoot, pageData.wndName, {
			sid = self._sid,
			activityWebData = pageData.activityWebData,
			pbData = pageData.pbData,
			endTime = self._activityEndTime,
			showEndTime = self._activityShowEndTime,
			entryId = entryId,
			pageId = pageData.pageId,
			showBg = not self._showBg
		})
		self._entryId = nil
	end
	self._page = nil
end
function UIColWords:OnActivityPageResp(pb)
	local sid = pb.sid
	if sid ~= self._sid then
		return
	end
	self:SetPageList(pb)
	local btnIndex = 1
	if(self._pageId)then
		for i, v in pairs(self._pageList) do
			if(v.pageId == self._pageId)then
				btnIndex = i
			end
		end
	end
	self:OnClickBotBtn(btnIndex)
end

function UIColWords:OnActivityConfigData()
	local activityWebData = gModelActivity:GetWebActivityDataById(self._sid)
	self._activityWebData = activityWebData
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	self._activityData = activityData
	self._cfgData = activityWebData.config --main表
	self._cfgEntryList = activityWebData.chunk --条目表
	self._activityEndTime = activityData.endTime or 0
	self._activityShowEndTime = activityData.showEndTime or 0
	self.startTime = activityData.startTime

	if activityWebData then
		local config = activityWebData.config--配置表
		self:SetWndEasyImage(self.mMask,config.image)

		local dropInfo = string.split(config.dropItemId, "|")
		self.needItemList = {}
		for _, v in ipairs(dropInfo) do
			table.insert(self.needItemList, { itemType = 1, itemId = tonumber(v) })
		end
		self:InitNeedItem()
	end
	self._showBg = activityWebData ~= nil
	CS.ShowObject(self.mMask, true)

	gModelActivity:OnActivityPageReq(self._sid)
end


------------------------------------------------------------------
return UIColWords


