---
--- Created by Administrator.
--- DateTime: 2023/10/10 21:21:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIInvasionSay:LWnd
local UIInvasionSay = LxWndClass("UIInvasionSay", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIInvasionSay:UIInvasionSay()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIInvasionSay:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIInvasionSay:OnCreate()
	LWnd.OnCreate(self)

    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIInvasionSay:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
    self._currChannel = self:GetWndArg("channel") or ModelChat.CHANNEL_INVASION

    self:SetStaticContent()
    self:InitUIEvent()
    self:InitEvent()

    self:DisableInputText(self.mInput)
end

function UIInvasionSay:InitEvent()
    self:WndNetMsgRecv(LProtoIds.ChatMsgPushResp,function ()
        self:RefreshChatContent()
    end)
    self:WndEventRecv(EventNames.SENSITIVE_REGULATE,function ()
        local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_1)
        if sensitive then return end
        if self._currChannel == ModelChat.CHANNEL_INVASION then
            GF.ShowMessage(ccClientText(30800))
            self:WndClose()
            return
        end
    end)
end



function UIInvasionSay:OnClickSend()
    self._isLongClisk=false
    local cmd = self.mInput.text
    local type = ModelChat.MSGTYPE_NORMAL
    self:SendChatMsg(cmd,type)
end



function UIInvasionSay:RefreshChatContent()

    if not self._isContentShow then
        return
    end

	local infoList= gModelChat:GetTypeInfo(self._currChannel)
    local uiList = nil

    local uiItemList = self._uiInfoList
    if not uiItemList then
        uiItemList = self:GetUIScroll("uiInfoList")
        self._uiInfoList = uiItemList
        self._uiInfoList:Create(self.mInfoScroll,infoList,function (...) self:OnDrawChatItem(...) end, UIItemList.SUPER)
        uiList = self._uiInfoList:GetList()
        uiList:SetReversePos(true)
    else
        uiItemList:RefreshList(infoList)
        uiList = uiItemList:GetList()
    end

    local lastIndex = #infoList
    uiList:MoveToPos(lastIndex)

end

function UIInvasionSay:OnInputChange(str)
    local len = LxUtf8.cc_len(str)

    local maxLen = gModelChat:GetCharacterLimit(self._currChannel)
    if(len > maxLen)then
        --self.mInput.text = self._curStr
        self:SetWndTextInput(self.mInput,self._curStr)
        GF.ShowMessage(ccClientText(17603))
    else
        self._curStr = str
    end
    --激活聊天框不选中所有内容
    self.mInput.onFocusSelectAll = false
end


function UIInvasionSay:CheckHideFacePart(trans)
    if not self._isFacePartShow then
        return
    end

    if trans == self.mAddBtn then
        return
    end

    local path = LxUiHelper.GetRelativePath(self:GetWndName(),trans)
    if string.find(path,"facePart") then
        return
    end

    self:ShowFacePart(false)
end

function UIInvasionSay:SetStaticContent()
    self:SetWndButtonText(self.mSendBtn,ccClientText(12433))
    self.mInput.characterLimit =  gModelChat:GetCharacterLimit(self._currChannel)
    --local text = CS.FindTrans(self.mInput,"Text Area/Placeholder")
    --self:SetWndText(text,ccClientText(11133))
    self:SetWndTextInput(self.mInput,nil, ccClientText(11133))
    self.mInput.onFocusSelectAll = false
end

function UIInvasionSay:OnDrawChatItem(list,item, itemdata, itempos)
	if not itemdata then
		return
	end

	local meParent = self:FindWndTrans(item,"Me")
	local otherParent = self:FindWndTrans(item,"Other")
	local systemParent=self:FindWndTrans(item,"System")
	CS.ShowObject(meParent,false)
	CS.ShowObject(otherParent,false)
	CS.ShowObject(systemParent,false)

	local parent,head,textTran,infoText,chatBg,EmojiImage

	local msg = itemdata:GetMsg() or ""
	local playerName = itemdata.playerName

	if itemdata.isMe then--我
		parent=meParent
		infoText=self:FindWndTrans(parent,"NameText")
		chatBg=self:FindWndTrans(parent,"ChatBg")
		textTran=self:FindWndTrans(parent,"ChatBg/XUIText")
		head = self:FindWndTrans(parent,"HeadIcon")

		self:SetWndClick(head.gameObject,function()
			GF.OpenWnd("UIChaePop",{startType = ModelPlayerSpace.ROLE_HEAD})
		end)
	else --其他人
		parent=otherParent
		infoText=self:FindWndTrans(parent,"NameText")
		chatBg=self:FindWndTrans(parent,"ChatBg")
		textTran=self:FindWndTrans(parent,"ChatBg/XUIText")
		head = self:FindWndTrans(parent,"HeadIcon")

		self:SetWndClick(head.gameObject,function()
			self:OnClickHead(itemdata)
		end)
		-- 长按
		--self:SetWndLongClick(head,function()
		--	self:OnLongClickHead(itemdata)
		--end,0.8,false)
	end

	local color = itemdata.sex == 1 and "blue" or "purple"
	local nameStr = LUtil.FormatColorStr(playerName,color)
	self:SetWndText(infoText,nameStr)
	local rateIcon = self:FindWndTrans(infoText,"RateIcon")
	local vipIcon = self:FindWndTrans(infoText,"VipIcon")
	CS.ShowObject(rateIcon,false)
	CS.ShowObject(vipIcon,false)
	local title = itemdata.title
	if(title and title > 0)then

		local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(title)
		if ref then
			self:SetWndEasyImage(rateIcon,ref.icon,function()
				CS.ShowObject(rateIcon,true)
			end ,true)
			self:SetWndClick(rateIcon,function ()
				gModelPlayerSpace:OnPersonaliseOtherInfoReq(itemdata.playerName,itemdata.playerId,title)
			end)
		else
			self:SetWndClick(rateIcon,function ()
			end)
		end
	end

	CS.ShowObject(parent,true)
	head=self:FindWndTrans(parent,"HeadIcon")

	EmojiImage=self:FindWndTrans(parent,"EmojiImage")

	local InstanceID = item:GetInstanceID()
	local playerLevel = itemdata.level;
	local playerInfo={
		trans=head,
		icon=itemdata.head,
		headFrame = itemdata.headFrame,
		playerId=itemdata.playerId,
		NoClick=true,
		level = playerLevel,
		noLv= playerLevel == 0,
	}
	local baseClass = self:GetHeadIcon(InstanceID)
	baseClass:SetHeadData(playerInfo)
	baseClass:RefreshUI()

	msg=self:FormatAtPlayerName(msg,itemdata.atPlayerName)
	local faceId= LUtil.ChatInfoGetDaFace(msg)
	if(faceId and faceId~=0)then
		CS.ShowObject(chatBg,false)
		local icon= gModelChat:GetDaEmoji(faceId)
		self:SetWndEasyImage(EmojiImage,icon,function ()
			CS.ShowObject(EmojiImage,true)
		end,true)

		LxUiHelper.SetSizeWithCurAnchor(item,1,130)
	else
		msg= LUtil.GetFaceStr(msg,46)
		CS.ShowObject(EmojiImage,false)
		CS.ShowObject(chatBg,true)
		self:SetChatHeight(msg,chatBg,item)

		self:SetWndText(textTran,msg)
	end

end

function UIInvasionSay:AppendStr(str)
    local curStr = self._curStr or ""
    curStr = curStr..str

    self:SetInputStr(curStr)
end

function UIInvasionSay:SetChatHeight(msg, chatBg,item)
    self:SetWndText(self.mTestText,msg)
    self:SetWndText(self.mTestText2,msg)
    local width = self.mTestText.preferredWidth
    if(width>338)then
        width=338
    end
    chatBg.sizeDelta = Vector2.New(width + 38,chatBg.rect.height)
    local height = self.mTestText2.preferredHeight
    local c = 0
    if(height<30)then
        c = 15
    end

    height=66+ height + c

    LxUiHelper.SetSizeWithCurAnchor(item,1,height)
end


function UIInvasionSay:ShowChatContent(isShow)
    self._isContentShow = isShow

    CS.ShowObject(self.mMiddle,isShow)
    if isShow then
        self:RefreshChatContent()
    end

    local sizeDelta = nil
    if isShow then
        sizeDelta = Vector2.New(543,576)
    else
        sizeDelta = Vector2.New(543,75)
    end
    self.mChatFrame.sizeDelta = sizeDelta

    local rotation = nil
    if isShow then
        rotation = Quaternion.Euler(0,0,270)
    else
        rotation = Quaternion.Euler(0,0,90)
    end

    self.mArrowIcon.localRotation = rotation
