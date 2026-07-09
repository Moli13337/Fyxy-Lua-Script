---
--- Created by Administrator.
--- DateTime: 2024/11/5 15:38:17
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGameHelperBarave:LChildWnd
local UISubGameHelperBarave = LxWndClass("UISubGameHelperBarave", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGameHelperBarave:UISubGameHelperBarave()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGameHelperBarave:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGameHelperBarave:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGameHelperBarave:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:UpdateSetting()
end

function UISubGameHelperBarave:ClickChangeNum(b, num)
	if b then
		num = math.min(self.changeMax, num)
	else
		num = self.changeNum + num
		num = math.min(self.changeMax, num)
		num = math.max(num, 0)
	end
	local setting = {
		refId = 1091,
		parameter1 = num,
		parameter2 = self.defaultToggle and 1 or 0,
		parameter3 = self.highPowerToggle and 1 or 0
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end

function UISubGameHelperBarave:UpdateSetting()
	local setting = gModelGameHelper:GetSettingById(1091)
	self.defaultToggle = setting.parameter2 == 1
	self:SetWndTabStatus(self.mDefaultToggle, self.defaultToggle and 0 or 1)

	self.highPowerToggle = setting.parameter3 == 1
	self:SetWndTabStatus(self.mHighPowerToggle, self.highPowerToggle and 0 or 1)

	self.changeNum = setting.parameter1
	local num = tonumber(setting.functionData)
	self.changeMax = num == -1 and 999 or num
	self:SetChangeNumText()

	local setting = gModelGameHelper:GetSettingById(1131)
	self.nobilityLoseNum = setting.parameter1
	self.nobilityLoseMax = tonumber(setting.functionData)
	self:SetWndText(self.mNobilityLoseNum, self.nobilityLoseNum)

	self.nobilityChangeNum = setting.parameter2
	self.nobilityChangeMax = GameTable.AssistantConfig.crossGradingCount
	self:SetWndText(self.mNobilityChangeNum, self.nobilityChangeNum)
end

function UISubGameHelperBarave:ClickNobilityLoseNum(b, num)
	if b then
		num = math.min(self.nobilityLoseMax, num)
	else
		num = self.nobilityLoseNum + num
		num = math.min(self.nobilityLoseMax, num)
		num = math.max(num, 0)
	end
	local setting = {
		refId = 1131,
		parameter1 = num,
		parameter2 = self.nobilityChangeNum
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end

function UISubGameHelperBarave:InitCommon()
	------------------------------------------------------------------
	---member
	self.id = self:GetWndArg("id")
	local cfg = GameTable.AssistantTabRef[self.id]

	------------------------------------------------------------------
	---text
	self:SetTextTile(self.mTitle, ccLngText(cfg.name) .. ccClientText(24228))
	self:SetTextTile(self.mDefaultToggle, ccClientText(24254))
	self:SetTextTile(self.mHighPowerToggle, ccClientText(24255))
	self:SetTextTile(self.mBaraveTitle, ccLngText(GameTable.AssistantListRef[109].name))
	self:SetTextTile(self.mNobilityTitle, ccLngText(GameTable.AssistantListRef[113].name))
	self:SetTextTile(self.mNobilityLoseObj, ccClientText(24265))
	self:SetTextTile(self.mNobilityChangeObj, ccClientText(24256))
	self:SetWndText(self.mText, ccClientText(24256))

	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mSub, function()
		self:ClickChangeNum(false, -1)
	end)
	self:SetWndClick(self.mAdd, function()
		self:ClickChangeNum(false, 1)
	end)
	self:SetWndClick(self.mNumObj, function()
		local func = function(input)
			if self:IsWndClosed() then
				return
			end
			self:SetWndText(self.mNum, input)
		end

		local closeFunc = function(input)
			if self:IsWndClosed() then
				return
			end
			self:ClickChangeNum(true, input)
		end

		local para = {
			minNum = 0,
			maxNum = 999999,
			defaultNum = 0,
			inputFunc = func,
			inputTran = self.mNumObj,
			closeFunc = closeFunc
		}

		GF.OpenWnd("UINuoardUI", para)
	end)
	self:SetWndClick(self.mDefaultToggle, function()
		local v = self.defaultToggle and 0 or 1
		local setting = {
			refId = 1091,
			parameter1 = self.changeNum,
			parameter2 = v,
			parameter3 = self.highPowerToggle and 1 or 0
		}
		gModelGameHelper:GameHelperSettingReq(2, setting)
	end)
	self:SetWndClick(self.mHighPowerToggle, function()
		local v = self.highPowerToggle and 0 or 1
		local setting = {
			refId = 1091,
			parameter1 = self.changeNum,
			parameter2 = self.defaultToggle and 1 or 0,
			parameter3 = v,
		}
		gModelGameHelper:GameHelperSettingReq(2, setting)
	end)

	local numObj = CS.FindTrans(self.mNobilityLoseObj, "NumObj")
	local sub = CS.FindTrans(numObj, "Sub")
	local add = CS.FindTrans(numObj, "Add")

	self:SetWndClick(sub, function()
		self:ClickNobilityLoseNum(false, -1)
	end)
	self:SetWndClick(add, function()
		self:ClickNobilityLoseNum(false, 1)
	end)
	self:SetWndClick(numObj, function()
		local func = function(input)
			if self:IsWndClosed() then
				return
			end
			self:SetWndText(self.mNobilityLoseNum, input)
		end

		local closeFunc = function(input)
			if self:IsWndClosed() then
				return
			end
			self:ClickNobilityLoseNum(true, input)
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

	local numObj = CS.FindTrans(self.mNobilityChangeObj, "NumObj")
	local sub = CS.FindTrans(numObj, "Sub")
	local add = CS.FindTrans(numObj, "Add")

	self:SetWndClick(sub, function()
		self:ClickNobilityChangeNum(false, -1)
	end)
	self:SetWndClick(add, function()
		self:ClickNobilityChangeNum(false, 1)
	end)
	self:SetWndClick(numObj, function()
		local func = function(input)
			if self:IsWndClosed() then
				return
			end
			self:SetWndText(self.mNobilityChangeNum, input)
		end

		local closeFunc = function(input)
			if self:IsWndClosed() then
				return
			end
			self:ClickNobilityChangeNum(true, input)
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

	------------------------------------------------------------------
	---event
	self:WndEventRecv("GameHelperSettingResp", function()
		self:UpdateSetting()
	end)

end

function UISubGameHelperBarave:SetChangeNumText()
	self:SetWndText(self.mNum, self.changeNum)
end

function UISubGameHelperBarave:ClickNobilityChangeNum(b, num)
	if b then
		num = math.min(self.nobilityChangeMax, num)
	else
		num = self.nobilityChangeNum + num
		num = math.min(self.nobilityChangeMax, num)
		num = math.max(num, 0)
	end
	local setting = {
		refId = 1131,
		parameter1 = self.nobilityLoseNum,
		parameter2 = num
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end



------------------------------------------------------------------
return UISubGameHelperBarave