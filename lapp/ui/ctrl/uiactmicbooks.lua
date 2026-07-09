---
--- Created by Administrator.
--- DateTime: 2023/10/1 11:09:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActMicBooks:LWnd
local UIActMicBooks = LxWndClass("UIActMicBooks", LWnd)

local Tweening = DG.Tweening

UIActMicBooks.DISPLAY_ITEM = "0"
UIActMicBooks.DISPLAY_HERO = "1"

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActMicBooks:UIActMicBooks()
    self._displayItemPath = "DisplayItem"

	---@type LUIHeroObject
	self._curUIHeroObj = nil

	---@type table<number,UIIconEasyList>
	self._uiListTbl = {}

	self._showAniKey = "showAniKey"
	self._suspendTweenKey = "_suspendTweenKey"
	self._itemCanvasGroupTweenStartKey = "_itemCanvasGroupTweenStartKey"
	self._extraItemCanvasGroupTweenKey = "_extraItemCanvasGroupTweenKey"

	self._heroDisplayChangeTimerKey = "_heroDisplayChangeTimerKey"
	self._showExtraRewardTimer = "_showExtraRewardTimer"

	self._stepTitleFormat = "%s %s"
	self._stepDescFormat = "%s<br>%s"

	self._extraRewardSpineName = "fx_ui_mfsk_jiangchizhuijia"

	self._itemEffName = "fx_mofashujiangli_01"
	self._itemGetEffName = "fx_mofashujiangli_02"
	self._bgShowSpineName = "fx_ui_mofashuku1"
	self._bgDrawSpineName = "fx_ui_mofashuku1_2"

	self._canvasRootAnimKey = "_canvasRootAnimKey"
	self._delayShowRewardTimerKey = "_delayShowRewardTimerKey"
	self._delayShowRootTimerKey = "_delayShowRootTimerKey"

	self._bgSpineAnimEnum = {
		COMMON = "idle",
		START = "show",
		DRAW = "show1",
	}

	self._drawSpineAnimEnum = {
		DRAW = "show1",
	}

	self._changeThemeEffName = "fx_ui_mfsk_zhutizhuanchang"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActMicBooks:OnWndClose()
	if self._curUIHeroObj then
		self._curUIHeroObj:Destroy()
		self._curUIHeroObj = nil
	end

	if self._uiListTbl then
		local uiListTbl = self._uiListTbl
		for k,v in pairs(uiListTbl) do
			v:Destroy()
			uiListTbl[k] = v
		end
		self._uiListTbl = nil
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActMicBooks:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActMicBooks:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitParam()
	self:InitStaticContent()
end

--#####################################################################################################################
--## CallRoot #########################################################################################################
--#####################################################################################################################
function UIActMicBooks:InitCallRoot()
	local config = self._config
	if not config then return end

	--local discountBg = config.discountBg
	--if LxUiHelper.IsImgPathValid(discountBg) then
	--	self:SetWndEasyImage(self.mDiscountBg, discountBg, nil, true)
	--end
end

function UIActMicBooks:CloseWndFunc()
	self:WndClose()
end

function UIActMicBooks:GetCurDisplayItemList()
	local curStep = self._curStep
	local curLevelData = self._themeDataList[curStep]
	local displayReward = curLevelData.displayReward

	if not displayReward then
		LogError("self._themeDataList[curStep].displayReward is a nil, curStep = "..(curStep or "nil"))
		return nil
	end

	return displayReward
end

function UIActMicBooks:OnClickBotBtn(btnIndex,isClick)
	self._pageId = btnIndex
	self:SetSeleBtn()

	--用于切换子界面，目前暂无需求
	--local pageDataList=self:GetPageDataList(btnIndex)
	--if (pageDataList) then
	--	if(self._pageId ~= btnIndex)then
	--		self:CloseAllChild()
	--	else
	--		if(isClick)then
	--			return
	--		end
	--	end
	--	self._pageId = btnIndex
	--	self:SetSeleBtn()
	--	local wndName = self:GetPageWndNameTypeByBtnIndex(btnIndex)
	--	self._wnd = self:CreateChildWnd(self.mChildRoot, wndName,{
	--		sid = self._sid,
	--		pbDataList = pageDataList,
	--	})
	--end
end

function UIActMicBooks:PlayChangThemEff()
	CS.ShowObject(self.mChangThemeEff, false)
	self:CreateWndEffect(self.mChangThemeEff,self._changeThemeEffName,self._changeThemeEffName,100, false, false)
	CS.ShowObject(self.mChangThemeEff, true)
end

function UIActMicBooks:OnActivityDropGift(data)
	local sid = data.sid
	if self._sid ~= sid then return end

	self._actDropGiftData = data
	self:PlayTurnTableAnimation()
end

function UIActMicBooks:RefreshStepDescContent()
	local roundStr
	if self._isLoop then
		local curRound = self._loopCount + 1
		roundStr = string.replace(ccClientText(38207), curRound)
	end

	local curStep = self._curStep
	local stepStr =string.replace(ccClientText(38211), curStep)
	local titleStr
	if roundStr then
		titleStr = string.replace(self._stepTitleFormat, titleStr, stepStr)
	else
		titleStr = stepStr
	end

	self:SetWndText(self.mStepTitle, titleStr)
	self:InitTextLineWithLanguage(self.mStepTitle, -30)
	self:InitTextSizeWithLanguage(self.mStepTitle, -2)

	if not self._stepDataList then return end
	local stepDataList = self._stepDataList[curStep]
	if not stepDataList then return end
	local stepRateShow = stepDataList.stepRateShow
	local rateStr = string.replace(ccClientText(38208), stepRateShow)
	local curVal, maxValue = self:GetStepProgress(curStep)
	local durationValue = maxValue - curVal

	local maxStep = #self._stepDataList
	local callStr
	if curStep + 1 < maxStep then
		if durationValue <= 0 then
			callStr = string.replace(ccClientText(38210))
		else
			callStr = string.replace(ccClientText(38209), durationValue)
		end
	else
		if self:CheckCanOpenNextRound() then
			if durationValue <= 0 then
				callStr = string.replace(ccClientText(38218))
			else
				callStr = string.replace(ccClientText(38213), durationValue)
			end
		elseif curStep < maxStep then
			if durationValue <= 0 then
				callStr = string.replace(ccClientText(38210))
			else
				callStr = string.replace(ccClientText(38214), durationValue)
			end

		else
			callStr = ccClientText(38212)
		end
	end

	self:SetWndText(self.mStepDesc, string.replace(self._stepDescFormat, rateStr, callStr))
