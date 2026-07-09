---
--- Created by BY.
--- DateTime: 2023/10/8 10:17:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UICareColleSulation:LWnd
local UICareColleSulation = LxWndClass("UICareColleSulation", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UICareColleSulation:UICareColleSulation()
	self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UICareColleSulation:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UICareColleSulation:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UICareColleSulation:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UICareColleSulation:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(20907))
	self:SetWndText(self.mReportText,ccClientText(20916))
	self:SetWndText(self.mRankText,ccClientText(20917))
	self:RefreshData()
end

function UICareColleSulation:OnClickRank()
	GF.OpenWndBottom("UIRkPop",{refId = ModelRank.RANK_1600})
end

function UICareColleSulation:ListItem(list,item,itemdata,itempos)
	local bg = CS.FindTrans(item,"Image")
	local nameText = CS.FindTrans(item,"NameText")
	local recordBg = CS.FindTrans(item,"RecordBg")
	local recordText = CS.FindTrans(item,"RecordBg/RecordText")
	local desText = CS.FindTrans(item,"Image/DesText")

	self:SetWndEasyImage(bg,itemdata.tabIcon)
	self:SetWndText(nameText,ccLngText(itemdata.name))
	self:SetWndText(desText,ccLngText(itemdata.desc))
	local isShowRecord = itemdata.monster ~= 0
	CS.ShowObject(recordBg,isShowRecord)
	if isShowRecord then
		local list = gModelCareSchool:GetSimulationHurtList()
		local recordNum = list[itemdata.refId] or 0
		self:SetWndText(recordText,string.replace(ccClientText(20906),recordNum))
	end
	self:SetWndClick(item,function ()
		self:OnClickCell(itemdata)
	end)
end

function UICareColleSulation:OnClickReport()
	GF.OpenWnd("UICareColleReportPop")
end

function UICareColleSulation:InitEvent()
	self:SetWndClick(self.mBtnClose,function () self:OnClickClose() end)
	self:SetWndClick(self.mBtnReport,function () self:OnClickReport() end)
	self:SetWndClick(self.mBtnRank,function () self:OnClickRank() end)

	if PRODUCT_G_VER == 1 then --ios屏蔽
		CS.ShowObject(self.mBtnRank ,false)
		self.mBtnReport.transform.localPosition = self.mBtnRank.transform.localPosition
	end
end

function UICareColleSulation:InitMessage()

end

function UICareColleSulation:RefreshData()
	local list = gModelCareSchool:GetCollegeSimulationRefList()
	if not self._uiList then
		self._uiList = self:GetUIScroll("cell")
		self._uiList:Create(self.mCellSuper,list,function (...) self:ListItem(...) end, UIItemList.SUPER)
		self._uiList:EnableScroll(true,false)
	end
	self._uiList:MoveToPos()
end

function UICareColleSulation:OnClickClose()
	GF.OpenWndBottom("UICareColleWin")
	self:WndClose()
end

function UICareColleSulation:OnClickCell(ref)
	local refId = ref.refId
	gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_TACTICAL_SIMULATION,{targetId = refId})
end
------------------------------------------------------------------
return UICareColleSulation


