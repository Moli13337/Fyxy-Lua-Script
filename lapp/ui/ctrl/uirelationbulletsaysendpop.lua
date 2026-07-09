---
--- Created by Administrator.
--- DateTime: 2023/10/10 21:12:07
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIRelationBulletSaySendPop:LWnd
local UIRelationBulletSaySendPop = LxWndClass("UIRelationBulletSaySendPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRelationBulletSaySendPop:UIRelationBulletSaySendPop()
	self._oldStr = ""
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRelationBulletSaySendPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRelationBulletSaySendPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRelationBulletSaySendPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitInputEvent()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:SetLenTxt()

	self:DisableInputText(self.mDesInput)
end

function UIRelationBulletSaySendPop:InitMsg()
	self:WndNetMsgRecv(LProtoIds.RelationForCommentResp,function()
		self:CloseSend(1)
		self:WndClose()
	end)
end


function UIRelationBulletSaySendPop:InitInputEvent()
	self.mDesInput.onValueChanged:AddListener(function (str)
		--local msg = gModelHeroBook:DisposeText(str)
		--self:OnInputDes(msg)

		self:OnInputComment(str)
	end)
end

function UIRelationBulletSaySendPop:ShowFaceDiv(show)
	CS.ShowObject(self.mFaceMask,show)
	if show then
		self:InitFaceList()
	end
end

function UIRelationBulletSaySendPop:CloseSend(sendMsg)
	sendMsg = sendMsg or 0

	local haveHero = gModelHeroBook:GetHeroRelationActNum(self._relationRefId)
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"羁绊评论close",self._relationRefId,haveHero,sendMsg)
end

function UIRelationBulletSaySendPop:InitEvent()
	self:SetWndClick(self.mMask,function()
		self:CloseSend()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function()
		self:CloseSend()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mSendBtn,function()
		self:SendMsg()
	end)
	self:SetWndClick(self.mBarrageBtn,function()
		self._showBarrage = not self._showBarrage
		if self._showBarrage then
			-- 打开弹幕
		end
		CS.ShowObject(self.mBarrageMask,not self._showBarrage)
	end)
	self:SetWndClick(self.mFaceBtn,function() self:ShowFaceDiv(true) end)
	self:SetWndClick(self.mFaceMask,function() self:ShowFaceDiv(false) end)
end

function UIRelationBulletSaySendPop:OnInputDes(str)
	local len = LxUtf8.cnLen(str)
	local maxLen = self._heroCommentMesLong
	if len > maxLen then
		str = self._oldStr
		--self.mDesInput.text = str
		self:SetWndTextInput(self.mDesInput,  str)
		len = LxUtf8.cnLen(str)
		GF.ShowMessage(ccClientText(17603))
	else
		self._oldStr = str
	end
	self:SetLenTxt(len)
	--激活聊天框不选中所有内容
	self.mDesInput.onFocusSelectAll = false
end

function UIRelationBulletSaySendPop:InitData()
	self._relationRefId = self:GetWndArg("relationRefId")
	local heroCommentMesLong = gModelHero:GeConfigByKey("heroCommentMesLong")
	self._heroCommentMesLong = heroCommentMesLong * 2
	self._showBarrage = gModelHeroBook:GetRelationBarrageShow()
	CS.ShowObject(self.mBarrageMask,not self._showBarrage)

	local str = string.replace(ccClientText(19750),heroCommentMesLong)
	--self:SetWndText(self.mDesInput.placeholder,str)
	self:SetWndTextInput(self.mDesInput, nil, str)
end

function UIRelationBulletSaySendPop:OnInputComment(str)
	local msg = LUtil.FilterEmoji(str,"?")

	local func = function(isMatch,newText)
		if self:IsWndClosed() then
			return
		end
		local finalText = LUtil.ChatInfoFaceBinToDec(newText)
		self:OnInputDes(finalText)
	end

	LWordMaskUtil.ClearShieldWordEx(msg,false,true,LGameWordMask.SCENE_TYPE_PUBLIC_DATA,func)
	--msg = LWordMaskUtil.ClearShieldWord(msg,false,nil,true)
	--msg = LUtil.ChatInfoFaceBinToDec(msg)
	--self:OnInputDes(msg)
end

function UIRelationBulletSaySendPop:SetLenTxt(curLen)
	local maxLen = self._heroCommentMesLong / 2
	curLen = curLen or 0
	curLen = math.floor(curLen/2)
	local lenStr = string.replace(ccClientText(19713),curLen,maxLen)
	self:SetWndText(self.mLenText,lenStr)
end

function UIRelationBulletSaySendPop:OnDrawFaceCell(list,item,itemdata,itempos)
	local imageTran = CS.FindTrans(item,"Image")
	self:SetWndEasyImage(imageTran,itemdata.faceIcon)
	self:SetWndClick(item, function(...) self:OnClickFace(itemdata.faceinstead) end)
end

function UIRelationBulletSaySendPop:InitFaceList()
	--弹幕只有小表情
	local list = gModelChat:GetEmojiByType(1)
	local uiFaceList = self._uiFaceList
	if uiFaceList then
		uiFaceList:RefreshData(list)
	else
		uiFaceList = self:GetUIScroll("uiFaceList")
		self._uiFaceList = uiFaceList
		uiFaceList:Create(self.mFaceScroll,list,function(...) self:OnDrawFaceCell(...) end,UIItemList.WRAP)
	end
end

function UIRelationBulletSaySendPop:SendMsg()
	local openRefId = gModelHero:GeConfigByKey("heroBookCommentNeedLv")
	local isCommon = gModelHeroBook:GetCommontFuncOpenStatus(openRefId)
	if not isCommon then return end
	local msg = self.mDesInput.text
	local len = LxUtf8.cnLen(msg)
	local maxLen = gModelHero:GeConfigByKey("heroCommentMesLong")
	maxLen = maxLen * 2
	if(len > maxLen)then
		GF.ShowMessage(ccClientText(17603))
		--self.mDesInput.text = LxUtf8.sub(msg,1,len)
		self:SetWndTextInput(self.mDesInput, LxUtf8.sub(msg,1,len))
		return
	elseif(msg == "")then
		GF.ShowMessage(ccClientText(19760))
		return
	end
	local refId = self._relationRefId
	if not refId then return end
	gModelHeroBook:OnRelationForCommentReq(refId,msg)
end

--选择表情
function UIRelationBulletSaySendPop:OnClickFace(faceinstead)
	--self.mDesInput.text = self.mDesInput.text..faceinstead
	self:SetWndTextInput(self.mDesInput,  self.mDesInput.text..faceinstead)
end

function UIRelationBulletSaySendPop:InitText()
	self:SetWndButtonText(self.mSendBtn,ccClientText(19728))
	self:SetWndText(self.mTitleText,ccClientText(19751))
end
------------------------------------------------------------------
return UIRelationBulletSaySendPop


