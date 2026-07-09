---
--- Created by Administrator.
--- DateTime: 2023/10/4 16:34:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdSeekPopEn:LWnd
local UIGdSeekPopEn = LxWndClass("UIGdSeekPopEn", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdSeekPopEn:UIGdSeekPopEn()
	self:SetHideHurdle()
	self._curSelFilterRefId = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdSeekPopEn:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdSeekPopEn:OnCreate()
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	LWnd.OnCreate(self)
	self._showToggle = 0
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdSeekPopEn:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	--self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function () self:WndClose() end)

	self:DisableInputText(self.mSeekInput)
end

function UIGdSeekPopEn:OnClickOnKey()--一键加入
	if(not gModelGuild:GetAddGuildByTime())then
		return
	end
	gModelGuild:OnJoinGuildReq(2)
end

function UIGdSeekPopEn:OnClickSortBtn()
	local list = self._filterTypeRefList
	if #list < 1 then return end

	self._isOpenSort = not self._isOpenSort
	self:SetSelSortListState(self._isOpenSort)
	if self._isOpenSort then
		self:RefreshSelSortList()
	end
end

function UIGdSeekPopEn:OnClickApplyFor(itemdata)
	if(not gModelGuild:GetAddGuildByTime())then
		return
	end
	gModelGuild:OnJoinGuildReq(1,itemdata.guildId)
end

function UIGdSeekPopEn:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIGdSeekPopEn:RefreshSelSortListBtn()
	local curSelFilterRefId = self._curSelFilterRefId

	local cfg
	for k,v in ipairs(self._filterTypeRefList) do
		if v.refId == curSelFilterRefId then
			cfg = v
			break
		end
	end

	if not cfg then
		printInfoNR("cfg is not find, curSelFilterRefId = "..curSelFilterRefId)
		return
	end

	local nameStr = cfg.name
	local nameIcon = cfg.icon
	local isShowIcon = LxUiHelper.IsImgPathValid(nameIcon)
	if isShowIcon then
		self:SetWndEasyImage(self.mShowSortNameIcon, nameIcon, nil, true)
	else
		self:SetWndText(self.mShowSortName, nameStr)
	end

	CS.ShowObject(self.mShowSortName, not isShowIcon)
	CS.ShowObject(self.mShowSortNameIcon,  isShowIcon)
end

function UIGdSeekPopEn:SetSelSortListState(isOpen)
	CS.ShowObject(self.mSortMaskBg,isOpen)
	CS.ShowObject(self.mSelSortList,isOpen)

	self._isOpenSort = isOpen
	self.mShowSortBtn.localRotation = isOpen and self._sortBtnRot.open or self._sortBtnRot.close
end

function UIGdSeekPopEn:OnDrawSelTypeCell(list,item,itemdata,itempos)
	local SelImgTrans = self:FindWndTrans(item,"SelImg")
	local NameTrans = self:FindWndTrans(item,"Name")
	local iconTrans = self:FindWndTrans(item, "Icon")
	local SelNameTrans = self:FindWndTrans(item,"SelName")

	local refId = itemdata.refId
	local name =  itemdata.name
	local icon = itemdata.icon

	local isShowIcon = LxUiHelper.IsImgPathValid(icon)
	local show = refId == self._curSelFilterRefId
	CS.ShowObject(SelImgTrans,show)

	if isShowIcon then
		local imgColor = show and self._textImgColors.sel or self._textImgColors.common
		self:SetWndEasyImage(iconTrans, icon, function()
			self:SetWndImageColor(iconTrans, imgColor)
		end, true)
	else
		self:SetWndText(NameTrans,name)
		self:SetWndText(SelNameTrans,name)
	end

	CS.ShowObject(NameTrans,not isShowIcon and not show)
	CS.ShowObject(SelNameTrans,not isShowIcon and show)
	CS.ShowObject(iconTrans, isShowIcon)

	self:SetWndClick(item,function()
		self:OnClickSel(refId)
	end)
end

