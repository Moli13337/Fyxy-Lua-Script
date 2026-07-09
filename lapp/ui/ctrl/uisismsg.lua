---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISisMsg:LWnd
local UISisMsg = LxWndClass("UISisMsg", LWnd)

local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local Tweening = DG.Tweening
local typeDOTween = Tweening.DOTween
local EaseOutCubic = Tweening.Ease.OutCubic
------------------------------------------------------------------
local pattern = "#path=([%w_]+)#"
local posYPattern = "#posY=([%w_-]+)#"

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISisMsg:UISisMsg()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISisMsg:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	if self._textPool then
		self._textPool:Destroy()
		self._textPool = nil
	end
	if self._itemPool then
		self._itemPool:Destroy()
		self._itemPool = nil
	end
	for k,v in pairs(self._seqList or {}) do
		v:Kill(false)
	end
	self._seqList =nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISisMsg:OnCreate()
	LWnd.OnCreate(self)
	self._uiCommonList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISisMsg:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:VersionRefresh()

	self:InitData()
	self:WndEventRecv(EventNames.ON_SYS_MSG,function(msg) self:OnNewMsg(msg) end)
	self:WndEventRecv(EventNames.ON_DETAIL_SYS_MSG,function(rewardList) self:OnGetDetailMsg(rewardList) end)
end



function UISisMsg:InitData()
	self._msgWaitList = {}
	self._showingList={}

	self._seqList={}
	self._showTimer = "msgShowTimer"

	local itempool = UIObjPool:New()
	itempool:Create(self.mTemplates,self.mMsgTemplate)
	self._textPool = itempool

	local itempool = UIObjPool:New()
	itempool:Create(self.mTemplates,self.mMsgTemplate2)
	self._itemPool = itempool
end

function UISisMsg:FormatMsg(msg)
	local s = 1
	local e = 0
	local start = 1
	local len = string.len(msg)
	local cap = nil
	s,e,cap =string.find(msg,pattern,start)
	local a, b, posY = string.find(msg, posYPattern, start)
	if cap then
		local str = string.sub(msg,start,s-1)
		local data = {}
		data.type = 3
		data.str = str
		return data
	end
	if posY then
		local str = string.sub(msg, start, a - 1)
		local data = {}
		data.type = 1
		data.str = str
		data.posY = tonumber(posY)
		return data
	end
	local str = string.sub(msg,start,len)
	local data = {}
	data.type = 1
	data.str = str
	return data
end

function UISisMsg:OnGetDetailMsg(rewardList)
	if not rewardList then return end
	local firstData = table.remove(rewardList,1)
	if not firstData then return end
	if #self._msgWaitList==0 and #self._showingList==0 then
		self:ShowMsg(nil,firstData)
	else
		table.insert(self._msgWaitList,firstData)
	end
	local len = #rewardList
	if len > 0 then
		for i,v in ipairs(rewardList) do
			table.insert(self._msgWaitList,v)
		end
	end
	if not self:IsTimerExist(self._showTimer) then
		self:TimerStart(self._showTimer,0.5,false,-1)
	end
end

function UISisMsg:OnTimer(key)
	if self._showTimer ==key then
		local msg = self._msgWaitList[1]
		if msg then
			table.remove(self._msgWaitList,1)
			local isString = type(msg) == "string"
			if isString then
				self:ShowMsg(msg)
			else
				self:ShowMsg(nil,msg)
			end
		end
		self:CheckStopTimer()
	end
end

