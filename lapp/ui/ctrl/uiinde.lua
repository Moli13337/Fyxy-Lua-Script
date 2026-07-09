---
--- Created by Administrator.
--- DateTime: 2023/10/12 16:05:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIInde:LWnd
local UIInde = LxWndClass("UIInde", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIInde:UIInde()
	self._countDownKey ="countDownKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIInde:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIInde:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIInde:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
    self:InitData()
	self:InitCommand()
	self:DisableInputText(self.mGiftCodeText)
end

function UIInde:OnClickBtn()
	if not self._isClick then
		self._isClick = true
		self:TimerStart(self._countDownKey,5,false,-1)
		local giftCode = self.mGiftCodeText.text
		if not self:CheckCode(giftCode) then
			return
		end
		gModelActivity:OnActivityInvitationReq(ModelActivity.SET_INVITE_CODE,self._sid, giftCode)
	else
		GF.ShowMessage(ccClientText(14008))
	end
end

function UIInde:InitCommand()
	self:SetWndText(self.mTitleText, ccClientText(23601))
	self:SetWndButtonText(self.mBtnYellow2, ccClientText(23602))
	self:SetWndText(self.mTipsText,ccClientText(10103))
end

function UIInde:OnActivityInvitationResp(pb,ret)
	if pb.sid == self._sid and pb.opera == ModelActivity.SET_INVITE_CODE then
		self:WndClose()
	end
end

function UIInde:OnTimer(key)
	if key == self._countDownKey then
		self._isClick = false
	end
end

function UIInde:InitData()
    self._sid = self:GetWndArg("sid")
end

function UIInde:CheckCode(codeStr)
	if string.isempty(codeStr) then
		GF.ShowMessage(ccClientText(23606))
		return false
	end

	return true
end

function UIInde:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ActivityInvitationResp,function (...)
		self:OnActivityInvitationResp(...)
	end)
end

function UIInde:InitEvent()
	self:SetWndClick(self.mBgImage,function() self:WndClose() end)
	self:SetWndClick(self.mBtnYellow2,function() self:OnClickBtn() end)
end


------------------------------------------------------------------
return UIInde


