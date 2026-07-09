---
--- Created by Administrator.
--- DateTime: 2023/10/15 17:10:34
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIExre:LWnd
local UIExre = LxWndClass("UIExre", LWnd)

UIExre.RECEIVE_NEED_HERO = 1
UIExre.RECEIVE_NEED_SCORE = 2

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIExre:UIExre()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIExre:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIExre:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
-----------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIExre:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()
	self._isVie =gLGameLanguage:IsVieVersion()
	self:InitData()
	self:SetStaticContent()
	self:InitUIEvent()
	self:InitMessage()
	self:InitIosShowUI()

	gModelExplore:ExploreMessageReq()
	gModelExplore:SettingTaskQualityReq(0)
	
	if self._isVie then
		self:SetAnchorPos(self.mScrollRect,Vector2.New(110,59))

	end 
end

function UIExre:RefreshReceiveBtn()
	local isGray = not gModelFunctionOpen:CheckIsOpened(12300002)
	self:SetWndButtonGray(self.mReceiveBtn,isGray)
	if tonumber(LPlayerPrefs.exploreTaskAuto)>0 and gModelFunctionOpen:CheckIsOpened(12300004) then
		CS.ShowObject(self.mReceiveBtn,false)
	end
end

function UIExre:GetSpeedCost(explore)
	local refId = explore:GetRefId()
	local cfg = gModelExplore:GetExploreConfig(refId)
	local timeTotal = cfg.needTime
	local timePast =math.max(GetTimestamp() - explore:GetStartTime(), 1)
	local timeLeft = timeTotal - timePast
	local cost = gModelExplore:GetQuickCost(timeLeft)
	return cost
end

function UIExre:InitData()
	self._timer = "_timer"

	self._tabImgList = {
		gModelNormalActivity:GetBIActivityConfigRefByKey("textImage1"),
		gModelNormalActivity:GetBIActivityConfigRefByKey("textImage2"),
		gModelNormalActivity:GetBIActivityConfigRefByKey("textImage3"),
	}

	self._stateImgMap =
	{
		[0] = "public_btn_1_1",
		[1] = "public_btn_1_3",
		[2] = "public_btn_1_2"
	}

	self._qualityBgList=
	{
		[1] ="public_cell_17_1",
		[2] ="public_cell_17_2",
		[3] ="public_cell_17_3",
		[4] ="public_cell_17_4",
		[5] ="public_cell_17_5",
		[6] ="public_cell_17_6",
	}

	self._processList = {}
	self._actData = 1
	local actData = gModelActivity:GetActivityListByModelId(ModelActivity.COMMONRANK,"exploreTask")
	if actData then
		self._actData = actData
		CS.ShowObject(self.mActivityUpImg,true)
		local xiaohao = actData*100 .. "%"
		local str = string.replace(ccClientText(16215),xiaohao)
		self:SetWndText(self.mActivityUpTxt,str)
	end
	local newYearList = {}
	local isNewYear,activitys,txtList = gModelActivity:GetPrivilegeShow1(3)
	local tips = txtList and txtList[2]
	self._typeTips = tips or ""
	if isNewYear then
		for i, v in ipairs(activitys) do
			local activity = v
			local moreInfo = JSON.decode(activity.moreInfo)
			local refIds = moreInfo.privilegeShow4
			local refIdArr = string.split(refIds,"|")
			for i, v in ipairs(refIdArr) do
				local ref = gModelGeneral:GetSysEffectRef(tonumber(v))
				local effectValue = ref.effectValue
				local effectValueArr = string.split(effectValue,"|")
				for j, k in ipairs(effectValueArr) do
					local arr = string.split(k,"=")
					local key = tonumber(arr[1])
					newYearList[key] = tonumber(arr[2])
				end
			end
		end
	end
	self._newYearList = newYearList
	--self:InitGradeInfo()
end

