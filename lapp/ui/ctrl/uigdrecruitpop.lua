---
--- Created by BY.
--- DateTime: 2023/10/22 16:45:54
---
------------------------------------------------------------------
local LWnd = LWnd
local LxUtf8 = LXFW.LxUtf8
---@class UIGdRecruitPop:LWnd
local UIGdRecruitPop = LxWndClass("UIGdRecruitPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdRecruitPop:UIGdRecruitPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdRecruitPop:OnWndClose()
	self:OnClickWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdRecruitPop:OnCreate()
	LWnd.OnCreate(self)
	self._lvIndex=1
	self._approve=1
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdRecruitPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdRecruitPop:SendImpl(content)
	local list= gModelGuild:GetRecruitRequireLv()


	--local content,bool = LWordMaskUtil.ClearShieldWord(content,false,ccClientText(12499))
	--if(not bool)then
	--	self.mManifestoInput.text = content
	--	return
	--end
	local levelLimit = tonumber(list[self._lvIndex])
	local approve = self._approve
	local approveStr=""
	local list={
		ccClientText(12429),
		ccClientText(12489),
	}
	approveStr = list[ approve + 1]
	local guildInfo=gModelGuild:GetGuildInfo()
	local num=guildInfo.recruitCount
	local sendNum=gModelGuild:GetGuildConfigRefByKey("recruitMaxNum")
	if(num<gModelGuild:GetGuildConfigRefByKey("recruitFreeTimes"))then
		-- GF.OpenWnd("UIGdRecruitTips",{refId=100002,para2={approveStr,levelLimit},para={sendNum-num},func=function (...)
		-- 	gModelGuild:OnGuildInfoChangeReq(4 , content,levelLimit,approve,1)
		-- end })
		gModelGeneral:OpenUIOrdinTips({
			refId = 100002,
			para = {sendNum-num},
			func = function() gModelGuild:OnGuildRecruitReq() end
		})
		return
	end
	if(num<sendNum)then
		local item=gModelGuild:GetRecruitSpend()
		-- local itemRefId = item.refId
		local itemCount = item.count
		-- GF.OpenWnd("UIGdRecruitTips",{refId=100003,para2={approveStr,levelLimit},para={itemCount,sendNum-num},func=function (...)
		-- 	gModelGuild:OnGuildInfoChangeReq(4 , content,levelLimit,approve,1)
		-- end, consume = {itemCount, itemRefId} })
		gModelGeneral:OpenUIOrdinTips({
			refId = 100003,
			para = {itemCount, sendNum - num},
			func = function() gModelGuild:OnGuildRecruitReq() end
		})
		return
	end
	GF.ShowMessage(ccClientText(12492))
end

function UIGdRecruitPop:UpdateLv()
	local list= gModelGuild:GetRecruitRequireLv()
	CS.ShowObject(self.mLvBtn1,true)
	CS.ShowObject(self.mLvBtn2,true)
	if(self._lvIndex==1)then
		CS.ShowObject(self.mLvBtn1,false)
	elseif self._lvIndex==#list then
		CS.ShowObject(self.mLvBtn2,false)
	end
	local text=list[self._lvIndex]
	self:SetWndText(self.mLvText,text)
end

function UIGdRecruitPop:OnClickWndClose()
	local callFunc = self._callFunc
	if callFunc then
		callFunc()
	end
	self:WndClose()
end

function UIGdRecruitPop:OnClickSend()
	--local list= gModelGuild:GetRecruitRequireLv()
	--local content,levelLimit,approve
	local content = self.mManifestoInput.text
	if content == "" then
		GF.ShowMessage(ccClientText(12500))
		return
	end

	local func = function(isMatched,newText)
		if self:IsWndClosed() then
			return
		end

		if isMatched then
			--self.mManifestoInput.text = newText
			self:SetWndTextInput(self.mManifestoInput, newText)
			GF.ShowMessage(ccClientText(12511))
		else
			self:SendImpl(newText)
		end
	end

	LWordMaskUtil.ClearShieldWordEx(content,false,false,LGameWordMask.SCENE_TYPE_PUBLIC_DATA,func)




end

function UIGdRecruitPop:OnClickLv(index)
	if(index==1)then
		self._lvIndex = self._lvIndex - 1
	else
		self._lvIndex = self._lvIndex + 1
	end
	self:UpdateLv()
end

function UIGdRecruitPop:OnClickNotarize()
	local list= gModelGuild:GetRecruitRequireLv()
	local content,levelLimit,approve
	content=self.mManifestoInput.text
	levelLimit=tonumber(list[self._lvIndex])
	approve = self._approve
	local guildInfo=gModelGuild:GetGuildInfo()
	if(content == guildInfo.notice and levelLimit == guildInfo.levelLimit and approve == guildInfo.approve)then
		self:WndClose()
		return
	end
	content= LUtil.FilterEmoji(content,"?")
	local length = LxUtf8.cnLen(content)
	local lengLimit=gModelGuild:GetDeclarationNum()
	if(length>lengLimit)then
		GF.ShowMessage(string.replace(ccClientText(12510),lengLimit))
		return
	end

	local func = function(isMatched,newText)
		if self:IsWndClosed() then
			return
		end

		if isMatched then
			--self.mManifestoInput.text = newText
			self:SetWndTextInput(self.mManifestoInput, newText)
			GF.ShowMessage(ccClientText(12499))
		else
			gModelGuild:OnGuildInfoChangeReq(4,newText,levelLimit,approve)
		end
	end

	LWordMaskUtil.ClearShieldWordEx(content,false,false,LGameWordMask.SCENE_TYPE_PUBLIC_DATA,func)

	--local content,bool = LWordMaskUtil.ClearShieldWord(content,false,ccClientText(12499))
	--if(not bool)then
	--	self.mManifestoInput.text = content
	--	return
	--end
	--gModelGuild:OnGuildInfoChangeReq(4,content,levelLimit,approve)
end

function UIGdRecruitPop:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mLvBtn1, function(...) self:OnClickLv(1) end)
	self:SetWndClick(self.mLvBtn2, function(...) self:OnClickLv(2) end)
	self:SetWndClick(self.mCancelBtn, function(...) self:OnClickNotarize() end)
	self:SetWndClick(self.mSendBtn, function(...) self:OnClickSend() end)
	self:SetWndClick(self.mConditionBtn1, function(...) self:OnCondition(1) end)
	self:SetWndClick(self.mConditionBtn2, function(...) self:OnCondition(2) end)
