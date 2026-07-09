---
--- Created by wzz.
--- DateTime: 2024/6/11 14:42:37
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBlockMiniGame:LWnd
local UIBlockMiniGame = LxWndClass("UIBlockMiniGame", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBlockMiniGame:UIBlockMiniGame()
	self._isPause = true
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBlockMiniGame:OnWndClose()
	LWnd.OnWndClose(self)
	if(gModelBlockMiniGame:GetWXBSFlag())then
		gModelBlockMiniGame:SetWXBSFlag(false)
		GF.ChangeToMainScene({loadEndFunc = nil})
	end
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBlockMiniGame:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBlockMiniGame:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitTexts()
	self:InitEvents()

	local func = self:GetWndArg("openCall")
	if func then
		func(self)
	end
	self._ref = gModelBlockMiniGame:GetLevRef(self:GetWndArg("refId"))
	local isWXBS = self._ref.type == 3
	self._isWXBS = isWXBS
	gModelBlockMiniGame:SetIsOutFiveMin(false)
	if(isWXBS)then
		self:TimerStart("wx_bs_time_cnt", 5*60, true, 1)
		--self:TimerStart("wx_bs_time_cnt", 2, true, 1)
		CS.ShowObject(self.mCloseBtn, false)
		CS.ShowObject(self.mBtnPause, false)
	end
	local timePara = {
		key = 1,
		loopcnt = -1,
		interval = 1,
		timescale = false,
		callOnStart = false,
		func = function()
			self:UpdateTime()
		end
	}

	self:TimerStartImpl(timePara)
	self:Refresh()
	self:InitPos()
end

-- 开始游戏
function UIBlockMiniGame:OnStartGame()
	self._isPause = false

	CS.ShowObject(self.mMe, true)
	CS.ShowObject(self.mOther, true)
end

-- update
function UIBlockMiniGame:UpdateTime()
	if self._isPause then
		return
	end
	self._leftTime = self._leftTime - 1
	self:RefreshTime()

	if self._showBubbleEndTime then
		if self._showBubbleEndTime <= os.time() then
			CS.ShowObject(self.mBubble, false)
			self._showBubbleEndTime = nil
		end
	end

	if self._leftTime <= 0 then
		self._isPause = true
		FireEvent(EventNames.BLOCKMINIGAME_OVER, { isWin = false })
		return
	end
end

-- 消除行
function UIBlockMiniGame:OnClearLine(param)
	local lineNum = param.lineNum
	local ref = GameTable.BlockContinuousSterilizationRef[lineNum]
	if not ref then
		return
	end

	self:SetWndEasyImage(self.mFace, ref.face)
	self:SetWndEasyImage(self.mBubbleTxt, ref.desc)

	CS.ShowObject(self.mBubble, true)
	self._showBubbleEndTime = os.time() + 2
end

function UIBlockMiniGame:SetLongClick(btnTrans, key, func)
	local btnTransObj = btnTrans.gameObject
	CS.SetPointerUp(btnTransObj, function()
		-- if func then func() end
		self:RefreshBtnShowStatus(btnTrans, false)
		self:TimerStop(key)
	end)
	CS.SetPointerDown(btnTransObj, function()
		if func then func() end
		self:RefreshBtnShowStatus(btnTrans, true)
		self:StartLongTimer(key)
	end)
end

-- 点击控制按钮
function UIBlockMiniGame:OnClickBtnCtrl(flag)
	FireEvent(EventNames.BLOCKMINIGAME_BTN_CTRL, flag)
end

function UIBlockMiniGame:RefreshBtnShowStatus(btnTrans, isDown)
	local instanceID = btnTrans:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			BtnNoSel = self:FindWndTrans(btnTrans, "BtnNoSel"),
			BtnSel = self:FindWndTrans(btnTrans, "BtnSel"),
		}
	end
	CS.ShowObject(itemCache.BtnNoSel, not isDown)
	CS.ShowObject(itemCache.BtnSel, isDown)
end

-- 初始界面化文本
function UIBlockMiniGame:InitTexts()
	self:SetWndText(self.mTxtClose, ccClientText(30205))
	self:SetWndText(self.mTxtTimeTips, ccClientText(43506))
	self:SetWndText(self.mTxtNext, ccClientText(43511))
	if self.jpj then
		self:InitTextSizeWithLanguage(self.mTxtNext,-2)
		self:SetAnchorPos(self.mTxtNext,Vector2.New(260,276.8))
	end
end

function UIBlockMiniGame:SetBtnClickStatus(btnTrans, func)
	local btnTransObj = btnTrans.gameObject
	CS.SetPointerUp(btnTransObj, function()
		if func then func() end
		self:RefreshBtnShowStatus(btnTrans, false)
	end)
	CS.SetPointerDown(btnTransObj, function()
		self:RefreshBtnShowStatus(btnTrans, true)
	end)
end

-- 获取通关使用时间 秒
function UIBlockMiniGame:GetUseTime()
	local time = math.floor(math.max(0, self._totalTime - self._leftTime))
	return time, self._ref.refId
end

-- 恢复游戏
function UIBlockMiniGame:OnResumeGame()
	self._isPause = false
end

-- 点击帮助
function UIBlockMiniGame:OnClickBtnHelp()
	self._isPause = true
	FireEvent(EventNames.BLOCKMINIGAME_PAUSE)
	GF.OpenWnd("UIBlockMiniGameHelp", {
		callback = function()
			FireEvent(EventNames.BLOCKMINIGAME_RESUME)
		end
	})
end

function UIBlockMiniGame:StartLongTimer(key)
	self:TimerStart(key, 0.15, true, -1)
end

-- 初始控制ui位置
function UIBlockMiniGame:InitCtrlUIPos(screenPos)
	if CS.IsWebGL() and LWxHelper.IsDouYinPlatform() then
	else
		local uiCam = LGameUI.GetUICamera()
		local uiPos = uiCam:ScreenToWorldPoint(screenPos)
		self.mBottom.position = uiPos
	end
end

function UIBlockMiniGame:InitPos()
	--if CS.IsWebGL() and LWxHelper.IsDouYinPlatform() then
	local mgr = gLGpManager:FindBlockMiniGameGp()
	if not mgr or mgr:IsDisposed() then return end
	local uiNode = mgr:GetUINodeTrans()
	if uiNode then
		self:SetPos(self.mBottom,uiNode)
	end
	
	--local uiTitle = mgr:GetUITitleTrans()
	--if uiTitle then
	--	self:SetPos(self.mTop,uiTitle)
	--end
end

function UIBlockMiniGame:SetPos(trans,target)
	local sceneCamera = gLGameScene:GetCurrentSceneCamera()
	local screenPos = sceneCamera:WorldToScreenPoint(target.position) --Vector3

	local uiCam = LGameUI.GetUICamera()
	local uiPos = uiCam:ScreenToWorldPoint(screenPos)
	local curPos = trans.position
	trans.position = Vector3(curPos.x,uiPos.y,curPos.z)
end

-- 刷新倒计时
function UIBlockMiniGame:RefreshTime()
	self:SetWndText(self.mTxtTime, LUtil.FormatTimespanToMin2New(self._leftTime))
end

-- 重新开始游戏
function UIBlockMiniGame:OnRestartGame(refId)
	if refId then
		self._ref = gModelBlockMiniGame:GetLevRef(refId)
	end

	CS.ShowObject(self.mMe, false)
	CS.ShowObject(self.mOther, false)
	self:Refresh()
end

-- 塔血量变化
function UIBlockMiniGame:OnTowrHpChange(param)
	local item
	if param.isSelf then
		item = self.mMe
	else
		item = self.mOther
	end

	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			imgHp = CS.FindTrans(item, "HpBg/ImgHp"),
			txtHp = CS.FindTrans(item, "TxtHp"),
		}
		itemCache.imgHpS = itemCache.imgHp.sizeDelta
		self:SetComponentCache(instanceID, itemCache)
	end

	local hp = param.hp
	local maxHp = param.maxHp
	itemCache.imgHp.sizeDelta = Vector2(itemCache.imgHpS.x * (param.hp / param.maxHp), itemCache.imgHpS.y)
	self:SetWndText(itemCache.txtHp, string.format("%d/%d", hp, maxHp))

	-- if param.isInit then
	-- 	CS.ShowObject(item, true)
	-- end
