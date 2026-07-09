---
--- Created by LCM.
--- DateTime: 2024/3/2 10:45:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActFetch:LWnd
local UIActFetch = LxWndClass("UIActFetch", LWnd)

UIActFetch.TYPE_OPTBTN_DOWNLOAD = 1 			-- 未下载
UIActFetch.TYPE_OPTBTN_PAUSE = 2 				-- 暂停
UIActFetch.TYPE_OPTBTN_RUNING = 3 				-- 下载中
UIActFetch.TYPE_OPTBTN_FINISH = 4 				-- 完成

UIActFetch.LIST_MIN_NUM = 4					-- 小列表所显示个数
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActFetch:UIActFetch()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActFetch:OnWndClose()
	gModelActivity:SetActDownloadSchedule(self._sid,self._progress)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActFetch:OnCreate()
	LWnd.OnCreate(self)
	self._timeStartKey = "_timeStartKey"
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActFetch:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:CreateSpine()
	self:InitEvent()
	self:InitMsg()
	self:InitData()

    if gLGameUpdate:IsFullPart() then
        gModelActivity:SetActDownloadSchedule(self._sid,1)
        gModelActivity:DownLoadFinishSendMsg()
    end
    self:InitUpdateUI()


	self:RefreshUpdateUI()
	self:RefreshOptBtnStatus()
	self:RefreshGetBtnStatus()

	local downLoadStatus = gLGameUpdate:IsSilenceDownload()
	if downLoadStatus then
		self:ChangeOptBtnStatus(UIActFetch.TYPE_OPTBTN_RUNING)
	end

    gModelActivity:ReqActivityConfigData(self._sid)


--[[	self:TimerStop(self._timeStartKey)
	self:TimerStart(self._timeStartKey,0.5,false,-1)]]
end

function UIActFetch:CreateSpine()
	local spineName = "Tuzixinniang4LH"
	self:CreateWndSpine(self.mSpRoot,spineName,spineName)
end

function UIActFetch:ChangeOptBtnStatus(status)
	self._btnStatus = status
	self:RefreshOptBtnStatus()
end

function UIActFetch:RefreshOptBtnStatus()
	local btnStatus = self._btnStatus
	local optBtnStatusList = self._optBtnStatusList
	local btnStatusInfo = optBtnStatusList[btnStatus]
	if not btnStatusInfo then return end
	self:SetWndEasyImage(self.mOptBtn,btnStatusInfo.image,function()
		CS.ShowObject(self.mOptBtn,true)
	end)
end
------------------------- List -------------------------
--[[function UIActFetch:GetMinItemList()
end

function UIActFetch:InitMinItemList()
    local list = self:GetMinItemList()
    local uiMinItemList = self._uiMinItemList
    if uiMinItemList then
        uiMinItemList:RefreshList(list)
    else
        uiMinItemList = self:GetUIScroll("uiMinItemList")
        self._uiMinItemList = uiMinItemList
        uiMinItemList:Create(self.mMinItemList,list,function(...) self:OnDrawMinItemCell(...) end)
    end
end

function UIActFetch:OnDrawMinItemCell(list,item,itemdata,itempos)

    local CommonUITrans = self:FindWndTrans(item,"CommonUI")
    local IconTrans = self:FindWndTrans(item,"Icon")
end]]

function UIActFetch:GetItemList()
	local list = {}
	local activityData = self._activityData
	if activityData then
		local rewardPage = activityData[ModelActivity.DOWNLOAD_REWARD_PAGEID]
		if rewardPage then
			local entry = rewardPage.entry or {}
			for i,v in ipairs(entry) do
				for idx,val in ipairs(v.items) do
					table.insert(list,val)
				end
			end
		end
	end
	return list
end

function UIActFetch:InitUpdateUI()
	self._progress = gModelActivity:GetActDownloadScheduleBySid(self._sid)
	self._barObj = self:UIProgressFind(self.mBar, "barProgress",self._progress)
	self._barObj:SetProgress(self._progress)
	if self._progress >= 1 then
		self:ChangeOptBtnStatus(UIActFetch.TYPE_OPTBTN_FINISH)
	end
end

