---
--- Created by Administrator.
--- DateTime: 2023/10/29 14:23:25
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaSpread:LWnd
local UISagaSpread = LxWndClass("UISagaSpread", LWnd)
local YXUIPointUtil = CS.YXUIPointUtil

UISagaSpread.DATA_TYPE_ATTR = 1
UISagaSpread.DATA_TYPE_OUTFIT = 2
UISagaSpread.DATA_TYPE_RUNEANDTALENT = 3

UISagaSpread.MAX_OUTFIT_NUM = 4
UISagaSpread.MAX_RUNE_NUM = 2
UISagaSpread.MAX_TALENT_NUM = 2

UISagaSpread.TYPE_OPEN_NORMAL = 1
UISagaSpread.TYPE_OPEN_BOSSTOWER = 3
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaSpread:UISagaSpread()
	---@type table<number, CommonIcon>
	self._commonUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaSpread:OnWndClose()
	self:ClearCommonIconList(self._commonUIList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaSpread:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaSpread:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitTxt()
	self:InitData()
	self:InitEvent()
	self:InitMsg()

	CS.ShowObject(self.mShareBtn,self._share)

	local wndType = self._wndType
	-- if wndType == UISagaSpread.TYPE_OPEN_BOSSTOWER then
	-- 	self:RefreshBossTowerView()
	-- else
		self:RefreshNormalView()
	-- end
end

function UISagaSpread:CreateStarList(star)
	local list = {}
	local img,showNum = gModelHero:GetHeroStarImg(star)
	for i = 1,showNum do
		table.insert(list,{
			show = true,
			img = img
		})
	end
	local uiStarList = self._uiStarList
	if uiStarList then
		uiStarList:RefreshList(list)
	else
		uiStarList = self:GetUIScroll("uiStarList")
		self._uiStarList = uiStarList
		uiStarList:Create(self.mStarList,list,function(...) self:OnDrawStarCell(...) end)
	end
end

function UISagaSpread:SetOutfitActivitySuit(index, data)
	local outfitHeroRefId = data.heroRefId
	local refId = self._heroData and self._heroData.refId
	local isActivity = refId ~= nil and outfitHeroRefId == refId
	local outfitMaskTrans = self._outfitMaskTransList[index]
	CS.ShowObject(outfitMaskTrans, not isActivity)
end

function UISagaSpread:OnBossTowerHeroPowerResp(pb)
	-- if self._sid ~= pb.sid then return end
	-- local fightPower = pb.power or 0
	-- fightPower = tonumber(fightPower)
	-- self:SetWndText(self.mPowerNumTxt,LUtil.FormatCoversionHurtNumSpriteText(fightPower,false, nil, 22))
	-- local level = tonumber(pb.level)
	-- local lvStr = string.replace(ccClientText(20129),level)
	-- self:SetWndText(self.mLvTxt,lvStr)
	-- local attrs = pb.attrs
	-- local attrList = {}
	-- for i,v in ipairs(attrs) do
	-- 	attrList[v.refId] = v.value
	-- end
	-- self:CreateAttrList(attrList)
	-- self:CreateSkillList(self:GetBossTowerSkillList())
	-- self:CreateOutfitList(self:GetBossTowerOutfitList(pb))
	-- self:CreateRuneAndTalent(self:GetBossTowerRuneListAndTalentList(pb))
	-- self:CreateAwakenList()
end

function UISagaSpread:OnClickSkill(skillId,index)
	-- if self._wndType == UISagaSpread.TYPE_OPEN_BOSSTOWER then
	-- 	self:ShowBossTowerSkillInfo(skillId,index)
	-- else
		self:ShowNormalSkillInfo(skillId,index)
	-- end
end

function UISagaSpread:InitNormalData()
	self._playerId = self:GetWndArg("playerId")
	if string.isempty(self._playerId) then
		self._playerId = gLGameLogin:GetPlayerId()
	end
	local heroData = self:GetWndArg("heroData")
	self._share = self:GetWndArg("share")
	self._shareFunc = self:GetWndArg("shareFunc")
	self._refId = self:GetWndArg("refId")
	self._star = self:GetWndArg("star")
	self._skin = self:GetWndArg("skin")
	self._serverId = self:GetWndArg("serverId")
	if not self._serverId then
		self._serverId = gLGameLogin:GetServerId()
	end
	self._heroData = heroData
	if heroData then
		self._heroId = heroData.id
		gModelHero:FindHeroPowStateById(self._heroId)
		gModelHeroBook:OnHeroBookInfoReq(self._playerId,heroData.refId,self._serverId)
	end
end

function UISagaSpread:ShowRaecKeZhiInfo()
	-- if self._wndType == UISagaSpread.TYPE_OPEN_BOSSTOWER then
	-- 	self:RefreshBossTowerRaceKeZhiInfo()
	-- else
		self:RefrsehNormalRaceKeZhiInfo()
	-- end
end

function UISagaSpread:InitData()
	local wndType = self:GetWndArg("wndType")
	if not wndType then
		wndType = UISagaSpread.TYPE_OPEN_NORMAL
	end
	self._wndType = wndType

	self._baseAttrList = {LAttrConst.Atk,LAttrConst.MaxHP,LAttrConst.Def,LAttrConst.Speed}
	self._equipTypeList = {1,3,2,4}
	self._runeRefIdList = {1001,1002}
	self._talentRefIdList = {2001,2002}
	self._classList = {}
	self._outfitMaskTransList = {
		self.mTypeMask1,
		self.mTypeMask2,
		self.mTypeMask3,
		self.mTypeMask4,
	}

	if self._refId then
		local maxLv = 0
		local ref = gModelHero:GetHeroRef(self._refId)
		self._ref = ref
		if not self._star then self._star = ref.initStar end
		local classType = ref.classType
		self._classType = classType
		for k,v in pairs(GameTable.CharacterClassRef) do
			if v.type == classType then
				if maxLv < v.needLevel then
					maxLv = v.needLevel
				end
				table.insert(self._classList,v)
			end
		end
		table.sort(self._classList,function(c1,c2)
			return c1.grade < c2.grade
		end)
		self._maxLv = maxLv
	end

	-- if wndType == UISagaSpread.TYPE_OPEN_BOSSTOWER then
	-- 	self:InitBossTowerData()
	-- else
		self:InitNormalData()
	-- end
end

function UISagaSpread:CreateRuneList(list)
	list = list or {}
	local uiRuneList = self._uiRuneList
	if uiRuneList then
		uiRuneList:RefreshList(list)
	else
		uiRuneList = self:GetUIScroll("uiRuneList")
		self._uiRuneList = uiRuneList
		uiRuneList:Create(self.mRuneList,list,function(...) self:OnDrawRuneCell(...) end)
	end
end

function UISagaSpread:RefreshHeroInfo(refId,star,skin,lv)
	self:CreateStarList(star)

	local lvStr = string.replace(ccClientText(20129),lv)
	self:SetWndText(self.mLvTxt,lvStr)

	local ref = gModelHero:GetHeroRef(refId)
	if not ref then return end

	local raceId = ref.raceType
	local raceRef = gModelHero:GetHeroRaceRefByRefId(raceId)
	if not raceRef then return end

	local careerType = ref.careerType
	local careerRef = gModelHero:GetCareerRefByRefId(careerType)
	if not careerRef then return end

	local effRef = self:GetEffRef(refId,star,skin)
	self._effRef= effRef
	if effRef then
		local location = "[" .. ccLngText(effRef.location) .. "]"
		self:SetWndText(self.mJobEffTxt,location)
	end

	local careerName,careerImg = ccLngText(careerRef.name),careerRef.jobIcon
	self:SetWndText(self.mJobName,careerName)
	self:SetWndEasyImage(self.mJobImg,careerImg)

	local heroShareBg = raceRef.heroShareBg
	self:SetWndEasyImage(self.mHeroShareImg,heroShareBg,function() CS.ShowObject(self.mHeroShareImg,true) end)

	local qualityIcon = ref.qualityIcon
	self:SetWndEasyImage(self.mHeroZZImg,qualityIcon,function()
		CS.ShowObject(self.mHeroZZImg,true)
	end)

	local name = gModelHero:GetHeroNameByRefId(refId,star)
	self:SetWndText(self.mHeroName,name)

	local raceImg = raceRef.icon
	self:SetWndEasyImage(self.mHeroRaceImg,raceImg,function() CS.ShowObject(self.mHeroRaceImg,true) end)

	local quality = gModelHero:GetHeroQualityByRefId(refId,star)
	local qualityRef = gModelItem:GetQualityRef(quality)
	if qualityRef then
		local heroMsgNameBg = qualityRef.heroMsgNameBg
		self:SetWndEasyImage(self.mHeroQuaImg,heroMsgNameBg,function() CS.ShowObject(self.mHeroQuaImg,true) end)
	end

	self:CreateSp(refId,star,skin)
end

function UISagaSpread:RefreshBossTowerView()
	-- local bossTowerRef = self._bossTowerRef
	-- if not bossTowerRef then return end
	-- local heroRefId = bossTowerRef.type
	-- local star = gModelBossTower:GetHeroStarByRefId(self._bossTowerHeroRefId)
	-- local bossTowerServerData = self._bossTowerServerData
	-- local lv
	-- if bossTowerServerData then
	-- 	lv = bossTowerServerData.breakLv
	-- end
	-- if not lv then
	-- 	local monsterRef = gModelHero:GetMonsterAttrByRefId(bossTowerRef.attr)
	-- 	if monsterRef then
	-- 		lv = monsterRef.lv
	-- 	else
	-- 		lv = 0
	-- 	end
	-- end
	-- self:RefreshHeroInfo(heroRefId,star,0,lv)
	-- gModelBossTower:OnBossTowerHeroPowerReq(self._sid,self._bossTowerHeroRefId,self._playerId)
end

function UISagaSpread:CreateSp(refId,star,skin)
	local effRef = self:GetEffRef(refId,star,skin)
	if not effRef then return end

	local prefabName = effRef.prefabName
	self:CreateWndSpine(self.mHeroSPPos,prefabName,prefabName,false,function(dpSpine)
		dpSpine:SetScale(2)
	end)
end

function UISagaSpread:OnDrawAttrCell(list,item,itemdata,itempos)
	local refId = itemdata.refId
	local value = itemdata.value
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	if AttrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon,function()
			CS.ShowObject(AttrIcon,true)
		end)
	end
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	if AttrValue then
		local ref = gModelHero:GetAttributeRefById(refId)
		local numType,saveNum
		if ref then
			numType,saveNum = ref.numType,ref.saveNum
		else
			numType,saveNum = 1,0
		end
		if saveNum == 0 then
			value = math.floor(value + 0.5)
		else
			local tempPow = 10 ^ saveNum
			local temp = math.floor(value * tempPow + 0.5)
			value = temp / tempPow
		end
		if numType == 2 then
			value = value * 100 .. "%"
		end
		self:SetWndText(AttrValue,value)
	end
