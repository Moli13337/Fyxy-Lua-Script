---
--- Created by LCM.
--- DateTime: 2024/3/28 15:27:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeMoney:LWnd
local UIHopeMoney = LxWndClass("UIHopeMoney", LWnd)

UIHopeMoney.ATTACK_TYPE_0 = 0			-- 不能攻击
UIHopeMoney.ATTACK_TYPE_1 = 1			-- 可攻击
UIHopeMoney.ATTACK_TYPE_2 = 2			-- 攻击结束
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeMoney:UIHopeMoney()
	self._waitCountDownTimerKey = "waitCountDownTimerKey"           -- 倒计时3秒开始
	self._paryTimeKey = "paryTimeKey"                               -- 游戏时间

	self._countDownTime = 3                                         -- 倒计时


	self._bxSpineKey = "bxSpineKey"
	self._mdSpineKey = "mdSpineKey"

	self._bxEffKey = "bxEffKey"
	self._bxEffTime = 1

	self._showBXEffTimerKey = "showBXEffTimerKey"

	self._showEffNum = 5
	self._startIndex = 1
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeMoney:OnWndClose()
	GF.CloseWndByName("UIOrdinSowMsg")
	--FireEvent(EventNames.ON_DREAMTRIP_CLEARANISTATUS)
	FireEvent(EventNames.ON_FDT_EVENT_CLOSEUI)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeMoney:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeMoney:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitServerData()

	--- 初始化需要，读取配置
	self:InitImgList()

	self:CreateEff()
	GF.OpenWnd("UIOrdinSowMsg")
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitTimeList()
	self:SetLimitTxt()
	self:CreateTimer(self._waitCountDownTimerKey,1,-1)
end

function UIHopeMoney:GetMoneyIndex()
	local allWeight = self._allWeight
	local ramdonNum = math.random(1,allWeight)
	local weightList = self._weightList
	for i,v in ipairs(weightList) do
		if v.minW <= ramdonNum and v.maxW >= ramdonNum then
			return i
		end
	end
	return 1
end

function UIHopeMoney:RunBXSpineAni(aniName,isLoop,func)
	local dpSpine = self:FindWndSpineByKey(self._bxSpineKey)
	if not dpSpine then return end
	isLoop = isLoop and true or false
	dpSpine:PlayAnimationSolid(aniName,isLoop)
	dpSpine:SetAnimationCompleteFunc(func)
end

function UIHopeMoney:OnStopPrayTime()
	self._attackStatus = UIHopeMoney.ATTACK_TYPE_2
	self:TimerStop(self._paryTimeKey)
	self:SendMsg()
end

function UIHopeMoney:OnClickAttackBtnFunc()
	if self._attackStatus ~= UIHopeMoney.ATTACK_TYPE_1 then return end
	local newAttackNum = self._attackNum + 1
	if newAttackNum <= self._treeClick then
		self._attackNum = newAttackNum
		self:SetLimitTxt()
	end
	self:OnRunSpineAni()
end

function UIHopeMoney:OnDrawTimeCell(list,item,itemdata,itempos)
	local ImgTrans = self:FindWndTrans(item,"Img")
	self:SetWndEasyImage(ImgTrans,itemdata,function()
		CS.ShowObject(ImgTrans,true)
	end,true)
end

function UIHopeMoney:OnRunEff()
	local effKey = self._bxEffKey .. self._startIndex
	self:CreateWndEffect(self.mBXEffRoot,"fx_mjtanlanbaoxiang",effKey,100,false,false,false,function()

	end)
	local newIndex = self._startIndex + 1
	if newIndex > self._showEffNum then
		newIndex = 1
	end
	self._startIndex = newIndex
end

