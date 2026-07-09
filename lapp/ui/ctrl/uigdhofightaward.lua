---
--- Created by Administrator.
--- DateTime: 2024/6/20 20:38:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightAward:LWnd
local UIGdHoFightAward = LxWndClass("UIGdHoFightAward", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightAward:UIGdHoFightAward()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightAward:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightAward:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightAward:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self._isVie = gLGameLanguage:IsVieVersion()

    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitEvent()
    self:InitText()
    self:InitData()
    self:InitPara()

  
end

--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UIGdHoFightAward:SetTab()
    for k, v in ipairs(self._tabInfo) do
        local offTxt = CS.FindTrans(v.tran, "Off/UIText")
        local onTxt = CS.FindTrans(v.tran, "On/UIText")

        self:SetWndText(offTxt, v.tabText)
        self:SetWndText(onTxt, v.tabText)

        if self._isVie then
            local text = offTxt
            self:InitTextLineWithLanguage(text, 0)
            LxUiHelper.SetSizeWithCurAnchor(text,0,120)
            self:InitTextSizeWithLanguage(text,-4)
            local uiText =LxUiHelper.FindXTextCtrl(text)
            uiText.characterSpacing = -4
            text = onTxt
            self:InitTextLineWithLanguage(text, 0)
            LxUiHelper.SetSizeWithCurAnchor(text,0,120)
            self:InitTextSizeWithLanguage(text,-4)
            uiText =LxUiHelper.FindXTextCtrl(text)
            uiText.characterSpacing = -4
        end
        if self.jpj then
            local text = offTxt
            self:InitTextLineWithLanguage(text, -40) --
            LxUiHelper.SetSizeWithCurAnchor(text,0,120)
            self:InitTextSizeWithLanguage(text,-4)
            local uiText =LxUiHelper.FindXTextCtrl(text)
            uiText.characterSpacing = -4
            text = onTxt
            self:InitTextLineWithLanguage(text, -40) --
            LxUiHelper.SetSizeWithCurAnchor(text,0,120)
            self:InitTextSizeWithLanguage(text,-4)
            uiText =LxUiHelper.FindXTextCtrl(text)
            uiText.characterSpacing = -4
        end

        self:SetWndClick(v.tran, v.clickFunc)
    end
end

function UIGdHoFightAward:CreateTaskList(list, item, itemdata, itempos)
    local refId = itemdata:GetRefId()
    local cfg = gModelQuest:GetTaskConfig(refId)

    --标题
    local Title = CS.FindTrans(item, "Title_Bg/Title")
    if cfg then
        local textId = cfg.description
        self:SetWndText(Title, ccLngText(textId))
    end

    --奖励
    local RewardList = CS.FindTrans(item, "RewardList")
    local rewards = gModelQuest:GetRewardList(refId)
    if rewards then
        self:InitItemList(RewardList, rewards)
    end

    --
    local schedule = tonumber(itemdata:GetSchedule())
    local goal = tonumber(itemdata:GetGoal())
    local scheduleStr = LUtil.NumberCoversion(schedule)
    local goalStr = LUtil.NumberCoversion(goal)

    local str = string.format("%s/%s", scheduleStr, goalStr)

    local state = itemdata:GetState()
    --领取状态
    local NoEnought = CS.FindTrans(item, "NoEnought")

    local Get = CS.FindTrans(item, "Get")
    local GetUIText = CS.FindTrans(Get, "UIText")

    local Got = CS.FindTrans(item, "Got")

    self:SetWndText(GetUIText, ccClientText(16207))  --[16207]  可領取

    CS.ShowObject(NoEnought, state == 0)
    CS.ShowObject(Get, state == 1)
    CS.ShowObject(Got, state == 2)

    self:SetWndClick(Get, function()
        self:OnClickTask(itemdata, Get)
    end)

    --进度条
    local ScheduleBg = CS.FindTrans(item, "ScheduleBg")
    local ScheduleNum = CS.FindTrans(ScheduleBg, "ScheduleNum")
    local ScheduleBar = CS.FindTrans(ScheduleBg, "ScheduleBar")
    CS.ShowObject(ScheduleBg, true)

    self:SetWndText(ScheduleNum, str)

    --local color = "ffffffff"
    --if schedule >= goal then
    --    color = "139057ff"
    --end
    --self:SetXUITextTransColor(ScheduleNum, color)

    --		self._image.fillAmount = value
    local value = 0
    if goal > 0 then
        value = schedule / goal
    end
    LxUiHelper.SetProgress(ScheduleBar, value)

    local isfinish = gModelQuest:IsTaskFinish(refId)
    if isfinish and state == 1 then
        CS.ShowObject(NoEnought, false)
        CS.ShowObject(Get, true)
        CS.ShowObject(Got, false)

    elseif isfinish then
        CS.ShowObject(NoEnought, false)
        CS.ShowObject(Get, false)
        CS.ShowObject(Got, true)

        CS.ShowObject(ScheduleBg, false)

    end
end

function UIGdHoFightAward:CreateRankList(list, item, itemdata, itempos)
    --排名
    local rank = string.split(itemdata.rank, ",")
    local RankNum = CS.FindTrans(item, "RankNum")
    local RankImg = CS.FindTrans(item, "RankImg")
    local numStr
    if tonumber(rank[1]) == tonumber(rank[2]) then
        numStr = rank[1]

    else
        numStr = string.format("%s~%s", rank[1], rank[2])
    end

    self:SetWndText(RankNum, numStr)

    if tonumber(rank[1]) <= 3 then
        CS.ShowObject(RankImg, true)
        CS.ShowObject(RankNum, false)
        local rankImg = LUtil.GetRankImg(tonumber(rank[1]))

        self:SetWndEasyImage(RankImg, rankImg)
    end

    --奖励
    local rankData = LxDataHelper.ParseItem(itemdata.reward)
    local RewardList_1 = CS.FindTrans(item, "RewardList_1")
    self:InitItemList(RewardList_1, rankData)

    --额外奖励
    local rankwinData = LxDataHelper.ParseItem(itemdata.winReward)
    local RewardList_2 = CS.FindTrans(item, "RewardList_2")
    self:InitItemList(RewardList_2, rankwinData)
end

function UIGdHoFightAward:InitTaskInfo()
    self._taskTypeInfo = {
        [1] = ModelQuest.GuildHolyBattle_Self,
        [2] = ModelQuest.GuildHolyBattle_Guild,
    }
end

function UIGdHoFightAward:InitTabInfo()
    self._tabInfo = {
        [1] = {

            tran = self.mTab_1,
            clickFunc = function()
                self:OnChangeTabState(1)
                self:SetTaskList(1)
            end,
            titleBg = "guildwar1_target1",
            tabText = ccClientText(44040), --[44040] [個人目標]
            checkRedPointFunc = function()
                local isShow = gModelGuildHolyBattle:CheckRedPointTaskSelf()
                return isShow
            end,
        },
        [2] = {
            tran = self.mTab_2,
            clickFunc = function()
                self:OnChangeTabState(2)
                self:SetTaskList(2)
            end,
            titleBg = "guildwar1_target2",
            tabText = ccClientText(44041), --[44041] [龍騎團目標]
            checkRedPointFunc = function()

                local isShow = gModelGuildHolyBattle:CheckRedPointTaskGuild()
                return isShow
            end,
        },
        [3] = {
            tran = self.mTab_3,
            clickFunc = function()
                self:OnChangeTabState(3)
                self:SetRankList()
                gModelGuildHolyBattle:SendGuildBattlePlayerRankReq()
            end,
            titleBg = "guildwar1_rank",
            tabText = ccClientText(44042), --[44042] [排行獎勵]
            checkRedPointFunc = function()
                return false
            end,
        },
    }

    self:SetTab()
end

function UIGdHoFightAward:SetTaskList(tabIndex)
    CS.ShowObject(self.mTaskList, true)
    CS.ShowObject(self.mRank, false)

    local type = self._taskTypeInfo[tabIndex]
    local taskData = gModelQuest:GetTaskList(type)
    taskData = self:CreateTaskSort(taskData)
    local uiList = self._taskList

    if not uiList then
        uiList = self:GetUIScroll(self.mTaskList:GetInstanceID())
        uiList:Create(self.mTaskList, taskData, function(...)
            self:CreateTaskList(...)
        end, UIItemList.SUPER)
        self._taskList = uiList
    else
        uiList:RefreshList(taskData)
        uiList:DrawAllItems(true)
    end

    uiList:MoveToPos(1)
end

function UIGdHoFightAward:SetRankList()
    CS.ShowObject(self.mTaskList, false)
    CS.ShowObject(self.mRank, true)

    --去model类哪里那一次数据
    local rankRewardData = gModelGuildHolyBattle:GetRankReward()
    local uiList = self._rankList

    if not uiList then
        uiList = self:GetUIScroll(self.mRankRewardList:GetInstanceID())
        uiList:Create(self.mRankRewardList, rankRewardData, function(...)
            self:CreateRankList(...)
        end, UIItemList.SUPER)
        self._rankList = uiList
    else
        uiList:RefreshList(rankRewardData)
        uiList:DrawAllItems(true)
    end
end
--走任务系统的接口

--region 页面初始化 --------------------------------------------------------------------------------
function UIGdHoFightAward:InitText()
    self:SetWndText(self.mNoDes, ccClientText(11722))  --[沒有獎勵]@rem 未上榜沒有獎勵

    self:SetWndText(self.mCloseTip, ccClientText(10103))

    self:SetWndText(self.mTitle_1, ccClientText(28105)) --[28105]	[排名]
    self:SetWndText(self.mTitle_2, ccClientText(44069)) --[44069] [獎勵內容]
    self:SetWndText(self.mTitle_3, ccClientText(44070)) --[44070] [獲勝獎勵]
end

function UIGdHoFightAward:SetNoSelfRank()
    local RankNum = CS.FindTrans(self.mSelfInfo, "RankNum")
    local RewardList_1 = CS.FindTrans(self.mSelfInfo, "RewardList_1")
    local RewardList_2 = CS.FindTrans(self.mSelfInfo, "RewardList_2")
    self:SetWndText(RankNum, ccClientText(19526))
    CS.ShowObject(RewardList_1, false)
    CS.ShowObject(RewardList_2, false)
    CS.ShowObject(self.mNoDes, true)

end

function UIGdHoFightAward:SetTabRedPoint()
    for k, v in ipairs(self._tabInfo) do
        local redPoint = CS.FindTrans(v.tran, "redPoint")
        local isShow = v.checkRedPointFunc()
        CS.ShowObject(redPoint, isShow)
    end
end

function UIGdHoFightAward:InitPara()
    self._para = self:GetWndArg("para")
    local tabIndex = 1
    if self._para then
        tabIndex = self._para.tabIndex
    end
    self._curtabIndex = tabIndex
    self._tabInfo[tabIndex].clickFunc()
end

function UIGdHoFightAward:OpenReq()

end

function UIGdHoFightAward:SetSelfRankInfo()
    local rank = gModelGuildHolyBattle:GetSelfRank()

    if not rank then
        self:SetNoSelfRank()
    else
        local rankNum = rank.rank
        local rankRewardData = gModelGuildHolyBattle:GetRankReward()
        local showRef

        local temp_1, temp_2 = 0, 0
        for k, v in ipairs(rankRewardData) do
            local rank = string.split(v.rank, ",")
            if rankNum >= tonumber(rank[1]) and rankNum <= tonumber(rank[2]) then
                temp_1 = tonumber(rank[1])
                temp_2 = tonumber(rank[2])
                showRef = v
                break
            end
        end

        if not showRef then
            self:SetNoSelfRank()
        else

            --奖励
            local rankData = LxDataHelper.ParseItem(showRef.reward)
            local RewardList_1 = CS.FindTrans(self.mSelfInfo, "RewardList_1")
            CS.ShowObject(RewardList_1, true)
            self:InitItemList(RewardList_1, rankData)

            --额外奖励
            local rankwinData = LxDataHelper.ParseItem(showRef.winReward)
            local RewardList_2 = CS.FindTrans(self.mSelfInfo, "RewardList_2")
            CS.ShowObject(RewardList_2, true)
            self:InitItemList(RewardList_2, rankwinData)

            CS.ShowObject(self.mNoDes, false)

            local RankNum = CS.FindTrans(self.mSelfInfo, "RankNum")
            local RankImg = CS.FindTrans(self.mSelfInfo, "RankImg")
            if temp_1 == temp_2 then
                self:SetWndText(RankNum, rankNum)
            else
                self:SetWndText(RankNum, string.format("%s~%s", temp_1, temp_2))
            end

            if rank[1] and tonumber(rank[1]) <= 3 then
                CS.ShowObject(RankImg, true)
                CS.ShowObject(RankNum, false)
                local rankImg = LUtil.GetRankImg(tonumber(rank[1]))

                self:SetWndEasyImage(RankImg, rankImg)
            end

        end


    end
end

function UIGdHoFightAward:InitItemList(root, itemList)
    local instanceId = root:GetInstanceID()
    local uiList = self._uiListTbl[instanceId]
    if not uiList then
        uiList = UIIconEasyList:New()
        self._uiListTbl[instanceId] = uiList
        uiList:Create(self, root)
        uiList:SetShowNum(false)
        uiList:SetIconParentPath("itemRoot/CommonUI/Icon")
        uiList:SetShowExtraNum(true, "itemNum")
    end
    uiList:RefreshList(itemList)
end

function UIGdHoFightAward:CreateTaskSort(taskData)
    local list = {}

    for k, itemdata in ipairs(taskData) do
        local refId = itemdata:GetRefId()
        itemdata.sort = refId * 100000

        local state = itemdata:GetState()

        if state == 0 then
            --未完成
            itemdata.sort = itemdata.sort + 100000
        elseif state == 1 then
            --完成
            itemdata.sort = itemdata.sort - 100000
        elseif state == -1 or state == 2 then
            --已领取
            itemdata.sort = itemdata.sort + 10000000
        end

        table.insert(list, itemdata)
    end

    table.sort(list, function(a, b)
        return a.sort < b.sort
    end)

    return list
end

function UIGdHoFightAward:InitEvent()
    self:WndEventRecv(EventNames.ON_QUEST_CHANGE, function(...)
        if self._curtabIndex == 1 or self._curtabIndex == 2 then
            self:SetTaskList(self._curtabIndex)
            self:SetTabRedPoint()
        end
    end)

    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.RankDataChange, function()
        if self._curtabIndex == 3 then
            self:SetSelfRankInfo()
        end
    end)


    --ui
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)


