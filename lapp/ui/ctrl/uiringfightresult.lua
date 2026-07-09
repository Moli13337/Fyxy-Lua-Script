---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local Tweening = DG.Tweening
---
local LWnd = LWnd
---@class UIringFightResult:LWnd
local UIringFightResult = LxWndClass("UIringFightResult", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIringFightResult:UIringFightResult()
	---@type UIIconEasyList
	self._uiRewardList = nil
	---@type UIIconEasyList
	self._uiMinRewardList = nil
	self._canWndClose = false
	self._cantCloseTimer = nil
	self._heroQuotations = "_heroQuotations"


	self._speed = 0.5
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIringFightResult:OnWndClose()
	if self._seqList then
		for k, v in pairs(self._seqList) do
			v:Kill(false)
		end
	end
	if self._uiRewardList then
		self._uiRewardList:Destroy()
		self._uiRewardList = nil
	end

	if self._uiMinRewardList then
		self._uiMinRewardList:Destroy()
		self._uiMinRewardList = nil
	end

	self._seqList = nil

	local isVideoAlive = gModelBattle:IsVideoAlive()

	local combatType = self._combatType or LCombatTypeConst.COMBAT_ARENA_ATTACK
	--local wndName = self:GetWndName()
	--FireEvent(EventNames.ON_ACCOUNT_RELA_WND_CLOSE,wndName,combatType)

	local needSend = not self._isClickRet and not self._isFromBack and not isVideoAlive --and not self._isOutLine

	if needSend then
		FireEvent(EventNames.ON_EXIT_ACCOUNT_WND, combatType)
	end

	self:StopCrossGradingRankBarTween()
	--if not isVideoAlive then
	--	local reportId = self._combatResult and self._combatResult.reportId
	--	gModelBattle:ClearCacheReportByKey({reportId = reportId})
	--end
	gLGameAudio:StopSingleSound()
	gLGameAudio:StopSound()

	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIringFightResult:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIringFightResult:OnStart()
	LWnd.OnStart(self)
	--self:StartCantWndCloseTime()
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()
	
	if self._isEnus then
		self["mWarTempleItemIcon" .. 1].localPosition =self["mWarTempleItemIcon" .. 1].localPosition +Vector3.New(20,0,0)
		self["mTxtWarTempleItemNum" .. 1].localPosition =self["mTxtWarTempleItemNum" .. 1].localPosition +Vector3.New(20,0,0)
	end 
	
	
	self:InitServerData()

	self:InitList()

	self:SetStaticContent()
	self:RefreshUI()
	self:InitUIEvent()
	self:SetMvpHero()
	self:SetWndText(self.mCloseTip, ccClientText(10103))
end

function UIringFightResult:BackWarTemplate()
	self._isClickRet = true
	local returnFunc = gModelBattle:GetReturnFun(LCombatTypeConst.COMBAT_WAR_TEMPLE)
	if returnFunc then
		returnFunc()
	end
end

function UIringFightResult:InitUIEvent()
	self:SetWndClick(self.mBackArenaBtn, function() self:BackWnd() end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mOkBtn, function() self:OnClickOk() end, LSoundConst.CLICK_BUTTON_COMMON)
	--self:SetWndClick(self.mMask,function () self:OnClickOk() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mStatistics, function() self:ShowDetail() end, LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mBackPlay, function() self:CommonBackPlay() end, LSoundConst.CLICK_BUTTON_COMMON)
end

function UIringFightResult:OnClickOk()
	--if not self._isFromBack and not self._isOutLine then
	--	self:BackArena()
	--else



	self:WndClose()
	--end
end

function UIringFightResult:TweenNum(tweendata)
	local dtSequence = Tweening.DOTween.Sequence()
	local call = function(value)
		self:SetChangeContent(tweendata.tran, tweendata.format, tweendata.cur, value, tweendata.isRight)
	end
	local tween = YXTween.NumberTo(tweendata.startNum, tweendata.endNum, tweendata.duration, call)
	dtSequence:Append(tween)
	dtSequence:Play()
	return dtSequence
end

function UIringFightResult:OpenArenaDetail()
	self:OpenBattleDetails({
		meName = self.meName,
		otherName = self.otherName,
		combatType = LCombatTypeConst.COMBAT_ARENA_ATTACK,
		reportId = self._combatResult.reportId,
	})
end

function UIringFightResult:SetPlayer(item, itemdata, isSelf)
	local battleRet = self._combatResult

	local headIcon = self:FindWndTrans(item, "HeadIcon")
	local scoreTrans = self:FindWndTrans(item, "score")
	local PowerIconTrans = self:FindWndTrans(item, "PowerIcon")
	local scoreInfo = self:FindWndTrans(item, "scoreInfo")
	local name = self:FindWndTrans(item, "name")

	local line = self:FindWndTrans(item, "line")

	--local format="%s"
	local format = "#a1#"
	if self._combatType == LCombatTypeConst.COMBAT_WAR_TEMPLE then
		if isSelf then
			format = ccClientText(42065)
		else
			format = ccClientText(42066)
		end

		local posx = name.anchoredPosition.x
		local pos = scoreInfo.anchoredPosition
		pos.x = posx
		scoreInfo.anchoredPosition = pos
	end
	local score = itemdata.score or itemdata:GetScore()
	local change = itemdata.change or itemdata:GetChange()

	local isCrossGradingType = self:IsCrossGradingType()
	if isCrossGradingType then
		if battleRet then
			change = isSelf and battleRet.scoreA or battleRet.scoreB
		end
	end
	-- local isCombatType33 = self:IsCombatType33()
	-- CS.ShowObject(scoreTrans,not isCombatType33)
	-- if isCombatType33 then
	-- 	local first = self:FindWndTrans(scoreInfo,"first")
	-- 	self:SetWndText(first,LUtil.PowerNumberCoversion(itemdata.power))
	-- else
	self:SetChangeContent(scoreInfo, format, score, change, not isSelf)
	-- end
	CS.ShowObject(PowerIconTrans, isCrossGradingType)

	if self._combatType == LCombatTypeConst.COMBAT_ARENA_ATTACK then
		self:SetWndEasyImage(PowerIconTrans, "actionarena_icon_1", nil, true)
		PowerIconTrans.localScale = Vector2.New(0.5, 0.5)
		CS.ShowObject(PowerIconTrans, true)
	elseif self._combatType == LCombatTypeConst.COMBAT_CROSSGRADING_RANK then
		self:SetWndEasyImage(PowerIconTrans, "crossGrading_icon_1", nil, true)
		PowerIconTrans.localScale = Vector2.New(0.5, 0.5)
		CS.ShowObject(PowerIconTrans, true)
	end


	CS.ShowObject(line, isCrossGradingType)
	local isChange = change ~= 0

	local nameStr = itemdata.name
	if not nameStr then
		nameStr = itemdata:GetName()
	end
	self:SetWndText(name, nameStr)

	local playerInfo = {
		trans = headIcon,
		icon = itemdata.head or itemdata:GetHead(),
		headFrame = itemdata.headFrame or itemdata:GetHeadFrame(),
		name = itemdata.name or nameStr,
		level = itemdata.grade or itemdata:GetGrade(),
	}

	if self._combatType == LCombatTypeConst.COMBAT_WAR_TEMPLE and itemdata.playerId == 0 then
		playerInfo.level = nil
	end
	if self._combatType == LCombatTypeConst.COMBAT_CROSS_WAR and itemdata.playerId == 0 then
		playerInfo.level = nil
	end

	local playerId = itemdata.playerId or itemdata:GetPlayerId()
	local headClass = HeadIcon:New(self)
	headClass:SetHeadData(playerInfo)
	headClass:RefreshUI()
	if not isSelf then
		self:SetWndClick(headIcon, function()
			if playerId == 0 and self._combatType == LCombatTypeConst.COMBAT_WAR_TEMPLE then
				GF.ShowMessage(ccClientText(42040))
				return
			end
			if playerId == 0 and self._combatType == LCombatTypeConst.COMBAT_CROSS_WAR then
				GF.ShowMessage(ccClientText(43857))
				return
			end

			gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
		end)
	end

	if not self._tweenDataList then
		self._tweenDataList = {}
	end
	if isChange then
		local tChange = itemdata.change or itemdata:GetChange()
		if isCrossGradingType then
			tChange = isSelf and battleRet.scoreA or battleRet.scoreB
		end
		local tweenData = {
			tran = scoreInfo,
			cur = itemdata.score or itemdata:GetScore(),
			startNum = 0,
			endNum = tChange,
			duration = 1,
			format = format,
			isRight = not isSelf,
		}
		table.insert(self._tweenDataList, tweenData)
	end
end

function UIringFightResult:BackWnd()
	if self._combatType == LCombatTypeConst.COMBAT_WAR_TEMPLE then
		self:BackWarTemplate()
		return
	end
	if self._combatType == LCombatTypeConst.COMBAT_CROSS_WAR then
		self:BackArena()
		return
	end

	if self:IsCrossGradingType() then
		self:BackCrossGrading()
		-- elseif self:IsCombatType33() then
		-- 	local func = gModelBattle:GetReturnFun(LCombatTypeConst.COMBAT_TYPE_33)
		-- 	if func then
		-- 		func(self._combatResult)
		-- 	end
	else
		self:BackArena()
	end
end

function UIringFightResult:ShowDetail()
	if self:IsCrossGradingType() then
		self:OpenCrossGradingDetail()
		-- elseif self:IsCombatType33() then
		-- 	self:OpenBattleDetails({
		-- 		meName = self.meName,
		-- 		otherName = self.otherName,
		-- 		combatType = LCombatTypeConst.COMBAT_TYPE_33,
		-- 	})
	else
		self:OpenArenaDetail()
	end
end

function UIringFightResult:ShowRewards(itemList)
	local itemNum = #itemList
	local isShowMin = itemNum <= 5

	CS.ShowObject(self.mMinRewardList, isShowMin)
	CS.ShowObject(self.mRewardList, not isShowMin)
	CS.ShowObject(self.mTitleBg2, itemNum > 0)

	local uiList
	if isShowMin then
		uiList = self._uiMinRewardList
		if not uiList then
			uiList = UIIconEasyList:New()
			self._uiMinRewardList = uiList
			uiList:Create(self, self.mMinRewardList)
			uiList:EnableScroll(false)
		end
		uiList:RefreshList(itemList, true)
	else
		uiList = self._uiRewardList
		if not uiList then
			uiList = UIIconEasyList:New()
			self._uiRewardList = uiList
			uiList:Create(self, self.mRewardList)
			uiList:EnableScroll(true, false)
		end
		uiList:RefreshList(itemList, true)
	end
end

function UIringFightResult:GetProgress(selfData, changeScore)
	if not selfData then return end

	local tween = self._bloodTweem

	local curScore = selfData:GetScore()
	local curRank = selfData:GetRank()

	local rank = gModelCrossGrading:GetRank()
	local score = gModelCrossGrading:GetScore()

	local showRankDiv = false
	local curCrossGradingRef = gModelCrossGrading:GetCurCrossGradingIntervalRef(curScore, curRank)
	local crossGradingRef = gModelCrossGrading:GetCurCrossGradingIntervalRef(score, rank)
	if crossGradingRef and curCrossGradingRef then
		local curRefId = curCrossGradingRef.refId
		local refId = crossGradingRef.refId

		local curScoreDown = curCrossGradingRef.scoreDown
		local curScoreUp = curCrossGradingRef.scoreUp
		local isCurMaxRank = curScoreUp == ModelCrossGrading.SCOREUP_MAX

		local scoreDown = crossGradingRef.scoreDown
		local scoreUp = crossGradingRef.scoreUp
		local isMaxRank = scoreUp == ModelCrossGrading.SCOREUP_MAX

		local notSameRank = curRefId ~= refId

		local curPregressNum = curScore - curScoreDown
		local pregressNum = curScoreUp - curScoreDown
		local curPregress = curPregressNum / pregressNum
		if isCurMaxRank then
			curPregressNum = curScore
			pregressNum = curScoreDown
			curPregress = 1
		end

		local curNum = score - scoreDown
		local maxNum = scoreUp - scoreDown
		local percent = curNum / maxNum
		if isMaxRank then
			curNum = score
			maxNum = scoreDown
			percent = 1
		end
		--LxUiHelper.SetProgress(self.mCrossGradingBar,percent)

		local image = self.mCrossGradingBar
		local key = image:GetInstanceID()
		local progress = self:UIProgressFind(image, key, 0)
		if notSameRank then
			local curShowNum, curToNum, newShowNum, newToNum
			local curTextNum, curToTextNum, newTextNum, newToTextNum
			local isUpRank = score > curScore
			if isUpRank then
				curShowNum, curToNum, newShowNum, newToNum = curPregress, 1, 0, percent
				curTextNum, curToTextNum, newTextNum, newToTextNum = curPregressNum, pregressNum, 0, curNum
			else
				curShowNum, curToNum, newShowNum, newToNum = curPregress, 0, 1, percent
				curTextNum, curToTextNum, newTextNum, newToTextNum = curPregressNum, 0, pregressNum, curNum
			end
			printInfoNR("=== curShowNum,curToNum,newShowNum,newToNum = ", curShowNum, curToNum, newShowNum, newToNum)

			tween:Append(YXTween.TweenFloat(curShowNum, curToNum, self._speed, function(t)
				progress:SetUIProgress(t)
			end))
			tween:Join(YXTween.TweenInt(curTextNum, curToTextNum, self._speed, function(t)
				self:SetWndText(self.mCrossGradingNum, string.format("%s/%s", t, pregressNum))
			end))

			tween:Append(YXTween.TweenFloat(newShowNum, newToNum, self._speed, function(t)
				progress:SetUIProgress(t)
			end))
			tween:Join(YXTween.TweenInt(newTextNum, newToTextNum, self._speed, function(t)
				self:SetWndText(self.mCrossGradingNum, string.format("%s/%s", t, maxNum))
			end))


			self:TweenSeq_FadeInStaysAway("xiaoshi", self.mCrossGradingRankIcon, {
				showTime = 0,
				waitTime = 0.1,
				noShowTime = 0.5,
				runFunc = function()
					if not self:IsWndValid() then return end
					CS.ShowObject(self.mCrossGradingRankIcon, true)
					self:SetWndEasyImage(self.mCrossGradingRankIcon, curCrossGradingRef.icon, nil, true)
				end,
				completeFunc = function()
					if not self:IsWndValid() then return end

					CS.ShowObject(self.mCrossGradingRankIcon, false)
					self:SetWndEasyImage(self.mCrossGradingRankIcon, crossGradingRef.icon, nil, true)

					self:TweenSeq_FadeInStaysAway("chuxian", self.mCrossGradingRankIcon, {
						toAlpha = 0,
						fromAlpha = 1,
						showTime = 0,
						waitTime = 0.1,
						noShowTime = 0.5,
						runFunc = function()
							if not self:IsWndValid() then return end

							CS.ShowObject(self.mCrossGradingRankIcon, true)
						end
					})
				end
			})
		else
			tween:Append(YXTween.TweenFloat(curPregress, percent, self._speed, function(t)
				progress:SetUIProgress(t)
			end))

			tween:Join(YXTween.TweenInt(curPregressNum, curNum, self._speed, function(t)
				self:SetWndText(self.mCrossGradingNum, string.format("%s/%s", t, maxNum))
			end))

			self:SetWndEasyImage(self.mCrossGradingRankIcon, crossGradingRef.icon, nil, true)
		end

		showRankDiv = true
	end
	CS.ShowObject(self.mCrossGradingRankDiv, showRankDiv)

	local showQuotation = not showRankDiv
	if gModelBattle:ShowBattleInfoState() then
		showQuotation = not showRankDiv
	else
		showQuotation = false
	end
	CS.ShowObject(self.mHeroQuotations, showQuotation)
	CS.ShowObject(self.mMvpNameBg, not showRankDiv)
	CS.ShowObject(self.mMvpOutputBg, not showRankDiv)
	CS.ShowObject(self.mMvpBearBg, not showRankDiv)
	CS.ShowObject(self.mMvpCureBg, not showRankDiv)
end

function UIringFightResult:CommonBackPlay()
	local isCrossGradingType = self:IsCrossGradingType()
	if isCrossGradingType then
		self:OnCrossGradingBackPlay()
	else
		self:OnBackPlay()
	end
end

function UIringFightResult:GetHeroRefId(hero)
	local heroRefId = hero.refId
	-- if self:IsCombatType33() then
	-- 	local monsterRef = gModelHero:GetMonsterAttrByRefId(heroRefId)
	-- 	if monsterRef then
	-- 		heroRefId = monsterRef.heroId
	-- 	end
	-- end
	return heroRefId
end

---关闭阻断----------------------------------------------------------------------
function UIringFightResult:OnClickClose()
	--if not self._canWndClose then return end
	self:WndClose()
end

function UIringFightResult:RefreshWarTemple()
	CS.ShowObject(self.mWarTemple, self._combatType == LCombatTypeConst.COMBAT_WAR_TEMPLE)
	if self._combatType ~= LCombatTypeConst.COMBAT_WAR_TEMPLE then
		return
	end

	local params = JSON.decode(self._combatResult.params)
	local afterPalaceRank = tonumber(params.afterPalaceRank)
	local afterPalace = tonumber(params.afterPalace)
	local beforePalace = tonumber(params.beforePalace)
	local beforeMaxRank = tonumber(params.beforeMaxRank)
	local beforePalaceRank = tonumber(params.beforePalaceRank)
	local afterMaxRank = tonumber(params.afterMaxRank)

	local itemListBefore = gModelWarTemple:GetDailyRewardItem(beforePalace, beforePalaceRank)
	local itemListAfter = gModelWarTemple:GetDailyRewardItem(afterPalace, afterPalaceRank)

	if afterPalaceRank == 0 then
		CS.ShowObject(self["mWarTempleItemIcon" .. 1], false)
		CS.ShowObject(self["mTxtWarTempleItemNum" .. 1], false)
		CS.ShowObject(self["mWarTempleItemIcon" .. 2], false)
		CS.ShowObject(self["mTxtWarTempleItemNum" .. 2], false)
		self:SetWndText(self.mTxtWarTempleTips1, ccClientText(42067))
	else
		if #itemListBefore ~= #itemListAfter then
			if #itemListBefore == 1 and itemListBefore[1].refId == itemListAfter[2].refId then
				itemListAfter[1], itemListAfter[2] = itemListAfter[2], itemListAfter[1]
			elseif #itemListBefore == 2 and itemListBefore[2].refId == itemListAfter[1].refId then
				itemListBefore[1], itemListBefore[2] = itemListBefore[2], itemListBefore[1]
			end
		end

		for i = 1, 2 do
			local data = itemListBefore[i]
			local data2 = itemListAfter[i]

			if data and data2 == nil then
				data2 = table.clone(data)
				data2.count = 0
				data2.itemNum = 0
			elseif data2 and data == nil then
				data = table.clone(data2)
				data.count = 0
				data.itemNum = 0
			end

			if data and data2 then
				self:CreateCommonIconImpl(self["mWarTempleItemIcon" .. i], data, { showNum = false, showBg = false })
				local change = data2.count - data.count
				if change > 0 then
					self:SetTextTile(self["mWarTempleItemUp" .. i], "+" .. change)
				elseif change < 0 then
					self:SetTextTile(self["mWarTempleItemDown" .. i], change)
				end
				self:SetWndText(self["mTxtWarTempleItemNum" .. i], data2.count)

				CS.ShowObject(self["mWarTempleItemUp" .. i], change > 0)
				CS.ShowObject(self["mWarTempleItemDown" .. i], change < 0)

				CS.ShowObject(self["mWarTempleItemIcon" .. i], true)
				CS.ShowObject(self["mTxtWarTempleItemNum" .. i], true)
			else
				CS.ShowObject(self["mWarTempleItemIcon" .. i], false)
				CS.ShowObject(self["mTxtWarTempleItemNum" .. i], false)
			end
		end

		self:SetWndText(self.mTxtWarTempleTips1, ccClientText(42063))
	end

	self:SetWndText(self.mTxtWarTempleTips2, ccClientText(25266))

	local changeMaxRank = 0
	if beforeMaxRank == 0 then
		if afterMaxRank > 0 then
			changeMaxRank = gModelWarTemple:GetZeroRank() - afterMaxRank
		end
	else
		changeMaxRank = beforeMaxRank - afterMaxRank
	end
	if changeMaxRank > 0 then
		self:SetTextTile(self.mWarTempleRankUp, "+" .. changeMaxRank)
	elseif changeMaxRank < 0 then
		self:SetTextTile(self.mWarTempleRankDown, changeMaxRank)
	end
	CS.ShowObject(self.mWarTempleRankUp, changeMaxRank > 0)
	CS.ShowObject(self.mWarTempleRankDown, changeMaxRank < 0)


	self:SetWndText(self.mAwardText, ccClientText(42072, changeMaxRank))
	CS.ShowObject(self.mWarTempleTotalUp, changeMaxRank > 0)

	-- CS.ShowObject(self.mTxtWarTempleTips2, changeMaxRank ~= 0)
	local _, _, name = gModelWarTemple:GetNpcIdByRank(afterMaxRank)
	self:SetWndText(self.mTxtWarTempleRank, name .. string.replace(ccClientText(25112), afterPalaceRank))

	local battleRet = self._combatResult
	local playerId = battleRet.attack.playerId
	local itemdata = gModelPlayer:GetPlayerId() == playerId and battleRet.attack or battleRet.defense

	local playerInfo = {
		trans = CS.FindTrans(self.mWarTemple, "HeadIcon"),
		icon = itemdata.head or itemdata:GetHead(),
		headFrame = itemdata.headFrame or itemdata:GetHeadFrame(),
		name = itemdata.name or nameStr,
		level = itemdata.grade or itemdata:GetGrade(),
	}

	if self._combatType == LCombatTypeConst.COMBAT_WAR_TEMPLE and itemdata.playerId == 0 then
		playerInfo.level = nil
	end
	local headClass = HeadIcon:New(self)
	headClass:SetHeadData(playerInfo)
	headClass:RefreshUI()

	self:SetWndText(CS.FindTrans(self.mWarTemple, "Name"), itemdata.name)
end

function UIringFightResult:OnCrossGradingBackPlay()
	self._isPlayBack = true
	local combatResult = self._combatResult
	--gModelCrossGrading:GoToBattleFunc(self._combatResult,1,{
	--	battleEndfun = function()
	--		local wndPara = {
	--			combatResult = combatResult,
	--			wndName = "UIringFightResult"
	--		}
	--		gModelBattle:OpenCommonResult(wndPara)
	--	end
	--})

	gModelBattle:ContinueBattlePlayBack(combatResult)

	self:WndClose()
end

function UIringFightResult:StopCrossGradingRankBarTween()
	local seq = self._bloodTweem
	if seq then
		seq:Kill(false)
		self._bloodTweem = nil
	end
end

function UIringFightResult:SetMvpHero()
	local hero = self._combatResult.heroMvp
	local form = hero.form
	-- if self._combatType == LCombatTypeConst.COMBAT_ARENA_ATTACK and
	-- self._combatType == LCombatTypeConst.COMBAT_TYPE_33 then
	-- 	form = form and form.form
	-- end

	local heroRefId = self:GetHeroRefId(hero)
	local heroEffectId
	if hero.skin and hero.skin > 0 then --英雄皮肤
		heroEffectId = hero.skin
	else
		local heroRef = gModelHero:GetHeroRef(heroRefId)
		if not heroRef then
			printErrorN("英雄不存在 refId" .. tostring(heroRefId))
			return
		end
		--local starId = LUtil.GetStarId(heroRef.starType, hero.star)
		local starRef = gModelHero:GetHeroStarRef(heroRefId, form, hero.star)
		heroEffectId = starRef.effectId
	end



	local showEffect = gModelHero:GetShowEffectById(heroEffectId)
	if not showEffect then
		return
	end

	if PRODUCT_G_VER ~= 0 then
		return -- 提审屏蔽mvp
	end

	-- local refId = showEffect.heroType
	-- gModelHero:PlayHeroRoleSound(refId, heroEffectId)
	local loveLevel = gModelHero:GetHeroLoveLvByRefId(heroRefId) or 0
	local favorRef = gModelHero:GetHeroSpActionSoundRef().heroWinMVPSound
	if loveLevel >= favorRef.refId and favorRef.SpActionSound ~= "" then
		local sound = GameTable.CharacterEffectRef[heroEffectId > 0 and heroEffectId or heroRefId][favorRef.SpActionSound]
		if sound and sound ~= "" then
			gLGameAudio:PlaySound(sound)
		end
	end

	local paint = showEffect.heroDrawing
	local quotationsText = self._combatResult.winner == 1 and showEffect.descriptionVictory or showEffect
		.descriptionFail

	local scale = 0.95
	local flipx = false
	local x, y = gModelHeroBook:GetHeroPosByRefIdAndType(showEffect.refId, "heroDrawingPos3")
	if x and y then
		self.mHeroDrawing.localPosition = Vector3.New(x, y, 0)
	end

	--local pos3Flip = showEffect.pos3Flip
	--if pos3Flip and pos3Flip > 0 then
	--	flipx = pos3Flip == 1
	--end
	local pos3Scale = showEffect.pos3Scale
	if pos3Scale and pos3Scale > 0 then
		scale = pos3Scale
	end

	CS.ShowObject(self.mHeroDrawing, true)
	self:CreateWndSpine(self.mHeroSpine2, paint, paint, false, function(dpSpine)
		dpSpine:SetScale(scale)
		dpSpine:SetFlipX(flipx)
	end)

	local res1 = showEffect.skinSpineBg
	local res3 = showEffect.skinSpineHd
	if res1 ~= "" then
		self:CreateWndSpine(self.mHeroSpine1, res1, res1, false, function(dpSpine)
			dpSpine:SetScale(scale)
			dpSpine:SetFlipX(flipx)
		end)
	end

	if res3 ~= "" then
		self:CreateWndSpine(self.mHeroSpine3, res3, res3, false, function(dpSpine)
			dpSpine:SetScale(scale)
			dpSpine:SetFlipX(flipx)
		end)
	end

	-- mvp英雄语录
	if gModelBattle:ShowBattleInfoState() then
		self:TimerStart(self._heroQuotations, 1, false, 1)
	end

	self:SetWndText(self.mQuotationsText, ccLngText(quotationsText))
end

function UIringFightResult:GetNewProgress(selfData, changeScore)
	if not selfData then return end

	local tween = self._bloodTweem

	local curScore = selfData:GetScore()
	local curRank = selfData:GetRank()

	local rank = gModelCrossGrading:GetRank()
	local score = gModelCrossGrading:GetScore()

	local showRankDiv = false
	local curCrossGradingRef = gModelCrossGrading:GetCurCrossGradingIntervalRef(curScore, curRank)
	local crossGradingRef = gModelCrossGrading:GetCurCrossGradingIntervalRef(score, rank)
	if crossGradingRef and curCrossGradingRef then
		local curRefId = curCrossGradingRef.refId
		local refId = crossGradingRef.refId

		local curScoreDown = curCrossGradingRef.scoreDown
		local curScoreUp = curCrossGradingRef.scoreUp
		local isCurMaxRank = curScoreUp == ModelCrossGrading.SCOREUP_MAX

		local scoreDown = crossGradingRef.scoreDown
		local scoreUp = crossGradingRef.scoreUp
		local isMaxRank = scoreUp == ModelCrossGrading.SCOREUP_MAX

		local notSameRank = curRefId ~= refId

		local curPregressNum = curScore - curScoreDown
		local pregressNum = curScoreUp - curScoreDown
		local curPregress = curPregressNum / pregressNum
		if isCurMaxRank then
			curPregressNum = curScore
			pregressNum = curScoreDown
			curPregress = 1
		end

		local curNum = score - scoreDown
		local maxNum = scoreUp - scoreDown
		local percent = curNum / maxNum
		if isMaxRank then
			curNum = score
			maxNum = scoreDown
			percent = 1
		end
		--LxUiHelper.SetProgress(self.mCrossGradingBar,percent)

		local image = self.mCrossGradingBar
		local key = image:GetInstanceID()
		local progress = self:UIProgressFind(image, key, 0)



		if notSameRank then
			local curShowNum, curToNum, newShowNum, newToNum
			local curTextNum = curScore
			local curToTextNum = isCurMaxRank and curScoreDown or curScoreUp
			local newToTextNum = score
			local newTextNum

			local curEndNum = isCurMaxRank and curScoreDown or curScoreUp
			local newEndNum = isMaxRank and scoreDown or scoreUp

			local isUpRank = score > curScore
			if isUpRank then
				curShowNum, curToNum, newShowNum, newToNum = curPregress, 1, 0, percent
				--curTextNum,curToTextNum,newTextNum,newToTextNum = curPregressNum,pregressNum,0,curNum

				newTextNum = scoreDown
			else
				curShowNum, curToNum, newShowNum, newToNum = curPregress, 0, 1, percent
				--curTextNum,curToTextNum,newTextNum,newToTextNum = curPregressNum,0,pregressNum,curNum

				newTextNum = scoreUp
			end
			printInfoNR("=== curShowNum,curToNum,newShowNum,newToNum = ", curShowNum, curToNum, newShowNum, newToNum)

			tween:Append(YXTween.TweenFloat(curShowNum, curToNum, self._speed, function(t)
				progress:SetUIProgress(t)
			end))
			tween:Join(YXTween.TweenInt(curTextNum, curToTextNum, self._speed, function(t)
				self:SetWndText(self.mCrossGradingNum, string.format("%s/%s", t, curEndNum))
			end))

			tween:Append(YXTween.TweenFloat(newShowNum, newToNum, self._speed, function(t)
				progress:SetUIProgress(t)
			end))
			tween:Join(YXTween.TweenInt(newTextNum, newToTextNum, self._speed, function(t)
				self:SetWndText(self.mCrossGradingNum, string.format("%s/%s", t, newEndNum))
			end))


			self:TweenSeq_FadeInStaysAway("xiaoshi", self.mCrossGradingRankIcon, {
				showTime = 0,
				waitTime = 0.1,
				noShowTime = 0.5,
				runFunc = function()
					if not self:IsWndValid() then return end
					CS.ShowObject(self.mCrossGradingRankIcon, true)
					self:SetWndEasyImage(self.mCrossGradingRankIcon, curCrossGradingRef.icon, nil, true)
				end,
				completeFunc = function()
					if not self:IsWndValid() then return end

					CS.ShowObject(self.mCrossGradingRankIcon, false)
					self:SetWndEasyImage(self.mCrossGradingRankIcon, crossGradingRef.icon, nil, true)

					self:TweenSeq_FadeInStaysAway("chuxian", self.mCrossGradingRankIcon, {
						toAlpha = 0,
						fromAlpha = 1,
						showTime = 0,
						waitTime = 0.1,
						noShowTime = 0.5,
						runFunc = function()
							if not self:IsWndValid() then return end

							CS.ShowObject(self.mCrossGradingRankIcon, true)
						end
					})
				end
			})
		else
			local gotoNum = isMaxRank and scoreDown or scoreUp
			tween:Append(YXTween.TweenFloat(curPregress, percent, self._speed, function(t)
				progress:SetUIProgress(t)
			end))

			tween:Join(YXTween.TweenInt(curScore, score, self._speed, function(t)
				self:SetWndText(self.mCrossGradingNum, string.format("%s/%s", t, gotoNum))
			end))

			self:SetWndEasyImage(self.mCrossGradingRankIcon, crossGradingRef.icon, nil, true)
		end


		local iconEffect = crossGradingRef.iconEffect
		if not string.isempty(iconEffect) then
			tween:AppendCallback(function()
				self:CreateWndEffect(self.mCrossGradingRankEff, iconEffect, iconEffect, 100, false, false)
			end)
		end

		showRankDiv = true
	end
	CS.ShowObject(self.mCrossGradingRankDiv, showRankDiv)

	local showQuotation = not showRankDiv
	if gModelBattle:ShowBattleInfoState() then
		showQuotation = not showRankDiv
	else
		showQuotation = false
	end
	CS.ShowObject(self.mHeroQuotations, showQuotation)

	CS.ShowObject(self.mMvpNameBg, not showRankDiv)
	CS.ShowObject(self.mMvpOutputBg, not showRankDiv)
	CS.ShowObject(self.mMvpBearBg, not showRankDiv)
	CS.ShowObject(self.mMvpCureBg, not showRankDiv)
end

function UIringFightResult:InitServerData()
	local battleRet = self:GetWndArg("combatResult")
	self._combatResult = battleRet

	local combatType = battleRet.combatType
	self._combatType = combatType
end

function UIringFightResult:ExecuteBackPress()
	self:OnClickOk()
end

function UIringFightResult:InitCrossGradingRankBar()
	self:StopCrossGradingRankBarTween()

	local tween = DG.Tweening.DOTween.Sequence()
	self._bloodTweem = tween
end

function UIringFightResult:IsCrossGradingType()
	return self._combatType == LCombatTypeConst.COMBAT_CROSSGRADING_RANK
end

function UIringFightResult:RefreshUI()
	local battleRet = self._combatResult
	self._isFromBack = self:GetWndArg("isFromBack")
	self._battleInfo = self:GetWndArg("battleInfo")
	--self._isOutLine= battleRet.isOutLine == 1

	local isCrossGradingType = self:IsCrossGradingType()
	-- local isCombatType33 = self:IsCombatType33()
	local isOtherCombatType = not isCrossGradingType
	if isOtherCombatType then
		gModelBattle:OnCombatResultSureReq(battleRet.combatType, battleRet.reportId)
	end

	local playerID = gModelPlayer:GetPlayerId()
	local selfData = nil
	local otherData = nil
	local playerId = battleRet.attack.playerId
	if not playerId and isCrossGradingType then
		playerId = battleRet.attack:GetPlayerId()
	end
	local selfIsAttack = playerID == playerId
	local result = nil
	if selfIsAttack then
		selfData = battleRet.attack
		otherData = battleRet.defense
		result = battleRet.winner == 1
	else
		selfData = battleRet.defense
		otherData = battleRet.attack
		result = battleRet.winner == 2
	end

	if self._combatType == LCombatTypeConst.COMBAT_WAR_TEMPLE then
		selfData = battleRet.attack
		otherData = battleRet.defense

		local params = JSON.decode(self._combatResult.params)
		local npcId = tonumber(params.npcId) or 0

		local afterDefAllRank = tonumber(params.afterDefAllRank) or 0
		local beforeDefAllRank = tonumber(params.beforeDefAllRank) or 0
		local afterAtkAllRank = tonumber(params.afterAtkAllRank) or 0
		local beforeAtkAllRank = tonumber(params.beforeAtkAllRank) or 0

		if beforeAtkAllRank == 0 then
			if afterAtkAllRank == 0 then
				selfData.score = afterAtkAllRank
				selfData.change = 0
			else
				selfData.score = gModelWarTemple:GetZeroRank()
				selfData.change = selfData.score - afterAtkAllRank
			end
		else
			selfData.score = afterAtkAllRank
			selfData.change = beforeAtkAllRank - afterAtkAllRank
		end


		if npcId > 0 then
			local heroRefId, name = gModelWarTemple:GetShowHeroRefId(npcId)
			local head = gModelWarTemple:GetHeroHeadByRefId(heroRefId)
			otherData.head = head
			otherData.name = name
			otherData.change = 0
			otherData.playerId = 0


			otherData.score = afterDefAllRank
			otherData.change = 0
		else
			if afterDefAllRank == 0 then
				afterDefAllRank = gModelWarTemple:GetZeroRank()
			end

			otherData.score = afterDefAllRank
			otherData.change = beforeDefAllRank - afterDefAllRank
		end
	end

	if self._combatType == LCombatTypeConst.COMBAT_CROSS_WAR then
		selfData = battleRet.attack
		otherData = battleRet.defense

		local params = JSON.decode(self._combatResult.params)
		local npcId = tonumber(params.npcId) or 0

		local afterDefRank = tonumber(params.afterDefRank) or 0
		local beforeDefRank = tonumber(params.beforeDefRank) or 0
		local afterAtkRank = tonumber(params.afterAtkRank) or 0
		local beforeAtkRank = tonumber(params.beforeAtkRank) or 0

		-- if beforeAtkAllRank == 0 then
		-- 	if afterAtkAllRank == 0 then
		-- 		selfData.score = afterAtkAllRank
		-- 		selfData.change = 0
		-- 	else
		-- 		selfData.score = gModelWarTemple:GetZeroRank()
		-- 		selfData.change = selfData.score - afterAtkAllRank
		-- 	end
		-- else
		-- 	selfData.score = afterAtkAllRank
		-- 	selfData.change = beforeAtkAllRank - afterAtkAllRank
		-- end
		selfData.score = 0
		selfData.rank = afterAtkRank
		if beforeAtkRank == -1 then
			selfData.change = 0
			if afterAtkRank > 0 then
				selfData.score = 1
			end
		else
			selfData.change = beforeAtkRank - afterAtkRank
		end



		if npcId > 0 then
			local monsterCfg = gModelHero:GetMonsterFormationRefByRefId(npcId)
			local monsterShow = ModelCrossWar:GetMonsterShowByMonsterId(npcId)
			local head = gModelWarTemple:GetHeroHeadByRefId(monsterShow)
			otherData.head = head
			otherData.name = ccLngText(monsterCfg.name)
			otherData.change = 0
			otherData.playerId = 0


			-- otherData.score = afterDefAllRank
			-- otherData.change = 0
		else
			-- if afterDefAllRank == 0 then
			-- 	afterDefAllRank = gModelWarTemple:GetZeroRank()
			-- end

			-- otherData.score = afterDefAllRank
			afterDefRank = afterDefRank == -1 and 31 or afterDefRank
			otherData.change = beforeDefRank - afterDefRank
		end
	end

	if gModelBattle:ShowBattleInfoState() then
		if battleRet and isOtherCombatType then
			CS.ShowObject(self.mMvpMar, true)

			self:SetWndText(self.mMvpNameText1, ccClientText(10163))
			CS.ShowObject(self.mMvpNameBg, true)

			self:SetWndText(self.mMvpOutputText1, ccClientText(10164))
			CS.ShowObject(self.mMvpOutputBg, true)

			self:SetWndText(self.mMvpBearText1, ccClientText(10165))
			CS.ShowObject(self.mMvpBearBg, true)

			self:SetWndText(self.mMvpCureText1, ccClientText(10166))
			CS.ShowObject(self.mMvpCureBg, true)

			local hero = battleRet.heroMvp
			local heroRefId = self:GetHeroRefId(hero)
			local heroStar = hero.star
			local heroName = gModelHero:GetHeroNameByRefId(heroRefId, heroStar)
			local color = gModelHero:GetHeroNameColorByRefId(heroRefId, heroStar)
			--self:SetWndText(self.mMvpNameText2,LUtil.FormatColorStr(heroName,"#"..color))
			self:SetWndText(self.mMvpNameText2, heroName)
			self:SetWndText(self.mMvpOutputText2, LUtil.NumberCoversion(tonumber(battleRet.output)))
			self:SetWndText(self.mMvpBearText2, LUtil.NumberCoversion(tonumber(battleRet.bear)))
			self:SetWndText(self.mMvpCureText2, LUtil.NumberCoversion(tonumber(battleRet.cure)))
			self:SetWndText(self.mMvpKillText, LUtil.FormatHurtNumSpriteText(battleRet.kill))
			CS.ShowObject(self.mMvpKillBg, battleRet.kill > 0)
		elseif isCrossGradingType then
			CS.ShowObject(self.mMvpMar, true)

			local killNum = battleRet.kill
			self:SetWndText(self.mMvpKillText, LUtil.FormatHurtNumSpriteText(killNum))

			CS.ShowObject(self.mMvpKillBg, killNum > 0)
			local changeScore = selfIsAttack and battleRet.scoreA or battleRet.scoreB
			--self:GetProgress(selfData,changeScore)
			self:GetNewProgress(selfData, changeScore)
		end
	else
		CS.ShowObject(self.mMvpMar, false)
	end

	if result then
		-- 成功音效
		LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_FIGHT_WIN)
	else
		LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_FIGHT_FAIL)
	end

	CS.ShowObject(self.mWinBg, true)
	local effName = "fx_ui_shengli"
	local imgName = "settlement_bg_title_3"

	local trans   = self.mTitle
	if not result then
		effName = "fx_ui_shibai"
		imgName = "settlement_bg_title_4"
	end

	self:SetWndEasyImage(self.mWinBg, imgName)
	self:CreateWndEffect(trans, effName, effName, 100, false, false)


	local rankChange = 0
	if isOtherCombatType then
		if selfData.oldRank > 0 then
			rankChange = selfData.oldRank - selfData.rank
		end
	elseif isCrossGradingType then
		rankChange = battleRet.scoreA
	end

	if isOtherCombatType then
		-- if isCombatType33 then
		-- 	local refId = self:GetWndArg("refId")
		-- 	if refId then
		-- 		local wndData = GameTable.UIWindowAttRef[refId]
		-- 		if not wndData then
		-- 			if LOG_INFO_ENABLED then
		-- 				LogError("默认窗口类型为10001，没有配置该窗口的类型的数据:"..refId)
		-- 			end
		-- 		else
		-- 			local first = self:FindWndTrans(self.mRankInfo,"first")
		-- 			local text = ccLngText(wndData.text)
		-- 			self:SetWndText(first,text)
		-- 		end
		-- 	end
		-- else
		self:SetChangeContent(self.mRankInfo, ccClientText(17007), selfData.rank, rankChange)
		-- end
	end

	local isSpecial = isOtherCombatType and (not false)

	if isSpecial and rankChange ~= 0 then
		local tweenData = {}
		tweenData.tran = self.mRankInfo
		tweenData.cur = selfData.rank
		tweenData.startNum = 0
		tweenData.endNum = rankChange
		tweenData.duration = 1
		tweenData.format = ccClientText(17007)
		table.insert(self._tweenDataList, tweenData)
	end



	self:SetPlayer(self.mSelf, selfData, true)
	self:SetPlayer(self.mOther, otherData)

	local meName = selfData.name
	if not meName then
		meName = selfData:GetName()
	end
	self.meName = meName

	local otherName = otherData.name
	if not otherName then
		otherName = otherData:GetName()
	end
	self.otherName = otherName


	self:ShowRewards(battleRet.itemList)

	self:StartTween()
