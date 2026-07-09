---
--- Created by LCM.
--- DateTime: 2024/3/13 17:58:41
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeEventPuzzle:LWnd
local UIHopeEventPuzzle = LxWndClass("UIHopeEventPuzzle", LWnd)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local Tweening = DG.Tweening
local EaseInQuad = Tweening.Ease.InQuad
local YXTween = YXTween

UIHopeEventPuzzle.PUZZLEIMG_NAME1 = 1
UIHopeEventPuzzle.PUZZLEIMG_NAME2 = 2
UIHopeEventPuzzle.PUZZLEIMG_NAME3 = 3
UIHopeEventPuzzle.PUZZLEIMG_NAME4 = 4
UIHopeEventPuzzle.PUZZLEIMG_NAME5 = 5
UIHopeEventPuzzle.PUZZLEIMG_NAME6 = 6

UIHopeEventPuzzle.PUZZLEIMG_COL_NUM = 3			-- 列
UIHopeEventPuzzle.PUZZLEIMG_ROW_NUM = 2			-- 行
UIHopeEventPuzzle.PUZZLEIMG_ROW_MAX_NUM = 3		-- 行

UIHopeEventPuzzle.PUZZLEIMGNAMELIST = {
	UIHopeEventPuzzle.PUZZLEIMG_NAME1,
	UIHopeEventPuzzle.PUZZLEIMG_NAME2,
	UIHopeEventPuzzle.PUZZLEIMG_NAME3,
	UIHopeEventPuzzle.PUZZLEIMG_NAME4,
	UIHopeEventPuzzle.PUZZLEIMG_NAME5,
	UIHopeEventPuzzle.PUZZLEIMG_NAME6,
}

UIHopeEventPuzzle.MOVE_NULL = 0
UIHopeEventPuzzle.MOVE_LEFT = 1
UIHopeEventPuzzle.MOVE_RIGHT = 2
UIHopeEventPuzzle.MOVE_TOP = 3
UIHopeEventPuzzle.MOVE_BOTTOM = 4

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeEventPuzzle:UIHopeEventPuzzle()
	self._runShowAniKey = "runShowAniKey"
	self._runShowAniStatus = false

	self._movePuzzleImgAniKey = "movePuzzleImgAniKey"
	self._moveStatus = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeEventPuzzle:OnWndClose()
	local changePuzzleImgPosList = self._changePuzzleImgPosList or {}
	--gModelDreamTrip:SavePuzzlePosInfo(self._eventId,self._puzzleRefId,changePuzzleImgPosList)

	local extraData = self:GetExtraData()
	gModelCommonDreamTrip:SavePuzzlePosInfo({
		mapType = extraData.mapType,
		eventId = self._eventId,
		puzzleRefId = self._puzzleRefId,
		changePuzzleImgPosList = changePuzzleImgPosList,
	})
	gModelCommonDreamTrip:CheckSendSpeedUpEvent(extraData)
	--FireEvent(EventNames.ON_DREAMTRIP_CLEARANISTATUS)

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeEventPuzzle:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeEventPuzzle:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitPuzzleTransInfoList()
	self:InitPuzzleImgTransInfoList()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshPuzzleImgShowPos()
end

function UIHopeEventPuzzle:RefreshPuzzleImgShowPos()
	self:ChangePuzzleImgPos()
	self:SetAllPuzzleImg()
end

function UIHopeEventPuzzle:GetRightImgList(photoRefId)
	if not photoRefId then
		local photoGallery = gModelDreamTrip:GetConfigByKey("photoGallery")
		local randomNum = math.random(1,#photoGallery)
		photoRefId = tonumber(photoGallery[randomNum])
	end
	local iconRef = GameTable.DreamTripIconRef[photoRefId]
	if not iconRef then
		return
	end
	self._rightPuzzlePosList = {
		iconRef.photo1,
		iconRef.photo2,
		iconRef.photo3,
		iconRef.photo4,
		iconRef.photo5,
		iconRef.photo6,
		iconRef.photo7,
		iconRef.photo8,
		iconRef.photo9,
	}
	return photoRefId
end

function UIHopeEventPuzzle:CreateRandomNum()
	local initNumList = {}
	local allPuzzleImgNum = self._allPuzzleImgNum
	local showImgNum = self._showImgNum
	for i = 1,allPuzzleImgNum do
		table.insert(initNumList,i)
	end

	for i = 1,showImgNum do
		math.randomseed(tostring(os.time()):reverse():sub(1, 7))
		local random = math.random(i,showImgNum)
		local temp = initNumList[i]
		initNumList[i] = initNumList[random]
		initNumList[random] = temp
	end

	local rightPuzzlePosList = self._rightPuzzlePosList
	local imgList = {}
	for i = 1,showImgNum do
		local index = initNumList[i]
		imgList[i] = rightPuzzlePosList[index]
	end

	local isSame = self:CheckIsSameRightPos(imgList)
	if isSame then
		self:CreateRandomNum()
		return
	end

	if self:IsRandomNumAgain(initNumList) then
		return imgList
	else
		self:CreateRandomNum()
	end
end

function UIHopeEventPuzzle:OnClickReSetPuzzleImgFunc()
	self:RefreshPuzzleImgShowPos()
end

function UIHopeEventPuzzle:IsRandomNumAgain(list)
	local cnt = 0
	for i = 1,self._showImgNum do
		for j = i + 1,self._allPuzzleImgNum do
			if list[i] > list[j] then
				cnt = cnt + 1
			end
		end
	end
	return cnt % 2 == 0
end

function UIHopeEventPuzzle:InitMsg()

	self:WndNetMsgRecv(LProtoIds.DreamTripStartEventResp,function(pb) self:OnDreamTripStartEventResp(pb) end)
	self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList)
		--gModelDreamTrip:EventIdCanCel(self._eventId)

		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:CancelEventIdStatus({
			mapType = extraData.mapType,
			sid = extraData.sid,
			eventId = self._eventId
		})
		self:WndClose()
	end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)


	--- 7.20新增活动梦境之旅
	--self:WndNetMsgRecv(LProtoIds.ActivityDreamTripStartEventResp,function(pb,ret) self:OnDreamTripStartEventResp(pb) end)
end

function UIHopeEventPuzzle:InitPuzzleImgPos()
	local puzzleImgInfoList = self._puzzleImgInfoList
	for i,v in ipairs(puzzleImgInfoList) do
		CS.ShowObject(v.root,false)
		v.root.localPosition = Vector3.zero
	end
end

function UIHopeEventPuzzle:InitData()
	self._eventId = self:GetWndArg("eventId")
	self._index = self:GetWndArg("index")

	local extraData = self:GetWndArg("extraData")
	self._extraData = extraData

	--local serverData = gModelDreamTrip:GetPlatformByIndexAndEventId(self._eventId,self._index)

	local serverData = gModelCommonDreamTrip:GetPlatformEventInfo(self._eventId,self._index,self:GetExtraData())
	if serverData then
		local eventRefId = serverData.eventRefId
		local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
		if eventRef then
			local name = ccLngText(eventRef.name)
			self:SetWndText(self.mLblBiaoti,name)

			local choose = tonumber(eventRef.choose)
			local textRef = gModelDreamTrip:GetDreamTripTextRefByRefId(choose)
			local dec = ""
			if textRef then
				dec = ccLngText(textRef.dec)
			end
			self:SetWndText(self.mEventDesc,dec)

			local resType = eventRef.resType
			if resType == 1 then
				local res = eventRef.res
				self:SetWndEasyImage(self.mEventIcon,res,function()
					CS.ShowObject(self.mEventIcon,true)
				end)
			elseif resType == 2 then
				local prefab = eventRef.prefab
				self:CreateWndSpine(self.mEventSpinePos,prefab,prefab,false,function(dpSpine)
					CS.ShowObject(self.mEventSpinePos,true)
				end)
			end
		end
	end
end

function UIHopeEventPuzzle:SetAllPuzzleImg()
	self:InitPuzzleImgPos()
	local changePuzzleImgPosList = self._changePuzzleImgPosList
	for k,v in pairs(changePuzzleImgPosList) do
		local root = self._puzzleImgInfoList[k].root
		self:SetWndEasyImage(root,v)
	end
	self:RunShowAni()
end

function UIHopeEventPuzzle:OnClickGiveUpBtnFunc()
	--self:OnClickReSetPuzzleImgFunc()
	--gModelDreamTrip:OnDreamTripStartEventReq(self._eventId,{-1})

	local extraData = self:GetExtraData()
	gModelCommonDreamTrip:OnDreamTripStartEventProcessor(self._eventId,{
		mapType = extraData.mapType,
		sid = extraData.sid,
		argList = {"0"},
	})
