---
--- Created by BY.
--- DateTime: 2023/10/4 20:38:18
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIRiskRtWin:LWnd
local UIRiskRtWin = LxWndClass("UIRiskRtWin", LWnd)
local Tweening = DG.Tweening
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRiskRtWin:UIRiskRtWin()
	self._effKey = "_effKey"
	self._prEffTrList = {}
	self.commonUIList = {}
	self.expEff = {}
	self.playExpEff = false
	self.oldSpine = ""
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRiskRtWin:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRiskRtWin:OnCreate()
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRiskRtWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()


	self._isJa = gLGameLanguage:IsJapanVersion()
	self:InitEvent()
	self:InitMessage()
	self:InitData()
	self:InitCommand()
end

function UIRiskRtWin:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mHelpBtn, function(...) GF.OpenWnd("UIBzTips",{refId = 1201}) end)
	self:SetWndClick(self.mFind, function()
		if not self._cutLv then return end
		local cfg = gModelGrade:GetGradeLvRefByRefId(self._cutLv)
		if not cfg then return end
		gModelGeneral:OpenHeroStarPre({refId = tonumber(cfg.showSpine)})
	end)
end

function UIRiskRtWin:InitData()
	self._openLvl = self:GetWndArg("lvl")
end

function UIRiskRtWin:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GradeRewardListResp, function(...)
		self._gradeLevel = gModelGrade:GetGradeLevel() or 1
		self._gradeExp = gModelGrade:GetGradeExp() or 0
		local _prEffTrList = self._prEffTrList
		if _prEffTrList then
			for i, v in pairs(_prEffTrList) do
				CS.ShowObject(v, false)
			end
		end
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.QuestListResp, function(...)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.PlayerChangeResp, function(...)
		local _exp = self._gradeExp
		local _gradeLevel = self._gradeLevel
		local _prEffTrList = self._prEffTrList
		if _prEffTrList then
			for i, v in pairs(_prEffTrList) do
				CS.ShowObject(v, false)
			end
		end
		if _exp and _gradeLevel then
			local _gradeExp = gModelGrade:GetGradeExp() or 0
			if _gradeExp <= _exp then
				return
			end
			local effIndexs = {}
			local prList = gModelGrade:GetPrivilegeListByLv(_gradeLevel)
			for i, v in ipairs(prList) do
				local value = v.value
				if _exp < value and value <= _gradeExp then
					table.insert(effIndexs, i)
				end
			end
			if #effIndexs > 0 then
				for i, v in ipairs(effIndexs) do
					local tr = _prEffTrList[v]
					CS.ShowObject(tr, true)
					self:CreateWndEffect(tr, "fx_shilianzhiteng_guangshu", "key" .. v, 100)
				end
			end
		end
		self._gradeLevel = gModelGrade:GetGradeLevel() or 1
		self._gradeExp = gModelGrade:GetGradeExp() or 0
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.QuestReceiveResp, function(...)
		self:RefreshData()
	end)
	self:WndEventRecv("OnGradeRewardResp", function() self:RefreshData() end)
end

function UIRiskRtWin:DrawProgressItem(_, item, data, pos)
	local AniRoot = self:FindWndTrans(item, "AniRoot")
	local Bg = self:FindWndTrans(AniRoot, "Bg")
	local On = self:FindWndTrans(AniRoot, "On")
	local Off = self:FindWndTrans(AniRoot, "Off")
	local Select = self:FindWndTrans(AniRoot, "Select")


	if self._isEnus then
		Bg.sizeDelta =Vector2.New(165,40)
		On.sizeDelta =Vector2.New(165,40)
		Off.sizeDelta =Vector2.New(165,40)
		Select.sizeDelta =Vector2.New(165,40)

		local uiText = LxUiHelper.FindXTextCtrl(self:FindWndTrans(Bg, "Text"))
		if (uiText) then
			uiText.fontSize =18
		end
		local uiText = LxUiHelper.FindXTextCtrl(self:FindWndTrans(On, "Text"))
		if (uiText) then
			uiText.fontSize =18
		end

		local uiText = LxUiHelper.FindXTextCtrl(self:FindWndTrans(Off, "Text"))
		if (uiText) then
			uiText.fontSize =18
		end

		local uiText = LxUiHelper.FindXTextCtrl(self:FindWndTrans(Select, "Text"))
		if (uiText) then
			uiText.fontSize =18
		end

	end


	if data ~= 1 then
		self:SetWndText(self:FindWndTrans(Bg, "Text"), ccLngText(data.name))
		self:SetWndText(self:FindWndTrans(On, "Text"), ccLngText(data.name))
		self:SetWndText(self:FindWndTrans(Off, "Text"), ccLngText(data.name))
		self:SetWndText(self:FindWndTrans(Select, "Text"), ccLngText(data.name))
		if data.refId <= gModelGrade:GetGradeLevel() then
			CS.ShowObject(Bg, true)
			CS.ShowObject(On, data.refId == self._cutLv)
			CS.ShowObject(Off, false)
			CS.ShowObject(Select, false)
		else
			CS.ShowObject(Off, true)
			CS.ShowObject(Select, data.refId == self._cutLv)
			CS.ShowObject(Bg, false)
			CS.ShowObject(On, false)
		end
		self:SetWndClick(AniRoot, function() self:ClickProgressItem(data.refId) end)
	else
		CS.ShowObject(Bg, false)
		CS.ShowObject(On, false)
		CS.ShowObject(Off, false)
		CS.ShowObject(Select, false)
	end