end

function UIringFightResult:OpenCrossGradingDetail()
	local combatResult = self._combatResult
	local extraData = {}
	extraData.meName = self.meName
	extraData.otherName = self.otherName
	extraData.combatType = LCombatTypeConst.COMBAT_CROSSGRADING_RANK
	extraData.reportId = combatResult.reportIdList
	extraData.serverId = combatResult.serverId
	extraData.reportUrl = combatResult.reportUrl
	--extraData.combatResult = combatResult
	extraData.winnerNumber = combatResult.winnerNumber

	gLFightManager:ShowCrossGradingBattleDetail(extraData)
end

-- function UIringFightResult:IsCombatType33()
-- 	return self._combatType == LCombatTypeConst.COMBAT_TYPE_33
-- end

function UIringFightResult:SetStaticContent()
	local battleRet = self._combatResult

	local isCrossGradingType = self:IsCrossGradingType()
	-- local isCombatType33 = self:IsCombatType33()

	local otherCombatType = not isCrossGradingType
	--CS.ShowObject(self.mTitleBg1, otherCombatType)

	local showTitleBg2 = otherCombatType
	-- if isCombatType33 then
	-- 	showTitleBg2 = false
	-- end
	CS.ShowObject(self.mTitleBg2, showTitleBg2)

	CS.ShowObject(self.mVsIcon, otherCombatType)
	CS.ShowObject(self.mCrossGradingVSIcon, isCrossGradingType)

	local text = self:FindWndTrans(self.mStatistics, "text")
	self:SetWndText(text, ccClientText(37567))
	self:SetWndText(self.mBackPlayText, ccClientText(17001)) -- 回放

	self:SetWndButtonText(self.mBackArenaBtn, ccClientText(10320))
	self:SetWndButtonText(self.mOkBtn, ccClientText(10321))

	if isCrossGradingType then
		--local str = string.replace(ccClientText(21831), ccClientText(21800))
		--self:SetWndText(self.mCrossGradingName, str)
		local winnerNumA = battleRet.winnerNumA
		local winnerNumB = battleRet.winnerNumB
		local scoreStr = string.replace(ccClientText(21829), winnerNumA, winnerNumB)
		self:SetWndText(self.mCrossGradingScore, scoreStr)


		self:SetWndText(self.mCrossGradingName, scoreStr .. "     ")

		CS.ShowObject(self.mCrossGradingName, true)
		CS.ShowObject(self.mCrossGradingScore, false)
		-- elseif isCombatType33 then
		-- 	local refId = self:GetWndArg("refId")
		-- 	if refId then
		-- 		local wndData = GameTable.UIWindowAttRef[refId]
		-- 		if not wndData then
		-- 			if LOG_INFO_ENABLED then
		-- 				LogError("默认窗口类型为10001，没有配置该窗口的类型的数据:"..refId)
		-- 			end
		-- 		else
		-- 			local btnList = {
		-- 				self.mOkBtn,self.mBackArenaBtn
		-- 			}
		-- 			local btnTxt = string.split(ccLngText(wndData.btnTxt),"|")
		-- 			local btnPng = string.split(wndData.btnPng,"|")
		-- 			local btnName,btnImg
		-- 			for i,v in ipairs(btnList) do
		-- 				btnName,btnImg = btnTxt[i],btnPng[i]
		-- 				if btnName then
		-- 					self:SetWndButtonText(v,btnName)
		-- 				end
		-- 				if btnImg then
		-- 					local mat = LUtil.GetOutlineMatByImg(btnImg)
		-- 					self:SetWndButtonTextMat(v,mat)
		-- 					self:SetWndButtonImg(v,btnImg)
		-- 				end
		-- 			end
		-- 		end
		-- 	end
		self:SetWndText(self.mDungeonText,
			ccLngText(GameTable.BattleGameRef[LCombatTypeConst.COMBAT_CROSSGRADING_RANK].name))                          -- 副本名字
	else
		self:SetWndText(self.mDungeonText, ccLngText(GameTable.BattleGameRef[self._combatType].name))                    -- 副本名字
		--text = self:FindWndTrans(self.mBackArenaBtn,"text")
		--self:SetWndText(text,ccClientText(10320))
		self:SetWndText(self.mAwardText, ccClientText(10721))
	end

	CS.ShowObject(self.mArena, self._combatType ~= LCombatTypeConst.COMBAT_WAR_TEMPLE)
	CS.ShowObject(self.mImg0, self._combatType ~= LCombatTypeConst.COMBAT_WAR_TEMPLE)
	self:RefreshWarTemple()
