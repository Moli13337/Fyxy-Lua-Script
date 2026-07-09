---
--- Created by BY.
--- DateTime: 2023/10/23 11:13:32
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdSeekPop:LWnd
local UIGdSeekPop = LxWndClass("UIGdSeekPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdSeekPop:UIGdSeekPop()
	self:SetHideHurdle()
	self.selectGuild = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdSeekPop:OnWndClose()

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdSeekPop:OnCreate()
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	LWnd.OnCreate(self)
	self._showToggle = 0
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdSeekPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	--self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function () self:WndClose() end)

	self:DisableInputText(self.mSeekInput)
	self:DisableSensitiveInputText(self.mSeekInput,ModelPlayer.SENSITIVE_TYPE_6)
end

function UIGdSeekPop:SetTopGuildInfo(data)
	if not data or self.selectGuild == data.guildId then
		return
	end
	self.selectGuild = data.guildId

	local flagBg = self:FindWndTrans(self.mGuildInfo, "FlagBg")
	local flagIcon = self:FindWndTrans(self.mGuildInfo,"FlagBg/FlagIcon")
	local nameText = self:FindWndTrans(self.mGuildInfo, "NameText")
	local leaderText = self:FindWndTrans(self.mGuildInfo, "LeaderText")
	local numText = self:FindWndTrans(self.mGuildInfo, "NumText")
	local powerText = self:FindWndTrans(self.mGuildInfo, "PowerText")
	local lookDes = self:FindWndTrans(self.mGuildInfo, "LookDes")
	local lookDesText = self:FindWndTrans(self.mGuildInfo, "LookDes/Text")
	local desText = self:FindWndTrans(self.mGuildInfo, "DesText")

	local ref = gModelGuild:GetGuildFlagRefByRefId(data.flagBgId)
	if ref then
		self:SetWndEasyImage(flagBg, ref.res)
	end
	ref = gModelGuild:GetGuildFlagRefByRefId(data.flagId)
	if ref then
		self:SetWndEasyImage(flagIcon, ref.res)
	end
	self:SetWndText(desText, data.notice)
	self:SetWndText(nameText, ccClientText(13435) .. "：" .. data.guildName)
	self:SetWndText(leaderText, ccClientText(12624) .. data.chairman:GetName())
	local limitNum=  gModelGuild:GetGuildNumByLv(data.level)
	local count = data.count
	local color = limitNum <= count and "red" or "green"
	local numStr = data.count .. "/" .. limitNum
	self:SetWndText(numText, ccClientText(12568) .. "：" .. LUtil.FormatColorStr(numStr, color))
	self:SetWndText(powerText, ccClientText(12623) .. "：" .. LUtil.FormatColorStr(LUtil.NumberCoversion(data.chairman._power), "#d2730f"))
	self:SetWndText(lookDesText, ccClientText(12402))

	self:SetWndClick(lookDes, function()
		self:OnClickGuildInfo(data)
	end)

	if self._uiList then
		self._uiList:DrawAllItems()
	end
end

function UIGdSeekPop:ToggLeRefresh()

end

function UIGdSeekPop:OnClickFound()--点击创建公会
	GF.OpenWnd("UIGdFoundPop")
end

function UIGdSeekPop:OnClickSeek()
	local name=self.mSeekInput.text
	name= LUtil.FilterEmoji(name,"?")
	if(name=="")then
		GF.ShowMessage(ccClientText(12495))
		gModelGuild:OnGuildListReq()
		return
	end

	local toggleNum = self._showToggle == 1 and 0 or 1

	local func = function(isMatched,newText)

		if self:IsWndClosed() then
			return
		end

		if isMatched then
			GF.ShowMessage(ccClientText(12496))
			--self.mSeekInput.text = newText
			self:SetWndTextInput(self.mSeekInput, newText)
		else
			gModelGuild:OnGuildListReq(toggleNum,name)
		end
	end

	LWordMaskUtil.ClearShieldWordEx(name,false,false,LGameWordMask.SCENE_TYPE_PRIVATE_CHAT,func)


	--local notice,bool = LWordMaskUtil.ClearShieldWord(name,false,ccClientText(12496))
	--if(not bool)then
	--	self.mSeekInput.text = notice
	--	return
	--end
	--
	--gModelGuild:OnGuildListReq(toggleNum,name)
end

