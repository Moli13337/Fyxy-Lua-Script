---
--- Created by BY.
--- DateTime: 2023/10/24 20:52:53
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubTurntableTk:LChildWnd
local UISubTurntableTk = LxWndClass("UISubTurntableTk", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubTurntableTk:UISubTurntableTk()
	self._tabTrList = {}
	self._uiCommonList = {}

	self._btnStrs=
	{
		[0] =ccClientText(12206),-- "未完成"),
		[1] =ccClientText(12207), --"领  取",
		[2] =ccClientText(12208), --"已领取",
	}
	self._stateImg =
	{
		[0] = "public_btn_2_1",
		[1] = "public_btn_2_2",
		[2] = "public_btn_ash_2",
	}
	self._redTrList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubTurntableTk:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubTurntableTk:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubTurntableTk:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UISubTurntableTk:ResetData(pb)
	local _pages = self._pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		local pageId = page.pageId
		_pages[pageId] = page
	end
	self._pages = _pages
	self:RefreshData()
end

function UISubTurntableTk:TaskListItem(list,item,itemdata,itempos)
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local titleBgTitle = self:FindWndTrans(item,"title")
	local rewardList = self:FindWndTrans(item,"rewardList")
	local btn = self:FindWndTrans(item,"btn")
	local btnText = self:FindWndTrans(btn,"text")
	local ShowText = self:FindWndTrans(item,"Show")
	local eff = self:FindWndTrans(item,"Eff")

	local title = entryCfg.name
	local rewards = LxDataHelper.ParseItem(entryCfg.reward)
	local jumpId = tonumber(entryCfg.jumpId)
	local jumpDesc = entryCfg.jumpDesc

	local goalData = itemdata.goalData
	local status   = goalData.status
	local schedule = goalData.schedules[1].schedule
	local goal = goalData.schedules[1].goal

	self:SetWndText(titleBgTitle,title)
	local InstanceID = item:GetInstanceID()
	local uiList =  self:GetUIScroll("key"..InstanceID)
	local drawRewardList = uiList:GetList()
	if(drawRewardList)then
		uiList:RefreshList(rewards)
		drawRewardList:SetContentPosition(0,0)
	else
		uiList:Create(rewardList,rewards,function (...) self:OnDrawReward(...)  end)
		drawRewardList = uiList:GetList()
		drawRewardList:SetContentPosition(0,0)
	end
	if #rewards >5 then
		uiList:EnableScroll(true,true)
	end

	local btnstr = self._btnStrs[status]
	local btnState = 0
	if status == 0 then
		btnState = 0
		if jumpId and jumpId >0 then
			btnstr = jumpDesc
		end
	elseif status == 1 then
		btnState = 1
	elseif status == 2 then
		btnState = 2
	end

	local img = self._stateImg[btnState]
	self:SetBtnImageAndMat(btn,img,btnText)

	if ShowText then
		CS.ShowObject(ShowText,status == 2)
	end
	CS.ShowObject(btn,status ~= 2)

	local DescTxtTrans = self:FindWndTrans(item, "DescTxt")
	if DescTxtTrans then
		local color = "red"
		if btnState ~= 0 then color = "green" end

		local str = string.format("(%s/%s)",schedule,goal)
		str = LUtil.FormatColorStr(str,color)
		self:SetWndText(DescTxtTrans,str)
	end

	self:SetImageActorState(btn,btnState)
	CS.ShowObject(eff,btnState == 1)
	if btnState == 1 then
		self:CreateWndEffect(eff,"fx_anniu_02",InstanceID,100,false,false)
	end
	self:SetWndText(btnText,btnstr)
	self:SetWndClick(btn,function () self:OnClickEntry(itemdata,status,jumpId) end)
end
--------------------------------------------兑换道具------------------------------------------------
function UISubTurntableTk:RefreshItem()
	local _showItem = self._showItem
	local _currency = _showItem
	local list = {}
	if not string.isempty(_currency) then
		local arr = string.split(_currency,"|")
		for i, v in ipairs(arr) do
			table.insert(list,{itemId = tonumber(v)})
		end
	end
	local _uiCellList = self._uiCellList
	if _uiCellList then
		_uiCellList:RefreshList(list)
	else
		_uiCellList = self:GetUIScroll("mItemScroll_UISubTurntableTk")
		_uiCellList:Create(self.mItemScroll,list,function (...) self:ListItem(...) end)
		self._uiCellList = _uiCellList
	end
end
function UISubTurntableTk:GetReturnRed(pageId)
	return gModelRedPoint:GetActivityRedPointPage(self._sid,pageId)
