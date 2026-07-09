---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
local YXUIPointUtil = CS.YXUIPointUtil
---@class UINuoardUI:LWnd
local UINuoardUI = LxWndClass("UINuoardUI", LWnd)

UINuoardUI.ENTER ="D"
UINuoardUI.CLEAR ="C"
UINuoardUI.INPUT ="I"

UINuoardUI.TYPE_COMMON = 0 --默认模式
UINuoardUI.TYPE_CODE 	 = 1 --验证码输入模式，每次只改变1位数, 允许前几位为0

UINuoardUI.CANCEL_TYPE_ALL = 1 --删除模式，每次点击c全部删除
UINuoardUI.CANCEL_TYPE_ONE = 2 --删除模式，每次点击c删除一位数

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UINuoardUI:UINuoardUI()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UINuoardUI:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UINuoardUI:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UINuoardUI:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()

	self._inputOne=true--第一次替换该数字
	self._inputTrans=self:GetWndArg("inputTran")
	self._numberStr=self:GetWndArg("defaultNum")
	self._inputCall=self:GetWndArg("inputFunc")
	self._minNum = self:GetWndArg("minNum")
	self._maxNum = self:GetWndArg("maxNum")
	self._inputType = self:GetWndArg("inputType") or UINuoardUI.TYPE_COMMON
	self._cancelType = self:GetWndArg("cancelType") or UINuoardUI.CANCEL_TYPE_ALL
	self._closeFunc = self:GetWndArg("closeFunc")

	if self._inputType == UINuoardUI.TYPE_CODE then
		if not self._numberStr then
			self._numberStr=""
		end
	else
		if not self._numberStr then
			self._numberStr="0"
		end

		local num = tonumber(self._numberStr)
		if num>self._maxNum then
			self._numberStr=tostring(self._maxNum)
		elseif num<self._minNum then
			self._numberStr=tostring(self._minNum)
		end
	end


	self:InitPoint()
	self:InitCommand()
end

function UINuoardUI:InitPoint()
	local trans=LGameUI.GetUICanvasRoot()
	local v2=YXUIPointUtil.GetScreenPoint(trans,self._inputTrans)

	local posX,posY
	if v2.x+self.mKeyboard.rect.width/2>320 then
		posX= 320-self.mKeyboard.rect.width/2 + 10
	elseif v2.x-self.mKeyboard.rect.width/2<-320 then
		posX= -320+self.mKeyboard.rect.width/2 + 10
		--posX=(v2.x+self._inputTrans.rect.width)-self.mKeyboard.rect.width/2
	else
		posX = v2.x
	end
	if v2.y-self._inputTrans.rect.height/2-self.mKeyboard.rect.height-10>-568 then
		posY=v2.y-self._inputTrans.rect.height/2-self.mKeyboard.rect.height/2-10
	else
		posY=(v2.y+self._inputTrans.rect.height/2)+self.mKeyboard.rect.height/2+10
	end
	self.mKeyboard.localPosition=Vector2.New(posX,posY)
end

function UINuoardUI:InitEvent()
	self:SetWndClick(self.mCloseImageObj,function(...) self:OnClickCommand("D") end)
end


function UINuoardUI:OnDrawCommandTextItem(list, item, itemdata, itempos, fromHeadTail)
	local iconTrans = CS.FindTrans(item,"Image")
	self:SetWndEasyImage(iconTrans,itemdata.tips)
end

function UINuoardUI:OnSendMeg(cmdKey,cmpPara)

	local inputCall = self._inputCall
	if inputCall ~= nil then
		if self._inputType == UINuoardUI.TYPE_COMMON then
			cmpPara = tonumber(cmpPara)
		end

		inputCall(cmpPara,cmdKey)
	end

	if cmdKey == UINuoardUI.ENTER then
		if self._closeFunc then
			self._closeFunc(cmpPara, cmdKey)
		end
		self:WndClose()
	end
end

function UINuoardUI:InitCommand()
	local listCommand = {
		{tips="public_keyboard_btn_7",command="7"},
		{tips="public_keyboard_btn_8",command="8"},
		{tips="public_keyboard_btn_9",command="9"},
		{tips="public_keyboard_btn_4",command="4"},
		{tips="public_keyboard_btn_5",command="5"},
		{tips="public_keyboard_btn_6",command="6"},
		{tips="public_keyboard_btn_1",command="1"},
		{tips="public_keyboard_btn_2",command="2"},
		{tips="public_keyboard_btn_3",command="3"},
		{tips="public_keyboard_btn_c",command="C"},
		{tips="public_keyboard_btn_0",command="0"},
		{tips="public_keyboard_btn_enter",command="D"},
	}
	self._listCommand = listCommand

	local uiList = self._uiList
	if (not uiList) then
		uiList = UIListEasy:New()
		uiList:Create(self,self.mListCommander)
		uiList:SetFuncOnItemDraw(function (...)
			self:OnDrawCommandItem(...)
		end)
		self._uiList = uiList
	end

	for k,v in ipairs(listCommand) do
		uiList:AddData(k,v)
	end
	uiList:RefreshList()
end

function UINuoardUI:OnClickCommand(cmd)
	local cmdKey = nil

	if cmd=="D"then
		cmdKey = UINuoardUI.ENTER
	elseif cmd=="C" then
		if self._inputType == UINuoardUI.TYPE_CODE then
			if self._cancelType == UINuoardUI.CANCEL_TYPE_ONE then
				local inputLen = string.len(self._numberStr)
				if inputLen > 1 then
					self._numberStr= string.sub(self._numberStr, 0 ,inputLen - 1)
				else
					self._numberStr= ""
				end
			else
				--每次直接删除
				self._numberStr= ""
			end
		else
			self._numberStr="0"
		end
		cmdKey = UINuoardUI.CLEAR
	else
		if self._inputType == UINuoardUI.TYPE_COMMON and (self._numberStr=="" or self._numberStr=="0") then
			self._numberStr = cmd
		else
			self._numberStr=self._numberStr..cmd
		end
		cmdKey = UINuoardUI.INPUT
	end

	if self._numberStr =="" then
		if self._inputType == UINuoardUI.TYPE_COMMON then
			self._numberStr="0"
		end
	end

	if cmdKey ~= UINuoardUI.CLEAR then
		if self._inputType == UINuoardUI.TYPE_CODE then
			local inputLen = string.len(self._numberStr)
			if inputLen > self._maxNum then
				self._numberStr = string.sub(self._numberStr, self._minNum, self._maxNum)
			end
		else
			local number=tonumber(self._numberStr)
			number = Mathf.Clamp(number,self._minNum,self._maxNum)
			self._numberStr = tostring(number)
		end
	end


	local cmdPara = self._numberStr

	self:OnSendMeg(cmdKey,cmdPara)
end


function UINuoardUI:OnDrawCommandItem(list, item, itemdata, itempos, fromHeadTail)
	self:OnDrawCommandTextItem(list, item, itemdata, itempos, fromHeadTail)
	self:SetWndClick(item,function (...)
		self:OnClickCommand(itemdata.command)
	end)
end

------------------------------------------------------------------
return UINuoardUI