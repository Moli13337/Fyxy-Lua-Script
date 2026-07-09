---
--- Created by Administrator.
--- DateTime: 2025/6/9 15:34:06
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActivity166Main:LWnd
local UIActivity166Main = LxWndClass("UIActivity166Main", LWnd)
------------------------------------------------------------------

local typeOfBoneFollower = typeof(Spine.Unity.BoneFollower)

local callPage = ModelActivity.PAGE_ACTIVITY_166_CALL


local SHOW_ICON = 1
local SHOW_SPINE = 2

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActivity166Main:UIActivity166Main()
	---@type boolean 是否开启轮次开关
	self._showRound = false

	---@type boolean 是否自选大奖
	self._canSelBigRew = false

	self._loadSpineEnd = false

	---@type LDisplaySpine
	self._niudanjiSpine = nil

	---@type LDisplayEffect
	self._niudanKJEff = nil

	---@type table<number,StructActivityPage>
	self._pages = {}

	---@type StructActLotteryInfo
	self._actLotteryInfo = nil

	--- 轮次 cd
	self._roundTimer = "_roundTimer"

	---@type UIObjPool
	self._itemPool = nil

	self._jumpAni = false

	self._actCDTimerKey = "_actCDTimerKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActivity166Main:OnWndClose()
	if self._itemPool then
		self._itemPool:DestroyAllObj()
		self._itemPool = nil
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActivity166Main:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActivity166Main:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	---@type UIObjPool
	local itempool = UIObjPool:New()
	itempool:Create(self.mItemPool,self.mItemTemp)
	self._itemPool = itempool

	self:InitBtnTransInfos()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
end


function UIActivity166Main:GetNeedAddItemList()
	local list = {}
	table.insert(list,{
		itemId = ModelItem.ITEM_DIAMOND,
	})
	local costItem = self._costItem
	if costItem and costItem > 0 then
		table.insert(list,{
			itemId = costItem,
		})
	end
	return list
end

function UIActivity166Main:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	-- self:SetWndClick(self.mXXXBtn,function() self:OnClickXXXBtnFunc() end)
	self:SetWndClick(self.mBtnHelp,function() self:OnClickBtnHelp() end)
	self:SetWndClick(self.mOneCallBtn,function() self:OnClickCallBtn(1) end)
	self:SetWndClick(self.mTenCallBtn,function() self:OnClickCallBtn(10) end)
	self:SetWndClick(self.mBtnRoundOff,function() self:OnClickBtnRoundOff() end)
	self:SetWndClick(self.mBtnBigRewSet,function() self:OnClickBtnBigRewSet() end)
	self:SetWndClick(self.mBtnLog,function() self:OnClickBtnLog() end)
	self:SetWndClick(self.mBtnProb,function() self:OnClickBtnProb() end)
	self:SetWndClick(self.mBtnJumpAni,function() self:OnClickBtnJumpAni() end)
	self:SetWndClick(self.mBtnShop,function() self:OnClickBtnShop() end)
end

function UIActivity166Main:InitNeedAddItemList()
	local list = self:GetNeedAddItemList()
	local uiNeedAddItemList = self._uiNeedAddItemList
	if uiNeedAddItemList then
		uiNeedAddItemList:RefreshList(list)
	else
		uiNeedAddItemList = self:GetUIScroll("uiNeedAddItemList")
		self._uiNeedAddItemList = uiNeedAddItemList
		uiNeedAddItemList:Create(self.mNeedAddItemList,list,function(...) self:OnDrawNeedAddItemCell(...) end)
	end
end

function UIActivity166Main:OnActSelLotteryRoundResp(pb)
	if pb.sid ~= self._sid then return end

	if self._actLotteryInfo then
		self._actLotteryInfo.round = pb.round
		self._actLotteryInfo:SetLotteryData(pb.lotteryData)
	end
	self:RefreshView()
end

function UIActivity166Main:OnClickCallBtn(callNum)
	if not self._loadSpineEnd then return end

	local actLotteryInfo = self._actLotteryInfo
	if not actLotteryInfo then return end

	if not self:IsSelBigReward() then
		GF.ShowMessage(self._textTip)
		return
	end

	local diamondCount = actLotteryInfo.diamondCount
	local hasDiamond = diamondCount >= callNum
	--- 1钻石,2道具,3免费
	local lotteryType
	if callNum == 1 then
		if actLotteryInfo:CheckHasFree() then
			lotteryType = 3
		else
			lotteryType = self:GetLotteryType(self._costOne2,self._costOne1,hasDiamond)
		end
	else
		lotteryType = self:GetLotteryType(self._costTen2,self._costTen1,hasDiamond)
	end
	if not lotteryType or lotteryType < 1 then return end

	self._callNum = callNum
	gModelActivity:OnActLotteryReq(self._sid,callPage,actLotteryInfo.round,callNum,lotteryType)
end

