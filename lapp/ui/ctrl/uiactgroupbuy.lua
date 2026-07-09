---
--- Created by BY.
--- DateTime: 2023/10/25 11:04:44
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActGroupBuy:LWnd
local UIActGroupBuy = LxWndClass("UIActGroupBuy", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActGroupBuy:UIActGroupBuy()
	self._uiCommonList = {}
	self._tabTrList = {}
	self._redTrList = {}

	self._timeKey = "UIActGroupBuy_timeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActGroupBuy:OnWndClose()
	self:TimerStop(self._timeKey)
	self:ClearCommonIconList(self._uiCommonList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActGroupBuy:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActGroupBuy:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIActGroupBuy:TabListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local btnTab = self:FindWndTrans(root,"BtnTab")
	local redPoint = self:FindWndTrans(root,"redPoint")
	--local mask = self:FindWndTrans(root,"Mask")

	local pageId = itemdata.pageId
	--local isOpen = self:GetIsOpentDay(pageId)

	self._tabTrList[pageId] = btnTab
	self._redTrList[pageId] = redPoint
	self:SetWndTabText(btnTab,itemdata.name)
	self:SetWndTabStatus(btnTab, 1)
	--CS.ShowObject(mask,isOpen)
	self:SetWndClick(root,function ()
		self:OnClickTab(pageId)
	end)
end

function UIActGroupBuy:OnClickHelp()
	local _sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(_sid)
	if not activityData then
		return
	end
	local data = activityData.config
	local title = gModelActivity:GetLngNameByActivitySid(_sid)
	local content = data.groupBuyHelpTips
	GF.OpenWnd("UIBzTips",{title= title,text = content})
end

function UIActGroupBuy:OnTryTcpReconnect()
	self:WndClose()
end

function UIActGroupBuy:BoxListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local disText = self:FindWndTrans(root,"DisText")
	local icon = self:FindWndTrans(root,"Icon")
	local numText = self:FindWndTrans(root,"NumText")
	local eff = self:FindWndTrans(root,"Eff")
	local _curData = self._curData
	if not _curData then return end
	local num = 0
	local eMoreInfo = JSON.decode(_curData.moreInfo)
	for a,b in pairs(eMoreInfo) do
		num = tonumber(b)
		break
	end
	local arr = string.split(itemdata,"=")
	local isGet = num >= tonumber(arr[1])
	local instanceID = item:GetInstanceID()

	local arr2 = arr[2] and tonumber(arr[2]) or 0
	self:SetWndText(disText,(arr2 * 100) .."%")
	local number = tonumber(arr[1])
	local numStr = LUtil.NumberCoversion(number)
	self:SetWndText(numText,string.replace(ccClientText(26402),numStr))
	self:SetWndEasyImage(icon,isGet and "activity_magicSchool_ui_icon_2" or "activity_magicSchool_ui_icon_4")
	CS.ShowObject(eff,isGet)
	if isGet then
		self:CreateWndEffect(eff,"ui_fx_mengjingxueyuan_xingxing",instanceID,100)
	end
	self:SetWndClick(icon,function ()
		self:OnClickBox()
	end)
end

function UIActGroupBuy:InitEvent()
	self._modelMagList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_66] = "UIActMagicShcool",
	}
	self:SetWndClick(self.mBtnClose, function(...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnBuy, function(...) self:OnClickBuy() end)
	self:SetWndClick(self.mBackground,function () self:OnClickBox() end)
	self:SetWndClick(self.mFill,function () self:OnClickBox() end)
	self:SetWndClick(self.mBtnHelp,function () self:OnClickHelp() end)
end

function UIActGroupBuy:RefreshGroupBuy()
	local _pages = self.pages or {}
	local _pageId = self._pageId
	local _pageData = _pages[_pageId]
	if not _pageData then return end
	local isOpen = self:GetIsOpentDay(_pageId)
	self._isOpen = isOpen
	self:SetTime()

	local list = _pageData.entry
	table.sort(list,function (a,b)
		local aPersonalGoal = a.MarketData.personalGoal
		local aPersonal = a.MarketData.personal
		local aPersonalNum = aPersonalGoal - aPersonal
		local aSort = aPersonalNum == 0 and 1 or 0
		local bPersonalGoal = b.MarketData.personalGoal
		local bPersonal = b.MarketData.personal
		local bPersonalNum = bPersonalGoal - bPersonal
		local bSort = bPersonalNum == 0 and 1 or 0
		if aSort ~= bSort then
			return aSort < bSort
		end
		return a.entryId < b.entryId
	end)
	local _uiCellList = self._uiCellList
	if _uiCellList then
		_uiCellList:RefreshList(list)
	else
		_uiCellList = self:GetUIScroll("mCellSuper_UIActGroupBuy")
		self._uiCellList = _uiCellList
		_uiCellList:Create(self.mCellSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
	end
	if not self._entryId then
		self:OnClickEntry(list[1])
	end
	_uiCellList:DrawAllItems()
end

function UIActGroupBuy:GetIsOpentDay(pageId)
	local _openDay = self._openDay
	local _groupBuyOpen = self._groupBuyOpen

	if not string.isempty(_groupBuyOpen) then
		local _groupBuyOpenArr = string.split(_groupBuyOpen,"|")
		for i, v in ipairs(_groupBuyOpenArr) do
			local arr = string.split(v,"=")
			local _pageId = tonumber(arr[1])
			local day = tonumber(arr[2])
			if _pageId == pageId then
				return _openDay >= day
			end
		end
	end
	return false
end

function UIActGroupBuy:CreateCommonIcon(data)
	local instanceID = data.instanceID
	local trans = data.trans
	local itemType,itemId,itemNum = data.itemType, data.itemId, data.itemNum
	local baseClass = self._uiCommonList[instanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiCommonList[instanceID] = baseClass
		baseClass:Create(trans)
	end
	baseClass:SetCommonReward(itemType,itemId,itemNum)
	local showNum = itemNum > 0
	baseClass:EnableShowNum(showNum)
	baseClass:DoApply()
end

function UIActGroupBuy:OnClickEntry(itemdata)
	self._entryId = itemdata.entryId
	self._uiCellList:DrawAllItems()
	self:RefreshGroupBuyEntry()
end
function UIActGroupBuy:GetEntryDis(itemdata)
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local moreInfo = entryCfg.moreInfo
	local disArr = string.split(moreInfo,"|")

	local num = 0
	local eMoreInfo = JSON.decode(itemdata.moreInfo)
	for a,b in pairs(eMoreInfo) do
		num = tonumber(b)
		break
	end
	local dis = 1
	for i, v in ipairs(disArr) do
		local arr = string.split(v,"=")
		local n = tonumber(arr[1])
		if num >= n then
			dis = tonumber(arr[2])
		end
	end
	return dis
end

function UIActGroupBuy:ResetData(pb)
	local list = self.pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		list[page.pageId] = page
	end
	self.pages = list
	self:RefreshData()
	self:RefreshGroupBuyEntry()
end

function UIActGroupBuy:SendMarkeyBuyMsg(info)
	local canBuyMore = info.canBuyMore
	local pageId = info.pageId
	local entryId = info.entryId
	if canBuyMore == 0 then
		gModelActivity:OnActivityMarkeyBuyReq(self._sid,pageId,entryId)
	else
		local canBuyMoreData = info.canBuyMoreData
		if canBuyMoreData then
			GF.OpenWnd("UIDianBuy",{goodsData = canBuyMoreData,wndType = 3,callFunc = function (num)
				gModelActivity:OnActivityMarkeyBuyReq(self._sid,pageId,entryId,num)
			end})
		end
	end
end

function UIActGroupBuy:RefreshData()
	local _pages = self.pages
	local _groupBuyPages = self._groupBuyPages
	local sid = self._sid
	local activityDataS = gModelActivity:GetActivityBySid(sid)
	local dataS = JSON.decode(activityDataS.moreInfo)
	self._openDay = dataS.openDay
	if not _pages or not _groupBuyPages then return end
	local list = {}
	for i, v in ipairs(_groupBuyPages) do
		local arr = string.split(v,"=")
		local pageId = tonumber(arr[1])
		local data = {
			pageId = pageId,
			name = arr[2],
			pageData = _pages[pageId]
		}
		table.insert(list,data)
	end
	local _uiTabList = self._uiTabList
	if not _uiTabList then
		_uiTabList = self:GetUIScroll("mTabScroll_UIActGroupBuy")
		self._uiTabList = _uiTabList
		_uiTabList:Create(self.mTabScroll,list,function (...) self:TabListItem(...) end)
	end

	local _uiMaskList = self._uiMaskList
	if _uiMaskList then
		_uiMaskList:RefreshList(list)
	else
		_uiMaskList = self:GetUIScroll("mMaskScroll_UIActGroupBuy")
		self._uiMaskList = _uiMaskList
		_uiMaskList:Create(self.mMaskScroll,list,function (...) self:MaskListItem(...) end)
	end

	local _page = self._page
	if _page then
		if _page > 0 then
			self:OnClickTab(list[_page].pageId)
		else
			self:OnClickTab(list[1].pageId)
		end
		self._page = nil
	else
		self:RefreshGroupBuy()
	end
	self:RefreshRed()
end

function UIActGroupBuy:RefreshGroupBuyEntry()
	local _pages = self.pages or {}
	local _pageId = self._pageId
	local _pageData = _pages[_pageId]
	if not _pageData then return end
	local _entryId = self._entryId
	if not _entryId then return end
	local curData
	for i, v in ipairs(_pageData.entry) do
		if v.entryId == _entryId then
			curData = v
		end
	end
	if not curData then return end
	self._curData = curData
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,curData.pageId,curData.entryId)

	local MarketData = curData.MarketData
	local personalGoal = MarketData.personalGoal
	local personal = MarketData.personal
	local personalNum = personalGoal - personal
	local reward = LxDataHelper.ParseItem_4(entryCfg.reward)
	reward.instanceID = "ItemRoot_UIActGroupBuy"
	reward.trans = self.mItemRoot
	local name = gModelItem:GetItemNameRichText(reward.itemId)
	local original = LxDataHelper.ParseItem_3(entryCfg.expend2)
	local dis = self:GetEntryDis(curData)
	local icon = gModelItem:GetItemIconByRefId(original.itemId)
	self._curCount = {
		itemId = original.itemId,
		itemType = original.itemType,
		itemNum = original.itemNum * dis
	}
	local moreInfo = entryCfg.moreInfo
	local moreArr = string.split(moreInfo,"|")
	local disLen = #moreArr
	local disData = moreArr[disLen]
	local disArr = string.split(disData,"=")
	local num = 0
	local eMoreInfo = JSON.decode(curData.moreInfo)
	for a,b in pairs(eMoreInfo) do
		num = tonumber(b)
		break
	end

	self.mScheduleBar.maxValue = tonumber(disArr[1])
	self.mScheduleBar.value = num
	self._boxTipsName = gModelGeneral:GetCommonItemName(reward)
	self._boxTipsValue = num
	self:CreateCommonIcon(reward)
	self:SetWndClick(self.mItemRoot,function ()
		gModelGeneral:ShowCommonItemTipWnd(reward)
	end)
	self:SetWndText(self.mNameText,name)
	local isBuy = personalNum > 0
	CS.ShowObject(self.mDisImg,isBuy and dis < 1)
	CS.ShowObject(self.mBtnBuy,isBuy)
	CS.ShowObject(self.mMaskBuy,not isBuy)
	local personalStr = LUtil.FormatColorStr(personalNum,isBuy and "green" or "red" )
	self:SetWndText(self.mNumText,string.replace(ccClientText(26401),personalStr))
	self:SetWndText(self.mOriginalText,original.itemNum)
	self:SetWndText(self.mCurrentText,original.itemNum * dis)
	self:SetWndEasyImage(self.mCostIcon,icon)
	CS.ShowObject(self.mDisImg,dis < 1)
	if dis < 1 then
		self:CreateWndEffect(self.mDisImg,"ui_fx_mengjingxueyuan_qipao","effKey_UIActGroupBuy",100)
	end
	self:SetWndText(self.mDisText,dis * 100 .."%")
	self:SetWndButtonGray(self.mBtnBuy,not self._isOpen)
	self._curData = curData
	local list = moreArr
	local boxUIList = self._boxUIList
	if boxUIList then
		boxUIList:RefreshList(list)
	else
		boxUIList = self:GetUIScroll("uiBoxList")
		boxUIList:Create(self.mBoxList,list,function (...) self:BoxListItem(...) end)
	end
end
function UIActGroupBuy:GetDayTime(day)
	local activityDatas = gModelActivity:GetActivityBySid(self._sid)
	local startTime = activityDatas.startTime
	local s = (day - 1) * 24 * 60 * 60
	local endTime = startTime + s
	return endTime
end

function UIActGroupBuy:MaskListItem(list, item, itemdata, itempos)
	local mask = self:FindWndTrans(item,"Mask")

	local pageId = itemdata.pageId
	local isOpen = self:GetIsOpentDay(pageId)
	CS.ShowObject(mask,isOpen)
end

function UIActGroupBuy:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if(self._sid ~= sid)then return end
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)
		local activities = pb.activities
		for i, v in ipairs(activities) do
			if v.sid == self._sid then
				self:RefreshData()
				return
			end
		end
	end)
	self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:RefreshRed() end)
	self:WndEventRecv(EventNames.ON_JUMP, function(...) self:WndClose() end)
