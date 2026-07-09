---
--- Created by BY.
--- DateTime: 2022/7/8 11:33:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKCardEquip:LWnd
local UIKCardEquip = LxWndClass("UIKCardEquip", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKCardEquip:UIKCardEquip()
	self._raceList = {}
	self._heroIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKCardEquip:OnWndClose()
	self:ClearCommonIconList(self._heroIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKCardEquip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKCardEquip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIKCardEquip:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(29526))
	self:SetWndButtonText(self.mBtnBook,ccClientText(29505))
	self:SetWndButtonText(self.mBtnDemount,ccClientText(29535))

	local heroId = self:GetWndArg("heroId")
	self._heroId = heroId

	local list = gModelSorceryCard:GetSorceryCardThemeRef()
	local uiList = self:GetUIScroll("mRaceScroll_UIKCardEquip")
	uiList:Create(self.mRaceScroll,list,function(...) self:RaceListItem(...) end)
	uiList:EnableScroll(#list >5,true)
	self:OnClickRace(list[1].refId)
end

function UIKCardEquip:InitEvent()
	self:SetWndClick(self.mBg,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnBook,function ()self:OnClickBook() end)
	self:SetWndClick(self.mBtnDemount,function ()self:OnClickDemount() end)
end
function UIKCardEquip:SetMappingCardShowSet(item)
	local root = self:FindWndTrans(item,"Root")
	local cardMask = self:FindWndTrans(item,"CardMask")
	local txt = self:FindWndTrans(cardMask,"Txt")
	local txtStr = self._showMapping and 38428 or 38429
	self:SetWndText(txt,ccClientText(txtStr))
	CS.ShowObject(root,false)
	CS.ShowObject(cardMask,true)
	CS.ShowObject(self.mBtnDemount,false)
end

function UIKCardEquip:RefreshData()
	local cardList = gModelSorceryCard:GetCardList()
	local heroKeys = gModelSorceryCard:GetHeroKeys()
	if not cardList or not heroKeys then
		gModelSorceryCard:OnSorceryCardOpenReq()
		return
	end
	self._cardList = cardList
	local _heroId = self._heroId
	--local serverData = gModelHero:GetHeroServerDataById(_heroId)
	--if not serverData then return end
	local curScRefId = heroKeys[_heroId] or 0
	if(self._showMapping)then
		local sorcesryCard = gModelHero:GetSorceryCardInfo()
		curScRefId = sorcesryCard and sorcesryCard.scRefId or curScRefId
	end
	self._curScRefId = curScRefId
	local _race = self._race
	local sorceryCardRefs = gModelSorceryCard:GetSorceryCardRefByTheme(_race)
	local list = {}
	if(not self._showMapping)then
		for i, v in ipairs(sorceryCardRefs) do
			if v.refId ~= curScRefId and cardList[v.refId] then
				if gModelSorceryCard:VerifyLimitByCardIdAndHeroId(v.refId,_heroId) then
					table.insert(list,v)
				end
			end
		end
	end
	local len = #list
	if len > 1 then
		table.sort(list,function (a,b)
			local aquality = a.quality
			local bquality = b.quality
			if aquality ~= bquality then
				return aquality > bquality
			end
			return a.refId < b.refId
		end)
	end
	local type = 2
	local mappingData = gModelResonance:CheckHeroInTargetMappingDict(_heroId)
	local sourceHeroId = mappingData and mappingData.sourceHeroId or nil
	local showMapping = sourceHeroId and sourceHeroId~="0" and sourceHeroId~=0
	if curScRefId > 0 then
		type = 1
		local itemdata = gModelSorceryCard:GetSorceryCardRefByRefId(curScRefId)
		self:CardShowSet(self.mCurRoot,itemdata)
	elseif(showMapping)then
		self:SetMappingCardShowSet(self.mCurRoot)
	end
	CS.ShowObject(self.mBtnDemount, not self._showMapping)
	type = showMapping and 1 or type

	CS.ShowObject(self.mNoRecord3,len <= 0)
	if len <= 0 then
		self:CreateEmptyShow(10006)
	end
	CS.ShowObject(self.mView1,type == 1)
	CS.ShowObject(self.mView2,type == 2)
	local uiList = self._uiList
	if uiList then
		uiList:RefreshList(list)
		uiList:DrawAllItems()
	else
		local mCellSuper = type == 1 and self.mCellSuper1 or self.mCellSuper2
		uiList = self:GetUIScroll("mCellSuper_UIKCardEquip")
		self._uiList = uiList
		uiList:Create(mCellSuper,list,function(...) self:ListItem(...) end,UIItemList.SUPER)
	end
	self:SetMappingGroup()
end
function UIKCardEquip:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local heroRoot = self:FindWndTrans(root,"HeroRoot")
	local heroIcon = self:FindWndTrans(root,"HeroRoot/HeroIcon")
	local useText = self:FindWndTrans(root,"UseText")
	local btnWear = self:FindWndTrans(root,"BtnMag/BtnWear")
	local btnReplace = self:FindWndTrans(root,"BtnMag/BtnReplace")

	local InstanceID = item:GetInstanceID()
	local _cardList = self._cardList or {}
	local _card = _cardList[itemdata.refId]
	local heroId = _card and _card.heroId
	local isHero = heroId and heroId ~= "0"
	local heroKeys = gModelSorceryCard:GetHeroKeys()
	local _heroId = self._heroId
	local curScRefId = heroKeys[_heroId] or 0
	local isWear = curScRefId > 0

	self:CardShowSet(item,itemdata)
	self:SetWndButtonText(btnWear,ccClientText(29527))
	self:SetWndButtonText(btnReplace,ccClientText(29528))
	CS.ShowObject(btnWear,not isHero and not isWear)
	CS.ShowObject(btnReplace,isHero or isWear)
	CS.ShowObject(heroRoot,isHero)
	CS.ShowObject(useText,isHero)
	if isHero then
		local baseClass = self._heroIconList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New(self)
			self._heroIconList[InstanceID] = baseClass
			baseClass:Create(heroIcon)
		end
		baseClass:SetHeroPlayer(heroId)
		baseClass:DoApply()
		self:SetWndText(useText,ccClientText(29529))
	end

	self:SetWndClick(btnWear,function ()
		self:OnClickWear(itemdata.refId)
	end)
	self:SetWndClick(btnReplace,function ()
		self:OnClickReplace(itemdata.refId,heroId)
	end)
end
function UIKCardEquip:OnClickWear(refId)
	local heroId = self._heroId
	local isWear = gModelSorceryCard:VerifyLimitByCardIdAndHeroId(refId,heroId)
	if not isWear then
		GF.ShowMessage(ccClientText(29537))
		return
	end
	local isTargetMapping = gModelResonance:CheckHeroInTargetMappingDict(heroId)
	local otherMapping = gModelResonance:GetMappingOtherId(heroId)
	local isMapping = not isTargetMapping and otherMapping
	local otherCanWear = otherMapping and ModelSorceryCard:CheckHeroCanWearByRefId(otherMapping,refId) or nil
	if(isMapping and not otherCanWear)then
		local para = {
			refId = 10048,
			func = function()
				gModelSorceryCard:OnSorceryCardWearReq(refId,heroId)
			end,
		}
		gModelGeneral:OpenUIOrdinTips(para)
		return
	end
	gModelSorceryCard:OnSorceryCardWearReq(refId,heroId)
end
function UIKCardEquip:InitMessage()
	self:WndNetMsgRecv(LProtoIds.SorceryCardOpenResp,function(pb) self:RefreshData() end)
	self:WndNetMsgRecv(LProtoIds.SorceryCardWearResp,function(pb) self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.SorceryCardUnloadResp,function(pb) self:WndClose() end)
	--self:WndNetMsgRecv("SorceryCardSwitchResp",function(pb) self:WndClose() end)
end
function UIKCardEquip:OnClickBook()
	GF.OpenWnd("UISorceryCardBook")
	self:WndClose()
end

function UIKCardEquip:OnClickRace(race)
	local _race = self._race
	local _raceList = self._raceList or {}
	if _race then
		CS.ShowObject(_raceList[_race],false)
	end
	CS.ShowObject(_raceList[race],true)
	self._race = race
	self:RefreshData()
end
function UIKCardEquip:CardShowSet(item,itemdata)
	local root = self:FindWndTrans(item,"Root")
	local cardFrame = self:FindWndTrans(root,"CardFrame")
	local icon = self:FindWndTrans(root,"CardFrame/Icon")
	local nameText = self:FindWndTrans(root,"NameText")
	local desText = self:FindWndTrans(root,"DesText")
	local btnDes = self:FindWndTrans(root,"BtnDes")
	local cardMask = self:FindWndTrans(item,"CardMask")
	CS.ShowObject(cardMask,false)
	CS.ShowObject(root,true)
	local _cardList = self._cardList or {}
	local _card = _cardList[itemdata.refId]
	if not _card then return end
	local skillLvRef = gModelSorceryCard:GetSorceryCardSkillRef(itemdata.skillGroup,_card.level)
	local skillRef = gModelSkill:GetSkillRef(skillLvRef.skill)
	local desStr = string.replace(ccClientText(29554),skillLvRef.level,ccLngText(skillRef.name))
	local themeRef = gModelSorceryCard:GetSorceryCardThemeRefByRefId(itemdata.theme)
	self:SetWndEasyImage(cardFrame,itemdata.frameRes,nil,true)
	self:SetWndEasyImage(icon,itemdata.icon,nil,true)
	local quality = itemdata.quality
	local qualityRef = gModelItem:GetQualityRef(quality)
	local nameStr = LUtil.FormatColorStr(ccLngText(itemdata.name),"#"..qualityRef.nameColor)
	self:SetWndText(nameText,nameStr)
	self:SetWndText(desText,desStr)
	self:SetWndClick(btnDes,function ()
		local argList = {
			skill = skillLvRef.skill,
			wndType = 7,
			cardId = itemdata.refId,
			skillGroup = itemdata.skillGroup,
			cardLevel = _card and _card.level or 0
		}
		gModelGeneral:OpenSkillWnd(argList)
	end)
end
function UIKCardEquip:OnClickDemount()
	local heroId = self._heroId
	local refId = self._curScRefId
	gModelSorceryCard:OnSorceryCardUnloadReq(refId,heroId)
end
function UIKCardEquip:SetMappingGroup()
	local heroId = self._heroId
	local mappingData = gModelResonance:CheckHeroInTargetMappingDict(heroId)
	local showMapping = false
	if(mappingData)then
		local sourceHeroId = mappingData.sourceHeroId
		showMapping = sourceHeroId and sourceHeroId~="0" and sourceHeroId~=0
		if(showMapping)then
			local sourceHeroId = mappingData.sourceHeroId
			local heroData = gModelHero:GetHeroById(sourceHeroId)
			local heroRefId = heroData:GetRefId()
			local heroEffRef = gModelHero:GetShowEffectById(heroRefId)
			local txtTrans = self:FindWndTrans(self.mMappingGroup,"DescTxt")
			local runeNameStr = ccClientText(38409)
			local descTxtStr = not self._showMapping and string.replace(ccClientText(38412),runeNameStr,runeNameStr) or ccClientText(38423)
			self:SetWndText(txtTrans,descTxtStr)
			local iconTrans = self:FindWndTrans(txtTrans,"Icon")
			self:SetWndEasyImage(iconTrans,heroEffRef.outfitIcon)
			local changeBtnTrans = self:FindWndTrans(txtTrans,"ChangeBtn")
			local changeBtnText = self:FindWndTrans(changeBtnTrans,"Text")
			local changeBtnStrId = not self._showMapping and 38424 or 38425
			self:SetWndText(changeBtnText,ccClientText(changeBtnStrId))
			self:SetWndClick(changeBtnTrans, function()
				if(self.clickMapping)then
					return
				end
				self._showMapping = not self._showMapping
				self._isClientHeroAttrReq = true
				self:RefreshData()
				gModelHero:OnHeroAttributeReq(self._heroId)
				self.clickMapping = true
				LxTimer.DelayTimeCall(function()
					self.clickMapping = false
				end,0.1)
			end)
		end
	end
	CS.ShowObject(self.mMappingGroup, showMapping)
end

function UIKCardEquip:RaceListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local icon = self:FindWndTrans(root,"Icon")
	local selImg = self:FindWndTrans(root,"SelImg")

	self._raceList[itemdata.refId] = selImg
	self:SetWndEasyImage(icon,itemdata.icon)
	self:SetWndClick(root,function ()
		self:OnClickRace(itemdata.refId)
	end)
end

function UIKCardEquip:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty1")
	emptyList:RefreshUI(data)
end
function UIKCardEquip:OnClickReplace(refId,reHeroId)
	local heroId = self._heroId
	local curRefId = self._curScRefId or 0
	local func = function()
		self:OnClickWear(refId)
	end
	if curRefId <= 0 then
		local cardName,oldHeroName,newHeroName = "","",""
		local ref = gModelSorceryCard:GetSorceryCardRefByRefId(refId)
		cardName = ccLngText(ref.name)
		oldHeroName = gModelHero:GetHeroNameById(reHeroId)
		newHeroName = gModelHero:GetHeroNameById(heroId)
		gModelGeneral:OpenUIOrdinTips({refId = 10032,func = func,para = {cardName,oldHeroName,newHeroName}})
	elseif string.isempty(reHeroId) or tonumber(reHeroId) <= 0 then
		self:OnClickWear(refId)
	else
		local popAlertId = 28000000
		local isAlert = gModelGeneral:FindAlertId(popAlertId)
		if isAlert then
			if func then
				func()
			end
		else
			GF.OpenWnd("UISorceryCardSwitchPop",{func = func,heroId = heroId,oldRefId = refId,newRefId = curRefId,popAlertId = popAlertId})
		end
	end
end
------------------------------------------------------------------
return UIKCardEquip