function UIActivity166Main:OnClickBtnRoundOff()
	local nextInfo = self._nextInfo
	if nextInfo and not self:CheckIsRoundOpen(nextInfo) then
		local timeSpan = nextInfo.openTime - GetTimestamp()
		local timerStr = string.replace(self._roundTimeTxt,LUtil.FormatTimespanCn(timeSpan,{
			hTextId = 10371
		}))
		GF.ShowMessage(timerStr)
		return
	end

	local round = self:GetCurLotteryRound()
	if not round then return end

	gModelActivity:OnActSelLotteryRoundReq(self._sid,callPage,round + 1)
end

function UIActivity166Main:OnActSelLotteryGuaranteeResp(pb)
	local sid = pb.sid
	if sid ~= self._sid then return end

	if self._actLotteryInfo then
		self._actLotteryInfo:SetLotteryData(pb.lotteryData)
	end
	self._actSelLotteryGuarantee = true

	self:RefreshItemPool()
	--gModelActivity:OnActLotteryInfoReq(sid,callPage)
end

function UIActivity166Main:OnTimer(key)
	if key == self._actCDTimerKey then
		self:SetCDTimer(key)
	end
end

function UIActivity166Main:OnClickBtnBigRewSet()
	local lotteryData = self:GetCurLotteryData()
	if not lotteryData then return end

	local bigRewardMap = self._bigRewardMap
	if not bigRewardMap then return end

	local round = lotteryData.round
	local selRewardList = bigRewardMap[round]
	if not selRewardList or #selRewardList < 1 then return end

	GF.OpenWnd("UIActivity166RewSel",{
		sid = self._sid,
		round = round,
		guaranteeId = lotteryData.guaranteeId,
		selRewardList = selRewardList,
	})
end

function UIActivity166Main:ShowRewardFunc()
	local rewardFunc = self._rewardFunc
	self._rewardFunc = nil
	if rewardFunc then
		rewardFunc()
	end
end

---@param payItem1 table 道具消耗
---@param payItem2 table 钻石消耗
---@param hasDiamondCnt boolean 是否有钻石次数
function UIActivity166Main:GetUseShowPay(payItem1,payItem2,hasDiamondCnt)
	local usePay = payItem1
	if not gModelGeneral:CheckItemEnough(payItem1.itemId,payItem1.itemNum) then
		--- 道具不足，只要还有钻石抽取次数，都需要显示钻石消耗，点击抽奖也是弹出钻石数量不足
		---	gModelGeneral:CheckItemEnough(payItem2.itemId,payItem2.itemNum)
		if hasDiamondCnt then
			usePay = payItem2
		end
	end
	return usePay
end

function UIActivity166Main:SetCallBtn(btnTrans,data)
	self:SetWndText(btnTrans.BtnName,data.btnName or "")

	local showPay = false
	local isFree = data.isFree
	if not isFree then
		local payData = data.payData
		if payData then
			showPay = true
			local itemId = payData.itemId
			local iconPath = gModelItem:GetItemIconByRefId(itemId)
			local IconImg = btnTrans.IconImg
			self:SetWndEasyImage(IconImg,iconPath,function()
				CS.ShowObject(IconImg,true)
			end)

			local itemNum = payData.itemNum
			local hasNum = gModelItem:GetNumByRefId(itemId)
			local color
			if hasNum < itemNum then
				color = "#c81212"
			end
			local numStr = LUtil.FormatColorStr(tostring(itemNum),color)
			self:SetWndText(btnTrans.NumTxt,numStr)
		end
	end
	CS.ShowObject(btnTrans.PayDiv,showPay)
end



function UIActivity166Main:OnTimer(key)
	if key == self._roundTimer then
		self:OnRoundTimer()
	end
end

function UIActivity166Main:GetCurLotteryRound()
	local actLotteryInfo = self._actLotteryInfo
	if not actLotteryInfo then return end

	return actLotteryInfo.round
end

function UIActivity166Main:RefreshJumpAniStatus()
	CS.ShowObject(self.mJumpAniBgGou,self._jumpAni)
end

function UIActivity166Main:OnClickBtnProb()
	local sid = self._sid

	local actWebData = gModelActivity:GetWebActivityDataById(sid)
	if not actWebData then return end

	local config = actWebData.config

	local btnList = {}
	local btnIcon = string.split(config.btnIcon,"=")
	for i,v in ipairs(btnIcon) do
		table.insert(btnList,{
			btnType = i,
			btnName = v,
		})
	end

	local explainList = {}
	local callHelpTitle = string.split(config.callHelpTitle,"|")
	for i,v in ipairs(callHelpTitle) do
		table.insert(explainList,v)
	end

	GF.OpenWnd("UIActivity166CallRule",{
		title = config.binWeightShow,
		policyTxt = config.policyTxt,
		showExplainStatus = 1,
		explainTxt = config.callHelpTitleTxt,
		explainList = explainList,
		btnList = btnList,
		ruleMap = self._roundIdDataMap,
	})
end

function UIActivity166Main:DisposePageData(sid,pb)
	local pages = self._pages
	if not pages then
		pages = {}
		self._pages = pages
	end
	for i, v in ipairs(pb.pages) do
		---@type StructActivityPage
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		pages[page.pageId] = page
	end

	local bigRewardMap = {}
	local entryDataMap = {}
	local roundDataMap = {}
	local roundIdDataMap = {}
	local entry2QualityMap = {}
	local bigIdxMap = {}
	---@type StructActivityPage
	local callPageData = pages[callPage]
	if callPageData then
		---@type StructActivityEntry[]
		local entry = callPageData.entry
		for i,v in ipairs(entry) do
			local entryId = v.entryId
			local entryCfg = gModelActivity:GetWebActivityEntryData(sid,v.pageId,entryId)
			if entryCfg then
				local moreInfo = string.split(entryCfg.moreInfo,"=")
				local round = checknumber(moreInfo[1])
				local isBig = checknumber(moreInfo[2]) == 1
				local index = checknumber(moreInfo[3])
				local picPath = moreInfo[4]
				local scale = checknumber(moreInfo[6]) or 1
				if scale == 0 then
					scale = 1
				end
				if picPath == "0" then
					picPath = ""
				end
				local name = ""
				local item = v.items[1]
				if item then
					--- 坐标下标
					if index > 0 then
						local roundData = roundDataMap[round]
						if not roundData then
							roundData = {}
							roundDataMap[round] = roundData
						end
						local showType = SHOW_ICON
						local path
						local type = item.type
						if type == LItemTypeConst.TYPE_HERO then
							path = gModelHero:GetHeroEffectPrefab(item.itemId)
							showType = SHOW_SPINE
						else
							path = gModelGeneral:GetCommonItemImgRef(item)
						end
						local indexRoundData = roundData[index]
						if not indexRoundData then
							indexRoundData = {}
							roundData[index] = indexRoundData
						end
						table.insert(indexRoundData,{
							showItem = item,
							showType = showType,
							showPath = path,
							bgPath = picPath,
							showNum = item.itemNum,
							scale = scale,
							entryId = entryId,
						})
					end

					if isBig then
						bigIdxMap[round] = index
						local bigRewards = bigRewardMap[round]
						if not bigRewards then
							bigRewards = {}
							bigRewardMap[round] = bigRewards
						end
						table.insert(bigRewards,{
							data = item,
							guaranteeId = entryId,
							round = round,
						})
					end

					name = gModelGeneral:GetCommonItemName(item)

					entry2QualityMap[entryId] = gModelGeneral:GetCommonItemQualityRef(item)
				end

				local roundIdDatas = roundIdDataMap[round]
				if not roundIdDatas then
					roundIdDatas = {}
					roundIdDataMap[round] = roundIdDatas
				end
				local roundIdData = {
					round = round,
					isBig = isBig,
					index = index,
					picPath = picPath,
					probability = moreInfo[5],
					scale = scale,
					entryId = entryId,
					name = name,
					item = item,
				}
				table.insert(roundIdDatas,roundIdData)
				entryDataMap[entryId] = roundIdData
			end
		end
	end
	self._bigIdxMap = bigIdxMap
	self._roundDataMap = roundDataMap
	self._entryDataMap = entryDataMap
	self._bigRewardMap = bigRewardMap
	self._roundIdDataMap = roundIdDataMap
	self._entry2QualityMap = entry2QualityMap

	self:RefreshItemPool()
end

function UIActivity166Main:RefreshCallBtns()
	local btnTransInfos = self._btnTransInfos

	local oneCallBtnInfo = btnTransInfos[1]
	local tenCallBtnInfo = btnTransInfos[2]

	local actLotteryInfo = self._actLotteryInfo
	local isFree = actLotteryInfo and actLotteryInfo:CheckHasFree() or false

	local callBtnTxtInfo = self._callBtnTxtInfo

	local diamondCount = actLotteryInfo and actLotteryInfo.diamondCount or 0

	local useCost1 = self:GetUseShowPay(self._costOne2,self._costOne1,diamondCount >= 1)
	self:SetCallBtn(oneCallBtnInfo,{
		isFree = isFree,
		btnName = isFree and callBtnTxtInfo[1] or callBtnTxtInfo[2],
		payData = useCost1,
	})


	local useCost10 = self:GetUseShowPay(self._costTen2,self._costTen1,diamondCount >= 10)
	self:SetCallBtn(tenCallBtnInfo,{
		isFree = false,
		btnName = callBtnTxtInfo[3],
		payData = useCost10,
	})

end

