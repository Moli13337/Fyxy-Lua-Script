---
--- Created by Administrator.
--- DateTime: 2023/10/17 21:23:16
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPrigeInfo:LWnd
local UIPrigeInfo = LxWndClass("UIPrigeInfo", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPrigeInfo:UIPrigeInfo()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPrigeInfo:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPrigeInfo:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPrigeInfo:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	--self:RefreshUI()
end


--function UIPrigeInfo:RefreshUI()
--
--	local items =
--	{
--		[1] = self.mItem_1,
--		[2] = self.mItem_2
--	}
--
--	for k=1,2 do
--		local root =items[k]
--		local content = self:FindWndTrans(root,"content")
--		local gotoTran = self:FindWndTrans(root,"goto")
--		local str = gModelExplore:GetPrivilegeConfig(k)
--		local isActive = gModelExplore:IsInPrivilege(k)
--		if isActive then
--			str = str..LUtil.FormatColorStr("(已激活)","green")
--		else
--			str = str..LUtil.FormatColorStr("(未激活)","red")
--		end
--		self:SetWndText(content,str)
--
--		CS.ShowObject(gotoTran,not isActive)
--		if not isActive then
--			local uiHyper = UIHyperText:New()
--			uiHyper:Create(gotoTran)
--			str = "前往激活"
--			local str = uiHyper:AddHyper(str,{func = function (type) self:OnClickPrivi(type)  end,para = k} )
--			str = LUtil.FormatColorStr(str,"green")
--			self:SetWndText(gotoTran,str)
--		end
--
--
--	end
--
--	self:SetWndClick(self.mMask,function () self:WndClose() end)
--end
--
--function UIPrigeInfo:OnClickPrivi(type)
--	local priType = type==1 and 2 or 1
--	local wndId = 51201
--	if priType == 2 then
--		wndId = 51202
--	end
--	local func = function() gModelExplore:ExplorePrivilegeBuyReq(priType)  end
--	local openFunc = function() GF.OpenWnd("UIOrdinTip",{refId = wndId,func = func}) end
--	gModelGeneral:ShowUIOrdinTip(wndId,func,openFunc)
--	self:WndClose()
--end


------------------------------------------------------------------
return UIPrigeInfo