end

function UIHopeEventPuzzle:RunShowAni()
	if self._runShowAniStatus then
		return
	end
	self._runShowAniStatus = true

	local seqKey = self._runShowAniKey
	local seqTween = self:TweenSeqFind(seqKey)
	if seqTween then
		self:TweenSeqKill(seqKey)
		seqTween = nil
	end

	local puzzleInfoList = self._puzzleInfoList

	seqTween = self:TweenSeqCreate(seqKey, function(seq)
		local showTime = 0.5
		local initTime = 0
		local baseTime = 0.1
		local puzzleImgInfoList = self._puzzleImgInfoList
		local changePuzzleImgPosList = self._changePuzzleImgPosList
		for k,v in pairs(changePuzzleImgPosList) do
			local trans = puzzleImgInfoList[k].root
			local tCanvasG = self:GetTransCanvasGroup(trans)
			if tCanvasG then
				CS.ShowObject(trans,true)
				local tweenShowAlpha = YXTween.TweenFloat(0, 1, showTime, function(ival)
					tCanvasG.alpha = ival
				end):SetEase(EaseInQuad)
				seq:Insert(initTime,tweenShowAlpha)
			end
			initTime = initTime + baseTime

			local puzzleInfo = puzzleInfoList[k]
			local localPos = puzzleInfo.localPos

			local tweenMoveTo = trans:DOLocalMove(localPos, showTime)
			seq:Insert(initTime,tweenMoveTo)
		end
		return seq
	end)
	seqTween:OnComplete(function()
		self._runShowAniStatus = false
		self:TweenSeqKill(seqKey)
	end)
	seqTween:PlayForward()
end

function UIHopeEventPuzzle:ChangePuzzleImgPos()
	--local changePuzzleImgPosList = self:CreateRandomNum() 		-- 随机生成有解拼图位置

	local changePuzzleImgPosList = self:GetPuzzleImgList()
	self._changePuzzleImgPosList = changePuzzleImgPosList

	local changePuzzleImgTransList = {}
	local index = 0
	for k,v in pairs(changePuzzleImgPosList) do
		if index >= self._showImgNum then break end
		changePuzzleImgTransList[k] = self._puzzleImgInfoList[k].root
		index = index + 1
	end
	self._changePuzzleImgTransList = changePuzzleImgTransList
end

function UIHopeEventPuzzle:InitPuzzleTransInfoList()
	local puzzleList = {
		self.mPuzzle1, self.mPuzzle2, self.mPuzzle3,
		self.mPuzzle4, self.mPuzzle5, self.mPuzzle6,
		self.mPuzzle7, self.mPuzzle8, self.mPuzzle9,
	}

	local puzzleInfoList = {}
	for i,v in ipairs(puzzleList) do
		table.insert(puzzleInfoList,{
			localPos = v.anchoredPosition,
			root = v,
			btnIndex = i
		})
	end
	self._puzzleInfoList = puzzleInfoList
end

function UIHopeEventPuzzle:OnDreamTripStartEventResp(pb)
	if pb.eventId ~= self._eventId then return end
	local endInfo = pb.endInfo
	if not endInfo then return end
	if endInfo.state == StructDreamTripGrid.FINISH then
		self:WndClose()
	end
end

