---
--- Created by Administrator.
--- DateTime: 2023/10/12 10:51:33
---
---活动75 八天登录
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAct172:LWnd
local UIAct172 = LxWndClass("UIAct172", LWnd)

UIAct172.PAGE_SIGN = 1
UIAct172.PAGE_QUEST = 2
UIAct172.TYPE_BUY_FREE = 0		--免费购买
UIAct172.TYPE_BUY_ITEM = 1		--道具购买
UIAct172.TYPE_BUY_RMB = 2		--充值购买
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAct172:UIAct172()
	if not LUtil.IsToDay(checknumber(LPlayerPrefs.openActivity172) or 0) then
		LPlayerPrefs.SetOpenActivity172(GetTimestamp())
		FireEvent(EventNames.ON_ACTIVITY_LOCAL_CLICK_RED_CHANGE)
	end
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAct172:OnWndClose()
	self:ClearTimer()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAct172:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAct172:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._curSelRound = 0
	self._tabList = {}
	self._isEnus = gLGameLanguage:IsForeignVersion()
	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitUIEvent()
	self:InitEvent()
	self:InitPara()

	self:SetStaticContent()
end

function UIAct172:InitPara()
	self._func = self:GetWndArg("func")
	self._sid = self:GetWndArg("sid")

	local subpage = self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end

	gModelActivity:ReqActivityConfigData(self._sid)

	local wndName = self:GetWndName()
	local wndPara = {
		wndName = wndName,
		para1 = 1,
		para2 = 1,
	}

	FireEvent(EventNames.ON_WND_OPEN_TRIGGER, wndPara) --指引触发条件


end

function UIAct172:SetStaticContent()

	self:SetWndText(self.mCloseTip, ccClientText(10103))
	--if not gLGameLanguage:IsForeignRegion() then
	--	--海外不显示该特效
	--	self:CreateWndEffect(self.mEffRoot,"ui_fx_batianhuodong","eff1",125)
	--end

	--self:CreateWndEffect(self.mLight1,"ui_fx_batianhuodong_02","eff2",100)
	--self:CreateWndEffect(self.mLight2,"ui_fx_batianhuodong_02","eff3",100)

end

function UIAct172:InitUIEvent()
	self:SetWndClick(self.mBtnClose, function()
		self:OnClickClose()
	end)
	self:SetWndClick(self.mBtnGet, function()
		self:OnClickGet()
	end)
	self:SetWndClick(self.mBtnHelp, function()
		GF.OpenWndUp("UIBzTips", { title = self._helpTipsTitle, text = self._helpTipsContent })
	end)

	self:SetWndClick(self.mMask, function()
		self:OnClickClose()
	end)
end

function UIAct172:OnClickClose()
	--local canGetReward = self:GetCanGetReward()
	--if canGetReward and #canGetReward > 0 then
	--	local para = {
	--		refId = 280101,
	--		func = function()
	--			gModelActivity:OnActivityReceiveGoalListReq(canGetReward)
	--		end,
	--		leftFunc = function()
	--			GF.CloseWndByName("UIAct172")
	--		end
	--	}
	--
	--	gModelGeneral:OpenWndCommonTips(para)
	--else
	--	self:WndClose()
	--end
	self:WndClose()
end

function UIAct172:InitEvent()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
		self:OnActivityConfigData(...)
	end)

	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...)
		self:OnActivityPageResp(...)
	end)

	self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
		local activity = pb.activity
		if not activity or self._sid ~= activity.sid then
			return
		end
		local status = activity.status
		if status == 3 then
			self:WndClose()
			return
		end
		self:RefreshCfg()
	end)

	self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(...)
		local actData = gModelActivity:GetActivityBySid(self._sid)
		if actData.status == 3 then
			self:WndClose()
			return
		end

		self:RefreshCfg()
	end)

	self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
		gModelActivity:OnActivityPageReq(self._sid)
	end)

end

