---
--- Created by BY.
--- DateTime: 2023/10/14 14:55:57
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMicFang:LWnd
local UIMicFang = LxWndClass("UIMicFang", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMicFang:UIMicFang()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMicFang:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMicFang:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMicFang:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UIMicFang:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId = 144})
end

function UIMicFang:InitEntry(item,itemdata, itempos)
	if not item or not itemdata then return end
	CS.ShowObject(item,true)
	local icon = self:FindWndTrans(item,"Icon")
	local mask = self:FindWndTrans(item,"Icon/Mask")

	local name = itemdata.name
	local jumpId = itemdata.jumpId
	self:SetWndEasyImage(icon,name)
	local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId, false)
	CS.ShowObject(mask,not isOpen)
	self:SetWndClick(item,function ()

		-- if itempos == 5 and gLGameLanguage:IsJapanRegion() then
		-- 	gModelRedPoint:SetRedPointClicked(ModelRedPoint.HOROSCOPE_ACT)
		-- end

		gModelFunctionOpen:Jump(jumpId)
	end)
end

function UIMicFang:InitCommand()
	self:SetWndText(self.mCloseText,ccClientText(30205))
	local list = {}
	for i, v in pairs(GameTable.FunctionOpenMolingRef) do
		table.insert(list,v)
	end
	table.sort(list,function (a,b)
		return a.refId < b.refId
	end)
	if #list > 0 then
		for i, v in ipairs(list) do
			local item = self:FindWndTrans(self.mEntryMag,"Entry"..v.refId)
			self:InitEntry(item,v, i)
		end
		CS.ShowObject(self.mEntryMag,true)
	end
	self:CreateWndSpine(self.mSpine,"Molingfang","UIMicFang",false,function(dpSpine)
		local dpTrans =dpSpine:GetDisplayTrans()
		dpTrans.anchorMin = Vector2.New(0.5,0.5)
		dpTrans.anchorMax = Vector2.New(0.5,0.5)
	end)
end

function UIMicFang:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnHelp,function (...) self:OnClickHelp() end)
end
------------------------------------------------------------------
return UIMicFang