end

function UIActGroupBuy:OnClickTab(pageId)
	local _tabTrList = self._tabTrList
	local _pageId = self._pageId
	if _pageId then
		self:SetWndTabStatus(_tabTrList[_pageId], 1)
	end
	self:SetWndTabStatus(_tabTrList[pageId], 0)
	self._pageId = pageId
	self._entryId = nil
	self:RefreshGroupBuy()
end

function UIActGroupBuy:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config

	local groupBuyBg,groupBuyPage,groupBuyTitle,groupBuyDes,groupBuyTips,groupBuyEnd
	= data.groupBuyBg,data.groupBuyPage,data.groupBuyTitle,data.groupBuyDes,data.groupBuyTips,data.groupBuyEnd
	self._groupBuyOpen = data.groupBuyOpen

	if LxUiHelper.IsImgPathValid(groupBuyBg) then
		self:SetWndEasyImage(self.mBg,groupBuyBg)
	end
	if LxUiHelper.IsImgPathValid(groupBuyTitle) then
		self:SetWndText(self.mTitleImg,groupBuyTitle)
	end
	if not string.isempty(groupBuyDes) then
		local str = string.gsub(groupBuyDes,"\\n","\n")
		self:SetWndText(self.mDesText,str)
	end
	if not string.isempty(groupBuyTips) then
		self:SetWndText(self.mTipsText,groupBuyTips)
	end

	if string.isempty(groupBuyPage) then return end
	self._groupBuyPages = string.split(groupBuyPage,"|")
	gModelActivity:OnActivityPageReq(sid)

	self._endTime = self:GetDayTime(groupBuyEnd + 1)
	local _timeKey = self._timeKey
	if not self:IsTimerExist(_timeKey) then
		self:TimerStart(_timeKey,1,false,-1)
	end
