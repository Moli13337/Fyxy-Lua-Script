---
--- Created by BY.
--- DateTime: 2023/10/18 10:57:34
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDTDLuckPop:LWnd
local UIDTDLuckPop = LxWndClass("UIDTDLuckPop", LWnd)

local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDTDLuckPop:UIDTDLuckPop()
	self._page = 0
	self._pageNumber = 25
	self._uiheadList = {}
	self._sortBtns = {}
	self._sortIndex = 1
	self._btnLikeList = {}
	self._playEffKey = "_playEffKey"
	self._TextIconTweenKey = "_TextIconTweenKey" --
	self._ImgIconTweenKey = "_ImgIconTweenKey" --
	self._luckEffKey = "_luckEffKey"
	self._bottomTweenKey = "_bottomTweenKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDTDLuckPop:OnWndClose()
	self:TweenSeqKill(self._TextIconTweenKey)
	self:TweenSeqKill(self._ImgIconTweenKey)
	self:ClearCommonIconList(self._uiheadList)
	GF.CloseWndByName("UILuckBulletSay")
	gModelGeneral:IsTriggerRewardPop()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDTDLuckPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDTDLuckPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()

	gModelWndPop:RemovePopWnd("UIDTDLuckPop")

end

function UIDTDLuckPop:RefreshSortText()
	local _sortIndex = self._sortIndex
	local str = _sortIndex == 2 and ccClientText(23116) or ccClientText(23117)
	self:SetWndText(self.mSortText,str)
end

function UIDTDLuckPop:OnTimer(key)
	if(self._luckEffKey == key)then
		if self.isLuckEnd and self._luckRefId>0 then
			self:SetImgIconTween()
		end
		self.isLuckEnd = true
	end
end

function UIDTDLuckPop:OnClickOpentSort()
	self:OnCutBtnSortStatus()
	if not self._isOpent then
		return
	end
	local _sortIndex = self._sortIndex
	local _sortBtns = self._sortBtns
	for i, v in ipairs(_sortBtns) do
		local selImg = self:FindWndTrans(v,"SelImg")
		local text = self:FindWndTrans(v,"UIText")
		CS.ShowObject(selImg,i == _sortIndex)
		local str = i == 2 and ccClientText(23116) or ccClientText(23117)
		str = LUtil.FormatColorStr(str,i == _sortIndex and "white" or "yellow_2")
		self:SetWndText(text,str)
	end
end

function UIDTDLuckPop:SetRoleTween()
	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq("Role")
	local tweener = self.mRoleMag:DOLocalMove(Vector2.New(0,0),0.3)
	seq:Join(tweener)
	seq:OnComplete(function ()
		self:OnClickBuzz()
	end)
	seq:PlayForward()
end

--function UIDTDLuckPop:InitLuck()
--	local _spaceInfo = gModelOneNight:GetSpaceInfoPB()
--	local isLuck = _spaceInfo.luck > 0
--	self._isLuck = isLuck		--是否有占卜过
--	self._luckRefId = _spaceInfo.luck or 0
--	self._luckTextRefId = _spaceInfo.luckText or 0
--	if isLuck then
--		self:ReqNewPage()
--	end
--	self:RefreshData(true)
--	self:RefreshSortText()
--	self:InitSpine()
--	if not isLuck then
--		self:SetTextIconTween()
--	end
--end

function UIDTDLuckPop:InitSpine()
	self:CreateWndSpine(self.mRoleImg,"meiriyunshi","meiriyunshi",false,function(dpSpine)
		local dpTrans = dpSpine:GetDisplayTrans()
		dpTrans.anchorMin = Vector2.New(0.5,0.5)
		dpTrans.anchorMax = Vector2.New(0.5,0.5)
		self:SetRunSpineAin(false)
	end)
end

function UIDTDLuckPop:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIDTDLuckPop:SetRunSpineAin(bool)
	local dpSpine = self:FindWndSpineByKey("meiriyunshi")
	if not dpSpine:IsDpValid() then return  end
	self:DestroyWndEffectByKey("fx_ui_meiriyunshi_zhanbu")
	if bool then
		dpSpine:PlayAnimation(0,"click",false)
		self:CreateWndEffect(self.mRoleImg,"fx_ui_meiriyunshi_zhanbu_02","fx_ui_meiriyunshi_zhanbu",100)
	else
		dpSpine:PlayAnimation(0,"idle",true)
		self:CreateWndEffect(self.mRoleImg,"fx_ui_meiriyunshi_zhanbu_01","fx_ui_meiriyunshi_zhanbu",100)
	end
