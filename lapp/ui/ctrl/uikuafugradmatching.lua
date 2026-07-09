---
--- Created by LCM.
--- DateTime: 2024/3/18 20:43:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuGradMatching:LWnd
local UIKuafuGradMatching = LxWndClass("UIKuafuGradMatching", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuGradMatching:UIKuafuGradMatching()
	self._waitTimeKey = "_waitTimeKey"
	self._startTimeKey = "_startTimeKey"
	self._centerTimeKey = "_centerTimeKey"
	self._endTimeKey = "_endTimeKey"
	self._showBattleTimeKey = "_showBattleTimeKey"
	self._closeTimeKey = "_closeTimeKey"

	self._startEffName = "fx_ui_duanweisai_vs_kaishi"
	self._endEffName = "fx_ui_duanweisai_vs_xiaoshi"

	self._shakeAnikey = "_shakeAnikey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuGradMatching:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuGradMatching:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuGradMatching:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitMsg()
	self:InitData()
	-- self:RunAni()
	--FireEvent(EventNames.CHANGE_MAIN_BTN,LMainBtnIndexConst.CITY)
    self:RefreshMeDiv()
	self:RefreshOtherDiv()
	self:MoveDiv()
	self:CreateWndEffect(self.mStartBgEff, "fx_ui_duanweisai_vs_new", "fx_ui_duanweisai_vs_new", 100)
end

-- function UIKuafuGradMatching:CreateSpine(trans,figure,showEff)
-- 	local ref = gModelPlayer:GetRoleAdventureImage(figure)
-- 	if not ref then return end
-- 	local key = trans:GetInstanceID()
-- 	self:DestroyWndSpineByKey(key)
-- 	self:CreateWndSpine(trans,ref.paint,key,false,function(dpSpine)
-- 		dpSpine:PlayAnimation(0,"idle",true)
-- 		self:StarShake()
--         CS.ShowObject(trans,true)
-- 		if showEff then
-- 			CS.ShowObject(self.mOtherEff,false)
-- 			local effKey = "fx_ui_duanweisai_juesechuxian"
-- 			self:CreateWndEffect(trans,effKey,effKey,100,false,false)
-- 		end
-- 	end)
-- end

function UIKuafuGradMatching:EnterFightMap()
	-- self:ShowCombat()
	-- CS.ShowObject(self.mStartBgEff,false)
	-- CS.ShowObject(self.mEndBgEff,true)
	-- local effName = self._endEffName
	-- self:CreateWndEffect(self.mEndBgEff,effName,effName,100,false,false,nil,function(dpTrans)
	-- 	dpTrans.gameObject:SetActive(true)
	-- 	CS.ShowObject(self.mMyDiv,false)
	-- 	CS.ShowObject(self.mOtherDiv,false)
	-- end)
	-- self:TimerStop(self._showBattleTimeKey)
	-- self:TimerStart(self._showBattleTimeKey,0.4,false,1)
end

function UIKuafuGradMatching:RunAni()
	-- 界面打开停留时间
	-- local effName = self._startEffName
	-- self:CreateWndEffect(self.mStartBgEff,effName,effName,100,false,false)
	-- local time = gModelCrossGrading:GetConfigByKey("aniWaitTime") or 0.5
	-- self:TimerStop(self._waitTimeKey)
	-- self:TimerStart(self._waitTimeKey,time,false,1)
end


function UIKuafuGradMatching:InitMsg()
-- self:SetWndClick(self.mBg, function()
-- 	self:WndClose()
-- end)
end

function UIKuafuGradMatching:RefreshMeDiv()
	local report = self._report
	if not report then return end
	local attack = report.attack
	if not attack then return end
	CS.ShowObject(self.mMyDiv,true)
	local score = attack:GetScore()
	local rank = attack:GetRank()
	local crossGradingRef = gModelCrossGrading:GetCurCrossGradingIntervalRef(score,rank)
	if crossGradingRef then
		local icon = crossGradingRef.icon
		self:SetWndEasyImage(self.mMyRankIcon,icon,function()
			CS.ShowObject(self.mMyRankIcon,true)
			local iconEffect = crossGradingRef.iconEffect
			if not string.isempty(iconEffect) then
				self:CreateWndEffect(self.mMyRankEff,iconEffect,iconEffect,100,false,false)
			end
		end ,true)
		self:SetWndText(self.mMyRankName,ccLngText(crossGradingRef.name))
		-- CS.ShowObject(self.mMyRankNameBg,true)
	end
	local name = attack:GetName()
	self:SetWndText(self.mMyName,name)
	-- CS.ShowObject(self.mMyNameBg,true)
	-- local figure = attack:GetFigure()
	-- self:CreateSpine(self.mMyLiHui,figure)

	local playerInfo = {
		trans = self.mMyHeadIcon,
		playerId = attack:GetPlayerId(),
		icon = attack:GetHead(),
		headFrame = attack:GetHeadFrame(),
		level = attack:GetGrade(),
	}
	local headIconCls = self:GetHeadIcon("mMyHeadIcon")
	headIconCls:SetHeadData(playerInfo)

	self:SetWndText(self.mMyScore, score)
end

function UIKuafuGradMatching:ShowCombat()
	local report = self._report
	if not report then
		self:WndClose()
		return
	end
	local reportIdList = report.reportIdList
	local first = reportIdList[1]
	if not first then
		self:WndClose()
		return
	end
	local serverId = report.serverId
	if not serverId then
		self:WndClose()
		return
	end
	gModelCrossGrading:StartBattlePlay(report)
end

function UIKuafuGradMatching:MoveDiv()
	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq("MoveDiv")
	local downTweener = self.mMyDiv:DOLocalMove(Vector3.New(0, 179, 0), 0.2):SetEase(DG.Tweening.Ease.Linear)
	seq:Insert(0, downTweener)
	local downTweener = self.mOtherDiv:DOLocalMove(Vector3.New(0, -171, 0), 0.2):SetEase(DG.Tweening.Ease.Linear)
	seq:Insert(0, downTweener)
	local downTweener = self.mMyDiv:DOLocalMove(Vector3.New(646, 179, 0), 0.1):SetEase(DG.Tweening.Ease.Linear)
	seq:Insert(1.6, downTweener)
	local downTweener = self.mOtherDiv:DOLocalMove(Vector3.New(-646, -171, 0), 0.1):SetEase(DG.Tweening.Ease.Linear)
	seq:Insert(1.6, downTweener)
	seq:InsertCallback(2, function()
		self:ShowCombat()
		self:WndClose()
	end)
	seq:PlayForward()
end

function UIKuafuGradMatching:InitData()
	self._report = self:GetWndArg("report")
end

function UIKuafuGradMatching:RefreshOtherDiv()
	local report = self._report
	if not report then return end
	local defense = report.defense
	if not defense then return end
	CS.ShowObject(self.mOtherDiv,true)
	local score = defense:GetScore()
	local rank = defense:GetRank()
	local crossGradingRef = gModelCrossGrading:GetCurCrossGradingIntervalRef(score,rank)
	if crossGradingRef then
		local icon = crossGradingRef.icon
		self:SetWndEasyImage(self.mOtherRankIcon,icon,function()
			CS.ShowObject(self.mOtherRankIcon,true)
			local iconEffect = crossGradingRef.iconEffect
			if not string.isempty(iconEffect) then
				self:CreateWndEffect(self.mOtherRankEff,iconEffect,iconEffect,100,false,false)
			end
		end ,true)
		self:SetWndText(self.mOtherRankName,ccLngText(crossGradingRef.name))
        -- CS.ShowObject(self.mOtherRankNameBg,true)
		-- CS.ShowObject(self.mOtherRankBg,true)
	end
	local name = defense:GetName()
	self:SetWndText(self.mOtherName,name)
	-- CS.ShowObject(self.mOtherNameBg,true)	-- local figure = defense:GetFigure()
	-- self:CreateSpine(self.mOtherLiHui,figure,true)

	local playerInfo = {
		trans = self.mOtherHeadIcon,
		playerId = defense:GetPlayerId(),
		icon = defense:GetHead(),
		headFrame = defense:GetHeadFrame(),
		level = defense:GetGrade(),
	}
	local headIconCls = self:GetHeadIcon("mOtherHeadIcon")
	headIconCls:SetHeadData(playerInfo)

	self:SetWndText(self.mOtherScore, score)
end

function UIKuafuGradMatching:OnTimer(key)
	-- if key == self._waitTimeKey then
	-- 	self:RunStartTimer()
	-- elseif key == self._startTimeKey then
	-- 	-- self:RunCenterTimer()
	-- elseif key == self._centerTimeKey then
	-- 	self:RunEndTimer()
	-- elseif key == self._endTimeKey then
	-- 	self:EnterFightMap()
	-- elseif key == self._showBattleTimeKey then
	-- 	gModelCrossGrading:OnCrossRankMatchInfoReq()
	-- 	self:WndClose()
	-- end
end

-- function UIKuafuGradMatching:RunCenterTimer()
-- 	local effectName = "fx_ui_duanweisai_juesehuadong"
-- 	self:CreateWndEffect(self.mOtherEff,effectName,effectName,100,false,false)
-- 	-- 滚动下方的立绘，匹配对手
-- 	local time = gModelCrossGrading:GetConfigByKey("aniCenterTime") or 2.5
-- 	self:TimerStop(self._centerTimeKey)
-- 	self:TimerStart(self._centerTimeKey,time,false,1)
-- end

function UIKuafuGradMatching:RunEndTimer()
	-- self:RefreshOtherDiv()
	-- -- 显示对手信息
	-- local time = gModelCrossGrading:GetConfigByKey("aniEndTime") or 4
	-- time = 1000
	-- self:TimerStop(self._endTimeKey)
	-- self:TimerStart(self._endTimeKey,time,false,1)
end

function UIKuafuGradMatching:RunStartTimer()
    -- 刷新自己的信息
    -- self:RefreshMeDiv()
	-- self:RefreshOtherDiv()
	-- local time = gModelCrossGrading:GetConfigByKey("aniStartTime") or 0.4
	-- self:TimerStop(self._startTimeKey)
	-- self:TimerStart(self._startTimeKey,time,false,1)
end

-- function UIKuafuGradMatching:StarShake()
-- 	self:TweenSeq_ShakeTrans(self._shakeAnikey,self.mAniRoot,3,1.5)
-- end
------------------------------------------------------------------
return UIKuafuGradMatching


