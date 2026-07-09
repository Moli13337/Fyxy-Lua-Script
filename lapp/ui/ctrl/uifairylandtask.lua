---
--- Created by Administrator.
--- DateTime: 2021/1/11 16:35:03
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFairylandTask:LWnd
local UIFairylandTask = LxWndClass("UIFairylandTask", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFairylandTask:UIFairylandTask()
	self:SetHideHurdle()

	---@type table<number, CommonIcon>
	self._commonIconTbl = {}

	self._curTargetTaskData = nil
	self._curAccumulateData = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFairylandTask:OnWndClose()
	self:ClearEffectKeyList()
	self:ClearCommonIconList(self._commonIconTbl)
	self._commonIconTbl = nil

	if self._uiRewardList then
		self._uiRewardList:OnWndClose()
	end

	if self._uiTaskList then
		self._uiTaskList:OnWndClose()
	end
	if self._uiLimitList then
		self._uiLimitList:OnWndClose()
	end

	self._curTargetTaskData = nil
	self._curAccumulateData = nil

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFairylandTask:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFairylandTask:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndPara()
	self:InitPara()
	self:InitEvent()
	self:InitMsg()
	self:InitData()

	self:SetWndText(self.mBoxDesc, ccClientText(18706))
end

function UIFairylandTask:OnDrawTaskItem(list, item, itemdata, itempos)
	local bgTrans = CS.FindTrans(item,"Bg")
	if not bgTrans then return end

	local iconTrans = CS.FindTrans(bgTrans,"CommonUI/Icon")
	local titleTextTrans = CS.FindTrans(bgTrans,"TitleText")
	local numTextTrans = CS.FindTrans(bgTrans,"NumText")
	local goIconTrans = CS.FindTrans(bgTrans,"GoIcon")
	local goText = CS.FindTrans(goIconTrans,"Text")
	local getIconTrans = CS.FindTrans(bgTrans,"GetIcon")
	local getText = CS.FindTrans(getIconTrans,"Text")
	local redPoint = CS.FindTrans(bgTrans,"redPoint")
	local maskTrans = CS.FindTrans(bgTrans,"Mask")

	local entryId	= itemdata.entryId				--当前条目的流水id
	local goalData 	= itemdata.goalData
	local status   	= goalData.status				--状态(0-不可领取, 1-可领取，2-已领取)
	local schedules = goalData.schedules[1]			--任务进度列表,一个条目可能由多个完成条件组合成
	local schedule 	= tonumber(schedules.schedule)  --当前进度
	local goal 		= tonumber(schedules.goal)      --目标进度
	local itemData 	= itemdata.items[1]				--道具信息，默认只有1个

	local instanceId = item:GetInstanceID()
	local itype,refId,num,effect = itemData.itemType,itemData.itemId,itemData.itemNum,itemData.isShowEff
	local numStr = string.replace(ccClientText(18722), schedule, goal)

	--奖励图标
	local baseClass = self._commonIconTbl[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._commonIconTbl[instanceId] = baseClass
		baseClass:Create(iconTrans)
	end
	baseClass:SetCommonReward(itype, refId , num)
	--baseClass:EnableShowNum(false)
	baseClass:DoApply()

	--设置道具特效
	local effTrans = self:FindWndTrans(item,"CommonUI/Eff")
	local show = effect ~= false
	if show and itype == LItemTypeConst.TYPE_ITEM then
		LxResUtil.DestroyChildImmediate(effTrans)
		local itemRef = gModelItem:GetRefByRefId(refId)
		local bgEff = itemRef and itemRef.bgEff or nil
		show = not string.isempty(bgEff)
		if show then
			local key = "DrawTaskItem"..tostring(entryId)..instanceId
			table.insert(self._effectKeyList,key)
			self:CreateWndEffect(effTrans,bgEff,key,100,false,false)
		end
	end
	CS.ShowObject(effTrans,show)

	self:SetIconClickScale(iconTrans, true)
	self:SetWndClick(iconTrans,function()
		local data = {itemId = refId,itemType = itype,itemNum = num}
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)

	local taskFrameIcon = self._cfgDataMoreInfo.taskFrameIcon
	if taskFrameIcon and taskFrameIcon ~= "" then
		self:SetWndEasyImage(bgTrans, taskFrameIcon)
	end
	self:SetWndText(titleTextTrans, itemdata.title)
	self:SetWndText(numTextTrans, numStr)

	local btnStr
	local iconText
	local isShowRed = false
	local isShowGray = false
	if status == 0 then
		btnStr = self._btnStr.GO
		iconText   = goText
	elseif status == 1 then
		btnStr = self._btnStr.GET
		isShowRed  = true
		iconText   = getText
	else
		--btnStr = self._btnStr.COMPONENT
		isShowGray = true
	end

	if iconText then
		self:SetWndText(iconText, btnStr)
	end

	CS.ShowObject(goIconTrans, not isShowRed)
	CS.ShowObject(getIconTrans, isShowRed)
	CS.ShowObject(redPoint, isShowRed)
	CS.ShowObject(maskTrans, isShowGray)

	self:SetWndClick(bgTrans, function()
		if status == 0 then
			local jumpId = tonumber(itemdata.jumpId)
			local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId,true)
			if not isOpen then return end

			gModelFunctionOpen:Jump(jumpId, self:GetWndName())
		elseif status == 1 then
			gModelActivity:OnActivityReceiveGoalReq(self._sid, self._pageId,entryId)
		elseif status == 2 then
			GF.ShowMessage(ccClientText(18728))
		end
	end)

	self:InitTextLineWithLanguage(titleTextTrans,-30)
end

--####################################################################################################################
--### Server #########################################################################################################
--####################################################################################################################
function UIFairylandTask:OnActivityResp(pb,ret)
	if self._sid ~= pb.sid then return end

	gModelActivity:OnActivityPageReq(self._sid)
	self:SetTop()
end

function UIFairylandTask:InitLimitListNoBox()
	CS.ShowObject(self.mTaskList, false)
	CS.ShowObject(self.mLimitList, true)

	self:ClearEffectKeyList()
	local uiList = self._uiLimitList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mLimitList)
		uiList:EnableScroll(true,false)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawTaskItem(...)
		end)
		self._uiLimitList = uiList
		uiList:ClearAllLoadAnimation()
		uiList:EnableLoadAnimation(true, 0.04, 3, 2)
		uiList:SetLoadAnimationScale(nil, 0.04)
	end
	uiList:RemoveAll()

	--添加信息
	local curType = self._moreInfoType.LIMIT
	if not self._activityPageData then return end
	local data = self._activityPageData[curType]
	if not data then return end

	for i,v in ipairs(data) do
		uiList:AddData(i,v)
	end

	uiList:RefreshList(UIListWrap.RefreshMode.Solid)
