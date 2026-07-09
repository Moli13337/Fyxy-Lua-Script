---
--- Created by Administrator.
--- DateTime: 2023/10/1 18:21:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeSelSaga:LWnd
local UIHopeSelSaga = LxWndClass("UIHopeSelSaga", LWnd)
------------------------------------------------------------------
UIHopeSelSaga.SELHERO_NUM = 5



--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeSelSaga:UIHopeSelSaga()
	---@type table<number,CommonIcon>
	self._heroIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeSelSaga:OnWndClose()
	self:ClearCommonIconList(self._heroIconList)
	if self._func then
		self._func()
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeSelSaga:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeSelSaga:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEmptyList()
	self:InitTxt()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitRaceTypeList()
	self:InitHeroList()
	self:InitSelHeroList()
end

function UIHopeSelSaga:GetAllHeroList()
	local list = {}
	local herostar = gModelDreamTrip:GetConfigByKey("herostar")
	local allHeroList = gModelHero:GetHeroSortList()
	table.sort(allHeroList,function(hero1,hero2)
		local power1,power2 = hero1:GetPower(),hero2:GetPower()
		return power1 > power2
	end)


	for i,v in ipairs(allHeroList) do
		local serverData = v:GetServerData()
		if serverData then
			local refId = serverData.refId
			local ins = false
			if self._raceType == 0 then
				ins = true
			else
				local race = gModelHero:GetHeroRace(refId)
				ins = race == self._raceType and true or false
			end
			if ins then
				ins = serverData.star >= herostar
			end
			if ins and not self._isShowTryHero then
				ins =  not serverData.isTry
			end

			if ins then
				table.insert(list,{
					id = serverData.id,
				})
			end
		end
	end
	local selHeroLen = #self._selHeroList
	if selHeroLen < UIHopeSelSaga.SELHERO_NUM and self._init then
		for i,v in ipairs(list) do
			local id = v.id
			local isMax = #self._selHeroList < UIHopeSelSaga.SELHERO_NUM
			if not isMax then
				break
			end
			if not self._selHeroListKey[id] and isMax then
				self._selHeroListKey[id] = id
				table.insert(self._selHeroList,{id = id})
			end
		end
		self._init = false
	end
	return list
end

function UIHopeSelSaga:AutoUpBtnEvent()
	local list = self:GetAllHeroList()
	local index = 0
	self._selHeroList = {}
	self._selHeroListKey = {}
	local autoSelList = {}
	for i,v in ipairs(list) do
		if index >= UIHopeSelSaga.SELHERO_NUM then
			break
		end
		local id = v.id
		table.insert(autoSelList,{id = id})
		self._selHeroListKey[id] = id
		index = index + 1
	end
	self._selHeroList = autoSelList
	self:InitSelHeroList()
	self:RefreshAllHeroList()
end

function UIHopeSelSaga:InitSelHeroList()
	local list = self:GetSelHeroList()
	self:RefreshPower()
	local uiSelHeroList = self._uiSelHeroList
	if uiSelHeroList then
		uiSelHeroList:RefreshData(list)
	else
		uiSelHeroList = self:GetUIScroll("uiSelHeroList")
		self._uiSelHeroList = uiSelHeroList
		uiSelHeroList:Create(self.mSelHeroList,list,function(...) self:OnDrawSelHeroCell(...) end)
		uiSelHeroList:EnableScroll(false)
	end
end

function UIHopeSelSaga:OnDrawSelHeroCell(list,item,itemdata,itempos)
	local Root = self:FindWndTrans(item,"Root")
	local Add = self:FindWndTrans(item,"Add")

	local instanceID = item:GetInstanceID()
	local selStatus,id = itemdata.selStatus,itemdata.id

	CS.ShowObject(Root,selStatus)
	CS.ShowObject(Add,not selStatus)

	if selStatus and id ~= nil then
		local heroIconList = self._heroIconList
		local baseClass = heroIconList[instanceID]
		if not baseClass then
			baseClass = CommonIcon:New(self)
			heroIconList[instanceID] = baseClass
			baseClass:Create(Root)
		end
		baseClass:SetHeroPlayer(id)
		baseClass:DoApply()
	end

	self:SetWndClick(Root,function()
		if id and id ~= "" then
			self:SelHeroEvent(id)
		end
	end)
end

