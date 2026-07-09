---
--- Created by Administrator.
--- DateTime: 2023/10/2 21:31:10
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISy:LWnd
local UISy = LxWndClass("UISy", LWnd)

local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local typeOfRectTransform = typeof(UnityEngine.RectTransform)


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISy:UISy()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISy:OnWndClose()
	if self._seqCom then
		self._seqCom:Destroy()
		self._seqCom = nil
	end

	--print("UISy:OnWndClose()")

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISy:OnCreate()
	LWnd.OnCreate(self)


	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISy:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._seqCom = SequenceCom:New()

	self._objPool = UIObjPool:New()
	self._objPool:Create(self.mUnUse,self.mIntroItem)

	self._textObjPool = UIObjPool:New()
	self._textObjPool:Create(self.mUnUse,self.mTextTemplate)

    self._effRootPool = UIObjPool:New()
    self._effRootPool:Create(self.mUnUse,self.mEffect)

	self._useedRootList = {}

	self:SetWndClick(self.mSkipBtn,function ()
		self:OnClickSkip()
	end)

	CS.ShowObject(self.mNormalText,false)
	CS.ShowObject(self.mHeroSay,false)
	CS.ShowObject(self.mIntroRoot,false)
	CS.ShowObject(self.mBlack,false)
	CS.ShowObject(self.mSelect,false)
	CS.ShowObject(self.mRed,false)
	CS.ShowObject(self.mSkipBtn,false)
	CS.ShowObject(self.mTextListRoot,false)

	self:WndEventRecv(EventNames.ON_STORY_OBJ_HURT,function (...)
		self:HideFinger(...)
	end)

	self:OnWndRefresh()

end

function UISy:OnClickSkip()
	local curStoryId = gLGpManager:FindStoryCopyGp():GetStoryId()
	gLxTKData:OnFixedStep(curStoryId)

	if self._skipType == 1 then
		gLGpManager:FindStoryCopyGp():StopStory()
		GF.CloseWndByName("UISy")
		gModelFunctionOpen:Jump(10000000)
	elseif self._skipType == 2 then
		gLGpManager:FindStoryCopyGp():StartStory(self._skipPara,true)
	end
end

function UISy:SetSkipShow(isShow)
	CS.ShowObject(self.mSkipBtn,isShow)
end

function UISy:NextText()
	local curIndex = self._curTextIndex + 1
	local item = self._textItemList[self._curTextIndex]
	if CS.IsValidObject(item) then
		local canvasGroup = item:GetComponent(typeofCanvasGroup)
		canvasGroup.alpha = 1
	end
	self._curTextIndex = curIndex
	if curIndex> #self._textList then
		local eventCtrl = gLGpManager:FindStoryCopyGp():GetEventCtrl()
		eventCtrl:ClearEvent({self._eventId})
		self:HideTextList()
	else
		local item = self._textItemList[curIndex]
		local canvasGroup = item:GetComponent(typeofCanvasGroup)
		local seq = self._seqCom:CreateSeq("textFade")
		local alphaTween =canvasGroup:DOFade(1,1)
		seq:Append(alphaTween)
		seq:AppendInterval(1)
		--seq:OnComplete(function ()
		--	--self:NextText()
		--end)
		seq:Play()
	end



end

function UISy:HideText(type,eventId)
	if type == LStoryEventType.TEXT_SCREEN then
		CS.ShowObject(self.mNormalText,false)
	elseif type == LStoryEventType.TEXT_SAY then
		CS.ShowObject(self.mHeroSay,false)
		local seq = self._seqCom:CreateSeq("heroSay")
		local canvasGroup = self.mMask:GetComponent(typeofCanvasGroup)
		local tween = canvasGroup:DOFade(0,0.1):SetEase(DG.Tweening.Ease.InSine)
		seq:Append(tween)
		seq:PlayForward()

		self._seqCom:DeleteSeq("Blink")
	elseif type == LStoryEventType.TEXT_INTRO then
		CS.ShowObject(self.mIntroRoot,false)

	elseif type == LStoryEventType.TEXT_NORMAL then
		self:HideTextList()
	elseif type == LStoryEventType.BLACK or type == LStoryEventType.BLACK_END then
		CS.ShowObject(self.mBlack,false)
	elseif type == LStoryEventType.SELECT then
		CS.ShowObject(self.mSelect,false)

		local battle = gLFightManager:GetCurBattleUnit()
		if battle then
			battle:Resume()
		end
	elseif type == LStoryEventType.RED then
		CS.ShowObject(self.mRed,false)
	elseif type == LStoryEventType.EFFECT_UI_FX then
		self:HideEffect(eventId,1)
    elseif type == LStoryEventType.EFFECT_UI_SPINE then
        self:HideEffect(eventId,2)
	end