function UIHopeMoney:ShowMsg()
	local rewardList = self._rewardList
	--[[	local len = #rewardList
        local randomNum = math.random(1,len)]]
	local randomNum = self:GetMoneyIndex()
	local info = rewardList[randomNum]
	if info then
		local refId = info.refId

		if self._addNum < self._treeClick then
			local num = self._rewardIdList[refId] or 0
			self._rewardIdList[refId] = num + 1
			self._addNum = self._addNum + 1
		end

		local itemId = info.itemId
		local itemNum = info.itemNum
		local name = gModelItem:GetNameByRefId(itemId)
		local numStr = LUtil.NumberCoversion(itemNum)

		local str = string.replace(ccClientText(28720),name,numStr)
		FireEvent(EventNames.ON_DREAMTRIP_SHOWMSG,3,str,self.mLimitTxt)

		if self._addNum >= self._treeClick then
			self:OnStopPrayTime()
		end
	end
end

function UIHopeMoney:OnRunWaitCountDownTimer()
	local countDownTime = self._countDownTime
	local img = self._countDownImgList[countDownTime]
	self:SetWndEasyImage(self.mCountDownImg,img,function()
		CS.ShowObject(self.mCountDownImg,true)
	end)
	self._countDownTime = countDownTime - 1
	if self._countDownTime < 0 then
		self._attackStatus = UIHopeMoney.ATTACK_TYPE_1
		CS.ShowObject(self.mCountDownBg,false)
		self:TimerStop(self._waitCountDownTimerKey)
		self:CreateTimer(self._paryTimeKey,1,-1)
		CS.ShowObject(self.mCountDownImg,false)
	end
end

------------------------- List -------------------------


function UIHopeMoney:GetTimeList()
	local countDownImgList = self._countDownImgList
	local list = {}
	local changeParyTime = self._changeParyTime
	local min = 0
	if changeParyTime > 3600 then
		min = math.floor(changeParyTime / 60) % 60
	end
	local zeroImg = countDownImgList[0]
	if min == 0 then
		table.insert(list,zeroImg)
		table.insert(list,zeroImg)
	else
		local tD = math.floor(min / 10)
		local sD = min % 10
		table.insert(list,countDownImgList[tD])
		table.insert(list,countDownImgList[sD])
	end
	table.insert(list,"activity_music1_ui_5")
	local sec = math.floor(changeParyTime) % 60
	if sec == 0 then
		table.insert(list,zeroImg)
		table.insert(list,zeroImg)
	else
		local tD = math.floor(sec / 10)
		local sD = sec % 10
		table.insert(list,countDownImgList[tD])
		table.insert(list,countDownImgList[sD])
	end
	return list
end

function UIHopeMoney:OnFDTEventFinish(recordFinishMap,pb)
	if not recordFinishMap[self._eventId] then return end
	self:WndClose()
end

function UIHopeMoney:OnRunParyTimer()
	self:InitTimeList()
	self._attackStatus = UIHopeMoney.ATTACK_TYPE_1
	self._changeParyTime = self._changeParyTime - 1
	if self._changeParyTime < 0 then
		self:OnStopPrayTime()
	end
end

function UIHopeMoney:SetLimitTxt()
	local str = string.replace(ccClientText(28718),self._attackNum,self._treeClick)
	self:SetWndText(self.mLimitTxt,str)
end

function UIHopeMoney:InitMsg()
	self:WndEventRecv(EventNames.ON_FDT_EVENT_FINISH,function(...) self:OnFDTEventFinish(...) end)
	self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList) self:WndClose() end)
end

function UIHopeMoney:InitTimeList()
	local list = self:GetTimeList()
	local uiTimeList = self._uiTimeList
	if uiTimeList then
		uiTimeList:RefreshList(list)
	else
		uiTimeList = self:GetUIScroll("uiTimeList")
		self._uiTimeList = uiTimeList
		uiTimeList:Create(self.mTimeList,list,function(...) self:OnDrawTimeCell(...) end)
	end
end

function UIHopeMoney:SendMsg()
	local rewardIdList = self._rewardIdList
	local rewardStr
	for rewardId,num in pairs(rewardIdList) do
		local str = rewardId .. "=" .. num
		if rewardStr then
			rewardStr = rewardStr .. ";" .. str
		else
			rewardStr = str
		end
	end
	gModelFastDreamTrip:OnDreamTripStartEventReq(self._eventId,{rewardStr})
