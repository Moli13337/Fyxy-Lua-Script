---
--- Created by Administrator.
--- DateTime: 2021/1/12 11:23:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFairylandAccumulate:LWnd
local UIFairylandAccumulate = LxWndClass("UIFairylandAccumulate", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFairylandAccumulate:UIFairylandAccumulate()
	---@type table<number,UIIconEasyList>
	self._uiListTbl = {}

	---@type table<number,table>
	self._activityPageAccumulateData = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFairylandAccumulate:OnWndClose()
	self:ClearEffectKeyList()
	self:ClearCommonIconList(self._uiListTbl)
	self._uiListTbl = nil

	if self._rewardList then
		self._rewardList:OnWndClose()
	end

	self._activityPageAccumulateData = {}

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFairylandAccumulate:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFairylandAccumulate:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:SetContent()

	self:SetWndText(self.mTitle, ccClientText(18709))
end

function UIFairylandAccumulate:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP,function () self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb) self:OnActivityPageResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityReceiveGoalResp, function(...) self:OnActivityReceiveGoalResp(...) end)

end

function UIFairylandAccumulate:SetTop()
	if not self._data then
		local pbData = gModelActivity:GetActivityPageBySid(self._sid)
		if pbData then
			self:ResetActivePageData(pbData)
		else
			gModelActivity:OnActivityPageReq(self._sid)
			return
		end
	else
		self:ResetActivePageAccumulateDataData()
	end

	self:SetContent()
end

function UIFairylandAccumulate:ClearEffectKeyList()
	if not self._effectKeyList then return end
	for k,v in pairs(self._effectKeyList) do
		self:DestroyWndEffectByKey(v)
	end
	self._effectKeyList={}
end

function UIFairylandAccumulate:SetDrawRewardItem(list,item,itemdata,itemPos)
	local bg 			= self:FindWndTrans(item,"bg")
	local bgTitle 		= self:FindWndTrans(bg,"title")
	local bgProgress 	= self:FindWndTrans(bg,"progress")
	local bgItemList 	= self:FindWndTrans(bg,"itemList")
	local bgButton 		= self:FindWndTrans(bg,"button")
	local blueBtn  		= self:FindWndTrans(bgButton,"BtnBlue3")
	local yellowBtn  	= self:FindWndTrans(bgButton,"BtnYellow3")
	local redPoint 		= self:FindWndTrans(bgButton,"redPoint")


	local titleStr 		= itemdata.title
	local entryId	 	= itemdata.entryId --当前条目的流水id
	local goalData 		= itemdata.goalData
	local status   		= itemdata.status				--状态(0-不可领取, 1-可领取，2-已领取)
	local schedules 	= goalData.schedules[1]			--任务进度列表,一个条目可能由多个完成条件组合成
	local schedule 		= tonumber(schedules.schedule)  --当前进度
	local goal 			= tonumber(schedules.goal)      --目标进度
	local moreInfo  	= JSON.decode(itemdata.moreInfo)
	local jumpDesc		= moreInfo.jumpDesc				--按钮描述
	local items 		= itemdata.items	--道具信息
	self:InitItemList(bgItemList, items)

	local haveGet		= status == 2
	local canGet 		= status == 1
	local color = "green"
	local buttonStr
	local showBtn = blueBtn
	if status == 1 then
		--可领取
		buttonStr = ccClientText(18707)
		showBtn  = yellowBtn
	elseif status == 2 then
		--已领取
		buttonStr = ccClientText(18710)
	else
		--不可领取
		color = "grey_1"
		buttonStr = jumpDesc
	end

	local progressStr = LUtil.FormatColorStr(string.replace(ccClientText(18702),schedule,goal),color)
	self:SetWndText(bgTitle, titleStr)
	self:SetWndText(bgProgress, progressStr)
	self:SetWndButtonText(showBtn, buttonStr)
	self:SetWndButtonGray(showBtn, haveGet)
	CS.ShowObject(blueBtn, not canGet)
	CS.ShowObject(yellowBtn, canGet)
	CS.ShowObject(redPoint, canGet)

	self:SetWndClick(showBtn, function()
		if canGet then
			--可领取
			gModelActivity:OnActivityReceiveGoalReq(self._sid, self._pageId,entryId)
		elseif not haveGet then
			--不可领取
			local jumpId = tonumber(moreInfo.jumpId)
			local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId,true)
			if not isOpen then
				return
			end

			--gModelFunctionOpen:Jump(jumpId, self:GetWndName(), nil, true)
			gModelFunctionOpen:Jump(jumpId, self:GetWndName())

		elseif haveGet then
			GF.ShowMessage(ccClientText(18728))
		end
	end)