function UIExre:OnClickReceiveBtn(notTip,openId)
	if not openId then openId = 12300002 end
	if not gModelFunctionOpen:CheckIsOpened(openId, not notTip) then
		return
	end

	local receiveQualityList = gModelExplore:GetReceiveQualityList()

	local exploreList =  gModelExplore:GetExploreList()
	local receiveList = {}
	for k,v in ipairs(exploreList) do
		local state = v:GetState()
		if state== StructExplore.UNSTART then
			local quality = v:GetQuality()
			if receiveQualityList[quality] then
				table.insert(receiveList, v)
			end
		end
	end

	local haveReceive = #receiveList > 0
	if not haveReceive then
		if not notTip then GF.ShowMessage(ccClientText(12339)) end
		return
	end

	local isOwn = false
	local own = gModelExplore:GetCurExplorePoint()
	local actData = gModelActivity:GetActivityListByModelId(ModelActivity.COMMONRANK,"exploreTask") or 1

	local receiveNeedType = UIExre.RECEIVE_NEED_SCORE
	for k,v in ipairs(receiveList) do
		local refId = v._refId
		local expend = gModelExplore:GetExploreExpend(refId)
		local req = expend.itemNum * actData
		if req <= own then
			receiveNeedType = UIExre.RECEIVE_NEED_HERO
			if gModelExplore:CheckCanReceive(refId) then
				isOwn = true
				break
			end
		end
	end

	if not isOwn then
		local str = receiveNeedType == UIExre.RECEIVE_NEED_SCORE and ccClientText(12325) or ccClientText(12326)
		if not notTip then GF.ShowMessage(str) end
		return
	end


	self._isClickReceive = true
	gModelExplore:CreateExploreReq(0, {}, 1)
end

function UIExre:CheckHaveGet()
	local exploreList =  gModelExplore:GetExploreList()
	local canGetList = {}
	for k,v in ipairs(exploreList) do
		local state = v:GetState()
		if state== StructExplore.FINISH then
			return true
		end
	end

	return false, canGetList
end

function UIExre:OnClickExploreItem(itemdata)
	if gModelExplore:IsProtect() then
		return
	end
	local state = itemdata:GetState()
	if state== StructExplore.UNSTART  then
		GF.OpenWnd("UIExreFormation",{exploreItem = itemdata,actData = self._actData })
	elseif state == StructExplore.UNFINISH then
		local cost = self:GetSpeedCost(itemdata)
		local own = gModelItem:GetNumByRefId(cost.itemId)
		local costNum = cost.itemNum
		if own >= costNum then
			local para =
			{
				refId = 53402,
				para = {costNum},
				func = function()
					gModelExplore:ReceiveExploreTaskReq(1,itemdata:GetId())
				end,
				consume = costNum
			}
			gModelGeneral:OpenUIOrdinTips(para)
		else
			GF.ShowMessage(ccClientText(10754))
		end

	elseif state== StructExplore.FINISH then
		--gModelExplore:ReceiveExploreTaskReq(1,itemdata:GetId())
		self:OnClickGet()
	end
end

function UIExre:SetBtnShow(tran,state,textTran)
	local img = self._stateImgMap[state]
	self:SetBtnImageAndMat(tran,img,textTran)
end