function UIAct172:OnActivityConfigData(data, sid)
	if sid ~= self._sid then
		return
	end
	self:RefreshCfg()
	gModelActivity:OnActivityPageReq(self._sid)
end

function UIAct172:RefreshCfg()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then
		return
	end

	local actData = gModelActivity:GetActivityBySid(self._sid)
	if not actData then
		return
	end

	local config = webData.config
	self.config = config

	self.IOSpackId = config.IOSpackId
	self.descBtn = config.descBtn

	self._helpTipsTitle = actData.title
	self._helpTipsContent = config.helpTipsContent or ""

	if LxUiHelper.IsImgPathValid(config.image) then
		self:SetWndEasyImage(self.mBg, config.image,nil,true)
	end

	if LxUiHelper.IsImgPathValid(config.descIcon) then
		self:SetWndEasyImage(self.mTitle, config.descIcon,nil,true)
	end

	if not string.isempty(config.descIconPosition) then
		local pos = LxDataHelper.ParseVector2(config.descIconPosition, '|')
		self:SetAnchorPos(self.mTitle, pos)
	end

	if not string.isempty(config.discountTxtPos) then
		local pos = LxDataHelper.ParseVector2(config.discountTxtPos, '|')
		self:SetAnchorPos(self.mDiscount, pos)
	end


	self:SetWndText(self.mTipText, ccLngText(config.desc))

	if not string.isempty(config.descPos) then
		local pos = LxDataHelper.ParseVector2(config.descPos, '|')
		self:SetAnchorPos(self.mTipRoot, pos)
	end

	if not string.isempty(config.ImageHero) then
		local showHeroInfo = string.split(config.ImageHero,"=")
		local showHeroType = tonumber(showHeroInfo[1])
		local heroTrans
		if showHeroType == 1 then
			if LxUiHelper.IsImgPathValid(showHeroInfo[2]) then
				self:SetWndEasyImage(self.mRoleImg, config.descIcon,nil,true)
				CS.ShowObject(self.mRoleImg, true)
				heroTrans = self.mRoleImg
			end
		elseif showHeroType == 2 then
			CS.ShowObject(self.mRoleImg, false)
			local drawHero = showHeroInfo[2]
			self:CreateWndSpine(self.mDrawingRoot, drawHero, "drawing")
			heroTrans = self.mDrawingRoot
		end
		local scale = tonumber(showHeroInfo[3])
		heroTrans.localScale = Vector3.New(scale,scale,scale)
	end

	if not string.isempty(config.ImageHeroPos) then
		local pos = LxDataHelper.ParseVector2(config.ImageHeroPos, '|')
		self:SetAnchorPos(self.mDrawingRoot, pos)
	end

	local pageData = gModelActivity:GetWebActivityPageData(self._sid, UIAct172.PAGE_SIGN)

	local dataList = {}
	for k, v in ipairs(pageData.entries) do
		local rewardList = LxDataHelper.ParseItem(v.reward)
		local data = {
			entry = v,
			rewardList = rewardList,
		}
		table.insert(dataList, data)
	end

	table.sort(dataList, function(a, b)
		return a.entry.sort < b.entry.sort
	end)
	self._dataList = dataList

	pageData = gModelActivity:GetWebActivityPageData(self._sid, UIAct172.PAGE_QUEST)
	self.questList = pageData.entries

	self.endTime = actData.endTime
end


function UIAct172:SetSpineHero(heroRefId)
	local effRef = gModelHero:GetHeroEffectRef(heroRefId)

	if effRef then
		local prefabName = effRef.prefabName
		self:CreateWndSpine(self.mHeroSpinePos, prefabName, "heroSpinePos", false)
		CS.ShowObject(self.mHeroSpinePos, true)

		self:SetWndClick(self.mHeroSpinePos, function()
			local itemData = {
				itemId = heroRefId, itemType = LItemTypeConst.TYPE_HERO, itemNum = 0
			}
			gModelGeneral:ShowCommonItemTipWnd(itemData)
		end)
	else
		CS.ShowObject(self.mHeroSpinePos, false)
	end