end

function UISagaSpread:ShowOutfitSultWnd()
	local heroData = self._heroData
	local refId = heroData and heroData.refId
	local outfitType = gModelHero:GetHeroOutfitTypeByHeroRefId(refId)
	if outfitType == 0 then return end
	local outfitList = self._curOutfitList or {}
	GF.OpenWnd("WndOutfitSultShowNew",{heroData = heroData,outfitList = outfitList})
end

function UISagaSpread:CreateAwakenList(skillList)
	local skillNum = skillList and #skillList or 0
	local isShowAwaken = skillNum > 0

	CS.ShowObject(self.mAwaken, isShowAwaken)
	if not isShowAwaken then
		return
	end

	local uiSkillList = self._uiAwakenSkillList
	if uiSkillList then
		uiSkillList:RefreshList(skillList)
	else
		uiSkillList = self:GetUIScroll("uiAwakenSkillList")
		self._uiAwakenSkillList = uiSkillList
		uiSkillList:Create(self.mAwakenSkillList,skillList,function(...) self:OnDrawAwakenSkillCell(...) end)
	end
end

function UISagaSpread:RefreshBossTowerRaceKeZhiInfo()
	-- local bossTowerRef = self._bossTowerRef
	-- if not bossTowerRef then return end
	-- if bossTowerRef then
	-- 	local canvasRect = LGameUI.GetUICanvasRoot()
	-- 	if not self._changePos then
	-- 		local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect,self.mTypeImgBg)
	-- 		self.mTypeImgBg.localPosition = targetPos - Vector3.New(0,0,0)
	-- 		self._changePos = true
	-- 	end
	-- 	local heroRefId = bossTowerRef.type
	-- 	local raceType = gModelHero:GetHeroType(heroRefId)
	-- 	if raceType then
	-- 		local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
	-- 		if raceRef then
	-- 			local heroRaceImage = raceRef.heroRaceImage
	-- 			self:SetWndEasyImage(self.mTypeKeZhiImg,heroRaceImage,function()
	-- 				CS.ShowObject(self.mTypeKeZhiImg,true)
	-- 			end,true)
	-- 			local name = string.replace(ccClientText(10079),ccLngText(raceRef.name))
	-- 			self:SetWndText(self.mRaceTypeName,name)
	-- 		end
	-- 	end
	-- end
