---
--- Created by BY.
--- DateTime: 2023/10/24 11:27:23
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIUendAidPop:LWnd
local UIUendAidPop = LxWndClass("UIUendAidPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIUendAidPop:UIUendAidPop()
	---@type table<number, CommonIcon>
	self._heroIconList = {}

	self:SetHideHurdle()

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIUendAidPop:OnWndClose()
	self:ClearCommonIconList(self._heroIconList)

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIUendAidPop:OnCreate()
	LWnd.OnCreate(self)

	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

	self._tabTransList = {}
	self._raceTransList = {}
	self._tabType = -1
	self._raceType = -1
	self._maxPower = -1
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIUendAidPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isVie = gLGameLanguage:IsVieVersion()
	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	self._redFun1 = function (pb)
		self:RefreshRed(ModelRedPoint.ENDLES_AID_COMPLEX)
	end
	self._redFun2 = function (pb)
		self:RefreshRed(ModelRedPoint.ENDLES_AID_SPECIAL)
	end
	if self._specialType == ModelEndles.ENDLES_COMPLEX then
		self:RegisterRedPointFunc(ModelRedPoint.ENDLES_AID_COMPLEX,self._redFun1)
	else
		self:RegisterRedPointFunc(ModelRedPoint.ENDLES_AID_SPECIAL,self._redFun2)
	end
end

function UIUendAidPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIUendAidPop:RefreshWin()
	if(not self._aidInfo)then
		gModelEndles:OnHelpHeroListReq(self._specialType)
		return
	end
	CS.ShowObject(self.mNoRecord,false)
	CS.ShowObject(self.mNoRecord1,false)
	local type = self._tabType
	CS.ShowObject(self.mAidMe,false)
	CS.ShowObject(self.mMeAidMag,false)
	local tips = ""
	if(type == 1)then
		CS.ShowObject(self.mAidMe,true)
		self:RefreshAidMe()
		tips = ccClientText(17231)
	else
		CS.ShowObject(self.mMeAidMag,true)
		self:RefreshMeAid()
		tips = ccClientText(17232)
	end
	self:SetWndText(self.mTipsText,tips)
end

function UIUendAidPop:TypeListItem(list,item, itemdata, itempos)--种族cell
	local image = CS.FindTrans(item,"Image")
	local _raceType = itemdata.refId
	local race = gModelEndles:GetIsRace(self._specialType,_raceType)
	local iconStr = itemdata.icon
	local onClickFun = nil
	if(_raceType ~= race)then
		iconStr = "public_race_icon_buff_0"
	else
		onClickFun = function() self:OnClickType(itemdata.refId) end
	end
	self:SetWndEasyImage(image,iconStr)
	self._raceTransList[itemdata.refId] = item
	self:SetWndClick(item, function(...) if(onClickFun)then onClickFun()end end,LSoundConst.CLICK_PAGE_COMMON)
	end

function UIUendAidPop:AidMeListItem(list,item, itemdata, itempos)--援助我的cell
	local nameText = CS.FindTrans(item,"NameText")
	local btn = CS.FindTrans(item,"Btn")
	local btnText = CS.FindTrans(item,"Btn/BtnYellow_1/XUIText")
	local scopeText = CS.FindTrans(item,"ScopeText")
	self:SetWndText(nameText,itemdata.playerName)

	local isHelp = itemdata.isHelp == 1
	--local ratio = gModelEndles:GetEndlessConfigRefByKey("powerDisparityRatio")
	local isScope = isHelp or itemdata.isScope == 1
	CS.ShowObject(btn,isScope)
	CS.ShowObject(scopeText,not isScope)
	if(isScope)then
		local btnStr = isHelp and ccClientText(17226) or ccClientText(17227)
		local btnImage = isHelp and "public_btn_3_1" or "public_btn_3_2"
		if(isHelp)then
			self:SetWndClick(btn, function(...) self:OnClickCancelAidMe(itemdata.id,itemdata.playerId) end)
		else
			self:SetWndClick(btn, function(...) self:OnClickSelectAidMe(itemdata.id,itemdata.playerId) end)
		end
		-- local nameOutlines = isHelp and "SourceHanSerifCN_132262_2" or "SourceHanSerifCN_442a00_2"
		-- self:SetWndButtonTextMat(btn,nameOutlines)
		self:SetWndButtonImg(btn,btnImage)
		self:SetWndButtonText(btn,btnStr)
	else
		self:SetWndText(scopeText,ccClientText(17228))
	end
	self:ShowHeroInfo(item,itemdata,true)

	self:InitTextLineWithLanguage(scopeText,-40)
end

function UIUendAidPop:ChangeRace(trans,bool)
	local selImg = CS.FindTrans(trans,"SelImg")
	CS.ShowObject(selImg,bool)
end

function UIUendAidPop:RefreshMeAid()--刷新我的援助
	local _aidInfo = self._aidInfo
	self._selfHeroId = _aidInfo.selfHero.id
	local heroList = gModelHero:GetHeroList()
	local list = {}
	for i, v in pairs(heroList) do
		local hero = v:GetServerData()
		local heroRef = gModelHero:GetHeroRef(hero.refId)

		if(heroRef.raceType == self._raceType or self._raceType == 0)then
			if(self._raceType == 0)then
				local race = gModelEndles:GetIsRace(self._specialType,heroRef.raceType)
				if(race == heroRef.raceType)then
					hero.lvl = hero.lv
					hero.power = hero.fightPower
					table.insert(list,hero)
				end
			else
				hero.lvl = hero.lv
				hero.power = hero.fightPower
				table.insert(list,hero)
			end
		end
	end

	local isShow = #list > 0
	CS.ShowObject(self.mNoRecord1,not isShow)
	if(not isShow)then
		self:CreateEmptyShow1(12002)
	else
		table.sort(list,function (a,b)
			return a.power > b.power
		end)
	end

	if(self._uiMeAidList)then
		self._uiMeAidList:RefreshSimpleList(list)
	else
		self._uiMeAidList = self:GetUIScroll("MeAid")
		self._uiMeAidList:Create(self.mMeAidScroll,list,function (...) self:MeAidListItem(...) end,UIItemList.WRAP)
	end

	local isSelect = _aidInfo.selfHero ~= nil and _aidInfo.selfHero.id ~= ""
	CS.ShowObject(self.mSelectText,not isSelect)
	CS.ShowObject(self.mSelectItem,isSelect)
	if(isSelect)then
		self:ShowHeroInfo(self.mSelectItem,_aidInfo.selfHero)
	end

	self:SendGuideReadyEvent(self:GetWndName()) --引导延迟触发
end

function UIUendAidPop:OnClickSelectAidMe(id,playerId)--选择雇佣英雄
	gModelEndles:OnSelectHelpHeroReq(1,id,self._specialType,playerId)
end

function UIUendAidPop:TabListItem(list,item, itemdata, itempos)--标签cell
	local btnTab1 = CS.FindTrans(item,"BtnTab1")
	local redPoint = CS.FindTrans(item,"redPoint")
	local addFontLine = -30
	local addSize = 0
	if self._isFrenchVersion then
		addFontLine = -60
	elseif self._isThaiVersion then
		addSize = -2
		addFontLine = -50
	end
	self:SetWndTabText(btnTab1,itemdata.des,addSize,addFontLine)
	self:SetWndTabStatus(btnTab1,LWnd.StateOff)
	self._tabTransList[itemdata.type] = btnTab1
	if itemdata.type == 2 then
		self._AddHeroRed = redPoint
	end
	self:SetWndClick(item, function(...) self:OnClickTab(itemdata.type) end,LSoundConst.CLICK_PAGE_COMMON)
end

function UIUendAidPop:ShowHeroInfo(item,itemdata,isAid)--显示英雄数据
	local jobText = CS.FindTrans(item,"JobText")
	local heroText = CS.FindTrans(item,"HeroText")
	local powerText = CS.FindTrans(item,"PowerBg_1/PowerText")
	local heroIcon = CS.FindTrans(item,"Root/HeroIcon")
	local heroRef = gModelHero:GetHeroRef(itemdata.refId)
	local jobRef = gModelHero:GetCareerRefByRefId(heroRef.careerType)
	local heroEffRef = gModelHero:GetHeroShowRefByRefId(itemdata.refId,itemdata.star)
	local color = "#"..gModelHero:GetHeroNameColorByRefId(itemdata.refId,itemdata.star)
	self:SetWndText(jobText,ccLngText(jobRef.name))
	self:SetWndText(heroText,LUtil.FormatColorStr(ccLngText(heroEffRef.name),color))
	self:SetWndText(powerText,LUtil.PowerNumberCoversion(itemdata.power))
	local heroData={
		id=itemdata.id,
		refId=itemdata.refId,
		star=itemdata.star,
		level=itemdata.lvl,
		fightPower = itemdata.power,
		grade = itemdata.grade,
		isResonance = itemdata.isResonance,
		skin = itemdata.skin,
		isEndlesHero = isAid,
		treeInfo = itemdata.treeInfo,
		form = itemdata.form,
	}
	local InstanceID = item:GetInstanceID()
	local baseClass = self._heroIconList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._heroIconList[InstanceID] = baseClass
		baseClass:Create(heroIcon)
		self:SetIconClickScale(heroIcon, true)
	end
	baseClass:SetHeroDataSet(heroData)
	baseClass:DoApply()

	self:SetWndClick(heroIcon,function ()
		gModelHero:ReqShowHeroTip(itemdata.playerId,heroData)
	end)
	if self._isVie then
		self:SetAnchorPos(heroText,Vector2.New(0,48.3))
	end
	if self.jpj then
		self:SetAnchorPos(heroText,Vector2.New(20,48.3))
	end
end

function UIUendAidPop:MeAidListItem(list,item, itemdata, itempos)--我的援助cell
	local onSelectText = CS.FindTrans(item,"OnSelectText")
	local btn = CS.FindTrans(item,"Btn")

	local isSelect = itemdata.id == self._selfHeroId
	CS.ShowObject(onSelectText,isSelect)
	CS.ShowObject(btn,not isSelect)
	if(not isSelect)then
		self:SetWndButtonText(btn,ccClientText(17230))
		self:SetWndClick(btn, function(...)
			if(self._selfHeroId ~= "")then
				GF.ShowMessage(ccClientText(17233))
			else
				self:OnClickSelectMeAid(itemdata.id)
			end
		end)
	else
		self:SetWndText(onSelectText,ccClientText(17229))
	end
	self:ShowHeroInfo(item,itemdata)
end

function UIUendAidPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.HelpHeroListResp,function (pb)
		self._aidInfo = gModelEndles:GetEndlessHelp(self._specialType)
		self:RefreshWin()
	end)
	self:WndNetMsgRecv(LProtoIds.SelectHelpHeroResp,function (pb)
		self._aidInfo = gModelEndles:GetEndlessHelp(self._specialType)
		self:RefreshWin()
		--gModelEndles:OnHelpHeroListReq(self._specialType)
	end)
