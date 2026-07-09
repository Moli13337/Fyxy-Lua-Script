---
--- 养成映射-伙伴选择弹框
--- Created by Ease.
--- DateTime: 2023/10/7 17:45:06
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMlpingSelSaga:LWnd
local UIMlpingSelSaga = LxWndClass("UIMlpingSelSaga", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMlpingSelSaga:UIMlpingSelSaga()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMlpingSelSaga:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMlpingSelSaga:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMlpingSelSaga:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitBtnEvent()
	self:InitEvent()
	self:InitMessage()
	self:InitData()
end
function UIMlpingSelSaga:InitBtnEvent()
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mSureBtn,function() self:OnClickSureBtnBtn() end)
end
function UIMlpingSelSaga:OnDrawHeroCell(list,item,itemdata,itempos)
	local CommonUITrans = self:FindWndTrans(item,"CommonUI")
	local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")
	local HeroNameTrans = self:FindWndTrans(item,"HeroName")

	local id = itemdata:GetId()
	local refId = itemdata:GetRefId()
	local star = itemdata:GetStar()

	local isSel = self._selHeroId and self._selHeroId == id or false

	local instanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(IconTrans)
	local herodata = {
		trans = IconTrans,
		id = id,
		refId = refId,
		star = star,
		level = itemdata:GetLv(),
		skin = itemdata:GetSkin(),
		isResonance = itemdata:GetResonanceStatus(),
		endTime = itemdata:GetEndTime(),
		isTry = itemdata:IsTryHero(),
		selected = isSel
	}
	baseClass:SetHeroDataSet(herodata)
	baseClass:DoApply()

	local heroName = gModelHero:GetHeroNameByRefId(refId,star)
	self:SetWndText(HeroNameTrans,heroName)

	self:SetWndClick(IconTrans,function()
		self:OnClickHeroIconFunc(itemdata)
	end)
end
function UIMlpingSelSaga:InitEvent()