end

function UISagaSpread:CreatedAwakenSkill(serverData)
	local skillId = serverData.skillId
	if skillId and skillId > 0 then
		local data = {
			skillId = skillId,
		}
		return data
	end

	return nil
end

function UISagaSpread:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mHeroZZImg,function() GF.OpenWndTop("UISagaQualitySow") end)
	self:SetWndClick(self.mHeroRaceImg,function()
		CS.ShowObject(self.mTypeImgMask,true)
		self:ShowRaecKeZhiInfo()
	end)
	self:SetWndClick(self.mTypeImgMask,function()
		CS.ShowObject(self.mTypeImgMask,false)
	end)
	self:SetWndClick(self.mShareBtn,function()
		if self._shareFunc then self._shareFunc() end
	end)

	self:SetWndClick(self.mOutfitBg,function() self:ShowOutfitSultWnd() end)
end

function UISagaSpread:RefrsehNormalRaceKeZhiInfo()
	local heroData = self._heroData
	if not heroData then return end
	local canvasRect = LGameUI.GetUICanvasRoot()
	if not self._changePos then
		local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect,self.mTypeImgBg)
		self.mTypeImgBg.localPosition = targetPos - Vector3.New(0,0,0)
		self._changePos = true
	end
	local refId = heroData.refId
	local raceType = gModelHero:GetHeroType(refId)
	if raceType then
		local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
		if raceRef then
			local heroRaceImage = raceRef.heroRaceImage
			self:SetWndEasyImage(self.mTypeKeZhiImg,heroRaceImage,function()
				CS.ShowObject(self.mTypeKeZhiImg,true)
			end,true)
			local name = string.replace(ccClientText(10079),ccLngText(raceRef.name))
			self:SetWndText(self.mRaceTypeName,name)
		end
	end
end

function UISagaSpread:GetEffRef(refId,star,skin)
	local showEffId
	if skin and skin > 0 then
		showEffId = skin
	else
		showEffId = gModelHero:GetHeroEffectByRefId(refId,star)
	end
	local effRef = gModelHero:GetShowEffectById(showEffId)
	return effRef
end

