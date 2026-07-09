---
--- Created by LCM.
--- DateTime: 2024/3/13 10:44:34
---
------------------------------------------------------------------
local LxUtf8 = LXFW.LxUtf8
local LWnd = LWnd
---@class UISagaResetName:LWnd
local UISagaResetName = LxWndClass("UISagaResetName", LWnd)
UISagaResetName.HeroWnd = 1
UISagaResetName.PetWnd = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaResetName:UISagaResetName()
	self._resetStatus = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaResetName:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaResetName:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaResetName:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitStaticData()
	self:InitData()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:DisableInputText(self.mNameInput)
	self:DisableSensitiveInputText(self.mNameInput,ModelPlayer.SENSITIVE_TYPE_7)

	self:InitNameInputStr()
end
function UISagaResetName:GetConfigName()
	local configName = ""
	-- 【C宠物系统】删掉宠物系统相关
	-- if(self._wndType == UISagaResetName.PetWnd)then
	-- 	configName = self._petRefName
	-- else
		local heroData = self._heroData
		configName = gModelHeroExtra:GetHeroConfigNameByServerData(heroData)
	-- end
	return configName
end

function UISagaResetName:InitNameInputStr()
	self:SetNameInputStr(nil,ccClientText(36709))
end

function UISagaResetName:InitStaticData()
	local nameNum = gModelHeroExtra:GetHeroResetNameCharNum()
	self._nameNum = nameNum				--- 字符长度
	self._chNameNum = nameNum / 2		--- 中文长度
end

function UISagaResetName:SendHeroSetNameReq(newText)
	local heroData = self._heroData
	-- local petData = self._petData
	if not heroData then return end
	self._sendMsg = true
	-- 【C宠物系统】删掉宠物系统相关
	-- if(self._wndType == UISagaResetName.PetWnd)then
	-- 	local setName = (not newText or string.isempty(newText)) and self._petRefName or newText
	-- 	self._setPetName = setName
	-- 	gModelPetSpace:OnPetSetNameReq(petData.id, setName)
	-- else
		gModelHeroExtra:OnHeroSetNameReq(heroData.id,newText)
	-- end
end

function UISagaResetName:OnClickEnterBtnFunc()
	if self._sendMsg then return end
	self:CheckInputStr()
end

function UISagaResetName:InitText()
	self:SetWndText(self.mLblBiaoti,ccClientText(36700))
	self:SetWndButtonText(self.mResetBtn,ccClientText(36702))
	self:SetWndButtonText(self.mEnterBtn,ccClientText(36703))

	local heroData = self._heroData
	if heroData then
		local curNameStr = string.replace(ccClientText(36701),gModelHeroExtra:GetHeroSetName(heroData))
		self:SetWndText(self.mCurHeroName,curNameStr)
	-- 【C宠物系统】删掉宠物系统相关
	-- elseif(self._petData)then
	-- 	local curNameStr = string.replace(ccClientText(36701), self._curPetName)
	-- 	self:SetWndText(self.mCurHeroName,curNameStr)
	end
	local isGray = self._isInitHeroName or false
	self:SetWndButtonGray(self.mResetBtn,isGray)
end

function UISagaResetName:SetNameInputStr(sTxt,holdTxt)
	self:SetWndTextInput(self.mNameInput, sTxt,holdTxt)
end
-- 【C宠物系统】删掉宠物系统相关
-- function UISagaResetName:OnPetSetNameResp()
-- 	if self._resetStatus then
-- 		GF.ShowMessage(ccClientText(36710))
-- 	else
-- 		GF.ShowMessage(ccClientText(36711))
-- 	end
-- 	FireEvent(EventNames.ON_SET_PET_NAME,self._setPetName)
-- 	self:WndClose()
-- end
function UISagaResetName:OnHeroSetNameResp()
	if self._resetStatus then
		GF.ShowMessage(ccClientText(36710))
	else
		GF.ShowMessage(ccClientText(36711))
	end
	--self._sendMsg = false
	self:WndClose()
end

function UISagaResetName:InitData()
	self._heroData = self:GetWndArg("heroData")
	self._wndType = self:GetWndArg("wndType")
	-- 【C宠物系统】删掉宠物系统相关
	-- if(self._wndType == UISagaResetName.PetWnd)then
	-- 	self._petData = self:GetWndArg("petData")
	-- 	local petRefId = self._petData.refId
	-- 	local petRef = gModelPetSpace:GetPetConfigByTypeAndKey(ModelPetSpace.MagicPetRef ,petRefId)
	-- 	local petRefName = ccLngText(petRef.name)
	-- 	self._curPetName = (self._petData.name and not string.isempty(self._petData.name)) and self._petData.name or petRefName
	-- 	self._isInitHeroName = not self._petData.name or string.isempty(self._petData.name) or self._petData.name == petRefName
	-- 	self._petRefName =  petRefName
	-- 	self:SetNameInputStr(nil,ccClientText(37998))
	-- else
		self._isInitHeroName = gModelHeroExtra:IsInitHeroNameByServerData(self._heroData)
	-- end
