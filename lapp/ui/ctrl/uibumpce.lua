---
--- Created by Administrator.
--- DateTime: 2023/10/7 10:21:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBumpce:LWnd
local UIBumpce = LxWndClass("UIBumpce", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBumpce:UIBumpce()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBumpce:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBumpce:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBumpce:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIBumpce:InitEvent()
	self:SetWndClick(self.mReturnBtn, function(...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnHelp,function () self:OnClickHelp() end)
	self:SetWndClick(self.mBtnAdd,function () self:OnClickAdd() end)
	self:SetWndClick(self.mBtnStartGame,function () self:OnClickStartGame() end)
end

function UIBumpce:OnTryTcpReconnect()
	self:WndClose()
end

function UIBumpce:OnClickAdd()

	if self._isGameEnd then
		GF.ShowMessage(self._tips4)
		return
	end


	if self._status then
		if self._taskJumpId then
			local wndName = self:GetWndName()
			local para =
			{
				refId = 110051,
				func = function()
					gModelFunctionOpen:Jump(self._taskJumpId,wndName)
				end
			}

			gModelGeneral:OpenUIOrdinTips(para)
		end
		return
	end

	local buyCnt = self._diamondBuyCount or 0
	if buyCnt <= 0 then
		local str =ccClientText(32001) --"今日次数全部用完,请明日再来"
		GF.ShowMessage(str)
	else
		local sid = self._sid
		local pageId = self._roundRewardPageId

		local costStr = gModelGeneral:GetCommonItemColorName(self._buyTimeCost,'*')
		local leftTimes = math.max(buyCnt,0)
		local para =
		{
			refId = self._buyWndRefId,
			para = {costStr,leftTimes},
			func = function()
				gModelActivity:OnActivitySpecialOpReq(sid,pageId,-1,10)
			end
		}

		gModelGeneral:OpenUIOrdinTips(para)
	end
end

function UIBumpce:OnClickSupperzzle(entryId,pos)
	local noRecordStatus = self._noRecordStatus
	if noRecordStatus ~= 0 then
		if noRecordStatus == 2 then
			GF.ShowMessage(ccClientText(22210))
		elseif noRecordStatus == 3 then
			GF.ShowMessage(ccClientText(22218))
		elseif noRecordStatus == 4 then
			GF.ShowMessage(ccClientText(22212))
		end
		return
	end

	if self._isOnClick then
		return
	end
	if self._playNum <= 0 then
		return
	end
	local posItemList = self._posItemList
	if not posItemList then
		return
	end
	local pos1 = self._pos1
	if pos1 and pos1 == pos then
		return
	end
	self._pos = pos
	self._clickEntryId = entryId
	self._isOnClick = true
	local eff = self:FindWndTrans(posItemList[pos],"Rotate")
	self:SetRotateTween({eff},1)

end

function UIBumpce:OnTimer(key)
	if self._drawKey == key then
		self._isYes = true
		gModelActivity:OnActivitySpecialOpReq(self._sid,self._roundRewardPageId,self._drawEntryId,7)
	elseif self._drawErrorKey == key then
		self:SetTween(self._tweens)
		gModelActivity:OnActivitySpecialOpReq(self._sid,self._roundRewardPageId,-1,9)
	elseif self._drawYesKey == key then
		self._isYes = false
		self:RefreshData()
		self._isOnClick = false
	end
end

function UIBumpce:InitCommand()
	self._sid = self:GetWndArg("sid")
	local subPage = self:GetWndArg("subPage")
	if subPage then
		self._sid = gModelActivity:GetSidByUniqueJump(subPage)
	end
	local modelId = gModelActivity:GetActivityModeIdBySid(self._sid)
	self._modelId = modelId

	---每轮奖励,次数条件表:分页Id
	self._modelList =
	{
		[ModelActivity.ACT_MODEL_97] = {1,2},
	}

	local list = self._modelList[modelId]
	self._roundRewardPageId = list[1]
	self._conditionPageId = list[2]
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if activityData then
		local moreInfo = JSON.decode(activityData.moreInfo)
		self._oldRound = moreInfo.round
	end

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIBumpce:ShowEndPlay()
	local seqCom  = self:GetSeqCom()
	local seq = seqCom:CreateSeq("endPlay")
	local toScale = Vector3.one *1.15
	CS.ShowObject(self.mFinishTip,true)
	local scaleTween = self.mFinishTip:DOScale(toScale, 0.2)
	seq:Append(scaleTween)
	scaleTween = self.mFinishTip:DOScale(Vector3.one, 0.2)
	seq:Append(scaleTween)
	seq:AppendInterval(0.5)
	seq:OnComplete(function ()
		CS.ShowObject(self.mFinishTip,false)
		self:RefreshData()
	end)
	seq:PlayForward()
end

function UIBumpce:ListItem(list,item, itemdata, itempos)
	local Root = self:FindWndTrans(item,"Root")
	local RootRotate = self:FindWndTrans(Root,"Rotate")
	local RotateFade = self:FindWndTrans(RootRotate,"fade")
	local RotateActive = self:FindWndTrans(RootRotate,"active")
	local RotateItem = self:FindWndTrans(RootRotate,"item")
	local itemItemIcon = self:FindWndTrans(RotateItem,"itemIcon")
	local RotateFront = self:FindWndTrans(RootRotate,"Front")
	local RootEff = self:FindWndTrans(Root,"Eff")
	local RootEff2 = self:FindWndTrans(Root,"Eff2")
	local RootClick = self:FindWndTrans(Root,"Click")




	CS.ShowObject(RootEff,false)
	CS.ShowObject(RootEff2,false)

	local entryId,pos = itemdata.entryId,itemdata.pos
	self._posItemList[pos] = Root
	self:SetWndClick(RootClick,function ()
		self:OnClickSupperzzle(entryId,pos)
	end)
	local bumpReceive = self._bumpReceive
	local isClose = bumpReceive[entryId]
	CS.ShowObject(RootClick,not isClose)

	local pos1,pos2 = self._pos1,self._pos2
	local isShowItem = (pos1 and pos1 == pos) or (pos2 and pos2 == pos)
	CS.ShowObject(RotateItem,isShowItem )
	CS.ShowObject(RotateActive,not isClose)
	if isClose then
		RootRotate.localRotation = Quaternion.Euler(0,0,0)
	end
	CS.ShowObject(RotateFront,not isClose and not isShowItem)
	if not isShowItem then
		return
	end
	local pages = self._pages
	if not pages or not pages[entryId] then
		return
	end
	local itemS = pages[entryId].item

	local icon = gModelGeneral:GetCommonItemImgRef(itemS)
	self:SetWndEasyImage(itemItemIcon,icon)

end

function UIBumpce:OnClickStartGame()
	if self._playNum <= 0 then
		self:OnClickAdd()
		return
	end

	gModelActivity:OnActivitySpecialOpReq(self._sid,self._roundRewardPageId,self._drawEntryId,8)
end

function UIBumpce:PlayEff(trans,effName,effKey)
	self:CreateWndEffect(trans,effName,effKey,100)
end

function UIBumpce:SetRotateTween(tweens,rotateType)
	local seqTween
	self:TweenSeqKill(self._rotateTweenKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._rotateTweenKey,function(seq)
			for i, v in ipairs(tweens) do
				local tweener
				if rotateType == 1 then
					tweener = v.transform:DOLocalRotate(Vector3.New(0,180,0),0.3)
				else
					tweener = v.transform:DOLocalRotate(Vector3.New(0,0,0),0.3)
				end
				seq:Join(tweener)
			end
			seq:InsertCallback(0.15,function ()
				if rotateType ~= 1 then
					self._pos1 = nil
					self._pos2 = nil
					self._entryId = nil
					self:RefreshGridShow()
				else
					self:DrawKai()
				end
			end)
			return seq
		end)
	end

	seqTween:OnComplete(function()
		self:TweenSeqKill(self._rotateTweenKey)
		if rotateType ~= 1 then
			self._isOnClick = false
		end
	end)
	seqTween:PlayForward()
end

function UIBumpce:RefreshGridShow()
	local list = self:FindUIScroll("bumpList")
	if list then
		list:DrawAllItems(false)
	end
end

function UIBumpce:SetTween(tweens)
	if not tweens then
		return
	end
	local seqTween
	self:TweenSeqKill(self._errorTweenKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._errorTweenKey,function(seq)
			for i, v in ipairs(tweens) do
				local tweener = v.transform:DOLocalRotate(Vector3.New(0,0,-10),0.06):SetEase(DG.Tweening.Ease.InSine)
				seq:Join(tweener)
			end
			seq:AppendInterval(0.06)
			for i, v in ipairs(tweens) do
				local tweener = v.transform:DOLocalRotate(Vector3.New(0,0,10),0.12):SetEase(DG.Tweening.Ease.InSine)
				seq:Join(tweener)
			end
			seq:AppendInterval(0.06)
			for i, v in ipairs(tweens) do
				local tweener = v.transform:DOLocalRotate(Vector3.New(0,0,0),0.12):SetEase(DG.Tweening.Ease.InSine)
				seq:Join(tweener)
			end
			return seq
		end)
	end
	seqTween:SetLoops(2)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._errorTweenKey)
		local pos1 = self._pos1
		local pos2 = self._pos2
		local posItemList = self._posItemList
		local eff1 = self:FindWndTrans(posItemList[pos1],"Rotate")
		local eff2 = self:FindWndTrans(posItemList[pos2],"Rotate")
		self:SetRotateTween({eff1,eff2},2)
	end)