end

function UIFairylandTask:InitGiftBox()
	local isLimit = self._openView == self._btnEnum.LIMIT
	local giftIconPath = isLimit and self._cfgDataMoreInfo.taskRechargeIcon or self._cfgDataMoreInfo.taskTargetIcon

	self:SetWndEasyImage(self.mGiftIcon, giftIconPath)
	CS.ShowObject(self.mBoxDescBg, isLimit)
	self:SetWndClick(self.mGiftIcon, function()
		if not isLimit then return end
		GF.OpenWnd("UIFairylandAccumulate", {sid = self._sid})
	end)
end

function UIFairylandTask:CloseWndFunc()
	local func = self:GetWndArg("closeFunc")
	if func then
		func()
	else
		GF.OpenWnd("UIFairylandMain",{sid = self._sid})
		local mainActivityData = gModelActivity:GetActivityBySid(self._sid)
		if mainActivityData then
			gLxTKData:OnMainUIActivityClick(mainActivityData)
		end
	end

	self:WndClose()
end

--#####################################################################################################################
--## RedPoint #########################################################################################################
--#####################################################################################################################
function UIFairylandTask:CheckTaskTabRedPoint()
	local goalData
	local status
	local targetData = self._curTargetTaskData or self:GetTargetTaskData()
	if targetData then
		goalData 		= targetData.goalData
		status   		= goalData.status				--状态(0-不可领取, 1-可领取，2-已领取)
		if status == 1 then
			return true
		end
	end

	local curType = self._moreInfoType.COMMON
	local taskData = self._activityPageData[curType]
	if taskData then
		for k,v in ipairs(taskData) do
			goalData 	= v.goalData
			status   	= goalData.status				--状态(0-不可领取, 1-可领取，2-已领取)
			if status == 1 then
				return true
			end
		end
	end

	return false
