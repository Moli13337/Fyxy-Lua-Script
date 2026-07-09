---
--- Created by Administrator.
--- DateTime: 2025/4/22 17:54:43
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActivityGiftModel4PopOld:LWnd
local UIActivityGiftModel4PopOld = LxWndClass("UIActivityGiftModel4PopOld", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActivityGiftModel4PopOld:UIActivityGiftModel4PopOld()
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActivityGiftModel4PopOld:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActivityGiftModel4PopOld:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActivityGiftModel4PopOld:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitEvent()
	self:InitMsg()
	self:InitPara()
	self:InitStaticText()
end

function UIActivityGiftModel4PopOld:OnClickPay(itemdata)
	--点击购买
	if (self._bBuyAll) then
		self._isClickBuy = true
		gModelActivity:OnActivitySpecialOpReq(self._sid, itemdata.pageId, itemdata.entryId, 3)
		return
	end
	local welfareId = tonumber(itemdata.MarketData.expend2)
	if welfareId == -1 then
		gModelActivity:OnActivityMarkeyBuyReq(self._sid, itemdata.pageId, itemdata.entryId)
		self._isClickBuy = true
		return
	end

	self._isClickBuy = true
	gModelPay:GiftPayCtrl(itemdata.entryId, welfareId, ModelPay.PAY_TYPE_ACTIVITY, 0, self._sid, itemdata.pageId)
end

function UIActivityGiftModel4PopOld:DrawGiftListItem(list, item, itemdata, itempos)
	local Title = CS.FindTrans(item, "Title")
	local BuyBtn = CS.FindTrans(item, "BuyBtn")
	local Mask = CS.FindTrans(item, "Mask")
	local ItemList = CS.FindTrans(item, "ItemList")
	local payText = CS.FindTrans(BuyBtn, "UIText")
	--获取条目的配置信息
	--local pageId = itemdata.pageId
	--local entryId = itemdata.entryId
	--local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, pageId, entryId)

	local bBuy = false
	local personalGoal, personal = itemdata.MarketData.personalGoal, itemdata.MarketData.personal
	if (personalGoal - personal > 0) then
		bBuy = true
	end

	--标题 -- NumText 限购
	--local title = gModelActivity:GetLngNameById(entryCfg.name)
	--self:SetWndText(Title, title)
	local numTextStr = string.replace(ccClientText(15600), personalGoal - personal)
	self:SetWndText(Title, numTextStr)
	--奖励
	local uilist = self:GetUIScroll(item:GetInstanceID())
	uilist:Create(ItemList, itemdata.items, function(...)
		self:DrawRewardListItem(...)
	end, UIItemList.SUPER)
	uilist:EnableScroll(true, false)

	--价格部分的设置
	local buyStr = ""
	local buyEnd = false
	local showRed = false
	if (bBuy) then
		if (self._bBuyAll) then
			buyStr = ccClientText(15617)
			showRed = false
		else
			buyStr = gModelPay:GetShowByWelfareId(tonumber(itemdata.MarketData.expend2))
			showRed = true
			if checknumber(itemdata.MarketData.expend2) == -1 then
				buyStr = ccClientText(10771)
			end
		end
	else
		buyStr = ccClientText(15618)
		buyEnd = true
		showRed = false
	end

	self:SetWndText(payText, buyStr)

	self:SetWndClick(item, function(...)
		if (bBuy) then
			self:OnClickPay(itemdata)
		else
			GF.ShowMessage(ccClientText(15606))
		end
	end)

	if not bBuy then
		CS.ShowObject(Mask, true)
		CS.ShowObject(BuyBtn, false)
	end
end

function UIActivityGiftModel4PopOld:SetGiftBtnStatus()
	-- config数据的获取
	local data = self._webData.config
	self._shopIconJump = data.shopIconJump

	local freeIcon, freeIconPosition = data.freeIcon, data.freeIconPosition
	if LxUiHelper.IsImgPathValid(freeIcon) then
		self:SetWndEasyImage(self.mGiftImg, freeIcon, function()
			CS.ShowObject(self.mGiftImg, true)
		end, true)
		if not string.isempty(freeIconPosition) then
			self:SetAnchorPos(self.mGiftImg, LxDataHelper.ParseVector2NotEmpty(freeIconPosition))
		end
	end
	self:CreateWndEffect(self.mGiftEff, "fx_tehuishangdian", "fx_tehuishangdian", 100)
	self:RefreshFuncBtnShow()
	self:RefreshShopRed()
