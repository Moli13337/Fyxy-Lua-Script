---
--- Created by BY.
--- DateTime: 2023/10/9 15:46:31
---
------------------------------------------------------------------
local LxUtf8 = LXFW.LxUtf8
local LWnd = LWnd
---@class UIBulletSaySendPop:LWnd
local UIBulletSaySendPop = LxWndClass("UIBulletSaySendPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBulletSaySendPop:UIBulletSaySendPop()
	self._barrageTweenTimeKey = "barrageTweenTimeKey"
	self._barrageTweenKey = "barrageTweenKey"
	self._barrageTextList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBulletSaySendPop:OnWndClose()
	self:TweenSeqKill(self._barrageTweenKey)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBulletSaySendPop:OnCreate()
	LWnd.OnCreate(self)
	self._oldStr = ""
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBulletSaySendPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	self:DisableInputText(self.mDesInput)
end

function UIBulletSaySendPop:OnClickSend()
	local functionOpenId = self._sendFunctionOpen[self._currChannel]
	if functionOpenId and not gModelFunctionOpen:CheckIsOpened(functionOpenId,true) then
		return
	end

	if(not self._isBarrageShow)then
	    GF.ShowMessage(ccClientText(17608))
	    return
	end
	local msg = self.mDesInput.text
	local len = LxUtf8.cnLen(msg)
	local maxLen = gModelChat:GetChatConfigRefByKey("textLength")
	if(len > maxLen)then
		GF.ShowMessage(ccClientText(17603))
		--self.mDesInput.text = LxUtf8.sub(msg,1,len)
		self:SetWndTextInput(self.mDesInput, LxUtf8.sub(msg,1,len))
		return
	elseif(msg == "")then
		GF.ShowMessage(ccClientText(17604))
		return
	end
	gModelChat:OnChatMsgReq(self._currChannel,1,msg)
end

--选择表情
function UIBulletSaySendPop:OnClickFace(faceinstead)
	--self.mDesInput.text = self.mDesInput.text..faceinstead
	self:SetWndTextInput(self.mDesInput, self.mDesInput.text..faceinstead)
end

function UIBulletSaySendPop:OnTimer(key)
	if(self._barrageTweenTimeKey == key)then
		self:SetTween()
	end
end

function UIBulletSaySendPop:SiftListItem(list, item, itemdata, itempos)
	local root = CS.FindTrans(item,"Root")
	local text = CS.FindTrans(root,"Mask/UIText")
	local msg = ccLngText(itemdata.text)
	local InstanceID = item:GetInstanceID()
	text.anchoredPosition = Vector2.New(5,0)
	self._barrageTextList[InstanceID] = text
	self:SetWndText(text,LUtil.GetFaceStr(msg,-1))
	self:SetWndClick(root,function ()
		local list = LUtil.GetRichTexts(msg)
		local msgStr = ""
		for i, v in ipairs(list) do
			msgStr = msgStr .. v.cap2
		end
		gModelChat:OnChatMsgReq(self._currChannel,1,msgStr)
	end)
end

function UIBulletSaySendPop:OnClickBarrageList()
	GF.OpenWnd("UIBulletSayListPop",{channel = self._currChannel})
end

function UIBulletSaySendPop:OnClickBFaceMask()
	self._isFace = not self._isFace
	CS.ShowObject(self.mFaceMask,self._isFace)
	if(self._isFace)then
		self:OnInitList()
	end
end

function UIBulletSaySendPop:OnClickBarrage()
	self._isBarrageShow = not self._isBarrageShow
	CS.ShowObject(self.mBarrageMask,not self._isBarrageShow)
	local msg = self._isBarrageShow and ccClientText(17619) or ccClientText(17620)
	GF.ShowMessage(msg)
	FireEvent(EventNames.ON_CHAT_BARRAGE_WIN,true)
end

function UIBulletSaySendPop:SetTween()
	local seqTween
	self:TweenSeqKill(self._barrageTweenKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._barrageTweenKey,function(seq)

			for i, v in pairs(self._barrageTextList) do
				if v then
					local uiText = LxUiHelper.FindXTextCtrl(v)
					if uiText.preferredWidth > 136 then
						local tweener = v.transform:DOLocalMove(Vector3.New(- v.rect.width - 100,0,0),3)
						seq:Join(tweener)
					end
				end
			end

			seq:AppendCallback(function()
				for i, v in pairs(self._barrageTextList) do
					if v then
						v.anchoredPosition = Vector2.New(5,0)
					end
				end
			end)
			seq:AppendInterval(1)
			return seq
		end)
	end
	seqTween:SetLoops(-1)
	seqTween:PlayForward()
	--seqTween:OnComplete(function()
	--	self:TweenSeqKill(self._barrageTweenKey)
	--end)
end

function UIBulletSaySendPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mFaceBtn, function(...) self:OnClickBFaceMask() end)
	self:SetWndClick(self.mFaceMask, function(...) self:OnClickBFaceMask() end)
	self:SetWndClick(self.mSendBtn, function(...) self:OnClickSend() end)
	self:SetWndClick(self.mBarrageBtn,function (...) self:OnClickBarrage() end)
	self:SetWndClick(self.mBtnMsgList,function (...) self:OnClickBarrageList() end)
	self:SetWndClick(self.mBtnSift,function (...) self:OnClickSift() end)
	self:SetWndClick(self.mSiftMask,function () CS.ShowObject(self.mSiftMask,false) end)