end

function UIUendAidPop:CreateEmptyShow1(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText1,
		TextBgTran = self.mEmptyTextBg1,
		IconTran = self.mEmptyIcon1,
	}
	local emptyList = self:GetCommonEmptyList("_empty2")
	emptyList:RefreshUI(data)
end

function UIUendAidPop:ChangeType(trans,bool)
	self:SetWndTabStatus(trans,bool and LWnd.StateOn or LWnd.StateOff)
end

function UIUendAidPop:OnClickTab(type)--点击标签类型
	if(self._tabType>0)then
		if(self._tabType == type)then
			return
		end
		local trans = self._tabTransList[self._tabType]
		self:ChangeType(trans,false)
	end
	self._tabType = type
	local trans = self._tabTransList[type]
	self:ChangeType(trans,true)
	local title = self._tablist[type].des
	self:SetWndText(self.mTitleText,title)
	self:OnClickType(0)
end

function UIUendAidPop:InitRaceTypeList()
	local data = {
		wndClass = self,
		listTrans = self.mHeroRaceList,
		showListBg = true,
		showType = UIHeroRaceList.TYPE_NORMAL,
		callbackFunc = function(raceType)
			if not self:IsWndValid() then return end
			if raceType == self._raceType then return end
			self._raceType = raceType
			self:RefreshBtnEvent()
		end,
		checkSelFunc = function(raceType)
			if not self:IsWndValid() then return end
			return self._raceType == raceType
		end,
	}
	self:GetUIHeroRaceList(data)
