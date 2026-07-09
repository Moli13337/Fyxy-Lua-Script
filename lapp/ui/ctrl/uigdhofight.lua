---
--- Created by Administrator.
--- DateTime: 2024/6/20 15:45:44
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFight:LWnd
local UIGdHoFight = LxWndClass("UIGdHoFight", LWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFight:UIGdHoFight()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFight:OnWndClose()
    CS.ShowObject(self.mHeroRoot,false)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFight:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFight:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion() or gLGameLanguage:IsVieVersion()

    if self._isEnus then
        LxUiHelper.SetSizeWithCurAnchor(self.mScore_Bg,0,230)
    end

    self._isVie = gLGameLanguage:IsVieVersion()
    self.jpj = gLGameLanguage:IsJapanVersion()
    if self.jpj then
        LxUiHelper.SetSizeWithCurAnchor(self.mScore_Bg,0,200)
        self:SetAnchorPos(self.mSelfLeftTimes,Vector2.New(-18,-65))
    end
    self:InitData()
    self:InitBase()
    self:InitCallBack()
    self:InitEvent()
    self:InitText()

    self:InitBtnRedPoint()
    self:InitEffect()
    self:OpenReq()
end

--endregion --------------------------------------------------------------------------------------


--region 页面 --------------------------------------------------------------------------------
function UIGdHoFight:SetBtnState()
    CS.ShowObject(self.mSelfBtnSelect, self._isSelfShow)
    CS.ShowObject(self.mBuffBtn, not self._isSelfShow)

    CS.ShowObject(self.mOppositeBtnSelect, not self._isSelfShow)
    CS.ShowObject(self.mBattleArrayBtn, self._isSelfShow)

    self._selectIndex = 0
end

function UIGdHoFight:OnScorceRankClick()
    local para = {}
    para.tabIndex = 2
    GF.OpenWnd("UIGdHoFightRk", { para = para })
end
--endregion --------------------------------------------------------------------------------------

--region 页面上的红点 --------------------------------------------------------------------------------
function UIGdHoFight:InitBtnRedPoint()
    self:SetBattleArrayBtnRedPoint()
    self:SetBoxBtnRedPoint()
    self:SetRewardBtnRedPoint()
end
--endregion --------------------------------------------------------------------------------------



--region 事件的回调 --------------------------------------------------------------------------------
function UIGdHoFight:OnGuildInfo()
    self._guildInfo = gModelGuildHolyBattle:GetGuildInfo()
    self:SetGuildFlag()
end

function UIGdHoFight:CreateHero()
    local showHeroList = gModelGuildHolyBattle:GetPrepareShowHeroList(self._isSelfShow)
    self._heroList = showHeroList

    CS.SetParentTrans(self.mHero, self.mHeroTempRoot)
    --local content = #showHeroList
    --local calculate_1 = math.floor(content / 3)
    --local calculate_2 = content % 3
    --calculate_1 = calculate_2 > 0 and (calculate_1 + 1) or calculate_1
    --local height = 240 + calculate_1 * 350
    --self.mHeroScrollRoot.rect.height=height
    --height = height > 1136 and height or 1136  -- 要大于最小屏幕的时候

    local height = 3640
    LxUiHelper.SetSizeWithCurAnchor(self.mHeroScrollRoot, 1, height )
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.mHeroScrollContent)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.mHeroScrollContent)
    CS.SetParentTrans(self.mHero, self.mHeroScrollRoot)

    local heroPosHeight = height / 4 + 100
    heroPosHeight = heroPosHeight>350 and 350 or heroPosHeight

    local pos = Vector2.New(0, heroPosHeight)
    self:SetAnchorPos(self.mHero, pos)

    if showHeroList and #showHeroList > 0 then
        local template = self.mHeroTemplate
        for i = 1, 40 do
            local key = "Pos" .. i
            local tran = self:FindWndTrans(self.mHeroRoot, key)

            if tran then
                CS.ShowObject(tran, false)


                if showHeroList[i] then
                    --判断是否创建过item 没有则进行创建
                    if not self._heroInfo then
                        self._heroInfo = {}
                    end

                    if not self._heroInfo[i] then
                        self._heroInfo[i] = {}
                        local item = LxResUtil.NewObject(template, nil, true)
                        CS.SetParentTrans(item, tran)
                        CS.ShowObject(item, true)
                        self._heroInfo[i].item = item
                    end

                    self:SetHeroInfo(i)

                    CS.ShowObject(tran, true)
                end

            end
        end
    end