end

function UIRiskRtWin:GetCutTaskRed(lv, cut)
	local selfLv = self._gradeLevel
	if lv >= selfLv and cut == 2 then
		return false
	end
	local refList = gModelGrade:GetGradeLvRef()
	local len = #refList
	for i, v in ipairs(refList) do
		if ((v.refId < lv and cut == 1) or (v.refId > lv and cut == 2)) and len ~= i then
			local bTask = self:GetTaskRedByLv(v.refId, v)
			if (bTask and v.refId <= self._gradeLevel) then
				return true
			end
			if self._gradeLevel == v.refId and self._gradeExp >= v.gradeValue then
				return true
			end
			local bBox = self:GetIsShowBox(v.refId)
			if (bBox) then
				return true
			end
		end
	end

	return false
end

function UIRiskRtWin:ClickProgressItem(id)
	if self.playExpEff then return end

	self:RefreshShowInfo(id)
	self:UpdateRewards()
	self:UpdateHeroInfo()
	self:UpdateStats()
	self:UpdateProgressList()
	if self.progressUIList then
		self.progressUIList:MoveToPos(id + 2, 240)
	end
end

function UIRiskRtWin:OnClickLeaveFor(itemdata)
	local canGoto = gModelQuest:TaskGoto(itemdata._refId, self:GetWndName())
	if canGoto then
		return
	end
end

function UIRiskRtWin:UpdateStats()
	local stats = {}
	local stats2 = {}
	local isNowLvl = self._cutLv == self._gradeLevel
	for i = self._cutLv, 1, -1 do
		local cfg = gModelGrade:GetGradeLvRefByRefId(i)
		if cfg then
			local taskList = self:GetTaskConfigList(i, cfg)
			for i = 1, #taskList, 1 do
				if not isNowLvl or (isNowLvl and taskList[i]._state == 2) then
					local c = gModelQuest:GetTaskConfig(taskList[i]._refId)
					if c then
						if not string.isempty(c.attrReward) then
							local attInfo = string.split(c.attrReward, "=")
							local attrRefId, attrValue = tonumber(attInfo[1]), tonumber(attInfo[3])
							local attCfg = gModelHero:GetAttributeRefById(attrRefId)
							if not stats[attrRefId] then
								stats[attrRefId] = { value = 0, name = ccLngText(attCfg.name), sort = attCfg.sort, type = attCfg.numType }
							end
							stats[attrRefId].value = stats[attrRefId].value + attrValue
						end
					end
				end
			end
		end
	end
	CS.ShowObject(self.mStatsObj, next(stats) ~= nil)
	if next(stats) == nil then return end
	for _, v in pairs(stats) do
		table.insert(stats2, v)
	end
	table.sort(stats2, function(a, b) return a.sort < b.sort end)
	for i = 1, 6 do
		local trans = self["mText" .. i]
		if stats2[i] then
			self:SetWndText(self:FindWndTrans(trans, "NameText"), stats2[i].name)
			local vS = "+"
			if stats2[i].type == 1 then
				vS = vS .. stats2[i].value
			elseif stats2[i].type == 2 then
				vS = vS .. stats2[i].value * 100 .. "%"
			end
			self:SetWndText(self:FindWndTrans(trans, "AdditionText"), vS)
			CS.ShowObject(trans, true)
		else
			CS.ShowObject(trans, false)
		end
		if self._isJa then
			self:InitTextSizeWithLanguage(self:FindWndTrans(trans, "AdditionText"),-2)
			self:InitTextSizeWithLanguage(self:FindWndTrans(trans, "NameText"),-2)
		end
	end