function UIExre:ShowPrivi()
	self:RefreshPriviIntro()

	local str = ccClientText(12332) --"订阅奖励"
	self:SetWndText(self.mText_2,str)

	local giftRef = gModelNormalActivity:GetBIActivityPrivilegeGiftRefByRefId(ModelActivity.PRIVILEGE_EXPLORE)
	self:SetWndEasyImage(self.mPriviImg,giftRef.icon)
	self:SetWndText(self.mText_1,ccLngText(giftRef.name))
	UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mText_1)
	UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mImage_text)

	local intro = gModelNormalActivity:GetPriviRewardDesc(ModelActivity.PRIVILEGE_EXPLORE)
	local strs = string.split(intro,'|')
	local tempStrs = {}
	for k,v in ipairs(strs) do
		local temp = string.format("%s.%s<br>",k,v)
		table.insert(tempStrs,temp)
	end

	local str = table.concat(tempStrs)
	self:SetWndText(self.mPriviIntro,str)

	local itemList = gModelNormalActivity:GetPrivilegeRewardShow(ModelActivity.PRIVILEGE_EXPLORE) or {}

	local uiList = self:FindUIScroll("priviRewardList")
	if uiList then
		uiList:RefreshList(itemList)
	else
		uiList = self:GetUIScroll("priviRewardList")
		uiList:Create(self.mPriviReward,itemList,function (...) self:RewardListItem(...) end)
	end
	local priviDataList = gModelNormalActivity:GetPriviIdListByType(ModelActivity.PRIVILEGE_EXPLORE)
	local dataId = priviDataList[1]
	local giftData = gModelNormalActivity:GetBIActivityPrivilegeDataRefByRefId(dataId)
	local expend = giftData.expend
	local iconTran = self:FindWndTrans(self.mPriviBuy,"Light/Image")
	local textTran = self:FindWndTrans(self.mPriviBuy,"Light/Text")
	local isItemCost = string.find(expend,"=")
	if isItemCost then
		local itemCost = LxDataHelper.ParseItem_3(expend)
		local iconRes = gModelItem:GetItemImgByRefId(itemCost.itemId)

		self:SetWndEasyImage(iconTran,iconRes)
		self:SetWndText(textTran,itemCost.itemNum)
	else
		local expendId = tonumber(expend)
		local valueShow = gModelPay:GetShowByWelfareId(expendId)
		self:SetWndText(textTran,valueShow)
	end

	CS.ShowObject(iconTran,isItemCost)

	self:SetWndClick(self.mPriviBuy,function ()
		self:BuyPrivi()
	end)
end