end

function UIBumpce:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp,function (pb)
		self:OnOperRet(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)
		local activities = pb.activities
		for i, v in ipairs(activities) do
			local sid = v.sid
			if sid == self._sid then
				self:RefreshData()
				return
			end
		end
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
		local activity = pb.activity
		local sid = activity.sid
		if sid == self._sid then
			self:RefreshData()
		end
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then
			return
		end
		self:OnActivityConfigData()
	end)
end

function UIBumpce:SetItemList(pages,round,bumpReceives)
	local list = {}
	for i, v in pairs(pages) do
		if v.round == round then
			local data =
			{
				item = v.item,
				sort = i,
				status = bumpReceives[i],
			}

			table.insert(list,data)
		end
	end
	table.sort(list,function (a,b)
		return a.sort < b.sort
	end)

	self:CreateUIScrollImpl("rewardList",self.mItemList,list,function (...)
		self:ItemListItem(...)
	end)

	local uiList = self:FindUIScroll("rewardList")
	if uiList then
		uiList:EnableScroll(true,true)
	end

end

function UIBumpce:SetStaticContent()
	self:SetWndText(self.mNumDesText,ccClientText(22205))
	self:SetWndText(self.mTxtReturn,ccClientText(20723))
	self:SetWndButtonText(self.mBtnStartGame,ccClientText(22211))
