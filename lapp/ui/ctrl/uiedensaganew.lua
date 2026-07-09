---
--- Created by Administrator.
--- DateTime: 2023/10/26 16:46:03
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenSagaNew:LWnd
local UIEdenSagaNew = LxWndClass("UIEdenSagaNew", LWnd)

UIEdenSagaNew.TYPE_POWER = 0				-- 战力
UIEdenSagaNew.TYPE_ATTR = 1				-- 攻击
UIEdenSagaNew.TYPE_MAXHP = 3				-- 生命
UIEdenSagaNew.TYPE_DEF = 4				-- 防御
UIEdenSagaNew.TYPE_SPEED = 5				-- 速度

UIEdenSagaNew.GET_HERO_ATTR_NUM = 20		-- 每次请求20个英雄的属性
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenSagaNew:UIEdenSagaNew()
	---@type table<number,CommonIcon>
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenSagaNew:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	self._uiCommonList = nil
	if #self._selHeroList > 0 then
		-- gModelTreasure:OnTreasureChoiceHeroReq(ModelTreasure.TYPE_OPT_CHANGHERO,self._selHeroList)
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenSagaNew:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenSagaNew:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitHeroList()

	self:RefreshSelFunc()
	-- gModelTreasure:OnTreasureChoiceHeroReq(ModelTreasure.TYPE_OPT_MEAN)
end

function UIEdenSagaNew:InitMsg()
	-- self:WndNetMsgRecv(LProtoIds.TreasureChoiceHeroResp, function(pb,ret)
	-- 	local ttype = pb.type
	-- 	if ttype == ModelTreasure.TYPE_OPT_MEAN then
	-- 		self:RefreshData(pb)
	-- 	elseif ttype == ModelTreasure.TYPE_OPT_CHANGHERO then
	-- 		self:RefreshData(pb)
	-- 	elseif ttype == ModelTreasure.TYPE_OPT_LOOKHERO then
	-- 		self:DisposeAttrList(pb.attrs)
	-- 	end
	-- end)
end

function UIEdenSagaNew:RefreshHeroList(heroIds)
	local selHeroList = {}
	self._selHeroList = {}
	self._selHeroKeyList = {}
	for i,v in ipairs(heroIds) do
		table.insert(self._selHeroList,v)
		self._selHeroKeyList[v] = true
		table.insert(selHeroList,v)
	end
	self:InitHeroList()
	self:RefreshSelDiv(selHeroList)
end

function UIEdenSagaNew:RefreshSelFunc()
	local selTypeList = self._selTypeList
	if not selTypeList then return end
	local selData = self:GetSelData()
	if not selData then return end
	local iconImg = selData.iconImg
	self:SetWndEasyImage(self.mSortIcon,iconImg)
	local attrName = selData.attrName
	self:SetWndText(self.mSortName,attrName)
end

function UIEdenSagaNew:ClickHeroId(opt,id)
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
	else
		self._selHeroList = list
		-- gModelTreasure:OnTreasureChoiceHeroReq(ModelTreasure.TYPE_OPT_CHANGHERO,self._selHeroList)
	end
end

function UIEdenSagaNew:GetNetAttr(idList)
	-- gModelTreasure:OnTreasureChoiceHeroReq(ModelTreasure.TYPE_OPT_LOOKHERO,idList,self._selType)
end

function UIEdenSagaNew:RefreshData(pb)
	local heroIds = pb.heroIds
	local filtraList = {}
	for i,v in ipairs(heroIds) do
		local serverData = gModelHero:GetHeroServerDataById(v)
		local isBag = serverData ~= nil
		if isBag then table.insert(filtraList,v) end
	end
	self:RefreshHeroList(filtraList)
end

function UIEdenSagaNew:GetAttrInfo()
	local heroList = self:GetHeroList()