end

function UIUendAidPop:RefreshRed(index)
	local showRed =  gModelRedPoint:CheckShowRedPoint(index)
	if self._AddHeroRed then
		CS.ShowObject(self._AddHeroRed,showRed)
	end
end

function UIUendAidPop:InitCommand()
	self:InitTextLineWithLanguage(self.mAidTipsText,-30)
	self:SetWndText(self.mAidTipsText,ccClientText(17264))
	self:SetWndText(self.mSelectText,ccClientText(17224))
	self:SetWndText(self.mOnSelectText,ccClientText(17229))
	self:SetWndText(self.mMeAidTitleText,ccClientText(17225))
	self._specialType = self:GetWndArg("type") or ModelEndles.ENDLES_COMPLEX
	self._page = self:GetWndArg("page") or 1
	self._tablist = {
		{type = 1,des = ccClientText(17222)},
		{type = 2,des = ccClientText(17223)},
	}
	self._uiList = self:GetUIScroll("tab")
	self._uiList:Create(self.mTabScroll,self._tablist,function (...) self:TabListItem(...) end)

	self._isFrenchVersion = gLGameLanguage:IsFrenchVersion()
	self._isThaiVersion = gLGameLanguage:IsThaiVersion()


	--local heroTypeList = gModelHero:GetHeroItemType()
	local heroTypeList = gModelHero:GetHeroRaceRefSortByRank()

	--table.insert(heroTypeList,{refId = 0,icon = "public_race_0"})
	--table.sort(heroTypeList,function (a,b)
	--	return a.refId <b.refId
	--end)
	self._uiTypeList = self:GetUIScroll("type")
	self._uiTypeList:Create(self.mTypeScroll,heroTypeList,function (...) self:TypeListItem(...) end)
	self._maxPower = gModelEndles:GetRaceMaxPower(self._specialType)
	local data = self._tablist[self._page]
	if not data then
		data = self._tablist[1]
	end
	self:OnClickTab(data.type)
