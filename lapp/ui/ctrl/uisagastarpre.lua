---
--- Created by Administrator.
--- DateTime: 2023/10/22 18:02:32
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaStarPre:LWnd
local UISagaStarPre = LxWndClass("UISagaStarPre", LWnd)

local typeof = typeof
local typeSpineClick = typeof(CS.SpineClick)
local Time = Time
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local LUISkillCtrl = LxRequire("LApp.UI.Display.LUISkillCtrl")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaStarPre:UISagaStarPre()
	---@type table<string,LUIHeroObject>
	self._uiHeroObjList = nil
	---@type LUIHeroObject
	self._curUIHeroObj = nil
	---@type LUISkillCtrl
	self._uiSkillCtrl = nil
	self._loopHeroObjTimerKey = 1119
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaStarPre:OnWndClose()
	if self._uiSkillCtrl then
		self._uiSkillCtrl:Destroy()
		self._uiSkillCtrl = nil
	end

	FireEvent(EventNames.ON_CHAT_SHOW,true)
	--这个是从列表器拿出来的，列表进行删除就好了
	self._curUIHeroObj = nil

	LUtil.ClearHashTable(self._uiHeroObjList)
	self._uiHeroObjList = nil

	if self._func then self._func(self._refId) end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaStarPre:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaStarPre:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	FireEvent(EventNames.ON_CHAT_SHOW,false)
	self:SetWndText(self.mKeZhiGuanXiTxt,ccClientText(10080))
	self:InitData()
	self:InitEvent()
	self:InitBtnList()
	self:Refresh(self._starList[1])
end

function UISagaStarPre:InitData()
	self._refId = self:GetWndArg("refId")
	self._list = self:GetWndArg("list")
	self._index = self:GetWndArg("index")
	self._func = self:GetWndArg("func")

	CS.ShowObject(self.mLeftBtn,self._list ~= nil)
	CS.ShowObject(self.mRightBtn,self._list ~= nil)

	self._baseAttr = {
		LAttrConst.Atk,
		LAttrConst.Speed,
		LAttrConst.MaxHP,
		LAttrConst.Def,
		LAttrConst.CritRatio,
		LAttrConst.Hit,
	}
	self._iconTransList = {
		self.mIcon1,
		self.mIcon2,
		self.mIcon3,
		self.mIcon4,
	}
	self._attrTransList = {
		self.mAttr1,
		self.mAttr2,
		self.mAttr3,
		self.mAttr4,
	}
	self._starTransList = {
		self.mStar1,
		self.mStar2,
		self.mStar3,
		self.mStar4,
		self.mStar5,
	}
	self._skillTransList = {
		self.mSkill1,
		self.mSkill2,
		self.mSkill3,
		self.mSkill4,
	}
	self._closeImg = "fight_btn_tab_off"
	self._onImg = "fight_btn_tab_on"

	self:Init()
end

function UISagaStarPre:BtnEvent(index,ref)
	for k,v in pairs(self._btnTrans) do
		local status = index == k and 0 or 1
		self:SetWndTabStatus(v,status)
	end
	self:Refresh(ref,true)
end

function UISagaStarPre:GetMaxClass(lv)
	local grade = 0
	for i,v in ipairs(self._classList) do
		local tempGrade = v.grade
		local needLv = v.needLevel
		if lv >= needLv and needLv ~= -1 and grade <= tempGrade then
			grade = tempGrade
		elseif needLv == -1 and self._maxLv < lv then
			grade = tempGrade
		end
	end
	return grade
end