--[[	local starNum = self._starNum + 1
	local endNum = self._starNum + UIEdenSagaNew.GET_HERO_ATTR_NUM
	local idList = {}
	for i = starNum,endNum do
		local hero = heroList[i]
		if hero then
			local id = hero.id
			local attrData = self:GetAttrDataById(id)
			if attrData == 0 then
				table.insert(idList,id)
			end
		end
	end]]

	local idList = {}
	local isHaveData = false
	local firstHeroId = heroList and heroList[1]
	if firstHeroId then
		local isHaveAttr = self:GetAttrDataById(firstHeroId.id)
		isHaveData = isHaveAttr and isHaveAttr > 0 or false
	end
	local selType = self._selType
	if isHaveData or selType == UIEdenSagaNew.TYPE_POWER then
		self:InitHeroList()
		return
	end
	if not isHaveData then
		for i,v in ipairs(heroList) do
			table.insert(idList,v.id)
		end
		if #idList > 0 then
			self:GetNetAttr(idList)
		end
	end
end

function UIEdenSagaNew:InitData()
	self._selHeroList = {}
	self._heroPowerList = {}				-- 英雄战力列表
	self._heroAttrList = {} 				-- 英雄属性列表
	self._starNum = 0						-- 从0开始请求数据
	self._isJumpTop = false 				-- 是否跳到最顶
	self._selTypeList = {
		[UIEdenSagaNew.TYPE_POWER] = {
			selType = UIEdenSagaNew.TYPE_POWER,
			iconImg = "icon_item_fight",
			attrName = ccClientText(21201)
		},
		[UIEdenSagaNew.TYPE_ATTR] = {
			selType = UIEdenSagaNew.TYPE_ATTR,
			iconImg = gModelHero:GetAttributeIconById(UIEdenSagaNew.TYPE_ATTR),
			attrName = gModelHero:GetAttributeNameById(UIEdenSagaNew.TYPE_ATTR)
		},
		[UIEdenSagaNew.TYPE_MAXHP] = {
			selType = UIEdenSagaNew.TYPE_MAXHP,
			iconImg = gModelHero:GetAttributeIconById(UIEdenSagaNew.TYPE_MAXHP),
			attrName = gModelHero:GetAttributeNameById(UIEdenSagaNew.TYPE_MAXHP)
		},
		[UIEdenSagaNew.TYPE_DEF] = {
			selType = UIEdenSagaNew.TYPE_DEF,
			iconImg = gModelHero:GetAttributeIconById(UIEdenSagaNew.TYPE_DEF),
			attrName = gModelHero:GetAttributeNameById(UIEdenSagaNew.TYPE_DEF)
		},
		[UIEdenSagaNew.TYPE_SPEED] = {
			selType = UIEdenSagaNew.TYPE_SPEED,
			iconImg = gModelHero:GetAttributeIconById(UIEdenSagaNew.TYPE_SPEED),
			attrName = gModelHero:GetAttributeNameById(UIEdenSagaNew.TYPE_SPEED)
		},
	}
	-- local ini = gModelTreasure:GetTreasureFilter()
	self._selType =ini or UIEdenSagaNew.TYPE_POWER

	self:GetAttrInfo()

	self._selHeroTrans = {
		{
			iconTrans = self.mCommonUI1,
			nameTrans = self.mHeroName1,
			heroBgTreans = self.mHeroBg1,
		},
		{
			iconTrans = self.mCommonUI2,
			nameTrans = self.mHeroName2,
			heroBgTreans = self.mHeroBg2,
		},
		{
			iconTrans = self.mCommonUI3,
			nameTrans = self.mHeroName3,
			heroBgTreans = self.mHeroBg3,
		},
		{
			iconTrans = self.mCommonUI4,
			nameTrans = self.mHeroName4,
			heroBgTreans = self.mHeroBg4,
		},
		{
			iconTrans = self.mCommonUI5,
			nameTrans = self.mHeroName5,
			heroBgTreans = self.mHeroBg5,
		},
	}

	self._maxNum = #self._selHeroTrans
end

function UIEdenSagaNew:CreateIcon(trans,key)
	local uiCommonList = self._uiCommonList
	local baseClass = uiCommonList[key]
	if not baseClass then
		baseClass = CommonIcon:New(self)
		uiCommonList[key] = baseClass
		baseClass:Create(CS.FindTrans(trans,"Icon"))
	end
	return baseClass
end