end

function UIFairylandTask:SetTabBtnRedPoint(btnTrans, index)
	local redPoint = CS.FindTrans(btnTrans, "redPoint")
	local isShowRed
	if index == self._btnEnum.COMMON then
		isShowRed = self:CheckTaskTabRedPoint()
	elseif index == self._btnEnum.LIMIT then
		isShowRed = self:CheckLimitTabRedPoint()
	end

	CS.ShowObject(redPoint, isShowRed or false)
end
--####################################################################################################################
--### TaskList #######################################################################################################
--####################################################################################################################
function UIFairylandTask:InitTaskList()
	CS.ShowObject(self.mTaskList, true)
	CS.ShowObject(self.mLimitList, false)

	self:ClearEffectKeyList()
	local uiList = self._uiTaskList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mTaskList)
		uiList:EnableScroll(true,false)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawTaskItem(...)
		end)
		self._uiTaskList = uiList
		uiList:ClearAllLoadAnimation()
		uiList:EnableLoadAnimation(true, 0.04, 3, 2)
		uiList:SetLoadAnimationScale(nil, 0.04)
	end
	uiList:RemoveAll()

	--添加任务信息
	local curType
	if self._openView == self._btnEnum.COMMON then
		curType = self._moreInfoType.COMMON
	else
		curType = self._moreInfoType.LIMIT
	end
	local taskData = self._activityPageData[curType]
	if not taskData then return end

	for i,v in ipairs(taskData) do
		uiList:AddData(i,v)
	end

	uiList:RefreshList(UIListWrap.RefreshMode.Solid)
end

function UIFairylandTask:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP,function () self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb) self:OnActivityPageResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityReceiveGoalResp, function(...)
		self:OnActivityReceiveGoalResp(...)
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function ()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
end

--####################################################################################################################
--### GiftContent ####################################################################################################
--####################################################################################################################
function UIFairylandTask:InitGiftContent()
	local hideGift = self._hideGift
	CS.ShowObject(self.mPattern, not hideGift)
	CS.ShowObject(self.mGiftContent, not hideGift)
	if hideGift then return end

	self:InitGiftBox()

	self._curTargetTaskData = nil
	self._curAccumulateData = nil
	if self._openView == self._btnEnum.COMMON then
		self._curTargetTaskData = self:GetTargetTaskData()
	else
		self._curAccumulateData = self:GetAccumulateData()
	end

	self:RefreshProgress()
	self:RefreshReward()
end

