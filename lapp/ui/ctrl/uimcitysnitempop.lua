---
--- Created by BY.
--- DateTime: 2023/10/10 20:16:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMCitySnItemPop:LWnd
local UIMCitySnItemPop = LxWndClass("UIMCitySnItemPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMCitySnItemPop:UIMCitySnItemPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMCitySnItemPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMCitySnItemPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMCitySnItemPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIMCitySnItemPop:RefreshData()
	local refId = self._refId
	local itemRef = gModelItem:GetRefByRefId(refId)
	local icon,iconBg = gModelItem:GetItemImgByRefId(refId)
	local num = gModelItem:GetNumByRefId(refId)
	local skinId = tonumber(itemRef.typeDate)

	local skinRef = gModelPlayerSpace:GetOneNightSkinRefByRefId(skinId)

	self:SetWndEasyImage(self.mItemBg,iconBg)
	self:SetWndEasyImage(self.mItemIcon,icon)
	self:SetWndText(self.mNameText,ccLngText(itemRef.name))
	self:SetWndText(self.mNumText,string.replace(ccClientText(30310),num))
	self:SetWndText(self.mDesText,ccLngText(itemRef.description))

	self:SetWndEasyImage(self.mSkinIcon,skinRef.icon)
	local isAct = gModelPlayerSpace:GetMainCitySkinByRefId(skinId)
	local ref = gModelPlayerSpace:GetOneNightSkinRefByRefId(skinId)
	local free = ref.free or 0
	local haveItem = not string.isempty(ref.item)
	local isFree = free == 1 and haveItem

	local func = nil
	local btnStr = ""
	if isAct and not isFree then
		btnStr = ccClientText(30312)
		local sell = LxDataHelper.ParseItem_3(itemRef.sell)
		local sellNum = sell.itemNum * num
		local sellName = gModelItem:GetNameByRefId(sell.itemId)
		sellName = sellNum .. sellName

		func = function()
			gModelGeneral:OpenUIOrdinTips({refId = 10010,para = {ccLngText(skinRef.name),sellName},func = function ()
				gModelGeneral:OnSellGoodsReq({{itype = LItemTypeConst.TYPE_ITEM,refId = refId,num = num}})
			end},true)
		end
	else
		btnStr = ccClientText(30313)
		func = function()
			GF.OpenWnd("UIMCitySnPreview",{refId = skinId})
			self:WndClose()
		end
	end
	self:SetWndButtonText(self.mBtnActivity,btnStr)
	self:SetWndClick(self.mBtnActivity,function ()
		if func then func() end
	end)
end
function UIMCitySnItemPop:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(30309))
	self:SetWndText(self.mDesTitleText,ccClientText(30311))

	local refId = self:GetWndArg("refId")
	self._refId = refId
	self:RefreshData()
end
function UIMCitySnItemPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.SellGoodsResp,function(pb) self:WndClose() end)
end
function UIMCitySnItemPop:InitEvent()
	self:SetWndClick(self.mBgImage,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function ()self:WndClose() end)
end
------------------------------------------------------------------
return UIMCitySnItemPop