function UIActivity166Main:RefreshItemPool()
	local roundDataMap = self._roundDataMap
	if not roundDataMap then return end

	local curRound = self:GetCurLotteryRound()

	local isRet = false
	if self._actSelLotteryGuarantee then
	elseif self._targetRound and self._targetRound == curRound then
		isRet = true
	end
	if isRet then return end

	self._actSelLotteryGuarantee = false

	self._targetRound = curRound

	---@type table<string,LDisplaySpine>
	local showSpineKeyMap = self._showSpineKeyMap
	if not showSpineKeyMap then
		showSpineKeyMap = {}
		self._showSpineKeyMap = showSpineKeyMap
	end
	for k,v in pairs(showSpineKeyMap) do
		self:DestroyWndSpineByKey(k)
	end

	local itemPool = self._itemPool
	itemPool:ReturnAllObj()

	local spine = self._niudanjiSpine
	local spienTrans = self.mItemPool
	local skeletonAni = spine:GetSkeletonAnimation()

	local lotteryData = self:GetCurLotteryData()
	local isSelBig = lotteryData and lotteryData:CheckIsSelGuaranteeId() or false
	local guaranteeId = lotteryData and lotteryData.guaranteeId or 0

	local bigIdxMap = self._bigIdxMap or {}
	for round,roundData in pairs(roundDataMap) do
		if curRound == round then
			local bigIdx = bigIdxMap[round] or -1
			for index,indexRoundData in pairs(roundData) do
				if #indexRoundData > 0 then
					local isFirstIdx = false
					if bigIdx and bigIdx > 0 then
						isFirstIdx = index == bigIdx
					end
					local data = indexRoundData[1]
					if isFirstIdx then
						for idx,val in ipairs(indexRoundData) do
							if val.entryId == guaranteeId then
								data = val
								break
							end
						end
					end

					local obj = itemPool:GetObj()
					CS.ShowObject(obj,false)

					local trans = obj.transform
					trans:SetParent(spienTrans, false)
					trans.name = "dan_" .. tostring(index)

					--local IconBg = self:FindWndTrans(trans,"IconBg")
					local Icon = self:FindWndTrans(trans,"Icon")
					local spineRoot = self:FindWndTrans(trans,"spineRoot")
					local showType = data.showType
					local showIcon = showType == SHOW_ICON
					local scale = data.scale
					local isNotSelBig = isFirstIdx and not isSelBig
					if isNotSelBig then
						showIcon = true
					end
					if showIcon then
						--self:SetWndEasyImage(IconBg,data.bgPath,function()
						--	CS.ShowObject(IconBg,true)
						--end)

						local showPath = data.showPath
						if isNotSelBig then
							showPath = "activity_166_ui_1"
						end
						self:SetWndEasyImage(Icon,showPath,function()
							Icon.localScale = Vector3(scale, scale, scale)
							CS.ShowObject(Icon,true)
						end,true)
					else
						local showPath = data.showPath
						local spineKey = showPath .. "_" .. tostring(index)
						---@param dpSpine LDisplaySpine
						local showSpine = self:CreateWndSpine(spineRoot,showPath,spineKey,nil,function(dpSpine)
							dpSpine:Freeze(true)
							dpSpine:SetScale(scale)
							CS.ShowObject(spineRoot,true)
						end)
						showSpineKeyMap[spineKey] = showSpine
					end

					if skeletonAni then
						local boneFollower = trans:GetComponent(typeOfBoneFollower)
						if not boneFollower then
							boneFollower = trans.gameObject:AddComponent(typeOfBoneFollower)
						end
						boneFollower.SkeletonRenderer = skeletonAni
						boneFollower:SetBone("dan_" .. tostring(index))
						CS.ShowObject(obj,true)
					end
				end
			end
		end
	end
end

function UIActivity166Main:OnClickBtnHelp()
	GF.OpenWnd("UIBzTips", { title = self._callHelpTitleTxt, text = self._callHelpTitle })
end

function UIActivity166Main:CheckIsRoundOpen(nextInfo)
	if not nextInfo then return true end

	return GetTimestamp() >= nextInfo.openTime
end

function UIActivity166Main:SetCDTimer(key)
	key = key or self._actCDTimerKey
	local endTime = self._endTime
	if not endTime or endTime < 0 then
		self:TimerStop(key)
		CS.ShowObject(self.mImgTime,false)
		return
	end

	local timeStr = ""
	local curTime = GetTimestamp()
	local timeSpan = endTime - curTime
	if timeSpan > 0 then
		timeStr = LUtil.FormatTimespanCn(timeSpan,{hTextId = 10371})
		timeStr = string.replace(ccClientText(11637),timeStr)
	else
		self:TimerStop(key)
		timeStr = ccClientText(14301)
	end
	self:SetWndText(self.mTxtTime,timeStr)
	CS.ShowObject(self.mImgTime,true)
end

function UIActivity166Main:OnClickBtnShop()
	GF.OpenWndBottom("UIDian",{page = ModelShop.ACTIVITY,subPage = self._sid})
end