end
function UIMlpingSelSaga:InitEmptyList()
	local emptyPara = self._wndType == 1 and ccClientText(38413) or ccClientText(38414)
	local data = {
		refId = 35001,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
		para = {emptyPara}
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end
function UIMlpingSelSaga:GetHeroRace(heroData)
	if(not heroData)then
		return 0
	end
	local heroRefId = heroData:GetRefId()
	local heroRef = gModelHero:GetHeroRef(heroRefId)
	return heroRef.raceType
end
function UIMlpingSelSaga:InitData()
	self.mapData = self:GetWndArg("mapData")
	self._wndType = self:GetWndArg("wndType")
	self._slotRefId = self:GetWndArg("slotRefId")
	-- 【G公共支持】删除伙伴链接功能
	-- self._mainCfg = GameTable.LevelShareConfigRef
	-- self._raceLimit = self._mainCfg.heroRace
	-- self._heroStarLimit = self._mainCfg.heroStars
	self._raceType = 0

	if(self.mapData)then
		if(self._wndType == 1)then
			self._selHeroId = self.mapData.sourceHeroId
		else
			self._selHeroId = self.mapData.targetHeroId
		end
		self._selHeroId = self._selHeroId ~= "0" and self._selHeroId or nil
		if(self._wndType == 1)then
			self.otherSignHeroId = self.mapData.targetHeroId
		else
			self.otherSignHeroId = self.mapData.sourceHeroId
		end
		self.otherSignHeroId = self.otherSignHeroId ~= "0" and self.otherSignHeroId or nil
		if(self.otherSignHeroId)then
			local otherHeroData = gModelHero:GetHeroById(self.otherSignHeroId)
			local heroRef = gModelHero:GetHeroRef(otherHeroData:GetRefId())
			self.otherHeroRace = heroRef.raceType
			self.otherHeroCareer = heroRef.careerType
			local heroKeys = gModelSorceryCard:GetHeroKeys()
			local otherHeroCardWearId = heroKeys[otherHeroData:GetId()]
			self.otherHeroCardRef = gModelSorceryCard:GetSorceryCardRefByRefId(otherHeroCardWearId)
			self:BotDescTxt()
		end
	end
	self:SetHeroList()
	self:SetDefultUI()
	self:InitHeroRaceList()
end
function UIMlpingSelSaga:InitHeroRaceList()
	local data = {
		wndClass = self,
		listTrans = self.mHeroRaceList,
		--ignoreRaceList = {
		--	[ModelSpiritHero.SPIRITHERO_RACE] = true,
		--},
		showListBg = true,
		showType = UIHeroRaceList.TYPE_SHOWBG,
		callbackFunc = function(raceType)
			if not self:IsWndValid() then return end
			if raceType == self._raceType then return end
			self._raceType = raceType
			self:SetHeroList()
		end,
		checkSelFunc = function(raceType)
			if not self:IsWndValid() then return end
			return self._raceType == raceType
		end
	}
	self:GetUIHeroRaceList(data)
end

function UIMlpingSelSaga:OnClickHeroIconFunc(itemdata)
	local id = itemdata:GetId()
	self._selHeroId = self._selHeroId ~= id and id or nil
	self:SetHeroList(true)
end
function UIMlpingSelSaga:SetDefultUI()
	local titleIdx =self._wndType == 1 and 38413 or 38414
	self:SetWndText(self.mTitleTxt,ccClientText(titleIdx)..ccClientText(38415))
	self:SetWndText(self.mDescTxt,ccClientText(38419))
	self:SetWndText(self.mSureBtnTxt,ccClientText(38421))
	self:InitEmptyList()
end
-- 【G公共支持】删除伙伴链接功能
-- function UIMlpingSelSaga:ChecHeroCfgLimit(race,star)
-- 	local raceLimit = false
-- 	local raceLimitArr = string.split(self._raceLimit,",")
-- 	for i, v in ipairs(raceLimitArr) do
-- 		if(tonumber(v) == race)then
-- 			raceLimit = true
-- 		end
-- 	end
-- 	return raceLimit and star>=self._heroStarLimit
-- end
function UIMlpingSelSaga:SetHeroList(isClick)
	local tmpList = gModelHero:GetHeroList()
	local list = {}
	local heroKeys = gModelSorceryCard:GetHeroKeys()
	if(not isClick)then
		for i, v in pairs(tmpList) do
			local heroId = v:GetId()
			local heroRefId = v:GetRefId()
			local heroRef = gModelHero:GetHeroRef(heroRefId)
			local isUsed = gModelResonance:CheckHeroInMappings(heroId,self._selHeroId,true)
			-- 【G公共支持】删除伙伴链接功能
			-- local cfgLimit = self:ChecHeroCfgLimit(heroRef.raceType,v:GetStar())
			local raceLimit = self._raceType == 0 or heroRef.raceType == self._raceType
			local careerLimit =not self.otherHeroCareer or self.otherHeroCareer == heroRef.careerType
			--local isTry = v:IsTryHero()
			-- 【G公共支持】删除伙伴链接功能
			-- if(cfgLimit and not isUsed and raceLimit and careerLimit)then
			if(not isUsed and raceLimit and careerLimit)then
				local cardLimit = true
				if(self._wndType == 2 and self.otherHeroCardRef)then
					cardLimit = gModelSorceryCard:CheckHeroCanWearByRefId(heroId,self.otherHeroCardRef.refId)
				end
				local targetHeroCardWearId = heroKeys[heroId]
				local cardRef = gModelSorceryCard:GetSorceryCardRefByRefId(targetHeroCardWearId)
				local targetCardList = true
				if(self._wndType == 1 and cardRef and cardRef.refId and self.otherSignHeroId)then
					targetCardList = gModelSorceryCard:CheckHeroCanWearByRefId(self.otherSignHeroId,cardRef.refId)
				end
				if(cardLimit and targetCardList)then
					table.insert(list,v)
				end
			end
		end
	end
	self._heroList = (self._heroList and isClick)and self._heroList or list
	table.sort(self._heroList, function(a,b)
			local aRace = self:GetHeroRace(a)
			local bRace = self:GetHeroRace(b)
			return aRace<bRace
	end)
	local uiHeroList = self._uiHeroList
	if uiHeroList then
		if(isClick)then
			uiHeroList:RefreshData(self._heroList)
		else
			uiHeroList:RefreshList(self._heroList)
		end
	else
		uiHeroList = self:GetUIScroll("uiHeroList")
		self._uiHeroList = uiHeroList
		uiHeroList:Create(self.mHeroList,self._heroList,function(...) self:OnDrawHeroCell(...) end,UIItemList.WRAP)
	end
	local isEmpty = #self._heroList < 1
	CS.ShowObject(self.mNoRecord2,isEmpty)
end

function UIMlpingSelSaga:OnClickSureBtnBtn()
	local sourceHeroId = self._wndType == 1 and (self._selHeroId or 0) or (self.otherSignHeroId or 0)
	local targetHeroId = self._wndType == 2 and (self._selHeroId or 0) or (self.otherSignHeroId or 0)
	if((sourceHeroId and sourceHeroId~=0) or (targetHeroId and targetHeroId~=0))then
		local sourceEmpty = not sourceHeroId or sourceHeroId==0
		local targetEmpty = not targetHeroId or targetHeroId==0
		if(sourceEmpty or targetEmpty)then
			local typeStr = sourceEmpty and 38413 or 38414
			local showStr = string.replace(ccClientText(38417),ccClientText(typeStr)..ccClientText(38415))
			GF.ShowMessage(showStr)
		end
	end
	local cardRef = self.otherHeroCardRef
	if(targetHeroId and cardRef and targetHeroId~=0)then
		local canWear = gModelSorceryCard:CheckHeroCanWearByRefId(targetHeroId,cardRef.refId)
		if(not canWear)then
			local cardLimitStr = cardRef and ccLngText(cardRef.equipLimitTxt) or ""
			local botDescStr = not string.isempty(cardLimitStr) and string.replace(ccClientText(38416),cardLimitStr) or ""
			if(botDescStr and not string.isempty(botDescStr))then
				GF.ShowMessage(botDescStr)
			end
			return
		end
	end
	gModelResonance:OnResonanceCheckHeroMapReq(sourceHeroId,targetHeroId)
end
function UIMlpingSelSaga:BotDescTxt()
	local cardRef = self.otherHeroCardRef
	local cardLimitStr = cardRef and ccLngText(cardRef.equipLimitTxt) or ""
	local botDescStr = not string.isempty(cardLimitStr) and string.replace(ccClientText(38416),cardLimitStr) or ""
	CS.ShowObject(self.mDescTxtGroup,self._wndType == 2 and not string.isempty(botDescStr))
	self:SetWndText(self.mBotDescTxt,botDescStr)
end
function UIMlpingSelSaga:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ResonanceCheckHeroMapResp, function(pb)
		local isTogether = pb.type and pb.type == 1
		local sourceHeroId = self._wndType == 1 and (self._selHeroId or 0) or (self.otherSignHeroId or 0)
		local targetHeroId = self._wndType == 2 and (self._selHeroId or 0) or (self.otherSignHeroId or 0)
		local reqType = (sourceHeroId == 0 and targetHeroId == 0) and 2 or 1
		if(sourceHeroId and sourceHeroId~=0)then
			local otherHero = gModelResonance:GetMappingOtherId(sourceHeroId)
			reqType = (otherHero and (sourceHeroId == 0 or targetHeroId == 0)) and 2 or reqType
		end
			local mapInfo = {
				slotRefId = self._slotRefId,
				sourceHeroId = sourceHeroId,
				targetHeroId = targetHeroId,
			}
			if(isTogether)then
				local func = function()
					gModelResonance:OnResonanceHeroMapReq(reqType,mapInfo)
					self:WndClose()
				end
				local para = {
					refId = 10047,
					func = func,
				}
				gModelGeneral:OpenUIOrdinTips(para)
			else
				gModelResonance:OnResonanceHeroMapReq(reqType,mapInfo)
				self:WndClose()
			end
	end)
end

------------------------------------------------------------------
return UIMlpingSelSaga


