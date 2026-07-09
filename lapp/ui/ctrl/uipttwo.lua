---
--- Created by Administrator.
--- DateTime: 2023/10/11 17:43:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPtTwo:LWnd
local UIPtTwo = LxWndClass("UIPtTwo", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPtTwo:UIPtTwo()

	self:SetHideHurdle()
	self:SetHideBottom()
	self:SetHideTop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPtTwo:OnWndClose()

	--if self._seqCom then
	--	self._seqCom:Destroy()
	--	self._seqCom = nil
	--end
	--print("UIPtTwo:OnWndClose()")

	FireEvent(EventNames.HIDE_WND_BY_PLOT,false)


	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPtTwo:OnCreate()
	LWnd.OnCreate(self)

	--self._seqCom = SequenceCom:New()


	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPtTwo:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitUIEvent()
	self.otherData = self:GetWndArg("otherData")
	self:SetWndText(self.mTitle_1,ccClientText(16764))
	self:OnWndRefresh()

	FireEvent(EventNames.HIDE_WND_BY_PLOT,true)


	self:AddWndAniCallbackList(function ()
		if LOG_INFO_ENABLED then
			print("wndplottwo hide guide wnd")
		end
		local wnd = GF.FindFirstWndByName("UIGue")
		if wnd then
			wnd:SetGuideWndVisible(false)
		end
	end)

end

function UIPtTwo:SetSpineColor(spine)
	if self.otherData and self.otherData.hideSpine then
		spine:SetColor(Color.New(0, 0, 0, 1))
	else
		spine:SetColor(Color.New(1, 1, 1, 1))
	end
end

function UIPtTwo:OnWndRefresh()
	self._plotId = self:GetWndArg("plotId")
	self._heroEffectRef = self:GetWndArg("heroEffectRef")

	self._closeFunc = self:GetWndArg("closeFunc")

	CS.ShowObject(self.mBtnClose,self._closeFunc~= nil)

	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_STORY,nil,self._plotId)
	FireEvent(EventNames.ON_PLOT_EVENT_START, self._plotId)

	if LOG_INFO_ENABLED then
		printInfoN(string.format("cur plot id %s",self._plotId))
	end
	local cfg = gModelPlot:GetPlotCfg(self._plotId)
	if not cfg then
		LogError("UIPtTwo:RefreshUI()  cfg is nil! plotId = "..tostring(self._plotId or 0))
		return
	end

	local selectList = gModelPlot:GetSelectList(self._plotId)
	local showPop = true
	if not selectList then
		showPop = false
	end

	CS.ShowObject(self.mSkipBtn,not showPop)

	self._select = 0

	CS.ShowObject(self.mSelelct,showPop)
	CS.ShowObject(self.mBottom,not showPop)
	if showPop then
		local itemList = self:GetUIScroll("selectList")
		itemList:Create(self.mItemList,selectList,function (...) self:OnDrawSelect(...)  end)
	end

	self._isPop = showPop

	if showPop then
		return
	end

	local name = ccLngText(cfg.name)
	local t = {
		["a1"] = gModelPlayer:GetPlayerName()
	}

	name = string.gsub(name,"#(%w+)#",t)


	local content = gModelPlot:GetRolePlotText(self._plotId)
	self._words = content

	local sound = cfg.soundP

	local paint = tonumber(cfg.paint)
	if paint == 1 then
		local sex = gModelPlayer:GetPlayerSex()
		paint = gModelPlot:GetPlotPaint(sex)
		if sex == 1 and not string.isempty(sound) then
			sound = sound..'_1'
		end
	end

	if not string.isempty(sound) then
		gLGameAudio:PlaySingleSound(sound)
	end
	local spineName,posY,scale = gModelPlayer:GetRoleAdventurePaint(paint)
	local pos = tonumber(cfg.action)
	pos = Mathf.Clamp(pos,0,4)
	local nextPos = tonumber(cfg.action1)
	nextPos = Mathf.Clamp(nextPos,0,4)
	local direction = cfg.direction
	local posX = cfg.storyX
	scale = scale ==0 and 1 or scale
	local offset = Vector3.New(posX,posY,0)
	if self._heroEffectRef and not string.isempty(self._heroEffectRef.heroDrawing) then
		spineName = self._heroEffectRef.heroDrawing
	end
	self:ShowRole(spineName,pos,direction,offset,scale,paint)
	if self.otherData and not string.isempty(self.otherData.plotTitle) then name = self.otherData.plotTitle end
	local noName = string.isempty(name)

	CS.ShowObject(self.mTitleBg,not noName)
	self:SetWndText(self.mName,name)
	local titleType = cfg.nameBg
	local titleIcon = self._titleBgList[titleType]
	if titleIcon then
		self:SetWndEasyImage(self.mTitleBg,titleIcon)
	end

	--CS.ShowObject(self.mTitleBg,titleIcon ~= nil)


	self._hasNext = gModelPlot:HasNextPlot(self._plotId)

	local delayTime =gModelPlot:GetPara("plotJump")
	self._endTime = GetTimestamp() + delayTime
	self:TimerStop(self._delayTimer)
	self:TimerStart(self._delayTimer,1,false,-1)
	self:SetCountDown()


	self._oldData = {
		spineName = spineName,
		pos = pos,
		nextPos = nextPos,
		offset = offset,
		scale = scale,
		paint = paint,
	}
