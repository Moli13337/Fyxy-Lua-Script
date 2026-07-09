---
--- Created by LCM.
--- DateTime: 2024/3/2 15:22:32
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIOrdinHot:LWnd
local UIOrdinHot = LxWndClass("UIOrdinHot", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOrdinHot:UIOrdinHot()
	self._endKey = "_endKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOrdinHot:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOrdinHot:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOrdinHot:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	--self:InitBotBtnList()
	self:Refresh()
end

function UIOrdinHot:OnActivityPageResp(pb)
	if pb.sid ~= self._sid then return end
	local pages = pb.pages
	if not pages then return end
	if pb.sid ~= self._sid then return end

    local list = self._activityList
    if not list then
        list = {}
        self._activityList = list
    end
	local hurtStr = ""
    local pageDataList = {}
    local tPageData
    for i,v in ipairs(pages) do
        tPageData = gModelActivity:GenerateActivePageDataFromPb(v)
        if tPageData then
            local pageId = tPageData.pageId
            pageDataList[pageId] = tPageData

			if pageId == ModelActivity.ACTIVITY_TOWER_HIT then
				local pageMoreInfo = JSON.decode(tPageData.moreInfo)
				hurtStr = LUtil.NumberCoversion(pageMoreInfo.allHurt or 0)
				hurtStr = string.replace(ccClientText(23790),hurtStr)
			end
        end
    end

	self:SetWndText(self.mHurtTxt,hurtStr)

	local tabIdList = self._tabIdList
	local statusList = {
		[0] = 2,
		[1] = 3,
		[2] = 1,
	}
	local pageData,data
	for i,pageId in ipairs(tabIdList) do
		pageData = pageDataList[pageId]
		if pageData then
            local entryList = {}
			for entryIdx,entry in ipairs(pageData.entry) do
				local entryId = entry.entryId
				local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,pageId,entryId)
				if entryCfg then
					local goalData = entry.goalData
					local schedule = tonumber(goalData.schedules[1].schedule)
					local goal = tonumber(goalData.schedules[1].goal)
					local times = goal - schedule
					local status = entry.status or goalData.status  --(0-不可领取, 1-可领取，2-已领取)
					data = {
						entryId = entryId,
						pageId  = pageId,
						desc = entryCfg.description,
						sort = entryCfg.sort,
						status = status,
						times = times,
						schedule = schedule,
						goal = goal,
						rewards = LxDataHelper.ParseItem(entryCfg.reward),
					}
					table.insert(entryList,data)
				end
			end
			table.sort(entryList,function(a,b)
				local statusA,statusB = a.status,b.status
				if statusA ~= statusB then
					return statusList[statusA] > statusList[statusB]
				end
				local sortA,sortB = a.sort,b.sort
				if sortA ~= sortA then
					return sortA < sortB
				end
				return a.entryId < b.entryId
			end)
            list[pageId] = entryList
		end
	end
	self:RefrshTaskList()
end

function UIOrdinHot:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIOrdinHot:GetActivityList()
	local list = {}
	local activityList = self._activityList
	if activityList then
		list = activityList[self._selTabId] or {}
	end
	local statusList = {
		[0] = 1,
		[1] = 2,
		[2] = 0,
	}
	table.sort(list,function(a,b)
		local statusA = statusList[a.status]
		local statusB = statusList[b.status]
		if statusA ~= statusB then
			return statusA > statusB
		else
			return a.sort < b.sort
		end
	end)
	return list
end

function UIOrdinHot:OnClickTaskBtnFunc(itemdata)
	local status = itemdata.status
	if status == 0 then
		-- 跳转
		self:WndClose()
	elseif status == 1 then
		local sid = self._sid
		local pageId = itemdata.pageId
		local entryId = itemdata.entryId
		gModelActivity:OnActivityReceiveGoalReq(sid,pageId,entryId)
	end
end

