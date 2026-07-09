---
--- Created by Administrator.
--- DateTime: 2023/10/12 17:48:43
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UINewSagaStarPre:LWnd
local UINewSagaStarPre = LxWndClass("UINewSagaStarPre", LWnd)


local Time = Time
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local LUISkillCtrl = LxRequire("LApp.UI.Display.LUISkillCtrl")
---@type LUIDrawingCtrl
local LUIDrawingCtrl = LxRequire("LApp.UI.Display.LUIDrawingCtrl")
local YXUIPointUtil = CS.YXUIPointUtil

UINewSagaStarPre.BASE_SORT_LIST = {
	LAttrConst.Atk,
	LAttrConst.MaxHP,
	LAttrConst.Def,
	LAttrConst.Speed,
}

UINewSagaStarPre.BASE_KEY_LIST = {
	[LAttrConst.Atk] = LAttrConst.Atk,
	[LAttrConst.MaxHP] = LAttrConst.MaxHP,
	[LAttrConst.Def] = LAttrConst.Def,
	[LAttrConst.Speed] = LAttrConst.Speed,
}

UINewSagaStarPre.ABOUT_POWER_LIST = {
	LAttrConst.Atk,
	LAttrConst.MaxHP,
	LAttrConst.Def,
	LAttrConst.Speed,
	LAttrConst.CritRatio,
	LAttrConst.Hit,
}

UINewSagaStarPre.MAX_GRADE_NUM = 6

UINewSagaStarPre.SHOW_NORMAL = 1
UINewSagaStarPre.SHOW_NEXTSTAR = 2

UINewSagaStarPre.PAGE_COMMON = 1			-- 常规页
UINewSagaStarPre.PAGE_AWAKEN = 2			-- 觉醒页
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UINewSagaStarPre:UINewSagaStarPre()
	---@type table<string,LUIHeroObject>
	self._uiHeroObjList = nil
	self._uiLiHuiObjList = nil
	---@type LUIHeroObject
	self._curUIHeroObj = nil
	self._curUILiHuiObj = nil			-- 当前立绘
	---@type LUISkillCtrl
	self._uiSkillCtrl = nil


	self._loopHeroObjTimerKey = 1119
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UINewSagaStarPre:OnWndClose()
	if self._uiSkillCtrl then
		self._uiSkillCtrl:Destroy()
		self._uiSkillCtrl = nil
	end
	if self._uiDrawingCtrl then
		self._uiDrawingCtrl:Destroy()
		self._uiDrawingCtrl = nil
	end

	--这个是从列表器拿出来的，列表进行删除就好了
	self._curUIHeroObj = nil
	LUtil.ClearHashTable(self._uiHeroObjList)
	self._uiHeroObjList = nil

	--这个是从列表器拿出来的，列表进行删除就好了
	self._curUILiHuiObj = nil
	LUtil.ClearHashTable(self._uiLiHuiObjList)
	self._uiLiHuiObjList = nil

	FireEvent(EventNames.ON_CHAT_SHOW,true)

	local haveHero = gModelHeroBook:GetHeroIsActByRefId(self._refId)
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"伙伴预览close",self._refId,haveHero)

	if self._func then self._func(self._refId) end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UINewSagaStarPre:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UINewSagaStarPre:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mKeZhiGuanXiTxt,ccClientText(10080))
	self:InitEvent()
	self:InitData()
	if self._showType == UINewSagaStarPre.SHOW_NORMAL then
		self:InitBtnList()
	end
	self:Refresh(self._starList[1])
end


function UINewSagaStarPre:CreateSpine(effectId,star)
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

		newUIHeroObj:Create(self.mHeroSpinePos,prefabName,prefabName)
		newUIHeroObj:SetScale(1)
		newUIHeroObj:SetClickFunc(function(...) self:OnClickHeroSpine(...) end)
		newUIHeroObj:SetDragFunc(function(...) self:OnDragHeroSpineEnd(...) end)

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

function UINewSagaStarPre:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mLeftBtn,function() self:CutHero(-1) end)
	self:SetWndClick(self.mRightBtn,function() self:CutHero(1) end)
	self:SetWndClick(self.mHeroZZImg,function() GF.OpenWndTop("UISagaQualitySow") end)
	self:SetWndClick(self.mHeroRaceImg,function()
		CS.ShowObject(self.mTypeImgMask,true)
		self:ShowRaecKeZhiInfo()
	end)
	self:SetWndClick(self.mTypeImgMask,function() CS.ShowObject(self.mTypeImgMask,false) end)
	self:SetWndClick(self.mGradeDescMask,function() CS.ShowObject(self.mGradeDescMask,false) end)
	self:SetWndClick(self.mLiHuiClick,function()
		GF.OpenWndTop("UISagaLiHuiSow",{selSkinRefId = self._refId})
	end)
	self:SetWndClick(self.mShiftAwakenBtn, function() self:OnClickAwakenEvent() end)
	self:SetWndClick(self.mShiftUpStarBtn, function() self:OnClickShiftUpStarEvent() end)
end

function UINewSagaStarPre:OnDrawStarCell(list,item,itemdata,itempos)
	local Star = self:FindWndTrans(item,"Star")
	if Star then
		self:SetWndEasyImage(Star,itemdata.img,function() CS.ShowObject(Star,true) end)
	end
end