function UIHopeSelSaga:InitEvent()
	self:SetWndClick(self.mAutoBtn,function()
		self:AutoUpBtnEvent()
	end)
	self:SetWndClick(self.mGoToBtn,function()
		self:GoToBtnEvent()
	end)
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIHopeSelSaga:InitEmptyList()
	local data = {
		refId = 10008,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIHopeSelSaga:RefreshPower()
	local power = 0
	for i,v in ipairs(self._selHeroList) do
		local serverData = gModelHero:GetHeroServerDataById(v.id)
		if serverData then
			power = power + serverData.fightPower
		end
	end
	local powerNum = LUtil.FormatPowerShowStr(power) --LUtil.FormatCoversionHurtNumSpriteText(power,nil,nil, 20)
	self:SetWndText(self.mPowerTxt,powerNum)
end

function UIHopeSelSaga:SelHeroEvent(id)
	local len = #self._selHeroList
	local isHave = self._selHeroListKey[id]
	if isHave then
		self._selHeroListKey[id] = nil
		local list = {}
		for i,v in ipairs(self._selHeroList) do
			local curId = v.id
			if curId ~= id then
				table.insert(list,{id = curId})
			end
		end
		self._selHeroList = list
	else
		if len >= UIHopeSelSaga.SELHERO_NUM then
			return
		end
		self._selHeroListKey[id] = id
		table.insert(self._selHeroList,{id = id})
	end
	self:InitSelHeroList()
	self:RefreshAllHeroList()
end

function UIHopeSelSaga:RefreshAllHeroList()
	local uiAllHeroList = self._uiAllHeroList
	if uiAllHeroList then
		local uiList = uiAllHeroList:GetList()
		uiList:DrawAllItems()
	end
end

function UIHopeSelSaga:InitTxt()
	self:SetWndText(self.mTitle,ccClientText(20420))
	self:SetTextTile(self.mTextTitle,ccClientText(20423))
	self:SetWndButtonText(self.mAutoBtn,ccClientText(20421))
	self:SetWndButtonText(self.mGoToBtn,ccClientText(20422))

	local isForeign = gLGameLanguage:IsForeignVersion()
	if isForeign then
		self:SetWndText(self.mCloseTipEn, ccClientText(20479))
	else
		self:SetWndText(self.mCloseTip,ccClientText(20479))
	end
	CS.ShowObject(self.mCloseTip, not isForeign)
	CS.ShowObject(self.mCloseTipEn, isForeign)
end

function UIHopeSelSaga:GoToBtnEvent()
	local selHeroList = self._selHeroList
	local len = #selHeroList
	if len <= 0 then
		GF.ShowMessage(ccClientText(20445))
		return
	end
	local func = function()
		gModelDreamTrip:OnDreamTripSelectHeroReq(selHeroList,self._mapRefId)
	end
	if len < UIHopeSelSaga.SELHERO_NUM then
		-- 弹窗提示
		gModelGeneral:OpenUIOrdinTips({refId = 230003,func = func})
	else
		func()
	end

end

function UIHopeSelSaga:InitHeroList()
	local list = self:GetAllHeroList()

	local uiAllHeroList = self._uiAllHeroList
	if uiAllHeroList then
		uiAllHeroList:RefreshList(list,false)
	else
		uiAllHeroList = self:GetUIScroll("uiAllHeroList")
		self._uiAllHeroList = uiAllHeroList
		uiAllHeroList:Create(self.mAllHeroList,list,function(...) self:OnDrawAllHeroCell(...) end,UIItemList.WRAP,false)
		uiAllHeroList:EnableLoadAnimation(true, 0, 4)
	end
	local uiList = uiAllHeroList:GetList()
	uiList:RefreshList(UIListWrap.RefreshMode.Solid)

	local isEmpty = #list < 1
	CS.ShowObject(self.mNoRecord2,isEmpty)
end

function UIHopeSelSaga:OnDrawAllHeroCell(list,item,itemdata,itempos)
	local Root = self:FindWndTrans(item,"Root")

	local instanceID = item:GetInstanceID()
	local id = itemdata.id

	local heroIconList = self._heroIconList
	local baseClass = heroIconList[instanceID]
	if not baseClass then
		baseClass = CommonIcon:New(self)
		heroIconList[instanceID] = baseClass
		baseClass:Create(Root)
	end
	baseClass:SetHeroPlayer(id)
	local showMask = self._selHeroListKey[id] ~= nil or false
	baseClass:ShowGouImg(showMask)
	baseClass:DoApply()

	self:SetWndClick(Root,function()
		self:SelHeroEvent(id)
	end)
end

function UIHopeSelSaga:InitRaceTypeList()
	local data = {
		wndClass = self,
		listTrans = self.mHeroRaceList,
		showType = UIHeroRaceList.TYPE_NORMAL,
		showListBg = true,
		callbackFunc = function(raceType)
			if not self:IsWndValid() then return end
			if raceType == self._raceType then return end
			self:ChangeRaceTypeEvent(raceType)
		end,
		checkSelFunc = function(raceType)
			if not self:IsWndValid() then return end
			return self._raceType == raceType
		end,
	}
	self:GetUIHeroRaceList(data)
end

function UIHopeSelSaga:InitData()
	self._mapRefId = self:GetWndArg("mapRefId")
	self._func = self:GetWndArg("func")
	self._raceType = 0
	self._selHeroList = {}
	self._selHeroListKey = {}
	self._init = true
	self._isShowTryHero = gModelBattle:CheckCombatPlayCampShowHeroFree(LCombatTypeConst.COMBAT_DREAMTRIP)
end

function UIHopeSelSaga:InitMsg()
	self:WndNetMsgRecv(LProtoIds.DreamTripSelectHeroResp,function()
		self:WndClose()
	end)
end

function UIHopeSelSaga:GetSelHeroList()
	local list = {}
	local selHeroList = self._selHeroList
	for i = 1,UIHopeSelSaga.SELHERO_NUM do
		local selData = selHeroList[i]
		local isSel = selData ~= nil
		local id = isSel and selData.id or ""
		table.insert(list,{
			id = id,
			selStatus = isSel,
		})
	end
	return list
end

function UIHopeSelSaga:ChangeRaceTypeEvent(race)
	if self._raceType == race then return end
	self._raceType = race
	self:InitHeroList()
end
------------------------------------------------------------------
return UIHopeSelSaga