end

function UIUendAidPop:OnClickSelectMeAid(id)--上阵援助英雄
	local playerId = gModelPlayer:GetPlayerId()
	gModelEndles:OnSelectHelpHeroReq(2,id,self._specialType,playerId)
end

function UIUendAidPop:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty1")
	emptyList:RefreshUI(data)
end

function UIUendAidPop:RefreshAidMe()--刷新援助我的
	local _aidInfo = self._aidInfo
	self.helpHeroId = _aidInfo.helpHero and _aidInfo.helpHero.id or ""
	local list = {}
	for i, v in pairs(_aidInfo.heroList) do
		local heroRef = gModelHero:GetHeroRef(v.refId)
		if(heroRef.raceType == self._raceType or self._raceType == 0)then
			v.isHelp = v.id == self.helpHeroId and 1 or 0
			local ratio = gModelEndles:GetEndlessConfigRefByKey("powerDisparityRatio")
			v.isScope = v.power <= self._maxPower * ratio and 1 or 0
			table.insert(list,v)
		end
	end
	table.sort(list,function (a,b)
		local aIsHelp = a.isHelp
		local bIsHelp = b.isHelp
		local aPower = a.power
		local bPower = b.power
		local aIsScope = a.isScope
		local bIsScope = b.isScope
		if(aIsScope ~= bIsScope)then
			return aIsScope > bIsScope
		end
		if(aIsHelp ~= bIsHelp)then
			return aIsHelp > bIsHelp
		end
		if(aPower ~= bPower)then
			return aPower > bPower
		end
		return false
	end)

	local isShow = #list > 0
	CS.ShowObject(self.mNoRecord,not isShow)
	if(not isShow)then
		self:CreateEmptyShow(12001)
	end

	if(self._uiAidMeList)then
		self._uiAidMeList:RefreshSimpleList(list)
	else
		self._uiAidMeList = self:GetUIScroll("AidMe")
		self._uiAidMeList:Create(self.mAidMeScroll,list,function (...) self:AidMeListItem(...) end,UIItemList.WRAP)
	end

	self:SendGuideReadyEvent(self:GetWndName()) --引导延迟触发
end

function UIUendAidPop:OnClickCancelAidMe(id,playerId)--取消雇佣英雄
	gModelEndles:OnSelectHelpHeroReq(3,id,self._specialType,playerId)
end

function UIUendAidPop:OnClickType(race)--点击种族
	if(race ~= 0 or self._specialType ~= 1)then
		race = gModelEndles:GetIsRace(self._specialType,race)
	end
	if(self._raceType>=0 and self._raceType ~= race)then
		local trans = self._raceTransList[self._raceType]
		--self:ChangeType(trans,false)
		self:ChangeRace(trans,false)
	end
	self._raceType = race
	local trans = self._raceTransList[race]
	--self:ChangeType(trans,true)
	self:ChangeRace(trans,true)
	self:RefreshWin()
end
------------------------------------------------------------------
return UIUendAidPop