end

function UIBumpce:ResetData(pb)
	local sid = pb.sid
	if(self._sid ~= sid)then
		return
	end
	local totalRound = 0
	if not self._pages then
		self._pages = {}
	end
	local pages = self._pages
	local source = self._source and self._source or {}
	local status = self._status ~= nil and self._status or false
	for i, v in ipairs(pb.pages) do
		if v.pageId == self._roundRewardPageId then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			for i1, v1 in ipairs(page.entry) do
				local entryId = v1.entryId
				local round = tonumber(v1.moreInfo)
				local reward = v1.items[1]
				pages[entryId] = {item = {itemId = reward.itemId,itemType = reward.type,itemNum = reward.count},round = round}
				if round > totalRound then
					totalRound = round
				end
			end
		elseif v.pageId == self._conditionPageId then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			for i1, v1 in ipairs(page.entry) do
				table.insert(source,v1)
				local goalData = v1.goalData
				if goalData.status < 1 then
					status = true
				end
			end
		end
	end
	self._totalRounds = totalRound
	self._status = status
	self._source = source
	self:RefreshData()
end

function UIBumpce:InitData()
	self._posItemList = {}
	self._drawKey = "_drawKey"
	self._drawErrorKey = "_drawErrorKey"
	self._drawYesKey = "_drawYesKey"
	self._errorTweenKey = "_errorTweenKey"
	self._rotateTweenKey = "_rotateTweenKey"

	self._roundStrList =
	{
		[1] = ccClientText(25115),
		[2] = ccClientText(25116),
		[3] = ccClientText(25117),
		[4] = ccClientText(25118),
		[5] = ccClientText(25119),
		[6] = ccClientText(25120),
		[7] = ccClientText(25121),
	}

	self._isEnter = true
end

function UIBumpce:OnClickHelp()--点击帮助
	local title = self._helpTitle or ""
	local text = self._helpText or ""
	GF.OpenWnd("UIBzTips",{title= title,text = text})
end

