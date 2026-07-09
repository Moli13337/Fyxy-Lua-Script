---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UILvUp:LWnd
local UILvUp = LxWndClass("UILvUp", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UILvUp:UILvUp()
    ---@type UIIconEasyList
    self._awardUiLsit = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UILvUp:OnWndClose()
    --if self._battleNode then
    --	FireEvent(EventNames.ON_INSTANCE_PASS,self._battleNode) ---引导要求
    --end
    --local newLv = self._newLevel
    --local oldLv = self._oldLevel
    --FireEvent(EventNames.ON_REACH_LEVEL,oldLv,newLv)

    --FireEvent(EventNames.CHECK_INSTANCE_PASS)

    if self._awardUiLsit then
        self._awardUiLsit:Destroy()
        self._awardUiLsit = nil
    end

    --FireEvent(EventNames.CHECK_WAIT_GUIDE) --升级弹窗后检查是否已触发引导
    --FireEvent(EventNames.ON_ACCOUNT_RELA_WND_CLOSE,self:GetWndName())

    LWnd.OnWndClose(self)
    self:ClearTimerClose()
    self:ClearCantWndCloseTime()
    self._canWndClose = false
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UILvUp:OnCreate()
    LWnd.OnCreate(self)
    self._nexStep = 0
    self._levelRef = nil
    self._oldLevel = 0
    self._newLevel = 0
    self._canWndClose = false
    self._cantCloseTimer = nil
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UILvUp:OnStart()
    LWnd.OnStart(self)
    self:StartCantWndCloseTime()
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitEvent()
    self:InitCommand()
    LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_LVUP_COMMON)

end

function UILvUp:OnCantCloseTimerFun()
    self._canWndClose = true
end

function UILvUp:ClearTimerClose()
    if self._timerClose then
        LxTimer.DelayTimeStop(self._timerClose)
        self._timerClose = nil
    end
end

function UILvUp:InitScrollRect(list)
    local _list = {}
    for i, v in pairs(list) do
        table.insert(_list, v)
    end

    local uiList = self._awardUiLsit
    if not uiList then
        uiList = UIIconEasyList:New()
        self._awardUiLsit = uiList
        uiList:Create(self, self.mAwardList)
        uiList:EnableIconAni(true)
    end

    uiList:RefreshList(_list, true)
end

function UILvUp:InitCommand()
    --self:SetWndText(self.mLevelUpTextObj,ccClientText(10503))
    self:SetWndText(self.mLevelText, ccClientText(10500))
    self:SetWndText(self.mAwardText, ccClientText(10501))
    self:SetWndText(self.mDisparkText, ccClientText(10502))
    self:SetWndText(self.mTipsText, ccClientText(10103))

    self:SetWndEasyImage(self.mLevel_Up,"role_lvup_txt", function()
        CS.ShowObject(self.mLevel_Up, true)
    end)
    --self:CreateWndSpine(self.mSpineNode,"shengji","shengli",false)


    local res1 = "fx_shengji_down"
    self:CreateWndEffect(self.mEffParent1, res1, res1, 100, false, false)

    local res2 = "fx_shengji_up"
    self:CreateWndEffect(self.mEffParent2, res2, res2, 85, false, false,
            nil, nil, 100)

    local oldLevel = self:GetWndArg("oldLv")
    self._oldLevel = oldLevel
    self._newLevel = self:GetWndArg("newLv")

    self._battleNode = self:GetWndArg("battleNode")
    self:SetWndText(self.mLevelChangeText, oldLevel)
    self:SetWndText(self.mLevelChangeToText, self._newLevel)

    CS.ShowObject(self.mLvTrans, false)
    CS.ShowObject(self.mAwardTrans, false)
    CS.ShowObject(self.mFunDispark, false)
    self:ExecuteStep(self._nexStep)
end

function UILvUp:OnClickClose()
    if not self._canWndClose then
        return
    end
    self:WndClose()
end