end

function UIAct172:RefreshRewardList()
	local list = self:FindUIScroll("rewardList")
	if not list then
		list = self:GetUIScroll("rewardList")
		list:Create(self.mItemList, self._dataList, function(...)
			self:OnDrawCell(...)
		end, UIItemList.SUPER_GRID)
		self._uiItemList = list
	else
		list:RefreshList(self._dataList)
		list:DrawAllItems(false)
	end
end

function UIAct172:OnDrawCell(list, item, itemdata, itempos)
	local AniRoot = self:FindWndTrans(item, "AniRoot")
	local AniRootDarkBg = self:FindWndTrans(AniRoot, "darkBg")
	local AniRootLightBg = self:FindWndTrans(AniRoot, "lightBg")
	local AniRootItemIcon = self:FindWndTrans(AniRoot, "itemIcon")
	local AniRootItemName = self:FindWndTrans(AniRoot, "itemName")
	local AniRootItemName_1 = self:FindWndTrans(AniRoot, "itemName_1")
	local AniRootDay = self:FindWndTrans(AniRoot, "day")
	local AniRootDay_1 = self:FindWndTrans(AniRoot, "day_1")
	local AniRootTag = self:FindWndTrans(AniRoot, "tag")
	local AniRootTagMask = self:FindWndTrans(AniRoot, "Mask")
	local Eff = self:FindWndTrans(AniRoot, "Eff")

	local AniRootActive = self:FindWndTrans(AniRoot, "active")

	item.localScale = Vector3.New(0.9 , 0.9 ,0.9)

	local entryCfg = itemdata.entry

	local reward = itemdata.rewardList[1]

	local instanceId = item:GetInstanceID()
	local uiItemList = self._uiItemList
	local baseClass = uiItemList:GetItemCls(instanceId)
	if not baseClass then
		baseClass = CommonIcon:New()
		uiItemList:SetItemCls(instanceId, baseClass)
		baseClass:Create(AniRootItemIcon)
	end

	local itemId = reward.itemId
	local itemType = reward.itemType
	local itemNum = reward.itemNum

	baseClass:SetCommonReward(itemType, itemId ,itemNum)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()

	self:SetIconClickScale(AniRootItemIcon, true)
	self:SetWndClick(AniRootItemIcon,function()
		gModelGeneral:ShowCommonItemTipWnd(reward)
	end)


	if self._isEnus then
		self:SetAnchorPos(AniRootDay,Vector2.New(-3.4,12))
		self:SetAnchorPos(AniRootDay_1,Vector2.New(-3.4,12))
	end

	if self.jpj then
		self:SetAnchorPos(AniRootDay,Vector2.New(-3.4,19))
		self:SetAnchorPos(AniRootDay_1,Vector2.New(-3.4,19))
	end

	local showDark = false

	local isSelect = entryCfg.id == self._curDay
	local entryData = self:GetEntryData(entryCfg.id)
	local HasGet = false
	if entryData then
		CS.ShowObject(AniRootTag, entryData.MarketData.personal == 1) --已领取
		CS.ShowObject(AniRootTagMask, entryData.MarketData.personal == 1)
		HasGet = entryData.MarketData.personal == 1
		--self:SetWndClick(AniRoot, function()
		--	if itemdata.entry.id == self.canGetEntryId then
		--		self:OnSelectItem(itemdata.entry.id)
		--	end
		--end)
		--showDark = entryData.MarketData.personal == 1
	end


	if not self._listItem then
		self._listItem = {}
	end
	self._listItem[itemdata.entry.id] = item

	if isSelect and not HasGet then
		self:CreateWndEffect(AniRootItemIcon, "fx_baowu_kejihuo", instanceId, 100, false, false, 20)
	else
		self:DestroyWndEffectByKey(instanceId)
	end

	local Bgimg = entryCfg.description
	if LxUiHelper.IsImgPathValid(Bgimg) then
		self:SetWndEasyImage(AniRootLightBg, Bgimg , nil, true)
		self:SetWndEasyImage(AniRootTagMask, Bgimg , nil, true)
	end

	--self:SetWndText(AniRootItemName,entryCfg.description)
	--self:InitTextLineWithLanguage(AniRootItemName, -30)
	--self:InitTextSizeWithLanguage(AniRootItemName, -4)

	self:SetWndText(AniRootDay, entryCfg.name)
	self:SetWndText(AniRootDay_1, entryCfg.name)
	--self:SetWndText(AniRootItemName_1,entryCfg.description)
	--self:InitTextLineWithLanguage(AniRootItemName_1, -30)
	--self:InitTextSizeWithLanguage(AniRootItemName_1, -4)

	local showLight = entryCfg.id <= self.openDay

	CS.ShowObject(AniRootDarkBg, false)
	CS.ShowObject(AniRootLightBg, true)
	CS.ShowObject(AniRootDay, not isSelect)
	--CS.ShowObject(AniRootItemName, showDark)

	CS.ShowObject(AniRootDay_1,  isSelect)
	--CS.ShowObject(AniRootItemName_1, not showDark)

	--local alpha = showDark and 1 or 0.8
	--self:SetImageAlpha(AniRootItemIcon,alpha)
	--CS.ShowObject(AniRootActive, isSelect)
