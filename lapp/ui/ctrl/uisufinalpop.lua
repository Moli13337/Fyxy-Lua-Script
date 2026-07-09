---
--- Created by Administrator.
--- DateTime: 2023/10/24 21:15:55
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISuFinalPop:LWnd
local UISuFinalPop = LxWndClass("UISuFinalPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISuFinalPop:UISuFinalPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISuFinalPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISuFinalPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISuFinalPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

    self:InitUIEvent()
    self:InitEvent()
    self:SetStaticContent()

    self:OnWndRefresh()
end

function UISuFinalPop:InitUIEvent()
    self:SetWndClick(self.mMask,function () self:WndClose() end)
    self:SetWndClick(self.mBtnJump,function () self:OnClickGoto() end)
end

function UISuFinalPop:SetPlayer(item,playerData)
    local headRoot = self:FindWndTrans(item,"headRoot")
    local name = self:FindWndTrans(item,"name")

    local headTran = self:FindWndTrans(headRoot,"HeadIcon")
    local playerInfo =
    {
        trans = headTran,
        icon = playerData.head,
        headFrame = playerData.headFrame,
        level = playerData.level,
        func = function()
            gModelGeneral:PlayerShowReq(playerData.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
        end,
    }

    self:CreateHeadIconImpl(playerInfo)

    local str = string.replace(ccClientText(25286),playerData.serverName,playerData.name)
    self:SetWndText(name,str)
end

function UISuFinalPop:OnWndRefresh()
    local type = 3
    local group = 0
    local round = 2
    local groupType = ModelSimuFight.GROUP_PINNACLE
    gModelSimuFight:OnSimulateGroupInfoReq(type,group,round,groupType)
end

function UISuFinalPop:InitEvent()
    self:WndNetMsgRecv(LProtoIds.SimulateGroupInfoResp,function (...)
        self:OnSimulateGroupInfoResp(...)
    end)
end

function UISuFinalPop:OnSimulateGroupInfoResp(pb)
    if pb.type ~= 3 then
        return
    end

    if pb.round ~= 2 then
        return
    end

    if pb.groupType ~= ModelSimuFight.GROUP_PINNACLE then
        return
    end

    local info = pb.infos[1]
    if not info then
        return
    end

    local battleInfo = StructSimulateBattleInfo:New()
    battleInfo:CreateByPb(info)
    self._battleInfo = battleInfo

    self:SetPlayer(self.mPlayer1,battleInfo.attack)
    self:SetPlayer(self.mPlayer2,battleInfo.defense)

end

function UISuFinalPop:SetStaticContent()
    self:SetWndText(self.mCloseTip,ccClientText(10103))
    self:SetWndButtonText(self.mBtnJump,ccClientText(21313))
end

function UISuFinalPop:OnClickGoto()
    GF.OpenWnd("UISuMin")
end

------------------------------------------------------------------
return UISuFinalPop