function UIFairylandTask:OnDrawGiftItem(list, item, itemdata, itempos)
	local iconTrans = CS.FindTrans(item,"CommonUI/Icon")
	local effTrans = self:FindWndTrans(item,"Eff")
	local itype,refId,num,effect = itemdata.itemType,itemdata.itemId,itemdata.itemNum,itemdata.isShowEff
	local instanceId = item:GetInstanceID()
	local baseClass = self._commonIconTbl[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._commonIconTbl[instanceId] = baseClass
		baseClass:Create(iconTrans)
	end
	baseClass:SetCommonReward(itype, refId , num)
	--baseClass:EnableShowNum(false)
	baseClass:DoApply()

	--设置道具特效
	local show = effect ~= false
	if show and itype == LItemTypeConst.TYPE_ITEM then
		LxResUtil.DestroyChildImmediate(effTrans)
		local itemRef = gModelItem:GetRefByRefId(refId)
		local bgEff = itemRef and itemRef.bgEff or nil
		show = not string.isempty(bgEff)
		if show then
			local key = "DrawTaskItem"..instanceId
			table.insert(self._effectKeyList,key)
			self:CreateWndEffect(effTrans,bgEff,key,54,false,false)
		end
	end
	CS.ShowObject(effTrans,show)

	self:SetIconClickScale(iconTrans, true)
	self:SetWndClick(iconTrans,function()
		local data = {itemId = refId,itemType = itype,itemNum = num}
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
end

function UIFairylandTask:ResetActivePageData(pb)
	local pageData
	local accumulateData
	for i, v in ipairs(pb.pages) do
		if v.pageId == self._pageId then
			local page= gModelActivity:GenerateActivePageDataFromPb(v)
			if page then
				pageData = page
			end
		elseif v.pageId == self._pageAccumulateId then
			accumulateData = gModelActivity:GenerateActivePageDataFromPb(v)
		end
	end
	--任务数据
	if pageData then
		self._activityPageData = {}
		for k,v in ipairs(pageData.entry) do
			local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
			if not entryCfg then
				return
			end

			local moreInfo = JSON.decode(v.moreInfo)
			local taskTypeList = string.split(moreInfo.moreInfo, ';')
			local taskType = tonumber(taskTypeList[1])
			local goalData 		= v.goalData
			local status   		= goalData.status

			local data = {
				entryId = v.entryId,
				title   = entryCfg.name,
				desc	= entryCfg.description,
				icon	= entryCfg.icon,
				items	= LxDataHelper.ParseItem(entryCfg.reward),
				marketData = v.MarketData,
				sort	= entryCfg.sort,
				goalData = goalData,
				status  = status,
				jumpId 	= moreInfo.jumpId,
				taskType = taskType,
			}

			local curTaskData = self._activityPageData[taskType]
			if not curTaskData then
				self._activityPageData[taskType] = {}
			end

			table.insert(self._activityPageData[taskType], data)
		end

		for k,v in pairs(self._activityPageData) do
			table.sort(v,function(ref1,ref2)
				local status1 = ref1.status
				local status2 = ref2.status
				if status1 ~= status2 then --状态(0-不可领取, 1-可领取，2-已领取)
					if status1 == 1 or status2 == 1 then
						return status1 == 1
					end

					return status1 < status2
				end

				return ref1.sort < ref2.sort
			end)
		end
	end

	if accumulateData then
		--累积充值数据
		self._activityPageAccumulateData = {}
		for k,v in ipairs(accumulateData.entry) do
			local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
			if not entryCfg then
				return
			end

			local goalData = v.goalData
			local status   = goalData.status

			local data = {
				entryId = v.entryId,
				title   = entryCfg.name,
				desc	= entryCfg.description,
				icon	= entryCfg.icon,
				items	= LxDataHelper.ParseItem(entryCfg.reward),
				marketData = v.MarketData,
				moreInfo = v.moreInfo,
				sort	= entryCfg.sort,
				goalData = goalData,
				status  = status,
			}
			table.insert(self._activityPageAccumulateData, data)
		end
	end
end

function UIFairylandTask:InitData()
	gModelActivity:ReqActivityConfigData(self._sid)
end


function UIFairylandTask:OnActivityPageResp(pb,ret)
	if self._sid ~= pb.sid then return end

	self:ResetActivePageData(pb)
	self:ViewCtrl()
end

function UIFairylandTask:SetWndPara()
	self._openView = self:GetWndArg("page") or 1 			-- 页面
	self._subPage = self:GetWndArg("subPage")				-- 礼包
end

function UIFairylandTask:GetTargetTaskData()
	local moreInfoType = self._moreInfoType.COMMON_TARGET
	local pageData = self._activityPageData[moreInfoType]
	if not pageData then
		LogError("self._activityPageData[moreType] is not find, moreType = "..(moreInfoType or nil))
		return {}
	end

	return pageData[1] or {}
end

function UIFairylandTask:RefreshProgress()
	local titleStr
	local goalData
	local status
	local schedules
	local curValue
	local maxValue
	local isShowGray
	local btnStr
	local jumpId
	local canGet
	local haveGet
	local entryId
	if self._openView == self._btnEnum.COMMON then
		--每日目标任务
		titleStr = self._curTargetTaskData.title
		entryId			= self._curTargetTaskData.entryId --当前条目的流水id
		goalData 		= self._curTargetTaskData.goalData
		status   		= goalData.status				--状态(0-不可领取, 1-可领取，2-已领取)
		schedules 		= goalData.schedules[1]			--任务进度列表,一个条目可能由多个完成条件组合成
		curValue 		= tonumber(schedules.schedule)  --当前进度
		maxValue 		= tonumber(schedules.goal)      --目标进度
		canGet			= status == 1
		haveGet			= status == 2
		if canGet then
			btnStr = ccClientText(18707)
		elseif haveGet then
			btnStr = ccClientText(18710)
		else
			btnStr = ccClientText(18708)
		end

		isShowGray 		= not canGet
	else
		if self._curAccumulateData == nil then
			return
		end

		--累计充值
		local accumulateData = self._curAccumulateData
		titleStr 		= accumulateData.title
		entryId	 		= accumulateData.entryId --当前条目的流水id
		goalData 		= accumulateData.goalData
		status   		= goalData.status				--状态(0-不可领取, 1-可领取，2-已领取)
		schedules 		= goalData.schedules[1]			--任务进度列表,一个条目可能由多个完成条件组合成
		local moreInfo  = JSON.decode(accumulateData.moreInfo)
		curValue 		= tonumber(schedules.schedule)  --当前进度
		maxValue 		= tonumber(schedules.goal)      --目标进度
		canGet			= status == 1
		haveGet			= status == 2
		if canGet then
			btnStr = ccClientText(18707)
		elseif haveGet then
			btnStr = ccClientText(18710)
		else
			btnStr = moreInfo.jumpDesc
		end

		isShowGray  = haveGet
		jumpId		= tonumber(moreInfo.jumpId)
	end

	if self._isForeign then
		self:SetWndText(self.mDescEn, titleStr)
	else
		self:SetWndText(self.mDesc, titleStr)
	end
	CS.ShowObject(self.mBoxTitle, not self._isForeign)
	CS.ShowObject(self.mBoxTitleEn, self._isForeign)

	local sliderFormat = self._sliderFormat[self._openView]
	local valueStr =  ccClientText(18767, curValue, maxValue) --string.replace(sliderFormat, curValue, maxValue)
	--if curValue >= maxValue then
	--	valueStr = LUtil.FormatColorStr(valueStr,"green")
	--end

	self:SetWndText(self.mProgressValue, valueStr)

	local percentage = curValue / maxValue
	LxUiHelper.SetProgress(self.mSlider,percentage)

	CS.ShowObject(self.mGiftBtnYellow, canGet)
	CS.ShowObject(self.mGiftBtnBlue, not canGet)
	CS.ShowObject(self.mGiftBtnRedPoint, canGet)
	local giftBtnTrans =  canGet and self.mGiftBtnYellow or self.mGiftBtnBlue
	self:SetWndButtonGray(giftBtnTrans, isShowGray)
	self:SetWndButtonText(giftBtnTrans, btnStr)

	self:SetWndClick(giftBtnTrans, function()
		if canGet then
			if self._openView == self._btnEnum.COMMON then
				gModelActivity:OnActivityReceiveGoalReq(self._sid, self._pageId,entryId)
			else
				gModelActivity:OnActivityReceiveGoalReq(self._sid, self._pageAccumulateId,entryId)
			end
		elseif haveGet then
			GF.ShowMessage(ccClientText(18728))
		elseif jumpId then
			local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId,true)
			if not isOpen then return end
			gModelFunctionOpen:Jump(jumpId, self:GetWndName())
		else
			GF.ShowMessage(ccClientText(18708))
		end
	end)
end

function UIFairylandTask:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end
	self:SetTop()
	gModelActivity:OnActivityPageReq(self._sid)
end


function UIFairylandTask:OnActivityReceiveGoalResp(pb,ret)
	--if self._sid ~= pb.sid or self._pageId ~= pb.pageId then return end
    --
	--
	--local index = self._entryIdToIndex[pb.entryId]
	--if not index then return end
	--local list = self._uiTaskList:GetList()
	--local data = list:GetDataByIndex(index)
	--data.state = 2
	--list:DrawItemByIndex(index)
end

function UIFairylandTask:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:CloseWndFunc() end)
	for i,v in ipairs(self._btnList) do
		self:SetWndClick(v,function()
			if self._openView == i then return end
			self._openView = i
			self:ViewCtrl()
		end)
	end

	self:SetWndClick(self.mDrawBtn,function()
		GF.OpenWndBottom("UIFlandDraw",{
			sid = self._sid,
		})
		self:WndClose()
	end)
