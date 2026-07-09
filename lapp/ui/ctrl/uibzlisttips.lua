---
--- Created by Administrator.
--- DateTime: 2023/10/4 20:53:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBzListTips:LWnd
local UIBzListTips = LxWndClass("UIBzListTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBzListTips:UIBzListTips()
	self._tabList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBzListTips:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBzListTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBzListTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitCommand()
	self:InitStaticContent()
end


-- 设置文本内容
function UIBzListTips:SetText()
	if not self._refID then return end

	local data
	for k,v in ipairs(self._refDataList) do
		if v.refId == self._refID then
			data = v
		end
	end

	local text = data.text
	local para = self._contentPara
	if para then
		text = LStringUtil.ReplaceStringCommon(text,nil,unpack(para))
	end

	if self._bTransWarp then
		text = string.gsub(text,"\\n","\n")
	end

	local titleStr = self._title
	if string.isempty(titleStr) then
		titleStr = data.title
	end
	self:SetWndText(self.mTitleText,titleStr)
	self:SetWndText(self.mContentText,text)
end

-- 获取帮助表文本数据
function UIBzListTips:InitData()
	self._bTransWarp = self:GetWndArg("bTransWarp")
	self._contentPara = self:GetWndArg("para")
	local refIdList = self:GetWndArg("refIdList")
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


	self._title = self:GetWndArg("title")
end

function UIBzListTips:ListItem(list,item, itemdata, itempos)
	local btnTab = CS.FindTrans(item,"BtnTab18")
	local refId = itemdata.refId
	self._tabList[refId] = btnTab

	self:SetWndTabText(btnTab,itemdata.title,-2,-30)
	self:SetWndTabStatus(btnTab, LWnd.StateOff)
	self:SetWndClick(item,function ()
		self:OnClickTab(refId)
	end)
end

function UIBzListTips:InitStaticContent()
	self:SetWndText(self.mCloseInfo,ccClientText(10103))
end

function UIBzListTips:InitEvent()
	self:SetWndClick(self.mBg,function()
		if not table.isempty(self._refDataList) then
			for k,v in ipairs(self._refDataList) do
				local refId = v.refId
				gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_TIP,"close",refId)
			end
		end

		self:WndClose()
	end)
end

function UIBzListTips:OnClickTab(redId)
	if self._refID then
		if self._refID == redId then
			return
		end
		self:SetWndTabStatus(self._tabList[self._refID],LWnd.StateOff)
	end

	self._refID = redId
	self:SetWndTabStatus(self._tabList[redId],LWnd.StateOn)
	self:SetText()
end

function UIBzListTips:InitCommand()
	local refDataList = self._refDataList
	local listNum = #refDataList
	if listNum == 0 then
		printInfoN2("帮助界面配置为空",string.format("GameTable.SupportTipsRef[%s] = nil",self._refIdList[1]))
		return
	end

	local data = self._refDataList[1]
	local refId = data.refId

	if listNum <= 1 then
		self._refID = refId
		self:SetText()
	else
		local uiList = self:GetUIScroll("showTab")
		uiList:Create(self.mTabScroll,refDataList,function (...) self:ListItem(...) end)
		self:OnClickTab(refId)
	end
end


------------------------------------------------------------------
return UIBzListTips