end

function UIActMicBooks:ResetThemePageData()
	self._curStep = 0
	if not self._isSelectTheme then
		return
	end

	local curTheme = self._selectTheme

	local pageData = self._themePageList[curTheme]
	local themeDataList = {}
	for k,v in pairs(pageData.entry) do
		local entryId = v.entryId
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,entryId)
		if entryCfg then
			local moreInfo = string.split(entryCfg.moreInfo, '|')
			local curLvl = tonumber(moreInfo[1])
			local displayIndex = tonumber(moreInfo[2])
			local extraIndex = tonumber(moreInfo[3])
			local isDisplay = displayIndex == 1
			local extraReward = extraIndex == 1
			if isDisplay or extraReward then
				local reward = LxDataHelper.ParseItem(entryCfg.reward)

				if not themeDataList[curLvl] then
					themeDataList[curLvl] = {}
				end

				if isDisplay then
					if not themeDataList[curLvl].displayReward then
						themeDataList[curLvl].displayReward = {}
					end

					table.insert(themeDataList[curLvl].displayReward, reward)
				end

				if extraReward then
					if not themeDataList[curLvl].extraReward then
						themeDataList[curLvl].extraReward = {}
					end

					table.insert(themeDataList[curLvl].extraReward, reward[1])
				end
			end
		end
	end

	local moreInfo = JSON.decode(pageData.moreInfo)
	local stage = moreInfo.stage 				--当前主题的阶段
	self._curStep = stage
	self._extractCount = moreInfo.extractCount	--当前主题抽取次数
	self._loopCount = moreInfo.loopCount 		--当前主题已循环次数

	self._themeDataList = themeDataList
end

function UIActMicBooks:RefreshCallRoot()
	if not self._isSelectTheme then return end
	local curStep = self._curStep
	local curVal, maxValue = self:GetStepProgress(curStep)

	local selectStr
	if curVal >= maxValue then
		local maxStep = #self._stepDataList
		if curStep < maxStep then
			selectStr = ccClientText(38215)
		elseif self:CheckCanOpenNextRound() then
			selectStr = ccClientText(38216)
		end
	end

	local isShowNext = not string.isempty(selectStr)
	local isShowCall = self:CheckCanCall()
	CS.ShowObject(self.mCallBtnRoot, isShowCall)
	CS.ShowObject(self.mSelectBtnRoot,  isShowNext)
	if isShowNext then
		self:SetWndButtonText(self.mSelectBtn, selectStr)
	end

	if isShowCall then
		self:RefreshCallBtn()
	end
end

function UIActMicBooks:ResetStepCfgData()
	if not self._isSelectTheme then
		return
	end

	local curTheme = self._selectTheme

	local data = self._themeCfgList[curTheme]
	if not data then
		LogError("self._themeCfgList[curTheme] is a nil, curTheme = "..(curTheme or "nil"))
		return
	end

	local stepList = {}
	local stepNum =  data.stepNum
	for i = 1, stepNum do
		local curData = {
			stepLimitNum 	= tonumber(data.stepLimitNum[i]),
			stepRewardNum 	= tonumber(data.stepRewardNum[i]),
			stepRollNum 	= tonumber(data.stepRollNum[i]),
			stepItemNum 	= data.stepItemNum[i],
			stepItemDiscount = data.stepItemDiscount[i],
			stepText 		= data.stepText[i],
			stepRateShow	= data.stepRateShow[i],
		}

		stepList[i] = curData
	end

	self._stepDataList = stepList
end

function UIActMicBooks:PlayDrawAnim()
	self:TimerStop(self._delayShowRewardTimerKey)
	self:TimerStart(self._delayShowRewardTimerKey, 2.5, false, 1)
	self:TimerStop(self._delayShowRootTimerKey)
	self:TimerStart(self._delayShowRootTimerKey, 4, false, 1)
	CS.ShowObject(self.mBotView, false)
	CS.ShowObject(self.mCanvasRoot, false)

	self:PlayBgShowDrawSpine()
	self:PlayDrawSpine()
end

function UIActMicBooks:PlayItemListAnimation()
	self:TweenSeq_Suspend(self._suspendTweenKey,self.mDisplayItem, self._itemFromPos,self._itemEndPos,
			2,nil,Tweening.Ease.InOutFlash,true)


	if self._isShowChangeAni then
		local endFunc = function()
			self:RefreshDisplayItemShow()
		end

		self:TweenSeq_FadeInStaysAway(self._itemCanvasGroupTweenStartKey, self.mDisplayItem,
				{
					waitTime = 3,
					showTime = 0.5,
					noShowTime = 0.5,
					openInteractable = true,
					endFunc = endFunc,
					isLoop = true,
				})
	end
end

function UIActMicBooks:CheckCanResetTheme()
	local cfg = self._config
	if not cfg then return false end

	local curStep = self._curStep
	local themeCount = self._themeCount
	local themeSelectNum = cfg.themeSelectNum
	local themeSelectStep = cfg.themeSelectStep
	return themeCount < themeSelectNum and curStep < themeSelectStep
end

function UIActMicBooks:OnClickSelectBtn()
	local curStep = self._curStep
	local maxStep = #self._stepDataList
	local isReset = false
	if curStep == maxStep and self:CheckCanOpenNextRound() then
		isReset = true
	end

	local sid = self._sid
	if isReset then
		--重置阶段
		self:PlayNextClassAnim()
		local args = "4"
		gModelActivity:OnActivitySpecialOpReq(sid,nil,nil,nil, args, ModelActivity.MAGIC_BOOKS_OPS)
	else
		--开启下一阶段
		local func = function()
			self:PlayNextClassAnim()
			local args = "3"
			gModelActivity:OnActivitySpecialOpReq(sid,nil,nil,nil, args, ModelActivity.MAGIC_BOOKS_OPS)
		end

		local nextStep = curStep + 1
		local openNoResetStep = false
		if self:CheckCanResetTheme() then
			local cfg = self._config
			local themeSelectStep = cfg.themeSelectStep
			if nextStep >= themeSelectStep then
				openNoResetStep = true
			end
		end

		local wndPara
		if openNoResetStep then
			--下阶段不可重置主题
			wndPara =
			{
				refId = 110078,
				sid  = sid,
				para = {nextStep,nextStep},
				func = func,
			}
		else
			wndPara =
			{
				refId = 110079,
				sid  = sid,
				para = {nextStep},
				func = func,
			}
		end

		gModelGeneral:OpenUIOrdinTips(wndPara)
	end
