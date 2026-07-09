---
--- Created by BY.
--- DateTime: 2023/10/10 17:18:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdeUpLvPop:LWnd
local UIGdeUpLvPop = LxWndClass("UIGdeUpLvPop", LWnd)
local Tweening = DG.Tweening
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdeUpLvPop:UIGdeUpLvPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdeUpLvPop:OnWndClose()
	if self._uiIconEasyList then
		self._uiIconEasyList:Destroy()
		self._uiIconEasyList = nil
	end
	gModelGeneral:IsTriggerRewardPop()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdeUpLvPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdeUpLvPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UIGdeUpLvPop:SetTowee(key)
	local seqTween
	self:TweenSeqKill(key)
	if not seqTween then
		seqTween = self:TweenSeqCreate(key,function(seq)
			local tList = {
				self.mIconObj,
				self.mImgObj
			}
			local sList = {
				{1.1,0.07},
				{0.97,0.13},
				{1.04,0.14},
				{1,0.16},
			}
			for i = 1, 2 do
				if(i == 2)then
					seq:AppendCallback(function ()
						self:PlayIconEff()
						self:SetGradeIcon(self._gradeLevel)
					end)
				end
				self:SetTransTween(seq,tList,sList)
				seq:AppendInterval(0.3)
			end

			local downPos = self.mIconObj.localPosition + Vector3.New(0,180,0)
			local tweener = self.mIconObj:DOLocalMove(downPos,0.3)
			seq:Append(tweener)
			local downPos = self.mImgObj.localPosition + Vector3.New(0,178,0)
			local tweener = self.mImgObj:DOLocalMove(downPos,0.3)
			seq:Join(tweener)
			seq:AppendInterval(0.2)
			seq:AppendCallback(function ()
				--CS.ShowObject(self.mUpPop,false)
				CS.ShowObject(self.mPopup14_2,true)
				self:RefreshPage()
			end)
			local canvasGroup = self.mPopup14_2:GetComponent(typeofCanvasGroup)
			canvasGroup.alpha = 0
			local tween = canvasGroup:DOFade(1,0.3)
			seq:Append(tween)

			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(key)

		self:SendGuideReadyEvent(self:GetWndName())
	end)
end

function UIGdeUpLvPop:PlayIconEff()
	self:PlayEff(self.mEff,"fx_ui_maoxianpingji_jinsheng_01_down","effKey1")
	self:PlayEff(self.mEff2,"fx_ui_maoxianpingji_jinsheng_01_top","effKey2")
	self:PlayEff(self.mEff3,"fx_ui_maoxianpingji_jinsheng_02","effKey3")
end

function UIGdeUpLvPop:InitCommand()
	self:SetWndText(self.mArrtText,ccClientText(18210))
	self:SetWndText(self.mCloseTip,ccClientText(15702))
	local _gradeLevel = gModelGrade:GetGradeLevel() or 1
	self._gradeLevel = _gradeLevel

	CS.ShowObject(self.mUpPop,true)
	CS.ShowObject(self.mPopup14_2,false)
	self:SetGradeIcon(self._gradeLevel - 1)
	self:SetTowee("key")
end

function UIGdeUpLvPop:PlayEff(trans,eff,key)
	self:CreateWndEffect(trans,eff,key,100,false,false)
end

function UIGdeUpLvPop:SetGradeIcon(lv)
	local ref = gModelGrade:GetGradeLvRefByRefId(lv)
	if not ref then
		return
	end
	self:SetWndEasyImage(self.mUpGradeIcon,ref.iconBig)
	self:SetWndEasyImage(self.mUpGradeImg,ref.iconSmall)
	local starNum = ref.starNum
	CS.ShowObject(self.mGradeStarMag,starNum > 0)
	if starNum > 0 then
		for i = 1, 5 do
			local trans = CS.FindTrans(self.mGradeStarMag,"Star"..i)
			if i <= starNum then
				self:SetWndEasyImage(trans,ref.iconBigStarColor)
			else
				self:SetWndEasyImage(trans,"mianui_risk_star_3")
			end
		end

	end
end

function UIGdeUpLvPop:RefreshPage()
	local _gradeLevel = self._gradeLevel
	local ref = gModelGrade:GetGradeLvRefByRefId(_gradeLevel)
	local arrList = {}
	for i = 1, _gradeLevel do
		local ref = gModelGrade:GetGradeLvRefByRefId(i)
		local list = LUtil.GetRefAttrData(ref.attr)
		for i, v in ipairs(list) do
			local arr = arrList[v.refId]
			if(arr)then
				arr.value = arr.value + v.value
				arrList[v.refId] = arr
			else
				if(_gradeLevel == i)then
					v.new = true
				end
				arrList[v.refId] = v
			end
		end
	end
	local list = {}
	for i, v in pairs(arrList) do
		table.insert(list,v)
	end

	local _attrList = self:GetUIScroll("_attrList")
	_attrList:Create(self.mArrtScroll,list,function (...) self:ArrtListItem(...) end)
	--local oldRef = gModelGrade:GetGradeLvRefByRefId(_gradeLevel - 1)
	--local itemList = LxDataHelper.ParseItem(oldRef.rewardUp)
	--local uiIconEasyList = self._uiIconEasyList
	--if(not uiIconEasyList)then
	--	uiIconEasyList = UIIconEasyList:New()
	--	uiIconEasyList:Create(self, self.mAwardScroll)
	--	uiIconEasyList:SetShowNum(true)
	--	uiIconEasyList:SetIconClickPath("CommonUI")
	--	--uiIconEasyList:SetShowExtraNum(true,"CommonUI/NumTxt")
	--	self._uiIconEasyList = uiIconEasyList
	--end
	--uiIconEasyList:RefreshList(itemList)
end

function UIGdeUpLvPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mCloseTip, function(...) self:WndClose() end)
end

function UIGdeUpLvPop:OnAwake()
	LWnd.OnAwake(self)
	self._delayFinishEvent = true
end

function UIGdeUpLvPop:ArrtListItem(list,item, itemdata, itempos)
	local iconTrans=CS.FindTrans(item,"Icon")
	local nameText=CS.FindTrans(item,"NameText")
	local valueText=CS.FindTrans(item,"ValueText")
	local newImg=CS.FindTrans(item,"NewImg")
	local icon=gModelHero:GetAttributeIconById(itemdata.refId)
	local name=gModelHero:GetAttributeNameById(itemdata.refId)
	local value= gModelHero:GetAttributeValueNoNameByIdAndVal(itemdata.refId,itemdata.numType,itemdata.value)
	self:SetWndEasyImage(iconTrans,icon)
	self:SetWndText(nameText,name)
	self:SetWndText(valueText,"+"..value)
	CS.ShowObject(newImg,itemdata.new)
end

function UIGdeUpLvPop:SetTransTween(seq,tList,sList)
	for i, v in ipairs(tList) do
		v.localScale = Vector3(0.6,0.6,0.6)
	end
	for j, k in ipairs(sList) do
		local scale = k[1]
		local time = k[2]
		for i, v in ipairs(tList) do
			local trans = v
			local toPos = Vector3.New(1*scale,1*scale,1*scale)
			local dtMoveTo = trans:DOScale(toPos,time)
			if i == 1 then
				seq:Append(dtMoveTo)
			else
				seq:Join(dtMoveTo)
			end
		end
	end
end
------------------------------------------------------------------
return UIGdeUpLvPop