function UISagaStarPre:CreateSpine(effectId,star)
	local effRef = gModelHero:GetShowEffectById(effectId)
	if not effRef then return end

	local uiHeroObjList = self._uiHeroObjList
	if not uiHeroObjList then
		uiHeroObjList = {}
		self._uiHeroObjList = uiHeroObjList
	end

	if self._uiSkillCtrl then
		self._uiSkillCtrl:Destroy()
		self._uiSkillCtrl = nil
	end

	local prefabName = effRef.prefabName
	local newUIHeroObj = uiHeroObjList[prefabName]

	local oldUIHeroObj = self._curUIHeroObj
	if oldUIHeroObj and newUIHeroObj ~= oldUIHeroObj then
		oldUIHeroObj:ShowHero(false)
	end

	if not newUIHeroObj then
		newUIHeroObj = LUIHeroObject:New(self)
		uiHeroObjList[prefabName] = newUIHeroObj
		self._curUIHeroObj = newUIHeroObj

		newUIHeroObj:Create(self.mPb,prefabName,prefabName)
		newUIHeroObj:SetScale(2.5)
		newUIHeroObj:SetClickFunc(function(...) self:OnClickHeroSpine(...) end)
		newUIHeroObj:SetDragFunc(function(...) self:OnDragHeroSpineEnd(...) end )

		newUIHeroObj:SetHeroData(nil, self._refId, star, nil,true)
		newUIHeroObj:ShowHero(true)
		newUIHeroObj:StartLoad()
	else
		self._curUIHeroObj = newUIHeroObj
		newUIHeroObj:SetHeroData(nil, self._refId, star, nil, true)
		newUIHeroObj:ShowHero(true)
	end

	self:StartHeroObjRunTimer()
end

function UISagaStarPre:StartHeroObjRunTimer()
	if self:IsTimerExist(self._loopHeroObjTimerKey) then return end
	self:TimerStart(self._loopHeroObjTimerKey,0, false, -1)
end

function UISagaStarPre:OnDrwaBtnItem(list, item, itemdata, itempos, fromHeadTail)
	local btnTrans = self:FindWndTrans(item,"Btn")
	if btnTrans then
		local ref = itemdata.ref
		local index = itemdata.index
		self._btnTrans[index] = btnTrans
		self:SetWndClick(btnTrans,function()
			self:BtnEvent(index,ref)
		end)

		local status = index == self._lastBtn and 0 or 1
		self:SetWndTabStatus(btnTrans,status)

		local str = ccClientText(10050)
		str = string.replace(str,ref.star)
		self:SetWndTabText(btnTrans,str)
	end
end

function UISagaStarPre:OnTimer(key)
	if key == self._loopHeroObjTimerKey then
		local time = Time.unscaledTime
		if self._curUIHeroObj then
			self._curUIHeroObj:OnRun(time)
		end
		if self._uiSkillCtrl then
			self._uiSkillCtrl:OnRun(time)
		end
	end
end

function UISagaStarPre:ShowRaecKeZhiInfo()
	local refId = self._refId
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

function UISagaStarPre:OnDragHeroSpineEnd(heroObj, beginPos, endPos)
	if self._curUIHeroObj == nil then return end
	if self._curUIHeroObj ~= heroObj then return end
	local beginX = beginPos.x
	local endX = endPos.x
	if beginX - endX > 20 then
		self:CutHero(1)
	elseif beginX - endX < -20 then
		self:CutHero(-1)
	end
end

