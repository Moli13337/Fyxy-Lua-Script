---
--- Created by Administrator.
--- DateTime: 2023/10/2 11:33:39
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActDiaReturnGift:LWnd
local UIActDiaReturnGift = LxWndClass("UIActDiaReturnGift", LWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActDiaReturnGift:UIActDiaReturnGift()
	self._timeKey1 = "_timeKey1"
	self._timeKey2 = "_timeKey2"
	self._redPointIndex = "noPageRedPoint1"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActDiaReturnGift:OnWndClose()
	LWnd.OnWndClose(self)
	self:TimerStop(self._timeKey1)
	self:TimerStop(self._timeKey2)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActDiaReturnGift:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActDiaReturnGift:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitMessage()
	self:InitCommand()

	self:InitEvents()
end

function UIActDiaReturnGift:RefreshUI()
	local tabInfo = self._tablist[self._curType]


	local entryCfg2 = tabInfo.entryCfg2
	local entry1 = tabInfo.entry1
	local entry2 = tabInfo.entry2
	local entryCfg1 = tabInfo.entryCfg1

	local returnReward = string.split(entryCfg2.reward, "=")
	local rewIcon = gModelItem:GetItemImgByRefId(tonumber(returnReward[2]))
	if(rewIcon) then
		self:SetWndEasyImage(self.mImageCost, rewIcon)
	end
	self:SetWndText(self.mDayReturn, entryCfg2.name)
	self:SetWndText(self.mTxtDiaNum, returnReward[3])


	local btnLight = CS.FindTrans(self.mBuyBtn, "Light")
	local btnLightImage = CS.FindTrans(btnLight, "GameObject/Image")
	local btnLightTxt2 = CS.FindTrans(btnLight, "GameObject/Text2")
	local btnGray = CS.FindTrans(self.mBuyBtn, "Gray")
	local btnGraytImage = CS.FindTrans(btnGray, "GameObject/Image")
	local btnGrayTxt2 = CS.FindTrans(btnGray, "GameObject/Text2")
	local redPoint = CS.FindTrans(self.mBuyBtn, "redPoint")
	local isBuy = entry1.MarketData.personal > 0
	local buyBtnShow = true
	local redpointShow = false
	local getInstance = self.mBuyBtn:GetInstanceID()
	self:DestroyWndEffectByKey(getInstance)

	local curTime = GetTimestamp();
	if not isBuy then
		local expend2 = string.split(entryCfg1.expend2, "=")
		local icon = gModelItem:GetItemImgByRefId(tonumber(expend2[2]))
		self:SetWndText(btnLightTxt2, expend2[3])
		self:SetWndEasyImage(btnLightImage, icon)
		--self:SetWndButtonGray(self.mBuyBtn, false)
		self._rewardList = string.split(tabInfo.entryCfg1.reward, ",")
		self:TimerStop(self._timeKey2)
		CS.ShowObject(self.mTextTime2, false)
		CS.ShowObject(btnLightImage, true)
		if self._buyEndTime and self._buyEndTime < curTime then
			self:SetWndText(btnGrayTxt2, expend2[3])
			self:SetWndEasyImage(btnGraytImage, icon)
			self:SetWndButtonGray(self.mBuyBtn, true)
		else
			self:SetWndText(btnLightTxt2, expend2[3])
			self:SetWndEasyImage(btnLightImage, icon)
			self:SetWndButtonGray(self.mBuyBtn, false)
		end
	else
		self._rewardList = string.split(tabInfo.entryCfg2.reward, ",")
		local status2 = entry2.goalData.status

		if status2 == 0 then
			self:SetWndEasyImage(btnGraytImage, rewIcon)
			self:SetWndText(btnGrayTxt2, ccClientText(11205))
			CS.ShowObject(btnGraytImage, false)
			self:SetWndButtonGray(self.mBuyBtn, true)

			local moreInfo = JSON.decode(entry1.moreInfo)
			local moreInfo2 = JSON.decode(entry2.moreInfo)
			local buyKey = "buyTime_"..entry1.entryId
			self._getReturnRewardTime = LUtil.GetNextDayTimes(tonumber(moreInfo[buyKey])/1000, tonumber(moreInfo2.moreInfo))
			local timeKey2 = self._timeKey2
			self:TimerStop(timeKey2)
			self:TimerStart(timeKey2, 1, false, -1)
			self:SetGetTime()
		elseif status2 == 1 then
			self:SetWndEasyImage(btnLightImage, rewIcon)
			self:SetWndText(btnLightTxt2, ccClientText(11205))
			CS.ShowObject(btnLightImage, false)
			self:SetWndButtonGray(self.mBuyBtn, false)
			redpointShow = true
			self:TimerStop(self._timeKey2)
			CS.ShowObject(self.mTextTime2, false)
			self:CreateWndEffect(self.mBuyBtn, 'fx_anniu_01', getInstance, 100, false)
		else
			self:TimerStop(self._timeKey2)
			CS.ShowObject(self.mTextTime2, false)
			buyBtnShow = false
		end
	end

	self:InitRewardList()
	CS.ShowObject(self.mBuyBtn, buyBtnShow)
	CS.ShowObject(self.mGetImg, not buyBtnShow)
	CS.ShowObject(redPoint, redpointShow)
end

function UIActDiaReturnGift:InitList()
	local tablist = self._tablist
	if(self._uiTablist) then
		self._uiTablist:RefreshList(tablist)
	else
		self._uiTablist = self:GetUIScroll("_uiTablist")
		self._uiTablist:Create(self.mTabScroll,tablist,function (...) self:OnDrawTabItem(...) end,UIItemList.NORMAL)
		--self._uiRewardList:EnableScroll(false,false)
	end
end

function UIActDiaReturnGift:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
	self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:RefreshRed() end)
	--self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
	--	local activity = pb.activity
	--	if activity.sid ~= self._sid then return end
	--	self:RefreshData()
	--end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)
		local actData = gModelActivity:GetActivityBySid(self._sid)
		if not actData or actData.status == 3 then
			self:WndClose()
		end
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_JUMP, function(...) self:WndClose() end)
end