function UIActFetch:OnProgressChange(barType, progress, info)
	if progress < self._progress then
		return
	end
	self._progress = progress
	local status = progress >= 1 and UIActFetch.TYPE_OPTBTN_FINISH or UIActFetch.TYPE_OPTBTN_RUNING
	self:ChangeOptBtnStatus(status)
	self:RefreshUpdateUI()
end

function UIActFetch:OnClickFinishFunc()
	GF.ShowMessage("已完成下载")
end

function UIActFetch:InitData()
	self._sid = self:GetWndArg("sid")

	self._btnStatus = UIActFetch.TYPE_OPTBTN_DOWNLOAD

	self._optBtnStatusList = {
		[UIActFetch.TYPE_OPTBTN_DOWNLOAD] = {
			status = UIActFetch.TYPE_OPTBTN_DOWNLOAD,
			image = "activity_music1_icon_btn_3",
		},
		[UIActFetch.TYPE_OPTBTN_PAUSE] = {
			status = UIActFetch.TYPE_OPTBTN_PAUSE,
			image = "activity_music1_icon_btn_4",
		},
		[UIActFetch.TYPE_OPTBTN_RUNING] = {
			status = UIActFetch.TYPE_OPTBTN_RUNING,
			image = "activity_music1_btn_1",
		},
		[UIActFetch.TYPE_OPTBTN_FINISH] = {
			status = UIActFetch.TYPE_OPTBTN_FINISH,
			image = "public_icon_on_1",
		},
	}
end

function UIActFetch:OnClickGetBtnFunc()
	local activityData = self._activityData
	if not activityData then return end
	local rewardPage = activityData[ModelActivity.DOWNLOAD_REWARD_PAGEID]
	if rewardPage then
		local entry = rewardPage.entry or {}
		local firstEntryData = entry[ModelActivity.DOWNLOAD_REWARD_ENTRYID]
		if not firstEntryData then return end
		local status = firstEntryData.goalData.status
		if status == 1 then
			gModelActivity:OnActivityReceiveGoalReq(self._sid, ModelActivity.DOWNLOAD_REWARD_PAGEID,ModelActivity.DOWNLOAD_REWARD_ENTRYID)
		end
	end
end

function UIActFetch:InitEvent()
    self:SetWndClick(self.mBgImage,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mOptBtn,function() self:OnClickOptBtnFunc() end)
    self:SetWndClick(self.mGetBtn,function() self:OnClickGetBtnFunc() end)
end

function UIActFetch:OnActivityListResp(pb)
    local isSame = false
    local isGet = false
    local activities = pb.activities
    for i, v in ipairs(activities) do
        if isSame then break end
        isSame = self._sid == v.sid
        if isSame then
            isGet = v.status == ModelActivity.STATUS_NO_SHOW
        end
    end
    if isGet then
        local activityData = self._activityData
        if activityData then
            local rewardPage = activityData[ModelActivity.DOWNLOAD_REWARD_PAGEID]
            if rewardPage then
                local entry = rewardPage.entry or {}
                local firstEntryData = entry[ModelActivity.DOWNLOAD_REWARD_ENTRYID]
                if not firstEntryData then return end
                firstEntryData.goalData.status = 2
            end
        end
        self._btnStatus = UIActFetch.TYPE_OPTBTN_FINISH
    end
    self:RefreshGetBtnStatus()
end

function UIActFetch:OnClickPauseFunc()
	self:OnClickDownloadFunc()
end

function UIActFetch:OnClickDownloadFunc()
	local packageId = gLSdkImpl:CallMethod(LSdkMethod.GetSdkPackageId) or "0"
	packageId = tonumber(packageId)

	if not self._isAllOpen then
		local packIdKeyList = self._packIdKeyList
		local packId = packIdKeyList[packageId]
		if not packId then
			GF.ShowMessage("暂无配置packId")
			return
		end
	end

	local packResId = self._packResId
	self:ChangeOptBtnStatus(UIActFetch.TYPE_OPTBTN_RUNING)
	gLGameUpdate:DownloadPartResource(packResId,packResId,function()
		self:ChangeOptBtnStatus(UIActFetch.TYPE_OPTBTN_FINISH)
        gModelActivity:DownLoadFinishSendMsg()
	end)
    gModelActivity:SetActDownLoadStatus(true)
end

function UIActFetch:InitText()
	self:SetWndText(self.mCloseTip,ccClientText(10103))
    self:SetWndButtonText(self.mGetBtn,ccClientText(21717))