function UINewSagaStarPre:OnDrawAwakenSkillCell(list,item,itemdata,itempos)
	local skillId = tonumber(itemdata)
	local curSelectTreePointId = self._curSelectTreePointId
	local awakenPointActivate = true
	local Root = self:FindWndTrans(item,"CommonUI/Root")
	if Root then
		local SkillIconTrans = self:FindWndTrans(Root,"SkillIcon")
		local baseClass = SkillIcon:New(self)
		if skillId then
			baseClass:SetSkillInfo(nil,false,nil,1)
			baseClass:Create(SkillIconTrans,skillId,function()
				local skillList = gModelHero:GetTreePointSkillIdList(curSelectTreePointId, itempos)
				if not table.isempty(skillList) then
					local firstSkillId = skillList[1]
					gModelGeneral:OpenSkillWnd({
						skill = firstSkillId,
						curSkillId = skillId,
						wndType = 5,
						pointActivate = awakenPointActivate,
					})
--[[					GF.OpenWnd("UINewJNTip",{
						skill = firstSkillId,
						curSkillId = skillId,
						wndType = 5,
						pointActivate = awakenPointActivate,
					})]]
				end
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

	local selectBg		= self:FindWndTrans(item, "SelectBg")
	local isActivate	= true
	local selectYesIcon = self:FindWndTrans(selectBg, "SelectYesIcon")
	local isSelect 		= isActivate and self._curSelectTreePointSkillId == skillId
	CS.ShowObject(selectYesIcon, isSelect)
	self:SetWndClick(selectBg, function()
		self:OnClickAwakenSkillSelect(skillId)
	end)
end


--####################################################################################################################
--## Awaken ##########################################################################################################
--####################################################################################################################
function UINewSagaStarPre:RefreshStarPage()
	local isShow = self._curStarPageType == UINewSagaStarPre.PAGE_AWAKEN
	CS.ShowObject(self.mAwakenView, isShow)
	if isShow then
		self:RefreshAwakenView()
	end
end

function UINewSagaStarPre:OnDrawStarBtnCell(list,item,itemdata,itempos)
	local BtnTab3 = self:FindWndTrans(item,"BtnTab3")
	if BtnTab3 then
		local ref = itemdata.ref
		local index = itemdata.index
		self:SetWndClick(BtnTab3,function()
			self:BtnEvent(index,ref)
		end)

		local status = index == self._lastBtn and 0 or 1
		self:SetWndTabStatus(BtnTab3,status)

		local str = ccClientText(10050)
		str = string.replace(str,ref.star)
		self:SetWndTabText(BtnTab3,str)
		self._curStarIndex = index
	end
end

function UINewSagaStarPre:OnDrawSkillCell(list,item,itemdata,itempos)
	local skillId,openClass = itemdata.skillId,itemdata.openClass
	local refId,star,index = itemdata.refId,itemdata.star,itemdata.index
	local grade = itemdata.grade
	local Root = self:FindWndTrans(item,"CommonUI/Root")
	if Root then
		local SkillIconTrans = self:FindWndTrans(Root,"SkillIcon")
		local baseClass = SkillIcon:New(self)
		if skillId then
			baseClass:SetSkillInfo(openClass,false,openClass,1)
			baseClass:Create(SkillIconTrans,skillId,function()
				local heroData = {
					refId = refId,
					star = star,
					grade = grade,
				}
				gModelGeneral:OpenHeroSkillWnd({curSkillId = skillId,curSkillIdx = index,heroData = heroData})
--[[				local skillInfo = {
					grade = openClass,
					refId = refId,
					star = star,
				}
				GF.OpenWndTop("UIJNInfo",{
					skillId = skillId,
					heroData = skillInfo,
					needGrade = openClass,
					index = index
				})]]
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
	local SkillName = self:FindWndTrans(item,"SkillName")
	if SkillName then
		local name
		if skillId then
			local skillRef = gModelHero:GetSkillByStarId(skillId)
			if skillRef then name = ccLngText(skillRef.name) end
		else
			name = ccClientText(10149)
		end
		self:SetWndText(SkillName,name)
	end

	self:InitTextModeWithLanguage(SkillName)
end

function UINewSagaStarPre:SetAwakenPointEffShow(isShow, effName, pointTrans)
	local InstanceID		= pointTrans:GetInstanceID()
	local effKey			= effName..InstanceID
	if isShow then
		self:CreateWndEffect(pointTrans,effName,effKey,100,false,false, 21)
	else
		self:DestroyWndEffectByKey(effKey)
	end
end

function UINewSagaStarPre:CutHero(curIndex)
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

function UINewSagaStarPre:CreateAwakenTree(treeTrans)
	local heroTreeInfoList	= self._heroTreeInfoList
	if not heroTreeInfoList then return end

	local pointListTrans	= self:FindWndTrans(treeTrans, "ScrollRect/Content/PointList")
	for k,v in pairs(heroTreeInfoList) do
		self:OnDrawAwakenTreePointCell(pointListTrans,v,k)
	end
end

function UINewSagaStarPre:StartHeroObjRunTimer()
	if self:IsTimerExist(self._loopHeroObjTimerKey) then return end
	self:TimerStart(self._loopHeroObjTimerKey,0, false, -1)
end

function UINewSagaStarPre:InitData()
	self._refId = self:GetWndArg("refId")
	self._list = self:GetWndArg("list")
	self._index = self:GetWndArg("index")
	self._func = self:GetWndArg("func")
	self._nextStar = self:GetWndArg("nextStar")
	self._hideAwaken = self:GetWndArg("hideAwaken")
	local showType = self:GetWndArg("showType")
	if showType == nil then
		showType = UINewSagaStarPre.SHOW_NORMAL
	end
	self._showType = showType

	CS.ShowObject(self.mLeftBtn,self._list ~= nil)
	CS.ShowObject(self.mRightBtn,self._list ~= nil)

	self._curStarPageType = UINewSagaStarPre.PAGE_COMMON
	self._awakenTreeList = {}
	self._awakenTreeTransList = {}

	if showType == UINewSagaStarPre.SHOW_NORMAL then
		self:Init()
	else
		self:ShowNextStar()
	end
end

function UINewSagaStarPre:OnClickAwakenSkillSelect()
	GF.ShowMessage(ccClientText(20160))
end

function UINewSagaStarPre:CreateAwakenAttrItemList(attrList)
	local uiAwakenAttrList = self._uiAwakenAttrList
	if uiAwakenAttrList then
		uiAwakenAttrList:RefreshList(attrList)
	else
		uiAwakenAttrList = self:GetUIScroll("uiAwakenAttrList")
		self._uiAwakenAttrList = uiAwakenAttrList
		uiAwakenAttrList:Create(self.mAwakenAttrList,attrList,function(...) self:OnDrawAwakenAttrCell(...) end)
	end

	uiAwakenAttrList:EnableScroll(#attrList > 3,false)
end

function UINewSagaStarPre:ShowNormal()
	local refId = self._refId
	local heroRef  = gModelHero:GetHeroRef(refId)
	if not heroRef then return end
	local raceId = heroRef.raceType
	local raceRef = gModelHero:GetHeroRaceRefByRefId(raceId)
	if not raceRef then return end
	local careerType = heroRef.careerType
	local careerRef = GameTable.CharacterCareerRef[careerType]
	if not careerRef then return end

	local careerName,careerImg = ccLngText(careerRef.name),careerRef.jobIcon
	self:SetWndText(self.mJobName,careerName)
	self:SetWndEasyImage(self.mJobImg,careerImg)

	local heroBg
	local qualityRef = gModelItem:GetQualityRef(heroRef.quality)
	if qualityRef then
	end
    heroBg = raceRef.heroBg
	self:SetWndEasyImage(self.mHeroBg,heroBg,function() CS.ShowObject(self.mHeroBg,true) end)
	local raceImg = raceRef.icon
	self:SetWndEasyImage(self.mHeroRaceImg,raceImg,function() CS.ShowObject(self.mHeroRaceImg,true) end)
	local qualityIcon = heroRef.qualityIcon
	self:SetWndEasyImage(self.mHeroZZImg,qualityIcon,function() CS.ShowObject(self.mHeroZZImg,true) end)

	local initStar = heroRef.initStar
	local quality = gModelHero:GetHeroQualityByRefId(refId,initStar)
	qualityRef = gModelItem:GetQualityRef(quality)
	if not qualityRef then return end
	local heroMsgNameBg = qualityRef.heroMsgNameBg
	self:SetWndEasyImage(self.mHeroQuaImg,heroMsgNameBg,function() CS.ShowObject(self.mHeroQuaImg,true) end)
end

function UINewSagaStarPre:SetStarPageShow(showType)
	if showType == self._curStarPageType then return end

	self._curStarPageType = showType
	self:RefreshStarPage()
end

function UINewSagaStarPre:OnClickHeroSpine(heroObj)
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

		skillCtr:InitData(heroObj, panelPlayEff, self.mHeroEffPos, 0, 12, 100)
		skillCtr:PreLoadPlaySkill()
	end
end

function UINewSagaStarPre:OnDrawGradeCell(list,item,itemdata,itempos)
	local grade,needLevel,haveData,act = itemdata.grade,itemdata.needLevel,itemdata.haveData,itemdata.act
	if grade == -1 then grade = "" end
	local NoActImg = self:FindWndTrans(item,"NoActImg")
	if NoActImg then
		local NoGradeLv = self:FindWndTrans(NoActImg,"NoGradeLv")
		if NoGradeLv then
			self:SetWndText(NoGradeLv,grade)
		end
		CS.ShowObject(NoActImg,not act)
	end
	local NoOpenImg = self:FindWndTrans(item,"NoOpenImg")
	if NoOpenImg then
		CS.ShowObject(NoOpenImg,not haveData)
	end
	local GradeLv = self:FindWndTrans(item,"GradeLv")
	if GradeLv then
		self:SetWndText(GradeLv,grade)
		CS.ShowObject(GradeLv,act)
	end
	self:SetWndClick(item,function()
		if haveData then
			self:ShowGradeDescDiv(grade,needLevel)
		end
	end)
end

function UINewSagaStarPre:CreateLiHui(effectId,star)
	local effRef = gModelHero:GetShowEffectById(effectId)
	if not effRef then return end
	local heroDrawing = effRef.heroDrawing

	local uiLiHuiObjList = self._uiLiHuiObjList
	if not uiLiHuiObjList then
		uiLiHuiObjList = {}
		self._uiLiHuiObjList = uiLiHuiObjList
	end

	if self._uiDrawingCtrl then
		self._uiDrawingCtrl:Destroy()
		self._uiDrawingCtrl = nil
	end

	local newUILiHui = uiLiHuiObjList[heroDrawing]
	local curUILiHui = self._curUILiHuiObj
	self._curUILiHuiObj = nil

	if curUILiHui and newUILiHui ~= curUILiHui then
		curUILiHui:ShowHero(false)
	end

	if not newUILiHui then
		newUILiHui = LUIHeroObject:New(self)
		uiLiHuiObjList[heroDrawing] = newUILiHui

		self._curUILiHuiObj = newUILiHui
		newUILiHui:Create(self.mHeroLiHuiPos,heroDrawing,heroDrawing)
		newUILiHui:SetRectMatch(true)
		newUILiHui:ShowHero(true)
		newUILiHui:StartLoad()
	else
		self._curUILiHuiObj = newUILiHui
		newUILiHui:ShowHero(true)
	end

	local uiDrawCtrl = LUIDrawingCtrl:New()
	self._uiDrawingCtrl = uiDrawCtrl
	uiDrawCtrl:SetHeroObject(newUILiHui)
	uiDrawCtrl:SetEffectInfo(self.mHeroLiHuiEffPos, 1, 6, 100)
	uiDrawCtrl:InitHeroEffectInfo(effectId)
	uiDrawCtrl:StartPlay()
end

function UINewSagaStarPre:OnClickTreePoint(treePointRefId)
	if self._curSelectTreePointId == treePointRefId then
		return
	end

	local oldSelectTreePointId = self._curSelectTreePointId
	local treePointTransList   = self._awakenTreeTransList[self._treePbName]
	local oldPointInfo = treePointTransList[oldSelectTreePointId]
	if oldPointInfo then
		CS.ShowObject(oldPointInfo.selectIcon, false)
	end

	local curPointInfo = treePointTransList[treePointRefId]
	if curPointInfo then
		CS.ShowObject(curPointInfo.selectIcon, true)
	end

	self:ShowPrepositionPointEff(false, oldSelectTreePointId)
	self:ShowPrepositionPointEff(true, treePointRefId)

	self._curSelectTreePointId = treePointRefId
	self:RefreshAwakenDetails()
end

function UINewSagaStarPre:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIconTrans = self:FindWndTrans(item,"AttrIcon")
	local AttrNameTrans = self:FindWndTrans(item,"AttrName")
	local AttrValueTrans = self:FindWndTrans(item,"AttrValue")
	local refId,numType,value,saveNum = itemdata.refId,itemdata.numType,itemdata.value,itemdata.saveNum
	if AttrIconTrans then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIconTrans,icon,function()
			CS.ShowObject(AttrIconTrans,true)
		end)
	end
	if AttrNameTrans then
		local name = gModelHero:GetAttributeNameById(refId)
		self:SetWndText(AttrNameTrans,name)
	end
	if AttrValueTrans then
		if saveNum == 0 then value = math.floor(value + 0.5) end
		if numType == 2 then value = (value * 100) .. "%" end
		self:SetWndText(AttrValueTrans,value)
	end
end

function UINewSagaStarPre:ShowGradeDescDiv(grade,needLevel)
	CS.ShowObject(self.mGradeDescMask,true)
	local canvasRect = LGameUI.GetUICanvasRoot()
	local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect,self.mGradeDescDiv)
	self.mGradeDescDiv.localPosition = targetPos - Vector3.New(0,0,0)
	local str = string.replace(ccClientText(20115),grade)
	self:SetWndText(self.mCurGradeDesc,str)
	if needLevel ~= -1 then
		str = string.replace(ccClientText(20116),needLevel,grade + 1)
	else
		str = ccClientText(20122)
	end
	self:SetWndText(self.mYaoqiuDesc,str)
end

function UINewSagaStarPre:OnClickSkillSelect(treePointRefId)
	local heroRefId = self._refId
	GF.OpenWnd("UISagaAwakenJNSelect",{
		pointRefId = treePointRefId,
		heroRefId  = heroRefId,
	})
end

function UINewSagaStarPre:Refresh(starRef,btnType)
	if table.isempty(starRef) then return end
	local refId = self._refId
	local lv = starRef.maxLevel
	local star = starRef.star


	local lvStr = string.replace(ccClientText(19757),lv,lv)
	self:SetWndText(self.mLvTxt,lvStr)

	local starId = starRef.refId
	local grade = self:GetMaxClass(lv)
	local gradeId = gModelHero:ConvertToHeroGradeId(self._classType,grade)
	if LOG_INFO_ENABLED then
		printInfoNR("打印而已，莫慌 ".. "阶级:" .. grade.. ",星级:" .. star)
	end

	self:CreateGradeList(grade)

	local buffList = gModelHero:GetSkillBuff(refId,star)
	local Atk,maxHp,Def,Speed = gModelHero:GetBaseAttrInfo(refId,lv,starId,gradeId,buffList)

	local heroInitCritRatio = gModelHero:GeConfigByKey("heroInitCritRatio") 		-- 暴伤基础
	local heroInitHit = gModelHero:GeConfigByKey("heroInitHit") 					-- 暴伤基础

	local attrInfoList = {}
	local attrList = {Atk,maxHp,Def,Speed,heroInitCritRatio,heroInitHit}
	local power = 0
	for i,v in ipairs(UINewSagaStarPre.ABOUT_POWER_LIST) do
		local attrRef = gModelHero:GetAttributeRefById(v)
		local powerHero = attrRef.powerHero
		local attrName = ccLngText(attrRef.name)
		local value = attrList[i]

		if LOG_INFO_ENABLED then
			printInfoNR("打印而已，莫慌 ".. "属性名字:" .. attrName.. ",属性值（客户端显示为四舍五入）:" .. value)
		end

		if UINewSagaStarPre.BASE_KEY_LIST[v] then
			table.insert(attrInfoList,{
				refId = v,
				numType = attrRef.numType,
				value = value,
				saveNum = attrRef.saveNum,
			})
		end

		local addPower = value * powerHero / 1000
		--addPower = math.floor(addPower)
		power = power + addPower
	end
	self:CreateAttrList(attrInfoList)

	if LOG_INFO_ENABLED then
		printInfoNR("打印而已，莫慌 ".. "战力值（向下取整）:" .. power)
	end
	power = LUtil.ToInteger(power)
	--local isForeign = LGameLanguage:IsForeignVersion()
	--local sizeRate = isForeign and 150 or 100
	local str = LUtil.FormatPowerShowStr(power,130,150)
	self:SetWndText(self.mPowerNumTxt,str)

	local effectId = starRef.effectId
	local effRef = gModelHero:GetShowEffectById(effectId)

	if btnType == nil then
		local location = "[" .. ccLngText(effRef.location) .. "]"
		self:SetWndText(self.mJobEffTxt,location)
		local x,y = gModelHeroBook:GetHeroPosByRefIdAndType(effectId,"heroDrawingPos2")
		if x and y then
			if not (x==0 and y==0) then
				self.mHeroLiHuiPos.anchoredPosition = Vector3.New(x,y,0)
				self.mHeroLiHuiEffPos.anchoredPosition = Vector3.New(x,y,0)
			end
		end
		self:CreateDisplay(effectId,star)
	end

	self:CreateStarList(star)

	local quality = starRef.quality
	local heroName = ccLngText(effRef.name)
--[[	local color = gModelItem:GetColorByQualityId(quality)
	if color then
		self:SetXUITextTransColor(self.mHeroName,color)
	end]]
	self:SetWndText(self.mHeroName,heroName)

	self:RefreshSkillList(star,grade)
	self:RefreshShiftAwakenBtn()
end

function UINewSagaStarPre:RefreshShiftAwakenBtn()
	local isShowAwaken = self._maxStar and self._maxStar >= 10

	if PRODUCT_G_VER == 1 or self._hideAwaken then --ios 提审屏蔽
		isShowAwaken = false
	end

	CS.ShowObject(self.mShiftAwakenBtn, isShowAwaken)
	if not isShowAwaken then return end
	local isOpen = gModelFunctionOpen:CheckIsOpened(10306002)
	if not isOpen then
		CS.ShowObject(self.mShiftAwakenBtn, false)
		return
	end
	self:SetWndText(self.mShiftAwakenBtnText, ccClientText(20137))
end

function UINewSagaStarPre:RefreshAwakenTree()
	local treeRefId = self._treeRefId
	if not self._treeRefId then
		return
	end

	local treeRef = gModelHero:GetHeroTreeRef(treeRefId)
	if not treeRef then
		printInfoNR("GameTable.CharacterTreeRef[refId] is a nil, refId = "..treeRefId)
		return
	end

	local treePbName = treeRef.treePb
	self._treePbName = treePbName
	local awakenTreeList = self._awakenTreeList

	local awakenTreeTrans = awakenTreeList[treePbName]
	if not awakenTreeTrans then
		self:CreateWndPrefab(self.mAwakenTree, treePbName, treePbName, function(prefabTrans)
			self._awakenTreeList[treePbName] = prefabTrans
			self:CreateAwakenTree(prefabTrans, treePbName)
		end, CS.RES_UI_HERO_AWAKEN_TREE)
	else
		self:CreateAwakenTree(awakenTreeTrans, treePbName)
	end

	for k,v in pairs(awakenTreeList) do
		CS.ShowObject(v, k == treePbName)
	end
end

function UINewSagaStarPre:OnDrawAwakenAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local NextAttrValue = self:FindWndTrans(item, "NextAttrValue")
	local refId,type,value,nextValue = itemdata.refId,itemdata.type,itemdata.value,itemdata.nextValue

	local icon = gModelHero:GetAttributeIconById(refId)
	self:SetWndEasyImage(AttrIcon,icon,function() CS.ShowObject(AttrIcon,true) end)

	local name = gModelHero:GetAttributeNameById(refId)
	self:SetWndText(AttrName,name)

	local val = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,type,value)
	local haveNextValue = nextValue and nextValue > 0
	local addVal = ""
	local addStrColor = haveNextValue and "lightGreen" or "yellow_2"
	if haveNextValue then
		val 	= "+"..val
		addVal 	= gModelHero:GetAttributeValueNoNameByIdAndVal(refId,type,nextValue)
	else
		addVal = val
		val    = ""
	end

	self:SetWndText(AttrValue,val)

	addVal = LUtil.FormatColorStr("+"..addVal,addStrColor)
	self:SetWndText(NextAttrValue,addVal)