end

--####################################################################################################################
--### Page ###########################################################################################################
--####################################################################################################################
function UIFairylandTask:ViewCtrl()
	self._hideGift = self._openView == self._btnEnum.LIMIT and self._cfgDataMoreInfo.accumulateRecharge == 0
	self:InitGiftContent()

	if not self._hideGift then
		self:InitTaskList()
	else
		self:InitLimitListNoBox()
	end

	for i,v in ipairs(self._btnList) do
		local bSel = i == self._openView
		self:SetWndTabStatus(v, bSel and LWnd.StateOn or LWnd.StateOff)
		self:SetTabBtnRedPoint(v, i)
	end
end
--####################################################################################################################
--### Common #########################################################################################################
--####################################################################################################################
function UIFairylandTask:SetTop()
	if not self._cfgDataMoreInfo then
		local webData = gModelActivity:GetWebActivityDataById(self._sid)
		if not webData then
			return
		end

		self._cfgDataMoreInfo 	= webData.config
	end

	local config = self._cfgDataMoreInfo

	local pbData = gModelActivity:GetActivityPageBySid(self._sid)
	if pbData then
		self:ResetActivePageData(pbData)
		self:ViewCtrl()
	end

	local taskImage = config.taskImage
	local taskTitleIcon = config.tasktitleIcon
	local taskTitleDesc = config.tasktitleDesc
	local tasktitlePos = config.tasktitlePos

	self:SetWndText(self.mTitleText, taskTitleDesc)
	self:InitTextLineWithLanguage(self.mTitleText, -30)
	self:InitTextSizeWithLanguage(self.mTitleText, -2)
	self:SetWndEasyImage(self.mTaskImage,taskImage,nil,true)
	self:SetWndEasyImage(self.mTitleImg,taskTitleIcon,nil,true)
	self:SetAnchorPos(self.mTitleImgContent, LxDataHelper.ParseVector2NotEmpty(tasktitlePos))

	local tabName = config.taskTabName
	local tabNameList = string.split(tabName, ',')
	for k,v in ipairs(self._btnList) do
		self:SetWndTabText(v, tabNameList[k] or "")
	end

	local flopName = config.flopName
	if string.isempty(flopName) then
		flopName = 	ccClientText(18757)
	end
	self:SetWndButtonText(self.mDrawBtn, flopName, nil, -2, -30)

	CS.ShowObject(self.mDrawBtn,  config.eModel ~= ModelActivity.MODEL_ACTIVITY_TYPE_158)
