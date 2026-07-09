---
--- Created by Administrator.
--- DateTime: 2023/10/25 11:58:40
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenSaga:LWnd
local UIEdenSaga = LxWndClass("UIEdenSaga", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenSaga:UIEdenSaga()
	---@type table<number,CommonIcon>
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenSaga:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	self._uiCommonList = nil

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenSaga:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenSaga:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitHeroList()

	-- self:ClickHeroId(ModelTreasure.TYPE_OPT_MEAN)
end

function UIEdenSaga:OnDrawAttrCell(list,item, itemdata, itempos)
	local refId,value = itemdata.refId,itemdata.value
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	if AttrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon,function()
			CS.ShowObject(AttrIcon,true)
		end)
	end
	if AttrName then
		local attrName = gModelHero:GetAttributeNameById(refId)
		self:SetWndText(AttrName,attrName)
	end
	if AttrValue then
		local valueStr = math.floor(value)
		--valueStr = "+" .. valueStr
		self:SetWndText(AttrValue,valueStr)
	end
end

function UIEdenSaga:IsSel(id)
	local sel = false
	for i,v in ipairs(self._selHeroList) do
		if sel then break end
		sel = v == id
	end
	return sel
end

function UIEdenSaga:InitAttrData()
	local list = {}
	for k,v in pairs(self._showAttrIdList) do
		table.insert(list,{
			refId = k,
			value = 0,
		})
	end
	return list
end

function UIEdenSaga:ClickHeroId(opt,id)
	if not self._selHeroList then self._selHeroList = {} end
	local list = {}
	if id then
		for i,v in ipairs(self._selHeroList) do
			table.insert(list,v)
		end

		local sel = false
		for i,v in ipairs(list) do
			sel = v == id
			if sel then
				table.remove(list,i)
				break
			end
		end
		if not sel then
			table.insert(list,id)
		end
	end
	local isMax = #list > self._maxNum

	if isMax then
		GF.ShowMessage(ccClientText(19064))
	-- else
	-- 	gModelTreasure:OnTreasureChoiceHeroReq(opt,list)
	end
end

function UIEdenSaga:RefreshData(pb)
	local heroIds = pb.heroIds
	local attrs = pb.attrs
	local filtraList = {}
	for i,v in ipairs(heroIds) do
		local serverData = gModelHero:GetHeroServerDataById(v)
		local isBag = serverData ~= nil
		if isBag then table.insert(filtraList,v) end
	end
	self:RefreshHeroList(filtraList)
	self:RefreshAttrList(attrs)
end

function UIEdenSaga:InitAttrList(attrList)
	local list = attrList or self:InitAttrData()
	local uiAttrList = self._uiAttrList
	if uiAttrList then
		uiAttrList:RefreshList(list)
	else
		uiAttrList = self:GetUIScroll("uiAttrList")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mAddAttrList,list,function(...) self:OnDrawAttrCell(...) end)
	end
end

function UIEdenSaga:RefreshSelDiv(selHeroList)
	for i,v in ipairs(self._selHeroTrans) do
		local selId = selHeroList[i]
		local show = selId ~= nil and selId ~= "0"
		local iconTrans,nameTrans,heroBgTreans = v.iconTrans,v.nameTrans,v.heroBgTreans
		if show then
			local serverData = gModelHero:GetHeroServerDataById(selId)
			if serverData then
				local key = "SelHeroCommon" .. i
				local baseClass = self:CreateIcon(iconTrans,key)
				baseClass:SetHeroPlayer(selId)
				baseClass:DoApply()

				local name = gModelHero:GetHeroNameByRefId(serverData.refId,serverData.star)
				self:SetWndText(nameTrans,name)
			end

			-- self:SetWndClick(iconTrans,function()
			-- 	self:ClickHeroId(ModelTreasure.TYPE_OPT_CHANGHERO,selId)
			-- end)
		end
		self:SetWndClick(heroBgTreans,function()
			if not show then GF.ShowMessage(ccClientText(19065)) end
		end)
		CS.ShowObject(iconTrans,show)
		CS.ShowObject(nameTrans,show)
	end