end

function UIBulletSaySendPop:OnInputDes(str)
	local len = LxUtf8.cnLen(str)
	local maxLen = gModelChat:GetChatConfigRefByKey("textLength")
	if(len > maxLen)then
		str = self._oldStr
		--self.mDesInput.text = str
		self:SetWndTextInput(self.mDesInput, str)
		len = LxUtf8.cnLen(str)
		GF.ShowMessage(ccClientText(17603))
	else
		self._oldStr = str
	end
	--激活聊天框不选中所有内容
	self.mDesInput.onFocusSelectAll = false
end

function UIBulletSaySendPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ChatMsgResp,function (pb)
		GF.ShowMessage(ccClientText(17607))
		self:WndClose()
	end)
	self:SetInputValueChange(self.mDesInput,function (str)
		self:OnInputDes(str)
	end)
	self:WndEventRecv(EventNames.SENSITIVE_REGULATE,function ()
		local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_1)
		if not sensitive then
			GF.ShowMessage(ccClientText(30800))
			self:WndClose()
			return
		end
	end)
end

function UIBulletSaySendPop:OnClickSift()
	CS.ShowObject(self.mSiftMask,true)
	local list1 = gModelChat:GetChatBarrageRefByType(1)
	local list2 = gModelChat:GetChatBarrageRefByType(2)

	local _uiList1 = self._uiList1
	if _uiList1 then
		_uiList1:RefreshList(list1)
	else
		_uiList1 = self:GetUIScroll("sift1List")
		_uiList1:Create(self.mSift1Scroll,list1,function (...) self:SiftListItem(...) end,UIItemList.WRAP)
	end

	local _uiList2 = self._uiList2
	if _uiList2 then
		_uiList2:RefreshList(list2)
	else
		_uiList2 = self:GetUIScroll("sift2List")
		_uiList2:Create(self.mSift2Scroll,list2,function (...) self:SiftListItem(...) end,UIItemList.WRAP)
	end
	self:TweenSeqKill(self._barrageTweenKey)
	self:TimerStop(self._barrageTweenTimeKey)
	self:TimerStart(self._barrageTweenTimeKey,1,false,1)
end

function UIBulletSaySendPop:FaceListItem(list, item, itemdata, itempos)
	local imageTran=CS.FindTrans(item,"Image")
	self:SetWndEasyImage(imageTran,itemdata.faceIcon)
	self:SetWndClick(imageTran, function (...) self:OnClickFace(itemdata.faceinstead) end)
end

function UIBulletSaySendPop:OnInitList()
	local list = gModelChat:GetEmojiByType(1)--弹幕只有小表情
	if(self._uiFaceList)then
		self._uiFaceList:RefreshData(list)
	else
		self._uiFaceList = self:GetUIScroll("_uiFaceList")
		self._uiFaceList:Create(self.mFaceScroll,list,function (...) self:FaceListItem(...) end,UIItemList.WRAP)
	end
end

function UIBulletSaySendPop:SetRolePaint(figure)
	self:CreateWndSpine(self.mSpine,figure,"spineKey",false,function(dpSpine)
		--local dpTrans =dpSpine:GetDisplayTrans()
		--dpSpine:PlayAnimationSolid("idle",true)
		dpSpine:SetScale(1.5)
	end)
end

function UIBulletSaySendPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(17600))
	self:SetWndButtonText(self.mSendBtn,ccClientText(17602))
	self:SetWndText(self.mBarrageText,ccClientText(10146))
	--self:SetWndText(self.mDesInput.placeholder,ccClientText(17610))
	self:SetWndTextInput(self.mDesInput, nil, ccClientText(17610))
	self:SetWndText(self.mMsgListText,ccClientText(17611))
	self:SetWndText(self.mSiftText,ccClientText(17612))
	self:SetWndText(self.mSift1Text,ccClientText(17613))
	self:SetWndText(self.mSift2Text,ccClientText(17614))
	self._currChannel = self:GetWndArg("channel") or ModelChat.CHANNEL_RISK
	local _currChannel = self._currChannel
	self._isBarrageShow = self:GetWndArg("isShow") or false
	self._isFace = true
	CS.ShowObject(self.mBarrageMask,not self._isBarrageShow)
	self:OnClickBFaceMask()
    self.mDesInput.characterLimit =  gModelChat:GetCharacterLimit(_currChannel)
	self._sendFunctionOpen = {
		[ModelChat.CHANNEL_PEAK] = 11720010,
		--[ModelChat.CHANNEL_RISK] = 11721010,
		[ModelChat.CHANNEL_WAR] = 11722010,
		[ModelChat.CHANNEL_CHAMPION] = 11723010,
	}

	local ref = gModelChat:GetChatChannelRefByChannelId(_currChannel)
	self:SetRolePaint(ref.roleSpine)
	self:SetWndText(self.mBubbleText,ccLngText(ref.text))
end
------------------------------------------------------------------
return UIBulletSaySendPop


