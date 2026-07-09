---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIYellAwardLook:LWnd
local UIYellAwardLook = LxWndClass("UIYellAwardLook", LWnd)


UIYellAwardLook.CALL_HERO = 1
UIYellAwardLook.CALL_TREA = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIYellAwardLook:UIYellAwardLook()
	---@type UIItemList
	self._uiList = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIYellAwardLook:OnWndClose()
	self._uiList = nil

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIYellAwardLook:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIYellAwardLook:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitList()
	self:SetXUITextText(self.mCloseTip,ccClientText(10103))
	self:SetXUITextText(self.mTitle,ccClientText(11613))
end


function UIYellAwardLook:InitData()
	self._callRefId = self:GetWndArg("callRefId")
	self._wndType = self:GetWndArg("wndType") or UIYellAwardLook.CALL_HERO
	self._uicommonList = {}
end

function UIYellAwardLook:OnDrawHeroCell(list, item, itemdata, itempos, fromHeadTail)
	local CommonUITrans = CS.FindTrans(item,"CommonUI")
	if CommonUITrans then
		local reward = itemdata.itemdata
		local iconTrans = CS.FindTrans(CommonUITrans , "Icon")
		local InstanceID = item:GetInstanceID()
		local baseClass = self._uiList:GetItemCls(InstanceID)
		if not baseClass then
			baseClass = CommonIcon:New()
			self._uiList:SetItemCls(InstanceID, baseClass)
			baseClass:Create(iconTrans)
		end
		baseClass:SetCommonReward(reward.itemType,reward.itemId,reward.itemNum)
		baseClass:EnableShowNum(reward.itemNum>0)
		baseClass:SetNoShowLv(true)
		baseClass:DoApply()

		local itype,refId,count = baseClass:GetRewardType(),baseClass:GetRewardRefId(),baseClass:GetRewardCount()

		self:SetIconClickScale(iconTrans, true)
		self:SetWndClick(iconTrans,function()
			if itype == 2 then
				gModelGeneral:OpenHeroSimpleTip(refId,true)
			else
				gModelGeneral:ShowCommonItemTipWnd(reward)
			end
		end)
	end

	local textTrans = CS.FindTrans(item,"text")
	if textTrans then
		local num = itemdata.probability
		local str = num*100 .. "%"
		self:SetWndText(textTrans,str)
	end
end

function UIYellAwardLook:InitList()
	if self._wndType == UIYellAwardLook.CALL_HERO then
		self:ShowCallHero()
	elseif self._wndType == UIYellAwardLook.CALL_TREA then
		self:ShowCallTrea()
	end

end

function UIYellAwardLook:InitEvent()
	self:SetWndClick(self.mMaskBg,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIYellAwardLook:ShowCallHero()
	local qualityList = {}
	local callRef = gModelCallHero:GetCallRefByRefId(self._callRefId)
	local jackpotId,quality = callRef.jackpotId,callRef.quality
	quality = string.split(quality,",") or {}
	for i,v in ipairs(quality) do
		v = string.split(v,"=")
		qualityList[tonumber(v[1])] = true
	end
	local dataList = {}
	for k,v in pairs(GameTable.SummonJackpotRef) do
		if v.jackpotId == jackpotId and qualityList[v.smallJackpot] and v.show == 1 then
			table.insert(dataList,v)
		end
	end
	table.sort(dataList,function(t1,t2)
		return t1.sort < t2.sort
	end)

	local list = {}
	for k,v in ipairs(dataList) do
		local itemdata = LxDataHelper.ParseItem_3(v.reward)
		local data =
		{
			itemdata = itemdata,
			probability = v.probabilityShow,
		}
		table.insert(list,data)
	end

	self:ShowList(list)
end

function UIYellAwardLook:ShowList(dataList)
	local uiList = self._uiList
	if not uiList then
		uiList = self:GetUIScroll("_key_uiList")
		self._uiList = uiList
		uiList:Create(self.mHeroList,dataList, function(...)
			self:OnDrawHeroCell(...)
		end,UIItemList.WRAP,false)
		--uiList:EnableScroll(true,false)
		local list = uiList:GetList()
		list:EnableLoadAnimation(true, 0, 4)
		list:RefreshList(UIListWrap.RefreshMode.Solid)
	else
		uiList:RefreshList(dataList)
	end
end

function UIYellAwardLook:ShowCallTrea()
	-- local list=gModelTreasure:GetTreasureDropByType(1)
	-- local dataList = {}
	-- for k,v in ipairs(list) do
	-- 	local itemdata = LxDataHelper.ParseItem_3(v.reward)
	-- 	--itemdata.itemNum = -1
	-- 	local data =
	-- 	{
	-- 		itemdata = itemdata,
	-- 		probability = v.probabilityShow,
	-- 	}
	-- 	table.insert(dataList,data)
	-- end

	-- self:ShowList(dataList)
end

------------------------------------------------------------------
return UIYellAwardLook