function UIActDiaReturnGift:SetGetTime()
	local _timeKey2 = self._timeKey2
	local time = GetTimestamp()
	local endTime = self._getReturnRewardTime
	if not endTime or endTime < time then
		self:TimerStop(_timeKey2)
		CS.ShowObject(self.mTextTime2, false)
		self:ReqPageData()
		return
	end
	local timespan = endTime - time
	local timeStr = LUtil.FormatTimespanDetail(timespan)
	--self:SetWndText(self.mTextTime2, "领取倒计时:"..timeStr)
	self:SetWndText(self.mTextTime2, string.replace(self._txt1, timeStr))
	CS.ShowObject(self.mTextTime2, true)
end

function UIActDiaReturnGift:SetActivityTime()
	local _timeKey = self._timeKey1
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	--local endTime = activityData.endTime
	local endTime = self._buyEndTime
	if endTime == 0 then
		self:TimerStop(_timeKey)
		self:SetWndText(self.mTimeText,ccClientText(18404))
		CS.ShowObject(self.mTimeBg,true)
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
	self:SetWndText(self.mTimeText1,timeStr)
	CS.ShowObject(self.mTimeBg,true)
end

function UIActDiaReturnGift:OnBuyBtnClick()
	local tabInfo = self._tablist[self._curType]
	local entryCfg2 = tabInfo.entryCfg2
	local entry1 = tabInfo.entry1
	local entry2 = tabInfo.entry2
	local entryCfg1 = tabInfo.entryCfg1
	local isBuy = entry1.MarketData.personal > 0
	if not isBuy then
		local buyEndTime = self._buyEndTime
		if buyEndTime and buyEndTime < GetTimestamp() then
			GF.ShowMessage(self._txt8)
			return
		end
		local expend2 = string.split(entryCfg1.expend2, "=")

		local isEnough = gModelGeneral:CheckItemEnough(tonumber(expend2[2]), tonumber(expend2[3]), true)
		if not isEnough then
			return
		end
		local func = function()
			gModelActivity:OnActivityMarkeyBuyReq(self._sid, ModelActivity.DiaReturnGift_1, entry1.entryId)
		end
		local costName = gModelItem:GetNameByRefId(tonumber(expend2[2]))
		local costStr = expend2[3]..costName
		local goodName = entryCfg1.name
		local para = {costStr, goodName}
		GF.OpenWnd("UIOrdinTip", {refId=361001, para = para, func = func})
	else
		local status = entry2.goalData.status
		local canGetReward = false
		if status == 0 then
			local endTime = self._getReturnRewardTime
			local time = GetTimestamp()
			if not endTime or time > endTime then
				canGetReward = true
			else
				local timespan = endTime - time
				local timeStr = LUtil.FormatTimespanDetail(timespan)
				local txt3 = self._txt3
				GF.ShowMessage(string.replace(txt3, timeStr))
			end

		elseif status == 1 then
			canGetReward = true
		end
		if canGetReward then
			gModelActivity:OnActivityReceiveGoalReq(self._sid, ModelActivity.DiaReturnGift_2, entry2.entryId)
		end
	end
