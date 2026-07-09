---
--- Created by Administrator.
--- DateTime: 2024/12/24 21:47:05
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGolemResolve:LChildWnd
local UISubGolemResolve = LxWndClass("UISubGolemResolve", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGolemResolve:UISubGolemResolve()
	self.selList = {}
	self.selMaxNum = 15
	self.curSelNum = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGolemResolve:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGolemResolve:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGolemResolve:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:SetStaticContent()
	self:UpdatePanel()
end


function UISubGolemResolve:SetStaticContent()
	self:SetWndClick(self.mBtnCancel,function ()
		if self.curSelNum> 0 then
			self.selList = {}
			self.curSelNum = 0
		else
			for _, data in ipairs(self.golemList) do
				if not data.isLock then
					self.selList[data.id] = data.id
					self.curSelNum = self.curSelNum+1
				end
				if self.curSelNum>= self.selMaxNum then break end
			end
		end
		self:UpdatePanel()
	end)

	self:SetWndClick(self.mBtnOk,function ()
		if self.curSelNum<=0 then return end
		local func = function()
			local list = {}
			for _, id in pairs(self.selList) do
				table.insert(list,id)
			end
			self.selList = {}
			self.curSelNum = 0
			gModelGolem:OnGolemDissolveReq(list)
		end
		local list = self:FindUIScroll("itemList")
		local uilist = list:GetList()
		local data = uilist:GetDataByKey(1)
		local itemName = gModelItem:GetNameByRefId(ModelItem.GOLEM_EXP_ITEM)
		local numStr = LUtil.NumberCoversion(data.itemNum)
		local showStr = string.format("%s*%s",itemName,numStr)
		gModelGeneral:OpenUIOrdinTips({refId = 310007,para = {showStr},func = func})
	end)
	self:SetWndClick(self.mBtnTip,function ()

	end)
	self:SetWndClick(self.mBtnIcon,function ()
		gModelGolem:OpenGolemResolve()
	end)

	self:WndNetMsgRecv(LProtoIds.GolemBagResp,function ()
		self:UpdatePanel()
	end)

	local data = {
		refId = 29007,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("empty")
	emptyList:RefreshUI(data)

	self:SetWndText(self.mBtnGoToText,ccClientText(33207))
	self:SetWndButtonText(self.mBtnOk,ccClientText(43704))
	-- local id = self:GetWndArg("golemId")
	-- self.selList[id] = id
	-- self.curSelNum = 1
end

function UISubGolemResolve:UpdateList()
	local golemList = gModelGolem:GetGolemList()
	local dataList = {}
	for k,v in pairs(golemList) do
		if not gModelGolem:CheckGolemIsWearByGolemInfo(v) then
			table.insert(dataList,v)
		end
	end
	table.sort(dataList,function (a,b)
		if a:GetLv() ~= b:GetLv() then
			return a:GetLv() > b:GetLv()
		end

		if a:GetStar() ~= b:GetStar() then
			return a:GetStar() > b:GetStar()
		end

		local aEquip = a:IsEquip() and 0 or 1
		local bEquip = b:IsEquip() and 0 or 1
		if aEquip ~= bEquip then
			return aEquip < bEquip
		end

		return a.refId < b.refId
	end)
	local isEmpty = #dataList == 0
	self.golemList = dataList
	CS.ShowObject(self.mGolemList,not isEmpty)
	CS.ShowObject(self.mNoRecord2,isEmpty)
	self:CreateUIScrollImpl("golemListResolve",self.mGolemList,dataList,function (...) self:OnDrawGolem(...) end,UIItemList.SUPER_GRID)
end

function UISubGolemResolve:OnDrawGolem(list,item,itemdata,itempos)
	local itemIcon = self:FindWndTrans(item,"itemIcon")
	local itemIconRoot = self:FindWndTrans(itemIcon,"root")


	local instanceID = item:GetInstanceID()
	local baseClass, isNew = self:GetCommonIcon(instanceID)
	if isNew then
		baseClass:Create(itemIconRoot)
	end

	local isSel = not not self.selList[itemdata.id]

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

function UISubGolemResolve:OnDrawGolemItem(list,item,itemdata,itempos)
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
		-- baseClass:SetGolemData(itemdata.data)
		baseClass:SetGolemData({
            refId = itemdata.data.refId,
            lvlRefId =itemdata.data.lvlRefId,
            lvl = gModelGolem:GetGolemLvlByGolemInfo(itemdata.data),
            displayPos = gModelGolem:GetGolemElementGolemDrawingIconByGolemInfo(itemdata.data)
        })
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

function UISubGolemResolve:ResolveRwdList()
	local dataList = {}

	---@type StructGolemInfo
	local golemData=nil
	local ref = nil
	local itemNum = 0
	local resolveRwd = gModelGolem._configExpRestitutionKey
	for k,id in pairs(self.selList) do
		golemData = gModelGolem:GetGolemServerDataById(id)
		ref = gModelGolem:GetGolemElementRefByRefId(golemData.refId)
		local quality = gModelGolem:GetGolemElementQualityByRefId(golemData.refId)
		local rote = resolveRwd[quality or 0] or 0
		itemNum = (ref.exp + golemData.exp*rote) + itemNum
	end
	if itemNum>0 then table.insert(dataList,{itemType = LItemTypeConst.TYPE_ITEM,itemId = ModelItem.GOLEM_EXP_ITEM,itemNum = itemNum}) end
	self:SetWndText(self.mTipText,itemNum>0 and ccClientText(41074) or ccClientText(33300))
	self:SetWndText(self.mTxtNum,string.replace(ccClientText(34857),self.curSelNum,self.selMaxNum))
	self:CreateUIScrollImpl("itemList",self.mRewardList,dataList,function (...)
		self:OnDrawItem(...)
	end)
end

function UISubGolemResolve:OnClickGolem(itemdata)
	if self.selList[itemdata.id] then
		self.selList[itemdata.id] = nil
		self.curSelNum = math.max(self.curSelNum-1,0)
	else
		if self.curSelNum>=15 then
			GF.ShowMessage(ccClientText(45912))
			return
		end
		if itemdata.isLock then
			gModelGolem:ChangeGolemLockStatusByGolemInfo(itemdata)
			return
		end

		self.selList[itemdata.id] = itemdata.id
		self.curSelNum = math.min(self.curSelNum+1,self.selMaxNum)
	end
	self:UpdatePanel()
end

function UISubGolemResolve:UpdatePanel()
	self:UpdateList()
	self:ResolveRwdList()
	self:UpdateSelList()
end

function UISubGolemResolve:UpdateSelList()
	local dataList = {}

	---@type StructGolemInfo
	local golemData=nil
	local isempty = true
	for k,id in pairs(self.selList) do
		golemData = gModelGolem:GetGolemServerDataById(id)
		isempty = false
		table.insert(dataList,{itemType = LItemTypeConst.TYPE_GOLEM,data = golemData})
	end
	self:SetWndButtonText(self.mBtnCancel,isempty and ccClientText(43744) or ccClientText(43742))
	local uilist = self:CreateUIScrollImpl("itemListGolem",self.mSelList,dataList,function (...)
		self:OnDrawGolemItem(...)
	end)
	uilist:EnableScroll(true,true)
end

function UISubGolemResolve:OnLongClickGolem(itemdata)
	local para =
	{
		viewType = 3,
		golemData = itemdata,
	}
	gModelGolem:OpenGolemInfoTip(para)
end

function UISubGolemResolve:OnDrawItem(list,item,itemdata,itempos)
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
------------------------------------------------------------------
return UISubGolemResolve