end

function UIFairylandTask:CheckLimitTabRedPoint()
	local goalData
	local status
	local accumulateData = self._curAccumulateData or self:GetAccumulateData()
	local isHide = self._cfgDataMoreInfo.accumulateRecharge == 0
	if not isHide and accumulateData then
		goalData 		= accumulateData.goalData
		status   		= goalData.status				--状态(0-不可领取, 1-可领取，2-已领取)
		if status == 1 then
			return true
		end
	end

	local curType = self._moreInfoType.LIMIT
	local limitTaskData = self._activityPageData[curType]
	if limitTaskData then
		for k,v in ipairs(limitTaskData) do
			goalData 	= v.goalData
			status   	= goalData.status				--状态(0-不可领取, 1-可领取，2-已领取)
			if status == 1 then
				return true
			end
		end
	end

	return false
end

function UIFairylandTask:OnWndRefresh()
	self:SetWndPara()
	self:ViewCtrl()
end

function UIFairylandTask:ClearEffectKeyList()
	if not self._effectKeyList then return end
	for k,v in pairs(self._effectKeyList) do
		self:DestroyWndEffectByKey(v)
	end
	self._effectKeyList={}
end

function UIFairylandTask:RefreshReward()
	local rewardDataList
	if self._openView == self._btnEnum.COMMON then
		rewardDataList = self._curTargetTaskData.items
	else
		rewardDataList = self._curAccumulateData and self._curAccumulateData.items or {}
	end

	local uiList = self._uiRewardList
	if not uiList then
		uiList = UIListEasy:New()
		uiList:Create(self,self.mGiftBtnList)
		uiList:EnableScroll(false)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawGiftItem(...)
		end)
		self._uiRewardList = uiList
	end
	uiList:RemoveAll()

	--添加奖励信息
	for i,v in ipairs(rewardDataList) do
		uiList:AddData(i,v)
	end
	uiList:RefreshList()