end

function UIActFetch:OnActivityPageResp(pb)
	if self._sid ~= pb.sid then return end
	local activityData = self._activityData
	if not activityData then
		activityData = {}
		self._activityData = activityData
	end
	for i,v in ipairs(pb.pages or {}) do
		local pageData = gModelActivity:GenerateActivePageDataFromPb(v)
		local pageId = pageData.pageId
		local entryList = {}
		activityData[pageId] = {
			sid = pageData.sid,
			pageId = pageId,
			entry = entryList,
		}
		for idx,val in ipairs(pageData.entry) do
			local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,val.pageId,val.entryId)
			if not entryCfg then return end
			local entryId = val.entryId
			local items = LxDataHelper.ParseItem(entryCfg.reward)
			local moreInfoList = LxDataHelper.ParseItem(entryCfg.moreInfo)
			local goalData = val.goalData
            local status = goalData.status
			local data = {
				entryId = entryId,
				pageId = pageId,
				title = entryCfg.name,
				desc = entryCfg.description,
				icon = entryCfg.icon,
				items = items,
				goalData = goalData,
				status  = status,
				MarketData = val.MarketData,
				moreInfo = moreInfoList,
				sort = entryCfg.sort,
				jumpId = entryCfg.jumpId,
				jumpDesc = entryCfg.jumpDesc,
			}
			table.insert(entryList, data)
		end
	end
    local rewardPage = activityData[ModelActivity.DOWNLOAD_REWARD_PAGEID]
    if rewardPage then
        local entry = rewardPage.entry or {}
        local firstEntryData = entry[ModelActivity.DOWNLOAD_REWARD_ENTRYID]
        if not firstEntryData then return end
        local status = firstEntryData.goalData and firstEntryData.goalData.status
        if status == 1 then
            self._progress = 1
            gModelActivity:SetActDownloadSchedule(self._sid,self._progress)
            self:ChangeOptBtnStatus(UIActFetch.TYPE_OPTBTN_FINISH)
            self:RefreshUpdateUI()
        end
    end
	self:InitItemList()
	self:RefreshGetBtnStatus()
end