end

function UIHopeMoney:InitData()

	local eventRefId = self._eventRefId

	local rewardIdList = {}
	local rewardList = gModelFastDreamTrip:GetDreamTripRewardListByByEventRefId(eventRefId)
	for idx,val in ipairs(rewardList) do
		table.insert(rewardIdList,val)
	end

	local allWeight = 0
	local weightList = {}
	for i,v in ipairs(rewardIdList) do
		local weight = v.weight
		local oldWeight = allWeight + 1
		allWeight = allWeight + weight
		table.insert(weightList,{
			minW = oldWeight,
			maxW = allWeight,
		})
	end
	self._weightList = weightList
	self._allWeight = allWeight
	self._rewardList = rewardIdList

	--- 祈愿事件：游戏参与时间s
	self._treeTime = gModelFastDreamTrip:GetConfigByKey("treeTime")

	self._treeClick = gModelFastDreamTrip:GetConfigByKey("treeClick")

	self:InitChangeData()
end

function UIHopeMoney:CreateTimer(key,time,loopCnt)
	self:TimerStop(key)
	self:TimerStart(key,time,false,loopCnt)
end

function UIHopeMoney:RunMDSpineAni(aniName,isLoop,func)
	local dpSpine = self:FindWndSpineByKey(self._mdSpineKey)
	if not dpSpine then return end
	isLoop = isLoop and true or false
	dpSpine:PlayAnimationSolid(aniName,isLoop)
	dpSpine:SetAnimationCompleteFunc(func)
end

function UIHopeMoney:InitEvent()
	self:SetWndClick(self.mAttackBtn,function() self:OnClickAttackBtnFunc() end)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
end


function UIHopeMoney:InitImgList()
	local countDownImgList
	local mdSpineName
	local mdConfigPos
	local monsterSpineName
	local monsConfigPos
	local bombEff
	local isHaveAttr = true
	local image = gModelFastDreamTrip:GetDreamTripEventImageByRefId(self._eventRefId)
	if not string.isempty(image) then
		local imageList = string.split(image,ModelDreamTrip.EVENTREF_IMAGE_SPLIT)
		--- 背景大图
		local bg = imageList[1]
		if not string.isempty(bg) then
			self:SetWndEasyImage(self.mBg,bg)
		end

		--- 标题底图
		local titleBg = imageList[2]
		if not string.isempty(titleBg) then
			self:SetWndEasyImage(self.mTimeCountDownBg,titleBg,nil,true)
		end

		--- 倒计时图片
		local countDownImg = imageList[3]
		if not string.isempty(countDownImg) then
			countDownImgList = {}
			local countDownImageList = string.split(countDownImg,",")
			for i,v in ipairs(countDownImageList) do
				v = string.split(v,"=")
				countDownImgList[tonumber(v[1])] = v[2]
			end
		end

		--- 是否有小人
		local haveAttr = imageList[4]
		if not string.isempty(haveAttr) then
			haveAttr = tonumber(haveAttr)
			isHaveAttr = haveAttr == 1
		end

		if isHaveAttr then
			--- 小人素材
			local matter = imageList[5]
			if not string.isempty(matter) then
				mdSpineName = matter
			end

			--- 小人位置
			local pos = imageList[6]
			if not string.isempty(pos) then
				mdConfigPos = pos
			end
		end

		--- 怪物素材
		local monster = imageList[7]
		if not string.isempty(monster) then
			monsterSpineName = monster
		end

		--- 怪物位置
		local monPos = imageList[8]
		if not string.isempty(monPos) then
			monsConfigPos = monPos
		end

		local clickEff = imageList[9]
		if not string.isempty(clickEff) then
			bombEff = clickEff
		end
	end

	self._bombEff = bombEff or "fx_mjtanlanbaoxiang"

	if mdConfigPos then
		mdConfigPos = string.split(mdConfigPos,",")
		self.mSpinePos.localPosition = Vector3(tonumber(mdConfigPos[1]),tonumber(mdConfigPos[2]),tonumber(mdConfigPos[3]))
	end
	if isHaveAttr then
		mdSpineName = mdSpineName or "Modai"
		self:CreateWndSpine(self.mSpinePos,mdSpineName,self._mdSpineKey,false,function()
			self:RunMDSpineAni("idle1",true)
		end)
	end
	CS.ShowObject(self.mSpinePos,isHaveAttr)

	if monsConfigPos then
		monsConfigPos = string.split(monsConfigPos,",")
		self.mBaoxiangPos.localPosition = Vector3(tonumber(monsConfigPos[1]),tonumber(monsConfigPos[2]),tonumber(monsConfigPos[3]))
	end
	monsterSpineName = monsterSpineName or "Tanlanbaoxiang"
	self:CreateWndSpine(self.mBaoxiangPos,monsterSpineName,self._bxSpineKey,false,function()
		self:RunBXSpineAni("idle",true)
	end)


	countDownImgList = countDownImgList or {
		[0] = "activity_music1_num_0",
		[1] = "activity_music1_num_1",
		[2] = "activity_music1_num_2",
		[3] = "activity_music1_num_3",
		[4] = "activity_music1_num_4",
		[5] = "activity_music1_num_5",
		[6] = "activity_music1_num_6",
		[7] = "activity_music1_num_7",
		[8] = "activity_music1_num_8",
		[9] = "activity_music1_num_9",
	}
	self._countDownImgList = countDownImgList