end

function UIAct172:OnSelectItem(day)
	if self._curDay == day then
		return
	end

	local oldDay = self._curDay
	self._curDay = day

	if oldDay and self._listItem[oldDay] then
		local oldItem = self._listItem[oldDay]
		local AniRoot = self:FindWndTrans(oldItem, "AniRoot")
		local AniRootActive = self:FindWndTrans(AniRoot, "active")
		CS.ShowObject(AniRootActive, false)
	end
	if day and self._listItem[day] then
		local selItem = self._listItem[day]
		local AniRoot = self:FindWndTrans(selItem, "AniRoot")
		local AniRootActive = self:FindWndTrans(AniRoot, "active")
		CS.ShowObject(AniRootActive, true)
	end

	--local list = self:FindUIScroll("rewardList")
	--if list then
	--	list:DrawAllItems(false)
	--end
	self:RefreshGetBtnShow()
end

function UIAct172:OnClickGet()
	local entryCfg = self._dataList[self._curDay]
	if not entryCfg then
		return
	end

	local entryData = self:GetEntryData(entryCfg.entry.id)
	if not entryData then
		return
	end

	if entryData.MarketData.personal == 1 then
		GF.ShowMessage(ccClientText(40220))
		return
	end

	local moreInfo = JSON.decode(entryData.moreInfo).moreInfo
	local GetCondStr = string.split(moreInfo, "|")
	local giftDay = tonumber(GetCondStr[1])
	
	local questIndex = tonumber(GetCondStr[2])
	local questRef = self.questList[questIndex]
	local NeedMoney = 0
	if questRef then
		local conditionArr = string.split(questRef.condition,"=")
		NeedMoney = tonumber(conditionArr[3]) / 10
	end



	local dayCond = giftDay <= self.openDay
	if dayCond then
		if self.canGetEntryId == giftDay then
			local isFinish = false
			if self._pageQuestData then
				local entry = self._pageQuestData.entry
				if entry and #entry > 0 then
					local quesData = entry[questIndex]
					if quesData then
						isFinish = quesData.goalData.status == 1
					end
				else
					if LOG_INFO_ENABLED then
						printError("活动172","缺少第二页数据")
					end
				end
			else
				if LOG_INFO_ENABLED then
					printError("活动172","缺少第二页数据")
				end
			end
			if isFinish then
				self:ClickBuyBtn(entryData)
			else
				local str = string.replace(ccLngText(self.config.Tips), NeedMoney)
				GF.ShowMessage(str)
			end
		else
			GF.ShowMessage(ccClientText(44601))
		end
	else
		local str = ccClientText(16209)
		str = string.replace(str, entryCfg.entry.sort)
		GF.ShowMessage(str)
	end

