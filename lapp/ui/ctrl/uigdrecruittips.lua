---
--- Created by BY.
--- DateTime: 2023/10/15 11:51:51
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdRecruitTips:LWnd
local UIGdRecruitTips = LxWndClass("UIGdRecruitTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdRecruitTips:UIGdRecruitTips()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdRecruitTips:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdRecruitTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdRecruitTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdRecruitTips:OnClickButton(index)
	local func
	if(index == 1)then
		if(self._leftFunc)then
			func = self._leftFunc
		else
			func = function()
				self:WndClose()
			end
		end
	else
		if(self._confirmFunc)then
			func = self._confirmFunc
		end
	end
	if func then
		func()
	end
end

function UIGdRecruitTips:InitCommand()
	local WindowAttRef = GameTable.UIWindowAttRef
	self._wndRefId = self:GetWndArg("refId")
	self._confirmFunc = self:GetWndArg("func")
	self._leftFunc = self:GetWndArg("leftFunc")
	self._contentPara = self:GetWndArg("para")
	self._contentPara2 = self:GetWndArg("para2")

	self:SetWndText(self.mLblBiaoti,ccClientText(12592))
	local wndData = WindowAttRef[self._wndRefId]
	local btnPng = wndData.btnPng
	local btnPngArr = string.split(btnPng,"|")
	self:SetWndButtonImg(self.mButton_1, btnPngArr[1])
	self:SetWndButtonImg(self.mButton_2, btnPngArr[2])
	local btnTxt = ccLngText(wndData.btnTxt)
	local btnTxtArr = string.split(btnTxt,"|")
	self:SetWndButtonText(self.mButton_1,btnTxtArr[1])
	self:SetWndButtonText(self.mButton_2,btnTxtArr[2])
	local text,text2
	text = ccLngText(wndData.text)
	if(wndData.text2)then
		text2 = ccLngText(wndData.text2)
	end
	local para = self._contentPara
	local para2 = self._contentPara2
	if para then
		text = string.replace(text,unpack(para))
	end
	if para2 then
		text2 = string.replace(text2,unpack(para2))
	end
	self:SetWndText(self.mContent1,text)
	if(text2)then
		local isEn = gLGameLanguage:IsEnglishVersion()
		if isEn then
			self:SetWndText(self.mContent2En,text2)
		else
			self:SetWndText(self.mContent2,text2)
		end

		CS.ShowObject(self.mContent2En, isEn)
		CS.ShowObject(self.mContent2, not isEn)
	end
end

function UIGdRecruitTips:InitMessage()

end

function UIGdRecruitTips:InitEvent()
	self:SetWndClick(self.mBgImage,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
	self:SetWndClick(self.mButton_1,function () self:OnClickButton(1) end)
	self:SetWndClick(self.mButton_2,function () self:OnClickButton(2) end)

	self:InitTextSizeWithLanguage(self.mContent2,-2)
end
------------------------------------------------------------------
return UIGdRecruitTips