end

function UISy:OnDrawSelect(list,item,itemdata,itempos)
	local bg = self:FindWndTrans(item,"bg")
	local select = self:FindWndTrans(item,"select")
	local intro = self:FindWndTrans(item,"intro")

	self:SetWndText(intro,itemdata.text)
	CS.ShowObject(select,false)
	self:SetWndClick(item,function () self:OnClickSelect(itemdata) end)
end

function UISy:ShowHeroSay()

	CS.ShowObject(self.mHeroSay,true)

	local item = self.mHeroSay
	local textBg = self:FindWndTrans(item,"textBg")
	local textBgHeadBg = self:FindWndTrans(textBg,"headBg")
	local headBgHead = self:FindWndTrans(textBgHeadBg,"head")
	local leftName = self:FindWndTrans(item,"leftName")
	local rightName = self:FindWndTrans(item,"rightName")
	local text = self:FindWndTrans(item,"text")


	local scale = Vector3.New(1,1,1)
	local isLeft = self._dire == 0

	if isLeft then
		scale = Vector3.New(-1,1,1)
	end

	textBg.localScale = scale
	textBgHeadBg.localScale = scale

	self:SetWndEasyImage(headBgHead,self._icon)
	self:SetWndText(text,self._text)

	CS.ShowObject(leftName,isLeft)
	CS.ShowObject(rightName, not isLeft)
	self:SetWndText(rightName,self._name)
	self:SetWndText(leftName,self._name)

	self:SetWndClick(item,function ()
		local eventCtrl = gLGpManager:FindStoryCopyGp():GetEventCtrl()
		eventCtrl:ClearEvent({self._eventId})
		self:HideText(LStoryEventType.TEXT_SAY)
	end,LSoundConst.CLICK_CLOSE_COMMON)

	local seq = self._seqCom:CreateSeq("heroSay")
	local canvasGroup = self.mMask:GetComponent(typeofCanvasGroup)
	canvasGroup.alpha = 0
	local tween = canvasGroup:DOFade(1,0.1):SetEase(DG.Tweening.Ease.InSine)
	seq:Append(tween)
	seq:PlayForward()

	self:FormatBlinkTween(self.mContinue)
end

function UISy:ShowFinger(pos,objId)
	if self._fingerEff then
		return
	end
	--printInfoN("ShowFinger")
	self._objId = objId
	local effName = "fx_ui_shou_2"
	self._fingerEff  = "fingerEff"
	self:CreateWndEffect(self.mFingerRoot,effName,self._fingerEff,80)
	local sceneCam = gLGameScene:GetCurrentSceneCamera()
	local uiCam = LGameUI.GetUICamera()
	local screenPos = sceneCam:WorldToScreenPoint(pos)
	local uiPos = uiCam:ScreenToWorldPoint(screenPos)
	self.mFingerRoot.position = uiPos
end

function UISy:HideTextList()
	if self._textItemList then
		for k,v in ipairs(self._textItemList) do
			self._textObjPool:ReturnObj(v)
		end
		self._textItemList =nil
	end

	CS.ShowObject(self.mTextListRoot,false)

end

function UISy:FormatBlinkTween(trans)
	local canvasGroup = trans:GetComponent(typeofCanvasGroup)
	canvasGroup.alpha = 0
	local seq = self._seqCom:CreateSeq("Blink")
	local tween = canvasGroup:DOFade(1,1)
	seq:Append(tween)

	tween = canvasGroup:DOFade(0,1)
	seq:Append(tween)

	seq:SetLoops(-1)
	seq:Play()

end

function UISy:OnWndRefresh()
	local operType = self:GetWndArg("operType")
	local para = self:GetWndArg("para")
	if operType == 1 then
		self._eventId = para
		self:ShowEvent()
	elseif operType == 2 then
		local eventType = para
		local eventId = self:GetWndArg("eventId")
		self:HideText(eventType,eventId)
	elseif operType == 3 then
		local strs = string.split(para,"=")
		local isShow = false
		local skipStoryId = nil
		local type =nil
		if #strs>0 then
			type = tonumber(strs[1])
			skipStoryId = tonumber(strs[2])
			if type == 1 or type ==2 then
				isShow = true
			end
		end
		self._skipType = type
		self._skipPara = skipStoryId

		if isShow then
			self:SetSkipShow(false)
			local seq = self._seqCom:CreateSeq("delayShowSkip")
			seq:AppendInterval(2)
			seq:OnComplete(function ()
				self._seqCom:DeleteSeq("delayShowSkip")
				self:SetSkipShow(isShow)
			end)
			seq:PlayForward()
		else
			self._seqCom:DeleteSeq("delayShowSkip")
			self:SetSkipShow(isShow)
		end


	elseif operType == 4 then
		local pos = self:GetWndArg("pos")
		local objId = self:GetWndArg("objId")
		self:ShowFinger(pos,objId)
	end