function UIBumpce:OnActivityConfigData()
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config

	self:SetWndEasyImage(self.mMask,data.image)
	local strs = string.split(data.enterHero,'=')
	local heroType = tonumber(strs[1])
	local heroRes = strs[2]
	CS.ShowObject(self.mHeroImage,heroType == 1)
	CS.ShowObject(self.mHeroPaint,heroType == 2)
	if heroType == 1 then
		self:SetWndEasyImage(self.mHeroImage,heroRes,nil,true)
	elseif heroType == 2 then
		self:CreateWndSpine(self.mHeroPaint,heroRes,"showHero")
	end

	local offset = LxDataHelper.ParseVector2(data.enterHeroPos,'|')
	self:SetAnchorPos(self.mHeroRoot,offset)

	--self:SetWndText(self.mTitleText,data.gameRewardTitle)


	self._helpText = data.gameHelpTxt
	self._helpTitle = gModelActivity:GetLngNameByActivitySid(self._sid)

	local strs = string.split(data.enterHeroTxt,"|")
	self._desText1 = strs[1]
	self._desText2 = strs[2]
	--self:SetWndText(self.mDesText,data.enterHeroTxt)

	--self._gameGrid = data.gameGrid
	local tipsStr= string.split(data.activeTips,"|")
	self._tips1 = tipsStr[1]
	self._tips2 = tipsStr[2]
	tipsStr = string.split(data.gameTips,"|")
	self._tips3 = tipsStr[1]
	self._tips4 = tipsStr[2]

	self._gamePlayTime = data.gamePlayTime
	self._buyTimeCost = LxDataHelper.ParseItem_3(data.countBuyPrice)
	self._taskJumpId = data.gameJumpId
	self._buyWndRefId = data.purchaseTips

	gModelActivity:OnActivityPageReq(self._sid)
end