end

function UIringFightResult:SetChangeContent(tran, format, cur, change, isRight)
	local item = tran
	local first = self:FindWndTrans(item, "first")
	local arrow = self:FindWndTrans(item, "arrow")
	local last = self:FindWndTrans(item, "last")
	CS.ShowObject(first, true)

	if change == 0 then
		local rankStr = tostring(cur)
		if cur <= 0 then
			rankStr = ccClientText(10363)
			if self._combatType == LCombatTypeConst.COMBAT_CROSS_WAR then
				rankStr = ccClientText(10333)
			end
		end
		if cur == 1 and self._combatType == LCombatTypeConst.COMBAT_CROSS_WAR then
			rankStr = ccClientText(43856)
		end
		local str = string.replace(format, rankStr)
		if self._combatType == LCombatTypeConst.COMBAT_CROSS_WAR then
			if isRight then
				str = ""
			end
		end
		self:SetWndText(first, str)
		CS.ShowObject(arrow, false)
		CS.ShowObject(last, false)
	elseif change ~= 0 then
		local changeStr = tostring(math.abs(math.floor(change)))
		local color = change > 0 and "lightGreen" or "lightRed"
		local str = nil
		local behind = LUtil.FormatColorStr(changeStr .. ")", color)
		local front = LUtil.FormatColorStr("(", color)
		local main = string.replace(format, cur)
		if isRight then
			str = front
		else
			str = main .. front
		end
		if self._combatType == LCombatTypeConst.COMBAT_CROSS_WAR then
			str = ""
		end
		self:SetWndText(first, str)
		CS.ShowObject(arrow, true)
		if isRight then
			str = behind .. main
		else
			str = behind
		end
		if self._combatType == LCombatTypeConst.COMBAT_CROSS_WAR then
			str = tostring(math.abs(math.floor(change)))
		end
		self:SetWndText(last, str)
		CS.ShowObject(last, true)
		local path = change > 0 and self._scoreStateIcon[1] or self._scoreStateIcon[2]
		self:SetWndEasyImage(arrow, path)
	end