function UIOrdinHot:InitTop()
	local config = self._config
	if not config then return end

	self:TimerStop(self._endKey)
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if activityData then
		self._endTime = tonumber(activityData.endTime)
		self:RefreshCountDown()
		self:TimerStart(self._endKey,1,false,-1)
	end

	local path = config.bgOne
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mActivityBg, path )
	end
	CS.ShowObject(self.mActivityBg, true)

	path = config.role
	if LxUiHelper.IsImgPathValid(path) then
		local pos = config.rolePos
		self:SetWndEasyImage(self.mActivityHead, path, function()
			if not string.isempty(pos) then
				self:SetAnchorPos(self.mActivityHead, LxDataHelper.ParseVector2NotEmpty(pos))
			end
			CS.ShowObject(self.mActivityHead, true)
		end, true)
	end

	CS.ShowObject(self.mTextImg,true)
end

function UIOrdinHot:Refresh()
	if not self._sid then return end
	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIOrdinHot:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb) self:OnActivityPageResp(pb) end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function ()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
end

function UIOrdinHot:OnTimer(key)
	if key == self._endKey then
		self:RefreshCountDown()
	end
end

function UIOrdinHot:OnClickBotBtnFunc(tabId)
	if tabId == self._selTabId then return end
	self._selTabId = tabId
	self:RefrshTaskList(0)
	local uiBotBtnList = self._uiBotBtnList
	if not uiBotBtnList then return end
	local uiList = uiBotBtnList:GetList()
	uiList:RefreshList()
end

function UIOrdinHot:RefreshCountDown()
	local endTime = self._endTime
	if not endTime then
		self:TimerStop(self._endKey)
		self:SetWndText(self.mTimeText,"")
		CS.ShowObject(self.mTimeBg,false)
		return
	end
	local curTime = GetTimestamp()
	local lastTime = endTime - curTime
	local timeStr
	if lastTime > 0 then
		timeStr = string.replace(ccClientText(23200), LUtil.FormatTimespanCn(lastTime))
	else
		timeStr = ccClientText(14301)
		self:TimerStop(self._endKey)
	end
	self:SetWndText(self.mTimeText,timeStr)
	CS.ShowObject(self.mTimeBg,true)
end

function UIOrdinHot:InitData()
	self._sid = self:GetWndArg("sid")

	local tabIdList = {
		--ModelActivity.ACTIVITY_TOWER_HOT,
		ModelActivity.ACTIVITY_TOWER_HIT,
	}
	self._tabIdList = tabIdList

	local initBotBtnList = {
		{
			btnName = ccClientText(23738),
			tabId = tabIdList[1],
		},
		{
			btnName = ccClientText(23739),
			tabId = tabIdList[2],
		},
	}
	self._initBotBtnList = initBotBtnList

	self._selTabId = tabIdList[1]

	self._isForeign = gLGameLanguage:IsForeignRegion()
end

function UIOrdinHot:RefrshTaskList(refreshStatus)
	refreshStatus = refreshStatus or 0
	local isRefreshList = refreshStatus == 0
	local list = self:GetActivityList()
	local uiTaskList = self._uiTaskList
	if uiTaskList then
		if isRefreshList then
			uiTaskList:RefreshList(list)
		else
			uiTaskList:RefreshData(list)
		end
	else
		uiTaskList = self:GetUIScroll("uiTaskList")
		self._uiTaskList = uiTaskList
		uiTaskList:Create(self.mTaskList,list,function(...) self:OnDrawTaskCell(...) end,UIItemList.WRAP)
	end
end

function UIOrdinHot:InitBotBtnList()
	local list = self._initBotBtnList
	local uiBotBtnList = self._uiBotBtnList
	if uiBotBtnList then
		uiBotBtnList:RefreshList(list)
	else
		uiBotBtnList = self:GetUIScroll("uiBotBtnList")
		self._uiBotBtnList = uiBotBtnList
		uiBotBtnList:Create(self.mBotBtnList,list,function(...) self:OnDrawBotBtnCell(...) end)
	end
end

function UIOrdinHot:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then return end
	self._config = webData.config
	self:InitTop()
	gModelActivity:OnActivityPageReq(self._sid)
end

function UIOrdinHot:CreateRewardList(trans,list)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawRewardCell(...) end)
	end
end

function UIOrdinHot:OnDrawRewardCell(list,item,itemdata,itempos)
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local Icon = self:FindWndTrans(itemRoot,"Icon")
	local ItemNum = self:FindWndTrans(item,"itemNum")
	local Eff = self:FindWndTrans(item,"Eff")

	local itemNum = itemdata.itemNum
	local itemNumStr = LUtil.NumberCoversion(tonumber(itemNum))
	self:SetWndText(ItemNum,itemNumStr)

	local InstanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemNum)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()
	self:SetIconClickScale(Icon, true)
	self:SetWndClick(Icon, function() gModelGeneral:ShowCommonItemTipWnd(itemdata) end)
	if itemdata.isShowEff then
		local effKey = Eff:GetInstanceID()
		local ref = gModelItem:GetRefByRefId(itemdata.itemId)
		local bgEff = ref and ref.bgEff
		self:DestroyWndEffectByKey(effKey)
		if not string.isempty(bgEff) then
			self:CreateWndEffect(Eff,bgEff,effKey,100,false,false)
			CS.ShowObject(Eff,true)
		else
			CS.ShowObject(Eff,false)
		end
	else
		CS.ShowObject(Eff,false)
	end
end

function UIOrdinHot:OnDrawBotBtnCell(list,item,itemdata,itempos)
	local TabBtn = self:FindWndTrans(item,"TabBtn")
	local tabId = itemdata.tabId
	local isSel = tabId == self._selTabId
	local status = isSel and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(TabBtn,status)
	self:SetWndTabText(TabBtn,itemdata.btnName)

	self:SetWndClick(TabBtn,function()
		self:OnClickBotBtnFunc(tabId)
	end)
end

function UIOrdinHot:OnDrawTaskCell(list,item,itemdata,itempos)
	local RewardList = self:FindWndTrans(item,"RewardList")
	local DiscountImg = self:FindWndTrans(item,"DiscountImg")
	local btn = self:FindWndTrans(item,"btn")
	local text = self:FindWndTrans(btn,"text")
	local EffRoot = self:FindWndTrans(btn,"EffRoot")
	local RedPoint = self:FindWndTrans(item,"RedPoint")
	local Txt = self:FindWndTrans(item,"TxtBg/Txt")
	local NotDescTxt = self:FindWndTrans(item,"NotDescTxt")
	local NotDescTxtEn = self:FindWndTrans(item,"NotDescTxtEn")
	local DescTxt = self:FindWndTrans(item,"DescTxt")
	local Show = self:FindWndTrans(item,"Show")

	local isForeign = self._isForeign

	local rewards = itemdata.rewards
	self:CreateRewardList(RewardList,rewards)

	local status = itemdata.status
	local isShowRedPoint = status == 1

	local key = EffRoot:GetInstanceID()
	self:DestroyWndEffectByKey(key)
	if isShowRedPoint then
		self:CreateWndEffect(EffRoot,"fx_anniu_02",key,100,false,false)
	end
	CS.ShowObject(RedPoint,false)
	CS.ShowObject(EffRoot,isShowRedPoint)

	local isGetReward = status == 2
	CS.ShowObject(Show,isGetReward)

	local showBtn = not isGetReward
	if showBtn then
		local btnType = isShowRedPoint and "yellow_2" or "blue_2"
		local img = LUtil.GetBtnImg(btnType)
		self:SetWndEasyImage(btn,img)

		local btnName = isShowRedPoint and ccClientText(23501) or ccClientText(23503)
		self:SetWndText(text,btnName)

		self:SetWndClick(btn,function() self:OnClickTaskBtnFunc(itemdata) end)
	end
	CS.ShowObject(btn,showBtn)

	self:SetWndText(Txt,itemdata.desc)

	CS.ShowObject(DiscountImg,false)

	local isFinsh = itemdata.times <= 0
	local textId = isFinsh and 23759 or 23760
	local goal = LUtil.NumberCoversion(itemdata.goal)
	local schedule = LUtil.NumberCoversion(itemdata.schedule)
	local str = string.replace(ccClientText(textId),schedule,goal)

	CS.ShowObject(NotDescTxt, not isForeign)
	CS.ShowObject(NotDescTxtEn, isForeign)
	if isForeign then
		self:SetWndText(NotDescTxt,str)
	else
		self:SetWndText(NotDescTxtEn,str)
	end
end

function UIOrdinHot:OnActivityResp(pb)

end

------------------------------------------------------------------
return UIOrdinHot


