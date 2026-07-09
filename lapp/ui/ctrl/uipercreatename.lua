---
--- Created by Administrator.
--- DateTime: 2023/10/17 15:10:07
---
------------------------------------------------------------------
local LWnd = LWnd
local LxUtf8 = LXFW.LxUtf8
local UnityEngine = UnityEngine
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)

---@class UIPerCreateName:LWnd
local UIPerCreateName = LxWndClass("UIPerCreateName", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPerCreateName:UIPerCreateName()
	self._oldStr = ""
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPerCreateName:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPerCreateName:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPerCreateName:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	GF.CloseWndByName("UIGueTip")

	self:SetPara()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()

	self:PlayShowAni()

	FireEvent(EventNames.CREATE_ROLE_START)

end

function UIPerCreateName:PlayReNameAnim()
	CS.ShowObject(self.mBottomNode,false)
	self:TriggerNextStep()
end

function UIPerCreateName:SetPara()
	self._isNew = self:GetWndArg("isNew")
	self._canClickCreateName = false
end

function UIPerCreateName:InitEvent()
	self:SetWndClick(self.mRandomBtn,function (...) self:OnClickRandom() end)
	self:SetWndClick(self.mCreateBtn,function (...) self:OnClickSub() end)

	self.mNameInput.onValueChanged:AddListener(function(str) self:OnInputDesc(str)  end)

	self:WndEventRecv(EventNames.NET_ERROR_CODE, function(msgId)
		if msgId == LProtoIds.PlayerReNameResp then
			self._canClickCreateName = true

			FireEvent(EventNames.CREATE_ROLE_FINISH, false)
		end
	end)


end

function UIPerCreateName:ShowInputText(isShow)
	CS.ShowObject(self.mNameInput, isShow)
	CS.ShowObject(self.mRandomBtn, isShow)
end

function UIPerCreateName:OnTryTcpReconnect()
	self._canClickCreateName = true
end

function UIPerCreateName:OnClickSub()
	if not self._canClickCreateName then
		return
	end

	if self._isBuy==false then
		GF.ShowMessage(ccClientText(10411))
		return
	end
	local nameText=self.mNameInput.text
	local bool
	if self._oldName == nameText then
		GF.ShowMessage(ccClientText(10405))
		return
	end

	if not gLGameLanguage:IsForeignRegion() then
		bool = string.find(nameText, " ")
		if bool then
			GF.ShowMessage(ccClientText(10409))
			return
		end
	else
		local isSpaceEdge = string.startswith(nameText, " ")
		if not isSpaceEdge then
			isSpaceEdge = string.endswith(nameText, " ")
		end
		if isSpaceEdge then
			GF.ShowMessage(ccClientText(10424))
			return
		end
	end

	local length = LxUtf8.cnLen(nameText)
	if(length < gModelPlayer:GetRoleConfigRefByKey("nameLengthMin"))then
		GF.ShowMessage(ccClientText(10417))
		return
	elseif(length > gModelPlayer:GetRoleConfigRefByKey("nameLengthMax"))then
		GF.ShowMessage(ccClientText(10406))
		return
	end

	local func = function(isMatched,newText)
		if self:IsWndClosed() then
			return
		end


		if isMatched then
			--self.mNameInput.text = newText
			self:SetWndTextInput(self.mNameInput, newText)
			GF.ShowMessage(ccClientText(10408))
		else
			self._nameText = newText
			self:OnRenameReq()
		end
	end
	LWordMaskUtil.ClearShieldWordEx(nameText,false,false,LGameWordMask.SCENE_TYPE_PUBLIC_DATA,func)
end

function UIPerCreateName:PlayShowAni()
	if CS.IsValidObject(self.mCoverBg) then
		CS.ShowObject(self.mCoverBg, false)
	end
	CS.ShowObject(self.mBottomNode,true)
	self._canClickCreateName = true
end

function UIPerCreateName:OnClickRandom()
	gModelPlayer:OnClickRandom(self._oldSex)
end

function UIPerCreateName:TriggerNextStep()
	if not self._createSuc then
		return
	end
	local isFromFront = self:GetWndArg("isFromFront")
	if isFromFront then
		GF.OpenWnd("UISyFront")
	elseif self:GetWndArg("FromNewbieEventId") then
		gLGpManager:FindNewbieGp():OnEventEnd(self:GetWndArg("FromNewbieEventId"))
	elseif self:GetWndArg("FromNoName") then
		self:WndClose()
	else
		FireEvent(EventNames.ON_CREATE_NAME_END)
	end
end

function UIPerCreateName:OnRenameEnd()
	local isFromFront = self:GetWndArg("isFromFront")
	if not isFromFront then
		FireEvent(EventNames.ON_RENAME_SUCCESS) --改名成功触发
	end

	if self._isNew then
		self._createSuc = true
	end

	self._canClickCreateName = false
	self:PlayReNameAnim()
end

function UIPerCreateName:InitCommand()
	self._noMsg = true --不发公告和邮件

	self._oldSex=gModelPlayer:GetPlayerSex()

	self.NameGeneratorConfigRef = GameTable.NameGeneratorConfigRef
	local num= gModelItem:GetNumByRefId(self.NameGeneratorConfigRef["renameItem"])
	self._oldName=gModelPlayer:GetPlayerName()
	self:SetWndTextInput(self.mNameInput, "", ccClientText(10419))

	local textInput = self:FindTextInput(self.mNameInput)
	self:DisableInputText(textInput)
	self:DisableSensitiveInputText(textInput,ModelPlayer.SENSITIVE_TYPE_2)

	self:SetWndButtonText(self.mCreateBtn, ccClientText(10423))

	if tonumber(num)>0 then
		self._isBuy = true
	else
		local item= self.NameGeneratorConfigRef["renameCost"]
		local strArr =string.split(item,"=")
		local itemId=tonumber(strArr[2])
		num=gModelItem:GetNumByRefId(itemId)
		self._isBuy = tonumber(num) >=tonumber(strArr[3])
	end

	CS.ShowObject(self.mBottomNode, false)
	self:OnClickRandom()
end

function UIPerCreateName:OnInputDesc(str)
	local len = LxUtf8.cnLen(str)
	local maxLen = gModelPlayer:GetRoleConfigRefByKey("nameLengthMax")
	if (len > maxLen) then
		str = self._oldStr
		self:SetWndTextInput(self.mNameInput, str)
		len = LxUtf8.cnLen(str)
		GF.ShowMessage(ccClientText(10406))
	else
		self._oldStr = str
	end
end

function UIPerCreateName:RandomNameResp(cmd)
	self:SetWndTextInput(self.mNameInput, cmd.name)
end

function UIPerCreateName:InitMessage()
	self:WndNetMsgRecv(LProtoIds.PlayerRandomNameResp,function (...)
		self:RandomNameResp(...)
	end)
	self:WndNetMsgRecv(LProtoIds.PlayerReNameResp,function (...)
		FireEvent(EventNames.CREATE_ROLE_FINISH, true)
		self:OnRenameEnd()

	end)
end

function UIPerCreateName:OnRenameReq()
	if not self._nameText then
		GF.ShowMessage(ccClientText(10409))
		printInfoNR("self._nameText is a nil")
		return
	end
	self._canClickCreateName = false

	gModelPlayer:OnRenameReq(self._nameText,self._oldSex,self._noMsg, true)
end

------------------------------------------------------------------
return UIPerCreateName