end

function UIGdHoFightAward:InitData()
    self._uiListTbl = {}

    self:InitTabInfo()
    self:InitTaskInfo()
end
--endregion --------------------------------------------------------------------------------------

--region 事件回调 --------------------------------------------------------------------------------
--ui
function UIGdHoFightAward:OnChangeTabState(tabIndex)
    for k, v in ipairs(self._tabInfo) do
        local off = CS.FindTrans(v.tran, "Off")
        local on = CS.FindTrans(v.tran, "On")
        CS.ShowObject(off, not (k == tabIndex))
        CS.ShowObject(on, k == tabIndex)

        local titleImgKey = "TitleImg_" .. k
        local titleImgTran = CS.FindTrans(self.mTitleImg, titleImgKey)
        CS.ShowObject(titleImgTran, k == tabIndex)
        if k == tabIndex then
            self:SetWndEasyImage(self.mTitleImg, v.titleBg)
        end


    end

    self._curtabIndex = tabIndex
end

function UIGdHoFightAward:OnClickTask(itemdata, bgItemList)
    local refId = itemdata:GetRefId()
    local state = itemdata:GetState()
    local cfg = gModelQuest:GetTaskConfig(refId)
    if state == ModelQuest.TASK_UNFINISH then
        local originId = cfg.originId
        if originId > 0 then
            gModelQuest:TaskGoto(refId, self:GetWndName())
        else
            GF.ShowMessage(ccClientText(12210))
        end
    elseif state == ModelQuest.TASK_FINNISH then
        --self:ShowPassEEffect(bgItemList)
        gModelQuest:OnQuestReceiveReq(refId)
    elseif state == ModelQuest.TASK_REWARDED then
        GF.ShowMessage(ccClientText(12211))
    elseif state == ModelQuest.TASK_LOCK then
        local str = string.replace(ccClientText(12219), ccLngText(cfg.unlockTip))
        GF.ShowMessage(str)
    end

end
--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UIGdHoFightAward