end

function UIRiskRtWin:UpdateRewards()
	local cfg = gModelGrade:GetGradeLvRefByRefId(self._cutLv)
	self:UpdateRewardIcon(self.mDailyRewardIcon, cfg.rewardDaily, false)
	self:UpdateRewardIcon(self.mStateRewardIcon, cfg.rewardUp or "", true)
	CS.ShowObject(self.mDailyReward, not string.isempty(cfg.rewardDaily))
	CS.ShowObject(self.mStateReward, not string.isempty(cfg.rewardUp))
end

function UIRiskRtWin:RefreshShowInfo(_gradeLevel)
	self._cutLv = _gradeLevel
	local ref = gModelGrade:GetGradeLvRefByRefId(_gradeLevel)
	local taskList = self:GetTaskConfigList(_gradeLevel, ref)

	if (self._uiTaskList) then
		self._uiTaskList:RefreshList(taskList)
	else
		self._uiTaskList = self:GetUIScroll("_uiTaskList")
		self._uiTaskList:Create(self.mTaskScroll, taskList, function(...) self:ListItem(...) end, UIItemList.WRAP)
	end
end

function UIRiskRtWin:ShowEndEff()
	if self.endEff then
		CS.ShowObject(self.mEndEff, false)
		CS.ShowObject(self.mEndEff, true)
	else
		self.endEff = self:CreateWndEffect(self.mEndEff, "fx_chengjiu_jifen_1", "endEffKey", 100, false, false)
	end
end