end

function UINewSagaStarPre:GetDefaultSelectTreePoint()
	local treeRefId = self._treeRefId
	local treeRef = gModelHero:GetHeroTreeRef(treeRefId)
	local bigRefId = treeRef.initPoint
	return bigRefId
end

function UINewSagaStarPre:CreateDisplay(effectId,star)
	self:CreateSpine(effectId,star)
	self:CreateLiHui(effectId,star)
end

function UINewSagaStarPre:CreateAwakenSkillItemList(list)
	local uiSkillList = self._uiAwakenSkillList
	if uiSkillList then
		uiSkillList:RefreshList(list)
	else
		uiSkillList = self:GetUIScroll("uiAwakenSkillList")
		self._uiAwakenSkillList = uiSkillList
		uiSkillList:Create(self.mAwakenSkillList,list,function(...) self:OnDrawAwakenSkillCell(...) end)
	end
end

function UINewSagaStarPre:OnDragHeroSpineEnd(heroObj, beginPos, endPos)
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

function UINewSagaStarPre:InitBtnList()
	local list = {}
	for i,v in ipairs(self._starList) do
		local data = {ref = v,index = i}
		table.insert(list,data)
	end

	self._lastBtn = list and list[1].index or 1
	local uiBtnList = self._uiBtnList
	if uiBtnList then
		uiBtnList:RefreshList(list)
	else
		uiBtnList = self:GetUIScroll("uiBtnList")
		self._uiBtnList = uiBtnList
		uiBtnList:Create(self.mChangeStarBtnList,list,function(...) self:OnDrawStarBtnCell(...) end)
		local isMove = #list > 3
		uiBtnList:EnableScroll(isMove,true)
	end
