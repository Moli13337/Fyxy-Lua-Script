---
--- Created by wzz.
--- DateTime: 2024/5/15 17:39:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDraconicGet:LWnd
local UIDraconicGet = LxWndClass("UIDraconicGet", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDraconicGet:UIDraconicGet()
	self._effectKey = "1"
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDraconicGet:OnWndClose()
	if self._seqCom then
		self._seqCom:Destroy()
		self._seqCom = nil
	end

	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDraconicGet:OnCreate()
	LWnd.OnCreate(self)
	self._seqCom = SequenceCom:New()
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDraconicGet:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._refIdList = self:GetWndArg("refIdList")
	self._callback = self:GetWndArg("callback")
	self._time = os.time()

	self:InitEvents()

	self:Refresh()
	LxUiHelper.PlayAudioSoundName(28)
end

--- 设置文字打字机效果
function UIDraconicGet:SetFormmatPrinterAni(formatInfo)
	formatInfo = formatInfo or {}
	local str = formatInfo.str or ""
	local trans = formatInfo.trans
	local color = formatInfo.color
	local len, itor = LUtil.FormatPrinterData(str)
	--local perTime = gModelPlot:GetPara("storyWriting") /1000
	local perTime = 0.02
	local time = len * perTime
	local tween = YXTween.TweenInt(0, len, time, function(value)
		local temp = itor(value) or ""
		if color then
			temp = LUtil.FormatColorStr(temp, color)
		end
		self:SetWndText(trans, temp)
	end)
	return tween, time
end

-- 点击下一个
function UIDraconicGet:OnClickNext()
	if self._time + 1 > os.time() then
		return
	end

	self:Refresh()
end

-- 创建特效
function UIDraconicGet:CreateEffect(trans, effectName, effectKey, order, endFunc, func)
	effectKey = effectKey or effectName
	if func then
		func()
	end

	self:DestroyWndEffectByKey(effectKey)
	self:CreateWndEffect(trans, effectName, effectKey, 100, false, false, order, nil, nil,nil,nil, endFunc)
end

-- 初始事件
function UIDraconicGet:InitEvents()
	self:SetWndClick(self.mMask, function() if self._playTweenEnd then self:OnClickNext() end end)
end

--- 屏幕震动
function UIDraconicGet:CreateShakeTrans(shakeInfo)
	shakeInfo = shakeInfo or {}
	local strength = shakeInfo.strength or 4
	local time = shakeInfo.time or 0.5
	local trans = shakeInfo.trans or self.mAniRoot
	local shake = trans:DOShakePosition(time, strength)
	return shake
end

-- 动画
function UIDraconicGet:StartTween()
	--self:ClearTween()

	self._playTweenEnd = nil
	self:InitTweenUI()

	local seqTween
	self:TweenSeqKill(self._effectKey)
	seqTween = self:TweenSeqCreate(self._effectKey, function(seq)
		local tween1 = self.mDraconicCard:DOScale(Vector3(1, 1, 1), 0.3)
		seq:Append(tween1)
		local tween2 = self.mTitle:DOScale(Vector3(1.2, 1.2, 1.2), 0.2)
		local tween3 = self.mTitle:DOScale(Vector3(1, 1, 1), 0.01)
		seq:Append(tween2)
		seq:Append(tween3)

		seq:Append(self:CreateShakeTrans())

		local tween4 = self.mIcon.parent:DOScale(Vector3(1, 1, 1), 0.01)
		seq:Insert(0.5, tween4)

		local heroNameFPTween, heroNameFPTime = self:SetFormmatPrinterAni({
			str = self._mNameStr,
			trans = self.mName,
			color = self._mNameColor,
		})
		seq:Insert(0.7,heroNameFPTween)
		local heroNameFPTween, heroNameFPTime = self:SetFormmatPrinterAni({
			str = self._mSkillNameStr,
			trans = self.mSkillName,
		})
		seq:Insert(0.7,heroNameFPTween)

		seq:AppendCallback(function()
			-- self:Refresh()
		end)
		return seq
	end)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._effectKey)
		self._playTweenEnd = true
	end)
end

-- 初始化动画ui设置
function UIDraconicGet:InitTweenUI()
	self.mTitle.localScale = Vector3(0, 0, 0)
	self.mDraconicCard.localScale = Vector3(0, 0, 0)
	self.mIcon.parent.localScale = Vector3(0, 1, 1)
end

-- 刷新界面
function UIDraconicGet:Refresh()
	local refId = table.remove(self._refIdList, 1)
	if refId == nil then
		self:WndClose()
		if self._callback then
			self._callback()
		end
		return
	end


	local ref = GameTable.DraconicRef[refId]
	local heroRef = GameTable.CharacterRef[ref.heroId]
	local _, name, color = gModelHeroExtra:GetHeroConfigNameByServerData({ refId = ref.heroId, star = heroRef.initStar },
		true)

	self._mNameStr = name
	self._mNameColor = "#" ..color
	self._mSkillNameStr = ccLngText(ref.name)
	self:SetWndText(self.mName, "")
	self:SetWndText(self.mSkillName, "")
	self:SetWndEasyImage(self.mBg, ref.callBg)
	self:SetWndEasyImage(self.mIcon, ref.callIcon, nil, nil, true)

	local param = {
		refId    = refId,
		showType = true,
	}
	CS.ShowObject(self.mCard, false)
	gModelDraconic:DrawCard(self, self.mDraconicCard, param)

	self:StartTween()

	self:CreateEffect(self.mBgEff, ref.callBgEff, "fx_huodelongwen_bj_zi", 10)
	self:CreateEffect(self.mTitle, "fx_huodelongwen", "fx_huodelongwen", 20)
	self:CreateEffect(self.mCardEff, "fx_huodelongwen_lw", "fx_huodelongwen_lw", 50, function(trans)
		local node = CS.FindTrans(trans, "fx_huodelongwen_1/longwen");
		if node then
			CS.ShowObject(self.mCard, true)
			self.mCard:SetParent(node, false)
			self.mCard.localScale = Vector3(0.01, 0.01, 0.01)
		end
	end, function()
		CS.ShowObject(self.mCard, false)
		self.mCard:SetParent(self._wndTrans, false)
	end)

end

--- 设置节点打字机效果
function UIDraconicGet:SetTransScaleAndPriterAni(transInfo, seq)
	local scale = transInfo.scale
	local trans = transInfo.trans
	local scaleTime = transInfo.scaleTime or 0.3
	local strength = transInfo.strength or 2
	local shakeTime = transInfo.shakeTime or 1
	local isJoin = transInfo.isJoin or false
	CS.ShowObject(trans, false)

	if scale then
		trans.localScale = Vector3(scale, scale, scale)
	end

	seq:AppendCallback(function()
		if not trans.gameObject.activeSelf then
			CS.ShowObject(trans, true)
		end
	end)

	local newImgScaleTween = trans.transform:DOScale(Vector3(1, 1, 1), scaleTime)
	if isJoin then
		seq:Join(newImgScaleTween)
	else
		seq:Append(newImgScaleTween)
	end

	local newShake = self:CreateShakeTrans({
		strength = strength,
		time = shakeTime
	})
	seq:Join(newShake)
end

------------------------------------------------------------------
return UIDraconicGet