end

function UIActDiaReturnGift:OnTimer(key)
	if(key == self._timeKey1)then
		self:SetActivityTime()
	elseif key == self._timeKey2 then
		self:SetGetTime()
	end
end

function UIActDiaReturnGift:InitEvents()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mCloseBtn, function(...) self:WndClose() end)
	self:SetWndClick(self.mBuyBtn, function ()
		self:OnBuyBtnClick()
	end)
	self:SetWndClick(self.mHelpBtn, function ()
		if not self._actData or not self._txt7 then
			return
		end
		local actName = self._actData.title
		local content = self._txt7
		GF.OpenWnd("UIBzTips", {title=actName, text=content})
	end)
end

function UIActDiaReturnGift:OnActivityConfigData()
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityData then
		return
	end
	local data = activityData.config
	self._txt1 = data.txt1
	self._txt2 = data.txt2
	self._txt3 = data.txt3
	self._txt4 = data.txt4
	self._txt7 = data.txt7
	self._txt8 = data.txt8

	local txt5, txt6, day = data.txt5, data.txt6, data.day

	self:SetWndText(self.mTitleText, txt5)
	self:SetWndText(self.mTitleText2, txt6)

	self:SetWndText(self.mTextTip, data.txt4)

	local buyEndTime = LUtil.GetNextDayTimes(self._actData.startTime, day)
	self._buyEndTime = buyEndTime

	--local endTime = self._actData.endTime
	if buyEndTime and buyEndTime ~= -1 then
		local timeKey1 = self._timeKey1
		self:TimerStop(timeKey1)
		self:TimerStart(timeKey1, 1, false, -1)
		self:SetActivityTime()
	end
end

function UIActDiaReturnGift:OnDrawTabItem(list,item, itemdata, itempos)
	local BtnTab1 = CS.FindTrans(item, "BtnTab1")
	local onObj = CS.FindTrans(BtnTab1, "On")
	local onText = CS.FindTrans(onObj, "Text")
	local offObj = CS.FindTrans(BtnTab1, "Off")
	local offText = CS.FindTrans(offObj, "Text")
	local redpoint = CS.FindTrans(item, 'redPoint')

	local entryCfg1 = itemdata.entryCfg1
	self:SetWndText(onText, entryCfg1.name)
	self:SetWndText(offText, entryCfg1.name)

	self:SetWndClick(BtnTab1, function ()
		self:onClickTab(entryCfg1.id)
	end)

	local state = entryCfg1.id == self._curType and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(BtnTab1,state)

	self._tabBtnList[entryCfg1.id] = item

	local entry2 = itemdata.entry2
	local red = entry2.goalData.status == 1
	CS.ShowObject(redpoint, red)
