---
--- Created by Administrator.
--- DateTime: 2025/12/18 17:47:31
--- 实名认证
------------------------------------------------------------------
local LWnd = LWnd
---@class UIRealNameAuth:LWnd
local UIRealNameAuth = LxClass("UIRealNameAuth", LWnd)
------------------------------------------------------------------
---@type number 提示
local REALNAME_STEP_1 = 1
---@type number 填写身份证
local REALNAME_STEP_2 = 2
---@type number 感谢配合
local REALNAME_STEP_3 = 3

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRealNameAuth:UIRealNameAuth()

	self._realNameStep = REALNAME_STEP_1
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRealNameAuth:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRealNameAuth:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRealNameAuth:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SendTKData()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end


function UIRealNameAuth:InitData()
	local realNameStep = self:GetWndArg("realNameStep")
	if realNameStep and realNameStep > 0 then
		self._realNameStep = realNameStep
	end
end

function UIRealNameAuth:GetIdCardInfo(idCardNumStr)
	local type = 0
	local genderDigitStr
	local age = ""
	if not string.isempty(idCardNumStr) then
		if self:IsValidIdCardNum(idCardNumStr) then
			local strLen = string.len(idCardNumStr)
			local birthDate,genderPos
			if strLen == 15 then
				birthDate = "19" .. string.sub(idCardNumStr, 7, 12)
				genderPos = 15
			else
				birthDate = string.sub(idCardNumStr, 7, 14)
				genderPos = 17
			end
			local month = checknumber(string.sub(birthDate, 5, 6))
			if month >= 1 and month <= 12 then
				local year = checknumber(string.sub(birthDate, 1, 4))
				local day = checknumber(string.sub(birthDate, 7, 8))
				local today = LUtil.OSDate("*t", GetTimestamp())
				age = today.year - year
				if today.month < month or (today.month == month and today.day < day) then
					age = age - 1
				end
				local genderDigit = checknumber(string.sub(idCardNumStr, genderPos, genderPos))
				genderDigitStr = genderDigit % 2 == 0 and "女" or "男"
				type = 1
				if age >= 18 then
					self._realNameStep = REALNAME_STEP_3
				else
					GF.ShowMessage(ccClientText(47709))
				end
			end
		else
			LogWarn("身份证号只能包含数字和X，身份证：" .. idCardNumStr)
		end
	end
	return type,age,genderDigitStr
end

function UIRealNameAuth:RefreshView()
	local realNameStep = self._realNameStep
	CS.ShowObject(self.mView1,realNameStep == REALNAME_STEP_1)
	CS.ShowObject(self.mView2,realNameStep == REALNAME_STEP_2)

	local isFinishStep = realNameStep == REALNAME_STEP_3
	CS.ShowObject(self.mView3,isFinishStep)
	CS.ShowObject(self.mCloseTip,isFinishStep)
end

function UIRealNameAuth:OnClickBtnNext()
	self._realNameStep = REALNAME_STEP_2
	self:RefreshView()
end

function UIRealNameAuth:OnFinishRealName(idCardNum,realName)
	self:SendTKData(tostring(idCardNum))
	self:RefreshView()
end

function UIRealNameAuth:InitText()
	self:SetCommonButtonText(self.mBtnNext,ccClientText(47702))
	self:SetCommonButtonText(self.mBtnLater,ccClientText(47705))
	self:SetCommonButtonText(self.mBtnSubmit,ccClientText(47706))
	self:SetWndText(self.mDesc1,ccClientText(47700))
	self:SetWndText(self.mDesc2,ccClientText(47701))
	self:SetWndText(self.mDesc3,ccClientText(47707))
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	self:SetWndTextInput(self.mInputName,nil,ccClientText(47703))
	self:SetWndTextInput(self.mInputIdNumber,nil,ccClientText(47704))
end

function UIRealNameAuth:OnClickBtnClose()
	if self._realNameStep ~= REALNAME_STEP_3 then
		QuitGame()
	else
		self:WndClose()
	end
end

function UIRealNameAuth:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mMask,function() self:OnClickMask() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:OnClickBtnClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnNext,function() self:OnClickBtnNext() end)
	self:SetWndClick(self.mBtnLater,function() self:OnClickBtnLater() end)
	self:SetWndClick(self.mBtnSubmit,function() self:OnClickBtnSubmit() end)
end

function UIRealNameAuth:InitMsg()
	self:WndEventRecv(EventNames.FINISH_REAL_NAME,function(...) self:OnFinishRealName(...) end)
end

function UIRealNameAuth:SendTKData(idCardNumStr)
	self:SendToTrack(idCardNumStr)
end

function UIRealNameAuth:OnClickBtnSubmit()
	local idCardNum = self.mInputIdNumber.text
	if string.isempty(idCardNum) then
		GF.ShowMessage(ccClientText(47708))
		return
	end
	local realName = self.mInputName.text
	if string.isempty(realName) then
		GF.ShowMessage(ccClientText(47708))
		return
	end
	gLSdkImpl:CallMethod(LSdkMethod.SetWXIdentify,idCardNum,realName)
end

function UIRealNameAuth:OnClickMask()
	if self._realNameStep == REALNAME_STEP_3 then
		self:WndClose()
	end
end

function UIRealNameAuth:OnClickBtnLater()
	self:WndClose()
end

function UIRealNameAuth:IsValidIdCardNum(idCardNumStr)
	local isMatch = string.match(idCardNumStr,"^[0-9X]+$")
	if isMatch then
		local strLen = string.len(idCardNumStr)
		if strLen == 15 or strLen == 18 then
		else
			isMatch = false
			LogWarn("身份证号长度应为15位或18位，身份证：" .. idCardNumStr)
		end
	end
	return isMatch
end

function UIRealNameAuth:SendToServer(idCardNumStr)
	local type,age,genderDigitStr = self:GetIdCardInfo(idCardNumStr)
	local data = { ["wxsmall_realname_type"] = tostring(type), }
	if type == 1 then
		data["wxsmall_realname_succ"] = string.replace("#a1#|#a2#|#a3#",idCardNumStr,tostring(age),genderDigitStr)
	end
	local attr1 = JSON.encode(data)
	gLxTKData:OnTAClientEventReq(LxTKData.WXSMALL_REALNAME_SHOW, "微小实名认证", attr1)
end

function UIRealNameAuth:SendToTrack(idCardNumStr)
	local type,age,genderDigitStr = self:GetIdCardInfo(idCardNumStr)
	FireEvent(EventNames.TRACK_REAL_NAME,type,idCardNumStr,tostring(age),genderDigitStr)
end



------------------------------------------------------------------
return UIRealNameAuth