---
--- Created by Administrator.
--- DateTime: 2023/10/10 21:14:15
---
---活动模板17 ， 掉落兑换
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubExcGje:LChildWnd
local UISubExcGje = LxWndClass("UISubExcGje", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubExcGje:UISubExcGje()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubExcGje:OnWndClose()
	self:Clear()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubExcGje:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubExcGje:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self._isVie = gLGameLanguage:IsVieVersion()

	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitData()
	self:SetPara()
	--self:SetContent()
	self:InitUIEvent()
	self:WndEventRecv(EventNames.On_Item_Change,function () self:SetItemInfo() end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:SetContent(...) end)

	local activityData = gModelActivity:GetActivityBySid(self._sid)
	local type = activityData.type
	local redType = gModelRedPoint:GetAcvityRedTypeByType(type)
	self:RegisterRedPointFunc(redType,function ()
		local redPoint = self:FindWndTrans(self.mExchangeBtn,"redPoint")
		local showRed = gModelRedPoint:CheckActivityShowRed(self._sid)
		CS.ShowObject(redPoint,showRed)
	end)

	gModelActivity:ReqActivityConfigData(self._sid)
	self:RefreshForeign()
end


function UISubExcGje:SetImageEx(tran,img,needNativeSize)
	if LxUiHelper.IsImgPathValid(img) then
		CS.ShowObject(tran,false)
		self:SetWndEasyImage(tran,img,function ()
			if CS.IsValidObject(tran) then
				CS.ShowObject(tran,true)
			end
		end,needNativeSize)
	end
end

function UISubExcGje:SetCountDown()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local endTime = activityData.endTime
	local str = nil
	if endTime == 0 then
		str=ccClientText(14300) --"永久"
		self:TimerStop(self._countDownTimer)
	else
		local timeSpan = endTime- GetTimestamp()
		if timeSpan < 0 then
			str =ccClientText(14301) --"活动已结束"
			self:TimerStop(self._countDownTimer)
		else
			str = LUtil.FormatTimespanCn(timeSpan)
			str = ccClientText(16800)..str --
		end
	end

	self:SetWndText(self.mTimeText,str)
end

function UISubExcGje:OnClickSrc()
	local itemId = self._itemId
	gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = self:GetWndName()})
end

function UISubExcGje:SetPara()
	self._sid = self:GetWndArg("sid")

end

function UISubExcGje:SetExchangeCountDown()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local str
	local showEndTime = activityData.showEndTime
	local timeSpan = showEndTime- GetTimestamp()
	if timeSpan <= 0 then
		self:TimerStop(self._exchangeCDTimer)
		str =ccClientText(14301) --"活动已结束"
		activityData:SetStatus(3)
		FireEvent(EventNames.ON_ACTIVITY_SHOW_END)
		return
	else
		str = LUtil.FormatTimespanCn(timeSpan)
		str =ccClientText(16801)..str -- "兑换时间:"..str
	end

	self:SetWndText(self.mTime,str)

end

function UISubExcGje:InitData()
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


end

function UISubExcGje:InitUIEvent()
	self:SetWndClick(self.mGetBtn,function () self:OnClickSrc() end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mExchangeBtn,function () self:OnClickExchange() end,LSoundConst.CLICK_BUTTON_COMMON)

	local text = self:FindWndTrans(self.mExchangeBtn,"Light/Text")
	local str = ccClientText(16807)
	self:SetWndText(text,str)

end

function UISubExcGje:SetColorGradient(tran,top,bottom)
	local topColor = LUtil.ColorByHex_6(top)
	local bottomColor = LUtil.ColorByHex_6(bottom)
	LxUiHelper.SetTextColorGradient(tran,topColor,topColor,bottomColor,bottomColor)
end

function UISubExcGje:OnClickExchange()
	gModelRedPoint:SetActivityRedClicked(self._sid)

	gModelActivity:OnActivitySpecialOpReq(self._sid,1, nil, nil, "1",26)
	GF.OpenWndBottom("UIDian",{page = ModelShop.ACTIVITY,subPage = self._sid})
end

function UISubExcGje:RefreshForeign()
	if self._isVie then
		self:InitTextSizeWithLanguage(self.mTimeText,-4)
		self:SetAnchorPos(self.mTimeText,Vector2.New(-30,0))
		self:SetAnchorPos(self.mTitle,Vector2.New(-72,677))

	end
	if self.jpj then
		self:SetAnchorPos(self.mTimeText,Vector2.New(-25,0))
	end
end


function UISubExcGje:OnTimer(key)
	if key == self._countDownTimer then
		self:SetCountDown()
	elseif key == self._exchangeCDTimer then
		self:SetExchangeCountDown()
	end