end
--region 初始化部分 --------------------------------------------------------------------------------
function UIGdHoFight:InitData()

    self._uiHeroObjList = {}
    self._timeKey = "UIGdHoFight_TimeKey" -- 每隔1S刷新一次

    local ref = GameTable.SupportTipsRef[17]

    --获取状态 设置
    self._stage = gModelGuildHolyBattle:GetStage()

    self._isSelfShow = not (self._stage == 3)  --  3的阶段就是进入对方的部分
    local isSelf = self:GetWndArg("isSelf")
    if isSelf then
        self._isSelfShow = isSelf
    end

    if ref then
        self._uiHelpTips = ccLngText(ref.text)
    else
        self._uiHelpTips = "17-------no config"
    end

    self._selectIndex = 0 --查看时候的部分
end

function UIGdHoFight:InitEvent()
    --event
    --公会信息
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.MatchDataChange_Self, function()
        self:OnGuildInfo()
    end)

    --自己的挑战信息
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.ChallengeDataChange, function()
        self:OnSelfSorceInfo()
    end)

    --据点信息
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.BattlefieldDataChange, function()
        self:CreateHero()
    end)


    --公会的列表信息--这里只接受单个的改变
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.BattlefieldDataChange_Type_2, function(changeIndex)
        for k, v in ipairs(changeIndex) do
            self:SetHeroInfo(v)
        end

    end)

    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.BattlefieldDataChange_Type_3, function(changeIndex)
        for k, v in ipairs(changeIndex) do
            self:SetHeroInfo(v)
        end
    end)

    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.RankDataChange, function()
        self:OnRankInfo()
    end)

    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        self:OnWndClose()
    end)


    --ui
    self:SetWndClick(self.mHelpTips, function(...)
        self:OnHelpTipsClick()
    end)

    self:SetWndClick(self.mReturnBtn, function(...)
        self:WndClose()
    end)

    self:SetWndClick(self.mRankBtn, function(...)
        self:OnRankClick()
    end)

    self:SetWndClick(self.mRewardBtn, function(...)
        self:OnRewardClick()
    end)

    self:SetWndClick(self.mBoxBtn, function(...)
        self:OnTreasureClick()
    end)

    self:SetWndClick(self.mListBtn, function(...)
        self:OnMatchListClick()
    end)

    self:SetWndClick(self.mSelfBtn, function(...)
        self._isSelfShow = true
        --切自己的阵营
        self:SetBtnState()
        self:CreateHero()
    end)

    self:SetWndClick(self.mOppositeBtn, function(...)
        self._isSelfShow = false
        --切敌方的阵营
        self:SetBtnState()
        self:CreateHero()
    end)

    self:SetWndClick(self.mBuffBtn, function(...)
        self:OnBuffClick()
    end)

    self:SetWndClick(self.mLogBtn, function(...)
        self:OnLogClick()
    end)

    self:SetWndClick(self.mBattleArrayBtn, function(...)
        self:OnSetBattleArrayClick()
    end)
    self:SetWndClick(self.mScore_Bg, function(...)
        self:OnScorceRankClick()
    end)

    self:SetWndClick(self.mCrossTag, function(...)
        --gModelCrossGrading:OpenGroupWndPop()


        local serverList, groupId = gModelGuildHolyBattle:GetServers()
        GF.OpenWnd("UIKfSyerGroupingPop", {

            wndType = 2, groupId = groupId, serverList = serverList
        })
    end)

    self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:InitBtnRedPoint() end)

    self:WndEventRecv(EventNames.ON_QUEST_CHANGE, function(...)
        self:SetRewardBtnRedPoint()
    end)
end

function UIGdHoFight:InitEffect()
    local instanceId = self.mSelfBtn:GetInstanceID()
    self:CreateWndEffect(self.mSelfBtn,"fx_ui_shengqizhizhan_judian",instanceId,100,false,false,nil,nil,nil,nil,nil,nil,1)
    local instanceId = self.mOppositeBtn:GetInstanceID()
    self:CreateWndEffect(self.mOppositeBtn,"fx_ui_shengqizhizhan_judian",instanceId,100,false,false,nil,nil,nil,nil,nil,nil,1)
end

function UIGdHoFight:SetGuildFlag()
    if self._guildInfo then
        for k, v in pairs(self._guildInfo) do
            local root = v.isSelf and self.mGuildInfo_1 or self.mGuildInfo_2

            local fragBgTran = CS.FindTrans(root, "GuildIconBg")
            local fragTran = CS.FindTrans(fragBgTran, "GuildIcon")
            local nameTran = CS.FindTrans(root, "GuildName")
            local barTran = v.isSelf and self.mInfoBar_1 or self.mInfoBar_2
            local barNumTran = CS.FindTrans(root, "Num")

            local fragRef = gModelGuild:GetGuildFlagRefByRefId(v.flagId)
            local fragBgRef = gModelGuild:GetGuildFlagRefByRefId(v.flagBgId)
            if fragBgRef then
                self:SetWndEasyImage(fragBgTran, fragBgRef.res, nil, false)
            end
            if fragRef then
                self:SetWndEasyImage(fragTran, fragRef.res, nil, false)
            end

            local guildName
            if gModelGuildHolyBattle:CheckIsCross() then
                guildName = string.format("<color=#68E6AC>[%s]</color> %s", v.serverName, v.guildName)
            else
                guildName = v.guildName
            end
            self:SetWndText(nameTran, guildName)

            self:SetWndText(barNumTran, v.starCount)
            local starCount = v.starCount
            local totalCount = gModelGuildHolyBattle:GetGuildTotalCount()

            if totalCount == 0 then
                barTran.transform.localScale = Vector3.New(0.5, 1, 1)
            else
                barTran.transform.localScale = Vector3.New(starCount / totalCount, 1, 1)
            end


        end

    end
end

function UIGdHoFight:SetBtnRedPoint(btnTran, isShow)
    local redPoint = CS.FindTrans(btnTran, "redPoint")

    if not redPoint then
        redPoint = CS.FindTrans(btnTran, "redPoint_2")
    end
    if redPoint then
        CS.ShowObject(redPoint, isShow)
    end

end

function UIGdHoFight:SetCrossState()
    local isCross = gModelGuildHolyBattle:CheckIsCross()
    CS.ShowObject(self.mCrossTag, isCross)
end

function UIGdHoFight:InitText()
    self:SetWndText(self.mTitleTxt, ccClientText(44000))  --[44000] [聖騎之戰]
    self:SetWndText(self.mCrossTxt, ccClientText(44066))  --[44066] [跨服]
    self:SetWndText(self.mScoreTitle, ccClientText(44021))  --[44021] [積分排行]

    self:SetWndText(self:GetBtnTextTran(self.mRankBtn), ccClientText(44012))  --[44012] [排 行]
    self:SetWndText(self:GetBtnTextTran(self.mRewardBtn), ccClientText(44013))  --[44013] [獎 勵]
    self:SetWndText(self:GetBtnTextTran(self.mBoxBtn), ccClientText(44014))  --[44014] [寶 箱]
    self:SetWndText(self:GetBtnTextTran(self.mListBtn), ccClientText(44015))  --[44015] [列 表]
    self:SetWndText(self:GetBtnTextTran(self.mReturnBtn), ccClientText(10320))  --[10320]	[返  回]
    self:SetWndText(self:GetBtnTextTran(self.mSelfBtn), ccClientText(44017))  --[44017]	[我方據點]
    self:SetWndText(self:GetBtnTextTran(self.mOppositeBtn), ccClientText(44018))  --[44018]	[敵方據點]
    self:SetWndText(self:GetBtnTextTran(self.mLogBtn), ccClientText(44019))  --[44019]	[日誌]
    self:SetWndText(self:GetBtnTextTran(self.mBuffBtn), ccClientText(44020))  --[44020]	[BUFF]
    self:SetWndText(self:GetBtnTextTran(self.mBattleArrayBtn), ccClientText(21810))  --[21810]	[陣容]
    if self._isVie then
        self:IsVies(self.mRankBtn)
        self:IsVies(self.mRewardBtn)
        self:IsVies(self.mBoxBtn)
        self:IsVies(self.mListBtn)
    end

end

function UIGdHoFight:OnRankInfo()
    for i = 1, 3 do
        local rankKey = "RankText_" .. i

        local rankTran = CS.FindTrans(self.mScoreRankRoot, rankKey)

        local ranks = gModelGuildHolyBattle:GetRank()

        local str = ""
        if ranks[i] then
            str = i .. "." .. ranks[i].info._name .. " " .. ranks[i].score
        else
            str = ccClientText(11707)
        end

        self:SetWndText(rankTran, str)
    end
end

function UIGdHoFight:OnMatchListClick()
    if self._stage > 1 then
        GF.OpenWnd("UIGdHoFightMatchList")
    else
        GF.ShowMessage(ccClientText(43312))
    end
end

function UIGdHoFight:OnRankClick()
    GF.OpenWnd("UIGdHoFightRk")
end

function UIGdHoFight:SetBoxBtnRedPoint()
    local isShow = gModelGuildHolyBattle:CheckRedpointTreasure()
    self:SetBtnRedPoint(self.mBoxBtn, isShow)
end


--Click事件
--help事件
function UIGdHoFight:OnHelpTipsClick()
    GF.OpenWnd("UIBzTips", { title = ccClientText(44000), text = self._uiHelpTips })
end

function UIGdHoFight:SetLeftTime()
    if self._stageEndTime == 0 or self._stageEndTime == nil then
        self:TimerStop(self._timeKey)
        return
    end
    local leftTime = self._stageEndTime - GetTimestamp()

    if leftTime <= 0 then
        self:TimerStop(self._timeKey)
        CS.ShowObject(self.mTimeStage_2, false)
        return
    end
    CS.ShowObject(self.mTimeStage_2, true)
    local timeStr = LUtil.FormatTimespanNumber(leftTime)
    local desStr = string.replace(ccClientText(44008), timeStr)
    self:SetWndText(self.mTimeTxtStage_2, desStr)
end

function UIGdHoFight:SetBattleArrayBtnRedPoint()
    local isShow = gModelGuildHolyBattle:CheckRedPointPrepare()
    self:SetBtnRedPoint(self.mBattleArrayBtn, isShow)
end

function UIGdHoFight:SetHeroSelectState(index)
    local olditem = self._heroInfo[self._selectIndex]

    if olditem then
        local stage_3_Old = self:FindWndTrans(olditem.item, "Stage_3")
        CS.ShowObject(stage_3_Old, false)
    end

    local newitem = self._heroInfo[index]
    local stage_3_new = self:FindWndTrans(newitem.item, "Stage_3")
    CS.ShowObject(stage_3_new, true)

    self._selectIndex = index
end
--endregion --------------------------------------------------------------------------------------


--region 新增定时器和对应的回调 --------------------------------------------------------------------------------
function UIGdHoFight:OnTimer(key)
    if (self._timeKey == key) then

        self:SetLeftTime()
    end
end

function UIGdHoFight:OpenReq()
    gModelGuildHolyBattle:SendGuildBattlePlayerRankReq()
    gModelGuildHolyBattle:SendGuildBattleBattlefieldReq()
end

function UIGdHoFight:OnLogClick()
    local para = {}
    para.tabIndex = 1
    GF.OpenWnd("UIGdHoFightRecord", { para = para })
end

function UIGdHoFight:GetBtnTextTran(tran)
    local textTran = CS.FindTrans(tran, "UIText")
    return textTran
end

function UIGdHoFight:OnTreasureClick()
    GF.OpenWnd("UIGdHoFightTsure")
end

function UIGdHoFight:OnSetBattleArrayClick()
    gModelGuildHolyBattle:SetRedPointPrepareClick()
    if self._stage == 2 then
        gModelGuildHolyBattle:SetDefendHero()
    else
        GF.ShowMessage(ccClientText(44058))   --[44058] [非戰備階段，無法進行佈陣]
    end
end