end

function UIGdRecruitPop:InitCommand()
	self._callFunc = self:GetWndArg("callFunc")
	self.mManifestoInput.characterLimit = gModelGuild:GetDeclarationNum()
	self:DisableInputText(self.mManifestoInput)
	self:DisableSensitiveInputText(self.mManifestoInput,ModelPlayer.SENSITIVE_TYPE_4)
	self:SetWndButtonText(self.mCancelBtn,ccClientText(12565))
	self:SetWndButtonText(self.mSendBtn,ccClientText(12427))
	self:SetWndText(self.mTitleText,ccClientText(12562))
	self:SetWndText(self.mConditionTip,ccClientText(12562))
	self:SetWndText(self.mLvTip,ccClientText(12593))
	self:SetWndText(self.mManifestoTip,ccClientText(12418))
	self._ConditionList = {
		self.mConditionBtn1,
		self.mConditionBtn2,
	}
	local conditionText = CS.FindTrans(self.mConditionBtn1,"ConditionText")
	self:SetWndText(conditionText,ccClientText(12429))
	local conditionText2 = CS.FindTrans(self.mConditionBtn2,"ConditionText")
	self:SetWndText(conditionText2,ccClientText(12489))

	local guildInfo=gModelGuild:GetGuildInfo()
	local list= gModelGuild:GetRecruitRequireLv()
	for i = 1, #list do
		if(list[i] == guildInfo.levelLimit)then
			self._lvIndex = i
		end
	end
	local approve = guildInfo.approve == 0 and 1 or 2
	self:OnCondition(approve)
	self:UpdateLv()
	if(guildInfo.notice ~= "")then
		--self.mManifestoInput.text=guildInfo.notice
		self:SetWndTextInput(self.mManifestoInput, guildInfo.notice)
	end
end

function UIGdRecruitPop:OnInputManifesto(str)
	local length = LxUtf8.cnLen(str)
	local maxLen = gModelGuild:GetDeclarationNum()
	if(length > maxLen)then
		str = self._oldStr
		--self.mManifestoInput.text = str
		self:SetWndTextInput(self.mManifestoInput, str)
		length = LxUtf8.cnLen(str)
		GF.ShowMessage(string.replace(ccClientText(12510),maxLen))
	else
		self._oldStr = str
	end
	--激活聊天框不选中所有内容
	self.mManifestoInput.onFocusSelectAll = false
	self:SetWndText(self.mManifestoLenText,length.."/"..maxLen)
end

function UIGdRecruitPop:OnCondition(index)
	for i, v in ipairs(self._ConditionList) do
		local bool = true
		if i ~= index then
			bool = false
		end
		self:ChangeCondition(v,bool)
	end
	self._approve = index == 1 and 0 or 1
end

function UIGdRecruitPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildInfoChangeResp,function (...)
		self:WndClose()
	end)
	self:WndNetMsgRecv(LProtoIds.GuildChangeResp,function (pb)
		if(pb.type==6 or pb.type==7)then
			GF.ShowMessage(ccClientText(12508))
			self:WndClose()
		end
	end)
	self.mManifestoInput.onValueChanged:AddListener(function (str)
		self:OnInputManifesto(str)
	end)
end

function UIGdRecruitPop:ChangeCondition(trans,bool)
	local onImage = CS.FindTrans(trans,"OnImage")
	CS.ShowObject(onImage,bool)
end
------------------------------------------------------------------
return UIGdRecruitPop


