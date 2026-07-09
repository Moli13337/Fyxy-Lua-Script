---
--- Created by Administrator.
--- DateTime: 2024/12/4 15:53:21
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDivineWeaponChapter:LWnd
local UIDivineWeaponChapter = LxWndClass("UIDivineWeaponChapter", LWnd)
local centerPos = {
	Vector2.New(-320, 700),   --1
	Vector2.New(-578, 700),   --2
	Vector2.New(-320, 700),   --3
	Vector2.New(-320, 700),   --4
	Vector2.New(-531, 700),   --5
	Vector2.New(-320, 700),   --6
	Vector2.New(-514, 700),   --7
	Vector2.New(-913, 700),   --8
	Vector2.New(-960, 700),   --9
	Vector2.New(-764, 700),   --10
	Vector2.New(-960, 700),   --11
	Vector2.New(-960, 700),   --12
	Vector2.New(-875, 700),   --13
	Vector2.New(-719, 700),   --14
	Vector2.New(-960, 700),   --15
}
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineWeaponChapter:UIDivineWeaponChapter()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineWeaponChapter:OnWndClose()
	LxTimer.DelayTimeStop(self.timer)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineWeaponChapter:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineWeaponChapter:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:SetHead()
	self:SetBarrier()
	self:UpdateReward()
	self:SetBarrierInCenter()
end

function UIDivineWeaponChapter:InitCommon()
	------------------------------------------------------------------
	---member
	self.chapter = self:GetWndArg("id")
	self.barrierCfg = gModelDivineWeaponFight:GetBarrierByChapter(self.chapter)
	self.chapterInfo = gModelDivineWeaponFight:GetChapterInfoById(self.chapter)
	self.curBarrierId = gModelDivineWeaponFight:GetCurBarrierId()
	self.canShow = true

	------------------------------------------------------------------
	---text
	self:SetTextTile(self.mTitle, ccClientText(46200))
	self:SetWndText(self.mTxtReturn, ccClientText(20723))
	self:SetWndText(self.mRewardText, ccClientText(46214))

	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mReturnBtn, function()
		self:WndClose()
	end)

	------------------------------------------------------------------
	---event
	self:WndEventRecv("DescendsInfoResp", function()
		self:OnUpdate()
		self:SetBarrierInCenter()
		self:SetHead()
	end)
	self:WndEventRecv("DescendsStarChestResp", function()
		self:OnUpdate()
	end)
end

function UIDivineWeaponChapter:OnUpdate()
	self.curBarrierId = gModelDivineWeaponFight:GetCurBarrierId()
	self.chapterInfo = gModelDivineWeaponFight:GetChapterInfoById(self.chapter)
	self:SetBarrier()
	self:UpdateReward()
end

function UIDivineWeaponChapter:SetBarrierInCenter()
	local isUpdate = gModelDivineWeaponFight:GetIsUpdateBarrier()
	if isUpdate then
		if not self.canShow then
			return
		end
		self.canShow = false
		local curIndex = self.curIndex
		if curIndex and curIndex > 1 and self.chapter == gModelDivineWeaponFight:GetCurChapterId() then
			self.mContent.localPosition = centerPos[curIndex - 1]
			local oldTrans = self["mChapter" .. curIndex - 1]
			local newTrans = self["mChapter" .. curIndex]
			self.mMe.localPosition = Vector2.New(oldTrans.localPosition.x, oldTrans.localPosition.y + 75)
			self.timer = LxTimer.DelayTimeCall(function()
				local seqCom = self:GetSeqCom()
				local seq = seqCom:CreateSeq("delayFreeze")
				local Tweening = DG.Tweening
				local downTweener = self.mContent:DOLocalMove(centerPos[curIndex], 2):SetEase(Tweening.Ease.Linear)
				seq:Insert(0, downTweener)

				local downTweener2 = self.mMe:DOLocalMove(Vector2.New(newTrans.localPosition.x, newTrans.localPosition.y + 75), 2):SetEase(Tweening.Ease.Linear)
				seq:Insert(0, downTweener2)
				seq:InsertCallback(2, function ()
					GF.OpenWnd("UIDivineWeaponBarrier", { id = self.curBarrierId })
					gModelDivineWeaponFight:SetIsUpdateBarrier(false)
					self.canShow = true
				end)
				seq:PlayForward()
			end, 0.2, true)
			return
		end
		local info = gModelDivineWeaponFight:GetChapterInfoById(self.chapter)
		local passBarrier = info.notFullStarBarriers
		if passBarrier and table.keysize(passBarrier) == 15 then
			GF.OpenWnd("UIDivineWeaponPass", { id = self.chapter })
			gModelDivineWeaponFight:SetIsUpdateBarrier(false)
			return
		end
	end
	if self.curIndex and self.curIndex > 0 then
		self.mContent.localPosition = centerPos[self.curIndex]
		local trans = self["mChapter" .. self.curIndex]
		self.mMe.localPosition = Vector2.New(trans.localPosition.x, trans.localPosition.y + 75)
	end