function UIHopeEventPuzzle:GetPuzzleImgList()
	local eventId = self._eventId
	local imgList = {}
	local puzzleRefId
	--local puzzlePosInfo = gModelDreamTrip:GetPuzzlePosInfo(eventId)

	local extraData = self:GetExtraData()
	local puzzlePosInfo = gModelCommonDreamTrip:GetPuzzlePosInfo({
		mapType = extraData.mapType,
		eventId = eventId,
	})

	if puzzlePosInfo then
		local posList = puzzlePosInfo.tPosList
		imgList = posList
		puzzleRefId = self:GetRightImgList(puzzlePosInfo.puzzleRefId)
	else
		puzzleRefId = self:GetRightImgList()
		if puzzleRefId then
			local boxSort = gModelDreamTrip:GetConfigByKey("boxSort")
			local randomNum = math.random(1,#boxSort)
			local boxStr = boxSort[randomNum]
			local rightPuzzlePosList = self._rightPuzzlePosList
			for i,v in ipairs(boxStr) do
				v = tonumber(v)
				imgList[i] = rightPuzzlePosList[v]
			end
		end
	end
	self._puzzleRefId = puzzleRefId
	return imgList
end

function UIHopeEventPuzzle:CheckCurPuzzleImgCanMove(btnIndex)
	local changePuzzleImgPosList = self._changePuzzleImgPosList
	local checkIsMove = function(moveIdx)
		return not changePuzzleImgPosList[moveIdx]
	end
	local checkMoveHo = function(moveNum)
		local move1
		if moveNum > 0 and moveNum % UIHopeEventPuzzle.PUZZLEIMG_ROW_MAX_NUM == 0 then
			move1 = math.floor(moveNum / UIHopeEventPuzzle.PUZZLEIMG_ROW_MAX_NUM)
		else
			move1 = math.floor(moveNum / UIHopeEventPuzzle.PUZZLEIMG_ROW_MAX_NUM) + 1
		end
		local move2 = math.floor(btnIndex / UIHopeEventPuzzle.PUZZLEIMG_ROW_MAX_NUM) + 1
		if btnIndex > 0 and btnIndex % UIHopeEventPuzzle.PUZZLEIMG_ROW_MAX_NUM == 0 then
			move2 = math.floor(btnIndex / UIHopeEventPuzzle.PUZZLEIMG_ROW_MAX_NUM)
		else
			move2 = math.floor(btnIndex / UIHopeEventPuzzle.PUZZLEIMG_ROW_MAX_NUM) + 1
		end
		return move1 == move2
	end
	local moveLeft = btnIndex - 1
	if moveLeft > 0 and checkIsMove(moveLeft) and checkMoveHo(moveLeft) then
		return UIHopeEventPuzzle.MOVE_LEFT,moveLeft
	end

	local isMoveRight = false
	local moveRight = btnIndex + 1
	if btnIndex > UIHopeEventPuzzle.PUZZLEIMG_COL_NUM then
		local tMoveRight = moveRight % UIHopeEventPuzzle.PUZZLEIMG_COL_NUM
		if tMoveRight == 0 then
			tMoveRight = UIHopeEventPuzzle.PUZZLEIMG_COL_NUM
		end
		isMoveRight = tMoveRight <= UIHopeEventPuzzle.PUZZLEIMG_COL_NUM
	else
		isMoveRight = moveRight <= UIHopeEventPuzzle.PUZZLEIMG_COL_NUM
	end
	if isMoveRight and moveRight <= self._allPuzzleImgNum and checkIsMove(moveRight) and checkMoveHo(moveRight) then
		return UIHopeEventPuzzle.MOVE_RIGHT,moveRight
	end

	local fastMoveTop = btnIndex - UIHopeEventPuzzle.PUZZLEIMG_COL_NUM
	local moveTop = math.ceil(btnIndex / UIHopeEventPuzzle.PUZZLEIMG_COL_NUM) - 1
	if moveTop > 0 and moveTop <= UIHopeEventPuzzle.PUZZLEIMG_ROW_NUM and checkIsMove(fastMoveTop) then
		return UIHopeEventPuzzle.MOVE_TOP,fastMoveTop
	end

	local moveBot = btnIndex + UIHopeEventPuzzle.PUZZLEIMG_COL_NUM
	if moveBot > 0 and moveBot <= self._allPuzzleImgNum and checkIsMove(moveBot) then
		return UIHopeEventPuzzle.MOVE_BOTTOM,moveBot
	end

	return UIHopeEventPuzzle.MOVE_NULL,0
end

function UIHopeEventPuzzle:CheckIsSameRightPos(list)
	local checkIndexList = {}
	local rightPuzzlePosList = self._rightPuzzlePosList
	for i,v in pairs(list) do
		local sameIndex = rightPuzzlePosList[i] == v and 1 or 0
		table.insert(checkIndexList,sameIndex)
	end

	local isSame = true
	for i,v in ipairs(checkIndexList) do
		isSame = v == 1
		if not isSame then break end
	end
	return isSame
end

function UIHopeEventPuzzle:OnClickPuzzleImgFunc(btnIndex)
	if self._runShowAniStatus then return end
	if self._moveStatus then return end
	local state,nextBtnIndex = self:CheckCurPuzzleImgCanMove(btnIndex)
	if state == UIHopeEventPuzzle.MOVE_NULL then
		return
	end
	if not nextBtnIndex then
		return
	end
	local curImg = self._changePuzzleImgPosList[btnIndex]
	self._changePuzzleImgPosList[btnIndex] = nil
	self._changePuzzleImgPosList[nextBtnIndex] = curImg
	self:MoveAni(btnIndex,nextBtnIndex)
end

function UIHopeEventPuzzle:MoveAni(curIndex,nextIndex)
	if not curIndex or not nextIndex then
		return
	end
	local puzzleInfoList = self._puzzleInfoList
	local nextInfo = puzzleInfoList[nextIndex]
	if not nextInfo then
		return
	end
	local changePuzzleImgTransList = self._changePuzzleImgTransList
	local curRoot = changePuzzleImgTransList[curIndex]
	if not curRoot then return end
	self._moveStatus = true

	local nextPox = nextInfo.localPos

	local seqKey = self._movePuzzleImgAniKey
	local seqTween = self:TweenSeqFind(seqKey)
	if seqTween then
		self:TweenSeqKill(seqKey)
		seqTween = nil
	end

	seqTween = self:TweenSeqCreate(seqKey, function(seq)
		local showTime = 0.2
		local moveTween = curRoot:DOLocalMove(nextPox,showTime)
		seq:Append(moveTween)
		return seq
	end)
	seqTween:OnComplete(function()
		self._changePuzzleImgTransList[curIndex] = nil
		self._changePuzzleImgTransList[nextIndex] = curRoot
		self:TweenSeqKill(seqKey)
		self._moveStatus = false
		local isSame = self:CheckIsSameRightPos(self._changePuzzleImgPosList)
		if isSame then
			--gModelDreamTrip:OnDreamTripStartEventReq(self._eventId,{1})

			local extraData = self:GetExtraData()
			gModelCommonDreamTrip:OnDreamTripStartEventProcessor(self._eventId,{
				mapType = extraData.mapType,
				sid = extraData.sid,
				argList = {"1"},
			})
		end
	end)
	seqTween:PlayForward()
end

function UIHopeEventPuzzle:GetTransCanvasGroup(trans)
	local canvasGroup = trans.gameObject:GetComponent(typeofCanvasGroup)
	if not canvasGroup then
		canvasGroup = trans.gameObject:AddComponent(typeofCanvasGroup)
	end
	canvasGroup.alpha = 0
	return canvasGroup
end

function UIHopeEventPuzzle:GetExtraData()
	return self._extraData
end

function UIHopeEventPuzzle:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mGiveUpBtn,function() self:OnClickGiveUpBtnFunc() end)
	self:SetWndClick(self.mCatPicBtn,function() self:OnClickCatPicBtnFunc() end)

	for i,v in ipairs(self._puzzleInfoList) do
		self:SetWndClick(v.root,function()
			self:OnClickPuzzleImgFunc(v.btnIndex)
		end)
	end
