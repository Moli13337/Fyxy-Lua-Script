---
--- Created by LCM.
--- DateTime: 2024/3/20 17:00:55
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuGradSeasonIdSow:LWnd
local UIKuafuGradSeasonIdSow = LxWndClass("UIKuafuGradSeasonIdSow", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuGradSeasonIdSow:UIKuafuGradSeasonIdSow()
	self._countDownKey = "countDownKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuGradSeasonIdSow:OnWndClose()
	if self._func then self._func() end

	local endTime = gModelCrossGrading:GetEndTime()
	if endTime then
		LPlayerPrefs.SetCrossGradingEndTime(endTime)
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuGradSeasonIdSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuGradSeasonIdSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
	self:InitText()
	self:InitSpine()
end

function UIKuafuGradSeasonIdSow:RunSpine()
	for i,v in ipairs(self._spineNameList) do
		CS.ShowObject(v.effectRoot,true)
		local spineName = v.spineName
		local dpSpine = self:FindWndSpineByKey(spineName)
		if dpSpine then
			dpSpine:PlayAnimation(0,"open",false)
			dpSpine:SetAnimationCompleteFunc(function()
				dpSpine:SetAnimationCompleteFunc(nil)
				if v.target == 1 then
					self:RunAni(true)
				end
				dpSpine:PlayAnimation(0,"idle",true)
			end)
		end
	end
end

function UIKuafuGradSeasonIdSow:OnTimer(key)
	if key == self._countDownKey then
		self:CheckSpineAddStatus()
	end
end

function UIKuafuGradSeasonIdSow:CheckSpineAddStatus()
	local len = #self._spineNameList
	local num = 0
	for k,v in pairs(self._spineCreateStatusList) do
		if v == 1 then
			num = num + 1
		end
	end
	if len == num then
		self:TimerStop(self._countDownKey)
		self:RunSpine()
	end
end

function UIKuafuGradSeasonIdSow:InitData()
	self._info = self:GetWndArg("info")
	self._func = self:GetWndArg("func")
	self._test = self:GetWndArg("test")

	local useGroup = self:GetWndArg("useGroup")
	if not useGroup then useGroup = 0 end
	self._useGroup = useGroup == 1

	self._spineNameList = {
		{
			spineName = "Duanweisaixinfeng",
			effectRoot = self.mXinFengSpineRoot,
			target = 1,
		},
		{
			spineName = "Duanweisailibao",
			effectRoot = self.mLiBaoSpineRoot,
			target = 0,
		},
		{
			spineName = "Duanweisaixiaoren",
			effectRoot = self.mXiaoRenSpineRoot,
			target = 0,
		},
	}
end

function UIKuafuGradSeasonIdSow:SetTextContent(str,trans)
	if not str or not trans then return end
	local t = {
		["a1"] = gModelPlayer:GetPlayerName()
	}

	str = string.gsub(str,"#(%w+)#",t)
	local len,itor = LUtil.FormatPrinterData(str)
	printInfoNR("len = " .. len .. "，str = " .. str)
	self._isTweening = true

	local key = trans:GetInstanceID()

	local perTime = gModelPlot:GetPara("storyWriting") /1000
	local time = len * perTime

	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq(key)
	local tween = YXTween.TweenInt(0,len,time,function (value)
		local temp = itor(value) or ""
		self:SetWndText(trans,temp)
	end)
	seq:Append(tween)
	seq:SetAutoKill(true)
	seq:OnKill(function ()
		self:SetWndText(trans,str)
		self._isTweening = false
	end)
	seq:PlayForward()
end

function UIKuafuGradSeasonIdSow:RunAni(show)
	show = show or false
	if show then CS.ShowObject(self.mContainer,show) end
	local alphaInOutList = {self.mTitle,self.mSeasonTxt,self.mOldSeasonTxt,self.mEnterBtn,self.mLine}
	for i,v in ipairs(alphaInOutList) do
		local aniInfo = {
			aniKey = "ani" .. i,
			trans = v,
			initAlpha = 0,
			fromAlpha = show and 0 or 1,
			toAlpha = show and 1 or 0,
			isVisible = show,
		}
		self:TweenSeq_RootAlphaInOut(aniInfo)
	end
	self:SetTextContent(self._seasonTxt,self.mNewSeasonDesc)
	CS.ShowObject(self.mNewSeasonDesc,show)
	self:SetTextContent(self._oldSeasonTxt,self.mOldSeasonDesc)
	CS.ShowObject(self.mOldSeasonDesc,show)
end

function UIKuafuGradSeasonIdSow:InitEvent()
	--self:SetWndClick(self.mMask,function() self:ExitAni() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function() self:ExitAni() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mEnterBtn,function() self:ExitAni() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIKuafuGradSeasonIdSow:InitSpine()
	if self._useGroup then
		self._spineCreateStatusList = {}
		for i,v in ipairs(self._spineNameList) do
			local spineName = v.spineName
			self._spineCreateStatusList[spineName] = 0
			self:CreateWndSpine(v.effectRoot,spineName,spineName,false,function()
				self._spineCreateStatusList[spineName] = 1
			end)
		end
		self:TimerStop(self._countDownKey)
		self:TimerStart(self._countDownKey,1,false,-1)
	else
		local name = "Duanweisaijiesuan"
		CS.ShowObject(self.mXinFengSpineRoot,true)
		self:CreateWndSpine(self.mXinFengSpineRoot,name,name,false,function(dpSpine)
			dpSpine:PlayAnimationSolid("open",false)
			dpSpine:SetAnimationCompleteFunc(function()
				dpSpine:SetAnimationCompleteFunc(nil)
				self:RunAni(true)
				dpSpine:PlayAnimation(0,"idle",true)
			end)
		end)
	end
end

function UIKuafuGradSeasonIdSow:ExitAni()
	if self._clickClose then return end
	self._clickClose = true
	if self._useGroup then
		for i,v in ipairs(self._spineNameList) do
			local spineName = v.spineName
			local dpSpine = self:FindWndSpineByKey(spineName)
			if dpSpine then
				dpSpine:PlayAnimation(0,"close",false)
				if v.target == 1 then
					dpSpine:SetAnimationCompleteFunc(function()
						dpSpine:SetAnimationCompleteFunc(nil)
						self:WndClose()
					end)
				end
			end
		end
	else
		self:RunAni(false)
		local dpSpine = self:FindWndSpineByKey("Duanweisaijiesuan")
		if dpSpine then
			dpSpine:PlayAnimation(0,"close",false)
			dpSpine:SetAnimationCompleteFunc(function()
				dpSpine:SetAnimationCompleteFunc(nil)
				self:WndClose()
			end)
		end
	end
end

function UIKuafuGradSeasonIdSow:InitText()
	self:SetWndText(self.mSeasonTxt,ccClientText(21849))
	self:SetWndText(self.mOldSeasonTxt,ccClientText(21850))
	self:SetWndButtonText(self.mEnterBtn,ccClientText(21853))

	local info = self._info
	if self._test then
		info = {
			combatTotal = 100,
			rankMax = 15,
			initScore = 800,
			seasonId = 5,
		}
	end

	if not info then return end
	local combatTotal = info.combatTotal
	local rankMax = info.rankMax
	--local initScore = info.initScore
	local initScore =  info.initScore
	local seasonId = gModelCrossGrading:GetSeasonId() or info.seasonId

	local title = string.replace(ccClientText(21848),seasonId)
	self:SetWndText(self.mTitle,title)

	local name = gModelCrossGrading:GetRankNameByScoreAndRank(initScore,nil,true)
	local seasonTxt = string.replace(ccClientText(21851),seasonId,name)
	self._seasonTxt = seasonTxt

	local oldName = gModelCrossGrading:GetRankNameByRefId(rankMax,true)
	if not oldName then
		local firstRefId = gModelCrossGrading:GetCrossGradingFirstRefId()
		oldName = gModelCrossGrading:GetRankNameByRefId(firstRefId,true)
	end
	local oldSeasonTxt = string.replace(ccClientText(21852),combatTotal,oldName)
	self._oldSeasonTxt = oldSeasonTxt
end

------------------------------------------------------------------
return UIKuafuGradSeasonIdSow


