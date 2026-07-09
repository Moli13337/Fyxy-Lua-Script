---
--- Created by LCM.
--- DateTime: 2024/3/3 11:41:42
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuGradRecord:LWnd
local UIKuafuGradRecord = LxWndClass("UIKuafuGradRecord", LWnd)

UIKuafuGradRecord.MY_RECORD = 1
UIKuafuGradRecord.DS_RECORD = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuGradRecord:UIKuafuGradRecord()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuGradRecord:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuGradRecord:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    self:SetHideHurdle()
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuGradRecord:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()

    self:SetWndText(self.mLblBiaoti, ccClientText(21816))
    self:InitEmptyList()
    self:InitEvent()
    self:InitMsg()
    self:InitData()

    self:InitBtnList()
end

function UIKuafuGradRecord:OnCrossRankReportListResp(reportList)
    local list = {}
    for i, v in ipairs(reportList or {}) do
        local report = gModelCrossGrading:GetCrossRankReportServerData(v)
        table.insert(list, report)
    end
    table.sort(list, function(a, b)
        return a.startTime > b.startTime
    end)
    self:InitRecordList(list)
end

function UIKuafuGradRecord:InitEmptyList()
    local data = {
        refId = 9008,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UIKuafuGradRecord:RefreshBtnList()
    local viewType = self._btnType
    local uiBtnList = self._uiBtnList
    if uiBtnList then
        local uiList = uiBtnList:GetList()
        uiList:RefreshList()
    end
    gModelCrossGrading:OnCrossRankReportListReq(viewType)
end

function UIKuafuGradRecord:InitRecordList(list)
    local isEmpty = #list <= 0
    CS.ShowObject(self.mNoRecord2, isEmpty)
    CS.ShowObject(self.mRecordList, not isEmpty)

    local uiRecordList = self._uiRecordList
    if uiRecordList then
        uiRecordList:RefreshList(list)
    else
        uiRecordList = self:GetUIScroll("uiRecordList")
        self._uiRecordList = uiRecordList
        uiRecordList:Create(self.mRecordList, list, function(...)
            self:OnDrawRecordCell(...)
        end, UIItemList.WRAP)
    end
end

function UIKuafuGradRecord:InitData()
    self._viewType = self:GetWndArg("viewType")

    self._viewList = {
        {
            viewType = UIKuafuGradRecord.MY_RECORD,
            btnName = ccClientText(21814),
        },
        {
            viewType = UIKuafuGradRecord.DS_RECORD,
            btnName = ccClientText(21815),
        },
    }
end

function UIKuafuGradRecord:InitMsg()
    self:WndNetMsgRecv(LProtoIds.CrossRankReportListResp, function(pb, ret)
        local type = pb.type
        if type ~= self._btnType then
            return
        end
        self:OnCrossRankReportListResp(pb.reportList)
    end)
end

function UIKuafuGradRecord:OnDrawRecordCell(list, item, itemdata, itempos)
    local winner = itemdata.winner

    local attack, defense = itemdata.attack, itemdata.defense
    local attackPlayerId = attack:GetPlayerId()
    local myPlayerId = gModelPlayer:GetPlayerId()
    local isLeft = attackPlayerId == myPlayerId

    if not isLeft then
        attack, defense = itemdata.defense, itemdata.attack
    end

    local attackType = isLeft and ModelCrossGrading.ATTACK_TYPE or ModelCrossGrading.DEFEND_TYPE
    local defenseType = isLeft and ModelCrossGrading.DEFEND_TYPE or ModelCrossGrading.ATTACK_TYPE

    local AttackDiv = self:FindWndTrans(item, "AttackDiv")
    if AttackDiv then
        self:SetBattleInfo(AttackDiv, itemdata, attack, attackType, winner)
    end

    local DefenseDiv = self:FindWndTrans(item, "DefenseDiv")
    if DefenseDiv then
        self:SetBattleInfo(DefenseDiv, itemdata, defense, defenseType, winner)
    end

    local TimeTxt = self:FindWndTrans(item, "TimeTxt")
    if TimeTxt then
        local timeStr = LUtil.FormatTimeStr(itemdata.startTime, "%Y.%m.%d")
        self:SetWndText(TimeTxt, timeStr)
    end

    local ScoreTxt = self:FindWndTrans(item, "ScoreTxt")
    if ScoreTxt then
        local winnerNumA = isLeft and itemdata.winnerNumA or itemdata.winnerNumB
        local winnerNumB = isLeft and itemdata.winnerNumB or itemdata.winnerNumA

        local colorA, colorB
        if winnerNumA > winnerNumB then
            colorA = "lightGreen"
            colorB = "lightRed"
        elseif winnerNumA < winnerNumB then
            colorA = "lightRed"
            colorB = "lightGreen"
        end
        if colorA then
            winnerNumA = LUtil.FormatColorStr(winnerNumA, colorA)
        end
        if colorB then
            winnerNumB = LUtil.FormatColorStr(winnerNumB, colorB)
        end
        local str = string.replace(ccClientText(21832), winnerNumA, winnerNumB)
        self:SetWndText(ScoreTxt, str)
    end

    local DetailsBtn = self:FindWndTrans(item, "DetailsBtn")
    if DetailsBtn then
        local DetailsBtnName = self:FindWndTrans(DetailsBtn, "DetailsBtnName")
        self:SetWndText(DetailsBtnName, ccClientText(21813))

        self:SetWndClick(DetailsBtn, function()
            GF.OpenWnd("UIKuafuGradRecordDetails", { report = itemdata, viewType = self._btnType, combatType = LCombatTypeConst.COMBAT_CROSSGRADING_RANK })
        end)
    end

end

function UIKuafuGradRecord:OnDrawBtnCell(list, item, itemdata, itempos)
    local TabBtn = self:FindWndTrans(item, "TabBtn")

    if self._isEnus then
        self:SetWndTabText(TabBtn, itemdata.btnName, -4)
    else
        self:SetWndTabText(TabBtn, itemdata.btnName)
    end

    local viewType = itemdata.viewType

    local selTab = self._btnType == viewType and LWnd.StateOn or LWnd.StateOff
    self:SetWndTabStatus(TabBtn, selTab)

    self:SetWndClick(TabBtn, function()
        self:ClickTabBtnFunc(viewType)
    end)
end

function UIKuafuGradRecord:InitEvent()
    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mClose_Mask, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UIKuafuGradRecord:ClickTabBtnFunc(viewType)
    if self._btnType and self._btnType == viewType then
        return
    end
    self._btnType = viewType
    self:RefreshBtnList()
end

function UIKuafuGradRecord:SetBattleInfo(trans, data, playerInfo, infoType, winner)
    if not trans or not CS.IsValidObject(trans) then
        return
    end
    if not data then
        return
    end
    if not playerInfo then
        return
    end

    local WinImg = self:FindWndTrans(trans, "WinImg")
    local FailImg = self:FindWndTrans(trans, "FailImg")
    local Score = self:FindWndTrans(trans, "Score")
    local Head = self:FindWndTrans(trans, "Head")
    local HeadIconTrans = self:FindWndTrans(Head, "HeadIcon")
    local PlayerName = self:FindWndTrans(trans, "PlayerName")
    local Power = self:FindWndTrans(trans, "Power")
    local RankImg = self:FindWndTrans(trans, "RankImg")
    local ScoreName = self:FindWndTrans(trans, "ScoreName")

    local InstanceID = trans:GetInstanceID()

    local isWin = infoType == winner
    CS.ShowObject(WinImg, isWin)
    CS.ShowObject(FailImg, not isWin)

    local isAttack = infoType == ModelCrossGrading.ATTACK_TYPE
    local changeScore = isAttack and data.scoreA or data.scoreB
    local color = changeScore > 0 and "lightGreen" or "lightRed"
    if changeScore > 0 then
        changeScore = "+" .. changeScore
    end
    changeScore = LUtil.FormatColorStr(changeScore, color)
    self:SetWndText(Score, changeScore)

    self:SetWndText(PlayerName, playerInfo:GetName())

    local score = playerInfo:GetScore()
    local rank = playerInfo:GetRank()
    local crossGradingRef = gModelCrossGrading:GetCurCrossGradingIntervalRef(score, rank)
    if crossGradingRef then
        local icon = crossGradingRef.icon
        self:SetWndEasyImage(RankImg, icon, nil, true)

        local name = ccLngText(crossGradingRef.name)
        self:SetWndText(ScoreName, name)
    end

    local power = string.replace(ccClientText(21811), LUtil.PowerNumberCoversion(playerInfo:GetPower()))
    self:SetWndText(Power, power)

    local headData = {
        trans = HeadIconTrans,
        icon = playerInfo:GetHead(),
        headFrame = playerInfo:GetHeadFrame(),
        name = playerInfo:GetName(),
        level = playerInfo:GetGrade(),
    }
    local baseClass = self:GetHeadIcon(InstanceID)
    baseClass:SetHeadData(headData)

    self:SetWndClick(HeadIconTrans, function()
        gModelGeneral:PlayerShowReq(playerInfo:GetPlayerId(), LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
    end)
end

function UIKuafuGradRecord:InitBtnList()
    local list = self._viewList

    local uiBtnList = self._uiBtnList
    if uiBtnList then
        uiBtnList:RefreshList(list)
    else
        uiBtnList = self:GetUIScroll("uiBtnList")
        self._uiBtnList = uiBtnList
        uiBtnList:Create(self.mBtnList, list, function(...)
            self:OnDrawBtnCell(...)
        end)
    end

    if not self._btnType then
        local selBtnType = self._viewType or UIKuafuGradRecord.MY_RECORD
        self:ClickTabBtnFunc(selBtnType)
    end
end

------------------------------------------------------------------
return UIKuafuGradRecord