function UIGdSeekPop:RefreshData()
	local list = gModelGuild:GetReqGuildList(self._showToggle)
	local bool= #list <= 0
	CS.ShowObject(self.mNoRecord,bool)
	if(bool)then
		if(self._guildName and self._guildName =="")then
			self:CreateEmptyShow(4004)
		else
			self:CreateEmptyShow(4005)
		end
	end
	if #list > 0 then
		self:SetTopGuildInfo(list[1])
	end
	if(self._uiList)then
		self._uiList:RefreshList(list)
		local uilist = self._uiList:GetList()
		uilist:RefreshSimpleList()
		return
	end
	self._uiList = self:GetUIScroll("cell")
	self._uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end,UIItemList.WRAP)
end

function UIGdSeekPop:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIGdSeekPop:OnClickApplyFor(itemdata)
	if(not gModelGuild:GetAddGuildByTime())then
		return
	end
	gModelGuild:OnJoinGuildReq(1,itemdata.guildId)
end

function UIGdSeekPop:InitEvent()
	--self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:SetWndClick(self.mCloseBtn, function(...) self:WndClose() end)
	self:SetWndClick(self.mSeekBtn, function(...) self:OnClickSeek() end)
	self:SetWndClick(self.mFoundBtn, function(...) self:OnClickFound() end)
	self:SetWndClick(self.mOnKeyBtn, function(...) self:OnClickOnKey() end)
	--self:SetWndClick(self.mShowToggle, function(...)
	--	self:SetWndToggleValue(self.mShowToggle,not self._showToggle)
	--end)
end

function UIGdSeekPop:OnClickOnKey()--一键加入
	if(not gModelGuild:GetAddGuildByTime())then
		return
	end
	gModelGuild:OnJoinGuildReq(2)
end

function UIGdSeekPop:ListItem( list,item, itemdata, itempos)
	local root = CS.FindTrans(item,"Root")
	local nameText = CS.FindTrans(root,"NameText")
	local leaderName = CS.FindTrans(root,"LeaderName")
	local flagBg = CS.FindTrans(root,"FlagBg")
	local flagIcon = CS.FindTrans(root,"FlagBg/FlagIcon")
	local lvText = CS.FindTrans(root, "LvlText")
	local numText= CS.FindTrans(root,"NumText")
	local applyForBtn1 = CS.FindTrans(root,"ApplyForBtn1")
	local applyForBtn2 = CS.FindTrans(root,"ApplyForBtn2")
	local applyForLvText= CS.FindTrans(root,"ApplyForLvText")
	local Image= CS.FindTrans(root,"Image")
	local sel = CS.FindTrans(root, "Sel")
	local powerText = CS.FindTrans(root, "PowerText")

	CS.ShowObject(sel, self.selectGuild == itemdata.guildId)

	local ref = gModelGuild:GetGuildFlagRefByRefId(itemdata.flagBgId)
	if ref then
		self:SetWndEasyImage(flagBg,ref.res)
	end
	ref = gModelGuild:GetGuildFlagRefByRefId(itemdata.flagId)
	if ref then
		self:SetWndEasyImage(flagIcon,ref.res)
	end

	local _color,_btnStr,_lvStr,_btnFunc
	local _limitNum=  gModelGuild:GetGuildNumByLv(itemdata.level)
	local _count = itemdata.count
	local _isLimitNum = _limitNum <= _count
	local _levelLimit = itemdata.levelLimit
	local _isNowLevelLimit = itemdata.approve == 0 --_levelLimit > 1
	local _selfLv = gModelPlayer:GetPlayerLv()
	local _islevelLimit = _selfLv < _levelLimit
	local _isApply = gModelGuild:GetBApplyByGuildId(itemdata.guildId)
	_btnFunc = function() self:OnClickApplyFor(itemdata)  end
	if(_isLimitNum)then
		_color = "red"
		_btnFunc = function() GF.ShowMessage(ccClientText(12505)) end
	else
		_color = "green"
	end
	self:SetWndText(nameText,itemdata.guildName)
	self:SetWndText(lvText,string.replace(ccClientText(10011),itemdata.level))
	self:SetWndText(powerText, LUtil.NumberCoversion(itemdata.power))
	local numStr = itemdata.count.."/".._limitNum
	self:SetWndText(numText,LUtil.FormatColorStr(numStr,_color))

	if _isNowLevelLimit then
		_btnStr = ccClientText(12569)
		if(_islevelLimit)then
			_color = "red"
			_btnFunc = function() GF.ShowMessage(ccClientText(12503)) end
		else
			_color = "green"
		end
		_lvStr = LUtil.FormatColorStr(string.replace(ccClientText(14134),_levelLimit),_color)
	else
		if(_islevelLimit)then
			_color = "red"
			_btnFunc = function() GF.ShowMessage(ccClientText(12503)) end
		else
			_color = "green"
		end
		_btnStr = ccClientText(12466)
		_lvStr = LUtil.FormatColorStr(string.replace(ccClientText(14134),_levelLimit),_color)
	end

	if not _isApply then
		_btnStr = ccClientText(12465)
		_btnFunc = function() GF.ShowMessage(ccClientText(12504)) end
	end
	self:SetWndButtonText(applyForBtn1,_btnStr)
	self:SetWndButtonText(applyForBtn2,_btnStr)
	CS.ShowObject(applyForBtn1,_isNowLevelLimit)
	CS.ShowObject(applyForBtn2,not _isNowLevelLimit)
	local isGray = _islevelLimit and _isApply and not _isLimitNum
	self:SetWndButtonGray(applyForBtn1,isGray)
	self:SetWndButtonGray(applyForBtn2,isGray)
	self:SetWndClick(applyForBtn1, function(...)
		if _btnFunc then _btnFunc() end
	end)
	self:SetWndClick(applyForBtn2, function(...)
		if _btnFunc then _btnFunc() end
	end)
	CS.ShowObject(applyForLvText,not _isNowLevelLimit or _levelLimit ~= 1)
	self:SetWndText(applyForLvText,_lvStr)
	self:SetWndText(leaderName, ccClientText(12624) .. itemdata.chairman:GetName())
	-- self:SetWndClick(Image, function(...) self:OnClickGuildInfo(itemdata) end)
	self:SetWndClick(item, function()
		self:SetTopGuildInfo(itemdata)
	end)