end


--#####################################################################################################################
--## BotView ##########################################################################################################
--#####################################################################################################################
function UIActMicBooks:SetBotList()
	local cfg = self._config
	if not cfg then return end

	local mainPage = cfg.mainPage
	local mainPageArr = string.split(mainPage, "|")
	local list = mainPageArr
	local botNum = #list
	local isShowBot = botNum > 1
	CS.ShowObject(self.mBotBtnScroll, isShowBot)
	if not isShowBot then return end

	local uiList = self._uiList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mBotBtnScroll")
		self._uiList = uiList
		uiList:Create(self.mBotBtnScroll, list, function(...)
			self:OnBotList(...)
		end)
		self._uiList:EnableScroll(false, true)
	end

	self:SetSeleBtn()
end

--#####################################################################################################################
--## DisplayItem ######################################################################################################
--#####################################################################################################################
function UIActMicBooks:StartDisplayItem()
	self._itemDataIndex = 0
	self:RefreshDisplayItemShow()
	self:PlayItemListAnimation()
end

function UIActMicBooks:OnBgShowSpineLoad(spine)
	spine:PlayAnimation(0,self._bgSpineAnimEnum.START,false)
	spine:SetAnimationCompleteFunc(function (aniname)
		if self._bgSpineAnimEnum.START == aniname then
			spine:PlayAnimationSolid(self._bgSpineAnimEnum.COMMON,true)
			CS.ShowObject(self.mCanvasRoot, true)
			self:TweenSeq_AlphaCanvasTrans(self._canvasRootAnimKey, self.mCanvasRoot, 0, 1, 1)
		elseif self._bgSpineAnimEnum.DRAW then
			spine:PlayAnimationSolid(self._bgSpineAnimEnum.COMMON,true)

			--更换阶段的动画
			if self._isNextAnim then
				self._isNextAnim = false
				self:PlayChangThemEff()
				self:TweenSeq_AlphaCanvasTrans(self._canvasRootAnimKey, self.mCanvasRoot, 0, 1, 1)
				CS.ShowObject(self.mCanvasRoot, true)
			end
		end
	end)
end

function UIActMicBooks:PlayNextClassAnim()
	self._isNextAnim = true
	CS.ShowObject(self.mCanvasRoot, false)
	self:PlayBgShowDrawSpine()
end

function UIActMicBooks:RefreshStepRoot()
	local list = self._stepDataList
	if not list then
		return
	end

	local stepMaxNum = #list
	self._stepMaxNum = stepMaxNum
	self._extraItemList = {}
	self._showBoxDetailIndex = 1

	local uiBtnList = self._uiBtnList
	if not uiBtnList then
		uiBtnList = UIListEasy:New()
		uiBtnList:Create(self,self.mStepList)
		uiBtnList:EnableScroll(stepMaxNum > 5,true)
		uiBtnList:SetFuncOnItemDraw(function(...)
			self:OnDrawStep(...)
		end)
		self._uiBtnList = uiBtnList
	end

	for i,v in ipairs(list) do
		uiBtnList:AddData(i,v)
	end
	uiBtnList:RefreshList()
	--if tIndex then
	--	uiBtnList:DelayScrollTo(tIndex - 1)
	--end
end

function UIActMicBooks:OnClickResetBtn()
	self:OpenWndThemePop()
end

function UIActMicBooks:ResetGoalPageData()
	if not self._isSelectTheme then
		return
	end

	--只有第一次才有大奖，后续循环不再获得
	if self._loopCount > 0 then
		self._stepGoalData = {}
		return
	end

	local curTheme = self._selectTheme
	local pageData = self._goalPageList

	local goalData = {}
	for p,q in pairs(pageData.entry) do
		local entryId = q.entryId
		local pageId = q.pageId
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,pageId,entryId)
		if entryCfg then
			local moreInfo = string.split(entryCfg.moreInfo, '|')
			local themeIndex = tonumber(moreInfo[1])
			if themeIndex == curTheme then
				local stepIndex  = tonumber(moreInfo[2])
				local reward = LxDataHelper.ParseItem(entryCfg.reward)
				goalData[stepIndex] = {
					entryId = entryId,
					pageId 	= pageId,
					id 		= entryCfg.id,
					reward 	= reward,
					status  = q.goalData.status,
				}
			end
		end
	end

	self._stepGoalData = goalData
end

--#####################################################################################################################
--## Top ##############################################################################################################
--#####################################################################################################################
function UIActMicBooks:InitTop()
	if not self._config then return end

	self:SetNeedItemNum()
	self:RefreshTitle()
end

function UIActMicBooks:ResetActivePageData(pb)
	for i, v in ipairs(pb.pages) do
		local pageData= gModelActivity:GenerateActivePageDataFromPb(v)
		if pageData then
			local pageId = v.pageId
			if pageId == ModelActivity.ACTIVITY_MAGIC_BOOKS_GOAL then
				--阶段目标
				self._goalPageList = pageData
			else
				--主题
				local themeIndex = pageId - 1
				self._themePageList[themeIndex] = pageData
			end
		end
	end
end

--#####################################################################################################################
--## DrawView #########################################################################################################
--#####################################################################################################################
function UIActMicBooks:InitParaCallDrawView()

    self:SetWndText(self.mShowToggleXUIText, ccClientText(38204))

	--是否跳过抽奖动画，直接显示奖励
	self._isJumpTurnAnim = toboolean(LPlayerPrefs.magicBooksJumpTurnTable)
	self:SetWndToggleValue(self.mShowToggle, self._isJumpTurnAnim)
end

