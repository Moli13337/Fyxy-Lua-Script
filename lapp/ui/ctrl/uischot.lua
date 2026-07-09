---
--- Created by Administrator.
--- DateTime: 2023/10/27 15:10:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISchot:LWnd
local UISchot = LxWndClass("UISchot", LWnd)

local UnityEngine = UnityEngine
local typeof = typeof
local typeUISlider = typeof(UnityEngine.UI.Slider)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local typeSpineClick = typeof(CS.SpineClick)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISchot:UISchot()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISchot:OnWndClose()
	FireEvent(EventNames.NOTCH_HIDE_VIEW,true)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISchot:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISchot:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	FireEvent(EventNames.NOTCH_HIDE_VIEW,false)
	self:SetWndText(self.mClearScreenBtnTxt,ccClientText(10132))
	self:InitSlider()
	self:InitData()
	self:InitEvent()
	self:InitImgList()
end

function UISchot:ChangeImg(index)
	for k,v in pairs(self._selTransList) do
		CS.ShowObject(v,k == index)
	end
end

function UISchot:RefreshSlider()
	local heroScaleRange = gModelHero:GeConfigByKey("heroScaleRange")
	heroScaleRange = string.split(heroScaleRange,",")
	local min,max = tonumber(heroScaleRange[1]),tonumber(heroScaleRange[2])

	self._sliderComponent.minValue = min
	self._sliderComponent.maxValue = max

	local heroScaleRangeDefault = gModelHero:GeConfigByKey("heroScaleRangeDefault")
	local curValue = tonumber(heroScaleRangeDefault)
	self._curSize = curValue/100
	self._sliderComponent.value = curValue

	local heroDrawActionCd = gModelHero:GeConfigByKey("heroDrawActionCd")
	self._heroDrawActionCd = heroDrawActionCd
end

function UISchot:Refresh(itemdata)
	local heroBg = itemdata.heroBg

	local index = itemdata.index
	self._imgIndex = index

	self:ChangeImg(index)

	self:SetWndEasyImage(self.mBg,heroBg)

	--self:StarShowTimer()
end

function UISchot:TabListItem(list,item, itemdata, itempos)
	local IconTrans = self:FindWndTrans(item,"Icon")
	if IconTrans then
		self:SetWndEasyImage(IconTrans,itemdata.heroBookScreenBg)
	end
	local SelTrans = self:FindWndTrans(item,"Sel")
	if SelTrans then
		local index = itemdata.index
		self._selTransList[index] = SelTrans
		CS.ShowObject(SelTrans,index == self._imgIndex)
	end
end

function UISchot:InitSlider()
	self._sliderComponent = self.mSlider:GetComponent(typeUISlider)
	if (not self._sliderComponent) then
		self._sliderComponent = self.mSlider:AddComponent(typeUISlider)
	end
	self:RefreshSlider()
	LxUiHelper.SetProgress_ValueChanged(self.mSlider, function()
		local value = self._sliderComponent.value
		self:ChangeHeroSpineSize(value)
	end)
end

function UISchot:CreateAni(isShow)
	if self._isPlayAni then return end
	self._isPlayAni = true
	self._showBotDiv = isShow
	FireEvent(EventNames.SET_CHAT_FLOAT_SHOW,isShow)
	CS.ShowObject(self.mClickBg,not isShow)
	local seqTween
	self:TweenSeqKill(self._aniKey)
	if not seqTween then
		local showTime = 0.5
		local moveDown,moveRight
		local fromAlpha,toAlpha
		if isShow then
			fromAlpha,toAlpha = 0,1
			moveDown,moveRight = 100,-100
		else
			fromAlpha,toAlpha = 1,0
			moveDown,moveRight = -100,100
		end
		seqTween = self:TweenSeqCreate(self._aniKey,function(seq)
			local Ease = DG.Tweening.Ease.OutCubic
			local botCanvasGroup = self.mListBg:GetComponent(typeofCanvasGroup)
			if botCanvasGroup then
				local tweener = self.mListBg:DOLocalMoveY(self.mListBg.localPosition.y + moveDown,showTime)
				seq:Join(tweener)
				local changeAlpha = YXTween.TweenFloat(fromAlpha, toAlpha, showTime, function(ival)
					botCanvasGroup.alpha = ival
				end):SetEase(Ease)
				seq:Join(changeAlpha)
			end
			local rightCanvasGroup = self.mSliderDiv:GetComponent(typeofCanvasGroup)
			if rightCanvasGroup then
				local tweener = self.mSliderDiv:DOLocalMoveX(self.mSliderDiv.localPosition.x + moveRight,showTime)
				seq:Join(tweener)
				local changeAlpha = YXTween.TweenFloat(fromAlpha, toAlpha, showTime, function(ival)
					rightCanvasGroup.alpha = ival
				end):SetEase(Ease)
				seq:Join(changeAlpha)
			end
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self._isPlayAni = false
		self:TweenSeqKill(self._aniKey)
	end)
