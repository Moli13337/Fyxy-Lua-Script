---
--- Created by BY.
--- DateTime: 2023/2/14 14:49:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISorceryCardSpeedHero:LWnd
local UISorceryCardSpeedHero = LxWndClass("UISorceryCardSpeedHero", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISorceryCardSpeedHero:UISorceryCardSpeedHero()
	self._raceList = {}
	self._heroIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISorceryCardSpeedHero:OnWndClose()
	self:ClearCommonIconList(self._heroIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISorceryCardSpeedHero:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISorceryCardSpeedHero:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	
	if self._isEnus then 
		self:InitTextSizeWithLanguage(self.mDesText,-2)
	end 
	
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UISorceryCardSpeedHero:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty1")
	emptyList:RefreshUI(data)
end
function UISorceryCardSpeedHero:HeroListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local heroRoot = self:FindWndTrans(root,"HeroRoot")
	local maskWear = self:FindWndTrans(root,"MaskWear")
	local maskSel = self:FindWndTrans(root,"MaskSel")
	local maskCard = self:FindWndTrans(root,"MaskCard")
	local cardIcon = self:FindWndTrans(root,"MaskCard/CardIcon")

	local _heroInfo = self._heroInfo
	local InstanceID = item:GetInstanceID()
	local heroKeys = gModelSorceryCard:GetHeroKeys() or {}
	local heroId = itemdata.id
	local cardId = heroKeys[heroId] or 0
	local isWear = cardId == self._refId
	local isSel = _heroInfo and _heroInfo.id == itemdata.id
	local isCard = not isWear and cardId > 0

	CS.ShowObject(maskWear,isWear)
	CS.ShowObject(maskSel,isSel)
	CS.ShowObject(maskCard,isCard)
	if isCard then
		local refId = cardId
		local ref = gModelSorceryCard:GetSorceryCardRefByRefId(refId)
		self:SetWndEasyImage(cardIcon,ref.fightIcon)
	end
	local baseClass = self._heroIconList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New(self)
		self._heroIconList[InstanceID] = baseClass
		baseClass:Create(heroRoot)
	end
	baseClass:SetHeroPlayer(heroId)
	baseClass:DoApply()

	self:SetWndClick(root,function ()
		self:OnClickHero(itemdata,isWear)
	end)
end
function UISorceryCardSpeedHero:InitMessage()
	self:WndNetMsgRecv(LProtoIds.SorceryCardWearResp,function(pb) self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.SorceryCardUnloadResp,function(pb) self:WndClose() end)
end
function UISorceryCardSpeedHero:OnClickHero(itemdata,isWear)
	--if isWear then
	--	GF.ShowMessage(ccClientText(29536))
	--	return
	--end
	self._heroInfo = itemdata
	local _heroUiList = self._heroUiList
	if not _heroUiList then return end
	_heroUiList:DrawAllItems()

	self:RefreshBtn()
end
function UISorceryCardSpeedHero:RefreshBtn()
	local _refId = self._refId
	local _heroInfo = self._heroInfo
	local oldRefId = _heroInfo.sorceryCardId

	local isWear = oldRefId ~= _refId
	local isUnload = oldRefId == _refId
	self:SetWndButtonGray(self.mBtnWear,not isWear)
	self:SetWndButtonGray(self.mBtnUnload,not isUnload)
end

function UISorceryCardSpeedHero:OnClickRace(type)
	local _raceType = self._raceType
	local _raceList = self._raceList or {}
	if _raceType then
		if _raceType == type then return end
		CS.ShowObject(_raceList[_raceType],false)
	end
	self._raceType = type
	CS.ShowObject(_raceList[type],true)
	self:RefreshData()
end

function UISorceryCardSpeedHero:RefreshData()
	local list = self:GetHeroList() or {}
	if not self._heroInfo then
		local cardRefId = self._refId
		for i, v in ipairs(list) do
			if v.sorceryCardId == cardRefId then
				self._heroInfo = v
				self:RefreshBtn()
				break
			end
		end
	end

	local len = #list
	CS.ShowObject(self.mNoRecord3,len <= 0)
	if len <= 0 then
		self:CreateEmptyShow(10009)
	end
	local _heroUiList = self._heroUiList
	if _heroUiList then
		_heroUiList:RefreshList(list)
		_heroUiList:DrawAllItems()
	else
		_heroUiList = self:GetUIScroll("mHeroSuper_UISorceryCardSpeedHero")
		self._heroUiList = _heroUiList
		_heroUiList:Create(self.mHeroSuper,list,function (...) self:HeroListItem(...) end,UIItemList.SUPER_GRID)
		_heroUiList:EnableScroll(true,false)
	end
end
function UISorceryCardSpeedHero:OnClickWear()
	local _heroInfo = self._heroInfo
	local _refId = self._refId
	if not _heroInfo then
		GF.ShowMessage(ccClientText(29566))
		return
	end
	local heroId = _heroInfo.id
	local func = function()
		local isWear = gModelSorceryCard:VerifyLimitByCardIdAndHeroId(_refId,heroId)
		if not isWear then
			GF.ShowMessage(ccClientText(29537))
			return
		end
		gModelSorceryCard:OnSorceryCardWearReq(_refId,heroId)
	end
	local oldRefId = _heroInfo.sorceryCardId
	if not oldRefId or oldRefId <= 0 then
		if func then
			func()
		end
		return
	end
	if oldRefId == _refId then
		GF.ShowMessage(ccClientText(29565))
		return
	end
	local popAlertId = 28000000
	local isAlert = gModelGeneral:FindAlertId(popAlertId)
	if isAlert then
		if func then
			func()
		end
	else
		GF.OpenWnd("UISorceryCardSwitchPop",{func = func,heroId = heroId,oldRefId = _refId,newRefId = _heroInfo.sorceryCardId,popAlertId = popAlertId})
	end
end

function UISorceryCardSpeedHero:GetHeroList()
	local unlockHeroStar = gModelSorceryCard:GetSorceryCardConfigRefByKey("unlockHeroStar")
	local _refId = self._refId
	local _equipLimit = self._equipLimit or 0
	local _raceType = self._raceType
	local heroKeys = gModelSorceryCard:GetHeroKeys()
	if not _raceType or not heroKeys then return end
	local limitRef = gModelSorceryCard:GetSorceryCardUseLimitRefByRefId(_equipLimit)
	if not limitRef then return end
	local suitRace,suitCareer,suitHeroInitQuality,suitGender,suitHero
	= limitRef.suitRace,limitRef.suitCareer,limitRef.suitHeroInitQuality,limitRef.suitGender,limitRef.suitHero
	local suitRaceList,suitCareerList,suitHeroInitQualityList,suitGenderList,suitHeroList
	if not string.isempty(suitRace) then
		local arr = string.split(suitRace,"|")
		suitRaceList = {}
		for i, v in ipairs(arr) do
			suitRaceList[tonumber(v)] = true
		end
	end
	if not string.isempty(suitCareer) then
		local arr = string.split(suitCareer,"|")
		suitCareerList = {}
		for i, v in ipairs(arr) do
			suitCareerList[tonumber(v)] = true
		end
	end
	if not string.isempty(suitHeroInitQuality) then
		local arr = string.split(suitHeroInitQuality,"|")
		suitHeroInitQualityList = {}
		for i, v in ipairs(arr) do
			suitHeroInitQualityList[tonumber(v)] = true
		end
	end
	if not string.isempty(suitGender) then
		local arr = string.split(suitGender,"|")
		suitGenderList = {}
		for i, v in ipairs(arr) do
			suitGenderList[tonumber(v)] = true
		end
	end
	if not string.isempty(suitHero) then
		local arr = string.split(suitHero,"|")
		suitHeroList = {}
		for i, v in ipairs(arr) do
			suitHeroList[tonumber(v)] = true
		end
	end

	local list = {}
	local heroList = gModelHero:GetHeroList()
	for i, v in pairs(heroList) do
		local hero = v:GetServerData()
		if hero.star >= unlockHeroStar then
			local refId = hero.refId
			local heroRef = gModelHero:GetHeroRef(refId)
			local raceType = heroRef.raceType
			local careerType = heroRef.careerType
			local quality = heroRef.quality
			local genderType = heroRef.genderType
			--种族限制
			if _raceType == 0 or raceType == _raceType then
				--条件限制:	种族限制 职业限制 品质限制 性别限制 英雄refId限制
				if ((not suitRaceList or suitRaceList[raceType])
						and (not suitCareerList or suitCareerList[careerType])
						and (not suitHeroInitQualityList or suitHeroInitQualityList[quality])
						and (not suitGenderList or suitGenderList[genderType]))
						or (suitHeroList and suitHeroList[refId])
				then
					table.insert(list,hero)
				end
			end
		end
	end
	table.sort(list,function (a,b)
		local aCardId = heroKeys[a.id] or 0
		local bCardId = heroKeys[b.id] or 0
		local isAWear = aCardId == _refId and 1 or 0
		local isBWear = bCardId == _refId and 1 or 0
		if isAWear ~= isBWear then
			return isAWear > isBWear
		end
		local alv = a.lv
		local blv = b.lv
		if alv ~= blv then
			return alv > blv
		end
		local astar = a.star
		local bstar = b.star
		if astar ~= bstar then
			return astar > bstar
		end
		return a.id > b.id
	end)
	return list
end
function UISorceryCardSpeedHero:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(29561))
	self:SetWndButtonText(self.mBtnUnload,ccClientText(29563))
	self:SetWndButtonText(self.mBtnWear,ccClientText(29564))
	CS.ShowObject(self.mRaceBg,true)

	local cardRefId = self:GetWndArg("refId")
	local heroId = self:GetWndArg("heroId")
	local ref = gModelSorceryCard:GetSorceryCardRefByRefId(cardRefId)
	self:SetWndText(self.mDesText,string.replace(ccClientText(29562),ccLngText(ref.equipLimitTxt)))
	self._refId = cardRefId
	self._equipLimit = ref.equipLimit
	self._heroId = heroId
	CS.ShowObject(self.mBtnUnload,heroId and tonumber(heroId) > 0)
	CS.ShowObject(self.mBtnWear,true)

	local list = gModelHero:GetHeroRaceRefList()
	table.insert(list,{refId = 0 ,icon = "public_race_0", rank = 0})
	table.sort(list,function (a,b)
		return a.rank < b.rank
	end)
	local _uiRaceList = self:GetUIScroll("raceType")
	_uiRaceList:Create(self.mRaceScroll,list,function (...) self:RaceListItem(...) end)
	self:OnClickRace(list[1].refId)
end
function UISorceryCardSpeedHero:OnClickUnload()
	local _heroInfo = self._heroInfo
	local _refId = self._refId
	local heroId = _heroInfo and _heroInfo.id or self._heroId
	if not heroId then
		self:WndClose()
	end
	local oldRefId = _heroInfo.sorceryCardId
	if not oldRefId or oldRefId <= 0 or oldRefId ~= _refId then
		GF.ShowMessage(ccClientText(29567))
		return
	end
	gModelSorceryCard:OnSorceryCardUnloadReq(_refId,heroId)
end

function UISorceryCardSpeedHero:RaceListItem(list,item, itemdata, itempos)
	local image = self:FindWndTrans(item,"Icon")
	local selImg = self:FindWndTrans(item,"SelImg")

	self._raceList[itemdata.refId] = selImg
	self:SetWndEasyImage(image,itemdata.icon)
	self:SetWndClick(item, function(...)
		self:OnClickRace(itemdata.refId)
	end)
end

function UISorceryCardSpeedHero:InitEvent()
	self:SetWndClick(self.mBgImage,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnUnload,function ()self:OnClickUnload() end)
	self:SetWndClick(self.mBtnWear,function ()self:OnClickWear() end)
end
------------------------------------------------------------------
return UISorceryCardSpeedHero


