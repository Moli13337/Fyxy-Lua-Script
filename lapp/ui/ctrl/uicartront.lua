---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UICartront:LWnd
local UICartront = LxWndClass("UICartront", LWnd)
local typeof = typeof
local YXTween = YXTween
local typeofXUIMelt = typeof(CS.YXUIMelt)
local typeofXUIText = typeof(CS.YXUIText)
local typeUIImage = typeof(UnityEngine.UI.Image)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
UICartront.LeftToRight 		    = 1
UICartront.RightToLeft			    = 2
UICartront.TopToBtton				= 3
UICartront.BttonToTop				= 4
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UICartront:UICartront()
	self._pageImgList = {}			--事件17控制的图片预制体
	self._textList = {}				--事件19控制的图片预制体
	self._spineList = {}			--事件22控制的spine预制体
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UICartront:OnWndClose()
	if self._itemPool then
		self._itemPool:Destroy()
		self._itemPool = nil
	end
	if self._textPool then
		self._textPool:Destroy()
		self._textPool = nil
	end
	if self._spinePool then
		self._spinePool:Destroy()
		self._spinePool = nil
	end
	LWnd.OnWndClose(self)
	self:ClearTimerClose()

	self:StopVideo()

	--FireEvent(EventNames.ON_CARTOON_END)
	FireEvent(EventNames.CHECK_POP_WND)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UICartront:OnCreate()
	LWnd.OnCreate(self)
	self:SetAutoAdjustNotch(1)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UICartront:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self._screenWidth=self.mLayePage.rect.width
	self._screenHeight=self.mLayePage.rect.height
	local itempool = UIObjPool:New()
	itempool:Create(self.mTemplates,self.mImgPrefab)
	self._itemPool = itempool
	local textpool = UIObjPool:New()
	textpool:Create(self.mTemplates,self.mTextPrefab)
	self._textPool = textpool
	local spinepool = UIObjPool:New()
	spinepool:Create(self.mTemplates,self.mSpinePrefab)
	self._spinePool = spinepool
	self:InitData()

	self._startTime = GetTimestamp()

	self:StartTaTimer()
end

function UICartront:OnTimer(key)
	if key == "delayClose" then
		self:WndClose()
	elseif key == self._taTimer then
		self:CheckSendTaData()
	end
end

---延迟执行----------------------------------------------------------------------
function UICartront:OnTimerFun()
	self:ExecuteEvent(self.nexStepId)
end

function UICartront:StartDelayTimerClose(time, unscale)
	self:ClearTimerClose()
	if time<=0 then
		self:OnTimerFun()
		return
	end
	if self._timerClose == nil then
		local iTimeOut = time
		self._timerClose = LxTimer.DelayTimeCall(function()
			self:OnTimerFun()
		end, iTimeOut, unscale)
	end
end

function UICartront:StartTaTimer()
	local isSetting = self:GetWndArg("isSetting")
	if isSetting then
		return
	end
	self:TimerStop(self._taTimer)
	self:TimerStart(self._taTimer,1,false,-1)
end
function UICartront:GetTextNew(pid)
	local itemNew = self._textList[pid]
	if itemNew then return itemNew end
	itemNew = self._textPool:GetObj()
	local itemRoot = self.mLayePage
	itemNew.transform:SetParent(itemRoot.transform, false)
	CS.ShowObject(itemNew,true)
	self._textList[pid] = itemNew
	return itemNew
end

function UICartront:SendTaSkip()
	local isSetting = self:GetWndArg("isSetting")
	if isSetting then
		return
	end

	local isStory = self:GetWndArg("isStartStory")
	if isStory then
		return
	end

	--local timePast = math.floor(GetTimestamp() - self._startTime)
	--gLxTKData:OnTAClientEventReq(LxTKData.SYS_GUIDE,"1",timePast) --跳过CG
	gLxTKData:NoviceStepReq(1)
end