function UIEdenSagaNew:GetHeroList()
	local list = {}
	local heroList = gModelHero:GetPowerSortHeroList()
	if heroList then
		for i,v in ipairs(heroList) do
			local hero = v:GetServerData()
			table.insert(list,hero)
		end

		local powerSortFunc = function(heroA,heroB)
			return heroA.fightPower > heroB.fightPower
		end
		local attrCommonSortFunc = function(heroA,heroB)
			local heroIdA,heroIdB = heroA.id,heroB.id
			local num1,num2 = self:GetAttrDataById(heroIdA),self:GetAttrDataById(heroIdB)
			return num1 > num2
		end

		local sortFunc
		if self._selType == UIEdenSagaNew.TYPE_POWER then
			sortFunc = powerSortFunc
		else
			sortFunc = attrCommonSortFunc
		end
		if sortFunc then
			table.sort(list,sortFunc)
		end
	end
	return list
end

function UIEdenSagaNew:DisposeAttrList(attrs)
	local heroAttrList = self._heroAttrList
	if not heroAttrList then
		heroAttrList = {}
		self._heroAttrList = heroAttrList
	end
	for i,attrInfo in ipairs(attrs) do
		local attrHeroId = attrInfo.heroId
		local heroAttr = heroAttrList[attrHeroId]
		if not heroAttr then
			heroAttr = {}
			heroAttrList[attrHeroId] = heroAttr
		end
		local refId = attrInfo.refId
		heroAttr[refId] = attrInfo.value
	end
	local jumpTop = true
	if self._isJumpTop then
		self._isJumpTop = false
		jumpTop = false
	end
	self:InitHeroList(jumpTop)
end

function UIEdenSagaNew:RefreshSelDiv(selHeroList)
	local isForeign = gLGameLanguage:IsForeignRegion()
	local iconPos	= isForeign and Vector2.New(0,0) or Vector2.New(0,12.1)
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

			self:SetWndClick(iconTrans,function()
				-- self:ClickHeroId(ModelTreasure.TYPE_OPT_CHANGHERO,selId)
			end)
		end
		self:SetWndClick(heroBgTreans,function()
			if not show then GF.ShowMessage(ccClientText(19065)) end
		end)
		self:SetAnchorPos(iconTrans, iconPos)
		CS.ShowObject(iconTrans,show)
		CS.ShowObject(nameTrans,show)
	end
end

function UIEdenSagaNew:HideSelFunc()
	CS.ShowObject(self.mListMaskBg,false)
	CS.ShowObject(self.mSelSortList,false)
end

function UIEdenSagaNew:GetSelData()
	local selTypeList = self._selTypeList
	if not selTypeList then return end
	local selData = selTypeList[self._selType]
	return selData
end

function UIEdenSagaNew:GetSelList()
	local list = {}
	for k,v in pairs(self._selTypeList) do
		table.insert(list,v)
	end
	table.sort(list,function(a,b)
		return a.selType < b.selType
	end)
	return list
end

function UIEdenSagaNew:IsSel(id)
	local sel = false
	for i,v in ipairs(self._selHeroList) do
		if sel then break end
		sel = v == id
	end
	return sel
end

function UIEdenSagaNew:OnClickSel(selType)
	if self._selType == selType then
		self:HideSelFunc()
		return
	end

	-- gModelTreasure:SetTresureFilter(selType)

	self._selType = selType
	self._starNum = 0
	self._isJumpTop = true
	self:RefreshSelFunc()
	self:GetAttrInfo()
	self:HideSelFunc()
end

function UIEdenSagaNew:AutoSelHeroFunc()
	local heroList = self._heroList
	if heroList then
		local list = {}
		local selNum = 0
		for i,v in ipairs(heroList) do
			if selNum >= self._maxNum then break end
			table.insert(list,v.id)
			selNum = selNum + 1
		end
		self._selHeroList = list
		-- gModelTreasure:OnTreasureChoiceHeroReq(ModelTreasure.TYPE_OPT_CHANGHERO,self._selHeroList)
	end
end