function UIActMicBooks:ShowBoxDetail()
	local showBoxDetailIndex = self._showBoxDetailIndex
	local curTrans = self._extraItemList[showBoxDetailIndex]
	if curTrans then
		CS.ShowObject(curTrans, true)
		self:TweenSeq_FadeInStaysAway(self._extraItemCanvasGroupTweenKey, curTrans,
				{
					waitTime = 3.5,
					showTime = 0.5,
					noShowTime = 0.5,
					openInteractable = true,
					completeFunc = function() CS.ShowObject(curTrans, false) end,
				}
		)
	end

	local nextIndex = showBoxDetailIndex + 1
	local maxNum = #self._extraItemList
	if nextIndex > maxNum then
		nextIndex = 1
	end

	self._showBoxDetailIndex = nextIndex
end

function UIActMicBooks:RefreshDisplayItemShow()
	local itemList = self:GetCurDisplayItemList()

	for i = 1, self._itemMaxNum do
		local index = self._itemDataIndex + i
		local itemDisplayRoot = self:FindWndTrans(self.mDisplayItem, self._displayItemPath..i)
		local itemData = itemList[index]

		local isShow = not table.isempty(itemData)
		CS.ShowObject(itemDisplayRoot, isShow)
		if isShow then
			self:OnDrawItem(itemDisplayRoot, itemData[1], i)
		end
	end

	local maxDataNum = #itemList
	local isShowChange = maxDataNum > self._itemMaxNum
	self._isShowChangeAni = isShowChange
	if not isShowChange then
		return
	end

	local newItemDataIndex = self._itemDataIndex + self._itemMaxNum
	if newItemDataIndex >= maxDataNum then
		newItemDataIndex = 0
	end
	self._itemDataIndex = newItemDataIndex
end

function UIActMicBooks:OnBotList(list, item, itemdata, itempos)
	local nameTxt = self:FindWndTrans(item, "NameTxt")
	self._btnList = self._btnList and self._btnList or {}
	self._btnList[itempos] = { itemData = itemdata, obj = item }
	local itemDataArr = string.split(itemdata,"=")
	local iconName = itemDataArr[2]
	-- self:SetBtnRP(rpTrans, itemdata, itempos)
	self:SetWndText(nameTxt, iconName)
	local addSize = -2
	if gLGameLanguage:IsForeignVersion() then
		addSize = -4
	end
	self:InitTextSizeWithLanguage(nameTxt, addSize)
	self:InitTextLineWithLanguage(nameTxt, -30)
	self:SetWndClick(item, function()
		self:OnClickBotBtn(itempos,true)
	end)
end

