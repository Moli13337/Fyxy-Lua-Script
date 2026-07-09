---
--- Created by BY.
--- DateTime: 2022/7/26 17:55:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISorceryCardCollectorOverview:LWnd
local UISorceryCardCollectorOverview = LxWndClass("UISorceryCardCollectorOverview", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISorceryCardCollectorOverview:UISorceryCardCollectorOverview()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISorceryCardCollectorOverview:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISorceryCardCollectorOverview:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISorceryCardCollectorOverview:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self._isVie = gLGameLanguage:IsVieVersion()
	self:InitEvent()
	self:InitCommand()
end

function UISorceryCardCollectorOverview:RefreshData()
	local refId = gModelSorceryCard:GetCollectorInfo()
	if not refId then return end
	self._refId = refId
	local list = gModelSorceryCard:GetSorceryCardConfigRef()

	local index = 1
	for i, v in ipairs(list) do
		if v.refId == refId then
			index = i
		end
	end

	local _lvUiList = self._lvUiList
	if _lvUiList then
		_lvUiList:RefreshList(list)
		_lvUiList:DrawAllItems()
	else
		_lvUiList = self:GetUIScroll("mLvSuper_UISorceryCardCollectorOverview")
		self._lvUiList = _lvUiList
		_lvUiList:Create(self.mLvSuper,list,function(...) self:ListItem(...) end,UIItemList.SUPER)
		_lvUiList:EnableScroll(true,false)
	end
	_lvUiList:MoveToPos(index)
end

function UISorceryCardCollectorOverview:ArrtListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local icon = self:FindWndTrans(root,"Icon")
	local nameText = self:FindWndTrans(root,"NameText")
	local addText = self:FindWndTrans(root,"AddText")

	local iconStr = gModelHero:GetAttributeIconById(itemdata.refId)
	local nameStr = gModelHero:GetAttributeNameById(itemdata.refId)
	local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(itemdata.refId,itemdata.numType,itemdata.value)
	self:SetWndEasyImage(icon,iconStr)
	self:SetWndText(nameText,nameStr)
	self:SetWndText(addText,valueStr)
	if self._isVie then
		self:InitTextSizeWithLanguage(nameText,-2)
		self:InitTextSizeWithLanguage(addText,-2)
	end
end

function UISorceryCardCollectorOverview:ListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local nameText = self:FindWndTrans(root,"NameText")
	local attrScroll = self:FindWndTrans(root,"AttrScroll")
	local maskCur = self:FindWndTrans(root,"MaskCur")

	local InstanceID = item:GetInstanceID()
	local arrtList = LUtil.GetRefAttrData(itemdata.attr)

	self:SetWndText(nameText,ccLngText(itemdata.name))
	self:SetTextTile(maskCur, ccClientText(29571))
	CS.ShowObject(maskCur,self._refId == itemdata.refId)
	if self._isVie then
		self:InitTextCharacterWithLanguage(nameText,-3)
		self:SetAnchorPos(nameText,Vector2.New(8,-45.7))
	end
	self:CreateUIScrollImpl(InstanceID,attrScroll,arrtList,function(...) self:ArrtListItem(...) end)
	local _lvUiList = self:GetUIScroll(InstanceID)
	if _lvUiList:GetList() then
		_lvUiList:EnableScroll(#arrtList > 4,false)
	end
end
function UISorceryCardCollectorOverview:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(29520))
	self:SetWndText(self.mLvText,ccClientText(29521))
	self:SetWndText(self.mArrtText,ccClientText(29522))
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	self:RefreshData()
end

function UISorceryCardCollectorOverview:InitEvent()
	self:SetWndClick(self.mBgImage,function ()self:WndClose() end)

end
------------------------------------------------------------------
return UISorceryCardCollectorOverview