function UIExre:RewardListItem(list, item, itemdata, itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootItem = self:FindWndTrans(AniRoot,"item")
	local itemIcon = self:FindWndTrans(AniRootItem,"icon")
	local AniRootTag = self:FindWndTrans(AniRoot,"tag")


	local isShowTab = itemdata.descript ~= 0
	CS.ShowObject(AniRootTag,isShowTab)

	if isShowTab then
		local tabImg = ""
		if itemdata.descript == 1 then
			tabImg = self._tabImgList[1]
		elseif itemdata.descript == 2 then
			tabImg = self._tabImgList[2]
		else
			tabImg = self._tabImgList[3]
		end
		self:SetWndEasyImage(AniRootTag,tabImg)
	end
	self:CreateCommonIconImpl(itemIcon,itemdata)
end

function UIExre:OnReceiveExploreReward(indexList,idList)
	local uiItemList = self._uiTaskList
	if not uiItemList then
		return
	end

	local list = uiItemList:GetList()

	for k,v in ipairs(indexList) do
		list:DelDataByIndex(v)
		list:RemoveItemByDataPos(v)
	end

	if not self._processList then
		return
	end
	for k,v in pairs(idList) do
		self._processList[k] = nil
	end

    local list = gModelExplore:GetExploreList()
    local showTip = list and #list==0
    CS.ShowObject(self.mEmptyTip,showTip)
end

function UIExre:ShowAllCountDown()
	for k,v in pairs(self._processList) do
		self:ShowProgress(k)
	end
end

function UIExre:InitIosShowUI()
	if PRODUCT_G_VER == 1 then
		--ios 写死屏蔽
		CS.ShowObject(self.mPriviBg, false)
		CS.ShowObject(self.mHelpBtn, false)
	elseif PRODUCT_G_VER == 2 or PRODUCT_G_VER == 3 then
		--海外ios 写死屏蔽
		CS.ShowObject(self.mPriviBg, false)
	end
end

function UIExre:ShowRefreshBtn()
	local refreshCnt =gModelExplore:GetFreeRefreshCnt()
	local alreadyCnt = gModelExplore:GetTotalRefreshCnt()
	local refreshStr = nil
	local showIcon = false
	if alreadyCnt<refreshCnt then
		refreshStr = ccClientText(12308)
	else
		showIcon = true

		local refreshCost = gModelExplore:GetRefreshCost()
		local ownNum = gModelItem:GetNumByRefId(refreshCost.itemId)
		if ownNum>=refreshCost.itemNum then
			refreshStr = tostring(refreshCost.itemNum)..ccClientText(12309)
		else
			refreshCost = gModelExplore:GetRefreshCost2()
			refreshStr = tostring(refreshCost.itemNum)..ccClientText(12309)
		end
		local icon,iconBg = gModelItem:GetItemImgByRefId(refreshCost.itemId)
		if icon then
			self:SetWndEasyImage(self.mItemIcon,icon)
		end
	end

	self:SetWndText(self.mRefreshText,refreshStr)
	if self._isVie then
		self:InitTextSizeWithLanguage(self.mRefreshText,-6)
	else
		self:InitTextSizeWithLanguage(self.mRefreshText, -2)
	end


	CS.ShowObject(self.mItemIcon,showIcon)
end

function UIExre:Jump()
	local funcId = 10401131
	local isOpen = gModelFunctionOpen:CheckIsOpened(funcId,true)
	if not isOpen then
		return
	end
	gModelFunctionOpen:Jump(funcId)
	self:WndClose()
end

function UIExre:ShowProgress(id)
	local data = self._processList[id]
	if not data then
		return
	end
	local item=data.item
	local itemdata = data.itemdata

	local button = self:FindWndTrans(item,"button")
	local buttonLayout = self:FindWndTrans(button,"layout")
	local layoutIcon = self:FindWndTrans(buttonLayout,"icon")
	local layoutText = self:FindWndTrans(buttonLayout,"text")
	local process = self:FindWndTrans(item,"process")
	local processSlider = self:FindWndTrans(process,"slider")
	local processTime = self:FindWndTrans(process,"time")
	local unstart = self:FindWndTrans(item,"unstart")
	local finish = self:FindWndTrans(item,"finish")

	local refId = itemdata:GetRefId()
	local cfg = gModelExplore:GetExploreConfig(refId)
	if not cfg then
		return
	end
	local timeTotal = cfg.needTime

	local timePast =GetTimestamp() - itemdata:GetStartTime()
	local timeLeft =math.floor(timeTotal - timePast)
	local progressValue = 0
	local btnStr = ""
	local timeStr = ""
	local isFinish = false
	local instanceId = item:GetInstanceID()
	if timePast>= timeTotal then
		btnStr = "<#ffffff>" .. ccClientText(12305) .. "</color>"
		progressValue = 1
		isFinish = true
		self:SetWndEasyImage(button, "public_btn_1_2")

		self:CreateWndEffect(button, "fx_shouchong_anniu_zhong", instanceId, 100)
	else
		self:SetWndEasyImage(button, "public_btn_1_3")
		local cost = gModelExplore:GetQuickCost(timeLeft)
		local icon,iconBg = gModelItem:GetItemImgByRefId(cost.itemId)
		if icon then
			self:SetWndEasyImage(layoutIcon,icon)
		end
		-- btnStr =string.format("%s %s",cost.itemNum,ccClientText(12307)) --cost.itemNum..ccClientText(12307)
		btnStr = "<#ffffff>" .. cost.itemNum  .. " " .. ccClientText(12307) .. "</color>"
		if timeTotal >0 then
			progressValue = timePast/timeTotal
		end
		timeStr = LUtil.FormatTimespanNumber(timeLeft)
		self:DestroyWndEffectByKey(instanceId)
	end

	local btnState = 1
	if isFinish then
		btnState =2
	end
--[[	self:SetImageActorState(button,btnState)]]
	-- self:SetBtnShow(button,btnState,layoutText)
	CS.ShowObject(finish,isFinish)
	CS.ShowObject(process,not isFinish)
	CS.ShowObject(unstart,false)
	self:SetWndText(layoutText,btnStr)
	self:SetWndText(processTime,timeStr)
	CS.ShowObject(layoutIcon,not isFinish)
	LxUiHelper.SetProgress(processSlider,progressValue)

end

function UIExre:OnClickGet()
	local canGet = self:CheckHaveGet()
	if not canGet then
		GF.ShowMessage(ccClientText(12313))
		return
	end

	gModelExplore:ReceiveExploreTaskReq(2)
end


function UIExre:RefreshTaskItem(index)
	if not self._taskItemUIList then
		return
	end

	if self._isClickReceive then
		GF.ShowMessage(ccClientText(12334))
		gModelExplore:ExploreMessageReq()
	else
		local list = self._taskItemUIList:GetList()
		list:DrawItemByIndex(index)

		--if #self._countDownList>0 then
		--	self:TimerStop(self._timer)
		--	self:TimerStart(self._timer,1,false,-1)
		--end
	end
	self._isClickReceive = false
end

--重连
function UIExre:OnTcpReconnect()
	gModelExplore:ExploreMessageReq()
end

function UIExre:InitUIEvent()
	--self:SetWndClick(self.mGradeBtn,function () self:OnClickGrade() end,LSoundConst.CLICK_ERROR_COMMON)
	self:SetWndClick(self.mBtnClose,function () self:WndCloseAndBack() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mHelpBtn,function () self:ShowHelp() end,LSoundConst.CLICK_ERROR_COMMON)
	self:SetWndClick(self.mRefreshBtn,function () self:OnClickRefresh() end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mReceiveBtn,function () self:OnClickReceiveBtn() end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mSettingBtn, function () self:OnClickSettingBtn() end,LSoundConst.CLICK_BUTTON_COMMON)
end


function UIExre:OnClickSettingBtn()
	local isAuto = tonumber(LPlayerPrefs.exploreTaskAuto)
	GF.OpenWnd("UIExreSettingQuality",{callBk = function()
		local newAuto = tonumber(LPlayerPrefs.exploreTaskAuto)
		if isAuto~= newAuto and newAuto>0 then
			self:RefreshAutoAccept()
		end
	end})
end

function UIExre:OnDrawTaskItem(list,item,itemdata,itempos)
	--local bg = self:FindWndTrans(item,"bg")
	local nameBg = self:FindWndTrans(item,"nameBg")
	local name = self:FindWndTrans(nameBg,"name")
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local button = self:FindWndTrans(item,"button")
	local buttonLayout = self:FindWndTrans(button,"layout")
	local layoutIcon = self:FindWndTrans(buttonLayout,"icon")
	local layoutText = self:FindWndTrans(buttonLayout,"text")
	local process = self:FindWndTrans(item,"process")
	--local processSlider = self:FindWndTrans(process,"slider")
	--local sliderBackground = self:FindWndTrans(processSlider,"Background")
	--local processTime = self:FindWndTrans(process,"time")
	local unstart = self:FindWndTrans(item,"unstart")
	local unstartNeedText = self:FindWndTrans(unstart,"needText")
	local unstartNeedIcon = self:FindWndTrans(unstart,"needIcon")
	local unstartNeedNum = self:FindWndTrans(unstart,"needNum")
	local finish = self:FindWndTrans(item,"finish")
	local finishFinish = self:FindWndTrans(finish,"finish")
	local buffBg = self:FindWndTrans(item,"BuffBg")
	local buffText = self:FindWndTrans(item,"BuffBg/BuffText")
	--CS.ShowObject(buffBg,false)
	--printInfoN("itempos "..itempos)

	local refId = itemdata:GetRefId()
	local cfg = gModelExplore:GetExploreConfig(refId)
	if not cfg then
		return
	end
	local exploreName = ccLngText(cfg.name)
	local state = itemdata:GetState()


	local btnState =0
	if state == StructExplore.UNSTART then
		btnState =0
		local expend = gModelExplore:GetExploreExpend(refId)
		local iconpath = gModelItem:GetItemImgByRefId(expend.itemId)
		self:SetWndEasyImage(unstartNeedIcon,iconpath)
		self:SetWndText(unstartNeedNum,expend.itemNum * self._actData )
		self:SetWndText(unstartNeedText,ccClientText(12330))
		self:SetWndText(layoutText,ccClientText(12303))
		self:SetWndEasyImage(button, "public_btn_1_1")
	elseif state == StructExplore.UNFINISH then
		btnState = 1
	elseif state == StructExplore.FINISH then
		btnState = 2
	end

	if state == StructExplore.UNFINISH and self._isEnus then
		button.sizeDelta = Vector2.New(185,56)
	end


	CS.ShowObject(unstart,state == StructExplore.UNSTART)
	CS.ShowObject(process,state == StructExplore.UNFINISH)
	CS.ShowObject(finish,state == StructExplore.FINISH)
	self:SetWndText(finishFinish,ccClientText(12306))
	CS.ShowObject(layoutIcon,false)

	--self:SetImageActorState(button,btnState)

	-- self:SetBtnShow(button,btnState,layoutText)

	local instanceId = item:GetInstanceID()
	if state == StructExplore.UNFINISH or state == StructExplore.FINISH then
		local id = itemdata:GetId()
		if id then
			self._processList[id] = {itemdata =itemdata,item =item}
			self:ShowProgress(id)
		end
	else
		self:DestroyWndEffectByKey(instanceId)
	end

	local reward = gModelExplore:GetRewardList(refId)
	if reward then
		local data = reward[1]

		local iconTrans = CS.FindTrans(itemRoot, "CommonUI/Icon")
		local baseClass = self._uiTaskList:GetItemCls(instanceId)
		if not baseClass then
			baseClass = CommonIcon:New()
			self._uiTaskList:SetItemCls(instanceId, baseClass)
			baseClass:Create(iconTrans)
		end
		baseClass:SetCommonReward(data.itemType, data.itemId, data.itemNum)
		baseClass:EnableShowNum(true)
		baseClass:DoApply()

		self:SetIconClickScale(iconTrans, true)
		self:SetWndClick(iconTrans, function() gModelGeneral:ShowCommonItemTipWnd(data)  end)
	end

	local quality = itemdata:GetQuality()
	local bgPath = self._qualityBgList[quality]
	if bgPath then
		self:SetWndEasyImage(nameBg,bgPath)
	end

	local showBuff = self._newYearList[quality]
	CS.ShowObject(buffBg,showBuff)
	if showBuff then
		--CS.ShowObject(buffBg,true)
		self:SetWndText(buffText,ccClientText(19238))
		self:SetWndClick(buffBg,function ()
			GF.ShowMessage(self._typeTips)
		end)
	end

	self:SetWndText(name,exploreName)
	self:SetWndClick(button,function () self:OnClickExploreItem(itemdata) end,LSoundConst.CLICK_BUTTON_COMMON)

	self:InitTextSizeWithLanguage(layoutText,-4)
end

function UIExre:SetStaticContent()
	local str = ccClientText(12310)
	self:SetWndText(self.mTitleText,str)
	str = ccClientText(12312)
	self:SetWndText(self.mEmptyTip,str)
	str = ccClientText(12333)
	self:SetWndButtonText(self.mReceiveBtn, str, nil, -2)
	str= ccClientText(11545)
	self:SetWndText(self.mSettingBtnText, str)
	self:RefreshReceiveBtn()
	self:RefreshSettingBtn()
end

function UIExre:InitMessage()
	self:WndEventRecv(EventNames.On_Item_Change,function ()
		self:ShowTicket()
		self:ShowExplorePoint()
		self:ShowRefreshBtn()
	end)
	self:WndNetMsgRecv(LProtoIds.ExploreMessageResp,function ()
		self:RefreshUI()
	end)
	self:WndNetMsgRecv(LProtoIds.FlushExploreMissionResp,function ()
		local str = ccClientText(12340)
		GF.ShowMessage(str)
		self:ShowExplorePoint()
		self:ShowTaskList(true)
		self:ShowRefreshBtn()
		self:RefreshAutoAccept()
	end)

	self:WndEventRecv(EventNames.ON_RECEIVE_EXPLORE_REWARD,function (...)
		self:OnReceiveExploreReward(...)
	end)
	self:WndEventRecv(EventNames.ON_CREATE_EXPLORE,function (...)
		self:RefreshTaskItem(...)
	end)

	self:WndEventRecv(EventNames.PRIVILEGE_REFRESH,function (refId)
		-- if refId == ModelActivity.PRIVILEGE_EXPLORE then
			self:RefreshPriviIntro()
		-- end
	end)

	self:WndEventRecv(EventNames.REFRESH_FUNCTION_STATE,function ()
		self:RefreshReceiveBtn()
		self:RefreshSettingBtn()
	end)
	self:WndEventRecv(EventNames.PRIVILEGE_BUY_IDS,function (buyIds)
		for _, refId in ipairs(buyIds) do
			local ref = GameTable.InnerActivityPrivilegeDataRef[refId]
			if ref.type == ModelActivity.PRIVILEGE_EXPLORE then
				LPlayerPrefs.SetExploreTaskAuto(1)
				self:RefreshAutoAccept()
				break
			end
		end
	end)

end

function UIExre:OnTaskItemReturn(list,item,itemdata,itempos)
	if itemdata then
		local id = itemdata:GetId()
		if id and self._processList then
			self._processList[id] = nil
		end
	end
end

function UIExre:RefreshSettingBtn()
	local isShow = gModelFunctionOpen:CheckIsOpened(12300003)
	CS.ShowObject(self.mSettingBtn,isShow)
end

function UIExre:ShowHelp()
	local str1 = tostring(gModelExplore:GetExplorePara("inforMax"))
	local str2 = tostring(gModelExplore:GetExplorePara("maxTask"))
	local str3 = tostring(gModelExplore:GetExplorePara("refreshFreeCount"))
	local para ={
		str1,str2,str3
	}
	GF.OpenWnd("UIBzTips",{refId= 7,para =para})
end

function UIExre:BuyPrivi()
	local priviDataList = gModelNormalActivity:GetPriviIdListByType(ModelActivity.PRIVILEGE_EXPLORE)
	local refId = priviDataList[1]
	gModelNormalActivity:BuyPrivi(refId)
end

function UIExre:ShowExplorePoint()
	local exploreList = gModelExplore:GetExploreList()
	if not exploreList then
		return
	end
	local min = nil
	for k,v in ipairs(exploreList) do
		if v:GetState() == StructExplore.UNSTART then
			local expend = gModelExplore:GetExploreExpend(v:GetRefId())
			local itemNum = expend.itemNum* self._actData
			if not min or itemNum<min then
				min = itemNum
			end
		end
	end
	if not min then
		min = 0
	end
	--local max = gModelExplore:GetMaxExplorePoint()
	local cur = gModelExplore:GetCurExplorePoint()

	local color = "lightGreen"
	if min >cur then
		color = "red"
	end
	local max= gModelExplore:GetMaxExplorePoint()
	--max = max + self._maxAddExplorePoint
	local curStr = LUtil.FormatColorStr(cur,color)
	self:SetWndText(self.mNum,curStr.."/"..max)
	local itemId = tonumber(gModelExplore:GetExplorePara("expendItem"))
	local iconPath = gModelItem:GetItemImgByRefId(itemId)
	self:SetWndEasyImage(self.mIcon,iconPath)
	self:SetWndClick(self.mAdd,function ()
		gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = self:GetWndName()})
	end,LSoundConst.CLICK_BUTTON_COMMON)