function UIActivity166Main:SetContent()
	local sid = self._sid
	local actData = gModelActivity:GetActivityBySid(sid)
	if not actData then return end

	local actWebData = gModelActivity:GetWebActivityDataById(sid)
	if not actWebData then return end


	self._endTime = checknumber(actData.endTime)

	local timerKey = self._actCDTimerKey
	self:SetCDTimer(timerKey)
	self:TimerStop(timerKey)
	self:TimerStart(timerKey,1,false,-1)

	local config = actWebData.config

	local showHelpTips = checknumber(config.helpTips) or 0
	if showHelpTips then
		self._callHelpTitleTxt = config.callHelpTitleTxt
		self._callHelpTitle = config.callHelpTitle
	end
	CS.ShowObject(self.mBtnProb,showHelpTips)

	local roundOff = checknumber(config.roundOff) or 0
	self._showRound = roundOff == 1

	local startTime = actData.startTime
	local roundTimeMap = {}
	local roundTimeList = {}
	local roundTimeNum,openDay
	local roundTime = string.split(config.roundTime,"|")
	for i,v in ipairs(roundTime) do
		v = string.split(v,"=")
		roundTimeNum = checknumber(v[1])
		openDay = checknumber(v[2])
		local data = {
			roundTimeNum = roundTimeNum,
			openDay = openDay,
			openTime = startTime + openDay * 86400
		}
		roundTimeMap[roundTimeNum] = data
		table.insert(roundTimeList,data)
	end
	self._roundTimeMap = roundTimeMap
	self._roundTimeList = roundTimeList

	self._roundTimeTxt = config.roundTimeTxt

	local selectType = checknumber(config.selectType) or 0
	local canSelBigRew = selectType == 1
	self._canSelBigRew = canSelBigRew

	self._costOne1 = LxDataHelper.ParseItem_3(config.costOne1)
	self._costTen1 = LxDataHelper.ParseItem_3(config.costTen1)

	self._costOne2 = LxDataHelper.ParseItem_3(config.costOne2)
	self._costTen2 = LxDataHelper.ParseItem_3(config.costTen2)

	self._costItem = config.costItem

	self._textTip = config.textTip

	local callBtnTxtInfo = {}
	local callBtnTxt = string.split(config.callBtnTxt,"=")
	for i,v in ipairs(callBtnTxt) do
		table.insert(callBtnTxtInfo,v)
	end
	self._callBtnTxtInfo = callBtnTxtInfo

	--- 大奖：自選保底次數
	self._graduateTime = checknumber(config.graduateTime)

	--- 抽奖配置：钻石消耗-每日伙伴召唤次数上限
	self._goldTimes = checknumber(config.goldTimes)

	--- 抽奖配置：每日能召唤的最大次数，一般配置10000
	self._callMaxNum = checknumber(config.callMaxNum)

	--- 抽奖配置：今日抽取上限提示文本
	self._callLimitTips = config.callLimitTips

	--- 抽奖配置：今日钻石抽取提示文本
	self._diaCallLimitTips = config.diaCallLimitTips

	self._logTitle = config.logTitle
	local logKeepNum = config.logKeepNum
	self._logTips = string.replace(config.logTips,logKeepNum)
	self._logTimeTips = config.logTimeTips

	self._goodsOne = LxDataHelper.ParseItem_3(config.goodsOne)
	self._goodsTen = LxDataHelper.ParseItem_3(config.goodsTen)

	local headline = config.headline
	if LxUiHelper.IsImgPathValid(headline) then
		self:SetWndEasyImage(self.mBaoDiImg,headline,function()
			CS.ShowObject(self.mBaoDiImg,true)
		end,true)
	else
		CS.ShowObject(self.mBaoDiImg,true)
	end

	local selectDescIcon = config.selectDescIcon
	if LxUiHelper.IsImgPathValid(selectDescIcon) then
		self:SetWndEasyImage(self.mSelBigRewImg,selectDescIcon,function()
			CS.ShowObject(self.mSelBigRewImg,true)
		end,true)
	else
		CS.ShowObject(self.mSelBigRewImg,true)
	end

	local shopShow = config.shopShow or 0
	local showShop = shopShow == 1
	CS.ShowObject(self.mBtnShop,showShop)

	self:SetAnchorPos(self.mImgTime,LxDataHelper.ParseVector2NotEmpty2(config.timePos))

	local jumpAni = false
	local act166JumpAni = checknumber(LPlayerPrefs.act166JumpAni) or 0
	if act166JumpAni == 0 then
		local skipAnimation = checknumber(config.skipAnimation) or 0
		local useConfig = skipAnimation > 0
		if useConfig then
			jumpAni = true
		end
	else
		jumpAni = act166JumpAni == 1
	end
	self._jumpAni = jumpAni
	CS.ShowObject(self.mBtnJumpAni,true)
	self:RefreshJumpAniStatus()
end