end
function UIActGroupBuy:OnClickBox()
	local text = ccClientText(26439)
	GF.ShowMessage(string.replace(text,self._boxTipsName ,self._boxTipsValue))
end

function UIActGroupBuy:InitCommand()
	local sid = self:GetWndArg("sid")
	self._page = self:GetWndArg("page") or 0 --支持跳转
	local _subPage = self:GetWndArg("subPage")
	if _subPage then
		sid = gModelActivity:GetSidByUniqueJump(_subPage)
	end
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._sid = sid
	self._modelId = modelId
	gModelActivity:ReqActivityConfigData(sid)

	self:SetWndText(self.mCostTipsText,ccClientText(26403))
	self:SetWndButtonText(self.mBtnBuy,ccClientText(26404))
	self:SetWndText(self.mShopDesText,ccClientText(26405))
end
function UIActGroupBuy:OnClickClose()
	local wndName = self._modelMagList[self._modelId]
	GF.OpenWnd(wndName,{sid = self._sid})
	self:WndClose()
end

function UIActGroupBuy:OnTimer(key)
	if(key == self._timeKey)then
		self:SetTime()
	end
end
function UIActGroupBuy:OnClickBuy()
	local _isOpen = self._isOpen
	local curData = self._curData
	local pageId = self._pageId
	local endTime = self._endTime
	local _groupBuyOpen = self._groupBuyOpen
	local _curCount = self._curCount
	local entryId = self._entryId
	if not entryId then return end
	if not _isOpen and not string.isempty(_groupBuyOpen) then
		local _day
		local _groupBuyOpenArr = string.split(_groupBuyOpen,"|")
		for i, v in ipairs(_groupBuyOpenArr) do
			local arr = string.split(v,"=")
			local _pageId = tonumber(arr[1])
			local day = tonumber(arr[2])
			if _pageId == pageId then
				_day = day
			end
		end
		if _day then
			local startTime = self:GetDayTime(_day)
			local time = GetTimestamp()
			local timespan = startTime - time
			if timespan > 0 then
				local timeStr = LUtil.FormatTimespanCn(timespan)
				GF.ShowMessage(string.replace(ccClientText(26407),timeStr))
				return
			end
		end
	end
	if endTime then
		local time = GetTimestamp()
		local timespan = endTime - time
		if timespan <= 0 then
			GF.ShowMessage(ccClientText(26408))
			return
		end
	end
	if not curData then
		GF.ShowMessage(ccClientText(26409))
		return
	end
	local MarketData = curData.MarketData
	local personalGoal = MarketData.personalGoal
	local personal = MarketData.personal
	local personalNum = personalGoal - personal
	if personalNum <= 0 then
		GF.ShowMessage(ccClientText(26409))
		return
	end
	local itemId = _curCount.itemId
	local dia = gModelItem:GetNumByRefId(itemId)
	local itemName = gModelItem:GetItemNameRichText(itemId)
	local value = _curCount.itemNum
	if dia < value then
		gModelGeneral:OpenGetWayWnd({itemId = itemId})
		return
	end
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,curData.pageId,curData.entryId)
	local canBuyMore = entryCfg.canBuyMore or 0
	local reward = LxDataHelper.ParseItem_4(entryCfg.reward)
	local name = gModelItem:GetItemNameRichText(reward.itemId)
	gModelGeneral:OpenUIOrdinTips({refId = 110042,para = {value..itemName,name},func = function (...)
		self:SendMarkeyBuyMsg({
			pageId = pageId,
			entryId = entryId,
			canBuyMore = canBuyMore,
			canBuyMoreData = {
				price = _curCount,
				reward = reward,
				limit = personalNum,
			}
		})
	end})