function UISagaSpread:RefreshNormalView()
	local heroData = self._heroData
	if not heroData then return	end

	local refId = heroData.refId
	local star = heroData.star
	local skin = heroData.skin
	local lv = heroData.lv or heroData.level
	self:RefreshHeroInfo(refId,star,skin,lv)


	local fightPower = heroData.fightPower or 0
	self:SetWndText(self.mPowerNumTxt,LUtil.FormatCoversionHurtNumSpriteText(fightPower,false, nil, 22))

	self:CreateAttrList(self:GetHeroInfoByType(UISagaSpread.DATA_TYPE_ATTR) or {})
	self:CreateSkillList(self:GetNormalSkillList())
	self:CreateOutfitList(self:GetNormalOutfitList())
	self:CreateRuneAndTalent(self:GetNormalRuneListAndTalentList())
	self:CreateAwakenList(self:GetNormalAwakenSkillList())
end

function UISagaSpread:OnDrawTalentCell(list,item,itemdata,itempos)
	local isLock = itemdata.isLock
	local skillId = itemdata.skillId
	local talentData = itemdata.talentData
	local unlockTxt = itemdata.unlockTxt
	local index = itemdata.index
	local Root = self:FindWndTrans(item,"Root")
	if Root then
		local SkillIconTrans = self:FindWndTrans(Root,"SkillIcon")
		local baseClass = SkillIcon:New(self)
		baseClass:ShowLock(isLock)
		if not isLock then
			baseClass:ShowAdd(talentData == nil)
		else
			baseClass:ShowAdd(false)
		end
		baseClass:Create(SkillIconTrans,skillId,function()
			if isLock then
				GF.ShowMessage(ccClientText(10135))
			else
				if skillId == index then
					GF.ShowMessage(ccClientText(10136))
				else
					if talentData then
						local ref = gModelRune:GetSkillInfoByRefId(talentData)
						if talentData then
							local lv = ref.skillLevel
							local other = {lv = lv}
							GF.OpenWndTop("UIJNInfo",{skillId = skillId,other = other})
							return
						end
					end
					GF.ShowMessage(ccClientText(10136))
				end
			end
		end)
	end
end

function UISagaSpread:OnDrawStarCell(list,item,itemdata,itempos)
	local Star = self:FindWndTrans(item,"Star")
	if Star then
		self:SetWndEasyImage(Star,itemdata.img,function() CS.ShowObject(Star,true) end)
	end
end

function UISagaSpread:InitBossTowerData()
	-- self._bossTowerHeroRefId = self:GetWndArg("bossTowerHeroRefId")
	-- self._sid = self:GetWndArg("sid")
	-- self._bossTowerRef = gModelBossTower:GetBossTowerHeroRefByRefId(self._bossTowerHeroRefId)
	-- self._bossTowerServerData = self:GetWndArg("bossTowerServerData")
	-- self._playerId = self:GetWndArg("playerId")
	-- if string.isempty(self._playerId) then
	-- 	self._playerId = gLGameLogin:GetPlayerId()
	-- end
end

function UISagaSpread:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ChatShareResp,function(pb)
		if self._wndType == UISagaSpread.TYPE_OPEN_NORMAL then
			self:WndClose()
		end
	end)
	self:WndNetMsgRecv(LProtoIds.PowerShowResp,function(pb,ret)
		if self._wndType ~= UISagaSpread.TYPE_OPEN_NORMAL then return end
		if not self._heroId then return end
		local showType = pb.type
		if showType == 2 then
			local _powers = pb.powers
			for i, v in ipairs(_powers) do
				local key = v.key
				if key == self._heroId then
					local power = v.power
					self:SetWndText(self.mPowerNumTxt,LUtil.FormatCoversionHurtNumSpriteText(power,false, nil, 22))
				end
			end
		end
	end)

	self:WndNetMsgRecv(LProtoIds.HeroBookInfoResp,function(pb,ret)
		local playerId = pb.playerId
		if self._playerId ~= playerId then return end
		local heroRefId = pb.heroRefId
		local heroData = self._heroData
		if not heroData then return end
		local refId = heroData.refId
		if refId ~= heroRefId then return end
		local closeGrade = pb.closeGrade
		self:CreateQMDJList(closeGrade,heroRefId)
	end)

	-- self:WndNetMsgRecv(LProtoIds.BossTowerHeroPowerResp,function(pb,ret)
	-- 	self:OnBossTowerHeroPowerResp(pb)
	-- end)
end

function UISagaSpread:CreateOutfitList(list)
	local effRef = self._effRef
	local heroType = effRef.heroType
	local outfitType = gModelHero:GetHeroOutfitTypeByHeroRefId(heroType)
	local showSuit = outfitType ~= 0 and self._wndType ~= UISagaSpread.TYPE_OPEN_BOSSTOWER

	CS.ShowObject(self.mOutfitBg, showSuit)
	if showSuit then
		--local heroRoundIcon = effRef.heroRoundIcon
		--self:SetWndEasyImage(self.mOutfitHeroIcon,heroRoundIcon,function()
		--	CS.ShowObject(self.mOutfitHeroIcon,true)
		--end)

		for k,v in ipairs(list) do
			self:SetOutfitActivitySuit(k, v)
		end

		self:InitOutfitActivityList(list)
	end

	CS.ShowObject(self.mOutfitList, not showSuit)
	CS.ShowObject(self.mOutfitListRight, showSuit)
	local uiOutfitList = self._uiOutfitList
	if uiOutfitList then
		uiOutfitList:RefreshList(list)
	else
		uiOutfitList = self:GetUIScroll("uiOutfitList")
		self._uiOutfitList = uiOutfitList

		local outfitTrans = showSuit and self.mOutfitListRight or self.mOutfitList
		uiOutfitList:Create(outfitTrans,list,function(...) self:OnDrawOutfitCell(...) end)
	end
