---
--- Created by Administrator.
--- DateTime: 2023/9/2 15:54:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGameBzer:LWnd
local UIGameBzer = LxWndClass("UIGameBzer", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGameBzer:UIGameBzer()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGameBzer:OnWndClose()
    LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGameBzer:OnCreate()
    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGameBzer:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    if self._isEnus then 
        self:SetAnchorPos(self.mSpeedText,Vector2.New(50,16))
        self:SetAnchorPos(self.mHelpBtn,Vector2.New(160,157))
    end
    self.jpj = gLGameLanguage:IsJapanVersion()
    if self.jpj then
        self:SetAnchorPos(self.mHelpBtn,Vector2.New(120,157))
    end
    if not gModelGameHelper:IsInitDoList() then
        gModelGameHelper:InitDoList()
    end
    self:InitCommon()
    self:OnWndRefresh()

    gModelGameHelper:GameHelperSettingReq(1)
end

------------------------------------------------------------------
--- ↓ 加速助手部分 ↓ ---
------------------------------------------------------------------
function UIGameBzer:InitSpeed()
    ------------------------------------------------------------------
    ---click
    self:SetWndClick(self.mSetSpBtn, function()
        self:ApplySpeed()
    end)
    self:SetWndClick(self.mHelpBtn, function()
        GF.OpenWnd("UIBzTips", { refId = 104 })
    end)

    ------------------------------------------------------------------
    ---text
    self:SetTextTile(self.mOnlyBattleTog, ccClientText(24214))

    ------------------------------------------------------------------
    ---toggle
    self:SetWndToggleValue(self.mOnlyBattleTog, gModelGameHelper:GetOnlyBattle())
    self:SetWndToggleDelegate(self.mOnlyBattleTog, function(value)
        gModelGameHelper:SetOnlyBattle(value)
    end)

    ------------------------------------------------------------------
    ---slider
    self:SetWndSliderDelegate(self.mSpeedSlider, function(...)
        self:OnSpeedSliderChange(...)
    end)
end

function UIGameBzer:RefreshTop()
    self:RefreshSpeedText()
    local maxValue = gModelGameHelper:GetUnLockMaxSpeed()
    local minValue = 0
    local curSpeed = gModelGameHelper:GetGameSpeed()
    self:SetWndSliderPara(self.mSpeedSlider, curSpeed, minValue, maxValue, true)
    self:RefreshSpBtnShow()
end

function UIGameBzer:InitCommon()
    ------------------------------------------------------------------
    ---click
    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mStartBtn, function()
        local openId = GameTable.AssistantConfig.helperLighteningOpen
        local isOpen = gModelFunctionOpen:CheckIsOpened(openId, true)
        if not isOpen then
            return
        end

        local refIds = {}
        for refId, b in pairs(self.doList) do
            if b == true then
                table.insert(refIds, refId)
            end
        end
        if #refIds > 0 then
            gModelGameHelper:GameHelperExecuteReq(refIds)
        else
            GF.ShowMessage(ccClientText(24245))
        end
    end)

    ------------------------------------------------------------------
    ---text
    self:SetWndText(self.mTxtReturn, ccClientText(20723))
    self:SetWndText(self.mTitleText, ccClientText(24203))
    self:SetWndButtonText(self.mStartBtn, ccClientText(24227))

    ------------------------------------------------------------------
    ---order
    self:InitSpeed()

    local openId = GameTable.AssistantConfig.helperLighteningOpen
    local isOpen = gModelFunctionOpen:CheckIsOpened(openId)
    CS.ShowObject(self.mUnOpen, not isOpen)
    CS.ShowObject(self.mStartBtn, isOpen)
    local s = gModelFunctionOpen:GetOpenTips(openId)
    self:SetTextTile(self.mUnOpen, s)

    ------------------------------------------------------------------
    ---event
    self:WndEventRecv("GameHelperSettingResp", function()
        if not self.initTab then
            self:InitTab()
            self.initTab = true
        end
	end)

    ------------------------------------------------------------------
    ---resp
    self:WndNetMsgRecv(LProtoIds.GameHelperExecuteResp, function(pb)
        if pb.syncType == 1 then
            GF.OpenWnd("UIGameHelperDo", { pb = pb })
        end
	end)
end

function UIGameBzer:OnWndRefresh()
    self:RefreshTop()
end

