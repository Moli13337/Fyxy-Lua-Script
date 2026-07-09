---
--- Created by Administrator.
--- DateTime: 2024/4/23 16:50:59
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIRiskRtUpLvl:LWnd
local UIRiskRtUpLvl = LxWndClass("UIRiskRtUpLvl", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRiskRtUpLvl:UIRiskRtUpLvl()
    self.commonUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRiskRtUpLvl:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRiskRtUpLvl:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRiskRtUpLvl:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()

    self:InitEvent()
    self:InitData()
end

function UIRiskRtUpLvl:InitEvent()
    self:SetWndClick(self.mBgImage, function()
        self:ClickBgImage()
    end)
end

function UIRiskRtUpLvl:InitData()
    self:SetWndText(self.mCloseText, ccClientText(41037))
    self:SetWndText(self.mDailyTitle, ccClientText(18213))
    self:SetWndText(self.mStatsTitle, ccClientText(18237))

    self.nowLvl = self:GetWndArg("lvl")
    if self.nowLvl == nil then
        self:WndClose()
        return
    end
    self.oldLvl = self.nowLvl - 1
    self:SetInfo()
end

function UIRiskRtUpLvl:ClickBgImage()
    gModelGrade:OnGradeRewardReq(self.nowLvl)
    gModelGrade:OpenRewardWnd()
    self:WndClose()
end

function UIRiskRtUpLvl:SetRewardsIcon(trans, rewards)
    local info = string.split(rewards, ",")
    for i = 1, 2 do
        local icon = self:FindWndTrans(self:FindWndTrans(trans, "RewardObj"), "Icon" .. i)
        local iconRoot = self:FindWndTrans(icon, "IconRoot")
        local itemName = self:FindWndTrans(icon, "ItemName")
        if info[i] then
            local itemIcon = self.commonUIList[trans.gameObject.name .. i]
            local reward = LxDataHelper.ParseItem_3(info[i])
            if not itemIcon then
                itemIcon = CommonIcon:New()
                itemIcon:Create(iconRoot)
                self.commonUIList[trans.gameObject.name .. i] = itemIcon
            end
            itemIcon:SetCommonReward(reward.itemType, reward.itemId, reward.itemNum)
            itemIcon:EnableShowNum(true)
            itemIcon:DoApply()

            self:SetWndClick(iconRoot, function()
                gModelGeneral:ShowCommonItemTipWnd(reward)
            end)
            local name = gModelGeneral:GetCommonItemName(reward)
            self:SetWndText(itemName, name)
            CS.ShowObject(icon, true)
        else
            CS.ShowObject(icon, false)
        end
    end
end

function UIRiskRtUpLvl:SetInfo()
    local nowCfg = GameTable.PlayerGradeLvRef[self.nowLvl]
    local oldCfg = GameTable.PlayerGradeLvRef[self.oldLvl]
    self:SetWndText(self.mNowText, ccLngText(nowCfg.name))
    self:SetWndText(self.mOldText, ccLngText(oldCfg.name))
    self:SetRewardsIcon(self.mDailyObj, nowCfg.rewardDaily)
    self:SetRewardsIcon(self.mStatsObj, oldCfg.rewardUp)

    if self._isEnus then

        LxTimer.DelayFrameCall(function()
            local desUIText = LxUiHelper.FindXTextCtrl(self.mOldText)
            local curwidth = desUIText.preferredWidth
            LxUiHelper.SetSizeWithCurAnchor(self.mOldLvl, 0, curwidth + 50)
            desUIText = LxUiHelper.FindXTextCtrl(self.mNowText)
            curwidth = desUIText.preferredWidth
            LxUiHelper.SetSizeWithCurAnchor(self.mNowLvl, 0, curwidth + 50)
			local offsetX= curwidth/4
			self:SetAnchorPos(self.mOldLvl,Vector2.New(-96-offsetX,0))
			self:SetAnchorPos(self.mNowLvl,Vector2.New(96+offsetX,0))
        end, 1)

    end
end

------------------------------------------------------------------
return UIRiskRtUpLvl