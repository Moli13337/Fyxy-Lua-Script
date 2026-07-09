---
--- Created by Administrator.
--- DateTime: 2023/10/3 14:29:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenTsBag:LWnd
local UIEdenTsBag = LxWndClass("UIEdenTsBag", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenTsBag:UIEdenTsBag()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenTsBag:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenTsBag:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenTsBag:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:RefreshUI()

	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseTip,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIEdenTsBag:SetStaticContent()
	local str  =ccClientText(16746) --"宝物收集"
	self:SetWndText(self.mTitle,str)
	str =ccClientText(16747) -- "宝物仅在奇景探险中生效，重置后将消失"
	self:SetWndText(self.mIntro,str)
	self:InitTextLineWithLanguage(self.mIntro, -30)
	str =ccClientText(10103) -- "点击空白处关闭界面"
	self:SetWndText(self.mCloseTip,str)
end

function UIEdenTsBag:OnDrawTreasure(list,item,itemdata,itempos)
	local treasure = self:FindWndTrans(item,"TreasureIcon")

	local data =
	{
		refId = itemdata.refId,
		lv = itemdata.level,
		canLvUp = false,
	}

	TreasureIcon.SetIcon(treasure,data,self)
end

function UIEdenTsBag:RefreshUI()
	local dataList = gModelWonderland:GetSortedTreasureList()
	local cnt = #dataList
	local isEmpty = cnt ==0
	CS.ShowObject(self.mEmptRoot,isEmpty)
	CS.ShowObject(self.mItemList,not isEmpty)
	if isEmpty then
		local item = self.mEmptRoot
		local icon = self:FindWndTrans(item,"icon")
		local textBg = self:FindWndTrans(item,"textBg")
		local textBgUIText = self:FindWndTrans(textBg,"UIText")
		local emptyList = self:GetCommonEmptyList("_empty")
		local data =
		{
			refId= 7001,
			IntroTran = textBgUIText,
			IconTran= icon,
			TextBgTran= textBg,
			--IconTran,
			--GetBtn,
			--GetBtnText
			--ButtonRoot,
		}
		emptyList:RefreshUI(data)
		return
	end
	local list = self:GetUIScroll(self._listKey)
	list:Create(self.mItemList,dataList,function (...) self:OnDrawTreasure(...) end,UIItemList.WRAP,false)
	local uiList = list:GetList()
	uiList:EnableLoadAnimation(true, 0.02, 3)
	uiList:RefreshList()
end

function UIEdenTsBag:InitData()
	self._listKey = "_listKey"
end


------------------------------------------------------------------
return UIEdenTsBag


