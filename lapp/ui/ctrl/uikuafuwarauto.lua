---
--- Created by Administrator.
--- DateTime: 2024/7/1 20:46:42
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuWarAuto:LWnd
local UIKuafuWarAuto = LxWndClass("UIKuafuWarAuto", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuWarAuto:UIKuafuWarAuto()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuWarAuto:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuWarAuto:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuWarAuto:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	if not gModelFunctionOpen:CheckIsOpened(13900000, true) then
		return
	end

	local refId = self:GetWndArg("refId")
	self:WndEventRecv("CrossWarTempleStateResp", function()
		if gModelCrossWar:GetState() == 0 then
			GF.ShowMessage(ccClientText(43830))
			self:WndClose()
			return
		end
		gModelCrossWar:CrossWarTempleInfoReq()
	end)
	self:WndEventRecv("CrossWarTempleInfoResp", function()
		if not table.isempty(gModelCrossWar:GetSelfInsideInfo()) then
			GF.ShowMessage(ccClientText(43850))
			self:WndClose()
			return
		end
		local innerTempleInfo = gModelCrossWar:GetInnerTempleInfo()
		if not table.isempty(innerTempleInfo) and innerTempleInfo.innerTempleRank == tonumber(refId) then
			GF.ShowMessage(ccClientText(43849))
			self:WndClose()
			return
		end
		gModelCrossWar:CrossWarTempleRetinueApplyReq(4, tonumber(refId))
		self:WndClose()
	end)
	gModelCrossWar:CrossWarTempleStateReq()
end



------------------------------------------------------------------
return UIKuafuWarAuto