function UIActMicBooks:InitItemList(root,itemList)
	local instanceId = root:GetInstanceID()
	local uiList = self._uiListTbl[instanceId]
	if not uiList then
		uiList = UIIconEasyList:New()
		self._uiListTbl[instanceId] = uiList
		uiList:Create(self, root)
		uiList:SetShowNum(false)
		uiList:SetIconParentPath("CommonUI/Icon")
		uiList:SetShowExtraNum(true, "ItemNum")
	end
	uiList:RefreshList(itemList)
	uiList:EnableScroll(#itemList > 3,true)
end


function UIActMicBooks:OnClickLogBtn()
	if not self._sid then return end
	GF.OpenWnd("UIYellLog",{sid = self._sid,callType = 3, titleStr = ccClientText(38201)})
end

function UIActMicBooks:SetNeedItemNum()
	local config = self._config
	local showItemList = {}
	local showItem = string.split(config.mainItem1,";")
	for i,v in ipairs(showItem) do
		local refId = v
		table.insert(showItemList,{
			refId = tonumber(refId)
		})
	end
	self:InitNeedList(showItemList)
end

function UIActMicBooks:OnActivityPageResp(pb, ret)
	local sid = pb.sid
	if self._sid ~= sid then
		return
	end

	self:ResetActivePageData(pb)
	self:ResetThemePageData()
	self:ResetGoalPageData()
	self:RefreshView()
end

function UIActMicBooks:OnDrawAnimEnd()
	self:TimerStop(self._delayShowRewardTimerKey)

	self:OpenUIAward()
end


function UIActMicBooks:OnTimer(key)
	if key == self._heroDisplayChangeTimerKey then
		self:TimerStop(self._heroDisplayChangeTimerKey)
		self:CreateShowHeroLiHui(0)
	elseif key == self._showExtraRewardTimer then
		self:ShowBoxDetail()
	elseif key == self._delayShowRewardTimerKey then
		self:OnDrawAnimEnd()
	elseif key == self._delayShowRootTimerKey then
		CS.ShowObject(self.mBotView, true)
		CS.ShowObject(self.mCanvasRoot, true)
	end
end

function UIActMicBooks:CheckCanOpenNextRound()
	if not self._isLoop then
		return false
	end

	local curTheme = self._selectTheme
	local data = self._themeCfgList[curTheme]
	local loopLimit = data.loopLimit
	return self._loopCount < (loopLimit - 1)
end

--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UIActMicBooks:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:InitData()

	if self._isSelectTheme then
		gModelActivity:OnActivityPageReq(self._sid)
	else
		self:OpenWndThemePop()
	end
end

function UIActMicBooks:RefreshCallBtn()
	if not self._stepDataList then return end
	local curStep = self._curStep
	local stepDataList = self._stepDataList[curStep]
	if not stepDataList then return end

	local stepRollNum = stepDataList.stepRollNum

	local callStr = string.replace(ccClientText(38205), stepRollNum)
	self:SetWndButtonText(self.mCallBtn, callStr)

	local stepItemDiscount = stepDataList.stepItemDiscount
	local isShowDiscount = not string.isempty(stepItemDiscount)
	CS.ShowObject(self.mDiscountBg, isShowDiscount)
	if isShowDiscount then
		self:SetWndText(self.mDiscountText, stepItemDiscount)
	end

	local stepItemNum = stepDataList.stepItemNum
	local itemData = LxDataHelper.ParseItem_4(stepItemNum)
	local itemId = itemData.itemId
	local itemNum = itemData.itemNum
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(self.mPayIcon, icon)
	self:SetWndText(self.mPayNum, itemNum)
	CS.ShowObject(self.mPayDiv, true)

	CS.ShowObject(self.mCallRedPoint, gModelGeneral:CheckItemEnough(itemId,itemNum))
end

function UIActMicBooks:OnClickHelp()
	local cfg = self._config
	if not cfg then return end
	local helpTips = cfg.helpTips
	local title	  = gModelActivity:GetLngNameByActivitySid(self._sid)
	local str = string.gsub(helpTips,'\\n','\n')

	GF.OpenWndUp("UIBzTips",{title =title, text = str})
end

function UIActMicBooks:OnDrawStep(list, item, itemdata, itempos)
	local bg = self:FindWndTrans(item, "Bg")
	local line = self:FindWndTrans(item, "Line")
	local text = self:FindWndTrans(item, "Text")
	local itemRoot = self:FindWndTrans(item, "Item")
	local boxDetail = self:FindWndTrans(item, "BoxDetail")

	local instanceID = item:GetInstanceID()
	local curStep = self._curStep
	local stepGoalData = self._stepGoalData[itempos]
	local haveStepGoalItem = stepGoalData ~= nil

	local isShowLine = itempos < self._stepMaxNum
	CS.ShowObject(line, isShowLine)
	if isShowLine then
		local progressLine = self:FindWndTrans(line, "ProgressLine")
		local curVal, maxValue = self:GetStepProgress(itempos)
		LxUiHelper.SetProgress(progressLine,curVal/maxValue)
	end

	local isShowBg = not haveStepGoalItem
	CS.ShowObject(bg, isShowBg)
	if isShowBg then
		local curIcon = self:FindWndTrans(bg, "CurIcon")
		local overIcon = self:FindWndTrans(bg, "OverIcon")
		CS.ShowObject(curIcon, curStep == itempos)
		CS.ShowObject(overIcon, curStep > itempos)
	end

	if haveStepGoalItem then
		local bigItemBg = self:FindWndTrans(itemRoot, "BigItemBg")
		local itemGetEff = self:FindWndTrans(itemRoot, "ItemGetEff")
		local itemIcon  = self:FindWndTrans(itemRoot, "ItemRoot/CommonUI/Icon")
		local redPoint = self:FindWndTrans(itemRoot, "RedPoint")
		local itemNum = self:FindWndTrans(itemRoot, "ItemNum")
		local isGetIcon = self:FindWndTrans(itemRoot, "IsGetIcon")

		local pageId = stepGoalData.pageId
		local entryId = stepGoalData.entryId
		local goalStatus = stepGoalData.status
		local reward = stepGoalData.reward[1]
		local itemCfg = gModelItem:GetRefByRefId(reward.itemId)
		local itemIconPath = itemCfg.icon
		local canGet = goalStatus == 1
		CS.ShowObject(bigItemBg, goalStatus == 0)
		CS.ShowObject(itemGetEff, canGet)
		CS.ShowObject(redPoint, canGet)
		self:SetWndEasyImage(itemIcon, itemIconPath)
		self:SetWndText(itemNum, reward.itemNum)
		CS.ShowObject(isGetIcon, goalStatus == 2)
		self:SetWndClick(itemRoot, function()
			if canGet then
				gModelActivity:OnActivityReceiveGoalReq(self._sid, pageId, entryId)
			else
				gModelGeneral:ShowCommonItemTipWnd(reward)
			end
		end)

		if canGet then
			local effKey = self._itemGetEffName..instanceID
			self:CreateWndEffect(itemGetEff, self._itemGetEffName, effKey, 100,false, false)
		end
	end
	CS.ShowObject(itemRoot, haveStepGoalItem)

	local stepText = itemdata.stepText
	local isShow = not string.isempty(stepText)
	if isShow then
		self:SetWndText(text, stepText)
	end
	CS.ShowObject(text, isShow)

	CS.ShowObject(boxDetail, false)
	local extraItemReward = self:GetCurExtraItemListByStep(itempos)
	isShow = not table.isempty(extraItemReward)
	if isShow then
		local boxDetailItemList = self:FindWndTrans(boxDetail, "AniRoot/BoxDetailItemList")
		local extraSpineRoot 	= self:FindWndTrans(boxDetail, "Text/ExtraSpine")
		table.insert(self._extraItemList, boxDetail)
		self:InitItemList(boxDetailItemList,extraItemReward)
		local extraItemNum = #extraItemReward
		if extraItemNum > 1 then
			local extraAniRoot = self:FindWndTrans(boxDetail, "AniRoot")
			local posX
			if itempos == 1 then
				posX = 22 * (extraItemNum - 1)
			elseif itempos == self._stepMaxNum then
				posX = -22 * (extraItemNum - 1)
			end

			if posX then
				self:SetAnchorPos(extraAniRoot, Vector2.New(posX,0))
			end
		end

		self:CreateWndSpine(extraSpineRoot, self._extraRewardSpineName, self._extraRewardSpineName..instanceID)
	end

	if itempos == self._stepMaxNum then
		self:TimerStop(self._showExtraRewardTimer)
		if #self._extraItemList > 1 then
			self:TimerStart(self._showExtraRewardTimer, 5, false, -1)
		end
		self:ShowBoxDetail()
	end
end

--设置选中底部按钮状态
function UIActMicBooks:SetSeleBtn()
	if (not self._btnList or #self._btnList == 0) then
		return
	end
	for i, v in ipairs(self._btnList) do
		local seleBg = self:FindWndTrans(v.obj, "SelBg")
		local icon = self:FindWndTrans(v.obj, "Icon")
		local redPoint = self:FindWndTrans(v.obj,"redPoint")
		local itemDataArr = string.split(v.itemData,"=")
		local seleIconPath = itemDataArr[3]
		local noSeleIcon = itemDataArr[4]
		self:SetWndEasyImage(icon, seleIconPath)
		local pId = self._pageId
		local iconPath = i == pId and seleIconPath or noSeleIcon
		self:SetWndEasyImage(icon, iconPath)
		CS.ShowObject(seleBg, i == pId)
		--local showRP = self:CheckRPByIndex(i)
		--CS.ShowObject(redPoint, showRP)
	end
end

function UIActMicBooks:PlayTurnTableAnimation()
	if self._isJumpTurnAnim or GF.FindFirstWndByName("UIOrdinYellAward") then
		self:OpenUIAward()
	else
		--播放动画
		self:SetNeedItemNum()
		LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_CALL_HEART)
		self:PlayDrawAnim()
	end
end

function UIActMicBooks:InitNeedList(list)
	list = list or {}
	local uiNeedList = self._uiNeedList
	if uiNeedList then
		uiNeedList:RefreshData(list)
	else
		uiNeedList = self:GetUIScroll("uiNeedList")
		self._uiNeedList = uiNeedList
		uiNeedList:Create(self.mNeedItemList,list,function(...) self:OnDrawNeedItemCell(...) end)
	end
end



function UIActMicBooks:InitStaticContent()
	self:SetWndText(self.mLogBtnName, ccClientText(38200))
	self:SetWndText(self.mProbBtnName, ccClientText(38202))
end

function UIActMicBooks:OnClickProbBtn()
	local page = self._selectTheme + 1
	GF.OpenWnd("UIActMicBooksRatePop",{sid = self._sid, page = page})
end

function UIActMicBooks:RefreshResetBtn()
	local cfg = self._config
	if not cfg then return end

	local isShow = self:CheckCanResetTheme()
	CS.ShowObject(self.mResetBtn, isShow)
	if not isShow then
		return
	end

	self:SetWndText(self.mResetBtnName, ccClientText(38203))
end

function UIActMicBooks:GetCurExtraItemListByStep(curStep)
	local curLevelData = self._themeDataList[curStep]
	local extraReward = curLevelData.extraReward
	if not extraReward then
		return nil
	end

	return extraReward
end

function UIActMicBooks:PlayBgShowDrawSpine()
	if self._bgShowSpine then
		self._bgShowSpine:PlayAnimation(0,self._bgSpineAnimEnum.DRAW,false)
	end
end

function UIActMicBooks:PlayDrawSpine()
	if not self._drawSpine then
		self._drawSpine = self:CreateWndSpine(self.mDrawSpine, self._bgDrawSpineName, self._bgDrawSpineName,false,function (spine)
		end)
	else
		self._drawSpine:PlayAnimation(0,self._drawSpineAnimEnum.DRAW,false)
	end
end

function UIActMicBooks:RefreshView()
	self:RefreshResetBtn()

	if not self._isSelectTheme then return end
	self:RefreshDisplayType()
	self:RefreshStepRoot()
	self:RefreshStepDescContent()
	self:RefreshCallRoot()
end

function UIActMicBooks:OnDrawItem(item,itemdata,itempos)
	local bg 		= self:FindWndTrans(item, "Bg")
	local iconRoot = self:FindWndTrans(item, "Icon")
	local itemNum = self:FindWndTrans(item, "ItemNum")

	local instanceID = item:GetInstanceID()
	local itemCfg = gModelItem:GetRefByRefId(itemdata.itemId)
	local itemIconPath = itemCfg.icon
	self:SetWndEasyImage(iconRoot, itemIconPath)

	self:SetWndText(itemNum,itemdata.itemNum)

	self:SetWndClick(item, function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)

	local effKey = self._itemEffName..instanceID
	self:CreateWndEffect(bg, self._itemEffName, effKey, 100,false, false)
end

function UIActMicBooks:CheckCanCall()
	local curStep = self._curStep
	local data = self._stepDataList[curStep]
	if not data then
		LogError("self._stepDataList[curStep] is nil, stepIndex = "..(curStep or "nil"))
		return false
	end

	local stepLimitNum = data.stepLimitNum
	if stepLimitNum < 0 then
		return true
	end

	return self._extractCount < stepLimitNum
end

function UIActMicBooks:GetStepProgress(stepIndex)
	local curStep = self._curStep
	if curStep > stepIndex then
		return 1,1
	elseif curStep < stepIndex then
		return 0,1
	end

	local data = self._stepDataList[curStep]
	if not data then
		LogError("self._stepDataList[curStep] is nil, stepIndex = "..(curStep or "nil"))
		return 0,1
	end

	local stepRewardNum = data.stepRewardNum

	return self._extractCount, stepRewardNum
end

-- 打开奖励弹窗
function UIActMicBooks:OpenUIAward()
	local data = self._actDropGiftData
	if not data then return end

	local botTipsTxtStr
	local fixedData = data.fixedData
	if fixedData then
		local fixName,fixNum = gModelItem:GetNameByRefId(tonumber(fixedData.refId)),tonumber(fixedData.num)
		botTipsTxtStr = string.replace(ccClientText(11619),fixName,fixNum)
	end

	GF.OpenWndTop("UIOrdinYellAward2",{
		itemList = data.itemList,
		botTipsTxtStr = botTipsTxtStr,
		bgPath = "activity_stack_bg_big_1",
	})
	self._actDropGiftData = nil
end
--#####################################################################################################################
--## StepRoot #########################################################################################################
--#####################################################################################################################
function UIActMicBooks:InitParaStepRoot()
	if not self._config then return end
	local config = self._config

	local themeSelectTitle 		= string.split(config.themeSelectTitle, '|')
	local themeSelectTitlePos 	= string.split(config.themeSelectTitlePos, '|')

	local isLoop = config.isLoop or 0
	self._isLoop = isLoop == 1

	local themeList = {}
	for i = 1, self._themeMaxNum do
		local data = {}
		local cfgIndex = i + 1

		local stepLimitNum		= config["stepLimitNum"..cfgIndex]
		if not string.isempty(stepLimitNum) then
			data.stepLimitNum = string.split(stepLimitNum, '|')
		end

		local stepRewardNum		= config["stepRewardNum"..cfgIndex]
		if not string.isempty(stepRewardNum) then
			data.stepRewardNum = string.split(stepRewardNum, '|')
		end

		local stepRollNum		= config["stepRollNum"..cfgIndex]
		local stepNum			= 0
		if not string.isempty(stepRollNum) then
			local stepRollNumList 	= string.split(stepRollNum, '|')
			data.stepRollNum 		= stepRollNumList
			stepNum					= #stepRollNumList
			data.stepNum 			= stepNum
		end

		local stepItemNum		= config["stepItemNum"..cfgIndex]
		if not string.isempty(stepItemNum) then
			data.stepItemNum = string.split(stepItemNum, '|')
		end

		local stepItemDiscount	= config["stepItemDiscount"..cfgIndex]
		if not string.isempty(stepItemDiscount) then
			data.stepItemDiscount = string.split(stepItemDiscount, '|')
		end

		local stepText	= config["stepText"..cfgIndex]
		if not string.isempty(stepText) then
			data.stepText = string.split(stepText, '|')
		end

		local stepRateShow	= config["stepRateShow"..cfgIndex]
		if not string.isempty(stepRateShow) then
			data.stepRateShow = string.split(stepRateShow, '|')
		end

		if self._isLoop then
			local loopLimit = config["loopLimit"..cfgIndex] or 0
			data.loopLimit = loopLimit
		end

		data.themeSelectTitle = themeSelectTitle[i]
		data.themeSelectTitlePos = themeSelectTitlePos[i]

		themeList[i] = data
	end
	self._themeCfgList = themeList
end
--#####################################################################################################################
--## DisplayHero ######################################################################################################
--#####################################################################################################################
function UIActMicBooks:StartDisplayHeroSpine()
	local itemList = self:GetCurDisplayItemList()
	local showIndex = 1
	self._curShowHeroIndex = showIndex
	local curHeroData = itemList[showIndex]
	if not curHeroData then return end

	local heroId = curHeroData[1].itemId
	self:CreateShowHeroLiHui(heroId)
end

function UIActMicBooks:RefreshDisplayType()
	if not self._isSelectTheme then return end
	local curTheme = self._selectTheme

	local displayType = self._themeType[curTheme]
	self._displayType =displayType

	CS.ShowObject(self.mDisplayItem, displayType == UIActMicBooks.DISPLAY_ITEM)
	CS.ShowObject(self.mDisplayHero, displayType == UIActMicBooks.DISPLAY_HERO)
	if displayType == UIActMicBooks.DISPLAY_ITEM then
		self:StartDisplayItem()
	else
		self:StartDisplayHeroSpine()
	end
end

function UIActMicBooks:OnActivityListResp(pb)
	local activities = pb.activities
	for i, v in ipairs(activities) do
		local sid = v.sid
		if self._sid == sid then
			self:InitData()
			if self._isSelectTheme then
				gModelActivity:OnActivityPageReq(self._sid)
			end
			break
		end
	end
end

function UIActMicBooks:CreateTimer(key,time,loopCnt)
	time = time or 1
	loopCnt = loopCnt or -1
	self:TimerStop(key)
	self:TimerStart(key,time,false,loopCnt)
end


--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################
function UIActMicBooks:InitData()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then return end

	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	self._activityData = activityData
	local activityMoreInfo = JSON.decode(activityData.moreInfo)

	self._selectTheme = 0
	local selectTheme = activityMoreInfo.selectTheme  or 0 --当前所选主题,默认0=未选择, 主题1 = 2
	if selectTheme > 0 then
		self._selectTheme = selectTheme - 1
	end

	self._themeCount  = activityMoreInfo.themeCount or 0 --主题选择次数，默认0次
	self._isSelectTheme = self._selectTheme > 0

	local config 	= webData.config
	self._config 	= config


	self._themeType = string.split(config.themeType, '|')
	self._themeMaxNum = #self._themeType

	self:InitParaStepRoot()
	self:InitTop()
	self:InitCallRoot()
	self:SetBotList()
	self:ResetStepCfgData()

	if self._isSelectTheme then
		self:PlayBgShowSpine()
	end
end

function UIActMicBooks:RefreshTitle()
	if not self._isSelectTheme then return end

	local curTheme = self._selectTheme
	local data = self._themeCfgList[curTheme]
	local themeSelectTitle = data.themeSelectTitle
	if LxUiHelper.IsImgPathValid(themeSelectTitle) then
		self:SetWndEasyImage(self.mTxtImg, themeSelectTitle, nil , true)
		CS.ShowObject(self.mTxtImg, true)

		local themeSelectTitlePos = data.themeSelectTitlePos
		if not string.isempty(themeSelectTitlePos) then
			self:SetAnchorPos(self.mTxtImg, LxDataHelper.ParseVector2NotEmpty3(themeSelectTitlePos))
		end
	end
end

function UIActMicBooks:CreateShowHeroLiHui(showFirst,changeCallType)
	if self._displayType ~= UIActMicBooks.DISPLAY_HERO then return end
	if showFirst == 0 then
		local itemList = self:GetCurDisplayItemList()
		local newIndex = self._curShowHeroIndex + 1
		if newIndex > #itemList then
			newIndex = 1
		end
		self._curShowHeroIndex = newIndex
		local curHeroData = itemList[newIndex]
		showFirst = curHeroData[1].itemId
	end
	showFirst = showFirst or 0
	if showFirst == 0 then return end

	local showHeroLiHuiList = self._showHeroLiHuiList
	if not showHeroLiHuiList then
		showHeroLiHuiList = {}
		self._showHeroLiHuiList = showHeroLiHuiList
	end

	self.mHeroSpinePos.localPosition = self._lihuiInitPos

	local curLiHuiPos = self.mHeroSpinePos.localPosition
	local curLiHuiPosX = curLiHuiPos.x
	local curLiHuiPosY = curLiHuiPos.y
	local curLiHuiPosZ = curLiHuiPos.z

	local startTimeFunc = function()
		local callHeroShowCd = 3
		self:CreateTimer(self._heroDisplayChangeTimerKey,callHeroShowCd,1)
	end

	local showNewLHFunc = function()
		local showHeroLiHui = showHeroLiHuiList[showFirst]
		if showHeroLiHui then
			showHeroLiHui:SetVisible(true)
		else
			local spine = gModelHero:GetHeroPrefabNameByRefId(showFirst,nil,true)
			if not spine then
				if LOG_INFO_ENABLED then
					printInfoNR("打印而已，莫慌    没有找到对应英雄的立绘，英雄refId = " .. showFirst)
				end
				return
			end
			showHeroLiHui = self:CreateWndSpine(self.mHeroSpinePos,spine,showFirst)
		end
		self._curShowSpine = showHeroLiHui
		self._curShowHero = showFirst
		showHeroLiHuiList[showFirst] = showHeroLiHui
	end

	local vanishTime = 0.5
	local showTime = 0.3
	local moveX = 80

	if self._curShowSpine and self._curShowHero and self._curShowHero ~= showFirst then
		if changeCallType then
			self:TweenSeqKill(self._showAniKey)
			self:SetCanvasGroupAlpha(self.mHeroSpinePos,1)
			self._curShowSpine:SetVisible(false)
			self.mHeroSpinePos.localPosition = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ)
			showNewLHFunc()
			startTimeFunc()
		else
			local transInfoList = {
				{
					trans = self.mHeroSpinePos,
					aniStarPos = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ),
					vanishPos = Vector3(curLiHuiPosX - moveX,curLiHuiPosY,curLiHuiPosZ),
					aniShowPos = Vector3(curLiHuiPosX + moveX,curLiHuiPosY,curLiHuiPosZ),
					showPos = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ),
				}
			}
			local extraData = {
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
					self.mHeroSpinePos.localPosition = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ)
					showNewLHFunc()
					startTimeFunc()
				end
			}
			self:TweenSeq_MoveFadeAni(self._showAniKey,transInfoList,extraData)
		end
	else
		if changeCallType then
			self:TweenSeqKill(self._showAniKey)
			self:SetCanvasGroupAlpha(self.mHeroSpinePos,1)
			self.mHeroSpinePos.localPosition = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ)
			showNewLHFunc()
			startTimeFunc()
		else
			local transInfoList = {
				{
					trans = self.mHeroSpinePos,
					aniStarPos = Vector3(curLiHuiPosX + moveX,curLiHuiPosY,curLiHuiPosZ),
					vanishPos = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ),
				}
			}
			local extraData = {
				initAlpha = 0,
				fromAlpha = 0,
				toAlpha = 1,
				vanishTime = vanishTime,
				showTime = showTime,
				startShowFunc = function()
					showNewLHFunc()
				end,
				endFunc = function()
					self.mHeroSpinePos.localPosition = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ)
					startTimeFunc()
				end
			}
			self:TweenSeq_MoveFadeAni(self._showAniKey,transInfoList,extraData)
		end
	end
