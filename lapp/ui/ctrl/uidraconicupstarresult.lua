---
--- Created by wzz.
--- DateTime: 2024/4/11 19:48:23
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDraconicUpStarResult:LWnd
local UIDraconicUpStarResult = LxWndClass("UIDraconicUpStarResult", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDraconicUpStarResult:UIDraconicUpStarResult()
	self._effectKey = "1"
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDraconicUpStarResult:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDraconicUpStarResult:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDraconicUpStarResult:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._refId = self:GetWndArg("refId")
	self._starNum = self:GetWndArg("starNum")
	self._oldStarNum = self._starNum - 1

	self:InitTexts()
	self:InitEvents()
	self:InitTweenUI()

	self:Refresh()
	self:PlayEffect()
end

-- 龙语属性
function UIDraconicUpStarResult:RefreshSpeechAttr()
	local curAttrList = gModelDraconic:GetSpeechBaseAttr(self._refId, self._oldStarNum)
	local nextAttrList = gModelDraconic:GetSpeechBaseAttr(self._refId, self._starNum)

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
function UIDraconicUpStarResult:PlayEffect()
	local seqTween
	self:TweenSeqKill(self._effectKey)
	seqTween = self:TweenSeqCreate(self._effectKey, function(seq)
		local showTopTime = 0.2
		local showAttrTime = 0.08

		local bgTween = self.mPanel:DOScale(Vector3.New(1, 1, 1), 0.15)
		local topTween = self.mTop:DOScale(Vector3.New(1, 1, 1), 0.1)
		seq:Append(bgTween)
		seq:Append(topTween)
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

		local tween1 = self.mSkillRoot:DOScale(Vector3.New(1, 1, 1), 0.05)
		local tween2 = self.mTxtCloseTips:DOScale(Vector3.New(1, 1, 1), 0.02)
		seq:Append(tween1)
		seq:Append(tween2)
		return seq
	end)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._effectKey)
		self._playEndEffect = true
	end)
end

-- 初始界面化文本
function UIDraconicUpStarResult:InitTexts()
	self:SetWndText(self.mTxtCloseTips, ccClientText(41037))
end

-- 初始事件
function UIDraconicUpStarResult:InitEvents()
	self:SetWndClick(self.mMask, function(...) if self._playEndEffect then self:WndClose() end end)
end

-- 初始化动画ui设置
function UIDraconicUpStarResult:InitTweenUI()
	self.mPanel.localScale = Vector3.New(1, 0, 1)
	CS.ShowObject(self.mTitleEff.parent, false)
	self.mTop.localScale = Vector3.New(1, 0, 1)
	self.mSpeechAttrRoot.localScale = Vector3.New(0, 0, 1)
	self.mSkillRoot.localScale = Vector3.New(0, 0, 1)
	self.mTxtCloseTips.localScale = Vector3.New(0, 0, 1)
end

-- 创建标题特效
function UIDraconicUpStarResult:CreateTitleEffect()
	CS.ShowObject(self.mTitleEff.parent, true)
	self:CreateEffect(self.mTitleEff, "fx_ui_shengxing_1")
end

-- 刷新界面
function UIDraconicUpStarResult:Refresh()
	local param = {
		refId   = self._refId,
		starNum = self._oldStarNum,
	}
	gModelDraconic:DrawCard(self, self.mDraconicCardLeft, param)
	param = {
		refId   = self._refId,
		starNum = self._starNum,
	}
	gModelDraconic:DrawCard(self, self.mDraconicCardRight, param)

	self:SetWndText(self.mLv1, self._oldStarNum + 1)
	self:SetWndText(self.mLv2, self._starNum + 1)

	local ref = gModelDraconic:GetDraconicRef(self._refId)
	self:SetWndEasyImage(self.mSkillBg1, ref.skillbg)
	self:SetWndEasyImage(self.mSkillIcon1, ref.skillIcon)
	self:SetWndEasyImage(self.mSkillBg2, ref.skillbg)
	self:SetWndEasyImage(self.mSkillIcon2, ref.skillIcon)

	self:SetWndClick(self.mSkill1, function() GF.OpenWnd("UIDraconicUpStar", {refId = self._refId, starNum = self._oldStarNum, tips = true}) end)
	self:SetWndClick(self.mSkill2, function() GF.OpenWnd("UIDraconicUpStar", {refId = self._refId, starNum = self._starNum, tips = true}) end)

	self:RefreshSpeechAttr()
end

-- 创建特效
function UIDraconicUpStarResult:CreateEffect(trans, effectName, effectKey, effectSize)
	effectKey = effectKey or effectName
	effectSize = effectSize or 100
	self:CreateWndEffect(trans, effectName, effectKey, effectSize, false, false)
end

------------------------------------------------------------------
return UIDraconicUpStarResult