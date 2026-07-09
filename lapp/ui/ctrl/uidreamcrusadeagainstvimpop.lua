---
--- Created by BY.
--- DateTime: 2022/10/26 15:35:03
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDreamCrusadeAgainstVimPop:LWnd
local UIDreamCrusadeAgainstVimPop = LxWndClass("UIDreamCrusadeAgainstVimPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDreamCrusadeAgainstVimPop:UIDreamCrusadeAgainstVimPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDreamCrusadeAgainstVimPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDreamCrusadeAgainstVimPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDreamCrusadeAgainstVimPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIDreamCrusadeAgainstVimPop:RefreshData()
	local buyCount ,buyLimit = gModelCrusadeAgainst:GetBuyInfo()
	local buyEnergy = gModelCrusadeAgainst:GetDreamCrusadeConfigRefByKey("buyEnergy")
	local buyEnergyItem = LxDataHelper.ParseItem_4(buyEnergy)
	local priceEnergy = gModelCrusadeAgainst:GetDreamCrusadeConfigRefByKey("priceEnergy")
	local priceEnergyList = LxDataHelper.ParseItem(priceEnergy)

	local name = gModelItem:GetNameByRefId(buyEnergyItem.itemId)
	local num = gModelItem:GetNumByRefId(buyEnergyItem.itemId)
	local des = gModelItem:GetDescByRefId(buyEnergyItem.itemId)
	local costNum = priceEnergyList[buyCount + 1]
	if not costNum then
		costNum = priceEnergyList[#priceEnergyList]
	end
	self:SetWndText(self.mNameText,name)
	self:SetWndText(self.mNumText,string.replace(ccClientText(32313),num))
	self:SetWndText(self.mDesText,des)
	self:CreateCommonIconImpl(self.mCommonIcon,buyEnergyItem)
	self:SetWndText(self.mCostNumText,costNum.itemNum)
	local costIconTrans = self:FindWndTrans(self.mBtnBuy,"Image/Image")
	local iconRef = gModelItem:GetRefByRefId(costNum.itemId)
	self:SetWndEasyImage(costIconTrans,iconRef.icon)
	self:SetWndButtonText(self.mBtnBuy,string.replace(ccClientText(32315),buyLimit - buyCount))

	local vipLv = gModelPlayer:GetVipLevel()
	local vipRef = gModelVip:GetRefByVipLv(vipLv)
	local physical = gModelCrusadeAgainst:GetPhysical()
	local energyLimit = vipRef.energyLimit

	self:SetWndText(self.mStaminaText,string.format("%s/%s",physical,energyLimit))
end

function UIDreamCrusadeAgainstVimPop:OnClickBuy()
	--local bool = self:CheckIsPhysical()
	--if not bool then
	--	return
	--end

	local buyCount ,buyLimit = gModelCrusadeAgainst:GetBuyInfo()
	if buyCount >= buyLimit then
		GF.ShowMessage(ccClientText(32323))
		return
	end
	local priceEnergy = gModelCrusadeAgainst:GetDreamCrusadeConfigRefByKey("priceEnergy")
	local priceEnergyList = LxDataHelper.ParseItem(priceEnergy)
	--local costNum = priceEnergyList[buyCount + 1]
	--if not costNum then
	--	costNum = priceEnergyList[#priceEnergyList]
	--end
	--local isEnough = gModelGeneral:CheckItemEnough(costNum.itemId,costNum.itemNum,true)
	--if not isEnough then
	--	return
	--end
	--gModelCrusadeAgainst:OnCrusadeBuyReq()

	local buyEnergy = gModelCrusadeAgainst:GetDreamCrusadeConfigRefByKey("buyEnergy")
	local buyEnergyItem = LxDataHelper.ParseItem_4(buyEnergy)

	local data =
	{
		price = priceEnergyList,
		item = buyEnergyItem,
		limit = buyCount - buyLimit,
		buyCount = buyCount,
		buyLimit = buyLimit,
	}
	GF.OpenWnd("UIDianBuy",{goodsData = data,wndType = 5,callFunc = function (num)
		--LogError(string.format("购买体力药剂 %s 次",num))
		local buyId,buyNum
		for i = 1, num do
			local costItem = priceEnergyList[buyCount + i]
			if not costItem then
				costItem = priceEnergyList[#priceEnergyList]
			end
			if buyId then
				buyNum = buyNum + costItem.itemNum
			else
				buyId = costItem.itemId
				buyNum = costItem.itemNum
			end
		end
		if not buyId or not buyNum then return end
		local isEnough = gModelGeneral:CheckItemEnough(buyId,buyNum,true)
		if not isEnough then
			return
		end
		gModelCrusadeAgainst:OnCrusadeBuyReq(num)
	end})
end
function UIDreamCrusadeAgainstVimPop:OnClickUse()
	--local bool = self:CheckIsPhysical()
	--if not bool then
	--	return
	--end
	local buyEnergy = gModelCrusadeAgainst:GetDreamCrusadeConfigRefByKey("buyEnergy")
	local buyEnergyItem = LxDataHelper.ParseItem_4(buyEnergy)
	local itemId = buyEnergyItem.itemId
	local isEnough = gModelGeneral:CheckItemEnough(itemId,1,false)
	if not isEnough then
		GF.ShowMessage(ccClientText(32322))
		return
	end
	gModelItem:OnItemUseReq({{refId = itemId,num = 1}})		 --向服务器发送物品使用请求
end
function UIDreamCrusadeAgainstVimPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(32312))
	self:SetWndText(self.mCostDesText,ccClientText(32314))
	self:SetWndButtonText(self.mBtnUse,ccClientText(32316))

	self:RefreshData()

	if gLGameLanguage:IsEnglishVersion() or gLGameLanguage:IsVieVersion() then
		self:SetAnchorPos(self.mCostDesText,Vector2.New(-48,-1))
	end
end

function UIDreamCrusadeAgainstVimPop:InitEvent()
	self:SetWndClick(self.mBgImage,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
	self:SetWndClick(self.mBtnBuy,function ()self:OnClickBuy() end)
	self:SetWndClick(self.mBtnUse,function ()self:OnClickUse() end)
end

function UIDreamCrusadeAgainstVimPop:CheckIsPhysical()
	local vipLv = gModelPlayer:GetVipLevel()
	local vipRef = gModelVip:GetRefByVipLv(vipLv)
	local physical = gModelCrusadeAgainst:GetPhysical()
	local energyLimit = vipRef.energyLimit
	if physical >= energyLimit then
		GF.ShowMessage(ccClientText(32324))
		return false
	end
	return true
end
function UIDreamCrusadeAgainstVimPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ItemChangeResp,function()
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.CrusadeBuyResp,function()
		self:RefreshData()
	end)
end
------------------------------------------------------------------
return UIDreamCrusadeAgainstVimPop