end

function UIGdSeekPop:InitCommand()
	self.mSeekInput.characterLimit=gModelGuild:GetGuildNameMaxNum()
	--local inputText = CS.FindTrans(self.mSeekInput_1,"Text Area/Placeholder")
	--self:SetWndText(inputText,ccClientText(12419))
	self:SetWndText(self:FindWndTrans(self.mCloseBtn, "TxtClose"), ccClientText(30205))
	self:SetWndText(self:FindWndTrans(self.mGuildInfo, "Title"), ccClientText(13435))
    self:SetWndTextInput(self.mSeekInput, nil, ccClientText(12419))
	self:SetWndText(self.mInfoText,ccClientText(12460))
	self:SetWndText(self.mNumText,ccClientText(12568))
	self:SetWndText(self.mOperText,ccClientText(12463))
	self:SetWndButtonText(self.mSeekBtn,ccClientText(12470))
	self:SetWndButtonText(self.mFoundBtn,ccClientText(12414))
	self:CreateWndEffect(self.mFoundEff,"fx_anniu_01","fx_anniu_01",100)
	self:SetWndButtonText(self.mOnKeyBtn,ccClientText(12468))
	self:SetWndText(self.mEmptyText,ccClientText(12557))
	self:SetWndText(self.mPowerText, ccClientText(12623))
	local text = CS.FindTrans(self.mShowToggle,"XUIText")
	self:SetWndText(text,ccClientText(12588))
	local toggle = true
	local toggleNum = toggle and 0 or 1
	gModelGuild:OnGuildListReq(toggleNum)
	self:SetWndToggleValue(self.mShowToggle,toggle)
end

function UIGdSeekPop:OnClickGuildInfo(itemdata)--点击查看公会信息
	gModelGuild:OnGuildMemberListReq(itemdata.guildId)
end

function UIGdSeekPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildListResp,function (pb)
		self._guildName = pb.guildName
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.CreateGuildResp,function (...)
		self:WndClose()
	end)
	self:WndNetMsgRecv(LProtoIds.JoinGuildResp,function (...)
		if(self._uiList)then
			local list=gModelGuild:GetReqGuildList(self._showToggle)
			self._uiList:RefreshData(list)
		end
	end)
	self:SetWndToggleDelegate(self.mShowToggle,function (value)
		if(value)then
			self._showToggle = 1
		else
			self._showToggle = 0
		end
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.GuildInfoResp,function (pb)
		GF.OpenWnd("UIGdWin")
		self:WndClose()
	end)
end
------------------------------------------------------------------
return UIGdSeekPop