end

function UIHopeEventPuzzle:InitText()
	self:SetWndButtonText(self.mGiveUpBtn,ccClientText(28704))
	self:SetWndButtonText(self.mCatPicBtn,ccClientText(28705))
end

function UIHopeEventPuzzle:OnClickCatPicBtnFunc()
	GF.OpenWnd("UIHopeEventPuzzleSow",{rightImgList = self._rightPuzzlePosList})
end

function UIHopeEventPuzzle:InitPuzzleImgTransInfoList()
	local puzzleImgList = {
		self.mPuzzleImg1, self.mPuzzleImg2, self.mPuzzleImg3,
		self.mPuzzleImg4, self.mPuzzleImg5, self.mPuzzleImg6,
		self.mPuzzleImg7, self.mPuzzleImg8, self.mPuzzleImg9
	}
	local puzzleImgInfoList = {}
	for i,v in ipairs(puzzleImgList) do
		table.insert(puzzleImgInfoList,{
			localPos = v.anchoredPosition,
			root = v,
			btnIndex = i,
		})
	end
	self._puzzleImgInfoList = puzzleImgInfoList

	local puzzleImgLen = #puzzleImgInfoList
	self._allPuzzleImgNum = puzzleImgLen
	self._showImgNum = puzzleImgLen - 1
end

------------------------- List -------------------------


------------------------- List -------------------------

------------------------------------------------------------------
return UIHopeEventPuzzle


