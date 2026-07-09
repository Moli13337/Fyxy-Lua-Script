---
--- Created by BY.
--- DateTime: 2023/10/28 18:18:42
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActKeyRoom:LWnd
local UIActKeyRoom = LxWndClass("UIActKeyRoom", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActKeyRoom:UIActKeyRoom()
	self._uiIconEasyList = {}
	self._playerList = {}							--玩家预制体
	self._playerSpeakList = {}						--玩家发言预制体
	self._weedNameList = {}							--淘汰已经飘字列表
	self._timeKey = "ActivityAnswerRoom_timeKey"
	self._isFace = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActKeyRoom:OnWndClose()
	self:TimerStop(self._timeKey)
	self:ClearCommonIconList(self._uiIconEasyList)
	if self._itemPool then
		self._itemPool:Destroy()
		self._itemPool = nil
	end
	GF.CloseWndByName("UIBulletSay")
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActKeyRoom:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActKeyRoom:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitDate()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	self:DisableInputText(self.mDesInput)
end
function UIActKeyRoom:InitCommand()
	local sid = self:GetWndArg("sid")
	if not sid then return end
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._sid = sid
	self._modelId = modelId
	self._channel = self._modelChannelList[modelId]
	local itempool = UIObjPool:New()
	itempool:Create(self.mTemplates,self.mPrefabRoot)
	self._itemPool = itempool

	local openFunc = self:GetWndArg("openFunc")
	if openFunc then
		openFunc()
	end

	self.mDesInput.characterLimit =  gModelChat:GetCharacterLimit(self._channel)
	gModelActivity:ReqActivityConfigData(sid)
end
function UIActKeyRoom:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
	--self:WndNetMsgRecv(LProtoIds.RankResp,function (pb)
	--	local sid = pb.activityId
	--	if(not sid or self._sid ~= sid)then return end
	--	self:RefreshRank(pb)
	--end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if(self._sid ~= sid)then return end
		self:ResetData(pb)
	end)
	--self:WndNetMsgRecv(LProtoIds.ActivityMagicAcademyAnswerRoomResp,function (pb)
	--	local sid = pb.sid
	--	local roomId = pb.roomId
	--	if self._sid ~= sid then return end
	--	self:RefreshAnswer()
	--end)
	self:SetInputValueChange(self.mDesInput,function (str)
		self:OnInputDes(str)
	end)
	self:WndNetMsgRecv(LProtoIds.ChatMsgResp,function (pb)
		GF.ShowMessage(ccClientText(17607))
		self.mDesInput.text = ""
	end)
end

function UIActKeyRoom:RefreshRank(pb)
	local pages = self.pages
	local sid = self._sid
	local _rankRewardId = self._rankRewardId
	local page = pages[_rankRewardId]
	if not page then return end

	local activityDataS = gModelActivity:GetActivityBySid(sid)
	local dataS = JSON.decode(activityDataS.moreInfo)
	local rank = dataS.rank or 0											--排名
	local score = dataS.accomplish_count or 0								-- 答题通关次数

	--local selfRank = pb.selfRank
	--local rank = selfRank and selfRank.rank or 0
	--local score = selfRank and selfRank.score or 0
	self:SetWndText(self.mMeStrText,rank > 0 and rank or ccClientText(26422))
	self:SetWndText(self.mDesStrText,string.replace(ccClientText(26423),score))

	local _rewardList = LxDataHelper.SevenParseRewardList(sid,page)
	local curRank = _rewardList[#_rewardList]
	for i, v in ipairs(_rewardList) do
		local rankArr = string.split(v.rank,",")
		if tonumber(rankArr[1]) <= rank and rank <= tonumber(rankArr[2]) then
			curRank = v
			break
		end
	end
	local award = curRank.reward
	local itemList = LxDataHelper.ParseItem(award)
	self:InitItemList("UIActKeyRoom_mAwardRoot",self.mAwardRoot,itemList)
end

function UIActKeyRoom:OnInitFaceList()
	local list = gModelChat:GetEmojiByType(1)--弹幕只有小表情
	if(self._uiFaceList)then
		self._uiFaceList:RefreshData(list)
	else
		self._uiFaceList = self:GetUIScroll("_uiFaceList")
		self._uiFaceList:Create(self.mFaceScroll,list,function (...) self:FaceListItem(...) end,UIItemList.WRAP)
	end
end
function UIActKeyRoom:OnClickRank()
	local sid = self._sid
	local _pages = self.pages
	local _rankRewardId = self._rankRewardId or 12
	local page =  _pages[_rankRewardId]
	if not page then return end
	local _rewardList = LxDataHelper.SevenParseRewardList(sid,page)
	GF.OpenWndBottom("UIRkPop",{refId = self._rankId,sid = sid,rewardList = _rewardList,callFunc = function()
		local bool = gModelActivity:GetAnswerIsRoom(sid)
		if not bool then
			GF.OpenWnd("UIActKeyMin",{sid = sid})
		else
			GF.OpenWnd("UIActKeyRoom",{sid = sid})
		end
	end})
	self:WndClose()
end

function UIActKeyRoom:CreatePlayer()
	local para = gModelActivity:GetAnswerRoomData(self._sid)
	if not para then return end
	local members = para.members
	for i, v in ipairs(members) do
		local spineParent = self:FindWndTrans(self.mSpineMag,"Spine"..i)
		self:SetPlayerSpine(spineParent,v,i)
		local nameParent = self:FindWndTrans(self.mSpineNameMag,"Spine"..i)
		self:SetPlayerName(nameParent,v,i)
	end
	self._isCreatePlayer = true
	gModelGeneral:OpenBarrage({channel = self._channel,roomId = tostring(para.roomId)})
end
function UIActKeyRoom:FaceListItem(list, item, itemdata, itempos)
	local imageTran=CS.FindTrans(item,"Image")
	self:SetWndEasyImage(imageTran,itemdata.faceIcon)
	self:SetWndClick(imageTran, function (...) self:OnClickFace(itemdata.faceinstead) end)
end
function UIActKeyRoom:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config
	self._rankId,self._rankRewardId = data.answerRank,data.answerRankReward
	self._askTimeWait,self._askWaitTxt,self._askReadyTxt,self._askOutTxt,self._askSuccTxt,self._askLoseTxt,self._askOutNameTxt
	= data.askTimeWait,data.askWaitTxt,data.askReadyTxt,data.askOutTxt,data.askSuccTxt,data.askLoseTxt,data.askOutNameTxt
	self._askReadyTime = data.askReadyTime or 5

	gModelActivity:OnActivityPageReq(sid)
	self:RefreshAnswer()
end

function UIActKeyRoom:PlayItemTween(seqKey,trans)
	self:TweenSeqKill(seqKey)
	local seqTween = self:TweenSeqCreate(seqKey, function(seq)
		--local pos = trans.localSale
		local ePos = Vector3.New(0,0,0)
		--local move = trans:DOLocalMoveY(pos.y - 200, 0.5)
		local move = trans:DOScale(ePos,0.7)
		seq:Join(move)
		return seq
	end)

	seqTween:OnComplete(function()
		self:TweenSeqKill(seqKey)
		CS.ShowObject(trans,false)
	end)
	seqTween:PlayForward()
end
function UIActKeyRoom:InitDate()
	self:SetWndText(self.mAwardText,ccClientText(26418))
	self:SetWndText(self.mRwardText,ccClientText(26419))
	self:SetWndText(self.mMeText,ccClientText(26421))
	self:SetWndText(self.mDesText,ccClientText(26430))
	self:SetWndText(self.mDetailsText,ccClientText(26420))
	self:SetWndTextInput(self.mDesInput, nil, ccClientText(26434))
	self:SetWndButtonText(self.mBtnSend,ccClientText(26433))
	self:SetWndText(self.mTipsText3,ccClientText(26435))

	self._modelMagList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_66] = "UIActMagicShcool",
	}
	self._modelChannelList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_66] = ModelChat.CHANNEL_CHILD_33,
	}
