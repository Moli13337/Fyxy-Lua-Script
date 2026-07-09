---
--- Created by BY.
--- DateTime: 2022/7/15 11:41:01
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISorceryCardUpLv:LWnd
local UISorceryCardUpLv = LxWndClass("UISorceryCardUpLv", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISorceryCardUpLv:UISorceryCardUpLv()
	self._uiCommonList = {}
	self._heroIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISorceryCardUpLv:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	self:ClearCommonIconList(self._heroIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISorceryCardUpLv:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISorceryCardUpLv:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	
	if self._isEnus then 
		self:SetAnchorPos(self.mSubstituteIcon,Vector2.New(-85,-26.5))
	end
	self._isJapaness  =gLGameLanguage:IsJapanVersion()

	if self._isJapaness then
		self:SetAnchorPos(self.mHeroText,Vector2.New(0,68.2))
	end

	self._isVie = gLGameLanguage:IsVieVersion()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UISorceryCardUpLv:OnClickUp()
	local _aItemBool = self._aItemBool
	local _refId = self._refId
	if not _aItemBool then
		local ref = gModelSorceryCard:GetSorceryCardRefByRefId(_refId)
		gModelGeneral:OpenGetWayWnd({itemId = ref.associateItem,srcWnd = self:GetWndName()})
		return
	end

	gModelSorceryCard:OnSorceryCardUpgradeReq(_refId)
end
function UISorceryCardUpLv:CreateCommonIcon(data)
	local key = data.key
	local trans = data.trans
	local itemType,itemId,itemNum = data.itemType, data.itemId, data.itemNum
	local baseClass = self._uiCommonList[key]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiCommonList[key] = baseClass
		baseClass:Create(trans)
	end
	baseClass:SetCommonReward(itemType,itemId,itemNum)
	local showNum = itemNum > 0
	baseClass:EnableShowNum(showNum)
	baseClass:DoApply()
	self:SetWndClick(trans,function ()
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
end
function UISorceryCardUpLv:OnClickDes()
	GF.OpenWnd("UISorceryCardAddPop",{refId = self._refId})
end
function UISorceryCardUpLv:OnClickClose()
	-- local _callMoveLayer = self._callMoveLayer
    -- local _callTheme = self._callTheme
	-- GF.OpenWnd("UISorceryCardBook",{moveLayer = _callMoveLayer,theme = _callTheme})
	self:WndClose()
end

function UISorceryCardUpLv:RefreshData()
	local cardList = gModelSorceryCard:GetCardList()
	local heroKeys = gModelSorceryCard:GetHeroKeys()
	local _refId = self._refId
	if(self._showMapping)then
		local sorcesryCard = gModelHero:GetSorceryCardInfo()
		_refId = sorcesryCard and sorcesryCard.scRefId or _refId
		--self._refId = _refId
	end
	if not cardList or not heroKeys then
		gModelSorceryCard:OnSorceryCardOpenReq()
		return
	end
	local ref = gModelSorceryCard:GetSorceryCardRefByRefId(_refId)
	local themeRef = gModelSorceryCard:GetSorceryCardThemeRefByRefId(ref.theme)
	local cardInfo = cardList[_refId]
	local curLv = cardInfo and cardInfo.level or 0
	self._curLv = curLv
	local lvRef = gModelSorceryCard:GetSorceryCardUpgradeRef(_refId,curLv)
	local icense = lvRef.icense == 1
	local isNextLevel = lvRef.nextLevel ~= -1
	local nexLvRef = isNextLevel and gModelSorceryCard:GetSorceryCardUpgradeRef(_refId,curLv + 1) or nil
	local skillGroup = ref.skillGroup
	local skillRef,skillLock = gModelSorceryCard:GetSorceryCardSkillRef(skillGroup,curLv)
	local nexSkillRef = (skillLock and isNextLevel) and gModelSorceryCard:GetSorceryCardSkillRef(skillGroup,curLv + 1) or nil
	local isNexSkill = nexSkillRef and nexSkillRef.refId ~= skillRef.refId

	CS.ShowObject(self.mAniRoot,true)
	CS.ShowObject(self.mBgImage,true)
	CS.ShowObject(self.mCardFrame,true)
	CS.ShowObject(self.mBtnDes,curLv > 0)
	CS.ShowObject(self.mMaskNullHero,cardInfo)
	CS.ShowObject(self.mMaskLockHero,not cardInfo)
	CS.ShowObject(self.mHeroText, not string.isempty(ccLngText(ref.equipLimitTxt)))
	self:SetWndEasyImage(self.mBgImage,themeRef.bgImg)
	self:SetWndEasyImage(self.mCardFrame,ref.frameRes)
	self:SetWndEasyImage(self.mCardIcon,ref.icon,function()
		CS.ShowObject(self.mCardIcon,true)
	end,not CS.IsWebGL())
	self:SetWndEasyImage(self.mThemeIcon,themeRef.icon)
	self:SetWndText(self.mTitleText,ccLngText(ref.name))
	self:SetWndText(self.mHeroText,ccLngText(ref.equipLimitTxt))
	self:SetWndText(self.mArrtDesText,string.replace(ccClientText(29506),ccLngText(ref.attrBonusDesc)))
	self:InitTextLineWithLanguage(self.mArrtDesText, -30)
	if self._isVie then
		local textTran = LxUiHelper.FindXTextCtrl(self.mArrtDesText)

		textTran.enableWordWrapping = false
		self:InitTextCharacterWithLanguage(self.mArrtDesText, -4)
	end
	UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mTitleBg)
	self:RefreshHero()

	local list = {
		{
			type = isNextLevel and 1 or 2,
			level1 = lvRef.level,
			level2 = isNextLevel and nexLvRef.level or 0,
		}
	}
	local arrt1List = LUtil.GetRefAttrData(lvRef.attr)
	local arrt2List = isNextLevel and LUtil.GetRefAttrData(nexLvRef.attr) or {}
	if isNextLevel then
		for i, v in ipairs(arrt2List) do
			local arrt1s = arrt1List[i]
			if not arrt1s then
				arrt1s = {
					refId = v.refId,
					numType = v.numType,
					value = 0,
				}
			end
			table.insert(list,{type = isNextLevel and 1 or 2,arrt1 = arrt1s,arrt2 = v})
		end
	else
		for i, v in ipairs(arrt1List) do
			table.insert(list,{type = 2,arrt1 = v})
		end
	end

	local arrUiList = self._arrUiList
	if arrUiList then
		arrUiList:RefreshList(list)
		arrUiList:DrawAllItems()
	else
		arrUiList = self:GetUIScroll("mArrtSuper_UISorceryCardUpLv")
		self._arrUiList = arrUiList
		arrUiList:Create(self.mArrtSuper,list,function(...) self:ArrtListItem(...) end,UIItemList.SUPER)
	end

	self:SetSkillIcon(self.mSkill1,skillRef,not skillLock)
	CS.ShowObject(self.mSkillUpImg,isNexSkill)
	CS.ShowObject(self.mSkill2,isNexSkill)
	if isNexSkill then
		self:SetSkillIcon(self.mSkill2,nexSkillRef)
	end
	CS.ShowObject(self.mCostRoot,isNextLevel and not self._showMapping)
	if isNextLevel then
		local associateItem = ref.associateItem
		local substitute = ref.substitute
		local data = {
			trans = self.mCostIcon,
			key = "mCostRoot",
			itemType = 1,
			itemId = associateItem,
			itemNum = -1
		}
		self:CreateCommonIcon(data)
		local costName = gModelItem:GetNameByRefId(associateItem)
		local bagNum = gModelItem:GetNumByRefId(associateItem)
		self:SetWndText(self.mCostNameText,costName)
		local aItemBool = bagNum >= lvRef.upCost
		local numStr =LUtil.FormatColorStr(bagNum,aItemBool and "lightGreen" or "lightRed")
		self:SetWndText(self.mCostNumText,string.format("%s/%s",numStr,lvRef.upCost))
		if icense and not aItemBool then
			local icon = gModelItem:GetItemImgByRefId(substitute)
			local sBagNum = gModelItem:GetNumByRefId(substitute)
			local rTaskNum = lvRef.upCost - bagNum
			aItemBool = sBagNum >= rTaskNum
			local sNumStr = LUtil.FormatColorStr(rTaskNum,aItemBool and "lightGreen" or "lightRed")
			CS.ShowObject(self.mSubstituteIcon,aItemBool)
			self:SetWndEasyImage(self.mSubstituteIcon,icon)
			self:SetWndText(self.mSubstituteText,sNumStr)
		else
			CS.ShowObject(self.mSubstituteIcon,false)
		end
		self._aItemBool = aItemBool
	else
		CS.ShowObject(self.mSubstituteIcon,false)

	end
	CS.ShowObject(self.mCostNumText,isNextLevel and not self._showMapping)
	CS.ShowObject(self.mCostNameText,isNextLevel and not self._showMapping)
	local btnUpStr = curLv == 0 and ccClientText(29509) or ccClientText(29510)
	CS.ShowObject(self.mBtnUp,isNextLevel and not self._showMapping)
	CS.ShowObject(self.mMaxLv,not isNextLevel)
	CS.ShowObject(self.mCostITitle, isNextLevel)
	self:SetWndButtonText(self.mBtnUp,btnUpStr)
end
function UISorceryCardUpLv:RefreshHero()
	CS.ShowObject(self.mHeroRoot,false)
	local cardList = gModelSorceryCard:GetCardList()
	local _refId = self._refId
	if not cardList then return end
	local cardInfo = cardList[_refId]
	if not cardInfo then return end
	local heroId = cardInfo.heroId
	local isHero = not string.isempty(heroId) and tonumber(heroId) > 0
	CS.ShowObject(self.mHeroRoot,isHero)
	if(isHero)then
		self:SetMappingGroup(heroId)
	end
	CS.ShowObject(self.mCostText,not self._showMapping)
	local mappingOtherHero = gModelResonance:GetMappingOtherId(heroId)
	local isBeMapping = gModelResonance:CheckHeroInTargetMappingDict(heroId) and mappingOtherHero
	CS.ShowObject(self.mMappingGroup,isHero and isBeMapping)
	local InstanceID = "heroIcon_UISorceryCardUpLv"
	local baseClass = self._heroIconList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New(self)
		self._heroIconList[InstanceID] = baseClass
		baseClass:Create(self.mHeroRoot)
	end
	baseClass:SetHeroPlayer(heroId)
	baseClass:DoApply()
end
function UISorceryCardUpLv:OnClickRecommend()
	GF.OpenWnd("UISorceryCardRecommend",{refId = self._refId})
end
function UISorceryCardUpLv:OnWndRefresh()
	self:InitThemeList()
end
function UISorceryCardUpLv:ArrtListItem(list,item, itemdata, itempos)
	local root1 = self:FindWndTrans(item,"Root1")
	local root2 = self:FindWndTrans(item,"Root2")

	local type = itemdata.type
	CS.ShowObject(root1,type == 1)
	CS.ShowObject(root2,type == 2)
	local root = type == 1 and root1 or root2
	self:SetRoot1Item(root,itemdata)
end
function UISorceryCardUpLv:SetRoot1Item(item,itemdata)
	local nameText = self:FindWndTrans(item,"NameText")
	local icon = self:FindWndTrans(item,"NameText/Icon")
	local arrt1Text = self:FindWndTrans(item,"Arrt1Text")
	local arrt2Text = self:FindWndTrans(item,"Arrt2Text")

	local type = itemdata.type
	local level1 = itemdata.level1
	local level2 = itemdata.level2
	local arrt1 = itemdata.arrt1
	local arrt2 = itemdata.arrt2
	local iconStr,nameStr,valueStr
	if arrt1 then
		iconStr = gModelHero:GetAttributeIconById(arrt1.refId)
		nameStr = gModelHero:GetAttributeNameById(arrt1.refId)
		valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(arrt1.refId,arrt1.numType,arrt1.value)
	end
	nameStr = level1 and ccClientText(10057) or nameStr

	CS.ShowObject(icon,not level1)
	self:SetWndText(nameText,nameStr)
	self:SetWndEasyImage(icon,iconStr)
	self:SetWndText(arrt1Text,level1 and level1 or valueStr)

	if type == 2 then
		return
	end
	local value2Str
	if arrt2 then
		value2Str = gModelHero:GetAttributeValueNoNameByIdAndVal(arrt2.refId,arrt2.numType,arrt2.value)
	end
	self:SetWndText(arrt2Text,level2 and level2 or value2Str)

	if self._isVie then
		self:InitTextCharacterWithLanguage(nameText,-5)
		self:SetAnchorPos(nameText,Vector2.New(-430,0))
		self:SetAnchorPos(arrt1Text,Vector2.New(-90,0))
		self:InitTextCharacterWithLanguage(arrt1Text,-5)
		self:InitTextCharacterWithLanguage(arrt2Text,-5)
	end
	if self._isEnus then
		self:SetAnchorPos(nameText,Vector2.New(-427,0))
		self:SetAnchorPos(arrt1Text,Vector2.New(-88.7,0))
	end
end
function UISorceryCardUpLv:UIDragTryOnEnd(dragKey,eventData)
	self.mDragRoot.transform.localPosition = Vector2.New(0,242)
	self._bDrag = true
end
function UISorceryCardUpLv:OnClickHero()
	local refId = self._refId
	local card = gModelSorceryCard:GetCardInfoByRefId(refId)
	if not card then
		GF.ShowMessage(ccClientText(29551))
		return
	end
	GF.OpenWnd("UISorceryCardSelHero",{refId = refId})
end

function UISorceryCardUpLv:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId = 380})
end
function UISorceryCardUpLv:OnClickCut(type)
	local _listLen = self._listLen or 0
	local _refIdList = self._refIdList or {}
	local _indexList = self._indexList or {}
	if _listLen <= 0 then return end
	self._showMapping =false
	CS.ShowObject(self.mMappingGroup,false)
	local _refId = self._refId

	local curIndex = _refIdList[_refId]
	if type == 1 then
		curIndex = curIndex - 1
	else
		curIndex = curIndex + 1
	end
	if curIndex < 1 or curIndex > _listLen then return end
	self._refId = _indexList[curIndex]

	CS.ShowObject(self.mBtnCut1,curIndex > 1)
	CS.ShowObject(self.mBtnCut2,curIndex < _listLen)
	self:RefreshData()