end

function UIExre:OnTimer(key)
	if self._timer == key then
		self:ShowAllCountDown()
	end
end

function UIExre:ShowTaskList(isTop)
	self._processList = {}
	local exploreList = gModelExplore:GetExploreList()
	local uiItemList = self._uiTaskList
	if not uiItemList then
		uiItemList = self:GetUIScroll("taskList")
		self._uiTaskList = uiItemList
		uiItemList:Create(self.mItemList,exploreList,function (...) self:OnDrawTaskItem(...) end,UIItemList.WRAP,false)
	else
		uiItemList:RefreshList(exploreList, true)
	end
	local list = uiItemList:GetList()
	list:SetFuncOnItemReturn(function (...) self:OnTaskItemReturn(...) end)
	list:EnableLoadAnimation(true, 0.03, 1, 2)
	list:SetLoadAnimationScale(nil, 0.03)
	uiItemList:EnableScroll(true,false)

	self:TimerStop(self._timer)
	self:TimerStart(self._timer,1,false,-1)

	if isTop then
		list:RefreshSimpleList(UIListWrap.RefreshMode.Top)
	else
		list:RefreshList()
	end

	self._taskItemUIList = uiItemList

	local total= #exploreList
	local showTip = total==0
	CS.ShowObject(self.mEmptyTip,showTip)

	--local wndName = self:GetWndName()
	--self:SendGuideReadyEvent(wndName)

	self:DelaySendFinish(0.3)
