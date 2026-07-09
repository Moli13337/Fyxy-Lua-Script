---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIringRk:LWnd
local UIringRk = LxWndClass("UIringRk", LWnd)
local typeOfScrollRect = typeof(UnityEngine.UI.ScrollRect)
local typeOfRectTransform = typeof(UnityEngine.RectTransform)
local typeofYXUIStateActor = typeof(CS.YXUIStateActor)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIringRk:UIringRk()
    self:SetHideHurdle()
    self._headIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIringRk:OnWndClose()
    --self:ModifyMainUI(1)
    if self._seqCom then
        self._seqCom:Destroy()
        self._seqCom = nil
    end
    self:ClearCommonIconList(self._headIconList)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIringRk:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

    self._seqCom = SequenceCom:New()
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIringRk:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitData()
    self:InitList()
    self:SetStaticContent()

    self:WndNetMsgRecv(LProtoIds.PlayerArenaResp, function(...)
        self:OnPlayerArenaResp(...)
        --self:RefreshCost()
    end)
    if not gModelArena:OnPlayerArenaReq() then
        self:InitBoxList()
        self:StarCountDown()
        self:SetSelfPlayer()
    end

    CS.ShowObject(self.mChanllengeList, false)

    if not gModelArena:OnArenaMatchReq(false) then
        self:RefreshChallengeList()
    end
    self:WndNetMsgRecv(LProtoIds.ArenaMatchResp, function(...)
        self:OnArenaMatchResp(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ReceiveArenaRewardResp, function(...)
        self:OnReceiveArenaRewardResp(...)
    end)

    self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP, function(...)
        self:WndClose()
    end)

    self:WndEventRecv(EventNames.ON_GET_FORMATION_RET, function()
        self:RefreshChallengeList()
    end)
    self:WndNetMsgRecv(LProtoIds.RankResp, function(...) self:SetRankTopThree(...) end)
	self:WndNetMsgRecv(LProtoIds.PlayerLikeResp, function(...) gModelRank:OnRankReq(2, 4, 1, 25) end)

    self:InitUIEvent()

    self:StartCooling()

    local formation = gModelFormation:GetFormation(LCombatTypeConst.COMBAT_ARENA_ATTACK)
    if not formation then
        gModelFormation:OnGetFormationReq(LCombatTypeConst.COMBAT_ARENA_ATTACK)
    end
    self:ShowActivityPrivilege()
    gModelRank:OnRankReq(2, 4, 1, 25) --排行榜请求
    
    self:RefreshForeign()
end