end

function UIActivityGiftModel4PopOld:SetPagePanel()
	local pageData = self._page[self._pageIndex]

	if not pageData then
		return
	end

	if pageData.isGift then
		CS.ShowObject(self.mGiftDiv, true)
		CS.ShowObject(self.mTaskDiv, false)
		self:SetGiftPagePanel()
	else
		CS.ShowObject(self.mGiftDiv, false)
		CS.ShowObject(self.mTaskDiv, true)
		self:SetTaskPagePanel()
	end
end
--endregion --------------------------------------------------------------------------------------

--region 初始化 --------------------------------------------------------------------------------
function UIActivityGiftModel4PopOld:InitPara()

	local actData = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_DAILYGIFTBAG)
	if not actData then
		self:WndClose()
		RInfoS("MODEL_DAILYGIFTBAG", "not actData")
	end

	self._actData = actData[1]
	local sid = self._actData.sid
	self._sid = sid

	gModelActivity:ReqActivityConfigData(self._sid)

	self._pageIndex = self:GetWndArg("pageIndex") or 1
end

function UIActivityGiftModel4PopOld:RefreshFuncBtnShow()
	if self._shopIconJump then
		local isShow = gModelFunctionOpen:CheckIsShow(self._shopIconJump)
		CS.ShowObject(self.mGiftImg, isShow)
	end
end

function UIActivityGiftModel4PopOld:SetGiftPagePanel()
	local pageData = self._pageWebData[ModelActivity.DAILY_GIFT_TYPE_COMMON]
	if not pageData then
		return
	end

	local list = {}
	local value = 0
	local cost = 0

	self._bNoBuyAll = true
	self._isOneKeyBuy = true --是否可以一键购买
	for i, v in ipairs(pageData.entry) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, v.pageId, v.entryId)
		if not entryCfg then
			return
		end
		local curEntry = {
			pageId = v.pageId,
			entryId = v.entryId,
			title = entryCfg.name,
			items = LxDataHelper.SevenParseItems(v.items),
			MarketData = v.MarketData,
			activeMoreInfo = v.moreInfo,
			moreInfo = entryCfg.moreInfo,
		}
		--总的价值
		value = value + gModelPay:GetValueByWelfareId(tonumber(v.MarketData.expend2))
		table.insert(list, curEntry)

		local expend1 = v.MarketData.expend1
		local money
		if string.isempty(expend1) then
			money = gModelPay:GetRMBValueByWelfareId(tonumber(v.MarketData.expend2))
		else
			money = tonumber(expend1)
		end
		cost = cost + money

		local personalGoal, personal = v.MarketData.personalGoal, v.MarketData.personal
		if (personalGoal - personal > 0 and self._bNoBuyAll) then
			self._bNoBuyAll = false
		end

		if personalGoal - personal <= 0 and tonumber(v.MarketData.expend2) > 0 then
			if self._isOneKeyBuy then
				self._isOneKeyBuy = false
			end
		end
	end

	local symbol = gModelPay:GetMoneySymbol()
	local costStr = string.replace(ccClientText(15603), string.format("%s%s", symbol, value))
	self:SetWndText(self.mOldPrice, costStr)

	local isDmm = gLSdkImpl:CallMethod(LSdkMethod.IsDMMPlatform)
	if isDmm then
		CS.ShowObject(self.mOldPrice, false)
	end

	self._cost = cost

	local buyEnd = false
	local isGray = false
	self._bBuyAll = false
	local pageData = JSON.decode(pageData.moreInfo)
	self._oneKeyBuyStr = ccClientText(15638)
	if (pageData.buyAllFlag) then
		self._bBuyAll = true
		self._oneKeyBuyStr = ccClientText(15623)
	elseif (self._bNoBuyAll) then
		isGray = true
		buyEnd = true
	end

	if (self._uiGiftList) then
		self._uiGiftList:RefreshData(list)
		self._uiGiftList:DrawAllItems()
	else
		self._uiGiftList = self:GetUIScroll("cell")
		self._uiGiftList:Create(self.mGiftScroll, list, function(...)
			self:DrawGiftListItem(...)
		end, UIItemList.SUPER)
	end
	self._marketGiftData = list

	self._uiGiftList:EnableScroll(false, true)