end

function UISy:ShowBlack()

	CS.ShowObject(self.mBlack,true)

	local sequence = self._seqCom:CreateSeq("blackFade")
	local canvasGroup = self.mBlack:GetComponent(typeofCanvasGroup)
	canvasGroup.alpha = 0
	local showTime = self._timeSpan -2
	showTime = showTime>0 and showTime or 0
	local tween = canvasGroup:DOFade(1,1)
	sequence:Append(tween)
	sequence:AppendInterval(showTime)
	tween = canvasGroup:DOFade(0,1)
	sequence:Append(tween)
	sequence:OnComplete(function()
		self._seqCom:DeleteSeq("blackFade")
 	end)
	sequence:PlayForward()
end

function UISy:FadeTween(targetTran,key,onComplete)
	local sequence = self._seqCom:CreateSeq(key)

	local canvasGroup = targetTran:GetComponent(typeofCanvasGroup)
	canvasGroup.alpha = 0
	local tween = canvasGroup:DOFade(1,0.5):SetEase(DG.Tweening.Ease.InSine)
	sequence:Append(tween)
	local interval = self._timeSpan-1
	if interval< 0 then
		interval = 0
	end
	sequence:AppendInterval(interval)
	tween = canvasGroup:DOFade(0,0.5):SetEase(DG.Tweening.Ease.OutSine)
	sequence:Append(tween)
	sequence:OnComplete(function ()
		if onComplete then
			onComplete()
		end
	end)
	sequence:PlayForward()
end

function UISy:ShowEffect(eventId,type)
	local effectKey = string.format("uieff_"..eventId)
	local effect = self._effectName

    local root = self._effRootPool:GetObj()
    root.transform:SetParent(self.mRoot,false)
    if type == 1 then
        self:CreateWndEffect(root.transform,effect,effectKey,100)
    elseif type == 2 then
        self:CreateWndSpine(root.transform,effect,effectKey)
    end
    local rectTran = root.transform:GetComponent(typeOfRectTransform)
	rectTran.anchoredPosition = self._pos

    self._useedRootList[effectKey] = root
end

function UISy:OnClickSelect(itemdata)
	local eventId = self._eventId
	local storyId = itemdata.sceneId
	local clean = itemdata.clean == 1

	gLxTKData:OnStorySelClick(eventId, storyId)

	gLGpManager:FindStoryCopyGp():StartStory(storyId,clean)

	self:HideText(LStoryEventType.SELECT)
end

function UISy:ShowEvent()

	--self._objPool:ReturnAllObj()
	local eventId = self._eventId

	self:SetWndClick(self.mBlack,function () end)

	local cfg = gModelPlot:GetStoryEventRef(eventId)
	local type = cfg.eventType
	--local startTime = cfg.beginTime
	local endTime = cfg.endTime --持续时间
	self._timeSpan = endTime

	local msg = ccLngText(cfg.text)



	self._text = LUtil.GetFaceStr(msg,32)
	self._name = ccLngText(cfg.name)

	self._dire = cfg.direction
	self._icon = cfg.icon
	self._pos = LxDataHelper.ParseVector(cfg.coordinate)
	self._effectName = cfg.effectName

	local selectList ={}
	local data = {
		text =cfg.choose1,
		clean = cfg.clean1,
		sceneId = cfg.chooseScene1,
	}

	table.insert(selectList,data)
	local choose =cfg.choose2
	if not string.isempty( choose) then
		local data = {
			text = choose,
			clean = cfg.clean2,
			sceneId = cfg.chooseScene2,
		}
		table.insert(selectList,data)
	end


	self._selectList = selectList

    if type == LStoryEventType.TEXT_SCREEN then
        self:ShowScreenText()
    elseif type == LStoryEventType.TEXT_SAY then
        self:ShowHeroSay()
    elseif type == LStoryEventType.TEXT_INTRO then
        self:ShowIntro()
    elseif type == LStoryEventType.TEXT_NORMAL then
        local strs = string.split(msg,"|")
        local textList = {}
        for k,v in ipairs(strs) do
            local text = LUtil.GetFaceStr(v,32)
            table.insert(textList,text)
        end

        self._textList = textList

        self:ShowTextList()

    elseif type == LStoryEventType.BLACK or type == LStoryEventType.BLACK_END then
        self:ShowBlack()
    elseif type == LStoryEventType.SELECT then
        self:ShowSelect()
        local battle = gLFightManager:GetCurBattleUnit()
        if battle then
            battle:Resume()
        end
    elseif type == LStoryEventType.RED then
        self:ShowRed()
    elseif type == LStoryEventType.EFFECT_UI_FX then
        self:ShowEffect(eventId,1)
    elseif type == LStoryEventType.EFFECT_UI_SPINE then
        self:ShowEffect(eventId,2)
    end
end

function UISy:ShowTextList()

	CS.ShowObject(self.mTextListRoot,true)
	local itemList = {}
	for k,v in ipairs(self._textList) do
		local item = self._textObjPool:GetObj()
		item.transform:SetParent(self.mTextList,false)
		CS.ShowObject(item,true)
		self:SetWndText(item,v)
		local canvasGroup = item:GetComponent(typeofCanvasGroup)
		canvasGroup.alpha = 0
		table.insert(itemList,item)
	end
	self._textItemList = itemList
	self._curTextIndex = 0

	self:FormatBlinkTween(self.mTextContinue)
	self:NextText()

	self:SetWndClick(self.mTextList,function ()
		self:NextText()
	end)


end

function UISy:HideFinger(objId)
	if objId~= self._objId then
		return
	end
	if self._fingerEff then
		--printInfoN("HideFinger")
		self:DestroyWndEffectByKey(self._fingerEff)
		self._fingerEff = nil
	end
end

function UISy:ShowIntro()

	CS.ShowObject(self.mIntroRoot,true)

	local item = self._objPool:GetObj()
	local bg = self:FindWndTrans(item,"bg")
	local bgUIText = self:FindWndTrans(bg,"UIText")

	item.transform:SetParent(self.mIntroRoot,false)

	self:SetWndText(bgUIText,self._text)
	LxUiHelper.SetAnchoredPosition(item,self._pos.x,self._pos.y)
	CS.ShowObject(item,true)

	local onComplete = function()
		self._objPool:ReturnObj(item)
	end
	local instanceId = item:GetInstanceID()
	self:FadeTween(item,"introFade"..instanceId,onComplete)
end

function UISy:ShowSelect()


	self:SetWndText(self.mSelectIntro,self._text)

	local list = self._selectUIList
	if not list then
		list = self:GetUIScroll("selectList")
		list:Create(self.mChooseList,self._selectList,function (...) self:OnDrawSelect(...) end)
	else
		list:RefreshList(self._selectList)
	end

    --local cnt = #self._selectList
    --self:SetSelectHeight(cnt)

	--local sizeDelta = Vector2.New(640,220+ 140*cnt)
	--self.mCommonBg_5_1.sizeDelta = sizeDelta
	CS.ShowObject(self.mSelect,false) --触发重新布局
	local seq = self._seqCom:CreateSeq("layoutDelay")
	seq:AppendInterval(0.02)
	seq:OnComplete(function ()
		CS.ShowObject(self.mSelect,true)
	end)
	seq:Play()

end

function UISy:ShowScreenText()

	CS.ShowObject(self.mNormalText,true)

	local text = self:FindWndTrans(self.mNormalText,"text")
	self:SetWndText(text,self._text)
	self:FadeTween(self.mNormalText,"textFade")
end

function UISy:ShowRed()
	CS.ShowObject(self.mRed,true)

	local sequence = self._seqCom:CreateSeq("redFade")
	local canvasGroup = self.mRed:GetComponent(typeofCanvasGroup)
	canvasGroup.alpha = 0
	local tween = canvasGroup:DOFade(1,1):SetEase(DG.Tweening.Ease.OutSine)
	sequence:Append(tween)
	sequence:OnComplete(function()
		self._seqCom:DeleteSeq("redFade")
 	end)
	sequence:PlayForward()
end

function UISy:HideEffect(eventId,type)
	local effectKey = string.format("uieff_"..eventId)
    if type == 1 then
        self:DestroyWndEffectByKey(effectKey)
    elseif type == 2 then
        self:DestroyWndSpineByKey(effectKey)
    end
    local root = self._useedRootList[effectKey]
    self._effRootPool:ReturnObj(root)
end


------------------------------------------------------------------
return UISy