end

function UINewSagaStarPre:OnTimer(key)
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

function UINewSagaStarPre:ShowNextStar()
	self:ShowNormal()
	local refId = self._refId
	local heroRef  = gModelHero:GetHeroRef(refId)
	if not heroRef then return end
	local starType = heroRef.starType
	local maxStar = heroRef.maxStar
	self._maxStar = maxStar
	local nextStar = self._nextStar
	if nextStar > maxStar then
		nextStar = maxStar
	end

	self._starList = {}
	self._classList = {}

	local starId = gModelHero:GetStarId(starType,nextStar)
	local starRef = gModelHero:GetHeroStarById(starId)
	table.insert(self._starList,starRef)

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

function UINewSagaStarPre:ShowPrepositionPointEff(isShow, treePointRefId)
	local heroTreePointInfo = self._heroTreeInfoList[treePointRefId]
	if not heroTreePointInfo then
		return
	end

	local isShowEff = isShow
	if isShowEff then
		isShowEff = false
		if not heroTreePointInfo.isActivate then
			if not heroTreePointInfo.canActivate and heroTreePointInfo.needConType == ModelHero.TREE_CON_TYPE_LVL then
				isShowEff = true
			end
		end
	end

	local ref   = gModelHero:GetHeroTreePointRef(treePointRefId)
	if not ref then
		printInfoNR("GameTable.CharacterTreePointRef[refId] is a nil, refId = "..treePointRefId)
		return
	end

	local front = ref.front
	if not front or front <= 0 then
		return
	end

	local treePointTransList = self._awakenTreeTransList[self._treePbName]
	local frontPointInfo 	 = treePointTransList[front]
	if not frontPointInfo then
		return
	end

	local frontHeroTreePointInfo = self._heroTreeInfoList[front]
	if not frontHeroTreePointInfo then
		return
	end

	local pointTrans 		= frontPointInfo.pointTrans
	local pointType 		= frontHeroTreePointInfo.pointType
	local effName			= pointType == ModelHero.TREE_POINT_TYPE_ATTR and "ui_yingxiongjuexing_qianzhi" or "ui_yingxiongjuexing_qianzhi_2"
	self:SetAwakenPointEffShow(isShowEff, effName, pointTrans)