end
function UIActKeyRoom:GetItemNew(pid,parent)
	local itemNew = self._playerList[pid]
	if itemNew then return itemNew end
	itemNew = self._itemPool:GetObj()
	local itemRoot = parent
	itemNew.transform:SetParent(itemRoot.transform, false)
	itemNew.transform.localPosition = Vector2.New(0,0)
	CS.ShowObject(itemNew,true)
	self._playerList[pid] = itemNew
	return itemNew
end
function UIActKeyRoom:ResetData(pb)
	local list = self.pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		list[page.pageId] = page
	end
	self.pages = list
	self:RefreshData()
end
function UIActKeyRoom:OnClickLook()
	local data = {
		sid = self._sid,
		title = string.replace(ccClientText(26427),self._rounds),
		refId = self._questionRefId,
		msIsAnswer = self._msIsAnswer,
		meIsWeed = self._meIsWeed,
	}
	GF.OpenWnd("UIActKeyPop",{type = 1,para = data})
end
function UIActKeyRoom:OnClickBFaceMask()
	local _isFace = not self._isFace
	CS.ShowObject(self.mFaceMask,_isFace)
	if(_isFace)then
		self:OnInitFaceList()
	end
	self._isFace = _isFace
end
function UIActKeyRoom:SetPlayerSpine(item,itemdata,itempos)
	if not item or not itemdata then return end
	local playerId = itemdata.playerId
	local root = self:GetItemNew(playerId,item)
	local spineBg = self:FindWndTrans(root,"SpineBg")
	local spine = self:FindWndTrans(root,"Spine")
	--local nameText = self:FindWndTrans(root,"NameText")
	local speakBg = self:FindWndTrans(root,"SpeakBg")
	local speakText = self:FindWndTrans(root,"SpeakBg/SpeakText")
	local mask = self:FindWndTrans(root,"Mask")
	local eff = self:FindWndTrans(root,"Eff")

	local figure = itemdata.figure
	--local name = itemdata.name

	self._playerSpeakList[playerId] = {
		spineBg = spineBg,
		spine = spine,
		speakBg = speakBg,
		speakText = speakText,
		mask = mask,
		eff = eff
	}

	self:SetWndEasyImage(mask, "public_txt_taotai", nil, true)
	--local selfPlayerId = gModelPlayer:GetPlayerId()
	--local nameStr = LUtil.FormatColorStr(name,selfPlayerId == playerId and "yellow_2" or "white")
	--self:SetWndText(nameText,nameStr)
	local ref = gModelPlayer:GetRoleAdventureImage(figure)
	self:CreateWndSpine(spine,ref.spine,playerId,false,function(dpSpine)
		--local paintFlip=ref.paintFlip2==1
		--local paintMultiple=ref.paintMultiple2
		--dpSpine:SetScale(paintMultiple)
		--dpSpine:SetFlipX(paintFlip)
		--local dpTrans =dpSpine:GetDisplayTrans()
		--dpTrans.anchorMin = Vector2.New(0.5,0.5)
		--dpTrans.anchorMax = Vector2.New(0.5,0.5)
	end)