end

function UIPtTwo:OnTimer(key)
	if self._delayTimer == key then
		self:SetCountDown()
	end
end

function UIPtTwo:OnDrawSelect(list,item,itemdata,itempos)
	local bg = self:FindWndTrans(item,"bg")
	local text = self:FindWndTrans(item,"text")

	self:SetWndText(text,itemdata.buttonStr)
	self:InitTextLineWithLanguage(text, -30)

	local isSelect = itempos == self._select
	local state = isSelect and 1 or 2

	self:SetImageActorState(bg,state)

	self:SetWndClick(item,function ()
		self:OnClickSelect(itemdata)
	end)

end


function UIPtTwo:ShowSaying(name,str)
	self:SetWndText(self.mContent,str)
	self:SetWndText(self.mName,name)

end

function UIPtTwo:MoveToPos(tran,pos,speed,useCurPos,offset,uniqueKey)
	if CS.IsNullObject(tran) then
		return
	end
	local key = uniqueKey
	if not key then
		return
	end

	local targetPos = self._roleRootList[pos] + offset
	local startOffset = Vector3.New(-200,0,0)
	if pos>1 then
		startOffset = Vector3.New(200,0,0)
	end
	local startPos = targetPos + startOffset

	if not useCurPos then
		tran.localPosition = startPos
	end

	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq(key)
	local duration = 0.5 /speed
	duration = Mathf.Clamp(duration,0.1,3)
	local tween = tran:DOLocalMove(targetPos,duration)
	seq:Append(tween)
	seq:OnKill(function ()
		if CS.IsValidObject(tran) then
			tran.localPosition = targetPos
		end
	end)
	seq:PlayForward()


	seqCom:DeleteSeq("textTween")

end


function UIPtTwo:InitUIEvent()
	self:SetWndClick(self.mMask,function ()

		if self._isCreating then --小人创建中，不能下一步，防止报错
			return
		end

		if self._isTweening then
			local seqCom = self:GetSeqCom()
			seqCom:DeleteSeq("textTween")
			return
		end

		if not self._isPop then
			gModelPlot:NextPlot(self._closeFunc)
		end
	end)

	self:SetWndClick(self.mSkipBtn,function ()

		gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_SKIP,nil,self._plotId)

		gModelPlot:OnClickSkip(self._plotId,self._closeFunc)
	end)

	self:SetWndClick(self.mBtnClose,function ()
		gModelPlot:StopPlot()
		self:WndClose()
		if self._closeFunc then
			self._closeFunc()
		end
	end)
end

function UIPtTwo:SetSpineActive(spine,isActive,scale)
	local rscale =scale * 0.9
	local color = Color.New(0.4,0.4,0.4,1)
	if isActive then
		color = Color.New(1,1,1,1)
		rscale = scale
	end
	spine:SetColor(color)
	spine:SetScale(rscale)

	local timeScale = 1
	if not isActive then
		timeScale = 0

	end
	spine:SetAnimationTimeScale(timeScale)

	if isActive then
		local tran = spine:GetDisplayTrans()
		if CS.IsValidObject(tran) then
			tran:SetAsLastSibling()
		end
	end
end

function UIPtTwo:SetTextContent(str)

	local t = {
		["a1"] = gModelPlayer:GetPlayerName()
	}

	str = string.gsub(str,"#(%w+)#",t)

	local len,itor = LUtil.FormatPrinterData(str)

	self._isTweening = true


	local perTime = gModelPlot:GetPara("storyWriting") /1000
	local time = len* perTime
	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq("textTween")
	local tween = YXTween.TweenInt(0,len,time,function (value)
		local temp = itor(value) or ""
		--printInfoN("str ------------ "..temp)
		self:SetWndText(self.mContent,temp)
	end)
	seq:Append(tween)
	seq:SetAutoKill(true)
	seq:OnKill(function ()
		self:SetWndText(self.mContent,str)
		self._isTweening = false
	end)
	seq:PlayForward()
