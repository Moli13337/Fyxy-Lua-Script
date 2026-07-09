---
--- Created by Administrator.
--- DateTime: 2023/10/21 21:19:22
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWonderBfTip:LWnd
local UIWonderBfTip = LxWndClass("UIWonderBfTip", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWonderBfTip:UIWonderBfTip()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWonderBfTip:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWonderBfTip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWonderBfTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:RefreshUI()

	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)
end

function UIWonderBfTip:OnDrawTrea(list,item,itemdata,itempos)
	local level = self:FindWndTrans(item,"level")
	local intro = self:FindWndTrans(item,"intro")

	local isCur = self._refId == itemdata.refId


	local lvStr = string.replace(ccClientText(10011),itemdata.lv)
	if isCur then
		lvStr = LUtil.FormatColorStr(lvStr,'lightGreen')
	end
	self:SetWndText(level,lvStr)
	local desc = ccLngText(itemdata.desc)
	if isCur then
		desc = LUtil.FormatColorStr(desc,'lightGreen')
	end
	self:SetWndText(intro,desc)

end

function UIWonderBfTip:RefreshUI()
	local refId = self:GetWndArg("refId")
	self._refId = refId

	local curRef = gModelWonderland:GetTreasureConfig(refId)
	if not curRef then
		return
	end
	local name = ccLngText(curRef.name)
	self:SetWndText(self.mTitle,name)
	local dataList = gModelWonderland:GetTreasureGroup(refId)

	local uiList = self:GetUIScroll("itemList")
	uiList:Create(self.mItemList,dataList,function (...) self:OnDrawTrea(...) end)
	uiList:EnableScroll(true,false)
end

------------------------------------------------------------------
return UIWonderBfTip