end
--选择表情
function UIActKeyRoom:OnClickFace(faceinstead)
	self:SetWndTextInput(self.mDesInput, self.mDesInput.text..faceinstead)
end
function UIActKeyRoom:InitItemList(InstanceID,awardRoot,itemList)
	local uiIconEasyList = self._uiIconEasyList[InstanceID]
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		self._uiIconEasyList[InstanceID] = uiIconEasyList
		uiIconEasyList:Create(self, awardRoot)
		uiIconEasyList:EnableScroll(true,true)
	end
	uiIconEasyList:RefreshList(itemList)
end
function UIActKeyRoom:OnClickSend()
	local _stage = self._stage or 1
	if _stage == 3 then
		GF.ShowMessage(ccClientText(26432))
		return
	end
	local msg = self.mDesInput.text
	local len = LxUtf8.cnLen(msg)
	local maxLen = gModelChat:GetCharacterLimit(self._channel)
	if(len > maxLen)then
		GF.ShowMessage(ccClientText(17603))
		self:SetWndTextInput(self.mDesInput, LxUtf8.sub(msg,1,len))
		return
	elseif(msg == "")then
		GF.ShowMessage(ccClientText(17604))
		return
	end
	gModelChat:OnChatMsgReq(self._channel,1,msg)
end
function UIActKeyRoom:RefreshData()
	local answerRank = self._rankId
	if answerRank and not self._isOne then
		self._isOne = true
		local ref = gModelRank:GetRankingRefData(answerRank)
		self:SetWndText(self.mTitleText,ccLngText(ref.nameTitle))
		--gModelRank:OnRankReq(2,answerRank,1,25,self._sid)
	end
	self:RefreshRank()
