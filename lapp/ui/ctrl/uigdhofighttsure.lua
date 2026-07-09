---
--- Created by Administrator.
--- DateTime: 2024/6/21 11:46:37
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightTsure:LWnd
local UIGdHoFightTsure = LxWndClass("UIGdHoFightTsure", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightTsure:UIGdHoFightTsure()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightTsure:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightTsure:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightTsure:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    
    if self._isEnus then 
        self:SetAnchorPos(self.mLook,Vector2.New(125,-45))
    end

    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitEvent()
    self:InitText()
    self:InitData()
    self:OpenReq()
end

--endregion --------------------------------------------------------------------------------------

--region 计时器 --------------------------------------------------------------------------------
function UIGdHoFightTsure:OnTimer(key)
    if (self._timeKey == key) then

        self:SetLeftTime()
    end
end

--ui
function UIGdHoFightTsure:OnTreasureClick()
    if self._isCanGet  then

        if #self._treasure== 0 then
            GF.ShowMessage(ccClientText(44073)) --[44078] [宝藏暂未开启]
        else
            GF.OpenWnd("UIGdHoFightTsureDetail")
        end

    else
        GF.ShowMessage(ccClientText(44078)) --[44078] [宝藏暂未开启]
    end
end


--endregion --------------------------------------------------------------------------------------

--region 事件回调 --------------------------------------------------------------------------------
function UIGdHoFightTsure:OnStateUpdate()
    self._isCanGet, self._timeSpan, self._treasure = gModelGuildHolyBattle:GetTreasureInfo()
    --if self._isCanGet then
    --    gModelGuildHolyBattle:SendGuildBattleTreasureBoxReq(1)
    --
    --end

    self:SetTreasureInfo()
end

function UIGdHoFightTsure:OpenReq()
    gModelGuildHolyBattle:SendGuildBattleStageReq()
    gModelGuildHolyBattle:SendGuildBattleTreasureBoxReq(1)
end

--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UIGdHoFightTsure:SetTreasureInfo()
    self:SetWndImageGray(self.mTreasure, not self._isCanGet)
    CS.ShowObject(self.mTreasure, true)
    self:SetLeftTime()
    self:TimerStart(self._timeKey, 1, false, -1)
    local instanceId = self.mTreasure:GetInstanceID()
    if self._isCanGet then
        self:InitEffectTreasure()
    elseif self:FindWndEffectByKey(instanceId) then
        self:DestroyWndEffectByKey(instanceId)
    end
end


function UIGdHoFightTsure:InitEffectTreasure()
    local instanceId = self.mTreasure:GetInstanceID()
    self:CreateWndEffect(self.mTreasure,"fx_ui_shengqibaozang",instanceId,100,false,false,nil,nil,nil,nil,nil,nil,1)
end

--region 页面初始化 --------------------------------------------------------------------------------
function UIGdHoFightTsure:InitText()
    self:SetWndText(self.mTitle, ccClientText(44043))  --[44043] [聖騎寶藏]
    self:SetWndText(self.mTreasureDes, ccClientText(44073))  --[44073] [未知寶藏]
    self:SetWndText(self.mInfo_Title_1, ccClientText(44049))  --[44049] [寶藏預覽]
    if self._isVie then
        self:InitTextCharacterWithLanguage(self.mTreasureDes,-5)
    end
end

function UIGdHoFightTsure:InitData()
    self._timeKey = "UIGdHoFightTsure_TimeKey" -- 每隔1S刷新一次
end

function UIGdHoFightTsure:OnTreasurePreview()
    GF.OpenWnd("UIGdHoFightTsurePreview")
end

function UIGdHoFightTsure:SetLeftTime()
    if self._timeSpan <= 0 or self._timeSpan == nil then
        self:SetWndText(self.mGetLeftTime, ccClientText(16206))
        self:TimerStop(self._timeKey)
        return
    end
    local leftTime = self._timeSpan
    local timeStr = LUtil.FormatTimespanNumber(leftTime)
    local desStr = string.replace(ccClientText(44047), timeStr)
    self:SetWndText(self.mGetLeftTime, desStr)
    self._timeSpan = self._timeSpan - 1
end

function UIGdHoFightTsure:OnTreasureDataChange()
    self._isWin = gModelGuildHolyBattle:CheckGuildHolyIsWin()
    self._isCanGet, self._timeSpan, self._treasure = gModelGuildHolyBattle:GetTreasureInfo()
    if self._isCanGet then

        local str
        if not self._treasure then
            gModelGuildHolyBattle:SendGuildBattleTreasureBoxReq(1)
            return
        end

        if #self._treasure == 0 then
            str = ccClientText(44073)
        else
            str = self._isWin and ccClientText(44071) or ccClientText(44072)
        end

        self:SetWndText(self.mTreasureDes, ccClientText(str))  --[44073] [未知寶藏]
    else
        self:SetWndText(self.mTreasureDes, ccClientText(44073))  --[44073] [未知寶藏]
    end
end

function UIGdHoFightTsure:InitEvent()
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.TreasureDataChange, function()
        self:OnTreasureDataChange()
    end)


    -- model 事件驱动-- gModelGuildHolyBattle.EventArgs.oneDataChange
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.StageDataChange, function()
        self:OnStateUpdate()
    end)


    --ui
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mClose, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mTreasure, function()
        self:OnTreasureClick()
    end)

    self:SetWndClick(self.mInfo_Title_1, function()
        self:OnTreasurePreview()
    end)

    self:SetWndClick(self.mLook, function()
        self:OnTreasurePreview()
    end)

end


--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIGdHoFightTsure