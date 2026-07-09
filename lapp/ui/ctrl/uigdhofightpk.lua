---
--- Created by Administrator.
--- DateTime: 2024/9/5 15:19:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightPk:LWnd
local UIGdHoFightPk = LxWndClass("UIGdHoFightPk", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightPk:UIGdHoFightPk()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightPk:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightPk:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightPk:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self._isEnus = gLGameLanguage:IsEnglishVersion() or gLGameLanguage:IsVieVersion()
    
    self:InitCommon()
    gModelGuildHolyPeak:GuildPinnacleStageReq()
    gModelGuildHolyPeak:GuildPinnacleGuildInfoReq()
    gModelRank:OnRankReq(2, gModelRank.RANK_HOLY_BATTLE, 1, 1)
end

function UIGdHoFightPk:SetRankItem(trans, data, rank)
    local on = CS.FindTrans(trans, "On")
    local flag = CS.FindTrans(on, "Flag")
    local icon = CS.FindTrans(on, "Icon")
    local serverText = CS.FindTrans(on, "ServerText")
    local nameText = CS.FindTrans(on, "NameText")
    local off = CS.FindTrans(trans, "Off")
    local offText = CS.FindTrans(off, "Text")
    local rankText = CS.FindTrans(trans, "RankBg/RankText")
    local rankBg = CS.FindTrans(trans, "RankBg")
    if self._isEnus then
        rankBg.sizeDelta = Vector2.New(120, 25)
    else
        rankBg.sizeDelta = Vector2.New(63, 20)
    end

    self:SetWndText(rankText, gModelGuildHolyPeak:GetRankTextByRank(rank))
    if not data then
        self:SetWndText(offText, ccClientText(11707))
    else
        local flagRes = gModelGuild:GetGuildFlagRefByRefId(data.flagBgId).res
        local iconRes = gModelGuild:GetGuildFlagRefByRefId(data.flagId).res
        self:SetWndEasyImage(flag, flagRes)
        self:SetWndEasyImage(icon, iconRes)
        self:SetWndText(serverText, "[" .. gLGameLogin:GetServerShotNameById(data.serverId) .. "]")
        self:SetWndText(nameText, data.guildName)
        self:SetTextOutLineByColor(serverText, "black")
        self:SetTextOutLineByColor(nameText, "black")

        if rank == 1 then
            self:CreateWndEffect(on, "fx_ui_sqzz_guanjun", "rank1", 100)
        elseif rank == 2 then
            self:CreateWndEffect(on, "fx_ui_sqzz_yajun", "rank2", 100)
        elseif rank == 3 then
            self:CreateWndEffect(on, "fx_ui_sqzz_jijun", "rank3", 100)
        end
    end
    CS.ShowObject(on, data ~= nil)
    CS.ShowObject(off, data == nil)

    self:SetWndClick(trans, function()
        if data then
            gModelGuild:OnGuildMemberListReq(data.guildId, data.serverId)
        end
    end)
end

function UIGdHoFightPk:UpdateRank()
    local rankInfo = gModelGuildHolyPeak:GetGuildInfoList()
    local list, mList = {}, {}
    for _, v in ipairs(rankInfo) do
        if v.rank > 0 and v.rank <= 4 then
            list[v.rank] = v
        end
        if v.rank == 8 then
            table.insert(mList, v)
        end
    end

    for i = 1, 4 do
        local trans = CS.FindTrans(self.mRankObj, "Rank" .. i)
        self:SetRankItem(trans, list[i], i)
    end
    for i = 1, 4 do
        local rank = 4 + i
        local trans = CS.FindTrans(self.mRankObj, "Rank" .. rank)
        self:SetRankItem(trans, mList[i], rank)
    end
end

function UIGdHoFightPk:UpdateInfo()
    self:SetWndText(self.mStateText, gModelGuildHolyPeak:GetStateText())
end

function UIGdHoFightPk:InitCommon()
    ------------------------------------------------------------------
    ---click
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mNowRank, function()
        GF.OpenWnd("UIGdHoFightRk")
    end)
    self:SetWndClick(self.mBeforeRank, function()
        GF.OpenWnd("UIGdHoFightPkRk")
    end)
    self:SetWndClick(self.mFightBtn, function()
        GF.OpenWnd("UIGdHoFightPkSchedule")
    end)
    self:SetWndClick(self.mTeamBtn, function()
        local stage = gModelGuildHolyPeak:GetStage()
        if stage > 2 then
            GF.ShowMessage(ccClientText(46040))
            return
        end
        GF.OpenWnd("UIGdHoFightPkTeam")
    end)
    self:SetWndClick(self.mLookRank, function()
        GF.OpenWnd("UIGdHoFightRk")
    end)
    self:SetWndClick(self.mHelpBtn, function()
        GF.OpenWnd("UIBzTips", { refId = 18 })
    end)
    self:SetWndClick(self.mRewardBtn, function()
        GF.OpenWnd("UIGdHoFightPkAward")
    end)
    self:SetWndClick(self.mCrossTag, function()
        local serverList, groupId = gModelGuildHolyBattle:GetServers()
        GF.OpenWnd("UIKfSyerGroupingPop", {
            wndType = 2,
            groupId = groupId,
            serverList = serverList
        })
    end)

    self:SetWndClick(self.mCrossTag_Enus, function()
        local serverList, groupId = gModelGuildHolyBattle:GetServers()
        GF.OpenWnd("UIKfSyerGroupingPop", {
            wndType = 2,
            groupId = groupId,
            serverList = serverList
        })
    end)

    ------------------------------------------------------------------
    ---text
    self:SetWndText(self.mTxtClose, ccClientText(42010))
    self:SetWndText(self.mTitle, ccClientText(46002))
    self:SetWndText(self.mOpenTitle, ccClientText(46003))
    self:SetWndText(self.mOpenTime, ccClientText(46004))
    self:SetWndText(self.mConditions, ccClientText(46005))
    self:SetWndText(CS.FindTrans(self.mLookRank, "Text"), ccClientText(46006))
    self:SetWndText(CS.FindTrans(self.mNowRank, "Text"), ccClientText(46007))
    self:SetWndText(CS.FindTrans(self.mBeforeRank, "Text"), ccClientText(46008))
    self:SetWndText(CS.FindTrans(self.mTeamBtn, "Text"), ccClientText(46009))
    self:SetWndText(CS.FindTrans(self.mRewardBtn, "Text"), ccClientText(11715))
    self:SetWndButtonText(self.mFightBtn, ccClientText(46010))
    self:SetTextTile(self.mCrossTag, ccClientText(44066))
    self:SetTextTile(self.mCrossTag_Enus, ccClientText(44066))

    ---适配
    if self._isEnus then
        LxTimer.DelayFrameCall(function()
            local desUIText = LxUiHelper.FindXTextCtrl(self.mOpenTitle)
            local curwidth = desUIText.preferredWidth
            LxUiHelper.SetSizeWithCurAnchor(self.mBg3, 0, curwidth + 50)
        end)
    end

    if gLGameLanguage:IsVieVersion() then
        local text = CS.FindTrans(self.mRewardBtn, "Text")
        self:InitTextLineWithLanguage(text,0)
    end
    ------------------------------------------------------------------
    ---event
    self:WndEventRecv("GuildPinnacleStageResp", function()
        self:UpdateInfo()
    end)
    self:WndEventRecv("GuildPinnacleGuildInfoResp", function()
        self:UpdateRank()

        local isJoin = gModelGuildHolyPeak:GetIsJoin()
        CS.ShowObject(self.mTeamBtn, isJoin)

        local isCross = gModelGuildHolyPeak:GetCross() == 1
        CS.ShowObject(self.mCrossTag, isCross and (not self._isEnus))
        CS.ShowObject(self.mCrossTag_Enus, isCross and self._isEnus)
    end)

    ------------------------------------------------------------------
    ---resp
    self:WndNetMsgRecv(LProtoIds.RankResp, function(pb)
        if pb.rankType ~= gModelRank.RANK_HOLY_BATTLE then
            return
        end
        local rank = pb.selfRank.rank
        local s = rank > 0 and string.replace(ccClientText(46011), rank) or ccClientText(42017)
        self:SetWndText(self.mSelfRank, s)
    end)

    ------------------------------------------------------------------
    ---eff
    self:CreateWndEffect(self.mBg, "fx_ui_sqzz_beijing_zhujiemian", "bg", 100)
end

------------------------------------------------------------------
return UIGdHoFightPk