end

function UISchot:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBg,function()
--[[		CS.ShowObject(self.mImgList,true)
		CS.ShowObject(self.mReturnBtn,true)
		self:StarShowTimer()]]
	end)
	self:SetWndClick(self.mClearScreenBtn,function()
		--self:CreateAni(false)
		gLGameUI:CaptureUIScreen(self:GetWndTrans(), {self.mBg, self.mHeroPb})
	end)
	self:SetWndClick(self.mClickBg,function()
		if self._showBotDiv then return end
		self:CreateAni(true)
	end)
end

function UISchot:OnSpineLoaded(spine)
	local spineTrans = spine:GetSpineTrans()
	local spineClick = spineTrans:GetComponent(typeSpineClick)
	if not spineClick then
		spineClick = spineTrans.gameObject:AddComponent(typeSpineClick)
		spineClick.isUISpine = true
	end
	spineClick.onDrag = function(eventData)
		local camera = eventData.pressEventCamera
		local curPos = camera:ScreenToWorldPoint(eventData.position)
		local x = curPos.x
		local y = curPos.y
		local z = curPos.z
		spineTrans.position = Vector3(x,y,z)
	end
end

function UISchot:OnItemCenter(item, itemdata, itempos)
	self:Refresh(itemdata)
end

function UISchot:ChangeHeroSpineSize(value)
	if self._spine then
		local size = value / 100
		self._spine:SetScale(size)
	end
end

function UISchot:InitData()
	self._refId = self:GetWndArg("refId")
	self._star = self:GetWndArg("star")

	self._showTime = 3
	self._showTimeKey = "show"

	self._aniKey = "move"
	self._showBotDiv = true
	self._isPlayAni = false

	if not self._star then
		self._star = gModelHero:GetHeroInitStarByRefId(self._refId)
	end

	local prefabName = gModelHero:GetHeroPrefabNameByRefId(self._refId,self._star,true)
	if not string.isempty(prefabName) then
		local spine = self:CreateWndSpine(self.mHeroPb,prefabName,prefabName,false,function(spine)
			spine:SetScale(self._curSize)
			spine:MatchRectTransform()
			self:OnSpineLoaded(spine)
		end)
		self._spine = spine
	end

	local img = ""
	local raceType = gModelHero:GetMonsterRace(self._refId)

	self._imgIndex = 1

	local imgList = {}
	for k,v in pairs(GameTable.CharacterRaceRef) do
		local refId,heroBg,heroBookScreenBg = v.refId,v.heroBg,v.heroBookScreenBg
		if refId == raceType then
			img = heroBg
		end
		table.insert(imgList,{refId = refId,heroBg = heroBg,heroBookScreenBg = heroBookScreenBg})
	end
	table.sort(imgList,function(t1,t2)
		return t1.refId < t2.refId
	end)

	self._imgList = {}
	for i,v in ipairs(imgList) do
		local heroBg = v.heroBg
		local heroBookScreenBg = v.heroBookScreenBg
		if heroBg == img then
			self._imgIndex = i
		end
		table.insert(self._imgList,{heroBg = heroBg,index = i,heroBookScreenBg = heroBookScreenBg})
	end
end

function UISchot:InitImgList()
	CS.ShowObject(self.mImgList,true)
	self._selTransList = {}

	local uiList = self:GetUIScroll("imgList")
	uiList:InitListData({
		root = self.mImgList,
		dataList = self._imgList,
		setFunc = function (...) self:TabListItem(...) end,
		type = UIItemList.CIRCLE,
		onCenterFunc = function (...) self:OnItemCenter(...) end,
		centerPos = self._imgIndex
	})

	--uiList:Create(self.mItemList,dataList,function (...) self:OnDrawTreasure(...) end,UIItemList.WRAP)
end

function UISchot:StarShowTimer()
	self:TimerStop(self._showTimeKey)
	self:TimerStart(self._showTimeKey,self._showTime,false,1)
end

function UISchot:OnTimer(key)
	CS.ShowObject(self.mImgList,false)
	CS.ShowObject(self.mReturnBtn,false)
end

------------------------------------------------------------------
return UISchot