end

function UIActDiaReturnGift:InitCommand()
	local _sid = self:GetWndArg("sid")
	if not _sid then
		local dataList = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_ACTIVITY_TYPE_123)
		if dataList[1] then
			_sid = dataList[1].sid
		else
			return
		end
	end
	self._sid = _sid
	self._actData = gModelActivity:GetActivityBySid(_sid)
	gModelActivity:ReqActivityConfigData(_sid)

	local redPointIndex = self._redPointIndex
	--local red = gModelRedPoint:GetActivityRedPointIndex(_sid, redPointIndex)
	local red = gModelRedPoint:GetActivityRedPointPage(_sid, ModelActivity.DiaReturnGift_1)
	if red then
		gModelActivity:OnActivitySpecialOpReq(_sid, ModelActivity.DiaReturnGift_1, nil, ModelActivity.CANCEL_RED_POINT, "1")
	end
end

function UIActDiaReturnGift:onClickTab(entryId)
	if self._curType == entryId then
		return
	end

	local oldSelect = self._curType
	if oldSelect==-1 then
		for k,v in pairs(self._tabBtnList) do
			local BtnTab1 = self:FindWndTrans(v,"BtnTab1")
			self:SetWndTabStatus(BtnTab1,LWnd.StateOff)
		end
	else
		local oldSelectItem = self._tabBtnList[oldSelect]
		if oldSelectItem then
			local BtnTab1 = self:FindWndTrans(oldSelectItem,"BtnTab1")
			self:SetWndTabStatus(BtnTab1,LWnd.StateOff)
		end
	end
	self._curType = entryId
	--self:SaveWndArg()
	local newSelectItem = self._tabBtnList[entryId]
	if newSelectItem then
		local BtnTab1 = self:FindWndTrans(newSelectItem,"BtnTab1")
		self:SetWndTabStatus(BtnTab1,LWnd.StateOn)
	end

	self:RefreshUI()
end

function UIActDiaReturnGift:RefreshRed()

end

function UIActDiaReturnGift:InitData()
	self._tabBtnList = {}
	self._commonIconTbl = {}
end

function UIActDiaReturnGift:OnDrawRewardItem(list, item, itemdata, itempos)
	local itemBg=CS.FindTrans(item,"Image")
	local icon=CS.FindTrans(itemBg,"Icon")
	local itemNum=CS.FindTrans(itemBg,"ItemNum")
	local eff = CS.FindTrans(itemBg, "Eff")


	--self:SetWndEasyImage(itemBg, "privilege1_star_".."1")
	--CS.ShowObject(itemBg, false)
	local tabInfo = self._tablist[self._curType]
	local entryCfg2 = tabInfo.entryCfg2
	local entry1 = tabInfo.entry1
	local entry2 = tabInfo.entry2
	local entryCfg1 = tabInfo.entryCfg1
	local isBuy = entry1.MarketData.personal > 0
	local effName = "";

	if isBuy then
		effName = "fx_ui_zhongshentequan_1"
	else
		effName = "fx_ui_zhongshentequan_2"
	end

	local instanceId = eff:GetInstanceID()
	self:DestroyWndEffectByKey(instanceId)
	self:CreateWndEffect(eff, effName, instanceId, 80, false)


	local reward = string.split(itemdata, "=")
	--local itemIcon =
	self:SetWndText(itemNum, LUtil.NumberCoversion(tonumber(reward[3])))
	local rewardType = tonumber(reward[1])
	local iconPath = ""
	if rewardType == LItemTypeConst.TYPE_ITEM then --道具
		iconPath = gModelItem:GetItemImgByRefId(tonumber(reward[2]))
	elseif rewardType == LItemTypeConst.TYPE_HERO then --英雄
		iconPath = gModelHero:GetHeroImgByRefId(tonumber(reward[2]))
	elseif rewardType == LItemTypeConst.TYPE_EQUIP then--装备
		iconPath = gModelEquip:GetEquipImgByRefId(tonumber(reward[2]))
	elseif rewardType == LItemTypeConst.TYPE_RUNE then--符文
		iconPath = gModelRune:GetRuneImgByRefId(tonumber(reward[2]))
	end

	self:SetWndEasyImage(icon, iconPath)

	--local instanceId = icon:GetInstanceID()
	--		--奖励图标
	--local baseClass = self._commonIconTbl[instanceId]
	--if not baseClass then
	--	baseClass = CommonIcon:New()
	--	self._commonIconTbl[instanceId] = baseClass
	--	baseClass:Create(icon)
	--end
	--baseClass:SetCommonReward(tonumber(reward[1]), tonumber(reward[2]) , tonumber(reward[3]))
	----baseClass:EnableShowNum(false)
	--baseClass:DoApply()


	local rewardData = {
		itemId = tonumber(reward[2]),
		itemType = tonumber(reward[1]),
		count = tonumber(reward[3])
	}
	self:SetWndClick(icon,function()
		gModelGeneral:ShowCommonItemTipWnd(rewardData)
	end)