function UISagaStarPre:Refresh(starRef,btnType)
	if table.isempty(starRef) then return end
	local refId = self._refId
	local lv = starRef.maxLevel
	local star = starRef.star
	self._curStar = star
	local lvStr = string.replace(ccClientText(10011),lv)
	self:SetXUITextText(self.mLvTxt,lvStr)
	local starId = starRef.refId
	local grade = self:GetMaxClass(lv)
	local gradeId = gModelHero:ConvertToHeroGradeId(self._classType,grade)
	if LOG_INFO_ENABLED then
		printInfoNR("打印而已，莫慌 ".. "阶级:" .. grade.. ",星级:" .. star)
	end

	local buffList = gModelHero:GetSkillBuff(refId,star)
	local Atk,maxHp,Def,Speed = gModelHero:GetBaseAttrInfo(refId,lv,starId,gradeId,buffList)

	local heroInitCritRatio = gModelHero:GeConfigByKey("heroInitCritRatio") 		-- 暴伤基础
	local heroInitHit = gModelHero:GeConfigByKey("heroInitHit") 					-- 暴伤基础

	local attrList = {Atk,Speed,maxHp,Def,heroInitCritRatio,heroInitHit}
	local iconTransList = self._iconTransList
	local attrTransList = self._attrTransList
	local power = 0
	for i,v in ipairs(self._baseAttr) do
		local iconTrans = iconTransList[i]
		local attrTrans = attrTransList[i]

		local attrRef = gModelHero:GetAttributeRefById(v)
		local attrIcon = attrRef.icon
		self:SetWndEasyImage(iconTrans,attrIcon)

		local powerHero = attrRef.powerHero
		local attrName = ccLngText(attrRef.name)
		local numType = attrRef.numType
		local saveNum = attrRef.saveNum
		local value = attrList[i]

		if LOG_INFO_ENABLED then
			printInfoNR("打印而已，莫慌 ".. "属性名字:" .. attrName.. ",属性值（客户端显示为四舍五入）:" .. value)
		end

		local addPower = value * powerHero / 1000
		--addPower = math.floor(addPower)
		power = power + addPower

		if saveNum == 0 then value = math.floor(value + 0.5) end
		if numType == 2 then value = (value * 100) .. "%" end
		local str = string.format("%s %s",attrName,value)
		self:SetWndText(attrTrans,str)
	end
	if LOG_INFO_ENABLED then
		printInfoNR("打印而已，莫慌 ".. "战力值（向下取整）:" .. power)
	end
	power = math.floor(power)

	self:SetXUITextText(self.mPowerTxt,LUtil.FormatHurtNumSpriteText(power,false))

	local effectId = starRef.effectId
	local effRef = gModelHero:GetShowEffectById(effectId)

	if btnType == nil then
		local location = "[" .. ccLngText(effRef.location) .. "]"
		self:SetXUITextText(self.mLocationTxt,location)

		self:CreateSpine(effectId,star)
	end

	local quality = starRef.quality
	local color = gModelItem:GetColorByQualityId(quality)
	local heroName = ccLngText(effRef.name)
	if color then
		self:SetXUITextColor(self.mHeroName,color)
	end
	self:SetXUITextText(self.mHeroName,heroName)

	local img,showNum = gModelHero:GetHeroStarImg(star)
	for i,v in ipairs(self._starTransList) do
		local show = false
		if i <= showNum then
			show = true
			self:SetWndEasyImage(v,img)
		end
		CS.ShowObject(v,show)
	end
	self:RefreshSkillList(star)
end

function UISagaStarPre:InitBtnList()
	local uiList = self._uiList
	if not uiList then
		uiList = UIListEasy:New()
		uiList:Create(self,self.mBtnList)
		uiList:EnableScroll(true,true)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrwaBtnItem(...)
		end)
		self._uiList = uiList
	end
	uiList:RemoveAll()
	for i,v in ipairs(self._starList) do
		local data = {
			ref = v,
			index = i
		}
		uiList:AddData(i,data)
	end
	self._lastBtn = 1
	uiList:RefreshList()
end

function UISagaStarPre:Init(refresh)
	local heroRef  = gModelHero:GetHeroRef(self._refId)
	if not heroRef then return end
	local raceId = heroRef.raceType
	local raceRef = gModelHero:GetHeroRaceRefByRefId(raceId)
	if raceRef then
		local heroBg = raceRef.heroBg
		self:SetWndEasyImage(self.mBg,heroBg)
	end

	self._heroRef = heroRef
	self._starList = {}
	self._classList = {}
	if heroRef then
		local raceType = heroRef.raceType
		local raceImg = gModelHero:GetRaceImgByRefId(raceType)
		self:SetWndEasyImage(self.mTypeImg,raceImg)

		local qualityIcon = heroRef.qualityIcon
		self:SetWndEasyImage(self.mHeroQuaImg,qualityIcon)


		local careerType = heroRef.careerType
		local careerRef = GameTable.CharacterCareerRef[careerType]
		local careerName,careerImg = ccLngText(careerRef.name),careerRef.jobIcon
		if not string.isempty(careerName) then
			self:SetXUITextText(self.mJobName,careerName)
		end
		if not string.isempty(careerImg) then
			self:SetWndEasyImage(self.mRaceImg,careerImg)
		end

		local starType = heroRef.starType
		local initStar = heroRef.initStar
		local maxStar = heroRef.maxStar
		for i = initStar,maxStar do
			local starId = gModelHero:GetStarId(starType,i)
			local starRef = gModelHero:GetHeroStarById(starId)
			if starRef and starRef.preview == 1 then
				table.insert(self._starList,starRef)
			end
		end
		local classType = heroRef.classType
		self._classType = classType
		local maxLv = 0
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
	self._btnTrans = {}

	if refresh then
		self:InitBtnList()
		self:Refresh(self._starList[1])
	end
