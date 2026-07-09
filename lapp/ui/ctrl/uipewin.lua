---
--- Created by Administrator.
--- DateTime: 2024/6/14 18:58:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeWin:LWnd
local UIPeWin = LxWndClass("UIPeWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeWin:UIPeWin()
	self._tabList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeWin:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeWin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:WndEventRecv(EventNames.PET_INFO_CHANGE,function()
		self:UpdateTabState()
		self:UpdateTabRed() end)
	self:WndEventRecv(EventNames.PET_CHANGE_STAR,function(isActive)
		if isActive then self:UpdateTabState() end
		self:UpdateTabRed() end)
	self:WndEventRecv(EventNames.PET_CHANGE_LEVEL,function() self:UpdateTabRed() end)
	self:WndEventRecv(EventNames.PET_EQUIP_CHANGE,function() self:UpdateTabRed() end)
	self:WndNetMsgRecv(LProtoIds.PetEquipUnloadResp,function() self:UpdateTabRed() end)
	self:WndNetMsgRecv(LProtoIds.PetEquipWearResp,function() self:UpdateTabRed() end)
	self:InitDatas()
	self:InitTabList()
	self:OpenChildCtrl()

	self:SetWndClick(self.mCloseBtn, 
	function(...) self:WndClose() 
	end)
	self:SetWndClick(self.mBtnWin, 
	function(...) self:WndClose() 
	end)
	self:SetWndText(self.mTxtClose,ccClientText(30205))
end

function UIPeWin:RefreshSelectTable(newIndex,oldIndex)
    self:SetWndTabStatus(self._tabList[oldIndex],1,oldIndex)
	self:SetWndTabStatus(self._tabList[newIndex],0,newIndex)

    self:CreateChildWnd(self.mChildRoot,self._tabDatas[newIndex].uiName,self:GetWndArgList())
end

function UIPeWin:InitTabList()
    local uiList = self:GetUIScroll("badgeTab")
	uiList:Create(self.mTabScroll,self._tabDatas,function(...) self:OnDrawTab(...) end)
    self._tabUiList = uiList
end

function UIPeWin:OpenChildCtrl()
    local uiName = self._tabDatas[self._curTabIndex].uiName
    if string.isempty(uiName) then return end
	self:CreateChildWnd(self.mChildRoot,self._tabDatas[self._curTabIndex].uiName,self:GetWndArgList())
	self:SetWndTabStatus(self._tabList[self._curTabIndex],0,self._curTabIndex)
end

function UIPeWin:OnDrawTab(list, item, itemData, index)
	self:SetWndTabText(item,itemData.name,nil,true)
	-- if itemData.openId and not gModelFunctionOpen:CheckIsOpened(itemData.openId,false) then
	-- 	local cfg = GameTable.FeatureOpenRef[itemData.openId]
	-- 	if cfg.show<=0 then
	-- 		CS.ShowObject(item,false)
	-- 		return
	-- 	end
	-- 	isLock = true
	-- end
	local argList = self:GetWndArgList()
	local pet = gModelPet:GetPetById(argList.refId)
	local isLock = not pet.isActive and itemData.showLock
	self:SetWndTabStatus(item, isLock and 2 or 1)
	self:SetWndTabIcon(item,itemData.icon,itemData.icon)
	self._tabList[index] = item
	self:SetWndClick(item, function (...)
		local argList = self:GetWndArgList()
		local pet = gModelPet:GetPetById(argList.refId)
		if not pet.isActive then
			GF.ShowMessage(ccClientText(43764))
			return
		end
		self:DoChangeTab(index) end)

	self:UpdateRed(item,index)
	-- local funcRed =function (isShow)
	-- 	local RedPoint=self:FindWndTrans(item,"redPoint")
	-- 	CS.ShowObject(RedPoint,isShow)
	-- end
	-- self:RegisterRedPointFunc(itemData.redId,funcRed)
end

function UIPeWin:DoChangeTab(index)
    if self._curTabIndex == index then return end
	local itemData = self._tabDatas[index]
	if itemData.openId and not gModelFunctionOpen:CheckIsOpened(itemData.openId,true) then return end
    local oldIndex = self._curTabIndex
    self._curTabIndex = index
	self:SetWndTabStatus(self._tabList[oldIndex],1,oldIndex)
	self:SetWndTabStatus(self._tabList[index],0,index)

	local uiname = self._tabDatas[index].uiName
    self:CreateChildWnd(self.mChildRoot,uiname,self:GetWndArgList())
	local childPetRelation = self:FindChild("UISubPeStar")
	if childPetRelation and childPetRelation._wndTrans then
		CS.ShowObject(childPetRelation._wndTrans,childPetRelation._wndName==uiname)
	end
end
function UIPeWin:UpdateRed(item,index)
	local petId = self:GetWndArg("refId")
	---@type StructPet
	local pet = gModelPet:GetPetById(petId)
	local RedPoint=self:FindWndTrans(item,"redPoint")
	if index==3 then
		local state = pet:GetPetState()
		CS.ShowObject(RedPoint,state==2 or pet:IsCanUpLevel())
	elseif index==2 then
		CS.ShowObject(RedPoint,pet:IsCanUpStar() and pet.isActive)
	elseif index==1 then
		local partCfg = GameTable.MagicPetArticleTypeRef
		local isShow = false
		local argList = self:GetWndArgList()
		local pet = gModelPet:GetPetById(argList.refId)
		local equipList = pet:GetPetWearEquips() or {}--穿戴列表
		if pet.isActive then
			for _, value in ipairs(partCfg or {}) do
				if equipList[value.refId] then
					isShow = gModelPet:GetStrongerEquipByPart(equipList[value.refId],value.refId)
				else
					isShow = gModelPet:GetWearRedPointByPart(value.refId)
				end
				if isShow then break end
			end
		end
		CS.ShowObject(RedPoint,isShow and pet.isActive)
	end
end
function UIPeWin:UpdateTabState()
	local argList = self:GetWndArgList()
	local pet = gModelPet:GetPetById(argList.refId)
	if not pet.isActive then
		-- self._curTabIndex = #self._tabDatas
		-- self:OpenChildCtrl()
		self:DoChangeTab(#self._tabDatas)
	end
	for index, value in ipairs(self._tabList or {}) do
		if self._tabDatas[index].showLock then
			local isLock = not pet.isActive
			self:SetWndTabStatus(value, isLock and 2 or (self._curTabIndex==index and 0 or 1))
		end
	end
end

function UIPeWin:InitDatas()
    self._tabDatas = {
		{uiName="UISubPeEq",icon ="pet_btn_icon_7",name=ccClientText(43712),showLock = true},
		{uiName="UISubPeStar",icon ="pet_btn_icon_6", name=ccClientText(43711),showLock = true},
        {uiName="UISubPeInfo",icon ="pet_btn_icon_5", name=ccClientText(43710)},--ModelRedPoint.HOLY_LAND_TABBAR
    }

    local openName = self:GetWndArg("name")
    self._curTabIndex = #self._tabDatas
    if openName then
		for k,v in ipairs(self._tabDatas) do
			if v.uiName == openName then
				if v.openId and not gModelFunctionOpen:CheckIsOpened(v.openId,true) then
					self:WndClose()
				end
				self._curTabIndex = k
				break
			end
		end
	end

end
function UIPeWin:UpdateTabRed()
	for index, value in ipairs(self._tabList or {}) do
		self:UpdateRed(value,index)
	end
end
------------------------------------------------------------------
return UIPeWin