---
--- Created by LCM.
--- DateTime: 2024/3/13 16:34:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIQukSelRecast:LWnd
local UIQukSelRecast = LxWndClass("UIQukSelRecast", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIQukSelRecast:UIQukSelRecast()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIQukSelRecast:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIQukSelRecast:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIQukSelRecast:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitData()
	self:RefreshSelHeroIcon()
	self:InitHeroList()
	self:RefreshRaceSelStatus(self.mAllRaceBtn)
	self:RefreshRaceSel()
end

function UIQukSelRecast:RefreshRaceSelStatus(btnTrans)
	CS.SetParentTrans(self.mRaceSelImg,btnTrans)
end

function UIQukSelRecast:InitText()
	self:SetWndText(self.mLblBiaoti,ccClientText(18388))
	self:SetWndButtonText(self.mCancelBtn,ccClientText(10101))
	self:SetWndButtonText(self.mEnterBtn,ccClientText(10102))
	self:SetTextTile(self.mTextTitle,ccClientText(18389))
end

function UIQukSelRecast:OnClickEnterFunc()
	local refId = self._selRefId
	if self._func then
		self._func(refId)
		if refId then
			local name = gModelHero:GetColoredHeroName(refId)
			local str = string.replace(ccClientText(11334),name)
			GF.ShowMessage(str)
		end
	end
	--【D道具系统】删除2个字段（客户端）
	-- local selRecastItemData = self._selRecastItemData
	-- if refId and selRecastItemData then
	-- 	local itemId = selRecastItemData.itemId
	-- 	local itemRace = gModelItem:GetItemRaceTypeByRefId(itemId)
	-- 	if itemRace == 0 then
	-- 		LPlayerPrefs.SetAllRaceSelHeroRefId(tostring(refId))
	-- 	elseif itemRace == 1 then
	-- 		LPlayerPrefs.SetRace1SelHeroRefId(tostring(refId))
	-- 	elseif itemRace == 2 then
	-- 		LPlayerPrefs.SetRace2SelHeroRefId(tostring(refId))
	-- 	elseif itemRace == 3 then
	-- 		LPlayerPrefs.SetRace3SelHeroRefId(tostring(refId))
	-- 	elseif itemRace == 4 then
	-- 		LPlayerPrefs.SetRace4SelHeroRefId(tostring(refId))
	-- 	elseif itemRace == 5 then
	-- 		LPlayerPrefs.SetRace5SelHeroRefId(tostring(refId))
	-- 	end
	-- end
	--
	self:WndClose()
end

function UIQukSelRecast:OnClickRaceBtnFunc(race,btnTrans)
	if self._raceType == race then return end

	if self._forceSel then
		local name = ""
		local raceType = 1
		local itemId = self._itemId
		if itemId then
			name = gModelItem:GetItemNameRichText(itemId)
			--【D道具系统】删除2个字段（客户端）
			-- raceType = gModelItem:GetItemRaceTypeByRefId(itemId)
			--
		end
		local raceName = ""
		local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
		if raceRef then
			raceName = ccLngText(raceRef.name)
		end
		local str = string.replace(ccClientText(11333),name,raceName)
		GF.ShowMessage(str)
		return
	end

	self._raceType = race
	self:RefreshRaceSelStatus(btnTrans)
	self:InitHeroList()
end

function UIQukSelRecast:GetHeroList()
	local list = {}
	local heroRefId = self._heroRefId
	local ref = GameTable.CharacterRef
	for k,v in pairs(ref) do
		local outfitRecastRate = v.outfitRecastRate
		if outfitRecastRate > 0 then
			local raceType = v.raceType
			local ins = self._raceType == 0 or self._raceType == raceType
			if ins then
				local isSameExc = heroRefId and k == heroRefId or false
				table.insert(list,{
					refId = k,
					isSameExc = isSameExc,
					raceType = raceType,
					quality = v.quality,
				})
			end
		end
	end
	table.sort(list,function(a,b)
		local raceTypeA,raceTypeB = a.raceType,b.raceType
		if raceTypeA ~= raceTypeB then
			return raceTypeA < raceTypeB
		else
			local qualityA,qualityB = a.quality,b.quality
			if qualityA ~= qualityB then
				return qualityA > qualityB
			else
				return a.refId < b.refId
			end
		end
	end)
	return list
end

function UIQukSelRecast:InitHeroList(refresh)
	local list = self:GetHeroList()

	local uiHeroList = self._uiHeroList
	if uiHeroList then
		if refresh then
			uiHeroList:RefreshData(list)
		else
			uiHeroList:RefreshList(list)
		end
	else
		uiHeroList = self:GetUIScroll("uiHeroList")
		self._uiHeroList = uiHeroList
		uiHeroList:Create(self.mHeroList,list,function(...) self:OnDrawHeroCell(...) end,UIItemList.WRAP)
	end
end

function UIQukSelRecast:RefreshRaceSel()
	local list = {0,1,2,3,4,5}
	local btnTransList = {self.mAllRaceBtn,self.mRaceBtn1,self.mRaceBtn2,self.mRaceBtn3,self.mRaceBtn4,self.mRaceBtn5}
	for i,v in ipairs(list) do
		if (i - 1) == self._raceType then
			self:RefreshRaceSelStatus(btnTransList[i])
			break
		end
	end
end

function UIQukSelRecast:RefreshSelHeroIcon()
	local selRefId = self._selRefId
	local isSel = selRefId ~= nil
	CS.ShowObject(self.mEmptyBg,not isSel)
	CS.ShowObject(self.mSelHeroRoot,isSel)
	if not isSel then return end

	local SelHeroUITrans = self.mSelHeroUI
	local iconTrans = self:FindWndTrans(SelHeroUITrans,"Icon")

	local instanceId = SelHeroUITrans:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(iconTrans)
	baseClass:SetHeroIcon(selRefId)
	baseClass:SetNoShowLv(true)
	baseClass:DoApply()

	local heroName = gModelHero:GetHeroNameByRefId(selRefId)
	self:SetWndText(self.mSelHeroName,heroName)
end

function UIQukSelRecast:InitData()
	self._selRefId = self:GetWndArg("selRefId")
	self._func = self:GetWndArg("func")
	self._heroRefId = self:GetWndArg("heroRefId")
	local selRecastItemData = self:GetWndArg("selRecastItemData")
	self._selRecastItemData = selRecastItemData

	local raceType = 0
	--【D道具系统】删除2个字段（客户端）
	-- if selRecastItemData then
	-- 	local itemId = selRecastItemData.itemId
	-- 	self._itemId = itemId
	-- 	local itemRace = gModelItem:GetItemRaceTypeByRefId(itemId)
	-- 	raceType = itemRace
	-- 	if itemRace ~= 0 then
	-- 		self._forceSel = true
	-- 	end
	-- end
	--
	self._raceType = raceType
end

function UIQukSelRecast:OnDrawHeroCell(list,item,itemdata,itempos)
	local CommonUI = self:FindWndTrans(item,"CommonUI")
	local Icon = self:FindWndTrans(CommonUI,"Icon")
	local HeroName = self:FindWndTrans(item,"HeroName")
	local SelImg = self:FindWndTrans(item,"SelImg")

	local refId = itemdata.refId
	local isSel = refId == self._selRefId

	local isSameExc = itemdata.isSameExc

	local instanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(Icon)
	baseClass:SetHeroIcon(refId)
	baseClass:SetNoShowLv(true)
	baseClass:SetShowMaskOnly(isSameExc)
	baseClass:DoApply()

	local heroName = gModelHero:GetHeroNameByRefId(refId)
	local colorHeroName = gModelHero:GetColoredHeroName(refId)
	self:SetWndText(HeroName,heroName)

	CS.ShowObject(SelImg,isSel)

	self:SetWndClick(CommonUI,function()
		if isSameExc then
			local str = string.replace(ccClientText(18395),colorHeroName)
			GF.ShowMessage(str)
		else
			self:OnClickSelHeroFunc(refId)
		end
	end)
end

function UIQukSelRecast:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCancelBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mEnterBtn,function() self:OnClickEnterFunc() end)
	self:SetWndClick(self.mHelpBtn,function() GF.OpenWnd("UIBzTips",{refId = 92}) end)

	local raceTypeBtnList = {self.mRaceBtn1,self.mRaceBtn2,self.mRaceBtn3,self.mRaceBtn4,self.mRaceBtn5}
	for i,v in ipairs(raceTypeBtnList) do
		self:SetWndClick(v,function()
			self:OnClickRaceBtnFunc(i,v)
		end)
	end

	self:SetWndClick(self.mAllRaceBtn,function()
		self:OnClickRaceBtnFunc(0,self.mAllRaceBtn)
	end)
end

function UIQukSelRecast:OnClickSelHeroFunc(refId)
	if self._selRefId == refId then return end
	self._selRefId = refId
	self:RefreshSelHeroIcon()

	self:InitHeroList(true)
end

------------------------------------------------------------------
return UIQukSelRecast