end

function UIActMicBooks:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:CloseWndFunc() end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mHelpBtn, function() self:OnClickHelp() end, LSoundConst.CLICK_ERROR_COMMON)
	self:SetWndClick(self.mLogBtn, function() self:OnClickLogBtn() end)
	self:SetWndClick(self.mProbBtn, function() self:OnClickProbBtn() end)
	self:SetWndClick(self.mResetBtn, function() self:OnClickResetBtn() end)

	self:SetWndToggleDelegate(self.mShowToggle,function (value)
		LPlayerPrefs.SetMagicBooksJumpTurnTable(tostring(value))
		self._isJumpTurnAnim = value
	end)

	self:SetWndClick(self.mCallBtn, function() self:OnClickCallBtn() end)
	self:SetWndClick(self.mSelectBtn, function() self:OnClickSelectBtn() end)
end

function UIActMicBooks:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (...) self:OnActivityPageResp(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb) self:OnActivityListResp(pb) end)
	self:WndEventRecv(EventNames.On_Item_Change,function() self:SetNeedItemNum() end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_DROP_GIFT,function(data) self:OnActivityDropGift(data) end)
end

function UIActMicBooks:InitParam()
	self._sid = self:GetWndArg("sid")
	if not self._sid then
		local subpage= self:GetWndArg("subPage") --支持跳转
		if subpage then
			self._sid = gModelActivity:GetSidByUniqueJump(subpage)
		end
	end

	local page = self:GetWndArg("page") or 1
	self._pageId = self:GetWndArg("pageId") or page

	self._themePageList = {}
	self._lihuiInitPos = self.mHeroSpinePos.localPosition
	local itemFromPos = self.mDisplayItem.localPosition
	self._itemFromPos = itemFromPos
	self._itemEndPos = itemFromPos + Vector3.New(0, 15, 0)

    self._itemMaxNum = self.mDisplayItem.childCount

	self:InitParaCallDrawView()

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActMicBooks:OnDrawNeedItemCell(list,item,itemdata,itempos)
	local IconTrans = self:FindWndTrans(item,"Icon")
	local NumTrans = self:FindWndTrans(item,"Num")
	local AddBtnTrans = self:FindWndTrans(item,"BtnDiv/AddBtn")
	local refId = itemdata.refId
	if IconTrans then
		local icon = gModelItem:GetItemIconByRefId(refId)
		self:SetWndEasyImage(IconTrans,icon)
	end
	if NumTrans then
		local haveNum = gModelItem:GetNumByRefId(refId)
		self:SetWndText(NumTrans,haveNum)
	end
	if AddBtnTrans then
		self:SetWndClick(AddBtnTrans,function()
			self:AddItemEvent(refId)
		end)
	end

	self:SetWndClick(item,function()
		self:AddItemEvent(refId)
	end)