end

function UISagaSpread:CreateQMDJList(dj,heroRefId)
	local list = {}
	local closeLv = gModelHeroBook:GetHeroCloseLv(heroRefId)
	for i = 1, closeLv do
		local actStar = dj >= i
		table.insert(list, { actStar = actStar })
	end
	local uiQMDJList = self._uiQMDJList
	if uiQMDJList then
		uiQMDJList:RefreshList(list)
	else
		uiQMDJList = self:GetUIScroll("uiQMDJList")
		self._uiQMDJList = uiQMDJList
		uiQMDJList:Create(self.mQmDJList, list, function(...)
			self:OnDrawQMDCell(...)
		end)
	end
end

function UISagaSpread:GetBossTowerOutfitList(pb)
	local list = {}
	-- local outfitList = pb.outfitList or {}
	-- for i = 1,UISagaSpread.MAX_OUTFIT_NUM do
	-- 	local serverData = outfitList[i]
	-- 	local ishave = true
	-- 	if not serverData then
	-- 		ishave = false
	-- 		serverData = {refId = i}
	-- 	elseif type(serverData) ~= "table" then
	-- 		ishave = false
	-- 		serverData = {refId = i}
	-- 	end
	-- 	local data = table.clone(serverData)
	-- 	data.ishave = ishave
	-- 	data.index = i
	-- 	data.outfitList = outfitList
	-- 	table.insert(list,data)
	-- end
	return list
end

function UISagaSpread:OnDrawRuneCell(list,item,itemdata,itempos)
	local InstanceID = item:GetInstanceID()
	local isLock,unlockTxt = itemdata.isLock,itemdata.unlockTxt
	local Root = self:FindWndTrans(item,"Root")
	if Root then
		local commonUIList = self._commonUIList
		if not commonUIList then
			commonUIList = {}
			self._commonUIList = commonUIList
		end
		local baseClass = commonUIList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New()
			commonUIList[InstanceID] = baseClass
			baseClass:Create(Root)
		end
		baseClass:SetRuneData(itemdata)
		baseClass:SetRuneLock(isLock,unlockTxt)
		baseClass:DoApply()

		self:SetWndClick(Root,function()
			if isLock then
				GF.ShowMessage(ccClientText(10139))
			else
				if itemdata.id ~= nil then
					local data = {runeData = itemdata}
					gModelGeneral:OpenRuneInfoTip(data)
				else
					GF.ShowMessage(ccClientText(10140))
				end
			end
		end)
	end

	local Mask = self:FindWndTrans(item,"Mask")
	if Mask then
		local MaskTxt = self:FindWndTrans(Mask,"MaskTxt")
		if MaskTxt then
			local maskTxt = ""
			if isLock then
				maskTxt = unlockTxt
			end
			self:SetWndText(MaskTxt,maskTxt)
		end
	end
	CS.ShowObject(Mask,isLock)
end

function UISagaSpread:CreateAttrList(attrList)
	local list = {}
	local baseAttrList = self._baseAttrList
	for i,v in ipairs(baseAttrList) do
		table.insert(list,{
			refId = v,
			value = attrList[v] or 0,
		})
	end

	local uiAttrList = self._uiAttrList
	if uiAttrList then
		uiAttrList:RefreshList(list)
	else
		uiAttrList = self:GetUIScroll("uiAttrList")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mAttrList,list,function(...) self:OnDrawAttrCell(...) end)
	end
end

function UISagaSpread:OnDrawAwakenSkillCell(list,item,itemdata,itempos)
	local skillId = itemdata.skillId
	local Root = self:FindWndTrans(item,"Root")
	if Root then
		local SkillIconTrans = self:FindWndTrans(Root,"SkillIcon")
		local baseClass = SkillIcon:New(self)
		if skillId then
			baseClass:SetSkillInfo(nil,false,nil,1)
			baseClass:Create(SkillIconTrans,skillId,function()
				gModelGeneral:OpenSkillWnd({curSkillId = skillId,wndType = 2})
				--GF.OpenWnd("UINewJNTip",{curSkillId = skillId,wndType = 2})
			end)
		else
			baseClass:SetShowIcon(false,false)
			baseClass:SetSkillInfo(nil,nil,nil,1)
			baseClass:Create(SkillIconTrans,0,function() end)
		end

		if not skillId then
			baseClass:SetIconAndIconBgGray(false)
		end
	end
end