end

function UISubExcGje:SetItemInfo()
	local itemId = self._itemId
	if not itemId then
		return
	end
	local num = gModelItem:GetNumByRefId(itemId)
	self:SetWndText(self.mNum,num)
end

function UISubExcGje:Clear()
	if self._iconList then
		self._iconList:Destroy()
		self._iconList = nil
	end
end

function UISubExcGje:SetContent(data,sid)
	--local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	--if not activityData then
	--	return
	--end
	--local moreInfo = activityData.moreInfo

	if self._sid ~= sid then
		return
	end


	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then
		return
	end
	local data = webData.config
	local path = data.image

	self:SetImageEx(self.mBg,path)
	path = data.descIcon
	self:SetImageEx(self.mTitle,path,true)
	path = data.tipsTitle
	for k,v in ipairs(self._arrowItems) do
		self:SetImageEx(v,path)
	end
	path = data.ruleIcon
	for k,v in ipairs(self._starItems) do
		self:SetImageEx(v,path)
	end
	path = data.sourceIcon
    local getIcon = self:FindWndTrans(self.mGetBtn,"icon")
	self:SetImageEx(getIcon,path)
    local getText = self:FindWndTrans(self.mGetBtn,"text")
    local str = ccClientText(16806)
    self:SetWndText(getText,str)

	path = data.desBgBig
	self:SetImageEx(self.mCellBg_1,path)
	path = data.desBgSmall
	--self:SetImageEx(self.mCellBg_2,path)
	self:SetImageEx(self.mCellBg_3,path)

	local topColor = data.tipsTitleColor1
	local bottomColor= data.tipsTitleColor2
	local str = ccClientText(16804) --"活动规则"
	self:SetWndText(self.mRuleTitle,str)
	str =ccClientText(16805) --"珍稀奖励"
	self:SetWndText(self.mRewardTitle,str)
	if not string.isempty(topColor) then
		self:SetColorGradient(self.mRuleTitle,topColor,bottomColor)
		self:SetColorGradient(self.mRewardTitle,topColor,bottomColor)
	end


	self:SetAnchorPos(self.mTitle, LxDataHelper.ParseVector2NotEmpty(data.descIconXY))
	self:SetAnchorPos(self.mTimeBg, LxDataHelper.ParseVector2NotEmpty(data.openTimeXY))
	self:SetCountDown()
	self:TimerStop(self._countDownTimer)
	self:TimerStart(self._countDownTimer,1,false,-1)


	local itemId = tonumber(data.itemId)
	local num = gModelItem:GetNumByRefId(itemId)
	local iconPath = gModelItem:GetItemImgByRefId(itemId)

	self._itemId = itemId

	self:SetImageEx(self.mIcon,iconPath)
	self:SetWndText(self.mNum,num)

	local str = data.tipsDescription
	self:SetWndText(self.mContent,str)

	if not string.isempty(bottomColor)  then
		local color = LUtil.ColorByHex_6(bottomColor)
		local xuitxt = self:FindWndText(self.mContent)
		self:SetXUITextColor(xuitxt,color)
	end

	local reward = data.rewardShow
	local items = LxDataHelper.ParseItem(reward)
	--local itemList = self:GetUIScroll("itemList")
	--itemList:Create(self.mItemList,items,function (...) self:OnDrawItem(...) end)
	local showList ={}
	for k,v in ipairs(items) do
		local temp =
		{
			itemId = v.itemId,
			itemNum = -1,
			itemType = v.itemType,
		}
		table.insert(showList,temp)
	end

	local uiIconEasyList = self._iconList
	if not uiIconEasyList then
		uiIconEasyList = UIIconEasyList:New()
		self._iconList = uiIconEasyList
		uiIconEasyList:Create(self, self.mItemList)
	end
	uiIconEasyList:RefreshList(showList)

	self:ShowActivityHero(self.mRoleRoot,data.ImageHero,data.ImageHeroPos)

	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local showEndTime = activityData.showEndTime
	local timeSpan = showEndTime- GetTimestamp()
	if timeSpan <= 0 then
		str =ccClientText(14301) --"活动已结束"
		self:TimerStop(self._exchangeCDTimer)
	else
		str = LUtil.FormatTimespanCn(timeSpan)
		str = ccClientText(16801)..str --"兑换时间:"
		self:TimerStart(self._exchangeCDTimer,1,false,-1)
	end

	self:SetWndText(self.mTime,str)
	CS.ShowObject(self.mAniRoot,true)
end


------------------------------------------------------------------
return UISubExcGje


