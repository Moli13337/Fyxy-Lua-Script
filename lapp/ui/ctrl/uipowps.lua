---
--- Created by BY.
--- DateTime: 2023/10/30 14:07:09
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPowps:LWnd
local UIPowps = LxWndClass("UIPowps", LWnd)
local Tweening = DG.Tweening

UIPowps.MAIN = 1
UIPowps.WONDERLAND = 2

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPowps:UIPowps()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPowps:OnWndClose()
	self:ClearTween()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPowps:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPowps:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._wndType = self:GetWndArg("wndType")
	self:SetTypeContent()
	self:InitData()
	self:InitCommand()
end

function UIPowps:ShowUpEffect()
	local effName = self._powerUpEff
	self:CreateWndEffect(self.mPowerEff,effName,effName,100)
end

function UIPowps:ClearTween()
	if self._powerSeq then
		self._powerSeq:Kill(false)
		self._powerSeq= nil
	end
end

function UIPowps:SetTypeContent()
	local wndType = self._wndType
	local bgPath = "hero_bg_12"
	local scale = Vector3.New(1,1,1)
	self._powerTextSize = 34
	if wndType == UIPowps.WONDERLAND and not gLGameLanguage:IsForeignVersion() then
		bgPath = "public_bg_top_2"
		self._powerTextSize = 24
		scale = Vector3.New(0.8,0.8,0.8)
	end

	self.mPowerBg.localScale = scale
	self:SetWndEasyImage(self.mPowerBg,bgPath)
	local xuiTextTrans = self:FindWndText(self.mPower)
	self:SetXUITextFontSize(xuiTextTrans,self._powerTextSize)

end

function UIPowps:ShowFlyEffect()
	local effName = self._powerBulletEff
	self:CreateWndEffect(self.mFlyRoot,effName,effName,100)
	local startPos = self.mPower.position
	local endPos = self.mPowerNum.position
	local duration = 0.5
	local curveFun = LCurveUtil.Linear(startPos,endPos,duration)
	local tweener = YXTween.TweenFloat(0,1,duration,function (value)
		local pos = curveFun(value)
		if CS.IsValidObject(self.mFlyRoot) then
			self.mFlyRoot.position = pos
		end
	end)
	return tweener
end

function UIPowps:InitCommand()
	local power = self:GetWndArg("power")
	local oldPower = self:GetWndArg("oldPower")
	self:SetPower(oldPower)
	self:OnPowerChange(power)
end

function UIPowps:ShowHitEffect()
	local effName = self._powerHitEff
	self:CreateWndEffect(self.mPowerNum,effName,effName,100)
end

function UIPowps:OnTweenEnd()
	self:DestroyWndEffectByKey(self._powerHitEff)
	self:DestroyWndEffectByKey(self._powerUpEff)
	CS.ShowObject(self.mFlyRoot,false)
	self:ClearTween()
	FireEvent(EventNames.ON_POWER_CHANGE_END)
	self:WndClose()
end

function UIPowps:InitMsg()
	self:WndEventRecv(EventNames.ON_POWER_CHANGE,function(pType,pKey,pPower)
		if pType == 0 then
			self:OnPowerChange(pPower)
		end
	end)
end

function UIPowps:InitData()
	self._powerUpEff ="fx_zhanliUP"
	self._powerBulletEff ="fx_zhanliUP_bullet"
	self._powerHitEff ="fx_zhanliUP_hit"
end

function UIPowps:SetPower(num)
	self._oldPower = tonumber(num)
	self:SetWndText(self.mPowerNum,LUtil.PowerNumberCoversion(num))
end

function UIPowps:OnPowerChange(power)
	local oldPower = self._oldPower
	self._oldPower = power
	local powerAdd = power - oldPower
	if powerAdd>0 then
		--local str = LUtil.FormatCoversionHurtNumSpriteText(powerAdd, true, nil, self._powerTextSize)
		local str ="+".. LUtil.NumberCoversion(powerAdd, true, nil, self._powerTextSize)
		self:SetWndText(self.mPower,str)
		CS.ShowObject(self.mPowerRoot,true)
		self.mPowerRoot.localScale = Vector3.New(1,0,1)

		self:ClearTween()
		local seq =Tweening.DOTween.Sequence()
		self._powerSeq = seq
		self:DestroyWndEffectByKey(self._powerUpEff)
		local tweener = self.mPowerRoot:DOScale(Vector3.New(1,1,1),0.2)
		seq:Append(tweener)
		seq:AppendInterval(1.2)
		tweener = self.mPowerRoot:DOScale(Vector3.New(1,0,1),0.2)
		seq:Append(tweener)
		seq:InsertCallback(0.05,function ()
			self:ShowUpEffect()
		end)
		seq:InsertCallback(1.6,function ()
			CS.ShowObject(self.mPowerRoot,false)
			CS.ShowObject(self.mFlyRoot,true)
		end)
		tweener = self:ShowFlyEffect()
		seq:Append(tweener)
		seq:AppendCallback(function ()
			self:ShowHitEffect()
		end)
		local from = oldPower
		local to  = power
		local duration = 0.5
		tweener = YXTween.TweenInt(from, to, duration,function(ival)
			self:SetWndText(self.mPowerNum,LUtil.PowerNumberCoversion(ival))
		end)

		seq:Append(tweener)
		seq:AppendInterval(1)
		seq:OnComplete(function ()
			--self:SetPower(power)
			self:OnTweenEnd()
		end)
		seq:PlayForward()
	else
		self:SetPower(power)
	end
end
------------------------------------------------------------------
return UIPowps