function UISagaSpread:CreateSkillList(list)
	local uiSkillList = self._uiSkillList
	if uiSkillList then
		uiSkillList:RefreshList(list)
	else
		uiSkillList = self:GetUIScroll("uiSkillList")
		self._uiSkillList = uiSkillList
		uiSkillList:Create(self.mSkillList,list,function(...) self:OnDrawSkillCell(...) end)
	end
end

function UISagaSpread:InitTxt()
	self:SetWndText(self.mSkillTxt,ccClientText(20130))
	self:SetWndText(self.mOutfitTxt,ccClientText(20131))
	self:SetWndText(self.mRuneTxt,ccClientText(20132))
	self:SetWndText(self.mGiftTxt,ccClientText(20133))
	self:SetWndText(self.mAwakenTxt,ccClientText(20137))
	self:SetWndText(self.mKeZhiGuanXiTxt,ccClientText(10080))
	self:SetWndButtonText(self.mShareBtn,ccClientText(10118))
end

function UISagaSpread:OnDrawSkillCell(list,item,itemdata,itempos)
	local skillId,openClass = itemdata.skillId,itemdata.openClass
	local grade = itemdata.grade
	local refId,star,index = itemdata.refId,itemdata.star,itemdata.index
	local Root = self:FindWndTrans(item,"Root")
	if Root then
		local SkillIconTrans = self:FindWndTrans(Root,"SkillIcon")
		local baseClass = SkillIcon:New(self)
		if skillId then
			baseClass:SetSkillInfo(grade,false,openClass,1)
			baseClass:Create(SkillIconTrans,skillId,function() self:OnClickSkill(skillId,index) end)
		else
			baseClass:SetShowIcon(false,false)
			baseClass:SetSkillInfo(nil,nil,nil,1)
			baseClass:Create(SkillIconTrans,0,function() end)
		end
		if not skillId then
			baseClass:SetIconAndIconBgGray(false)
		end
	end
end

function UISagaSpread:ShowBossTowerSkillInfo(skillId,index)
	-- local bossTowerRef = self._bossTowerRef
	-- if not bossTowerRef then return end
	-- local monsterRefId = bossTowerRef.attr
	-- local monsterRef = gModelHero:GetMonsterAttrByRefId(monsterRefId)
	-- local star = monsterRef and monsterRef.starLv or 0
	-- local heroRefId = bossTowerRef.type
	-- local heroData = {
	-- 	refId = heroRefId,
	-- 	grade = gModelHero:GetClassGradeByRefIdAndStar(heroRefId,star)
	-- }
	-- gModelGeneral:OpenHeroSkillWnd({curSkillId = skillId,curSkillIdx = index,heroData = heroData})
end

function UISagaSpread:GetBossTowerRuneListAndTalentList(pb)
	-- local bossTowerRef = self._bossTowerRef
	-- if not bossTowerRef then
	-- 	return {},{}
	-- end
	-- local monsterRefId = bossTowerRef.attr
	-- local monsterRef = gModelHero:GetMonsterAttrByRefId(monsterRefId)
	-- --local lv = monsterRef and monsterRef.lv or 0
	-- local bossTowerServerData = self._bossTowerServerData
	-- local lv
	-- if bossTowerServerData then
	-- 	lv = bossTowerServerData.breakLv
	-- end
	-- if not lv then
	-- 	if monsterRef then
	-- 		lv = monsterRef.lv
	-- 	else
	-- 		lv = 0
	-- 	end
	-- end
	-- local star = monsterRef and monsterRef.starLv or 0
	-- local runeList = pb.runelist or {}
	-- local tRuneList = {}
	-- local runeRefIdList = self._runeRefIdList
	-- for i = 1,UISagaSpread.MAX_RUNE_NUM do
	-- 	local runeRefId = runeRefIdList[i]
	-- 	local isLock = true
	-- 	local runePosRef = GameTable.MagicRunePosRef[runeRefId]
	-- 	local unlock = runePosRef.unlock
	-- 	local unlockTxt = ccLngText(runePosRef.text)
	-- 	unlock = string.split(unlock,"=")
	-- 	local condition
	-- 	if tonumber(unlock[1]) == 1 then
	-- 		condition = lv
	-- 	else
	-- 		condition = star
	-- 	end
	-- 	if condition >= tonumber(unlock[2]) then isLock = false end
	-- 	local runeData = runeList[i]
	-- 	local serverData = {}
	-- 	if runeData then serverData = runeData:GetServerData() end
	-- 	serverData.isLock = isLock
	-- 	serverData.unlockTxt = unlockTxt
	-- 	table.insert(tRuneList,serverData)
	-- end

	-- local talentList = pb.talentList or {}
	-- local tTalentList = {}
	-- local talentRefIdList = self._talentRefIdList
	-- for i = 1,UISagaSpread.MAX_TALENT_NUM do
	-- 	local pos = i + 2
	-- 	local talentRefId = talentRefIdList[i]
	-- 	local isLock = true
	-- 	local runePosRef = GameTable.MagicRunePosRef[talentRefId]
	-- 	local unlock = runePosRef.unlock
	-- 	local unlockTxt = ccLngText(runePosRef.text)
	-- 	unlock = string.split(unlock,"=")
	-- 	local condition
	-- 	if tonumber(unlock[1]) == 1 then
	-- 		condition = lv
	-- 	else
	-- 		condition = star
	-- 	end
	-- 	if condition >= tonumber(unlock[2]) then isLock = false end
	-- 	local skillId = i
	-- 	local talentData = talentList[pos]
	-- 	if not isLock and talentData ~= nil then
	-- 		local ref = gModelRune:GetSkillInfoByRefId(talentData)
	-- 		skillId = tonumber(ref.SkillId)
	-- 	end
	-- 	local serverData = {
	-- 		isLock = isLock,
	-- 		skillId = skillId,
	-- 		index = i,
	-- 		unlockTxt = unlockTxt,
	-- 		talentData = talentData,
	-- 	}
	-- 	table.insert(tTalentList,serverData)
	-- end

	return {},{}