end

function UIActivityGiftModel4PopOld:SetPageRedPoint()
	if not self._pageRedPoint then
		return
	end

	for pageIndex, redPoint in ipairs(self._pageRedPoint) do
		local pageData = self._page[pageIndex]
		local isRed = false
		if pageData.isGift then
			for k, itemdata in ipairs(self._marketGiftData) do
				if checknumber(itemdata.MarketData.expend2) == -1 then
					local personalGoal, personal = itemdata.MarketData.personalGoal, itemdata.MarketData.personal
					if (personalGoal - personal > 0) then
						isRed = true
					end

					if isRed then
						break
					end
				end
			end
		else
			local pageData = self._page[pageIndex]
			local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, pageData.pageId, 1)
			local moreInfo = entryCfg.moreInfo
			local tempData = string.split(moreInfo, "|")
			local curTaskId = checknumber(tempData[4])
			local taskData = gModelQuest:GetTaskDataByRefId(curTaskId)
			local state = taskData:GetState()
			isRed = state == ModelQuest.TASK_FINNISH
		end

		CS.ShowObject(redPoint, isRed)
	end
end

function UIActivityGiftModel4PopOld:OnActivityConfigData(data, sid)
	if sid ~= self._sid then
		return
	end

	self._webData = data

	if not self._webData then
		self:WndClose()
		RInfoS("UIActivityGiftModel4PopOld", "not webData close wnd")
		return
	end

	gModelActivity:OnActivityPageReq(self._sid)
end

function UIActivityGiftModel4PopOld:DrawPageListItem(list, item, itemdata, itempos)
	local SelectBg = CS.FindTrans(item, "SelectBg")
	local PageName = CS.FindTrans(item, "PageName")
	local redPoint = CS.FindTrans(item, "redPoint")
	CS.ShowObject(SelectBg, itempos == self._pageIndex)
	self:SetWndText(PageName, itemdata.name)
	self:SetWndClick(item, function()
		self:OnPageItemClick(itempos)
	end)

	if not self._pageItem then
		self._pageItem = {}
	end

	self._pageItem[itempos] = item
	if not self._pageRedPoint then
		self._pageRedPoint = {}
	end

	self._pageRedPoint[itempos] = redPoint

	--红点设置
	local pageData = self._page[itempos]
	local isRed = false
	if pageData.isGift then
		for k, itemdata in ipairs(self._marketGiftData) do
			if checknumber(itemdata.MarketData.expend2) == -1 then
				local personalGoal, personal = itemdata.MarketData.personalGoal, itemdata.MarketData.personal
				if (personalGoal - personal > 0) then
					isRed = true
				end

				if isRed then
					break
				end
			end
		end
	else
		local pageData = self._page[itempos]
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, pageData.pageId, 1)
		local moreInfo = entryCfg.moreInfo
		local tempData = string.split(moreInfo, "|")
		local curTaskId = checknumber(tempData[4])
		local taskData = gModelQuest:GetTaskDataByRefId(curTaskId)
		local state = ModelQuest.TASK_UNFINISH
		if taskData then
			state = taskData:GetState()
		end
		isRed = state == ModelQuest.TASK_FINNISH
	end

	CS.ShowObject(redPoint, isRed)
end

function UIActivityGiftModel4PopOld:OnClickGift()
	--特惠商店的跳轉
	local id = self._shopIconJump
	local isOpen = gModelFunctionOpen:CheckIsOpened(id, true)
	if (not isOpen) then
		return
	end
	gModelFunctionOpen:Jump(id, self:GetWndName())
end

