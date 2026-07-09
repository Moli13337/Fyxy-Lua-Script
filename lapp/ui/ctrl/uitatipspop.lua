---
--- Created by BY.
--- DateTime: 2023/10/13 20:48:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITaTipsPop:LWnd
local UITaTipsPop = LxWndClass("UITaTipsPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITaTipsPop:UITaTipsPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITaTipsPop:OnWndClose()
	LWnd.OnWndClose(self)
	self:ClearTimerClose()
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITaTipsPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITaTipsPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UITaTipsPop:InitCommand()
	self._rewards = self:GetWndArg("rewards")
	self:SetWndText(self.mXUIText,ccClientText(12120))
	self:InitTextSizeWithLanguage(self.mXUIText,-2)
	self:InitTextLineWithLanguage(self.mXUIText,-20)
	self:SetWndText(self.mCloseTip,ccClientText(12121))
	self._countDown = gModelTower:GetTowerConfigRefByKey("escapeWinCountdown")
	self:SetWndText(self.mTipsText,string.replace(ccClientText(12122),self._countDown))
	self:StartDelayTimerClose(1)
end

function UITaTipsPop:StartDelayTimerClose(time)
	self:ClearTimerClose()
	if time<=0 then
		self:OnTimerFun()
		return
	end
	if self._timerClose == nil then
		local iTimeOut = time
		self._timerClose = LxTimer.DelayTimeCall(function()
			self:OnTimerFun()
		end, iTimeOut)
	end
end

function UITaTipsPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...)
		self:OnClickCloseWnd()
	end)
end

function UITaTipsPop:ClearTimerClose()
	if self._timerClose then
		LxTimer.DelayTimeStop(self._timerClose)
		self._timerClose = nil
	end
end

---延迟执行----------------------------------------------------------------------
function UITaTipsPop:OnTimerFun()
	self._countDown=self._countDown-1
	self:SetWndText(self.mTipsText,string.replace(ccClientText(12122),self._countDown))
	if(self._countDown<=0)then
		self:OnClickCloseWnd()
	else
		self:StartDelayTimerClose(1)
	end
end

function UITaTipsPop:OnClickCloseWnd()
	--print("点击关闭界面")
	local isFromBack = self:GetWndArg("isFromBack")

	local refId = 80008
	local tLayer = gModelTower:GetTasLayer(ModelTower.RACE_COM)
	local layer = gModelTower:GetBehindPhaseLayer(tLayer,ModelTower.RACE_COM)

	local unlockForeshowRace = gModelTower:GetTowerConfigRefByKey("unlockForeshowRace")
	local unlockForeshowDifficulty = gModelTower:GetTowerConfigRefByKey("unlockForeshowDifficulty")
	local num = gModelTower:GetUnlockRaceTowerNum()
	local difficultyNum = gModelTower:GetUnlockDifficultyTowerNum()
	local other = {layer}
	if num > 0 and unlockForeshowRace <= tLayer then
		refId = 80014
		other = { layer,num ,ccClientText(12180)}
	elseif difficultyNum > 0 and unlockForeshowDifficulty <= tLayer then
		refId = 80014
		other = { layer,difficultyNum,ccClientText(12181) }
	end
	gModelBattle:OpenCommonResult({
		refId = refId,
		other = other,
		isFromBack = isFromBack,
		combatType = LCombatTypeConst.COMBAT_TOWER_BATTLE,
		accWndType = 3,
		showNext = true,
		towerData = self._rewards
	})

	FireEvent(EventNames.ON_TOWER_PASS,layer)

	self:WndClose()
end

function UITaTipsPop:InitMessage()
end

------------------------------------------------------------------
return UITaTipsPop