end

function UIDTDLuckPop:InitEvent()
	--self._screenHeight = self.mPop.rect.height
	self._bottomHeight = self.mBottom.rect.height
	self._bottomPosition = self.mBottom.localPosition

	self._sortBtns = { self.mSortList1,self.mSortList2 }
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnDivination, function(...) self:OnClickDivination() end)
	self:SetWndClick(self.mBtnSend, function(...) self:OnClickSend() end)
	self:SetWndClick(self.mBtnSendEn, function(...) self:OnClickSend() end)
	self:SetWndClick(self.mBtnSort, function(...) self:OnClickOpentSort() end)
	self:SetWndClick(self.mSortList1, function(...) self:OnClickSortBtn(1) end)
	self:SetWndClick(self.mSortList2, function(...) self:OnClickSortBtn(2) end)
	self:SetWndClick(self.mBtnBuzz, function(...) self:OnClickBuzz() end)
	self:SetWndClick(self.mBtnBuzzEn, function(...) self:OnClickBuzz() end)
end

function UIDTDLuckPop:SetHeadIcon(headIcon,info,InstanceID)
	local playerInfo={
		trans = headIcon,
		playerId = info._playerId,
		icon = info._head,
		headFrame = info._headFrame,
		level = info._grade,
	}
	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(playerInfo)
	self:SetWndClick(headIcon, function (...)
		gModelGeneral:PlayerShowReq(info._playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
	end)
end

function UIDTDLuckPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.SpaceInfoResp,function (...)
		if self._noInit then
			self:InitLuck()
		else
			self:RefreshData()
		end
	end)
	self:WndNetMsgRecv(LProtoIds.SpaceLuckResp,function (pb)
		gModelGeneral:SetIsStoragePop(true)
		--gModelOneNight:SpaceInfoReq(0)
		self._isLuck = true
		local luck = pb.luck
		local luckText = pb.luckText
		self._luckRefId = luck or 0
		self._luckTextRefId = luckText or 0
		if self.isLuckEnd and self._luckRefId > 0 then
			self:SetImgIconTween()
		end
		self.isLuckEnd = true
	end)
	self:WndNetMsgRecv(LProtoIds.SpaceLuckMessageListResp,function (pb)
		local messages = pb.messages
		local page = pb.page
		if page == 1 then
			self._msgList = {}
		end
		local _msgList = self._msgList or {}
		--for i, v in ipairs(messages) do
		--	local msg = gModelOneNight:GenerateStructSpaceVisitInfoFromPb(v)
		--	table.insert(_msgList,msg)
		--end
		self._msgList = _msgList
		if not GF.FindFirstWndByName("UILuckBulletSay") then
			gModelGeneral:OpenLuckBarrage({msgList = _msgList})
		end
		self:RefreshMsg()
	end)
	self:WndNetMsgRecv(LProtoIds.SpaceLuckMessageLikeResp,function (pb)
		local messages = pb.messages
		--local msg = gModelOneNight:GenerateStructSpaceVisitInfoFromPb(messages)
		--GF.ShowMessage(string.replace(ccClientText(23109),msg.info._name))
		--local list = {}
		--local _msgList = self._msgList or {}
		--for i, v in ipairs(_msgList) do
		--	local data = v
		--	if v.id == msg.id then
		--		data = msg
		--	end
		--	table.insert(list,data)
		--end
		--self._msgList = list
		--self:RefreshMsg(msg.id)
	end)
	self:WndNetMsgRecv(LProtoIds.SpaceLuckMessageResp,function (pb)
		--gModelOneNight:SpaceInfoReq(0)
		--local messages = pb.messages
		--local msg = gModelOneNight:GenerateStructSpaceVisitInfoFromPb(messages)
		--local list = {}
		--local _msgList = self._msgList or {}
		--table.insert(list,msg)
		--for i, v in ipairs(_msgList) do
		--	table.insert(list,v)
		--end
		--self._msgList = list
		--self:RefreshMsg()
	end)
	self:WndEventRecv(EventNames.ON_WND_CLOSE,function (wndName)
		if wndName == "UIAward"  then
			CS.ShowObject(self.mBtnMar,true)
			if self._luckTextRefId then
				local textRef = GameTable.OneNightDailyLuckTextRef[self._luckTextRefId]
				if not textRef then
					printInfoNR("GameTable.OneNightDailyLuckTextRef[luckTextRefId] is not find, luckTextRefId = "..self._luckTextRefId)
					return
				end
				self:SetWndText(self.mDivinationDesText,ccLngText(textRef.text))
			end
		end
	end)
