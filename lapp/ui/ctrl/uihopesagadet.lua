---
--- Created by Administrator.
--- DateTime: 2023/10/6 10:22:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeSagaDet:LWnd
local UIHopeSagaDet = LxWndClass("UIHopeSagaDet", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeSagaDet:UIHopeSagaDet()
	self._commonUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeSagaDet:OnWndClose()
	self:ClearCommonIconList(self._commonUIList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeSagaDet:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeSagaDet:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mTitle,ccClientText(20403))
	self:SetWndButtonText(self.mUseBtn,ccClientText(20443))
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:Refresh()
	self:InitHeroList()
	self:InitUseList()
end

function UIHopeSagaDet:GetSelHeroList(recordHeroList)
	recordHeroList = recordHeroList or {}
	local list = {}
	local selList = gModelDreamTrip:GetSelHeroList()
	local showEff
	for i,v in ipairs(selList) do
		showEff = recordHeroList[v.id] ~= nil and true or false
		table.insert(list,{
			showEff = showEff,
			playerInfo = v
		})
	end
	table.sort(list,function(a,b)
		local heroA,heroB = a.playerInfo,b.playerInfo
		return heroA.power > heroB.power
	end)
	return list
end

function UIHopeSagaDet:GetUseItemList()
	local list = {}
	local itemList = gModelDreamTrip:GetConfigByKey("useItemList")
	if itemList then
		for idx,itemInfo in ipairs(itemList) do
			local canSelList = {}
			local itemId = itemInfo[1]
			local itemNum = 0
			for i,v in ipairs(itemInfo) do
				local haveNum = gModelItem:GetNumByRefId(v)
				if haveNum > 0 then
					table.insert(canSelList,{
						refId = v,
						haveNum = haveNum,
					})
					itemId = v
				end
				itemNum = itemNum + haveNum
			end
			local ref = gModelItem:GetRefByRefId(itemId)
			table.insert(list,{
				itemType = LItemTypeConst.TYPE_ITEM,
				refId = itemId,
				haveNum = itemNum,
				itemName = ccLngText(ref.name),
				itemEff = ccLngText(ref.description),
				canSelList = canSelList,
			})
		end
	end
	return list
end

function UIHopeSagaDet:OnDrawUseItemCell(list,item,itemdata,itempos)
	local refId = itemdata.refId
	local itemType = itemdata.itemType
	local haveNum = itemdata.haveNum
	local InstanceID = item:GetInstanceID()
	local isSel = false
	local canSelList = itemdata.canSelList
	for i,v in ipairs(canSelList) do
		if isSel then break end
		isSel = v.refId == self._useItemId
	end
	local OnImage = self:FindWndTrans(item,"OnImage")
	CS.ShowObject(OnImage,isSel)

	local CommonUI = self:FindWndTrans(item,"CommonUI")
	if CommonUI then
		local commonUIList = self._commonUIList
		if not commonUIList then
			commonUIList = {}
			self._commonUIList = commonUIList
		end
		local baseClass = commonUIList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New(self)
			commonUIList[InstanceID] = baseClass
			baseClass:Create(CS.FindTrans(CommonUI,"Icon"))
		end
		baseClass:SetCommonReward(itemType, refId, haveNum)
		local showNum = haveNum > 0
		baseClass:EnableShowNum(showNum)
		baseClass:DoApply()
	end

	self:SetWndClick(CommonUI,function()
		gModelGeneral:OpenItemInfoTip(refId,haveNum,nil,nil,nil,nil,nil,true)
	end)

	local ItemName = self:FindWndTrans(item,"ItemName")
	if ItemName then
		local fcolor = gModelItem:GetItemNameColor(refId)
		self:SetXUITextTransColor(ItemName,fcolor)

		self:SetWndText(ItemName,itemdata.itemName)
	end
--[[	local HaveNum = self:FindWndTrans(item,"HaveNum")
	if HaveNum then
		self:SetWndText(HaveNum,haveNum)
	end]]
	local EffDesc = self:FindWndTrans(item,"EffDesc")
	if EffDesc then
		self:SetWndText(EffDesc,itemdata.itemEff)
		self:InitTextModeWithLanguage(EffDesc)
	end

	self:SetWndClick(item,function()
		self:ClickItemEvent(itemdata)
	end)
end

function UIHopeSagaDet:OnDrawSelHeroCell(list,item,itemdata,itempos)
	local HeroIcon = self:FindWndTrans(item,"HeroIcon")
	local Icon = self:FindWndTrans(HeroIcon,"Icon")
	local blood = self:FindWndTrans(item,"blood")
	local deadTag = self:FindWndTrans(item,"deadTag")
	local hireTag = self:FindWndTrans(item,"hireTag")
	local Eff = self:FindWndTrans(item,"Eff")
	local SelTag = self:FindWndTrans(item,"SelTag")

	local showEff,playerInfo = itemdata.showEff,itemdata.playerInfo
	local InstanceID = item:GetInstanceID()
	local id = playerInfo.id

	if showEff then
		self:CreateWndEffect(Eff,"fx_qjtx_wupinshuaxin",InstanceID,100,false)
	end
	CS.ShowObject(Eff,showEff)

	local curHp,maxHp = playerInfo.curHp,playerInfo.maxHp
	local isDel = curHp <= 0

	if HeroIcon then
		local commonUIList = self._commonUIList
		if not commonUIList then
			commonUIList = {}
			self._commonUIList = commonUIList
		end
		local baseClass = commonUIList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New(self)
			commonUIList[InstanceID] = baseClass
			baseClass:Create(Icon)
		end

		local herodata = {}
		herodata.trans = Icon
		herodata.id = id
		herodata.refId = playerInfo.refId
		herodata.star = playerInfo.star
		herodata.level = playerInfo.lvl
		herodata.isResonance = playerInfo.resonance
		herodata.skin = playerInfo.skin
		herodata = playerInfo.power,
		baseClass:SetHeroDataSet(herodata)
		baseClass:DoApply()

		local showMask = self._selHeroId and self._selHeroId == id or false
		CS.ShowObject(SelTag,showMask)

		self:SetWndClick(HeroIcon,function()
			self:SelHeroEvent(id)
		end)

		local heroData = {
			id = id,
			refId = playerInfo.refId,
			star = playerInfo.star,
			level = playerInfo.lvl,
			isResonance = playerInfo.resonance,
			skin = playerInfo.skin,
			fightPower = gModelHero:FindHeroPowerById(id),
			grade = playerInfo.grade,
		}
		self:SetWndLongClick(HeroIcon,function()
			gModelHero:ReqShowHeroTip("",heroData)
		end,0.8,false)
	end

	if blood then
		local value = 0
		if not isDel then
			value = curHp / maxHp
		end
		LxUiHelper.SetProgress(blood,value)
	end

	if deadTag then
		CS.ShowObject(deadTag,isDel)
	end

	if hireTag then
		local heroType = playerInfo.heroType
		CS.ShowObject(hireTag,heroType == 2)
	end
end

function UIHopeSagaDet:InitUseList()
	local list = self:GetUseItemList()
	local uiUseItemList = self._uiUseItemList
	if uiUseItemList then
		uiUseItemList:RefreshData(list)
	else
		uiUseItemList = self:GetUIScroll("uiUseItemList")
		self._uiUseItemList = uiUseItemList
		uiUseItemList:Create(self.mUseList,list,function(...) self:OnDrawUseItemCell(...) end,UIItemList.WRAP)
	end
end

function UIHopeSagaDet:InitHeroList(recordHeroList)
	local list = self:GetSelHeroList(recordHeroList)
	local uiSelHeroList = self._uiSelHeroList
	if uiSelHeroList then
		uiSelHeroList:RefreshData(list)
	else
		uiSelHeroList = self:GetUIScroll("uiSelHeroList")
		self._uiSelHeroList = uiSelHeroList
		uiSelHeroList:Create(self.mHeroList,list,function(...) self:OnDrawSelHeroCell(...) end,UIItemList.WRAP)
	end
end

function UIHopeSagaDet:SelHeroEvent(heroId)
	if self._selHeroId == heroId then return end
	self._selHeroId = heroId

--[[	local uiSelHeroList = self._uiSelHeroList
	if uiSelHeroList then
		local uiList = uiSelHeroList:GetList()
		uiList:RefreshList()
	end]]
	self:InitHeroList()
end

function UIHopeSagaDet:InitMsg()
	self:WndNetMsgRecv(LProtoIds.DreamTripItemUseResp,function(pb,ret)
		GF.ShowMessage(ccClientText(20495))
		local info = pb.info
		local serverData
		local recordHeroList = {}
		for i,v in ipairs(info) do
			serverData = gModelDreamTrip:GetMonsterInfoByPb(v)
			if serverData then
				recordHeroList[serverData.id] = true
			end
		end
		self:Refresh()
		self:InitHeroList(recordHeroList)
		self:InitUseList()
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function()
		self:InitUseList()
	end)
end

function UIHopeSagaDet:InitEvent()
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mUseBtn,function()
		self:UseEvent()
	end)
