---
--- Created by BY.
--- DateTime: 2023/10/10 15:13:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActPrigeCard:LWnd
local UIActPrigeCard = LxWndClass("UIActPrigeCard", LWnd)

UIActPrigeCard.TYPE_BUY_FREE = 0		--免费购买
UIActPrigeCard.TYPE_BUY_ITEM = 1		--道具购买
UIActPrigeCard.TYPE_BUY_RMB = 2		--充值购买
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActPrigeCard:UIActPrigeCard()
	self._uiCommonList = {}
	self._timeKey = "UIActPrigeCard_timeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActPrigeCard:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActPrigeCard:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActPrigeCard:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitDate()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIActPrigeCard:InitDate()
	self._modelEnum = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = {ModelActivity.SWEET_COUNTRY_19,ModelActivity.SWEET_COUNTRY_20},
	}
	self._modelGenEnum = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = ModelActivity.SWEETS_COUNTRY_RECEIVE_PRIVILEGE_REWARD
	}
	self:SetWndText(self.mAwardText,ccClientText(27600))
	self:SetWndText(self.mPrivilegeText,ccClientText(27601))
	self:SetWndText(self.mDailyText,ccClientText(27602))
	self:SetWndButtonText(self.mBtnGet,ccClientText(27603))
	self:SetWndText(self.mCloseText,ccClientText(15710))
end
function UIActPrigeCard:PrivilegeListItem(list, item, itemdata, itempos)
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local desText = self:FindWndTrans(item,"DesText")

	local description = entryCfg.description
	local str = string.gsub(description,"\\n","\n")
	self:SetWndText(desText,str)
	local uiText = LxUiHelper.FindXTextCtrl(desText)
	local higth = uiText.preferredHeight
	LxUiHelper.SetSizeWithCurAnchor(item,1,higth + 20)
end
function UIActPrigeCard:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end)
end

function UIActPrigeCard:OnTryTcpReconnect()
	self:WndClose()
end

function UIActPrigeCard:OnActivityConfigData()
	local _sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(_sid)
	local data = activityData.config
	local candyCardBg,candyCardTitle,candyCardTitlePos,candyCardIcon,candyCardIconPos,extraDecoration,extraDecorationPos
	= data.candyCardBg,data.candyCardTitle,data.candyCardTitlePos,data.candyCardIcon,data.candyCardIconPos,data.extraDecoration,data.extraDecorationPos
	self._candyCardHelpTitle,self._candyCardHelpTxt = data.candyCardHelpTitle,data.candyCardHelpTxt

	if LxUiHelper.IsImgPathValid(candyCardBg) then
		CS.ShowObject(self.mBg,true)
		self:SetWndEasyImage(self.mBg,candyCardBg)
	end
	if not string.isempty(candyCardIcon) then
		local imgArr = string.split(candyCardIcon,"=")
		local posParent
		if imgArr[1] == "1" then
			posParent = self.mHeroImg
			self:SetWndEasyImage(posParent,imgArr[2],nil,true)
		else
			posParent = self.mHeroSpine
			local spineName = imgArr[2]
			self:CreateWndSpine(posParent,spineName,spineName.."UIActPrigeCard",false)
		end
		if imgArr[3] then
			local flip = tonumber(imgArr[3])
			posParent.localScale = Vector2.New(flip,1)
		end
		CS.ShowObject(posParent,true)
		if not string.isempty(candyCardIconPos) then
			local pos = LxDataHelper.ParseVector2NotEmpty2(candyCardIconPos)
			self:SetAnchorPos(posParent, pos)
		end
	end
	if LxUiHelper.IsImgPathValid(candyCardTitle) then
		local posParent = self.mTextImg
		CS.ShowObject(posParent,true)
		self:SetWndEasyImage(posParent,candyCardTitle,nil,true)
		if not string.isempty(candyCardTitlePos) then
			local pos = LxDataHelper.ParseVector2NotEmpty2(candyCardTitlePos)
			self:SetAnchorPos(posParent, pos)
		end
	end

	local activityDatas = gModelActivity:GetActivityBySid(_sid)
	local _endTime = activityDatas.endTime
	local _timeKey = self._timeKey
	if(_endTime and _endTime ~= -1)then
		self:TimerStop(_timeKey)
		self:TimerStart(_timeKey,1,false,-1)
		self:SetTime()
	end

	local enums = self._modelEnum[self._modelId]
	gModelActivity:OnActivityPageReq(self._sid,enums)