function UIGameBzer:DrawTab(_, trans, data)
    local on = CS.FindTrans(trans, "On")
    local onYes = CS.FindTrans(on, "Yes")
    local onNo = CS.FindTrans(on, "No")
    local off = CS.FindTrans(trans, "Off")
    local select = CS.FindTrans(trans, "Selct")
    local name = CS.FindTrans(trans, "Name")

    self:SetWndText(name, ccLngText(data.name))
    local isOpen = gModelFunctionOpen:CheckIsOpened(data.open)
    local key = data.id
    CS.ShowObject(on, isOpen)
    CS.ShowObject(off, not isOpen)
    CS.ShowObject(onYes, self.doList[key])
    CS.ShowObject(onNo, not self.doList[key])
    CS.ShowObject(off, not isOpen)
    CS.ShowObject(select, self.curSelect == data.id)

    self:SetWndClick(off, function()
        gModelFunctionOpen:CheckIsOpened(data.open, true)
    end)
    self:SetWndClick(on, function()
        self:ClickTabBtn(data.id)
    end)
    self:SetWndClick(onYes, function()
        self:ClickDoBtn(false, data)
    end)
    self:SetWndClick(onNo, function()
        self:ClickDoBtn(true, data)
    end)
end

function UIGameBzer:ApplySpeed()
    local funcId = GameTable.AssistantConfig["helperAccelerateOpen2"]
    if not gModelFunctionOpen:CheckIsOpened(funcId, true) then
        return
    end
    gModelGameHelper:ApplySpeed()
    self:RefreshSpBtnShow()
end

function UIGameBzer:OnSpeedSliderChange(value)
    if value < 1 then
        self:SetWndSliderPara(self.mSpeedSlider, 1)
        return
    end
    gModelGameHelper:SetGameSpeed(value)
    self:RefreshSpeedText()
end

function UIGameBzer:ClickDoBtn(b, data)
    local key = data.id
    self.doList = gModelGameHelper:SetDoList(key, b)
    self.tabList:DrawAllItems()
end

function UIGameBzer:ClickTabBtn(id)
    if self.curSelect == id then
        return
    end
    self.curSelect = id
    self:CloseAllChild()
    self:CreateChildWnd(self.mChildRoot, self.childWnd[id], { id = id })
    self.tabList:DrawAllItems()
end

function UIGameBzer:RefreshSpeedText()
    local speed = gModelGameHelper:GetGameSpeed()
    local ref = gModelGameHelper:GetHelpSpeedRef(speed)
    if ref then
        self:SetWndText(self.mSpeedText, string.replace(ccClientText(24208), ref.valueDisplay))
    end
end
------------------------------------------------------------------
--- ↑ 加速助手部分 ↑ ---
------------------------------------------------------------------

------------------------------------------------------------------
--- ↓ tab list ↓ ---
------------------------------------------------------------------
---WndchildGameHelper
function UIGameBzer:InitTab()
    ------------------------------------------------------------------
    ---member
    self.childWnd = {
        "UISubGameHelperDaily",        --日常
        "UISubGameHelperGetGold",      --神像禱告
        "UISubGameHelperTower",        --少女密室
        "UISubGameHelperBarave",       --勇者杯
        "UISubGameHelperGuild",        --龍騎團
        "UISubGameHelperMiracle",      --少女神跡
        -- "WndChildGameHelperNobility",     --王國爵位賽
        "UISubGameHelperEndLess",      --无尽诱惑
    }
    self.doList = gModelGameHelper:GetDolist()

    local list = gModelGameHelper:GetTabList()
    if self.tabList then
		self.tabList:ResetList(list)
		self.tabList:DrawAllItems()
	else
		self.tabList = self:GetUIScroll("tabList")
		self.tabList:Create(self.mTabList, list, function(...) self:DrawTab(...) end, UIItemList.SUPER)
	end
    self:ClickTabBtn(list[1].id)
end

function UIGameBzer:RefreshSpBtnShow()
    local isSpeeded = gModelGameHelper:IsSpeeded()
    local on = self:FindWndTrans(self.mSetSpBtn, "On")
    local off = self:FindWndTrans(self.mSetSpBtn, "Off")
    CS.ShowObject(on, not isSpeeded)
    CS.ShowObject(off, isSpeeded)
end
------------------------------------------------------------------
--- ↑ tab list ↑ ---
------------------------------------------------------------------


return UIGameBzer