end
------------------------- List -------------------------


function UISagaResetName:GetNeedItemList()
	local list = {}
	return list
end


function UISagaResetName:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mResetBtnRoot,function() self:OnClickResetBtnRootFunc() end)
    self:SetWndClick(self.mResetBtn,function() self:OnClickResetBtnFunc() end)
    self:SetWndClick(self.mEnterBtnRoot,function() self:OnClickEnterBtnRootFunc() end)
    self:SetWndClick(self.mEnterBtn,function() self:OnClickEnterBtnFunc() end)
end

function UISagaResetName:OnClickResetBtnFunc()
	if self._isInitHeroName then
		GF.ShowMessage(ccClientText(36712))
		return end
	if self._sendMsg then return end
	local heroData = self._heroData
	-- local petData = self._petData
	if not heroData then return end

	--self:InitNameInputStr()
	local configName =self:GetConfigName()
	if string.isempty(configName) then
		if LOG_INFO_ENABLED then
			printInfoNR("配置名为空 refId = " .. heroData.refId)
		end
		return
	end
	self._resetStatus = true
	self:SendHeroSetNameReq("")
end

function UISagaResetName:InitNeedItemList()
    local list = self:GetNeedItemList()
    local uiNeedItemList = self._uiNeedItemList
    if uiNeedItemList then
        uiNeedItemList:RefreshList(list)
    else
        uiNeedItemList = self:GetUIScroll("uiNeedItemList")
        self._uiNeedItemList = uiNeedItemList
        uiNeedItemList:Create(self.mNeedItemList,list,function(...) self:OnDrawNeedItemCell(...) end)
    end
end

------------------------- List -------------------------


--重连
function UISagaResetName:OnTcpReconnect()
	self._sendMsg = false
end

function UISagaResetName:OnDrawNeedItemCell(list,item,itemdata,itempos)
    local IconDivTrans = self:FindWndTrans(item,"IconDiv")
    local IconTrans = self:FindWndTrans(IconDivTrans,"Icon")
    local NumTrans = self:FindWndTrans(item,"Num")
	local itemId = itemdata.itemId
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(IconTrans,icon,function()
		CS.ShowObject(IconDivTrans,true)
	end,true)
	local haveNum = gModelItem:GetNumByRefId(itemId)

	local itemNum = itemdata.itemNum
	local isEnough = haveNum >= itemNum
	local color = isEnough and "green" or "red"
	local numStr = LUtil.FormatColorStr(itemNum,color)
	self:SetWndText(NumTrans,numStr)
end

function UISagaResetName:CheckInputStr()
	local heroData = self._heroData
	-- 【C宠物系统】删掉宠物系统相关
	-- local petData = self._petData
	if not heroData then return end

	local nameText = self.mNameInput.text
	if string.isempty(nameText) then
		GF.ShowMessage(ccClientText(36707))
		return
	end

	nameText = string.gsub(nameText,"\r","")
	nameText = string.gsub(nameText,"\n","")

	if not gLGameLanguage:IsForeignVersion() then
		local bool = string.find(nameText, " ")
		if bool then
			GF.ShowMessage(ccClientText(10409))
			return
		end
	end

	local curHeroName = gModelHeroExtra:GetHeroSetName(heroData)
	if heroData then
		curHeroName = gModelHeroExtra:GetHeroSetName(heroData)
	-- 【C宠物系统】删掉宠物系统相关
	-- elseif(self._petData)then
	-- 	curHeroName = self._curPetName
	end
	if curHeroName == nameText then
		GF.ShowMessage(ccClientText(36704))
		return
	end

	local length = LxUtf8.cnLen(nameText)
	if length > self._nameNum then
		GF.ShowMessage(ccClientText(36705))
		return
	end

	local configName =self:GetConfigName()
	if nameText == configName then
		self:SendHeroSetNameReq("")
		return
	end

	local func = function(isMatch,newText)
		if self:IsWndClosed() then return end
		if isMatch then
			self:SetNameInputStr(newText)
			GF.ShowMessage(ccClientText(36706))
			return
		end

		self:SendHeroSetNameReq(newText)
	end

	LWordMaskUtil.ClearShieldWordEx(nameText,false,false,LGameWordMask.SCENE_TYPE_PUBLIC_DATA,func)
end

function UISagaResetName:InitMsg()
	 self:WndNetMsgRecv(LProtoIds.HeroSetNameResp,function(pb) self:OnHeroSetNameResp(pb) end)
	-- 【C宠物系统】删掉宠物系统相关
	--  self:WndNetMsgRecv(LProtoIds.PetSetNameResp,function(pb) self:OnPetSetNameResp(pb) end)

	self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList)
		self._sendMsg = false
	end)

	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end
------------------------------------------------------------------
return UISagaResetName



