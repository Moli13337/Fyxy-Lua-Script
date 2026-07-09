---
--- Created by Administrator.
--- DateTime: 2023/10/8 11:29:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIInpite:LWnd
local UIInpite = LxWndClass("UIInpite", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIInpite:UIInpite()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIInpite:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIInpite:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIInpite:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndButtonText(self.mInputBtn,ccClientText(20848))
	self:InitEvent()
	self:InitMsg()
	self:InitData()
end

function UIInpite:SendMsg()
	local str = self.mInput.text
	if string.isempty(str) then
		GF.ShowMessage(ccClientText(20851))
	else
		gModelActivity:OnActivityInvitationReq(ModelActivity.SET_PLAYER_INFO,self._sid,str)
	end
end

function UIInpite:InitEvent()
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mInputBtn,function()
		self:SendMsg()
	end)

	self.mInput.onValueChanged:AddListener(function (str)
		self:ClickInputFunc()
	end)

	--激活聊天框不选中所有内容
	self.mInput.onFocusSelectAll = false
end

function UIInpite:InitData()
	self._sid = self:GetWndArg("sid")

	self._func = self:GetWndArg("func")
end

function UIInpite:ClickInputFunc()
end

function UIInpite:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ActivityInvitationResp,function (pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		local opera = pb.opera
		if opera == ModelActivity.SET_PLAYER_INFO then
			if self._func then self._func() end
			GF.ShowMessage(ccClientText(20849))
			self:WndClose()
		end
	end)
end



------------------------------------------------------------------
return UIInpite


