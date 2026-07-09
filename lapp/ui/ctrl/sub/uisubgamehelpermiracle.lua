---
--- Created by Administrator.
--- DateTime: 2024/11/5 15:45:33
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGameHelperMiracle:LChildWnd
local UISubGameHelperMiracle = LxWndClass("UISubGameHelperMiracle", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGameHelperMiracle:UISubGameHelperMiracle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGameHelperMiracle:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGameHelperMiracle:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGameHelperMiracle:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:UpdateSetting()
end

function UISubGameHelperMiracle:ClickCrystalNum(b, num)
	if b then
		num = math.min(self.crystalMax, num)
	else
		num = self.crystalNum + num
		num = math.min(self.crystalMax, num)
		num = math.max(num, 0)
	end
	local setting = {
		refId = 1124,
		parameter1 = num
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end

function UISubGameHelperMiracle:ClickExpNum(b, num)
	if b then
		num = math.min(self.expMax, num)
	else
		num = self.expNum + num
		num = math.min(self.expMax, num)
		num = math.max(num, 0)
	end
	local setting = {
		refId = 1122,
		parameter1 = num
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end

function UISubGameHelperMiracle:UpdateCost()
	local cost = 0
	local t = {
		self.goldNum,
		self.expNum,
		self.crystalNum,
		self.markNum
	}
	for i, v in ipairs(t) do
		if v > 0 then
			for times = 1, v do
				local costData = gModelDungeonDaily:GetSweepExpend(i, times)
				if not costData then
					local cfg = gModelGeneral:GetSysEffectRef(80015)
					local costInfo = LxDataHelper.ParseItem(cfg.effectValue)
					local num = #gModelDungeonDaily:GetSweepExpendByType(i)
					costData = costInfo[times - num]
				end
				cost = cost + costData.itemNum
			end
		end
	end
	self:SetWndText(self.mCostNum, "x" .. cost)
end

function UISubGameHelperMiracle:ClickGlodNum(b, num)
	if b then
		num = math.min(self.goldMax, num)
	else
		num = self.goldNum + num
		num = math.min(self.goldMax, num)
		num = math.max(num, 0)
	end
	local setting = {
		refId = 1123,
		parameter1 = num
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end

function UISubGameHelperMiracle:InitCommon()
	------------------------------------------------------------------
	---member
	self.id = self:GetWndArg("id")
	local cfg = GameTable.AssistantTabRef[self.id]

	------------------------------------------------------------------
	---text
	self:SetTextTile(self.mTitle, ccLngText(cfg.name) .. ccClientText(24228))
	self:SetTextTile(self.mFreeToggle, ccClientText(24240))
	self:SetTextTile(self.mGlodObj, ccClientText(24241))
	self:SetTextTile(self.mExpObj, ccClientText(24242))
	self:SetTextTile(self.mCrystalObj, ccClientText(24243))
	self:SetTextTile(self.mMarkObj, ccClientText(24244))
	self:SetTextTile(self.mCostObj, ccClientText(24237))

	------------------------------------------------------------------
	---click
	local t = {
		"Glod",
		"Exp",
		"Crystal",
		"Mark",
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
			refId = 1121,
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

function UISubGameHelperMiracle:UpdateSetting()
	local freeSetting = gModelGameHelper:GetSettingById(1121)
	self.freeToggle = freeSetting.parameter1 == 1
	self:SetWndTabStatus(self.mFreeToggle, self.freeToggle and 0 or 1)

	local goldSetting = gModelGameHelper:GetSettingById(1123)
	self.goldNum = goldSetting.parameter1
	self.goldMax = tonumber(goldSetting.functionData)
	self:SetWndText(self.mGlodNum, self.goldNum)

	local expSetting = gModelGameHelper:GetSettingById(1122)
	self.expNum = expSetting.parameter1
	self.expMax = tonumber(expSetting.functionData)
	self:SetWndText(self.mExpNum, self.expNum)

	local crystalSetting = gModelGameHelper:GetSettingById(1124)
	self.crystalNum = crystalSetting.parameter1
	self.crystalMax = tonumber(crystalSetting.functionData)
	self:SetWndText(self.mCrystalNum, self.crystalNum)

	local markSetting = gModelGameHelper:GetSettingById(1125)
	self.markNum = markSetting.parameter1
	self.markMax = tonumber(markSetting.functionData)
	self:SetWndText(self.mMarkNum, self.markNum)

	self:UpdateCost()
end

function UISubGameHelperMiracle:ClickMarkNum(b, num)
	if b then
		num = math.min(self.markMax, num)
	else
		num = self.markNum + num
		num = math.min(self.markMax, num)
		num = math.max(num, 0)
	end
	local setting = {
		refId = 1125,
		parameter1 = num
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end


------------------------------------------------------------------
return UISubGameHelperMiracle