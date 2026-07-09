---
--- Created by BY.
--- DateTime: 2023/10/18 15:56:21
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UICumSelectNew2:LWnd
local UICumSelectNew2 = LxWndClass("UICumSelectNew2", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UICumSelectNew2:UICumSelectNew2()
	self._commonIconList = {}
	self._selectIndex = 1
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UICumSelectNew2:OnWndClose()
	self:ClearCommonIconList(self._commonIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UICumSelectNew2:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UICumSelectNew2:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	--self:InitMessage()
	self:InitCommand()
end

function UICumSelectNew2:OnDrawCellItem2(list, item, itemData, itemPos)
	local root = self:FindWndTrans(item,"ItemRoot/Icon")
	local itemNum = self:FindWndTrans(item,"ItemNum")
	local itemInfo = LxDataHelper.ParseItem_4(itemData.data)
	local selStr = self._selectedList[self._selectIndex]
	local isSelect = false
	if selStr then
		isSelect = selStr == itemData.data
	end
	local func = function() self:OnClickSelectData(itemData) end
	local InstanceID = item:GetInstanceID()
	self:InitCommonIcon(InstanceID,root,itemInfo,func,nil,itemNum,isSelect)
end

function UICumSelectNew2:OnDrawCellItem(list, item, itemData, itemPos)
	local tipBtn = self:FindWndTrans(item,"TipBtn")
	local root = self:FindWndTrans(item,"ItemRoot/Icon")
	local itemNum = self:FindWndTrans(item,"ItemNum")
	local selectImg = self:FindWndTrans(item,"SelectImg")
	local itemTipsTxt = self:FindWndTrans(item,"ItemTipsTxt")

	local isCurSelect = self._selectIndex == itemPos			--是否当前选择
	local data = itemData.data
	local isData = data ~= nil								--是否有数据
	local func = function() self:OnClickSelectIndex(itemPos) end

	CS.ShowObject(tipBtn,isData)
	CS.ShowObject(itemNum,isData)
	CS.ShowObject(selectImg,isCurSelect)
	CS.ShowObject(itemTipsTxt,not isData)
	if not isData then
		self:SetWndText(itemTipsTxt, ccClientText(18605))
		self:SetWndClick(root,function () if func then func() end end)
		return
	end
	local itemInfo = LxDataHelper.ParseItem_4(data)
	local InstanceID = item:GetInstanceID()
	self:InitCommonIcon(InstanceID,root,itemInfo,func,tipBtn,itemNum)
end

function UICumSelectNew2:OnClickSelectIndex(index)
	self._selectIndex = index
	self:RefreshItemListData()
	self:RefreshCustomItemListData()
end

function UICumSelectNew2:InitCommand()
	local para = self:GetWndArg("para")
	if not para then
		self:WndClose()
		return
	end
	self._callFunc = para.callFunc							--回调方法
	local name = para.name or ""							--窗口名字
	local rewardFree = para.rewardFree or ""				--能选择的道具
	local selected = para.selected or ""					--已选择的道具

	local rewardFreeArr = string.split(rewardFree,"|")
	local len = #rewardFreeArr
	local selectedArr = string.split(selected,",")
	local selectedList = {}
	for i = 1, len do
		selectedList[i] = selectedArr[i]
	end
	self._selectLen = len
	self._selectedList = selectedList
	self._rewardFreeArr = rewardFreeArr

	self:SetWndText(self.mLblBiaoti,name)
	self:SetWndText(self.mTitleText, ccClientText(18606))
	self:SetWndText(self.mNoText, ccClientText(18604))
	self:RefreshItemListData()
	self:RefreshCustomItemListData()
end

function UICumSelectNew2:OnClickSelectData(itemData)
	local data = itemData.data
	local index = itemData.index
	self._selectedList[index] = data
	self:RefreshItemListData()
	self:RefreshCustomItemListData()
end

function UICumSelectNew2:InitCommonIcon(key,root,itemInfo,func,root2,numText,isSelect)
	local baseClass = self._commonIconList[key]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._commonIconList[key] = baseClass
		baseClass:Create(root)
		self:SetIconClickScale(root, true)
	end
	baseClass:SetCommonReward(itemInfo.itemType, itemInfo.itemId, numText and -1 or itemInfo.itemNum)
	baseClass:ShowGouImg(isSelect or false)
	baseClass:DoApply()
	self:SetWndClick(root,function ()
		if func then
			func()
		end
	end)
	if root2 then
		self:SetWndClick(root2,function () gModelGeneral:OpenItemInfoTipsFormChat(itemInfo) end)
	end
	if numText then
		self:SetWndText(numText,LUtil.NumberCoversion(itemInfo.itemNum))
	end
	self:SetWndLongClick(root,function() gModelGeneral:OpenItemInfoTipsFormChat(itemInfo) end,0.8,false)
end

function UICumSelectNew2:RefreshCustomItemListData()
	local _selectIndex = self._selectIndex
	local items = self._rewardFreeArr[_selectIndex]
	local itemsArr = string.split(items,",")
	local list = {}
	for i, v in ipairs(itemsArr) do
		table.insert(list,{data = v,index = _selectIndex})
	end
	CS.ShowObject(self.mNoText,#list <= 0)
	local uiList = self._uiCustomItemItemList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("selectCustomItemItemList")
		uiList:Create(self.mCustomItemList, list, function(...) self:OnDrawCellItem2(...) end)
		uiList:EnableScroll(false)
		self._uiCustomItemItemList = uiList
	end
end

function UICumSelectNew2:RefreshItemListData()
	--local selectedList = self._selectedList
	local list = {}
	local len = self._selectLen
	local _selectedList = self._selectedList
	for i = 1, len do
		table.insert(list,{data = nil})
	end
	local selNum = 0
	for i, v in pairs(_selectedList) do
		list[i].data = v
		if v then
			selNum = selNum + 1
		end
	end
	self:SetWndButtonText(self.mConfirmBtn,selNum >= len and ccClientText(10102) or ccClientText(18603))

	local uiList = self._uiItemList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("selectItemList")
		uiList:Create(self.mItemList, list, function(...) self:OnDrawCellItem(...) end)
		uiList:EnableScroll(false)
		self._uiItemList = uiList
	end
end

function UICumSelectNew2:OnClickConfirm()
	local  len = self._selectLen
	local _selList = self._selectedList
	local selected = ""
	for i = 1, len do
		local data = _selList[i]
		if not data then
			self:OnClickSelectIndex(i)
			return
		end
		selected = i == 1 and data or selected..","..data
	end
	local _callFunc = self._callFunc
	if _callFunc then
		self:WndClose()
		_callFunc(selected)
	end
end

function UICumSelectNew2:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function (...)self:WndClose() end)
	self:SetWndClick(self.mConfirmBtn,function (...)self:OnClickConfirm() end)
end
------------------------------------------------------------------
return UICumSelectNew2