function UIBumpce:RefreshData()
	if self._isYes then
		return
	end
	local activityDataS = gModelActivity:GetActivityBySid(self._sid)
	local activityWebData = gModelActivity:GetWebActivityDataById(self._sid)
	local pages = self._pages              --当前轮次奖励道具 {item,round}
	local totalRounds = self._totalRounds  --总轮次
	local status = self._status            --今天次数是否还有获取
	if not activityDataS or not pages or not activityWebData or not totalRounds then
		return
	end

	---游戏状态
	local dataS = JSON.decode(activityDataS.moreInfo)
	---可购买次数
	local diamondBuyCount = dataS.diamondBuyCount or 0
	---游戏状态
	local startState = dataS.start_state
	---当前轮次
	local round = dataS.round
	---总游戏次数
	local bumpCount = dataS.bumpCount
	local count = bumpCount - (round - 1)

	---数据
	local bumpData = JSON.decode(dataS.bumpData)
	---翻开id
	local bumpReceive = JSON.decode(dataS.bumpReceive)
	local bumpReceives = {}
	local receiveLen = 0
	if bumpReceive then
		for i, v in ipairs(bumpReceive) do
			bumpReceives[v] = true
			receiveLen = i
		end
	end
	self._bumpReceive = bumpReceives
	local dataList = {}
	if bumpData then
		for k,v in pairs(bumpData) do
			table.insert(dataList,{entryId = v,pos = k + 1})
		end
	end
	table.sort(dataList,function (a,b)
		return a.pos < b.pos
	end)

	local isRoundChange = self._oldRound ~= round

	self._oldRound = round

	local curRoundEnd = receiveLen >= #dataList/2
	if (isRoundChange or curRoundEnd) and self._isGameRunning then
		self._isGameRunning = false
		self:ShowEndPlay()
		return
	end

	local isGameEnd = round == totalRounds and receiveLen >= #dataList/2
	local playNum = nil
	if isGameEnd then
		playNum = 0
	else
		playNum = math.max(0,count)
	end
	self._playNum = playNum
	self._round = round
	self._diamondBuyCount = diamondBuyCount
	self:SetWndText(self.mNumText,playNum)

	local str = isGameEnd and self._desText2 or self._desText1

	self:SetWndText(self.mDesText,str)

	local roundStr = self._roundStrList[round]
	self:SetWndText(self.mRoundText,roundStr)

	self._isGameEnd = isGameEnd
	local noRecordStatus = 0
	local showStartGame = true
	self._isGameRunning = false
	if isGameEnd then
		self:SetWndText(self.mTipsText,self._tips4)
		noRecordStatus = 1
	else
		if startState == 0 then                  --未开始游戏
			noRecordStatus = 4
			CS.ShowObject(self.mBtnStartGame,true)
			if playNum <= 0  then
				if status then              --0次数但活跃度未达条件时的空列表
					noRecordStatus = 3
					self:SetWndText(self.mTipsText,self._tips1)
				else
					noRecordStatus = 2              --今天次数用完但活动没完
					self:SetWndText(self.mTipsText,self._tips2)
				end
			else
				local str =ccClientText(32000)--"请开始游戏"
				self:SetWndText(self.mTipsText,str)
			end
		else
			self:SetWndText(self.mTipsText1,self._tips3) --游戏进行中
			showStartGame = false

			self._isGameRunning = true
		end
	end


	CS.ShowObject(self.mBtnStartGame,showStartGame)
	CS.ShowObject(self.mNumDesText,showStartGame)
	CS.ShowObject(self.mTip,showStartGame)
	CS.ShowObject(self.mTip1,not showStartGame)


	self._noRecordStatus = noRecordStatus
	local currAwardRound = round
	--if noRecordStatus == 2 then
	--	currAwardRound = currAwardRound - 1
	--elseif noRecordStatus == 3 then
	--	if currAwardRound > 1 then
	--		currAwardRound = currAwardRound - 1
	--	end
	--end
	self:SetItemList(pages,currAwardRound,bumpReceives)

	self:CreateUIScrollImpl("bumpList",self.mCellScroll,dataList,function (...)
		self:ListItem(...)
	end)

	local list = self:FindUIScroll("bumpList")
	if list then
		list:EnableScroll(#list > 16,false)
	end


	self:SetWndButtonGray(self.mBtnStartGame,isGameEnd)

	self:RefreshBtnRed()
end

function UIBumpce:RefreshBtnRed()
	local showRed
	if self._isGameEnd then
		showRed = false
	else
		showRed = self._playNum and self._playNum > 0
		if not showRed then
			showRed = self._status == true
		end
	end


	CS.ShowObject(self.mRedPoint,showRed)
end

function UIBumpce:OnOperRet(pb)
	local opType = pb.opType
	if opType == 8 then
		GF.ShowMessage(ccClientText(22217))
		self:RefreshData()
		return
	elseif opType ~= 7 then
		return
	end
	local posItemList = self._posItemList
	local pos1 = self._pos1
	local pos2 = self._pos2
	local eff1 = self:FindWndTrans(posItemList[pos1],"Eff2")
	local eff2 = self:FindWndTrans(posItemList[pos2],"Eff2")
	CS.ShowObject(eff1,true)
	CS.ShowObject(eff2,true)
	self:PlayEff(eff1,"fx_ui_duiduipeng_zhengque_texiao","texiao"..pos1)
	self:PlayEff(eff2,"fx_ui_duiduipeng_zhengque_texiao","texiao"..pos2)
	self._pos1 = nil
	self._pos2 = nil
	self._entryId = nil
	self:TimerStop(self._drawYesKey)
	self:TimerStart(self._drawYesKey,1.1,false,1)
end

function UIBumpce:ItemListItem(list,item, itemdata, itempos)
	local root = CS.FindTrans(item,"Icon")
	local mask = CS.FindTrans(item,"Mask")
	CS.ShowObject(mask,itemdata.status)
	self:CreateCommonIconImpl(root,itemdata.item)
end

function UIBumpce:DrawKai()
	local posItemList = self._posItemList
	if not posItemList then
		return
	end
	local pos = self._pos
	local pos1 = self._pos1
	local entryId = self._entryId
	local clickEntryId = self._clickEntryId
	if pos1 then
		self._pos2 = pos
		if entryId == clickEntryId then --开出同样的，领取奖励
			self:RefreshGridShow()

			self._drawEntryId = entryId
			self:TimerStop(self._drawKey)
			self:TimerStart(self._drawKey,0.3,false,1)
		else --开出不同样的，翻回去
			self:RefreshGridShow()

			local list =
			{
				posItemList[pos1],
				posItemList[pos],
			}
			self._tweens = list
			self:TimerStop(self._drawErrorKey)
			self:TimerStart(self._drawErrorKey,0.1,false,1)
		end
	else--开第一张牌
		self._pos1 = pos
		self._entryId = clickEntryId
		self:RefreshGridShow()
		self._isOnClick = false
	end
end

function UIBumpce:OnClickClose()
	self:WndClose()
end

------------------------------------------------------------------
return UIBumpce