end

function UIInvasionSay:SendChatMsg(cmd,type)
    if not type then
        type = ModelChat.MSGTYPE_NORMAL
    end
    local bool = gModelChat:GetIfSend(self._currChannel,cmd)
    if(bool == false ) then
        return
    else
        local info= gModelChat:GetChatRestrict(cmd)
        if(info.bool)then
            self:SetInputStr(info.str)
            CS.ShowObject(self.mText_Area,false)
            CS.ShowObject(self.mText_Area,true)
            return
        end
    end


    gModelChat:OnChatMsgReq(self._currChannel,type,cmd)
    self:SetInputStr("")
    CS.ShowObject(self.mText_Area,false)
    CS.ShowObject(self.mText_Area,true)
    local caret = self:FindWndTrans(self.mText_Area,"Caret")
    local text = self:FindWndTrans(self.mText_Area,"Text")
    caret.anchoredPosition = Vector2.New(0,0)
    text.anchoredPosition = Vector2.New(0,0)
    self._targetInfo=nil
end

function UIInvasionSay:ShowFacePart(isShow)
    self._isFacePartShow = isShow
    CS.ShowObject(self.mFacePart,isShow)
    local emojiList = self._uiEmojiList
    if not emojiList then
        local dataList=gModelChat:GetEmojiByType(1)

        emojiList = self:GetUIScroll("emojiList")
        self._uiEmojiList = emojiList
        emojiList:Create(self.mEmojiList,dataList,function (...) self:OnDrawEmojiItem(...) end,UIItemList.SUPER_GRID)
    end
end


--function UIInvasionSay:OnLongClickHead(itemdata)
--	if itemdata.playerId == "-1" or itemdata.playerId == gModelPlayer:GetPlayerId() then
--		return
--	end
--	self._isLongClisk=true
--	local str = string.format("@%s  ",itemdata.playerName)
--	self:SetInputStr(str)
--
--	self._targetInfo=itemdata
--end

function UIInvasionSay:SetInputStr(str)
    --self.mInput.text = str
    self:SetWndTextInput(self.mInput,str)
end

function UIInvasionSay:OnClickHead(itemdata)
	if(self._isLongClisk)then
		self._isLongClisk=false
		return
	end
	if(not itemdata.playerId or itemdata.playerId=="")then
		return
	end
	local playerId = gModelPlayer:GetPlayerId()
	if(itemdata.playerId==playerId )then
		GF.ShowMessage(ccClientText(11522))
		return
	end

	if(itemdata.playerId == "-1")then
		GF.ShowMessage(ccClientText(11122))
		return
	end
	gModelGeneral:PlayerShowReq(itemdata.playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM,itemdata.channel,itemdata.number or 1)
end

function UIInvasionSay:FormatAtPlayerName(msg,name)
    local str = msg
    local text =string.match(msg,"%@"..name)
    if(text)then
        str= string.gsub(str,text,"<u>"..text.."</u>",1)
    end
    return str
end

function UIInvasionSay:OnDrawEmojiItem(list,item,itemdata,itempos)
    local imageTran=CS.FindTrans(item,"Image")
    self:SetWndEasyImage(imageTran,itemdata.faceIcon)
    self:SetWndClick(item, function (...) self:AppendStr(itemdata.faceinstead) end)
end

function UIInvasionSay:InitUIEvent()
    self:SetWndClick(self.mSendBtn,function ()
        self:OnClickSend()
    end)
    self:SetWndClick(self.mArrow,function ()
        local isShow = not self._isContentShow
        self:ShowChatContent(isShow)
    end)

    self:SetWndClick(self.mAddBtn,function ()

        local isShow = not self._isFacePartShow
        self:ShowFacePart(isShow)
    end)

    self:SetWndClick(self.mMask,function ()
        self:WndClose()
    end)

    self:SetInputValueChange(self.mInput,function (value)
        self:OnInputChange(value)
    end)

    self:WndEventRecv(EventNames.ON_CLICK_BUTTON,function (trans)
        self:CheckHideFacePart(trans)
    end)

end

------------------------------------------------------------------
return UIInvasionSay


