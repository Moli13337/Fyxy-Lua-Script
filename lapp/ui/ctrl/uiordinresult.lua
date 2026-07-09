---
--- Created by BY.
--- DateTime: 2023/10/14 16:34:59
---
------------------------------------------------------------------
local LWnd = LWnd

local Tweening = DG.Tweening
local EaseOutCubic = Tweening.Ease.OutCubic

--local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)

---@class UIOrdinResult:LWnd
local UIOrdinResult = LxWndClass("UIOrdinResult", LWnd)

UIOrdinResult.NORMAl = 1
UIOrdinResult.GUILD_SWEEP = 2
UIOrdinResult.TOWER_ESCAPE = 3            --试炼之藤逃跑
UIOrdinResult.INVASION_SWEEP = 4

UIOrdinResult.TYPE_BATTLE = 1                -- 通用战斗结算
-- UIOrdinResult.TYPE_MINGAME = 2			-- 小游戏结算
UIOrdinResult.TYPE_MATCH = 3            -- 宠物三消
UIOrdinResult.TYPE_GM = 4                -- GM


-- UIOrdinResult.MINGAME_TYPE_SUCCESS = 2
-- UIOrdinResult.MINGAME_TYPE_FAIL = 3
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOrdinResult:UIOrdinResult()
    ---@type UIIconEasyList
    self._uiRewardList = nil

    ---@type UIIconEasyList
    self._uiMinRewardList = nil

    self._countDownKey = "_resultCountDownKey"
    self._heroQuotations = "_heroQuotations"

    FireEvent(EventNames.ON_CHAT_SHOW, false)
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOrdinResult:OnWndClose()
    FireEvent(EventNames.ON_CHAT_SHOW, true)

    if LOG_INFO_ENABLED then
        print("UIOrdinResult:OnWndClose()")
    end
    if self._uiRewardList then
        self._uiRewardList:Destroy()
        self._uiRewardList = nil
    end

    if self._uiMinRewardList then
        self._uiMinRewardList:Destroy()
        self._uiMinRewardList = nil
    end
    if self._delayTimer then
        LxTimer.DelayTimeStop(self._delayTimer)
        self._delayTimer = nil
    end

    self:StopPlayerTween()
    gLGameAudio:StopSingleSound()
    gLGameAudio:StopSound()
    self:StopHeroTween()
    local isVideoAlive = gModelBattle:IsVideoAlive()
    --if not isVideoAlive then
    --	local reportId = self._combatResult and self._combatResult.reportId
    --	gModelBattle:ClearCacheReportByKey({reportId = reportId})
    --end

    local combatType = self._combatType

    local isFromBack = self._isFromBack --or self._isOutLine

    local needSend = not self._isClickRet and not isFromBack and not self._isToNextBattle and not isVideoAlive

    if combatType == LCombatTypeConst.COMBAT_MAIN then
        local battleNode = self._combatResult.battleNode
        local isStoryInstance = gModelPlot:IsStoryInstance(battleNode)
        if isStoryInstance then
            needSend = false
        end
    elseif combatType == LCombatTypeConst.COMBAT_DREAMTRIP then
        local wndIns = GF.FindFirstWndByName("UIHope")
        if wndIns then
            gModelFastDreamTrip:CheckIsEndPointFinish()
            gModelFastDreamTrip:CheckIsSaveRollCb()
        end
    end
    if needSend then
        FireEvent(EventNames.ON_EXIT_ACCOUNT_WND, combatType, self._combatResult) --主要进行地图切换和回到对应系统
    end

    local wndName = self:GetWndName()
    FireEvent(EventNames.ON_ACCOUNT_RELA_WND_CLOSE, wndName, combatType)

    gModelBattle:RecordExitByBottomClick(combatType, false)

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOrdinResult:OnCreate()
    LWnd.OnCreate(self)

    --self._canWndClose = false
    --self._cantCloseTimer = nil

    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOrdinResult:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    
    if self._isEnus then 
        self:SetAnchorPos(self.mStarRoot,Vector2.New(-6,2.7))
    end

    self._isVie =gLGameLanguage:IsVieVersion()
    
    if self._isVie then
        self:SetAnchorPos(self.mStarRoot,Vector2.New(-36,2.7))
    end 
    
    self:AddWndAniCallbackList(function()
        self:AniEnd()
    end)

    self:SetStaticContent()

    local openType = self:GetWndArg("openType") or UIOrdinResult.TYPE_BATTLE
    self._openType = openType

    self:RefreshTypeView()

    local showFunc = self:ShowFunctionPrePost()
    CS.ShowObject(self.mFunctionOpen, showFunc)
    local showBadgeStar = false
    if self._openType == UIOrdinResult.TYPE_BATTLE then
        --- 从 ShowTypeBattle() 移出来
        showBadgeStar = self:OnBadgeStar()
    end
    if self._combatType == LCombatTypeConst.COMBAT_TYPE_47 then
        showBadgeStar = true
        self:ShowType47Star()
    end
    CS.ShowObject(self.mObjStar, showBadgeStar)
    local showButton = self:SetButton()
    self.mFunctionOpenCG.alpha = showFunc and 1 or 0
    self.mObjStarCG.alpha = showBadgeStar and 1 or 0
    self.mBottomBtnCG.alpha = showButton and 1 or 0
end

-- 胜利类型窗口2
function UIOrdinResult:ShowTypeWinTwo()
    CS.ShowObject(self.mCommonResult, true)
    CS.ShowObject(self.mFailWnd, false)
    CS.ShowObject(self.mWinWnd, true)
    CS.ShowObject(self.mBattleData, false)
    CS.ShowObject(self.mBackPlay, false)

    CS.ShowObject(self.mPlayerLevel, self._isShowLevel)
    if self._isShowLevel then
        self:InitPlayLevel()
    else
        self:SetText(self.mDescriptionText)
    end

    self:ShowMvpHero(true)
    self:SetDungeonText(self.mDungeonText, self._combatType)
    self:ShowTitleEff(true)
    self:InitScrollView()
end

function UIOrdinResult:BossTowerNextIns()
    -- local _combatResult = self._combatResult
    -- if not _combatResult then return end
    -- local refId = _combatResult.refId
    -- local sid = _combatResult.sid
    -- if not refId then return end
    -- if not sid then return end
    -- if self._isTcpReconnect then
    -- 	local activityData = gModelActivity:GetActivityBySid(sid)
    -- 	if activityData and activityData.status == ModelActivity.STATUS_VALID then
    -- 		GF.OpenWnd("UIActTower",{sid = sid,page = 2})
    -- 	end
    -- 	self:WndClose()
    -- 	return
    -- end
    -- gModelBossTower:BossTowerNextIns(sid,refId,self._isFromBack)
    -- self:WndClose()
end

-- 设置无奖励时显示文本
function UIOrdinResult:SetNoRecordText()
    if not self.mNoRecordText then
        return
    end

    if self._noRecordText then
        self:SetWndText(self.mNoRecordText, self._noRecordText)
    end

    CS.ShowObject(self.mNoRecordText, self._noRecordText ~= nil)
end

function UIOrdinResult:GetBtnByName(name)
    local btn = self:FindWndTrans(self.mBtnPool, name)
    if btn then
        return LxResUtil.NewObject(btn.gameObject)
    end
end
---关闭阻断----------------------------------------------------------------------
function UIOrdinResult:OnClickClose()
    local combatType = self._combatType
    -- if combatType == gModelBossTower:GetBossTowerConfigRefByKey("towerFightType") then
    -- 	local winIns = GF.FindFirstWndByName("UIMultiFightPre")
    -- 	if winIns then
    -- 		GF.CloseWndByName("UIMultiFightPre")
    -- 	end
    -- 	winIns = GF.FindFirstWndByName("UIActTower")
    -- 	if not winIns then
    -- 		local combatResult = self._combatResult or {}
    -- 		local sid = combatResult.sid
    -- 		if sid then
    -- 			GF.OpenWnd("UIActTower",{sid = sid,page = ModelBossTower.TYPE_BTN_ADVENTURE})
    -- 		end
    -- 	end
    if combatType == LCombatTypeConst.COMBAT_ACTIVITY_DREAMTRIP then
        FireEvent(EventNames.ON_DREAMTRIP_SHOWHURT2)
        FireEvent(EventNames.ON_DREAMTRIP_CLEARANISTATUS)
        gModelActivityDreamTrip:CheckSpeedUpCallBackFunc()
        -- 【G公共支持】删除本命英雄功能
        -- elseif combatType == LCombatTypeConst.COMBAT_TYPE_34 then
        -- 	GF.ChangeMap("LCityMap")
        -- 	GF.OpenWnd("UIMCity")
        -- 	GF.OpenWnd("WndNaturalPartner")
    elseif combatType == LCombatTypeConst.COMBAT_MAIN then
        local bNeed = self:IsNeedGotoNextMain()
        self:WndClose()
        if bNeed then
            self:GotoNextMain()
        end
        return
    end
    self:WndClose()

    -- 【C宠物系统】删掉宠物系统相关
    -- if self._openType == UIOrdinResult.TYPE_MATCH then
    -- 	GF.CloseWndByName("WndPetFight")
    -- end
end

function UIOrdinResult:SetStaticContent()
    local emptyList = self:GetCommonEmptyList("_empty")
    local data = {
        refId = 19001,
        IntroTran = self:FindWndTrans(self.mNoRecord, "text"),
    }
    emptyList:RefreshUI(data)

    self:SetWndText(self.mLevelText, ccClientText(17010))
end
-------------------------------------UIListEasy-------------------------------------
function UIOrdinResult:GetShowItemList()
    local wndType = self._accWndType
    local itemList = nil
    local rewardInfo = nil
    if wndType == UIOrdinResult.TOWER_ESCAPE then
        itemList = self._towerData.itemList
        rewardInfo = self._towerData.rewardInfo
    elseif wndType == UIOrdinResult.GUILD_SWEEP then
        itemList = self._guildData.reward
        rewardInfo = self._guildData.rewardInfo
    elseif wndType == UIOrdinResult.NORMAl then
        itemList = self._combatResult.itemList
        rewardInfo = self._combatResult.rewardInfo
    elseif wndType == UIOrdinResult.INVASION_SWEEP then
        itemList = self._invasionData.reward
        rewardInfo = self._invasionData.rewardInfo
    end

    return self:GetShowItemListImpl(itemList, rewardInfo)
end

function UIOrdinResult:SweepGuildBrave()
    if gModelGuildBoss:CanSweep() then
        self:OnClickClose()
    end
    gModelGuildBoss:OnClickSweep()
end

function UIOrdinResult:OnClickShare()
    local _shareRefId = self._shareRefId
    if not _shareRefId then
        return
    end
    local ref = gModelCareSchool:GetCollegeSimulationRefByRefId(_shareRefId)
    if not ref then
        return
    end
    local shareType = ModelChat.CHATSHARE_17
    local battleName = ccLngText(ref.name)
    local shareData = {
        reportId = self._combatResult.reportId,
        serverId = self._serverId or gLGameLogin:GetActualServerId(),
        battleName = battleName,
    }
    if _shareRefId == 3 then
        shareType = ModelChat.CHATSHARE_21
    else
        local _other = self._other
        if not _other or not _other[1] then
            return
        end
        shareType = ModelChat.CHATSHARE_17
        shareData.hurt = _other[1]
    end
    local jsonStr = JSON.encode(shareData)
    local data = {
        root = self.mBtnShare,
        shareType = shareType,
        shareData = jsonStr
    }
    gModelGeneral:OpenShareTip(data)
end

function UIOrdinResult:SetItemList(dataList, isDetail)
    isDetail = isDetail and true or false
    local uiRewardList = self._uiRewardList
    if not uiRewardList then
        uiRewardList = UIIconEasyList:New()
        self._uiRewardList = uiRewardList
        uiRewardList:Create(self, self.mItemList, nil, isDetail)
        uiRewardList:EnableLoadAnimation(true, 0.1, 1)
        uiRewardList:SetIconParentPath("Icon")
        uiRewardList:EnableScroll(true, false)
    end
    uiRewardList:RefreshList(dataList, true)
    uiRewardList:EnableScroll(true, false)
end

------------------------ ShowTypeBattle ------------------------
function UIOrdinResult:ShowTypeBattle()
    self:InitData()
    self:ShowTypeWndByData()
    self:InitEvent()
    self:PlayBattleMusic()
end

