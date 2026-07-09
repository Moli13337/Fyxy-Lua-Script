---
--- Created by admin-pc.
--- DateTime: 2024/3/11 15:30:29
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDevSdkLogin:LWnd
local UIDevSdkLogin = LxWndClass("UIDevSdkLogin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDevSdkLogin:UIDevSdkLogin()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDevSdkLogin:OnWndClose()
    self:ClearAdaptKeyboard()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDevSdkLogin:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDevSdkLogin:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()

    self:InitTexts()
    self:InitClicks()
    self:InitDevLoginUI()
end

function UIDevSdkLogin:InitClicks()
    self:SetWndClick(self.mMask, function()
        self:TryLogin()
    end)

    self:SetWndClick(self.mBtnLogin, function()
        self:TryLogin()

    end)
end

function UIDevSdkLogin:InitDevLoginUI()
    local account = LPlayerPrefs.serverAccount
    local password = ""
    self:SetWndTextInput(self.mAccountText, account)
    self:SetWndTextInput(self.mPwdText, password)
end

function UIDevSdkLogin:InitTexts()
    self:SetWndText(self.mAccountLabel, ccClientText(166))
    self:SetWndText(self.mPwdLabel, ccClientText(165))

    if self._isEnus then
        self:InitTextSizeWithLanguage(self.mAccountLabel, -8)
        local pos = self.mAccountLabel.transform.localPosition
        self.mAccountLabel.transform.localPosition = pos + Vector3.New(-15, 0, 0)

        self:InitTextSizeWithLanguage(self.mPwdLabel, -8)

        local pos = self.mPwdLabel.transform.localPosition
        self.mPwdLabel.transform.localPosition = pos + Vector3.New(-15, 0, 0)
    end

    self:SetWndButtonText(self.mBtnLogin, ccClientText(164))
end

function UIDevSdkLogin:InitAdaptKeyboard()
    local uiAdaptKeyboard = UIAdaptKeyboard:New()
    self._uiAdaptKeyboard = uiAdaptKeyboard
    uiAdaptKeyboard:Create(self.mAccountText, self.mContentLoginObj.transform, Vector3.zero)
end

function UIDevSdkLogin:ClearAdaptKeyboard()
    if self._uiAdaptKeyboard then
        self._uiAdaptKeyboard:Destroy()
        self._uiAdaptKeyboard = nil
    end
end

function UIDevSdkLogin:TryLogin()
    local account = self.mAccountText.text
    if string.startswith(account, "Baiao_") then
        GF.ShowMessage("账号不能以 Baiao_ 开头")
        return
    end
    if not string.match(account, "^[A-Za-z0-9]*$") then
        GF.ShowMessage("账号只能用数字、字母组合")
        return
    end

    gLSdkImpl:CallMethod(LSdkMethod.OnLoginResult, account)
    self:WndClose()
end

------------------------------------------------------------------
return UIDevSdkLogin