end


function UIPtTwo:OnClickSelect(itemdata)

	local nextId = itemdata.next
	gModelPlot:NextSelectPlot(nextId,self._closeFunc)

end

function UIPtTwo:InitData()

	self._delayTimer = "_delayTimer"

	self._roleRootList =
	{
		[0] = self.mPos_0.localPosition,
		[1] = self.mPos_1.localPosition,
		[2] = self.mPos_2.localPosition,
		[3] = self.mPos_3.localPosition,
		[4] = self.mPos_4.localPosition,
	}

	self._titleBgList =
	{
		[0] = "plot_title_3",
		[1] = "plot_title_1",
		[2] = "plot_title_2"
	}
	self._roleRecord = {}

end

function UIPtTwo:SetCountDown()
	local timeLeft = self._endTime - GetTimestamp()
	timeLeft = math.ceil(timeLeft)
	if timeLeft<= 0 then
		if not self._isPop then
			gModelPlot:NextPlot(self._closeFunc)
			return
		end
	end


	local str = nil
	if not self._hasNext then
		str = ccClientText(21601)
	else
		str =ccClientText(21600) --"点击继续,%s秒后自动播放下一条"
	end
	str = string.replace(str,timeLeft)
	self:SetWndText(self.mTipText,str)

end
function UIPtTwo:IsSceneRoleGray()

end


function UIPtTwo:ShowRole(spineName,pos,direction,offset,scale,paint)


	if self._oldData then
		local lastSpineKey = self._oldData.paint
		if lastSpineKey then
			local lastSpine = self:FindWndSpineByKey(lastSpineKey)
			if lastSpine then
				self:SetSpineActive(lastSpine,false,self._oldData.scale)

				if self._oldData.nextPos then
					self._roleRecord[self._oldData.pos] = nil
					local curSpinekey = self._roleRecord[self._oldData.nextPos]
					if curSpinekey then
						local seqCom = self:GetSeqCom()
						seqCom:DeleteSeq(curSpinekey)
						self:DestroyWndSpineByKey(curSpinekey)
					end
					self._roleRecord[self._oldData.nextPos] = self._oldData.paint
					local tran = lastSpine:GetDisplayTrans()
					local speed = gModelPlot:GetPara("storyRoleSpeed")
					self:MoveToPos(tran,self._oldData.nextPos, speed,true,self._oldData.offset,self._oldData.paint)
				end
			end
		end
	end

	local noNew = string.isempty(spineName) or (pos<1 or pos >3)
	local canvasGroup = self:GetCanvasGroup(self.mMask)
	canvasGroup.alpha = noNew and 0 or 1

	printInfoN(string.format("cur spine %s,%s",spineName,pos))

	if not spineName then
		return
	end



	local oldSpineKey = self._roleRecord[pos]
	local key = paint
	if oldSpineKey == key then
		local dp = self:FindWndSpineByKey(key)
		if dp then
			self:SetSpineActive(dp,true,scale)
			dp:SetFlipX(direction == 1)
			self:SetSpineColor(dp)
		end

		self:SetTextContent(self._words)
	else
		local speedKey = "storyRoleSpeed"..pos
		local speed = gModelPlot:GetPara(speedKey)
		speed = speed or 1

		local seqCom = self:GetSeqCom()
		seqCom:DeleteSeq(oldSpineKey)
		self:DestroyWndSpineByKey(oldSpineKey)


		self._isCreating = true

		local loadedFun = function (spine)
			local tran = spine:GetDisplayTrans()
			spine:SetFlipX(direction == 1)
			spine:SetScale(scale)
			self:MoveToPos(tran,pos,speed,false,offset,paint)
			self:SetTextContent(self._words)
			self:SetSpineColor(spine)
			spine:PlayAnimationSolid("idle",true)
			self._isCreating = false
		end
		local spine = self:FindWndSpineByKey(key)
		if spine then
			loadedFun(spine)
			self._isCreating = false
		else
			self:CreateWndSpine(self.mRoleRoot,spineName,key,nil,loadedFun)
		end

	end

	self._roleRecord[pos] = paint

end

------------------------------------------------------------------
return UIPtTwo