function UIActivityGiftModel4PopOld:RefreshShopRed()
	--local isRed = gModelRedPoint:CheckActivityShowRed(self._sid)

	local isRed = gModelRedPoint:CheckShowRedPoint(10405111)
	--isRed = isRed or gModelRedPoint:CheckShowRedPoint(10405111)
	CS.ShowObject(self.mRedPoint, isRed)
end

function UIActivityGiftModel4PopOld:OnInitActivityPanel(pb)
	local sid = pb.sid
	if self._sid ~= sid then
		return
	end

	--解析分页的数据
	self._page = {}
	local taskPage = self._webData.config.taskPage
	taskPage = gModelActivity:GetLngNameById(taskPage)
	taskPage = string.split(taskPage, "|")

	for k, v in ipairs(taskPage) do
		local tempData = string.split(v, "=")

		local tempData_2 = {
			isGift = checknumber(tempData[1]) == 1,
			name = tempData[3],
			pageId = checknumber(tempData[2]),
		}

		table.insert(self._page, tempData_2)
	end

	--分页的服务器数据
	self._pageWebData = {}

	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		table.insert(self._pageWebData, page)
	end


	-- 页面设置
	self:SetGiftBtnStatus()
	self:SetPageScroll()

	self:SetGiftPagePanel()
	self:SetTaskPagePanel()
	self:SetPagePanel()
	self:SetOneKeyBuyStatus()
	self:SetPageRedPoint()
	local data = self._webData.config
	local shopname = data.shopname
	if (shopname) then
		self:SetWndText(self.mGiftText, shopname)
		self:InitTextSizeWithLanguage(self.mGiftText, -2)
		self:InitTextLineWithLanguage(self.mGiftText, -30)
	end
	local content = data.helpTipsContent

	if string.isempty(content) then
		CS.ShowObject(self.mHelpBtn, false)
	end

end
function UIActivityGiftModel4PopOld:OnClickOneBuy()
	local pageData = self._pageWebData[self._pageIndex]
	local data = JSON.decode(pageData.moreInfo)
	if self._bBuyAll and not self._bNoBuyAll then
		local pageId
		for i, v in ipairs(pageData.entry) do
			if pageId then
				break
			end
			pageId = v.pageId
		end
		self._isClickBuy = true
		gModelActivity:OnActivitySpecialOpReq(self._sid, pageId, 0, 3)
		return
	end
	if (data.buyAllFlag) then
		GF.ShowMessage(ccClientText(15605))
		return
	end
	if (self._bNoBuyAll) then
		GF.ShowMessage(ccClientText(15621))
		return
	end
	if not self._isOneKeyBuy then
		GF.ShowMessage(ccClientText(15629))
		return
	end
	local bBuy = true
	local list = pageData.entry
	local entryId = ""
	local j = 1
	for i, v in ipairs(list) do
		local personalGoal, personal = v.MarketData.personalGoal, v.MarketData.personal
		if (personalGoal - personal > 0) then
			if (j == 1) then
				entryId = v.entryId
			else
				entryId = entryId .. "#" .. v.entryId
			end
			j = j + 1
		end
	end
	if (not bBuy) then
		GF.ShowMessage(ccClientText(15605))
		return
	end
	self._isClickBuy = true
	gModelPay:GiftPayCtrl(entryId, self._buyAllExpend, ModelPay.PAY_TYPE_ACTIVITY, 0, self._sid, pageData.pageId)
end

function UIActivityGiftModel4PopOld:SetPageScroll()
	-- 绘制这块的页面
	local list = self._pageScroll

	if not list then
		self._pageScroll = self:GetUIScroll("uiList")
		self._pageScroll:Create(self.mPageScroll, self._page, function(...)
			self:DrawPageListItem(...)
		end, UIItemList.SUPER)
	else
		self._pageScroll:RefreshList(self._page)
	end

	self._pageScroll:EnableScroll(true, true)
end

