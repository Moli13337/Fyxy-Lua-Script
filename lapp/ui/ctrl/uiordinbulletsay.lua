---
--- Created by Administrator.
--- DateTime: 2023/10/6 15:03:44
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIOrdinBulletSay:LWnd
local UIOrdinBulletSay = LxWndClass("UIOrdinBulletSay", LWnd)
local Tweening = DG.Tweening
local typeRectTransform = typeof(UnityEngine.RectTransform)

UIOrdinBulletSay.AUTO_RUN = true 				-- 是否自动滚动
UIOrdinBulletSay.AUTO_ADD = true 				-- 是否自动添加
UIOrdinBulletSay.MAX_SHOW_BARRAGE = 5 			-- 最多显示条数
UIOrdinBulletSay.LINE_NUM = 25
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOrdinBulletSay:UIOrdinBulletSay()
	self._barrageKey = "_barrageKey"
	self._barrageLoopKey = "_barrageLoopKey"
	self._intervalKey = "_intervalKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOrdinBulletSay:OnWndClose()
	if self._timerList then
		for k,v in pairs(self._timerList) do
			LxTimer.DelayTimeStop(v)
		end
	end
	self._timerList = nil
	if self._seqList then
		for k,v in pairs(self._seqList) do
			v:Kill(false)
		end
	end
	self._seqList = nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOrdinBulletSay:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOrdinBulletSay:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
	if not self._getBarrageFromEvent then
		self:InitMsg()
	end
	self:Refresh()
end

-- 定时任务
function UIOrdinBulletSay:DelayTween(itemdata)
	local key = itemdata.id
	local timer = nil
	timer = LxTimer.DelayFrameCall(function ()
		self:TweenItem(itemdata)
		LxTimer.DelayTimeStop(timer)
		self._timerList[key] = nil
	end,1)
	self._timerList[key] = timer
end

function UIOrdinBulletSay:RefreshCommentList(network)
	self._netIsOver = false
	self._oldIndex = 0

	local func = function()
		if not self:IsWndValid() then return end
		self:StopClickDropTimer()
		self:OnGetNewPage()
	end

	if network then
		self:StopClickDropTimer()
		self._delayClickDropTimer = LxTimer.DelayTimeCall(function ()
			func()
			self:StopClickDropTimer()
		end, 3)
	else
		func()
	end
end
------------------------------------------------------------------
--- 开始创建弹幕
function UIOrdinBulletSay:OnSatrtBarrage()
	if self._curBarrage >= self._maxShowBarrage then return end
	local getIndex = math.random(1,self._canSetNum)
	if self._usePosList[getIndex] then
		local new = math.ceil(getIndex / 2)
		getIndex = new <= 0 and 1 or new
	end
	local barrageData = table.remove(self._barragePoolList,1)
	if not barrageData then
		self:TimerStop(self._barrageKey)
		self._curBarrage = 0
		local isAutoAdd = self._isAutoAdd
		if isAutoAdd then
			local barrageType = self._barrageType
			if barrageType == ModelHeroBook.BARRAGE_TYPE_OTHERBARRAGE
					or barrageType == ModelHeroBook.BARRAGE_TYPE_BAND_THEME then
				self:RunBarrage()
			else
				self:LoopStarTime()
			end
		end
		return
	end
	local newIndex = self._curBarrage + 1
	self._curBarrage = newIndex
	local msgInfo = {
		id = barrageData.id,
		text = barrageData.text,
		playerId = barrageData.playerId,
		lineIndex = getIndex,
	}
	self:CreateBarrage(msgInfo)
end

function UIOrdinBulletSay:RefreshBarrageList(netWork)
	local list = {}
	local sendBarrageList = self._sendBarrageList or {}
	for i,v in ipairs(sendBarrageList) do
		table.insert(list,v)
	end
	self._barragePoolList = list
end

