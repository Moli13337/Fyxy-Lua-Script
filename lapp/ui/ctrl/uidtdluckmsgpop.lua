---
--- Created by BY.
--- DateTime: 2023/10/18 17:54:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDTDLuckMsgPop:LWnd
local UIDTDLuckMsgPop = LxWndClass("UIDTDLuckMsgPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDTDLuckMsgPop:UIDTDLuckMsgPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDTDLuckMsgPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDTDLuckMsgPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDTDLuckMsgPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()

	self:DisableInputText(self.mDesInput)
	self:DisableSensitiveInputText(self.mDesInput,ModelPlayer.SENSITIVE_TYPE_5)
	self:SetWndTextInput(self.mDesInput, "")
end

function UIDTDLuckMsgPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(23113))
	self:SetWndButtonText(self.mSendBtn,ccClientText(23114))

	self._isFace = true
	self:OnClickBFaceMask()
	self.mDesInput.characterLimit = GameTable.OneNightConfigRef["messageTextLength"]
	self:SetWndText(self.mPlaceholder,ccClientText(23108))
end

function UIDTDLuckMsgPop:OnClickFace(faceinstead)
	local str = self.mDesInput.text..faceinstead
	self:SetWndTextInput(self.mDesInput, str)
	--self.mDesInput.text = str
end

function UIDTDLuckMsgPop:OnInputDes(str)
	local len = LxUtf8.cnLen(str)
	local maxLen = GameTable.OneNightConfigRef["messageTextLength"]
	if(len > maxLen)then
		str = self._oldStr
		self:SetWndTextInput(self.mDesInput, str)
		--self.mDesInput.text = str
		len = LxUtf8.cnLen(str)
		GF.ShowMessage(ccClientText(23112))
	else
		self._oldStr = str
	end
	self:SetWndText(self.mLenText,len.."/"..maxLen)
	--激活聊天框不选中所有内容
	self.mDesInput.onFocusSelectAll = false
end

function UIDTDLuckMsgPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mFaceBtn, function(...) self:OnClickBFaceMask() end)
	self:SetWndClick(self.mFaceMask, function(...) self:OnClickBFaceMask() end)
	self:SetWndClick(self.mSendBtn, function(...) self:OnClickSend() end)
end

function UIDTDLuckMsgPop:OnInitList()
	local list = gModelChat:GetEmojiByType(1)--弹幕只有小表情
	if(self._uiFaceList)then
		self._uiFaceList:RefreshData(list)
	else
		self._uiFaceList = self:GetUIScroll("_uiFaceList")
		self._uiFaceList:Create(self.mFaceScroll,list,function (...) self:FaceListItem(...) end,UIItemList.WRAP)
	end
end

function UIDTDLuckMsgPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.SpaceLuckMessageResp,function (pb)
		GF.ShowMessage(ccClientText(23107))
		self:WndClose()
	end)
	self:SetInputValueChange(self.mDesInput,function (str)
		self:OnInputDes(str)
	end)
end

function UIDTDLuckMsgPop:FaceListItem(list, item, itemdata, itempos)
	local imageTran=CS.FindTrans(item,"Image")
	self:SetWndEasyImage(imageTran,itemdata.faceIcon)
	self:SetWndClick(imageTran, function (...) self:OnClickFace(itemdata.faceinstead) end)
end

function UIDTDLuckMsgPop:OnClickBFaceMask()
	self._isFace = not self._isFace
	CS.ShowObject(self.mFaceMask,self._isFace)
	if(self._isFace)then
		self:OnInitList()
	end
end

function UIDTDLuckMsgPop:OnClickSend()
	--local sendNum = GameTable.OneNightConfigRef["dailyMessageTime"]
	--local _spaceInfo = gModelOneNight:GetSpaceInfoPB()
	--local luckMessageCount = _spaceInfo.luckMessageCount or 0
	--if luckMessageCount >= sendNum then
	--	GF.ShowMessage(ccClientText(23110))
	--	return
	--end
	--local msg = self.mDesInput.text
	--msg = LUtil.FilterEmoji(msg)
	--local len = LxUtf8.cnLen(msg)
	--local maxLen = GameTable.OneNightConfigRef["messageTextLength"]
	--if(len > maxLen)then
	--	GF.ShowMessage(ccClientText(23112))
	--	self:SetWndTextInput(self.mDesInput, LxUtf8.sub(msg,1,len))
	--	--self.mDesInput.text = LxUtf8.sub(msg,1,len)
	--	return
	--elseif(msg == "")then
	--	GF.ShowMessage(ccClientText(23108))
	--	return
	--end
	----local _msg = LWordMaskUtil.ClearShieldWord(msg,false,nil,true)
	--
	--local func = function(isMatch,newText)
	--	local finalText = LUtil.ChatInfoFaceDecToBin(newText)
	--	gModelOneNight:SpaceLuckMessageReq(finalText)
	--end
	--
	--LWordMaskUtil.ClearShieldWordEx(msg,false,true,LGameWordMask.SCENE_TYPE_PUBLIC_DATA,func)

	--_msg = LUtil.ChatInfoFaceDecToBin(_msg)
	----local _msg = LWordMaskUtil.ClearShieldWord(msg,false,nil,true)
	--gModelOneNight:SpaceLuckMessageReq(_msg)
end
------------------------------------------------------------------
return UIDTDLuckMsgPop