function UIOrdinResult:ShowFunctionPrePost()
    if self._combatType ~= LCombatTypeConst.COMBAT_MAIN then
        return false
    end

    local combatResult = self._combatResult

    if combatResult.winner ~= 1 then
        return false
    end

    local battleNode = combatResult.battleNode
    local iRef = gModelInstance:GetMissionCfg(battleNode)
    local num = iRef.num
    local serverDay = gLGameLogin:GetServerOpenDay()
    local list = gModelInstance:GetInstanceFunctionRef()
    local itemList = {}
    for i, v in ipairs(list) do
        if #itemList >= 2 then
            break
        end
        local foRef = gModelFunctionOpen:GetFunctionOpenCfg(v.functionId)
        if foRef then
            local showType = 1
            local battleNum = 0
            local openDay = 0
            if not string.isempty(foRef.open) then
                local open = string.split(foRef.open, ",")
                for j, k in ipairs(open) do
                    local arr = string.split(k, "=")
                    local type = tonumber(arr[1])
                    if type == 2 then
                        battleNum = tonumber(arr[2]) - num
                        showType = 2
                    elseif type == 11 then
                        openDay = tonumber(arr[2]) - serverDay
                    end
                end
            end
            if battleNum > 0 and openDay > 0 then
                showType = 3
            end
            if not string.isempty(foRef.otherOpen) and (battleNum == 0 or openDay == 0) then
                local otherOpen = string.split(foRef.otherOpen, ",")
                for j, k in ipairs(otherOpen) do
                    local arr = string.split(k, "=")
                    local type = tonumber(arr[1])
                    if type == 2 then
                        battleNum = tonumber(arr[2]) - num
                        showType = 2
                    elseif type == 11 then
                        openDay = tonumber(arr[2]) - serverDay
                    end
                end
                showType = 4
            end
            if openDay <= 0 then
                showType = 2
            end
            if battleNum > 0 then
                local data = {
                    name = ccLngText(foRef.name),
                    battleNum = battleNum,
                    openDay = openDay,
                    showType = showType,
                    cfg = v
                }
                table.insert(itemList, data)
            end
        end
    end

    if #itemList == 0 then
        return false
    end

    table.sort(itemList, function(a, b)
        return a.cfg.sort < b.cfg.sort
    end)

    local roolList = {
        self.mFunctionItem1,
        self.mFunctionItem2
    }
    for i, v in ipairs(roolList) do
        CS.ShowObject(v, false)
    end
    for i, v in ipairs(itemList) do
        self:SetFunctionItem(roolList[i], v)
    end
    return true
end

function UIOrdinResult:GetMvpHeroData()
    local wndType = self._accWndType
    local hero = nil
    if wndType == UIOrdinResult.NORMAl then
        local data = self._combatResult.heroMvp
        hero = {
            skin = data.skin,
            refId = data.refId,
            star = data.star,
            isMonster = self._combatResult.isMonsterMVP == 1,
            form = data.form and data.form.form,
        }
    elseif wndType == UIOrdinResult.GUILD_SWEEP then
        local data = self._guildData.hurtMvpId
        hero = {
            skin = data.skin,
            refId = data.refId,
            star = data.star,
            form = data.form and data.form.form,
        }
    elseif wndType == UIOrdinResult.TOWER_ESCAPE then
        local data = self._towerData.mvp
        hero = {
            skin = data.skin,
            refId = data.refId,
            star = data.star,
            form = data.form and data.form.form,
        }
    elseif wndType == UIOrdinResult.INVASION_SWEEP then
        local data = self._invasionData.hurtMvpId
        hero = {
            skin = data.skin,
            refId = data.refId,
            star = data.star,
            form = data.form and data.form.form,
        }
    end
    if hero.refId <= 0 then
        return
    end
    return hero
end

function UIOrdinResult:StopHeroTween()
    local seq = self._heroTweem
    if seq then
        seq:Kill(false)
        self._heroTweem = nil
    end
end

-- 带新纪录类型窗口
function UIOrdinResult:ShowNewRecordType()
    CS.ShowObject(self.mCommonResult, true)
    CS.ShowObject(self.mFailWnd, false)
    CS.ShowObject(self.mWinWnd, true)
    CS.ShowObject(self.mBattleData, true)
    CS.ShowObject(self.mBackPlay, true)
    CS.ShowObject(self.mPlayerLevel, false)
    CS.ShowObject(self.mNewRecordIcon, self._isNewRecord or false)

    self:SetText(self.mDescriptionText)

    self:SetDungeonText(self.mDungeonText, self._combatType)
    self:ShowMvpHero(true)
    self:ShowTitleEff(true)
    --self:CreateWinEffect()
    self:InitScrollView()
    self:SetNoRecordText()
end

function UIOrdinResult:ShowType47Star()
    local battleResult = JSON.decode(self._combatResult.activityData)
    local id = battleResult.battleRefId
    local starInfo = { false, false, false }
    for _, v in ipairs(battleResult.star) do
        starInfo[tonumber(v)] = true
    end
    for i = 1, 3 do
		local star = self["mImgStar" .. i]
		local condText = self["mTxtStar" .. i]

        local isOn = starInfo[i]
        local res = isOn and "weapon1_star1" or "weapon1_star2"
        self:SetWndEasyImage(star, res)
        star.sizeDelta = Vector2.New(32, 32)

		local cond = GameTable.DescendsBarrierRef[id]["star" .. i]
		local condStr = cond and gModelDivineWeaponFight:GetStarStrByCond(cond) or ccClientText(46212)
		self:SetWndText(condText, condStr)
        local color = isOn and "89ff78ff" or "F5F6FEff"
        self:SetXUITextTransColor(condText, color)
	end
end

function UIOrdinResult:InitScrollView()
    local resultDataList, isUseDetailInfo = self:GetShowItemList()
    local itemNum = #resultDataList
    local isEmpty = itemNum == 0
    CS.ShowObject(self.mNoRecord, isEmpty and not self._noRecordText)
    if isEmpty then
        return
    end

    local isShowMin = itemNum <= 5
    CS.ShowObject(self.mMinItemList, isShowMin)
    CS.ShowObject(self.mItemList, not isShowMin)
    if isShowMin then
        self:SetMinItemList(resultDataList, isUseDetailInfo)
    else
        self:SetItemList(resultDataList, isUseDetailInfo)
    end
end

function UIOrdinResult:NextTowerBattle(combatType)
    if combatType == LCombatTypeConst.COMBAT_TYPE_75 then
        local type, list = gModelTower:GetIsTowerBattle(combatType, 5)
        if type == 3 then
            gModelGeneral:OpenUIOrdinTips({ refId = 80017, func = function()
                local pos = list[1] or 0
                gLFightManager:PrepareGoToBattle(combatType, { curTeam = pos })    --切换到布阵界面
                self:WndClose()
            end })
            return
        end
    end
    local isFromBack = self._isFromBack --or self._isOutLine
    if combatType == LCombatTypeConst.COMBAT_TOWER_BATTLE then
        local layer = gModelTower:GetCurrLayer()
        gModelTower:OnTowerBeforeBattleReq(layer, 2, isFromBack)
    else
        local combatData = {
            combatType = combatType,
            isBattleToBackground = isFromBack,
            --meName = gModelPlayer:GetPlayerName(),
        }
        --combatData.otherName = gModelBattle:GetOtherName(combatData)
        gModelBattle:StartAfterSetFormation(combatData)
    end

    self._isToNextBattle = true
    self:WndClose()
end

function UIOrdinResult:ShowCountPanel(para)
    CS.ShowObject(self.mMvpMar, true)
    self:SetWndText(self.mMvpNameText1, ccClientText(10163))
    self:SetWndText(self.mMvpOutputText1, ccClientText(10164))
    self:SetWndText(self.mMvpBearText1, ccClientText(10165))
    self:SetWndText(self.mMvpCureText1, ccClientText(10166))
    -- 【C宠物系统】删掉宠物系统相关
    -- self:SetWndText(self.mMvpNameText2,para.name)
    self:SetWndText(self.mMvpOutputText2, LUtil.NumberCoversion(tonumber(para.mvpOutput)))
    self:SetWndText(self.mMvpBearText2, LUtil.NumberCoversion(tonumber(para.mvpBear)))
    self:SetWndText(self.mMvpCureText2, LUtil.NumberCoversion(tonumber(para.mvpCure)))
    self:SetWndText(self.mMvpKillText, LUtil.FormatHurtNumSpriteText(para.mvpKill))
    CS.ShowObject(self.mMvpKillBg, para.mvpKill > 0)
end

function UIOrdinResult:InitPlayLevel()
    if not self:StartTween() then
        local level = gModelPlayer:GetPlayerLv()
        local totalExp = gModelPlayer:GetCurLevelTotalExp()
        local curExp = gModelPlayer:GetPlayerExp()
        local progress = curExp / totalExp
        self:ShowPlayerLvAndExp(level, progress)
        if totalExp < 0 then
            --- 2024/6/3： 反馈表处理，直接显示已满级
            --[[            local str = ccClientText(17011)
                        str = string.replace(str, curExp)
                        self:SetWndText(self.mLevelInfo, str)]]
            self:SetWndText(self.mLevelInfo, ccClientText(17011))
        end
    end
end

--因为某个够能错误设置了锚点导致，需要修复锚点为下对齐进行的修复功能
function UIOrdinResult:FixedSpineLHUIAnchor(dpSpine)
    if dpSpine and dpSpine:IsDpValid() then
        local dpTrans = dpSpine:GetDisplayTrans()
        dpTrans.anchorMin = Vector2(0.5, 0)
        dpTrans.anchorMax = Vector2(0.5, 0)
        dpTrans.pivot = Vector2(0.5, 0)
        dpTrans.anchoredPosition = Vector2.zero
        dpTrans.localScale = Vector3.one
    end
end

function UIOrdinResult:LoadMVPHeroDrawing(paintTans, paint, quotationsTrans, quotationsText, rankingId, heroShowRef)
    --设置立绘
    local scale = 0.95
    local flipx = false

    local x, y = gModelHeroBook:GetHeroPosByRefIdAndType(heroShowRef.refId, "heroDrawingPos3")
    if x and y then
        local extraY = gModelHeroExtra:GetCommonBattleY(paint)
        y = y + extraY
        paintTans.localPosition = Vector3.New(x, y, 0)
    end

    --local pos3Flip = heroShowRef.pos3Flip
    --if pos3Flip and pos3Flip > 0 then
    --    flipx = heroShowRef.pos3Flip == 1
    --end
    local pos3Scale = heroShowRef.pos3Scale
    if pos3Scale and pos3Scale > 0 then
        scale = pos3Scale
    end

    if (paint) then
        CS.ShowObject(paintTans, true)
        self:CreateWndSpine(self.mHeroSpine2, paint, paint, false, function(dpSpine)
            self:FixedSpineLHUIAnchor(dpSpine)
            dpSpine:SetScale(scale)
            dpSpine:SetFlipX(flipx)
            self:HeroAnimaition()

            if gModelBattle:ShowBattleInfoState() then
                self:TimerStart(self._heroQuotations, 1, false, 1)
            end
        end)

        local res1 = heroShowRef.skinSpineBg
        local res3 = heroShowRef.skinSpineHd
        if res1 ~= "" then
            self:CreateWndSpine(self.mHeroSpine1, res1, res1, false, function(dpSpine)
                self:FixedSpineLHUIAnchor(dpSpine)
                dpSpine:SetScale(scale)
                dpSpine:SetFlipX(flipx)
            end)
        end

        if res3 ~= "" then
            self:CreateWndSpine(self.mHeroSpine3, res3, res3, false, function(dpSpine)
                self:FixedSpineLHUIAnchor(dpSpine)
                dpSpine:SetScale(scale)
                dpSpine:SetFlipX(flipx)
            end)
        end
    else
        CS.ShowObject(paintTans, false)
    end

    -- mvp英雄语录
    if quotationsTrans and quotationsText then

        CS.ShowObject(quotationsTrans, true)
        if self._accWndType == 3 then
            quotationsText = ccClientText(12120)
        end
        self:SetWndText(quotationsTrans, quotationsText)
        if gLGameLanguage:IsJapanRegion() then
            self:InitTextLineWithLanguage(quotationsTrans, -20)
            self:InitTextSizeWithLanguage(quotationsTrans, -2)
        end
    end
end