-- 创建Item移动动画
function UIOrdinBulletSay:TweenItem(itemdata)
	local item = itemdata.item
	local imageTrans = itemdata.imageTrans
	local seq = Tweening.DOTween.Sequence()
	self._seqList[seq] = seq
	local length = imageTrans:GetComponent(typeRectTransform).rect.width
	local movX = -(length+ self._width)
	local oldPos = item.transform.anchoredPosition
	local tweener = YXTween.TweenFloat(0,1,self._moveSpeed,function (value)
		local pos = movX * value
		item.transform.anchoredPosition = oldPos + Vector3.New(pos,0,0)
	end)
	seq:Append(tweener)
	seq:SetAutoKill(true)
	seq:OnComplete(function()
		self._seqList[seq] = nil
		self._curBarrage = self._curBarrage - 1
		self:ReturnToPool(itemdata.item)
		self._usePosList[itemdata.lineIndex] = false
	end)
	seq:SetUpdate(true)
	seq:PlayForward()
end

function UIOrdinBulletSay:InitData()
	-- 弹幕类型
	local barrageType = self:GetWndArg("barrageType")
	if barrageType == nil then
		barrageType = ModelHeroBook.BARRAGE_TYPE_OTHERBARRAGE
	end
	self._barrageType = barrageType

	self._loopCd = self:GetWndArg("loopCd")

	self._heroRefId = self:GetWndArg("heroRefId")

	-- 通用类型使用Event接收数据
	self._getBarrageFromEvent = barrageType == ModelHeroBook.BARRAGE_TYPE_OTHERBARRAGE

	self._oldIndex = 0

	local oneRepCommentNum = gModelHero:GeConfigByKey("OneRepCommentNum")
	if not oneRepCommentNum then
		printInfoNR("请在HeroConfigRef里配置每次请求的评论条数，字段名OneRepCommentNum，若无配置，默认"..ModelHeroBook.SEND_REP_NUM)
		oneRepCommentNum = ModelHeroBook.SEND_REP_NUM
	end
	self._oneRepCommentNum = oneRepCommentNum

	-- 弹幕列表
	self._barrageList = self:GetWndArg("barrageList")

	-- 弹幕时间
	self._cd = self:GetWndArg("cd")

	-- 是否打开面板立即生成
	self._isQuicklyCreate = self:GetWndArg("isQuicklyCreate")

	-- 弹幕颜色列表
	self._colorList = self:GetWndArg("colorList")

	-- 是否自动开启滚屏
	local autoRun = self:GetWndArg("autoRun")
	if autoRun == nil then
		autoRun = UIOrdinBulletSay.AUTO_RUN
	end
	self._autoRun = autoRun

	-- 是否重复滚屏
	self._repeatRun = self:GetWndArg("repeatRun")

	-- 当内容完了是否继续增加初始化内容
	local isAutoAdd = self:GetWndArg("isAutoAdd")
	if isAutoAdd == nil then
		isAutoAdd = UIOrdinBulletSay.AUTO_ADD
	end
	self._isAutoAdd = isAutoAdd

	-- 滚屏速度
	local moveSpeed = self:GetWndArg("moveSpeed")
	if not moveSpeed then
		moveSpeed = gModelChat:GetChatConfigRefByKey("textSpeed")
	end
	self._moveSpeed = moveSpeed

	-- 跳过敏感字检测
	self._jumpShield = self:GetWndArg("jumpShield") or false

	-- 最多可共存的弹幕条数
	local maxShowBarrage = self:GetWndArg("maxShowBarrage")
	if maxShowBarrage == nil then
		maxShowBarrage = UIOrdinBulletSay.MAX_SHOW_BARRAGE
	end
	self._maxShowBarrage = maxShowBarrage

	self._barrageTypeRegFunc = {
		[ModelHeroBook.BARRAGE_TYPE_HEROCOMMENT] = {
			msgFunc = function() self:NewPage() end,
		},
		[ModelHeroBook.BARRAGE_TYPE_HERORELATION] = {
			msgFunc = function() self:NewPage() end,
		},
		[ModelHeroBook.BARRAGE_TYPE_BAND_THEME] = {
			msgFunc = function() end,
		},
		[ModelHeroBook.BARRAGE_TYPE_OTHERBARRAGE] = {
			msgFunc = function() end,
		},
	}

	-- 当前显示的弹幕条数
	self._curBarrage = 0

	-- 创建的节点缓存
	self._userItemList = {}

	-- 发送的弹幕缓存，用于更新评论列表
	self._sendBarrageList = {}

	self._timerList = {}
	self._seqList = {}

	self._netIsOver = false

	self._lineSpacing  = 33

	-- 弹幕缓存
	self._barragePoolList = {}
	self._plyaerId = gModelPlayer:GetPlayerId()

	local areaTrans, template
	if barrageType == ModelHeroBook.BARRAGE_TYPE_BAND_THEME then
		areaTrans = self.mBandThemeArea
		template  = self.mBandThemeTemplate
	else
		areaTrans = self.mArea
		template  = self.mTemplate
	end
	self._areaTrans = areaTrans
	self._templateTrans = template

	local rectTran = areaTrans:GetComponent(typeRectTransform)
	if rectTran then
		self._width = rectTran.rect.width
		self._height = rectTran.rect.height
	else
		self._width = 640
		self._height = 830
	end
	rectTran = template:GetComponent(typeRectTransform)
	if rectTran then
		self._itemHeight = rectTran.rect.height
	else
		self._itemHeight = 0
	end

	local itemHeight = self._itemHeight or 0
	if itemHeight then
		itemHeight = 30
	end
	local canSetNum = math.ceil(self._height / itemHeight)
	self._canSetNum = math.ceil(canSetNum / 2)

	-- 可用位置
	self._usePosList = {}
