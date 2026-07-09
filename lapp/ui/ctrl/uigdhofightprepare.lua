---
--- Created by Administrator.
--- DateTime: 2024/6/19 21:58:14
---
------------------------------------------------------------------
local typeofCanvas = typeof(UnityEngine.Canvas)
local LWnd = LWnd
---@class UIGdHoFightPrepare:LWnd
local UIGdHoFightPrepare = LxWndClass("UIGdHoFightPrepare", LWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightPrepare:UIGdHoFightPrepare()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightPrepare:OnWndClose()
    CS.ShowObject(self.mHero, false)
    CS.ShowObject(self.mHeroRoot, false)
    CS.ShowObject(self.mHeroRoot_OnlySelf, false)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightPrepare:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightPrepare:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    if gModelGuildHolyBattle:CheckIsInFight() then
        self:OnWndClose()
        return
    end

    self._isEnus = gLGameLanguage:IsEnglishVersion() or gLGameLanguage:IsVieVersion()

    if self._isEnus then
        LxUiHelper.SetSizeWithCurAnchor(self.mScore,0,200)
    end
    self.jpj = gLGameLanguage:IsJapanVersion()
    if self.jpj then
        LxUiHelper.SetSizeWithCurAnchor(self.mScore,0,200)
    end
    self:InitData()
    self:InitText()
    self:InitEvent()
    self:OpenReq()
    self:InitBtnRedPoint()
    self:InitEffectVS()
    --printInfoN2("----------cjh ---------redpoint--12109999", gModelRedPoint:CheckShowRedPoint(12109999))
    --printInfoN2("----------cjh ---------redpoint--12110000", gModelRedPoint:CheckShowRedPoint(12110000))
    --printInfoN2("----------cjh ---------redpoint--12110001", gModelRedPoint:CheckShowRedPoint(12110001))
    --printInfoN2("----------cjh ---------redpoint--12110002", gModelRedPoint:CheckShowRedPoint(12110002))
    --printInfoN2("----------cjh ---------redpoint--12110003", gModelRedPoint:CheckShowRedPoint(12110003))
    --printInfoN2("----------cjh ---------redpoint--12110004", gModelRedPoint:CheckShowRedPoint(12110004))
    --printInfoN2("----------cjh ---------redpoint--12110005", gModelRedPoint:CheckShowRedPoint(12110005))
end

function UIGdHoFightPrepare:SetLeftTime()
    if self._stageEndTime == 0 or self._stageEndTime == nil then
        CS.ShowObject(self.mTimeStage_2, false)
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

function UIGdHoFightPrepare:SetCrossState()
    CS.ShowObject(self.mCrossTag, self._isCross)
end

--endregion --------------------------------------------------------------------------------------

--region 页面上的红点 --------------------------------------------------------------------------------
function UIGdHoFightPrepare:InitBtnRedPoint()
    self:SetBoxBtnRedPoint()
    self:SetRewardBtnRedPoint()
end

function UIGdHoFightPrepare:SetStageTxt()
    if self._stage > 1 and (not self._guildInfo) then
        self:SetWndText(self.mStageTxt, ccClientText(44075))
    else
        local colorStr = gModelGuildHolyBattle:GetStageColor(self._stage)
        local showStr = string.format(colorStr, gModelGuildHolyBattle:GetStageTextStr(self._stage))
        self:SetWndText(self.mStageTxt, showStr)
        CS.ShowObject(self.mMatch, self._stage == 1)
    end
end

function UIGdHoFightPrepare:SetGuildFlag()
    if self._guildInfo then
        for k, v in pairs(self._guildInfo) do
            local root = v.isSelf and self.mGuildInfo_1 or self.mGuildInfo_2

            local fragRef = gModelGuild:GetGuildFlagRefByRefId(v.flagId)
            local fragBgRef = gModelGuild:GetGuildFlagRefByRefId(v.flagBgId)

            local fragBgTran = CS.FindTrans(root, "GuildIconBg")
            local fragTran = CS.FindTrans(fragBgTran, "GuildIcon")
            local nameTran = CS.FindTrans(root, "GuildName")
            --local barTran = CS.FindTrans(root, "Bar")
            local barNumTran = CS.FindTrans(root, "Num")

            --重新调整  进度条要置于其他控件的底部所以抽取出来
            local barTran = v.isSelf and self.mInfoBar_1 or self.mInfoBar_2

            if fragBgRef then
                self:SetWndEasyImage(fragBgTran, fragBgRef.res, nil, false)
            end
            if fragRef then
                self:SetWndEasyImage(fragTran, fragRef.res, nil, false)
            end

            local guildName
            if self._isCross then
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
            if gModelGuildHolyBattle:GetMatchInfo(v.guildId) == 0 then
                --轮空
                CS.ShowObject(self.mGuildInfo_2, false)

                CS.ShowObject(self.mFightBtn, false)

            end
        end

    end
end

function UIGdHoFightPrepare:SetBtnRedPoint(btnTran, isShow)
    local redPoint = CS.FindTrans(btnTran, "redPoint")
    if redPoint then
        CS.ShowObject(redPoint, isShow)
    end
end

function UIGdHoFightPrepare:CreateHeroList(fromPos, toPos, list, dataList)
    for i = fromPos, toPos do
        local data = {}
        if dataList[i] then
            data = dataList[i]
            data.haveData = true
        else
            data.haveData = false
        end

        table.insert(list, data)
    end
end
function UIGdHoFightPrepare:InitEffectMpap()
    local instanceId = self.mStage_2:GetInstanceID()
    self:CreateWndEffect(self.mStage_2,"fx_ui_shengqizhizhan_map",instanceId,100,false,false,nil,nil,nil,nil,nil,nil,1)
 end

function UIGdHoFightPrepare:OpenReq()
    gModelGuildHolyBattle:SendGuildBattleStageReq()
end
--endregion --------------------------------------------------------------------------------------

--region 事件回调 --------------------------------------------------------------------------------
function UIGdHoFightPrepare:OnStateUpdate()
    --获取状态 设置
    self._stage = gModelGuildHolyBattle:GetStage()
    self._isGuildPartIn = gModelGuildHolyBattle:CheckGuildPartInState()
    self._isPlayerPartIn = gModelGuildHolyBattle:CheckPlayerPartInState()
    self._isCross = gModelGuildHolyBattle:CheckIsCross()

    self:SetCrossState()
    self:SetStageTxt()
    self._isTranSetStage_1 = true

    --local isShowBattle  = (self._stage == 3) or (self._stage == 2) or (self._stage == 4)
    local isShowBattle = self._stage > 2
    local strid = isShowBattle and 44011 or 44055 --[44055] [進入佈陣]  --[44011] [進入戰場
    self:SetWndText(self:GetBtnTextTran(self.mFightBtn), ccClientText(strid))

    --按钮的隐藏
    CS.ShowObject(self.mFightBtn, self._stage > 0)

    if self._stage > 0 then
        gModelGuildHolyBattle:CheckIsOpenCrossReward()
    end

    if not self._isGuildPartIn then
        --未参与
        self:SetStage_1()
        gModelGuildHolyBattle:SendGuildBattleBattlefieldReq()
        return
    end

    if self._stage >= 0 and self._stage < 2 then
        self:SetStage_1()
    end

    if self._stage >= 2 then
        self:SetStage_2()
        self._isTranSetStage_1 = false
    end

    --请求自己公会的战场信息
    gModelGuildHolyBattle:SendGuildBattleBattlefieldReq()
end
--endregion --------------------------------------------------------------------------------------


--region 新增定时器和对应的回调 --------------------------------------------------------------------------------
function UIGdHoFightPrepare:OnTimer(key)
    if (self._timeKey == key) then

        self:SetLeftTime()
    end
end

function UIGdHoFightPrepare:InitEffectVS()
    local instanceId = self.mEffectVs:GetInstanceID()
    self:CreateWndEffect(self.mEffectVs,"fx_ui_shengqizhizhan_vs",instanceId,100,false,false,nil,nil,nil,nil,nil,nil,1)
    local instanceId = self.mFightBtn:GetInstanceID()
    self:CreateWndEffect(self.mFightBtn,"fx_anniu_lanse_zhong",instanceId,100,false,false,nil,nil,nil,nil,nil,nil,0)

end

---Click 事件
--help事件
function UIGdHoFightPrepare:OnHelpTipsClick()
    GF.OpenWnd("UIBzTips", { title = ccClientText(44000), text = self._uiHelpTips })
end

function UIGdHoFightPrepare:InitText()
    self:SetWndText(self.mTitleTxt, ccClientText(44000))  --[44000] [聖騎之戰]
    self:SetWndText(self.mCrossTxt, ccClientText(44066))  --[44066] [跨服]
    self:SetWndText(self.mMatchText, ccClientText(44007))  --[44007] [檢索對手中......]
    self:SetWndText(self:GetBtnTextTran(self.mFightBtn), ccClientText(44011))  --[44011] [進入戰場]
    self:SetWndText(self:GetBtnTextTran(self.mRankBtn), ccClientText(44012))  --[44012] [排 行]
    self:SetWndText(self:GetBtnTextTran(self.mRewardBtn), ccClientText(44013))  --[44013] [獎 勵]
    self:SetWndText(self:GetBtnTextTran(self.mBoxBtn), ccClientText(44014))  --[44014] [寶 箱]
    self:SetWndText(self:GetBtnTextTran(self.mListBtn), ccClientText(44015))  --[44015] [列 表]
    self:SetWndText(self:GetBtnTextTran(self.mReturnBtn), ccClientText(10320))  --[10320]	[返  回]
end

--进入战场
function UIGdHoFightPrepare:OnBattleClick()
    --这里只进入战场
    if self._isPlayerPartIn then
        if not self._guildInfo then
            GF.ShowMessage(ccClientText(44075))     --[44075] [本輪無參戰資格]
        else
            GF.OpenWnd("UIGdHoFight")
        end
    else
        GF.ShowMessage(ccClientText(44056))     --[44056] [個人爲滿足參與條件]
    end
end

function UIGdHoFightPrepare:OnSelfSorceInfo()
    local leftTimes = string.replace(ccClientText(44009), gModelGuildHolyBattle:GetTotalCount() - gModelGuildHolyBattle:GetChallengeCount(), gModelGuildHolyBattle:GetTotalCount())
    local sorce = string.replace(ccClientText(44010), gModelGuildHolyBattle:GetScore())

    local leftTimesTxt = self:FindWndTrans(self.mScore, "LeftTimes")
    local sorceTxt = self:FindWndTrans(self.mScore, "ScoreTxt")

    self:SetWndText(leftTimesTxt, leftTimes)
    self:SetWndText(sorceTxt, sorce)
end

function UIGdHoFightPrepare:OnGuildInfo()
    self._guildInfo = gModelGuildHolyBattle:GetGuildInfo()
    self:SetStageTxt()
    self:SetGuildFlag()
end

function UIGdHoFightPrepare:SetBoxBtnRedPoint()
    local isShow = gModelGuildHolyBattle:CheckRedpointTreasure()
    self:SetBtnRedPoint(self.mBoxBtn, isShow)
end

function UIGdHoFightPrepare:OnMatchListClick()
    if self._stage > 1 then
        GF.OpenWnd("UIGdHoFightMatchList")
    else
        GF.ShowMessage(ccClientText(43312))
    end
end

function UIGdHoFightPrepare:GetBtnTextTran(tran)
    local textTran = CS.FindTrans(tran, "UIText")
    return textTran
end

function UIGdHoFightPrepare:OnRankClick()
    GF.OpenWnd("UIGdHoFightRk")
    --        self:CreateHero()
end

function UIGdHoFightPrepare:SetFightBtnRedPoint()
    --local leftNum = gModelGuildHolyBattle:GetTotalCount() - gModelGuildHolyBattle:GetChallengeCount()
    local isShow = gModelGuildHolyBattle:CheckRedPointBattle()
    self:SetBtnRedPoint(self.mFightBtn, isShow)
    if isShow then
        local redPoint = self:FindWndTrans(self.mFightBtn,"redPoint")
        if redPoint then
            local canvas = redPoint:GetComponent(typeofCanvas)
            if not canvas then
                canvas = redPoint.gameObject:AddComponent(typeofCanvas)
            end
            canvas.overrideSorting = true
            canvas.sortingLayerName = self:GetWndSortLayer()
            canvas.sortingOrder = self:GetWndSortOrder()+2
        end
    end
end

function UIGdHoFightPrepare:OnRewardClick()
    local para = {}
    para.tabIndex = 1
    GF.OpenWnd("UIGdHoFightAward", { para = para })
end

function UIGdHoFightPrepare:OnTreasureClick()
    GF.OpenWnd("UIGdHoFightTsure")
end

function UIGdHoFightPrepare:CreateHero()
    CS.ShowObject(self.mHeroRoot_OnlySelf, false)
    CS.ShowObject(self.mHeroRoot, false)

    local heroRoot = self._isOnlySelfGuild and self.mHeroRoot_OnlySelf or self.mHeroRoot
    CS.ShowObject(heroRoot, true)
    if self._heroList and #self._heroList > 0 then
        local template = self.mHeroTemplate

        for i = 1, 10 do
            local key = "Pos" .. i

            local tran = self:FindWndTrans(heroRoot, key)

            local item = LxResUtil.NewObject(template, nil, true)

            if self._heroList[i].haveData then
                local ref = gModelPlayer:GetRoleAdventureImage(self._heroList[i].image)
                local spineName = ref.spine

                local heroTran = self:FindWndTrans(item, "Hero")
                local instanceId = tran:GetInstanceID()

                if not self._uiHeroObjList then
                    self._uiHeroObjList = {}
                end

                local newUIHeroObj = self._uiHeroObjList[instanceId]

                if not newUIHeroObj then
                    newUIHeroObj = LUIHeroObject:New(self)
                    self._uiHeroObjList[instanceId] = newUIHeroObj
                    newUIHeroObj:Create(heroTran, instanceId, spineName)
                    newUIHeroObj:SetScale(1.3)
                    newUIHeroObj:ShowHero(true)
                    newUIHeroObj:StartLoad()

                    --创建角色的打印
                    printInfoN2("---holybatle--", instanceId .. "--这次缓存的id")
                else
                    newUIHeroObj:ShowHero(true)
                end

                CS.SetParentTrans(item, tran)
                CS.ShowObject(item, true)
                local UIText = self:FindWndTrans(item, "UIText")
                self:SetWndText(UIText, self._heroList[i].name)

                local isRight = i > 5

                if isRight then
                    heroTran.transform.localScale = Vector3.New(-1, 1, 1)
                end

            else
                CS.ShowObject(tran, false)
            end
        end
    end
end



--endregion --------------------------------------------------------------------------------------



--region 页面方法 --------------------------------------------------------------------------------
function UIGdHoFightPrepare:SetStage_1()
    CS.ShowObject(self.mStage_1, true)
    CS.ShowObject(self.mStage_2, false)
    CS.ShowObject(self.mFightBtn, false)

    local timeStr = gModelGuildHolyBattle:GetStarTimeDes()
    if string.isempty(timeStr) then
        CS.ShowObject(self.mTimeStage_1, false)
    else
        CS.ShowObject(self.mTimeStage_1, true)
        self:SetWndText(self.mTimeTxtStage_1, timeStr)
    end
    if self:FindWndEffectByKey(self.mStage_2:GetInstanceID()) then
        self:DestroyWndEffectByKey(self.mStage_2:GetInstanceID())
    end
end

function UIGdHoFightPrepare:InitEvent()
    -- model 事件驱动-- gModelGuildHolyBattle.EventArgs.oneDataChange
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.StageDataChange, function()
        self:OnStateUpdate()
    end)

    --据点信息
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.BattlefieldDataChange, function()
        self:OnHeroCreate()
    end)

    --公会信息 -- 二阶段才会请求
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.MatchDataChange_Self, function()
        self:OnGuildInfo()
    end)

    --自己的挑战信息
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.ChallengeDataChange, function()
        self:OnSelfSorceInfo()
        self:SetFightBtnRedPoint()
    end)

    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        self:WndClose()
    end)



    --ui
    self:SetWndClick(self.mReturnBtn, function(...)
        self:WndClose()
    end)

    self:SetWndClick(self.mHelpTips, function(...)
        self:OnHelpTipsClick()
    end)

    self:SetWndClick(self.mFightBtn, function(...)
        self:OnBattleClick()
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
    self:SetWndClick(self.mCrossTag, function(...)
        local serverList, groupId = gModelGuildHolyBattle:GetServers()
        GF.OpenWnd("UIKfSyerGroupingPop", {

            wndType = 2, groupId = groupId, serverList = serverList
        })
    end)


    --红点信息
    self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:InitBtnRedPoint() end)

    self:WndEventRecv(EventNames.ON_QUEST_CHANGE, function(...)
        self:SetRewardBtnRedPoint()
    end)