function UIOrdinResult:ShowTypeWndByData()
    local wndRefId = self._wndRefId
    local wndData = GameTable.UIWindowAttRef[wndRefId]
    if not wndData then
        LogError("默认窗口类型为10001，没有配置该窗口的类型的数据:" .. wndRefId)
        wndData = GameTable.UIWindowAttRef[10001]
    end
    self._wndData = wndData

    -- 弹窗样式:5--通用胜利结算弹窗,6--通用失败结算弹窗
    local wndType = tonumber(wndData.windowType)
    self._wndType = wndType

    -- 点击空白处是否退出
    local touchAnyClose = wndData.touchAnyClose
    self._touchClose = tonumber(touchAnyClose)

    -- 正文文本:配置level显示角色头像和等级、进度条,配置其他文本显示文本（不显示头像等级）
    local text = ccLngText(wndData.text)
    if wndRefId == 51001 or wndRefId == 51003 then
        self._isShowLevel = true
    else
        if self._other then
            table.insert(self._other, " ")
            table.insert(self._other, " ")
            table.insert(self._other, " ")
            text = string.replace(text, unpack(self._other)) --LXStringUtil.ReplaceStringCommon(text,nil,unpack(self._other))
        end
        if self._isConcealText then
            text = ""
        end
        self._descriptionText = text
    end

    -- 无奖励时显示文本:读取配置Text2的描述，为空时，显示默认图片
    local text2 = wndData.text2
    text2 = ccLngText(text2)
    if not string.isempty(text2) then
        if self._other2 then
            text2 = string.replace(text2, unpack(self._other2)) --LXStringUtil.ReplaceStringCommon(text,nil,unpack(self._other))
        end
        self._noRecordText = text2
    end

    local btnText = ccLngText(wndData.btnTxt)
    local strs = string.split(btnText, "|")

    local btnPng = wndData.btnPng
    local pngStr = string.split(btnPng, "|")

    local startCountDowns = LxDataHelper.ParseNumber_Sign(self._wndData.startCountDown, "|")
    local countDowns = LxDataHelper.ParseNumber_Sign(self._wndData.countdown, '|')

    self._countDownDataList = {}
    self._btnClickList = {}

    local bNeedTimer = false
    for k = 1, 3 do
        local buttonCd = startCountDowns[k] or 0
        local tipsCd = countDowns[k] or 0
        if buttonCd > 0 then
            self._btnClickList[k] = false
        end
        if k == 3 and buttonCd > 0 and self._combatType == LCombatTypeConst.COMBAT_MAIN then
            local realTime = math.floor((gModelInstance:GetChallengeCd() or 0) - GetTimestamp() + 0.5)
            buttonCd = math.max(buttonCd, realTime)
        end
        if buttonCd > 0 or tipsCd > 0 then
            self._countDownDataList[k] = { buttonCd = buttonCd, buttonTime = buttonCd, isButtonOk = buttonCd <= 0, tipsCd = tipsCd, tipsTime = tipsCd }
            bNeedTimer = true
        end
    end

    self._btnStrs = strs
    self._btnImgPaths = pngStr
    local setFunc = self._typeSetFunc[wndType]
    if setFunc then
        setFunc()
    end

    if bNeedTimer then
        self:TimerStart(self._countDownKey, 1, false, -1)
    end

    local accWndType = self._accWndType

    local hidePlayback = false

    if accWndType == UIOrdinResult.NORMAl then
        local combatType = self._combatResult.combatType
        if combatType == LCombatTypeConst.COMBAT_MAIN then
            --local battleNode = self._combatResult.battleNode
            --hidePlayback = gModelPlot:IsStoryInstance(battleNode)

            if self._combatResult.winner == 1 then
                self:ShowWeakGuide()
            end
        elseif gModelBattle:IsEndlessCombat(combatType) then
            hidePlayback = true
        end

    elseif accWndType == UIOrdinResult.GUILD_SWEEP then
        hidePlayback = true
    elseif accWndType == UIOrdinResult.INVASION_SWEEP then
        hidePlayback = true
    end

    if hidePlayback then
        CS.ShowObject(self.mBackPlay, false)
        CS.ShowObject(self.mBattleData, false)
    end
    local combatType = (self._combatResult and self._combatResult.combatType) or 0
    if combatType == LCombatTypeConst.COMBAT_SWEETCOUNTRY_BOSS then
        CS.ShowObject(self.mBackPlay, false)
    end
end
-------------------------------------胜利窗口-------------------------------------
function UIOrdinResult:ShowTitleBg(isSuc)
    local image = "settlement_bg_title_1"
    if not isSuc then
        image = "settlement_bg_title_2"
    end
    self:SetWndEasyImage(self.mTitleBg, image)
end

function UIOrdinResult:IsNeedGotoNextMain()
    local battleNode = self._combatResult.battleNode
    local firstNode = tonumber(gModelPlot:GetPara("storynovicecombat"))
    if firstNode == battleNode then
        return true
    end
    return false
end

function UIOrdinResult:AniEnd()
    self.mBottom.anchoredPosition = Vector2(0, self.mCenterBg.localPosition.y * 0.5)

    self._delayTimer = LxTimer.DelayTimeCall(function()
        self.mBottom.anchoredPosition = Vector2(0, self.mCenterBg.localPosition.y * 0.5)
        self._delayTimer = nil
        self.mBottomCG.alpha = 1
    end, 0.1)
end

function UIOrdinResult:GetCombatGrowthWayRefIdByOrder(order)
    local refId = 0
    for key, value in pairs(GameTable.BattleGrowthWayRef) do
        if value.order == order then
            refId = value.refId
        end
    end
    return refId
end

function UIOrdinResult:ShowPlayerLvAndExp(level, progress)
    if not self.mLevel then
        return
    end
    self:SetXUITextText(self.mLevel, level)
    local expSlider = self:UIProgressFind(self.mExp, "_expSliderKey", progress)
    expSlider:SetUIProgress(progress)
end

-- 胜利类型窗口
function UIOrdinResult:ShowTypeWin()
    CS.ShowObject(self.mCommonResult, true)
    CS.ShowObject(self.mFailWnd, false)
    CS.ShowObject(self.mWinWnd, true)
    CS.ShowObject(self.mBattleData, true)
    CS.ShowObject(self.mBackPlay, true)
    CS.ShowObject(self.mPlayerLevel, self._isShowLevel)
    CS.ShowObject(self.mNewRecordIcon, self._isNewRecord or false)
    if self._isShowLevel then
        self:InitPlayLevel()
    else
        self:SetText(self.mDescriptionText)
    end

    self:SetDungeonText(self.mDungeonText, self._combatType)
    self:ShowMvpHero(true)
    self:ShowTitleEff(true)
    --self:CreateWinEffect()
    self:InitScrollView()
end

-- 设置按钮参数
function UIOrdinResult:SetButton()
    local btnTransList = {}
    self._btnTransList = btnTransList
    local btnAutoTextTransList = {}
    self._btnAutoTextTransList = btnAutoTextTransList

    local eventList = self:GetClickEventListImpl()

    local haveStartNum

    local bottomBtn = self.mBottomBtn
    LxResUtil.DestroyChild(bottomBtn)

    local btnDataList = {}
    for k, v in ipairs(self._btnImgPaths or {}) do
        local btnText = self._btnStrs[k]
        local btnFunc = eventList[k]
        if btnText and btnFunc then
            local data = {
                btnText = btnText,
                btnImg = v,
                btnFunc = btnFunc
            }

            table.insert(btnDataList, data)
        end

    end

    for i, v in ipairs(btnDataList) do
        local btnText = v.btnText
        local btnImg = v.btnImg
        local func = v.btnFunc

        local btnObj = self:GetBtnByName(btnImg)
        if btnObj then
            CS.ShowObject(btnObj, true)

            local btn = btnObj.transform
            CS.SetParentTrans(btn, bottomBtn)

            btnTransList[i] = btn
            local countDownText = self:FindWndTrans(btn, "CountDownText")
            btnAutoTextTransList[i] = countDownText

            self._btnClickList[i] = true
            local countDownData = self._countDownDataList[i]
            local btnTextShowStr = btnText
            haveStartNum = false

            if countDownData and countDownData.buttonCd > 0 then
                self:SetWndButtonGray(btn, true)
                btnTextShowStr = string.format("%s(%ss)", btnText, countDownData.buttonCd)
                self._btnClickList[i] = false
                haveStartNum = true
            end
            self:SetWndButtonText(btn, btnTextShowStr)

            if countDownData and countDownData.tipsCd > 0 then
                CS.ShowObject(countDownText, not haveStartNum)
                self:SetWndText(countDownText, string.replace(ccClientText(17004), tostring(countDownData.tipsCd)))
            end

            local index = i
            self:SetWndClick(btn, function()
                self:OnClickButton(index, func)
            end)

            if self._combatType == LCombatTypeConst.COMBAT_GUILD_BRAVE and i == 3 then
                local isGray = gModelGuildBoss:GetLastHurtCnt() <= 0
                self:SetWndButtonGray(btn, isGray)
            end
        end
    end
    return true
end

function UIOrdinResult:StopPlayerTween()
    if self._playerSeq then
        self._playerSeq:Kill(false)
        self._playerSeq = nil
    end
end
--endregion --------------------------------------------------------------------------------------

------------------------ ShowTypeBattle ------------------------
---【G公共支持】删掉小游戏功能
-- function UIOrdinResult:ShowTypeMinGame()
-- 	self:InitMinGameEvent()
-- 	self:InitMinGameData()
-- 	self:ShowTypeMinGameWndByData()
-- 	self:RefreshMinGameView()
-- 	self:PlayBattleMusic()
-- end

-- function UIOrdinResult:InitMinGameEvent()
-- 	--self:SetWndClick(self.mBg,function() self:WndClose() end)
-- end

-- function UIOrdinResult:GetMinGameBtnEvent()
-- 	local eventList = {}
-- 	local closeFunc = function()
-- 		FireEvent(EventNames.PARKOUR_TYPE_STOPGAME)
-- 		GF.OpenWnd("UIMCity")
-- 		GF.ChangeMap("LFightIdleMap")
-- 		GF.CloseWndByName("WndParkourShow")
-- 		gModelMinGame:EnterGame()
-- 		self:WndClose()
-- 	end
-- 	local returnFunc = function()
-- 		FireEvent(EventNames.PARKOUR_TYPE_STOPGAME)
-- 		GF.OpenWnd("UIMCity")
-- 		GF.ChangeMap("LFightIdleMap")
-- 		GF.CloseWndByName("WndParkourShow")
-- 		gModelMinGame:EnterGame()
-- 		self:WndClose()
-- 	end
-- 	local resetFunc = function()
-- 		FireEvent(EventNames.PARKOUR_TYPE_RESET)
-- 		self:WndClose()
-- 	end
-- 	local wndTipsRefId = self._wndTipsRefId
-- 	local isSuc = wndTipsRefId == 270003

-- 	eventList[1]= closeFunc
-- 	eventList[2]= isSuc and returnFunc or resetFunc
-- 	return eventList
-- end

function UIOrdinResult:GetMatchEvent()
    local eventList = {}
    local closeFunc = function()
        -- 【C宠物系统】删掉宠物系统相关
        -- GF.ChangeMap("LPetRoadMap")
        -- GF.CloseWndByName("WndPetFight")
        self:WndClose()
    end
    local returnFunc = function()
        -- 【C宠物系统】删掉宠物系统相关
        -- GF.ChangeMap("LPetRoadMap")
        -- GF.CloseWndByName("WndPetFight")
        self:WndClose()
    end

    eventList[1] = closeFunc
    eventList[2] = returnFunc
    -- 【C宠物系统】删掉宠物系统相关
    -- if self:GetWndArg("showNext") then
    -- 	local nextFunc = function()
    -- 		gModelPetFight:OnClickFight()
    -- 		self:WndClose()
    -- 	end
    -- 	eventList[3]= nextFunc
    -- end
    return eventList
end

function UIOrdinResult:OnShareBtnClick()
    local shareType = ModelChat.CHAT_SHARE_44
    local otherName = gModelBattle:GetOtherNameByCombatResult(self._combatResult)
    local shareData = {
        playerName2 =otherName,
        playerName1 = gModelPlayer:GetPlayerName(),
        reportId = self._combatResult.reportId,
        combatType=LCombatTypeConst.COMBAT_PK ,
        serverId = self._serverId or gLGameLogin:GetActualServerId(),
    }

    local jsonStr = JSON.encode(shareData)
    local data = {
        root = self.mShareBtn,
        shareType = shareType,
        shareData = jsonStr
    }
    gModelGeneral:OpenShareTip(data)
    --printInfoN2("--", "--")
end

-- 设置正文文本
function UIOrdinResult:SetText(textTrans)
    if self._descriptionText and textTrans then
        local str = self._descriptionText
        -- if self._combatType == gModelBossTower:GetBossTowerConfigRefByKey("towerBossFightType") then
        -- 	str = string.replace(str,LUtil.NumberCoversion(tonumber(self._combatResult.hurtCountA)))
        -- elseif self._combatType == gModelBossTower:GetBossTowerConfigRefByKey("towerFightType") then
        -- 	local combatResult = self._combatResult
        -- 	local refId = combatResult.refId
        -- 	local insRef = gModelBossTower:GetBossTowerInsRefByRefId(refId)
        -- 	if insRef then
        -- 		local sort =insRef.sort
        -- 		local multiWinner = combatResult.multiWinner or {}
        -- 		local winA,winB = 0,0
        -- 		--if combatResult.winner == ModelCrossGrading.ATTACK_TYPE then
        -- 		--	winA = winA + 1
        -- 		--end
        -- 		for i,v in ipairs(multiWinner) do
        -- 			if v == ModelCrossGrading.ATTACK_TYPE then
        -- 				winA = winA + 1
        -- 			else
        -- 				winB = winB + 1
        -- 			end
        -- 		end
        -- 		local winStr = string.replace(ccClientText(21841),winA,winB)
        -- 		str = string.replace(str,sort,winStr)
        -- 	end
        -- end
        self:SetWndText(textTrans, str)
        CS.ShowObject(textTrans, true)
    end
end

function UIOrdinResult:InitEvent()
    self:SetWndClick(self.mBtnShare, function()
        self:OnClickShare()
    end, LSoundConst.CLICK_BUTTON_COMMON)

    self:SetWndClick(self.mBattleData, function()
        self:OnBattleDetails()
    end, LSoundConst.CLICK_BUTTON_COMMON)

    self:SetWndClick(self.mBackPlay, function()
        self:BattlePlayback()
    end, LSoundConst.CLICK_BUTTON_COMMON)

    if self._combatType == LCombatTypeConst.COMBAT_BADGE_GAME then
        gModelBadgeGame:OnBadgeGameInfoReq()
        self:WndEventRecv(EventNames.BADGE_GAME_BATTLE_STAR, function(...)
            self:OnBadgeStar()
        end)
        self:WndEventRecv(EventNames.BADGE_GAME_UPDATE, function(...)
            self:OnBadgeStar()
        end)
    end
end
function UIOrdinResult:NextMainBraveHeroBattle(combatType)
    local nextCd = gModelInstance:GetChallengeCd()
    local nowtime = GetTimestamp()
    if nowtime < nextCd then
        GF.ShowMessage(ccClientText(10751))
        return
    end
    local battleNode = gModelInstance:GetRawBattleNode()
    if battleNode == -1 then
        return
    end
    local func = function()
        local isBackground = self._isFromBack
        local combatData = {
            combatType = combatType,
            isBattleToBackground = isBackground
        }
        if (combatType == LCombatTypeConst.COMBAT_TYPE_30 or combatType == LCombatTypeConst.COMBAT_TYPE_31) then
            local diffLvl = combatType == LCombatTypeConst.COMBAT_TYPE_30 and 2 or 3
            local isSkip = gModelInstance:GetMainFightDiffLvlSkip(diffLvl, 2)
            combatData.skipBattle = isSkip
        end
        gModelBattle:StartAfterSetFormation(combatData)

        if not isBackground then
            local wnd = GF.FindFirstWndByName("UIMCity")
            if wnd then
                wnd:ChangeCurBtn(3)
            end
        end
        self._isToNextBattle = true
        GF.CloseWndByName("UIOrdinResult")
    end

    gModelInstance:CheckShowExploreTip(30008, func)
end
-------------------------------------UIListEasy-------------------------------------

-------------------------------------ClickButton-------------------------------------
-- 战斗回放
function UIOrdinResult:BattlePlayback()

    if self._accWndType ~= UIOrdinResult.NORMAl then
        return
    end
    local combatResult = self._combatResult
    local otherName, dungeonId

    otherName = gModelBattle:GetOtherNameByCombatResult(combatResult)

    if self._combatType == LCombatTypeConst.COMBAT_DUNGEON_DAILY then
        dungeonId = combatResult and combatResult.wonderlandEventRefId
    end

    local battleData = {
        reportId = combatResult.reportId,
        meName = gModelPlayer:GetPlayerName(),
        otherName = otherName,
        combatType = self._combatType,
        dungeonId = dungeonId,
        battleEndfun = function(changeBot)
            gModelBattle:ShowAccountByCombatResult(combatResult, changeBot)
        end
    }

    if self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
        -- local data = JSON.decode(self._combatResult.activityData)
        -- local conditionList = data.conditionList
        -- battleData.conditionList = conditionList
    end

    if self._combatType == LCombatTypeConst.COMBAT_TYPE_75 then
        battleData.reportId = combatResult.multReportIds
        self:BattlePlayBack2(battleData, true)
        return
    elseif self._combatType == LCombatTypeConst.COMBAT_TYPE_30 or self._combatType == LCombatTypeConst.COMBAT_TYPE_31 then
        battleData.reportId = combatResult.multReportIds
        self:BattlePlayBack2(battleData, true)
        return
    end

    -- if self._combatType == gModelBossTower:GetBossTowerConfigRefByKey("towerBossFightType") then
    -- 	battleData.reportId = combatResult.multReportIds
    -- 	self:BattlePlayBack2(battleData,true)
    -- 	return
    -- end

    -- if self._combatType == gModelBossTower:GetBossTowerConfigRefByKey("towerFightType") then
    -- 	battleData.reportId = combatResult.multReportIds
    -- 	self:BattlePlayBack2(battleData,true)
    -- 	return
    -- end
    if self._combatType == LCombatTypeConst.COMBAT_CRUSADE_AGAINST then
        battleData.targetId = combatResult.battleNode
    end

    gModelBattle:BattlePlayBack(battleData, true)
end

function UIOrdinResult:ShowNoGotoListType()
    local isWin = self._resultWin or false
    CS.ShowObject(self.mCommonResult, false)
    CS.ShowObject(self.mBattleData, true)
    CS.ShowObject(self.mBackPlay, true)
    CS.ShowObject(self.mPlayerLevel, false)

    self:SetText(self.mDescriptionText)

    self:SetDungeonText(self.mDungeonText, self._combatType)
    self:ShowMvpHero(isWin)
    self:ShowTitleEff(isWin)
    --self:CreateWinEffect()
    self:InitScrollView()
    self:SetNoRecordText()
end

-- 失败类型窗口
function UIOrdinResult:ShowTypeFail()
    CS.ShowObject(self.mCommonResult, true)
    CS.ShowObject(self.mWinWnd, false)
    CS.ShowObject(self.mFailWnd, true)
    CS.ShowObject(self.mPlayerLevel, false)

    self:SetDungeonText(self.mDungeonText, self._combatType)
    self:ShowMvpHero(false)
    self:InitFail()
    self:SetText(self.mDescriptionText)
end

function UIOrdinResult:SweepInvasion()

    self._isClickRet = true
    local returnFun = gModelBattle:GetReturnFun(LCombatTypeConst.COMBAT_INVASION_BOSS)
    if returnFun then
        returnFun(true)
    end
    self:OnClickClose()
    --gModelInvasion:OnClickSweep()
end

-- 详情界面
function UIOrdinResult:OnBattleDetails()
    local combatType = self._combatType

    local combatResult = self._combatResult
    local otherName = gModelBattle:GetOtherNameByCombatResult(combatResult)

    local extraData = {}
    extraData.combatType = combatType
    extraData.meName = gModelPlayer:GetPlayerName()
    extraData.otherName = otherName
    if combatType == LCombatTypeConst.COMBAT_CRUSADE_AGAINST then
        extraData.targetId = combatResult.battleNode
    end
    if combatType == LCombatTypeConst.COMBAT_DUNGEON_DAILY then
        extraData.dungeonId = combatResult and combatResult.wonderlandEventRefId
    elseif combatType == LCombatTypeConst.COMBAT_TYPE_75 then
        local multReportIds = self._combatResult.multReportIds
        local multiWinner = self._combatResult.multiWinner

        local extraData = {
            winnerNumber = multiWinner,
            reportId = multReportIds,
            serverId = gLGameLogin:GetActualServerId(),
            combatType = combatType,
        }
        --extraData.closeAfterVideo = function()
        --    GF.OpenWndBottom("UITaWin",{towerType = ModelTower.RACE_TYPE_99})
        --end
        gLFightManager:ShowCrossGradingBattleDetail(extraData)
        return
    elseif combatType == LCombatTypeConst.COMBAT_TYPE_30 or combatType == LCombatTypeConst.COMBAT_TYPE_31 then
        local multReportIds = self._combatResult.multReportIds
        local multiWinner = self._combatResult.multiWinner

        local extraData = {
            winnerNumber = multiWinner,
            reportId = multReportIds,
            serverId = gLGameLogin:GetActualServerId(),
            combatType = combatType,
        }
        gLFightManager:ShowCrossGradingBattleDetail(extraData)
        return
        -- elseif self._combatType == gModelBossTower:GetBossTowerConfigRefByKey("towerBossFightType")
        -- 	 or self._combatType == gModelBossTower:GetBossTowerConfigRefByKey("towerFightType") then
        -- 		local multiWinner = self._combatResult.multiWinner
        -- 		local extraData = {
        -- 			winnerNumber = multiWinner,
        -- 			reportId = self._combatResult.multReportIds,
        -- 			serverId = gLGameLogin:GetActualServerId(),
        -- 			combatType = self._combatType,
        -- 		}
        -- 		gLFightManager:ShowCrossGradingBattleDetail(extraData)
        -- 		return
    elseif combatType == LCombatTypeConst.COMBAT_ACTIVITY_DREAMTRIP then
        local extraData = {
            sid = self._combatResult.towerRefId
        }
        local reportId = self._combatResult.reportId
        gLFightManager:OnOpenBattleDetails(reportId, extraData, nil, true)
        return
    elseif gModelBattle:IsPetDreamLandCombat(combatType) then
        extraData.params = self._combatResult.params
    elseif combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
        local data = JSON.decode(self._combatResult.activityData)
        for k, v in pairs(data) do
            extraData[k] = v
        end
        self._combatResult.sid = data.sid
    end
    if self._accWndType == UIOrdinResult.NORMAl then
        extraData.sid = self._combatResult.sid
        local reportId = self._combatResult.reportId
        gLFightManager:OnOpenBattleDetails(reportId, extraData, nil, true)
    end
end

-- 倒计时结束，自动点击对应按钮事件
function UIOrdinResult:SetCountDown()
    local btnTransList = self._btnTransList
    local btnAutoTextTransList = self._btnAutoTextTransList


    --local openType = self._openType
    local eventList = self:GetClickEventListImpl()
    --if openType == UIOrdinResult.TYPE_BATTLE then
    --	eventList = self:GetClickEvent()
    --elseif openType == UIOrdinResult.TYPE_MINGAME then
    --	eventList = self:GetMinGameBtnEvent()
    --end

    local bStop = true
    local countDownDataList = self._countDownDataList
    local btnStrs = self._btnStrs

    for i = 1, 3 do
        local btnText = btnStrs[i]
        local countDownData = countDownDataList[i]
        local event = eventList[i]
        if countDownData and not countDownData.isAllOk and btnText and event ~= nil then
            local btn = btnTransList[i]
            local autoTextTrans = btnAutoTextTransList[i]

            bStop = false
            if not countDownData.isButtonOk then
                local text
                local timeLeft = countDownData.buttonTime - 1
                countDownData.buttonTime = timeLeft
                if timeLeft > 0 then
                    text = string.format("%s(%ss)", btnText, timeLeft)
                else
                    text = btnText

                    self._btnClickList[i] = true

                    self:SetWndButtonGray(btn, false)

                    countDownData.isButtonOk = true
                    if countDownData.tipsTime > 0 then
                        CS.ShowObject(autoTextTrans, true)
                    else
                        countDownData.isAllOk = true
                    end
                end

                self:SetWndButtonText(btn, text)
            else
                local timeLeft = countDownData.tipsTime - 1
                countDownData.tipsTime = timeLeft
                if timeLeft > 0 then
                    local autoText = string.replace(ccClientText(17004), timeLeft)
                    self:SetWndText(autoTextTrans, autoText)
                else
                    event()
                end
            end

            if self._combatType == LCombatTypeConst.COMBAT_GUILD_BRAVE and i == 3 then
                local isGray = gModelGuildBoss:GetLastHurtCnt() <= 0
                self:SetWndButtonGray(btn, isGray)
            end
        end
    end

    if bStop then
        self:TimerStop(self._countDownKey)
    end
