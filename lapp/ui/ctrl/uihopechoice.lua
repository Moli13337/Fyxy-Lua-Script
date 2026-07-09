---
--- Created by LCM.
--- DateTime: 2024/3/21 17:17:38
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeChoice:LWnd
local UIHopeChoice = LxWndClass("UIHopeChoice", LWnd)

UIHopeChoice.TYPE_SEL_1 = 1		-- 正面
UIHopeChoice.TYPE_SEL_2 = 2		-- 反面

UIHopeChoice.NOT_START_GAME = 0	-- 未开始游戏
UIHopeChoice.START_GAME = 1		-- 开始游戏
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeChoice:UIHopeChoice()
	self._spineKey = "spineKey"

	self._rewardTimerKey = "rewardTimerKey"
	self._rewardTime = 1.7

	self._startGameStatus = UIHopeChoice.NOT_START_GAME
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeChoice:OnWndClose()
	self:SendMsg()
	--FireEvent(EventNames.ON_DREAMTRIP_CLEARANISTATUS)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeChoice:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeChoice:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:CreateWndSpine(self.mSpineRoot,"Youlebi",self._spineKey,false)

	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
	self:InitChoiceList()
end

function UIHopeChoice:OnClickGoToBtnFunc()
	if not self._selIndex then return end
	if self._sendMsg then return end
	self._sendMsg = true
	self._startGameStatus = UIHopeChoice.START_GAME
	self:RunAni()
end

function UIHopeChoice:OnClickCloseBtnFunc()
	if self._startGameStatus == UIHopeChoice.START_GAME then return end
	self:WndClose()
end

function UIHopeChoice:InitMsg()
	self:WndNetMsgRecv(LProtoIds.DreamTripStartEventResp,function(pb) self:OnDreamTripStartEventResp(pb) end)
	self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList)
		--gModelDreamTrip:EventIdCanCel(self._eventId)

		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:CancelEventIdStatus({
			mapType = extraData.mapType,
			sid = extraData.sid,
			eventId = self._eventId
		})

		self._startGameStatus = UIHopeChoice.NOT_START_GAME
	end)

	--- 7.20新增活动梦境之旅
	--self:WndNetMsgRecv(LProtoIds.ActivityDreamTripStartEventResp,function(pb,ret) self:OnDreamTripStartEventResp(pb) end)
end

function UIHopeChoice:SendMsg()
	if self._sendMsgFunc then
		self._sendMsgFunc()
	end
	self._sendMsgFunc = nil
end

function UIHopeChoice:OnClickChoiceBtnFunc(selType)
	if self._selIndex == selType then
		return
	end
	self._selIndex = selType
	self:InitChoiceList()
end

function UIHopeChoice:GetIsZ()
	local randomNum = math.random(1,100)
	local isZ = randomNum % 2 == 0
	return isZ
end

function UIHopeChoice:InitData()
	self._eventId = self:GetWndArg("eventId")
	self._index = self:GetWndArg("index")


	local extraData = self:GetWndArg("extraData")
	self._extraData = extraData


	local typeInfo1 = {
		selType = UIHopeChoice.TYPE_SEL_1,
		name = ccClientText(28700),
		icon = "dreamTrip_ui_14",
	}
	local typeInfo2 = {
		selType = UIHopeChoice.TYPE_SEL_2,
		name = ccClientText(28701),
		icon = "dreamTrip_ui_5_1",
	}
	self._typeInfoList = {
		[UIHopeChoice.TYPE_SEL_1] = typeInfo1,
		[UIHopeChoice.TYPE_SEL_2] = typeInfo2,
	}

	self._selIndex = nil
end

function UIHopeChoice:RefreshView()
	local eventRefId
	if self._eventId and self._index then
		--local serverData = gModelDreamTrip:GetPlatformByIndexAndEventId(self._eventId,self._index)

		local serverData = gModelCommonDreamTrip:GetPlatformEventInfo(self._eventId,self._index,self:GetExtraData())
		if serverData then
			eventRefId = serverData.eventRefId
		end
	else
		eventRefId = 2501
	end
	local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
	if not eventRef then return end

	local name = ccLngText(eventRef.name)
	self:SetWndText(self.mLblBiaoti,name)

	local choose = tonumber(eventRef.choose)
	local textRef = gModelDreamTrip:GetDreamTripTextRefByRefId(choose)
	local dec = ""
	if textRef then
		dec = ccLngText(textRef.dec)
	end
	self:SetWndText(self.mEventDesc,dec)

	local resType = eventRef.resType
	if resType == 1 then
		local res = eventRef.res
		self:SetWndEasyImage(self.mEventIcon,res,function()
			CS.ShowObject(self.mEventIcon,true)
		end)
	elseif resType == 2 then
		local prefab = eventRef.prefab
		self:CreateWndSpine(self.mEventSpinePos,prefab,prefab,false,function(dpSpine)
			CS.ShowObject(self.mEventSpinePos,true)
		end)
	end
