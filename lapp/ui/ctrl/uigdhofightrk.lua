---
--- Created by Administrator.
--- DateTime: 2024/6/21 10:36:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightRk:LWnd
local UIGdHoFightRk = LxWndClass("UIGdHoFightRk", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightRk:UIGdHoFightRk()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightRk:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightRk:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightRk:OnStart()
    LWnd.OnStart(self)
    self:InitUI()


    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitEvent()
    self:InitText()
    self:InitData()
    self:InitPara()
end

--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UIGdHoFightRk:SetTab()
    for k, v in ipairs(self._tabInfo) do
        local offTxt = CS.FindTrans(v.tran, "Off/UIText")
        local onTxt = CS.FindTrans(v.tran, "On/UIText")

        self:SetWndText(offTxt, v.tabText)
        self:SetWndText(onTxt, v.tabText)

        self:SetWndClick(v.tran, v.clickFunc)
    end
end

function UIGdHoFightRk:SetScoreListRank()
    local uiList = self._scoreList

    if not uiList then
        uiList = self:GetUIScroll(self.mPlayerCellScroll:GetInstanceID())
        uiList:Create(self.mPlayerCellScroll, self._otherScoreRankData, function(...)
            self:CreateScoreList(...)
        end)

        self._scoreList = uiList
    else
        uiList:RefreshList(self._otherScoreRankData)
        uiList:DrawAllItems(true)
    end

    uiList:EnableScroll(true, false)
end

--endregion --------------------------------------------------------------------------------------

--region 事件回调 --------------------------------------------------------------------------------
function UIGdHoFightRk:OnScoreRankInfo()
    self._selfScoreRank = gModelGuildHolyBattle:GetSelfRank()
    local ranks = gModelGuildHolyBattle:GetRank()
    --构建前三的数据和列表的数据和自己的数据
    self._threeScoreRankData = {}
    self._otherScoreRankData = {}
    for k, v in ipairs(ranks) do
        if #self._threeScoreRankData < 3 then
            table.insert(self._threeScoreRankData, v)
        else
            table.insert(self._otherScoreRankData, v)
        end
    end

    if #self._otherScoreRankData < 22 then
        for i = #self._otherScoreRankData + 1, 22 do
            local data = { isNotData = true }
            table.insert(self._otherScoreRankData, data)
        end
    end

    self:SetScoreRank()
    self:SetScoreListRank()
    self:SetSelfScoreRank()
end

function UIGdHoFightRk:InitPara()
    self._para = self:GetWndArg("para")
    local tabIndex = 1
    if self._para then
        tabIndex = self._para.tabIndex
    end

    self._tabInfo[tabIndex].clickFunc()
end

function UIGdHoFightRk:SetScoreRank()
    for i = 1, 3 do
        local rankData = self._threeScoreRankData[i]
        local rankRootKey = "Rank" .. i

        local rankRoot = CS.FindTrans(self.mPlayerRank, rankRootKey)

        local playIcon = self:FindWndTrans(rankRoot, "Mask/PlayIcon")
        local PlayerName = self:FindWndTrans(rankRoot, "PlayerName")
        local Score = self:FindWndTrans(rankRoot, "Score")
        local GuildLvText = self:FindWndTrans(Score, "GuildLvText")
        if rankData then
            CS.ShowObject(Score, true)

            self:SetHeroPaint(playIcon, rankData.info, 2)
            self:SetWndText(PlayerName, rankData.info._name)
            self:SetWndText(GuildLvText, rankData.score)

        else
            CS.ShowObject(Score, false)
            self:SetWndText(PlayerName, string.format("【%s】", ccClientText(11707)))

        end
    end
end

function UIGdHoFightRk:OnGuildRankInfo()
    local ranks = gModelRank:GetRankListInfo(2, gModelRank.RANK_HOLY_BATTLE)

    --构建前三的数据和列表的数据和自己的数据
    self._threeGuildRankData = {}
    self._otherGuildRankData = {}

    for i, v in ipairs(ranks) do
        v.index = i
        if #self._threeGuildRankData < 3 then
            table.insert(self._threeGuildRankData, v)
        else
            table.insert(self._otherGuildRankData, v)
        end
    end

    if #self._otherGuildRankData < 22 then
        local pos = #self._otherGuildRankData

        for i = pos + 1, 22 do
            local data = { isNotData = true }
            table.insert(self._otherGuildRankData, data)
        end
    end
    self:SetGuildRank()
    self:SetGuildListRank()
    self:SetSelfGuildRank()
end

function UIGdHoFightRk:CreateScoreList(list, item, itemdata, itempos)
    local RankText = CS.FindTrans(item, "RankText")
    local HeadIconTran = CS.FindTrans(item, "HeadIcon")
    local PlayerName = CS.FindTrans(item, "PlayerName")
    local Score = CS.FindTrans(item, "Score/GuildLvText")
    if itemdata.isNotData then
        self:SetWndText(PlayerName, ccClientText(11711))   --[11711]	[暫無上榜騎士]
        self:SetWndText(Score, 0)
        self:SetWndText(RankText, string.format("%s", itempos + 3))
        return
    end
    --排名
    self:SetWndText(RankText, itemdata.rank)

    --头像
    local info = {
        icon = itemdata.info._head,
        headFrame = itemdata.info._headFrame,
        level = itemdata.info._grade,
    }
    local InstanceID = item:GetInstanceID()
    if not self._uiheadList then
        self._uiheadList = {}
    end
    local baseClass = self._uiheadList[InstanceID]
    if not baseClass then
        baseClass = HeadIcon:New(self)
        self._uiheadList[InstanceID] = baseClass
    end
    info.trans = HeadIconTran
    --info._uiIconBgTrans= HeadIconTran
    baseClass:SetHeadData(info)

    --名字
    self:SetWndText(PlayerName, itemdata.info._name)

    --积分
    self:SetWndText(Score, itemdata.score)
end

function UIGdHoFightRk:InitData()
    self._rankPage = 1
    self._rankPageSize = 25

    self:InitTabInfo()
end

function UIGdHoFightRk:SetGuildListRank()
    local uiList = self._guildList

    if not uiList then
        uiList = self:GetUIScroll(self.mGuildCellScroll:GetInstanceID())
        uiList:Create(self.mGuildCellScroll, self._otherGuildRankData, function(...)
            self:CreateGuildList(...)
        end, UIItemList.WRAP)
        self._guildList = uiList

        local tuiList = uiList:GetList()
        tuiList:EnableLoadAnimation(true, 0.03, 1, 2)
        tuiList:SetLoadAnimationScale(nil, 0.03)
        --tuiList:RefreshSimpleList(UIListWrap.RefreshMode.Top)
    else
        --uiList:RefreshList(self._otherGuildRankData)
        --uiList:DrawAllItems(true)
        uiList:RefreshData(self._otherGuildRankData)
        local tuiList = uiList:GetList()
        tuiList:EnableLoadAnimation(false)
        tuiList:RefreshSilent()
    end

    uiList:EnableScroll(true, false)
end

--玩家自己的积分成绩
function UIGdHoFightRk:SetSelfScoreRank()
    local RankImg = CS.FindTrans(self.mMePlayerRankItem, "RankImg")
    local RankText = CS.FindTrans(self.mMePlayerRankItem, "RankText")
    local HeadIconTran = CS.FindTrans(self.mMePlayerRankItem, "HeadIcon")
    local PlayerName = CS.FindTrans(self.mMePlayerRankItem, "PlayerName")
    local Score = CS.FindTrans(self.mMePlayerRankItem, "Score/GuildLvText")

    local MeTitleText = CS.FindTrans(self.mMePlayerRankItem, "Image/MeTitleText")
    self:SetWndText(MeTitleText, ccClientText(10339)) --[10339]	[我的排名]
    local empty = {}
    local isempty = false
    if not self._selfScoreRank or self._selfScoreRank.rank == 0 then
        isempty = true
        --无数据设置  直接填充嘛
        empty.info = {
            _head = gModelPlayer:GetPlayerHead(),
            _headFrame = gModelPlayer:GetPlayerHeadFrame(),
            _grade = gModelPlayer:GetPlayerLv(),
        }
        self._selfScoreRank.rank = -1
        self._selfScoreRank.info._name = gModelPlayer:GetPlayerName()
        self._selfScoreRank.score = 0
    end

    if self._selfScoreRank.rank > 0 and self._selfScoreRank.rank <= 3 then
        CS.ShowObject(RankImg, true)
        CS.ShowObject(RankText, false)

        local img = self:GetRankImg(self._selfScoreRank.rank)

        self:SetWndEasyImage(RankImg, img)
    else
        CS.ShowObject(RankImg, false)
        CS.ShowObject(RankText, true)
    end

    if self._selfScoreRank.rank == -1 then
        self:SetWndText(RankText, ccClientText(10363))
    else
        self:SetWndText(RankText, self._selfScoreRank.rank)
    end

    local info = {
        icon = isempty and empty.info._head or self._selfScoreRank.info._head,
        headFrame = isempty and empty.info._headFrame or self._selfScoreRank.info._headFrame,
        level = isempty and empty.info._grade or self._selfScoreRank.info._grade,
    }
    local InstanceID = self.mMePlayerRankItem:GetInstanceID()
    if not self._uiheadList then
        self._uiheadList = {}
    end
    local baseClass = self._uiheadList[InstanceID]
    if not baseClass then
        baseClass = HeadIcon:New(self)
        self._uiheadList[InstanceID] = baseClass
    end
    info.trans = HeadIconTran
    baseClass:SetHeadData(info)

    self:SetWndText(Score, self._selfScoreRank.score)

    self:SetWndText(PlayerName, self._selfScoreRank.info._name)
end

function UIGdHoFightRk:CreateGuildList(list, item, itemdata, itempos)
    if not itemdata then
        return
    end

    local rankData = itemdata
    local rankRoot = item

    local RankText = CS.FindTrans(item, "RankText")

    local Group = CS.FindTrans(item, "Group")
    local FlagBg = CS.FindTrans(rankRoot, "FlagBg")
    local FlagIcon = CS.FindTrans(FlagBg, "FlagIcon")
    local GuildLvText = CS.FindTrans(FlagBg, "GuildLvBg/GuildLvText")
    local ServerText = CS.FindTrans(rankRoot, "Group/ServerText")
    local GuildNameText = CS.FindTrans(rankRoot, "Group/GuildNameText")
    local NameText = CS.FindTrans(rankRoot, "Group/NameText")
    local Score = CS.FindTrans(rankRoot, "Score/GuildLvText")
    local ScoreRoot = CS.FindTrans(rankRoot, "Score")
    local NoText = CS.FindTrans(rankRoot, "NoText")
    if itemdata.isNotData then
        CS.ShowObject(Group, false)
        CS.ShowObject(FlagBg, false)
        CS.ShowObject(ScoreRoot, false)
        CS.ShowObject(NoText, true)
        local rankStr = string.format("%s", itempos + 3)
        self:SetWndText(RankText, rankStr)
        self:SetWndText(NoText, ccClientText(11736))  --[11736]	[暫無上榜龍騎團]
        return
    end

    CS.ShowObject(Group, true)
    CS.ShowObject(FlagBg, true)
    CS.ShowObject(ScoreRoot, true)
    CS.ShowObject(NoText, false)

    local rankStr = string.format("%s", itemdata.rank)
    self:SetWndText(RankText, rankStr)

    local fragRef = gModelGuild:GetGuildFlagRefByRefId(rankData.flagId)
    local fragBgRef = gModelGuild:GetGuildFlagRefByRefId(rankData.flagBgId)

    self:SetWndEasyImage(FlagBg, fragBgRef.res, nil, false)
    self:SetWndEasyImage(FlagIcon, fragRef.res, nil, false)

    self:SetWndText(GuildLvText, rankData.guildLevel)

    --self:SetWndText(ServerText, rankData.info._serverName)
    self:SetWndText(ServerText, string.format("【%s】", rankData.info._serverName))
    self:SetWndText(GuildNameText, rankData.info._guildName)
    self:SetWndText(NameText, rankData.info._name)

    local scoreStr = string.replace(ccClientText(44054), rankData.score)

    self:SetWndText(Score, scoreStr)

    self:SetWndClick(FlagBg, function()
        local isopen = gModelFunctionOpen:CheckIsOpened(12100000, true)
        if isopen then
            gModelGuild:OnGuildMemberListReq(rankData.info._guildId, rankData.info._serverId)
        end
    end)

    if itemdata.index >= (self._rankPage * self._rankPageSize - 3) then
        local num = gModelRank:GetRankQuantity(gModelRank.RANK_HOLY_BATTLE)
        if num and num > self._rankPage * self._rankPageSize then
            self._rankPage = self._rankPage + 1
            self:SendRankReq()
        end
    end
end

--设置公会的排行榜
function UIGdHoFightRk:SetGuildRank()
    for i = 1, 3 do
        local rankData = self._threeGuildRankData[i]
        local rankRootKey = "Rank" .. i

        local rankRoot = CS.FindTrans(self.mGuildRank, rankRootKey)
        --旗子
        local FlagBg = CS.FindTrans(rankRoot, "FlagBg")
        local FlagIcon = CS.FindTrans(FlagBg, "FlagIcon")
        --lv
        local GuildLvText = CS.FindTrans(FlagBg, "GuildLvBg/GuildLvText")
        --服务器名字
        local ServerText = CS.FindTrans(rankRoot, "ServerText")
        --公会名
        local NameText = CS.FindTrans(rankRoot, "NameText")

        --
        local Score = CS.FindTrans(rankRoot, "Score/GuildLvText")
        local ScoreRoot = CS.FindTrans(rankRoot, "Score")
        if rankData then
            CS.ShowObject(FlagBg, true)
            CS.ShowObject(ScoreRoot, true)

            local fragRef = gModelGuild:GetGuildFlagRefByRefId(rankData.flagId)
            local fragBgRef = gModelGuild:GetGuildFlagRefByRefId(rankData.flagBgId)

            self:SetWndEasyImage(FlagBg, fragBgRef.res, nil, false)
            self:SetWndEasyImage(FlagIcon, fragRef.res, nil, false)

            self:SetWndText(GuildLvText, rankData.guildLevel)

            --self:SetWndText(ServerText, rankData.info._serverName)
            self:SetWndText(ServerText, string.format("【%s】", rankData.info._serverName))

            self:SetWndText(NameText, rankData.info._guildName)

            local scoreStr = string.replace(ccClientText(44054), rankData.score)
            self:SetWndText(Score, scoreStr)

            self:SetWndClick(FlagBg, function()
                local isopen = gModelFunctionOpen:CheckIsOpened(12100000, true)
                if isopen then
                    gModelGuild:OnGuildMemberListReq(rankData.info._guildId, rankData.info._serverId)
                end
            end)
        else
            --置空
            CS.ShowObject(FlagBg, false)
            CS.ShowObject(ScoreRoot, false)

            self:SetWndText(NameText, string.format("【%s】", ccClientText(11707)))
        end
    end
end

--region 页面初始化 --------------------------------------------------------------------------------
function UIGdHoFightRk:InitText()
    self:SetWndText(self.mTitle, ccClientText(44052))
    self:SetWndText(self.mCloseTip, ccClientText(10103))
    if self.jpj then
        local offTxt = CS.FindTrans(self.mTab_1, "Off/UIText")
        local onTxt = CS.FindTrans(self.mTab_1, "On/UIText")
        local offTxt2 = CS.FindTrans(self.mTab_2, "Off/UIText")
        local onTx2t = CS.FindTrans(self.mTab_2, "On/UIText")
        self:InitTextSizeWithLanguage(offTxt,-4)
        self:InitTextSizeWithLanguage(onTxt,-4)
        self:InitTextSizeWithLanguage(offTxt2,-4)
        self:InitTextSizeWithLanguage(onTx2t,-4)
    end
end

function UIGdHoFightRk:SendRankReq()
    gModelRank:OnRankReq(2, gModelRank.RANK_HOLY_BATTLE, self._rankPage, self._rankPageSize)
end


--ui
function UIGdHoFightRk:OnChangeTabState(tabIndex)
    for k, v in ipairs(self._tabInfo) do
        local off = CS.FindTrans(v.tran, "Off")
        local on = CS.FindTrans(v.tran, "On")
        CS.ShowObject(off, not (k == tabIndex))
        CS.ShowObject(on, k == tabIndex)
    end

    CS.ShowObject(self.mGuildRank, tabIndex == 1)
    CS.ShowObject(self.mPlayerRank, tabIndex == 2)
end


--设置立绘
function UIGdHoFightRk:SetHeroPaint(paintTans, info, index)
    --index = 1 文件形象， = 2 英雄形象


    if (info and index == 1) then
        local ref = gModelPlayer:GetRoleAdventureImage(info._figure)
        local key = info._playerId
        if (not ref) then
            return
        end
        self:SetSpine(paintTans, ref, key)
    elseif (info and index == 2) then
        local refId = info.refId
        local starLv = info.star
        local key = info.id or info._playerId
        local ref
        if (info._figure > 0) then
            --ref = gModelHero:GetShowEffectById(info._figure)
            --ref = gModelPlayer:GetRoleAdventureImage(ref.rankingId)
            ref = gModelPlayer:GetRoleAdventureImage(info._figure)
        else
            ref = gModelHero:GetHeroShowRefByRefId(refId, starLv)

            if ref then
                ref = gModelPlayer:GetRoleAdventureImage(ref.rankingId)
            end
        end
        if (not ref) then
            return
        end
        self:SetSpine(paintTans, ref, key)
    end
end

function UIGdHoFightRk:CreateGuildSelfRankData()
    local rankData = {}
    local selfInfo = gModelGuild:GetSelfGuildInfo()

    local guildInfo = gModelGuild:GetGuildInfo()

    rankData.info = selfInfo.info
    rankData.guildLevel = guildInfo.level
    rankData.flagId = guildInfo.flagId
    rankData.flagBgId = guildInfo.flagBgId
    rankData.score = 0
    rankData.rank = -1
    return rankData
end

--拿rank图片--
function UIGdHoFightRk:GetRankImg(rank)
    if rank == 1 then
        return "public_num_1"
    elseif rank == 2 then
        return "public_num_2"
    elseif rank == 3 then
        return "public_num_3"
    end
end

function UIGdHoFightRk:SetSelfGuildRank()

    local rankData = gModelRank:GetMeRank()
    local rankRoot = self.mMeGuildRankItem

    local MeTitleText = CS.FindTrans(rankRoot, "Image/MeTitleText")
    self:SetWndText(MeTitleText, ccClientText(10339)) --[10339]	[我的排名]

    --旗子
    local FlagBg = CS.FindTrans(rankRoot, "FlagBg")
    local FlagIcon = CS.FindTrans(FlagBg, "FlagIcon")
    --lv
    local GuildLvText = CS.FindTrans(FlagBg, "GuildLvBg/GuildLvText")
    --服务器名字
    local ServerText = CS.FindTrans(rankRoot, "Group/ServerText")
    --公会名
    local GuildNameText = CS.FindTrans(rankRoot, "Group/GuildNameText")
    local NameText = CS.FindTrans(rankRoot, "Group/NameText")

    --
    local Score = CS.FindTrans(rankRoot, "Score/GuildLvText")

    if nil == rankData or rankData.rank == 0 then
        --无数据设置
        rankData = self:CreateGuildSelfRankData()

    end

    local fragRef = gModelGuild:GetGuildFlagRefByRefId(rankData.flagId)
    local fragBgRef = gModelGuild:GetGuildFlagRefByRefId(rankData.flagBgId)

    self:SetWndEasyImage(FlagBg, fragBgRef.res, nil, false)
    self:SetWndEasyImage(FlagIcon, fragRef.res, nil, false)
    self:SetWndText(GuildLvText, rankData.guildLevel)
    self:SetWndText(ServerText, string.format("【%s】", rankData.info._serverName))
    self:SetWndText(GuildNameText, rankData.info._guildName)
    self:SetWndText(NameText, rankData.info._name)
    local scoreStr = string.replace(ccClientText(44054), rankData.score)
    self:SetWndText(Score, scoreStr)

    local RankImg = CS.FindTrans(self.mMeGuildRankItem, "RankImg")
    local RankText = CS.FindTrans(self.mMeGuildRankItem, "RankText")
    if rankData.rank > 0 and rankData.rank <= 3 then
        CS.ShowObject(RankImg, true)
        CS.ShowObject(RankText, false)

        local img = self:GetRankImg(rankData.rank)

        self:SetWndEasyImage(RankImg, img)
    else
        CS.ShowObject(RankText, true)
        CS.ShowObject(RankImg, false)
    end

    self:SetWndClick(FlagBg, function()
        local isopen = gModelFunctionOpen:CheckIsOpened(12100000, true)
        if isopen then
            gModelGuild:OnGuildMemberListReq(rankData.info._guildId, rankData.info._serverId)
        end
    end)

    if rankData.rank == -1 then
        self:SetWndText(RankText, ccClientText(10363))
    else
        self:SetWndText(RankText, rankData.rank)
    end
end
function UIGdHoFightRk:InitEvent()
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.RankDataChange, function()
        self:OnScoreRankInfo()
    end)

    self:WndEventRecv(EventNames.RANK_UPDATE_END, function(rankType, rankRefId)
        if rankRefId ~= ModelRank.RANK_HOLY_BATTLE then
            return
        end

        self:OnGuildRankInfo()
    end)

    --ui
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)


end

--设置形象
function UIGdHoFightRk:SetSpine(paintTans, ref, key)
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

function UIGdHoFightRk:InitTabInfo()
    self._tabInfo = {
        [1] = {

            tran = self.mTab_1,
            clickFunc = function()
                self:OnChangeTabState(1)
                self:SendRankReq()
            end,
            tabText = ccClientText(44053), --[44053] [龍騎團排行]
        },
        [2] = {
            tran = self.mTab_2,
            clickFunc = function()
                self._rankPage = 1

                self:OnChangeTabState(2)
                gModelGuildHolyBattle:SendGuildBattlePlayerRankReq()
            end,
            tabText = ccClientText(44021), --[44021] [積分排行]
        },
    }

    self:SetTab()
end
--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UIGdHoFightRk