end

function UIFairylandTask:InitPara()
	self._pageId = self:GetWndArg("pageId") or 1			--任务表id
	self._pageAccumulateId =  self:GetWndArg("pageAccumulateId") or 2 	--累积充值id
	self._func = self:GetWndArg("func")
	self._sid = self:GetWndArg("sid")
	--self._cfgDataMoreInfo = self:GetWndArg("data")
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end

	self._btnEnum = {
		COMMON = 1,	--每日任务
		LIMIT  = 2,	--限时任务
	}

	self._btnList = {self.mCommonTaskBtn,self.mLimitTimeTaskBtn} 					-- 切换按钮
	self._moreInfoType = {
		COMMON = 1,	--每日任务
		COMMON_TARGET = 2, --每日任务目标
		LIMIT = 3	--限时任务
	}

	self._btnStr = {
		GO 			= ccClientText(18703),	--前往
		GET 		= ccClientText(18704),	--领取
		COMPONENT 	= ccClientText(18705),	--已完成
	}

	self._sliderFormat = {
		ccClientText(18755),
		ccClientText(18756),
	}

	self._effectKeyList ={}
	self._hideGift = false

	self._isForeign = gLGameLanguage:IsForeignVersion()
end

function UIFairylandTask:GetAccumulateData()
	if not self._activityPageAccumulateData then
		return nil
	end

	table.sort(self._activityPageAccumulateData,function(ref1,ref2)
		local status1 = ref1.status
		local status2 = ref2.status
		if status1 ~= status2 then --状态(0-不可领取, 1-可领取，2-已领取)
			if status1 == 1 or status2 == 1 then
				return status1 == 1
			end

			return status1 < status2
		end

		if status1 == 2 and status2 == 2 then
			return ref1.sort > ref2.sort
		end

		return ref1.sort < ref2.sort
	end)

	return self._activityPageAccumulateData[1]
end
------------------------------------------------------------------
return UIFairylandTask


