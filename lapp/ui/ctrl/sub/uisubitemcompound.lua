---
--- Created by Administrator.
--- DateTime: 2024/9/13 14:45:29
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubItemCompound:LChildWnd
local UISubItemCompound = LxWndClass("UISubItemCompound", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubItemCompound:UISubItemCompound()
	self.itemList = {}
	self.itemIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubItemCompound:OnWndClose()
	self:ClearCommonIconList(self.itemIconList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubItemCompound:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubItemCompound:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:InitList()
end

function UISubItemCompound:InitCommon()
	-----------------------------------------------
	---click
	self:SetWndClick(self.mHelp, function()
		GF.OpenWnd("UIBzTips", { refId = 181 })
	end)

	-----------------------------------------------
	---event
	self:WndEventRecv(EventNames.On_Item_Change, function()
		self:InitList()
	end)
end

function UISubItemCompound:CreateItemIcon(root, data)
	local instanceId = root:GetInstanceID()
	if not self.itemIconList[instanceId] then
		self.itemIconList[instanceId] = CommonIcon:New()
		self.itemIconList[instanceId]:Create(root)
	end
	self.itemIconList[instanceId]:SetCommonReward(data.itemType, data.itemId)
	self.itemIconList[instanceId]:EnableShowNum(false)
	self.itemIconList[instanceId]:DoApply()

	self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
end

function UISubItemCompound:DrawItem(_, item, data, pos)
	local root = CS.FindTrans(item, "Root")
	local text = CS.FindTrans(item, "Text")
	local add = CS.FindTrans(item, "Add")

	self:CreateItemIcon(root, data.item)

	local haveNum = gModelItem:GetNumByRefId(data.item.itemId, nil, data.item.itemType)
	local str = "<color=#a1#>#a2#/#a3#</color>"
	local color = haveNum >= data.item.itemNum and "#734f22" or "#c81212"
	self:SetWndText(text, string.replace(str, color, haveNum, data.item.itemNum))

	CS.ShowObject(add, data.showAdd)
end

function UISubItemCompound:DrawList(_, item, data)
	local root = CS.FindTrans(item, "Root")
	local itemList = CS.FindTrans(item, "ItemList")
	local btn = CS.FindTrans(item, "Btn")
	-- local redPoint = CS.FindTrans(item, "redPoint")

	self:CreateItemIcon(root, data.item1)

	local instanceId = item:GetInstanceID()
	local len = #data.item2
	local x = math.min(((len - 1) * 114) + ((len - 1) * 3) + 88, 238)
	itemList.sizeDelta = Vector2.New(x, 107)
	local itemData = {}
	for i, v in ipairs(data.item2) do
		local data = {
			item = v,
			showAdd = i ~= len
		}
		table.insert(itemData, data)
	end
	if self.itemList[instanceId] then
		self.itemList[instanceId]:RefreshList(itemData)
		self.itemList[instanceId]:DrawAllItems()
	else
		self.itemList[instanceId] = self:GetUIScroll("itemList" .. instanceId)
		self.itemList[instanceId]:Create(itemList, itemData, function(...) self:DrawItem(...) end, UIItemList.SUPER_GRID)
	end

	local canCompound = gModelItem:CheckItemCanCompound(data.refId)
	-- CS.ShowObject(redPoint, canCompound)
	self:SetWndButtonGray(btn, not canCompound)
	self:SetWndButtonText(btn, ccClientText(11316))

	self:SetWndClick(btn, function()
		if not gModelItem:CheckItemCanCompound(data.refId, true) then
			GF.ShowMessage(ccClientText(44515))
			return
		end
		local maxCompundNum = gModelItem:GetMaxCompundNum(data.refId)
		if data.showMore and maxCompundNum > 1 then
			local data = {
				refId = data.item1.itemId,
				defaultNum = maxCompundNum,
				maxValue = maxCompundNum,
				minValue = 1,
				func = function(num)
					gModelItem:ItemComposeReq(data.refId, num)
				end
			}
			GF.OpenWndUp("UIItemSyePop", data)
			return
		end
		gModelItem:ItemComposeReq(data.refId, 1)
	end)
end

function UISubItemCompound:InitList()
	local list = gModelItem:GetItemCompoundList()
	local movePos = 1
	for i, v in ipairs(list) do
		if gModelItem:CheckItemCanCompound(v.refId) then
			movePos = i
		end
	end

	if self.list then
		self.list:RefreshList(list)
		self.list:DrawAllItems()
	else
		self.list = self:GetUIScroll("mList")
		self.list:Create(self.mList, list, function(...) self:DrawList(...) end, UIItemList.SUPER)
	end
	self.list:MoveToPos(movePos)
end



------------------------------------------------------------------
return UISubItemCompound