end

function UISagaSpread:GetNormalOutfitList()
	local list = {}
	local outfitList = self:GetHeroInfoByType(UISagaSpread.DATA_TYPE_OUTFIT)
	self._curOutfitList = outfitList or list
	if not outfitList then return list end
	for i = 1,UISagaSpread.MAX_OUTFIT_NUM do
		local serverData = outfitList[i]
		local ishave = true
		if not serverData then
			ishave = false
			serverData = {refId = i}
		elseif type(serverData) ~= "table" then
			ishave = false
			serverData = {refId = i}
		end
		local data = table.clone(serverData)
		data.ishave = ishave
		data.index = i
		data.outfitList = outfitList
		table.insert(list,data)
	end
	return list
end

function UISagaSpread:ShowNormalSkillInfo(skillId,index)
	local heroData = self._heroData
	if not heroData then return end
	gModelGeneral:OpenHeroSkillWnd({curSkillId = skillId,curSkillIdx = index,heroData = heroData})
end

function UISagaSpread:CreateTalentList(list)
	list = list or {}
	local uiTalentList = self._uiTalentList
	if uiTalentList then
		uiTalentList:RefreshList(list)
	else
		uiTalentList = self:GetUIScroll("uiTalentList")
		self._uiTalentList = uiTalentList
		uiTalentList:Create(self.mGiftList,list,function(...) self:OnDrawTalentCell(...) end)
	end
end

function UISagaSpread:CreateRuneAndTalent(tRuneList,tTalentList)
	self:CreateRuneList(tRuneList)
	self:CreateTalentList(tTalentList)
end

function UISagaSpread:GetBossTowerSkillList()
	local list = {}
	-- local bossTowerRef = self._bossTowerRef
	-- if bossTowerRef then
	-- 	local heroRefId = bossTowerRef.type
	-- 	local star = gModelBossTower:GetHeroStarByRefId(self._bossTowerHeroRefId)
	-- 	local heroSkillIdList = gModelHero:GetSkillListByRefIdAndStar(heroRefId,star)
	-- 	for i = 1,4 do
	-- 		local skillData = heroSkillIdList[i]
	-- 		local data = {
	-- 			grade = bossTowerRef.grade,
	-- 			refId = heroRefId,
	-- 			star = star,
	-- 			index = i,
	-- 		}
	-- 		if skillData then
	-- 			data.skillId = skillData.skillId
	-- 			data.openClass = skillData.openClass
	-- 		end
	-- 		table.insert(list,data)
	-- 	end
	-- end
	return list
end

function UISagaSpread:OnDrawQMDCell(list, item, itemdata, itempos)
	local Star = self:FindWndTrans(item, "Star")
	if Star then
		local actStar = not itemdata.actStar
		self:SetWndImageGray(Star, actStar)
	end
end

function UISagaSpread:GetNormalRuneListAndTalentList()
	local heroData = self._heroData
	if not heroData then return {},{} end

	local runeList,talentList = self:GetHeroInfoByType(UISagaSpread.DATA_TYPE_RUNEANDTALENT)
	runeList = runeList or {}
	talentList = talentList or {}

	local tRuneList = {}
	local runeRefIdList = self._runeRefIdList
	for i = 1,UISagaSpread.MAX_RUNE_NUM do
		local runeRefId = runeRefIdList[i]
		local isLock = true
		local runePosRef = GameTable.MagicRunePosRef[runeRefId]
		local unlock = runePosRef.unlock
		local unlockTxt = ccLngText(runePosRef.text)
		unlock = string.split(unlock,"=")
		local condition
		if tonumber(unlock[1]) == 1 then
			condition = heroData.lv or heroData.level
		else
			condition = heroData.star
		end
		if condition >= tonumber(unlock[2]) then isLock = false end
		local runeData = runeList[i]
		local serverData = {}
		if runeData then serverData = runeData:GetServerData() end
		serverData.isLock = isLock
		serverData.unlockTxt = unlockTxt
		table.insert(tRuneList,serverData)
	end

	local tTalentList = {}
	local talentRefIdList = self._talentRefIdList
	for i = 1,UISagaSpread.MAX_TALENT_NUM do
		local pos = i + 2
		local talentRefId = talentRefIdList[i]
		local isLock = true
		local runePosRef = GameTable.MagicRunePosRef[talentRefId]
		local unlock = runePosRef.unlock
		local unlockTxt = ccLngText(runePosRef.text)
		unlock = string.split(unlock,"=")
		local condition
		if tonumber(unlock[1]) == 1 then
			condition = heroData.lv or heroData.level
		else
			condition = heroData.star
		end
		if condition >= tonumber(unlock[2]) then isLock = false end
		local skillId = i
		local talentData = talentList[pos]
		if not isLock and talentData ~= nil then
			local ref = gModelRune:GetSkillInfoByRefId(talentData)
			skillId = tonumber(ref.SkillId)
		end
		local serverData = {
			isLock = isLock,
			skillId = skillId,
			index = i,
			unlockTxt = unlockTxt,
			talentData = talentData,
		}
		table.insert(tTalentList,serverData)
	end

	return tRuneList,tTalentList
