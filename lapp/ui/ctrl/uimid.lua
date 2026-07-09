---
--- Created by Administrator.
--- DateTime: 2024/4/2 10:35:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMid:LWnd
local UIMid = LxWndClass("UIMid", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMid:UIMid()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMid:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMid:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMid:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isJapaness  =gLGameLanguage:IsJapanVersion()

	if self._isJapaness then
		LxUiHelper.SetSizeWithCurAnchor(self.mTabScroll, 1, 90)
	end 
	self:InitData()
	self:InitText()
	self:InitTabList()
	self:UpdateRedPoint()
	self:UpatePetEquipPoint()
	self:InitEvent()
end

function UIMid:InitText()
	self:SetWndText(self:FindWndTrans(self.mCloseBtn, "TxtClose"), ccClientText(30205))
end

function UIMid:UpdateRedPoint()
	for i, v in ipairs(self.BotBtnData) do
		if v.redPointFunc then
			CS.ShowObject(self.BotBtnRedPoint[v.childWnd], v.redPointFunc())
		end
	end
end

function UIMid:InitData()
	self.BotBtnData = {
		[1] = {
			name = ccClientText(13203),
			childWnd = "UISubReCompound",
			onIcon = "butler_tab2",
			offIcon = "butler_tab2",
			redPointFunc = function()
				return gModelRune:GetCompoundRuneNum()
			end
		},
		[2] = {
			name = ccClientText(11317),
			childWnd = "UISubEqSynthesis",
			onIcon = "butler_tab1",
			offIcon = "butler_tab1",
			redPointFunc = function()
				return gModelEquip:GetEquipCompoundRedPoint()
			end
		},
		[3] = {
			name = ccClientText(43705),
			childWnd = "UISubPeEqComp",
			onIcon = "pet_btn_icon_8",
			offIcon = "pet_btn_icon_8",
			openId = 27003000
		},
		[4] = {
			name = ccClientText(10259),
			childWnd = "UISubItemCompound",
			onIcon = "butler_tab3",
			offIcon = "butler_tab3",
			redPointFunc = function()
				-- return gModelItem:GetItemCompoundRedPoint()
				return false
			end,
			openId = 27004000
		},
	}
	self.BotBtnDisObj = {}
	self.BotBtnRedPoint = {}
	self.CurSelBtn = 0
end

function UIMid:InitEvent()
	self:SetWndClick(self.mCloseBtn, function() self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.EquipCompoundResp, function()
		self:UpdateRedPoint()
	end)
	self:WndNetMsgRecv(LProtoIds.PetEquipCompoundResp, function()
		self:UpatePetEquipPoint()
	end)
	self:WndNetMsgRecv(LProtoIds.RuneCompoundResp,function(pb,ret)
		self:UpdateRedPoint()
	end)
	self:WndEventRecv(EventNames.On_Item_Change, function()
		self:UpdateRedPoint()
	end)
	self:WndEventRecv(EventNames.PET_EQUIP_CHANGE, function()
		self:UpatePetEquipPoint()
	end)
end

function UIMid:InitTabList()
	self.tabBtn = {}
	self.tabList = self:GetUIScroll("TabScroll")
	self.tabList:Create(self.mTabScroll, self.BotBtnData, function(...) self:OnDrawTab(...) end)

	local page = self:GetWndArg("page")
	if not page then
		local datas = self.BotBtnData
		local data
		local len = #datas
		for i = len,1,-1 do
			if datas[i] then
				data = datas[i]
				if data.redPointFunc and data.redPointFunc() then
					page = i
					break
				end
			end
		end
	end
	page = page or 2
	self:ClickBotBtn(page)
end

function UIMid:OnDrawTab(list, item, itemData, index)
	self:SetWndTabText(item, itemData.name)
	local isLock = false
	if itemData.openId and not gModelFunctionOpen:CheckIsOpened(itemData.openId,false) then
		local cfg = GameTable.FeatureOpenRef[itemData.openId]
		if cfg.show<=0 then
			CS.ShowObject(item,false)
			return
		end
		isLock = true
	end
	self:SetWndTabStatus(item, isLock and 2 or 1)
	if itemData.onIcon then
		local On = self:FindWndTrans(item,"On")
		self:SetWndEasyImage(On,itemData.onIcon)
	end
	if itemData.offIcon then
		local Off = self:FindWndTrans(item,"Off")
		local Gray = self:FindWndTrans(item,"Gray")
		self:SetWndEasyImage(Off,itemData.offIcon)
		self:SetWndEasyImage(Gray,itemData.offIcon)
	end
	self.tabBtn[index] = item
	self.BotBtnRedPoint[itemData.childWnd] = self:FindWndTrans(item, "redPoint")
	self:SetWndClick(item, function (...) self:ClickBotBtn(index) end)
end

function UIMid:ClickBotBtn(index)
	if self.CurSelBtn == index then
		return
	end
	local itemData = self.BotBtnData[index]
	if itemData.openId and not gModelFunctionOpen:CheckIsOpened(itemData.openId,true) then return end
	local oldIndex = self.CurSelBtn
	self.CurSelBtn = index
	self:SetWndTabStatus(self.tabBtn[oldIndex], 1)
	self:SetWndTabStatus(self.tabBtn[index], 0)
	if itemData.childWnd then
		self:CreateChildWnd(self.mChildRoot, itemData.childWnd)
	end
end

function UIMid:UpatePetEquipPoint()
	local petRed = gModelPet:GetEquipCompoundRedPointByPart()
	local redTran = self.BotBtnRedPoint["UISubPeEqComp"]
	if redTran then CS.ShowObject(redTran,petRed) end
end

------------------------------------------------------------------
return UIMid