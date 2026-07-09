---
--- Created by admin-pc.
--- DateTime: 2025/2/12 14:20:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHelpListJa:LWnd
local UIHelpListJa = LxWndClass("UIHelpListJa", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHelpListJa:UIHelpListJa()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHelpListJa:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHelpListJa:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHelpListJa:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self:InitData()

	self:InitEvent()


	self:InitStaticContent()

	self:InitView()
end


-- 设置文本内容
function UIHelpListJa:SetText()
	if not self._refID then return end

	local data
	for k,v in ipairs(self._refDataList) do
		if v.refId == self._refID then
			data = v
		end
	end

	local text = data.text
	local titleStr = self._title
	if string.isempty(titleStr) then
		titleStr = data.title
	end
	self:SetWndText(self.mTitleText,titleStr)
	self:SetWndText(self.mContentText,text)

	local height = self.mContentText_1.preferredHeight
	local size = self.mContentText.sizeDelta
	size.y = height + 300
	self.mContentText.sizeDelta = size
	self.mScroll_1.normalizedPosition = Vector2(0,1)
end

function UIHelpListJa:ListItem(list,item, itemdata, itempos)
	local btnTab = CS.FindTrans(item,"BtnTab3")
	local refId = itemdata.refId
	self._tabList[refId] = btnTab

	self:SetWndTabText(btnTab,itemdata.title,-2,-30)
	self:SetWndTabStatus(btnTab, self._refID == refId  and LWnd.StateOn or LWnd.StateOff)
	self:SetWndClick(item,function ()
		self:OnClickTab(refId)
	end)
end

function UIHelpListJa:OnClickTab(refId)
	if self._refID then
		if self._refID == refId then
			return
		end
		self:SetWndTabStatus(self._tabList[self._refID],LWnd.StateOff)
	end

	self._refID = refId
	self:SetWndTabStatus(self._tabList[refId],LWnd.StateOn)
	self:SetText()
end

function UIHelpListJa:InitEvent()
	if self._isAgree then
		self:SetWndClick(self.mBg,function()
			self:WndClose()
		end)
	end

	self:SetWndClick(self.mBtnOK,function()
		if not self._isAgree then
			GF.ShowMessage(ccClientText(807))
			return
		end
		LPlayerPrefs.SetJaAgreeRule("1")
		self:WndClose()
	end)

	self:SetWndClick(self.mBtnCancel, function()
		self:WndClose()
	end)

	self:SetWndToggleDelegate(self.mToggle,function (value)
		self._isAgree = value
	end)
end

function UIHelpListJa:InitView()
	self:SetWndToggleValue(self.mToggle, self._isAgree)

	local size = self.mTextNodeRectTrans.sizeDelta
	if self._isAgree then
		CS.ShowObject(self.mBottomNode, false)
		size.y = 600
	else
		CS.ShowObject(self.mBottomNode, true)
		size.y = 720
	end
	self.mTextNodeRectTrans.sizeDelta = size

	local refDataList = self._refDataList
	local listNum = #refDataList
	if listNum == 0 then
		printInfoN2("帮助界面配置为空",string.format("GameTable.SupportTipsRef[%s] = nil",self._refIdList[1]))
		return
	end

	local data = self._refDataList[1]
	local refId = data.refId
	self._refID = refId
	self:SetText()

	local uiList = self:GetUIScroll("showTab")
	uiList:Create(self.mTabScroll,refDataList,function (...) self:ListItem(...) end, UIItemList.SUPER_GRID)
end

-- 获取帮助表文本数据
function UIHelpListJa:InitData()
	self._tabList = {}
	local refIdList = {801,802}
	if LGameSettings.platformId == 203 or LGameSettings.platformId == 204 then
		refIdList = {804,805}
	end

	self._refIdList = refIdList
	self._refDataList = {}
	for k,v in ipairs(refIdList) do
		local ref = GameTable.SupportTipsRef[v]
		if ref then
			local data = {
				refId = v,
				title = ccLngText(ref.title),
				text = ccLngText(ref.text),
			}

			table.insert(self._refDataList, data)
		end
	end

	self._isAgree = checknumber(LPlayerPrefs.isJaAgreeRule) > 0
	if gLSdkImpl:CallMethod(LSdkMethod.IsDMMPlatform) then
		if not self._isAgree then
			self._isAgree = true
			LPlayerPrefs.SetJaAgreeRule("1")
		end
	end
end

function UIHelpListJa:InitStaticContent()
	if self._isAgree then
		CS.ShowObject(self.mCloseInfo, true)
		self:SetWndText(self.mCloseInfo,ccClientText(10103))
	else
		CS.ShowObject(self.mCloseInfo, false)
	end

	self:SetWndButtonText(self.mBtnCancel,ccClientText(805))
	self:SetWndButtonText(self.mBtnOK,ccClientText(806))

	self:SetWndText(self.mToggleText, ccClientText(804))
end


------------------------------------------------------------------
return UIHelpListJa