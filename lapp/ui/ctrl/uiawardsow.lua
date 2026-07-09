---
--- Created by Administrator.
--- DateTime: 2023/10/9 10:25:06
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAwardSow:LWnd
local UIAwardSow = LxWndClass("UIAwardSow", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAwardSow:UIAwardSow()
	---@type table<number,CommonIcon>
	self._commonIconTbl = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAwardSow:OnWndClose()
	self:ClearCommonIconList(self._commonIconTbl)
	self._commonIconTbl = nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAwardSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAwardSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()

	local showChangeBtn = self._allItemList ~= nil
	CS.ShowObject(self.mLeftBtn,showChangeBtn)
	CS.ShowObject(self.mRightBtn,showChangeBtn)

	if self._itemData then
		self:SetWndText(self.mTitle,self._title)
	end

    self:SetWndText(self.mDesc,ccClientText(15614))
	self:SetWndText(self.mBottomTitle,ccClientText(10103))
	self:InitEvent()
	self:Refresh()
end

function UIAwardSow:InitData()
    self._itemData = self:GetWndArg("ItemData")
    self._title = self:GetWndArg("title")
	self._day = self:GetWndArg("day")

	self._allItemList = self:GetWndArg("allItemList")
	self._index = self:GetWndArg("index")
	self._dayList = self:GetWndArg("dayList")
	self._titleList = self:GetWndArg("titleList")
end

function UIAwardSow:OnDrawItemCell(list, item, itemdata, itempos, fromHeadTail)
    local CommonUITrans = self:FindWndTrans(item,"CommonUI")
    if CommonUITrans then
		local iconTrans = CS.FindTrans(CommonUITrans, "Icon")
		local instanceId = item:GetInstanceID()
		if not self._commonIconTbl then
			self._commonIconTbl = {}
		end
		local baseClass = self._commonIconTbl[instanceId]
		if not baseClass then
			baseClass = CommonIcon:New()
			self._commonIconTbl[instanceId] = baseClass
			baseClass:Create(iconTrans)
		end
		baseClass:SetCommonReward(itemdata.itype, itemdata.itemId, itemdata.count)
		baseClass:EnableShowNum(true)
		baseClass:DoApply()


        local formatData = {
            itemId = itemdata.itemId,
            itemType = itemdata.itype,
            itemNum = itemdata.count,
        }
		self:SetIconClickScale(iconTrans, true)
        self:SetWndClick(iconTrans, function()
			gModelGeneral:ShowCommonItemTipWnd(formatData)
		end)
    end

    local NameTrans = self:FindWndTrans(item,"Name")
    if NameTrans then
        local str = string.replace(ccClientText(15706),itemdata.index)
        self:SetWndText(NameTrans,str)
    end

	local IsGetTrans = self:FindWndTrans(item,"IsGet")
	if IsGetTrans then
		local isGet = itemdata.isGet
		if isGet == nil then
			CS.ShowObject(IsGetTrans,false)
		else
			CS.ShowObject(IsGetTrans,isGet)
		end
	end
end

function UIAwardSow:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mLeftBtn,function()
		self:CutRewardShow(-1)
	end)
	self:SetWndClick(self.mRightBtn,function()
		self:CutRewardShow(1)
	end)
end

function UIAwardSow:GetDataList()
	local list = {}
	if self._itemData then
		for i,v in ipairs(self._itemData) do
			local data = {
				itemId = v.rewards[1].itemId,
				count = v.rewards[1].itemNum,
				itype = v.rewards[1].itemType,
				index = i,
				isGet = self._day >= i,
			}
			table.insert(list,data)
		end
	elseif self._allItemList then
		local rewardList,fundType
		for k,v in pairs(self._allItemList) do
			if v.index == self._index then
				fundType = k
				rewardList = v.rewardList
				break
			end
		end

		local title = self._titleList[fundType]
		self:SetWndText(self.mTitle,title)

		local day = self._dayList[fundType]

		for i,v in ipairs(rewardList or {}) do
			local data = {
				itemId = v.rewards[1].itemId,
				count = v.rewards[1].count,
				itype = v.rewards[1].type,
				index = i,
				isGet = day >= i,
			}
			table.insert(list,data)
		end
	end
	return list
end

function UIAwardSow:CutRewardShow(index)
	local dataLen = table.keysize(self._allItemList)
	local curIndex = self._index
	local newIndex = curIndex + index
	if newIndex <= 0 then
		newIndex = dataLen
	elseif newIndex > dataLen then
		newIndex = 1
	end
	self._index = newIndex
	self:Refresh()
end

function UIAwardSow:Refresh()
	local uiList = self._uiList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mItemList)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawItemCell(...)
		end)
		uiList:EnableLoadAnimation(true,0,1)
		self._uiList = uiList
	end
	uiList:RemoveAll()
	local list = self:GetDataList()
	for i,v in ipairs(list) do
        uiList:AddData(i,v)
	end
	uiList:RefreshList()
end
------------------------------------------------------------------
return UIAwardSow