function UIEdenSagaNew:OnDrawHeroCell(list,item, itemdata, itempos)
	local id = itemdata.id
	local instanceID = item:GetInstanceID()

	local sel = self:IsSel(id)
	local CommonUI = self:FindWndTrans(item,"CommonUI")
	if CommonUI then
		local baseClass = self:CreateIcon(CommonUI,instanceID)
		baseClass:SetHeroPlayer(id)
		baseClass:SetShowGouImg(sel)
		baseClass:DoApply()

		self:SetWndClick(CommonUI,function()
			-- self:ClickHeroId(ModelTreasure.TYPE_OPT_CHANGHERO,id)
		end)

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
		local selData = self:GetSelData()
		local IconTrans = self:FindWndTrans(PowerBg,"Icon")
		if IconTrans and selData then
			local iconImg = selData.iconImg
			self:SetWndEasyImage(IconTrans,iconImg)
		end
		local PowerText = self:FindWndTrans(PowerBg,"PowerText")
		if PowerText then
			local str,num
			if self._selType == UIEdenSagaNew.TYPE_POWER then
				num = itemdata.fightPower
			else
				num = self:GetAttrDataById(id)
			end

			local sizeRate = nil
			if gLGameLanguage:IsForeignVersion() then
				sizeRate = 150
			end
			str = LUtil.FormatCoversionHurtNumSpriteText(num,false, sizeRate, 12)
			self:SetWndText(PowerText,str)
		end
	end
end

function UIEdenSagaNew:InitHeroList(refreshData)
	local list = self:GetHeroList()
	self._heroList = list
	local uiHeroList = self._uiHeroList
	if uiHeroList then
		if refreshData then
			uiHeroList:RefreshData(list)
		else
			uiHeroList:RefreshList(list)
			local uiList = uiHeroList:GetList()
			uiList:RefreshList(UIListWrap.RefreshMode.Solid)
		end
	else
		uiHeroList = self:GetUIScroll("uiHeroList")
		self._uiHeroList = uiHeroList
		uiHeroList:Create(self.mHeroList,list,function(...) self:OnDrawHeroCell(...) end,UIItemList.WRAP)
	end
end

function UIEdenSagaNew:ShowSelTypeList()
	CS.ShowObject(self.mListMaskBg,true)
	CS.ShowObject(self.mSelSortList,true)

	local list = self:GetSelList()
	local uiSelSortList = self._uiSelSortList
	if uiSelSortList then
		uiSelSortList:RefreshList(list)
	else
		uiSelSortList = self:GetUIScroll("uiSelSortList")
		self._uiSelSortList = uiSelSortList
		uiSelSortList:Create(self.mSelSortList,list,function(...) self:OnDrawSelTypeCell(...) end)
	end
end

function UIEdenSagaNew:OnDrawSelTypeCell(list,item,itemdata,itempos)
	local SelImgTrans = self:FindWndTrans(item,"SelImg")
	local AttrIconTrans = self:FindWndTrans(item,"AttrIcon")
	local NameTrans = self:FindWndTrans(item,"Name")
	local SelNameTrans = self:FindWndTrans(item,"SelName")

	local selType = itemdata.selType
	local iconImg = itemdata.iconImg
	local attrName = itemdata.attrName

	local show = selType == self._selType
	CS.ShowObject(SelImgTrans,show)

	self:SetWndEasyImage(AttrIconTrans,iconImg)

	self:SetWndText(NameTrans,attrName)
	self:SetWndText(SelNameTrans,attrName)

	CS.ShowObject(NameTrans,not show)
	CS.ShowObject(SelNameTrans,show)

	self:SetWndClick(item,function()
		self:OnClickSel(selType)
	end)
end

function UIEdenSagaNew:InitText()
	self:SetWndText(self.mCloseTip,ccClientText(21203))
	self:SetWndText(self.mLblBiaoti,ccClientText(21202))
	self:SetWndText(self.mDescTxt,ccClientText(19033))
	self:InitTextLineWithLanguage(self.mDescTxt,-10)
	self:SetWndButtonText(self.mAutoSelBtn,ccClientText(14405))
end

function UIEdenSagaNew:GetAttrDataById(id)
	local heroAttrList = self._heroAttrList
	if not heroAttrList then return 0 end
	local heroAttr = heroAttrList[id]
	if not heroAttr then return 0 end
	return heroAttr[self._selType] or 0
end

function UIEdenSagaNew:InitEvent()
	self:SetWndClick(self.mBg,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mListMaskBg,function() self:HideSelFunc() end)
	self:SetWndClick(self.mShowListBtn,function() self:ShowSelTypeList() end)
	self:SetWndClick(self.mAutoSelBtn,function() self:AutoSelHeroFunc() end)
end
------------------------------------------------------------------
return UIEdenSagaNew