function UIGdHoFight:SetHeroInfo(index)
    if nil == self._heroInfo[index] then
        return
    end

    local item = self._heroInfo[index].item

    local ref = gModelPlayer:GetRoleAdventureImage(self._heroList[index].image)
    local spineName = ref.spine

    local heroTran = self:FindWndTrans(item, "Hero")
    local instanceId = heroTran:GetInstanceID()

    local spineKey = self._isSelfShow and instanceId .. "_self" or instanceId .. "_otner"
    local spineOtherKey = (not self._isSelfShow) and instanceId .. "_self" or instanceId .. "_otner"

    local newUIHeroObj = self._uiHeroObjList[spineKey]

    --形象
    if not newUIHeroObj then
        newUIHeroObj = LUIHeroObject:New(self)
        self._uiHeroObjList[spineKey] = newUIHeroObj

        newUIHeroObj:Create(heroTran, spineKey, spineName)
        newUIHeroObj:SetScale(1.3)
        newUIHeroObj:ShowHero(true)
        newUIHeroObj:StartLoad()
    else
        newUIHeroObj:ShowHero(true)
    end
    --newUIHeroObj:SetRectMatch(true)
    --newUIHeroObj:SetClickFunc(function(...)
    --    local para = {}
    --    para.spineName = spineName
    --    para.itemData = self._heroList[index]
    --
    --    self:SetHeroSelectState(index)
    --
    --    if self._isSelfShow then
    --        GF.OpenWnd("UIGdHoFightDefendInfo", { para = para })
    --    else
    --        GF.OpenWnd("UIGdHoFightAttackInfo", { para = para })
    --    end
    --end)

    local ClickArea = self:FindWndTrans(item, "ClickArea")
    --self:SetWndText(UIText, self._heroList[index].name)
    self:SetWndClick(ClickArea,function()
            local para = {}
            para.spineName = spineName
            para.itemData = self._heroList[index]






            self:SetHeroSelectState(index)

            if self._isSelfShow then
                local serverId = gModelPlayer:GetServerId()
                para.serverId = serverId
                GF.OpenWnd("UIGdHoFightDefendInfo", { para = para })
            else

                for k,v in pairs(self._guildInfo) do
                    if not v.isSelf then
                        para.serverId=v.serverId
                        break
                    end
                end

                GF.OpenWnd("UIGdHoFightAttackInfo", { para = para })
            end
    end)

    if self._uiHeroObjList[spineOtherKey] then
        self._uiHeroObjList[spineOtherKey]:ShowHero(false)
    end

    --名字
    local UIText = self:FindWndTrans(item, "UIText")
    self:SetWndText(UIText, self._heroList[index].name)

    --战力
    local PowerText = self:FindWndTrans(item, "PowerBg/Power")
    self:SetWndText(PowerText, LUtil.NumberCoversion(self._heroList[index].power))

    --星星
    for i = 1, 3 do
        local starRoot = self:FindWndTrans(item, "StarRoot")

        local starKey = "Star_" .. i

        local star = self:FindWndTrans(starRoot, starKey)

        if i <= self._heroList[index].star then
            self:SetWndEasyImage(star, "hero_icon_star1")
        else
            self:SetWndEasyImage(star, "guildwar1_star -hui")
        end
    end

    --显示那块砖
    local Stage_3 = self:FindWndTrans(item, "Stage_3")
    local Stage_2 = self:FindWndTrans(item, "Stage_2")
    local Stage_1 = self:FindWndTrans(item, "Stage_1")
    local isShowCanDo = self._heroList[index].sweep
    CS.ShowObject(Stage_3, false)
    CS.ShowObject(Stage_2, isShowCanDo)
    CS.ShowObject(Stage_1, not isShowCanDo)

end

function UIGdHoFight:InitBase()
    self:SetBtnState()
    self:SetCrossState()

    --倒计时
    self._stageEndTime = gModelGuildHolyBattle:GetStageEndTime()
    self:SetLeftTime()
    self:TimerStart(self._timeKey, 1, false, -1)


end

function UIGdHoFight:SetRewardBtnRedPoint()
    local isShow = gModelGuildHolyBattle:CheckRedPointTaskSelf() or gModelGuildHolyBattle:CheckRedPointTaskGuild()
    self:SetBtnRedPoint(self.mRewardBtn, isShow)
end

--上个页面请求过了，这个页面打开的时候 调用一次回调
function UIGdHoFight:InitCallBack()
    self:OnGuildInfo()
    self:OnSelfSorceInfo()

end

function UIGdHoFight:IsVies(tran)
    local Rank1 = CS.FindTrans(tran,"UIText")
    self:InitTextLineWithLanguage(Rank1, -20)
    LxUiHelper.SetSizeWithCurAnchor(Rank1,0,60)
    self:SetAnchorPos(Rank1,Vector2.New(0,-26))
end

function UIGdHoFight:OnRewardClick()
    local para = {}
    para.tabIndex = 1
    GF.OpenWnd("UIGdHoFightAward", { para = para })

end

function UIGdHoFight:OnSelfSorceInfo()
    local leftTimes = string.replace(ccClientText(44009), gModelGuildHolyBattle:GetTotalCount() - gModelGuildHolyBattle:GetChallengeCount(), gModelGuildHolyBattle:GetTotalCount())
    self:SetWndText(self.mSelfLeftTimes, leftTimes)
end

function UIGdHoFight:OnBuffClick()
    GF.OpenWnd("UIGdHoFightBfInfo")
end

--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UIGdHoFight