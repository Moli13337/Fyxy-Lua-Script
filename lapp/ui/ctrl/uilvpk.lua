---
--- Created by Administrator.
--- DateTime: 2023/10/10 16:04:52
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UILvPk:LWnd
local UILvPk = LxWndClass("UILvPk", LWnd)

LXImport("LApp.Models.Struct.StructCrossRankPkInfo")

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UILvPk:UILvPk()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UILvPk:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UILvPk:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UILvPk:OnStart()
    LWnd.OnStart(self)
    self:InitUI()


    self.jpj = gLGameLanguage:IsJapanVersion()
    self:SetStatic()
    self:InitEvent()

    gModelCrossGrading:OnCrossRankPkListReq()

    self:SetWndText(self.mMeTitleText, ccClientText(11726))
end

function UILvPk:SetStatic()
    local str = ccClientText(16406)--"切磋列表"
    self:SetWndText(self.mLblBiaoti, str)
    str = ccClientText(10339) --"我的排名"
    self:SetWndText(self.mMeTitleText, str)

    self._rankImgMap = {
        [1] = "public_num_1",
        [2] = "public_num_2",
        [3] = "public_num_3",
    }

    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
end

function UILvPk:ShowContent(pb)
    local dataList = {}
    for k, v in ipairs(pb.pkInfo) do
        local data = StructCrossRankPkInfo:New()
        data:CreateByPb(v)
        table.insert(dataList, data)
    end

    local score = gModelCrossGrading:GetScore()
    local str = string.replace(ccClientText(10368), score)
    self:SetWndText(self.mScoreText, str)

    if self.jpj then
        self:SetAnchorPos(self.mScoreText,Vector2.New(150,-44.3))
    end

    local rank = gModelCrossGrading:GetRank()

    if rank < 0 or nil == rank then
        str = string.format("<size=22>%s</size>", ccClientText(10363))
    else
        str = string.format("No.<size=22>%s</size>", rank)
    end

    self:SetWndText(self.mRankText, str)

    self:CreateUIScrollImpl("playerList", self.mPlayerList, dataList, function(...)
        self:OnDrawPlayer(...)
    end, UIItemList.SUPER)
end

function UILvPk:OnBattleDataRet(pb)
    self._isReqing = false
    local report = gModelCrossGrading:GetCrossRankReportServerData(pb.report)
    if not report then
        return
    end
    local reportIdList = report.reportIdList
    local first = reportIdList[1]
    if not first then
        return
    end
    local serverId = report.serverId
    if not serverId then
        return
    end
    gModelCrossGrading:StartBattlePlay(report)
end

function UILvPk:OnDrawPlayer(list, item, itemdata, itempos)
    local Image = self:FindWndTrans(item, "Image")
    local RankText = self:FindWndTrans(item, "RankText")
    local rankImg = self:FindWndTrans(item, "rankImg")
    local serverText = self:FindWndTrans(item, "serverText")
    local scoreText = self:FindWndTrans(item, "scoreText")
    local BgPower = self:FindWndTrans(item, "PowerBg")
    -- local BgPowerBack = self:FindWndTrans(BgPower, "Back")
    -- local BgPowerIcon = self:FindWndTrans(BgPower, "Icon")
    local BgPowerPowerText = self:FindWndTrans(BgPower, "PowerText")
    local btnPk = self:FindWndTrans(item, "btnPk")

    self:SetWndButtonText(btnPk, ccClientText(16400))
    local rank = itemdata.rank
    local showIcon = rank >= 1 and rank <= 3

    CS.ShowObject(rankImg, showIcon)
    CS.ShowObject(RankText, not showIcon)
    if showIcon then
        self:SetWndEasyImage(rankImg, self._rankImgMap[rank])
    else
        self:SetWndText(RankText, string.format("No.<size=22>%s</size>", rank))
    end
    local score = itemdata.score
    local scoreStr = string.replace(ccClientText(10368), score)
    self:SetWndText(scoreText, scoreStr)
    local power = LUtil.PowerNumberCoversion(itemdata.power)
    local showRed = tonumber(itemdata.power) > gModelPower:GetMainCityPower()
    if showRed then
        power = LUtil.FormatColorStr(power, 'red')
    end
    self:SetWndText(BgPowerPowerText, power)

    self:SetWndText(serverText, itemdata.playerName)

    self:SetWndClick(btnPk, function()
        self:OnClickFight(itemdata.playerId)
    end)

    local headTran = self:FindWndTrans(item, "HeadIcon")

    local playerInfo = {
        trans = headTran,
        icon = itemdata.head,
        headFrame = itemdata.headFrame,
        level = itemdata.level,
        func = function()
            gModelGeneral:PlayerShowReq(itemdata.playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
        end,
    }
    self:CreateHeadIconImpl(playerInfo)
end

function UILvPk:OnClickFight(playerId)
    if self._isReqing then
        return
    end
    self._isReqing = true
    gModelCrossGrading:OnCrossRankPkReq(playerId)
end

function UILvPk:InitEvent()
    self:WndNetMsgRecv(LProtoIds.CrossRankPkListResp, function(pb)
        self:ShowContent(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.CrossRankPkResp, function(pb)
        self:OnBattleDataRet(pb)
    end)
end

------------------------------------------------------------------
return UILvPk


