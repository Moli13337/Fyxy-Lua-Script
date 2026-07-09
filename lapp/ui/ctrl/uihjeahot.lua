---
--- Created by Administrator.
--- DateTime: 2023/10/14 21:10:23
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIhjeaHot:LWnd
local UIhjeaHot = LxWndClass("UIhjeaHot", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIhjeaHot:UIhjeaHot()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIhjeaHot:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIhjeaHot:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIhjeaHot:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	gModelGeneral:SetDayInfoRecord("TreasureHot")
	--self:DoWndStartScale(0,self.mPopup)

	self._sid = self:GetWndArg("sid")
	self:InitData()


	self:SetWndClick(self.mClose,function () self:WndClose() end)

	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if self._sid ~= sid then
			return
		end

		self:RefreshUI()
	end)

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIhjeaHot:SetItem(item,itemdata)
	local icon = self:FindWndTrans(item,"icon")
	--local itemId = itemdata.itemId
	--local iconPath = gModelItem:GetItemImgByRefId(itemId)
	self:SetWndEasyImage(icon,itemdata)
end

function UIhjeaHot:InitData()
	self._countDownTimer = "countDown"

	self._itemList =
	{
		self.mItem_1,
		self.mItem_2,
		self.mItem_3,
		self.mItem_4,
	}
end

function UIhjeaHot:OnClickHelp(tipsId)
	GF.OpenWnd("UIBzTips",{refId = tipsId})

end

function UIhjeaHot:OnTimer(key)
	if key == self._countDownTimer then
		self:SetCountDown()
	end
end

function UIhjeaHot:RefreshUI()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end

	local activityCfg = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityCfg then
		return
	end
	--local moreInfo = activityData.moreInfo
	local data = activityCfg.config
	--local path = data.bannerBg
	--if LxUiHelper.IsImgPathValid(path) then
	--	--self:SetWndEasyImage(self.mBanner,path)
	--end
	--path = data.bannerName
	--if LxUiHelper.IsImgPathValid(path) then
	--	self:SetWndEasyImage(self.mBannerName,path,function ()
	--		CS.ShowObject(self.mBannerName,true)
	--	end)
	--end
	--self:SetAnchorPos(self.mBannerName, LxDataHelper.ParseVector2NotEmpty(data.bannerNamePosition))

	--CS.ShowObject(self.mHelpBtn,true)
	--self:SetWndClick(self.mHelpBtn,function () self:OnClickHelp(data.helpTipsId) end,LSoundConst.CLICK_ERROR_COMMON)


	--self:SetAnchorPos(self.mTimeBg, LxDataHelper.ParseVector2NotEmpty(data.endTimePosition))

	self:SetCountDown()
	self:TimerStop(self._countDownTimer)
	self:TimerStart(self._countDownTimer,1,false,-1)

	CS.ShowObject(self.mTimeBg,true)


	local helpTipsContent = data.helpTipsContent
	local strs = string.split(helpTipsContent,"\n")
	if #strs <= 1 then
		strs = string.split(helpTipsContent,"<br>")
	end

	self:SetWndText(self.mText1,strs[1])
	self:SetWndText(self.mText2,strs[2])
	self:InitTextLineWithLanguage(self.mText1, -30)
	self:InitTextLineWithLanguage(self.mText2, -30)

	local rewardList =string.split(data.rewardShow,",") --LxDataHelper.ParseItem(data.rewardShow)

	for k,v in ipairs(rewardList) do
		local item = self._itemList[k]
		self:SetItem(item,v)
	end

	local str =ccClientText(19412) --"前往寻宝"
	self:SetWndButtonText(self.mGotoBtn,str)

	self:SetWndClick(self.mGotoBtn,function ()
		--gModelFunctionOpen:Jump(15800001,self:GetWndName())
		gModelCallHero:OpenCallWnd({page = 4})
		self:WndClose()
	end)

end

function UIhjeaHot:SetCountDown()
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
		if timeSpan <= 0 then
			str =ccClientText(14301) --"活动已结束"
			self._isEnd = true
			self:TimerStop(self._countDownTimer)
		else
			str = LUtil.FormatTimespanCn(timeSpan)
			str = ccClientText(14302)..str  --活动剩余时间：
		end
	end

	self:SetWndText(self.mTimeText,str)
end




------------------------------------------------------------------
return UIhjeaHot