end

function UISorceryCardUpLv:InitDrag()--拖动
	self:UIDragSetItem("_UISorceryCardUpLv_InitDrag","AniRoot/Centre/DragRoot",CS.YXUIDrag.DragMode.DragOrigin)
end
function UISorceryCardUpLv:InitMessage()
	self:WndNetMsgRecv(LProtoIds.SorceryCardOpenResp,function(pb) self:RefreshData() end)
	self:WndNetMsgRecv(LProtoIds.SorceryCardUpgradeResp,function(pb)
		self:CreateWndEffect(self.mCardEff,"fx_ui_shengji_hero","fx_ui_shengji_hero",140)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.SorceryCardWearResp,function(pb) self:RefreshHero() end)
	self:WndNetMsgRecv(LProtoIds.SorceryCardUnloadResp,function(pb) self:RefreshHero() end)

	self:WndEventRecv(EventNames.On_Item_Change, function()
		self:RefreshData()
	end)
end
function UISorceryCardUpLv:InitThemeList()
	local refId = self:GetWndArg("refId")
	self._refId = refId

	local ref = gModelSorceryCard:GetSorceryCardRefByRefId(refId)
	local sorceryCardRefs = gModelSorceryCard:GetSorceryCardRefByTheme(ref.theme)
	table.sort(sorceryCardRefs,function (a,b)
		if a.quality ~= b.quality then
			return a.quality > b.quality
		end
		return a.refId < b.refId
	end)
	local refIdList = {}
	local indexList = {}
	for i, v in ipairs(sorceryCardRefs) do
		refIdList[v.refId] = i
		indexList[i] = v.refId
	end
	self._listLen = #sorceryCardRefs
	self._refIdList = refIdList
	self._indexList = indexList
	local curIndex = refIdList[refId] or 0
	CS.ShowObject(self.mBtnCut1,curIndex > 1)
	CS.ShowObject(self.mBtnCut2,curIndex < self._listLen)

	self:RefreshData()
