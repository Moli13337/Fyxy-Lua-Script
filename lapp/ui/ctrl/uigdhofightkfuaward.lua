---
--- Created by Administrator.
--- DateTime: 2024/7/3 20:18:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightKfuAward:LWnd
local UIGdHoFightKfuAward = LxWndClass("UIGdHoFightKfuAward", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightKfuAward:UIGdHoFightKfuAward()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightKfuAward:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightKfuAward:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightKfuAward:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitEvent()
    self:InitText()
    self:InitData()
    self:InitPara()
end
--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UIGdHoFightKfuAward:SetReward()
    local uiList = self._uiRewardList
    if not uiList then
        uiList = UIIconEasyList:New()
        self._uiRewardList = uiList
        uiList:Create(self, self.mReward)
        uiList:SetShowNum(false)
        uiList:SetIconParentPath("itemRoot/CommonUI/Icon")
        uiList:SetShowExtraNum(true, "itemNum")
    end
    uiList:RefreshList(self._para.itemReward)
end

function UIGdHoFightKfuAward:InitData()

end

function UIGdHoFightKfuAward:InitPara()
    self._para = self:GetWndArg("para")

    self:SetReward()
end

--region 页面初始化 --------------------------------------------------------------------------------
function UIGdHoFightKfuAward:InitText()
    self:SetWndText(self.mTitle1, ccClientText(44061)) --[44061] [跨服聖戰]
    self:SetWndText(self.mContent1, ccClientText(44062))    --[44062] [全新戰鬥開啓]
    self:SetWndText(self.mContent2, ccClientText(44063))    --[44063] [聖騎之戰即將進入跨界模式]
    self:SetWndText(self.mContent3, ccClientText(44064))    --[44064] [全新獎勵預覽]

    self:SetWndText(self.mCloseTip,ccClientText(10103))
end

function UIGdHoFightKfuAward:InitEvent()

    --ui
    self:SetWndClick(self.mCloseBtn1, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mMaskCell, function()
        self:WndClose()
    end)
end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIGdHoFightKfuAward