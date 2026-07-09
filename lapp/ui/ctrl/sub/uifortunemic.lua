---
--- Created by Administrator.
--- DateTime: 2023/10/25 11:21:46
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UIFortuneMic:LChildWnd
local UIFortuneMic = LxWndClass("UIFortuneMic", LChildWnd)
local typeOfRectTransform = typeof(UnityEngine.RectTransform)

--刷新特效key
local RESET_EFFECT_KEY = "shuaxin"
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFortuneMic:UIFortuneMic()

	-- 魔轮物品索引list
	self._itemIndexList = {}

	-- 魔轮物品遮罩
	self._itemMaskList = {}

	-- 魔轮物品格子
	self._itemEffectTransList = {}


	-- 奖励 icon 类
	---@type table<number,CommonIcon>
	self._itemIconList = {}

	self._canClick = true
	self._isShowItem = true
	self._isPlayResetAnimation = false
	self._showItemTimer = nil
	self._showItemCoinTimer = nil
	self._canClickTimer = nil
	self._effectList = nil
	self._playingAnimationItemIndex = 0
	self._playingAnimationItemCoinIndex = 0
	self._isShowClickWaitMsg = true
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFortuneMic:OnWndClose()
	self._canClick = true
	self._isShowClickWaitMsg = true
	self._isShowItem = true
	self:ClearAllTime()
	self._isPlayResetAnimation = false
	self:ClearResetEffect()
	self:ClearResetTime()
	self:ClearCanClickTime()
	self:ClearStopResetItemAnimationTimer()
	self._itemEffectTransList = {}
	self._playingAnimationItemIndex = 0

	if self._luckSliderUp then
		self._luckSliderUp:CleanUp()
	end

	if self._itemIconList then
		for k,v in pairs(self._itemIconList) do
			v:Destroy()
			self._itemIconList[k] = nil
		end
		self._itemIconList = nil
	end

	if self._miracleSliderUp then
		self._miracleSliderUp:CleanUp()
	end

	self:OpenUIAward()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFortuneMic:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFortuneMic:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMsg()

	self._lightGrid = CS.FindTrans(self.mGridList,"Grid1")
	self._purpleLightGrid = CS.FindTrans(self.mPurpleGridList, "Grid1")


	gModelCallHero:CallOpt(self._page,self._subPage)

	self:CreateWndEffect(self.mRunBtn1,"fx_ui_XLZH_anniu","btn1",100)
	self:CreateWndEffect(self.mRunBtn2,"fx_ui_XLZH_anniu","btn1",100)
	self:SetWndToggleValue(self.mShowToggle,not gModelCallHero:GetLuckyMagicIsEff())
	self:SetWndText(self.mShowToggleXUIText, ccClientText(14617))
end


---- 刷新奖励动画 ------------------------------------------------------------------------------------------------------

--开始刷新奖励动画
function UIFortuneMic:PlayResetAnimation()
	self._isPlayResetAnimation = true

	local isEff = gModelCallHero:GetLuckyMagicIsEff()
	if isEff then
		self:PlayUpdateEff()
	end

	--请求刷新道具数据
	gModelCallHero:OnMagicWheelResetReq(self._curMagicWheelType)
end

-- 再来一次
function UIFortuneMic:OnComeAgain(moreNum,type)
	local wheelType = moreNum > 3 and 2 or 1
	self._isPlayAnimation = false
	self:OnTurnClickBtn(type,wheelType, true)
end

-- 播放轮盘闲置动画
function UIFortuneMic:StartTurnTableIdle(luckMagicWheelType)
	self:SetTurnTableTransByType(luckMagicWheelType)
	-- 闲置动画不用太快，弄个最慢的速度
	self:OnTimerStart(self._magicWheelDownCountKeyList[1],self._speedLevel[#self._speedLevel])
end

-- 转动按钮点击表现
function UIFortuneMic:ChangeMagicWheelBtn(btnType)
	local ClickText = "ClickText"
	local isClickStr = "IsClick"
	local NoClick1 = self:FindWndText(CS.FindTrans(self.mLuckTurnTableTypeBtn1,ClickText .. 1))
	local NoClick2 = self:FindWndText(CS.FindTrans(self.mLuckTurnTableTypeBtn2,ClickText .. 2))
	local IsClick1 = CS.FindTrans(self.mLuckTurnTableTypeBtn1,isClickStr)
	local IsClick2 = CS.FindTrans(self.mLuckTurnTableTypeBtn2,isClickStr)

	local funcId = 16700001
	if btnType == UIFortuneMic.MAGIC_WHEEL_LUCK then
		self:SetXUITextColor(NoClick1,LUtil.ColorByHex("FFFFFFFF"))
		self:SetXUITextColor(NoClick2,LUtil.ColorByHex("c5ccedFF"))
		CS.ShowObject(IsClick1,true)
		CS.ShowObject(IsClick2,false)



	else
		funcId = 16700011
		self:SetXUITextColor(NoClick1,LUtil.ColorByHex("c5ccedFF"))
		self:SetXUITextColor(NoClick2,LUtil.ColorByHex("FFFFFFFF"))
		CS.ShowObject(IsClick1,false)
		CS.ShowObject(IsClick2,true)
	end

	gModelRedPoint:SetRedPointClicked(funcId)
end


function UIFortuneMic:InitMsg()
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function ()
		gModelCallHero:CallOpt(self._page,self._subPage)
	end)
	---------------------------------- 魔轮 -----------------------------
	-- 魔轮信息返回
	self:WndNetMsgRecv(LProtoIds.MagicWheelInfoResp, function(pb, ret)
		local showItem =  pb.type == UIFortuneMic.MAGIC_WHEEL_LUCK and gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelExpend") or gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighExpend")
		self:SetNeedItemNum()

		self._isShowItem = true
		self:StopResetAnimation()

		self:LuckMagicWheelInitData(tonumber(pb.type),pb)
		self:ChangeMagicWheelBtn(pb.type)

		self:RefreshLimitNum()
	end)

	-- 魔轮重置返回
	self:WndNetMsgRecv(LProtoIds.MagicWheelResetResp, function(pb, ret)
		self:ChangeTurnTableData(pb.info)
		self:SetNeedItemNum()
	end)

	self:WndEventRecv(EventNames.On_Item_Change,function()
		self:SetNeedItemNum()
	end)

	-- 魔轮抽取返回（奖励不走通用）
	self:WndNetMsgRecv(LProtoIds.MagicWheelResp, function(pb, ret)
		LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_LUCKY_MIRROR)
		self:SetNeedItemNum()

		self._receiveList = pb.rewardItems
		self._allRewardList = pb.items
		self._itemDetail = pb.itemDetail
		local target = self:GetWheelItemIndexByID(pb.rewardItems[1])
		self:ShowLuckValue(pb.luckyCount,self._curMagicWheelType == UIFortuneMic.MAGIC_WHEEL_LUCK and self._luckSliderUp or self._miracleSliderUp)

		if self._isPlayAnimation and target then
			self:StartPlayTurnTable(tonumber(pb.type),target)
		else
			self._isPlayAnimation = true
			self:OpenUIAward()
			if self._allRewardList and self._uiItemList then
				self:ChangeItem(self._allRewardList,self._uiItemList)
			end
		end

		self:RefreshLimitNum()
	end)

	-- 魔轮幸运奖励领取返回（奖励走通用）
	self:WndNetMsgRecv(LProtoIds.MagicLuckyReceiveResp, function(pb, ret)
		self._luckyReceiveList = pb.luckyReceive

		self:ShowLuckValue(pb.luckyCount,self._curMagicWheelType == UIFortuneMic.MAGIC_WHEEL_LUCK and self._luckSliderUp or self._miracleSliderUp)
	end)
	self:SetWndToggleDelegate(self.mShowToggle,function (value)
		gModelCallHero:SetLuckyMagicIsEff(not value)
	end)
	---------------------------------- 魔轮 -----------------------------
