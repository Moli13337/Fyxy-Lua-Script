---
--- Created by BY.
--- DateTime: 2023/10/3 17:35:52
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIYellSagaSpreadWin:LWnd
local UIYellSagaSpreadWin = LxWndClass("UIYellSagaSpreadWin", LWnd)
local typeof = typeof
local typeGridLayoutGroup = typeof(CS.GridLayoutGroup)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIYellSagaSpreadWin:UIYellSagaSpreadWin()
	self._uiCommonIconList = {}
	self._seqList = {}
	self._playKey = "moveYuan"
	self._heroEffectList = {
		[4] = "fx_ui_ZHJS_yingxiong_zise",
		[5] = "fx_ui_ZHJS_yingxiong_chengse",
	}
	self._curHeroTimerKey = "_curHeroTimerKey"
	self._showAniKey = "showAniKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIYellSagaSpreadWin:OnWndClose()
	self:ClearCommonIconList(self._uiCommonIconList)
	local seqList = self._seqList
	for k,v in pairs(self._seqList) do
		v:Kill(false)
		seqList[k] = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIYellSagaSpreadWin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIYellSagaSpreadWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIYellSagaSpreadWin:GetShowUpHeroList()
	local extraReward = self._extraReward
	local showLiHuiHeroKeyList = {}
	for i,v in ipairs(extraReward) do
		local itype = v.type
		if itype == LItemTypeConst.TYPE_HERO then
			local heroRefId = v.itemId
			local initStar = gModelHero:GetHeroInitStarByRefId(heroRefId)
			if initStar >= 4 then
				if not showLiHuiHeroKeyList[heroRefId] then
					showLiHuiHeroKeyList[heroRefId] = i
				end
			end
		end
	end
	local list = {}
	for heroRefId,idx in pairs(showLiHuiHeroKeyList) do
		table.insert(list,{
			heroRefId = heroRefId,
			idx = idx
		})
	end
	table.sort(list,function(a,b)
		return a.idx < b.idx
	end)
	local showLiHuiHeroList = {}
	for i,v in ipairs(list) do
		local ref = gModelHero:GetHeroRef(v.heroRefId)
		if ref then
			table.insert(showLiHuiHeroList,v.heroRefId)
		end
	end
	table.sort(showLiHuiHeroList,function(a,b)
		local refA,refB = gModelHero:GetHeroRef(a),gModelHero:GetHeroRef(b)
		if refA and refB then
			local qualityA,qualityB = refA.quality,refB.quality
			if qualityA ~= qualityB then
				return qualityA > qualityB
			end
			return a < b
		end
		return false
	end)
	return showLiHuiHeroList
end

function UIYellSagaSpreadWin:PlayEff(trans,eff,key)
	self:CreateWndEffect(trans,eff,key,100,false,false)
end

function UIYellSagaSpreadWin:OnTimer(key)
	if key == self._curHeroTimerKey then
		self:TimerStop(key)
		self:OnCreateHeroList()
	end
end

function UIYellSagaSpreadWin:InitMessage()

end

function UIYellSagaSpreadWin:CreateTimer(key,time,loopCnt)
	time = time or 1
	loopCnt = loopCnt or -1
	self:TimerStop(key)
	self:TimerStart(key,time,false,loopCnt)
end

function UIYellSagaSpreadWin:PlayYuanAni()
	local seqTween
	self:TweenSeqKill(self._playKey)
	if not seqTween then
		local showTime = 18
		seqTween = self:TweenSeqCreate(self._playKey,function(seq)
			local moveZ = self.mYuan.transform:DORotate(Vector3.New(0,0,180),showTime)
			seq:Append(moveZ)
			return seq
		end)
	end
	seqTween:SetLoops(-1,DG.Tweening.LoopType.Restart)
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._playKey)
	end)
	seqTween:PlayForward()
end

function UIYellSagaSpreadWin:InitCommand()
	local structCallShowInfo = self:GetWndArg("StructCallShowInfo")
	local playerName		 = structCallShowInfo.callPlayerName or structCallShowInfo.playerName
	self._playerName		 = playerName
	self:SetWndText(self.mPlayerNameText,playerName)
	local formatStr = ccClientText(11652)
	local createTime = structCallShowInfo.createTime
	self._createTime = createTime
	if createTime then
		local time = LUtil.OSDate(formatStr,tonumber(createTime)/1000)
		self:SetWndText(self.mTimeText,time)
	end
	self:SetWndText(self.mEnterBtnName,ccClientText(10102))
	self:SetWndText(self.mShareBtnName, ccClientText(13273))

	local rankValue = structCallShowInfo.rankValue
	self._rankValue = rankValue
	self:SetWndText(self.mOuQiText,rankValue)
	self:PlayEff(self.mTopView,"fx_ui_ZHJS_lanse_xingdian","fx_ui_ZHJS_lanse_xingdian")
	self:PlayEff(self.mView,"fx_ui_ZHJS_lanse_BJxingguang","fx_ui_ZHJS_lanse_BJxingguang")
	self:PlayEff(self.mEffectRoot,"fx_ui_zhaohuanouqi","fx_ui_zhaohuanouqi")
	self:PlayYuanAni()
	local heroList = structCallShowInfo.extraReward
	self._extraReward = heroList
	--local heroList = {}
	--for i, v in ipairs(list) do
	--	if(v.type == 2)then
	--		table.insert(heroList,v)
	--	end
	--end
	self._lihuiInitPos = self.mSpPos.localPosition
	self:ShowUpHeroList()
	local heroScroll = self.mHeroScroll
	if(#heroList == 1)then
		heroScroll = self.mHeroScroll1
	end
	local uiList = self:GetUIScroll("_uiRewardList")
	uiList:Create(heroScroll, heroList, function(...)
		self:OnDrawRewardItem(...)
	end)

	self:SetWndText(self.mOuQiZhiImgText, ccClientText(11681))
end

function UIYellSagaSpreadWin:CreateLiHui(heroRefId,isMin)
	local startTimeFunc = function()
		if isMin then return end
		local callHeroShowResultCd = gModelCallHero:GetCallConfigRefByKey("callHeroShowResultCd") or 5
		self:CreateTimer(self._curHeroTimerKey,callHeroShowResultCd,1)
	end

	if self._curShowHero and self._curShowHero == heroRefId then
		startTimeFunc()
		return
	end

	--- 英雄召唤获得界面Y轴
	local heroShowLH3 = 100

	--- 英雄召唤获得界面倍数
	local heroShowLH2 = 1

	local effRef = gModelHero:GetHeroEffectRef(heroRefId)
	if effRef then
--[[		local tHeroShowLH3 = effRef.heroShowLH3 or 0
		if tHeroShowLH3 > 0 then
			heroShowLH3 = tHeroShowLH3
		end

		local tHeroShowLH4 = effRef.heroShowLH4 or 0
		if tHeroShowLH4 > 0 then
			heroShowLH4 = tHeroShowLH4
		end
		heroShowLH2 = effRef.heroShowLH2]]
	end

	local showNewLHFunc = function()
		local showHeroLiHuiList = self._showHeroLiHuiList
		if not showHeroLiHuiList then
			showHeroLiHuiList = {}
			self._showHeroLiHuiList = showHeroLiHuiList
		end

		--local curPos = self.mSpPos.localPosition
		--self.mSpPos.localPosition = Vector3(curPos.x,heroShowLH3,curPos.z)
		self.mSpPos.localPosition = gModelHeroExtra:GetHeroShowLH1(effRef,self.mSpPos)

		local showHeroLiHui = showHeroLiHuiList[heroRefId]
		if showHeroLiHui then
			showHeroLiHui:SetVisible(true)
		else
			local spine = gModelHero:GetHeroPrefabNameByRefId(heroRefId,nil,true)
			if not spine then
				return
			end

			showHeroLiHui = self:CreateWndSpine(self.mSpPos,spine,heroRefId,false,function(dpSpine)
				--dpSpine:SetAlpha(0.5)
				dpSpine:SetScale(heroShowLH2)
			end)
		end
		showHeroLiHuiList[heroRefId] = showHeroLiHui
		self._curShowSpine = showHeroLiHui
		self._curShowHero = heroRefId
		--CS.ShowObject(self.mSpPos,true)
	end

	local tCurPos = self.mSpPos.localPosition
	self.mSpPos.localPosition = Vector3(self._lihuiInitPos.x,tCurPos.y,self._lihuiInitPos.z)

	local curLiHuiPos = self.mSpPos.localPosition
	local curLiHuiPosX = curLiHuiPos.x
	local curLiHuiPosY = curLiHuiPos.y
	local curLiHuiPosZ = curLiHuiPos.z

	local vanishTime = 1
	local showTime = 1
	local moveX = self._lihuiInitPos.x

	if self._curShowSpine and self._curShowHero and self._curShowHero ~= heroRefId then
		self:TweenSeq_MoveFadeAni(self._showAniKey,{
			{
				trans = self.mSpPos,
				aniStarPos = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ),
				vanishPos = Vector3(curLiHuiPosX - moveX,curLiHuiPosY,curLiHuiPosZ),
				aniShowPos = Vector3(curLiHuiPosX + moveX,heroShowLH3,curLiHuiPosZ),
				showPos = Vector3(curLiHuiPosX,heroShowLH3,curLiHuiPosZ),
			}
		},{
			initAlpha = 1,
			fromAlpha = 1,
			toAlpha = 0,
			vanishTime = vanishTime,
			showTime = showTime,
			nextShowAni = true,
			nextShowFunc = function()
				self._curShowSpine:SetVisible(false)
				showNewLHFunc()
			end,
			endFunc = function()
				self.mSpPos.localPosition = Vector3(curLiHuiPosX,heroShowLH3,curLiHuiPosZ)
				showNewLHFunc()
				startTimeFunc()
			end
		})
	else
		self:TweenSeq_MoveFadeAni(self._showAniKey,{
			{
				trans = self.mSpPos,
				aniStarPos = Vector3(curLiHuiPosX + moveX,heroShowLH3,curLiHuiPosZ),
				vanishPos = Vector3(curLiHuiPosX,heroShowLH3,curLiHuiPosZ),
			}
		},{
			initAlpha = 0,
			fromAlpha = 0,
			toAlpha = 1,
			vanishTime = vanishTime,
			showTime = showTime,
			startShowFunc = function()
				showNewLHFunc()
			end,
			endFunc = function()
				self.mSpPos.localPosition = Vector3(curLiHuiPosX,heroShowLH3,curLiHuiPosZ)
				startTimeFunc()
			end
		})
	end
end

function UIYellSagaSpreadWin:OnSetItem(list, item, itemData, itemPos)
	local refId = itemData.itemId
	local itype = itemData.type
	local count = itemData.count
	local aniTrans = CS.FindTrans(item, "CommonUI")
	local iconTrans = CS.FindTrans(aniTrans, "Icon")

	local InstanceID = item:GetInstanceID()
	local baseClass = self._uiCommonIconList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiCommonIconList[InstanceID] = baseClass
		baseClass:Create(iconTrans)
	end
	baseClass:SetCommonReward(itype, refId, count)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()

	self:SetIconClickScale(iconTrans, true)
	self:SetWndClick(iconTrans,function()
		if itype == LItemTypeConst.TYPE_ITEM then
			gModelGeneral:OpenItemInfoTipTop(refId,count,nil,nil,nil,true)
		elseif itype == LItemTypeConst.TYPE_HERO then
			gModelGeneral:OpenHeroSimpleTip(refId,true)
		elseif itype == LItemTypeConst.TYPE_EQUIP then
			gModelGeneral:OpenEquipInfoTip(refId,nil,false,true,false,nil,true)
		end
	end)
end

function UIYellSagaSpreadWin:OnShareBtnClick()
	local jsonStr = self:GetShareJsonData()
	local data = {
		root = self.mShareBtn,
		shareType = ModelChat.CHATSHARE_RANK_CALL,
		shareData = jsonStr
	}
	gModelGeneral:OpenShareTip(data)