end

function UIOrdinBulletSay:RefreshCommonBarrageList()
	local barrageList = self._barrageList or {}
	local barragePoolList = self._barragePoolList or {}
	local sendBarrageList = self._sendBarrageList or {}
	local repeatRun = self._repeatRun
	local list = {}
	local listKey = {} 				-- 同个id不会出现在同个列表里
	-- 获取评论缓存中剩下的数据
	for i,v in ipairs(barragePoolList) do
		local barrageKey = v.id
		listKey[barrageKey] = barrageKey
		table.insert(list,v)
	end
	-- 新增的评论数据
	for i,v in ipairs(sendBarrageList) do
		local barrageKey = v.id
		if not listKey[barrageKey] then
			listKey[barrageKey] = barrageKey
			table.insert(list,v)
		end
	end
	if repeatRun then
		-- 初始化评论数据
		for i,v in ipairs(barrageList) do
			local barrageKey = v.id
			if not listKey[barrageKey] then
				listKey[barrageKey] = barrageKey
				table.insert(list,v)
			end
		end
	end
	self._barragePoolList = list
end

function UIOrdinBulletSay:OnGetNewPage()
	local barrageType = self._barrageType
	if barrageType == ModelHeroBook.BARRAGE_TYPE_HEROCOMMENT
			or barrageType == ModelHeroBook.BARRAGE_TYPE_HERORELATION then
		local barrageTypeRegFunc = self._barrageTypeRegFunc
		if barrageTypeRegFunc then
			local barrageTypeInfo = barrageTypeRegFunc[barrageType]
			if not barrageTypeInfo then return end
			local msgFunc = barrageTypeInfo.msgFunc
			if msgFunc then msgFunc() end
		end
	end
end

function UIOrdinBulletSay:GetCommonCommentStruct(data)
	local text = data.text
--[[	text = LUtil.ChatInfoFaceDecToBin(text)
	local _msg = LWordMaskUtil.ClearShieldWord(text,false,nil,true)]]
	return {
		id = data.id or "",
		text = text or "",
		playerId = data.playerId or "",
	}
end

function UIOrdinBulletSay:NewPage()
	local refId = self._heroRefId
	if not refId then return end
	local oldIndex = self._oldIndex or 0
	if oldIndex ~= 0 then
		oldIndex = oldIndex + 1
	end
	local repNum = self._oneRepCommentNum - 1
	local newIndex = oldIndex + repNum
	local barrageType = self._barrageType
	if barrageType == ModelHeroBook.BARRAGE_TYPE_HEROCOMMENT then
		gModelHeroBook:OnHeroCommentListReq(refId,oldIndex,newIndex,ModelHeroBook.TYPE_BARRAGE)
	elseif barrageType == ModelHeroBook.BARRAGE_TYPE_HERORELATION then
		gModelHeroBook:OnRelationCommentListReq(refId,oldIndex,newIndex)
	end
end

function UIOrdinBulletSay:InitEvent()
	self:WndEventRecv(EventNames.ON_COMMON_BARRAGE_STATUS,function(status)
		self:TimerStop(self._barrageKey)
		self:TimerStop(self._barrageLoopKey)
		self:TimerStop(self._intervalKey)
		if status then
			self:RunBarrage()
		else
			if self._timerList then
				for k,v in pairs(self._timerList) do
					LxTimer.DelayTimeStop(v)
				end
			end
			self._timerList = {}
			if self._seqList then
				for k,v in pairs(self._seqList) do
					v:Kill(false)
				end
			end
			self._seqList = {}
			LxResUtil.DestroyChildImmediate(self._areaTrans)
            self._userItemList = {}
            self._curBarrage = 0
		end
	end)
	self:WndEventRecv(EventNames.SEND_COMMON_BARRAGE_LIST,function(list,star)
		if not self._getBarrageFromEvent then return end
		self._sendBarrageList = list
		if star == nil then star = true end
		if star == true then
			self:RunBarrage()
		end
	end)
	self:WndEventRecv(EventNames.CHANGE_COMMON_BARRAGE_INFO,function(info)
		self._heroRefId = info.heroRefId
		self._barrageType = info.barrageType
        self:TimerStop(self._barrageKey)
        self:TimerStop(self._barrageLoopKey)
		self:TimerStop(self._intervalKey)
		self:TimerStart(self._intervalKey,2,false,1)
	end)
end

function UIOrdinBulletSay:GetRelationCommentList(pb)
	local dataList = {}
	local commentInfo = pb.commentInfo
	for i,v in ipairs(commentInfo) do
		local commentData = self:GetCommonCommentStruct(v)
		table.insert(dataList,commentData)
	end
	self._sendBarrageList = dataList
	local numEnd = pb.numEnd
	local len = #commentInfo
	local oldIndex = self._oldIndex
	self:RefreshOldIndex(numEnd,len + oldIndex,true)
end

-- 创建弹幕
function UIOrdinBulletSay:CreateBarrage(data)
	local itemTemp = self._templateTrans
	local itemRoot = self._areaTrans
	local itemNew = table.remove(self._userItemList)
	if not itemNew then
		itemNew = LxResUtil.NewObject(itemTemp.gameObject)
		itemNew.transform:SetParent(itemRoot.transform, false)
	end
	local lineIndex = data.lineIndex
	local posY = -(lineIndex - 1) * (self._itemHeight + self._lineSpacing)
	if (posY * -1) > self._height then
		posY = self._height + posY
	end
	itemNew.transform.anchoredPosition = Vector3.New(self._width,posY,0)
	self._usePosList[lineIndex] = true

	local imageTrans = self:FindWndTrans(itemNew.transform,"Image")
	local textTran = self:FindWndTrans(imageTrans.transform,"text")
	local textImage = self:FindWndImage(imageTrans)

	local playerId = data.playerId
	local isSelf = playerId == self._plyaerId
	if textImage then
		textImage.enabled = isSelf or self._barrageType == ModelHeroBook.BARRAGE_TYPE_BAND_THEME
	end

	local color
	local colorList = self._colorList
	local len = #colorList
	if len ~= 0 then
		local randIdx = math.random(1,len)
		color = colorList[randIdx]
	end

	local msg = data.text
	msg = LUtil.FilterEmoji(msg,"?")

	local func = function(isMatch,newText)

		if self:IsWndClosed() then
			return
		end

		if isMatch then return end

		newText = LUtil.ChatInfoFaceBinToDec(newText)
		newText= LUtil.GetFaceStr(newText,32)

		local str
		if color then
			str = string.replace(ccClientText(17606),color,newText)
		else
			str = msg
		end
		self:SetWndText(textTran,str)
		CS.ShowObject(itemNew,true)

		local info = {
			item = itemNew,
			imageTrans = imageTrans,
			lineIndex = lineIndex,
			id = data.id
		}
		self:DelayTween(info)
	end

	if self._jumpShield then
		func(nil, msg)
	else
		LWordMaskUtil.ClearShieldWordEx(msg,false,true,LGameWordMask.SCENE_TYPE_PUBLIC_DATA,func)
	end

	--msg = LWordMaskUtil.ClearShieldWord(msg,false,nil,true)
	--msg = LUtil.ChatInfoFaceBinToDec(msg)
	--msg= LUtil.GetFaceStr(msg,32)
    --
	--local str
	--if color then
	--	str = string.replace(ccClientText(17606),color,msg)
	--else
	--	str = msg
	--end
	--self:SetWndText(textTran,str)
	--CS.ShowObject(itemNew,true)
    --
	--local info = {
	--	item = itemNew,
	--	imageTrans = imageTrans,
	--	lineIndex = lineIndex,
	--	id = data.id
	--}
	--self:DelayTween(info)
end

function UIOrdinBulletSay:OnTimer(key)
	if key == self._barrageKey then
		self:OnSatrtBarrage()
	elseif key == self._barrageLoopKey then
		self:RefreshCommentList()
	elseif key == self._intervalKey then
		self:RefreshCommentList()
	end
end

function UIOrdinBulletSay:Refresh()
	if not self._autoRun then return end
	local barrageType = self._barrageType
	if barrageType == ModelHeroBook.BARRAGE_TYPE_HEROCOMMENT
			or barrageType == ModelHeroBook.BARRAGE_TYPE_HERORELATION then
		self:OnGetNewPage()
	else
		self:RunBarrage()
	end
end

function UIOrdinBulletSay:StopClickDropTimer()
	if self._delayClickDropTimer then
		LxTimer.DelayTimeStop(self._delayClickDropTimer)
		self._delayClickDropTimer = nil
	end
end

function UIOrdinBulletSay:GetHeroCommentList(pb)
	local dataList = {}
	local comments = pb.comments
	for i,v in ipairs(comments) do
		local commentData = gModelHeroBook:GetGeneralHeroCommentInfoFromPb(v)
		table.insert(dataList,commentData)
	end
	self._sendBarrageList = dataList
	local numEnd = pb.numEnd
	local len = #comments
	local oldIndex = self._oldIndex
	self:RefreshOldIndex(numEnd,len + oldIndex,true)
end

function UIOrdinBulletSay:InitMsg()
	self:WndNetMsgRecv(LProtoIds.HeroCommentListResp,function (pb)
		local openType = pb.openType
		if openType == ModelHeroBook.TYPE_BARRAGE then
			local repHeroRefId = self._heroRefId
			local heroRefId = pb.heroRefId
			if heroRefId ~= repHeroRefId then return end
			self:GetHeroCommentList(pb)
		end
	end)
	self:WndNetMsgRecv(LProtoIds.RelationCommentListResp,function (pb)
		local repHeroRefId = self._heroRefId
		local heroRefId = pb.relationRefId
		if heroRefId ~= repHeroRefId then return end
		self:GetRelationCommentList(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.HeroForCommentResp,function()
		self:RefreshCommentList(true)
	end)
	self:WndNetMsgRecv(LProtoIds.RelationForCommentResp,function()
		self:RefreshCommentList(true)
	end)
end

-- 回收Item
function UIOrdinBulletSay:ReturnToPool(item)
	CS.ShowObject(item,false)
	table.insert(self._userItemList, item)
end

function UIOrdinBulletSay:RunBarrage(netWork)
	local barrageType = self._barrageType
	if barrageType == ModelHeroBook.BARRAGE_TYPE_HEROCOMMENT
			or barrageType == ModelHeroBook.BARRAGE_TYPE_HERORELATION then
		self:RefreshBarrageList(netWork)
	else
		self:RefreshCommonBarrageList()
	end

	self:TimerStop(self._barrageKey)
	self:TimerStart(self._barrageKey,self._cd,false,-1)

	if self._isQuicklyCreate then
		self._isQuicklyCreate = false
		self:OnSatrtBarrage()
	end
end

function UIOrdinBulletSay:RefreshOldIndex(newIndex,len,netWork)
	local oldIndex = self._oldIndex
	self._oldIndex = newIndex
	self._netIsOver = oldIndex == len

	if self._heroRefId then
		local showBarrage
		if self._barrageType == ModelHeroBook.BARRAGE_TYPE_HEROCOMMENT then
			showBarrage = gModelHeroBook:GetBarrageStatus()
		elseif self._barrageType == ModelHeroBook.BARRAGE_TYPE_HERORELATION then
			showBarrage = gModelHeroBook:GetRelationBarrageStatus()
		end
		if not showBarrage then
			self:TimerStop(self._barrageKey)
			return
		end
	end
	self:RunBarrage(netWork)
end

function UIOrdinBulletSay:LoopStarTime()
	self:TimerStop(self._barrageLoopKey)
	if self._netIsOver then
		self:TimerStart(self._barrageLoopKey,self._loopCd,false,1)
	else
		self:OnGetNewPage()
	end
end
------------------------------------------------------------------
return UIOrdinBulletSay


