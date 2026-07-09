---
--- Created by BY.
--- DateTime: 2023/10/25 17:45:14
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIItemSummonSowPop:LWnd
local UIItemSummonSowPop = LxWndClass("UIItemSummonSowPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIItemSummonSowPop:UIItemSummonSowPop()
	self._uiCommonList = {}
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
function UIItemSummonSowPop:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIItemSummonSowPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIItemSummonSowPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIItemSummonSowPop:GetShareJsonData()
	local _reward = self._reward or {}
	local list = {}
	for i, v in ipairs(_reward) do
		local data = {
			count = v.itemNum,
			effect = v.isShowEff,
			itemId = v.itemId,
			type = v.itemType
		}
		table.insert(list,data)
	end

	local playerName = gModelPlayer:GetPlayerName()
	local data = {
		extraReward = list,
		rankValue	= self._rankValue or 0,
		callPlayerName = playerName,
		shareType = ModelChat.CHAT_SHARE_34,
		createTime = GetTimestamp() * 1000
	}
	return JSON.encode(data)
end
function UIItemSummonSowPop:OnClickEndEff()
	self:EndAni()
end
function UIItemSummonSowPop:ShowUpHeroList(func)
	local dataList = self._reward or {}
	local upHeroList = {}
	for i,v in ipairs(dataList) do
		local itype = v.itemType
		if itype == LItemTypeConst.TYPE_HERO then
			local heroRefId = v.itemId
			local initStar = gModelHero:GetHeroInitStarByRefId(heroRefId)
			if initStar >= 4 then
				table.insert(upHeroList,{refId = heroRefId})
			end
		end
	end
	gModelGeneral:ShowUpHero(upHeroList,func)
end
function UIItemSummonSowPop:InitEvent()
	self:SetWndClick(self.mBgImage,function ()self:OnClickClose() end)
	self:SetWndClick(self.mBtnSummon,function ()self:OnClickSummon() end)
	self:SetWndClick(self.mBtnGet,function ()self:OnClickGet() end)
	self:SetWndClick(self.mBtnConfirm,function ()self:OnClickClose() end)
	self:SetWndClick(self.mTheGasBg,function ()self:OnClickShare() end)
	self:SetWndClick(self.mAniEff,function ()self:OnClickEndEff() end)
end

function UIItemSummonSowPop:CreateTimer(key,time,loopCnt)
	time = time or 1
	loopCnt = loopCnt or -1
	self:TimerStop(key)
	self:TimerStart(key,time,false,loopCnt)
end
function UIItemSummonSowPop:InitCommand()
	self:SetWndText(self.mTheGasText,ccClientText(30913))
	self:SetWndButtonText(self.mBtnSummon,ccClientText(10250))
	self:SetWndButtonText(self.mBtnGet,ccClientText(10251))
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(22002))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:RefreshOpen()
end
function UIItemSummonSowPop:RewardListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local commonUI = self:FindWndTrans(root,"CommonUI/Icon")
	local name = self:FindWndTrans(root,"Name")
	local effectRoot = self:FindWndTrans(root,"CommonUI/EffectRoot")

	local instanceID = item:GetInstanceID()
	local itemType = itemdata.itemType
	local itemId = itemdata.itemId
	local itemNum = itemdata.itemNum

	local uicommonlist = self._uiCommonList
	local baseClass = uicommonlist[instanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uicommonlist[instanceID] = baseClass
		baseClass:Create(commonUI)
	end
	baseClass:SetCommonReward(itemType, itemId, itemNum)
	baseClass:DoApply()
	if itemType == LItemTypeConst.TYPE_HERO then
		self:ShowHeroEff(effectRoot,instanceID,itemId)
	end
	local itemName = gModelGeneral:GetCommonItemName({itemType = itemType,itemId = itemId})
	self:SetWndText(name,itemName)
	self:InitTextShowWithLanguage(name)
	self:SetWndClick(item,function()
		if itemType == LItemTypeConst.TYPE_HERO then
			gModelGeneral:OpenHeroSimpleTip(itemId,true)
		else
			gModelGeneral:OpenItemInfoTip(itemId,itemNum)
		end
	end)
end
function UIItemSummonSowPop:OnTimer(key)
	if key == self._curHeroTimerKey then
		self:TimerStop(key)
		self:OnCreateHeroList()
	end
end

function UIItemSummonSowPop:RefreshData()
	local rankValue = self._rankValue

	self:SetWndText(self.mTheGasValueText,rankValue)

	self:RefreshReward()
end

function UIItemSummonSowPop:CreateLiHui(heroRefId,isMin)
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

--[[		local curPos = self.mSpPos.localPosition
		self.mSpPos.localPosition = Vector3(curPos.x,heroShowLH3,curPos.z)]]
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
		CS.ShowObject(self.mSpPos,true)
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
function UIItemSummonSowPop:InitMessage()

end
function UIItemSummonSowPop:OnClickShare()
	local jsonStr = self:GetShareJsonData()
	local data = {
		root = self.mBtnShare,
		shareType = ModelChat.CHAT_SHARE_34,
		shareData = jsonStr
	}
	gModelGeneral:OpenShareTip(data)
end
function UIItemSummonSowPop:ShowHeroEff(effRoot,instanceId,heroId)
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
	self:DestroyWndEffectByKey(instanceId)
	if not eff then return end
	self:CreateWndEffect(effRoot,eff,instanceId,effScaleSize,false,false)
end
function UIItemSummonSowPop:OnCreateHeroList()
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

function UIItemSummonSowPop:OnTryTcpReconnect()
	self:WndClose()
end
function UIItemSummonSowPop:RefreshOpen()
	local refId = self:GetWndArg("refId")
	local id = self:GetWndArg("id")
	local reward = self:GetWndArg("reward")
	local callNum = self:GetWndArg("callNum")
	local rankValue = self:GetWndArg("rankValue")
	local opType = self:GetWndArg("opType") or 0
	local isNoEff = self:GetWndArg("isNoEff")

	CS.ShowObject(self.mAniRoot,false)
	CS.ShowObject(self.mBtnSummon,opType == 0)
	CS.ShowObject(self.mBtnGet,opType == 0)
	CS.ShowObject(self.mBtnConfirm,opType == 1)
	CS.ShowObject(self.mTitleImg,opType == 0)
	CS.ShowObject(self.mTitleEff,opType == 1)
	if opType == 1 then
		self:CreateWndEffect(self.mTitleEff,"fx_ui_gongxihuode","TitleEff_fx_ui_gongxihuode",100)
	end

	local dataList = LxDataHelper.ParseItem_3List(reward)
	self._refId = refId
	self._id = id
	self._reward = dataList
	self._rankValue = rankValue
	self._isAniEff = not isNoEff
	self._lihuiInitPos = self.mSpPos.localPosition

	if self._isAniEff then
		GF.OpenWnd("UIMirrorYellSagaSow",{
			viewType = 3,
			getHeroList = dataList,
			callEndFunc = function()
				self:EndAni()
			end
		})
		return
	end
	CS.ShowObject(self.mAniRoot,true)
	local showLiHuiHeroList = self:GetShowUpHeroList()
	self:CreateShowHeroLiHui(showLiHuiHeroList)
	self:RefreshData()
end
function UIItemSummonSowPop:OnClickSummon()
	local refId = self._refId
	local id = self._id
	gModelGeneral:OpenUIOrdinTips({refId = 10035,func = function ()
		gModelGeneral:ItemSummonOperate(refId,id,0)
	end})
end

function UIItemSummonSowPop:OnClickClose()
	if self._isAniEff then return end
	self:WndClose()
end
function UIItemSummonSowPop:EndAni()
	CS.ShowObject(self.mAniEff, false)
	self:ShowUpHeroList(function ()
		CS.ShowObject(self.mAniRoot, true)
		local showLiHuiHeroList = self:GetShowUpHeroList()
		self:CreateShowHeroLiHui(showLiHuiHeroList)
		self:RefreshData()
		self._isAniEff = false
	end)
end
function UIItemSummonSowPop:OnClickGet()
	local refId = self._refId
	local id = self._id
	gModelGeneral:OpenUIOrdinTips({refId = 10036,func = function ()
		gModelGeneral:ItemSummonOperate(refId,id,1)
		self:WndClose()
	end})
end
function UIItemSummonSowPop:CreateShowHeroLiHui(upHeroList)
	self:TimerStop(self._curHeroTimerKey)
	local len = #upHeroList
	if len < 1 then return end
	self._showUpHeroList = upHeroList
	self._index = 1
	self:OnCreateHeroList()
end
function UIItemSummonSowPop:GetShowUpHeroList()
	local extraReward = self._reward or {}
	local showLiHuiHeroKeyList = {}
	for i,v in ipairs(extraReward) do
		local itype = v.itemType
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
function UIItemSummonSowPop:OnWndRefresh()
	self:RefreshOpen()
end
function UIItemSummonSowPop:RefreshReward()
	local dataList = self._reward or {}

	local uiList = self._itemSuperList
	if uiList then
		uiList:RefreshList(dataList)
		uiList:DrawAllItems()
	else
		uiList = self:GetUIScroll("mRewardList")
		self._itemSuperList = uiList
		uiList:Create(self.mRewardList,dataList,function (...) self:RewardListItem(...) end,UIItemList.SUPER_GRID)
	end
	uiList:EnableScroll(#dataList > 10,false)
end
------------------------------------------------------------------
return UIItemSummonSowPop