function UIActFetch:OnDrawItemCell(list,item,itemdata,itempos)
    local CommonUITrans = self:FindWndTrans(item,"CommonUI")
    local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")
	local itemType,itemId,itemNum = itemdata.itemType,itemdata.itemId,itemdata.itemNum
	local InstanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	baseClass:Create(IconTrans)
	baseClass:SetCommonReward(itemType, itemId, itemNum)
	baseClass:DoApply()
	self:SetWndClick(IconTrans,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
end

function UIActFetch:OnActivityConfigData(data,sid)
    if sid ~= self._sid then return end
	local activityWebData = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityWebData then return end
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end

	local moreInfo = JSON.decode(activityData.moreInfo)
	local packId = moreInfo.packId

	local isAllOpen = false
	local packIdKeyList = {}
	if not string.isempty(packId) then
		local packIdList = string.split(packId,",")
		for i,v in ipairs(packIdList) do
			v = tonumber(v)
			if v == 0 then
				isAllOpen = true
			end
			packIdKeyList[v] = v
		end
	end

	self._isAllOpen = isAllOpen
	self._packIdKeyList = packIdKeyList
	self._packId = packId

	local packResId = moreInfo.packResId
	self._packResId = tonumber(packResId)

	if gLGameUpdate:IsDownloadPart(packResId) then
		gModelActivity:SetActDownloadSchedule(self._sid,1)
		gModelActivity:DownLoadFinishSendMsg()
	end

	local config = activityWebData.config
	local title = config.title
	self:SetWndText(self.mTitle,title)

	local txt1 = config.txt1
	local show = not string.isempty(txt1)
	CS.ShowObject(self.mTipsBg,show)
	self:SetWndText(self.mTitle1,txt1)

	local txt2 = config.txt2
	self:SetWndText(self.mTitle2,txt2)


	gModelActivity:OnActivityPageReq(self._sid)
end

function UIActFetch:OnClickRuningFunc()
	gLGameUpdate:StepUpdateRes3_StopDownload()
	self:ChangeOptBtnStatus(UIActFetch.TYPE_OPTBTN_PAUSE)
    gModelActivity:SetActDownLoadStatus(false)
end

function UIActFetch:OnTimer(key)
	if key == self._timeStartKey then
		self._progress = self._progress + 0.5
		local testNum = self._progress
		FireEvent(EventNames.UPDATE_PROGRESS_CHANGE, 2, testNum, testNum..'/'..100)
		if testNum >= 100 then
			self:TimerStop(self._timeStartKey)
		end
	end
end

function UIActFetch:OnClickOptBtnFunc()
	local btnStatus = self._btnStatus
	if btnStatus == UIActFetch.TYPE_OPTBTN_DOWNLOAD then
		self:OnClickDownloadFunc()
	elseif btnStatus == UIActFetch.TYPE_OPTBTN_PAUSE then
		self:OnClickPauseFunc()
	elseif btnStatus == UIActFetch.TYPE_OPTBTN_RUNING then
		self:OnClickRuningFunc()
	elseif btnStatus == UIActFetch.TYPE_OPTBTN_FINISH then
		self:OnClickFinishFunc()
	end
end

function UIActFetch:RefreshGetBtnStatus()
--[[	local showGetBtn = self._btnStatus == UIActFetch.TYPE_OPTBTN_FINISH
	local showRewardImg = false
	local activityData = self._activityData
	if activityData then
		local rewardPage = activityData[ModelActivity.DOWNLOAD_REWARD_PAGEID]
		if rewardPage then
			local entry = rewardPage.entry or {}
			local firstEntryData = entry[ModelActivity.DOWNLOAD_REWARD_ENTRYID]
			if not firstEntryData then return end
			local status = firstEntryData.goalData.status
			if status == 2 then
				showGetBtn = false
				showRewardImg = true
			end
		end
	end
	CS.ShowObject(self.mGetBtn,showGetBtn)
	CS.ShowObject(self.mGetImg,showRewardImg)]]

	local showGetBtn = true
	local showRewardImg = false
	local isGrayBtn = self._btnStatus ~= UIActFetch.TYPE_OPTBTN_FINISH
	local activityData = self._activityData
	if activityData then
		local rewardPage = activityData[ModelActivity.DOWNLOAD_REWARD_PAGEID]
		if rewardPage then
			local entry = rewardPage.entry or {}
			local firstEntryData = entry[ModelActivity.DOWNLOAD_REWARD_ENTRYID]
			if not firstEntryData then return end
			local status = firstEntryData.goalData.status
			if status == 2 then
				showGetBtn = false
				showRewardImg = true
			end
		end
	end
	self:SetWndButtonGray(self.mGetBtn,isGrayBtn)
	CS.ShowObject(self.mGetBtn,showGetBtn)
	CS.ShowObject(self.mGetImg,showRewardImg)
end

function UIActFetch:InitMsg()

	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function(pb) self:OnActivityListResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb) self:OnActivityPageResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp,function (pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		gModelActivity:OnActivityPageReq(self._sid)
	end)

	self:WndEventRecv(EventNames.UPDATE_PROGRESS_CHANGE,function (...)
		self:OnProgressChange(...)
	end)

	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIActFetch:InitItemList()
    local list = self:GetItemList()

	local isMin = #list <= UIActFetch.LIST_MIN_NUM
	local useListTrans = isMin and self.mMinItemList or self.mItemList
	local hideListTrans = isMin and self.mItemList or self.mMinItemList
	CS.ShowObject(useListTrans,true)
	CS.ShowObject(hideListTrans,false)

    local uiItemList = self._uiItemList
    if uiItemList then
        uiItemList:RefreshList(list)
    else
        uiItemList = self:GetUIScroll("uiItemList")
        self._uiItemList = uiItemList
        uiItemList:Create(useListTrans,list,function(...) self:OnDrawItemCell(...) end)
    end
	uiItemList:EnableScroll(not isMin)
end

function UIActFetch:RefreshUpdateUI()
	local progress = self._progress or 0
	local progressStr = string.format("%.2f%%" , progress * 100)
	self:SetWndText(self.mScheduleTxt,progressStr)
	self._barObj:SetProgress(progress)

	self:RefreshGetBtnStatus()
end

function UIActFetch:OnActivityResp(pb)
	if self._sid ~= pb.sid then return end
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIActFetch



