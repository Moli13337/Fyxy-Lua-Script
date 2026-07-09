---
--- Created by Administrator.
--- DateTime: 2024/12/24 21:57:00
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGolemBack:LChildWnd
local UISubGolemBack = LxWndClass("UISubGolemBack", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGolemBack:UISubGolemBack()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGolemBack:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGolemBack:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGolemBack:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self:InitEvent()
	self:SetStaticContent()
	self:InitUIEvent()
	self:ShowGolemList()
	self:RefreshContent()
end

function UISubGolemBack:InitUIEvent()
	self:SetWndClick(self.mBtnOk,function ()
		self:OnClickGolemBack()
	end)

	self:SetWndClick(self.mBtnBack,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mBtnTip,function ()
		GF.OpenWnd("UIBzTips",{refId = 506})
	end)
end

function UISubGolemBack:OnDrawGolem(list,item,itemdata,itempos)
	local itemIcon = self:FindWndTrans(item,"itemIcon")
	local itemIconRoot = self:FindWndTrans(itemIcon,"root")


	local instanceID = item:GetInstanceID()
	local baseClass, isNew = self:GetCommonIcon(instanceID)
	if isNew then
		baseClass:Create(itemIconRoot)
	end

	local isSel = self._curSel == itemdata.id

	local data = {
		refId = gModelGolem:GetGolemRefIdByGolemInfo(itemdata),
		lvlRefId = gModelGolem:GetGolemLvlRefIdByGolemInfo(itemdata),
		lvl = gModelGolem:GetGolemLvlByGolemInfo(itemdata),
		showGou = isSel,
		displayPos = gModelGolem:GetGolemElementGolemDrawingIconByGolemInfo(itemdata),
		displayHero = gModelHero:GetHeroOutfitIconById(itemdata.heroId),
		showLock = itemdata:IsLock(),
	}

	baseClass:SetGolemData(data)
	baseClass:DoApply()

	self:SetWndClick(itemIcon,function()
		self:OnClickGolem(itemdata)
	end)

	self:SetWndLongClick(itemIcon,function ()
		self:OnLongClickGolem(itemdata)
	end)


end

function UISubGolemBack:RefreshContent()
	local dataList = {}
	if not self._curSel then return end
	---@type StructGolemInfo
	local golemData= gModelGolem:GetGolemServerDataById(self._curSel)
	local default = golemData:GetDefaultData()

	table.insert(dataList,{itemType = LItemTypeConst.TYPE_GOLEM,data = default})

	local returnItemList = gModelGolem:GetReturnItem(self._curSel)
	for k,v in ipairs(returnItemList) do
		table.insert(dataList,v)
	end

	self:CreateUIScrollImpl("itemList",self.mRewardList,dataList,function (...)
		self:OnDrawItem(...)
	end)

	local returnCost = gModelGolem:GetReturnConsume()
	local icon = gModelItem:GetItemImgByRefId(returnCost.itemId)
	self:SetWndEasyImage(self.mItemIcon,icon)
	local own = gModelItem:GetNumByRefId(returnCost.itemId)
	local color = own < returnCost.itemNum and "red" or "white"
	local str = LUtil.FormatColorStr(returnCost.itemNum,color)
	self:SetWndText(self.mItemNum,str)

	self:ShowGolem()
end

function UISubGolemBack:SetStaticContent()
	local str =ccClientText(34850)-- "回 退"
	self:SetWndButtonText(self.mBtnOk,str)

	str =ccClientText(34852)-- "回退返回预览")
	self:SetWndText(self.mTipText,str)

	local data = {
		refId = 29007,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("empty")
	emptyList:RefreshUI(data)
	self:SetWndText(self.mItemNum,0)

end

function UISubGolemBack:InitEvent()
	self:WndNetMsgRecv(LProtoIds.GolemBagResp,function ()
		self:ShowGolemList()
		self:RefreshContent()
	end)
end


function UISubGolemBack:OnClickGolem(itemdata)
	if self._curSel == itemdata.id then
		return
	end

	local golemData = gModelGolem:GetGolemServerDataById(itemdata.id)
	if golemData.isLock then
		gModelGolem:ChangeGolemLockStatusByGolemInfo(golemData)
		return
	end

	self._curSel = itemdata.id

	local list = self:FindUIScroll("golemList")
	if list then
		list:DrawAllItems(false)
	end

	self:RefreshContent()
end

function UISubGolemBack:OnLongClickGolem(itemdata)
	local para =
	{
		viewType = 3,
		golemData = itemdata,
	}
	gModelGolem:OpenGolemInfoTip(para)
end

function UISubGolemBack:OnDrawItem(list,item,itemdata,itempos)
	local itemIcon = self:FindWndTrans(item,"itemIcon")
	local itemIconRoot = self:FindWndTrans(itemIcon,"root")

	local instanceID = item:GetInstanceID()
	local baseClass, isNew = self:GetCommonIcon(instanceID)
	if isNew then
		baseClass:Create(itemIconRoot)
		baseClass:EnableSupportMulti(true) --格子支持多类型重用
	end

	if itemdata.itemType == LItemTypeConst.TYPE_ITEM then
		baseClass:SetCommonItemdata(itemdata)
	elseif itemdata.itemType == LItemTypeConst.TYPE_GOLEM then
		baseClass:SetGolemData(itemdata.data)
	end


	baseClass:DoApply()


	self:SetWndClick(itemIconRoot,function ()
		if itemdata.itemType == LItemTypeConst.TYPE_ITEM then
			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		elseif itemdata.itemType == LItemTypeConst.TYPE_GOLEM then
			gModelGolem:OpenGolemInfoTip({
				viewType = 2,
				golemData = itemdata.data,
			})
		end
	end)
end

function UISubGolemBack:ShowGolem()
	local golem = gModelGolem:GetGolemServerDataById(self._curSel)
	local typeBig = gModelGolem:GetGolemElementTypeBigByGolemInfo(golem)
	local suit = gModelGolem:GetSuitByType(typeBig)

	local showType = suit.attrShowType
	CS.ShowObject(self.mGolemIcon,showType == 1)
	CS.ShowObject(self.mGolemRoot,showType ~= 1)

	if showType == 1 then
		local instanceID = self.mGolemIcon:GetInstanceID()
		local baseClass = self:GetCommonIcon(instanceID)
		baseClass:Create(self.mGolemIcon)
		baseClass:SetGolemData({
			refId =golem.refId,
			lvlRefId = golem.lvlRefId,
			lvl = gModelGolem:GetGolemLvlByGolemInfo(golem),
			displayPos = gModelGolem:GetGolemElementGolemDrawingIconByGolemInfo(golem),
		})
		baseClass:DoApply()
	elseif showType == 2 then
		self:DestroyWndSpineByKey("suitSpine")
		self:CreateWndSpine(self.mGolemSpine,suit.attrShow,"suitSpine")
	elseif showType == 3 then
		self:DestroyWndEffectByKey("suitEff")
		self:CreateWndEffect(self.mGolemEff,suit.attrShow,"suitEff")
	end
end

function UISubGolemBack:ShowGolemList()
	local dataList = gModelGolem:GetBackGolemList()
	local isEmpty = #dataList == 0
	CS.ShowObject(self.mGolemList,not isEmpty)
	CS.ShowObject(self.mNoRecord2,isEmpty)
	self:SetWndButtonGray(self.mBtnOk,isEmpty)
	CS.ShowObject(self.mGolem,not isEmpty)
	CS.ShowObject(self.mRewardList,not isEmpty)

	if isEmpty then
		self._curSel = nil
		return
	end

	if not self._curSel then
		self._curSel = self:GetWndArg("golemId")
	end

	local isExist = false
	for k,v in ipairs(dataList) do
		if self._curSel == v.id then
			isExist= true
			break
		end
	end

	if not isExist then
		self._curSel = dataList[1].id
	end


	self:CreateUIScrollImpl("golemList",self.mGolemList,dataList,function (...) self:OnDrawGolem(...) end,UIItemList.SUPER_GRID)
end

function UISubGolemBack:OnClickGolemBack()


	local cost = gModelGolem:GetReturnConsume()
	if not gModelGeneral:CheckItemEnough(cost.itemId,cost.itemNum,true,self:GetWndName()) then

		local str =ccClientText(34853) --"钻石不足,无法回退"
		GF.ShowMessage(str)
		return
	end

	if self._curSel then

		---@type StructGolemInfo
		local golem = gModelGolem:GetGolemServerDataById(self._curSel)

		if golem:IsRecasting() then
			local para = {
				refId = 310028,
			}
			gModelGeneral:OpenUIOrdinTips(para)
			return
		end

		if golem:IsLock() then
			local para = {
				refId = 310029,
			}
			gModelGeneral:OpenUIOrdinTips(para)
			return
		end

		local refId = golem.refId
		local lv = golem:GetLv()
		local costStr =string.replace("#a1#*#a2#",gModelGeneral:GetCommonItemName(cost),cost.itemNum)
		local golemStr = gModelGolem:GetGolemElementNameByRefId(refId)
		local sel = self._curSel
		local para = {
			refId = 310027,
			func = function()
				gModelGolem:OnGolemRollbackReq(sel)
			end,
			para = {costStr,lv,golemStr}
		}
		gModelGeneral:OpenUIOrdinTips(para)

	end
end


------------------------------------------------------------------
return UISubGolemBack