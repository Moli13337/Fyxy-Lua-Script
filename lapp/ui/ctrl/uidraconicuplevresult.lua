---
--- Created by wzz.
--- DateTime: 2024/4/12 14:51:11
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDraconicUpLevResult:LWnd
local UIDraconicUpLevResult = LxWndClass("UIDraconicUpLevResult", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDraconicUpLevResult:UIDraconicUpLevResult()
	self._effectKey = 1
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDraconicUpLevResult:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDraconicUpLevResult:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDraconicUpLevResult:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._refId = self:GetWndArg("refId")
	self._lev = self:GetWndArg("lev")
	self._oldLev = self._lev - 1


	self:InitTexts()
	self:InitEvents()
	self:InitTweenUI()

	self:Refresh()
	self:PlayEffect()
end

-- 创建特效
function UIDraconicUpLevResult:CreateEffect(trans, effectName, effectKey, effectSize)
	effectKey = effectKey or effectName
	effectSize = effectSize or 100
	self:CreateWndEffect(trans, effectName, effectKey, effectSize, false, false)
end

-- 龙语属性
function UIDraconicUpLevResult:RefreshSpeechAttr()
	local curAttrList = gModelDraconic:GetIllustratedAttr(self._refId, self._oldLev)
	local nextAttrList = gModelDraconic:GetIllustratedAttr(self._refId, self._lev)
	self._uiSpeechAttrList = self._uiSpeechAttrList or {}
	for k, data in ipairs(curAttrList) do
		local tab = self._uiSpeechAttrList[k]
		if not tab then
			local obj = CS.InstantObject(self.mSpeechAttrRoot.gameObject)
			local trans = obj.transform
			trans:SetParent(self.mSpeechAttrRoot.parent, false)
			tab                       = {}
			tab.obj                   = obj
			tab.trans                 = trans
			tab.icon                  = CS.FindTrans(trans, "AttrIcon")
			tab.txt                   = CS.FindTrans(trans, "AttrValue")
			tab.name                  = CS.FindTrans(trans, "AttrName")
			tab.add                   = CS.FindTrans(trans, "AttrValueAdd")
			self._uiSpeechAttrList[k] = tab

			CS.ShowObject(tab.obj, true)

			local iconPath = gModelHero:GetAttributeIconById(data.attrId)
			self:SetWndEasyImage(tab.icon, iconPath)

			local name = gModelHero:GetAttributeNameById(data.attrId)
			self:SetWndText(tab.name, name)
		end

		local val = gModelHero:GetAttributeValueNoNameByIdAndVal(data.attrId, data.type, data.value)
		self:SetWndText(tab.txt, val)

		if nextAttrList[k] then
			local val = gModelHero:GetAttributeValueNoNameByIdAndVal(data.attrId, data.type, nextAttrList[k].value)
			self:SetWndText(tab.add, val)
		else
			self:SetWndText(tab.add, "")
		end
	end
end

-- 播放动画
function UIDraconicUpLevResult:PlayEffect()
	local seqTween
	self:TweenSeqKill(self._effectKey)
	seqTween = self:TweenSeqCreate(self._effectKey, function(seq)
		local showTopTime = 0.2
		local showAttrTime = 0.08

		local bgTween = self.mPanel:DOScale(Vector3.New(1, 1, 1), 0.15)
		seq:Append(bgTween)
		seq:AppendCallback(function()
			self:CreateTitleEffect()
			LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_UPGRADE_COMMON)
		end)
		seq:AppendInterval(showTopTime)

		for i, v in ipairs(self._uiSpeechAttrList or {}) do
			seq:AppendCallback(function()
				self:CreateEffect(v.trans, "fx_ui_shengxing_3", "eff" .. i)
				local tween = v.trans:DOScale(Vector3.New(1, 1, 1), showAttrTime * 0.8)
				tween:Play()
			end)
			seq:AppendInterval(showAttrTime)
		end
		local tween2 = self.mTxtCloseTips:DOScale(Vector3.New(1, 1, 1), 0.02)
		seq:Append(tween2)
		return seq
	end)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._effectKey)
		self._playEndEffect = true
	end)
end

-- 初始事件
function UIDraconicUpLevResult:InitEvents()
	self:SetWndClick(self.mMask, function(...) if self._playEndEffect then self:WndClose() end end)
end

-- 初始化动画ui设置
function UIDraconicUpLevResult:InitTweenUI()
	self.mPanel.localScale = Vector3.New(1, 0, 1)
	CS.ShowObject(self.mTitleEff.parent, false)
	self.mSpeechAttrRoot.localScale = Vector3.New(0, 0, 1)
	self.mTxtCloseTips.localScale = Vector3.New(0, 0, 1)
end

-- 初始界面化文本
function UIDraconicUpLevResult:InitTexts()
	self:SetWndText(self.mTxtCloseTips, ccClientText(41037))
end

-- 创建标题特效
function UIDraconicUpLevResult:CreateTitleEffect()
	CS.ShowObject(self.mTitleEff.parent, true)
	self:CreateEffect(self.mTitleEff, "fx_ui_shengxing_1")
end

-- 刷新界面
function UIDraconicUpLevResult:Refresh()
	self:RefreshSpeechAttr()
end

------------------------------------------------------------------
return UIDraconicUpLevResult