end

function UIActKeyRoom:OnTryTcpReconnect()
	self:WndClose()
end
function UIActKeyRoom:SetPlayerName(item,itemdata,itempos)
	if not item or not itemdata then return end
	local playerId = itemdata.playerId
	local root = self:GetItemNew(playerId.."name",item)
	local nameText = self:FindWndTrans(root,"NameText")
	local name = itemdata.name

	local selfPlayerId = gModelPlayer:GetPlayerId()
	local nameStr = LUtil.FormatColorStr(name,selfPlayerId == playerId and "yellow_2" or "white")
	self:SetWndText(nameText,nameStr)
end
function UIActKeyRoom:RefreshPlayer()
	local list = {
		"activity_magicSchool_txt_A","activity_magicSchool_txt_B","activity_magicSchool_txt_C","activity_magicSchool_txt_D"
	}
	local para = gModelActivity:GetAnswerRoomData(self._sid)
	if not para then return end
	local weedList = {}
	local members = para.members
	local meIsWeed = false							--是否被淘汰
	local msIsAnswer = 0							--是否答题过
	local mePlayerId = gModelPlayer:GetPlayerId()
	for i, v in ipairs(members) do
		local playerId = v.playerId
		local answerIndex = v.answerIndex or 0
		local playerSpeak = self._playerSpeakList[playerId]
		if playerSpeak then
			CS.ShowObject(playerSpeak.mask,v.disuse == 1)
			CS.ShowObject(playerSpeak.speakBg,answerIndex > 0 and v.disuse == 0)
			self:SetWndEasyImage(playerSpeak.speakText,list[answerIndex])
			CS.ShowObject(playerSpeak.spineBg,true)
			self:SetWndEasyImage(playerSpeak.spineBg,v.disuse == 1 and "fight_ui_1" or "fight_ui_7")
			if v.disuse == 1 then
				table.insert(weedList,v)
			end
			if mePlayerId == playerId and v.disuse == 1 then
				meIsWeed = true
			elseif mePlayerId == playerId and answerIndex > 0 then
				msIsAnswer = answerIndex
			end
		end
	end
	local stage = para.stage					--当前所处阶段（ 1=预备答题，2=答题中，3=结束）
	local rounds = para.rounds					--当前答题轮次
	local endTime = para.endTime				--当前阶段结束时刻（毫秒）
	local questionRefId = para.questionRefId	--问题refId
	local _askTimeWait = self._askTimeWait or 0
	self._stage = stage
	self._questionRefId = questionRefId
	self._msIsAnswer = msIsAnswer
	self._meIsWeed = meIsWeed
	local time = GetTimestamp()
	local timespan = endTime/1000 - time
	local isWaitTime = timespan <= _askTimeWait	--是否在等待时间

	local _timeKey = self._timeKey

	if questionRefId and questionRefId > 0 then
		local ref = GameTable.IssueRef[questionRefId]
		self:SetWndText(self.mTipsText1,ccLngText(ref.dec))
		if stage == 1 then
			local answer = ref.answer
			local question = string.split(ccLngText(ref.question),"|")
			local list = {
				"A","B","C","D"
			}
			local des = list[answer]..question[answer]
			self:SetWndText(self.mTipsText2,string.replace(ccClientText(26436),des))
		end
	end

	local _weedNum = 0
	if stage == 1 or stage == 3 then
		for i, v in ipairs(weedList) do
			local name = v.name
			if not self._weedNameList[name] then
				GF.ShowMessage(string.replace(self._askOutNameTxt,name))
				local playerId = v.playerId
				local playerSpeak = self._playerSpeakList[playerId]
				self:CreateWndEffect(playerSpeak.eff,"ui_fx_mengjingxueyuan_heidong",playerId.."UIActKeyRoom",100)
				self:PlayItemTween(playerId,playerSpeak.spine)
				self._weedNameList[name] = true
				_weedNum = _weedNum + 1
			end
		end
	end
	CS.ShowObject(self.mTipsText3,stage == 2)
	CS.ShowObject(self.mTipsText4,stage == 1)
	self:SetWndText(self.mTipsText4,string.replace(self._askOutTxt,_weedNum))

	if stage == 1 then

	elseif stage == 2 then
		if msIsAnswer == 0 and not meIsWeed and not isWaitTime and not GF.FindFirstWndByName("UIActKeyPop") then
			local data = {
				sid = self._sid,
				title = string.replace(ccClientText(26427),rounds),
				refId = questionRefId,
				endTime = endTime - _askTimeWait * 1000,
				rounds = rounds
			}
			GF.OpenWnd("UIActKeyPop",{type = 2,para = data})
		end
	elseif stage == 3 then
		local tipsStr = self._askLoseTxt
		if #weedList ~= #members then
			tipsStr = self._askSuccTxt
			self:CreateWndEffect(self.mEff,"ui_fx_mengjingxueyuan_yanhua","effKey_UIActKeyRoom",100)
		end
		self:SetWndText(self.mTipsText,tipsStr)
		CS.ShowObject(self.mTipsBg,true)
		CS.ShowObject(self.mTipsBg2,false)
		self:TimerStop(_timeKey)
		return
	end
	self._rounds = rounds
	self._endTime = endTime
	if not self:IsTimerExist(_timeKey) then
		self:TimerStart(_timeKey,1,false,-1)
		self:SetTime()
	end
