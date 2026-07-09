---
--- Created by Administrator.
--- DateTime: 2024/11/5 15:43:44
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGameHelperGuild:LChildWnd
local UISubGameHelperGuild = LxWndClass("UISubGameHelperGuild", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGameHelperGuild:UISubGameHelperGuild()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGameHelperGuild:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGameHelperGuild:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGameHelperGuild:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:UpdateSetting()
end

function UISubGameHelperGuild:SetDonateGoldNumText()
	self:SetWndText(self.mDonateGoldNum, self.donateGoldNum)
	local cost = 0
	if self.donateGoldNum > 0 then
		for i = 1, self.donateGoldNum do
			local temp = self.donateGoldCost[i] ~= nil and self.donateGoldCost[i] or self.donateGoldCost[#self.donateGoldCost]
			cost = cost + temp
		end
	end
	self:SetWndText(self.mDonateGoldCost, "x" .. cost)
end

function UISubGameHelperGuild:ClickBossNum(b, num)
	if b then
		num = math.min(self.bossMax, num)
	else
		num = self.bossNum + num
		num = math.min(self.bossMax, num)
		num = math.max(num, 0)
	end
	local setting = {
		refId = 1112,
		parameter1 = num
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end

function UISubGameHelperGuild:SetBossNumText()
	self:SetWndText(self.mBossNum, self.bossNum)
	local cost = 0
	if self.bossNum > 0 then
		for i = 1, self.bossNum do
			local temp = self.bossCost[i] ~= nil and self.bossCost[i] or self.bossCost[#self.bossCost]
			cost = cost + temp
		end
	end
	self:SetWndText(self.mBossCost, "x" .. cost)
end

function UISubGameHelperGuild:InitCommon()
	------------------------------------------------------------------
	---member
	self.id = self:GetWndArg("id")
	local cfg = GameTable.AssistantTabRef[self.id]

	self.donateGoldCost = {}
	self.donateUpCost = {}
	self.donateDiamondCost = {}
	local t = {
		self.donateGoldCost,
		self.donateUpCost,
		self.donateDiamondCost,
	}
	for i, v in ipairs(t) do
		local sArr = string.split(GameTable.ClanDonateRef[i].price, "|")
		for _, v2 in ipairs(sArr) do
			local info = string.split(v2, "=")
			table.insert(v, tonumber(info[3]))
		end
	end

	self.bossCost = {}
	local sArr = string.split(gModelGuildBoss:GetNewGuildDungeonConfigRefByKey("GuildBuyTimeNeed"), "|")
	for _, v in ipairs(sArr) do
		local info = string.split(v, "=")
		table.insert(self.bossCost, tonumber(info[3]))
	end

	------------------------------------------------------------------
	---text
	self:SetTextTile(self.mTitle, ccLngText(cfg.name) .. ccClientText(24228))
	self:SetTextTile(self.mDonateTitle, ccClientText(24257))
	self:SetTextTile(self.mDonateGoldObj, ccClientText(24258))
	self:SetTextTile(self.mDonateUpObj, ccClientText(24259))
	self:SetTextTile(self.mDonateDiamondObj, ccClientText(24260))
	self:SetTextTile(self.mBossTitle, ccClientText(24261))
	self:SetTextTile(self.mBossFreeToggle, ccClientText(24262))
	self:SetTextTile(self.mBossObj, ccClientText(24263))
	self:SetTextTile(CS.FindTrans(self.mDonateGoldObj, "CostObj"), ccClientText(24232))
    self:SetTextTile(CS.FindTrans(self.mDonateUpObj, "CostObj"), ccClientText(24232))
	self:SetTextTile(CS.FindTrans(self.mDonateDiamondObj, "CostObj"), ccClientText(24232))
	self:SetTextTile(CS.FindTrans(self.mBossObj, "CostObj"), ccClientText(24232))

	------------------------------------------------------------------
	---click
	local t = {
		"DonateGold",
		"DonateUp",
		"DonateDiamond",
		"Boss",
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

	self:SetWndClick(self.mBossFreeToggle, function()
		local v = self.bossFreeToggle and 0 or 1
		local setting = {
			refId = 1111,
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

function UISubGameHelperGuild:UpdateSetting()
	local donateGoldSetting = gModelGameHelper:GetSettingById(1101)
	self.donateGoldNum = donateGoldSetting.parameter1
	self.donateGoldMax = tonumber(donateGoldSetting.functionData)
	self:SetDonateGoldNumText()

	local donateUpSetting = gModelGameHelper:GetSettingById(1102)
	self.donateUpdNum = donateUpSetting.parameter1
	self.donateUpMax = tonumber(donateUpSetting.functionData)
	self:SetDonateUpNumText()

	local donateDiamondSetting = gModelGameHelper:GetSettingById(1103)
	self.donateDiamondNum = donateDiamondSetting.parameter1
	self.donateDiamondMax = tonumber(donateDiamondSetting.functionData)
	self:SetDonateDiamondNumText()

	local bossFreeSetting = gModelGameHelper:GetSettingById(1111)
	self.bossFreeToggle = bossFreeSetting.parameter1 == 1
	self:SetWndTabStatus(self.mBossFreeToggle, self.bossFreeToggle and 0 or 1)

	local bossSetting = gModelGameHelper:GetSettingById(1112)
	self.bossNum = bossSetting.parameter1
	self.bossMax = tonumber(bossSetting.functionData)
	self:SetBossNumText()
end

function UISubGameHelperGuild:SetDonateDiamondNumText()
	self:SetWndText(self.mDonateDiamondNum, self.donateDiamondNum)
	local cost = 0
	if self.donateDiamondNum > 0 then
		for i = 1, self.donateDiamondNum do
			local temp = self.donateDiamondCost[i] ~= nil and self.donateDiamondCost[i] or self.donateDiamondCost[#self.donateDiamondCost]
			cost = cost + temp
		end
	end
	self:SetWndText(self.mDonateDiamondCost, "x" .. cost)
end

function UISubGameHelperGuild:ClickDonateGoldNum(b, num)
	if b then
		num = math.min(self.donateGoldMax, num)
	else
		num = self.donateGoldNum + num
		num = math.min(self.donateGoldMax, num)
		num = math.max(num, 0)
	end
	local setting = {
		refId = 1101,
		parameter1 = num
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end

function UISubGameHelperGuild:ClickDonateDiamondNum(b, num)
	if b then
		num = math.min(self.donateDiamondMax, num)
	else
		num = self.donateDiamondNum + num
		num = math.min(self.donateDiamondMax, num)
		num = math.max(num, 0)
	end
	local setting = {
		refId = 1103,
		parameter1 = num
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end

function UISubGameHelperGuild:SetDonateUpNumText()
	self:SetWndText(self.mDonateUpNum, self.donateUpdNum)
	local cost = 0
	if self.donateUpdNum > 0 then
		for i = 1, self.donateUpdNum do
			local temp = self.donateUpCost[i] ~= nil and self.donateUpCost[i] or self.donateUpCost[#self.donateUpCost]
			cost = cost + temp
		end
	end
	self:SetWndText(self.mDonateUpCost, "x" .. cost)
end

function UISubGameHelperGuild:ClickDonateUpNum(b, num)
	if b then
		num = math.min(self.donateUpMax, num)
	else
		num = self.donateUpdNum + num
		num = math.min(self.donateUpMax, num)
		num = math.max(num, 0)
	end
	local setting = {
		refId = 1102,
		parameter1 = num
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)
end



------------------------------------------------------------------
return UISubGameHelperGuild