end


function UIExre:RefreshUI()


	self:ShowExplorePoint()
	self:ShowPrivi()
	self:ShowRefreshBtn()
	self:ShowTaskList()
	self:ShowTicket()
	self:RefreshAutoAccept()
end

function UIExre:OnClickRefresh()
	if gModelExplore:IsProtect() then
		return
	end

	local needPopWnd = false

	local refreshCnt =gModelExplore:GetFreeRefreshCnt()
	local alreadyCnt = gModelExplore:GetTotalRefreshCnt()
	local refreshCost = gModelExplore:GetRefreshCost()
	if alreadyCnt>=refreshCnt then
		local ownNum = gModelItem:GetNumByRefId(refreshCost.itemId)
		if ownNum<refreshCost.itemNum then
			refreshCost = gModelExplore:GetRefreshCost2()
			needPopWnd = true
		end
		ownNum = gModelItem:GetNumByRefId(refreshCost.itemId)
		if ownNum<refreshCost.itemNum then
			gModelGeneral:OpenGetWayWnd({itemId=refreshCost.itemId,srcWnd = self:GetWndName()})
			return
		end
	end

	local noticeQuality = gModelExplore:GetReceiveQualityList()--gModelExplore:GetNoticeQuality()
	local needAsk = false
	local exploreList = gModelExplore:GetExploreList()
	for k,v in ipairs(exploreList) do
		local state = v:GetState()
		if state == StructExplore.UNSTART then
			local quality = v:GetQuality()
			if noticeQuality[quality] then
				needAsk = true
				break
			end
		end
	end


	local func = function()
		if needPopWnd then
			local itemNum = refreshCost.itemNum
			local para =
			{
				refId = 53401,
				para = {itemNum},
				func = function()
					gModelExplore:FlushExploreMissionReq()
				end,
				consume = itemNum,
			}

			gModelGeneral:OpenUIOrdinTips(para)
		else
			gModelExplore:FlushExploreMissionReq()
		end
	end


	if needAsk then
		local wndId = 51101
		gModelGeneral:OpenUIOrdinTips({refId = wndId,func = func})
	else
		func()
	end

