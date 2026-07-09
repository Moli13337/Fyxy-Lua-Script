---
--- Created by Administrator.
--- DateTime: 2024/7/17 16:42:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIOnHookAwardEff:LWnd
local UIOnHookAwardEff = LxWndClass("UIOnHookAwardEff", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOnHookAwardEff:UIOnHookAwardEff()
	self.effNum = 10
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOnHookAwardEff:OnWndClose()
	gModelInstance.isShowOnHookRewardEff = false
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOnHookAwardEff:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOnHookAwardEff:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	local num = gModelItem:GetNumByRefId(ModelItem.ITEM_DIAMOND)
    num = LUtil.NumberCoversion(num)
    self:SetWndText(self.mMasonryNum, num)

	num = gModelItem:GetNumByRefId(ModelItem.ITEM_GOLD)
    num = LUtil.NumberCoversion(num)
    self:SetWndText(self.mGoldNum, num)

	num = gModelPlayer:GetPlayerLv()
    self:SetWndText(self.mLvNum, num)

	local baseClass = HeadIcon:New(self)
	baseClass:SetHeadData({
        trans = self.mHeadIcon,
        icon = gModelPlayer:GetPlayerHead(),
        headFrame = gModelPlayer:GetPlayerHeadFrame(),
    })
	baseClass:RefreshUI()

	self:CreateEff()
	self:EffMove()
end

function UIOnHookAwardEff:EffMove()
	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq("delayFreeze")
	local Tweening = DG.Tweening
	local time = 0.1
	local openTime = 0.3
	local moveTime = 0.9
	for i = 1, self.effNum do
		local root = self["mExp" .. i]
		local pos = Vector2.New(math.random(-140, -40), math.random(-81, 19))
		local downTweener = root:DOLocalMove(pos, openTime):SetEase(Tweening.Ease.Linear)
		seq:Insert(time * i, downTweener)
		local downTweener = root:DOLocalMove(self.mExpHit.localPosition, moveTime):SetEase(Tweening.Ease.InCirc)
		seq:Insert(openTime + (time * i), downTweener)

		root = self["mJinBi" .. i]
		local pos = Vector2.New(math.random(-50, 50), math.random(-59, 41))
		downTweener = root:DOLocalMove(pos, openTime):SetEase(Tweening.Ease.Linear)
		seq:Insert(time * i, downTweener)
		downTweener = root:DOLocalMove(self.mJinBiHit.localPosition, moveTime):SetEase(Tweening.Ease.InCirc)
		seq:Insert(openTime + (time * i), downTweener)

		root = self["mZuanShi" .. i]
		local pos = Vector2.New(math.random(103, 203), math.random(-81, 19))
		downTweener = root:DOLocalMove(pos, openTime):SetEase(Tweening.Ease.Linear)
		seq:Insert(time * i, downTweener)
		downTweener = root:DOLocalMove(self.mZuanShiHit.localPosition, moveTime):SetEase(Tweening.Ease.InCirc)
		seq:Insert(openTime + (time * i), downTweener)

		seq:InsertCallback(openTime + moveTime + (time * i), function()
			self.expHitEff:SetVisible(false)
			self.jinBiHitEff:SetVisible(false)
			self.zuanShiHitEff:SetVisible(false)
			self.expHitEff:SetVisible(true)
			self.jinBiHitEff:SetVisible(true)
			self.zuanShiHitEff:SetVisible(true)
		end)
		local vector = i % 2 == 0 and Vector3.New(1.1, 1.1, 1.1) or Vector3.New(0.9, 0.9, 0.9)
		downTweener = self.mMasonryDiv:DOScale(vector, 0.1)
		seq:Insert(openTime + moveTime + (time * i), downTweener)
		downTweener = self.mGoldDiv:DOScale(vector, 0.1)
		seq:Insert(openTime + moveTime + (time * i), downTweener)
		downTweener = self.mHeadIcon:DOScale(vector, 0.1)
		seq:Insert(openTime + moveTime + (time * i), downTweener)
	end

	seq:InsertCallback(openTime + moveTime + (time * self.effNum) + 0.3, function()
		self:WndClose()
	end)
	seq:PlayForward()
end

function UIOnHookAwardEff:CreateEff()
	for i = 1, self.effNum do
		local root = self["mExp" .. i]
		self:CreateWndEffect(root, "fx_ui_guajijiangli_exp", root.gameObject.name, 120, false, false)
		root = self["mJinBi" .. i]
		self:CreateWndEffect(root, "fx_ui_guajijiangli_jinbi", root.gameObject.name, 120, false, false)
		root = self["mZuanShi" .. i]
		self:CreateWndEffect(root, "fx_ui_guajijiangli_zuanshi", root.gameObject.name, 120, false, false)
	end
	local root = self.mExpHit
	self.expHitEff = self:CreateWndEffect(root, "fx_ui_guajijiangli_hit", root.gameObject.name, 120, false, false)
	self.expHitEff:SetVisible(false)
	root = self.mJinBiHit
	self.jinBiHitEff = self:CreateWndEffect(root, "fx_ui_guajijiangli_hit", root.gameObject.name, 120, false, false)
	self.jinBiHitEff:SetVisible(false)
	root = self.mZuanShiHit
	self.zuanShiHitEff = self:CreateWndEffect(root, "fx_ui_guajijiangli_hit", root.gameObject.name, 120, false, false)
	self.zuanShiHitEff:SetVisible(false)
end



------------------------------------------------------------------
return UIOnHookAwardEff