function UISisMsg:OnItemShowEx(item)
	if not item then
		return
	end
	CS.ShowObject(item.item,true)
	local moveTime = 3
	local moveY= 288
	local pos = item.item.transform.localPosition
	local movetween = item.item.transform:DOLocalMoveY(pos.y + moveY,moveTime)
	local alphaTime = 2.5
	local canvasGroup = item.item.transform:GetComponent(typeofCanvasGroup)
	canvasGroup.alpha =1
	local alphatween = CS.YXDOTweenModuleUI.DOFade(canvasGroup, 0, alphaTime)
	local seq = typeDOTween.Sequence()
	self._seqList[seq] = seq

	seq:SetAutoKill(true)
	seq:Append(movetween)
	seq:Insert(0.5,alphatween)

	seq:OnComplete(function()
		self._seqList[seq]= nil
		table.remove(self._showingList,1)
		self:CheckStopTimer()
		self:DestroyMsgItem(item)
	end)
	seq:SetUpdate(true)
	seq:PlayForward()

	--printInfoN("UISisMsg:OnItemShowEx(item) "..tostring(GetTimestamp()))
end

function UISisMsg:VersionRefresh()
	local text = self:FindWndTrans(self.mMsgTemplate,"text")
	self:InitTextLineWithLanguage(text,-30)
end

function UISisMsg:GetItemNew(type, posY)
	local itemNew
	if(type == 3)then
		itemNew = self._itemPool:GetObj()
	else
		itemNew = self._textPool:GetObj()
	end
	local y = posY ~= nil and posY or 0
	itemNew.transform.localPosition = Vector2.New(0,y)
	local itemRoot = self.mShowRoot
	itemNew.transform:SetParent(itemRoot.transform, false)
	return {item = itemNew,type = type}
end

function UISisMsg:DestroyMsgItem(item)
	if(item.type==1)then
		self._textPool:ReturnObj(item.item)
	else
		self._itemPool:ReturnObj(item.item)
	end
end

