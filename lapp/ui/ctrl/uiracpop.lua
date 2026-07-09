---
--- Created by Administrator.
--- DateTime: 2023/10/27 20:55:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIRacPop:LWnd
local UIRacPop = LxWndClass("UIRacPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRacPop:UIRacPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRacPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRacPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRacPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()
	self:InitUIEvent()
	self:OnWndRefresh()

end

function UIRacPop:OnChangeValue(value)
	local num =math.floor(value* self._numLimit)
	num = math.max(1,num)
	self._curNum = num
	self:RefreshNumShow()
end


function UIRacPop:SetStaticContent()

	local str =ccClientText(16739)-- "取消"
	self:SetWndButtonText(self.mCancelBtn,str)
	str = ccClientText(19626)--"确定"
	self:SetWndButtonText(self.mOkBtn,str)
	str =ccClientText(10240)-- "道具描述"
	self:SetTextTile(self.mTextTitle,str)
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	str = ccClientText(33115)
	self:SetWndText(self.mLblBiaoti,str)
end

function UIRacPop:OnClickOk()
	if self._callFunc then
		self._callFunc(self._curNum)
	end

	self:WndClose()
end

function UIRacPop:RefreshNumShow()
	local sliderValue = self._curNum / self._numLimit
	self:SetWndSliderDelegate(self.mNumSlider,function (...) end)
	self:SetWndSliderPara(self.mNumSlider,sliderValue)
	self:SetWndSliderDelegate(self.mNumSlider,function (...)
		self:OnChangeValue(...)
	end)

	self:SetWndText(self.mNum,self._curNum)
end

function UIRacPop:InitUIEvent()
	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)
	self:SetWndClick(self.mCancelBtn,function ()
		self:WndClose()
	end)
	self:SetWndClick(self.mOkBtn,function ()
		self:OnClickOk()
	end)

	self:SetWndClick(self.mAddBtn,function ()
		self:ChangeNum(1)
	end)

	self:SetWndClick(self.mSubBtn,function ()
		self:ChangeNum(-1)
	end)

	self:SetWndSliderDelegate(self.mNumSlider,function (...)
		self:OnChangeValue(...)
	end)

	self:SetWndClick(self.mNum,function () self:OpenKeyboard() end)
end

function UIRacPop:OnWndRefresh()
	local data = self:GetWndArg("para")
	local itemdata = data.itemdata
	self._callFunc = data.callFunc


	self:CreateCommonIconImpl(self.mItem,itemdata)
	local name = gModelGeneral:GetCommonItemColorNameNoNum(itemdata)
	self:SetWndText(self.mName,name)

	local own = gModelItem:GetNumByRefId(itemdata.itemId)
	local str = string.replace(ccClientText(33124),own)
	self:SetWndText(self.mText_1,str)

	local ref = gModelItem:GetRefByRefId(itemdata.itemId)
	if ref then
		local desc = ccLngText(ref.description)
		self:SetWndText(self.mDesText,desc)
	end

	self._curNum = data.num or 1

	self._numLimit = data.numLimit or 1

	self:RefreshNumShow()

	self:SetWndText(self.mText_2,data.intro)

end

function UIRacPop:ChangeNum(num)
	local newNum = self._curNum + num
	newNum = Mathf.Clamp(newNum,1,self._numLimit)
	self._curNum = newNum

	self:RefreshNumShow()

end

function UIRacPop:OpenKeyboard()
	local min,max,default=0,0,0
	if self._numLimit>0 then
		min = 1
		max = self._numLimit
		default = 1
	end
	local func= function(input,cmd)

		if self:IsWndClosed() then
			return
		end

		self._curNum = tonumber(input)
		self:RefreshNumShow()
	end
	GF.OpenWnd("UINuoardUI",{minNum = min,maxNum = max,defaultNum = default,inputFunc = func,inputTran = self.mNum})

end



------------------------------------------------------------------
return UIRacPop


