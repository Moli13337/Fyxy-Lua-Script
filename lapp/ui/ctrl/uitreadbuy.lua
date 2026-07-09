---
--- Created by Administrator.
--- DateTime: 2023/10/14 16:29:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITreadBuy:LWnd
local UITreadBuy = LxWndClass("UITreadBuy", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITreadBuy:UITreadBuy()
	---@type table<number, CommonIcon>
	self._commonIconTbl = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITreadBuy:OnWndClose()
	self:ClearCommonIconList(self._commonIconTbl)
	self._commonIconTbl = nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITreadBuy:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITreadBuy:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)
	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)
	self:RefreshUI()

	self:InitNetEvent()

	gModelTreaFind:OnFindTreasureInfoReq()
end

function UITreadBuy:BuyGoods(itemdata)
	local data = gModelTreaFind:GetTreaFindInfo()
	if not data then
		return
	end
	local buyCnt = data.buyCount
	local limitCnt = data.buyLimit
	if buyCnt>=limitCnt then
		local maxLimit = gModelVip:GetMaxTreaBuy()
		local str = nil
		if maxLimit>data.buyLimit then
			str =ccClientText(19405) -- "提升VIP等级,可购买更多"
		else
			str =ccClientText(19406) -- "购买次数不足,明日再来"
		end
		GF.ShowMessage(str)

	else
		--todo buy
		--local dataList = gModelTreaFind:GetGoodsList()
		--local itemdata = dataList[type]
		local price = itemdata.price
		local itemNum = price.itemNum
		local own = gModelItem:GetNumByRefId(price.itemId)
		local wndName = self:GetWndName()
		if own<itemNum then
			gModelGeneral:OpenGetWayWnd({itemId = price.itemId,srcWnd = wndName})
		else
			local type = itemdata.type
			local cnt = 1
			if type == 2 then
				cnt = 5
			end

			local canBuy = math.floor(own/itemNum)
			local maxBuy =math.floor((limitCnt - buyCnt)/cnt)
			local limit = math.min(canBuy,maxBuy)

			local data =
			{
				price = price,
				rewards =itemdata.reward,
				limit = limit,
				leftTimes = maxBuy,
				type = itemdata.type
			}
			GF.OpenWnd("UIDianBuy",{goodsData = data,wndType = 2})
			--gModelTreaFind:OnFindTreasureBuyReq(type)
		end
	end
end

function UITreadBuy:OnDrawGood(list,item,itemdata,itempos)

	local bg = self:FindWndTrans(item,"bg")
	local itemName = self:FindWndTrans(item,"itemName")
	local soldout = self:FindWndTrans(item,"soldout")
	local soldoutIcon = self:FindWndTrans(soldout,"icon")
	local buyBtn = self:FindWndTrans(item,"buyBtn")
	local buyBtnLayout = self:FindWndTrans(buyBtn,"layout")
	local layoutIcon = self:FindWndTrans(buyBtnLayout,"icon")
	local layoutNum = self:FindWndTrans(buyBtnLayout,"num")
	local DiscountImg = self:FindWndTrans(item,"DiscountImg")
	local DiscountImgText = self:FindWndTrans(DiscountImg,"text")
	local limit = self:FindWndTrans(item,"limit")

	local rewardData = itemdata.reward
	local iconTrans = CS.FindTrans(item, "CommonUI/Icon")

	local instanceId = item:GetInstanceID()
	local baseClass = self._commonIconTbl[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._commonIconTbl[instanceId] = baseClass
		baseClass:Create(iconTrans)
	end
	baseClass:SetCommonReward(rewardData.itemType,rewardData.itemId, rewardData.itemNum)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()

	self:SetIconClickScale(iconTrans, true)
	self:SetWndClick(iconTrans,function()
		gModelGeneral:ShowCommonItemTipWnd(rewardData)
	end)

	local nameCfg = gModelGeneral:GetCommonItemName(rewardData)
	self:SetWndText(itemName,nameCfg)

	local price = itemdata.price
	local showIcon = false
	local priceNum =price.itemNum
	if priceNum > 0 then
		showIcon = true
		local priceIcon = gModelItem:GetItemImgByRefId(price.itemId)
		if priceIcon then
			self:SetWndEasyImage(layoutIcon,priceIcon)
		end

		local priceStr = nil
		if price.itemId == 101001 then
			priceStr = LUtil.NumberCoversion(priceNum)
		else
			priceStr = LUtil.AddNumberSeparate(priceNum)
		end

		self:SetWndText(layoutNum,priceStr)
	else
		local str = ccClientText(11913)
		self:SetWndText(layoutNum,str)
	end
	CS.ShowObject(layoutIcon,showIcon)

	local discountIcon = itemdata.discount
	local show = false
	if not string.isempty(discountIcon) then
		show = true
		self:SetWndText(DiscountImgText,discountIcon)
		--self:SetWndEasyImage(discount,discountIcon)
	end

	CS.ShowObject(DiscountImg,show)

	CS.ShowObject(limit,false)
	CS.ShowObject(soldout,false)
	self:SetWndClick(buyBtn,function () self:BuyGoods(itemdata) end)
end



function UITreadBuy:RefreshUI()

	local str =ccClientText(19403) -- "购买寻宝石"
	self:SetWndText(self.mTitle,str)

	local data = gModelTreaFind:GetTreaFindInfo()
	if not data then
		return
	end
	local buyCnt = data.buyCount
	local limitCnt = data.buyLimit
	local color = "green"
	if buyCnt>= limitCnt then
		color = "red"
	end

	--local str =ccClientText(19404) -- "今日剩余购买次数:%s/%s"
	local str = string.format("%s/%s",buyCnt,limitCnt)
	str = LUtil.FormatColorStr(str,color)
	local showStr =ccClientText(19404)..str
	self:SetWndText(self.mIntro,showStr)
	local dataList = gModelTreaFind:GetGoodsList()

	local list = self:GetUIScroll("itemList")
	list:Create(self.mItemList,dataList,function (...) self:OnDrawGood(...) end)



end

function UITreadBuy:InitNetEvent()
	self:WndNetMsgRecv(LProtoIds.FindTreasureInfoResp,function ()
		self:RefreshUI()
	end)
end



------------------------------------------------------------------
return UITreadBuy