end
function UIActPrigeCard:SetTime()
	local mTimeBg = self.mTimeBg
	local mTimeText = self.mTimeText
	local _timeKey = self._timeKey
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local endTime = activityData.endTime
	if endTime == 0 then
		self:TimerStop(_timeKey)
		self:SetWndText(mTimeText,ccClientText(18404))
		CS.ShowObject(mTimeBg,true)
		return
	end
	local time = GetTimestamp()
	local timespan = endTime - time
	local  timeStr = ""
	if(timespan < 0)then
		timeStr = ccClientText(14301)
		self:TimerStop(_timeKey)
	else
		timeStr = LUtil.FormatTimespanCn(timespan)
		timeStr = string.replace(ccClientText(18400),timeStr)
	end
	self:SetWndText(mTimeText,timeStr)
	CS.ShowObject(mTimeBg,true)
end
function UIActPrigeCard:RefreshData()
	local _sid = self._sid
	local pages = self.pages
	if not pages then return end
	local _cardPage,_privilegePage = pages[self._cardEnum],pages[self._privilegeEnum]
	local _cardList,_privilegeList = _cardPage.entry,_privilegePage.entry
	local _privilegeCard = _cardList[1]
	local moreInfo = JSON.decode(_privilegeCard.moreInfo)
	local buyDay = moreInfo.buyDay or 1
	local daysRewardState = moreInfo.daysRewardState or 0
	local cardEntryCfg = gModelActivity:GetWebActivityEntryData(_sid,_privilegeCard.pageId,_privilegeCard.entryId)
	local rewards = LxDataHelper.ParseItem(cardEntryCfg.reward) or {}
	local cfgMoreInfos = string.split(cardEntryCfg.moreInfo,";")
	local dayRewards = cfgMoreInfos[1] and LxDataHelper.ParseItem(cfgMoreInfos[1]) or {}
	local dayList = {}
	for i, v in ipairs(dayRewards) do
		local itemNum = v.itemNum
		local dayItemNum = itemNum * (buyDay - 1)
		if dayItemNum > 0 then
			local data = {
				itemId = v.itemId,
				itemType = v.itemType,
				itemNum = dayItemNum,
			}
			table.insert(dayList,data)
		end
	end
	local awardList = LxDataHelper.MergeTwoRewardList(rewards,dayList)
	local _uiAwardList = self._uiAwardList
	if _uiAwardList then
		_uiAwardList:RefreshList(awardList)
	else
		_uiAwardList = self:GetUIScroll("AwardSuper_UIActPrigeCard")
		_uiAwardList:Create(self.mAwardSuper,awardList,function (...) self:ListItem(...) end,UIItemList.SUPER)
		_uiAwardList:EnableScroll(true,true)
		self._uiAwardList = _uiAwardList
	end
	_uiAwardList:DrawAllItems()

	local privilegeList = {}
	local privileges = cfgMoreInfos[2] and string.split(cfgMoreInfos[2],",") or {}
	for i, v in ipairs(privileges) do
		local privilegeId = tonumber(v)
		local privilege = _privilegeList[privilegeId]
		table.insert(privilegeList,privilege)
	end
	local marketData = _privilegeCard.MarketData
	local personal = marketData.personal
	local personalGoal = marketData.personalGoal
	local isGuy = personal < personalGoal
	self._isGuy = isGuy

	local _uiPrivilegeList = self._uiPrivilegeList
	if not _uiPrivilegeList then
		_uiPrivilegeList = self:GetUIScroll("PrivilegeSuper_UIActPrigeCard")
		_uiPrivilegeList:Create(self.mPrivilegeSuper,privilegeList,function (...) self:PrivilegeListItem(...) end,UIItemList.SUPER)
		_uiPrivilegeList:EnableScroll(true,false)
		self._uiPrivilegeList = _uiPrivilegeList
		_uiPrivilegeList:DrawAllItems()
	end

	local _uiRewardsList = self._uiRewardsList
	if not _uiRewardsList then
		_uiRewardsList = self:GetUIScroll("mDailySuper_UIActPrigeCard")
		_uiRewardsList:Create(self.mDailySuper,dayRewards,function (...) self:ListItem(...) end,UIItemList.SUPER)
		_uiRewardsList:EnableScroll(true,true)
		self._uiRewardsList = _uiRewardsList
		_uiRewardsList:DrawAllItems()
	end

	local expend2 = cardEntryCfg.expend2
	if not expend2 then return end
	local str = ccClientText(10771)
	local buyType = self.TYPE_BUY_FREE
	local itemInfo
	if not string.isempty(expend2) then
		if not string.find(expend2,"=") then
			str = gModelPay:GetShowByWelfareId(expend2)
			buyType = self.TYPE_BUY_RMB
		else
			itemInfo = LxDataHelper.ParseItem_3(expend2)
			str = itemInfo.itemNum
			buyType = self.TYPE_BUY_ITEM
			local icon,iconBg = gModelItem:GetItemImgByRefId(itemInfo.itemId)
			self:SetWndEasyImage(self.mItemIcon,icon)
		end
	end

	self:SetWndButtonText(self.mBtnBuy,str)
	self:SetWndText(self.mItemText,str)
	CS.ShowObject(self.mBtnBuy,buyType ~= self.TYPE_BUY_ITEM and isGuy)
	CS.ShowObject(self.mBtnItemBuy,buyType == self.TYPE_BUY_ITEM and isGuy)
	CS.ShowObject(self.mMaskBuy,not isGuy)
	local btnFun = function()
		if isGuy then
			if buyType == self.TYPE_BUY_RMB then
				gModelPay:GiftPayCtrl(_privilegeCard.entryId,expend2,ModelPay.PAY_TYPE_ACTIVITY,0,_sid,_privilegeCard.pageId)
			elseif buyType == self.TYPE_BUY_ITEM and itemInfo then
				local dia = gModelItem:GetNumByRefId(itemInfo.itemId)
				local itemName = gModelItem:GetNameByRefId(itemInfo.itemId)
				local value = itemInfo.itemNum
				local itemId = itemInfo.itemId
				-- 钻石购买
				local func = function()
					if dia >= value then
						gModelActivity:OnActivityMarkeyBuyReq(self._sid,_privilegeCard.pageId,_privilegeCard.entryId)
					else
						gModelGeneral:OpenGetWayWnd({itemId = itemInfo.itemId})
					end
				end
				gModelGeneral:OpenUIOrdinTips({refId = 110005,para = {value .. itemName},func = func, consume = {value, itemId},})
				--GF.OpenWnd("UIOrdinTip",{refId = 110005,func = func,para = {value .. itemName},consume = {value, itemInfo.itemId.itemId}})
			else
				gModelActivity:OnActivityMarkeyBuyReq(self._sid,_privilegeCard.pageId,_privilegeCard.entryId)
			end
		end
	end
	self:SetWndClick(self.mBtnBuy,function ()
		if btnFun then btnFun() end
	end)
	self:SetWndClick(self.mBtnItemBuy,function ()
		if btnFun then btnFun() end
	end)
	CS.ShowObject(self.mBtnGet,not isGuy)
	self:SetWndButtonGray(self.mBtnGet,daysRewardState == 1)
	self:SetWndClick(self.mBtnGet,function ()
		if daysRewardState == 0 then
			gModelActivity:OnActivitySpecialOpReq(self._sid,_privilegeCard.pageId,_privilegeCard.entryId,0,nil,self._modelGenEnum[self._modelId])
		else
			GF.ShowMessage(ccClientText(27657))
		end
	end)