end

function UIEdenSaga:InitText()
	self:SetWndText(self.mCloseTip,ccClientText(19062))
	self:SetWndText(self.mTitle,ccClientText(19056))
	self:SetWndText(self.mCloseTip,ccClientText(19062))
	self:SetWndText(self.mDescTxt,ccClientText(19033))
	self:SetWndText(self.mArrowTitle,ccClientText(19032))
	self:SetWndButtonText(self.mAutoUpBtn,ccClientText(14405))
end

function UIEdenSaga:InitEvent()
	self:SetWndClick(self.mBg, function (...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function (...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mHelpTip, function(...)
		-- local tipId = gModelTreasure:GetTreasureConfigRefByKey("selHeroHelpTips")
		-- if tipId then
		-- 	GF.OpenWnd("UIBzTips",{refId = tipId})
		-- else
		-- 	local str = "TreasureConfigRef表没有配置 selHeroHelpTips 字段,麻烦策划兼容下"
		-- 	GF.ShowMessage(str)
		-- 	printInfoNR(str)
		-- end
	end)
	self:SetWndClick(self.mShowListBtn, function(...)

	end)

	self:SetWndClick(self.mAutoUpBtn,function()
		self:AutoUpHeroBtn()
	end)

	self:SetWndClick(self.mAllRaceBtn, function(...)
		self:RaceBtnEvent(0,self.mAllRaceBtn)
	end)

	local list = {
		self.mRaceBtn1,
		self.mRaceBtn2,
		self.mRaceBtn3,
		self.mRaceBtn4,
		self.mRaceBtn5,
	}
	for i,v in ipairs(list) do
		self:SetWndClick(v, function(...)
			self:RaceBtnEvent(i,v)
		end)
	end
end

function UIEdenSaga:RaceBtnEvent(race,btnTrans)
	if self._raceType == race then return end
	self._raceType = race
	CS.SetParentTrans(self.mRaceSelImg,btnTrans)
	self:InitHeroList(true)
end

function UIEdenSaga:InitData()
	self._sortList = {
		[1] = {
			target = 1,
			btnName = ccClientText(19059),
			sortFunc = function(a,b)

			end,
		},
		[2] = {
			target = 2,
			btnName = ccClientText(19060),
			sortFunc = function(a,b)

			end,
		},
		[3] = {
			target = 3,
			btnName = ccClientText(19061),
			sortFunc = function(a,b)

			end,
		},
	}

	self._selHeroList = {}

	self._raceType = 0

	self._showAttrIdList = {
		[LAttrConst.Atk] = true,
		[LAttrConst.MaxHP] = true,
		[LAttrConst.Def] = true,
		[LAttrConst.Speed] = true,
	}

	self._selHeroTrans = {
		[1] = {
			iconTrans = self.mCommonUI1,
			nameTrans = self.mHeroName1,
			heroBgTreans = self.mHeroBg1,
		},
		[2] = {
			iconTrans = self.mCommonUI2,
			nameTrans = self.mHeroName2,
			heroBgTreans = self.mHeroBg2,
		},
		[3] = {
			iconTrans = self.mCommonUI3,
			nameTrans = self.mHeroName3,
			heroBgTreans = self.mHeroBg3,
		},
		[4] = {
			iconTrans = self.mCommonUI4,
			nameTrans = self.mHeroName4,
			heroBgTreans = self.mHeroBg4,
		},
		[5] = {
			iconTrans = self.mCommonUI5,
			nameTrans = self.mHeroName5,
			heroBgTreans = self.mHeroBg5,
		},
	}

	self._maxNum = #self._selHeroTrans
end

function UIEdenSaga:InitMsg()
	self:WndNetMsgRecv(LProtoIds.TreasureChoiceHeroResp, function(pb,ret)
		self:RefreshData(pb)
	end)
end

function UIEdenSaga:RefreshHeroList(heroIds)
	local selHeroList = {}
	self._selHeroList = {}
	for i,v in ipairs(heroIds) do
		table.insert(self._selHeroList,v)
		table.insert(selHeroList,v)
	end
	self:InitHeroList()
	self:RefreshSelDiv(selHeroList)
end

function UIEdenSaga:InitHeroList(changeRace)
	local list = self:GetHeroList()
	self._heroList = list
	local uiHeroList = self._uiHeroList
	if uiHeroList then
		if changeRace then
			uiHeroList:RefreshList(list)
		else
			uiHeroList:RefreshData(list)
		end
	else
		uiHeroList = self:GetUIScroll("uiHeroList")
		self._uiHeroList = uiHeroList
		uiHeroList:Create(self.mHeroList,list,function(...) self:OnDrawHeroCell(...) end,UIItemList.WRAP)
		local uiList = uiHeroList:GetList()
		uiList:EnableLoadAnimation(true, 0, 5)
	end
end

function UIEdenSaga:RefreshAttrList(attrs)
	local list = {}
	for k,v in pairs(attrs) do
		local refId = v.refId
		local isIns = self._showAttrIdList and self._showAttrIdList[refId] or false
		if isIns then
			table.insert(list,{
				refId = refId,
				value = v.value
			})
		end
	end
	self:InitAttrList(list)
end

function UIEdenSaga:OnDrawHeroCell(list,item, itemdata, itempos)
	local id = itemdata.id
	local fightPower = itemdata.fightPower
	local instanceID = item:GetInstanceID()

	local sel = self:IsSel(id)
	local CommonUI = self:FindWndTrans(item,"CommonUI")
	if CommonUI then
		local baseClass = self:CreateIcon(CommonUI,instanceID)
		baseClass:SetHeroPlayer(id)
		baseClass:SetShowGouImg(sel)
		baseClass:DoApply()

		-- self:SetWndClick(CommonUI,function()
		-- 	self:ClickHeroId(ModelTreasure.TYPE_OPT_CHANGHERO,id)
		-- end)

		self:SetWndLongClick(CommonUI,function()
			local data = {
				id = id,
				refId = itemdata.refId,
				level = itemdata.lv,
				star = itemdata.star,
				grade = itemdata.grade,
				fightPower = itemdata.fightPower,
				isResonance = itemdata.isResonance,
				skin = itemdata.skin,
			}
			gModelHero:ReqShowHeroTip("",data)
		end)
	end
	local PowerBg = self:FindWndTrans(item,"PowerBg")
	if PowerBg then
		local PowerText = self:FindWndTrans(PowerBg,"PowerText")
		if PowerText then

			local fightPowerStr = LUtil.FormatCoversionHurtNumSpriteText(fightPower,false, nil, 14)
			self:SetWndText(PowerText,fightPowerStr)
		end
	end
end

function UIEdenSaga:GetHeroList()
	--local record  = gModelFormation:GetOnFormationHeros(LCombatTypeConst.COMBAT_MAIN)
	local heroList = gModelHero:GetPowerSortHeroList()
	local list = {}
	if heroList then
		for i,v in ipairs(heroList) do
			local hero = v:GetServerData()
			local refId = hero.refId
			local ref = gModelHero:GetHeroRef(refId)
			if ref then
				local race = ref.raceType
				if self._raceType == 0 then
					table.insert(list,hero)
				elseif race == self._raceType then
					table.insert(list,hero)
				end
			end
		end
	end

	return list
end

function UIEdenSaga:AutoUpHeroBtn()
	local selList = {}
	local list = self._heroList
	if list then
		local insNum = 0
		local maxNum = self._maxNum
		for i,v in ipairs(list) do
			if insNum >= maxNum then break end
			table.insert(selList,v.id)
			insNum = insNum + 1
		end
		-- gModelTreasure:OnTreasureChoiceHeroReq(1,selList)
	end
end

function UIEdenSaga:CreateIcon(trans,key)
	local uiCommonList = self._uiCommonList
	local baseClass = uiCommonList[key]
	if not baseClass then
		baseClass = CommonIcon:New(self)
		uiCommonList[key] = baseClass
		baseClass:Create(CS.FindTrans(trans,"Icon"))
	end
	return baseClass
end
------------------------------------------------------------------
return UIEdenSaga