function UIGdSeekPopEn:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildListResp,function (pb)
		self._guildName = pb.guildName
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.CreateGuildResp,function (...)
		self:WndClose()
	end)
	self:WndNetMsgRecv(LProtoIds.JoinGuildResp,function (...)
		if(self._uiList)then
			local list=gModelGuild:GetReqGuildList(self._showToggle, self._curSelFilterRefId)
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

function UIGdSeekPopEn:OnClickSel(filterRefId)
	self._curSelFilterRefId = filterRefId
	self._isOpenSort = false
	gModelGuild:SetSeekSelectLanguageType(filterRefId)
	self:SetSelSortListState(false)
	self:RefreshSelSortListBtn()
	self:RefreshData()
end

function UIGdSeekPopEn:RefreshFiltrate()
	local filterTypeRefList = gModelGuild:GetLanguageFiltrateList()
	self._filterTypeRefList = filterTypeRefList
	if not self._curSelFilterRefId and not table.isempty(filterTypeRefList) then
		self._curSelFilterRefId = filterTypeRefList[1].refId
	end

	self:RefreshSelSortListBtn()
	self._isOpenSort = false
	self:SetSelSortListState(false)
end

function UIGdSeekPopEn:ListItem( list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local nameText = self:FindWndTrans(root,"NameText")
	local flagBg = self:FindWndTrans(root,"FlagBg")
	local flagIcon = self:FindWndTrans(root,"FlagBg/FlagIcon")
	local lvText = self:FindWndTrans(root,"FlagBg/LvBg/LvText")
	local numText= self:FindWndTrans(root,"NumText")
	local languageText = self:FindWndTrans(root, "LanguageText")
	local languageImg = self:FindWndTrans(root, "LanguageImg")
	local applyForBtn1 = self:FindWndTrans(root,"ApplyForBtn1")
	local applyForBtn2 = self:FindWndTrans(root,"ApplyForBtn2")
	local applyForLvText= self:FindWndTrans(root,"ApplyForLvText")
	local Image= self:FindWndTrans(root,"Image")

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
	self:SetWndText(lvText,string.replace(ccClientText(12464),itemdata.level))
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

	CS.ShowObject(applyForBtn1,_isNowLevelLimit)
	CS.ShowObject(applyForBtn2,not _isNowLevelLimit)
	local applyBtn = _isNowLevelLimit and applyForBtn1 or applyForBtn2
	self:SetWndButtonText(applyBtn,_btnStr)
	local isGray = _islevelLimit and _isApply and not _isLimitNum
	self:SetWndButtonGray(applyBtn,isGray)
	self:SetWndClick(applyBtn, function(...)
		if _btnFunc then _btnFunc() end
	end)
	CS.ShowObject(applyForLvText,not _isNowLevelLimit or _levelLimit ~= 1)
	self:SetWndText(applyForLvText,_lvStr)
	self:SetWndClick(Image, function(...) self:OnClickGuildInfo(itemdata) end)

	-- 【D多语言】删除多语言联盟机制（客户端&服务端）
	-- local languageRefId = itemdata.languageRefId
	-- local languageName, languageIcon = gModelGuild:GetLanguageGuildRefNameByRefId(languageRefId)

	-- local isShowLanguageIcon = LxUiHelper.IsImgPathValid(languageIcon)
	-- if isShowLanguageIcon then
	-- 	self:SetWndEasyImage(languageImg, languageIcon, nil, true)
	-- else
	-- 	self:SetWndText(languageText, languageName)
	-- end
	-- CS.ShowObject(languageImg,  isShowLanguageIcon)
	-- CS.ShowObject(languageText, not isShowLanguageIcon)

end

function UIGdSeekPopEn:RefreshData()
	local list = gModelGuild:GetReqGuildList(self._showToggle, self._curSelFilterRefId)
	local bool= #list <= 0
	CS.ShowObject(self.mNoRecord,bool)
	if(bool)then
		if(self._guildName and self._guildName =="")then
			self:CreateEmptyShow(4004)
		else
			self:CreateEmptyShow(4005)
		end
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

function UIGdSeekPopEn:ToggLeRefresh()

end

function UIGdSeekPopEn:OnClickFound()--点击创建公会
	GF.OpenWnd("UIGdFoundPop")
end

function UIGdSeekPopEn:InitCommand()
	self.mSeekInput.characterLimit=gModelGuild:GetGuildNameMaxNum()
	local inputText = self:FindWndTrans(self.mSeekInput_1,"Text Area/Placeholder")
	self:SetWndText(inputText,ccClientText(12419))
	self:SetWndText(self.mLblBiaoti,ccClientText(12459))
	self:SetWndText(self.mInfoText,ccClientText(12460))
	self:SetWndText(self.mLvText,ccClientText(12461))
	self:SetWndText(self.mNumText,ccClientText(12568))
	self:SetWndText(self.mOperText,ccClientText(12463))
	self:SetWndText(self.mLanguageText, ccClientText(12607))
	self:SetWndButtonText(self.mSeekBtn,ccClientText(12470))
	self:SetWndButtonText(self.mFoundBtn,ccClientText(12414))
	self:CreateWndEffect(self.mFoundEff,"fx_zhandou_anniu","fx_zhandou_anniu",100)
	self:SetWndButtonText(self.mOnKeyBtn,ccClientText(12468))
	self:SetWndText(self.mEmptyText,ccClientText(12557))
	local text = self:FindWndTrans(self.mShowToggle,"XUIText")
	self:SetWndText(text,ccClientText(12588))

	self._isOpenSort = false
	self._sortBtnRot = {
		open = Quaternion.Euler(0,0,0),
		close = Quaternion.Euler(0,0,180),
	}

	self._textImgColors = {
		common = Color.New(254/255,235/255,167/255,1),
		sel = Color.New(1,1,1,1),
	}

	--当前语言类型refId
	self._curSelFilterRefId = gModelGuild:GetSeekSelectLanguageType()
	self._isForeign = gLGameLanguage:IsForeignVersion()

	local toggle = true
	local toggleNum = toggle and 0 or 1
	gModelGuild:OnGuildListReq(toggleNum)
	self:SetWndToggleValue(self.mShowToggle,toggle)
	self:RefreshFiltrate()
end

function UIGdSeekPopEn:RefreshSelSortList()
	local list = self._filterTypeRefList
	if #list < 1 then return end

	CS.ShowObject(self.mSortMaskBg,true)
	CS.ShowObject(self.mSelSortList,true)

	local uiSelSortList = self._uiSelSortList
	if uiSelSortList then
		uiSelSortList:RefreshList(list)
	else
		uiSelSortList = self:GetUIScroll("uiSelSortList")
		self._uiSelSortList = uiSelSortList
		uiSelSortList:Create(self.mSelSortList,list,function(...) self:OnDrawSelTypeCell(...) end)
	end
end

function UIGdSeekPopEn:OnClickSeek()
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
			self:SetWndTextInput(self.mSeekInput, newText)
			--self.mSeekInput.text = newText
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

function UIGdSeekPopEn:InitEvent()
	--self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:SetWndClick(self.mCloseBtn, function(...) self:WndClose() end)
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mSeekBtn, function(...) self:OnClickSeek() end)
	self:SetWndClick(self.mFoundBtn, function(...) self:OnClickFound() end)
	self:SetWndClick(self.mOnKeyBtn, function(...) self:OnClickOnKey() end)
	self:SetWndClick(self.mShowListBtn, function() self:OnClickSortBtn() end)
	self:SetWndClick(self.mSortMaskBg, function() self:SetSelSortListState(false) end)
	--self:SetWndClick(self.mShowToggle, function(...)
	--	self:SetWndToggleValue(self.mShowToggle,not self._showToggle)
	--end)
end

function UIGdSeekPopEn:OnClickGuildInfo(itemdata)--点击查看公会信息
	gModelGuild:OnGuildMemberListReq(itemdata.guildId)
end

------------------------------------------------------------------
return UIGdSeekPopEn