end

function UIActGroupBuy:RefreshRed()
	for i, v in pairs(self._redTrList) do
		local isRed = gModelRedPoint:GetActivityRedPointPage(self._sid,i)
		CS.ShowObject(v,isRed)
	end
end

function UIActGroupBuy:SetTime()
	local endTime = self._endTime
	if not endTime then return end
	local _pageId = self._pageId
	local _groupBuyPages = self._groupBuyPages
	local _isOpen = self._isOpen
	if not _groupBuyPages then return end

	local  timeStr = ""
	if not _isOpen then
		timeStr = ccClientText(26410)
	else
		local name = ""
		for i, v in ipairs(_groupBuyPages) do
			local arr = string.split(v,"=")
			if tonumber(arr[1]) == _pageId then
				name = arr[2]
				break
			end
		end
		local time = GetTimestamp()
		local timespan = endTime - time
		if(timespan < 0)then
			timeStr = ccClientText(26411)
		else
			timeStr = LUtil.FormatTimespanCn(timespan)
			timeStr = string.replace(ccClientText(26400),name,timeStr)
		end
	end
	self:SetWndText(self.mTimeText,timeStr)
end

function UIActGroupBuy:ListItem(list,item, itemdata, itempos)
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local root = self:FindWndTrans(item,"Root")
	local itemRoot = self:FindWndTrans(root,"ItemRoot")
	local onImg = self:FindWndTrans(root,"OnImg")
	local disImg = self:FindWndTrans(root,"DisImg")
	local disText = self:FindWndTrans(root,"DisText")

	local instanceID = item:GetInstanceID()
	local reward = LxDataHelper.ParseItem_4(entryCfg.reward)
	local _entryId = self._entryId
	local dis = self:GetEntryDis(itemdata)

	reward.instanceID = instanceID
	reward.trans = itemRoot
	self:CreateCommonIcon(reward)
	CS.ShowObject(onImg,_entryId and _entryId == itemdata.entryId)
	CS.ShowObject(disImg,dis < 1)
	self:SetWndText(disText,dis * 100 .."%")
	self:SetWndClick(root,function ()
		self:OnClickEntry(itemdata)
	end)
end
------------------------------------------------------------------
return UIActGroupBuy


