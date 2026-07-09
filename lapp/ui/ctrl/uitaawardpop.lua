---
--- Created by BY.
--- DateTime: 2023/10/14 10:48:49
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITaAwardPop:LWnd
local UITaAwardPop = LxWndClass("UITaAwardPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITaAwardPop:UITaAwardPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITaAwardPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITaAwardPop:OnCreate()
	LWnd.OnCreate(self)
	self._pocketKey = "_pocketKey"
	self._uiCommonList={}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITaAwardPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self._isVie = gLGameLanguage:IsVieVersion()
	local itemFunc = function(refId,num)
		gModelGeneral:OpenItemInfoTip(refId,num)
	end
	local heroFunc = function()

	end
	local equipFunc = function(refId)
		gModelGeneral:OpenEquipInfoTip(refId,nil,nil,true)
	end
	self._funcList = {
		itemFunc,
		heroFunc,
		equipFunc,
	}
	self:InitCommand()


end

function UITaAwardPop:RefreshTabList()
	if self._tabList then
		self._tabList:DrawAllItems()
	end
end

function UITaAwardPop:OnModaiLoaded()
	local spine = self:FindWndSpineByKey(self._pocketKey)
	if spine then
		spine:PlayAnimation(0,"idle1",true)
	end
end

function UITaAwardPop:OnClickTab(tab)
	self._towerType = tab
	if self._tabList then
		self._tabList:DrawAllItems()
	end
	self:RefreshWnd()
end

function UITaAwardPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...)
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnClose, function(...)
		self:WndClose()
	end)
end

function UITaAwardPop:InitCommand()
	local towerType = self:GetWndArg("towerType")
	local openType = self:GetWndArg("openType") or 1
	self._openType = openType
	local titleStr = ccClientText(12102)
	if openType ==2 then
		titleStr = ccClientText(12170)
	end
	self:SetWndText(self.mTitleText,titleStr)
	local desStr = ""
	if openType == 2 then
		desStr = ccClientText(12169)
	else
		desStr = ccClientText(12132)
	end
	self:SetWndText(self.mDesText,desStr)
	local addLine = -30
	if gLGameLanguage:IsEnglishVersion() then
		addLine = -20
	end
	if self._isVie then
		addLine = 0
	end
	self:InitTextLineWithLanguage(self.mDesText, addLine)
	local isOpentRace = gModelTower:GetIsUnlockRaceTower()
	if isOpentRace or openType == 2 then
		local redType = gModelTower:GetBehindPhaseArwardRed()
		if redType > 0 then
			towerType = redType
		end
		local list = {}
		if openType == 2 then
			list = gModelTower:GetTowerPatternList(2)
			towerType = list[1].refId
		else
			list = gModelTower:GetTowerPatternList(1)
		end
		local _tabList = self:GetUIScroll("tabList")
		_tabList:Create(self.mTabScroll,list,function (...) self:TabListItem(...) end,UIItemList.SUPER)
		_tabList:EnableScroll(true,true)
		self._tabList = _tabList
		self._towerType = towerType
		self:OnClickTab(towerType)
		local index = 0
		for i, v in ipairs(list) do
			if towerType == v.refId then
				index = i - 1
				break
			end
		end
		_tabList:MoveToPos(index)
	else
		self._towerType = towerType
		self:RefreshWnd()
	end
end

function UITaAwardPop:CreateModai()
	local root = self.mPocketObj
	self:CreateWndSpine(root,"Modai",self._pocketKey,true,function () self:OnModaiLoaded() end)
end

function UITaAwardPop:RefreshWnd()
	local list = gModelTower:GetBehindPhaseArward(self._towerType)
	local bool= #list <= 0
	CS.ShowObject(self.mNoRecord,bool)
	if(bool)then
		self:CreateEmptyShow(15001)
	end
	if(self.uiList)then
		self.uiList:RefreshList(list)
		return
	end
	self.uiList = self:GetUIScroll("cell")
	self.uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end,UIItemList.WRAP)
end

function UITaAwardPop:OnClickGetAward(refId)
	local bool=gModelTower:GetPhaseState(refId,self._towerType)
	if(bool)then
		gModelTower:OnTowerStateRewardReq(refId)
	else
		GF.ShowMessage(ccClientText(12208))
	end

end

function UITaAwardPop:TabListItem(list, item, itemdata, itempos)
	local btnTab = CS.FindTrans(item,"Root/BtnTab1")
	local redPoint = CS.FindTrans(item,"Root/RedRoot/redPoint")
	local redpoint = gModelRedPoint:CheckShowRedPoint(itemdata.redpoint or 0)
	CS.ShowObject(redPoint,redpoint)
	self:SetWndTabStatus(btnTab,self._towerType == itemdata.refId and 0 or 1)
	self:SetWndTabText(btnTab,ccLngText(itemdata.name))
	self:SetWndClick(item,function  ()
		self:OnClickTab(itemdata.refId)
	end)
end

function UITaAwardPop:ListItem(list, item, itemdata, itempos)
	local xUIText=CS.FindTrans(item,"XUIText")
	local getBtn = CS.FindTrans(item,"GetBtn")
	local itemScroll=CS.FindTrans(item,"ItemScroll")

	CS.ShowObject(getBtn,false)
	local layer=gModelTower:GetTasLayer(self._towerType)
	local str=""
	local bGet=false
	if self._openType ~= 2 then
		if(layer>=itemdata.floor)then
			str = string.replace(ccClientText(12144),layer,itemdata.floor)
			bGet=true
		else
			str = string.replace(ccClientText(12145),layer,itemdata.floor)
		end
	end
	local instanceID = getBtn:GetInstanceID()
	self:SetWndText(xUIText,string.replace(ccClientText(12133),itemdata.floor)..str)
	if(bGet)then
		CS.ShowObject(getBtn,true)
		self:SetWndClick(getBtn, function(...)
			self:OnClickGetAward(itemdata.refId)
		end)
		local bool = gModelTower:GetPhaseState(itemdata.refId,self._towerType)
		self:SetWndButtonGray(getBtn,not bool)
		local btrStr = ""
		if(bool)then
			btrStr = ccClientText(12134)
			self:CreateWndEffect(getBtn,"fx_anniu_02",instanceID,100,nil,nil,nil,nil,nil,true)
		else
			btrStr = ccClientText(12208)
		end
		self:SetWndButtonText(getBtn,btrStr)
	end
	local eff = self:FindWndEffectByKey(instanceID)
	if eff and not bGet then eff:SetVisible(false) end
	local list = gModelTower:SetAawardDataList(itemdata.reward)

	local InstanceID = item:GetInstanceID()

	local iconList = self.uiList:GetItemCls(InstanceID)
	if not iconList then
		iconList = UIIconEasyList:New()
		self.uiList:SetItemCls(InstanceID, iconList)
		iconList:Create(self, itemScroll)
	end
	iconList:RefreshList(list, true)
	if(#list>4)then
		iconList:EnableScroll(true,true)
	end
end

function UITaAwardPop:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UITaAwardPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.TowerStateRewardResp,function (...)
		self:RefreshWnd()
	end)
	self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:RefreshTabList() end)
end
------------------------------------------------------------------
return UITaAwardPop