end

function UINewSagaStarPre:RefreshAwakenDetails()
	local treePointRefId = self._curSelectTreePointId
	if not treePointRefId then
		return
	end

	local heroTreePointInfo = self._heroTreeInfoList[treePointRefId]
	if not heroTreePointInfo then
		printInfoNR("self._heroTreeInfoList[treePointRefId] is a nil, treePointRefId = "..treePointRefId)
		return
	end

	local lvRefId			= heroTreePointInfo.lvRefId
	local nextLvRefId 		= heroTreePointInfo.nextLvRefId
	local pointType 		= heroTreePointInfo.pointType
	local lvList 			= heroTreePointInfo.lvList
	local isMaxLv 			= heroTreePointInfo.isMaxLv
	local maxLvListNum 		= #lvList
	local maxPointLvData 	= lvList[maxLvListNum]
	local maxPointLvRefId 	= maxPointLvData.refId
	local curPointLvRef  	= gModelHero:GetHeroTreePointLvRef(lvRefId)
	local nextPointLvRef 	= gModelHero:GetHeroTreePointLvRef(nextLvRefId)
	local maxPointLvRef  	= gModelHero:GetHeroTreePointLvRef(maxPointLvRefId)

	local isTryHero			= self._isTryHero

	local curPointLv		= curPointLvRef.lv
	local maxPointLv		= maxPointLvRef.lv
	local titleStr 			= string.replace(ccClientText(20139), curPointLv, maxPointLv)
	self:SetWndText(self.mAwakenTitle, titleStr)

	-- 显示属性/技能
	if pointType == ModelHero.TREE_POINT_TYPE_ATTR then
		local curPointAttr  = curPointLvRef.attr
		local nextPointAttr = nextPointLvRef and nextPointLvRef.attr or ""
		local attrList 		= gModelHero:GetAwakenTreePointAttrList(curPointAttr, nextPointAttr)
		self:CreateAwakenAttrItemList(attrList)
	else
		self._curSelectTreePointSkillId = heroTreePointInfo.skillId
		local curPointSkill  			= curPointLvRef.skill
		local pointSkill
		if not string.isempty(curPointSkill) and curPointSkill ~= "0" then
			pointSkill	= curPointSkill
		else
			pointSkill	= nextPointLvRef.skill
		end
		local list 						= string.split(pointSkill, '|')
		self:CreateAwakenSkillItemList(list)
	end
	CS.ShowObject(self.mAwakenAttr, pointType == ModelHero.TREE_POINT_TYPE_ATTR)
	CS.ShowObject(self.mAwakenSkill, pointType == ModelHero.TREE_POINT_TYPE_SKILL)

	-- 显示消耗区域
	self._awakenSelectHeroList = {}

	--升级按钮与描述屏蔽
	local isShowPageDesc = true
	local pageDesc = ccClientText(20142)

	CS.ShowObject(self.mAwakenPageDesc,isShowPageDesc)
	if not isTryHero then
		self:SetWndText(self.mAwakenPageDesc,pageDesc)
	end