end

function UIDivineWeaponChapter:SetBarrierTrans(trans, data)
	local lock = CS.FindTrans(trans, "Lock")
	local starObj = CS.FindTrans(trans, "StarObj")
	local name = CS.FindTrans(trans, "Name")
	local role = CS.FindTrans(trans, "Role")
	local isPass = CS.FindTrans(trans, "IsPass")
	local fighting = CS.FindTrans(trans, "Fighting")

	self:SetTextTile(name, ccLngText(data.name))
	self:SetTextTile(isPass, ccClientText(46215))
	local instanceID = trans:GetInstanceID()
	if self.curBarrierId >= data.refId then
		self:CreateWndSpine(role, data.spine, instanceID)
	end

	local isPassList = self.chapterInfo.notFullStarBarriers
	local isPass = isPassList and isPassList[data.refId] ~= nil
	for i = 1, 3 do
		local star = CS.FindTrans(starObj, "Star" .. i)
		local res = "weapon1_star2"
		if isPass then
				res = isPassList[data.refId].star[i] and "weapon1_star1" or "weapon1_star2"
		end
		self:SetWndEasyImage(star, res)
	end

	CS.ShowObject(lock, self.curBarrierId < data.refId)
	CS.ShowObject(isPass, self.curBarrierId > data.refId)
	CS.ShowObject(role, self.curBarrierId >= data.refId)
	CS.ShowObject(fighting, false)

	self:SetWndClick(trans, function()
		GF.OpenWnd("UIDivineWeaponBarrier", { id = data.refId })
	end)
end

function UIDivineWeaponChapter:UpdateReward()
	local chapterInfo = gModelDivineWeaponFight:GetChapterInfoById(self.chapter)
	local chapterCfg = gModelDivineWeaponFight:GetChapterCfgById(self.chapter)
	local starNum = chapterInfo.starNum or 0
	local starProgress = string.split(chapterCfg.starProgress, "=")
	local starChest = chapterInfo.starChest or {}
	local isGetNum = #starChest
	local index
	local canGet
	for i, v in ipairs(starProgress) do
		local num = tonumber(v)
		if starNum <= num and isGetNum < i and not index then
			index = i
		end
		if not canGet and starNum >= num and isGetNum < i then
			canGet = i
		end
	end
	index = index ~= nil and index or 3

	local res
	if canGet then
		res = "quest_icon_box_3"
		self:CreateWndEffect(self.mBox, "fx_richangbaoxiang", "RewardEff", 110)
	elseif not canGet and starNum == tonumber(starProgress[#starProgress]) then
		res = "quest_icon_box_2"
		self:DestroyWndEffectByKey("RewardEff")
	else
		res = "quest_icon_box_1"
		self:DestroyWndEffectByKey("RewardEff")
	end
	self:SetWndEasyImage(self.mBox, res)

	self:SetWndClick(self.mBox, function()
		if canGet then
			gModelDivineWeaponFight:DescendsStarChestReq(self.chapter, canGet)
		else
			GF.OpenWnd("UIDivineWeaponReward", { id = self.chapter })
		end
	end)

	self:SetWndText(self.mProText, starNum .. "/" .. starProgress[#starProgress])
	self:SetWndSliderPara(self.mSlider, starNum == 0 and 0 or starNum / tonumber(starProgress[#starProgress]))
end

function UIDivineWeaponChapter:SetBarrier()
	for i = 1, 15 do
		local trans = self["mChapter" .. i]
		self:SetBarrierTrans(trans, self.barrierCfg[i])

		if self.curBarrierId == self.barrierCfg[i].refId then
			self.curIndex = i
		end
	end
end

function UIDivineWeaponChapter:SetHead()
	local res = gModelPlayer:GetPlayerIconByType(ModelPlayer.PERSONALITY_HEAD_IMAGE)
	self:SetWndEasyImage(CS.FindTrans(self.mHeadObj, "Mask/Head"), res)
	CS.ShowObject(self.mMe, self.chapter == gModelDivineWeaponFight:GetCurChapterId())
end


------------------------------------------------------------------
return UIDivineWeaponChapter