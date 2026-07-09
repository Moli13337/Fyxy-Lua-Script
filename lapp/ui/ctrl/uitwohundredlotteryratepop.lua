---
--- Created by BY.
--- DateTime: 2022/8/11 22:13:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITwoHundredLotteryRatePop:LWnd
local UITwoHundredLotteryRatePop = LxWndClass("UITwoHundredLotteryRatePop", LWnd)

UITwoHundredLotteryRatePop.PAGE_REWARD = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITwoHundredLotteryRatePop:UITwoHundredLotteryRatePop()
	self._uiList = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITwoHundredLotteryRatePop:OnWndClose()
	self._uiList = nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITwoHundredLotteryRatePop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITwoHundredLotteryRatePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
    self:SetTopDesc()
	self:InitPara()
	self:InitStaticInfo()
end

function UITwoHundredLotteryRatePop:InitPara()
	self._sid = self:GetWndArg("sid")

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UITwoHundredLotteryRatePop:InitData()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then return end

	local config 	= webData.config
	self._config 	= config

	local activityData 	= gModelActivity:GetActivityBySid(self._sid)
	local moreInfo  	= JSON.decode(activityData.moreInfo)

	local helpTip	= config.specialTips
	self._helpTips  = string.split(helpTip, '|')
	self._receiveList = {}
	local dropRecord		= moreInfo.dropRecord
	for k,v in ipairs(dropRecord) do
		if v.receive == 1 then
			self._receiveList[v.select] = true
		end
	end
end

function UITwoHundredLotteryRatePop:OnActivityPageResp(pb)
	local sid = pb.sid
	if sid ~= self._sid then return end

	self:ResetActivePageData(pb)
	self:RefreshView()
end

function UITwoHundredLotteryRatePop:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb) self:OnActivityPageResp(pb) end)
end

function UITwoHundredLotteryRatePop:InitEvent()
	self:SetWndClick(self.mMaskBg,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UITwoHundredLotteryRatePop:RefreshHeroList()
	local dataList = self._rewardList

	table.sort(dataList,function (a,b)
		if a.rate ~= b.rate then
			return a.rate < b.rate
		end
		return a.entryId < b.entryId
	end)
	local uiList = self._uiList
	if not uiList then
		uiList = self:GetUIScroll("_key_uiList")
		self._uiList = uiList
		uiList:Create(self.mHeroList,dataList, function(...)
			self:OnDrawHeroCell(...)
		end,UIItemList.WRAP,false)
		--uiList:EnableScroll(true,false)
		local list = uiList:GetList()
		list:EnableLoadAnimation(true, 0, 4)
		list:RefreshList(UIListWrap.RefreshMode.Solid)
	else
		uiList:RefreshList(dataList)
	end
end

function UITwoHundredLotteryRatePop:ShiftRateStr(rateValue)
	local tempValue
	--向上取整
	if rateValue >= 10 then
		--保留2位小数
		tempValue = 100
	elseif rateValue >= 0.1 then
		--保留3位小数
		tempValue = 1000
	elseif rateValue >= 0.01 then
		--保留4位小数
		tempValue = 10000
	else
		--保留5位小数
		tempValue = 100000
	end

	return math.ceil(rateValue * tempValue)/ tempValue
end

function UITwoHundredLotteryRatePop:OnDrawHeroCell(list, item, itemdata, itempos)
	local CommonUITrans = CS.FindTrans(item,"CommonUI")
	local iconTrans = CS.FindTrans(CommonUITrans , "Icon")
	local textTrans = CS.FindTrans(item,"text")

	local rewards = itemdata.rewards
	local reward  = rewards[1]
	local itemId  = reward.itemId
	local InstanceID = item:GetInstanceID()
	local baseClass = self._uiList:GetItemCls(InstanceID)
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiList:SetItemCls(InstanceID, baseClass)
		baseClass:Create(iconTrans)
	end
	baseClass:SetCommonReward(reward.itemType,itemId,reward.itemNum)
	baseClass:EnableShowNum(reward.itemNum>0)
	baseClass:SetNoShowLv(true)
	--local isGet = self:CheckRewardGetState(itemId)
	--baseClass:SetShowMaskOnly(isGet)
	baseClass:DoApply()

	local itype,refId,count = baseClass:GetRewardType(),baseClass:GetRewardRefId(),baseClass:GetRewardCount()

	self:SetIconClickScale(iconTrans, true)
	self:SetWndClick(iconTrans,function()
		if itype == LItemTypeConst.TYPE_HERO then
			gModelGeneral:OpenHeroSimpleTip(refId,true)
		else
			gModelGeneral:OpenItemInfoTip(refId,count)
		end
	end)

	local showRate = itemdata.showRate
	if not string.isempty(showRate) then
		local str = tonumber(showRate)*100 .. "%"
		self:SetWndText(textTrans,str)
	end
end

function UITwoHundredLotteryRatePop:CheckRewardGetState(itemId)
	return self._receiveItemIdList[itemId]
end

--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UITwoHundredLotteryRatePop:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:InitData()
	gModelActivity:OnActivityPageReq(self._sid)
end

function UITwoHundredLotteryRatePop:SetTopDesc()

	local str = ccClientText(26001)
	local isShow = not string.isempty(str)
	CS.ShowObject(self.mTopContent, isShow)
	if not isShow then return end


	self:SetWndText(self.mDesc, str)
	self:InitTextSizeWithLanguage(self.mDesc, 2)
end

function UITwoHundredLotteryRatePop:RefreshView()
	self:RefreshHeroList()
end

function UITwoHundredLotteryRatePop:InitStaticInfo()
	self:SetWndText(self.mTitle1, ccClientText(26000))
end

--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################
function UITwoHundredLotteryRatePop:ResetActivePageData(pb)
	local pageData
	for i, v in ipairs(pb.pages) do
		local pageId = v.pageId
		if pageId == self.PAGE_REWARD then
			local page=gModelActivity:GenerateActivePageDataFromPb(v)
			if page then
				pageData = page
				break
			end
		end
	end

	if not pageData then return end

	self._receiveItemIdList = {}
	local allRate 	 = 0
	local rewardList = {}
	for i,v in ipairs(pageData.entry) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		if entryCfg then
			local id 			= entryCfg.id
			local rate 			= entryCfg.rate
			local rewards
			--if rate > 0 then
				rewards 	= LxDataHelper.ParseItem(entryCfg.reward)
				local moreInfo = entryCfg.moreInfo
				if not string.isempty(moreInfo) then
					local arr = string.split(moreInfo,"|")
					local showRate = arr[2]
					if showRate then
						local data = {
							entryId = v.entryId,
							pageId	= v.pageId,
							id		= id,
							rewards = rewards,
							rate	= rate,
							showRate = showRate
						}
						table.insert(rewardList,data)
						allRate = allRate + rate
					end
				end

			--end

			if self._receiveList[id] then
				--已领取
				if not rewards then
					rewards 	= LxDataHelper.ParseItem(entryCfg.reward)
				end
				local reward	= rewards[1]
				local itemId	= reward.itemId
				self._receiveItemIdList[itemId] = true
			end
		end
	end

	self._rewardList = rewardList
	self._allRate = allRate
end
------------------------------------------------------------------
return UITwoHundredLotteryRatePop