end

function UINewSagaStarPre:BtnEvent(index,ref)
	if self._lastBtn == index then return end
	self._lastBtn = index
	local uiBtnList = self._uiBtnList
	if uiBtnList then
		local uiList = uiBtnList:GetList()
		uiList:RefreshList()
	end
	self:SetStarPageShow(UINewSagaStarPre.PAGE_COMMON)
	self:Refresh(ref,true)
end

function UINewSagaStarPre:OnDrawAwakenTreePointCell(parentRoot,itemdata,itempos)
	local treePbName = self._treePbName
	if not treePbName then
		return
	end

	local list = self._awakenTreeTransList[treePbName]
	if not list then
		self._awakenTreeTransList[treePbName] = {}
		list = self._awakenTreeTransList[treePbName]
	end

	local treePointRefId	= itemdata.treePointRefId
	local info 				= list[treePointRefId]
	if not info then
		local pointRef			= gModelHero:GetHeroTreePointRef(treePointRefId)
		local treePbNode		= pointRef.treePbNode
		local pointTrans 		= self:FindWndTrans(parentRoot, treePbNode)
		if not pointTrans then
			printInfoNR("trans not find, transName = "..treePbNode)
			return
		end

		info = {
			pointTrans		= pointTrans,
			commonBgTrans	= self:FindWndTrans(pointTrans, "CommonBg"),
			coverBgTrans	= self:FindWndTrans(pointTrans, "CoverBg"),
			commonIcon		= self:FindWndTrans(pointTrans, "CommonIcon"),
			coverIcon		= self:FindWndTrans(pointTrans, "CoverIcon"),
			selectIcon		= self:FindWndTrans(pointTrans, "SelectIcon"),
			upIcon			= self:FindWndTrans(pointTrans, "UpIcon"),
			newIcon			= self:FindWndTrans(pointTrans, "NewIcon"),
			skillTrans		= self:FindWndTrans(pointTrans, "Skill/Root/SkillIcon"),
		}

		list[treePointRefId] = info
	end

	local isTryHero			= self._isTryHero
	local pointTrans		= info.pointTrans
	local isActivate 		= itemdata.isActivate or false
	local canActivate		= itemdata.canActivate or false
	local canLvlUp			= itemdata.canLvlUp or false
	local isSelect			= treePointRefId == self._curSelectTreePointId
	local showActivate		= canActivate and canLvlUp and not isTryHero
	local showLvUp			= isActivate and canLvlUp and not isTryHero

	CS.ShowObject(info.commonBgTrans, not isActivate)
	CS.ShowObject(info.commonIcon, not isActivate)
	CS.ShowObject(info.coverBgTrans, isActivate)
	CS.ShowObject(info.coverIcon, isActivate)
	CS.ShowObject(info.selectIcon, isSelect)
	CS.ShowObject(info.upIcon, showLvUp)

	local showNewIcon = false
	CS.ShowObject(info.newIcon, showNewIcon)

	self:SetWndClick(pointTrans, function()
		self:OnClickTreePoint(treePointRefId)
	end)

	local pointType 		= itemdata.pointType

	--技能图标
	if pointType == ModelHero.TREE_POINT_TYPE_SKILL and info.skillTrans then
		local skillIconList = self._skillIconList
		if not skillIconList then
			skillIconList = {}
			self._skillIconList = skillIconList
		end

		local skillIconTrans = info.skillTrans
		local skillId = itemdata.skillId
		local haveSkill = skillId and skillId > 0
		local InstanceID = skillIconTrans:GetInstanceID()
		local baseClass = skillIconList[InstanceID]
		if not baseClass then
			baseClass = SkillIcon:New(self)
		end

		if not haveSkill then
			baseClass:SetShowIcon(false,false)
			baseClass:SetSkillInfo(nil,nil,nil,1)
			baseClass:ShowLvl(false)
			baseClass:Create(skillIconTrans,0,function()
				self:OnClickSkillSelect(treePointRefId)
			end)
			baseClass:SetIconAndIconBgGray(false)
		else
			baseClass:SetSkillInfo(nil,false,nil,1)
			baseClass:ShowLvl(false)
			baseClass:ShowLock(false)
			baseClass:Create(skillIconTrans,skillId,function()
				self:OnClickSkillSelect(treePointRefId)
			end)
			baseClass:SetIconAndIconBgGray(false)
		end
	end
