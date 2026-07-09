---
--- Created by BY.
--- DateTime: 2023/10/22 14:29:50
---
------------------------------------------------------------------
local LWnd = LWnd
local LxUtf8 = LXFW.LxUtf8
---@class UIGdFoundPop:LWnd
local UIGdFoundPop = LxWndClass("UIGdFoundPop", LWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdFoundPop:UIGdFoundPop()
	self._curSelFilterRefId = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdFoundPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdFoundPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdFoundPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdFoundPop:OnInputManifesto(str)
	local length = LxUtf8.cnLen(str)

	local maxLen = gModelGuild:GetDeclarationNum()
	if(length > maxLen)then
		str = self._oldStr
		self:SetWndTextInput(self.mManifestoInput, str)
		--self.mManifestoInput.text = str
		length = LxUtf8.cnLen(str)
		GF.ShowMessage(string.replace(ccClientText(12510),maxLen))
	else
		self._oldStr = str
	end
	--激活聊天框不选中所有内容
	self.mManifestoInput.onFocusSelectAll = false
	self:SetWndText(self.mManifestoLenText,length.."/"..maxLen)
end


function UIGdFoundPop:CheckCreateGuild()
	if not self._isNameOk then
		return
	end

	if not self._isNoticeOk then
		return
	end

	local guildName = self._guildName
	local notice = self._guildNotice

	local vipLv=gModelPlayer:GetVipLevel()
	local vipLimit=gModelGuild:GetGuildConfigRefByKey("createGuildVip")
	local item=gModelGuild:GetGuildFoundConsume()
	local itemRefId = item.refId
	local itemCount = item.count
	local num=gModelItem:GetNumByRefId(itemRefId)

	if(num < itemCount)then
		local wndName = self:GetWndName()
		gModelGeneral:OpenGetWayWnd({itemId=itemRefId,srcWnd = wndName})
		return
	elseif(vipLv < vipLimit)then
		GF.ShowMessage(ccClientText(12558))
		return
	end

	-- 【D多语言】删除多语言联盟机制（客户端&服务端）
	-- local language = gModelGuild:GetLanguageGuildMarkByRefId(self._curSelFilterRefId)

	GF.OpenWnd("UIOrdinTip",{refId=100001,para={itemCount,guildName},func=function ()
		gModelGuild:OnCreateGuildReq(guildName , notice,self._showToggle,self._flagIconRefId,self._flagBgRefId)
	end, consume = {itemCount, itemRefId}})

end

function UIGdFoundPop:RefreshFlag(_selFlagBgId,_selFlagId)
	self._flagBgRefId = _selFlagBgId
	self._flagIconRefId = _selFlagId
	local bgRef = gModelGuild:GetGuildFlagRefByRefId(_selFlagBgId)
	local iconRef = gModelGuild:GetGuildFlagRefByRefId(_selFlagId)
	self:SetWndEasyImage(self.mFlagBg,bgRef.res)
	self:SetWndEasyImage(self.mFlagIcon,iconRef.res)
end

function UIGdFoundPop:OnClickSel(filterRefId)
	self._curSelFilterRefId = filterRefId
	self._isOpenSort = false
	gModelGuild:SetSeekSelectLanguageType(filterRefId)
	self:SetSelSortListState(false)
	self:RefreshSelSortListBtn()
end


function UIGdFoundPop:InitCommand()
	self._textImgColors = {
		common = Color.New(254/255,235/255,167/255,1),
		sel = Color.New(1,1,1,1),
	}

	self.mNameInput.characterLimit=gModelGuild:GetGuildNameMaxNum()
	self:DisableInputText(self.mNameInput)
	self:DisableSensitiveInputText(self.mNameInput,ModelPlayer.SENSITIVE_TYPE_4)
	self.mManifestoInput.characterLimit=gModelGuild:GetDeclarationNum()
	self:DisableInputText(self.mManifestoInput)
	self:DisableSensitiveInputText(self.mManifestoInput,ModelPlayer.SENSITIVE_TYPE_4)

	local name = nil
	local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_4)
	if not sensitive then
		name = self:GetRandomName()
	end
	CS.ShowObject(self.mNameRandom, not sensitive)
	
	self:SetWndText(self.mLblBiaoti,ccClientText(12414))
	self:SetWndText(self.mFlagText,ccClientText(12602))
	self:SetWndText(self.mNameTipText,ccClientText(12416))
	self:SetWndText(self.mManifestoTipText,ccClientText(12418))
	--local inputText = CS.FindTrans(self.mNameInput_1,"Text Area/Placeholder")
	--self:SetWndText(inputText,ccClientText(12419))
	self:SetWndTextInput(self.mNameInput, name, ccClientText(12419))
	
	local str = gModelGuild:GetRandomManifesto(1)
	self:SetWndTextInput(self.mManifestoInput, str)
	--self.mManifestoInput.text = str
	self:SetWndButtonText(self.mFoundBtn,ccClientText(12415))
	self:SetWndText(self.mToggleText,ccClientText(12570))
	local item = gModelGuild:GetGuildFoundConsume()
	self:SetWndText(self.mNumText,item.count)
	local numIconRef = gModelItem:GetRefByRefId(tonumber(item.refId))
	self:SetWndEasyImage(self.mNumImage,numIconRef.icon)
	self:SetWndText(self.mFoundDesText,string.replace(ccClientText(12421),gModelGuild:GetGuildConfigRefByKey("createGuildVip")))
	self:SetWndToggleValue(self.mShowToggle,true)

	local flagBgs = gModelGuild:GetGuildFlagRefByType(1)
	local flagIcons = gModelGuild:GetGuildFlagRefByType(2)

	local rand = math.random(1,#flagBgs)
	local bgRef = flagBgs[rand]
	self._flagBgRefId = bgRef.refId
	self:SetWndEasyImage(self.mFlagBg,bgRef.res)

	rand = math.random(1,#flagIcons)
	local iconRef = flagIcons[rand]
	self._flagIconRefId = iconRef.refId
	self:SetWndEasyImage(self.mFlagIcon,iconRef.res)

	local isForeign = gLGameLanguage:IsForeignRegion()
	local isUSAForeign = gLGameLanguage:IsUSARegion()
	self._isForeign = isForeign
	CS.ShowObject(self.mSortContent, false)
	if isUSAForeign then
		self._isOpenSort = false
		self._sortBtnRot = {
			open = Quaternion.Euler(0,0,0),
			close = Quaternion.Euler(0,0,180),
		}

		self:RefreshFiltrate()
	end
end

function UIGdFoundPop:GetRandomName()
	local index = math.random(1, #GameTable.RandomGuildNamebaseRef)
	local ref = GameTable.RandomGuildNamebaseRef[index]
	local flag = gLGameLanguage:GetLanguageFlag()
	return ref[flag]
end


function UIGdFoundPop:OnClickSortBtn()
	local list = self._filterTypeRefList
	if not list or #list < 1 then return end

	self._isOpenSort = not self._isOpenSort
	self:SetSelSortListState(self._isOpenSort)
	if self._isOpenSort then
		self:RefreshSelSortList()
	end
end


function UIGdFoundPop:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mFoundBtn, function(...) self:OnClickFound() end)
	self:SetWndClick(self.mBtnFlag, function(...) self:OnClickFlag() end)
	self:SetWndClick(self.mShowListBtn, function() self:OnClickSortBtn() end)
	self:SetWndClick(self.mSortMaskBg, function() self:SetSelSortListState(false) end)
	self:SetWndClick(self.mNameRandom, function() self:OnClickNameRandom() end)
end

function UIGdFoundPop:SetSelSortListState(isOpen)
	CS.ShowObject(self.mSortMaskBg,isOpen)
	CS.ShowObject(self.mSelSortList,isOpen)

	self.mShowSortBtn.localRotation = isOpen and self._sortBtnRot.open or self._sortBtnRot.close
end

function UIGdFoundPop:OnClickFound()
	--local vipLv=gModelPlayer:GetVipLevel()
	--local vipLimit=gModelGuild:GetGuildConfigRefByKey("createGuildVip")
	--local item=gModelGuild:GetGuildFoundConsume()
	--local num=gModelItem:GetNumByRefId(item.refId)
	local guildName=self.mNameInput.text
	local notice=self.mManifestoInput.text
	guildName= LUtil.FilterEmoji(guildName,"?")
	notice= LUtil.FilterEmoji(notice,"?")
	local length = LxUtf8.cnLen(guildName)
	local noticeLength = LxUtf8.cnLen(notice)
	if(guildName == "")then
		GF.ShowMessage(ccClientText(12547))
		return
	elseif(length>gModelGuild:GetGuildNameMaxNum() or length<gModelGuild:GetGuildConfigRefByKey("guildNameMinNum"))then
		GF.ShowMessage(ccClientText(12417))
		return
	elseif(string.find(guildName, " "))then
		if not self._isForeign then
			GF.ShowMessage(ccClientText(12497))
			return
		else
			local isSpaceEdge = string.startswith(guildName, " ")
			if not isSpaceEdge then
				isSpaceEdge = string.endswith(guildName, " ")
			end
			if isSpaceEdge then
				GF.ShowMessage(ccClientText(10424))
				return
			end
		end
	elseif(noticeLength>gModelGuild:GetDeclarationNum())then
		GF.ShowMessage(string.replace(ccClientText(12510),gModelGuild:GetDeclarationNum()))
		return
	elseif(noticeLength <= 0)then
		GF.ShowMessage(ccClientText(12500))
		return
	end

	self._isNameOk = false
	self._isNoticeOk = false

	local nameCheckFunc= function (isMatched,newText)
		if self:IsWndClosed() then
			return
		end

		if isMatched then
			--self.mNameInput.text = newText
			self:SetWndTextInput(self.mNameInput, newText)
			GF.ShowMessage(ccClientText(12496))
		else
			self._isNameOk =true
			self._guildName = newText

			self:CheckCreateGuild()
		end
	end

	LWordMaskUtil.ClearShieldWordEx(guildName,false,false,LGameWordMask.SCENE_TYPE_PUBLIC_DATA,nameCheckFunc)



	local noticeCheckFunc= function (isMatched,newText)
		if self:IsWndClosed() then
			return
		end

		if isMatched then
			--self.mManifestoInput.text = newText
			self:SetWndTextInput(self.mManifestoInput, newText)
			GF.ShowMessage(ccClientText(12499))
		else
			self._isNoticeOk =true
			self._guildNotice = newText
--print("39012931293193-1")
			self:CheckCreateGuild()
		end
	end

	LWordMaskUtil.ClearShieldWordEx(notice,false,false,LGameWordMask.SCENE_TYPE_PUBLIC_DATA,noticeCheckFunc)


	--local guildName,bool = LWordMaskUtil.ClearShieldWord(guildName,false,ccClientText(12496))
	--if(not bool)then
	--	self.mNameInput.text = guildName
	--	return
	--end
	--local notice,bool = LWordMaskUtil.ClearShieldWord(notice,false,ccClientText(12499))
	--if(not bool)then
	--	self.mManifestoInput.text = notice
	--	return
	--end

end

function UIGdFoundPop:RefreshSelSortList()
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

--#####################################################################################################################
--## Filter ###########################################################################################################
--#####################################################################################################################
function UIGdFoundPop:RefreshFiltrate()
	local filterTypeRefList = gModelGuild:GetLanguageFiltrateList()
	self._filterTypeRefList = filterTypeRefList
	if not self._curSelFilterRefId and not table.isempty(filterTypeRefList) then
		self._curSelFilterRefId = filterTypeRefList[1].refId
	end

	self:RefreshSelSortListBtn()
	self._isOpenSort = false
	self:SetSelSortListState(false)
end

function UIGdFoundPop:OnClickNameRandom()
	local name = self:GetRandomName()
	self:SetWndTextInput(self.mNameInput, name, ccClientText(12419))
end


function UIGdFoundPop:OnClickFlag()
	GF.OpenWnd("UIGdFlagPop",{confirmType = ModelGuild.GUILD_FLAG_TYPE_FOUND,flagId = self._flagIconRefId,flagBgId = self._flagBgRefId})
end

function UIGdFoundPop:OnDrawSelTypeCell(list,item,itemdata,itempos)
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


function UIGdFoundPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.CreateGuildResp,function (...)
		GF.OpenWnd("UIGdWin")
		self:WndClose()
	end)
	self:WndEventRecv(EventNames.ON_GUILD_FLAG_CHANGE,function(...)
		self:RefreshFlag(...)
	end)
	self.mManifestoInput.onValueChanged:AddListener(function (str)
		self:OnInputManifesto(str)
	end)
	self:SetWndToggleDelegate(self.mShowToggle,function (value)
		if(not value)then
			self._showToggle = 1
		else
			self._showToggle = 0
		end
	end)
end

function UIGdFoundPop:RefreshSelSortListBtn()
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

------------------------------------------------------------------
return UIGdFoundPop


