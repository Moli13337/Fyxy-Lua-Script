---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LxUtf8 = LXFW.LxUtf8
local LWnd = LWnd
---@class UIPerReNameUI:LWnd
local UIPerReNameUI = LxWndClass("UIPerReNameUI", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPerReNameUI:UIPerReNameUI()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPerReNameUI:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPerReNameUI:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPerReNameUI:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetPara()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()

	self:RefreshUIForGuide()
	self:DisableInputText(self.mNameInput)
	self:DisableSensitiveInputText(self.mNameInput,ModelPlayer.SENSITIVE_TYPE_2)
end

function UIPerReNameUI:InitEvent()
	self:SetWndClick(self.mRandomBtnObj,function (...) self:OnClickRandom() end)
	-- self:SetWndClick(self.mManBtnObj,function (...) self:OnClickSex(1) end)
	-- self:SetWndClick(self.mWomanBtnObj,function (...) self:OnClickSex(0) end)
	self:SetWndClick(self.mBtnBlue2,function (...) self:OnClickSub() end)
	self:SetWndClick(self.mBgImageObj,function (...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function (...) self:WndClose() end)
end

function UIPerReNameUI:InitMessage()
	self:WndNetMsgRecv(LProtoIds.PlayerRandomNameResp,function (...)
		self:RandomNameResp(...)
	end)
	self:WndNetMsgRecv(LProtoIds.PlayerReNameResp,function (...)
		if not self._noMsg then
			GF.ShowMessage(ccClientText(10412))
		end
		self:WndClose()
		FireEvent(EventNames.ON_RENAME_SUCCESS) --改名成功触发
	end)

	self:WndNetMsgRecv(LProtoIds.PlayerChangeInfoResp,function (...)
		if not self._noMsg then
			GF.ShowMessage(ccClientText(10422))
		end
		self:WndClose()
		FireEvent(EventNames.ON_RENAME_SUCCESS) --改名成功触发
	end)
end

function UIPerReNameUI:OnChangeNameJa()
	local nameText = self.mNameInput.text
	nameText = string.gsub(nameText,"\r","")
	nameText = string.gsub(nameText,"\n","")

	local haveNewName = not string.isempty(nameText) and self._oldName ~= nameText
	if haveNewName then
		local bool = string.find(nameText, " ")
		if bool then
			GF.ShowMessage(ccClientText(10409))
			return
		end

		local length = LxUtf8.cnLen(nameText)
		if(length < gModelPlayer:GetRoleConfigRefByKey("nameLengthMin"))then
			GF.ShowMessage(ccClientText(10417))
			return
		elseif(length > gModelPlayer:GetRoleConfigRefByKey("nameLengthMax"))then
			GF.ShowMessage(ccClientText(10406))
			return
		end
	end


	local noMsg = self._noMsg
	local curSex = self._oldSex
	local isBuy =  self._isBuy

	local func = function(isMatch,newText)
		if self:IsWndClosed() then
			return
		end

		if isMatch then
			self:SetWndTextInput(self.mNameInput, newText)
			GF.ShowMessage(ccClientText(10408))
		else

			local oldSex = gModelPlayer:GetPlayerSex()
			if curSex == oldSex and not haveNewName then
				GF.ShowMessage(ccClientText(10421))
				return
			end

			if isBuy==false then
				GF.ShowMessage(ccClientText(10411))
				return
			end

			if curSex ~= oldSex and not haveNewName then
				gModelPlayerSpace:OnPlayerChangeInfoReq(1,tostring(curSex))--只修改玩家性别请求
			else
				--这里参数0 = 女
				gModelPlayer:OnRenameReq(nameText,curSex,noMsg)
			end
		end

	end

	LWordMaskUtil.ClearShieldWordEx(nameText,false,false,LGameWordMask.SCENE_TYPE_PUBLIC_DATA,func)



end

function UIPerReNameUI:OnClickSub()
	self:OnChangeName()
	--if gLGameLanguage:IsJapanRegion() then
	--	self:OnChangeNameJa()
	--else
	--	self:OnChangeName()
	--end
end

function UIPerReNameUI:OnClickSex(index)
	--print(index,self._oldSex)
	-- if self._oldSex~=nil  then
	-- 	local oldTrans=self._sexBtnList[self._oldSex+1]
	-- 	local selectTrans = CS.FindTrans(oldTrans,"Image")
	-- 	CS.ShowObject(selectTrans,false)

	-- end
	-- local trans= self._sexBtnList[index+1]
	-- local selectTrans = CS.FindTrans(trans,"Image")
	-- CS.ShowObject(selectTrans,true)
	-- self._oldSex=index
end

function UIPerReNameUI:OnClickRandom()
	gModelPlayer:OnClickRandom(self._oldSex)
end

function UIPerReNameUI:SetPara()
	--self._isFromJump = self:GetWndArg("isFromJump")
	self._functionId = self:GetWndArg("functionId")
end

function UIPerReNameUI:RefreshUIForGuide()
	if self._functionId and self._functionId == 50300000 then

		--GF.CloseWndByName("UIPt")

		CS.ShowObject(self.mBtnClose,false)
		CS.ShowObject(self.mNumTextObj,true)
		CS.ShowObject(self.mConsumeObj,false)
		local str =ccClientText(10415) --"您的降临是奥兹的希望,请留下谱写传奇的名字"
		self:SetWndText(self.mNumTextObj,str)
		self:SetWndClick(self.mBgImageObj,function ()  end)
		str =ccClientText(10416) -- "您的名字"
		self:SetWndText(self.mTipsXUITextObj,str)
		CS.ShowObject(self.mNameTextObj,false)
		self._noMsg = true --不发公告和邮件

		self:OnClickRandom()
	end
end


function UIPerReNameUI:OnChangeName()
	if self._isBuy==false then
		GF.ShowMessage(ccClientText(10411))
		return
	end
	local nameText = self.mNameInput.text
	nameText = string.gsub(nameText,"\r","")
	nameText = string.gsub(nameText,"\n","")
	if self._oldName == nameText then
		GF.ShowMessage(ccClientText(10405))
		return
	end

	if not gLGameLanguage:IsForeignRegion() then
		local bool = string.find(nameText, " ")
		if bool then
			GF.ShowMessage(ccClientText(10409))
			return
		end
	else
		local isSpaceEdge = string.startswith(nameText, " ")
		if not isSpaceEdge then
			isSpaceEdge = string.endswith(nameText, " ")
		end
		if isSpaceEdge then
			GF.ShowMessage(ccClientText(10424))
			return
		end
	end

	local length = LxUtf8.cnLen(nameText)
	if(length < gModelPlayer:GetRoleConfigRefByKey("nameLengthMin"))then
		GF.ShowMessage(ccClientText(10417))
		return
	elseif(length > gModelPlayer:GetRoleConfigRefByKey("nameLengthMax"))then
		GF.ShowMessage(ccClientText(10406))
		return
	end

	local sex = self._oldSex
	local noMsg = self._noMsg

	local func = function(isMatch,newText)

		if self:IsWndClosed() then
			return
		end

		if isMatch then
			--self.mNameInput.text = newText
			self:SetWndTextInput(self.mNameInput, newText)
			GF.ShowMessage(ccClientText(10408))
		else
			gModelPlayer:OnRenameReq(nameText,sex,noMsg)
		end

	end

	LWordMaskUtil.ClearShieldWordEx(nameText,false,false,LGameWordMask.SCENE_TYPE_PUBLIC_DATA,func)

	--nameText,bool = LWordMaskUtil.ClearShieldWord(nameText,false,ccClientText(10408))
	--if(not bool)then
	--	self.mNameInput.text = nameText
	--	return
	--end
	--gModelPlayer:OnRenameReq(nameText,self._oldSex,self._noMsg)
end

function UIPerReNameUI:InitCommand()
	-- self._sexBtnList={
	-- 	self.mWomanBtnObj,
	-- 	self.mManBtnObj,
	-- }
	--设置了sex 但没有设置形象
	self._oldSex=gModelPlayer:GetPlayerSex()
	-- self:OnClickSex(self._oldSex)
	self.NameGeneratorConfigRef = GameTable.NameGeneratorConfigRef
	local num= gModelItem:GetNumByRefId(self.NameGeneratorConfigRef["renameItem"])
	self._oldName=gModelPlayer:GetPlayerName()
	--local text = CS.FindTrans(self.mNameInput,"Placeholder")
	--self:SetWndText(text,ccClientText(10405))
	self:SetWndTextInput(self.mNameInput, nil, ccClientText(10405))
	self:SetWndText(self.mTipsXUITextObj,ccClientText(10413))
	self:SetWndButtonText(self.mBtnBlue2, ccClientText(10414))
	self:SetWndText(self.mNameTextObj,string.replace(ccClientText(10401),self._oldName))
	if tonumber(num)>0 then
		CS.ShowObject(self.mNumTextObj,true)
		CS.ShowObject(self.mConsumeObj,false)
		self:SetWndText(self.mNumTextObj,ccClientText(10404)..num)
	else
		local item= self.NameGeneratorConfigRef["renameCost"]
		local strArr =string.split(item,"=")
		CS.ShowObject(self.mNumTextObj,false)
		CS.ShowObject(self.mConsumeObj,true)
		local icon = CS.FindTrans(self.mConsumeObj,"Image")
		local text = CS.FindTrans(self.mConsumeObj,"XUIText")

		local itemId=tonumber(strArr[2])
		num=gModelItem:GetNumByRefId(itemId)
		self:SetWndEasyImage(icon,GameTable.PlayerItemRef[itemId].icon)
		local str
		if tonumber(num) >=tonumber(strArr[3]) then
			str="<color=#0fb93f>"..num.."</color>".."/"..strArr[3]
		else
			str="<color=#FF0000>"..num.."</color>".."/"..strArr[3]
			self._isBuy=false
		end
		self:SetWndText(text,str)
	end
end

function UIPerReNameUI:RandomNameResp(cmd)
	--self.mNameInput.text = cmd.name
	self:SetWndTextInput(self.mNameInput, cmd.name)
end

------------------------------------------------------------------
return UIPerReNameUI


