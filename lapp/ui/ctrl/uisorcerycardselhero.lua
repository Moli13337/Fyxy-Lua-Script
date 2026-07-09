---
--- Created by BY.
--- DateTime: 2022/7/25 14:53:23
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISorceryCardSelHero:LWnd
local UISorceryCardSelHero = LxWndClass("UISorceryCardSelHero", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISorceryCardSelHero:UISorceryCardSelHero()
	self._raceList = {}
	self._heroIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISorceryCardSelHero:OnWndClose()
	self:ClearCommonIconList(self._heroIconList)
	--if gLGameTouch then gLGameTouch:TouchUnRegister(LGameTouch.TOUCH_BT_WNDCLOSE) end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISorceryCardSelHero:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISorceryCardSelHero:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UISorceryCardSelHero:OnClickSel()
	local _heroInfo = self._heroInfo
	local _refId = self._refId
	if not _heroInfo then
		self:WndClose()
		return
	end
	local heroId = _heroInfo.id
	local func = function()
		local isWear = gModelSorceryCard:VerifyLimitByCardIdAndHeroId(_refId,heroId)
		if not isWear then
			GF.ShowMessage(ccClientText(29537))
			return
		end
		local isTargetMapping = gModelResonance:CheckHeroInTargetMappingDict(heroId)
		local otherMapping = gModelResonance:GetMappingOtherId(heroId)
		local isMapping = not isTargetMapping and otherMapping
		local otherCanWear = otherMapping and ModelSorceryCard:CheckHeroCanWearByRefId(otherMapping,_refId) or nil
		if(isMapping and not otherCanWear)then
			local para = {
				refId = 10048,
				func = function()
					gModelSorceryCard:OnSorceryCardWearReq(_refId,heroId)
				end,
			}
			gModelGeneral:OpenUIOrdinTips(para)
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

function UISorceryCardSelHero:RefreshData()
	local list = self:GetHeroList() or {}

	local len = #list
	CS.ShowObject(self.mNoRecord2,len <= 0)
	if len <= 0 then
		self:CreateEmptyShow(10009)
	end
	local _heroUiList = self._heroUiList
	if _heroUiList then
		_heroUiList:RefreshList(list)
		_heroUiList:DrawAllItems()
	else
		_heroUiList = self:GetUIScroll("mHeroSuper_UISorceryCardSelHero")
		self._heroUiList = _heroUiList
		_heroUiList:Create(self.mHeroSuper,list,function (...) self:HeroListItem(...) end,UIItemList.SUPER_GRID)
		_heroUiList:EnableScroll(true,false)
	end
end
function UISorceryCardSelHero:InitMessage()
	self:WndNetMsgRecv(LProtoIds.SorceryCardWearResp,function(pb) self:WndClose() end)
	--self:WndNetMsgRecv("SorceryCardSwitchResp",function(pb) self:WndClose() end)
end

function UISorceryCardSelHero:InitEvent()
	self:SetWndClick(self.mBgImage,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnSel,function ()self:OnClickSel() end)
	--local op = LGameTouch.TOUCH_BT_WNDCLOSE
	--gLGameTouch:TouchRegister(op,LGameTouch.TOUCH_EVT_START,function (screenPos)
	--	self:WndClose()
	--end)
end

function UISorceryCardSelHero:GetHeroList()
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
function UISorceryCardSelHero:HeroListItem(list,item, itemdata, itempos)
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

function UISorceryCardSelHero:RaceListItem(list,item, itemdata, itempos)
	local image = CS.FindTrans(item,"Icon")
	local selImg = CS.FindTrans(item,"SelImg")

	self._raceList[itemdata.refId] = selImg
	self:SetWndEasyImage(image,itemdata.icon)
	self:SetWndClick(item, function(...)
		self:OnClickRace(itemdata.refId)
	end)
end
function UISorceryCardSelHero:InitCommand()
	self:SetWndButtonText(self.mBtnSel,ccClientText(11415))
	CS.ShowObject(self.mRaceBg,true)

	local cardRefId = self:GetWndArg("refId")
	local ref = gModelSorceryCard:GetSorceryCardRefByRefId(cardRefId)
	self:SetWndText(self.mDesText,string.replace(ccClientText(29512),ccLngText(ref.equipLimitTxt)))
	self._refId = cardRefId
	self._equipLimit = ref.equipLimit

	local list = gModelHero:GetHeroRaceRefList()
	table.insert(list,{refId = 0 ,icon = "public_race_0",rank=0})
	table.sort(list,function (a,b)
		return a.rank < b.rank
	end)
	local _uiRaceList = self:GetUIScroll("raceType")
	_uiRaceList:Create(self.mRaceScroll,list,function (...) self:RaceListItem(...) end)
	self:OnClickRace(list[1].refId)
end

function UISorceryCardSelHero:OnClickRace(type)
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
function UISorceryCardSelHero:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty1")
	emptyList:RefreshUI(data)
end
function UISorceryCardSelHero:OnClickHero(itemdata,isWear)
	if isWear then
		GF.ShowMessage(ccClientText(29536))
		return
	end
	self._heroInfo = itemdata
	local _heroUiList = self._heroUiList
	if not _heroUiList then return end
	_heroUiList:DrawAllItems()
end
------------------------------------------------------------------
return UISorceryCardSelHero


