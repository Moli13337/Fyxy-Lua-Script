---
--- Created by Administrator.
--- DateTime: 2024/8/8 20:27:10
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMinLineAwardsTips:LWnd
local UIMinLineAwardsTips = LxWndClass("UIMinLineAwardsTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMinLineAwardsTips:UIMinLineAwardsTips()
	self.commonUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMinLineAwardsTips:OnWndClose()
	self:ClearCommonIconList(self.commonUIList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMinLineAwardsTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMinLineAwardsTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)

	self:SetWndText(self.mTitle, ccClientText(45003))
	self:SetWndText(self.mCloseTip, ccClientText(17003))

	local theGirdPos = self:GetWndArg(1)
	local list = {}
	local cfg = GameTable.MainInstanceProRewardRef
	for _, v in pairs(cfg) do
		if v.type == 1 then
			local data = {
				reward = LxDataHelper.ParseItem(v.reward),
				sort = v.sort,
				name = ccLngText(gModelInstance:GetMissionCfg(v.refId).nameWorld)
			}
			table.insert(list, data)
		end
	end
	table.sort(list, function(a, b)
		return a.sort < b.sort
	end)

	local SetRewardIcon = function(root, data)
		local instanceId = root:GetInstanceID()
		if not self.commonUIList[instanceId] then
			self.commonUIList[instanceId] = CommonIcon:New()
			self.commonUIList[instanceId]:Create(root)
		end
		self.commonUIList[instanceId]:SetCommonReward(data.itemType, data.itemId, data.itemNum)
		self.commonUIList[instanceId]:DoApply()

		self:SetWndClick(root, function()
			gModelGeneral:ShowCommonItemTipWnd(data)
		end)
	end

	local DrawReward = function(_, item, data, pos)
		local titel = CS.FindTrans(item, "Bg/TitleImg/Title")
		local rewardObj = CS.FindTrans(item, "Bg/RewardObj")

		self:SetWndText(titel, data.name)

		for i = 1, 5 do
			local tran = CS.FindTrans(rewardObj, "Item" .. i)
			local root = CS.FindTrans(tran, "Root")
			local isGet = CS.FindTrans(tran, "IsGet")
			if data.reward[i] then
				SetRewardIcon(root, data.reward[i])
			end
			CS.ShowObject(tran, data.reward[i] ~= nil)
			CS.ShowObject(isGet, theGirdPos >= pos)
			self:SetWndClick(isGet, function()
				gModelGeneral:ShowCommonItemTipWnd(data.reward[i])
			end)
		end
	end

	local rewardList = self:GetUIScroll("mRewardList")
	rewardList:Create(self.mRewardList, list, function(...) DrawReward(...) end, UIItemList.SUPER)
end


------------------------------------------------------------------
return UIMinLineAwardsTips