end

function UIHopeChoice:InitText()
	self:SetTextTile(self.mDescTxt,ccClientText(28702))
	self:SetWndButtonText(self.mGoToBtn,ccClientText(28707))
end

function UIHopeChoice:InitChoiceList(list)
	list = list or self:GetChoiceList()
	local uiChoiceList = self._uiChoiceList
	if uiChoiceList then
		uiChoiceList:RefreshList(list)
	else
		uiChoiceList = self:GetUIScroll("uiChoiceList")
		self._uiChoiceList = uiChoiceList
		uiChoiceList:Create(self.mChoiceList,list,function(...) self:OnDrawChoiceCell(...) end)
	end
end

function UIHopeChoice:OnDreamTripStartEventResp(pb)
	if tonumber(pb.eventId) ~= self._eventId then return end
	local endInfo = pb.endInfo
	if not endInfo then return end
	if endInfo.state == StructDreamTripGrid.FINISH then
		--gModelCommonDreamTrip:CheckSendSpeedUpEvent(self:GetExtraData())
		self:WndClose()
	end
end

function UIHopeChoice:InitEvent()
	self:SetWndClick(self.mMask,function() self:OnClickCloseBtnFunc() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:OnClickCloseBtnFunc() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mGoToBtn,function() self:OnClickGoToBtnFunc() end)
end

------------------------- List -------------------------

function UIHopeChoice:GetChoiceList()
	local list = {}
	local typeInfoList = self._typeInfoList
	if typeInfoList then
		table.insert(list,typeInfoList[UIHopeChoice.TYPE_SEL_1])
		table.insert(list,typeInfoList[UIHopeChoice.TYPE_SEL_2])
	end
	return list
end

function UIHopeChoice:RunAni()
	local dpSpine = self:FindWndSpineByKey(self._spineKey)
	if not dpSpine then
		return
	end
	local isZ = self:GetIsZ()
	local isTrue = false
	if isZ then
		isTrue = self._selIndex == UIHopeChoice.TYPE_SEL_1
	else
		isTrue = self._selIndex == UIHopeChoice.TYPE_SEL_2
	end
	local status = isTrue and 1 or -1
	self._status = status

	self._sendMsgFunc = function()
		--gModelDreamTrip:OnDreamTripStartEventReq(self._eventId,{self._status or 1})

		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:OnDreamTripStartEventProcessor(self._eventId,{
			mapType = extraData.mapType,
			sid = extraData.sid,
			argList = {tostring(self._status or 1)},
		})
	end

	CS.ShowObject(self.mSpineRoot,true)
	self:InitChoiceList({})
	local aniName = isZ and "idle1" or "idle2"
	local typeInfoList = self._typeInfoList
	local typeInfo = isZ and typeInfoList[UIHopeChoice.TYPE_SEL_1] or typeInfoList[UIHopeChoice.TYPE_SEL_2]
	local textId = isTrue and 28726 or 28727
	dpSpine:SetAnimationCompleteFunc(function()
		--CS.ShowObject(self.mSpineRoot,false)
		--self:InitChoiceList({typeInfo})
		self:SetTextTile(self.mDescTxt,ccClientText(textId))
		self:TimerStop(self._rewardTimerKey)
		self:TimerStart(self._rewardTimerKey,self._rewardTime,false,1)
	end)
	dpSpine:PlayAnimationSolid(aniName,false)

end

function UIHopeChoice:GetExtraData()
	return self._extraData
end

function UIHopeChoice:OnDrawChoiceCell(list,item,itemdata,itempos)
	local SelImgTrans = self:FindWndTrans(item,"SelImg")
	local IconTrans = self:FindWndTrans(item,"Icon")
	local NameTrans = self:FindWndTrans(item,"Name")
	local BtnTrans = self:FindWndTrans(item,"Btn")

	local selType = itemdata.selType
	local isSel = self._selIndex and self._selIndex == selType or false
	CS.ShowObject(SelImgTrans,isSel)

	local icon = itemdata.icon
	self:SetWndEasyImage(IconTrans,icon)

	self:SetWndText(NameTrans,itemdata.name)

	self:SetWndClick(BtnTrans,function()
		self:OnClickChoiceBtnFunc(selType)
	end)
end

function UIHopeChoice:OnTimer(key)
	if key == self._rewardTimerKey then
		self:SendMsg()
	end
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIHopeChoice



