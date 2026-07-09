---
--- Created by Administrator.
--- DateTime: 2024/11/5 15:42:21
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGameHelperGetGold:LChildWnd
local UISubGameHelperGetGold = LxWndClass("UISubGameHelperGetGold", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGameHelperGetGold:UISubGameHelperGetGold()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGameHelperGetGold:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGameHelperGetGold:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGameHelperGetGold:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:UpdateSetting()
end

function UISubGameHelperGetGold:SetItemNumText()
	self:SetWndText(self.mItemNum, self.itemNum)
	self:SetWndText(self.mItemCost, "x" .. self.itemNum)
end

function UISubGameHelperGetGold:SetDiamondNumText()
	self:SetWndText(self.mDiamondNum, self.diamondNum)
	self:SetWndText(self.mDiamondCost, "x" .. self.diamondNum * self.diamondCost)
end

function UISubGameHelperGetGold:InitCommon()
	------------------------------------------------------------------
	---member
	self.DiamondMax = 0
	self.ItemMax = 0
	self.diamondNum = 0
	self.itemNum = 0
	self.id = self:GetWndArg("id")
	local cfg = GameTable.AssistantTabRef[self.id]
	local cfg2 = GameTable.AssistantListRef

	------------------------------------------------------------------
	---text
	self:SetTextTile(self.mTitle, ccLngText(cfg.name) .. ccClientText(24228))
	self:SetTextTile(self.mGoldTitle, ccLngText(cfg2[105].name))
	self:SetTextTile(self.mFreeToggle, ccClientText(24229))
	self:SetWndText(self.mDiamondText, ccClientText(24230))
    self:SetWndText(self.mItemText, ccClientText(24231))
    self:SetTextTile(CS.FindTrans(self.mDiamondObj, "CostObj"), ccClientText(24232))
    self:SetTextTile(CS.FindTrans(self.mItemObj, "CostObj"), ccClientText(24232))

	------------------------------------------------------------------
	---click
	local t = {
		"Diamond",
		"Item"
	}
	for _, v in ipairs(t) do
		local transS = "m#a1#Obj"
		local funS = "Click#a1#Num"
		local obj = self[string.replace(transS, v)]
		local numObj = CS.FindTrans(obj, "NumObj")
		local sub = CS.FindTrans(numObj, "Sub")
		local add = CS.FindTrans(numObj, "Add")
		local num = CS.FindTrans(numObj, v .. "Num")

		self:SetWndClick(sub, function()
			self[string.replace(funS, v)](self, false, -1)
		end)
		self:SetWndClick(add, function()
			self[string.replace(funS, v)](self, false, 1)
		end)
		self:SetWndClick(numObj, function()
			local func = function(input)
				if self:IsWndClosed() then
					return
				end
				self:SetWndText(num, input)
			end

			local closeFunc = function(input)
				if self:IsWndClosed() then
					return
				end
				self[string.replace(funS, v)](self, true, input)
			end

			local para = {
				minNum = 0,
				maxNum = 999999999,
				defaultNum = 0,
				inputFunc = func,
				inputTran = numObj,
				closeFunc = closeFunc
			}

			GF.OpenWnd("UINuoardUI", para)
		end)
	end

	self:SetWndClick(self.mFreeToggle, function()
		local v = self.freeToggle and 0 or 1
		local setting = {
			refId = 1051,
			parameter1 = v
		}
		gModelGameHelper:GameHelperSettingReq(2, setting)
	end)

	------------------------------------------------------------------
	---event
	self:WndEventRecv("GameHelperSettingResp", function()
		self:UpdateSetting()
	end)
end

function UISubGameHelperGetGold:ClickDiamondNum(b, num)
	if b then
		num = math.min(self.diamondMax, num)
	else
		num = self.diamondNum + num
		num = math.min(self.diamondMax, num)
		num = math.max(num, 0)
	end
	local setting = {
		refId = 1052,
		parameter1 = num
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end

function UISubGameHelperGetGold:ClickItemNum(b, num)
	if b then
		num = math.min(self.itemMax, num)
	else
		num = self.itemNum + num
		num = math.min(self.itemMax, num)
		num = math.max(num, 0)
	end
	local setting = {
		refId = 1053,
		parameter1 = num
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end

function UISubGameHelperGetGold:UpdateSetting()
	local freeSetting = gModelGameHelper:GetSettingById(1051)
	self.freeToggle = freeSetting.parameter1 == 1
	self:SetWndTabStatus(self.mFreeToggle, self.freeToggle and 0 or 1)

	local diamondSetting = gModelGameHelper:GetSettingById(1052)
	self.diamondNum = diamondSetting.parameter1
	self.diamondMax = tonumber(diamondSetting.functionData)
	local basicsRef = gModelGoldBuy:GetGoldBuyBasicsRefById(2)
	local buyNeedArr = string.split(basicsRef.buyNeed,"=")
	local buyNeed = {
		itemType = 1,
		itemId = tonumber(buyNeedArr[1]),
		itemNum = tonumber(buyNeedArr[2]),
	}
	self.diamondCost = buyNeed.itemNum
	self:SetDiamondNumText()

	local itemSetting = gModelGameHelper:GetSettingById(1053)
	self.itemNum = itemSetting.parameter1
	local num = tonumber(itemSetting.functionData)
	self.itemMax = num == -1 and 999 or num
	local basicsRef = gModelGoldBuy:GetGoldBuyBasicsRefById(2)
	local buyNeedArr = string.split(basicsRef.buyNeed,"=")
	local buyNeed = {
		itemType = 1,
		itemId = tonumber(buyNeedArr[1]),
		itemNum = tonumber(buyNeedArr[2]),
	}
	self.itemCost = buyNeed.itemNum
	self:SetItemNumText()
end



------------------------------------------------------------------
return UISubGameHelperGetGold