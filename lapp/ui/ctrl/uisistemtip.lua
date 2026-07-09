---
--- Created by luofuwen.
--- DateTime: 2023/10/15 14:50:03
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISistemTip:LWnd
local UISistemTip = LxWndClass("UISistemTip", LWnd)


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISistemTip:UISistemTip()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISistemTip:OnWndClose()
	if self._closeFunc then
		self._closeFunc()
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISistemTip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISistemTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitTips()
end

function UISistemTip:OnBtnClick(iType)
	-- 0关闭  1左边  2右边
	if self._callFunc then
		self._callFunc(iType)
	end
	if iType == 1 then
		if self._leftFunc then
			self._leftFunc()
		end
	elseif iType == 2 then
		if self._rightFunc then
			self._rightFunc()
		end
	end


	self:WndClose()
end
function UISistemTip:InitTipByRef()
	local wndRefId = self._wndRefId
	--wndRefId = 50201
	local wndData = GameTable.UIWindowAttRef[wndRefId]
	if not wndData then
		LogError("默认窗口类型为10001，没有配置该窗口的类型的数据:"..wndRefId)
		wndData = GameTable.UIWindowAttRef[10001]
	end
	self._wndData = wndData

	local btnText=ccLngText(wndData.btnTxt)
	local strs = string.split(btnText,"|") or {}

	local btnPng = wndData.btnPng
	local pngStr = string.split(btnPng,"|") or {}

	local title = ccLngText(wndData.title)

	self._btnImgPaths = pngStr
	local text = ccLngText(wndData.text)
	local para = self._contentPara
	if para then
		text = string.replace(text,unpack(para))
	end

	if (string.isempty(self._content)) then
		self._content = text
	end

	if (string.isempty(self._title)) then
		self._title = title
	end

	if #strs > 1 then
		if (string.isempty(self._btnText1)) then
			self._btnText1 = strs[1]
		end

		if (string.isempty(self._btnText2)) then
			self._btnText2 = strs[2]
		end
	else
		if (string.isempty(self._btnText1)) then
			self._btnText1 = strs[1]
		end
		if (string.isempty(self._btnText2)) then
			self._btnText2 = strs[1]
		end
	end

end

function UISistemTip:InitTips()
	local defaultImgNames = {
		[1] = "public_btn_1_3",
		[2] = "public_btn_1_2",
		[3] = "public_btn_1_1"
	}
	self._btnImgPaths = {}
	self._title = self:GetWndArg("title")
	self._content = self:GetWndArg("content")
	self._btnText1 = self:GetWndArg("btnTile1")
	self._btnText2 = self:GetWndArg("btnTile2")
	self._callFunc = self:GetWndArg("callFunc")			-- 回调函数

	self._wndRefId = self:GetWndArg("refId") 			-- 窗口的RefId
	self._leftFunc = self:GetWndArg("leftFunc")
	self._rightFunc = self:GetWndArg("func")
	self._contentPara = self:GetWndArg("para")
	self._closeFunc = self:GetWndArg("closeFunc")		-- 关闭按钮的回调

	self:ShowBtnItem(nil, nil, nil)

	if self._wndRefId then
		self:InitTipByRef()
		if 1 == #self._btnImgPaths then
			self:ShowBtnItem(self._btnImgPaths[1], nil, 2)
		else
			self:ShowBtnItem(self._btnImgPaths[1], nil, 1)
			self:ShowBtnItem(self._btnImgPaths[2], nil, 2)
		end

		self:SetTipsText(self.mTitle, self._title)
		self:SetTipsText(self.mContent, self._content)
		self:SetBtnText(self._btnImgPaths[1], nil, self._btnText1)
		self:SetBtnText(self._btnImgPaths[2], nil, self._btnText2)
	else
		self:SetTipsText(self.mTitle, self._title)
		self:SetTipsText(self.mContent, self._content)
		self:ShowBtnItem(defaultImgNames[1], nil, 1)
		self:ShowBtnItem(defaultImgNames[3], nil, 2)
		self:SetBtnText(defaultImgNames[1], nil, self._btnText1)
		self:SetBtnText(defaultImgNames[3], nil, self._btnText2)
	end

	--self:SetWndClick(self.mCloseBtn,function () self:OnBtnClick(0) end)
	--self:SetWndClick(self.mBtn1,function () self:OnBtnClick(1) end)
	--self:SetWndClick(self.mBtn2,function () self:OnBtnClick(2) end)

	CS.ShowObject(self.mCloseBtn,false)
end

function UISistemTip:SetTipsText(txtObj, text)
	if not txtObj then
		return
	end
	CS.ShowObject(txtObj, not string.isempty(text))
	if text then
		self:SetXUITextText(txtObj, text)
	end
end

function UISistemTip:SetBtnText(btnName, btnIndex, text)
	local btnItem = nil
	if btnName then
		btnItem = self:FindWndTrans(self.mBtnList, btnName)
	elseif btnIndex then
		btnItem = self.mBtnList:GetChild(btnIndex-1)
	end
	if btnItem and text then
		self:SetWndButtonText(btnItem, text)
	end
end

function UISistemTip:ShowBtnItem(btnName, btnIndex, callIndex)
	if not btnName and not btnIndex then
		local childCount = self.mBtnList.childCount
		local btnItem = nil
		for idx = 1, childCount do
			btnItem = self.mBtnList:GetChild(idx-1)
			CS.ShowObject(btnItem, false)
		end
		return
	end
	local btnItem = nil
	if btnName then
		btnItem = self:FindWndTrans(self.mBtnList, btnName)
	end
	if not btnItem and btnIndex then
		btnItem = self.mBtnList:GetChild(btnIndex-1)
	end

	if btnItem then
		if btnIndex then
			btnItem:SetSiblingIndex(btnIndex)
		end
		CS.ShowObject(btnItem, true)
	end

	self:SetWndClick(btnItem,function () self:OnBtnClick(callIndex) end)
end
------------------------------------------------------------------
return UISistemTip