end

function UIAct172:ClickBuyBtn(data)
	if self.endTime - GetTimestamp() < 0 then
		GF.ShowMessage(ccClientText(29200))
		return
	end
	if data.MarketData.expendType == UIAct172.TYPE_BUY_FREE then
		gModelActivity:OnActivityMarkeyBuyReq(self._sid, self.pageId, data.entryId)
	elseif data.MarketData.expendType == UIAct172.TYPE_BUY_ITEM then
		local item = LxDataHelper.ParseItem_4(data.MarketData.expend2)
		local name = gModelGeneral:GetCommonItemName(item)
		local func = function()
			if gModelGeneral:CheckItemEnough(item.itemId, item.itemNum, true, self:GetWndName()) then
				--gModelActivity:OnActivityMarkeyBuyReq(self.sid, UIAct172.PAGE_SIGN, data.entryId)
			end
		end
		local para =
		{
			refId = 50401,
			func = func,
			para = { item.itemNum .. name, data.title },
			consume = { item.itemNum, item.itemId },
		}
		gModelGeneral:OpenUIOrdinTips(para)
	elseif data.MarketData.expendType == 2 then
		if gLGameLanguage:IsChineseVersion()then
			if self:IsHasIosPackId(self.IOSpackId, true) then
				local TicketNum = gModelItem:GetNumByRefId(ModelItem.ITEM_GOLD_TICKET)
				local money = gModelPay:GetMoneyItemNeed(tonumber(data.MarketData.expend2))
				if TicketNum < money and money == 1 then
					GF.OpenWnd("UIAct172Tips")
					return
				end
			end
		end
		gModelPay:GiftPayCtrl(data.entryId, tonumber(data.MarketData.expend2), ModelPay.PAY_TYPE_ACTIVITY, nil, self._sid, UIAct172.PAGE_SIGN)
	end
end

function UIAct172:OnActivityPageResp(pb, ret)
	local sid = pb.sid
	if sid ~= self._sid then
		return
	end
	local cnt = 8
	self._pageData = nil
	for k, v in ipairs(pb.pages or {}) do
		local pageId = v.pageId
		if pageId == UIAct172.PAGE_SIGN then
			self._pageData = gModelActivity:GenerateActivePageDataFromPb(v)
			cnt = #self._pageData.entry
		elseif pageId == UIAct172.PAGE_QUEST then
			self._pageQuestData = gModelActivity:GenerateActivePageDataFromPb(v)
		end
	end
	if self._pageData then
		local actData = gModelActivity:GetActivityBySid(self._sid)
		local actMoreInfo = JSON.decode(actData.moreInfo)
		local openDay = actMoreInfo["openDay"] --- 开启天数
		self.openDay = openDay < cnt and openDay or cnt
		local moreInfo = JSON.decode(pb.pages[1].moreInfo)
		self.pageId = pb.pages[1].pageId
		self.canGetEntryId = moreInfo.giftRefId < self.openDay and moreInfo.giftRefId + 1 or self.openDay
		self._curDay = self.canGetEntryId
	end

	self:RefreshRewardList()
	self:RefreshGetBtnShow()
	self:CreateTimer()
end

