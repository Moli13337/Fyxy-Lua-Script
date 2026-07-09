---
--- Created by Administrator.
--- DateTime: 2023/10/23 10:52:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaLiHuiSow:LWnd
local UISagaLiHuiSow = LxWndClass("UISagaLiHuiSow", LWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
---@type LUIDrawingCtrl
local LUIDrawingCtrl = LxRequire("LApp.UI.Display.LUIDrawingCtrl")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaLiHuiSow:UISagaLiHuiSow()
	---@type table<string,LUIHeroObject>
	self._uiHeroLiHuiList = nil 		-- 立绘列表
	---@type LUIDrawingCtrl
	self._uiDrawingCtrl = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaLiHuiSow:OnWndClose()
	if self._uiDrawingCtrl then
		self._uiDrawingCtrl:Destroy()
		self._uiDrawingCtrl = nil
	end

	LUtil.ClearHashTable(self._uiHeroLiHuiList)
	self._uiHeroLiHuiList = nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaLiHuiSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaLiHuiSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
	if self._selSkinRefId then
		self:CreateLiHui()
	end
end

function UISagaLiHuiSow:CreateLiHui()
	local selSkinRefId = self._selSkinRefId
	local effectRef = gModelHero:GetShowEffectById(selSkinRefId)
	if not effectRef then return end
	if self._uiDrawingCtrl then
		self._uiDrawingCtrl:Destroy()
		self._uiDrawingCtrl = nil
	end

	local heroDrawing = effectRef.heroDrawing
	local uiHeroLiHuiList = self._uiHeroLiHuiList
	if not uiHeroLiHuiList then
		uiHeroLiHuiList = {}
		self._uiHeroLiHuiList = uiHeroLiHuiList
	end
	local newUILiHuiObj = uiHeroLiHuiList[heroDrawing]
	if not newUILiHuiObj then
		newUILiHuiObj = LUIHeroObject:New(self)
		newUILiHuiObj:Create(self.mLiHui,heroDrawing,heroDrawing)
		newUILiHuiObj:SetRectMatch(true)
		newUILiHuiObj:ShowHero(true)
		newUILiHuiObj:StartLoad()
	end
	local uiDrawCtrl = LUIDrawingCtrl:New()
	self._uiDrawingCtrl = uiDrawCtrl
	uiDrawCtrl:SetHeroObject(newUILiHuiObj)
	uiDrawCtrl:SetEffectInfo(self.mLiHuiEff, 0, 3, 100)
	uiDrawCtrl:InitHeroEffectInfo(selSkinRefId)
	uiDrawCtrl:StartPlay()
end

function UISagaLiHuiSow:InitData()
	self._selSkinRefId = self:GetWndArg("selSkinRefId")
	self._uiHeroLiHuiList = {}
end

function UISagaLiHuiSow:InitEvent()
	self:SetWndClick(self.mBg,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
end

------------------------------------------------------------------
return UISagaLiHuiSow