function UIRiskRtWin:UpdateProgressList()
	local list = {}
	local cfg = GameTable.PlayerGradeLvRef
	for _, v in ipairs(cfg) do
		table.insert(list, v)
	end
	local len = #list
	table.insert(list, 1, 1)
	table.insert(list, 1, 1)
	table.insert(list, len + 3, 1)
	table.insert(list, len + 4, 1)
	self.mProgressBg.sizeDelta = Vector2.New((len - 1) * 185, 10)

	local ref = gModelGrade:GetGradeLvRefByRefId(gModelGrade:GetGradeLevel())
	local taskList = self:GetTaskConfigList(gModelGrade:GetGradeLevel(), ref)
	local okNum = 0
	for _, v in ipairs(taskList) do
		if v._state == 2 then
			okNum = okNum + 1
		end
	end
	self.mProgressFill.sizeDelta = Vector2.New(((gModelGrade:GetGradeLevel() - 1) + (okNum / #taskList)) * 185, 10)
	if not self.progressUIList then
		self.progressUIList = self:GetUIScroll("mProgressList")
		self.progressUIList:Create(self.mProgressList, list, function(...) self:DrawProgressItem(...) end,
			UIItemList.SUPER_GRID)
	else
		self.progressUIList:RefreshList(list)
		self.progressUIList:DrawAllItems()
	end
end

function UIRiskRtWin:InitCommand()
	local type = self:GetWndArg("type") or 0
	self:SetWndText(self.mLblBiaoti,ccClientText(18200))
	self:SetWndText(self.mDailyText, ccClientText(18213))
	self:SetWndText(self.mDailyText_enus, ccClientText(18213))
	self:SetWndText(self.mStateText, ccClientText(18237))
	self:SetWndText(self.mStateText_enus, ccClientText(18237))

	CS.ShowObject(self.mDailyBg,not self._isEnus)
	CS.ShowObject(self.mStateBg,not self._isEnus)
	CS.ShowObject(self.mDailyBg_enus,self._isEnus)
	CS.ShowObject(self.mStateBg_enus,self._isEnus)

	self._gradeLevel = gModelGrade:GetGradeLevel() or 1
	self._gradeExp = gModelGrade:GetGradeExp() or 0
	self:RefreshData()

	if self._isOne then
		return
	end
	self._isOne = true
	if type == 2 then
		local bool = gModelGrade:GetCurRewardSignRef()
		if not bool then
			type = 1
		end
	end
	if type == 1 then
		local maskLv = gModelPlayer:GetRoleConfigRefByKey("gradeDailyRewardShow")
		local lv = gModelPlayer:GetPlayerLv()
		local inguide = gModelGuide:HasWaitGuide()
		if lv >= maskLv and self:GetIsShowBox(self._gradeLevel) and not inguide then
			GF.OpenWnd("UIGdeAwardPop",{refId = self._cutLv})
		end
	end
end

function UIRiskRtWin:RefreshData()
	self._onClick = false
	if not self._openLvl then
		self._gradeLevel = gModelGrade:GetGradeLevel() or 1
		local openLvl = self._gradeLevel
		for i = self._gradeLevel, 1, -1 do
			local ref = gModelGrade:GetGradeLvRefByRefId(i)
			local taskList = self:GetTaskConfigList(i, ref)
			local ischange = false
			for _, v in ipairs(taskList) do
				if v._state == 1 then
					openLvl = i
					ischange = true
					break
				end
			end
			if ischange then break end
			local isGet = self:GetIsShowBox(i)
			if isGet then
				openLvl = i
				break
			end
		end
		self:ClickProgressItem(openLvl)
	else
		self:ClickProgressItem(self._openLvl)
		self._openLvl = nil
		self._isOne = true
	end
end

function UIRiskRtWin:ListItem(list, item, itemdata, itempos)
	local nameText = CS.FindTrans(item, "NameBg/NameText")
	local TaskPro = CS.FindTrans(item, "NameBg/TaskPro")
	local TaskText = CS.FindTrans(item, "TaskText")
	local goToBtn1 = CS.FindTrans(item, "GoToBtn1")
	local goToBtn2 = CS.FindTrans(item, "GoToBtn2")
	local eff = CS.FindTrans(item, "Eff")
	local maskImg = CS.FindTrans(item, "MaskImg")
	local expEff = CS.FindTrans(item, "ExpEff")

	CS.ShowObject(goToBtn1, false)
	CS.ShowObject(goToBtn2, false)
	CS.ShowObject(maskImg, false)
	CS.ShowObject(eff, false)

	local InstanceID = item:GetInstanceID()
	local ref = gModelQuest:GetTaskConfig(itemdata._refId)
	local numStr = ""
	local _schedule = tonumber(itemdata._schedule)
	local _goal = tonumber(itemdata._goal)
	local _scheduleStr = LUtil.NumberCoversion(_schedule)
	local _goalStr = LUtil.NumberCoversion(_goal)
	if _schedule < _goal then
		numStr = string.replace(ccClientText(18232), _scheduleStr, _goalStr)
	else
		numStr = string.replace(ccClientText(18233), _scheduleStr, _goalStr)
	end
	local _finishCount = itemdata._finishCount
	CS.ShowObject(TaskPro, _finishCount and (not itemdata._state or itemdata._state ~= 2))
	if _finishCount then
		self:SetWndText(TaskPro, numStr)
	end
	self:SetWndText(nameText, ccLngText(ref.description))
	self:InitTextSizeWithLanguage(nameText, -2)
	local maskStr = ""
	local goToStr = ""
	local func = nil
	if (self._cutLv > self._gradeLevel) then
		maskStr = "public_txt_7_3"
	elseif (itemdata._state == 2) then
		maskStr = "achievement_txt_2"
	elseif (itemdata._state == 1) then
		goToStr = ccClientText(18214)
		CS.ShowObject(goToBtn2, true)
		CS.ShowObject(eff, true)
		self:PlayEff(eff, "fx_anniu_02", InstanceID)
		func = function()
			self:SetTween(expEff, itempos)
			self:OnClickTask(itemdata._refId)
		end
	else
		goToStr = ccClientText(12535)
		CS.ShowObject(goToBtn1, true)
		func = function()
			self:OnClickLeaveFor(itemdata)
		end
	end
	if (maskStr ~= "") then
		CS.ShowObject(maskImg, true)
		self:SetWndEasyImage(maskImg, maskStr)
	end
	self:SetWndButtonText(goToBtn1, goToStr)
	self:SetWndButtonText(goToBtn2, goToStr)
	if (func) then
		self:SetWndClick(goToBtn1, function(...)
			func()
		end)
		self:SetWndClick(goToBtn2, function(...)
			func()
		end)
	end


	if not string.isempty(ref.attrReward) then
		local attInfo = string.split(ref.attrReward, "=")
		local attrRefId, attrValue = tonumber(attInfo[1]), tonumber(attInfo[3])
		local attCfg = gModelHero:GetAttributeRefById(attrRefId)
		local type = attCfg.numType
		local vS = type == 1 and " <#139057>+#a1#</color>" or " <#139057>+#a1#%</color>"
		local value = type == 1 and attrValue or attrValue * 100
		vS = string.replace(vS, value)
		self:SetWndText(TaskText, ccLngText(attCfg.name) .. vS)
	end
	if not string.isempty(ref.SysReward) then
		local cfg = gModelGeneral:GetSysEffectRef(tonumber(ref.SysReward))
		self:SetWndText(TaskText, ccLngText(cfg.desc))
	end
end

function UIRiskRtWin:GetTaskRedByLv(lv, ref)
	local list = self:GetTaskConfigList(lv, ref)
	if #list < 1 then
		return false
	end
	for i, v in ipairs(list) do
		if (v._state == 1) then
			return true
		end
	end
end

function UIRiskRtWin:GetIsShowBox(lv)
	local rewards = gModelGrade:GetRewards()
	if (not rewards or #rewards < 1) then
		gModelGrade:OnGradeRewardListReq()
		self._isOne = false
		return false
	end
	local isLV = self._gradeLevel >= lv
	local reward = rewards[lv]
	local isShowBox = reward and reward ~= 1
	return isShowBox and isLV
end

function UIRiskRtWin:SetTween(tran, itempos)
	self.playExpEff = true
	if self.progressUIList then
		self.progressUIList:MoveToPos(gModelGrade:GetGradeLevel() + 2, 240)
	end
	local oldPos = tran.localPosition
	local seqTween
	self:TweenSeqKill("Tween_key" .. itempos)
	seqTween = self:TweenSeqCreate("Tween_key" .. itempos,function(seq)
		if self.expEff[itempos] then
			CS.ShowObject(tran, true)
		else
			self.expEff[itempos] = self:CreateWndEffect(tran, "fx_chengjiu_jifen_2", itempos, 100, false, false)
		end
		local moveY = 35 + (itempos - 1) * 117
		local tweener = tran.transform:DOLocalMove(Vector3.New(300, moveY, 0), 0.2)
		seq:Append(tweener)
		return seq
	end)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self.playExpEff = false
		CS.ShowObject(tran, false)
		tran.localPosition = oldPos
		self:ShowEndEff()
		self:ClickProgressItem(gModelGrade:GetGradeLevel())
	end)
end

function UIRiskRtWin:UpdateHeroInfo()
	local cfg = gModelGrade:GetGradeLvRefByRefId(self._cutLv)
	if not cfg then return end
	local heroCfg = GameTable.CharacterRef[cfg.showSpine]
	local heroEffCfg = GameTable.CharacterEffectRef[cfg.showSpine]
	local qualityRef = gModelItem:GetQualityRef(heroCfg.quality)
	self:SetWndText(self.mHeroNameText, gModelHero:GetHeroNameByRefId(cfg.showSpine))
	for i = 1, 5 do
		CS.ShowObject("mStar" .. i, heroCfg.initStar <= i)
	end
	self:SetWndEasyImage(self.mHeroQuaIcon, heroCfg.qualityIcon)
	self:SetWndEasyImage(self.mHeroNameBg, qualityRef.heroMsgNameBg)
	self:SetWndEasyImage(self.mHeroRaceIcon, gModelHero:GetHeroRaceRef()[heroCfg.raceType].icon)

	local scale = Vector3.One
	if not string.isempty(cfg.showScale) then
		scale = tonumber(cfg.showScale)
	end
	if heroEffCfg.heroDrawing ~= self.oldSpine then
		self.oldSpine = heroEffCfg.heroDrawing
		if self.heroSpine then
			self:DestroyWndSpineByKey("heroSpineKey")
		end
		self.heroSpine = self:CreateWndSpine(self.mSpine, heroEffCfg.heroDrawing, "heroSpineKey", false, function(dpSpine)
			dpSpine:SetScale(scale)
		end)
		if not string.isempty(cfg.showXY) then
			local pos = LxDataHelper.ParseVector2NotEmpty(cfg.showXY)
			self:SetAnchorPos(self.mSpine, pos)
		end
	end
end

function UIRiskRtWin:PlayEff(trans, eff, key, bDefaultLayer)
	self:CreateWndEffect(trans, eff, key, 100, bDefaultLayer, false, 0, nil, 100)
end

function UIRiskRtWin:OnClickTask(refId)
	local netData = gModelQuest:GetTaskDataByRefId(refId)
	if not netData then
		return
	end
	local state = netData:GetState()
	if state ==0 then
		local cfg = gModelQuest:GetTaskConfig(refId)
		local originId = cfg.originId
		if originId > 0 then
			gModelQuest:TaskGoto(refId,self:GetWndName())
		else
			GF.ShowMessage(ccClientText(12210))
		end
	elseif state== 1 then
		gModelQuest:OnQuestReceiveReq(refId)
		local c = gModelQuest:GetTaskConfig(refId)
		if c then
			if not string.isempty(c.attrReward) then
				local attInfo = string.split(c.attrReward, "=")
				local attrRefId, attrValue = tonumber(attInfo[1]), tonumber(attInfo[3])
				gModelGeneral:OpenHeroPowerTip({ { refId = attrRefId, addNum = attrValue } })
			end
		end
	elseif state == 2 then
		GF.ShowMessage(ccClientText(12211))
	end
end

function UIRiskRtWin:UpdateRewardIcon(trans, rewards, isState)
	local info = string.split(rewards, ",")
	local isGet = self:GetIsShowBox(self._cutLv)
	for i = 1, 2 do
		local IconObj = self:FindWndTrans(trans, "Icon" .. i)
		local IconRoot = self:FindWndTrans(IconObj, "IconRoot")
		local redPoint = self:FindWndTrans(IconObj, "redPoint")
		if info[i] then
			local icon = self.commonUIList[trans.gameObject.name .. i]
			local reward = LxDataHelper.ParseItem_3(info[i])
			if not icon then
				icon = CommonIcon:New()
				icon:Create(IconRoot)
				self.commonUIList[trans.gameObject.name .. i] = icon
			end
			icon:SetCommonReward(reward.itemType, reward.itemId, reward.itemNum)
			icon:EnableShowNum(true)
			if isState then
				if self._cutLv >= gModelGrade:GetGradeLevel() then
					icon:ShowLock(true)
					CS.ShowObject(redPoint, false)
				else
					icon:SetShowGouImg(true)
					CS.ShowObject(redPoint, false)
				end
			else
				if self._cutLv > gModelGrade:GetGradeLevel() then
					icon:ShowLock(true)
					CS.ShowObject(redPoint, false)
				else
					icon:SetShowGouImg(not isGet)
					CS.ShowObject(redPoint, isGet)
				end
			end
			icon:DoApply()
			self:SetImageAlpha(icon._curIconCls._uiMaskTrans, 0.6)
			self:SetWndClick(IconObj, function()
				if not isState and isGet then
					GF.OpenWnd("UIGdeAwardPop", { refId = self._cutLv })
				else
					gModelGeneral:ShowCommonItemTipWnd(reward)
				end
			end)
			CS.ShowObject(IconRoot, true)
		else
			CS.ShowObject(IconRoot, false)
		end
	end
end

function UIRiskRtWin:GetTaskConfigList(lv, ref)
	local taskList = {}
	local questIdArr = string.split(ref.questId, ";")
	local list = gModelQuest:GetTaskKeyList(ModelQuest.GRADE_QUEST)
	for i, v in ipairs(questIdArr) do
		local task = list[tonumber(v)]
		if task then
			table.insert(taskList, task)
		else
			local ref = gModelQuest:GetTaskConfig(tonumber(v))
			if ref then
				local finishCondArr = string.split(ref.finishCond, "=")
				local state = lv > self._gradeLevel and 0 or 2
				local schedule, goal
				if ref.questProgressType == 1 then
					schedule, goal = lv <= self._gradeLevel and "1" or "0", "1"
				else
					local strArr = string.split(finishCondArr[3], ",")
					local len = #strArr
					schedule, goal = lv <= self._gradeLevel and strArr[len] or "0", strArr[len]
				end
				local task = {
					_refId = ref.refId,
					_schedule = schedule,
					_sort = ref._sort,
					_state = state,
					_goal = goal
				}
				table.insert(taskList, task)
			end
		end
	end
	return taskList
end
------------------------------------------------------------------
return UIRiskRtWin


