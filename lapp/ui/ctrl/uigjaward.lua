---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGjAward:LWnd
local UIGjAward = LxWndClass("UIGjAward", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGjAward:UIGjAward()
	---@type UIIconEasyList
	self._uiShowRewardList = nil
	---@type UIIconEasyList
	self._uiNetRewardList = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGjAward:OnWndClose()
	if self._uiShowRewardList then
		self._uiShowRewardList:Destroy()
		self._uiShowRewardList = nil
	end
	if self._uiNetRewardList then
		self._uiNetRewardList:Destroy()
		self._uiNetRewardList = nil
	end
	for k,v in pairs(self._uiHyperList or {}) do
		v:Destroy()
	end
	self._uiHyperList =nil

	self:SetWndVisible(false)

	if self._feedOpen then
		FireEvent(EventNames.ON_CHECK_SUBSCRIBE_FEED_CLEANTAR)
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGjAward:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGjAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	local feedOpen = self:GetWndArg("feedOpen")
	self._feedOpen = feedOpen
	if feedOpen then
		LogWarn("正在直流")
	else
		LogWarn("bu 在直流")
	end
	
	self:InitData()
	self:SetStaticContent()
	self:InitRewardList()

	self:InitUIEvent()
	

	self:WndNetMsgRecv(LProtoIds.GetPlaceRewardResp,function (...) self:OnGetPlaceRewardResp(...) end)
	self:WndEventRecv(EventNames.PLACE_TIME_REFRESH,function () self:OnTimeRefresh() end)

	gModelInstance:OnPlayerInstanceReq()
end

function UIGjAward:InitData()
	self._timerKey = "hangTime"
	self._refreshGetKey = "_refreshGetKey"
	self._rewardList = {}
	self._uiHyperList = {}
	self._getUicommonList={}
	self._uicommonList={}
end

function UIGjAward:OnAwake()
	LWnd.OnAwake(self)
	self._delayFinishEvent = true
end

function UIGjAward:OnGetPlaceRewardResp(pb)
	if #pb.items >0 then
		CS.ShowObject(self.mItemGetList,true)
		CS.ShowObject(self.mEmptyTip,false)
		self._canGetReward = true
	else
		self._canGetReward = false
	end

	self:RefreshGetReward(pb.items)


	self:SendGuideReadyEvent(self:GetWndName())
end

function UIGjAward:OnTimeRefresh()
	local timePast = GetTimestamp()- gModelInstance:GetPlaceTime()

	local timeMin = gModelInstance:GetInstancePara("BoxTimeMin")*60
	self._canGetReward = false
	local timeEnough = false
	if timePast >timeMin then
		timeEnough = true
		gModelInstance:OnGetPlaceRewardReq()
	end
	CS.ShowObject(self.mItemGetList,timeEnough)
	CS.ShowObject(self.mEmptyTip,not timeEnough)



	self:SetTimeContent()

	self:TimerStop(self._timerKey)
	self:TimerStart(self._timerKey,1,false,-1)


	if timePast<0 then
		timePast =0
	end
	timePast = math.floor(timePast)%60
	local timeLeft = gModelInstance:GetInstancePara("TimeCount") - timePast

	self:TimerStop(self._refreshGetKey)
	self:TimerStart(self._refreshGetKey,timeLeft+1,false,-1)


end


function UIGjAward:OnTimer(key)
	if self._timerKey ==key then
		self:SetTimeContent()
	elseif self._refreshGetKey ==key then
		gModelInstance:OnGetPlaceRewardReq()
		self:TimerStop(self._refreshGetKey)
		self:TimerStart(self._refreshGetKey,60,false,-1)
	end

end

function UIGjAward:SetLittleItem(list,item,itemdata,itempos)
	local iconTran = self:FindWndTrans(item,"icon")
	local icon,ionBg = gModelItem:GetItemImgByRefId(itemdata.itemId)
	if icon then
		self:SetWndEasyImage(iconTran,icon)
	end
	local num = itemdata.itemNum..ccClientText(10714) --"/M"
	local text = self:FindWndTrans(item,"text")
	self:SetWndText(text,num)
	self:InitTextSizeWithLanguage(text, -4)
end

function UIGjAward:SetTimeContent()
	local timeTotal = GetTimestamp()- gModelInstance:GetPlaceTime()
	if timeTotal<0 then
		timeTotal =0
	end
	local timeMax = gModelInstance:GetBoxTimeLimit()*60
	if timeTotal > timeMax then
		timeTotal = timeMax
	end

	local color = 'green'
	if timeTotal == timeMax then
		color = 'red'
	end
	local maxTimeStr = LUtil.FormatTimespanNumber(timeMax)


	local totalTimeStr= LUtil.FormatTimespanNumber(timeTotal)
	local timeStr =string.format("%s/%s",totalTimeStr,maxTimeStr)
	timeStr = ccClientText(10713)..LUtil.FormatColorStr(timeStr,color)

	self:SetWndText(self.mRewardIntro_3,timeStr)

	local vipMin = gModelVip:GetOnHookOutLineTime()
	local hour = math.floor(vipMin/60)

	--local showVip = false
	--if hour>0 then
		local str= string.replace(ccClientText(10785),hour)
		--timeStr= LUtil.FormatColorStr(str,"darkYellow")
		self:SetWndText(self.mRewardIntro_4,str)
		--showVip = true
	--end
	--CS.ShowObject(self.mRewardIntro_4,showVip)

end

function UIGjAward:OnClickGet()
	if  self._canGetReward then
		--gModelOutfit:ShowMaxOutfitTips(self._rewardList,function()
			gModelInstance:OpenWndHangReceive()
		--end)
		self:WndClose()
	else
		GF.ShowMessage(ccClientText(10712))
	end
end

function UIGjAward:InitUIEvent()
	self:SetWndClick(self.mGetBtn,function () self:OnClickGet() end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMaskBtn,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	--self:SetWndClick(self.mSetting,function ()
	--	local funcId = gModelInstance:GetInstancePara("timeOutfitSetting")
	--	if not gModelFunctionOpen:CheckIsOpened(tonumber(funcId),true) then
	--		return
	--	end
	--	GF.OpenWnd("UIEqSetting")
	--end)
end

function UIGjAward:OpenRewardPreWnd()
	GF.OpenWnd("UIGjDrop")
end
function UIGjAward:CheckItemListHasSameId(id,list)
	for i, v in pairs(list) do
		if v.itemId == id then
			return true
		end
	end
	return false
end


function UIGjAward:InitRewardList()
	local battleNode = gModelInstance:GetBattleNode(1)
	local timeRewardFix =gModelInstance:GetMissionTimeRewardFix(battleNode)
	local itemList = table.clone(timeRewardFix)

	local heroBattleNode = gModelInstance:GetBattleNode(3)
	local heroDiffOpen = gModelInstance:CheckDiffLvlFuncIsOpen(3)
	if(heroBattleNode and heroDiffOpen)then
		local heroItemList =gModelInstance:GetMissionTimeRewardFix(heroBattleNode)
		for i, v in ipairs(heroItemList) do
			for j, k in ipairs(itemList) do
				if(k.itemId == v.itemId)then
					k.itemNum = k.itemNum + v.itemNum
				end
			end
		end
	end
	local list = self:GetUIScroll("initList")
	local root = self.mSolidReward
	list:Create(root,itemList,function (...) self:SetLittleItem(...) end)

	local showRewardsTmp =gModelInstance:GetShowReward(battleNode)
	local showRewards = table.clone(showRewardsTmp)
	if(heroBattleNode and heroDiffOpen)then
		local heroShowRewards =gModelInstance:GetShowReward(heroBattleNode)
		for i, v in ipairs(heroShowRewards) do
			local hasSameItem = self:CheckItemListHasSameId(v.itemId,showRewards)
			if(not hasSameItem)then
				table.insert(showRewards, v)
			end
		end
	end
	if not showRewards then
		showRewards ={}
	end

	local uiRewardList = self._uiShowRewardList
	if not uiRewardList then
		uiRewardList = UIIconEasyList:New()
		self._uiShowRewardList = uiRewardList
		uiRewardList:Create(self, self.mItemList)
		uiRewardList:SetShowNum(false)
		uiRewardList:EnableScroll(true, true)
	end
	uiRewardList:RefreshList(showRewards)
end

function UIGjAward:RefreshGetReward(rewards)
	self._rewardList = rewards
	local uiNetRewardList = self._uiNetRewardList
	if not uiNetRewardList then
		uiNetRewardList = UIIconEasyList:New()
		self._uiNetRewardList = uiNetRewardList
		uiNetRewardList:Create(self, self.mItemGetList)
		uiNetRewardList:EnableScroll(true, false)
	end
	uiNetRewardList:RefreshList(rewards, true)
end

function UIGjAward:SetStaticContent()
	local title =ccClientText(10700)--"魔袋"
	self:SetWndText(self.mTitleText,title)
	local str =ccClientText(10702) --  "当前每分钟固定收益(推图越远,收益越高)"
	self:SetWndText(self.mRewardIntro_1,str)
	local hyperText= UIHyperText:New()
	hyperText:Create(self.mRewardIntro_2)
	str =ccClientText(10703)   --"收益预告"
	str = hyperText:AddHyper(str,{func = function () self:OpenRewardPreWnd() end})
	str = LUtil.FormatColorStr(str,"green")
	str =ccClientText(10704)..str  --"当前每分钟随机收益"
	self:SetWndText(self.mRewardIntro_2,str)

	str = ccClientText(10705) --冒险累计奖励
	--local text = self:FindWndTrans(self.mTextTitle,"UIText")
	self:SetWndText(self.mAwardText,str)
	--local text = self:FindWndTrans(self.mGetBtn,"text")
	str =ccClientText(10706) --"领取奖励"
	--self:SetWndText(text,str)
	self:SetWndButtonText(self.mGetBtn,str)

	local data=
	{
		refId = 6001,
		IntroTran = self.mEmpty,

	}

	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)

	--str =ccClientText(22000)-- "装备设置")
	--self:SetWndButtonText(self.mSetting,str)

end


------------------------------------------------------------------
return UIGjAward


