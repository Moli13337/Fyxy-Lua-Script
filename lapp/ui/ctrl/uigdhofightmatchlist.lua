---
--- Created by Administrator.
--- DateTime: 2024/6/21 14:52:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightMatchList:LWnd
local UIGdHoFightMatchList = LxWndClass("UIGdHoFightMatchList", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightMatchList:UIGdHoFightMatchList()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightMatchList:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightMatchList:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightMatchList:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()

    self:InitEvent()
    self:InitText()
    self:InitData()
    self:InitPara()
    self:OpenReq()
end

function UIGdHoFightMatchList:InitEvent()
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.MatchDataChange_Match, function()
        self:OnGuildInfo()
    end)

    --ui
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
end

--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UIGdHoFightMatchList:SetSelfGuildInfo()

    self:SetWndText(self.mInfoTitle, ccClientText(44050))
    local isempty = true
    if self._guildInfo then
        for k, v in pairs(self._guildInfo) do
            local root = v.isSelf and self.mFirstDiv or self.mSecondDiv
            if k == 0 or gModelGuildHolyBattle:GetMatchInfo(v.guildId) == 0 then
                --轮空 不处理数据
                self:SetWndText(self.mInfoTitle, ccClientText(44076))  --[44050] [對戰列表]  or  [44076] [其他公會對戰]
                --轮空要重新设置一遍设配

            else
                CS.ShowObject(self.mSelfDiv, true)
                self:SetGuildInfo(root, v, true)
                isempty = false
            end
        end
        if isempty then
            self:SetEmptyGuildInfo()
        end


    end
end

function UIGdHoFightMatchList:OpenReq()
    gModelGuildHolyBattle:SendGuildBattleMatchReq(2)
end

function UIGdHoFightMatchList:InitPara()

end


--region 界面初始化 --------------------------------------------------------------------------------
function UIGdHoFightMatchList:InitText()
    self:SetWndText(self.mTitle, ccClientText(44050))  --[44050] [對戰列表]
    --self:SetWndText(self.mInfoTitle, ccClientText(44050))  --[44050] [對戰列表]
    self:SetWndText(self.mCloseTip, ccClientText(10103))
end

function UIGdHoFightMatchList:FilterOtherGuildInfo()
    local showData = {}
    local selfGuild = gModelPlayer:GetGuildId()
    for k, v in ipairs(self._guildOtherInfo) do
        if v.guildA == selfGuild or v.guildB == selfGuild then

        else
            if string.isempty(v.guildA) or string.isempty(v.guildB) then

            else
                table.insert(showData, v)
            end

        end
    end
    self._guildOtherInfo = showData
end

function UIGdHoFightMatchList:InitData()

end

function UIGdHoFightMatchList:SetOtherGuildInfo()
    local uiList = self._otherList

    if not uiList then
        uiList = self:GetUIScroll(self.mOtherGuildInfo:GetInstanceID())
        uiList:Create(self.mOtherGuildInfo, self._guildOtherInfo, function(...)
            self:CreateOtherGuildInfoList(...)
        end, UIItemList.SUPER)

        self._otherList = uiList
    else
        uiList:RefreshList(self._showList)
        uiList:DrawAllItems(true)
    end
end

function UIGdHoFightMatchList:SetEmptyGuildInfo()
    CS.ShowObject(self.mSelfDiv, false)
    self:SetAnchorPos(self.mInfoDiv, Vector2.New(0, 194))

    self.mOtherGuildInfo.sizeDelta = Vector2.New(570, 847)
    self:SetAnchorPos(self.mOtherGuildInfo, Vector2.New(10, -270))
end
--endregion --------------------------------------------------------------------------------------

--region 事件回调 --------------------------------------------------------------------------------
function UIGdHoFightMatchList:OnGuildInfo()
    self._guildInfo = gModelGuildHolyBattle:GetGuildInfo()
    self._guildOtherInfo = gModelGuildHolyBattle:GetOtherMatchInfo()

    --自身的数据没有  就关闭掉
    if not self._guildInfo then
        GF.ShowMessage(ccClientText(44068))
        self:WndClose()
        return
    end

    CS.ShowObject(self.mAniRoot, true)
    self:SetSelfGuildInfo()

    self:FilterOtherGuildInfo()
    self:SetOtherGuildInfo()
end

function UIGdHoFightMatchList:CreateOtherGuildInfoList(list, item, itemdata, itempos)
    local FirstDiv = CS.FindTrans(item, "FirstDiv")
    local guildItemData_A = gModelGuildHolyBattle:GetOtherGuildInfo(itemdata.guildA)
    if guildItemData_A then
        self:SetGuildInfo(FirstDiv, guildItemData_A)
    end

    local SecondDiv = CS.FindTrans(item, "SecondDiv")
    local guildItemData_B = gModelGuildHolyBattle:GetOtherGuildInfo(itemdata.guildB)
    if guildItemData_A then
        self:SetGuildInfo(SecondDiv, guildItemData_B)
    end
end

function UIGdHoFightMatchList:SetGuildInfo(tran, itemData, isSetSelf)
    local FlagBg = CS.FindTrans(tran, "FlagBg")
    local FlagIcon = CS.FindTrans(FlagBg, "FlagIcon")
    local GuildLvText = CS.FindTrans(FlagBg, "GuildLvBg/GuildLvText")
    local ServerText = CS.FindTrans(tran, "ServerText")
    local GuildName = CS.FindTrans(tran, "GuildName")
    local PowerText = CS.FindTrans(tran, "PowerText")

    if self._isEnus then
        local img = CS.FindTrans(tran, "Image")
        if img.gameObject.activeSelf == true then
            CS.ShowObject(img, false)
        end
    end

    --旗子
    local fragRef = gModelGuild:GetGuildFlagRefByRefId(itemData.flagId)
    local fragBgRef = gModelGuild:GetGuildFlagRefByRefId(itemData.flagBgId)

    if fragBgRef then
        self:SetWndEasyImage(FlagBg, fragBgRef.res, nil, false)
    end
    if fragRef then
        self:SetWndEasyImage(FlagIcon, fragRef.res, nil, false)
    end

    self:SetWndText(GuildLvText, itemData.level)

    self:SetWndText(PowerText, LUtil.NumberCoversion(itemData.guildPower))
    if isSetSelf then
        local guildName = string.format("<color=#139057>【%s】</color> %s", itemData.serverName, itemData.guildName)
        self:SetWndText(GuildName, guildName)
    else
        self:SetWndText(GuildName, itemData.guildName)
        self:SetWndText(ServerText, itemData.serverName)
    end

    self:SetWndClick(FlagBg, function()
        local isopen = gModelFunctionOpen:CheckIsOpened(12100000, true)
        if isopen then
            gModelGuild:OnGuildMemberListReq(itemData.guildId, itemData.serverId)
        end
    end)
end

--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UIGdHoFightMatchList