end

function UIOrdinResult:BattlePlayBack2(battleData, bool)
    gModelBattle:MultiBattlePlayBack(battleData, bool)
end

-- 扫荡,挑战结束类型窗口
function UIOrdinResult:ShowTypeMopUpOrChallenge(isMopUp)
    CS.ShowObject(self.mCommonResult, true)
    CS.ShowObject(self.mWinWnd, true)
    CS.ShowObject(self.mFailWnd, false)
    CS.ShowObject(self.mPlayerLevel, false)

    local image = "fight_txt_2"
    if isMopUp then
        image = "fight_txt_3"
    end
    CS.ShowObject(self.mTitleEff, false)
    CS.ShowObject(self.mTitleIcon, true)
    self:SetWndEasyImage(self.mTitleIcon, image)
    self:ShowTitleBg(true)

    self:ShowMvpHero(true)
    self:SetDungeonText(self.mDungeonText, self._combatType)
    self:InitScrollView()
end

-- 【C宠物系统】删掉宠物系统相关
-- function UIOrdinResult:ShowMatchMvp(isWin)
-- 	local data = self:GetWndArg("data")
-- 	local petInfo = data.mvpPet

-- 	local effectRef = gModelPetSpace:GetPetShowEffect(petInfo)
-- 	if not effectRef then
-- 		return
-- 	end
-- 	local drawing = effectRef.prefabName
-- 	local saying = nil
-- 	if isWin then
-- 		saying = ccLngText(effectRef.descriptionVictory)
-- 	else
-- 		saying = ccLngText(effectRef.descriptionFail)
-- 	end

-- 	local offset = LxDataHelper.ParseVector2(effectRef.petResultPos,"|")
-- 	local size = effectRef.petResultSize

-- 	local root = self.mHeroDrawing
-- 	CS.ShowObject(root,true)
-- 	self:SetAnchorPos(root,offset)
-- 	self:CreateWndSpine(root,drawing,drawing,false,function(dpSpine)
-- 		dpSpine:SetScale(size)
-- 		dpSpine:SetChangeStatus(petInfo.changeStatus)
-- 		dpSpine:SetFlipX(false)
-- 		self:HeroAnimaition()
-- 		self:TimerStart(self._heroQuotations,1,false,1)
-- 	end)

-- 	-- mvp英雄语录
-- 	CS.ShowObject(self.mQuotationsText,true)
-- 	self:SetWndText(self.mQuotationsText,saying)
-- end

function UIOrdinResult:InitRefData()
    local wndRefId = self._wndRefId
    local wndData = GameTable.UIWindowAttRef[wndRefId]
    if not wndData then
        LogError("默认窗口类型为10001，没有配置该窗口的类型的数据:" .. wndRefId)
        wndData = GameTable.UIWindowAttRef[10001]
    end
    self._wndData = wndData

    -- 弹窗样式:5--通用胜利结算弹窗,6--通用失败结算弹窗
    local wndType = tonumber(wndData.windowType)
    self._wndType = wndType

    -- 点击空白处是否退出
    local touchAnyClose = wndData.touchAnyClose
    self._touchClose = tonumber(touchAnyClose)

    -- 正文文本:配置level显示角色头像和等级、进度条,配置其他文本显示文本（不显示头像等级）
    local text = ccLngText(wndData.text)
    if wndRefId == 51001 or wndRefId == 51003 then
        self._isShowLevel = true
    else
        if self._other then
            table.insert(self._other, " ")
            table.insert(self._other, " ")
            table.insert(self._other, " ")
            text = string.replace(text, unpack(self._other)) --LXStringUtil.ReplaceStringCommon(text,nil,unpack(self._other))
        end
        if self._isConcealText then
            text = ""
        end
        self._descriptionText = text
    end

    -- 无奖励时显示文本:读取配置Text2的描述，为空时，显示默认图片
    local text2 = wndData.text2
    text2 = ccLngText(text2)
    if not string.isempty(text2) then
        if self._other2 then
            text2 = string.replace(text2, unpack(self._other2)) --LXStringUtil.ReplaceStringCommon(text,nil,unpack(self._other))
        end
        self._noRecordText = text2
    end

    local btnText = ccLngText(wndData.btnTxt)
    local strs = string.split(btnText, "|")

    local btnPng = wndData.btnPng
    local pngStr = string.split(btnPng, "|")

    local startCountDowns = LxDataHelper.ParseNumber_Sign(self._wndData.startCountDown, "|")
    local countDowns = LxDataHelper.ParseNumber_Sign(self._wndData.countdown, '|')

    self._countDownDataList = {}
    self._btnClickList = {}

    local bNeedTimer = false
    for k = 1, 3 do
        local buttonCd = startCountDowns[k] or 0
        local tipsCd = countDowns[k] or 0
        if buttonCd > 0 then
            self._btnClickList[k] = false
        end
        --if k == 3 and buttonCd > 0 and self._combatType == LCombatTypeConst.COMBAT_MAIN then
        --	local realTime = math.floor((gModelInstance:GetChallengeCd() or 0) - GetTimestamp() + 0.5)
        --	buttonCd = math.max(buttonCd, realTime)
        --end
        if buttonCd > 0 or tipsCd > 0 then
            self._countDownDataList[k] = { buttonCd = buttonCd, buttonTime = buttonCd, isButtonOk = buttonCd <= 0, tipsCd = tipsCd, tipsTime = tipsCd }
            bNeedTimer = true
        end
    end

    self._btnStrs = strs
    self._btnImgPaths = pngStr

    if bNeedTimer then
        self:TimerStart(self._countDownKey, 1, false, -1)
    end

end

function UIOrdinResult:GetClickEventListImpl()
    local openType = self._openType
    local eventList = {}
    if openType == UIOrdinResult.TYPE_BATTLE then
        eventList = self:GetClickEvent()
        -- 【G公共支持】删掉小游戏功能
        -- elseif openType == UIOrdinResult.TYPE_MINGAME then
        -- 	eventList = self:GetMinGameBtnEvent()
    elseif openType == UIOrdinResult.TYPE_MATCH then
        eventList = self:GetMatchEvent()
    end
    return eventList
end

function UIOrdinResult:ShowMatchWin()
    local wndRefId = self._wndRefId
    local wndData = GameTable.UIWindowAttRef[wndRefId]
    local title_2_str = ""
    if wndData then
        if not string.isempty(wndData.title1) then
            title_2_str = ccLngText(wndData.title1)
        else
            title_2_str = ccClientText(10721)
        end
    end

    self:SetWndText(self.mAwardText, title_2_str)
    -- LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_FIGHT_WIN)
    local soundName = LxResPathUtil.GetAudioSoundNameByRefId(LSoundConst.TRIGGER_FIGHT_WIN)
    gLGameAudio:PlaySingleSound(soundName)
    self:OnPlayMvpSound()
    self:ShowTitleEff(true)

    CS.ShowObject(self.mCommonResult, true)
    CS.ShowObject(self.mFailWnd, false)
    CS.ShowObject(self.mWinWnd, true)
    CS.ShowObject(self.mPlayerLevel, false)

    local data = self:GetWndArg("data")
    local resultDataList, isUseDetailInfo = self:GetShowItemListImpl(data.itemList, data.rewardInfo)
    local itemNum = #resultDataList
    local isEmpty = itemNum == 0
    CS.ShowObject(self.mNoRecord, isEmpty and not self._noRecordText)
    if isEmpty then
        return
    end

    local isShowMin = itemNum <= 5
    CS.ShowObject(self.mMinItemList, isShowMin)
    CS.ShowObject(self.mItemList, not isShowMin)
    if isShowMin then
        self:SetMinItemList(resultDataList, isUseDetailInfo)
    else
        self:SetItemList(resultDataList, isUseDetailInfo)
    end

end

function UIOrdinResult:NextMainBattle()
    local nextCd = gModelInstance:GetChallengeCd()
    local nowtime = GetTimestamp()
    if nowtime < nextCd then
        GF.ShowMessage(ccClientText(10751))
        return
    end
    local battleNode = gModelInstance:GetRawBattleNode()
    if battleNode == -1 then
        return
    end
    local func = function()
        local isBackground = self._isFromBack
        local combatData = {
            combatType = LCombatTypeConst.COMBAT_MAIN,
            isBattleToBackground = isBackground,
            meName = gModelPlayer:GetPlayerName()
        }
        gModelBattle:StartAfterSetFormation(combatData)

        if not isBackground then
            local wnd = GF.FindFirstWndByName("UIMCity")
            if wnd then
                --wnd:ChangeCurBtn(6)
                wnd:ChangeCurBtn(LMainBtnIndexConst.ADVENTURE)

            end
        end
        self._isToNextBattle = true
        GF.CloseWndByName("UIOrdinResult")
    end

    gModelInstance:CheckShowExploreTip(30008, func)
end

function UIOrdinResult:OnPlayMvpSound()
    local mvp = self:GetMvpHeroData()
    local loveLevel = gModelHero:GetHeroLoveLvByRefId(mvp.refId) or 0
    local favorRef = gModelHero:GetHeroSpActionSoundRef().heroWinMVPSound
    if loveLevel >= favorRef.refId and favorRef.SpActionSound ~= "" then
        local sound = GameTable.CharacterEffectRef[mvp.skin > 0 and mvp.skin or mvp.refId][favorRef.SpActionSound]
        if sound and sound ~= "" then
            gLGameAudio:PlaySound(sound)
        end
    end
end

function UIOrdinResult:SetFunctionItem(item, itemdata)
    if not item then
        return
    end
    CS.ShowObject(item, itemdata)
    if not itemdata then
        return
    end
    local icon = CS.FindTrans(item, "IconBg/FunctionIcon")
    local text = CS.FindTrans(item, "FunctionText")

    local showType = itemdata.showType
    local str = ""
    if showType == 1 then
        str = string.replace(ccClientText(17012), itemdata.name)
    elseif showType == 2 then
        str = string.replace(ccClientText(17013), itemdata.battleNum, itemdata.name)
    elseif showType == 3 then
        str = string.replace(ccClientText(17016), itemdata.battleNum, itemdata.openDay, itemdata.name)
    elseif showType == 4 then
        str = string.replace(ccClientText(17017), itemdata.battleNum, itemdata.openDay, itemdata.name)
    end
    self:SetWndEasyImage(icon, itemdata.cfg.icon)
    self:SetWndText(text, str)
    self:InitTextSizeWithLanguage(text, -6)
    self:InitTextLineWithLanguage(text, -40)
end

function UIOrdinResult:SetPkInfo(tran, info)
    local HeadIconTran = CS.FindTrans(tran, "HeadIcon")
    local infodata = {
        icon = info._head,
        headFrame = info._headFrame,
        level = info._grade,
    }
    local InstanceID = HeadIconTran:GetInstanceID()
    if not self._uiheadList then
        self._uiheadList = {}
    end
    local baseClass = self._uiheadList[InstanceID]
    if not baseClass then
        baseClass = HeadIcon:New(self)
        self._uiheadList[InstanceID] = baseClass
    end
    infodata.trans = HeadIconTran
    --info._uiIconBgTrans= HeadIconTran
    baseClass:SetHeadData(infodata)

    local NameTran = CS.FindTrans(tran, "Name")
    self:SetWndText(NameTran, info._name)
end

function UIOrdinResult:ShowMatchFail()

    local wndRefId = self._wndRefId
    local wndData = GameTable.UIWindowAttRef[wndRefId]
    local title_2_str = ""
    if wndData then
        if not string.isempty(wndData.title1) then
            title_2_str = ccLngText(wndData.title1)
        else
            title_2_str = ccClientText(10162)
        end
    end

    self:SetWndText(self.mAwardText, title_2_str)

    --self:SetWndText(self.mAwardText, ccClientText(10162))
    LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_FIGHT_FAIL)
    self:ShowTitleEff(false)

    local dataList = {}
    for k, v in pairs(GameTable.BattleGrowthWayRef) do
        if v.type == 1 then
            table.insert(dataList, v)
        end
    end

    table.sort(dataList, function(a, b)
        return a.order < b.order
    end)

    local itemList = self:GetUIScroll("gotoList")
    itemList:Create(self.mGotoList, dataList, function(...)
        self:OnDrawGoto(...)
    end)

    CS.ShowObject(self.mCommonResult, true)
    CS.ShowObject(self.mWinWnd, false)
    CS.ShowObject(self.mFailWnd, true)
    CS.ShowObject(self.mPlayerLevel, false)
end