function UIringRk:InitUIEvent()
    self:SetWndClick(self.mBackBtn, function()

        local backFunc = self:GetWndArg("backFunc")
        local isFromJump = self:GetWndArg("isFromJump")
        if not self:WndCloseAndBack() then
            if backFunc then
                backFunc()
                -- 【G公共支持】删除跨服天梯和跨服周冠玩法
                -- else
                -- 	if not isFromJump then
                -- 		gModelCrossServer:OpenUIring()
                -- 	end
            end
        else
            GF.OpenWndBottom("UIOutts", { childIndex = 2 })
        end


    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mHelpBtn, function()
        self:ShowHelp()
    end, LSoundConst.CLICK_ERROR_COMMON)

    self:SetWndClick(self.mTickets, function()
        gModelGeneral:OpenGetWayWnd({ itemId = 100100, srcWnd = self:GetWndName() })
    end, LSoundConst.CLICK_BUTTON_COMMON)

    self:SetWndClick(self.mRefreshBtn, function()
        self:OnClickRefreshBtn()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    local isSkip = gModelArena:GetIsSkipChecked()
    self:SetWndToggleValue(self.mSkipBattle, isSkip)
    self:SetWndToggleDelegate(self.mSkipBattle, function(value)
        local isSuc = gModelArena:SetIsSkipChecked(value, true)
        if not isSuc then
            self:SetWndToggleValue(self.mSkipBattle, not value)
        end
    end)

    isSkip = gModelArena:IsSkipPrepare()
    self:SetWndToggleValue(self.mSkipPrepare, isSkip)
    self:SetWndToggleDelegate(self.mSkipPrepare, function(value)
        local isSuc = gModelArena:SetSkipPrepare(value)
        if not isSuc then
            self:SetWndToggleValue(self.mSkipPrepare, not value)
        end
    end)

    self:SetWndClick(self.mDefendBtn, function()
        self:OpenDefendArray()
    end)

end

function UIringRk:OpenChildWnd(index)

    local wndName = self._wndList[index].wndName
    local wndPara = self._wndList[index].para
    if not wndName then
        return
    end

    if index == 2 then
        local rewardList1 = {}
        local rewardList2 = {}
        local rewardList = gModelArena:GetRankRewardConfig()
        for k, v in pairs(rewardList) do
            local cfg = gModelArena:GetRankAwardRefT(v.refId)
            local rankT = cfg.rankT
            local rank = { rankT.left, rankT.right }
            local itemdata = {
                index = k,
                rank = rank,
                reward = cfg.dailyRewardT,
            }

            local itemdata2 = {
                index = k,
                rank = rank,
                reward = cfg.seasonRewardT,
            }
            table.insert(rewardList1, itemdata)
            table.insert(rewardList2, itemdata2)
        end

        table.sort(rewardList1, function(a, b)
            return a.index < b.index
        end)
        table.sort(rewardList2, function(a, b)
            return a.index < b.index
        end)
        wndPara.rewardList = rewardList1
        wndPara.rewardList2 = rewardList2
    end

    if index == 1 then
        GF.OpenWnd(wndName, wndPara)
    else
        GF.OpenWndBottom(wndName, wndPara)
    end
end

function UIringRk:InitList()
    self._bottomBtnList = {
        self.mBottomBtn_1,
        self.mBottomBtn_2,
        self.mBottomBtn_3,
    }
    self._boxIconAtlas = ""

    self._wndList = {
        { wndName = "UIringRecord" },
        { wndName = "UIRkPop", para = { refId = ModelRank.RANK_ARENA_LEADER, } }, --{wndName="UIringLeaderBoard"}, {wndName="UIringRkAward"},
        { wndName = "UIDian", para = { shopId = 2003 } },
    }
    self._bottomBtnTextList = {
        10359,
        10372,
        10362,
    }
    self._bottomFuncList = {
        function()
            self:OpenChildWnd(1)
        end,
        function()
            self:OpenChildWnd(2)
        end,
        function()
            self:OpenChildWnd(3)
        end,
    }

    self._playerList = {
        self.mPlayer_1,
        self.mPlayer_2,
        self.mPlayer_3,
    }

    self._boxItemDataList = {}
end

function UIringRk:SetPlayerInfo(item, playerData)
    local bg = self:FindWndTrans(item, "bg")
    local rankBg = self:FindWndTrans(item, "rankBg")
    local rankBgUIText = self:FindWndTrans(rankBg, "UIText")
    local name = self:FindWndTrans(item, "name")
    local challengeBtn = self:FindWndTrans(item, "challengeBtn")
    local challengeBtnText = self:FindWndTrans(challengeBtn, "text")
    -- local power = self:FindWndTrans(item, "power")
    -- local powerIcon = self:FindWndTrans(power, "Icon")
    local powerText = self:FindWndTrans(item, "PowerBg/PowerText")
    local score = self:FindWndTrans(item, "score")
    local layout = self:FindWndTrans(item, "layout")
    local layoutIcon = self:FindWndTrans(layout, "icon")
    local layoutText = self:FindWndTrans(layout, "text")
    local freeText = self:FindWndTrans(item, "FreeText")

    local headIconTran = self:FindWndTrans(item, "HeadIcon")

    local Image_Title_Bg = self:FindWndTrans(item, "Image_Title_Bg")

    if self._isEnus then
        Image_Title_Bg.sizeDelta = Vector2.New(450,30)
    end

    local nameFinal = playerData.name
    if playerData.isSameGuild then
        nameFinal = nameFinal .. ccClientText(10334) --(同公会)
    end

    if self._isEnus then
        nameFinal="  "..nameFinal
    end

    self:SetWndText(name, nameFinal)
    self:SetWndText(score, playerData.score)

    local color = "yellow_2"
    local selfPower = gModelPower:GetFormationPower(LCombatTypeConst.COMBAT_ARENA_ATTACK)
    if playerData.power > selfPower then
        color = "red"
    end

    local powerValueStr = LUtil.PowerNumberCoversion(playerData.power)
    --local powerStr= LUtil.FormatColorStr(powerValueStr,color)
    --self:SetWndText(powerText, powerValueStr)
    self:SetWndText(powerText, powerValueStr)
    local rankStr = tostring(playerData.rank)
    if playerData.rank <= 0 then
        rankStr = ccClientText(10363)

          rankStr = string.format("<color=#FFA1B0>%s</color>",rankStr)
    end
    self:SetWndText(rankBgUIText, rankStr)

    -- 等级
    self:SetWndClick(challengeBtn, playerData.func, LSoundConst.CLICK_BUTTON_COMMON)

    local instanceId = item:GetInstanceID()
    local headIcon = self._headIconList[instanceId]
    if not headIcon then
        headIcon = HeadIcon:New(self)
        self._headIconList[instanceId] = headIcon
    end

    local headData = {
        trans = headIconTran,
        icon = playerData.head,
        headFrame = playerData.frame,
        name = playerData.name,
        level = playerData.level,
    }
    headIcon:SetHeadData(headData)
    headIcon:RefreshUI()

    self:SetWndClick(headIconTran, function()
        if (playerData.playerId == gModelPlayer:GetPlayerId()) then
            GF.ShowMessage(ccClientText(11522))
            return
        end
        gModelGeneral:PlayerShowReq(playerData.playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
    end)

    local ticketId = gModelArena:GetArenaPara("TciketId")
    local icon, iconBg = gModelItem:GetItemImgByRefId(ticketId)
    if icon then
        self:SetWndEasyImage(layoutIcon, icon)
    end
    self:SetWndClick(bg, function()
        self:ShowChallengeTipWnd(playerData)
    end)

    local canFreeChallenge = gModelArena:CanFreeChallenge()
    CS.ShowObject(layout, not canFreeChallenge)

    local isShowFree = false
    if canFreeChallenge then
        local freeCombatCount = gModelArena:GetFreeCombatCount()
        local configFreeCount = gModelArena:GetConfigFreeCombatCount()
        local freeStr = string.replace(ccClientText(10382), freeCombatCount)
        if freeCombatCount > configFreeCount then
            freeStr = string.replace(ccClientText(10374), freeCombatCount - configFreeCount)
        end
        isShowFree = true
        self:SetWndText(freeText, freeStr)
    end
    CS.ShowObject(freeText, isShowFree)

    local str = nil
    if canFreeChallenge then
        str = ccClientText(10313)
    else
        str = ccClientText(10335)
    end
    local num = gModelArena:GetArenaPara("TicketNum")

    self:SetWndText(layoutText, num)

    self:SetWndText(challengeBtnText, str)

    self:InitTextLineWithLanguage(challengeBtnText, -40)

end

function UIringRk:InitBoxList()
    local boxCfg = gModelArena:GetBoxConfig()
    local stageCnt = #boxCfg

    local challengeTimes = gModelArena:GetSeasonChallengeTimes()
    --local colorStr = LUtil.FormatColorStr(challengeTimes,"green")
    local str = string.replace(ccClientText(10309), challengeTimes)
    self:SetWndText(self.mInfoText, str)
    self:SetWndText(self.mChallengeTimes, challengeTimes)

    local curStage = 0
    for i = 1, stageCnt do
        if challengeTimes < boxCfg[i].times then
            break
        end
        curStage = i
    end
    local progress = 0
    if curStage == stageCnt then
        progress = 1
    else
        local startTimes = curStage == 0 and 0 or boxCfg[curStage].times
        local endTimes = boxCfg[curStage + 1].times
        progress = curStage / stageCnt + (challengeTimes - startTimes) / (endTimes - startTimes) / stageCnt
    end
    LxUiHelper.SetProgress(self.mSlider, progress)

    --self:UIProgressFind(self.mSlider,self._sliderKey,progress)

    local scrollContent = self.mBoxList:Find("content")
    local itemTemp = self.mBoxList:Find("ItemTemplate")
    local itemRoot = scrollContent:Find("ItemRoot")
    CS.ShowObject(itemTemp.gameObject, false)
    if not self._boxItemList then
        self._boxItemList = {}
        for i = 1, stageCnt do
            local itemNew = LxResUtil.NewObject(itemTemp.gameObject)
            table.insert(self._boxItemList, itemNew.transform)
            itemNew.transform:SetParent(itemRoot.transform, false)
            itemNew.name = string.format("item{%d}", i)
            CS.ShowObject(itemNew, true)
        end
    end

    local boxGetData = gModelArena:GetBoxGetRecord()

    local isGetList = {}
    for k, v in ipairs(boxGetData) do
        isGetList[v] = true
    end

    local boxDataList = {}
    local curCanGet = nil
    for i = 1, stageCnt do
        local cfg = boxCfg[i]
        local refId = cfg.refId
        local isGet = isGetList[refId]
        local canGet = not isGet and gModelArena:GetSeasonChallengeTimes() >= cfg.times
        if canGet and not curCanGet then
            curCanGet = i
        end

        local parsedCfg = gModelArena:GetSeasonBoxRefT(refId)
        local boxData = {
            refId = refId,
            times = cfg.times,
            isGet = isGet,
            canGet = canGet,
            icon = cfg.icon,
            itemList = parsedCfg.rewardT,
            func = function()
                self:OnClickBox(refId)
            end
        }
        table.insert(boxDataList, boxData)
    end
    table.sort(boxDataList, function(a, b)
        return a.refId < b.refId
    end)

    for k, v in ipairs(self._boxEffKeyList) do
        self:DestroyWndEffectByKey(v)
    end

    for i = 1, stageCnt do
        self:OnDrawItem(self._boxItemList[i], boxDataList[i])
    end
    if curCanGet then
        self._delayUpdateScrollTimer = LxTimer.DelayFrameCall(function()
            self:ScrollBoxCenter(curCanGet, stageCnt)
        end, 1)
    end

end

function UIringRk:StarCountDown()
    self:SetCountDownText()
    self:TimerStop(self._rankingCountDown)
    self:TimerStart(self._rankingCountDown, 1, false, -1)
end

function UIringRk:RefreshForeign()
    if self._isVie then
        local text =CS.FindTrans(self.mDefendBtn,"text")
        self:InitTextLineWithLanguage(text,0)
        LxUiHelper.SetSizeWithCurAnchor(text,0, 90)
        text =CS.FindTrans(self.mBottomBtn_1,"text")
        self:InitTextLineWithLanguage(text,0)
        LxUiHelper.SetSizeWithCurAnchor(text,0, 90)
        text =CS.FindTrans(self.mBottomBtn_2,"text")
        self:InitTextLineWithLanguage(text,0)
        LxUiHelper.SetSizeWithCurAnchor(text,0, 90)
        text =CS.FindTrans(self.mBottomBtn_3,"text")
        self:InitTextLineWithLanguage(text,0)
        LxUiHelper.SetSizeWithCurAnchor(text,0, 90)
    end
end

function UIringRk:OnTimer(key)
    if self._rankingCountDown == key then
        self:SetCountDownText()
    elseif self._refreshCooling == key then
        self:SetRefreshCd()
    end
end

function UIringRk:OnReceiveArenaRewardResp(pb, ret)

    local rewardId = pb.rewardId
    local boxItemData = self._boxItemDataList[rewardId]
    if boxItemData then
        boxItemData[2].isGet = true
        boxItemData[2].canGet = false
    end
    self:OnDrawItem(boxItemData[1], boxItemData[2])

    local boxCfg = gModelArena:GetBoxConfig()
    local stageCnt = #boxCfg
    local boxGetData = gModelArena:GetBoxGetRecord()

    local isGetList = {}
    for k, v in pairs(boxGetData) do
        isGetList[v] = true
    end

    local curCanGet = nil
    for i = 1, stageCnt do
        local cfg = boxCfg[i]
        local refId = cfg.refId
        local isGet = isGetList[refId]
        local canGet = not isGet and gModelArena:GetSeasonChallengeTimes() >= cfg.times
        if canGet and not curCanGet then
            curCanGet = i
            break
        end
    end
    if curCanGet then
        self._delayUpdateScrollTimer = LxTimer.DelayFrameCall(function()
            self:ScrollBoxCenter(curCanGet, stageCnt)
        end, 1)
    end

end

function UIringRk:OnClickRefreshBtn()
    printInfoN("mRefreshBtn")
    --local endCd = gModelArena:GetRefreshCdEnd()
    if self._isCooling then
        GF.ShowMessage(string.replace(ccClientText(12038), self._refreshTimeLeft))
        return
    end
    self._isCooling = true
    local cd = gModelArena:GetArenaPara("RefreshCd")
    local cdEnd = GetTimestamp() + cd
    gModelArena:SetRefreshCdEnd(cdEnd)
    self:StartCooling()
    --reqRefresh
    gModelArena:OnArenaMatchReq(true)
end

function UIringRk:OnArenaMatchResp(...)
    self:RefreshChallengeList()
    self:SendGuideReadyEvent(self:GetWndName())

    gModelRank:OnRankReq(2, 4, 1, 25) --排行榜请求
end

function UIringRk:ShowActivityPrivilege()
    local freePrivileNum = 0

    local dataList = gModelActivity:GetActPrivilegeList("privilegeShow5")
    for k, v in ipairs(dataList) do
        local ref = gModelGeneral:GetSysEffectRef(v)
        local effectValue = ref.effectValue
        freePrivileNum = freePrivileNum + tonumber(effectValue)
    end

    --local privilegeShowId = gModelActivity:GetActivityPrivilegeById("privilegeShow5")
    --if not string.isempty(privilegeShowId)then
    --	local ids = string.split(tostring(privilegeShowId),"|")
    --	for i, v in ipairs(ids) do
    --		local ref = gModelGeneral:GetSysEffectRef(tonumber(v))
    --		local effectValue = ref.effectValue
    --		freePrivileNum = freePrivileNum + tonumber(effectValue)
    --	end
    --end
    if freePrivileNum > 0 then
        local para = {
            title = ccClientText(10380),
            desc = string.replace(ccClientText(10373), freePrivileNum),
            icon = "activity_spring3_icon_1",
        }
        local priviCom = self:GetActivityPrivilegeCom()
        priviCom:Create(self.mBtnPrivile, para, self)
    end
end

function UIringRk:OpenDefendArray()
    local para = {
        setTargetType = LCombatTypeConst.COMBAT_ARENA_DEFEND,
        returnFunc = function()
            FireEvent(EventNames.CHANGE_MAIN_BTN, LMainBtnIndexConst.OUTSKIRTS)
            GF.ChangeMap("LCityMap")
            GF.OpenWndBottom("UIringRk")
        end,
        retAfterSet = true,
    }
    gModelFormation:OpenSetFormationWnd(para)
    self:WndClose()
end

function UIringRk:SetRankTopThree(pb)
	if pb.infos then
		for i = 1, 3 do
			if pb.infos[i] then
				self:SetRankTrans(self["mRank" .. i], pb.infos[i])
            else
                self:SetRankTrans(self["mRank" .. i])
			end
		end
	end
end

function UIringRk:OnTryTcpReconnect()
    local formation = gModelFormation:GetFormation(LCombatTypeConst.COMBAT_ARENA_ATTACK)
    if not formation then
        gModelFormation:OnGetFormationReq(LCombatTypeConst.COMBAT_ARENA_ATTACK)
    end
end

function UIringRk:SetStaticContent()
    self:SetWndText(self.mTitle, ccClientText(10301))
    for k, v in pairs(self._bottomBtnList) do
        local text = self:FindWndTrans(v, "text")
        self:SetWndText(text, ccClientText(self._bottomBtnTextList[k]))
        self:InitTextLineWithLanguage(text, -50)
        self:SetWndClick(v, self._bottomFuncList[k], LSoundConst.CLICK_PAGE_COMMON)
    end

    local defentText = self:FindWndTrans(self.mDefendBtn, "text")
    self:SetWndText(defentText, ccClientText(10358))

    local ticketId = gModelArena:GetArenaPara("TciketId")
    local icon, iconBg = gModelItem:GetItemImgByRefId(ticketId)
    if icon then
        self:SetWndEasyImage(self.mTicketIcon, icon)
    end

    local num = gModelItem:GetNumByRefId(ticketId)
    self:SetWndText(self.mTicketNum, num)
    self:WndEventRecv(EventNames.On_Item_Change, function()
        local num = gModelItem:GetNumByRefId(ticketId)
        self:SetWndText(self.mTicketNum, num)
    end)

    local text = self:FindWndTrans(self.mSkipPrepare, "Label")
    local str = ccClientText(10364)--"跳过战前布阵"
    self:SetWndText(text, str)
    text = self:FindWndTrans(self.mSkipBattle, "Label")
    str = ccClientText(10365)-- "跳过战斗"
    self:SetWndText(text, str)

    local isSkip = gModelArena:GetIsSkipChecked()
    self:SetWndToggleValue(self.mSkipBattle, isSkip)

    isSkip = gModelArena:IsSkipPrepare()
    self:SetWndToggleValue(self.mSkipPrepare, isSkip)

    --self:SetWndButtonText(self.mDefendBtn,ccClientText(10358))

    self:SetWndText(self.mChallengeTimes_Title, ccClientText(17578))
end

function UIringRk:ShowHelp()
    local str1 = tostring(gModelArena:GetConfigFreeCombatCount())
    local str2 = tostring(gModelArena:GetArenaPara("AccountTime"))
    str2 = string.gsub(str2, "=", ":")
    local str3 = tostring(gModelArena:GetArenaPara("SeasonDays"))
    local str4 = tostring(gModelArena:GetArenaPara("ScorePercent"))
    local para = {
        str1, str2, str3, str4
    }
    GF.OpenWnd("UIBzTips", { refId = 8, para = para })
end

function UIringRk:SetSelfPlayer()
    local score = gModelArena:GetScore()
    local rank = gModelArena:GetRank()

    if rank <= 0 then
        rank = ccClientText(10363)
    end
    -- 玩家头像

    self:SetWndText(self.mMyScore, score)
    self:SetWndText(self.mMyRank, ccClientText(17202) .. rank)

    --玩家战力
    local num = gModelPower:GetMainCityPower()
    local playerPower = tonumber(num)
    local str = LUtil.PowerNumberCoversion(playerPower)
    self:SetWndText(self.mMyPowerText, str)
end

function UIringRk:SetRefreshCd()
    local endCd = gModelArena:GetRefreshCdEnd()
    local timeLeft = math.ceil(endCd - GetTimestamp())
    local text = nil
    local isCooling = timeLeft > 0
    self._isCooling = true
    if isCooling then
        self._refreshTimeLeft = timeLeft
        text = timeLeft .. ccClientText(10355)
    else
        text = ccClientText(10311) --刷新
        self._isCooling = false
    end

    self:SetWndButtonText(self.mRefreshBtn, text)
    self:SetWndButtonGray(self.mRefreshBtn, isCooling)
    --self:SetWndImageGray(self.mRefreshBtn,isCooling)
    --self:SetXUITextText(self.mRefreshText,text)
end

function UIringRk:ScrollBoxCenter(index, total)
    local viewLength = self.mBoxList:GetComponent(typeOfRectTransform).rect.width
    local scrollContent = self.mBoxList:Find("content")
    local contentLength = scrollContent:GetComponent(typeOfRectTransform).rect.width
    if contentLength < viewLength then
        return
    end
    local factor = ((index / total) * contentLength - viewLength / 2) / (contentLength - viewLength)

    if factor > 0 then
        factor = factor > 1 and 1 or factor
        local scrollRect = self.mBoxList:GetComponent(typeOfScrollRect)
        if scrollRect then
            scrollRect.normalizedPosition = Vector2(factor, 0)
        end
    end

end

function UIringRk:SetRankTrans(trans, data)
	local serverText = self:FindWndTrans(trans,"ServerText")
	local nameText = self:FindWndTrans(trans, "NameText")
	local likeBtn = self:FindWndTrans(trans, "LikeBtn")
	local likeBtnImg = self:FindWndTrans(likeBtn, "Image")
	local likeText = self:FindWndTrans(likeBtn, "Text")
    local SelfTag = self:FindWndTrans(trans, "SelfTag")
    if not data then
        CS.ShowObject(likeBtn, false)
        self:SetWndText(nameText, ccClientText(11711))
        return
    end

	self:SetHeroPaint(trans, data.info)

    local instanceId = trans:GetInstanceID()
	local likeType = 1001
	local isLiked = gModelRank:IsLiked(likeType, data.info.playerId)
	-- local isSelf = data.info.playerId == gModelPlayer:GetPlayerId()
	local isGray = isLiked
	self:SetWndTabStatus(likeBtn, isGray and 0 or 1) --点赞0 没点1

	self:SetWndText(serverText, data.info.score)
	self:SetWndText(nameText, data.info.name)
	self:SetWndText(likeText, LUtil.NumberCoversion(data.info.like))

    if isGray then
        self:DestroyWndEffectByKey(instanceId .. "show")
    else
        self:CreateWndEffect(likeBtnImg, "fx_ui_dianzanchangzhu", instanceId .. "show", 100)
    end


    local selfPlayerId = gModelPlayer:GetPlayerId()
    CS.ShowObject(SelfTag,selfPlayerId == data.info.playerId)

	self:SetWndClick(trans, function()
		gModelGeneral:PlayerShowReq(
			data.info.playerId,
			LCombatTypeConst.COMBAT_MAIN,
			LPlayerShowConst.OTHER_SYSTEM
		)
	end)
	self:SetWndClick(likeBtn, function()
		-- if isSelf then
		-- 	GF.ShowMessage(ccClientText(11877))
		-- 	return
		-- end
        if isLiked then
			GF.ShowMessage(ccClientText(11878))
			return
		end
		gModelRank:OnPlayerLikeReq(data.info.playerId, likeType)
        local eff = self:FindWndEffectByKey(instanceId)
        if eff then
            eff:SetVisible(false)
            eff:SetVisible(true)
        else
            self:CreateWndEffect(likeBtnImg, "fx_ui_dianzan", instanceId, 100)
        end
	end)
end

function UIringRk:ShowChallengeTipWnd(playerData)
    local isDirty = gModelArena:IsChallengeDataDirty()
    if isDirty then
        return
    end
    GF.OpenWnd("UIringPerInfo", { playerData = playerData })
end

function UIringRk:OnClickChallenge(data)

    local isDirty = gModelArena:IsChallengeDataDirty()
    if isDirty then
        return
    end

    if self._isClick then
        return
    end

    self._isClick = true
    local seq = self._seqCom:CreateSeq("clickCooling")
    seq:AppendInterval(1)
    seq:OnComplete(function()
        self._seqCom:DeleteSeq("clickCooling")
        self._isClick = false
    end)
    seq:PlayForward()

    --print("挑战 "..data.playerId)
    gModelArena:GoToChallenge(data, self:GetWndName())
end

function UIringRk:InitData()
    self._rankingCountDown = "ranking"
    self._sliderKey = "boxSlider"
    self._refreshCooling = "refreshCooling"
    self._endCd = 0
    self._boxEffKeyList = {}

end

function UIringRk:SetCountDownText()
    local seasonEndTime = gModelArena:GetRankSeasonTime()
    local nowTime = GetTimestamp()
    local timespan = seasonEndTime - nowTime
    local timeStr = LUtil.FormatTimespanCn(timespan)
    --timeStr = LUtil.FormatColorStr(timeStr,"green")
    timeStr = string.replace(ccClientText(10310), timeStr)-- string.format("结束倒计时:%s",timeStr)
    self:SetWndText(self.mCountDownText, timeStr)
end

function UIringRk:OnDestroy()
    if self._delayUpdateScrollTimer then
        LxTimer.DelayTimeStop(self._delayUpdateScrollTimer)
        self._delayUpdateScrollTimer = nil
    end
    LWnd.OnDestroy(self)
end

function UIringRk:OnClickBox(refId)
    --print("box index "..refId)
    local itemData = self._boxItemDataList[refId]
    if not itemData then
        return
    end
    if itemData[2].isGet then
        GF.ShowMessage(ccClientText(11859))
        return
    end
    if itemData[2].canGet then
        gModelArena:OnReceiveArenaRewardReq(refId)

        local item = self._boxItemDataList[refId]
        local key = "boxOpenEff"
        self:DestroyWndEffectByKey(key)
        item = item and item[1]
        --if item then
        --	local effRoot = self:FindWndTrans(item,"effRoot")
        --	self:CreateWndEffect(effRoot,"fx_baoxiang_paiweisai02",key,100)
        --end

    else
        local item = itemData[1]
        local root = self:FindWndTrans(item, "btn")
        GF.OpenWnd("UIringBoxDetail", { root, itemData[2].itemList })
    end


end

function UIringRk:StartCooling()
    local cdEnd = gModelArena:GetRefreshCdEnd()
    self:SetRefreshCd()
    if cdEnd > GetTimestamp() then
        local cd = gModelArena:GetArenaPara("RefreshCd")
        self:TimerStop(self._refreshCooling)
        self:TimerStart(self._refreshCooling, 1, false, cd)
    end

end

function UIringRk:OnDrawItem(item, itemdata)
    local effRoot = self:FindWndTrans(item, "effRoot")
    local btn = self:FindWndTrans(item, "btn")
    local bg = self:FindWndTrans(item, "bg")
    local bgTimes = self:FindWndTrans(bg, "times")

    self:SetWndClick(btn, itemdata.func, LSoundConst.CLICK_BUTTON_COMMON)

    local imageState = 0
    local key = "boxEff" .. tostring(itemdata.refId)
    self:DestroyWndEffectByKey(key)

    local iconPath="quest_icon_box_1"

    if itemdata.canGet then
        imageState = 1
        --self:CreateWndEffect(effRoot,"fx_baoxiang_paiweisai01",key,100)
        self:CreateWndEffect(effRoot, "fx_richangbaoxiang", key, 100)
    end
    if itemdata.isGet then
        imageState = 2

        iconPath="quest_icon_box_2"
    end


    self:SetWndEasyImage(btn,iconPath,nil,false)
    --local stateActor = btn.transform:GetComponent(typeofYXUIStateActor)
    --if stateActor then
    --    stateActor:SetState(imageState)
    --end

    local alpha = itemdata.canGet and 0 or 1

    LxUiHelper.SetImageAlpha(btn, alpha)
    --CS.ShowObject(btn,not itemdata.canGet)
    --CS.ShowObject(showBtn,true)
    self:SetWndText(bgTimes, itemdata.times)
    self._boxItemDataList[itemdata.refId] = { item, itemdata }
end

function UIringRk:SetHeroPaint(trans, info)
	local paintTans = self:FindWndTrans(trans, "Spine/SpineRoot")
	local ref = gModelPlayer:GetRoleAdventureImage(info.figure)
	if not ref then return end
	local key = trans.gameObject.name

	local paintFlip = ref.paintFlip2 == 1
	local paintMultiple = ref.paintMultiple2
	local offset = LxDataHelper.ParseVector2(ref.paintPaint2, ',')
	self:CreateWndSpine(paintTans, ref.spine, key, false, function(dpSpine)
		dpSpine:SetScale(paintMultiple)
		dpSpine:SetFlipX(paintFlip)
		local dpTrans = dpSpine:GetDisplayTrans()
		if dpTrans then
			dpTrans.anchorMin = Vector2.New(0.5, 0.5)
			dpTrans.anchorMax = Vector2.New(0.5, 0.5)
			dpTrans.localPosition = offset
		end
	end)
end
--function UIringRk:OnAwake()
--	LWnd.OnAwake(self)
--	self:DelaySendFinish(0.2)
--end

--function UIringRk:RefreshCost()
--
--	for k,v in ipairs(self._playerList) do
--		local item = v
--		local challengeBtn = self:FindWndTrans(item,"challengeBtn")
--		local challengeBtnText = self:FindWndTrans(challengeBtn,"text")
--		local challengeBtnTicket = self:FindWndTrans(challengeBtn,"ticket")
--		local ticketIcon = self:FindWndTrans(challengeBtnTicket,"icon")
--		local ticketNum = self:FindWndTrans(challengeBtnTicket,"num")
--		local ticketId =gModelArena:GetArenaPara("TciketId")
--		local icon,iconBg = gModelItem:GetItemImgByRefId(ticketId)
--		if icon then
--			self:SetWndEasyImage(ticketIcon,icon)
--		end
--		local canFreeChallenge = gModelArena:CanFreeChallenge()
--		if canFreeChallenge then
--			self:SetWndText(challengeBtnText,ccClientText(10313))--免费挑战
--		else
--			local num = gModelArena:GetArenaPara("TicketNum")
--			local str = string.format("%s %s",num,ccClientText(10335))
--			self:SetWndText(ticketNum,str) --挑战
--		end
--
--		CS.ShowObject(challengeBtnTicket,not canFreeChallenge)
--		CS.ShowObject(challengeBtnText,canFreeChallenge)
--	end
--
--
--
--end

function UIringRk:OnPlayerArenaResp(...)
    self:InitBoxList()
    self:StarCountDown()
    self:SetSelfPlayer()
    self:RefreshChallengeList()
end

function UIringRk:RefreshChallengeList()
    CS.ShowObject(self.mChanllengeList, true)
    local challengeList = gModelArena:GetChallengeList()
    local selfGuildId = gModelPlayer:GetGuildId()

    local t = {}
    for i = 1, 3 do
        local playerData = {}
        local data = challengeList[i]
        if not data then
            break
        end
        playerData.rank = data.rank
        playerData.name = data.name
        playerData.level = data.grade
        playerData.score = data.score
        playerData.power = data.power
        playerData.head = data.head
        playerData.frame = data.headFrame
        playerData.playerId = data.playerId
        playerData.func = function()
            self:OnClickChallenge(data)
        end

        local isSameGuild = tonumber(data.guildId) > 0 and data.guildId == selfGuildId
        playerData.isSameGuild = isSameGuild
        table.insert(t, playerData)
    end
    table.sort(t, function(a, b)
        return a.power > b.power
    end)

    for k, v in ipairs(t) do
        self:SetPlayerInfo(self._playerList[k], v)
    end

end

------------------------------------------------------------------
return UIringRk

