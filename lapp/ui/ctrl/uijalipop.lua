---
--- Created by Administrator.
--- DateTime: 2023/10/4 17:28:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIJaLiPop:LWnd
local UIJaLiPop = LxWndClass("UIJaLiPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIJaLiPop:UIJaLiPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIJaLiPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIJaLiPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIJaLiPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
	self:SetContent()
end

function UIJaLiPop:OnClickOKBtn()
	self:SetJapanBuyLimitAgeIndex()
	self:WndClose()
end

function UIJaLiPop:SetJapanBuyLimitAgeIndex()
	local selectIndex = self._selectIndex
	if not selectIndex or selectIndex == 0 then return end

	LPlayerPrefs.SetJapanBuyLimitAgeIndex(selectIndex)
end

function UIJaLiPop:OnDrawSelectItem(list,item,itemdata,itempos)
	local NameText = self:FindWndTrans(item,"NameText")
	local DescText = self:FindWndTrans(item,"DescText")

	self:SetWndText(NameText, itemdata.title)

	self:SetWndText(DescText, itemdata.desc)

	local isSelect = self._selectIndex == itempos
	self:SetWndToggleValue(item, isSelect)
	self:SetWndToggleDelegate(item,function (value)
		self:SelSelectToggle(value, itempos, item)
	end)
end

function UIJaLiPop:InitData()
	self._selectDataList = {
		{
			title = ccClientText(36602),
			desc = ccClientText(36603),
		},
		{
			title = ccClientText(36604),
			desc = ccClientText(36605),
		},
		{
			title = ccClientText(36606),
			desc = ccClientText(36607),
		},
	}

	self._selectIndex = tonumber(LPlayerPrefs.japanBuyLimitAgeIndex)
end

function UIJaLiPop:SelSelectToggle(isOpen,itempos,  item)
	if not isOpen then
		if self._selectIndex == itempos then
			self:SetWndToggleValue(item, true)
		end
		return
	end

	if self._selectIndex == itempos then return end

	self._selectIndex = itempos
	self:RefreshSelectList()
end

function UIJaLiPop:InitEvent()
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mBgImage,function() self:WndClose() end)
	self:SetWndClick(self.mOKBtn,function() self:OnClickOKBtn() end)
end

function UIJaLiPop:RefreshSelectList()
	local dataList = self._selectDataList

	local selectScrollList = self._selectScrollList
	if(selectScrollList)then
		selectScrollList:RefreshList(dataList)
	else
		selectScrollList = self:GetUIScroll("_skillScroll")
		selectScrollList:Create(self.mSelectScroll,dataList,function (...) self:OnDrawSelectItem(...) end)
		selectScrollList:EnableScroll(true)
	end
end

function UIJaLiPop:SetContent()
	self:RefreshSelectList()

	self:SetWndText(self.mTitleText, ccClientText(36600))
	self:SetWndText(self.mDesText, ccClientText(36601))
	self:SetWndButtonText(self.mOKBtn, ccClientText(10102))
end


------------------------------------------------------------------
return UIJaLiPop


