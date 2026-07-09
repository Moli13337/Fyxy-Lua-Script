---
--- Created by Administrator.
--- DateTime: 2021/3/29 11:23:38
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFairylandWatchesFell:LWnd
local UIFairylandWatchesFell = LxWndClass("UIFairylandWatchesFell", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFairylandWatchesFell:UIFairylandWatchesFell()
	---@type UIIconEasyList
	self._uiIconEasyList = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFairylandWatchesFell:OnWndClose()
	if self._uiIconEasyList then
		self._uiIconEasyList:Destroy()
		self._uiIconEasyList = nil
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFairylandWatchesFell:OnCreate()
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFairylandWatchesFell:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitEvent()
	self:InitMsg()
	self:InitData()

	self:SetWndText(self.mTitle, ccClientText(18758))
	self:SetWndButtonText(self.mGoTo, ccClientText(18760))
end

function UIFairylandWatchesFell:CloseWndFunc()
	GF.OpenWnd("UIFairylandMain",{sid = self._sid})
	local mainActivityData = self._activityData
	if mainActivityData then
		gLxTKData:OnMainUIActivityClick(mainActivityData)
	end
	self:WndClose()
end

function UIFairylandWatchesFell:InitEvent()
	self:SetWndClick(self.mBg,function ()
		self:CloseWndFunc()
	end)

	self:SetWndClick(self.mCloseBtn,function ()
		self:CloseWndFunc()
	end,LSoundConst.CLICK_CLOSE_COMMON)

	-- 前往兑换
	self:SetWndClick(self.mGoTo,function ()
		self:GotoShop()
	end,LSoundConst.CLICK_BUTTON_COMMON)

	self:SetWndClick(self.mDetailsBtn, function()
		self:DetailsOnClick()
	end,LSoundConst.CLICK_BUTTON_COMMON)
end

function UIFairylandWatchesFell:DetailsOnClick()
	GF.OpenWnd("UIFairylandWatchesDetails",{
		sid = self._sid,
	})
end

function UIFairylandWatchesFell:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
end

function UIFairylandWatchesFell:ShowTimerFunc()
	local now = GetTimestamp()
	local timeDif = os.difftime(self._endTime,now)
	if timeDif <= 0 then
		self:StopShowTimer()
		return
	end

	local timeStr  = LUtil.FormatTimeToCn3(timeDif)
	timeStr		   = string.replace(ccClientText(18759), timeStr)
	self:SetWndText(self.mEndTime,timeStr)
end

function UIFairylandWatchesFell:InitData()
	self._func = self:GetWndArg("func")
	self._sid = self:GetWndArg("sid")

	local page = self:GetWndArg("page")
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end

	self._page = page or 1
	self._subPage = 1

	self._showTimeKey = "_endTimeKey"

	gModelActivity:ReqActivityConfigData(self._sid)
end

--#####################################################################################################################
--## time #############################################################################################################
--#####################################################################################################################
function UIFairylandWatchesFell:RefreshShowTime()
	local timeValue = self._activityData.endTime or 0
	self._endTime   = timeValue
	local showTime = self._endTime > 0
	CS.ShowObject(self.mEndTime, showTime)
	if not showTime then return end
	self:ShowTimerFunc()
	self:TimerStart(self._showTimeKey,1,false,-1)
end

function UIFairylandWatchesFell:InitRewardList()
	local itemsList = LxDataHelper.ParseItem(self._cfgDataMoreInfo.dropShowReward)
	local uiList = self._uiIconEasyList
	if not uiList then
		uiList = UIIconEasyList:New()
		self._uiIconEasyList = uiList
		uiList:Create(self, self.mRewardList)
		uiList:EnableScroll(true,true)
	end
	uiList:RefreshList(itemsList)
end

function UIFairylandWatchesFell:RefreshRed()
	local isShowRed = false
	local isClicked = gModelActivity:IsClickActivityRed(self._sid)
	if not isClicked then
		if self._cfgDataMoreInfo then
			local itemId = self._cfgDataMoreInfo.itemId
			isShowRed = gModelItem:GetNumByRefId(itemId) >= 10
		end
	end

	CS.ShowObject(self.mRedPoint, isShowRed)
end

function UIFairylandWatchesFell:StopShowTimer()
	self:TimerStop(self._showTimeKey)
	self:WndClose()
end

function UIFairylandWatchesFell:OnTimer(key)
	if key == self._showTimeKey then
		self:ShowTimerFunc()
	end
end
--####################################################################################################################
--### Common #########################################################################################################
--####################################################################################################################
function UIFairylandWatchesFell:RefreshUI()
	local cfg = self._cfgDataMoreInfo
	self:SetWndEasyImage(self.mMainImage, cfg.dropImage)
	self:SetWndEasyImage(self.mTxtImage, cfg.dropTitleIcon, nil, true)
	self:SetAnchorPos(self.mTxtImage, LxDataHelper.ParseVector2NotEmpty(cfg.dropTitlePos))
	self:SetWndText(self.mHelpText, cfg.dropDesc)
	self:InitTextLineWithLanguage(self.mHelpText, -10)
	self:InitTextSizeWithLanguage(self.mHelpText, -2)
	self:SetWndText(self.mDetailsTxt, cfg.InformationBtntext)

	self:InitRewardList()
	self:RefreshShowTime()
	self:RefreshRed()
end

--####################################################################################################################
--### Server #########################################################################################################
--####################################################################################################################
function UIFairylandWatchesFell:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:InitPara()
	self:RefreshUI()
end

function UIFairylandWatchesFell:InitPara()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then
		return
	end

	self._activityData = gModelActivity:GetActivityBySid(self._sid)
	self._cfgDataMoreInfo = webData.config
end

function UIFairylandWatchesFell:GotoShop()
	local sid = self._sid
	gModelActivity:CheckActivityClickRed(true, sid)
	GF.OpenWndBottom("UIDian",{page = ModelShop.ACTIVITY,subPage = sid,func = function()
		local activityData = gModelActivity:GetActivityBySid(sid)
		if activityData then
			if activityData.status ~= 3 then
				GF.OpenWnd("UIFairylandMain",{sid = sid})
				GF.OpenWnd("UIFairylandWatchesFell",{sid = sid})
			else
				GF.ShowMessage(ccClientText(14301))
			end
		end
	end})

	GF.CloseWndByName("UIFairylandMain")
	self:WndClose()
end



------------------------------------------------------------------
return UIFairylandWatchesFell