function UIOrdinResult:OnBadgeStar()
    local conditionList = {}
    local okList = {}
    local imgPath = {}
    if self._combatType == LCombatTypeConst.COMBAT_BADGE_GAME and self._combatResult.refId > 0 then
        local refId = self._combatResult.refId
        local ref = GameTable.BadgeGameBarrierRef[refId]
        conditionList[2] = ref.starCond1
        conditionList[3] = ref.starCond2

        local chapterInfo = gModelBadgeGame:GetChapterById(ref.chapterId)
        local stars = { 0, 0, 0 }
        if chapterInfo then
            stars = chapterInfo:GetBarrierStar(self._combatResult.refId, true)
        end

        if gModelBadgeGame.starCondRefId[ref.starCond1] or stars[2] > 0 then
            okList[2] = true
        end
        if gModelBadgeGame.starCondRefId[ref.starCond2] or stars[3] > 0 then
            okList[3] = true
        end
        local starInfo = ModelBadgeGame.StarImgMap[ref.type]
        imgPath.ok = starInfo.Act
        imgPath.no = starInfo.NoAct
        imgPath.size = Vector2(30, 26)
    elseif self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
        local data = JSON.decode(self._combatResult.activityData)
        conditionList[2] = data.conditionList[1]
        conditionList[3] = data.conditionList[2]
        local okMap = {}
        if self._combatResult.args and self._combatResult.args[1] then
            local list = JSON.decode(self._combatResult.args[1])
            for k, v in pairs(list or {}) do
                okMap[v] = true
            end
        end

        if okMap[conditionList[2]] then
            okList[2] = true
        end
        if okMap[conditionList[3]] then
            okList[3] = true
        end
        imgPath.ok = "public_icon_right_2"
        imgPath.no = "public_false_01"
        imgPath.size = Vector2(26, 26)
    end

    if self._combatResult and self._combatResult.winner == 1 then
        okList[1] = true
    else
        okList[1] = false
        okList[2] = false
        okList[3] = false
    end

    local isShow = #conditionList > 0
    CS.ShowObject(self.mImgStarBg, isShow)
    CS.ShowObject(self.mObjStar, isShow)
    if isShow then
        for i = 1, 3 do
            local trans = self["mStar" .. i]
            self:SetWndEasyImage(trans, okList[i] and imgPath.ok or imgPath.no)
            trans.sizeDelta = imgPath.size
        end

        local isOk = okList[1]
        local color = isOk and "89ff78ff" or "F5F6FEff"
        self:SetWndText(self.mTxtStar1, ccClientText(40226))
        self:SetXUITextTransColor(self.mTxtStar1, color)
        self:SetWndEasyImage(self.mImgStar1, isOk and imgPath.ok or imgPath.no)
        self.mImgStar1.sizeDelta = imgPath.size

        local condRefId = conditionList[2]
        local condRef = GameTable.BadgeGameCondRef[condRefId]
        isOk = okList[2]
        color = isOk and "89ff78ff" or "F5F6FEff"
        self:SetWndText(self.mTxtStar2, ccLngText(condRef.text))
        self:SetXUITextTransColor(self.mTxtStar2, color)
        self:SetWndEasyImage(self.mImgStar2, isOk and imgPath.ok or imgPath.no)
        self.mImgStar2.sizeDelta = imgPath.size

        local condRefId2 = conditionList[3]
        if condRefId2 then
            condRef = GameTable.BadgeGameCondRef[condRefId2]
            isOk = okList[3]
            color = isOk and "89ff78ff" or "F5F6FEff"
            self:SetWndText(self.mTxtStar3, ccLngText(condRef.text))
            self:SetXUITextTransColor(self.mTxtStar3, color)
            self:SetWndEasyImage(self.mImgStar3, isOk and imgPath.ok or imgPath.no)
            self.mImgStar3.sizeDelta = imgPath.size
        end
        CS.ShowObject(self.mTxtStar3.parent, condRefId2 ~= nil)
    end
    return isShow
end

function UIOrdinResult:PlayBattleMusic()
    local id
    -- 【G公共支持】删掉小游戏功能
    -- local openType = self._openType
    -- if openType == UIOrdinResult.TYPE_MINGAME then
    -- 	id = self._gameStatus == UIOrdinResult.MINGAME_TYPE_SUCCESS and LSoundConst.TRIGGER_FIGHT_WIN or LSoundConst.TRIGGER_FIGHT_FAIL
    -- else
    if self._resultWin then
        id = LSoundConst.TRIGGER_FIGHT_WIN
        self:OnPlayMvpSound()
    else
        id = LSoundConst.TRIGGER_FIGHT_FAIL
    end
    -- end

    -- LxUiHelper.PlayAudioSoundName(id)
    local soundName = LxResPathUtil.GetAudioSoundNameByRefId(id)
    gLGameAudio:PlaySingleSound(soundName)
end

-------------------------------------失败窗口-------------------------------------
function UIOrdinResult:InitFail()
    self:ShowTitleEff(false)

    local combatType = self._combatType
    local dataList = {}
    -- local towerFightType = gModelBossTower:GetBossTowerConfigRefByKey("towerFightType")
    -- local compareFightType = gModelBossTower:GetBossTowerConfigRefByKey("compareFightType")
    -- if combatType ~= towerFightType and combatType ~= compareFightType then
    for k, v in pairs(GameTable.BattleGrowthWayRef) do
        if v.type == 0 then
            table.insert(dataList, v)
        end
    end
    -- else
    -- 	self:SetWndText(self.mNoRecordText,ccClientText(23772))
    -- end

    table.sort(dataList, function(a, b)
        return a.order < b.order
    end)

    local itemList = self:GetUIScroll("gotoList")
    itemList:Create(self.mGotoList, dataList, function(...)
        self:OnDrawGoto(...)
    end)
end

function UIOrdinResult:ShowTitleEff(isSuc)
    CS.ShowObject(self.mTitleIcon, false)
    CS.ShowObject(self.mTitleEff, true)
    CS.ShowObject(self.mWinBg, true)
    self:ShowTitleBg(isSuc)
    local effName = "fx_ui_shibai"
    local imgName = "settlement_bg_title_4"
    --local pos= Vector3.New(0,31,0)
    if isSuc then
        effName = "fx_ui_shengli"
        imgName = "settlement_bg_title_3"
        --pos = Vector3.New(0,-135,0)
    end
    self:CreateWndEffect(self.mTitleEff, effName, effName, 100)
    --self.mTitleEff.localPosition = pos
    local pos = Vector2.New(-13.85, 10)
    if gLGameLanguage:IsForeignVersion() then
        pos = Vector2.New(-13.85, 10)
    end
    self:SetAnchorPos(self.mTitleEff, pos)
    self:SetWndEasyImage(self.mWinBg, imgName)
end

function UIOrdinResult:BadgeGameNextBattle()
    local barrierId = self._combatResult.winner ~= 1 and self._combatResult.refId or self._combatResult.refId + 1
    local nextRef = GameTable.BadgeGameBarrierRef[barrierId]
    if not nextRef then
        GF.ShowMessage(ccClientText(40227))
        return
    end
    local chapterInfo = gModelBadgeGame:GetChapterById(nextRef.chapterId)
    if chapterInfo and chapterInfo:GetChapterState() == 2 then
        local chapterRef = GameTable.BadgeGameChapRef[nextRef.chapterId]
        local str = string.replace(ccClientText(40228), chapterRef.needLevel)
        if chapterRef.needStar and chapterRef.needStar > 0 then
            str = str .. string.replace(ccClientText(40229), chapterRef.needStar)
        end
        str = str .. ccClientText(40230)
        GF.ShowMessage(str)
        return
    end
    self._isClickRet = true
    local monsterRef = GameTable.MonsterFormationRef[nextRef.monster]
    -- local name = monsterRef and ccLngText(monsterRef.name)
    local power = monsterRef and monsterRef.monsterPower or 0
    gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_BADGE_GAME,
            { refId = barrierId, power = power, monsterRefId = nextRef.monster })--otherName=name，
    gModelBadgeGame:SetLastBattleBarrier(barrierId)
    self:OnClickClose()
end

function UIOrdinResult:GetClickEvent()
    local eventList = {}
    local combatType = self._combatType
    local showNext = self._showNext
    local returnFunc = function()
        self._isClickRet = true

        if combatType == LCombatTypeConst.COMBAT_MAIN then
            local battleNode = self._combatResult.battleNode
            local noNeed = false
            if gModelPlot:IsStoryInstance(battleNode) then
                noNeed = true
            end

            if gModelPlot:IsDogInstance(battleNode) then
                noNeed = true
            end

            local needNext = self:IsNeedGotoNextMain()
            if noNeed or needNext then
                self:WndClose()
                if needNext then
                    self:GotoNextMain()
                end
                return
            end
        end

        local func = gModelBattle:GetReturnFun(combatType)
        if func then
            func(self._combatResult)
        end
    end
    local closeFunc = nil
    if returnFunc then
        closeFunc = function()
            self:OnClickClose()
        end
    end
    eventList[1] = closeFunc
    eventList[2] = returnFunc
    if combatType == LCombatTypeConst.COMBAT_MAIN then
        if showNext then
            eventList[3] = function()
                self:NextMainBattle()
            end
        end
        local justShowConfirm = self:GetWndArg("justShowConfirm")
        if justShowConfirm then
            eventList[2] = nil
            eventList[3] = nil
        end
    elseif gModelTower:GetIsTowerTypeByCombatType(combatType) then
        if showNext then
            eventList[3] = function()
                self:NextTowerBattle(combatType)
            end
        end
    elseif gModelInstance:IsMainLineCombat(combatType) then
        if showNext then
            eventList[3] = function()
                self:NextMainBraveHeroBattle(combatType)
            end
        end
    elseif combatType == LCombatTypeConst.COMBAT_GUILD_BRAVE then
        eventList[3] = function()
            self:SweepGuildBrave()
        end
    elseif combatType == LCombatTypeConst.COMBAT_INVASION_BOSS then
        eventList[3] = function()
            self:SweepInvasion()
        end
        -- elseif combatType == gModelBossTower:GetBossTowerConfigRefByKey("towerFightType") then
        -- 	eventList[3]= function() self:BossTowerNextIns() end
    elseif combatType == LCombatTypeConst.COMBAT_BADGE_GAME then
        eventList[3] = function()
            self:BadgeGameNextBattle()
        end
    end

    return eventList
end

function UIOrdinResult:RefreshTypeView()
    local openType = self._openType
    if openType == UIOrdinResult.TYPE_BATTLE then
        self:ShowTypeBattle()
        -- 【G公共支持】删掉小游戏功能
        -- elseif openType == UIOrdinResult.TYPE_MINGAME then
        -- 	self:ShowTypeMinGame()
    elseif openType == UIOrdinResult.TYPE_MATCH then
        self:ShowTypeMatch()
    elseif openType == UIOrdinResult.TYPE_GM then
        self:ShowGMType()
    end

    local h = 92
    if self._resultWin and self._combatType ~= LCombatTypeConst.COMBAT_ACTIVITY_155 then
        self.mTitleBlackBg2.anchoredPosition = Vector3(0, -52, 0)
        self.mTitleBg2.anchoredPosition = Vector3(0, -52, 0)
    else
        self.mTitleBlackBg2.anchoredPosition = Vector3(0, -6, 0)
        self.mTitleBg2.anchoredPosition = Vector3(0, -6, 0)
        h = 49
    end

    local isHaveData = self:GetWndArg("isHaveData")
    if isHaveData then
        self.mTitleBlackBg2.anchoredPosition = Vector3(0, -75, 0)
        self.mTitleBg2.anchoredPosition = Vector3(0, -75, 0)

        self:ShowTypeHavePK()

        h = 140
    end

    if self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
        CS.ShowObject(self.mDescriptionContent, false)
        if self._resultWin then
            self.mCommonResult.anchoredPosition = Vector3(0, 75, 0)
        end
    end
    self.mDescriptionContent.sizeDelta = Vector2(438, h)
end
----------------------------------------------------------------------------------
-- 设置副本名称
function UIOrdinResult:SetDungeonText(textTrans, combatType)
    if textTrans and combatType then
        local dungeonName = self._titleName
        if not dungeonName then
            if combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
                local data = JSON.decode(self._combatResult.activityData)
                local activityCfg = gModelActivity:GetWebActivityDataById(data.sid)
                dungeonName = activityCfg and activityCfg.config and activityCfg.config.name or ""

                dungeonName=gModelActivity:GetLngNameById(dungeonName)
            else
                local ref = GameTable.BattleGameRef[combatType]
                if not ref then
                    printErrorN("没有 CombatGameRef refId:" .. combatType)
                    return ""
                end
                dungeonName = ccLngText(ref.name)
            end
        end

        self:SetWndText(textTrans, dungeonName)
        CS.ShowObject(textTrans, true)
    end
end

function UIOrdinResult:SetMinItemList(dataList, isDetail)
    isDetail = isDetail and true or false
    local uiRewardList = self._uiMinRewardList
    if not uiRewardList then
        uiRewardList = UIIconEasyList:New()
        self._uiMinRewardList = uiRewardList
        uiRewardList:Create(self, self.mMinItemList, nil, isDetail)
        uiRewardList:EnableLoadAnimation(false)
        uiRewardList:SetIconParentPath("Icon")
    end
    uiRewardList:RefreshList(dataList, true)
end
function UIOrdinResult:ShowWeakGuide()

    local showWeak = gModelGuide:IsBattleNodeTrigger()

    if not showWeak then
        return
    end

    local canAutoNext = gModelBattle:CanAutoNextMain()
    if not canAutoNext then
        return
    end

    local tran = self._btnTransList[1]
    local clickFunc = function()
        self:OnClickClose()

        local combatData = {
            combatType = LCombatTypeConst.COMBAT_MAIN,
            isBattleToBackground = true
        }
        gModelBattle:StartAfterSetFormation(combatData)
    end

    local text = ccLngText(gModelGuide:GetGuidePara("guideTxt"))
    GF.OpenUIGue("UIGueTip", { wndType = 3, targetTran = tran, para = { clickFunc = clickFunc, info = text } })
end

function UIOrdinResult:InitData()
    self._wndRefId = self:GetWndArg("refId")                -- 窗口的RefId
    self._other = self:GetWndArg("other")                    -- 嵌入文本参数
    self._other2 = self:GetWndArg("other2")                -- 嵌入文本参数2
    self._isFromBack = self:GetWndArg("isFromBack")       -- 后台结算
    self._showNext = self:GetWndArg("showNext")           -- 是否显示下一关
    self._combatType = self:GetWndArg("combatType")
    self._isConcealText = self:GetWndArg("isConcealText")
    self._combatResult = self:GetWndArg("combatResult")    -- 通用奖励结算
    self._isNewRecord = self:GetWndArg("isNewRecord")        -- 是否为新纪录

    self._guildData = self:GetWndArg("guildData")         -- 公会副本扫荡结果
    self._towerData = self:GetWndArg("towerData")         -- 试炼之藤逃跑
    self._invasionData = self:GetWndArg("invasionData")   -- 异界boss扫荡
    self._accWndType = self:GetWndArg("accWndType") or UIOrdinResult.NORMAl           -- 界面类型 1，普通结算，2 公会副本扫荡，3 试炼之藤逃跑
    self._titleName = self:GetWndArg("titleName")

    local _combatResult = self._combatResult
    if _combatResult then
        local refId = _combatResult.refId
        local isShowShare = self._combatType == LCombatTypeConst.COMBAT_TACTICAL_SIMULATION
        CS.ShowObject(self.mBtnShare, isShowShare)
        if isShowShare then
            self._shareRefId = refId
            self:SetWndText(self.mShareText, ccClientText(21508))
        end
    end

    if gModelBattle:ShowBattleInfoState() then
        if _combatResult then
            CS.ShowObject(self.mMvpMar, true)
            self:SetWndText(self.mMvpNameText1, ccClientText(10163))
            self:SetWndText(self.mMvpOutputText1, ccClientText(10164))
            self:SetWndText(self.mMvpBearText1, ccClientText(10165))
            self:SetWndText(self.mMvpCureText1, ccClientText(10166))
            local hero = self:GetMvpHeroData()
            local isMonster = hero.isMonster
            local name1, name2
            if isMonster then
                name1, name2 = gModelHero:GetMonsterColorName(hero.refId)
            else
                name1, name2 = gModelHero:GetHeroColorName(hero.refId, hero.star)
            end

            self:SetWndText(self.mMvpNameText2, name2)
            self:SetWndText(self.mMvpOutputText2, LUtil.NumberCoversion(tonumber(_combatResult.output)))
            self:SetWndText(self.mMvpBearText2, LUtil.NumberCoversion(tonumber(_combatResult.bear)))
            self:SetWndText(self.mMvpCureText2, LUtil.NumberCoversion(tonumber(_combatResult.cure)))
            self:SetWndText(self.mMvpKillText, LUtil.FormatHurtNumSpriteText(_combatResult.kill))
            CS.ShowObject(self.mMvpKillBg, _combatResult.kill > 0)
        end
    else
        CS.ShowObject(self.mMvpMar, false)
    end

    --self._isOutLine = false
    if self._combatResult then
        --self._isOutLine = self._combatResult.isOutLine == 1
        local combatType = self._combatResult.combatType
        if combatType then
            local reportId = self._combatResult.reportId

            local curBattle = gLFightManager:GetBattleByType(self._combatType)
            if curBattle then
                local battleReportId = curBattle:GetReportId()
                if battleReportId == reportId then
                    gLFightManager:ExitBattle(self._combatType)
                end
            end
            gModelBattle:OnCombatResultSureReq(combatType, reportId)
        end
    end

    local resultWin = true
    if self._accWndType == UIOrdinResult.NORMAl then
        if self._combatType == LCombatTypeConst.COMBAT_GUILD_BRAVE or self._combatType == LCombatTypeConst.COMBAT_TYPE_32 then
            resultWin = true
        else
            resultWin = nil
            if gModelBattle:IsEndlessCombat(self._combatType) then
                resultWin = self:GetWndArg("isWin")
            else
                resultWin = (self._combatResult.winner or 1) == 1
            end
        end
    elseif self._accWndType == UIOrdinResult.GUILD_SWEEP then
        resultWin = true
    elseif self._accWndType == UIOrdinResult.TOWER_ESCAPE then
        resultWin = true
    elseif self._accWndType == UIOrdinResult.INVASION_SWEEP then
        resultWin = true
    end
    self._resultWin = resultWin

    local desStr = ccClientText(10162)
    if resultWin or self._combatResult.combatType == LCombatTypeConst.COMBAT_SWEETCOUNTRY_BOSS then
        desStr = ccClientText(10721)
    end

    local wndRefId = self._wndRefId
    local wndData = GameTable.UIWindowAttRef[wndRefId]
    if wndData then
        if not string.isempty(wndData.title1) then
            desStr = ccLngText(wndData.title1)
        end
    end

    self:SetWndText(self.mAwardText, desStr)

    self._isShowLevel = false    --显示胜利界面的头像等级经验条?
    self._descriptionText = nil    --正文文本
    self._noRecordText = nil        --无奖励时显示文本
    self._typeSetFunc = {
        [5] = function()
            self:ShowTypeWin()
        end,
        [6] = function()
            self:ShowTypeFail()
        end,
        [7] = function()
            self:ShowTypeWinTwo()
        end,
        [8] = function()
            self:ShowTypeMopUpOrChallenge(false)
        end,
        [9] = function()
            self:ShowTypeMopUpOrChallenge(true)
        end,
        [10] = function()
            self:ShowNewRecordType()
        end,
        [11] = function()
            self:ShowNoGotoListType()
        end,
    }

    self:SetWndText(self.mBattleDataText, ccClientText(17000))
    self:SetWndText(self.mBackPlayText, ccClientText(17001))
    self:SetWndText(self.mCloseTip, ccClientText(17003))
    self:SetWndText(self.mShareBtnText, ccClientText(21508))

    if self._combatType == LCombatTypeConst.COMBAT_PK then
        CS.ShowObject(self.mShareBtn, true)
        self:SetWndClick(self.mShareBtn, function()
            self:OnShareBtnClick()
        end)
    else
        CS.ShowObject(self.mShareBtn, false)
    end
end

function UIOrdinResult:OnDrawGoto(list, item, itemdata, itempos)
    local Bg = self:FindWndTrans(item, "Bg")
    --local BgBgIcon = self:FindWndTrans(Bg,"BgIcon")
    local BgIcon = self:FindWndTrans(Bg, "icon")
    local BgDesc = self:FindWndTrans(Bg, "desc")

    local name = itemdata.name
    local icon = itemdata.icon
    local origin = itemdata.origin

    self:SetWndText(BgDesc, ccLngText(name))
    self:SetWndEasyImage(BgIcon, icon)
    -- self:SetWndText(gotoText, ccClientText(10907))

    self:SetWndClick(item, function()
        local isOpen = gModelFunctionOpen:CheckIsOpened(origin, true)
        if isOpen then
            self._isClickRet = true
            self:OnClickClose()
            gModelFunctionOpen:Jump(origin)
        end
    end, LSoundConst.CLICK_BUTTON_COMMON)
end

function UIOrdinResult:ShowTypeMatch()
    local data = self:GetWndArg("data")
    self._wndRefId = self:GetWndArg("refId")                -- 窗口的RefId
    local isWin = data.win == 1

    self:InitRefData()

    self:SetWndText(self.mDescriptionText, self._descriptionText)

    CS.ShowObject(self.mBackPlay, false)
    CS.ShowObject(self.mBattleData, false)
    CS.ShowObject(self.mPlayerLevel, false)
    local str = "惊梦冒险"
    self:SetWndText(self.mDungeonText, str)
    if isWin then
        self:ShowMatchWin()
    else
        self:ShowMatchFail()
    end

    -- 【C宠物系统】删掉宠物系统相关
    -- self:ShowMatchMvp(isWin)
    -- local petInfo = data.mvpPet

    if gModelBattle:ShowBattleInfoState() then
        local para = {
            -- name = gModelPetSpace:GetColorPetName(petInfo),
            mvpOutput = data.mvpOutput,
            mvpBear = data.mvpBear,
            mvpCure = data.mvpCure,
            mvpKill = data.mvpKill,
        }

        self:ShowCountPanel(para)
    else

        CS.ShowObject(self.mMvpMar, false)
    end
end

function UIOrdinResult:GetShowItemListImpl(itemList, rewardInfo)
    local rewardList = {}
    if rewardInfo ~= nil then
        local thingsDetail = gModelGeneral:GetThingsDetailInfoByPb(rewardInfo)
        if thingsDetail then
            local rewardNum = thingsDetail:GetThingsDetailRewardNum()
            if rewardNum > 0 then
                rewardList = thingsDetail:GetThingsDetailAllRewardList() or {}
            end
        end
    end
    local rewardLen = #rewardList
    local isUseDetailInfo = rewardLen > 0
    if rewardLen < 1 then
        local dataList = {}
        for k, v in ipairs(itemList) do
            local itemId = v.itemId or v.refId
            if not dataList[itemId] then
                if v.type == LItemTypeConst.TYPE_ITEM or v.type == LItemTypeConst.TYPE_HERO
                        or v.type == LItemTypeConst.TYPE_OUTFIT then
                    dataList[itemId] = {
                        itemId = v.itemId or v.refId,
                        itemNum = tonumber(v.count) or tonumber(v.itemNum),
                        itemType = v.type or v.itemType,
                        detail = false
                    }
                end
            else
                local oldNum = dataList[itemId].itemNum
                dataList[itemId].itemNum = oldNum + (tonumber(v.count) or tonumber(v.itemNum))
            end
        end

        for k, v in pairs(dataList) do
            table.insert(rewardList, v)
        end
    end

    return rewardList, isUseDetailInfo
end

function UIOrdinResult:OnTcpReconnect()
    --- 爬塔活动断线重连标识，返回界面活动界面即可
    self._isTcpReconnect = true
end

-- mvp英雄立绘缩放动画
function UIOrdinResult:HeroAnimaition()
    self:StopHeroTween()
    local tween = Tweening.DOTween.Sequence()
    self._heroTweem = tween

    local Tween1 = self.mHeroDrawing:DOScale(Vector3(1.1, 1.1, 1.1), 0.4):SetEase(EaseOutCubic)
    tween:Append(Tween1)
    local Tween2 = self.mHeroDrawing:DOScale(Vector3(1, 1, 1), 0.001):SetEase(EaseOutCubic)
    tween:Append(Tween2)

    tween:Play()
end

function UIOrdinResult:ExecuteBackPress()
    local eventList = self:GetClickEventListImpl()
    local func = eventList[1]
    if func then
        func()
    end
end

------------------------ ShowTypeBattle ------------------------


