---
--- Created by Administrator.
--- DateTime: 2024/5/21 19:55:01
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISd:LWnd
local UISd = LxWndClass("UISd", LWnd)
------------------------------------------------------------------


local UIBtnTabList = LXImport('LApp.UI.Common.UIBtnTabList')

--- 图鉴
UISd.TYPE_TAB_BOOK = 1


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISd:UISd()
	---@type UIBtnTabList
	self._uiBtnTabList = nil

	self._page = UISd.TYPE_TAB_BOOK
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISd:OnWndClose()
	if self._uiBtnTabList then
		self._uiBtnTabList:Destroy()
		self._uiBtnTabList = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISd:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISd:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitCommonData()
	self:InitCallBtnTransInfo()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:OnWndRefresh()
end

function UISd:ChangePage(page)
	if self._page == page then return end
	self._page = page
	self:RefreshShow()
end

function UISd:InitCommonData()
	self._btnTabList = {
		{
			btnType = UISd.TYPE_TAB_BOOK,
			btnName = ccClientText(41502),
			functionId = ModelFunctionOpen.HalidomBook,
			offIcon = "halidom_btn_icon_1",
			onIcon = "halidom_btn_icon_1",
			isNativeSize = true,
			clickFunc = function(itemdata)
				self:ChangePage(itemdata.btnType)
			end,
			wndFunc = function()
				self:CreateChildWnd(self.mChildRoot,"UISubSdBook")
			end,
		}
	}
	self._btnFuncList = {}
	for i,v in ipairs(self._btnTabList) do
		self._btnFuncList[v.btnType] = v.wndFunc
	end
end

function UISd:OnEventXXXXX()
end

function UISd:RefreshShow()
	self:CloseAllChild()
	self:ShowContent()
end

function UISd:InitEvent()
	--- 返回按钮必备
	 self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UISd:InitText()
	self:SetWndText(self.mTxtClose,ccClientText(30205))
end

function UISd:InitData()
end

function UISd:InitCallBtnTransInfo()
	---@type UIBtnTabList
	self._uiBtnTabList = UIBtnTabList:New()
	self._uiBtnTabList:SetData(self,self.mTabScroll,self._btnTabList,self._page,true)
end

function UISd:OnMsgXXXXX()
end


function UISd:OnWndRefresh()
	self:InitData()
	self:RefreshShow()
end

function UISd:InitMsg()
	-- self:WndEventRecv(EventNames.xxxxx,function (...) self:OnEventXXXXX() end)
	-- self:WndNetMsgRecv(LProtoIds.xxxxx,function(...) self:OnMsgXXXXX(...) end)
end



function UISd:RefreshBottomBtnShow()
	self:InitData()
end

function UISd:RefreshView()
end

function UISd:ShowContent()
	local page = self._page
	if not page then
		page = UISd.TYPE_TAB_BOOK
	end
	print("page = " .. page)
	self:RefreshBottomBtnShow()
	local btnFunc = self._btnFuncList[page]
	if btnFunc then
		btnFunc()
	end
end



------------------------------------------------------------------
return UISd