end

-- 刷新界面
function UIBlockMiniGame:Refresh()
	local ref = self._ref
	self:SetWndText(self.mTxtTitle, ccClientText(43503, ref.level))

	self._leftTime = gModelBlockMiniGame:GetCurLevLeftTime(ref.type)
	self._totalTime = self._leftTime
	self:RefreshTime()
end

-- 游戏结束
function UIBlockMiniGame:OnOverGame()
	self._isPause = true

	gModelBlockMiniGame:SetCurLevLeftTime(self._ref.type)
end

-- 点击返回
function UIBlockMiniGame:OnClickBtnBlack()
	self._isPause = true
	FireEvent(EventNames.BLOCKMINIGAME_PAUSE)

	local useTime, id = self:GetUseTime()

	gModelGeneral:OpenUIOrdinTips({
		refId = 460000,
		-- para = para,
		func = function()
			gModelBlockMiniGame:ExitGame(id, useTime)
			GF.ChangeMap("LCityMap")
			GF.OpenWnd("UIBlockMiniGameLevel")
			GF.CloseWndByName("UIBlockMiniGameReady")
			self:WndClose()
		end,
		closeFunc = function()
			FireEvent(EventNames.BLOCKMINIGAME_RESUME)
		end
	})
end

-- 初始事件
function UIBlockMiniGame:InitEvents()
	self:SetBtnClickStatus(self.mCloseBtn, function()
		self:OnClickBtnBlack()
	end)

	self:SetBtnClickStatus(self.mBtnPause, function()
		self:OnClickBtnPause()
	end)

	self:SetWndClick(self.mBtnHelp, function() self:OnClickBtnHelp() end)

	self:SetLongClick(self.mBtnLeft,"left",function()
		self:OnClickBtnCtrl("left")
	end)

	self:SetLongClick(self.mBtnRight,"right",function()
		self:OnClickBtnCtrl("right")
	end)

	self:SetLongClick(self.mBtnDown,"down",function()
		self:OnClickBtnCtrl("down")
	end)

	self:SetBtnClickStatus(self.mBtnRotate, function()
		self:OnClickBtnCtrl("rotate")
	end)

	self:SetBtnClickStatus(self.mBtnFast, function()
		self:OnClickBtnCtrl("fast")
	end)

	self:WndEventRecv(EventNames.BLOCKMINIGAME_START, function() self:OnStartGame() end)
	self:WndEventRecv(EventNames.BLOCKMINIGAME_RESUME, function() self:OnResumeGame() end)
	self:WndEventRecv(EventNames.BLOCKMINIGAME_OVER, function() self:OnOverGame() end)
	self:WndEventRecv(EventNames.BLOCKMINIGAME_RESTART, function(...) self:OnRestartGame(...) end)
	self:WndEventRecv(EventNames.BLOCKMINIGAME_TOWERHPCHANGE, function(...) self:OnTowrHpChange(...) end)
	self:WndEventRecv(EventNames.BLOCKMINIGAME_CLEARLINESTART, function(...) self:OnClearLine(...) end)


	local scaleList = { 0.01, 0.1, 1, 5 }
	local funcScale = function(scale)
		Time.timeScale = scale
	end
	for i = 1, 4 do
		self:SetWndButtonText(self["mBtn" .. i], scaleList[i])
		self:SetWndClick(self["mBtn" .. i], function() funcScale(scaleList[i]) end)
	end
	CS.ShowObject(self["mBtn1"].parent, false)
end

-- 点击暂停
function UIBlockMiniGame:OnClickBtnPause()
	self._isPause = true
	GF.OpenWnd("UIBlockMiniGamePause")
end

function UIBlockMiniGame:OnTimer(key)
	if key == "left" then
		self:OnClickBtnCtrl(key)
	elseif key == "right" then
		self:OnClickBtnCtrl(key)
	elseif key == "down" then
		self:OnClickBtnCtrl(key)
	elseif key == "wx_bs_time_cnt" then
		gModelBlockMiniGame:SetIsOutFiveMin(true)
	end
end

------------------------------------------------------------------
return UIBlockMiniGame