function UIActivityGiftModel4PopOld:SetOneKeyBuyStatus()
	local data = self._webData.config

	local isOpenOneKeyBuy = checknumber(data.buyAllLimit) == 1

	CS.ShowObject(self.mBuyBtn, isOpenOneKeyBuy)
	CS.ShowObject(self.mBuyDes, isOpenOneKeyBuy)
	if not isOpenOneKeyBuy then
		return
	end

	local buyAllType = checknumber(data.buyAllType)

	if not buyAllType == 1 then
		--这个面板只处理1的情况
		return
	end

	self._buyAllExpend = nil
	local _buyAllStr = data.buyAllExpend2
	local _buyAllArr = string.split(_buyAllStr, ";")
	local discount = 0
	local cost = self._cost or 0 -- 与礼包价格相关 在处理礼包时进行计算


	for i, v in ipairs(_buyAllArr) do
		local costArr = string.split(v, "=")
		local costNum = tonumber(costArr[1])
		self._buyAllExpend = tonumber(costArr[2])
		if (costNum == cost) then
			self._buyAllExpend = tonumber(costArr[2])
			discount = tonumber(costArr[3])
			break
		end
	end

	-- 下方tips描述
	local desStr = data.buyAllJump2
	desStr = gModelActivity:GetLngNameById(desStr)
	self:SetWndText(self.mBuyDes, desStr)

	-- 描述  --UI无体现 屏蔽
	--local buyAllDescription2 = data.buyAllDescription2
	--if(buyAllDescription2)then
	--    local str = string.gsub(buyAllDescription2,"\\n",'\n')
	--end

	-- 按钮描述
	local payTextStr
	if self._buyAllExpend then
		payTextStr = gModelPay:GetShowByWelfareId(tonumber(self._buyAllExpend)) -- string.replace(ccClientText(15603),priceCost)
		payTextStr = string.replace(ccClientText(15603), payTextStr)
	end
	self:SetWndText(self.mCurPrice, payTextStr)
	self:SetWndText(CS.FindTrans(self.mBuyBtn, "UIText"), self._oneKeyBuyStr)


	--置灰
	local pageData = self._pageWebData[self._pageIndex]
	local data = JSON.decode(pageData.moreInfo)

	if (data.buyAllFlag) or (self._bNoBuyAll) or (not self._isOneKeyBuy) then
		self:SetWndImageGray(self.mBuyBtn, true)
	else
		self:SetWndImageGray(self.mBuyBtn, false)
	end

end

function UIActivityGiftModel4PopOld:OnPageItemClick(itempos)
	if self._pageIndex == itempos then
		return
	end

	local oldIndex = self._pageIndex
	local item = self._pageItem[oldIndex]
	local SelectBg = CS.FindTrans(item, "SelectBg")
	CS.ShowObject(SelectBg, false)

	self._pageIndex = itempos
	item = self._pageItem[itempos]
	SelectBg = CS.FindTrans(item, "SelectBg")
	CS.ShowObject(SelectBg, true)

	self:SetPagePanel()
end

--region 事件 --------------------------------------------------------------------------------
function UIActivityGiftModel4PopOld:InitEvent()
	self:SetWndClick(self.mBgImage, function()
		self:WndClose()
	end)

	self:SetWndClick(self.mGiftImg, function(...)
		self:OnClickGift()
	end)
	self:SetWndClick(self.mBuyBtn, function(...)
		self:OnClickOneBuy()
	end)

	self:SetWndClick(self.mGetBtn, function()
		if self._taskData then
			if self._cutTaskState == ModelQuest.TASK_UNFINISH then
				self:OnPageItemClick(self._curTaskJumpIndex)
			else
				gModelQuest:OnClickTaskBtn(self._taskData, self:GetWndName())
			end


		else
			self:OnPageItemClick(self._curTaskJumpIndex)
		end
	end)

	self:SetWndClick(self.mHelpBtn, function(...)
		UIHelper.OnClickHelpBtn(self._sid)
	end, LSoundConst.CLICK_ERROR_COMMON)
end

