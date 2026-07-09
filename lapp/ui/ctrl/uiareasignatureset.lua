---
--- Created by BY.
--- DateTime: 2023/10/2 16:10:42
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAreaSignatureSet:LWnd
local UIAreaSignatureSet = LxWndClass("UIAreaSignatureSet", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAreaSignatureSet:UIAreaSignatureSet()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAreaSignatureSet:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAreaSignatureSet:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAreaSignatureSet:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()

	self:DisableInputText(self.mSignatureInput)
	self:DisableSensitiveInputText(self.mSignatureInput,ModelPlayer.SENSITIVE_TYPE_2)
end

function UIAreaSignatureSet:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(21131))
	self:SetWndButtonText(self.mBtnYellow2,ccClientText(21130))
	self._textMax = gModelPlayer:GetRoleConfigRefByKey("personalSignatureNum")
	self.mSignatureInput.characterLimit = self._textMax
	local signature = gModelPlayer:GetPlayerSignature()
	if signature == "" then
		signature = ccClientText(21109)
	end

	-- signature = ccClientText(21109)

	self._oldSignature = signature
	--self.mSignatureInput.text = signature
	self:SetWndTextInput(self.mSignatureInput,  signature)
end

function UIAreaSignatureSet:InitEvent()
	self:SetWndClick(self.mBgImage, function (...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnClose, function (...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnYellow2, function (...) self:OnClickReq() end)
end

function UIAreaSignatureSet:OnClickReq()
	local signature = self.mSignatureInput.text
	if signature == self._oldSignature then
		self:WndClose()
		return
	end
	if signature == "" then
		signature = ccClientText(21109)
	end
	signature = LUtil.FilterEmoji(signature,"?")
	local length = LxUtf8.cnLen(signature)

	if(length > self._textMax)then
		GF.ShowMessage(ccClientText(21133))
		return
	end

	local func = function(isMatched,newText)
		if self:IsWndClosed() then
			return
		end

		if isMatched then
			--self.mSignatureInput.text = newText
			self:SetWndTextInput(self.mSignatureInput,  newText)
			GF.ShowMessage(ccClientText(21134))
		else
			gModelPlayerSpace:OnPlayerChangeInfoReq(3,newText)
		end
	end

	LWordMaskUtil.ClearShieldWordEx(signature,false,false,LGameWordMask.SCENE_TYPE_PUBLIC_DATA,func)

	--local name,bool = LWordMaskUtil.ClearShieldWord(signature,false,ccClientText(21134),true)
	--if(not bool)then
	--	self.mSignatureInput.text = name
	--	return
	--end
    --
	--gModelPlayerSpace:OnPlayerChangeInfoReq(3,signature)
end

function UIAreaSignatureSet:OnInputDes(str)
	local length = LxUtf8.cnLen(str)
	if(length > self._textMax)then
		str = self._oldStr
		--self.mSignatureInput.text = str
		self:SetWndTextInput(self.mSignatureInput,  str)
		length = LxUtf8.cnLen(str)
		GF.ShowMessage(ccClientText(21133))
	else
		self._oldStr = str
	end
	self:SetWndText(self.mNumText,length.."/"..self._textMax)
end

function UIAreaSignatureSet:OnClickClose()
	local signature = self.mSignatureInput.text
	if signature == self._oldSignature then
		self:WndClose()
		return
	end
	gModelGeneral:OpenUIOrdinTips({refId = 50008,leftFunc = function () self:WndClose() end ,func = function () self:OnClickReq() end})
end

function UIAreaSignatureSet:InitMessage()
	self:WndNetMsgRecv(LProtoIds.PlayerChangeInfoResp,function (...)
		GF.ShowMessage(ccClientText(21147))
		self:WndClose()
	end)
	self.mSignatureInput.onValueChanged:AddListener(function (str)
		self:OnInputDes(str)
	end)
end
------------------------------------------------------------------
return UIAreaSignatureSet