end

function UIHopeSagaDet:Refresh()
	local selList = gModelDreamTrip:GetSelHeroList()
	local itemList = gModelDreamTrip:GetConfigByKey("useItemList")

	--优先级：未满血+回复＞已阵亡+复活＞满血
	--同样状态有多个时，默认选中战力最高的那个（这块跟文档不同，稍后更新文档）

	local useItemId,selHeroId
	local isSelHero = false
	local injuredList = {} 			-- 未满血
	local dealHeroList = {} 		-- 已阵亡
	local curHp,maxHp
	for i,v in ipairs(selList) do
		curHp,maxHp = v.curHp,v.maxHp
		if curHp < maxHp and curHp > 0 then
			table.insert(injuredList,v)
		end
		if curHp == 0 then
			table.insert(dealHeroList,v)
		end
	end

	local sortFunc = function(heroA,heroB)
		return heroA.power > heroB.power
	end

	-- 未满血+回复
	local injuredLen = #injuredList
	if not isSelHero and injuredLen > 0 then
		table.sort(injuredList,sortFunc)
		isSelHero = true
		selHeroId = injuredList[1].id

		local firstRefId
		local selItem
		for i,v in ipairs(itemList) do
			if selItem then break end
			for k,refId in ipairs(v) do
				if not firstRefId then firstRefId = refId end
				local haveNum = gModelItem:GetNumByRefId(refId)
				if haveNum > 0 then
					useItemId = refId
					selItem = true
					break
				end
			end
		end
		if not useItemId then
			useItemId = firstRefId
		end
	end

	-- 已阵亡+复活
	local dealHeroLen = #dealHeroList
	if not isSelHero and dealHeroLen > 0 then
		table.sort(dealHeroList,sortFunc)
		isSelHero = true
		selHeroId = dealHeroList[1].id

		local firstRefId

		for k,refId in ipairs(itemList[2] or {}) do
			if not firstRefId then firstRefId = refId end
			local haveNum = gModelItem:GetNumByRefId(refId)
			if haveNum > 0 then
				useItemId = refId
				break
			end
		end
		if not useItemId then
			useItemId = firstRefId
		end
	end

	if not selHeroId then
		table.sort(selList,sortFunc)
		selHeroId = selList[1].id
		local firstRefId
		local selItem
		for i,v in ipairs(itemList) do
			if selItem then break end
			for k,refId in ipairs(v) do
				if not firstRefId then firstRefId = refId end
				local haveNum = gModelItem:GetNumByRefId(refId)
				if haveNum > 0 then
					useItemId = refId
					selItem = true
					break
				end
			end
		end
		if not useItemId then
			useItemId = firstRefId
		end
	end

	self._selHeroId = selHeroId
	self._useItemId = useItemId
end

function UIHopeSagaDet:InitData()
	self._selHeroId = nil
	self._useItemId = nil
end

function UIHopeSagaDet:ClickItemEvent(itemdata)
	local haveNum = itemdata.haveNum
	if haveNum <= 0 then
		GF.ShowMessage(ccClientText(20436))
		return
	end
	local canSelList = itemdata.canSelList
	local itemId
	for i,v in ipairs(canSelList) do
		if v.haveNum > 0 then
			itemId = v.refId
			break
		end
	end
	if not itemId then return end
	self._useItemId = itemId
	local uiUseItemList = self._uiUseItemList
	if uiUseItemList then
		local uiList = uiUseItemList:GetList()
		uiList:RefreshList()
	end
end

function UIHopeSagaDet:UseEvent()
	local itemId,targetId = self._useItemId,self._selHeroId
	if not itemId then
		GF.ShowMessage(ccClientText(20435))
		return
	end
	if not targetId then
		GF.ShowMessage(ccClientText(20434))
		return
	end
	gModelDreamTrip:OnDreamTripItemUseReq(itemId,targetId)
end
------------------------------------------------------------------
return UIHopeSagaDet


