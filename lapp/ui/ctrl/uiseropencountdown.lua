---
--- Created by By.
--- DateTime: 2023/10/29 17:46:45
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISerOpenCountDown:LWnd
local UISerOpenCountDown = LxWndClass("UISerOpenCountDown", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISerOpenCountDown:UISerOpenCountDown()
    self._timerKey = "_countdown"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISerOpenCountDown:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISerOpenCountDown:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISerOpenCountDown:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isAmerica = gLGameLanguage:IsAmericaRegion()

    self:InitStaticContent()
    self:InitEvent()

    self:InitServerOpenTime()
    self:CheckCountTime()
    self:StartCountdown()
end

function UISerOpenCountDown:UpdateCountTimeUI()
    local timespan = math.floor(self._countDownValue or 0)
    local day = 0
    local hour = 0
    local min = 0
    local sec = 0

    day = math.floor(timespan / 86400)
    timespan = timespan % 86400

    hour = math.floor(timespan / 3600)
    timespan = timespan % 3600

    min = math.floor(timespan / 60)
    timespan = timespan % 60
    sec = timespan

    self:SetWndText(self.mTextDay, self:GenerateText(day))
    self:SetWndText(self.mTextHour, self:GenerateText(hour))
    self:SetWndText(self.mTextMin, self:GenerateText(min))
    self:SetWndText(self.mTextSec, self:GenerateText(sec))
end

function UISerOpenCountDown:InitServerOpenTime()
    local countDownTimeValue = self:GetWndArg("countDownTimeValue") or 0
    if countDownTimeValue <= 0 then
        countDownTimeValue = 0
    end
    countDownTimeValue = countDownTimeValue + GetTimestamp()
    self._countDownTime = countDownTimeValue
end

function UISerOpenCountDown:GenerateText(num)
    return tostring(num)
    --local textStr = ""
    --if num < 10 then
    --	textStr = string.format("<sprite index=%s><sprite index=%s>", "0", tostring(num))
    --elseif num < 100 then
    --	local hnum = math.floor(num / 10)
    --	local lnum = num % 10
    --	textStr = string.format("<sprite index=%s><sprite index=%s>", tostring(hnum), tostring(lnum))
    --else
    --	textStr = string.format("<sprite index=%s><sprite index=%s>", "9", "9")
    --end
    --return textStr
end

function UISerOpenCountDown:UpdateButtonShow()
    local val = self._countDownValue
    local isShowRestart = false
    if val <= 0 then
        isShowRestart = true
    end
    if self._isShowRestart == nil or isShowRestart ~= self._isShowRestart then
        self._isShowRestart = isShowRestart

        CS.ShowObject(self.mRestartDiv, isShowRestart)

        --这里进行切换
        CS.ShowObject(self.mBtnDiv, false)
        CS.ShowObject(self.mBtnDiv_enus, false)
        if self._isAmerica then
            CS.ShowObject(self.mBtnDiv_enus, not isShowRestart)
        else
            CS.ShowObject(self.mBtnDiv, not isShowRestart)
        end
    end
end

function UISerOpenCountDown:InitEvent()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mBtnOk, function(...)
        --RestartGame()
        self:WndClose()
    end)
    self:SetWndClick(self.mBtnRead, function(...)
        self:OpenNotice()
    end)
    self:SetWndClick(self.mBtnJump_1, function(...)
        local url = gModelNormalActivity:GetBIActivityConfigRefByKey("facebookLink")
        if string.isempty(url) then
            return
        end
        CS.UApplication.OpenURL(url)
    end)

    self:SetWndClick(self.mBtnJump_2, function(...)
        local url = gModelNormalActivity:GetBIActivityConfigRefByKey("discordLink")
        if string.isempty(url) then
            return
        end
        CS.UApplication.OpenURL(url)
    end)
end

function UISerOpenCountDown:CheckCountTime()
    local countVal = math.floor(self._countDownTime - GetTimestamp())
    if countVal <= 0 then
        countVal = 0
    end
    local lastVal = self._countDownValue
    if not lastVal or lastVal ~= countVal then
        self._countDownValue = countVal
        self:UpdateCountTimeUI()
        self:UpdateButtonShow()
    end
end

function UISerOpenCountDown:OpenNotice()
    if gLGameLogin:HasNotice() then
        local dataList = gLGameLogin:GetPlatformNotices()
        GF.OpenWndTop("UIBulin", { type = 2, list = dataList })
    end
end

function UISerOpenCountDown:StartCountdown()
    self:TimerStart(self._timerKey, 0.3, false, -1)
end

function UISerOpenCountDown:OnTimer(key)
    if key == self._timerKey then
        if not self:IsWndValid() then
            return
        end
        self:CheckCountTime()
    end
end

function UISerOpenCountDown:InitStaticContent()
    self:SetWndText(self.mCloseTip, ccClientText(10103))

    self:SetWndText(self.mBtnReadName, ccClientText(32804))
    self:SetWndText(self.mBtnOkName, ccClientText(32807))

    self:SetWndText(self.mBtnJump_1Name, ccClientText(32808)) -- [32808] [跳轉Facebook]
    self:SetWndText(self.mBtnJump_2Name, ccClientText(32809)) -- [32809] [跳轉Discord]

    self:SetWndText(self.mTxtTips, ccClientText(32806))
    self:SetWndText(self.mTextDayName, ccClientText(32800))
    self:SetWndText(self.mTextHourName, ccClientText(32801))
    self:SetWndText(self.mTextMinName, ccClientText(32802))
    self:SetWndText(self.mTextSecName, ccClientText(32803))

    local showCommunity = false
    local packageId = gLSdkImpl:CallMethod(LSdkMethod.GetSdkPackageId) or "0"
    packageId = checknumber(packageId)
    if packageId == 201 or packageId == 103 then
        showCommunity = true
        self:SetCommonButtonText(self.mBtnGoCommunity,ccClientText(32805))

        self:SetWndClick(self.mBtnGoCommunity,function()
            CS.UApplication.OpenURL("https://l.taptap.cn/b3N6aOoQ?channel=rep-rep_exlswmxhicy")
        end)
    end
    CS.ShowObject(self.mBtnGoCommunity,showCommunity)
end

------------------------------------------------------------------
return UISerOpenCountDown


