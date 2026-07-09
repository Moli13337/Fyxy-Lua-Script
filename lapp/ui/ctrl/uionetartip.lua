---
--- Created by Administrator.
--- DateTime: 2023/10/22 11:36:40
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIOnetarTip:LWnd
local UIOnetarTip = LxWndClass("UIOnetarTip", LWnd)

local typeUIToggle = typeof(UnityEngine.UI.Toggle)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOnetarTip:UIOnetarTip()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOnetarTip:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOnetarTip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOnetarTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:ShowTypeWndByData()
	self:InitStaticInfo()
end

function UIOnetarTip:InitData()
	self._wndRefId = self:GetWndArg("refId") 			-- 窗口的RefId
	if self._wndRefId then
		self._wndRefId = tonumber(self._wndRefId)
	end

	self._confirmFunc = self:GetWndArg("func")			-- 回调函数
	self._leftFunc = self:GetWndArg("leftFunc")
	self._closeFunc = self:GetWndArg("closeFunc")		-- 关闭按钮的回调
	self._wndData = nil
end

function UIOnetarTip:InitStaticInfo()
	self:SetWndText(self.mDayNotShowTxt, ccClientText(10155))
end

function UIOnetarTip:SetTitle()
	self:DisposeXUIText(self.mTitle,self._title)
	self:DisposeXUIText(self.mDesc,self._text)
end

function UIOnetarTip:OnClickCloseButton()
	if self._closeFunc then self._closeFunc() end
	self:WndClose()
end

function UIOnetarTip:ShowTypeWndByData()
	local wndRefId = self._wndRefId

	local wndData = GameTable.UIWindowAttRef[wndRefId]
	if not wndData then
		LogError("默认窗口类型为10001，没有配置该窗口的类型的数据:"..wndRefId)
		wndData = GameTable.UIWindowAttRef[10001]
	end
	self._wndData = wndData

	local wndType = tonumber(wndData.windowType)
	-- wndType = 2
	self._wndType = wndType

	local showCloseBtn = tonumber(wndData.closeBtn)
	self._showCloseBtn = showCloseBtn == 1
	CS.ShowObject(self.mCloseBtn,self._showCloseBtn)

	-- 点击空白处是否退出
	local touchAnyClose = wndData.touchAnyClose
	self._touchClose = tonumber(touchAnyClose)

	-- 今日不再提醒块是否显示
	local todayTipStr = string.split(wndData.todayTip,"=")
	local todayTip = tonumber(todayTipStr[1])
	self._todayTip = todayTip
	self._todayDefaultSel = tonumber(todayTipStr[2]) == 1
	if self._todayDefaultSel then
		local csToggle = self.mToggle:GetComponent(typeUIToggle)
		if csToggle then
			csToggle.isOn = self._todayDefaultSel
			self._isNotAlert = self._todayDefaultSel
		end
	end

	local title = ccLngText(wndData.title)
	self._title = title

	local btnText=ccLngText(wndData.btnTxt)
	local strs = string.split(btnText,"|")

	local btnPng = wndData.btnPng
	local pngStr = string.split(btnPng,"|")

	self._btnStrs=strs
	self._btnImgPaths=pngStr

	local text = ccLngText(wndData.text)
	self._text = text

	self:ShowType()
end

function UIOnetarTip:SetDayNoShow()
	CS.ShowObject(self.mDayNotShow,self._todayTip ~= 0)
end

function UIOnetarTip:DisposeXUIText(trans,msg,size,color)
	local xuiTextTrans = self:FindWndText(trans)
	self:SetXUITextText(xuiTextTrans,msg)
	if size  then self:SetXUITextFontSize(xuiTextTrans,size) end
	if color then self:SetXUITextColor(xuiTextTrans,color)	 end
end

function UIOnetarTip:OnClickButton(index)
	local func = self._leftFunc
	if self._confirmFunc then
		func = self._confirmFunc
	end

	if self._isNotAlert then
		local refId = self._wndRefId
		local sid   = self._sid
		local alertId
		if self._todayTip and self._todayTip == 2 then
			--todayTip为2， 同refId，不同sid, 今日不再提示不共用
			if not sid then
				LogError("sid is a nil")
				return
			end
			alertId = tonumber(refId..sid)
		else
			--todayTip为1， 同refId，今日不再提示共用
			alertId = tonumber(refId)
		end
		gModelGeneral:SetAlertId(alertId)
	end

	local closeFunc = self._closeFunc

	if index == 1 then
		if closeFunc and func ~= closeFunc then  ---防止重复调用
		closeFunc()
		end
	end

	if func then
		func()
	end
	self:WndClose()
end

function UIOnetarTip:InitEvent()
	if self._touchClose == 1 then
		self:SetWndClick(self.mMaskCell,function()
			self:OnClickCloseButton()
		end)
	end
	LxUiHelper.SetToggle_ValueChanged(self.mToggle,function()
		self:OnClickToggleFunc()
	end)
	self:SetWndClick(self.mCloseBtn,function () self:OnClickCloseButton() end)
	self:SetWndClick(self.mToggleBtn,function () self:OnClickToggleFunc(true) end)
end

function UIOnetarTip:SetBtn()
	local haveStartNum = false

	local btnTransList = {}
	self._btnTransList = btnTransList

	local root = self.mBtnLayout
	local childCount = root.childCount
	for idx = 1, childCount do
		local btnItem = root:GetChild(idx-1)
		CS.ShowObject(btnItem, false)
	end

	for i=1,2 do
		local btnText= self._btnStrs[i]
		local btnImg = self._btnImgPaths[i]
		local active = false

		local btn = self:FindWndTrans(root, btnImg)
		if btn then
			CS.ShowObject(btn, true)
			-- 调整按钮位置
			btn:SetSiblingIndex(i)
			btnTransList[i] = btn

			haveStartNum = false
			if btnText then
				active = true
				local text = btnText
				self:SetWndButtonText(btn, text)
				local index = i
				self:SetWndClick(btn,function () self:OnClickButton(index) end)
			end
		end

	end
end

function UIOnetarTip:OnClickToggleFunc(btnClick)
	local csToggle = self.mToggle:GetComponent(typeUIToggle)
	if (csToggle) then
		local isOn = csToggle.isOn
		if btnClick then
			isOn = not isOn
			csToggle.isOn = isOn
		end
		self._isNotAlert = isOn
	end
end

function UIOnetarTip:ShowType()
	self:SetTitle()
	self:SetBtn()
	self:SetDayNoShow()
end



------------------------------------------------------------------
return UIOnetarTip