--region ShowTypeHavePK --------------------------------------------------------------------------------
function UIOrdinResult:ShowTypeHavePK()
    --相关控件的显隐
    CS.ShowObject(self.mDescriptionContent, false)
    CS.ShowObject(self.mPkInfo, true)

    local isWin = self:GetWndArg("isWin")

    if not isWin then
        CS.ShowObject(self.mPkInfo, false)
        CS.ShowObject(self.mNoRecord, false)
        self.mTitleBlackBg2.anchoredPosition = Vector3(0, 15, 0)
        self.mTitleBg2.anchoredPosition = Vector3(0, 15, 0)
        self.mCommonResult.anchoredPosition = Vector3(0, 60, 0)
        return
    end


    --星星的设置
    self:SetWndText(self.mPkRewardTxt, self._descriptionText)
    local starCount = self:GetWndArg("star")
    for i = 1, 3 do
        local starKey = "Star_" .. i
        local starTran = CS.FindTrans(self.mStarRoot, starKey)

        local isShow = false
        if starCount then
            isShow = i <= starCount
        end
        CS.ShowObject(starTran, isShow)
    end

    --人物信息的设置
    --进攻部分
    local attack = self:GetWndArg("attack")

    local isRobot = self:GetWndArg("isRobot")
    local defense

    self:SetPkInfo(self.mAttackDiv, attack)
    if isRobot then
        local robotInfo = self:GetWndArg("robotInfo")

        local IconBg = CS.FindTrans(self.mDefenseDiv, "HeadIcon/IconBg")
        local Icon = CS.FindTrans(IconBg, "Icon")

        self:SetWndEasyImage(Icon, robotInfo.headIcon)

        local NameTran = CS.FindTrans(self.mDefenseDiv, "Name")
        self:SetWndText(NameTran, robotInfo.name)
    else
        --防御部分
        defense = self:GetWndArg("defense")

        self:SetPkInfo(self.mDefenseDiv, defense)
    end

end

function UIOrdinResult:StartTween()
    self:StopPlayerTween()
    --local totalExp = 0
    --for k,v in pairs(self._combatResult.itemList) do
    --	if v.itemId == 103001 then           --获取战报结果中的角色经验
    --		totalExp = tonumber(v.count)
    --		break
    --	end
    --end

    local tweenDataList = {}

    local lvInfo = self._combatResult.playerLevelExpChange
    --local playerInfo = gModelBattle:GetCurPlayerInfo(self._combatType)
    --if not playerInfo then
    --	return false
    --end

    gModelPlayer:onPlayerLvChange(lvInfo)

    local curLv = lvInfo.oldLevel
    local curExp = lvInfo.oldExp

    local nextLv = lvInfo.newLevel
    local nextExp = lvInfo.newExp
    local curLvExpNeed = gModelPlayer:GetLevelExpNeed(curLv)

    local level = curLv

    while level <= nextLv do
        local startProgress = 0
        local endProgress = 0
        if level == curLv then
            startProgress = curExp / curLvExpNeed
        end
        local data = {}
        data.lv = level
        if level < nextLv then
            endProgress = 1
        elseif level == nextLv then
            local curLevelExpNeed = gModelPlayer:GetLevelExpNeed(level)
            endProgress = nextExp / curLevelExpNeed
        end

        data.startP = startProgress
        data.endP = endProgress

        table.insert(tweenDataList, data)

        level = level + 1
    end

    local duration = 2

    local totalLen = 0
    for k, v in ipairs(tweenDataList) do
        totalLen = totalLen + v.endP - v.startP
    end
    if totalLen <= 0 then
        return false
    end
    local perLenTime = duration / totalLen

    local first = tweenDataList[1]
    if first then
        self:ShowPlayerLvAndExp(first.lv, first.startP)
    end

    self._playerSeq = Tweening.DOTween.Sequence()
    for k, v in ipairs(tweenDataList) do
        local time = (v.endP - v.startP) * perLenTime
        local lv = v.lv
        local tweener = YXTween.TweenFloat(v.startP, v.endP, time, function(t)
            self:ShowPlayerLvAndExp(lv, t)
        end)
        self._playerSeq:Append(tweener)
    end

    self._playerSeq:SetAutoKill(true)
    self._playerSeq:PlayForward()
    return true
end

function UIOrdinResult:GotoNextMain()
    FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.ADVENTURE })
    gModelInstance:GotoChallenge()
end

-- 【G公共支持】删掉小游戏功能
-- function UIOrdinResult:InitMinGameData()
-- 	self._wndTipsRefId = self:GetWndArg("wndTipsRefId")
-- 	self._rewardList = self:GetWndArg("rewardList")
-- 	self._gameStatus = self:GetWndArg("gameStatus")
-- end

-- function UIOrdinResult:ShowTypeMinGameWndByData()
-- 	local wndRefId = self._wndTipsRefId
-- 	local wndData = GameTable.UIWindowAttRef[wndRefId]
-- 	if not wndData then
-- 		LogError("默认窗口类型为10001，没有配置该窗口的类型的数据:"..wndRefId)
-- 		wndData = GameTable.UIWindowAttRef[10001]
-- 	end
-- 	self._wndData = wndData

-- 	local title = wndData.title
-- 	self:SetWndText(self.mDungeonText,ccLngText(title))

-- 	local btnPng = wndData.btnPng
-- 	local pngStr = string.split(btnPng,"|")
-- 	self._btnImgPaths = pngStr

-- 	local btnTxt = wndData.btnTxt
-- 	btnTxt = ccLngText(btnTxt)
-- 	local strs = string.split(btnTxt,"|")
-- 	self._btnStrs = strs

-- 	-- 正文文本:配置level显示角色头像和等级、进度条,配置其他文本显示文本（不显示头像等级）
-- 	local text = wndData.text
-- 	text = ccLngText(text)
-- 	self._descriptionText = text

-- 	-- 无奖励时显示文本:读取配置Text2的描述，为空时，显示默认图片
-- 	local text2 = wndData.text2
-- 	text2 = ccLngText(text2)
-- 	self._noRecordText = text2

-- 	local startCountDowns = LxDataHelper.ParseNumber_Sign(wndData.startCountDown,"|")
-- 	local countDowns = LxDataHelper.ParseNumber_Sign(wndData.countdown,'|')

-- 	self._countDownDataList = {}
-- 	self._btnClickList = {}

-- 	local bNeedTimer = false
-- 	for k=1,3 do
-- 		local buttonCd = startCountDowns[k] or 0
-- 		local tipsCd = countDowns[k] or 0
-- 		if buttonCd > 0 then
-- 			self._btnClickList[k] = false
-- 		end
-- 		if buttonCd > 0 or tipsCd > 0 then
-- 			self._countDownDataList[k] = {buttonCd = buttonCd, buttonTime = buttonCd, isButtonOk = buttonCd <= 0, tipsCd = tipsCd, tipsTime = tipsCd}
-- 			bNeedTimer = true
-- 		end
-- 	end

-- 	if bNeedTimer then self:TimerStart(self._countDownKey,1,false,-1) end

-- 	self:SetButton(self.mBottomBtn)
-- end

-- function UIOrdinResult:GetMinGameHeroRef()
-- 	local isWin = self._gameStatus == UIOrdinResult.MINGAME_TYPE_SUCCESS
-- 	local spineKey = isWin and "win" or "lose"
-- 	local heroEffectId = gModelMinGame:GetMinGameConfigRefByKey(spineKey)
-- 	local showEffect = gModelHero:GetShowEffectById(heroEffectId)
-- 	return showEffect
-- end

-- function UIOrdinResult:ShowMinGameHero()
-- 	self:ShowMvpHero(self._gameStatus == UIOrdinResult.MINGAME_TYPE_SUCCESS)
-- end

-- function UIOrdinResult:ShowRewardList()
-- 	local resultDataList = self._rewardList or {}
-- 	local itemNum = #resultDataList;
-- 	local isEmpty = itemNum == 0
-- 	CS.ShowObject(self.mNoRecord,isEmpty and not self._noRecordText)
-- 	if isEmpty then
-- 		self:SetWndText(self.mNoRecordText,ccClientText(21038))
-- 		return
-- 	end
-- 	CS.ShowObject(self.mWinWnd,not isEmpty)
-- 	local isShowMin = itemNum <= 5
-- 	CS.ShowObject(self.mMinItemList, isShowMin)
-- 	CS.ShowObject(self.mItemList, not isShowMin)
-- 	if isShowMin then
-- 		self:SetMinItemList(resultDataList)
-- 	else
-- 		self:SetItemList(resultDataList)
-- 	end
-- end

-- function UIOrdinResult:RefreshMinGameView()
-- 	CS.ShowObject(self.mBackPlay,false)
-- 	CS.ShowObject(self.mBattleData,false)
-- 	CS.ShowObject(self.mPlayerLevel,false)
-- 	self:SetText(self.mDescriptionText)

-- 	local desStr = ccClientText(10721)
-- 	self:SetWndText(self.mAwardText,desStr)

-- 	self:ShowTitleEff(self._gameStatus == UIOrdinResult.MINGAME_TYPE_SUCCESS)
-- 	self:ShowRewardList()
-- 	self:SetNoRecordText()
-- 	self:ShowMinGameHero()
-- end

function UIOrdinResult:ShowGMType()
    local btnObj = self:GetBtnByName("public_btn_1_3")
    if btnObj then
        local btn = btnObj.transform
        CS.ShowObject(btn, true)
        CS.SetParentTrans(btn, self.mBottomBtn)
        self:SetWndClick(btn, function()
            local gmCb = self:GetWndArg("gmCb")
            if gmCb then
                gmCb()
            end
            self:WndClose()
        end)
    end

    local heroEffectId = self:GetWndArg("heroEffectId")
    local heroShowRef = gModelHero:GetShowEffectById(heroEffectId)
    if not heroShowRef then
        return
    end

    self:LoadMVPHeroDrawing(self.mHeroDrawing, heroShowRef.heroDrawing, self.mQuotationsText, heroShowRef.descriptionVictory, heroShowRef.rankingId, heroShowRef)
end

function UIOrdinResult:GetCombatType()
    return self:GetWndArg("combatType")
end

function UIOrdinResult:OnTimer(key)
    if key == self._countDownKey then
        self:SetCountDown()
    elseif key == self._heroQuotations then
        CS.ShowObject(self.mHeroQuotations, true)
    end
end

-----------------------------------公会扫荡,挑战结束窗口----------------------------
function UIOrdinResult:GetMvpHeroRef()
    local hero = self:GetMvpHeroData()
    if not hero then
        return
    end

    local heroEffectId
    if hero.skin and hero.skin > 0 then
        --英雄皮肤
        heroEffectId = hero.skin
    else
        local heroRefId = hero.refId
        if hero.isMonster then
            local monsterRef = gModelHero:GetMonsterAttrByRefId(heroRefId)
            heroEffectId = monsterRef.effectId
        else
            local heroRef = gModelHero:GetHeroRef(heroRefId)
            if not heroRef then
                printErrorN("英雄不存在 refId" .. tostring(heroRefId))
                return
            end
            local starRef = gModelHero:GetHeroStarRef(heroRefId, hero.form, hero.star)
            heroEffectId = starRef.effectId
        end
    end
    local showEffect = gModelHero:GetShowEffectById(heroEffectId)
    return showEffect
end

function UIOrdinResult:ShowMvpHero(isSuc)
    local heroShowRef
    local openType = self._openType
    if openType == UIOrdinResult.TYPE_BATTLE then
        heroShowRef = self:GetMvpHeroRef()
        -- 【G公共支持】删掉小游戏功能
        -- elseif openType == UIOrdinResult.TYPE_MINGAME then
        -- 	heroShowRef = self:GetMinGameHeroRef()
    end
    if not heroShowRef then
        return
    end
    if PRODUCT_G_VER ~= 0 then
        return
    end
    local heroType = heroShowRef.heroType
    gModelHero:PlayHeroRoleSound(heroType, heroShowRef.refId)
    local drawing = heroShowRef.heroDrawing
    local saying = nil
    if isSuc then
        saying = ccLngText(heroShowRef.descriptionVictory)
    else
        saying = ccLngText(heroShowRef.descriptionFail)
    end
    self:LoadMVPHeroDrawing(self.mHeroDrawing, drawing, self.mQuotationsText, saying, heroShowRef.rankingId, heroShowRef)
end

function UIOrdinResult:OnClickButton(index, func)
    local countDownData = self._countDownDataList[index]
    if countDownData and not countDownData.isButtonOk and not self._btnClickList[index] then
        local time = countDownData.buttonTime
        if time > 0 then
            local str = string.replace(ccClientText(10114), time)
            GF.ShowMessage(str)
            return
        end
    end

    if func then
        func()
    end
end

------------------------------------------------------------------
return UIOrdinResult