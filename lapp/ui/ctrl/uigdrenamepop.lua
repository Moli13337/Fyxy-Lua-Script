---
--- Created by BY.
--- DateTime: 2023/10/23 16:09:28
---
------------------------------------------------------------------
local LWnd = LWnd
local LxUtf8 = LXFW.LxUtf8
---@class UIGdReNamePop:LWnd
local UIGdReNamePop = LxWndClass("UIGdReNamePop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdReNamePop:UIGdReNamePop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdReNamePop:OnWndClose()
	self:OnClickWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdReNamePop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdReNamePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdReNamePop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildInfoChangeResp,function (...)
		--self:RefreshData()
		self:WndClose()
	end)
end


function UIGdReNamePop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mCloseBtn, function(...) self:WndClose() end)
	self:SetWndClick(self.mOutBtn, function(...) self:OnClickSend() end)
end

function UIGdReNamePop:InitCommand()
	self._callFunc = self:GetWndArg("callFunc")
	self.mNameInput.characterLimit=gModelGuild:GetGuildNameMaxNum()
	self:DisableInputText(self.mNameInput)
	self:DisableSensitiveInputText(self.mNameInput,ModelPlayer.SENSITIVE_TYPE_4)
	local guildInfo=gModelGuild:GetGuildInfo()
	--local text = CS.FindTrans(self.mNameInput_1,"Text Area/Placeholder")
	--self:SetWndText(text,ccClientText(12417))
	self:SetWndTextInput(self.mNameInput, nil, ccClientText(12417))
	self:SetWndText(self.mTitleText,ccClientText(12584))
	self:SetWndText(self.mCurrText,string.replace(ccClientText(12485),guildInfo.guildName))
	self:SetWndButtonText(self.mOutBtn,ccClientText(12484))
	self:SetWndButtonText(self.mCloseBtn,ccClientText(10101))
	self:RefreshData()
end

function UIGdReNamePop:OnClickSend()
	local item = gModelGuild:GetChangeNameSpend()
	local num = gModelItem:GetNumByRefId(item.refId)
	if(num < item.count)then
		GF.ShowMessage(ccClientText(10754))
		return
	end
	local name=self.mNameInput.text
	name= LUtil.FilterEmoji(name,"?")
	local length = LxUtf8.cnLen(name)

	if not gLGameLanguage:IsForeignRegion() then
		local bool = string.find(name, " ")
		if bool then
			GF.ShowMessage(ccClientText(12497))
			return
		end
	else
		local isSpaceEdge = string.startswith(name, " ")
		if not isSpaceEdge then
			isSpaceEdge = string.endswith(name, " ")
		end
		if isSpaceEdge then
			GF.ShowMessage(ccClientText(10424))
			return
		end
	end

	if(name=="")then
		GF.ShowMessage(ccClientText(12547))
		return
	elseif(length>gModelGuild:GetGuildNameMaxNum() or length<gModelGuild:GetGuildConfigRefByKey("guildNameMinNum"))then
		GF.ShowMessage(ccClientText(12417))
		return
	elseif(num<item.count)then
		GF.ShowMessage(ccClientText(12496))
		return
	end

	local func = function(isMatched,newText)
		if self:IsWndClosed() then
			return
		end

		if isMatched then
			--self.mNameInput.text = newText
			self:SetWndTextInput(self.mNameInput, newText)
			GF.ShowMessage(ccClientText(12496))
		else
			gModelGuild:OnGuildInfoChangeReq(1,newText)
		end
	end

	LWordMaskUtil.ClearShieldWordEx(name,false,false,LGameWordMask.SCENE_TYPE_PUBLIC_DATA,func)


	--local name,bool = LWordMaskUtil.ClearShieldWord(name,false,ccClientText(12496))
	--if(not bool)then
	--	self.mNameInput.text = name
	--	return
	--end
	--gModelGuild:OnGuildInfoChangeReq(1 , name)
end

function UIGdReNamePop:OnClickWndClose()
	local callFunc = self._callFunc
	if callFunc then
		callFunc()
	end
	self:WndClose()
end

function UIGdReNamePop:RefreshData()
	local item=gModelGuild:GetChangeNameSpend()
	local num = gModelItem:GetNumByRefId(item.refId)
	local numStr = LUtil.NumberCoversion(num)
	local itemCount = item.count
	local color = ""
	if num >= item.count then
		color = "green"
	else
		color = "red"
	end
	self:SetWndText(self.mNumText,LUtil.FormatColorStrs(numStr,itemCount,color))

	local iconTrans = self:FindWndTrans(self.mNumText,"Icon")
	local iconRef = gModelItem:GetRefByRefId(tonumber(item.refId))
	self:SetWndEasyImage(iconTrans,iconRef.icon)
end
------------------------------------------------------------------
return UIGdReNamePop


