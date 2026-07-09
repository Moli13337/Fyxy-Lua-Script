---
--- Created by Administrator.
--- DateTime: 2025/11/12 18:29:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPhoneBinding:LWnd
local UIPhoneBinding = LxWndClass("UIPhoneBinding", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPhoneBinding:UIPhoneBinding()
	self._getCodeTimer = "_getCodeTimer"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPhoneBinding:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPhoneBinding:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPhoneBinding:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UIPhoneBinding:IsValidPhoneNumber(phoneNum)
	local phone = string.gsub(phoneNum,"[%s%-%(%)]","")
	if #phone ~= 11 then
		GF.ShowMessage(ccClientText(47610))
		return
	end
end

function UIPhoneBinding:GetInputPhoneNum()
	return self.mInputNumber.text
end

function UIPhoneBinding:OnEventSdkMobileAuthCodeResult()
	self:RefreshView()
end

function UIPhoneBinding:InitMsg()
	self:WndEventRecv(EventNames.SDK_ACCOUNTBIND_RESULT,function (...) self:OnEventSdkAccountbindResult(...) end)
	self:WndEventRecv(EventNames.SDK_MOBILE_AUTHCODE_RESULT,function (...) self:OnEventSdkMobileAuthCodeResult(...) end)
end

function UIPhoneBinding:NextGetCodeLastTime()
	local getCodeCDTime = self:GetCodeCDTime()
	if getCodeCDTime < 1 then return 0 end
	return getCodeCDTime - GetTimestamp()
end

function UIPhoneBinding:InitData()
end

function UIPhoneBinding:InitText()
	self:SetWndText(self.mTitleTxt,ccClientText(47600))
	self:SetWndText(self.mDescTxt,ccClientText(47601))
	self:SetWndTextInput(self.mInputNumber,nil,ccClientText(47602))
	self:SetWndTextInput(self.mInputCode,nil,ccClientText(47603))
	self:SetWndButtonText(self.mBtnGetCode,ccClientText(47604))
	self:SetWndButtonText(self.mBtnBinding,ccClientText(47605))
end

function UIPhoneBinding:GetCodeCDTime()
	return checknumber(LPlayerPrefs.getCodeCDTime)
end

function UIPhoneBinding:RefreshView()
	local timeKey = self._getCodeTimer
	self:TimerStop(timeKey)
	local lastTime = self:NextGetCodeLastTime()
	if lastTime > 0 then
		self:TimerStart(timeKey,lastTime,false,-1)
	end

end

function UIPhoneBinding:RefreshGetCodeBtn()
	local btnName = ""
	local lastTime = self:NextGetCodeLastTime()
	if lastTime > 0 then
		btnName = string.replace(ccClientText(47608),lastTime)
	else
		btnName = ccClientText(47604)
		self:TimerStop(self._getCodeTimer)
	end
	self:SetWndButtonText(self.mBtnGetCode,btnName)
end

function UIPhoneBinding:OnClickBtnGetCodeFunc()
	local phoneNum = self:GetInputPhoneNum()
	if string.isempty(phoneNum) then
		GF.ShowMessage(ccClientText(47606))
		return
	end
	local lastTime = self:NextGetCodeLastTime()
	if lastTime > 0 then
		GF.ShowMessage(string.replace(ccClientText(47609),lastTime))
		return
	end
	gLSdkImpl:CallMethod(LSdkMethod.SendMobileAuthCode,phoneNum)
end

function UIPhoneBinding:OnEventSdkAccountbindResult(isOk)
	if isOk then
		self:WndClose()
	end
end

function UIPhoneBinding:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mBtnGetCode,function() self:OnClickBtnGetCodeFunc() end)
	self:SetWndClick(self.mBtnBinding,function() self:OnClickBtnBindingFunc() end)
end

function UIPhoneBinding:OnTimer(key)
	if key == self._getCodeTimer then
		self:RefreshGetCodeBtn()
	end
end

function UIPhoneBinding:OnClickBtnBindingFunc()
	FireEvent(EventNames.CLICK_PHONE_BIND_BTN)
	local phoneNum = self:GetInputPhoneNum()
	if string.isempty(phoneNum) then
		GF.ShowMessage(ccClientText(47606))
		return
	end
	local codeNum = self.mInputCode.text
	if string.isempty(codeNum) then
		GF.ShowMessage(ccClientText(47607))
		return
	end
	gLSdkImpl:CallMethod(LSdkMethod.BindToMobile,phoneNum,codeNum)
end

------------------------------------------------------------------
return UIPhoneBinding