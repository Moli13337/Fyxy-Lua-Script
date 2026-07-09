---
--- 冒险推图难度等级过场动画
--- Created by Ease.
--- DateTime: 2023/10/14 14:39:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMinFightOpenEffect:LWnd
local UIMinFightOpenEffect = LxWndClass("UIMinFightOpenEffect", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMinFightOpenEffect:UIMinFightOpenEffect()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMinFightOpenEffect:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMinFightOpenEffect:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMinFightOpenEffect:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	local exceptsWnd = {
		["UIMinFightOpenEffect"]= true,
		["UIMinFight"] = true,
		["UIGolbMlNew"] = true,
	}
	gLGameUI:CloseAllButExcept(exceptsWnd)
	self:PlayInterludeSpine()
end
function UIMinFightOpenEffect:PlayInterludeSpine()
	local interludeSpineKey = self.mView:GetInstanceID()
	local interludeSpineSpine = self:FindWndSpineByKey(interludeSpineKey)
	if (not interludeSpineSpine) then
		self:CreateWndSpine(self.mView, "Bianfuzhuanchang", interludeSpineKey, false, function(dpSpine)
			dpSpine:SetIgnoreTimeScale(true)
			dpSpine:PlayAnimation(0, "idle1", false, false)
			self.interludeSpinePlayState = 1
			dpSpine:SetAnimationCompleteFunc(function()
				if(self.interludeSpinePlayState == 1)then
					FireEvent(EventNames.MAINFIGHT_CHANGE_DIFF_LVL,{self._diffLvl})
					dpSpine:PlayAnimation(0, "idle2", false, false)
					self.interludeSpinePlayState = 2
					if(self._callBack)then
						self._callBack()
					end
				else
					self:WndClose()
				end
			end)
		end)
	else
		interludeSpineSpine:PlayAnimation(0, "idle1", false, false)
		self.interludeSpinePlayState = 1
	end
end
function UIMinFightOpenEffect:InitData()
	self._diffLvl = self:GetWndArg("diffLvl")
	self._callBack = self:GetWndArg("callBack")
end

------------------------------------------------------------------
return UIMinFightOpenEffect