function UIActivity166Main:InitText()
	self:SetWndText(self.mTxtClose,ccClientText(42010))
	self:SetWndText(self.mJumpAniBgTxt,ccClientText(47005))
	self:SetTextTile(self.mBtnLog,ccClientText(47001))
	self:SetTextTile(self.mBtnProb,ccClientText(47002))
	self:SetTextTile(self.mBtnShop,ccClientText(11676))
	self:SetTextTile(self.mBtnRoundOff,ccClientText(47004))
	self:SetWndText(self:FindWndTrans(self.mBtnBigRewSet,"BtnName"),ccClientText(47003))
end

function UIActivity166Main:InitBtnTransInfos()
	local btnTransInfos = {}
	local btnList = {self.mOneCallBtn,self.mTenCallBtn}
	for i,v in ipairs(btnList) do
		local PayDiv = self:FindWndTrans(v,"PayDiv")
		table.insert(btnTransInfos,{
			EffRoot = self:FindWndTrans(v,"EffRoot"),
			BtnName = self:FindWndTrans(v,"BtnName"),
			TimeTxt = self:FindWndTrans(v,"TimeTxt"),
			PayDiv = PayDiv,
			IconImg = self:FindWndTrans(PayDiv,"IconImg"),
			NumTxt = self:FindWndTrans(PayDiv,"NumTxt"),
			FreeTxt = self:FindWndTrans(v,"FreeTxt"),
		})
	end
	self._btnTransInfos = btnTransInfos
end

function UIActivity166Main:OnRoundTimer()
	local timerStr = ""
	local nextInfo = self._nextInfo
	if nextInfo then
		if self:CheckIsRoundOpen(nextInfo) then
			self:TimerStop(self._roundTimer)
		else
			local timeSpan = nextInfo.openTime - GetTimestamp()
			timerStr = string.replace(self._roundTimeTxt,LUtil.FormatTimespanCn(timeSpan,{
				hTextId = 10371
			}))
		end
	end
	self:SetWndText(self.mRoundOffTime,timerStr)
end