end

-- 设置物品遮罩
function UIFortuneMic:SetItemMaskShow(refid,num)
	local index = self._itemIndexList[refid]
	local mask = self._itemMaskList[index]
	CS.ShowObject(mask,self:IsReceiveWheelItem(refid,num))
end



UIFortuneMic.MAGIC_WHEEL_LUCK = 0                -- 幸运魔轮
UIFortuneMic.MAGIC_WHEEL_MIRACLE = 1             -- 奇迹魔轮
UIFortuneMic.MAGIC_WHEEL_LUCK_KEY = "magicWheelLuck"
UIFortuneMic.MAGIC_WHEEL_MIRACLE_KEY = "magicWheelMiracle"

function UIFortuneMic:InitData()
	self._page = self:GetWndArg("page") or 1
	self._subPage = self:GetWndArg("subPage") or 1
	---------------------------------- 魔轮 -----------------------------
	-- 是否播放抽奖动画
	self._isPlayAnimation = true

	-- 当前抽奖动画是否播放完毕
	self._turnTableAnimationEnd = true

	-- 当前轮盘类型：幸运 or 奇迹
	self._curMagicWheelType = 0

	-- 当前轮盘动画阶段
	self._curAnimation = 1

	-- 轮盘当前格子
	self._curGridIndex = 0

	-- 轮盘上一个格子
	self._lastGridIndex = 0

	-- 1次 or 15次
	self._wheelType = nil

	-- 轮盘转速key值
	self._magicWheelDownCountKeyList = {
		"_magicWheelDownCountKey1",
		"_magicWheelDownCountKey2",
	}

	-- 控制轮盘阶段转速key值
	self._magicWheelIntervalKeyList = {
		"_magicWheelIntervalKey1",
		"_magicWheelIntervalKey2",
	}

	-- 延迟播放待机动画
	self._magicDelayPlayAnimKey = "_magicDelayPlayAnimKey"
	self._timerList = {}

	-- 降速阶段轮盘目标列表
	self._targetList = {}

	-- 轮盘转速：数值越小越快
	self._speedLevel = {
		[1] = 0.01,
		[2] = 0.5,
		[3] = 0.3,
		[4] = 0.6,
	}

	-- 轮盘阶段间隔
	self._timeInterval = {
		[1] = 0.8,
		[2] = 0.01,
		--[3] = 0.2,
		--[4] = 0.01,
	}

	-- 魔轮动画控制参数：圈数
	self._turnCount = 3
	-- 魔轮动画控制参数：几个格子起降速
	self._decelerationGridCount = 5
	-- 魔轮动画控制参数：速率，越大越慢
	self._multiple = 2

	self._showItemEffectKey = "showItemEffectKey"
	self._showItemIconKey = "showItemIconKey"

	---------------------------------- 魔轮 -----------------------------
end

-- 开始转动抽奖轮盘
function UIFortuneMic:StartPlayTurnTable(luckMagicWheelType,targetItemIndex)

	if not luckMagicWheelType and not targetItemIndex then
		return
	end

	self._turnTableAnimationEnd = false

	self._targetItemIndex = targetItemIndex

	self:GetTurnTableAnimationData(targetItemIndex)

	self:SetTurnTableTransByType(luckMagicWheelType)

	-- 转动速度
	self:OnTimerStart(self._magicWheelDownCountKeyList[1],self._speed)--self._speedLevel[self._curAnimation])

	-- 下一个阶段转速
	self:OnTimerStart(self._magicWheelIntervalKeyList[1],self._timeInterval[self._curAnimation])

end

function UIFortuneMic:SetUpdateTime(freeTime,trans,updateTimeBg,freeBtn,key)
	local remainTime = freeTime - GetTimestamp()
	local str = ccClientText(14608) .. LUtil.FormatColorStr(LUtil.FormatTimespanNumber(remainTime),"green")

	self:SetWndText(trans,str)
	CS.ShowObject(updateTimeBg,true)
	if remainTime <= 0 then
		CS.ShowObject(updateTimeBg,false)
		CS.ShowObject(trans,false)
		CS.ShowObject(freeBtn,true)
		self:SetWndClick(freeBtn, function()
			self:OnUpdateClickBtn(true,"")
		end)
		self:ClearTimer(true,key)
	end
end

