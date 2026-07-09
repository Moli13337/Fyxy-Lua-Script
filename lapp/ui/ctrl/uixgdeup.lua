---
--- Created by Administrator.
--- DateTime: 2023/10/4 14:19:18
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIXGdeUp:LWnd
local UIXGdeUp = LxWndClass("UIXGdeUp", LWnd)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIXGdeUp:UIXGdeUp()
	self._effectKey = "effectKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIXGdeUp:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIXGdeUp:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIXGdeUp:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:InitEvent()
	self:InitData()
	self:CreateEffect(self.mTitleImg,"fx_ui_shengxing_1")
	self:RefreshView()
end

function UIXGdeUp:PlayEffect()
	local seqTween
	self:TweenSeqKill(self._effectKey)
	local contentTrans = self.mCommonBg_5.transform
	contentTrans.localRotation = Quaternion.Euler(90,0,0)

	local rotateY = 180
	local old = self.mOldHeroCard
	local oldTrans = old.transform
	oldTrans.localRotation = Quaternion.Euler(0,rotateY,0)

	local new = self.mNewHeroCard
	local newTrans = new.transform
	newTrans.localRotation = Quaternion.Euler(0,rotateY,0)

	if not seqTween then
		seqTween = self:TweenSeqCreate(self._effectKey,function(seq)
			local showTopTime = 0.2
			local rotateTween = contentTrans:DORotate(Vector3.New(0,0,0),showTopTime)
			seq:Append(rotateTween)

			seq:AppendCallback(function ()
				CS.ShowObject(self.mTitleImg,true)
			end)
			seq:AppendInterval(showTopTime)

			local rotateTime = 0.2
			local alphaTime = 0.3
			local jiangeTime = 0.1
			local Ease = DG.Tweening.Ease.OutCubic

			local oldCanvasGroup = oldTrans:GetComponent(typeofCanvasGroup)
			if oldCanvasGroup then
				CS.ShowObject(old,true)
				local _temp = YXTween.TweenFloat(0, 1, alphaTime, function(ival)
					oldCanvasGroup.alpha = ival
				end):SetEase(Ease)
				local oldRotateTween = oldTrans:DORotate(Vector3.New(0,0,0),rotateTime)
				seq:Append(oldRotateTween)
				seq:Join(_temp)
			end
			seq:AppendCallback(function ()
				CS.ShowObject(self.mArrow,true)
			end)
			seq:AppendInterval(jiangeTime)

			local newCanvasGroup = newTrans:GetComponent(typeofCanvasGroup)
			if newCanvasGroup then
				CS.ShowObject(new,true)
				local _temp = YXTween.TweenFloat(0, 1, alphaTime, function(ival)
					newCanvasGroup.alpha = ival
				end):SetEase(Ease)
				local newRotateTween = newTrans:DORotate(Vector3.New(0,0,0),rotateTime)
				seq:Append(_temp)
				seq:Join(newRotateTween)
			end
			seq:AppendInterval(jiangeTime)

			local itemTransList = self._itemTransList or {}
			for i,v in ipairs(itemTransList) do
				seq:AppendCallback(function ()
					self:CreateEffect(v,"fx_ui_shengxing_3","eff"..i)
					CS.ShowObject(v,true)
				end)
				seq:AppendInterval(showTopTime)
			end
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._effectKey)
	end)
end

function UIXGdeUp:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIXGdeUp:OnDrawStarCell(list,item,itemdata,itempos)
	local Star = self:FindWndTrans(item,"Star")
	local show = itemdata.show
	self:SetWndImageGray(Star,show)
end

function UIXGdeUp:OnDrawAttrList(list,item,itemdata,itempos)
	local itemTransList = self._itemTransList
	if not itemTransList then
		itemTransList = {}
		self._itemTransList = itemTransList
	end
	local Bg = self:FindWndTrans(item,"Bg")
	table.insert(itemTransList,Bg)
	local AttrIcon = self:FindWndTrans(Bg,"AttrIcon")
	local AttrName = self:FindWndTrans(Bg,"AttrName")
	local AttrCurValue = self:FindWndTrans(Bg,"AttrCurValue")
	local AttrNextValue = self:FindWndTrans(Bg,"AttrNextValue")
	local numType,refId,curValue,nextValue = itemdata.numType,itemdata.refId,itemdata.curValue,itemdata.newValue
	if AttrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon,function() CS.ShowObject(AttrIcon,true) end)
	end
	if AttrName then
		local name = gModelHero:GetAttributeNameById(refId)
		self:SetWndText(AttrName,name)
	end
	if AttrCurValue then
		local attrValue = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,curValue)
		self:SetWndText(AttrCurValue,attrValue)
	end
	if AttrNextValue then
		local attrValue = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,nextValue)
		self:SetWndText(AttrNextValue,attrValue)
	end
end

function UIXGdeUp:CreateEffect(trans,effectName,effectKey)
	effectKey = effectKey or effectName
	self:CreateWndEffect(trans,effectName,effectKey,100,false,false)
end

function UIXGdeUp:CreateStarList(key,trans,dj,heroRefId)
	local list = {}
	local closeLv = gModelHeroBook:GetHeroCloseLv(heroRefId)
	for i = 1,closeLv do
		local show = dj < i
		table.insert(list,{
			show = show,
		})
	end
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawStarCell(...) end)
	end
end

function UIXGdeUp:CreateAttrList()
	local list = self:GetAttrList()
	local uiList = self._uiList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("uiList")
		self._uiList = uiList
		uiList:Create(self.mAttrList,list,function(...) self:OnDrawAttrList(...) end)
	end
end

function UIXGdeUp:RefreshView()
	local oldBookStruct = self._oldBookStruct
	local newBookStruct = self._newBookStruct
	if not oldBookStruct or not newBookStruct then return end
	local heroRefId = oldBookStruct.heroRefId
	local heroRef = gModelHero:GetHeroRef(heroRefId)
	if not heroRef then return end
	local heroEffRef = gModelHero:GetHeroShowRefByRefId(heroRefId)
	if not heroEffRef then return end

	local heroBookIcon = heroEffRef.iconBig
	self:SetWndEasyImage(self.mOldHeroIcon,heroBookIcon)
	self:SetWndEasyImage(self.mNewHeroIcon,heroBookIcon)

	local heroName = gModelHero:GetHeroNameByRefId(heroRefId)
	self:SetWndText(self.mOldHeroName,heroName)
	self:SetWndText(self.mNewHeroName,heroName)

	local quality = gModelHero:GetHeroQualityByRefId(heroRefId)
	local qualityRef = gModelItem:GetQualityRef(quality)
	if qualityRef then
	end

	local raceType = heroRef.raceType
	local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
	if raceRef then
		local icon = raceRef.icon
		local mOldHeroRaceImg = self.mOldHeroRaceImg
		local mNewHeroRaceImg = self.mNewHeroRaceImg
		self:SetWndEasyImage(mOldHeroRaceImg,icon,function() CS.ShowObject(mOldHeroRaceImg,true) end)
		self:SetWndEasyImage(mNewHeroRaceImg,icon,function() CS.ShowObject(mNewHeroRaceImg,true) end)
	end

	local oldGrade,newGrade = oldBookStruct.closeGrade,newBookStruct.closeGrade
	self:CreateStarList("old",self.mOldHeroLoveList,oldGrade,heroRefId)
	self:CreateStarList("new",self.mNewHeroLoveList,newGrade,heroRefId)

	self:CreateAttrList()

	self:PlayEffect()
end

function UIXGdeUp:GetAttrList()
	local list = {}
	local oldBookStruct = self._oldBookStruct
	local newBookStruct = self._newBookStruct
	if not oldBookStruct or not newBookStruct then return list end
	local heroRefId = oldBookStruct.heroRefId
	local heroRef = gModelHero:GetHeroRef(heroRefId)
	if not heroRef then return end
	local oldGrade,newGrade = oldBookStruct.closeGrade,newBookStruct.closeGrade
	local closeLv = heroRef.closeLv
	local oldHeroCloseRef = gModelHeroBook:GetHeroCloseLvRefByCloseTypeAndCloseGrade(closeLv,oldGrade)
	local newHeroCloseRef = gModelHeroBook:GetHeroCloseLvRefByCloseTypeAndCloseGrade(closeLv,newGrade)
	if not oldHeroCloseRef or not newHeroCloseRef then return list end
	local oldAttrKeyList = oldHeroCloseRef.attrKeyList
	local newAttrKeyList = newHeroCloseRef.attrKeyList

	for k,v in pairs(newAttrKeyList) do
		local newValue = v.value
		local oldData = oldAttrKeyList[k]
		local oldValue = oldData and oldData.value or 0
		table.insert(list,{
			numType = v.numType,
			refId = v.refId,
			curValue = oldValue,
			newValue = newValue,
		})
	end
	table.sort(list,function(a,b)
		return a.refId < b.refId
	end)
	return list
end

function UIXGdeUp:InitData()
	self._oldBookStruct = self:GetWndArg("oldBookStruct")
	self._newBookStruct = self:GetWndArg("newBookStruct")
	self._itemTransList = {}
end
------------------------------------------------------------------
return UIXGdeUp


