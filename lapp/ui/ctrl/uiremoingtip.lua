---
--- Created by Administrator.
--- DateTime: 2023/10/9 10:29:16
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIRemoingTip:LWnd
local UIRemoingTip = LxWndClass("UIRemoingTip", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRemoingTip:UIRemoingTip()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRemoingTip:OnWndClose()

	if self._callOnClose then
		self._callOnClose()
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRemoingTip:OnCreate()
	LWnd.OnCreate(self)

	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRemoingTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitEvent()

	self:OnWndRefresh()
end

function UIRemoingTip:InitData()
	---@type table<string,UIObjPool>
	self._objPoolList = {}

	local objPool = UIObjPool:New()
	objPool:Create(self.mUnuse,self.mPublic_btn_1_1)
	self._objPoolList["public_btn_1_1"] = objPool
	objPool = UIObjPool:New()
	objPool:Create(self.mUnuse,self.mPublic_btn_1_2)
	self._objPoolList["public_btn_1_2"] = objPool
	objPool = UIObjPool:New()
	objPool:Create(self.mUnuse,self.mPublic_btn_1_3)
	self._objPoolList["public_btn_1_3"] = objPool
end

function UIRemoingTip:InitEvent()
	self:WndEventRecv(EventNames.REMOTE_DOWNLOAD_PROGRESS,function (...)
		self:UpdateText(...)
	end)
end

function UIRemoingTip:UpdateText(key,value)
	if self._key ~= key then
		return
	end
	local str = string.format("%s%%",math.floor(value*100))
	local text = string.replace(self._wndPara.text,str)

	self:SetWndText(self.mContent1,text)
end

function UIRemoingTip:OnWndRefresh()
	local refId = self:GetWndArg("refId")
	self._callOnClose = self:GetWndArg("callOnClose")
	self._funcMap = self:GetWndArg("funcMap")
	self._key = self:GetWndArg("key")

	local ref =  GameTable.UIWindowAttRef[refId]

	local wndPara =
	{
		showCloseBtn = ref.closeBtn == 1,
		touchAnyClose = ref.touchAnyClose == 1,
		title = ccLngText(ref.title),
		text = ccLngText(ref.text),
	}

	local btnTextList = string.split(ccLngText(ref.btnTxt),'|')
	local btnPngList = string.split(ref.btnPng,'|')

	local btnList = {}
	for k,v in ipairs(btnTextList) do
		local btnData =
		{
			btnText = v,
			btnPng = btnPngList[k],
			index = k
		}

		table.insert(btnList,btnData)
	end

	wndPara.btnList = btnList

	self._wndPara = wndPara

	self:SetWndText(self.mTitle1,wndPara.title)

	CS.ShowObject(self.mCloseBtn1,wndPara.showCloseBtn)
	self:SetWndClick(self.mCloseBtn1,function ()
		self:OnClickClose()
	end)

	self:SetWndClick(self.mMask,function ()
		self:OnClickMask()
	end)

	for k,v in pairs(self._objPoolList) do
		v:ReturnAllObj()
	end

	for k,v in ipairs(btnList) do
		local objPool = self._objPoolList[v.btnPng]
		if objPool then
			local obj = objPool:GetObj()
			local objTran = obj.transform
			CS.SetParentTrans(objTran,self.mBtnLayout_1)
			self:SetWndButtonText(objTran,v.btnText)
			self:SetWndClick(objTran,function ()
				self:OnClickBtn(v.index)
			end)
		end
	end

end

function UIRemoingTip:OnClickClose()
	self:WndClose()
end

function UIRemoingTip:OnClickBtn(index)
	local funcMap = self._funcMap or {}
	local func = funcMap[index]
	if func then
		func()
	end

	self:WndClose()
end

function UIRemoingTip:OnClickMask()
	if not self._wndPara.touchAnyClose then
		return
	end

	self:OnClickClose()
end



------------------------------------------------------------------
return UIRemoingTip