function UISisMsg:SetItemIcon(item,itemdata)
	local Image = self:FindWndTrans(item,"Image")
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	-- local otherItemRoot = self:FindWndTrans(item,"OtherItemRoot")
	local UIText = self:FindWndTrans(item,"UIText")
	-- local iconRoot = self:FindWndTrans(otherItemRoot, "IconRoot")
	-- 【G公共支持】删除伙伴晶石功能相关数据
	-- CS.ShowObject(itemRoot,itemdata.itype ~= LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD)
	-- CS.ShowObject(otherItemRoot,itemdata.itype == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD)

	-- 【G公共支持】删除伙伴晶石功能相关数据
	-- if(itemdata.itype == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD)then
	-- 	local colorName = gModelCrystalShard:GetColorNameByItemData(itemdata)
	-- 	self:SetWndText(UIText,colorName)
	-- 	if(itemdata.type == 1)then
	-- 		local iconBg = self:FindWndTrans(otherItemRoot,"IconBg")
	-- 		local icon = self:FindWndTrans(otherItemRoot,"Icon")
	-- 		local iconBgPath,iconPath,itemName = gModelCrystalShard:GetMapIconPathByItemData(itemdata)
	-- 		self:SetWndEasyImage(iconBg, iconBgPath)
	-- 		self:SetWndEasyImage(icon, iconPath)
	-- 		CS.ShowObject(iconRoot, false)
	-- 	else
	-- 		local icon = self:FindWndTrans(otherItemRoot,"Icon")
	-- 		CS.ShowObject(icon, false)
	-- 		CS.ShowObject(iconRoot, true)
	-- 		local uiCommonList = self._uiCommonList
	-- 		local InstanceID2 = otherItemRoot:GetInstanceID()
	-- 		local baseClass2 = uiCommonList[InstanceID2]
	-- 		if not baseClass2 then
	-- 			baseClass2 = CommonIcon:New()
	-- 			uiCommonList[InstanceID2] = baseClass2
	-- 			baseClass2:Create(iconRoot)
	-- 		end
	-- 		local isDetail = itemdata.isDetail or false

	-- 		if isDetail then
	-- 			baseClass2:SetRewardDetailItem(itemdata)
	-- 			baseClass2:EnableShowNum(false)
	-- 		else
	-- 			baseClass2:SetCommonReward(itemdata.itemType, itemdata.itemId, -1)
	-- 			baseClass2:EnableShowNum(true)
	-- 		end
	-- 		baseClass2:DoApply()
	-- 	end
	-- 	return
	-- end
	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		-- 【G公共支持】删除伙伴晶石功能相关数据
		-- if(itemdata.itype == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD)then
		-- 	baseClass:Create(otherItemRoot)
		-- else
			baseClass:Create(itemRoot)
		-- end

	end
	local isDetail = itemdata.isDetail or false

	if isDetail then
		baseClass:SetRewardDetailItem(itemdata)
		baseClass:EnableShowNum(false)
	else
		baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, -1)
		baseClass:EnableShowNum(true)
	end

	self:SetWndClick(itemRoot,function()
		if isDetail then return end
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
	baseClass:DoApply()

	local colorName
	if isDetail then
		local itype = itemdata.itype
		if itype then
			local data = {
				itemId = itemdata.refId,
				itemType = itype,
			}
			if itype == LItemTypeConst.TYPE_OUTFIT then
				local outfitName = gModelGeneral:GetCommonItemName(data)
				local color = gModelGeneral:GetCommonItemColor(data)
				local heroRefId = itemdata.heroRefId
				if heroRefId ~= 0 then
					local heroData = {
						itemId = heroRefId,
						itemType = LItemTypeConst.TYPE_HERO,
					}
					local heroName = gModelGeneral:GetCommonItemName(heroData)
					local str = string.replace(ccClientText(10177),outfitName,heroName)
					colorName = LUtil.FormatColorStr(str,color)
				else
					colorName = LUtil.FormatColorStr(outfitName,color)
				end
			else
				local itemNum = itemdata.num or 1
				data.itemNum = itemNum
				colorName = gModelGeneral:GetCommonItemColorName(data)
			end
		end
	else
		colorName = gModelGeneral:GetCommonItemColorName(itemdata)
	end
	self:SetWndText(UIText,colorName)

	local isForeign = gLGameLanguage:IsForeignRegion()
	CS.ShowObject(Image,not isForeign)
end

function UISisMsg:CreateMsg(data,detailData)
	local isDetail = detailData ~= nil
	local itemdata = isDetail and detailData or data
	if not itemdata then
		printErrorN("mesg is empty")
		return
	end
	local info = itemdata
	itemdata.isDetail = isDetail
	local itemShowType = isDetail and 3 or info.type
	local itemNew = self:GetItemNew(itemShowType, info.posY)
	if isDetail then
		self:SetItemIcon(itemNew.item,info)
	else
		if(itemNew.type==1)then
			local textNew = CS.FindTrans(itemNew.item,"text")
			self:SetWndText(textNew.transform,info.str)
		else
			local itemList = LxDataHelper.ParseItem(info.str)
			local itemData = itemList[1]
			self:SetItemIcon(itemNew.item,itemData)
		end
	end
	CS.ShowObject(itemNew.item,false)
	return itemNew
end

function UISisMsg:OnDestroy()
	LWnd.OnDestroy(self)
end

function UISisMsg:CheckStopTimer()
	if #self._msgWaitList ==0 and #self._showingList==0 then
		self:TimerStop(self._showTimer)
	end
end

function UISisMsg:ShowMsg(msg,detailData)
	local msgItem
	if detailData then
		msgItem = self:CreateMsg(nil,detailData)
	else
		local dataList = self:FormatMsg(msg)
		msgItem = self:CreateMsg(dataList)
	end
	self:OnItemShowEx(msgItem)
	local data = {item = msgItem}
	table.insert(self._showingList,data)
end

function UISisMsg:OnNewMsg(msg)
	if #self._msgWaitList==0 and #self._showingList==0 then
		self:ShowMsg(msg)
	else
		table.insert(self._msgWaitList,msg)
	end
	if not self:IsTimerExist(self._showTimer) then
		self:TimerStart(self._showTimer,0.5,false,-1)
	end
end

function UISisMsg:Test()
	local msg = "获得100#path=icon_item_dia#"
	self:OnNewMsg(msg)
end
------------------------------------------------------------------
return UISisMsg