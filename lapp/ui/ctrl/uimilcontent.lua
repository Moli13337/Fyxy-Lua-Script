---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMilContent:LWnd
local UIMilContent = LxWndClass("UIMilContent", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMilContent:UIMilContent()
    self._validTimerKey = "_validTimerKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMilContent:OnWndClose()
    self:ClearCommonIconList(self._hyperList)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMilContent:OnCreate()
    LWnd.OnCreate(self)

    self._hyperList = {}
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMilContent:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:RefreshUI()
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mOkBtn, function()
        self:DeleteMail()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UIMilContent:RefreshValidTime()
    local expiredTime = self._expiredTime
    local haveValid = expiredTime and expiredTime ~= 0

    CS.ShowObject(self.mValidTime, haveValid)
    if not haveValid then
        return
    end

    self:TimerStart(self._validTimerKey, 1, false, -1)
    self:StarCountDown()
end

function UIMilContent:RefreshUI()
    local str = ccClientText(11202)
    self:SetWndText(self.mMailTitle, str)
    self:SetWndButtonText(self.mOkBtn, ccClientText(11213))

    local mail = self:GetWndArg("mail")
    local sendname = self:GetWndArg("sendname")
    if not mail._read then
        gModelMail:MailReaderReq(mail._mailId)
    end
    self._mailId = mail._mailId

    local refId = mail._refId
    local title = nil
    local replacedContent = nil
    local sender = nil

    local hyperCreateFun = function(tran)
        if not CS.IsValidObject(tran) then
            return
        end
        local instanceId = tran:GetInstanceID()
        local hyper = self._hyperList[instanceId]
        if not hyper then
            hyper = UIHyperText:New()
            self._hyperList[instanceId] = hyper
            hyper:Create(tran)
        end
        return hyper
    end

    local wndName = self:GetWndName()

    if refId == 0 then
        title = mail._tile
        replacedContent = mail._content
        sender = mail._signature

        replacedContent = LUtil.CreateHyperWithValue(self.mContent, replacedContent, hyperCreateFun, function(data)
            local key = data.key

            if key == "keysdkurl" then
                local v = data.msg
                --if LGameSettings.platformRegion == LRegionConst.JAPAN then
                    if not string.isempty(v) then
                        gLSdkImpl:CallMethod(LSdkMethod.OpenSurvey, v, true)
                    end
                    return
                --end
            end
            gModelChat:ClickHyper(data, wndName)
        end)

        replacedContent = string.gsub(replacedContent, "\\n", "\n")

    else
        local cfg = gModelMail:GetMailCfg(refId)
        if not cfg then
            printErrorN("no mail cfg " .. refId)
            return
        end

        local cfgContent = ccLngText(cfg.content)
        local cfgTitle = ccLngText(cfg.title)
        local shiftNumIndex = cfg.shiftNumIndex
        title = mail._tile
        local content = mail._content

        if refId == 1 then
            --新角色登录游戏第一份邮件特殊处理
            local appName = LNativeHelper.GetAppName();
            title = "{\"a1\":\"" .. appName .. "\"}"
            content = title
        end

        title = LUtil.GetReplacedContent(cfgTitle, title) --gModelMail:GetReplacedContent(cfgTitle,title)
        title = string.gsub(title, "\\n", "\n")
        replacedContent = LUtil.GetReplacedContent(cfgContent, content, shiftNumIndex) --gModelMail:GetReplacedContent(cfgContent,content)

        replacedContent = LUtil.CreateHyperWithValue(self.mContent, replacedContent, hyperCreateFun, function(data)
            gModelChat:ClickHyper(data, wndName)
        end)

        replacedContent = string.gsub(replacedContent, "\\n", "\n")
        sender = ccLngText(cfg.signature)

        if refId == 604 then
            --local guildInfo = gModelGuild:GetGuildInfo()
            --if guildInfo then
            --    local chairman = guildInfo.chairman
            --    sender=string.replace(sender, chairman._name)
            --end
            sender=string.replace(sender, mail._sendName)
        end

        local needCheck = gModelMail:CheckNeedShield(refId)
        if needCheck then
            replacedContent = LWordMaskUtil.ClearShieldWord(replacedContent, true) --屏蔽字
        end
    end

    self:SetWndText(self.mArrowTitle, title)
    self:SetWndText(self.mContent, replacedContent)
    self:SetWndText(self.mSender, sender)
    local receiveTime = LUtil.OSDate("*t", mail._receiveTime / 1000)
    local timeStr = string.format("%d.%d.%d", receiveTime["year"], receiveTime["month"], receiveTime["day"])
    self:SetWndText(self.mDate, timeStr)

    --有效期
    local expiredTime = mail._expiredTime
    if expiredTime then
        self._expiredTime = expiredTime / 1000
    end

    self:RefreshValidTime()
end

function UIMilContent:OnTimer(key)
    if key == self._validTimerKey then
        self:StarCountDown()
    end
end
function UIMilContent:DeleteMail()
    gModelMail:MailRemoveReq(1, self._mailId)
    self:WndClose()
end

function UIMilContent:StarCountDown()
    local lastTime = self._expiredTime - GetTimestamp()
    if lastTime < 0 then
        CS.ShowObject(self.mValidTime, false)
        self:TimerStop(self._validTimerKey)
        return
    end

    local timeStr = LUtil.FormatTimespanCn(lastTime)
    timeStr = string.replace(ccClientText(11217), timeStr)
    self:SetWndText(self.mValidTime, timeStr)
end

------------------------------------------------------------------
return UIMilContent