end

function UIDTDLuckPop:OnCutBtnSortStatus()
	local _isOpent = self._isOpent
	_isOpent = not _isOpent
	CS.ShowObject(self.mSortList,_isOpent)
	self._isOpent = _isOpent
	self.mBtnSortIcon.localScale = Vector2.New(1,_isOpent and -1 or 1)
end
function UIDTDLuckPop:SetImgIconTween()
	local _mImgIcon = self.mImgIcon
	_mImgIcon.localScale = Vector3.zero
	CS.ShowObject(_mImgIcon,true)
	local ref = GameTable.OneNightDailyLuckRef[self._luckRefId]
	if ref then
		self:SetWndEasyImage(_mImgIcon,ref.typeIcon)
	else
		printErrorN(string.format("miss OneNightDailyLuckRef refId %s",self._luckRefId))
	end
	local seqTween
	local _compileTweenKey = self._ImgIconTweenKey
	self:TweenSeqKill(_compileTweenKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(_compileTweenKey,function(seq)
			local tween = _mImgIcon:DOScale(Vector3.one * 1.2,1.8)
			seq:Append(tween)
			local tween = _mImgIcon:DOScale(Vector3.one,0.3)
			seq:Append(tween)
			seq:AppendInterval(0.4)
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		_mImgIcon.localScale = Vector3.one
		self:SetRunSpineAin(false)
		self:RefreshData()
		gModelGeneral:IsTriggerRewardPop()
		local starNum = ref and ref.starNum or 0
		if starNum > 0 then
			CS.ShowObject(self.mStarMar,true)
			for i = 1, starNum do
				local star = self:FindWndTrans(self.mStarMar,"Star"..i)
				self:SetWndEasyImage(star,"dailyluck_star_on_1")
			end
		end
		self:SetRoleTween()
	end)
end

function UIDTDLuckPop:OnClickDivination()
	if self._luckRefId > 0 then
		GF.ShowMessage(ccClientText(23118))
		return
	end
	self:TweenSeqKill(self._TextIconTweenKey)
	self:SetRunSpineAin(true)
	gLGameAudio:PlaySound("SoundS_21")
	--gModelOneNight:SpaceLuckReq()
	self:ReqNewPage()
	self:TimerStop(self._luckEffKey)
	self:TimerStart(self._luckEffKey,0.6,false,1)
end

function UIDTDLuckPop:ListItem(list, item, itemdata, itempos)
	local headIcon = self:FindWndTrans(item,"Root/Image/HeadIcon")
	local nameText = self:FindWndTrans(item,"Root/Image/NameText")
	local msgText = self:FindWndTrans(item,"Root/Image/MsgText")
	local timeText = self:FindWndTrans(item,"Root/Image/TimeText")
	local btnMag = self:FindWndTrans(item,"Root/Image/BtnMag")
	local btnReport = self:FindWndTrans(btnMag,"BtnReport")
	local reportText = self:FindWndTrans(btnReport,"ReportText")
	local btnLike = self:FindWndTrans(btnMag,"BtnLike")
	local noLikeIcon = self:FindWndTrans(btnLike,"NoLikeIcon")
	local yesLikeIcon = self:FindWndTrans(btnLike,"YesLikeIcon")
	local likeText = self:FindWndTrans(btnLike,"LikeText")

	self._btnLikeList[itemdata.id] = btnLike
	local InstanceID = item:GetInstanceID()
	local info = itemdata.info
	local time = itemdata.time
	local text = itemdata.text
	local _msg = LUtil.FilterEmoji(text,"?")
	_msg = LWordMaskUtil.ClearShieldWord(_msg,false,nil,true)
	_msg = LUtil.ChatInfoFaceBinToDec(_msg)
	local msg = LUtil.GetFaceStr(_msg,30)
	local like = itemdata.like
	local likeCount = itemdata.likeCount
	local myPlayerId = gModelPlayer:GetPlayerId()
	local isMy = info._playerId == myPlayerId
	local formatStr = ccClientText(23115)
	local _time = LUtil.OSDate(formatStr,tonumber(time)/1000)

	local serverName = gModelFriend:GetSevenName(info._serverId)
	local name = info._name
	name = info.sex == 1 and string.replace(ccClientText(11148),name) or string.replace(ccClientText(11147),name)
	self:SetHeadIcon(headIcon,info,InstanceID)
	self:SetWndText(nameText,string.replace(ccClientText(23103),serverName,name))
	self:SetWndText(msgText,msg)
	self:SetWndText(timeText,_time)
	CS.ShowObject(btnMag,true)
	CS.ShowObject(btnReport,not isMy)
	--CS.ShowObject(btnLike,not isMy)
	self:SetWndText(reportText,ccClientText(23104))
	self:SetWndText(likeText,likeCount)
	CS.ShowObject(noLikeIcon,like == 1)
	CS.ShowObject(yesLikeIcon,like ~= 1)
	self:SetWndClick(btnReport,function ()
		self:OnClickReport(itemdata)
	end)
	self:SetWndClick(btnLike,function ()
		self:OnClickLike(itemdata)
	end)

	local uiText = LxUiHelper.FindXTextCtrl(msgText)
	local height = uiText.preferredHeight + 53
	if height < 106 then
		height = 106
	end
	LxUiHelper.SetSizeWithCurAnchor(item,1,height)
end

function UIDTDLuckPop:OnClickBuzz()
	if self._isNoClickBuzz then return end
	local _isShowBottom = self._isShowBottom or false
	local type = not _isShowBottom and 1 or 2
	self:SetBottomTween(type)
	local buzzIcon = _isShowBottom and "public_btn_icon_28_2" or "public_btn_icon_28_1"
	if self._isForeign then
		self:SetWndEasyImage(self.mBuzzIconEn,buzzIcon)
	else
		self:SetWndEasyImage(self.mBuzzIcon,buzzIcon)
	end

	self._isShowBottom = not _isShowBottom
end

function UIDTDLuckPop:OnClickSend()
	local sendNum = GameTable.OneNightConfigRef["dailyMessageTime"]
	--local _spaceInfo = gModelOneNight:GetSpaceInfoPB()
	--local luckMessageCount = _spaceInfo.luckMessageCount or 0
	--if luckMessageCount >= sendNum then
	--	GF.ShowMessage(ccClientText(23110))
	--	return
	--end
	--GF.OpenWnd("UIDTDLuckMsgPop")
end

function UIDTDLuckPop:OnClickReport(itemdata)
	GF.OpenWnd("UIRepin",{reportType = ModelChat.REPORT_TYPE_SPACE,
							   channelId = 100, playerInfo  = itemdata.info,text = itemdata.text,sendTime = itemdata.time })
end

function UIDTDLuckPop:RefreshData(bool)
	local isLuck = self._isLuck
	local _luckRefId = self._luckRefId
	local _luckTextRefId = self._luckTextRefId
	CS.ShowObject(self.mTextIcon,not isLuck)
	if not isLuck then
		self:SetWndText(self.mDivinationDesText,"")
	end
	if bool then
		local roleMagY = not isLuck and -150 or 0
		self.mRoleMag.localPosition = Vector2.New(0,roleMagY)
		CS.ShowObject(self.mBtnMar,isLuck)
		CS.ShowObject(self.mImgIcon,isLuck)
		CS.ShowObject(self.mStarMar,isLuck)
		if isLuck then
			local ref = GameTable.OneNightDailyLuckRef[_luckRefId]
			self:SetWndEasyImage(self.mImgIcon,ref.typeIcon)
			local starNum = ref.starNum
			if starNum > 0 then
				for i = 1, starNum do
					local star = self:FindWndTrans(self.mStarMar,"Star"..i)
					self:SetWndEasyImage(star,"dailyluck_star_on_1")
				end
			end
			if _luckTextRefId <= 0 then
				return
			end
			local textRef = GameTable.OneNightDailyLuckTextRef[_luckTextRefId]
			self:SetWndText(self.mDivinationDesText,ccLngText(textRef.text))
		end
	end
end

function UIDTDLuckPop:OnClickSortBtn(index)
	self:OnCutBtnSortStatus()
	self._sortIndex = index
	self._page = 0
	self:RefreshSortText()
	self:ReqNewPage()
end

function UIDTDLuckPop:InitCommand()
	self._isForeign = gLGameLanguage:IsForeignVersion()
	local isForeign = self._isForeign
	CS.ShowObject(self.mBtnBuzz, not isForeign)
	CS.ShowObject(self.mBtnBuzzEn,  isForeign)
	CS.ShowObject(self.mBtnSend, not isForeign)
	CS.ShowObject(self.mBtnSendEn,  isForeign)

	--self:SetWndText(self.mTitleText,ccClientText(23101))
	if not isForeign then
		self:SetWndText(self.mBuzzText,ccClientText(23119))
		self:SetWndText(self.mSendText,ccClientText(23102))
	else
		self:SetWndText(self.mBuzzTextEn,ccClientText(23119))
		self:InitTextLineWithLanguage(self.mBuzzTextEn, -30)
		self:SetWndText(self.mSendTextEn,ccClientText(23102))
		self:InitTextLineWithLanguage(self.mSendTextEn, -30)
	end

	--local _spaceInfo = gModelOneNight:GetSpaceInfoPB()
	--if not _spaceInfo then
	--	gModelOneNight:SpaceInfoReq(0)
	--	self._noInit = true
	--	return
	--end
	--self:InitLuck()
end

function UIDTDLuckPop:SetTextIconTween()
	local seqTween
	local _compileTweenKey = self._TextIconTweenKey
	self:TweenSeqKill(_compileTweenKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(_compileTweenKey,function(seq)
			local tween = self.mTextIcon:DOScale(Vector3.one * 1.2,1)
			seq:Append(tween)
			local tween = self.mTextIcon:DOScale(Vector3.one * 1,1)
			seq:Append(tween)
			return seq
		end)
	end
	seqTween:SetLoops(-1)
	seqTween:PlayForward()
	seqTween:OnComplete(function()

	end)
end

function UIDTDLuckPop:ReqNewPage()
	local _page = self._page or 0
	local newPage = _page + 1
	--gModelOneNight:SpaceLuckMessageListReq(self._sortIndex, 2, newPage, self._pageNumber)
	self._page = newPage
end
function UIDTDLuckPop:SetBottomTween(type)--1 显示 2 隐藏
	if type == 1 then
		CS.ShowObject(self.mBottom,true)
		self:SetCanvasGroupAlpha(self.mBottom,1)
		self:RefreshMsg()
	else
		self._isNoClickBuzz = true
		local seqCom = self:GetSeqCom()
		local seq = seqCom:CreateSeq("fade")
		local cg = self:FindCommonComponent(self.mBottom,typeofCanvasGroup)
		local tween = cg:DOFade(0,0.3)
		seq:Append(tween)
		seq:OnComplete(function ()
			self._isNoClickBuzz = false
			CS.ShowObject(self.mBottom,false)
		end)
		seq:PlayForward()
	end
end

function UIDTDLuckPop:OnClickLike(itemdata)
	local like = itemdata.like
	if like == 0 then
		--gModelOneNight:SpaceLuckMessageLikeReq(itemdata.id)
	else
		GF.ShowMessage(ccClientText(23106))
	end
end

function UIDTDLuckPop:RefreshMsg(id)
	local _msgList = self._msgList or {}
	local _uiMsgList = self._uiMsgList
	local len = #_msgList
	CS.ShowObject(self.mNoRecord2,len <= 0)
	if(len <= 0)then
		self:CreateEmptyShow(24001)
	end
	if(_uiMsgList)then
		_uiMsgList:RefreshList(_msgList)
	else
		_uiMsgList = self:GetUIScroll("uiMsgList")
		_uiMsgList:Create(self.mMsgSuper,_msgList,function (...) self:ListItem(...) end, UIItemList.SUPER)
		_uiMsgList:EnableScroll(true,false)
		self._uiMsgList = _uiMsgList
	end
	local _uiList = _uiMsgList:GetList()
	_uiMsgList:DrawAllItems(not id)
	if id then
		local btnLike = self._btnLikeList[id]
		self:DestroyWndEffectByKey("fx_ui_dianzan")
		self:CreateWndEffect(btnLike,"fx_ui_dianzan","fx_ui_dianzan",100)
	end
	_uiList:SetFuncOnItemReachTail(function (bool)
		if bool then
			local len = #_msgList
			local maxLen = self._page * self._pageNumber
			if len >= maxLen then
				self:ReqNewPage()
			end
		end
	end)
end
------------------------------------------------------------------
return UIDTDLuckPop