end
function UIActPrigeCard:ResetData(pb)
	local _pages = self.pages or {}
	for i, v in ipairs(pb.pages) do
		local pageId = v.pageId
		if self._cardEnum == pageId or self._privilegeEnum == pageId then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			_pages[pageId] = page
		end
	end
	self.pages = _pages
	self:RefreshData()
end
function UIActPrigeCard:CreateCommonIcon(data)
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
	self:SetWndClick(trans,function ()
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
end

function UIActPrigeCard:OnClickHelp()
	local title = self._candyCardHelpTitle
	local text = self._candyCardHelpTxt
	GF.OpenWnd("UIBzTips",{title= title,text = text})
end

function UIActPrigeCard:OnTimer(key)
	if(key == self._timeKey)then
		self:SetTime()
	end
end

function UIActPrigeCard:ListItem(list, item, itemdata, itempos)
	local commonUI = self:FindWndTrans(item,"CommonUI")
	local mask = self:FindWndTrans(item,"Mask")
	local instanceID = item:GetInstanceID()
	local data = {
		itemType = itemdata.itemType,
		itemId = itemdata.itemId,
		itemNum = itemdata.itemNum,
		instanceID = instanceID,
		trans = commonUI
	}
	self:CreateCommonIcon(data)
	if mask then
		local _isGuy = self._isGuy
		CS.ShowObject(mask,not _isGuy)
	end
end
function UIActPrigeCard:InitCommand()
	local sid = self:GetWndArg("sid")
	local _page = self:GetWndArg("page") --支持跳转
	local _subPage = self:GetWndArg("subPage")
	if _subPage then
		sid = gModelActivity:GetSidByUniqueJump(_subPage)
	end
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	local enumList = self._modelEnum[modelId]
	self._cardEnum,self._privilegeEnum = enumList[1],enumList[2]
	self._modelId = modelId
	self._sid = sid
	gModelActivity:ReqActivityConfigData(sid)
end
function UIActPrigeCard:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
	self:WndEventRecv(EventNames.ON_JUMP, function(...) self:WndClose() end)
end
------------------------------------------------------------------
return UIActPrigeCard


