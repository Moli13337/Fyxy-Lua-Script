---
--- Created by Administrator.
--- DateTime: 2023/10/21 18:11:41
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubDWFightTk:LChildWnd
local UISubDWFightTk = LxWndClass("UISubDWFightTk", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubDWFightTk:UISubDWFightTk()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubDWFightTk:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubDWFightTk:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubDWFightTk:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:InitUIEvent()
	self:InitEvent()

	gModelDarkWar:OnDarkWarTokenReceiveReq(0)

end

function UISubDWFightTk:OnClickTask(itemdata)
	local tokenInfo = gModelDarkWar:GetGiftState(itemdata.refId)

	local state =  tokenInfo.state
	local str = nil
	if state == 0 then
		str = ccClientText(30674)--"不可领取"
		GF.ShowMessage(str)
	elseif state == 1 then
		local isNormalGet = tokenInfo.freeReward == 1
		if not isNormalGet then
			gModelDarkWar:OnDarkWarTokenReceiveReq(1,{itemdata.refId})
		else
			local isBuy = gModelDarkWar:IsGiftBuyed(self._curIndex)
			if not isBuy then
				self:OnClickGift()
			else
				if tokenInfo.ordinaryReward ~= 1 or tokenInfo.advancedReward ~= 1 then
					gModelDarkWar:OnDarkWarTokenReceiveReq(1,{itemdata.refId})
				end
			end
		end
	end

end


function UISubDWFightTk:SetStaticContent()

	local itemIcon = gModelItem:GetItemImgByRefId(252102)
	self:SetWndEasyImage(self.mItemIcon,itemIcon)

	local str = ccClientText(30663)--"完成任务，达到指定积分可获得奖励战令积分共享，可解锁不同级别奖励"
	self:SetWndText(self.mText1,str)

	str = ccClientText(30664)--"初级奖励"
	self:SetWndText(self.mLowReward,str)

	self._curIndex = 1

	self:CreateUIScrollImpl("tabList",self.mTabList,self._tabDataList,function (...) self:OnDrawTab(...)  end)

end

function UISubDWFightTk:InitEvent()
    self:WndNetMsgRecv(LProtoIds.DarkWarTokenReceiveResp,function ()
		self._isDataRet = true
        self:SetContent()
    end)
end



function UISubDWFightTk:OnDrawTask(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootLightbg = self:FindWndTrans(AniRoot,"lightbg")
	local AniRootLightBg1 = self:FindWndTrans(AniRoot,"lightBg1")
	local AniRootItem = self:FindWndTrans(AniRoot,"item")
	local itemIcon = self:FindWndTrans(AniRootItem,"icon")
	local itemTag = self:FindWndTrans(AniRootItem,"tag")
	local tagCheck = self:FindWndTrans(itemTag,"check")
	local AniRootItemList = self:FindWndTrans(AniRoot,"itemList")
	local AniRootTag = self:FindWndTrans(AniRoot,"tag")
	local AniRootBtnGet = self:FindWndTrans(AniRoot,"btnGet")
	--local btnGetLight = self:FindWndTrans(AniRootBtnGet,"Light")
	--local LightText = self:FindWndTrans(btnGetLight,"Text")
	--local btnGetGray = self:FindWndTrans(AniRootBtnGet,"Gray")
	--local GrayText = self:FindWndTrans(btnGetGray,"Text")
	local AniRootProgress1 = self:FindWndTrans(AniRoot,"progress1")
	local progress1Image = self:FindWndTrans(AniRootProgress1,"Image")
	local AniRootProgress2 = self:FindWndTrans(AniRoot,"progress2")
	local progress2Image = self:FindWndTrans(AniRootProgress2,"Image")
	local AniRootNumPart = self:FindWndTrans(AniRoot,"numPart")
	local numPartActive = self:FindWndTrans(AniRootNumPart,"active")
	local numPartUnactive = self:FindWndTrans(AniRootNumPart,"unactive")
	local numPartNum = self:FindWndTrans(AniRootNumPart,"num")



	local isEven = itempos % 2 == 0
	CS.ShowObject(AniRootLightbg,isEven)
	CS.ShowObject(AniRootLightBg1,isEven)

	local isActive = itemdata.score < self._score

	CS.ShowObject(numPartActive,isActive)
	CS.ShowObject(numPartUnactive,not isActive)
	local color = "yellow"
	if not isActive then
		color = "lightBlue"
	end

	CS.ShowObject(AniRootProgress1,itempos ~= 1)
	CS.ShowObject(AniRootProgress2,itempos ~= self._itemCount)

	self:SetWndText(numPartNum,LUtil.FormatColorStr(itemdata.score,color))

	local reward = itemdata.rewardFree[1]

	self:CreateCommonIconImpl(itemIcon,reward)

	self:SetWndClick(AniRoot,function ()
		self:OnClickTask(itemdata)
	end)

	local refId = itemdata.refId
	local rewards = nil
	if self._curIndex == 1 then
		rewards = itemdata.rewardPayNormal
	else
		rewards = itemdata.rewardPaySpecial
	end
    local instanceId = item:GetInstanceID()

    local metaData = {refId = refId}
    local list = self:FindUIScroll(instanceId)
    if not list then
        list = self:GetUIScroll(instanceId)
        local para =
        {
            root = AniRootItemList,
            dataList = rewards,
            setFunc = function (...) self:OnDrawItem(...) end,
            metaData = metaData
        }
        list:InitListData(para)
    else
        list:SetMetaData(metaData)
        list:RefreshList(rewards)
    end


	local lastData = self._dataList[itempos - 1]
	local lastPoint = lastData and lastData.score or 0
	local curPoint = itemdata.score
	local nextData = self._dataList[itempos + 1]
	local nextPoint = nextData and nextData.score or 0

	local startP1 = (lastPoint + curPoint)/2
	local startP2 = (curPoint + nextPoint)/2
	local percent1 = 0
	percent1 = (self._score - startP1)/(curPoint - startP1)
	percent1 = Mathf.Clamp(percent1,0,1)
	local percent2 = 0
	percent2 = (self._score - curPoint)/(startP2 - curPoint)
	percent2 = Mathf.Clamp(percent2,0,1)

	LxUiHelper.SetProgress(progress1Image,percent1)
	LxUiHelper.SetProgress(progress2Image,percent2)

    local tokenInfo = gModelDarkWar:GetGiftState(refId)

	local isNormalGet = tokenInfo.freeReward == 1
	local state = tokenInfo.state
	local showTag = false
	local str = nil
	if state == 0 then
		str = ccClientText(30671)--"未达成"
	elseif state == 1 then
		str = ccClientText(30672)--"领奖"
		if isNormalGet then
			local isBuy = gModelDarkWar:IsGiftBuyed(self._curIndex)
			if not isBuy then
				str = ccClientText(30673)--"再领一次"
			else
				local getState = self._curIndex == 1 and tokenInfo.ordinaryReward or tokenInfo.advancedReward
				showTag = getState == 1
			end
		end

	end

	self:SetWndButtonText(AniRootBtnGet,str)
	self:SetWndButtonGray(AniRootBtnGet,state == 0)
	CS.ShowObject(AniRootTag,showTag)
	CS.ShowObject(AniRootBtnGet,not showTag)
	CS.ShowObject(itemTag,isNormalGet)
	self:SetWndClick(AniRootBtnGet,function ()
		self:OnClickTask(itemdata)
	end)
end

function UISubDWFightTk:OnClickTab(index)
	if self._curIndex == index then
		return
	end

	self._curIndex = index
	local list = self:FindUIScroll("tabList")
	if list then
		list:DrawAllItems(false)
	end

	self:ShowTaskList()
	self:ShowGiftIcon()
end

function UISubDWFightTk:CheckShowRedPoint(rType)
	if not self._dataList then
		return false
	end

	for k,v in ipairs(self._dataList) do
		local tokenInfo = gModelDarkWar:GetGiftState(v.refId)
		local state = tokenInfo.state
		if state == 1 then
			if rType == 1 then
				local isBuy = gModelDarkWar:IsGiftBuyed(1)
				if isBuy and tokenInfo.ordinaryReward~= 1 then
					return true
				end
			elseif rType == 2 then
				local isBuy = gModelDarkWar:IsGiftBuyed(2)
				if isBuy and tokenInfo.advancedReward~= 1 then
					return true
				end
			end
		end
	end
end

function UISubDWFightTk:InitUIEvent()
	self:SetWndClick(self.mBtnUnlock,function ()
		self:OnClickGift()
	end)

	self:SetWndClick(self.mGiftIcon,function ()
		self:OnClickGift()
	end)
end


function UISubDWFightTk:SetContent()
	self._score = gModelDarkWar:GetGiftScore()
	local _,endTime = gModelDarkWar:GetTimeInfo()
	self._endTime = endTime


	self:ShowTaskList()

	local str = string.replace(ccClientText(30669),self._score)
	self:SetWndText(self.mText3,str)

	self:TimerStop(self._endTimer)
	self:TimerStart(self._endTimer,1,false,-1)

	self:ShowGiftIcon()
end

function UISubDWFightTk:OnClickGift()
	local data = self._giftIdList[self._curIndex]
	local isActive = gModelDarkWar:IsGiftBuyed(data.index)
	if isActive then
		local str = ccClientText(30696) --"已解锁"
		GF.ShowMessage(str)
		return
	end

    GF.OpenWnd("WndDarkWarBuy",{giftType = data.index})
end

function UISubDWFightTk:OnDrawTab(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootBtnTab18 = self:FindWndTrans(AniRoot,"BtnTab18")

	local AniRootRedPoint = self:FindWndTrans(AniRoot,"redPoint")


	self:SetWndTabText(AniRootBtnTab18,itemdata.name)
	self:SetWndClick(AniRoot,function ()
		self:OnClickTab(itemdata.index)
	end)
	local isRed = self:CheckShowRedPoint(itemdata.index)
	CS.ShowObject(AniRootRedPoint,isRed)

	local isSel = itemdata.index == self._curIndex
	self:SetWndTabStatus(AniRootBtnTab18, isSel and LWnd.StateOn or LWnd.StateOff)
end

function UISubDWFightTk:ResetTimeCd()
	local timeLeft = self._endTime - GetTimestamp()
	timeLeft = math.max(0,timeLeft)
	local str = string.replace(ccClientText(30670),LUtil.FormatTimespanCn(timeLeft))
	self:SetWndText(self.mText2,str)

end

function UISubDWFightTk:OnDrawItem(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootItem = self:FindWndTrans(AniRoot,"item")
	local AniRootTag = self:FindWndTrans(AniRoot,"tag")
	local tagCheck = self:FindWndTrans(AniRootTag,"check")


	self:CreateCommonIconImpl(AniRootItem,itemdata)

	local metaData = list:GetMetaData()
	local refId = metaData.refId
	local tokenInfo = gModelDarkWar:GetGiftState(refId)
	local isBuy = gModelDarkWar:IsGiftBuyed(self._curIndex)


	local showMask = false
	local showCheck = false
	if not isBuy then
		showMask = true
		showCheck = false
	else
		local getState = self._curIndex == 1 and tokenInfo.ordinaryReward or tokenInfo.advancedReward
		if getState == 1 then
			showMask = true
			showCheck = true
		end
	end

	CS.ShowObject(AniRootTag,showMask)
	CS.ShowObject(tagCheck,showCheck)
end

function UISubDWFightTk:ShowTaskList()
	if not self._isDataRet then
		return
	end
	local season = gModelDarkWar:GetCurSeason()
	local dataList = gModelDarkWar:FormatTaskDataList(season)

	local pos = 1
	for k,v in ipairs(dataList) do
		local tokenInfo = gModelDarkWar:GetGiftState(v.refId)
		local state = tokenInfo.state
		if state == 1 then
			if tokenInfo.freeReward ~= 1 then
				pos = k
				break
			else
				local isBuy = gModelDarkWar:IsGiftBuyed(1)
				if isBuy and tokenInfo.ordinaryReward~= 1 then
					pos = k
					break
				end
				isBuy = gModelDarkWar:IsGiftBuyed(2)
				if isBuy and tokenInfo.advancedReward~= 1 then
					pos = k
					break
				end
			end
		end
	end

	self._dataList = dataList
	self._itemCount = #dataList
	self:CreateUIScrollImpl('taskList',self.mRewardList,dataList,function(...)
		self:OnDrawTask(...) end,UIItemList.SUPER)

	local list = self:FindUIScroll("taskList")
	if list then
		list:MoveToPos(pos)
	end

	local tabList = self:FindUIScroll("tabList")
	if tabList then
		tabList:DrawAllItems(false)
	end
end

function UISubDWFightTk:OnTimer(key)
	if key == self._endTimer then
		self:ResetTimeCd()
	end
end

function UISubDWFightTk:ShowGiftIcon()
	local btnText = ""
	local data = self._giftIdList[self._curIndex]
	local isActive = gModelDarkWar:IsGiftBuyed(data.index)

	self:SetWndEasyImage(self.mGiftIcon,data.giftIcon)
	if isActive then
		btnText =ccClientText(30696) --"已解锁"
	else
		btnText = data.btnText
	end

	self:SetTextTile(self.mBtnUnlock,btnText)
end

function UISubDWFightTk:InitData()
	self._tabDataList =
	{
		[1] =
		{
			index = 1,
			name = ccClientText(30665)--"中级奖励",
		},
		[2] =
		{
			index = 2,
			name = ccClientText(30666)--"高级奖励",
		}
	}

	self._endTimer = "_endTimer"

	self._giftIdList =
	{
		[1] =
		{
			index = 1,
			giftIcon = gModelDarkWar:GetPara("giftPayNormalIcon"),
			btnText = ccClientText(30667)--"解锁中级奖励"
		},
		[2] =
		{
			index = 2,
			giftIcon = gModelDarkWar:GetPara("giftPaySpecialIcon"),
			btnText = ccClientText(30668)--"解锁高级奖励"
		},
	}

end

------------------------------------------------------------------
return UISubDWFightTk