function UIAct172:RefreshGetBtnShow()
	local entryCfg = self._dataList[self._curDay]
	if not entryCfg then
		return
	end

	local entryData = self:GetEntryData(entryCfg.entry.id)
	if not entryData then
		return
	end

	local str = ""
	local isGray = false
	local showGetTag = false

	local showDis = false
	if not string.isempty(entryCfg.entry.discount) then
		local discount = tonumber(entryCfg.entry.discount)
		if discount > 0  then
			local discountStr = string.replace(ccLngText(self.config.discountTxt), discount)
			self:SetTextTile(self.mDiscount, discountStr)
			showDis = true
		end
	end
	CS.ShowObject(self.mDiscount, showDis)

	local moreInfo = JSON.decode(entryData.moreInfo).moreInfo
	local GetCondStr = string.split(moreInfo, "|")
	local dayCond = tonumber(GetCondStr[1])
	local NeedVipExp = tonumber(GetCondStr[2])

	local serVipExp = gModelPlayer:GetVipExp()

	local expendType = entryCfg.entry.expendType
	local expend2 = entryCfg.entry.expend2

	if entryData.MarketData.personal == 1 then
		isGray = true
		str = ccClientText(40220)
	else
		if expendType == self.TYPE_BUY_FREE then
			str = ccClientText(46913)
		elseif expendType == self.TYPE_BUY_ITEM then

		elseif expendType == self.TYPE_BUY_RMB then
			--str = self:GetPayType(expendType, expend2)
			local money = gModelPay:GetMoneyItemNeed(tonumber(expend2))
			str = string.replace(self.descBtn,money)
		end
	end

	self:SetWndButtonText(self.mBtnGet, str)
	self:SetWndButtonGray(self.mBtnGet, isGray)

	--CS.ShowObject(self.mGetTag, showGetTag)
	--CS.ShowObject(self.mBtnGet, not showGetTag)

	--local redTran = CS.FindTrans(self.mBtnGet, "redPoint")
	--CS.ShowObject(redTran, status == 1)

	--if status ~= 1 then
	--	self:DestroyWndEffectByKey("btnEff")
	--end

end

function UIAct172:GetPayType(expendType,expend2)
	local txt,itemId
	local showIconImg = false
	if expendType == UIAct172.TYPE_BUY_FREE then
		txt = ccClientText(11913)
	elseif expendType == UIAct172.TYPE_BUY_ITEM then
		showIconImg = true
		local expend2Info =  string.split(expend2,"=")
		txt = expend2Info[3]
		itemId = tonumber(expend2Info[2])
	elseif expendType == UIAct172.TYPE_BUY_RMB then
		--local rmb = gModelPay:GetRMBValueByWelfareId(tonumber(expend2))
		txt = gModelPay:GetShowByWelfareId(tonumber(expend2)) --string.replace(ccClientText(21718),rmb)
	end
	return txt,showIconImg,itemId
end

function UIAct172:GetEntryData(entryId)
	if not self._pageData then
		return
	end

	return self._pageData:GetEntry(entryId)
end

function UIAct172:CreateTimer()
	self:ClearTimer()
	self:SetTimeStr()
	self.timer = LxTimer.LoopTimeCall(function()
		self:SetTimeStr()
	end, 1, false, -1)
end

function UIAct172:SetTimeStr()
	local curTime = self.endTime - GetTimestamp()
	if curTime > 0 then
		local str = string.replace(ccClientText(15610), LUtil.FormatTimeToCn3(curTime))
		self:SetWndText(self.mTimeText, str)
	else
		self:SetWndText(self.mTimeText, ccClientText(14301))
		self:ClearTimer()
	end
end

function UIAct172:ClearTimer()
	if self.timer then
		LxTimer.DelayTimeStop(self.timer)
		self.timer = nil
	end
end

function UIAct172:IsHasIosPackId(packId, defaultVal)
	if string.isempty(packId) then
		return defaultVal
	end

	local strs = string.split(packId, ";")
	local selfpackId = tostring(gModelActivity:GetPackageId())
	for k, v in ipairs(strs) do
		if v == selfpackId then
			return true
		end
	end

	return false
end

function UIAct172:OnTryTcpReconnect()
	gModelActivity:ReqActivityConfigData(self._sid)
end

------------------------------------------------------------------
return UIAct172



