---
--- Created by BY.
--- DateTime: 2023/10/23 16:01:07
---
------------------------------------------------------------------
local LWnd = LWnd
local LxUtf8 = LXFW.LxUtf8
---@class UIGdHeaderPop:LWnd
local UIGdHeaderPop = LxWndClass("UIGdHeaderPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHeaderPop:UIGdHeaderPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHeaderPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHeaderPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHeaderPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdHeaderPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildInfoChangeResp,function (...)
		self:WndClose()
	end)
	self:WndNetMsgRecv(LProtoIds.GuildChangeResp,function (pb)
		if(pb.type == 6)then
			GF.ShowMessage(ccClientText(12508))
			self:WndClose()
		end
	end)
	self.mDesInput.onValueChanged:AddListener(function (str)
		self:OnInputDes(str)
	end)
end


function UIGdHeaderPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mOverBtn, function(...) self:WndClose() end)
end

function UIGdHeaderPop:OnInputDes(str)
	local length = LxUtf8.cnLen(str)
	local maxLen = gModelGuild:GetAnnouncementNum()
	if(length > maxLen)then
		str = self._oldStr
		--self.mDesInput.text = str
		self:SetWndTextInput(self.mDesInput, str)
		length = LxUtf8.cnLen(str)
		GF.ShowMessage(string.replace(ccClientText(12510),maxLen))
	else
		self._oldStr = str
	end
	--激活聊天框不选中所有内容
	self.mDesInput.onFocusSelectAll = false
	self:SetWndText(self.mDesLenText,length.."/"..gModelGuild:GetAnnouncementNum())
end

function UIGdHeaderPop:OnClickSend()
	local des=self.mDesInput.text
	des= LUtil.FilterEmoji(des,"?")
	local length = LxUtf8.cnLen(des)
	local lengLimit=gModelGuild:GetAnnouncementNum()
	if length <= 0 then
		GF.ShowMessage(ccClientText(12582))
		return
	end
	if(length>lengLimit)then
		GF.ShowMessage(string.replace(ccClientText(12510),lengLimit))
		return
	end

	local func = function(isMatched,newText)
		if self:IsWndClosed() then
			return
		end

		if isMatched then
			--self.mDesInput.text = newText
			self:SetWndTextInput(self.mDesInput,newText)
			GF.ShowMessage(ccClientText(12511))
		else
			gModelGuild:OnGuildInfoChangeReq(3,newText)
		end
	end

	LWordMaskUtil.ClearShieldWordEx(des,false,false,LGameWordMask.SCENE_TYPE_PUBLIC_DATA,func)


	--local des,bool = LWordMaskUtil.ClearShieldWord(des,false,ccClientText(12511))
	--if(not bool)then
	--	self.mDesInput.text = des
	--	return
	--end
	--gModelGuild:OnGuildInfoChangeReq(3 , des)
end

function UIGdHeaderPop:InitCommand()
	--local _isAuto = self:GetWndArg("isAuto")
	self:SetWndText(self.mTitleText,ccClientText(12483))
	self.mDesInput.characterLimit = gModelGuild:GetAnnouncementNum()
	self:DisableInputText(self.mDesInput)
	self:DisableSensitiveInputText(self.mDesInput,ModelPlayer.SENSITIVE_TYPE_4)
	local guildInfo = gModelGuild:GetGuildInfo()
	if(guildInfo.announcement ~= "")then
		--self.mDesInput.text = guildInfo.announcement
		self:SetWndTextInput(self.mDesInput, ccLngText(guildInfo.announcement))
	else
		--local inputText = CS.FindTrans(self.mDesInput_1,"Text Area/Placeholder")
		--self:SetWndText(inputText,ccClientText(12521))
		self:SetWndTextInput(self.mDesInput, nil, ccClientText(12521))
	end
	--if _isAuto then
	--	self:SetWndButtonText(self.mOutBtn,ccClientText(12484))
	--	CS.ShowObject(self.mOverBtn,false)
	--	self:SetWndClick(self.mOutBtn, function(...) self:WndClose() end)
	--	return
	--end
	local selfInfo = gModelGuild:GetSelfGuildInfo()
	local func = nil
	if selfInfo.position > 2 then
		self.mDesInput.interactable = false
		CS.ShowObject(self.mOverBtn,false)
		func = function () self:WndClose() end
	else
		func = function () self:OnClickSend() end
	end
	self:SetWndButtonText(self.mOutBtn,ccClientText(12484))
	self:SetWndButtonText(self.mOverBtn,ccClientText(12432))
	self:SetWndClick(self.mOutBtn, function(...) if func then func () end end)

	CS.ShowObject(self.mDesLenText, gModelGuild:GetGuildPosition() <= 2)
end
------------------------------------------------------------------
return UIGdHeaderPop