end
function UISorceryCardUpLv:SetSkillIcon(item,lvRef,lock)
	if not item or not lvRef then return end
	local skillIcon = self:FindWndTrans(item,"SkillIcon")
	local lvText = self:FindWndTrans(item,"LvBg/LvText")
	local luckBg = self:FindWndTrans(item,"LuckBg")

	if self._isEnus then
		luckBg =self:FindWndTrans(item,"LuckBg_Enus")
	end

	local luckText = self:FindWndTrans(luckBg,"LuckText")

	local ref = gModelHero:GetSkillByStarId(lvRef.skill)

	self:SetWndEasyImage(skillIcon,ref.icon)
	self:SetWndText(lvText,lvRef.level)
	CS.ShowObject(luckBg,lock)
	self:SetWndText(luckText,string.replace(ccClientText(29534),lvRef.unlockLevel))
	self:SetWndClick(item,function ()
		local cardInfo = gModelSorceryCard:GetCardInfoByRefId(self._refId)
		local argList = {
			skill = lvRef.skill,
			wndType = 7,
			cardId = self._refId,
			skillGroup = lvRef.group,
			cardLevel = cardInfo and cardInfo.level or 0
		}
		gModelGeneral:OpenSkillWnd(argList)
	end)
end
function UISorceryCardUpLv:InitCommand()
	self:SetWndText(self.mCloseText,ccClientText(20723))
	self:SetWndText(self.mRecommendText,ccClientText(29507))
	self:SetWndButtonText(self.mBtnDes,ccClientText(29508))
	self:SetWndText(self.mSkillText,ccClientText(29532))
	self:SetWndText(self.mCostText,ccClientText(29533))
	-- self:SetWndText(self.mMaxLvText,ccClientText(29511))

	self._callMoveLayer = self:GetWndArg("callMoveLayer")
    self._callTheme = self:GetWndArg("callTheme")
	local isOpenWear = self:GetWndArg("isOpenWear")
	self:InitThemeList()
	self:InitDrag()
	if isOpenWear then
		self:OnClickHero()
	end