end
function UISubTurntableTk:RefreshData()
	local _pages = self._pages or {}
	local _pageId = self._pageId
	local page = _pages[_pageId]
	if not page then return end
	self:RefreshItem()

	local list = page.entry
	table.sort(list,function (a,b)
		local aStatus = a.goalData.status
		local bStatus = b.goalData.status
		local aSort = aStatus == 1 and -1 or aStatus
		local bSort = bStatus == 1 and -1 or bStatus
		local aEntryId = a.entryId
		local bEntryId = b.entryId
		if aSort ~= bSort then
			return aSort < bSort
		end
		return aEntryId < bEntryId
	end)
	local _uiTaskList = self._uiTaskList
	if(_uiTaskList)then
		_uiTaskList:RefreshList(list)
	else
		_uiTaskList = self:GetUIScroll("mTaskScroll_UISubTurntableTk")
		self._uiTaskList = _uiTaskList
		_uiTaskList:Create(self.mTaskScroll,list,function (...) self:TaskListItem(...) end, UIItemList.SUPER)
	end
	_uiTaskList:MoveToPos(1)
end
function UISubTurntableTk:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ItemChangeResp,function (pb)
		self:RefreshItem()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:RefreshRed() end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
end

function UISubTurntableTk:InitEvent()
	self._modelEnumList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_57] = {ModelActivity.NEWYEAR2022_ITEM_6,ModelActivity.NEWYEAR2022_ITEM_7},
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_66] = {ModelActivity.MAGIC_ACADEMY6,ModelActivity.MAGIC_ACADEMY7},
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = {ModelActivity.SWEET_COUNTRY_9,ModelActivity.SWEET_COUNTRY_10},
		-- [ModelActivity.SUMMER_DAY] = {ModelActivity.BAND_THEME_TURN_TARGET1,ModelActivity.BAND_THEME_TURN_TARGET2},
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_96] = {ModelActivity.MOTIF_ACTIVITY_LOTTERY_3,ModelActivity.MOTIF_ACTIVITY_LOTTERY_4},
	}
end

function UISubTurntableTk:OnDrawReward(list, item,itemdata,itempos)
	local itemType,itemRefId,itemCount = itemdata.itemType,itemdata.itemId,itemdata.itemNum
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local itemNum = self:FindWndTrans(item,"itemNum")
	local EffTrans = self:FindWndTrans(item,"Eff")
	if EffTrans then
		local show = false
		if itemType == LItemTypeConst.TYPE_ITEM then
			LxResUtil.DestroyChildImmediate(EffTrans)
			local itemRef = gModelItem:GetRefByRefId(itemRefId)
			local bgEff = itemRef and itemRef.bgEff or nil
			if not string.isempty(bgEff) then
				show = true
				local instanceId = item:GetInstanceID()
				self:CreateWndEffect(EffTrans,bgEff,instanceId,90,false,false)
			end
		end
		CS.ShowObject(EffTrans,show)
	end

	if itemRoot then
		local formatData =
		{
			itemId = itemRefId,
			itemType = itemType,
			itemNum = itemCount,
		}
		local uiCommonList = self._uiCommonList
		local InstanceID = item:GetInstanceID()
		local baseClass = uiCommonList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New()
			uiCommonList[InstanceID] = baseClass
			baseClass:Create(CS.FindTrans(itemRoot,"Icon"))
		end
		baseClass:SetCommonReward(itemType, itemRefId, -1)
		self:SetWndClick(itemRoot, function()
			gModelGeneral:ShowCommonItemTipWnd(formatData)
		end)
		baseClass:DoApply()
	end

	local numStr = LUtil.NumberCoversion(itemCount)
	self:SetWndText(itemNum,numStr)
end
--------------------------------------------兑换道具------------------------------------------------
function UISubTurntableTk:OnClickTab(pageId)
	local _tabTrList = self._tabTrList
	local _pageId = self._pageId
	if _pageId then
		self:SetWndTabStatus(_tabTrList[_pageId], 1)
	end
	self:SetWndTabStatus(_tabTrList[pageId], 0)
	self._pageId = pageId
	self:RefreshData()