function UIActivity166Main:InitMsg()
	-- self:WndEventRecv(EventNames.xxxxx,function (...) self:OnEventXXXXX() end)
	-- self:WndNetMsgRecv(LProtoIds.xxxxx,function(...) self:OnMsgXXXXX(...) end)

	self:WndEventRecv(EventNames.On_Item_Change,function() self:OnItemChange() end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndEventRecv(EventNames.ON_ACTLOTTERYINFO,function (...) self:OnActLotteryInfo(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb) self:OnActivityPageResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActLotteryResp,function(pb) self:OnActLotteryResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActSelLotteryGuaranteeResp,function(...) self:OnActSelLotteryGuaranteeResp(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function(pb) self:OnActivityListResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
	self:WndEventRecv(EventNames.ON_ACTLOTTERYLOG,function(...) self:OnActLotteryLogResp(...) end)
	self:WndNetMsgRecv(LProtoIds.ActSelLotteryRoundResp,function(pb) self:OnActSelLotteryRoundResp(pb) end)

end

---@return StructLotteryData | nil
function UIActivity166Main:GetCurLotteryData()
	local actLotteryInfo = self._actLotteryInfo
	if not actLotteryInfo then return end

	return actLotteryInfo:GetCurLotteryData()
end

function UIActivity166Main:OnClickBtnLog()
	gModelActivity:OnActLotteryLogReq(self._sid,callPage)
end

function UIActivity166Main:OnActLotteryResp(pb)
	local sid = pb.sid
	if sid ~= self._sid then return end

	local rewards = {}
	local itemList = pb.itemList
	for i,v in ipairs(itemList) do
		table.insert(rewards, {
			itype = v.type,
			refId = v.itemId,
			count = v.count,
		})
	end

	local lotteryType = pb.lotteryType
	local freeCount = pb.freeCount
	local diamondCount = pb.diamondCount
	local tolCount = pb.tolCount
	local callNum = self._callNum
	local fixedReward = callNum == 1 and self._goodsOne or self._goodsTen
	self._rewardFunc = function()
		GF.OpenWndTop("UIOrdinYellAward", {
			sid = sid,
			itemList = rewards,
			callNum = callNum,
			jumpAni = self._jumpAni,
			freeCount = freeCount,
			diamondCount = diamondCount,
			tolCount = tolCount,
			lotteryType = lotteryType,
			fixedReward = fixedReward,
			closeWndFunc = function()
				if not self:IsWndValid() then return end
				self:SetAniScale(1)
				self._callNum = nil
			end
		})
		self:RefreshView()
	end


	if self._actLotteryInfo then
		self._actLotteryInfo:SetActLotteryData(pb)
	end

	if GF.FindFirstWndByName("UIOrdinYellAward") then
		self:ShowRewardFunc()
	else
		local entry2QualityMap = self._entry2QualityMap or {}
		local maxQuality = -1
		local quality
		local resultRefIds = pb.resultRefIds
		for i,v in ipairs(resultRefIds) do
			quality = entry2QualityMap[v]
			if quality and quality > 0 then
				if quality > maxQuality then
					maxQuality = quality
				end
			end
		end

		if maxQuality < 0 then
			maxQuality = 1
		end

		self:DoKaiJiangAni(maxQuality)
	end
end

function UIActivity166Main:OnActLotteryInfo(data,sid)
	if sid ~= self._sid then return end

	self._actLotteryInfo = data

	if self._reqPage then
		gModelActivity:OnActivityPageReq(sid)
	end
	self._reqPage = false
end

function UIActivity166Main:DoKaiJiangAni(maxQuality)
	if self._jumpAni then
		self:ShowRewardFunc()
	else
		local niudanjiSpine = self._niudanjiSpine
		if niudanjiSpine then
			maxQuality = maxQuality or 1

			local aniKey = "DoKaiJiangAni"
			self:TweenSeqKill(aniKey)
			local seq = self:TweenSeqCreate(aniKey,function(seq)
				CS.ShowObject(self.mEffRoot,false)

				local endAni = "end_" .. maxQuality
				niudanjiSpine:SetAnimationCompleteFunc(function(ani)
					if ani == endAni then
						self:ShowRewardFunc()
						niudanjiSpine:PlayAnimationSolid("idle",true)
					end
				end)
				niudanjiSpine:PlayAnimationSolid("start",false)

				seq:InsertCallback(3, function()
					niudanjiSpine:PlayAnimationSolid(endAni,false)
				end)
				seq:Insert(3, YXTween.TweenFloat(1, 1.6, 0.5, function(t)
					self:SetAniScale(t)
				end))

				seq:InsertCallback(5.166, function()
					CS.ShowObject(self.mEffRoot,true)
				end)

				seq:InsertCallback(6,function()

				end)
				return seq
			end)
			seq:OnComplete(function ()
				self:TweenSeqKill(aniKey)
			end)
			seq:PlayForward()

		else
			self:ShowRewardFunc()
		end
	end
end

function UIActivity166Main:SetAniScale(scale)
	scale = scale or 1
	self.mAni.localScale = Vector3(scale,scale,scale)
end

---@param payItem1 table 道具消耗
---@param payItem2 table 钻石消耗
---@return number 类型： 1钻石,2道具,3免费,-1 返回
function UIActivity166Main:GetLotteryType(payItem1,payItem2,hasDiamond)
	local lotteryType = 1
	if gModelGeneral:CheckItemEnough(payItem1.itemId,payItem1.itemNum) then
		lotteryType = 2
	else
		if not gModelGeneral:CheckItemEnough(payItem2.itemId,payItem2.itemNum) then
			if hasDiamond then
				gModelGeneral:CheckItemEnough(payItem2.itemId,payItem2.itemNum,true,self:GetWndName())
			else
				gModelGeneral:CheckItemEnough(payItem1.itemId,payItem1.itemNum,true,self:GetWndName())
			end
			return -1
		else
			if not hasDiamond then
				gModelGeneral:CheckItemEnough(payItem1.itemId,payItem1.itemNum,true,self:GetWndName())
				return -1
			end
		end
	end
	return lotteryType
end

function UIActivity166Main:OnClickBtnJumpAni()
	local jumpAni = not self._jumpAni
	self._jumpAni = jumpAni
	local status = jumpAni and "1" or "-1"
	LPlayerPrefs.SetAct166JumpAni(status)
	self:RefreshJumpAniStatus()
end

function UIActivity166Main:CheckHasNextRound()
	local round = self:GetCurLotteryRound()
	if not round then return false end

	local roundTimeList = self._roundTimeList or {}
	local roundTimeCnt = #roundTimeList
	return round < roundTimeCnt,roundTimeList[round + 1]
end

function UIActivity166Main:OnDrawNeedAddItemCell(list,item,itemdata,itempos)
	local IconTrans = self:FindWndTrans(item,"IconDiv/Icon")
	local NumTrans = self:FindWndTrans(item,"Num")
	local AddBtnTrans = self:FindWndTrans(item,"BtnDiv/AddBtn")

	local itemId = itemdata.itemId
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(IconTrans,icon)

	local haveNum = gModelItem:GetNumStrByRefId(itemId)
	self:SetWndText(NumTrans,haveNum)

	self:SetWndClick(AddBtnTrans,function()
		self:OnClickAddBtnFunc(itemdata)
	end)
end

function UIActivity166Main:InitData()
	local sid = self:GetWndArg("sid")
	local subPage = self:GetWndArg("subPage")
	if subPage then
		sid = gModelActivity:GetSidByUniqueJump(subPage)
	end
	if not sid then
		self:WndClose()
		return
	end

	self._niudanjiSpine = self:CreateWndSpineImpl({
		trans = self.mSpineRoot,
		spineName = "ui_niudanji",
		key = "ui_niudanji",
		sortOrder = 1,
		endFunc = function()
			self._loadSpineEnd = true
		end,
	})

	CS.ShowObject(self.mEffRoot,false)
	self._niudanKJEff = self:CreateWndEffect_Ex({
		trans = self.mEffRoot,
		effName = "fx_ui_niudanji_kaijiang",
		effKey = "fx_ui_niudanji_kaijiang",
		upSortOrder = 6,
	})

	self._sid = sid
	gModelActivity:ReqActivityConfigData(sid)
end

function UIActivity166Main:OnActLotteryLogResp(data,sid)
	if sid ~= self._sid then return end

	---@type StructLotteryLogData[]
	local logDataList = data.logDataList
	GF.OpenWnd("UIYellLog",{
		logTitle = self._logTitle,
		logTips = self._logTips,
		logTimeTips = self._logTimeTips,
		logList = logDataList,
		special = 1,
	})
end

function UIActivity166Main:RefreshView()
	self:RefreshCallBtns()

	local dailyNumStr = ""
	local diamondsNumStr = ""
	local actLotteryInfo = self._actLotteryInfo
	if actLotteryInfo then
		dailyNumStr = string.replace(self._callLimitTips,actLotteryInfo.tolCount,self._callMaxNum)
		diamondsNumStr = string.replace(self._diaCallLimitTips,actLotteryInfo.diamondCount)
	end
	self:SetWndText(self.mCallDailyNum,dailyNumStr)
	self:SetWndText(self.mCallDiamondsNum,diamondsNumStr)

	self._nextInfo = nil
	self:TimerStop(self._roundTimer)
	local showBtnRoundOff = false
	local showRound = self._showRound
	if showRound then
		local lotteryData = self:GetCurLotteryData()
		local isHasNext,nextInfo = self:CheckHasNextRound()
		if lotteryData and lotteryData:CheckIsGuarantee() and isHasNext and nextInfo then
			showBtnRoundOff = true

			if not self:CheckIsRoundOpen(nextInfo) then
				self._nextInfo = nextInfo
				self:OnRoundTimer()
				self:TimerStart(self._roundTimer,1,false,-1)
			end
		end
	end
	CS.ShowObject(self.mBtnRoundOff,showBtnRoundOff)


	local showInfoDiv = false
	local showSelBigRewImg = false
	local showCallInfoShow = false
	local showBtnBigRewSet = false
	local canSelBigRew = self._canSelBigRew
	local lotteryData = self:GetCurLotteryData()
	if lotteryData then
		if canSelBigRew and lotteryData:CheckShowBtnBigRewSet() then
			showBtnBigRewSet = true
			showSelBigRewImg = true
		else
			showCallInfoShow = true
		end
		if lotteryData:CheckShowInfo() then
			showCallInfoShow = true
			showSelBigRewImg = false
		end

		self:SetWndText(self.mBigRewCallNum,LUtil.GetNumCoversionStrSprite(self._graduateTime - lotteryData.lotteryCount))

		local name = ""
		local entryDataMap = self._entryDataMap or {}
		local entryData = entryDataMap[lotteryData.guaranteeId]
		if entryData then
			name = entryData.name
		end
		self:SetWndText(self.mBigRewName,name)

		--- 出大奖了，不显示
		if not lotteryData:CheckIsGuarantee() then
			showInfoDiv = true
		end
	end
	CS.ShowObject(self.mBtnBigRewSet,showBtnBigRewSet)
	CS.ShowObject(self.mSelBigRewImg,showSelBigRewImg)
	CS.ShowObject(self.mCallInfoShow,showCallInfoShow)
	CS.ShowObject(self.mInfoDiv,showInfoDiv)

end

function UIActivity166Main:OnItemChange()
	self:InitNeedAddItemList()
	self:RefreshView()
end

function UIActivity166Main:OnActivityResp(pb)
	local sid = self._sid
	local activity = pb.activity
	if activity.sid == sid and activity.status ~= 3 then
		gModelActivity:OnActivityPageReq(sid)
	end
end

function UIActivity166Main:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end
	self:SetContent()
	self:InitNeedAddItemList()
	self._reqPage = true
	gModelActivity:OnActLotteryInfoReq(sid,callPage)
end

function UIActivity166Main:OnActivityPageResp(pb)
	local sid = pb.sid
	if sid ~= self._sid then return end

	self:DisposePageData(sid,pb)

	self:RefreshView()
end

---@return boolean 是否设置大奖
function UIActivity166Main:IsSelBigReward()
	if not self._canSelBigRew then return true end
	local lotteryData = self:GetCurLotteryData()
	if not lotteryData then return true end
	return lotteryData:CheckIsSelGuaranteeId()
end

function UIActivity166Main:OnClickAddBtnFunc(itemdata)
	gModelGeneral:OpenGetWayWnd({itemId = itemdata.itemId,srcWnd = self:GetWndName()})
end

function UIActivity166Main:OnActivityListResp(pb)
	local sid = self._sid
	local activities = pb.activities
	for i, v in ipairs(activities) do
		if v.sid == sid and v.status ~= 3 then
			gModelActivity:OnActivityPageReq(sid)
			return
		end
	end
end

------------------------------------------------------------------
return UIActivity166Main