function UICartront:OnSkipBtn()

	if self._isClickSkip then
		return
	end

	if self._isStartStory then
		local curStep = self._curStepId or 0
		if curStep > 0 then
			local lastStep = gModelPlot:GetLastStepId(curStep)
			FireEvent(EventNames.ON_STORY_STEP_FINISH,lastStep)
		end

		gModelPlot:RecordStep(ModelPlot.START_TYPE_1,0)
	end

	local isSetting = self:GetWndArg("isSetting")
	if not isSetting then
		local stepId = gModelPlot:GetCartoonStep()
		local isFirstCartoon = stepId == self:GetWndArg("stepId") --开场过场

		if isFirstCartoon then

			local isFromFront = self:GetWndArg("isFromFront") --前置小游戏
			GF.OpenWnd('UIPerCreateName', {isNew = true,isFromFront = isFromFront})

			-- 尝试静默下载整包资源
			if gLGameUpdate:IsSetupUpdate() then
				gLGameUpdate:CheckTargetPartDownload()
			end
		end


	end
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_CG,"end")
	self:StopVideo()
	self:ClearTimerClose()
	self.nexStepId=0
	if self:IsWndClosed() then
		return
	end
	self:TimerStop("delayClose")
	self:TimerStart("delayClose",isSetting and 0.3 or 1,false,1)

	self._isClickSkip = true
end
function UICartront:GetSpineNew(pid)
	local itemNew = self._spineList[pid]
	if itemNew then return itemNew end
	itemNew = self._spinePool:GetObj()
	local itemRoot = self.mLayePage
	itemNew.transform:SetParent(itemRoot.transform, false)
	CS.ShowObject(itemNew,true)
	self._spineList[pid] = itemNew
	return itemNew
end

--页切换
function UICartront:CutPage(trans,cutTime,fromDir,_move,isAlpha)
	local seqTween
	self:TweenSeqKill(self._topRightKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._topRightKey,function(seq)
			local canvasGroup = trans:GetComponent(typeofCanvasGroup)
			if(canvasGroup and isAlpha~=nil) then
				local fromAlpha,toAlpha
				if isAlpha then
					fromAlpha=1
					toAlpha=0
				else
					fromAlpha=0
					toAlpha=1
				end
				local _temp = YXTween.TweenFloat(fromAlpha, toAlpha, cutTime, function(ival)
					canvasGroup.alpha = ival
				end)
				seq:Join(_temp)
			end

			local vec,tweener
			local moveX=0
			local moveY=0
			if (fromDir == UICartront.LeftToRight) then
				moveX=_move
			elseif (fromDir == UICartront.RightToLeft) then
				moveX=-_move
			elseif (fromDir==UICartront.TopToBtton)then
				moveY =-_move
			elseif (fromDir==UICartront.BttonToTop)then
				moveY =_move
			end
			vec = Vector2.New(trans.localPosition.x + moveX  , trans.localPosition.y+moveY)
			tweener = trans:DOLocalMove(vec,cutTime)
			seq:Join(tweener)
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		CS.ShowObject(trans,false)
		self:TweenSeqKill(self._topRightKey)
	end)
end

function UICartront:StopVideo()
	if self._videoPath then
		gLGameVideo:StopVideo(nil,self._videoPath)
		self._videoPath = nil
	end
end

--页缩放
function UICartront:ScalePage(_tansList,_to,_time)
	local seqTween
	self:TweenSeqKill(self._toScaleKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._toScaleKey,function(seq)
			for i = 1,#_tansList do
				local trans = _tansList[i]
				local vec = Vector3.New(_to[i],_to[i],_to[i])
				local tweener = trans:DOScale(vec,_time[i])
				seq:Join(tweener)
			end
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()

		self:TweenSeqKill(self._toScaleKey)
	end)
end

