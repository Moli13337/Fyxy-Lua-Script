---
--- Created by Administrator.
--- DateTime: 2024/6/3 10:08:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISdBigAward:LWnd
local UISdBigAward = LxWndClass("UISdBigAward", LWnd)
------------------------------------------------------------------

---- 大奖
UISdBigAward.TYPE_REWARD_BIG = 1


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISdBigAward:UISdBigAward()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISdBigAward:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISdBigAward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISdBigAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()

end

function UISdBigAward:InitMsg()
	self:WndEventRecv(EventNames.CLOSE_HALIDOM_BIGREWARD,function (...) self:OnEventCloseHalidomBigReward() end)
	-- self:WndNetMsgRecv(LProtoIds.xxxxx,function(...) self:OnMsgXXXXX(...) end)
end

function UISdBigAward:OnClickXXXBtnFunc()
end

function UISdBigAward:RefreshHalidomBigReward()
	self:CreateWndEffect_Ex({
		trans = self.mHalidomBigEffectRoot,
		effName = ModelHalidom.CALL_DAJIANG,
		effKey = ModelHalidom.CALL_DAJIANG,
		upSortOrder = 6,
		endFunc = function()
			CS.ShowObject(self.mHalidomBigEffectRoot,true)
		end
	})
end

function UISdBigAward:InitText()
end

function UISdBigAward:InitEvent()
	--- 返回按钮必备
	-- self:SetWndClick(self.mReturnBtn,function() self:CloseWnd() end,LSoundConst.CLICK_CLOSE_COMMON)

	-- self:SetWndClick(self.mXXXBtn,function() self:OnClickXXXBtnFunc() end)
end

function UISdBigAward:OnMsgXXXXX()
end

function UISdBigAward:OnEventCloseHalidomBigReward()
	self:WndClose()
end

function UISdBigAward:InitData()
	self._rewardType = self:GetWndArg("rewardType")
end

function UISdBigAward:RefreshView()
	if self._rewardType == UISdBigAward.TYPE_REWARD_BIG then
		self:RefreshHalidomBigReward()
	end
end

------------------------------------------------------------------
return UISdBigAward