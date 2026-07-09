---
--- Created by BY.
--- DateTime: 2023/10/23 14:57:14
---
------------------------------------------------------------------
local LWnd = LWnd
local LxUtf8 = LXFW.LxUtf8
---@class UIGdMilPop:LWnd
local UIGdMilPop = LxWndClass("UIGdMilPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdMilPop:UIGdMilPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdMilPop:OnWndClose()
	self:OnClickWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdMilPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdMilPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdMilPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildMailNoticeResp,function (...)
		GF.ShowMessage(ccClientText(12518))
		self:WndClose()
	end)
	self.mDesInput.onValueChanged:AddListener(function (str)
		self:OnInputDes(str)
	end)
end

function UIGdMilPop:OnClickWndClose()
	local callFunc = self._callFunc
	if callFunc then
		callFunc()
	end
	self:WndClose()
end

function UIGdMilPop:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mOverBtn, function(...) self:WndClose() end)
	self:SetWndClick(self.mSendBtn, function(...) self:OnClickSend() end)
end

function UIGdMilPop:InitCommand()
	self._callFunc = self:GetWndArg("callFunc")
	self.mDesInput.characterLimit=gModelGuild:GetMailMaxNum()
	self:DisableInputText(self.mDesInput)
	self:DisableSensitiveInputText(self.mDesInput,ModelPlayer.SENSITIVE_TYPE_4)
	--local text = CS.FindTrans(self.mDesInput_1,"Text Area/Placeholder")
	--self:SetWndText(text,ccClientText(12583))
	self:SetWndTextInput(self.mDesInput, nil, ccClientText(12583))
	local guildInfo=gModelGuild:GetGuildInfo()
	local limit = gModelGuild:GetGuildConfigRefByKey("mailLimit")
	self._num = limit-guildInfo.mailCount
	self:SetWndText(self.mTitleText,ccClientText(12475))
	self:SetWndText(self.mNumText,string.replace(ccClientText(12476),self._num))
	self:OnInputDes(self.mDesInput.text)
	self:SetWndButtonText(self.mSendBtn,ccClientText(12433))
	self:SetWndButtonText(self.mOverBtn,ccClientText(10101))
end

function UIGdMilPop:OnClickSend()
	if(self._num<=0)then
		GF.ShowMessage(ccClientText(12554))
		return
	end
	local des=self.mDesInput.text
	des= LUtil.FilterEmoji(des,"?")
	local length = LxUtf8.cnLen(des)
	local limLen=gModelGuild:GetMailMaxNum()
	if(length>limLen)then
		GF.ShowMessage(string.replace(ccClientText(12510),limLen))
		return
	elseif(des=="")then
		GF.ShowMessage(ccClientText(12517))
		return
	end

	local func = function(isMatched,newText)
		if self:IsWndClosed() then
			return
		end

		if isMatched then
			--self.mDesInput.text = newText
			self:SetWndTextInput(self.mDesInput, newText)
			GF.ShowMessage(ccClientText(12544))
		else
			gModelGuild:OnGuildMailNoticeReq(des)
		end
	end

	LWordMaskUtil.ClearShieldWordEx(des,false,false,LGameWordMask.SCENE_TYPE_PRIVATE_CHAT,func)



	--local notice,bool = LWordMaskUtil.ClearShieldWord(des,false,ccClientText(12544))
	--if(not bool)then
	--	self.mDesInput.text = notice
	--	return
	--end
	--gModelGuild:OnGuildMailNoticeReq(des)
end

function UIGdMilPop:OnInputDes(str)
	local length = LxUtf8.cnLen(str)
	local maxLen = gModelGuild:GetMailMaxNum()
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
	self:SetWndText(self.mLenText,length.."/"..maxLen)
end
------------------------------------------------------------------
return UIGdMilPop