function UICartront:InitData()
	self._taTimer = "_taTimer"
	self._topRightKey = "Move"
	self._toScrollKey = "ToScroll"
	self._toScaleKey = "ToScale"
	self._toAplhaKey="ToAplha"
	self._btnTopSpacing= self.mLayePage.rect.width
	self._toPageList = {
		self.mPage1,
		self.mPage2,
		self.mMelt
	}
	self._toPageImageList = {
		self.mPage1:GetComponent(typeUIImage),
		self.mPage2:GetComponent(typeUIImage),
		self.mMelt:GetComponent(typeUIImage),
	}
	self._textObjList={}
	self._page1Melt=self.mMelt:GetComponent(typeofXUIMelt)
	--读表数据
	local stepId=self:GetWndArg("stepId")
	self._isNew  = self:GetWndArg("isNew")
	self._isStartStory = self:GetWndArg("isStartStory")

	printInfoN("start story")

	self._isClickSkip = false

	local normalStart = true
	if self._isStartStory then
		if gModelGuide:IsMeetJumpNewPlot() then
			normalStart = false
			local func = function()
				gModelGuide:GuideJumpReq(1,1)
				GF.CloseWndByName("UICartront")
			end

			local cancelFunc = function()
				gModelGuide:GuideJumpReq(1,0)
				self:ExecuteEvent(stepId)
			end

			local refId = 170011
			gModelGeneral:OpenUIOrdinTips({refId = refId,func = func, leftFunc = cancelFunc, closeFunc = cancelFunc},nil,nil,true)
		end
	end

	if normalStart then
		self:ExecuteEvent(stepId)
	end
end

function UICartront:InitEvent()
	CS.ShowObject(self.mImageBtnObj,false)
	local showSkip = not gLGameUpdate:IsSilenceDownload()
	CS.ShowObject(self.mSkipBtn,showSkip)
	CS.ShowObject(self.mScreenBtn,not showSkip)

	self:SetWndClick(self.mImageBtnObj,function(...) self:OnTimerFun() end)
	self:SetWndClick(self.mScreenBtn,function(...) self:OnSpeedFun() end)
	self:SetWndClick(self.mSkipBtn,function(...)
		gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_SKIP)

		self:SendTaSkip()
		self:OnSkipBtn()
	end)
end

--执行事件
function UICartront:ExecuteEvent(stepId)

	self._finishStepId = self._curStepId
	self._curStepId = stepId

	if self._isStartStory and stepId then
		local finishStep = self._finishStepId or 0
		if finishStep > 0 then
			FireEvent(EventNames.ON_STORY_STEP_FINISH,finishStep)
		end
		gModelPlot:RecordStep(ModelPlot.START_TYPE_1,stepId)
	end

	if stepId==nil or stepId==0 or self._cartoonEnd==true then
		return
	end


	self.storyStepRef = GameTable.StoryStepRef--触发表
	local stepRef=self.storyStepRef[stepId]--当前
	local event=stepRef.event--事件
	local content=stepRef.content--内容（或 图片名、特效名、文本、基本参数）
	local nextTime=stepRef.nextTime--延迟的时间
	local nexStep=stepRef.nextStep--下一步
	local lastTime=stepRef.lastTime--持续时间

	local unscale = nil

	if(self._jumpStepBool==true)then
		local jumpStepStr=stepRef.jumpStep--要跳的步骤
		local jumpStepArr=string.split(jumpStepStr,"=")
		self._jumpStepBool=false
		self._jumpStep=tonumber(jumpStepArr[1])
		self.jumpStepEven=tonumber(jumpStepArr[2])
	end

	if  self._jumpStep~=nil  then

		if self.jumpStepEven==1 and self._jumpStep==stepId then
			self._jumpStep=nil
			self._page1Melt:OnSkipVlaue(1)
		elseif self.jumpStepEven==2 and self._jumpStep==stepId then
			lastTime="0"
			self._jumpStep=nil
			self._page1Melt:OnSkipVlaue(1)
		else
			lastTime="0"
			nextTime=0.1
		end
	end
	local timeArry=string.split(lastTime,",")
	lastTime=tonumber(timeArry[1])
	local keyName=stepRef.name--引用
	local res=stepRef.res--资源名
	local posiX=stepRef.x--出现坐标x
	local posiY=stepRef.y--出现坐标y
	local layer=stepRef.layer--层
	local other=stepRef.other--其他参数
	local appearType=stepRef.appearType--出现和消失方式
	if self.nexStepId~=nil then
		self._oldStepId=self.nexStepId
	end
	self.nexStepId= nexStep
	local trans,keyNum,toArry

	if event==1 then
		if GF.FindFirstWndByName(res) then
			GF.CloseWndByName(res)
		end
	elseif event==2 then
		self:CreateWndEffect(self.mEffParentTrans,res,keyName,100,false,false)
		self.mEffParentTrans.localPosition=Vector2.New(posiX ,posiY)
		self.mEffParentTrans:SetSiblingIndex(layer)
	elseif event==3 or event==13 then
		keyNum=tonumber(keyName)
		trans=self._toPageList[keyNum]
		trans.sizeDelta=Vector2.New(self._screenWidth,self._screenHeight)
		self:SetWndEasyImage(trans,res,function()
			trans.localPosition=Vector2.New(posiX ,posiY)
			CS.ShowObject(trans,true)
			trans:SetSiblingIndex(layer)
			trans.localScale=Vector3.one
			if(keyNum==3)	then
				self._page1Melt:OnSetFloatVlaue("_Threshold",0)
			end
			if event == 13 then
				local uiPageImage=self._toPageImageList[keyNum]
				uiPageImage:SetNativeSize()
			end
			self:GesetCanvasGroupAlpha(trans)
			if appearType==2 then
				self:SetTextAlphaTween(trans ,false,lastTime,keyName)
			elseif(appearType==3)then
				self:CutPage(trans,lastTime,UICartront.LeftToRight,self._btnTopSpacing,false)
			end
		end
		)
	elseif event==14 then
		other=tonumber(other)
		self._page1Melt:CutIndexMaterial(other or 0)
		self._page1Melt:OnSetLerpVlaue("_Threshold",0,1,lastTime)
	elseif event==4 then
		keyNum=tonumber(keyName)
		trans=self._toPageList[keyNum]
		if appearType==2 then
			self:SetTextAlphaTween(trans,true,lastTime,keyName)
		elseif(appearType==3)then
			self:CutPage(trans,lastTime,UICartront.RightToLeft,self._btnTopSpacing,true)
		else
			CS.ShowObject(trans,false)
		end
	elseif event==5 then
		trans=self._textObjList[keyName]
		if trans ==nil then
			trans=LxResUtil.NewObject(self.mTextBg)
			self._textObjList[keyName]=trans
			CS.SetParentTrans(trans,self.mTextParentTrans)
		end
		CS.ShowObject(trans,true)
		trans.localPosition=Vector2.New(posiX,posiY)
		self.mTextParentTrans:SetSiblingIndex(layer)
		local tanrTest = CS.FindTrans(trans,"textXUIText"):GetComponent(typeofXUIText)
		self:GesetCanvasGroupAlpha(trans)
		self:SetWndEasyImage(trans,res)
		self:SetXUITextText(tanrTest, ccLngText(content))
		if appearType==2 then
			self:SetTextAlphaTween(trans,false,lastTime,keyName)
		end
	elseif event==6 then
		trans=self._textObjList[keyName]
		if appearType==2 then
			self:SetTextAlphaTween(trans,true,lastTime,keyName)
		else
			CS.ShowObject(trans,false)
		end
	elseif event==8 or event==7 then
		local keyArry = string.split(keyName,",")
		toArry = string.split(other,",")
		local list ={}
		local toList={}
		local timeList={}
		for k,v in pairs(keyArry) do
			keyNum=tonumber(v)
			local trans = self._toPageList[keyNum]
			list[k]=trans
			toList[k]=tonumber(toArry[k])
			timeList[k]=tonumber(timeArry[k]or "0.1")
		end
		self:ScalePage(list,toList,timeList)
	elseif event==9 then
		trans=self.mViewport
		CS.ShowObject(trans,true)
		local uiTextTrans=CS.FindTrans(trans,"XUIText")
		local uiText = uiTextTrans:GetComponent(typeofXUIText)
		self:SetXUITextText(uiText, ccLngText(content))
		toArry = string.split(other,",")
		trans.localPosition=Vector2.New(posiX,posiY)
		trans:SetSiblingIndex(layer)
		trans.sizeDelta=Vector2.New(tonumber(toArry[1]),tonumber(toArry[2]))
		uiTextTrans.localPosition = Vector2.New(uiTextTrans.localPosition.x,-(uiTextTrans.rect.height/2+trans.rect.height))
		local move=uiTextTrans.rect.height + trans.rect.height
		self:CutPage(uiTextTrans,lastTime,UICartront.BttonToTop,move)
	elseif event==10 then
		self:OnSkipBtn()
		self._cartoonEnd=true
		return
	elseif event==11 then
		CS.ShowObject(self.mImageBtnObj,true)
		CS.ShowObject(self.mScreenBtn,false)
		return
	elseif event==12 then

	elseif event==15 then
		CS.ShowObject(self.mSkipBtn,not gLGameUpdate:IsSilenceDownload())
	elseif event==16 then
		gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_CG,"start")
		self._videoPath = res
		gLGameVideo:PlayVideoClipUI(res,nil,self.mVideoMan,self:GetWndArg("isNew"))
		unscale = true
	elseif event == 17 then
		trans = self:GetItemNew(keyName)
		self:SetWndEasyImage(trans,res,function()
			CS.ShowObject(trans,true)
			trans.localPosition = Vector2.New(posiX ,posiY)
			trans.localScale = Vector3.one
			trans:SetSiblingIndex(layer)
			local uiPageImage = trans:GetComponent(typeUIImage)
			if uiPageImage then uiPageImage:SetNativeSize() end
			if other == "1" then
				self:SetTrAnchors(trans,Vector2.New(0,1))
			elseif other == "2" then
				self:SetTrAnchors(trans,Vector2.New(0.5,0.5))
			elseif other == "3" then
				self:SetTrAnchors(trans,Vector2.New(1,0))
			end
			if appearType ~= 0 then
				self:GesetCanvasGroupAlpha(trans,0)
			end
			if appearType == 2 then
				self:SetTextAlphaTween(trans ,false,lastTime,keyName)
			elseif appearType == 3 then
				self:CutPage(trans,lastTime,UICartront.LeftToRight,self._btnTopSpacing,false)
			end
		end
		)
	elseif event == 18 then
		trans = self._pageImgList[keyName]
		if appearType==2 then
			self:SetTextAlphaTween(trans,true,lastTime,keyName)
		elseif(appearType==3)then
			self:CutPage(trans,lastTime,UICartront.RightToLeft,self._btnTopSpacing,true)
		else
			CS.ShowObject(trans,false)
		end
	elseif event == 19 then
		trans = self:GetTextNew(keyName)
		CS.ShowObject(trans,true)
		trans.localPosition = Vector2.New(posiX,posiY)
		trans:SetSiblingIndex(layer)
		local tanrTest = trans:GetComponent(typeofXUIText)
		self:SetXUITextText(tanrTest, ccLngText(content))
		if appearType ~= 0 then
			self:GesetCanvasGroupAlpha(trans,0)
		end
		if appearType == 2 then
			self:SetTextAlphaTween(trans,false,lastTime,keyName)
		end
	elseif event == 20 then
		trans = self._textList[keyName]
		if appearType == 2 then
			self:SetTextAlphaTween(trans,true,lastTime,keyName)
		else
			CS.ShowObject(trans,false)
		end
	elseif event == 21 then
		trans = self:GetItemNew(keyName)
		self:SetWndEasyImage(trans,res,function()
			CS.ShowObject(trans,true)
			trans.localPosition = Vector2.New(posiX ,posiY)
			trans.localScale = Vector3.one
			local text = self:FindWndTrans(trans,"UIText")
			if text then
				self:SetWndText(text, ccLngText(content))
			end
			trans:SetSiblingIndex(layer)
			local uiPageImage = trans:GetComponent(typeUIImage)
			if uiPageImage then uiPageImage:SetNativeSize() end
			if appearType ~= 0 then
				self:GesetCanvasGroupAlpha(trans,0)
			end
			if appearType == 2 then
				self:SetTextAlphaTween(trans ,false,lastTime,keyName)
			elseif appearType == 3 then
				self:CutPage(trans,lastTime,UICartront.LeftToRight,self._btnTopSpacing,false)
			end
		end
		)
		if not string.isempty(other)then
			self:SetIconClickScale(trans, true)
			self:SetWndClick(trans,function ()

				self:ExecuteEvent(self.nexStepId)

				gModelFunctionOpen:Jump(tonumber(other))
			end)
		end
	elseif event == 22 then
		trans = self:GetSpineNew(keyName)
		self:CreateWndSpine(trans,res,keyName,false,function (dpSpine)
			--local dpTrans = dpSpine:GetDisplayTrans()
			if not string.isempty(other)then
				dpSpine:SetScale(tonumber(other))
			end
			trans.localPosition = Vector2.New(posiX ,posiY)
			trans:SetSiblingIndex(layer)
			if appearType ~= 0 then
				self:GesetCanvasGroupAlpha(trans,0)
			end
			if appearType == 2 then
				self:SetTextAlphaTween(trans ,false,lastTime,keyName)
			elseif appearType == 3 then
				self:CutPage(trans,lastTime,UICartront.LeftToRight,self._btnTopSpacing,false)
			end
		end)
	end
	if(self.nexStepId==nil or self.nexStepId==0)then
		return
	end
	self:StartDelayTimerClose(nextTime,unscale)
end

function UICartront:GesetCanvasGroupAlpha(trans,alpha)
	local alphaN = alpha or 1
	local canvasGroup = trans:GetComponent(typeofCanvasGroup)
	if(canvasGroup) then
		canvasGroup	.alpha = alphaN
	end
end

function UICartront:ClearTimerClose()
	if self._timerClose then
		LxTimer.DelayTimeStop(self._timerClose)
		self._timerClose = nil
	end
end

--淡入淡出
function UICartront:SetTextAlphaTween(_tans,isAlpha,showTime,key)
	local seqTween
	local textKey=key or"_tans".._tans.name
	self:TweenSeqKill(textKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(textKey,function(seq)
				local canvasGroup = _tans:GetComponent(typeofCanvasGroup)
				if(canvasGroup) then
					local fromAlpha,toAlpha
					if isAlpha then
						fromAlpha=1
						toAlpha=0
					else
						fromAlpha=0
						toAlpha=1
					end
					local _temp = YXTween.TweenFloat(fromAlpha, toAlpha, showTime, function(ival)
						canvasGroup.alpha = ival
					end)
					seq:Join(_temp)
				end
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		if  isAlpha then
			CS.ShowObject(_tans,false)
		end
		self:TweenSeqKill(textKey)
	end)
end


function UICartront:SendTaData(type)

	local isSetting = self:GetWndArg("isSetting")
	if isSetting then
		return
	end

	local isStory = self:GetWndArg("isStartStory")
	if isStory then
		return
	end


	if self._taRecord and self._taRecord[type] then
		return
	end

	local taRecord = self._taRecord or {}
	taRecord[type] = true
	self._taRecord = taRecord

	if type == 1 then
		gLxTKData:NoviceStepReq(2)
	elseif type == 2 then
		gLxTKData:NoviceStepReq(3)
	elseif type == 3 then
		gLxTKData:NoviceStepReq(4)
	elseif type == 4 then
		gLxTKData:NoviceStepReq(5)
	end
end

function UICartront:GetItemNew(pid)
	local itemNew = self._pageImgList[pid]
	if itemNew then return itemNew end
	itemNew = self._itemPool:GetObj()
	local itemRoot = self.mLayePage
	itemNew.transform:SetParent(itemRoot.transform, false)
	CS.ShowObject(itemNew,true)
	self._pageImgList[pid] = itemNew
	return itemNew
end

function UICartront:OnSpeedFun()
	--local num=self._onClickNum
	--if(not num)then
	--	num=0
	--end
	--num=num+1
	--self._onClickNum=num

	--local skipNum=GameTable.StorylineConfigRef["animationJump"]
	--if(self._onClickNum>=skipNum)then

	--end

	local showSkip = not gLGameUpdate:IsSilenceDownload()
	CS.ShowObject(self.mSkipBtn,showSkip)
	CS.ShowObject(self.mScreenBtn,not showSkip)
end

function UICartront:CheckSendTaData()
	local timePast = math.floor(GetTimestamp() - self._startTime)
	if timePast >60 then
		self:SendTaData(4)
		self:TimerStop(self._taTimer)
	elseif timePast > 45 then
		self:SendTaData(3)
	elseif timePast > 30 then
		self:SendTaData(2)
	elseif timePast >15 then
		self:SendTaData(1)
	end

end

------------------------------------------------------------------
return UICartront