end

function UIExre:RefreshPriviIntro()
	local isActive = gModelNormalActivity:IsPrivilegeTypeActive(ModelActivity.PRIVILEGE_EXPLORE)
	if isActive then
		local str =ccClientText(12301)
		self:SetWndText(self.mActiveIntro,str)
		self:InitTextLineWithLanguage(self.mActiveIntro, -30)
	end

	CS.ShowObject(self.mActiveIntro,isActive)
	CS.ShowObject(self.mPriviBuy,not isActive)
end

function UIExre:ShowTicket()
	local refreshCost = gModelExplore:GetRefreshCost()
	local icon,iconBg = gModelItem:GetItemImgByRefId(refreshCost.itemId)
	if icon then
		self:SetWndEasyImage(self.mTicket,icon)
	end
	local ownNum = gModelItem:GetNumByRefId(refreshCost.itemId)
	self:SetWndText(self.mTicketNum,ownNum)
	self:SetWndClick(self.mAddTicket,function ()
		gModelGeneral:OpenGetWayWnd({itemId = refreshCost.itemId ,srcWnd = self:GetWndName()})
	end,LSoundConst.CLICK_BUTTON_COMMON)
end
--自動接取任務
function UIExre:RefreshAutoAccept()
	if tonumber(LPlayerPrefs.exploreTaskAuto)>0 then self:OnClickReceiveBtn(true,12300004) end
end

function UIExre:OnClickGrade()
	local ref = gModelGeneral:GetSysEffectRef(10)
	GF.OpenWnd("UIBzTips",{refId= ref.helpTips})
end

------------------------------------------------------------------
return UIExre


