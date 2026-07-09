---
--- Created by Administrator.
--- DateTime: 2024/11/5 15:46:40
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGameHelperTower:LChildWnd
local UISubGameHelperTower = LxWndClass("UISubGameHelperTower", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGameHelperTower:UISubGameHelperTower()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGameHelperTower:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGameHelperTower:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGameHelperTower:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	self._isJapaness  =gLGameLanguage:IsJapanVersion()
	if  self._isEnus or self._isJapaness then
		self:InitTextSizeWithLanguage(CS.FindTrans(self.mSweepTitle,"UIText"),-6)
		LxUiHelper.SetSizeWithCurAnchor(self.mSweepTitle,0,380)

		self:InitTextSizeWithLanguage(CS.FindTrans(self.mAutoTitle,"UIText"),-6)
		LxUiHelper.SetSizeWithCurAnchor(self.mAutoTitle,0,380)
	end
	self:InitCommon()
	self:UpdateSetting()
end

function UISubGameHelperTower:SetAgainNumText()
	self:SetWndText(self.mAgainNum, self.againNum)
end

function UISubGameHelperTower:UpdateSetting()
	local setting = gModelGameHelper:GetSettingById(1071)
	self.freeToggle = setting.parameter1 == 1
	self:SetWndTabStatus(self.mFreeToggle, self.freeToggle and 0 or 1)

	local setting = gModelGameHelper:GetSettingById(1072)
	self.diamondNum = setting.parameter1
	self.diamondMax = tonumber(setting.functionData) or 0
	self:SetDiamondNumText()

	local setting = gModelGameHelper:GetSettingById(1081)
	self.changeToggle = setting.parameter1 == 1
	self:SetWndTabStatus(self.mChangeToggle, self.changeToggle and 0 or 1)
	self.againNum = setting.parameter2
	local num = tonumber(setting.functionData)
	self.againMax = num == -1 and 999 or num
	self:SetAgainNumText()

	self.typeStr = setting.moreInfo
	local strInfo = string.split(self.typeStr, "|")
	for _, v in ipairs(strInfo) do
		local id = tonumber(v)
		self.typeValue[id] = true
	end
	for i, v in ipairs(self.typeDataList) do
		local trans = self["mToggle" .. i]
		self:SetWndTabStatus(trans, self.typeValue[v.refId] and 0 or 1)
	end
end

function UISubGameHelperTower:ClickDiamondNum(b, num)
	if b then
		num = math.min(self.diamondMax, num)
	else
		num = self.diamondNum + num
		num = math.min(self.diamondMax, num)
		num = math.max(num, 0)
	end
	local setting = {
		refId = 1072,
		parameter1 = num
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end

function UISubGameHelperTower:ClickAgainNum(b, num)
	if b then
		num = math.min(self.againMax, num)
	else
		num = self.againNum + num
		num = math.min(self.againMax, num)
		num = math.max(num, 0)
	end
	local setting = {
		refId = 1081,
		parameter1 = self.changeToggle and 1 or 0,
		parameter2 = num,
		moreInfo = self.typeStr
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end

function UISubGameHelperTower:ClickTypeToggle(refId)
	local b = self.typeValue[refId]
	self.typeValue[refId] = not b
	local s = ""
	for id, v in pairs(self.typeValue) do
		if v then
			local temp = string.isempty(s) and id or "|" ..id
			s = s .. temp
		end
	end
	self.typeStr = s
	local setting = {
		refId = 1081,
		parameter1 = self.changeToggle and 1 or 0,
		parameter2 = self.againNum,
		moreInfo = self.typeStr
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end

function UISubGameHelperTower:InitCommon()
	------------------------------------------------------------------
	---member
	local cfg = GameTable.AssistantListRef
	self.diamondNum = 0
	self.id = self:GetWndArg("id")
	local cfg2 = GameTable.AssistantTabRef[self.id]
	self.typeValue = {}
	self.typeStr = ""

	------------------------------------------------------------------
	---text
	self:SetTextTile(self.mTitle, ccLngText(cfg2.name) .. ccClientText(24228))
	self:SetTextTile(self.mSweepTitle, ccLngText(cfg[107].name))
	self:SetTextTile(self.mAutoTitle, ccLngText(cfg[108].name))
	self:SetTextTile(self.mFreeToggle, ccClientText(24233))
	self:SetTextTile(self.mChangeToggle, ccClientText(24234))
	self:SetTextTile(CS.FindTrans(self.mDiamondObj, "CostObj"), ccClientText(24237))
	self:SetWndText(CS.FindTrans(self.mDiamondObj, "Text"), ccClientText(24238))
	self:SetWndText(CS.FindTrans(self.mAgainObj, "Text"), ccClientText(24239))

	------------------------------------------------------------------
	---click
	local t = {
		"Diamond",
		"Again"
	}
	for _, v in ipairs(t) do
		local transS = "m#a1#Obj"
		local funS = "Click#a1#Num"
		local obj = self[string.replace(transS, v)]
		local numObj = CS.FindTrans(obj, "NumObj")
		local sub = CS.FindTrans(numObj, "Sub")
		local add = CS.FindTrans(numObj, "Add")
		local num = CS.FindTrans(numObj, v .."Num")

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
				maxNum = 999999,
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
			refId = 1071,
			parameter1 = v,
		}
		gModelGameHelper:GameHelperSettingReq(2, setting)
	end)
	self:SetWndClick(self.mChangeToggle, function()
		local v = self.changeToggle and 0 or 1
		local setting = {
			refId = 1081,
			parameter1 = v,
			parameter2 = self.againNum,
			moreInfo = self.typeStr
		}
		gModelGameHelper:GameHelperSettingReq(2, setting)
	end)
	------------------------------------------------------------------
	---event
	self:WndEventRecv("GameHelperSettingResp", function()
		self:UpdateSetting()
	end)

	------------------------------------------------------------------
	---order
	self:InitType()
end

function UISubGameHelperTower:InitType()
	local cfg = GameTable.SnakeTowerPatternRef
	local list = {}
	for _, v in ipairs(cfg) do
		table.insert(list, v)
	end
	self.typeDataList = list
	for i, v in ipairs(list) do
		local trans = self["mToggle" .. i]
		self:SetTextTile(trans, ccLngText(v.name))

		self.typeValue[v.refId] = false

		self:SetWndClick(trans, function()
			self:ClickTypeToggle(v.refId)
		end)
	end
end

function UISubGameHelperTower:SetDiamondNumText()
	self:SetWndText(self.mDiamondNum, self.diamondNum)
	local cost = 0
	local guyNum = gModelTower:GetBuySweepNum()
	for i = 0, self.diamondNum do
		if i > 0 then
			local num = gModelTower:GetExpend(guyNum + i)
			cost = cost + num
		end
	end
	self:SetWndText(self.mDiamondCost, "x" .. cost)
end



------------------------------------------------------------------
return UISubGameHelperTower