end
function UISubTurntableTk:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config


	local btnIcon2 = data.btnIcon2
	self._showItem = data.showItem

	-- if data.eModel == ModelActivity.SUMMER_DAY then
	-- 	local enterHero = data.enterHero4
	-- 	if string.isempty(enterHero) or enterHero == "0" or enterHero == 0 then
	-- 		enterHero = data.enterHeroLH4
	-- 	end
	-- 	local pbName = gModelHero:GetHeroDrawing(tonumber(enterHero))
	-- 	self:CreateWndSpine(self.mHeroSpine,pbName,"drawing",false)
	-- 	local pos = LxDataHelper.ParseVector2NotEmpty2(data.turnDarwPos)
	-- 	self:SetAnchorPos(self.mHeroSpine, pos)
	-- 	CS.ShowObject(self.mHeroSpine,true)
	-- else
		local feedBackImg,feedBackPos = data.feedBackImg,data.feedBackPos
		local feedBackTxt,feedBackTxtPos = data.feedBackTxt,data.feedBackTxtPos
		if not string.isempty(feedBackImg) then
			local imgArr = string.split(feedBackImg,"=")
			local parent
			if imgArr[1] == "1" then
				parent = self.mHeroImg
				self:SetWndEasyImage(parent,imgArr[2],nil,true)
			else
				parent = self.mHeroSpine
				local spineName = imgArr[2]
				self:CreateWndSpine(parent,spineName,spineName.."UISubTurntableTk",false)
			end
			CS.ShowObject(parent,true)
			if not string.isempty(feedBackPos) then
				local pos = LxDataHelper.ParseVector2NotEmpty2(feedBackPos)
				self:SetAnchorPos(parent, pos)
			end
		end
		if LxUiHelper.IsImgPathValid(feedBackTxt) then
			local parent = self.mHeroTxt
			CS.ShowObject(parent,true)
			self:SetWndEasyImage(parent,feedBackTxt,nil,true)
			if not string.isempty(feedBackTxtPos) then
				local pos = LxDataHelper.ParseVector2NotEmpty2(feedBackTxtPos)
				self:SetAnchorPos(parent, pos)
			end
		end
	-- end

	local _uiTabList = self._uiTabList
	if not _uiTabList then
		if not string.isempty(btnIcon2) then
			local tabArr = string.split(btnIcon2,"|")
			local list = {}
			for i, v in ipairs(tabArr) do
				local arr = string.split(v,"=")
				local data =
				{
					pageId = tonumber(arr[1]),
					name = arr[2],
				}
				table.insert(list,data)
			end
			_uiTabList = self:GetUIScroll("mTabScroll_UISubTurntableTk")
			_uiTabList:Create(self.mTabScroll,list,function (...) self:TabListItem(...) end)
			self._uiTabList = _uiTabList
			self:OnClickTab(list[1].pageId)
		end
	end
	self:RefreshRed()

	local enums = self._modelEnumList[self._modelId]
	gModelActivity:OnActivityPageReq(self._sid,enums)
end
function UISubTurntableTk:ListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local itemBg = self:FindWndTrans(root,"ItemBg")
	local itemIcon = self:FindWndTrans(itemBg,"ItemIcon")
	local itemText = self:FindWndTrans(itemBg,"ItemText")

	local itemId = itemdata.itemId
	local icon,iconBg = gModelItem:GetItemImgByRefId(itemId)
	local itemNum = gModelItem:GetNumByRefId(itemId)

	self:SetWndEasyImage(itemIcon,icon)
	self:SetWndText(itemText,LUtil.NumberCoversion(itemNum))

	self:SetWndClick(root,function ()
		local wndName = self:GetParentWndName()
		gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = wndName})
	end)
end

function UISubTurntableTk:OnClickEntry(itemdata,state,jumpId)
	if state == 0 then
		if jumpId and jumpId>0 then
			local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId,true)
			if isOpen then
				local wndName = self:GetParentWndName()
				gModelFunctionOpen:Jump(jumpId,wndName)
			end
		else
			GF.ShowMessage(ccClientText(14303)) --"任务未完成，无法领取"
		end

	elseif state == 1 then
		local sid = self._sid
		local pageId = itemdata.pageId
		local entryId = itemdata.entryId
		gModelActivity:OnActivityReceiveGoalReq(sid,pageId,entryId)
	elseif state == 2 then
		GF.ShowMessage(ccClientText(12208))
	end
end
function UISubTurntableTk:InitCommand()
	local sid = self:GetWndArg("sid")
	self._sid = sid
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._modelId = modelId
	if not modelId then return end
	local enums = self._modelEnumList[modelId]
	self._turnTarget1Enum = enums[1]					--转盘目标1
	self._turnTarget2Enum = enums[2]					--转盘目标2

	self:OnActivityConfigData()
end
function UISubTurntableTk:RefreshRed()
	local _redTrList = self._redTrList or {}
	for i, v in pairs(_redTrList) do
		CS.ShowObject(v,self:GetReturnRed(i))
	end
end
function UISubTurntableTk:TabListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local tab = self:FindWndTrans(root,"Tab")
	local redPoint = self:FindWndTrans(root,"Tab/redPoint")
	self._tabTrList[itemdata.pageId] = tab
	self:SetWndTabText(tab,itemdata.name, -2, -30)
	self._redTrList[itemdata.pageId] = redPoint
	self:SetWndTabStatus(tab, 1)
	self:SetWndClick(root,function ()
		self:OnClickTab(itemdata.pageId)
	end)
end
------------------------------------------------------------------
return UISubTurntableTk