end

function UIHopeMoney:InitServerData()
	---@type StructDreamTripEventInfo
	local eventInfo = self:GetWndArg("eventInfo")
	self._eventInfo = eventInfo

	local gameParams = self:GetWndArg("gameParams")
	self._gameParams = gameParams

	self._eventId = eventInfo.eventId
	self._index = eventInfo.index
	self._eventRefId = eventInfo.eventRefId
	self._eventType = eventInfo.eventType
end

function UIHopeMoney:OnRunSpineAni()
	self:RunMDSpineAni("attack1",false,function()
		self:RunMDSpineAni("idle1",true)
	end)
	--[[	if not self:IsTimerExist(self._showBXEffTimerKey) then
            CS.ShowObject(self.mBXEffRoot,true)
            self:CreateTimer(self._showBXEffTimerKey,self._bxEffTime,1)
        end]]

	self:OnRunEff()

	self:RunBXSpineAni("hit",false,function()
		self:RunBXSpineAni("idle",true)
	end)
	self:ShowMsg()
end

function UIHopeMoney:OnDreamTripStartEventResp(pb)
	if pb.eventId ~= self._eventId then return end
	local endInfo = pb.endInfo
	if not endInfo then return end
	if endInfo.state == StructDreamTripGrid.FINISH then
		self:WndClose()
	end
end

function UIHopeMoney:CreateEff()
	local eff = self._bombEff or "fx_mjtanlanbaoxiang"
	for i = 1,self._showEffNum do
		local effKey = self._bxEffKey .. i
		self:CreateWndEffect(self.mBXEffRoot,eff,effKey,100,false,false,false,function()

		end)
	end
	CS.ShowObject(self.mBXEffRoot,true)
end

function UIHopeMoney:InitChangeData()
	self._changeParyTime = self._treeTime

	self._attackStatus = UIHopeMoney.ATTACK_TYPE_0
	self._attackNum = 0
	self._addNum = 0
	self._rewardIdList = {}
end

function UIHopeMoney:OnTimer(key)
	if key == self._paryTimeKey then
		self:OnRunParyTimer()
	elseif key == self._waitCountDownTimerKey then
		self:OnRunWaitCountDownTimer()
	elseif key == self._showBXEffTimerKey then
		self:TimerStop(self._showBXEffTimerKey)
		CS.ShowObject(self.mBXEffRoot,false)
	end
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIHopeMoney



