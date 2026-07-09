---
--- Created by Administrator.
--- DateTime: 2023/10/10 16:39:07
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPrepareMirrorYellAwardTop:LWnd
local UIPrepareMirrorYellAwardTop = LxWndClass("UIPrepareMirrorYellAwardTop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPrepareMirrorYellAwardTop:UIPrepareMirrorYellAwardTop()
	---@type table<number,CommonIcon>
	self._uiCommonList = {}

	self._uiList = nil
	self._startTweenKey = "_startTweenKey"
	self._effEndTimeKey = "_effEndTimeKey"
	self._canCloseTimeKey = "_canCloseTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPrepareMirrorYellAwardTop:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)

	if self._seqCom then
		self._seqCom:Destroy()
		self._seqCom = nil
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPrepareMirrorYellAwardTop:OnCreate()
	LWnd.OnCreate(self)

	self._seqCom = SequenceCom:New()
	self._curItemTweenList = {}

	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPrepareMirrorYellAwardTop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitPara()
	self:InitStaticInfo()

	if self._needAni then
		self:StartTween()
	else
		self:RefreshUI()
	end
end

function UIPrepareMirrorYellAwardTop:OnclickSelect(entryId, itemPos)
	if self._curSelect == entryId then return end

	self._curSelect = entryId

	local oldPos = self._curSelectPos
	self._curSelectPos = itemPos

	local uiList =self._itemSuperList
	local list = uiList:GetList()
	if oldPos then
		list:DrawItemByIndex(oldPos)
	end
	list:DrawItemByIndex(itemPos)
end

--#####################################################################################################################
--## Content ##########################################################################################################
--#####################################################################################################################
function UIPrepareMirrorYellAwardTop:RefreshUI()
	CS.ShowObject(self.mAniRoot, true)
	self._startTime = Time.time

	local dataList = self._rewardRefIdList

	local uiList =self._itemSuperList
	if not uiList then
		uiList = self:GetUIScroll("itemList")
		self._itemSuperList = uiList
		uiList:Create(self.mRewardList,dataList,function (...) self:RewardListOnDraw(...) end,UIItemList.SUPER_GRID,false)
		local list = uiList:GetList()

		list:SetFuncOnItemReturn(function (...)
			self:OnRewardItemReturn(...)
		end)

		list:SetOnStartDrag(function ()
			self:OnStartDrag()
		end)
	else
		uiList:RefreshData(dataList,true)
	end

	local list = uiList:GetList()
	list:RefreshList()
end

function UIPrepareMirrorYellAwardTop:InitMsg()

end

function UIPrepareMirrorYellAwardTop:OnClickEmpty()
	if self._isCreateAni then return end

	local seq = self._seqCom:FindSeq(self._startTweenKey)
	if seq then
		self._seqCom:DeleteSeq(self._startTweenKey)
		local contentTrans = self.mContent
		contentTrans.localRotation = Quaternion.Euler(0,0,0)
		self:RefreshUI()
	else
		local func = function()
			gModelCallHero:SetLocalPrepareMirrorCallData(nil, nil, nil, {})
			self:WndClose()
		end
		gModelGeneral:OpenUIOrdinTips({refId = 10041,func = func})
	end
end

function UIPrepareMirrorYellAwardTop:MoveContent()
	if self._cancelItemTween then
		return
	end

	local list = self._itemSuperList:GetList()
	if not list then
		return
	end

	local viewSize = self.mRewardList.rect.size
	local contentSize = list:GetContentSize()
	local itemSize = Vector2.New(115,140)

	local moveLen = contentSize.y - viewSize.y
	if moveLen<= 0 then
		return
	end
	local disY = -itemSize.y/moveLen

	local dis =Vector2.New(0,disY)
	local duration = 0.4
	local seq = self._seqCom:CreateSeq("moveContent")

	local curPos = list:GetContentPosition()
	local endPos = curPos + dis
	endPos.y = math.max(0,endPos.y)
	local tween = YXTween.TweenFloat(0,1,duration,function (t)
		local pos = Vector2.Lerp(curPos,endPos,t)
		list:SetContentPosition(pos)
	end)

	seq:Append(tween)
	seq:PlayForward()
end

function UIPrepareMirrorYellAwardTop:OnStartDrag()
	if table.isempty(self._curItemTweenList) then
		return
	end

	self._cancelItemTween = true

	self._seqCom:DeleteSeq("moveContent")
	for k,v in pairs(self._curItemTweenList) do
		self._seqCom:DeleteSeq(k)
	end
	self._curItemTweenList = {}

	local uiList =self._itemSuperList
	local list = uiList:GetList()
	local seq = self._seqCom:CreateSeq("moveContent")
	local duration = 0.2
	local curPos = list:GetContentPosition()
	local endPos = Vector2.zero
	local tween = YXTween.TweenFloat(0,1,duration,function (t)
		local pos = Vector2.Lerp(curPos,endPos,t)
		list:SetContentPosition(pos)
	end)

	seq:Append(tween)
	seq:PlayForward()

end

--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################
function UIPrepareMirrorYellAwardTop:OnClickOkBtn()
	if self._isCreateAni then return end

	local curSelect = self._curSelect
	if not curSelect then
		GF.ShowMessage(ccClientText(37408))
		return
	end


    local func = function()
		gModelCallHero:SetLocalPrepareMirrorCallData(nil, curSelect, nil, {})
        self:WndClose()
    end

	local curHeroId = gModelCallHero:GetLocalPrepareMirrorCallHero()

    if curHeroId and curHeroId > 0 and curHeroId ~= curSelect then
		local curHeroName = gModelGeneral:GetCommonItemColorNameNoNum({itemType = 2,itemId = curHeroId})
		local selectHeroName = gModelGeneral:GetCommonItemColorNameNoNum({itemType = 2,itemId = curSelect})
        gModelGeneral:OpenUIOrdinTips({refId = 10040,func = func, para = {curHeroName, selectHeroName}})
    else
        func()
    end
end

function UIPrepareMirrorYellAwardTop:TweenItemScale(item,itempos, effRoot)
	local nowTime = Time.time
	local timePast =nowTime - self._startTime
	local delay = itempos*self._iconPlayTime

	if timePast>delay or self._cancelItemTween then
		item.transform.localScale= Vector3.one
		return
	end
	CS.ShowObject(effRoot, false)
	local curDelay = delay - timePast
	local instanceId = item:GetInstanceID()
	item.transform.localScale= Vector3.zero
	local seq = self._seqCom:CreateSeq(instanceId)

	local tween = item:DOScale(Vector3.one,self._iconPlayTime)
	seq:AppendInterval(curDelay)
	if itempos>8 and  itempos%4 ==1 then
		seq:AppendCallback(function ()
			self:MoveContent()
		end)
	end

	seq:Append(tween)
	seq:OnComplete(function ()
		self._seqCom:DeleteSeq(instanceId)
		self._curItemTweenList[instanceId] = nil
		CS.ShowObject(effRoot, true)
	end)
	seq:OnKill(function()
		item.transform.localScale= Vector3.one
	end)
	seq:PlayForward()

	self._curItemTweenList[instanceId] = true
end

function UIPrepareMirrorYellAwardTop:ShowHeroEff(item, heroId)
	local instanceId = item:GetInstanceID()

	local effScaleSize = 100
	local eff
--[[	if gModelHero:CheckIsShowHeroQualityForeign() then
	else
	end]]
	local heroRef  = gModelHero:GetHeroRef(heroId)
	if heroRef then
		local qualityRef = gModelItem:GetQualityRef(heroRef.quality)
		if qualityRef then
			local heroCallFxList = string.split(qualityRef.heroCallFx, '=')
			eff = heroCallFxList[1]
			local fxEffSize = heroCallFxList[2]
			if not string.isempty(fxEffSize) then
				effScaleSize = tonumber(fxEffSize) * 100
			end
		end
	end
	local initStar = gModelHero:GetHeroInitStarByRefId(heroId)
	if initStar < 4 then
		LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_CALL_HERO_NORMAL)
	end
	if not eff then
		eff = self._heroEffectList[initStar]
	end

	if item then
		local uicommonTrans = CS.FindTrans(item,"EffectRoot")
		self:DestroyWndEffectByKey(instanceId)
		if eff and uicommonTrans then
			self:CreateWndEffect(uicommonTrans,eff,instanceId,effScaleSize,false,false)
		end
	end
end

function UIPrepareMirrorYellAwardTop:InitEvent()
	self:SetWndClick(self.mOkBtn,function() self:OnClickOkBtn() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn, function() self:OnClickEmpty() end)
end

function UIPrepareMirrorYellAwardTop:InitStaticInfo()
	self:SetWndText(self.mFixedIntro, ccClientText(37408))

	self:SetWndButtonText(self.mCloseBtn,ccClientText(37409))
	self:SetWndButtonText(self.mOkBtn,ccClientText(37424))
end

--#####################################################################################################################
--## Tween ############################################################################################################
--#####################################################################################################################
function UIPrepareMirrorYellAwardTop:StartTween()
	self._isCreateAni = true
	local contentTrans = self.mContent
	contentTrans.localRotation = Quaternion.Euler(90,0,0)

	local seq =self._seqCom:CreateSeq(self._startTweenKey)

	local duration = 0.4
	local rotateTween = contentTrans:DORotate(Vector3.New(0,0,0),duration)
	seq:Append(rotateTween)
	seq:InsertCallback(0.1,function ()
		if self._needAni then
			LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_EQUIP_COMMON)
		end
		self:RefreshUI()
	end)
	seq:OnComplete(function()
		self._seqCom:DeleteSeq(self._startTweenKey)
		self._isCreateAni = false
	end)
	seq:PlayForward()
end

function UIPrepareMirrorYellAwardTop:RewardListOnDraw(list, item, itemdata, itempos)
	local uiCommonTrans = CS.FindTrans(item,"CommonUI")
	local uiNameTrans = CS.FindTrans(uiCommonTrans, "UIName")
	local effRoot = CS.FindTrans(item,"EffectRoot")

	local uicommonlist = self._uiCommonList
	local instanceID = item:GetInstanceID()
	local baseClass = uicommonlist[instanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uicommonlist[instanceID] = baseClass
		baseClass:Create(CS.FindTrans(uiCommonTrans,"Icon"))
	end

	local heroId  = itemdata
	local heroRef = gModelHero:GetHeroRef(heroId)
	local heroStar = heroRef.initStar

	local isSel = self._curSelect == heroId
	if isSel then
		self._curSelectPos = itempos
	end

	local heroData = {
		refId = heroId,
		star = heroStar,
		--level = itemdata.breakLv,
	}
	baseClass:SetHeroDataSet(heroData)
	baseClass:SetNoShowLv(true)
	baseClass:EnableShowNum(false)
	baseClass:SetShowGouImg(isSel)
	baseClass:DoApply()

	local itemName = gModelGeneral:GetCommonItemColorNameNoNum({itemType = 2,itemId = heroId})
	self:SetWndText(uiNameTrans,itemName)

	self:ShowHeroEff(item, heroId)
	if self._needAni then
		self:TweenItemScale(uiCommonTrans,itempos, effRoot)
	end

	self:SetWndClick(item,function()
		self:OnclickSelect(heroId, itempos)
	end)

	self:SetWndLongClick(item,function()
		GF.OpenWndTop("UINewSagaStarPre", { refId = heroId, nextStar = heroStar, showType = 2, hideAwaken = true })
	end,0.8,false)
end

function UIPrepareMirrorYellAwardTop:InitPara()

	self._rewardRefIdList   = self:GetWndArg("rewards")
	self._needAni			= self:GetWndArg("needAni")
	self._isCreateAni = false

	self._curSelect 		= gModelCallHero:GetLocalPrepareMirrorCallHero()
	self._curSelectPos = nil

	self._heroEffectList = {
		[4] = "fx_ui_ZHJS_yingxiong_zise",
		[5] = "fx_ui_ZHJS_yingxiong_chengse",
	}
	self._iconPlayTime =0.1
end


function UIPrepareMirrorYellAwardTop:OnRewardItemReturn(list,item,itemdata,itempos)
	local instanceId = item:GetInstanceID()
	self._seqCom:DeleteSeq(instanceId)

	self._curItemTweenList[instanceId] = nil
end

------------------------------------------------------------------
return UIPrepareMirrorYellAwardTop


