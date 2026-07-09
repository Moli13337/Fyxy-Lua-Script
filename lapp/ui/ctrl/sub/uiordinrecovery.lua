---
--- Created by Administrator.
--- DateTime: 2023/10/21 10:16:31
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UIOrdinRecovery:LChildWnd
local UIOrdinRecovery = LxWndClass("UIOrdinRecovery", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOrdinRecovery:UIOrdinRecovery()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOrdinRecovery:OnWndClose()
	self:Clear()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOrdinRecovery:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOrdinRecovery:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitData()

	self:InitEvent()
	self:InitMsg()
	gModelActivity:ReqActivityConfigData(self._sid)
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if activityData then return end
	local type = activityData.type
	local redType = gModelRedPoint:GetAcvityRedTypeByType(type)
	self:RegisterRedPointFunc(redType,function()
		self:CheckBtnRedPoint()
	end)
end

function UIOrdinRecovery:InitData()
	self._sid = self:GetWndArg("sid")
	self._countDownTimer = "_countDownTimer"
	self._exchangeCDTimer = "_exchangeCDTimer"
	self._arrowItems =
	{
		self.mArrow_1,
		self.mArrow_2,
		self.mArrow_3,
		self.mArrow_4,
	}
	self._starItems =
	{
		self.mStar_1,
		self.mStar_2,
		self.mStar_3,
		self.mStar_4
	}

	self._recoveryList = {}
end

function UIOrdinRecovery:SetCountDown()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end

	local endTime = activityData.endTime
	local str = nil
	if endTime == 0 then
		str = ccClientText(14300) --"永久"
		self:TimerStop(self._countDownTimer)
	else
		local timeSpan = endTime - GetTimestamp()
		if timeSpan < 0 then
			str = ccClientText(14301) --"活动已结束"
			self:TimerStop(self._countDownTimer)
		else
			str = LUtil.FormatTimespanCn(timeSpan)
			str = ccClientText(16800) .. str
		end
	end
	self:SetWndText(self.mTimeText,str)
end

function UIOrdinRecovery:RefreshListAndRedPoint()
	local uiList = self._uiList
	if uiList then
		local list = uiList:GetList()
		list:RefreshList()
	end
	self:CheckBtnRedPoint()
end

function UIOrdinRecovery:Clear()
	if self._rewardIconList then
		self._rewardIconList:Destroy()
		self._rewardIconList = nil
	end
end

function UIOrdinRecovery:CheckBtnRedPoint()
	local serverRedPoint = gModelRedPoint:CheckActivityShowRed(self._sid)
	local showExchangeBtnRed,showRecoveryBtnRed = false,false
	if serverRedPoint then
		local recoveryList = self._recoveryList or {}
		for k,v in pairs(recoveryList) do
			if showExchangeBtnRed then break end
			local bagHaveNum = gModelItem:GetNumByRefId(k)
			showExchangeBtnRed = bagHaveNum >= v
		end

		showRecoveryBtnRed = self:RefreshRecoveryBtnRedPoint()
	end

	local redPoint = self:FindWndTrans(self.mExchangeBtn,"redPoint")
	CS.ShowObject(redPoint,showExchangeBtnRed)

	CS.ShowObject(self.mRecoveryBtnRedPoint,showRecoveryBtnRed)

	local show = showExchangeBtnRed or showRecoveryBtnRed
	if not show then
		gModelRedPoint:SetActivityRedClicked(self._sid)
	end
end

function UIOrdinRecovery:OnClickExchange()
	--gModelRedPoint:SetActivityRedClicked(self._sid)
	GF.OpenWndBottom("UIDian",{page = ModelShop.ACTIVITY,subPage = self._sid,func = function()
		self:RefreshListAndRedPoint()
	end})
end

function UIOrdinRecovery:OnClickRecovery()
	GF.OpenWnd("UIReery",{title = self._recoveryTitle,funcData = self._funcData,func = function()
		self:CheckBtnRedPoint()
	end})
end

function UIOrdinRecovery:RefreshRecoveryBtnRedPoint(recoveryType)
	recoveryType = recoveryType or (self._funcData and self._funcData.recoveryType)
	local status = false
	if not recoveryType then
		printInfoNR("====== not recoveryType")
	else
		if recoveryType == 1 then
			status = self:IsHaveEquip()
		--【G公共支持】删除神器功能相关数据
		-- elseif recoveryType == 2 then
		-- 	local coin = gModelDream:ChangeCoinByItem()
		-- 	status = coin ~= nil
		-- 	if not status then
		-- 		local materialItemList = self._materialItemList
		-- 		if materialItemList then
		-- 			for i,v in ipairs(materialItemList) do
		-- 				local bagHaveNum = gModelItem:GetNumByRefId(v)
		-- 				status = bagHaveNum > 0
		-- 				if status then break end
		-- 			end
		-- 		end
		-- 	end
		end
	end
	return status
end

function UIOrdinRecovery:IsHaveEquip()
	local equipList = gModelEquip:GetEquipItemList()
	return #equipList > 0
end

function UIOrdinRecovery:OnActivityConfigData()
	self:SetContent()
	gModelActivity:OnActivityPageReq(self._sid)
end

function UIOrdinRecovery:CreateItemList(list)
	local uiList = self._uiList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("uiList")
		self._uiList = uiList
		uiList:Create(self.mIconList,list,function(...) self:OnDrawItemCell(...) end)
	end
end

function UIOrdinRecovery:SelMinNum(pb)
	local sid = pb.sid
	if self._sid ~= sid then return end
	local recoveryList = self._recoveryList
	for idx,info in ipairs(pb.pages or {}) do
		local pageData = gModelActivity:GenerateActivePageDataFromPb(info)
		local entry = pageData.entry or {}
		for i,v in ipairs(entry) do
			local MarketData = v.MarketData
			local expend2 = MarketData and MarketData.expend2
			if expend2 then
				local expend2List = string.split(expend2,"=")
				local needRefId,needNum = tonumber(expend2List[2]),tonumber(expend2List[3])
				local minNum = recoveryList[needRefId]
				if minNum then
					if minNum == 0 then
						recoveryList[needRefId] = needNum
					elseif minNum > needNum then
						recoveryList[needRefId] = needNum
					end
				end
			end
		end
	end
	self:CheckBtnRedPoint()
end

function UIOrdinRecovery:InitEvent()
	self:SetWndClick(self.mExchangeBtn,function() self:OnClickExchange() end)
	self:SetWndClick(self.mRecoveryBtn,function() self:OnClickRecovery() end)
end

function UIOrdinRecovery:SetExchangeCountDown()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	local str
	local showEndTime = activityData.showEndTime
	local timeSpan = showEndTime - GetTimestamp()
	if timeSpan <= 0 then
		self:TimerStop(self._exchangeCDTimer)
		str =ccClientText(14301) --"活动已结束"
		activityData:SetStatus(3)
		FireEvent(EventNames.ON_ACTIVITY_SHOW_END)
	else
		str = LUtil.FormatTimespanCn(timeSpan)
		str =ccClientText(16801) .. str -- "兑换时间:"..str
	end
	self:SetWndText(self.mTime,str)
end

function UIOrdinRecovery:InitMsg()
	self:WndNetMsgRecv(LProtoIds.EquipDecomposeResp, function()
		self:RefreshListAndRedPoint()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		self:SelMinNum(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.SellGoodsResp, function()
		self:RefreshListAndRedPoint()
	end)
	self:WndNetMsgRecv(LProtoIds.DreamLandRecoveryResp, function()
		self:RefreshListAndRedPoint()
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then
			return
		end
		self:OnActivityConfigData()
	end)
end

function UIOrdinRecovery:OnTimer(key)
	if key == self._countDownTimer then
		self:SetCountDown()
	elseif key == self._exchangeCDTimer then
		self:SetExchangeCountDown()
	end
end

function UIOrdinRecovery:OnDrawItemCell(list,item,itemdata,itempos)
	local bgTrans = self:FindWndTrans(item,"bg")
	if bgTrans then
		local refId = tonumber(itemdata)
		local iconTrans = self:FindWndTrans(bgTrans,"icon")
		if iconTrans then
			local icon = gModelItem:GetItemIconByRefId(refId)
			self:SetWndEasyImage(iconTrans,icon)
		end
		local numTrans = self:FindWndTrans(bgTrans,"num")
		if numTrans then
			local num = gModelItem:GetNumByRefId(refId)
			num = LUtil.NumberCoversion(num)
			self:SetWndText(numTrans,num)
		end
	end
end

function UIOrdinRecovery:SetContent()
	--local activityData = gModelActivity:GetActivityBySid(self._sid)
	--if not activityData then return end
    --
	--local moreInfo = activityData.moreInfo
	--local data = JSON.decode(moreInfo)
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config
	local path = data.image
	self:SetWndEasyImage(self.mBg,path)

	path = data.descIcon
	self:SetWndEasyImage(self.mTitle,path,nil,true)

	path = data.tipsTitle
	for k,v in ipairs(self._arrowItems) do
		self:SetWndEasyImage(v,path)
	end

	path = data.ruleIcon
	for k,v in ipairs(self._starItems) do
		self:SetWndEasyImage(v,path)
	end

	self:SetAnchorPos(self.mTitle, LxDataHelper.ParseVector2NotEmpty(data.descIconXY))
	self:SetAnchorPos(self.mTimeBg, LxDataHelper.ParseVector2NotEmpty(data.openTimeXY))

	self:SetCountDown()

	self:TimerStop(self._countDownTimer)
	self:TimerStart(self._countDownTimer,1,false,-1)


	local itemIdList = string.split(data.itemId,"|")
	self._recoveryList = {}
	for i,v in ipairs(itemIdList) do
		local itemId = tonumber(v)
		self._recoveryList[itemId] = 0
	end
	self:CreateItemList(itemIdList)

	local materialItemList
	local materialItem = data.materialItem
	self._materialItem = data.materialItem
	if materialItem then
		materialItemList = {}
		materialItem = string.split(materialItem,";")
		for i,v in ipairs(materialItem) do
			table.insert(materialItemList,tonumber(v))
		end
	end
	self._materialItemList = materialItemList

	-- 【G公共支持】删除神器功能相关数据
	-- local artifactItemList
	-- local artifactItem = data.artifactItem
	-- self._artifactItem = data.artifactItem
	-- if artifactItem then
	-- 	artifactItemList = {}
	-- 	artifactItem = string.split(artifactItem,";")
	-- 	for i,v in ipairs(artifactItem) do
	-- 		--v = string.split(v,"=")
	-- 		--table.insert(materialItemList,tonumber(v[2]))
	-- 		table.insert(artifactItemList,tonumber(v))
	-- 	end
	-- end
	-- self._artifactItemList = artifactItemList

	local noChangeTxt = data.noChangeTxt
	local functionType = data.functionType
	self:GetFunctionType({
		functionType = functionType,
		noChangeTxt = noChangeTxt,
	})

--[[	local itemId = tonumber(data.itemId)
	local num = gModelItem:GetNumByRefId(itemId)
	local iconPath = gModelItem:GetItemImgByRefId(itemId)
	self._itemId = itemId
	self:SetImageEx(self.mIcon,iconPath)
	self:SetWndText(self.mNum,num)]]

	local str = data.tipsDescription
	self:SetWndText(self.mContent,str)

	local btn1Name = data.btn1Name
	self:SetWndText(self.mRecoveryBtnName,btn1Name)
	self._recoveryTitle = btn1Name

	local btn2Name = data.btn2Name
	self:SetWndText(self.mExchangeBtnName,btn2Name)

	local reward = data.rewardShow
	local items = LxDataHelper.ParseItem(reward)
	local showList = {}
	for k,v in ipairs(items) do
		local itemInfo = {
			itemId = v.itemId,
			itemNum = -1,
			itemType = v.itemType,
		}
		table.insert(showList,itemInfo)
	end
	local uiIconEasyList = self._rewardIconList
	if not uiIconEasyList then
		uiIconEasyList = UIIconEasyList:New()
		self._rewardIconList = uiIconEasyList
		uiIconEasyList:Create(self, self.mItemList)
	end
	uiIconEasyList:RefreshList(showList)

	self:TimerStop(self._exchangeCDTimer)
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	local showEndTime = activityData.showEndTime
	local timeSpan = showEndTime - GetTimestamp()
	if timeSpan <= 0 then
		str =ccClientText(14301) --"活动已结束"
	else
		str = LUtil.FormatTimespanCn(timeSpan)
		str = ccClientText(16801)..str --"兑换时间:"
		self:TimerStart(self._exchangeCDTimer,1,false,-1)
	end
	self:SetWndText(self.mTime,str)
end

function UIOrdinRecovery:GetFunctionType(info)
	--if not functionType then return end
	local functionType,noChangeTxt = info.functionType,info.noChangeTxt
	local recoveryType
	local data
	if type(functionType) == "number" then
		recoveryType = tonumber(functionType)
		data = {
			recoveryType = recoveryType,
			materialItemList = self._materialItemList,
			-- 【G公共支持】删除神器功能相关数据
			-- artifactItemList = self._artifactItemList,
			-- artifactItem = self._artifactItem,
			materialItem = self._materialItem,
			noChangeTxt = noChangeTxt,
		}
	elseif type(functionType) == "string" then
		local functionTypeData = string.split(functionType,"=")
		recoveryType = tonumber(functionTypeData[1])
		-- 装备回收
		data = {
			recoveryType = recoveryType,
			materialItemList = self._materialItemList,
			-- 【G公共支持】删除神器功能相关数据
			-- artifactItemList = self._artifactItemList,
			-- artifactItem = self._artifactItem,
			materialItem = self._materialItem,
			noChangeTxt = noChangeTxt,
		}
	else
		recoveryType = LItemTypeConst.TYPE_EQUIP
		data = {
			recoveryType = recoveryType,
		}
	end
	self._funcData = data
	local status = self:RefreshRecoveryBtnRedPoint(recoveryType)
	CS.ShowObject(self.mRecoveryBtnRedPoint,status)
end
------------------------------------------------------------------
return UIOrdinRecovery