-- 计算轮盘动画数据
function UIFortuneMic:GetTurnTableAnimationData(targetGridIndex)
	self._targetList = {}

	local gridCount = self._turnCount * 8
	self._speed = self._timeInterval[1] / gridCount
	self._targetIndex = self._decelerationGridCount

	local targetGridIndex1 = targetGridIndex - self._decelerationGridCount
	targetGridIndex1 = targetGridIndex1 < 0 and 8 + targetGridIndex1 or targetGridIndex1

	for i = 1, self._decelerationGridCount do
		local value = targetGridIndex1 + 1
		targetGridIndex1 = value > 8 and 1 or value
		table.insert(self._targetList,1,targetGridIndex1)
	end

	self._targetItemIndex = self._targetList[#self._targetList]
end

-- 刷新转盘
function UIFortuneMic:ChangeTurnTableData(pb)

	-- 转轮物品:所有魔轮奖励物品
	self._allRewardList = pb.items

	self:ChangeItem(self._allRewardList,self._uiItemList)

	self:ShowUpdateBtn(self._curMagicWheelType,pb)

	self:ShowStartTurnTableBtn(self._curMagicWheelType)
	-- 轮盘闲置动画
	if not self._isShowItem then return end
	self:ShowTurnTableAnimation()
end

-- 显示幸运值
function UIFortuneMic:ShowLuckValue(value,slider)
	if not value then
		return
	end

	local boxCount = #self._luckRefList
	self:SetWndText(self._CurLuckValueText,value)
	local maxValue = self._luckRefList[boxCount].grad
	self._luckCountNum = maxValue
	local curValue = value
	--local progress = curValue / maxValue
	local grid = 1 / boxCount
	local interval = grid * 480  -- 幸运条预制体宽480
	local curInterval = interval

	local curBoxNum = 0
	local curBoxIndex = 0

	--self:ClearAllEff()

	for i = 1, 5 do
		local str = "LuckCase" .. i
		local root = CS.FindTrans(self._LuckValue,str)
		local rootRect = root:GetComponent(typeOfRectTransform)
		local ref =  self._luckRefList[i]
		local gradReward = ref.gradReward or ""
		local grad = ref.grad or ""
		local luckID = ref.refId or ""
		local isReceive = self:IsReceiveLuckBox(luckID)

		local noUse = CS.FindTrans(root,"noUse")
		local isUse = CS.FindTrans(root,"isUse")
		local Use = CS.FindTrans(root,"Use")
		local valueBg = CS.FindTrans(root,"valueBg")
		local redPoint = CS.FindTrans(root,"redPoint")
		local text = CS.FindTrans(valueBg,"UIText")
		CS.ShowObject(noUse,false)
		CS.ShowObject(isUse,false)
		CS.ShowObject(Use,false)
		CS.ShowObject(redPoint,false)
		self:SetWndText(text,grad)

		rootRect.anchoredPosition = Vector3.New(curInterval or 0,rootRect.anchoredPosition.y or 0 ,0)
		curInterval = curInterval + interval

		if curValue >= grad then
			curBoxNum = grad
			curBoxIndex = i
			if isReceive then
				CS.ShowObject(isUse,true)
				-- 已领取
				self:SetWndClick(isUse, function()
					self:OnClickBox(isUse,gradReward)
				end)
			else
				CS.ShowObject(Use,true)
				self:CreateBoxEffect(Use,self._luckType..i)
				-- 可领取
				self:SetWndClick(Use, function()
					gModelCallHero:OnMagicLuckyReceiveReq({luckID})
				end)
			end
		else
			CS.ShowObject(noUse,true)
			-- 不可领取
			self:SetWndClick(noUse, function()
				self:OnClickBox(noUse,gradReward)
			end)
		end
	end

	local nextBoxIndex = curBoxIndex + 1
	nextBoxIndex = nextBoxIndex > boxCount and boxCount or nextBoxIndex
	local nextBoxNum = self._luckRefList[nextBoxIndex].grad
	local gridValue = nextBoxNum - curBoxNum
	local progress = (grid * curBoxIndex) + (((value - curBoxNum)/gridValue) * grid)

	slider:SetUIProgress(progress)

end

-- 显示刷新按钮状态
function UIFortuneMic:ShowUpdateBtn(luckMagicWheelType,pb)
	local updateBtn1,updateBtn2,updateTimeBg,dia,updateTime,freeRefTime,diaValue

	if luckMagicWheelType == UIFortuneMic.MAGIC_WHEEL_LUCK then
		updateBtn1 = self.mUpdateBtn1
		updateBtn2 = self.mUpdateBtn2
		updateTimeBg = self.mUpdateTimeBg
		dia = self.mDia
		updateTime = self.mUpdateTime
		freeRefTime = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelFreeRefTime")
		diaValue = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelRefExpend")
		self:SetUpdateBtnTime(pb.freeTime,self.mUpdateTimeText,updateTimeBg,self.mUpdateClick,UIFortuneMic.MAGIC_WHEEL_LUCK_KEY)

		self:SetWndClick(self.mUpdateClick, function()
			self:OnUpdateClickBtn(self._isFreeUpdate,diaValue)
		end)
	else
		updateBtn1 = self.mPurpleUpdateBtn1
		updateBtn2 = self.mPurpleUpdateBtn2
		updateTimeBg = self.mPurpleUpdateTimeBg
		dia = self.mPurpleDia
		updateTime = self.mPurpleUpdateTime
		freeRefTime = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighFreeRefTime")
		diaValue = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighRefExpend")
		self:SetUpdateBtnTime(pb.freeTime,self.mPurpleUpdateTimeText,updateTimeBg,self.mPurpleUpdateClick,UIFortuneMic.MAGIC_WHEEL_MIRACLE_KEY)

		self:SetWndClick(self.mPurpleUpdateClick, function()
			self:OnUpdateClickBtn(self._isFreeUpdate,diaValue)
		end)
	end

	CS.ShowObject(updateBtn2,self._isFreeUpdate)
	CS.ShowObject(updateBtn1,not self._isFreeUpdate)

	if not self._isFreeUpdate then
		self._updateExpend = diaValue     -- 刷新消耗
		self:SetDiaValueShow(dia,diaValue,true)
	end

end

--结束刷新奖励动画
function UIFortuneMic:StopResetAnimation()
	self._isPlayResetAnimation = false
	self:ClearResetEffect()
	self._playingAnimationItemIndex = 0
	self._playingAnimationItemCoinIndex = 0
	self:ClearResetTime()
end


function UIFortuneMic:ClearAllTime(request)
	if request then
		if gModelCallHero then gModelCallHero:CallOpt(self._page) end
	end

	if self._timerList then
		for k,v in pairs(self._timerList) do
			LxTimer.DelayTimeStop(v)
		end
		self._timerList = {}
	end
end

-- 设置钻石数量
function UIFortuneMic:SetDiaValueShow(rootTrans,itemStr,show)
	local expendList = string.split(itemStr,"=")
	local type = tonumber(expendList[1])
	local itemId = tonumber(expendList[2])
	local value = tonumber(expendList[3])

	if rootTrans and value then
		local DiaValue = CS.FindTrans(rootTrans,"DiaValue")
		self:SetWndText(DiaValue,value)
	end

	local itemImage = gModelItem:GetItemImgByRefId(itemId)
	local runBtn2ImageTrans = CS.FindTrans(rootTrans,"DiaImage")

	self:SetWndEasyImage(runBtn2ImageTrans,itemImage)

	CS.ShowObject(rootTrans,show)
end

function UIFortuneMic:PlayUpdateEff()
	--为道具格子的刷新特效做准备
	self:ClearResetTime()
	self._isShowItem    = false
	self._showItemTimer = LxTimer.DelayTimeCall(function()
		self._isShowItem = true
		self:TimerStop(self._showItemEffectKey)
		self:PlayerResetItemAnimation()
		self:TimerStart(self._showItemEffectKey,0.1,false,7)
	end, 0.7)

	self._showItemCoinTimer  = LxTimer.DelayTimeCall(function()
		self:TimerStop(self._showItemIconKey)
		self:PlayerShowItemIconAnimation()
		self:TimerStart(self._showItemIconKey,0.1,false,8)
	end, 0.8)

	--点击间隔
	self:ClearCanClickTime()
	self._canClick = false
	local magicWheelRefTime = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelRefTime") or 1
	self._canClickTimer = LxTimer.DelayTimeCall(function()
		self._canClick = true
		self._isShowClickWaitMsg = true
	end, magicWheelRefTime)

	--转盘特效
	if not self._effectList then
		self._effectList = {}
	end
	self:CreateResetEffect()
end

-- 刷新物品
function UIFortuneMic:ChangeItem(pbItemList,itemListRootTrans)

	local index = 1

	-- 魔轮物品索引list
	self._itemIndexList = {}

	-- 魔轮物品遮罩
	self._itemMaskList = {}

	self._itemEffectTransList = {}

	local itemIconList = self._itemIconList or {}

	self._itemIconList = itemIconList

	for i, v in ipairs(pbItemList) do
		local extractCount = v.extractCount
		local itemId = tonumber(v.itemId)

		local itemTrans = CS.FindTrans(itemListRootTrans,"Item" .. i)
		local iconRootTrans = CS.FindTrans(itemTrans,"IconRoot")
		local iconTrans = CS.FindTrans(iconRootTrans,"Icon")
		local itemEffectTrans = CS.FindTrans(iconRootTrans,"Effect")
		self._itemEffectTransList[i] = {
			itemTrans = itemTrans,
			iconTrans = iconTrans,
			effectTrans = itemEffectTrans,
		}

		if itemId and itemId > 0 then
			self._itemIndexList[itemId] = index
			local maskTrans = CS.FindTrans(iconRootTrans,"Mask")
			CS.ShowObject(maskTrans,self:IsReceiveWheelItem(itemId,extractCount))

			local ref = gModelCallHero:GetMagicWheelRewardRefByRefId(itemId)
			local reward = ref.reward

			local instanceId = itemTrans:GetInstanceID()

			local cls = itemIconList[instanceId]
			if not cls then
				cls = CommonIcon:New()
				itemIconList[instanceId] = cls
				cls:Create(iconTrans)
			end

			cls:SetCommonRewardByStr(reward)
			cls:DoApply()

			self:SetWndClick(iconRootTrans, function()
				self:OnItemIconClick(instanceId)
			end)

			table.insert(self._itemMaskList,maskTrans)
			index = index + 1
		end

		CS.ShowObject(itemTrans, self._isShowItem)
		CS.ShowObject(iconTrans, true)
	end
end

-- 重置刷新时间
function UIFortuneMic:SetUpdateBtnTime(freeTime,trans,updateTimeBg,freeBtn,key)
	local curTime = GetTimestamp()
	local timer = self._timerList[key]
	freeTime = tonumber(freeTime) / 1000

	if freeTime > curTime then
		if not timer then
			CS.ShowObject(updateTimeBg,true)
			self:SetUpdateTime(freeTime,trans,updateTimeBg,freeBtn,key)
			self._timerList[key] = LxTimer.LoopTimeCall(function()
				self:SetUpdateTime(freeTime,trans,updateTimeBg,freeBtn,key)
			end, 1, false, -1)
		end

		self._isFreeUpdate = false
	else
		CS.ShowObject(updateTimeBg,false)
		self._isFreeUpdate = true
	end
end

function UIFortuneMic:ClearTimer(request,index)
	local timerList = self._timerList
	local timer = timerList[index]
	if timer then
		LxTimer.DelayTimeStop(timer)
		timerList[index] = nil
	end
	if request then
		gModelCallHero:CallOpt(self._page)
	end
end

-- 创建刷新奖励特效
function UIFortuneMic:CreateResetEffect()
	table.insert(self._effectList, RESET_EFFECT_KEY)
	self:CreateWndEffect(self.mResetEffect,"fx_ui_xingyunmolun_shuaxin",RESET_EFFECT_KEY,
			100,false,false)
end

function UIFortuneMic:StopResetItemAnimation()
	self:ClearStopResetItemAnimationTimer()
	self._stopResetItemAnimationTimer = LxTimer.DelayTimeCall(function()
		self:StopResetAnimation()

		if not self:IsTimerExist(self._magicWheelIntervalKeyList[1]) then
			self:ShowTurnTableAnimation()
		end
	end, 1)
end

---- 特效 --------------------------------------------------------------------------------------------------------------

-- 创建宝箱特效
function UIFortuneMic:CreateBoxEffect(trans,key)
	if not trans then
		return
	end
	local key = key
	self:CreateWndEffect(trans,"fx_richangbaoxiang",key,100,false,false)
end
------------------------------ 幸运魔轮 ------------------------------

function UIFortuneMic:SetNeedItemNum()
	local showItem = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelResources")
	local showItemList = string.split(showItem, "|")
	local itemList = {}
	for i,v in ipairs(showItemList) do
		v = string.split(v,"=")
		table.insert(itemList,{refId = tonumber(v[2])})
	end

	self:InitItemList(itemList)
end

function UIFortuneMic:OnTimer(key)
	if key == self._magicWheelDownCountKeyList[1] then
		self:PlayTurnAnimation()
	end

	if key == self._magicWheelIntervalKeyList[1] then

		----多阶段动画
		--if self._curAnimation < #self._timeInterval then
		--    self._curAnimation = self._curAnimation + 1
		--    -- 转动速度
		--    self:OnTimerStart(self._magicWheelDownCountKeyList[1],self._speedLevel[self._curAnimation])
		--    -- 下一个阶段转速
		--    self:OnTimerStart(self._magicWheelIntervalKeyList[1],self._timeInterval[self._curAnimation])
		--elseif self._curAnimation == #self._timeInterval then
		--    -- 最后一个阶段要计算目标了
		--    -- 看下是否已经过了目标
		--    if self._curGridIndex - 1  == self._targetItemIndex  then
		--        self._curAnimation = 1
		--        self:TimerStop(self._magicWheelDownCountKeyList[1])
		--        self:TimerStop(self._magicWheelIntervalKeyList[1])
		--    else
		--        ---- 转动速度
		--        --self:OnTimerStart(self._magicWheelDownCountKeyList[1],self._speedLevel[#self._speedLevel])
		--        -- 避免检测失误
		--        self:OnTimerStart(self._magicWheelIntervalKeyList[1],0.01)
		--    end
		--end

		---- 双阶段动画
		--if self._curAnimation < #self._timeInterval then
		--    if self._curGridIndex  == self._targetItemIndex  then
		--        self._curAnimation = self._curAnimation + 1
		--
		--        local index = self._targetItemIndex + 3
		--        self._targetItemIndex = index > 8 and 8 or index
		--        -- 转动速度
		--        self:OnTimerStart(self._magicWheelDownCountKeyList[1],self._speedLevel[self._curAnimation])
		--    end
		--    -- 避免检测失误
		--    self:OnTimerStart(self._magicWheelIntervalKeyList[1],0.01)
		--
		--elseif self._curAnimation == #self._timeInterval then
		--    if self._curGridIndex  == self._targetItemIndex then
		--        self._curAnimation = 1
		--        self._turnTableAnimationEnd = true
		--        self:TimerStop(self._magicWheelDownCountKeyList[1])
		--        self:TimerStop(self._magicWheelIntervalKeyList[1])
		--    end
		--end

		-- 转盘动画3.0
		if self._curAnimation < #self._timeInterval then
			if self._curGridIndex  == self._targetItemIndex  then
				self._targetIndex = self._targetIndex - 1
				if self._targetIndex == 0 then
					self._curAnimation = self._curAnimation + 1
				else
					self._targetItemIndex = self._targetList[self._targetIndex]
				end

				-- 倍数递增来做降速效果
				self._speed = self._speed * self._multiple

				-- 转动速度
				self:OnTimerStart(self._magicWheelDownCountKeyList[1],self._speed)
			end
			-- 避免检测失误
			self:OnTimerStart(self._magicWheelIntervalKeyList[1],0.01)

		elseif self._curAnimation == #self._timeInterval then
			if self._curGridIndex  == self._targetItemIndex then
				self._curAnimation = 1
				self._turnTableAnimationEnd = true
				self:TimerStop(self._magicWheelDownCountKeyList[1])
				self:TimerStop(self._magicWheelIntervalKeyList[1])
				self:TimerStop(self._magicDelayPlayAnimKey)
				self:TimerStart(self._magicDelayPlayAnimKey, 3, false, 1)
				self:OpenUIAward()
				self:ChangeItem(self._allRewardList,self._uiItemList)
			end
		end
	end

	if key == self._showItemEffectKey then
		self:PlayerResetItemAnimation()
	elseif key == self._showItemIconKey then
		self:PlayerShowItemIconAnimation()
	end

	if key == self._magicDelayPlayAnimKey then
		self:StartTurnTableIdle(self._curMagicWheelType)
	end
end

function UIFortuneMic:ShowOtherUI(Show)
	CS.ShowObject(self.mTitleImg1,not Show)
	CS.ShowObject(self.mTitleImg,Show)
	CS.ShowObject(self.mDetailsBtn,Show)
	CS.ShowObject(self.mImage,Show)
	CS.ShowObject(self.mLimit,Show)
	CS.ShowObject(self.mOneCallBtn,Show)
	CS.ShowObject(self.mTenCallBtn,Show)
	CS.ShowObject(self.mFreeTimes,Show)
	--CS.ShowObject(self.mNeedProp,Show)
	--CS.ShowObject(self.mDiamond,Show)
	--CS.ShowObject(self.mProp,Show)
end

function UIFortuneMic:ClearResetTime()
	if self._showItemTimer then
		LxTimer.DelayTimeStop(self._showItemTimer)
		self._showItemTimer = nil
	end

	if self._showItemCoinTimer then
		LxTimer.DelayTimeStop(self._showItemCoinTimer)
		self._showItemCoinTimer = nil
	end

	self:ClearShowItemTime()
end

function UIFortuneMic:ClearResetEffect()
	if not self._effectList then return end
	for k,v in ipairs(self._effectList) do
		self:DestroyWndEffectByKey(v)
	end

	self._effectList = nil
end

-- 标题+标题颜色
function UIFortuneMic:SetTitle(iamge,titleStr,titleColor)
	self:SetWndEasyImage(self.mTitleImg1,iamge)
	self:SetWndText(self.mTitle1, titleStr)
	local text = self:FindWndText(self.mTitle1)
	self:SetXUITextColor(text,LUtil.ColorByHex(titleColor))
end

-- 打开奖励弹窗
function UIFortuneMic:OpenUIAward()
	if not self._receiveList or #self._receiveList == 0 then
		return
	end
	if not self._itemDetail or #self._itemDetail == 0 then
		return
	end

	--local receiveList = self._receiveList
	self._receiveList = nil

	local magicType = self._curMagicWheelType
	local fixedCfg = nil

	if magicType == ModelCallHero.LUCKY then
		fixedCfg = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelLuckNum")
	else
		fixedCfg = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighLuckNum")
	end

	local fixedItem = LxDataHelper.ParseItem_3(fixedCfg)
	local fixedReward = nil
	local itemDetail = self._itemDetail

	local itemList = {}
	--local calcNum = 0
	for i,v in ipairs(itemDetail) do
		local items = v.items or {}
		local heroes = v.heroes or {}
		local runes = v.runes or {}
		local outfits = v.outfits or {}
		local itemLen = #items
		local heroLen = #heroes
		local runeLen = #runes
		local outfitsLen = #outfits
		local tList,itypeType
		if itemLen > 0 then
			tList = items
			itypeType = LItemTypeConst.TYPE_ITEM
		elseif heroLen > 0 then
			tList = heroes
			itypeType = LItemTypeConst.TYPE_HERO
		elseif runeLen > 0 then
			tList = runes
			itypeType = LItemTypeConst.TYPE_RUNE
		elseif outfitsLen > 0 then
			tList = outfits
			itypeType = LItemTypeConst.TYPE_OUTFIT
		end
		if tList then
			for idx,data in ipairs(tList) do
				local item
				if itypeType == LItemTypeConst.TYPE_ITEM then
					item = gModelItem:GetServerDataByPb(data)
				elseif itypeType == LItemTypeConst.TYPE_HERO then
					item = gModelHero:GetServerDataByPb(data)
				elseif itypeType == LItemTypeConst.TYPE_RUNE then
					item = gModelRune:GetServerDataByPb(data)
				end
				if item then
					table.insert(itemList,item)
					if item.refId == fixedItem.itemId then
						fixedReward =
						{
							itemId = item.refId,
							itemType = item.itype,
							itemNum = item.num
						}
					end
				end
			end
		end
	end



	local moreNum = self._wheelType == 1 and 1 or self._moreNum


	local btnTextList = {ccClientText(14612),string.replace(ccClientText(14613),moreNum)}
	local para =
	{
		itemList = itemList,
		btnTextList = btnTextList,
		func = function ()
			self:OnComeAgain(moreNum,magicType)
		end,
		detail = true,
		fixedReward = fixedReward,
	}
	gModelWndPop:TryOpenPopWnd("UIAward",para)
end

function UIFortuneMic:ClearShowItemTime()
	self:TimerStop(self._showItemIconKey)
	self:TimerStop(self._showItemEffectKey)
end

-- 显示转动消耗
function UIFortuneMic:ShowStartTurnTableBtn(type)
	local expend,moreNum,moreExpend,itemImage,runBtn1ImageTrans,runBtn2ImageTrans,integral

	CS.ShowObject(self.mVipBg,false)
	if type == UIFortuneMic.MAGIC_WHEEL_LUCK then
		expend = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelExpend")
		moreNum = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelMoreNum")
		moreExpend = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelMoreExpend")
		local vipLv = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelDisMoreCondition")
		local currVipLv = gModelPlayer:GetVipLevel()
		if(currVipLv >= vipLv)then
			moreExpend = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelDisMoreExpend")
		else
			CS.ShowObject(self.mVipBg,true)
			self:SetWndText(self.mVipTipsText,string.replace(ccClientText(14615),vipLv))
		end
		self._integral = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelIntNum")
		self._luckNum = string.split(gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelLuckNum"),"=")[3]
	else
		expend = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighExpend")
		moreNum = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighMoreNum")
		moreExpend = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighMoreExpend")
		self._integral = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighIntNum")
		self._luckNum = string.split(gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighLuckNum"),"=")[3]
	end

	local expendList = string.split(expend,"=")
	self._turnBtn1ItemID = tonumber(expendList[2])
	self._turnBtn1Num = tonumber(expendList[3])
	self._moreNum = moreNum

	self:SetWndEasyImage(runBtn1ImageTrans,itemImage)
	--self:SetWndText(self.mRunBtn1Text,ccClientText(14605))               -- 转动1次
	self:SetWndButtonText(self.mRunBtn1,ccClientText(14605))
	self:SetDiaValueShow(self.mRunBtn1Dia,expend,true)

	local str = string.replace(ccClientText(14606),moreNum)
	expendList = string.split(moreExpend,"=")
	self._turnBtn2ItemID = tonumber(expendList[2])
	self._turnBtn2Num = tonumber(expendList[3])

	self:SetWndEasyImage(runBtn2ImageTrans,itemImage)
	--self:SetWndText(self.mRunBtn2Text,str)               -- 转动N次
	self:SetWndButtonText(self.mRunBtn2,str)
	self:SetDiaValueShow(self.mRunBtn2Dia,moreExpend,true)

end

-- 轮盘格子旋转动画
function UIFortuneMic:PlayTurnAnimation()
	--local root = self._gridList

	local index = self._curGridIndex + 1
	if index > 8 then
		index = 1
	end
	self._curGridIndex = index

	local z = 90 + index * -45

	local rotation = Quaternion.Euler(0,0,z)

	-- 亮片方向
	self._gridLightBg.localRotation = rotation
	-- 箭头方向
	self._dir.localRotation = rotation

	--for i = 1, 8 do
	--	local str = "Grid" .. i
	--	local grid = CS.FindTrans(root,str)
	--
	--	if i == self._curGridIndex then
	--		CS.ShowObject(grid,true)
	--	else
	--		CS.ShowObject(grid,false)
	--	end
	--end

	--self:PlayArrowDir()
end

function UIFortuneMic:RefreshLimitNum()
	local todayCnt,limitCnt = gModelCallHero:GetLimitInfo(self._curMagicWheelType)
	local str = string.replace(ccClientText(11630),todayCnt,limitCnt)
	self:SetWndText(self.mLimitText,str)
end

function UIFortuneMic:OnItemIconClick(instanceId)
	local itemIconList = self._itemIconList
	if not itemIconList then return end
	local cls = itemIconList[instanceId]
	if not cls or cls:IsDestroy() then return end
	local rewardType = cls:GetRewardType()
	if rewardType == LItemTypeConst.TYPE_EQUIP then
		gModelGeneral:OpenEquipInfoTip(cls:GetRewardRefId(),nil,1,true)
	elseif rewardType == LItemTypeConst.TYPE_ITEM then
		gModelGeneral:OpenItemInfoTip(cls:GetRewardRefId(),cls:GetRewardCount())
	elseif rewardType == LItemTypeConst.TYPE_OUTFIT then
		gModelGeneral:OpenOutfitInfoTipByRefId(cls:GetRewardRefId())
	end
end

-- 开启时间计时
function UIFortuneMic:OnTimerStart(key,time)
	if not key or not time then
		return
	end

	self:TimerStart(key,time,false,-1)
end

-- 获取物品索引
function UIFortuneMic:GetWheelItemIndexByID(id)
	if not id or table.isempty(self._itemIndexList) then
		return nil
	end

	return self._itemIndexList[id]
end

function UIFortuneMic:InitItemList(dataList)
	if(self._uiList)then
		self._uiList:RefreshList(dataList)
	else
		self._uiList = self:GetUIScroll("_uiList")
		self._uiList:Create(self.mPayItemList,dataList,function (...) self:OnDrawItem(...) end)
	end
end

-- 创建刷新奖励时，格子的特效
function UIFortuneMic:CreateResetIconEffect(trans, key)
	table.insert(self._effectList, key)
	self:CreateWndEffect(trans,"fx_ui_xingyunmolun_wupinshanguang",key,150,false,
			false)
end

function UIFortuneMic:PlayerShowItemIconAnimation()
	if not self._itemEffectTransList then
		self:StopResetItemAnimation()
		return
	end

	self._playingAnimationItemCoinIndex = self._playingAnimationItemCoinIndex  + 1
	local itemData = self._itemEffectTransList[self._playingAnimationItemCoinIndex]
	if not itemData then
		self:StopResetItemAnimation()
		return
	end


	local iconTrans = itemData.iconTrans
	CS.ShowObject(iconTrans, true)

	if self._playingAnimationItemCoinIndex >= 8 then
		self:StopResetItemAnimation()
	end
end

-- 重置按钮点击事件
function UIFortuneMic:OnUpdateClickBtn(isFree,expend)
	if not self._canClick then
		if self._isShowClickWaitMsg then
			self._isShowClickWaitMsg = false
			GF.ShowMessage(ccClientText(14616))
		end
		return
	end

	local list = string.split(expend,"=")
	local itemId = tonumber(list[2])
	local value = tonumber(list[3])

	if not self._turnTableAnimationEnd then
		return
	end

	if self:IsTimerExist(self._magicDelayPlayAnimKey) then
		self:TimerStop(self._magicDelayPlayAnimKey)
		self:StartTurnTableIdle(self._curMagicWheelType)
	end

	if isFree then
		self:OnMagicWheelResetFunc()
	elseif value and value > 0 then
		local wndId = self._curMagicWheelType == UIFortuneMic.MAGIC_WHEEL_LUCK and 101001 or 101002
		local dia = gModelItem:GetNumByRefId(itemId)
		-- 花费钻石重置
		local func = function()
			if self:IsWndClosed() then return end

			if dia >= value then
				self:OnMagicWheelResetFunc()
			else
				gModelGeneral:OpenGetWayWnd({itemId = itemId})
			end
		end
		gModelGeneral:OpenUIOrdinTips({refId = wndId,func = func,para = {value}, consume={value,itemId}})

		--local openFunc = function ()
		--	GF.OpenWnd("UIOrdinTip",{refId = wndId,func = func,para = {value}})
		--end
        --
		--gModelGeneral:ShowUIOrdinTip(wndId,func,openFunc)
	end
end

-- 点击领取宝箱
function UIFortuneMic:OnClickBox(trans,rewardList)
	local rewardList = gModelGeneral:GetParseItem(rewardList)
	GF.OpenWnd("UIringBoxDetail",{trans,rewardList})
end

function UIFortuneMic:OnDrawItem(list,item, itemdata, itempos)
	local bgTrans = self:FindWndTrans(item,"Bg")
	if bgTrans then
		local refId = itemdata.refId
		local IconTrans = self:FindWndTrans(bgTrans,"Icon")
		local BtnTrans = self:FindWndTrans(bgTrans,"Btn")
		local NumTrans = self:FindWndTrans(bgTrans,"Num")
		if IconTrans then
			local icon = gModelItem:GetItemIconByRefId(refId)
			self:SetWndEasyImage(IconTrans, icon)
		end
		if BtnTrans then
			self:SetWndClick(BtnTrans,function()
				gModelGeneral:OpenGetWayWnd({itemId = refId})
			end)
		end
		if NumTrans then
			local haveNum = gModelItem:GetNumStrByRefId(refId)
			self:SetWndText(NumTrans, haveNum)
		end
	end
end

function UIFortuneMic:InitEvent()
	---------------------------------- 魔轮 -----------------------------
	-- 魔轮：魔轮商店
	self:SetWndClick(self.mShop, function()
--[[		local func = function()
			gModelCallHero:OpenCallWnd({page = 3})
		end
		gModelFunctionOpen:Jump(14600041,nil,func)]]
		gModelCallHero:OpenCallWnd({page = 3})
		local callName = gModelCallHero:GetCallWndName()
		GF.CloseWndByName(callName)
	end)

	-- 魔轮：帮助
	self:SetWndClick(self.mHelp, function()
		local id = self._curMagicWheelType == UIFortuneMic.MAGIC_WHEEL_LUCK and 17 or 18
		GF.OpenWnd("UIBzTips",{refId=id,para ={self._luckNum or 10,self._luckCountNum or 1000}})
	end)

	-- 魔轮：幸运魔轮
	self:SetWndClick(self.mLuckTurnTableTypeBtn1, function()

		if self._turnTableAnimationEnd and self._curMagicWheelType ~= UIFortuneMic.MAGIC_WHEEL_LUCK then
			gModelCallHero:OnMagicWheelInfoReq(UIFortuneMic.MAGIC_WHEEL_LUCK)
		end
	end)

	-- 魔轮：奇迹魔轮
	self:SetWndClick(self.mLuckTurnTableTypeBtn2, function()

		if self._turnTableAnimationEnd and self._curMagicWheelType ~= UIFortuneMic.MAGIC_WHEEL_MIRACLE then
			gModelCallHero:OnMagicWheelInfoReq(UIFortuneMic.MAGIC_WHEEL_MIRACLE)
		end
	end)

	-- 魔轮：转动1次
	self:SetWndClick(self.mRunBtn1, function()
		if self._turnTableAnimationEnd then
			self:OnTurnClickBtn(self._curMagicWheelType,1)
			self._wheelType = 1
		end
	end)

	-- 魔轮：转动15次
	self:SetWndClick(self.mRunBtn2, function()
		if self._turnTableAnimationEnd then
			self:OnTurnClickBtn(self._curMagicWheelType,2)
			self._wheelType = 2
		end
	end)

	---------------------------------- 魔轮 -----------------------------
end

function UIFortuneMic:ShowTurnTableAnimation()
	if (self:IsWndClosed()) then return end

	self:StopTurnTableAnimation(self._magicWheelDownCountKeyList[1])
	self:StartTurnTableIdle(self._curMagicWheelType)
	self:PlayTurnAnimation()   --  两个转盘类型切换中无缝衔接
end

function UIFortuneMic:PlayerResetItemAnimation()
	if not self._itemEffectTransList then return end

	self._playingAnimationItemIndex = self._playingAnimationItemIndex + 1
	local itemData = self._itemEffectTransList[self._playingAnimationItemIndex]
	if not itemData then return end

	local itemTrans = itemData.itemTrans
	local iconTrans = itemData.iconTrans
	local effectTrans = itemData.effectTrans

	CS.ShowObject(itemTrans, true)
	CS.ShowObject(iconTrans, false)
	self:CreateResetIconEffect(effectTrans, "showItem"..self._playingAnimationItemIndex)
end

-- 是否已领取幸运宝箱
function UIFortuneMic:IsReceiveLuckBox(luckID)
	if not luckID or table.isempty(self._luckyReceiveList) then
		return false
	end

	for i, v in pairs(self._luckyReceiveList) do
		if v and tonumber(v) and tonumber(v) == luckID then
			return true
		end
	end
end

function UIFortuneMic:ClearCanClickTime()
	if not self._canClickTimer then return end

	LxTimer.DelayTimeStop(self._canClickTimer)
	self._canClickTimer = nil
	self._canClick = true
	self._isShowClickWaitMsg = true
end

-- 设置转盘节点参数
function UIFortuneMic:SetTurnTableTransByType(luckMagicWheelType)
	if luckMagicWheelType == UIFortuneMic.MAGIC_WHEEL_LUCK then
		self._gridList = self.mGridList
		self._itemList = self.mItemList
		self._dir = self.mUpdateBtnDir

		self._gridLightBg = self._lightGrid
	else
		self._gridList = self.mPurpleGridList

		self._gridLightBg = self._purpleLightGrid
		self._itemList = self.mPurpleItemList
		self._dir = self.mPurpleUpdateBtnDir
	end
end


function UIFortuneMic:LuckMagicWheelInitData(luckMagicWheelType,pb)

	if luckMagicWheelType == UIFortuneMic.MAGIC_WHEEL_LUCK then
		--local isShow = CS.IsShowObject(self.mLuckTurnTable1)
		--if isShow then return end
		CS.ShowObject(self.mLuckTurnTable1,true)
		CS.ShowObject(self.mLuckTurnTable2,false)
		self:SetTitle("callhero_bg_top_3",ccClientText(14600),"73E3FFFF")
		self._CurLuckValueText = self.mCurLuckValueText
		self._LuckValue = self.mLuckValue
		self._luckType = "luckValue"
		self._luckRefList = gModelCallHero:GetLuckMagicWheelLuckyRef()
		self._uiItemList = self.mItemList
	else
		--local isShow = CS.IsShowObject(self.mLuckTurnTable2)
		--if isShow then return end
		CS.ShowObject(self.mLuckTurnTable1,false)
		CS.ShowObject(self.mLuckTurnTable2,true)
		self:SetTitle("callhero_bg_top_2",ccClientText(14601),"C6A1FFFF")
		self._CurLuckValueText = self.mPurpleCurLuckValueText
		self._LuckValue = self.mPurpleLuckValue
		self._luckType = "purpleLuckValue"
		self._luckRefList = gModelCallHero:GetMiracleMagicWheelLuckyRef()
		self._uiItemList = self.mPurpleItemList
	end

	-- 幸运条
	self._luckSliderUp = self:UIProgressFind(self.mProgressUp,"BlueProgressUp",0)
	self._miracleSliderUp = self:UIProgressFind(self.mPurpleProgressUp,"PurpleProgressUp",0)

	-- 当前轮盘累计幸运值
	self._lucky = pb.lucky

	-- 当前轮盘幸运宝箱领取记录，为幸运奖励表Id
	self._luckyReceiveList = pb.luckyReceive

	self._curMagicWheelType = luckMagicWheelType

	self:ShowOtherUI(false)

	self:ShowLuckValue(self._lucky,luckMagicWheelType == UIFortuneMic.MAGIC_WHEEL_LUCK and self._luckSliderUp or self._miracleSliderUp)

	self:ChangeTurnTableData(pb)

	-- 查看更多
	local uiHyperText = UIHyperText:New()
	uiHyperText:Create(self.mLook)
	local str = ccClientText(14603)
	str = uiHyperText:AddHyper(str,{func = function()
		local itemList = gModelCallHero:GetMagicWheelExplainRefByType(self._curMagicWheelType)
		GF.OpenWnd("UIProbabilitySow",{itemList = itemList})
	end})
	self:SetWndText(self.mLook,str)

	-- 文本赋值
	self:SetWndText(self.mCurLuckText,ccClientText(14607))               -- 幸运值
	self:SetWndText(self.mPurpleCurLuckText,ccClientText(14610))
	self:SetWndText(self.mClickText1,ccClientText(14600))                -- 幸运魔轮
	self:SetWndText(self.mClickText2,ccClientText(14601))                -- 奇迹魔轮
	self:SetWndText(self.mUpdateText1,ccClientText(14602))               -- 刷 新
	self:SetWndText(self.mUpdateText2,ccClientText(14609))               -- 免 费刷 新
	self:InitTextLineWithLanguage(self.mUpdateText2, -30)
	self:InitTextSizeWithLanguage(self.mUpdateText2, -4)
	self:SetWndText(self.mPurpleUpdateText1,ccClientText(14602))         -- 刷 新
	self:SetWndText(self.mPurpleUpdateText2,ccClientText(14609))         -- 免 费刷 新
	self:InitTextLineWithLanguage(self.mPurpleUpdateText2, -30)
	self:InitTextSizeWithLanguage(self.mPurpleUpdateText2, -4)

	self:InitTextLineWithLanguage(self.mClickText1,-40)
	self:InitTextLineWithLanguage(self.mClickText2,-40)

end

-- 箭头方向
--function UIFortuneMic:PlayArrowDir()
--	local root = self._itemList
--	if not root then
--		return
--	end
--
--	local itemRoot = CS.FindTrans(root,"Item" .. self._curGridIndex)
--	local dir = itemRoot.position - self._dir.position
--	dir.z = 0
--	local normalized =  dir.normalized
--	self._dir.up = normalized
--end

-- 停止轮盘动画
function UIFortuneMic:StopTurnTableAnimation(key)
	if key then
		self:TimerStop(key)
		--self._curGridIndex = 0
		--self._lastGridIndex = 0
	end
end

-- 转动按钮点击事件
function UIFortuneMic:OnTurnClickBtn(type,wheelType, isAgain)

	local wndName = self:GetParentWndName()
	if gModelCallHero:SendMagicWheelReq(type,wheelType,wndName) then
		if not isAgain then
			self:TimerStop(self._magicDelayPlayAnimKey)
		end
	end



    --
	------ 幸运魔轮批量抽取判断是否满足条件
	----if wheelType == 2 and type == UIFortuneMic.MAGIC_WHEEL_LUCK then
	----	local needLv =  gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelMoreCondition")
	----	local curVipLv = gModelPlayer:GetVipLevel()
	----	if tonumber(curVipLv) < tonumber(needLv) then
	----		GF.ShowMessage(string.replace(ccClientText(14611),needLv))
	----		return
	----	end
	----end
    --
	---- 魔轮抽取类型：1单次抽取 2批量抽取
	--local needItemID = wheelType == 1 and self._turnBtn1ItemID or self._turnBtn2ItemID
	--local needItemCount = wheelType == 1 and self._turnBtn1Num or self._turnBtn2Num
	--local dia = gModelItem:GetNumByRefId(needItemID)
    --
	--if not self:IsWndValid() then
	--	GF.ShowMessage(ccClientText(14614))
	--	return
	--end
	--needItemCount = needItemCount or 0
	---- 购买
	--if dia >= needItemCount then
	--	if not isAgain then
	--		self:TimerStop(self._magicDelayPlayAnimKey)
	--	end
	--	gModelCallHero:OnMagicWheelReq(type,wheelType)
	--else
	--	gModelGeneral:OpenGetWayWnd({itemId = needItemID})
	--end
end

-- 是否已获取物品
function UIFortuneMic:IsReceiveWheelItem(itemId,num)
	local ref = gModelCallHero:GetMagicWheelRewardRefByRefId(itemId)
	local extractLimit = tonumber(ref.extractLimit)

	if extractLimit == 0 then
		return false
	end

	if extractLimit > 0 and num >= extractLimit then
		return true
	end
end

function UIFortuneMic:ClearStopResetItemAnimationTimer()
	if not self._stopResetItemAnimationTimer then return end

	LxTimer.DelayTimeStop(self._stopResetItemAnimationTimer)
	self._stopResetItemAnimationTimer = nil
end

--转盘奖励刷新
function UIFortuneMic:OnMagicWheelResetFunc()
	self:ClearStopResetItemAnimationTimer()
	self:StopResetAnimation()
	self:PlayResetAnimation()
end

------------------------------ 幸运魔轮 ------------------------------

------------------------------------------------------------------
return UIFortuneMic