end

function UIYellSagaSpreadWin:CreateShowHeroLiHui(upHeroList)
	self:TimerStop(self._curHeroTimerKey)
	local len = #upHeroList
	if len < 1 then return end
	self._showUpHeroList = upHeroList
	self._index = 1
	self:OnCreateHeroList()
end

function UIYellSagaSpreadWin:PlayAni(item, itemData, itemPos)
	local itype = itemData.type
	local refId = itemData.itemId
	local instanceId = item:GetInstanceID()
	local seq = self._seqList[instanceId]
	if seq then
		seq:Kill(false)
		self._seqList[instanceId] = nil
	end

	local aniTrans = CS.FindTrans(item, "CommonUI")

	--if itemData.isPlayAni then
	--	aniTrans.localScale = Vector3.one
	--	return
	--end
    --
	--itemData.isPlayAni = true

	aniTrans.localScale = Vector3.zero
	local dtSequence = YXTween.TweenSequenceIns()
	self._seqList[instanceId] = dtSequence

	local playTime = 0.2
	local startT = itemPos * playTime
	local ani1 = aniTrans:DOScale(1, playTime)

	dtSequence:AppendInterval(startT)
	dtSequence:Append(ani1)

	dtSequence:OnComplete(function()
		self._seqList[instanceId] = nil
		if itype == LItemTypeConst.TYPE_HERO then
			local initStar = gModelHero:GetHeroInitStarByRefId(refId)
			if initStar < 4 then
				LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_CALL_HERO_NORMAL)
			end
			local eff = self._heroEffectList[initStar]
			if item then
				local uicommonTrans = CS.FindTrans(item,"effectRoot")
				if eff and uicommonTrans then
					self:CreateWndEffect(uicommonTrans,eff,eff..itemPos,100,false,false)
				end
			end
		end
	end)

	dtSequence:PlayForward()
end

function UIYellSagaSpreadWin:InitEvent()
	self:SetWndClick(self.mEnterBtn,function() self:WndClose() end)
	self:SetWndClick(self.mShareBtn, function() self:OnShareBtnClick() end)
end

function UIYellSagaSpreadWin:OnCreateHeroList()
	local showUpHeroList = self._showUpHeroList or {}
	local len = #showUpHeroList
	if len < 1 then
		self:TimerStop(self._curHeroTimerKey)
		return
	end
	local index = self._index
	if index > len then
		index = 1
		self._index = index
	else
		self._index = index + 1
	end
	local heroRefId = showUpHeroList[index]
	if not heroRefId then
		self:TimerStop(self._curHeroTimerKey)
		return
	end
	local isMin = len <= 1
	self:CreateLiHui(heroRefId,isMin)
end

function UIYellSagaSpreadWin:ShowUpHeroList()
	local showLiHuiHeroList = self:GetShowUpHeroList()
	self:CreateShowHeroLiHui(showLiHuiHeroList)
end

function UIYellSagaSpreadWin:GetShareJsonData()
	local data = {
		extraReward = self._extraReward,
		createTime 	= self._createTime,
		rankValue	= self._rankValue,
		callPlayerName = self._playerName,
	}

	return JSON.encode(data)
end

function UIYellSagaSpreadWin:OnDrawRewardItem(list, item, itemdata, itempos, fromHeadTail)
	self:OnSetItem(list, item, itemdata, itempos)
	self:PlayAni(item, itemdata, itempos)
end
------------------------------------------------------------------
return UIYellSagaSpreadWin