end
function UIActKeyRoom:SetTime()
	local _askTimeWait = self._askTimeWait or 0
	local _stage = self._stage
	local endTime = self._endTime or 0
	local time = GetTimestamp()
	local timespan = endTime/1000 - time
	if(timespan <= 0)then
		--self:TimerStop(self._timeKey)
		return
	end
	local timeStr = LUtil.FormatTimeToCn1(timespan)
	local tipsStr = ""
	local isWe = timespan <= (self._askReadyTime + 1) and _stage == 1
	CS.ShowObject(self.mTipsBg,isWe)
	CS.ShowObject(self.mTipsBg2,not isWe)
	if _stage == 1 then
		tipsStr = string.replace(self._askReadyTxt,timeStr,self._rounds)
		self:SetWndText(self.mTipsText,tipsStr)
	elseif _stage == 2  then
		tipsStr = string.replace(ccClientText(26428),timeStr)
		self:SetWndText(self.mTipsText2,tipsStr)
	end
end
function UIActKeyRoom:OnClickAward()
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config

	local list = {
		{
			title = ccClientText(26425),
			itemList = LxDataHelper.ParseItem(data.questionYesReward)
		},
		{
			title = ccClientText(26426),
			itemList = LxDataHelper.ParseItem(data.questionNoReward)
		},
	}
	local para = {
		title = ccClientText(26424),
		list = list
	}
	GF.OpenWnd("UIActKeyAwardPop",{para = para})
end
function UIActKeyRoom:OnInputDes(str)
	local len = LxUtf8.cnLen(str)
	local maxLen = gModelChat:GetCharacterLimit(self._channel)
	if(len > maxLen)then
		str = self._oldStr
		self:SetWndTextInput(self.mDesInput, str)
		len = LxUtf8.cnLen(str)
		GF.ShowMessage(ccClientText(17603))
	else
		self._oldStr = str
	end
	--激活聊天框不选中所有内容
	self.mDesInput.onFocusSelectAll = false
end

function UIActKeyRoom:OnTimer(key)
	if(key == self._timeKey)then
		self:SetTime()
	end
end
function UIActKeyRoom:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnDetails, function(...) self:OnClickRank() end)
	self:SetWndClick(self.mBtnAward, function(...) self:OnClickAward() end)
	self:SetWndClick(self.mBtnFace, function(...) self:OnClickBFaceMask() end)
	self:SetWndClick(self.mFaceMask, function(...) self:OnClickBFaceMask() end)
	self:SetWndClick(self.mBtnSend, function(...) self:OnClickSend() end)
	self:SetWndClick(self.mBtnLook,function (...)self:OnClickLook() end)
end
function UIActKeyRoom:OnClickClose()
	local wndName = self._modelMagList[self._modelId]
	GF.OpenWnd(wndName,{sid = self._sid})
	self:WndClose()
end
function UIActKeyRoom:RefreshAnswer()
	if not self._isCreatePlayer then
		self:CreatePlayer()
	end
	self:RefreshPlayer()
end
------------------------------------------------------------------
return UIActKeyRoom