end

function UIGdHoFightPrepare:SetRewardBtnRedPoint()
    local isShow = gModelGuildHolyBattle:CheckRedPointTaskSelf() or gModelGuildHolyBattle:CheckRedPointTaskGuild()
    self:SetBtnRedPoint(self.mRewardBtn, isShow)
end

function UIGdHoFightPrepare:OnHeroCreate()
    -- 这里直接构建好对应的数据 -- 生成的列表一定是十个数据 数据里面的空数据代表不生成角色
    local attacklist = gModelGuildHolyBattle:GetPrepareShowHeroList(true)
    local defendlist = gModelGuildHolyBattle:GetPrepareShowHeroList()
    local list = {}

    self._isOnlySelfGuild = true
    if self._isTranSetStage_1 then
        --10个位置都从attack部分取
        self:CreateHeroList(1, 10, list, attacklist)
    else
        --5个从对方身上取
        self:CreateHeroList(1, 5, list, attacklist)
        self:CreateHeroList(6, 10, list, defendlist)

        self._isOnlySelfGuild = false
    end

    self._heroList = list

    self:CreateHero()
end

function UIGdHoFightPrepare:SetStage_2()
    CS.ShowObject(self.mStage_1, false)
    CS.ShowObject(self.mStage_2, true)
    CS.ShowObject(self.mFightBtn, true)
    --请求双方的公会信息
    gModelGuildHolyBattle:SendGuildBattleMatchReq(1)
    gModelGuildHolyBattle:SendGuildBattleParticipationInfoReq()

    --设置时间
    self._stageEndTime = gModelGuildHolyBattle:GetStageEndTime()
    self:SetLeftTime()
    self:TimerStart(self._timeKey, 1, false, -1)
    self:InitEffectMpap()
end

--region 初始化部分 --------------------------------------------------------------------------------
function UIGdHoFightPrepare:InitData()


    local ref = GameTable.SupportTipsRef[17]
    if ref then
        self._uiHelpTips = ccLngText(ref.text)
    else
        self._uiHelpTips = "17-------no config"
    end

    self._timeKey = "UIGdHoFightPrepare_TimeKey" -- 每隔1S刷新一次
end
--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIGdHoFightPrepare