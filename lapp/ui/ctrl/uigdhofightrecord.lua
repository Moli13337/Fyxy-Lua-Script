---
--- Created by Administrator.
--- DateTime: 2024/6/27 14:53:49
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightRecord:LWnd
local UIGdHoFightRecord = LxWndClass("UIGdHoFightRecord", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightRecord:UIGdHoFightRecord()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightRecord:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightRecord:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightRecord:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitEvent()
    self:InitText()
    self:InitData()
    self:InitPara()
end

function UIGdHoFightRecord:InitData()
    self:InitTabInfo()
end



--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UIGdHoFightRecord:SetTab()
    for k, v in ipairs(self._tabInfo) do
        local offTxt = CS.FindTrans(v.tran, "Off/UIText")
        local onTxt = CS.FindTrans(v.tran, "On/UIText")

        self:SetWndText(offTxt, v.tabText)
        self:SetWndText(onTxt, v.tabText)

        self:SetWndClick(v.tran, v.clickFunc)
    end
end

--ui
function UIGdHoFightRecord:OnChangeTabState(tabIndex)
    for k, v in ipairs(self._tabInfo) do
        local off = CS.FindTrans(v.tran, "Off")
        local on = CS.FindTrans(v.tran, "On")
        CS.ShowObject(off, not (k == tabIndex))
        CS.ShowObject(on, k == tabIndex)
    end
end

function UIGdHoFightRecord:OnGuildLogChange()
    self._showList = gModelGuildHolyBattle:GetLog(false)
    self:SetLogList()
end

--region 页面初始化 --------------------------------------------------------------------------------
function UIGdHoFightRecord:InitText()
    self:SetWndText(self.mTitle, ccClientText(17924))
    self:SetWndText(self.mCloseTip, ccClientText(10103))
    self:SetWndText(self.mEmptyText, ccClientText(44074)) --[44074] [暫無戰報]
end

function UIGdHoFightRecord:InitTabInfo()
    --(1=我的战报，2=团战报)
    self._tabInfo = {
        [1] = {

            tran = self.mTab_1,
            clickFunc = function()
                self:OnChangeTabState(1)
                gModelGuildHolyBattle:SendGuildBattleFightLogReq(2)
            end,
            tabText = ccClientText(44038), --[44038] [全場戰報]
        },
        [2] = {
            tran = self.mTab_2,
            clickFunc = function()
                self:OnChangeTabState(2)
                gModelGuildHolyBattle:SendGuildBattleFightLogReq(1)
            end,
            tabText = ccClientText(44039), --[44039] [我的戰報]
        },
    }

    self:SetTab()
end

function UIGdHoFightRecord:SetLogInfoTran(tran, itemData, isWin, star)
    local WinImg = CS.FindTrans(tran, "WinImg")
    local FailImg = CS.FindTrans(tran, "FailImg")
    local StarRoot = CS.FindTrans(tran, "StarRoot")

    CS.ShowObject(WinImg, isWin)
    CS.ShowObject(FailImg, not isWin)
    CS.ShowObject(StarRoot, isWin)

    if isWin then
        for i = 1, 3 do
            local starKey = "Star_" .. i
            local starTran = CS.FindTrans(StarRoot, starKey)
            CS.ShowObject(starTran, i <= star)
        end

        if star > 0 then
            local Score = CS.FindTrans(tran, "Score")
            self:SetWndText(Score, ccClientText(27410))

            if self._isVie then
                LxUiHelper.SetSizeWithCurAnchor(Score, 0, 40)
                self:InitTextLineWithLanguage(Score, 0)
                self:InitTextSizeWithLanguage(Score, -4)
                self:SetAnchorPos(Score, Vector2.New(-20, 74))
            end
        end
    end



    --头像信息
    local IconBg = CS.FindTrans(tran, "Head/HeadIcon/IconBg")
    local Icon = CS.FindTrans(IconBg, "Icon")
    local iconPath = gModelPlayer:GetHeadIcon(itemData.avatar)
    local framePath = gModelPlayer:GetRolePlayerHeadRefByRefId(itemData.avatarFrame)
    if framePath then
        self:SetWndEasyImage(IconBg, framePath.icon)
    end
    if iconPath then
        self:SetWndEasyImage(Icon, iconPath)
    end
    --名字相关信息
    local ScoreName = CS.FindTrans(tran, "ScoreName")
    local PlayerName = CS.FindTrans(tran, "PlayerName")
    local Power = CS.FindTrans(tran, "Power")
    self:SetWndText(ScoreName, itemData.guildName)
    self:SetWndText(PlayerName, itemData.playerName)
    self:SetWndText(Power, LUtil.NumberCoversion(itemData.playerPower))

    --旗子信息
    local fragBgTran = CS.FindTrans(tran, "RankImg")
    local fragTran = CS.FindTrans(fragBgTran, "RankImg_2")
    local flagId = itemData.guildBanner
    local flagBgId = itemData.flagBgId
    local fragRef = gModelGuild:GetGuildFlagRefByRefId(flagId)
    local fragBgRef = gModelGuild:GetGuildFlagRefByRefId(flagBgId)
    if fragBgRef then
        self:SetWndEasyImage(fragBgTran, fragBgRef.res, nil, false)
    end
    if fragRef then
        self:SetWndEasyImage(fragTran, fragRef.res, nil, false)
    end
end

function UIGdHoFightRecord:CreateRecordList(list, item, itemdata, itempos)
    --共用的部分
    local TimeTxt = CS.FindTrans(item, "TimeTxt")
    --自己信息
    local AttackDiv = CS.FindTrans(item, "AttackDiv")
    local DefenseDiv = CS.FindTrans(item, "DefenseDiv")
    local DetailsBtn = CS.FindTrans(item, "DetailsBtn")
    local DetailsBtnName = CS.FindTrans(DetailsBtn, "DetailsBtnName")
    local Arrow_Right = CS.FindTrans(item, "Arrow_Right")
    local Arrow_Left = CS.FindTrans(item, "Arrow_Left")
    local str = LUtil.OSDate("%Y/%m/%d", itemdata.fightTime)

    self:SetWndText(TimeTxt, str)
    self:SetWndText(DetailsBtnName, ccClientText(21536))

    local url = itemdata.reportId
    --点击播放录像
    self:SetWndClick(DetailsBtn, function(...)
        local mapRes = gModelBattle:GetCombatPlayCampRefByRefId(LCombatTypeConst.COMBAT_TYPE_44)

        local sceneRef = GameTable.BattleSceneRef[mapRes.fightScene]

        local combatExtraDatas = {
            battleEndfun = gModelBattle:GetReturnFun(LCombatTypeConst.COMBAT_TYPE_44),
            canSkip = true,
            battleMapName = sceneRef and sceneRef.name or nil,
            videoType = LVideoTypeConst.NORMAL,
            serverId = itemdata.serverId,
        }
        gLFightManager:OnPlayBattleVideo(url, combatExtraDatas)
        gLGameUI:CloseAllButExcept()
        self:WndClose()
    end)

    local own_IsAttack = itemdata.attack == 1
    CS.ShowObject(Arrow_Right, own_IsAttack)
    CS.ShowObject(Arrow_Left, not own_IsAttack)

    if self._isVie then
        local arrowImage = CS.FindTrans(Arrow_Right, "Image")
        self:SetWndEasyImage(arrowImage, "guildwar1_logtxt", nil, true)
    end

    local own_IsWin = itemdata.win == 1
    self:SetLogInfoTran(AttackDiv, itemdata.own, own_IsWin, itemdata.star)
    self:SetLogInfoTran(DefenseDiv, itemdata.enemy, not (own_IsWin), itemdata.star)
end

function UIGdHoFightRecord:InitPara()
    self._para = self:GetWndArg("para")
    local tabIndex = 1
    if self._para then
        tabIndex = self._para.tabIndex
    end

    self._tabInfo[tabIndex].clickFunc()
end

function UIGdHoFightRecord:SetLogList()
    local uiList = self._logList

    CS.ShowObject(self.mNoRecord2, #self._showList == 0)

    if not uiList then
        uiList = self:GetUIScroll(self.mRecordList:GetInstanceID())
        uiList:Create(self.mRecordList, self._showList, function(...)
            self:CreateRecordList(...)
        end, UIItemList.SUPER)

        self._logList = uiList
    else
        uiList:RefreshList(self._showList)
        uiList:DrawAllItems(true)
    end

end
function UIGdHoFightRecord:InitEvent()
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.LogDataChange_Self, function()
        self:OnSelfLogChange()
    end)

    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.LogDataChange_Guild, function()
        self:OnGuildLogChange()
    end)

    --ui
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)

end
--endregion --------------------------------------------------------------------------------------

--region 事件回调 --------------------------------------------------------------------------------
--event
function UIGdHoFightRecord:OnSelfLogChange()
    self._showList = gModelGuildHolyBattle:GetLog(true)
    self:SetLogList()
end
--endregion --------------------------------------------------------------------------------------


------------------------------------------------------------------
return UIGdHoFightRecord