---
--- Created by Administrator.
--- DateTime: 2024/9/4 21:34:18
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightSelect:LWnd
local UIGdHoFightSelect = LxWndClass("UIGdHoFightSelect", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightSelect:UIGdHoFightSelect()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightSelect:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightSelect:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightSelect:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()

    self:InitCommon()
    self:InitEvent()

    gModelGuildHolyPeak:GuildPinnacleStageReq()
    gModelGuildHolyBattle:SendGuildBattleStageReq()
end

function UIGdHoFightSelect:InitEvent()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)
    for _, v in ipairs(self.tabData) do
        self:SetWndClick(v.tran, function()
            v.func()
        end)
    end
end

function UIGdHoFightSelect:InitCommon()
    -----------------------------------------------
    ---member
    self.peakOpen = false
    self.scoreOpen = false
    self.tabData = {
        {
            tran = self.mScore,
            func = function()
                GF.OpenWndBottom("UIGdHoFightPrepare")
            end
        },
        {
            tran = self.mPeak,
            func = function()
                GF.OpenWndBottom("UIGdHoFightPk")
            end
        },
    }

    -----------------------------------------------
    ---Text
    self:SetWndText(self.mLblBiaoti, ccClientText(12643))
    self:SetWndText(CS.FindTrans(self.mScore, "On/Text"), ccClientText(46000))

    -----------------------------------------------
    ---event
    self:WndEventRecv(ModelGuildHolyBattle.EventArgs.StageDataChange, function()
        local stage = gModelGuildHolyBattle:GetStage()
        self.scoreOpen = stage ~= 0
        self:SetWndTabStatus(self.mScore, self.scoreOpen and 0 or 1)
        if not self.scoreOpen then
            local text = CS.FindTrans(self.mScore, "Off/TimeText")
            self:SetWndText(text, gModelGuildHolyBattle:GetStarTimeDes())
        else
            local text = CS.FindTrans(self.mScore, "On/Text")
            self:SetWndText(text, gModelGuildHolyBattle:GetStageTextStr(gModelGuildHolyBattle:GetStage()))
        end
    end)
    self:WndEventRecv("GuildPinnacleStageResp", function()
        local stage = gModelGuildHolyPeak:GetStage()
        self.peakOpen = stage ~= ModelGuildHolyPeak.STAGE_0 and stage ~= ModelGuildHolyPeak.STAGE_12
        self:SetWndTabStatus(self.mPeak, self.peakOpen and 0 or 1)
        if not self.peakOpen then
            local text = CS.FindTrans(self.mPeak, "Off/TimeText")
            self:SetWndText(text, ccClientText(46001))
        else
            local text = CS.FindTrans(self.mPeak, "On/Text")
            self:SetWndText(text, gModelGuildHolyPeak:GetOutStageText())
        end
    end)
    local image_1 = CS.FindTrans(self.mScore, "Image")
    self:SetWndEasyImage(image_1, "guildBattle_txt2", function()
        CS.ShowObject(image_1, true)
    end)
    
    local image_2 = CS.FindTrans(self.mPeak, "Image")
    self:SetWndEasyImage(image_2, "guildBattle_txt1", function()
        CS.ShowObject(image_2, true)
    end)
end

------------------------------------------------------------------
return UIGdHoFightSelect