end

function UIActMicBooks:OnClickCallBtn()
	if not self._stepDataList then return end
	local curStep = self._curStep
	local stepDataList = self._stepDataList[curStep]
	if not stepDataList then return end

	local stepItemNum = stepDataList.stepItemNum
	local itemData = LxDataHelper.ParseItem_4(stepItemNum)
	local itemId = itemData.itemId
	local itemNum = itemData.itemNum
	if not gModelGeneral:CheckItemEnough(itemId,itemNum) then
		gModelGeneral:OpenGetWayWnd({itemId=itemId,srcWnd = self:GetWndName()})
		return
	end

	local isFull = gModelGeneral:IsFullHeroBag(0,nil,nil,nil,nil,self:GetWndName())
	if isFull then return end

	local callFunc = function()
		local args = "2"
		local sid = self._sid
		gModelActivity:OnActivitySpecialOpReq(sid,nil,nil,nil, args, ModelActivity.MAGIC_BOOKS_OPS)
	end

	local itemName = gModelGeneral:GetItemName(itemData.itemType,itemId)

	local stepRollNum = stepDataList.stepRollNum
	local wndPara =
	{
		refId = 110075,
		sid  = self._sid,
		para = {itemNum,itemName, stepRollNum},
		func = callFunc,
		consume={itemNum, itemId}
	}

	gModelGeneral:OpenUIOrdinTips(wndPara)
end

function UIActMicBooks:AddItemEvent(refId)
	gModelGeneral:OpenGetWayWnd({itemId = refId,srcWnd = self:GetWndName()})
end

function UIActMicBooks:OpenWndThemePop()
	GF.OpenWnd("UIActMicBooksHeartPop",{sid = self._sid})
end

--#####################################################################################################################
--## TurnAnimation ####################################################################################################
--#####################################################################################################################
function UIActMicBooks:PlayBgShowSpine()
	self._bgShowSpine = self:CreateWndSpine(self.mBgSpine,self._bgShowSpineName, self._bgShowSpineName,false,function (spine)
		self:OnBgShowSpineLoad(spine)
	end)
end


------------------------------------------------------------------
return UIActMicBooks



