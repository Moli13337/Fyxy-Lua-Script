---
--- Created by A.
--- DateTime: 2023/10/19 20:09:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIExreSettingQuality:LWnd
local UIExreSettingQuality = LxWndClass("UIExreSettingQuality", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIExreSettingQuality:UIExreSettingQuality()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIExreSettingQuality:OnWndClose()
	local func = self:GetWndArg("callBk")
	if func then func() end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIExreSettingQuality:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIExreSettingQuality:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitUIEvent()
	self:InitMessage()
	self:InitView()
	self:SetStaticContent()
end

function UIExreSettingQuality:InitUIEvent()
	self:SetWndClick(self.mMaskObj,function ()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mBtnCancel,function ()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mBtnOK,function ()
		self:OnClickOK()
	end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UIExreSettingQuality:OnClickOK()
	local list = {}
	for k,v in pairs(self._receiveQualityList) do
		if v == true then
			table.insert(list, k)
		end
	end
	gModelExplore:SettingTaskQualityReq(1,list)
end

--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UIExreSettingQuality:OnSettingTaskQualityResp(pb)
	local type = pb.type
	if type == 1 then
		GF.ShowMessage(ccClientText(12337))
		self:WndClose()
		return
	end

	local quality = pb.quality
	self._receiveQualityList = {}
	for k,v in ipairs(quality) do
		self._receiveQualityList[v] = true
	end

	self:RefreshView()
end

function UIExreSettingQuality:SetStaticContent()
	self:SetWndText(self.mTitleText, ccClientText(12336))
	self:SetWndText(self.mHelpText, ccClientText(12338))
	self:SetWndText(self.mAutoText, ccClientText(12341))
	self:InitTextLineWithLanguage(self.mHelpText, -30)
	self:SetWndButtonText(self.mBtnCancel,ccClientText(10101))
	self:SetWndButtonText(self.mBtnOK,ccClientText(12335))
end

function UIExreSettingQuality:InitView()
	self._qualityList = self:GetQualityList()
	self._receiveQualityList = gModelExplore:GetReceiveQualityList()
	self:RefreshView()
end

function UIExreSettingQuality:InitMessage()
	self:WndNetMsgRecv(LProtoIds.SettingTaskQualityResp,function (...)
		self:OnSettingTaskQualityResp(...)
	end)

end

function UIExreSettingQuality:GetQualityList()
	local key = "qualityName"
	local list = {}
	for i = 1, 6 do
		local qualityName = GameTable.InvestigateConfigRef[key..i]
		if qualityName then
			local data = {
				quality = i,
				name = ccLngText(qualityName)
			}
			table.insert(list,data )
		end
	end

	table.sort(list, function(a,b)
		return a.quality > b.quality
	end)

	return list
end

function UIExreSettingQuality:SelQuality(quality, isOpen, item)
	if not isOpen then
		local selectNum = 0
		for k,v in pairs(self._receiveQualityList) do
			if v == true then
				selectNum = selectNum + 1
			end
		end

		if selectNum <= 1 then
			self:SetWndToggleValue(item, true)
			return
		end
	end

	self._receiveQualityList[quality] = isOpen
	self:RefreshView()
end

function UIExreSettingQuality:RefreshView()
	--local isAuto = tonumber(LPlayerPrefs.exploreTaskAuto)
	--self:SetWndToggleValue(self.mAutoToggle, isAuto>0)
	--self:SetWndToggleDelegate(self.mAutoToggle,function ()
	--	local isActive = gModelNormalActivity:IsPrivilegeTypeActive(ModelActivity.PRIVILEGE_EXPLORE)
	--	if not isActive then
	--		GF.ShowMessage(12342)
	--		return
	--	end
	--	LPlayerPrefs.SetExploreTaskAuto(isAuto>0 and 0 or 1)
	--end)

	local qualityList = self._qualityList
	local uiList = self._uiList
	if uiList then
		uiList:RefreshList(qualityList)
	else
		uiList = self:GetUIScroll("viewList")
		self._uiList = uiList
		uiList:Create(self.mLangRoot,qualityList,function (...) self:ListItem(...) end)
	end

	if #qualityList > 6 then
		uiList:EnableScroll(true,false)
	end
end

function UIExreSettingQuality:ListItem(list , item, itemdata, itempos)
	local textTrans = self:FindWndTrans(item, "Text")
	local quality = itemdata.quality
	local nameStr = itemdata.name
	self:SetWndText(textTrans, nameStr)
	self:InitTextLineWithLanguage(textTrans, -30)

	local isSelect = self._receiveQualityList[quality]
	self:SetWndToggleValue(item, isSelect)
	self:SetWndToggleDelegate(item,function (value)
		self:SelQuality(quality, value, item)
	end)
end


------------------------------------------------------------------
return UIExreSettingQuality