--任务界面
function UIActivityGiftModel4PopOld:SetTaskPagePanel()
	local pageData = self._page[self._pageIndex]

	--取下对应的配置
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, pageData.pageId, 1)

	local moreInfo = entryCfg.moreInfo

	local tempData = string.split(moreInfo, "|")
	local bg = tempData[1]
	--描述图部分
	if LxUiHelper.IsImgPathValid(bg) then
		self:SetWndEasyImage(self.mTaskDes, bg, nil, true)
	end

	local bgPos = LxDataHelper.ParseVector2NotEmpty2(tempData[2])
	self:SetAnchorPos(self.mTaskDes, bgPos)

	self._curTaskJumpIndex = checknumber(tempData[3])

	--任务     --按钮状态
	local curTaskId = checknumber(tempData[4])
	local taskData = gModelQuest:GetTaskDataByRefId(curTaskId)

	local state = ModelQuest.TASK_UNFINISH
	if not taskData then
		state = ModelQuest.TASK_UNFINISH
	else
		state = taskData:GetState()
		self._taskData = taskData
	end

	self._cutTaskState = state

	local btnStr
	self:SetWndImageGray(self.mGetBtn, false)
	if state == ModelQuest.TASK_UNFINISH then
		btnStr = gModelActivity:GetLngNameById(entryCfg.jumpDesc)
	elseif state == ModelQuest.TASK_FINNISH then
		btnStr = ccClientText(12207)
	elseif state == ModelQuest.TASK_REWARDED then
		btnStr = ccClientText(12208)
		self:SetWndImageGray(self.mGetBtn, true)
	end

	CS.ShowObject(CS.FindTrans(self.mGetBtn, "redPoint"), state == ModelQuest.TASK_FINNISH)

	if taskData then
		local _goal = taskData._goal
		local _schedule = taskData._schedule
		local progressStr = string.replace("#a1#/#a2#", _schedule, _goal)
		self:SetWndText(self.mTaskProgress, progressStr)
	end

	self:SetWndText(CS.FindTrans(self.mGetBtn, "UIText"), btnStr)
	--奖励列表
	local rewards = LxDataHelper.ParseItem(entryCfg.reward)
	local uilist = self._taskRewardList

	if not uilist then
		uilist = self:GetUIScroll(self.mTaskItemList:GetInstanceID())
		uilist:Create(self.mTaskItemList, rewards, function(...)
			self:DrawRewardListItem(...)
		end, UIItemList.SUPER)
		uilist:EnableScroll(true, false)
	else
		uilist:RefreshData(rewards)
		uilist:DrawAllItems()
	end

	self._taskRewardList = uilist
end

function UIActivityGiftModel4PopOld:OnTryRefreshRedPoint()
	self:RefreshShopRed()
end

function UIActivityGiftModel4PopOld:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
		self:OnActivityConfigData(...)
	end)

	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		self:OnInitActivityPanel(pb)
	end)

	self:WndEventRecv(EventNames.ON_QUEST_CHANGE, function(...)
		self:SetTaskPagePanel(...)
		self:SetPageRedPoint()
	end)
end


--endregion --------------------------------------------------------------------------------------

--region 界面设置 --------------------------------------------------------------------------------
function UIActivityGiftModel4PopOld:InitStaticText()
	self:SetWndText(CS.FindTrans(self.mCompletionDes, "UIText"), ccClientText(15639))

	local uiText = LxUiHelper.FindXTextCtrl(CS.FindTrans(self.mCompletionDes, "UIText"))
	local width = uiText.preferredWidth
	width = math.floor(width / 2)
	local posx = 75 + width
	self:SetAnchorPos(self.mRightArrow, Vector2.New(posx, 0))
	self:SetAnchorPos(self.mLeftArrow, Vector2.New(-posx, 0))

end

function UIActivityGiftModel4PopOld:DrawRewardListItem(list, item, itemdata, itempos)
	local ItemIconRoot = self:FindWndTrans(item, "ItemIconRoot")

	local itype, refId, count = itemdata.type or itemdata.itemType, itemdata.itemId, itemdata.count or itemdata.itemNum
	local formatData = {
		itemId = refId,
		itemType = itype,
		itemNum = count,
	}

	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(ItemIconRoot)
	end

	baseClass:SetCommonReward(formatData.itemType, formatData.itemId, count)
	baseClass:DoApply()
	self:SetIconClickScale(ItemIconRoot, true)
	self:SetWndClick(ItemIconRoot, function()
		gModelGeneral:ShowCommonItemTipWnd(formatData)
	end)
end


--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIActivityGiftModel4PopOld