end

function UIActDiaReturnGift:ResetData(pb)
	local sid = pb.sid
	if(self._sid ~= sid)then
		return
	end

	local activityData = gModelActivity:GetWebActivityDataById(sid)
	if not activityData then
		return
	end
	local chunks = activityData.chunk

	local tablist = self._tablist or {}

	local notBuyEntryId
	local redEntryId
	local minEntryId
	for i,v in ipairs(pb.pages) do
		if v.pageId == ModelActivity.DiaReturnGift_1 then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			for j,k in ipairs(page.entry) do
				local entryId = k.entryId
				local entryCfg = chunks[v.pageId].entries[entryId]
				if tablist[entryId] then
					tablist[entryId].entry1 = k
					tablist[entryId].entryCfg1 = entryCfg
				else
					table.insert(tablist, {entry1=k, entryCfg1=entryCfg})
				end
				if not notBuyEntryId and k.MarketData.personal == 0 then
					notBuyEntryId = k.entryId
				end
			end
		elseif v.pageId == ModelActivity.DiaReturnGift_2 then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			for j,k in ipairs(page.entry) do
				local entryId = k.entryId
				local entryCfg = chunks[v.pageId].entries[entryId]
				if tablist[entryId] then
					tablist[entryId].entry2 = k
					tablist[entryId].entryCfg2 = entryCfg
				else
					table.insert(tablist, {entry2=k, entryCfg2=entryCfg})
				end
				if not redEntryId and k.goalData.status == 1 then
					redEntryId = k.entryId
				elseif not minEntryId and k.goalData.status == 0 then
					minEntryId = k.entryId
				end
			end
		end
	end
	local len = #tablist
	if len == 0 then
		self:WndClose()
		return
	end
	self._tablist = tablist
	if redEntryId then
		self._curType = redEntryId
	elseif notBuyEntryId then
		self._curType = notBuyEntryId
	elseif minEntryId then
		self._curType = minEntryId
	else
		self._curType = tablist[1].entryCfg1.id
	end
	--self._curType = tablist[1].entryCfg1.id
	self:InitList()
	self:RefreshUI()
end

function UIActDiaReturnGift:InitRewardList()
	local rewardlist = self._rewardList
	local rewNum = #rewardlist

	local list = self.mRewardScroll
	if rewNum > 3 then
		list = self.mRewardScroll2
	end
	CS.ShowObject(self.mRewardScroll, rewNum <= 3)
	CS.ShowObject(self.mRewardScroll2, rewNum > 3)
	local key = list:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if(uiList) then
		uiList:RefreshList(rewardlist)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(list,rewardlist,function (...) self:OnDrawRewardItem(...) end)
		uiList:EnableScroll(true,true)
	end
end

function UIActDiaReturnGift:ReqPageData()
	gModelActivity:OnActivityPageReq(self._sid)
end

------------------------------------------------------------------
return UIActDiaReturnGift