end

function UISagaStarPre:RefreshSkillList(star)
	local refId = self._refId
	local heroSkillIdList = gModelHero:GetSkillListByRefIdAndStar(refId,star)
	if not table.isempty(heroSkillIdList) then
		local skillListLen = #heroSkillIdList
		local skillTransList = self._skillTransList
		for i,v in ipairs(skillTransList) do
			local skillData = heroSkillIdList[i]
			if not table.isempty(skillData) then
				local skillId,openClass = skillData.skillId,skillData.openClass
				local skillIconTrans = CS.FindTrans(v,"SkillIcon")
				if skillIconTrans then
					local baseClass = SkillIcon:New(self)
					baseClass:SetSkillInfo(openClass,false,openClass,1)
					baseClass:Create(skillIconTrans,skillId,function()
						local heroData = {
							grade = openClass,
							refId = refId,
							star = star,
						}
						GF.OpenWndTop("UIJNInfo",{skillId = skillId,heroData = heroData,needGrade = openClass,index = i})
					end)
					CS.ShowObject(v,true)
				end
			end
		end
		for i = skillListLen + 1,4 do
			local trans = skillTransList[i]
			if trans then
				local baseClass = SkillIcon:New(self)
				local skillIconTrans = CS.FindTrans(trans,"SkillIcon")
				baseClass:SetShowIcon(false,false)
				baseClass:SetSkillInfo(nil,nil,nil,1)
				baseClass:Create(skillIconTrans,0,function() end)
				baseClass:SetIconAndIconBgGray(false)
				CS.ShowObject(trans,true)
			end
		end
	end
end

function UISagaStarPre:OnClickHeroSpine(heroObj)
	if self._curUIHeroObj == nil then return end
	if self._curUIHeroObj ~= heroObj then return end
	local spine = self._curUIHeroObj:GetDpObject()
	if not spine then return end
	local nowPlayAniName = spine:GetCurTrackEntryName()
	if nowPlayAniName == nil or nowPlayAniName == "idle" then
		local panelPlayEff = heroObj:RandomOneSkill()
		if not panelPlayEff then
			heroObj:PlayAttackAni()
			return
		end

		local skillCtr = self._uiSkillCtrl
		if skillCtr then
			skillCtr:Destroy()
			skillCtr = nil
		end

		skillCtr = LUISkillCtrl:New(self)
		self._uiSkillCtrl = skillCtr

		skillCtr:InitData(heroObj, panelPlayEff, self.mEffectPb, 0, 3, 250)
		skillCtr:PreLoadPlaySkill()
	end
end

function UISagaStarPre:CutHero(curIndex)
	if self._list == nil then return end

	local list = self._list
	local maxIndex = table.keysize(list)
	local newIndex = self._index + curIndex
	if newIndex > maxIndex then
		newIndex = 1
	elseif newIndex < 1 then
		newIndex = maxIndex
	end
	if list[newIndex] then
		self._refId = list[newIndex]
		self._index = newIndex
		self:Init(true)
	end
end

function UISagaStarPre:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mLeftBtn,function()
		self:CutHero(-1)
	end)
	self:SetWndClick(self.mRightBtn,function()
		self:CutHero(1)
	end)
	self:SetWndClick(self.mHeroQuaImg,function()
		GF.OpenWndTop("UISagaQualitySow")
	end)
	self:SetWndClick(self.mTypeImg,function()
		CS.ShowObject(self.mTypeImgMask,true)
		self:ShowRaecKeZhiInfo()
	end)
	self:SetWndClick(self.mTypeImgMask,function() CS.ShowObject(self.mTypeImgMask,false) end)
end
------------------------------------------------------------------
return UISagaStarPre