function UILvUp:InitFunOpen(showList)
    local roolList = {
        [1] = {
            item = self._isEnus and self.mFunctionItem1_enus or self.mFunctionItem1,
            text = self._isEnus and self.mFunctionText1_enus or self.mFunctionText1,
        },
        [2] = {
            item = self._isEnus and self.mFunctionItem2_enus or self.mFunctionItem2,
            text = self._isEnus and self.mFunctionText2_enus or self.mFunctionText2,
        },
    }

    for i, v in ipairs(roolList) do
        local data = showList[i]
        local show = data ~= nil
        if show then
            self:SetWndText(v.text, data)

            CS.ShowObject(v.text, show)
        end

        CS.ShowObject(v.item, show)
    end

    --[[    for i, v in ipairs(showList) do
            local item = roolList[i]
            if not item then
                break
            end
            CS.ShowObject(item,true)
            local text = CS.FindTrans(item, "FunctionText")

            self:SetWndText(text,v)
        end]]

    if self.jpj then
        local img = CS.FindTrans(self.mFunctionItem1,"Image")
        local img2 = CS.FindTrans(self.mFunctionItem2,"Image")
        img.sizeDelta = Vector2.New(620,36)
        img2.sizeDelta = Vector2.New(620,36)
        self:InitTextSizeWithLanguage(self.mFunctionText1,-2)
        self:InitTextSizeWithLanguage(self.mFunctionText2,-2)
    end
end

---延迟执行----------------------------------------------------------------------
function UILvUp:OnTimerFun()
    self:ExecuteStep(self._nexStep)
end

function UILvUp:StartDelayTimerClose(time)
    self:ClearTimerClose()
    if time <= 0 then
        self:OnTimerFun()
        return
    end
    if self._timerClose == nil then
        local iTimeOut = time
        self._timerClose = LxTimer.DelayTimeCall(function()
            self:OnTimerFun()
        end, iTimeOut)
    end
end

function UILvUp:ClearCantWndCloseTime()
    if not self._cantCloseTimer then
        return
    end

    LxTimer.DelayTimeStop(self._cantCloseTimer)
    self._cantCloseTimer = nil
end

function UILvUp:InitEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:OnClickClose()
    end)
    self:SetWndClick(self.mTipsText, function(...)
        self:OnClickClose()
    end)
end

function UILvUp:ExecuteStep(index)
    local time = 0.2
    self._nexStep = self._nexStep + 1

    local showList = gModelFunctionOpen:GetFunctionOpenShowInfo()

    if (index == 0) then

    elseif (index == 1) then
        CS.ShowObject(self.mLvTrans, true)
    elseif (index == 2) then
        CS.ShowObject(self.mAwardTrans, true)
        --等级表
        self._levelRef = GameTable.SnakeRoleLevelRef[self._newLevel]
        self._awardList = {}
        for i = self._oldLevel + 1, self._newLevel do
            local ref = GameTable.SnakeRoleLevelRef[i]
            local rwewardArr = string.split(ref.reward, ",")
            for i = 1, #rwewardArr do
                local _item = LUtil.GetRefItemData(rwewardArr[i])
                if (self._awardList[_item.refId]) then
                    local item = self._awardList[_item.refId]
                    item.count = item.count + _item.count
                    self._awardList[item.refId] = item
                else
                    self._awardList[_item.refId] = _item
                end
            end
        end

        self:InitScrollRect(self._awardList)

        self._funId = self._levelRef.functionId
        if #showList == 0 or nil == showList then
            CS.ShowObject(self.mFunDispark, false)
            return
        end
        time = time + (#self._awardList * time)
    elseif (index == 3) then
        CS.ShowObject(self.mFunDispark, true)
        self:InitFunOpen(showList)
    else
        self:ClearTimerClose()
        return
    end
    self:StartDelayTimerClose(time)
end

function UILvUp:StartCantWndCloseTime()
    self:ClearCantWndCloseTime()
    self._canWndClose = false
    self._cantCloseTimer = LxTimer.DelayTimeCall(function()
        self:OnCantCloseTimerFun()
    end, 0.5)
end

------------------------------------------------------------------
return UILvUp