end

function UINewSagaStarPre:ShowRaecKeZhiInfo()
	local canvasRect = LGameUI.GetUICanvasRoot()
	if not self._changePos then
		local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect,self.mTypeImgMask)
		self.mTypeImgMask.localPosition = targetPos - Vector3.New(0,25,0)
		self._changePos = true
	end
	local refId = self._refId
	local raceType = gModelHero:GetHeroType(refId)
	if raceType then
		local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
		if raceRef then
			local restrainDetailsEff = raceRef.restrainDetailsEff
			local isEmpty = string.isempty(restrainDetailsEff)
			local str = ""
			if not isEmpty then
				local heroRaceImage = raceRef.heroRaceImage
				self:SetWndEasyImage(self.mTypeKeZhiImg,heroRaceImage,function()
					CS.ShowObject(self.mTypeKeZhiImg,true)
				end,true)
			else
				CS.ShowObject(self.mTypeKeZhiImg,not isEmpty)
				str = ccClientText(31233)
			end
			CS.ShowObject(self.mTypeKZImgDiv,not isEmpty)
			CS.ShowObject(self.mNoHaveKeZhiTxtDiv,isEmpty)

			local name = string.replace(ccClientText(10079),ccLngText(raceRef.name))
			self:SetWndText(self.mRaceTypeName,name)

			self:SetWndText(self.mNoHaveKeZhiTxt,str)
		end
	end
end

function UINewSagaStarPre:CreateStarList(star)
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

function UINewSagaStarPre:RefreshAwakenView()
	local treeRefId	= gModelHero:GetHeroAwakenByRefId(self._refId)
	if treeRefId == 0 then return end
	self._treeRefId = treeRefId
	local heroTreeInfoList = gModelHero:GetFakeMaxAwakenDataByRefId(treeRefId)
	if not heroTreeInfoList then return end
	self._heroTreeInfoList	= heroTreeInfoList

	local curSelectTreePointId
	if not self._curSelectTreePointId then
		curSelectTreePointId = self:GetDefaultSelectTreePoint()
	end

	self:RefreshAwakenTree()
	self:RefreshAwakenDetails()

	local starIndex = self._curStarIndex or 1
	local starRef = self._starList[starIndex]
	local effectId = starRef.effectId
	local effRef = gModelHero:GetShowEffectById(effectId)
	local heroName = ccLngText(effRef.name)
	self:SetWndText(self.mShiftUpStarText,heroName)

	local quality = starRef.quality
	local qualityRef 	  = gModelItem:GetQualityRef(quality)

	if curSelectTreePointId then
		self:OnClickTreePoint(curSelectTreePointId)
	end
end

function UINewSagaStarPre:RefreshSkillList(star,grade)
	local refId = self._refId
	local heroSkillIdList = gModelHero:GetSkillListByRefIdAndStar(refId,star)

	local list = {}
	for i = 1,4 do
		local skillData = heroSkillIdList[i]
		local data = {
			refId = refId,
			star = star,
			index = i,
			grade = grade
		}
		if skillData then
			data.skillId = skillData.skillId
			data.openClass = skillData.openClass
		end
		table.insert(list,data)
	end

	local uiSkillList = self._uiSkillList
	if uiSkillList then
		uiSkillList:RefreshList(list)
	else
		uiSkillList = self:GetUIScroll("uiSkillList")
		self._uiSkillList = uiSkillList
		uiSkillList:Create(self.mSkillList,list,function(...) self:OnDrawSkillCell(...) end)
	end
end

function UINewSagaStarPre:OnClickShiftUpStarEvent()
	self:SetStarPageShow(UINewSagaStarPre.PAGE_COMMON)
end

function UINewSagaStarPre:CreateAttrList(attrList)
	local uiAttrList = self._uiAttrList
	if uiAttrList then
		uiAttrList:RefreshList(attrList)
	else
		uiAttrList = self:GetUIScroll("uiAttrList")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mAttrList,attrList,function(...) self:OnDrawAttrCell(...) end)
	end
end

function UINewSagaStarPre:Init(refresh)
	self:ShowNormal()

	local refId = self._refId
	local heroRef  = gModelHero:GetHeroRef(refId)
	if not heroRef then return end
	local raceId = heroRef.raceType
	local raceRef = gModelHero:GetHeroRaceRefByRefId(raceId)
	if not raceRef then return end
	local careerType = heroRef.careerType
	local careerRef = GameTable.CharacterCareerRef[careerType]
	if not careerRef then return end
	local initStar = heroRef.initStar

	self._starList = {}
	self._classList = {}

	local starType = heroRef.starType
	local maxStar = heroRef.maxStar
	self._maxStar = maxStar

	--只显示最大星级 或 10 星

	for i = maxStar,initStar,-1 do
		local starId = gModelHero:GetStarId(starType,i)
		local starRef = gModelHero:GetHeroStarById(starId)
		if starRef and starRef.preview == 1 then
			table.insert(self._starList,starRef)
			break
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

	self._btnTrans = {}

	if refresh then
		self:InitBtnList()
		self:Refresh(self._starList[1])
	end
end

function UINewSagaStarPre:OnClickAwakenEvent()
	self._curSelectTreePointId = nil
	self:SetStarPageShow(UINewSagaStarPre.PAGE_AWAKEN)
end

function UINewSagaStarPre:CreateGradeList(grade)
	local list = self:GetGradeList(grade)
	local uiGradeList = self._uiGradeList
	if uiGradeList then
		uiGradeList:RefreshList(list)
	else
		uiGradeList = self:GetUIScroll("uiGradeList")
		self._uiGradeList = uiGradeList
		uiGradeList:Create(self.mGradeList,list,function(...) self:OnDrawGradeCell(...) end)
	end
end

function UINewSagaStarPre:GetMaxClass(lv)
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


function UINewSagaStarPre:GetGradeList(grade)
	local list = {}
	local refId = self._refId
	local heroRef = gModelHero:GetHeroRef(refId)
	if not heroRef then return list end
	local classType = heroRef.classType
	local refList = {}
	for k,v in pairs(GameTable.CharacterClassRef) do
		if v.grade ~= 0 and v.type == classType then
			table.insert(refList,v)
		end
	end
	table.sort(refList,function(a,b) return a.grade < b.grade end)
	for i = 1,UINewSagaStarPre.MAX_GRADE_NUM do
		local refData = refList[i]
		local haveData = refData ~= nil or false
		-- -1代表没有开启
		local garde = refData and refData.grade or -1
		local act = garde <= grade and garde ~= -1
		local data = {
			grade = garde,
			needLevel = refData and refData.needLevel or -1,
			haveData = haveData,
			act = act,
		}
		table.insert(list,data)
	end
	return list
end


------------------------------------------------------------------
return UINewSagaStarPre