end
function UISorceryCardUpLv:UIDragOnDrag(dragKey,eventData)
	local moveX = self.mDragRoot.transform.localPosition.x
	if not self._bDrag then return end
	if moveX > 20 then
		self:OnClickCut(1)
		self._bDrag = false
	elseif moveX < - 20 then
		self:OnClickCut(2)
		self._bDrag = false
	end
end
function UISorceryCardUpLv:SetMappingGroup(heroId)
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
			local cardNameStr = ccClientText(38409)
			local descTxtStr = not self._showMapping and string.replace(ccClientText(38412),cardNameStr,cardNameStr) or ccClientText(38423)
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
				self.clickMapping = true
				LxTimer.DelayTimeCall(function()
					self.clickMapping = false
				end,0.1)
			end)
		end
	end
	CS.ShowObject(self.mMappingGroup, showMapping)
	CS.ShowObject(self.mBotSelBtnGroup, not showMapping)
end

function UISorceryCardUpLv:InitEvent()
	self:SetWndClick(self.mBtnClose,function ()self:OnClickClose() end)
	self:SetWndClick(self.mBtnHelp,function ()self:OnClickHelp() end,LSoundConst.CLICK_ERROR_COMMON)
	self:SetWndClick(self.mBtnRecommend,function ()self:OnClickRecommend() end)
	self:SetWndClick(self.mBtnHero,function ()self:OnClickHero() end)
	self:SetWndClick(self.mBtnDes,function ()self:OnClickDes() end)
	self:SetWndClick(self.mBtnUp,function ()self:OnClickUp() end)
	self:SetWndClick(self.mBtnCut1,function ()self:OnClickCut(1) end)
	self:SetWndClick(self.mBtnCut2,function ()self:OnClickCut(2) end)
end
------------------------------------------------------------------
return UISorceryCardUpLv