end

function UIringFightResult:OpenBattleDetails(extraData)
	extraData = extraData or {}
	extraData.meName = extraData.meName or self.meName
	extraData.otherName = extraData.otherName or self.otherName
	extraData.combatType = extraData.combatType or self._combatType
	local reportId = extraData.reportId or self._combatResult.reportId
	gLFightManager:OnOpenBattleDetails(reportId, extraData, nil, true)
end

function UIringFightResult:BackArena()
	self._isClickRet = true
	local returnFunc = gModelBattle:GetReturnFun(self._combatType)
	if returnFunc then
		returnFunc()
	end
end

function UIringFightResult:InitList()
	self._scoreStateIcon =
	{
		"public_arrow_3",
		"actionarena_ui_arrow_1",
	}


	self._optTrans = {
		self.mOpt_1,
		self.mOpt_2,
		self.mOpt_3,
	}

	--self._optTexts=
	--{
	--	"强化装备",
	--	"调整阵容",
	--	"提升等级"
	--}

	self._tweenDataList = {}
	self._seqList = {}

	self:InitCrossGradingRankBar()
end

function UIringFightResult:BackCrossGrading()
	self._isClickRet = true
	local returnFunc = gModelBattle:GetReturnFun(LCombatTypeConst.COMBAT_CROSSGRADING_RANK)
	if returnFunc then
		returnFunc()
	end
end

function UIringFightResult:OnBackPlay()
	self._isPlayBack = true
	local reportId = self._combatResult.reportId
	local combatType = self._combatType

	local combatResult = self._combatResult
	local battleData =
	{
		meName = self.meName,
		otherName = self.otherName,
		combatType = combatType,
		reportId = reportId,
		battleEndfun = function(changeBot)
			gModelBattle:ShowAccountByCombatResult(combatResult, changeBot)
		end
	}

	gModelBattle:BattlePlayBack(battleData, true)
end

function UIringFightResult:StartTween()
	for k, v in pairs(self._tweenDataList) do
		local seq = self:TweenNum(v)
		table.insert(self._seqList, seq)
	end


	local tween = self._bloodTweem
	if tween then tween:Play() end
end

function UIringFightResult:OnTimer(key)
	if key == self._heroQuotations then
		--爵位赛控件和宣言部分互斥
		if not self.mCrossGradingRankDiv.gameObject.activeSelf then
			CS.ShowObject(self.mHeroQuotations, true)
		end
	end
end

------------------------------------------------------------------
return UIringFightResult