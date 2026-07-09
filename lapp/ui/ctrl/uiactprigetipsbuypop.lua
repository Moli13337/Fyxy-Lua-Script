---
--- Created by BY.
--- DateTime: 2023/10/19 11:43:04
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActPrigeTipsBuyPop:LWnd
local UIActPrigeTipsBuyPop = LxWndClass("UIActPrigeTipsBuyPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActPrigeTipsBuyPop:UIActPrigeTipsBuyPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActPrigeTipsBuyPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActPrigeTipsBuyPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActPrigeTipsBuyPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UIActPrigeTipsBuyPop:OnClickJump()
	local jump = self._privilegeCardJump
	gModelFunctionOpen:Jump(jump,self:GetWndName())
end

function UIActPrigeTipsBuyPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(27628))
	self:SetWndButtonText(self.mBtnCancel,ccClientText(27620))
	self:SetWndButtonText(self.mBtnJump,ccClientText(27630))

	local sid = self:GetWndArg("sid")

	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config

	self._privilegeCardJump = data.privilegeCardJump						--限时特权卡跳转id
	local privilegeCardIcon = data.privilegeCardIcon						--限时特权卡图标
	local candyCardbuyTimeTxt = data.candyCardbuyTimeTxt					--特权加的次数

	if LxUiHelper.IsImgPathValid(privilegeCardIcon) then
		self:SetWndEasyImage(self.mCardIcon,privilegeCardIcon,nil,true)
	end
	if not string.isempty(candyCardbuyTimeTxt) then
		self:SetWndText(self.mCardText,string.replace(ccClientText(27629),candyCardbuyTimeTxt))
	end
end

function UIActPrigeTipsBuyPop:InitEvent()
	self:SetWndClick(self.mBg,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
	self:SetWndClick(self.mBtnCancel,function () self:WndClose() end)
	self:SetWndClick(self.mBtnJump,function () self:OnClickJump() end)
end

function UIActPrigeTipsBuyPop:OnTryTcpReconnect()
	self:WndClose()
end
------------------------------------------------------------------
return UIActPrigeTipsBuyPop