end

function UIFairylandAccumulate:OnReturnRewardItem(list,item,itemdata,itemPos)
	--if not itemdata then
	--	return
	--end
	--local refId = itemdata.
	--local key = "reward"..tostring(refId)
	--self:DestroyWndEffectByKey(key)
end

--####################################################################################################################
--### Server #########################################################################################################
--####################################################################################################################
function UIFairylandAccumulate:OnActivityResp(pb,ret)
	if self._sid ~= pb.sid then return end
	self:SetTop()
end


function UIFairylandAccumulate:OnActivityPageResp(pb,ret)
	if self._sid ~= pb.sid then return end

	self:ResetActivePageData(pb)
	self:SetContent()
end

function UIFairylandAccumulate:ResetActivePageAccumulateDataData()
	if not self._data then return end
	--累积充值数据
	self._activityPageAccumulateData = {}
	for k,v in ipairs(self._data.entry) do
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
			goalData = goalData,
			status	 = status,
			sort	= entryCfg.sort,
		}
		table.insert(self._activityPageAccumulateData, data)
	end
end

function UIFairylandAccumulate:InitData()
	self._pageId 	= 2 			--累积充值id
	self._func 		= self:GetWndArg("func")
	self._sid 		= self:GetWndArg("sid")
	self._data 		= self:GetWndArg("data")

	self._effectKeyList ={}

	gModelActivity:ReqActivityConfigData(self._sid)
end


function UIFairylandAccumulate:OnActivityReceiveGoalResp(pb,ret)

end


function UIFairylandAccumulate:InitItemList(root,itemList)
	local rewardDataList = {}
	for k,v in ipairs(itemList) do
		local reward = {
			itemId = v.itemId,
			itemType = v.itemType,
			itemNum = v.itemNum,
		}
		table.insert(rewardDataList, reward)
	end

	local instanceId = root:GetInstanceID()
	local uiList = self._uiListTbl[instanceId]
	if not uiList then
		uiList = UIIconEasyList:New()
		self._uiListTbl[instanceId] = uiList
		uiList:Create(self, root)
		uiList:SetShowNum(false)
		uiList:SetIconParentPath("itemRoot/CommonUI/Icon")
		uiList:SetShowExtraNum(true, "itemNum")
	end
	uiList:RefreshList(rewardDataList)
end

function UIFairylandAccumulate:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:SetTop()
end

function UIFairylandAccumulate:InitEvent()
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
	self:SetWndClick(self.mMaskBg,function () self:WndClose() end)
end

function UIFairylandAccumulate:ResetActivePageData(pb)
	for i, v in ipairs(pb.pages) do
		if v.pageId == self._pageId then
			self._data = gModelActivity:GenerateActivePageDataFromPb(v)
			break
		end
	end

	self:ResetActivePageAccumulateDataData()
end

function UIFairylandAccumulate:SetContent()
	local itemDataList = self._activityPageAccumulateData
	table.sort(itemDataList, function(ref1, ref2)
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

	local rewardList = self._rewardList
	self:ClearEffectKeyList()

	if not rewardList then
		rewardList = UIListWrap:New()
		rewardList:Create(self,self.mRewardContent)
		rewardList:SetFuncOnItemDraw(function(...)
			self:SetDrawRewardItem(...)
		end)
		--rewardList:SetFuncOnItemReturn(function(...)
		--	self:OnReturnRewardItem(...)
		--end)

		rewardList:EnableLoadAnimation(true, 0.03, 1, 2)
		rewardList:SetLoadAnimationScale(nil, 0.03)
		self._rewardList = rewardList
	else
		rewardList:EnableLoadAnimation(false)
	end
	rewardList:RemoveAll()

	for k,v in ipairs(itemDataList) do
		rewardList:AddData(k, v)
	end

	rewardList:RefreshSimpleList(UIListWrap.RefreshMode.Top)
end

------------------------------------------------------------------
return UIFairylandAccumulate


