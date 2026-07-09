---
--- Created by BY.
--- DateTime: 2023/10/22 14:47:31
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBoxff:LWnd
local UIBoxff = LxWndClass("UIBoxff", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBoxff:UIBoxff()
	self._timeOpenedKey = "WndBoxOpenedEff"
	self._timeKey = "UIBoxff"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBoxff:OnWndClose()
	local _func = self._func
	if _func then
		_func()
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBoxff:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBoxff:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommand()
end

function UIBoxff:SetTime()
	self:WndClose()
end

function UIBoxff:OnItem()
	local award = self._award
	local icon = gModelGeneral:GetCommonItemImgRef(award)
	self:SetWndEasyImage(self.mIcon,icon)
	CS.ShowObject(self.mIcon,true)
end

function UIBoxff:OnTimer(key)
	if(self._timeKey == key)then
		self:SetTime()
	elseif(self._timeOpenedKey == key)then
		self:OnItem()
	end
end

function UIBoxff:InitCommand()
	self._func = self:GetWndArg("func")
	local eff  = self:GetWndArg("eff") or "fx_manghedakai"
	local award = self:GetWndArg("item")

	if award then
		local itype = award.itype
		if itype == LItemTypeConst.TYPE_RUNE then
			local setRefId = nil
			local serverData = gModelRune:GetServerDataById(award.itemId)
			if serverData then
				setRefId = serverData.refId
			end

			self._award = {
				itemId = setRefId,
				itype = award.itype,
				count = award.count,
			}
		else
			self._award = award
		end

		self:TimerStop(self._timeOpenedKey)
		self:TimerStart(self._timeOpenedKey,0.5,false,1)
	end
	self:CreateWndEffect(self.mEff,eff,"boxEffKey",100,false,false)

	self:TimerStop(self._timeKey)
	self:TimerStart(self._timeKey,1.5,false,1)
end
------------------------------------------------------------------
return UIBoxff