end

function UISagaSpread:OnDrawOutfitActCell(list,item,itemdata,itempos)
	local ActivityImg = self:FindWndTrans(item,"ActivityImg")
	local isAct = itemdata.isAct
	CS.ShowObject(ActivityImg,isAct)
end


function UISagaSpread:GetNormalAwakenSkillList()
	local heroData = self._heroData
	if not heroData then return end

	local treeInfo = heroData.treeInfo
	if treeInfo and treeInfo.treeRefId then
		local points = treeInfo.points
		local awakenSkillList = {}
		for i, v in ipairs(points) do
			local awakenSkill = self:CreatedAwakenSkill(v)
			if awakenSkill then
				table.insert(awakenSkillList,awakenSkill)
			end
		end
		return awakenSkillList
	end

	return nil
end

function UISagaSpread:InitOutfitActivityList(list)
	local refId = self._heroData and self._heroData.refId
	--local actList = gModelOutfit:GetOutfitSetActList(list,refId)
	-- local actList = gModelOutfit:GetOutfitZSActList(list,refId)
	local actList = {}
	local uiOutfitActivityList = self._uiOutfitActivityList
	if uiOutfitActivityList then
		uiOutfitActivityList:RefreshList(actList)
	else
		uiOutfitActivityList = self:GetUIScroll("uiOutfitActivityList")
		self._uiOutfitActivityList = uiOutfitActivityList
		uiOutfitActivityList:Create(self.mOutfitActivityStatusList,actList,function(...) self:OnDrawOutfitActCell(...) end)
	end
end

function UISagaSpread:OnDrawOutfitCell(list,item,itemdata,itempos)
	local InstanceID = item:GetInstanceID()
	local EffRoot = self:FindWndTrans(item,"EffRoot")
	local effKey = "OutfitKey" .. itemdata.index
	local CommonUI = self:FindWndTrans(item,"Root")
	if CommonUI then
		self:DestroyWndEffectByKey(effKey)
		local commonUIList = self._commonUIList
		if not commonUIList then
			commonUIList = {}
			self._commonUIList = commonUIList
		end
		local baseClass = commonUIList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New()
			commonUIList[InstanceID] = baseClass
			baseClass:Create(CommonUI)
		end
		local ishave = itemdata.ishave
		if ishave then
			baseClass:SetOutfitData(itemdata)
			local outfitHeroRefId = itemdata.heroRefId
			local refId = self._heroData and self._heroData.refId
			if outfitHeroRefId == refId then
				self:CreateWndEffect(EffRoot,"fx_ui_zhuanshuzhuangbei",effKey,100,false,false,21)
			end
		else
			baseClass:SetCommonReward(LItemTypeConst.TYPE_OUTFIT, itemdata.refId, nil)
		end
		self:SetIconClickScale(CommonUI, true)
		self:SetWndClick(CommonUI,function()
			local heroData = self._heroData
			if ishave then
				gModelGeneral:OpenOutfitInfoTip({heroData = heroData,curSerData = itemdata,outfitType = 2},true)
			else
				GF.ShowMessage(ccClientText(10138))
			end
		end)
		baseClass:DoApply()
	end
end

function UISagaSpread:GetNormalSkillList()
	local list = {}
	local heroData = self._heroData
	if not heroData then return end
	local refId,star = heroData.refId,heroData.star
	local heroSkillIdList = gModelHero:GetSkillListByRefIdAndStar(refId,star)
	for i = 1,4 do
		local skillData = heroSkillIdList[i]
		local data = {
			grade = heroData.grade,
			refId = refId,
			star = star,
			index = i,
		}
		if skillData then
			data.skillId = skillData.skillId
			data.openClass = skillData.openClass
		end
		table.insert(list,data)
	end
	return list
end

function UISagaSpread:GetHeroInfoByType(gType)
	local heroData = self._heroData
	if not heroData then return end
	local id = heroData.id
	local heroAttrList,heroWearEquipList,heroWearRuneList,heroWearTalentList,heroWearOutfitList = gModelHero:GetHeroAttrAndEquipInfoById(id)
	local isEmptyAttrList = table.isempty(heroAttrList)
	if not isEmptyAttrList then
		if gType == UISagaSpread.DATA_TYPE_ATTR then
			return heroAttrList
		elseif gType == UISagaSpread.DATA_TYPE_OUTFIT then
			return heroWearOutfitList
		elseif gType == UISagaSpread.DATA_TYPE_RUNEANDTALENT then
			return heroWearRuneList,heroWearTalentList
		end
	end
end

------------------------------------------------------------------
return UISagaSpread


