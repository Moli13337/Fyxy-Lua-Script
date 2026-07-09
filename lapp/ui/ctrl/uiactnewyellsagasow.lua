---
--- Created by Administrator.
--- DateTime: 2023/10/22 21:22:21
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActNewYellSagaSow:LWnd
local UIActNewYellSagaSow = LxWndClass("UIActNewYellSagaSow", LWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local UScreen = UnityEngine.Screen
local screenWidth = UScreen.width / 2
local UnityEngine = UnityEngine
local typeof = typeof
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local YXTween = YXTween
local Tweening = DG.Tweening
local EaseInQuad = Tweening.Ease.InQuad

UIActNewYellSagaSow.TYPE_STAGEVIEW = 1 			-- 心愿舞台
UIActNewYellSagaSow.TYPE_GIFTVIEW = 2			-- 心愿礼包
UIActNewYellSagaSow.TYPE_WALLVIEW = 3			-- 心愿墙
UIActNewYellSagaSow.TYPE_PAEANVIEW = 4			-- 心愿赞歌

UIActNewYellSagaSow.CALL_ONE = 1
UIActNewYellSagaSow.CALL_TEN = 10

UIActNewYellSagaSow.SHOW_RANKNUM = 3
UIActNewYellSagaSow.TYPE_RANK = 2

UIActNewYellSagaSow.TYPE_GIFT_POOL = 1
UIActNewYellSagaSow.TYPE_EXCHANGE = 7

UIActNewYellSagaSow.TYPE_BUY_FREE = 0
UIActNewYellSagaSow.TYPE_BUY_ITEM = 1
UIActNewYellSagaSow.TYPE_BUY_RMB = 2

UIActNewYellSagaSow.SHOW_LOG_CELL_NUM = 4

UIActNewYellSagaSow.LOG_CELL_STAR_POS = 40

UIActNewYellSagaSow.BTN_EFFECT_NAME = "fx_anniu_02"


--- 使用新的排行榜界面 或者活动表格配置showRankBgNew字段控制
--- 0：老的排行榜 1：新的排行榜
UIActNewYellSagaSow.USE_NEW_RANK = 1

UIActNewYellSagaSow.ARROW_SHRINK_STATUS = 0          --- 收缩
UIActNewYellSagaSow.ARROW_UNFOLD_STATUS = 1          --- 展开

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActNewYellSagaSow:UIActNewYellSagaSow()
	self._timerKey = "_timerKey"
	self._effTimerKey = "effTimerKey"
	self._effKey = "guideFinger"
	---@type table<string,LUIHeroObject>
	self._uiHeroObjList = nil			-- spine列表
	---@type LUIHeroObject
	self._curUIHeroObj = nil 			-- 当前spine
	---@type table<number,CommonIcon>
	self._uiCommonList 	= {}

	self._logSlideTime = "logSlideTime"
	self._logCellH = 40

	self._changeImg = false

	self._logKey = ModelScroll.TYPE_NEWCALLHERO
	self._moveKey = "moveKey"

    self._arrowEffKey = "_arrowEffKey"
    self._arrowStatus = UIActNewYellSagaSow.ARROW_UNFOLD_STATUS
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActNewYellSagaSow:OnWndClose()
	LUtil.ClearHashTable(self._uiHeroObjList)
	self._uiHeroObjList = nil
	--这个是从列表器拿出来的，列表进行删除就好了
	self._curUIHeroObj = nil
	self:ClearCommonIconList(self._uiCommonList)
	self._uiCommonList = nil
	if self._iconList then
		self._iconList:Destroy()
		self._iconList = nil
	end

	if self._func then self._func() end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActNewYellSagaSow:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActNewYellSagaSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:CreateWndEffect(self.mOneCallEffRoot,"fx_ui_ZH_anniu","OneCall",100,false,false)
	self:CreateWndEffect(self.mTenCallEffRoot,"fx_ui_ZH_anniu","TenCall",100,false,false)
	
	self:InitTxt()
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	self:InitLogCellList()
	gModelActivity:ReqActivityConfigData(self._sid)
	gModelScroll:OnScrollReq(self._logKey,self._sid)
end

function UIActNewYellSagaSow:CreateGift(trans,itemdata)
	local BgImg = self:FindWndTrans(trans,"BgImg")
	local Bg = self:FindWndTrans(trans,"Bg")
	local BuyCount = self:FindWndTrans(trans,"BuyCount")
	local title = self:FindWndTrans(trans,"title")
	local btn = self:FindWndTrans(trans,"btn")
	local btn1 = self:FindWndTrans(trans,"btn1")
	local rewardList1 = self:FindWndTrans(trans,"rewardList1")
	local rewardList2 = self:FindWndTrans(trans,"rewardList2")
	local DiscountImg = self:FindWndTrans(trans,"DiscountImg")
	local DiscountTxt = self:FindWndTrans(DiscountImg,"DiscountTxt")
	local redPoint = self:FindWndTrans(trans,"redPoint")
	local Show = self:FindWndTrans(trans,"Show")
	local maskTrans = self:FindWndTrans(trans, "mask")
	local ShowZSImg = self:FindWndTrans(trans, "ShowZSImg")
	local ZSNum = self:FindWndTrans(ShowZSImg, "ZSNum")
	local EffRoot = self:FindWndTrans(trans, "EffRoot")

	local buyNum = itemdata.buyNum
	local valuePercent  = itemdata.valuePercent			-- 价格百分比
	local isHave = not string.isempty(valuePercent) and buyNum > 0
	if isHave then
		local show = true
		if buyNum <= 0 then show = false end
		if valuePercent == "0" then show = false end
		if show then
			self:SetWndText(DiscountTxt,valuePercent)
		end
		isHave = show
	end
	CS.ShowObject(DiscountImg,isHave)

	local dataTableData = string.split(itemdata.moreInfo,";")
	local zsNum = tonumber(dataTableData[5])
	local showZSImg = zsNum and zsNum ~= 0 or false
	CS.ShowObject(ShowZSImg,showZSImg)
	if showZSImg then
		self:SetWndText(ZSNum,zsNum)
	end

	local buyEmpty = buyNum <= 0
	CS.ShowObject(Show,buyEmpty)
	CS.ShowObject(maskTrans,buyEmpty)

	local typeId = itemdata.typeId						-- 类型ID=礼包卡底资源图=售卖文本字色=售卖文本描边色
	--self:SetActivityTitleImage(BgImg,typeId)
	self:SetWndEasyImage(Bg,itemdata.desc,function() CS.ShowObject(Bg,true) end)

	local buyCountText = string.replace(ccClientText(20810), buyNum)
	self:SetWndText(BuyCount,buyCountText)
	self:SetWndText(title,itemdata.title)

	local itemList = itemdata.commonGiftList
	local showMaxList = #itemList > 3
	CS.ShowObject(rewardList1, not showMaxList)
	CS.ShowObject(rewardList2, showMaxList)
	local RewardList = showMaxList and rewardList2 or rewardList1
	self:CreateSelGiftList(RewardList,itemList,nil, false)

	local expend2 = itemdata.expend2
	local expend2List = string.split(expend2,"=")
	local len = #expend2List
	local isFree = expend2List[1] and expend2List[1] == "-1" or false
	CS.ShowObject(redPoint,false)

	if EffRoot then
		local InstanceID = EffRoot:GetInstanceID()
		self:DestroyWndEffectByKey(InstanceID)
		local isShow = isFree and buyNum > 0
		if isShow then
			local bgEff = "fx_libaomianfeilingqu"
			self:CreateWndEffect(EffRoot,bgEff,InstanceID,100,false,false)
		end
	end

	local txt
	local showIconImg = false
	if isFree then
		txt = ccClientText(11913)
	else
		showIconImg = len > 1
		if showIconImg then
			txt = expend2List[3]
		else
			--local rmb = gModelPay:GetRMBValueByWelfareId(tonumber(expend2))
			txt = gModelPay:GetShowByWelfareId(tonumber(expend2)) -- string.replace(ccClientText(15601),rmb)
		end
	end
	local BuyBtnTrans
	local BuyBtnTxt
	if showIconImg then
		CS.ShowObject(btn1,true)
		CS.ShowObject(btn,false)
		BuyBtnTxt = self:FindWndTrans(btn1,"Content/text1")
	else
		CS.ShowObject(btn,true)
		CS.ShowObject(btn1,false)
		BuyBtnTxt = self:FindWndTrans(btn,"text")
	end
	self:SetWndText(BuyBtnTxt,txt)
	local itemIconPath = gModelItem:GetItemIconByRefId(tonumber(expend2List[2]))
	local itemIconTrans = self:FindWndTrans(btn1,"Content/Image")
	self:SetWndEasyImage(itemIconTrans,itemIconPath)
	self:SetWndClick(trans,function()
		self:BuyClick(itemdata)
	end)
end

function UIActNewYellSagaSow:RefreshNumLimit()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end

	local moreInfo = JSON.decode(activityData.moreInfo)
	local showLimit = moreInfo.callMaxNum ~= nil
	CS.ShowObject(self.mChouquBg,showLimit)
	if not showLimit then
		return
	end
	local dayNum = moreInfo.dropNumToday or 0
	local str = string.replace(ccClientText(11630),dayNum,moreInfo.callMaxNum)
	self:SetWndText(self.mNumLimit,str)
end

function UIActNewYellSagaSow:RefreshMyRedPoint()
	local showStageRedPoint = self._freeNum and self._freeNum > 0
	CS.ShowObject(self.mStageRedPoint,showStageRedPoint)

	local activityData = self._activityData
	if activityData then
		local sid = self._sid
		local giftOptional = self._giftOptional or ModelActivity.GIFTOPTIONAL_0
		local pageId = ModelActivity.MODEL_NEWHEROCALL_TYPE_GIFT_SEL
		local pageData,entryList
		local showGiftRedPoint = false
		if gModelActivity:CheckGiftoptionalStatus(sid,giftOptional,pageId) then
			pageData = activityData[pageId] or {}
			entryList = pageData.entry or {}
			for i,v in ipairs(entryList) do
				local MarketData = v.MarketData
				local personal,personalGoal = MarketData.personal,MarketData.personalGoal
				local buyNum = personalGoal - personal
				local expendType = MarketData.expendType
				if buyNum > 0 and expendType == UIActNewYellSagaSow.TYPE_BUY_FREE then
					showGiftRedPoint = true
					break
				end
			end
		end
		if not showGiftRedPoint then
			pageId = ModelActivity.MODEL_NEWHEROCALL_TYPE_GIFT_SHOP
			if gModelActivity:CheckGiftoptionalStatus(sid,giftOptional,pageId) then
				local player = gModelPlayer:GetPlayerLv()
				pageData = activityData[pageId] or {}
				entryList = pageData.entry or {}
				for i,v in ipairs(entryList) do
					local moreInfo = string.split(v.moreInfo,";")
					local showLv = moreInfo[2]
					local needShowLv = showLv and tonumber(showLv) or 0 --显示等级
					local ins = player >= needShowLv
					if ins then
						local MarketData = v.MarketData
						local personal,personalGoal = MarketData.personal,MarketData.personalGoal
						local buyNum = personalGoal - personal
						local expend2 = MarketData.expend2
						if buyNum > 0 and expend2 == "-1" then
							showGiftRedPoint = true
							break
						end
					end
				end
			end
		end
		CS.ShowObject(self.mGiftRedPoint,showGiftRedPoint)

		local showTargetRedPoint = false
		local page3Info = self._page3Info or {}
		for i,v in ipairs(page3Info) do
			local _pageId = v.pageId
			local status = self:GetWallRedPointStatusByPageId(_pageId)
			if status then
				showTargetRedPoint = true
				break
			end
		end
		CS.ShowObject(self.mWallRedPoint,showTargetRedPoint)

        pageId = UIActNewYellSagaSow.TYPE_EXCHANGE
        pageData = activityData[pageId] or {}
        local showExchangeRedPoint = false
        entryList = pageData.entry or {}
        local minPay = 99999
        for i,v in ipairs(entryList) do
			local MarketData = v.MarketData
            local expend2 = string.split(MarketData.expend2,"=")
            local value = tonumber(expend2[3])
            if value < minPay and MarketData.personalGoal > MarketData.personal then
                minPay = value
            end
        end
        local haveNum = gModelItem:GetNumByRefId(self._itemId)
        showExchangeRedPoint = haveNum >= minPay
        CS.ShowObject(self.mPaeanRedPoint,showExchangeRedPoint)
        CS.ShowObject(self.mPaeanViewExchBtnRedPoint,showExchangeRedPoint)
	end
end

function UIActNewYellSagaSow:CallEvent(callType)
	if self._mySelect == 0 then
		GF.ShowMessage(ccClientText(11646))
		return
	end
	gModelActivity:GetCallDataBySid(self._sid,nil,callType,self:GetWndName())
end

function UIActNewYellSagaSow:OpenActivitySel(ispre)
	local sid,wishHero,mySelectHero = self._sid,self._wishHeroList,self._mySelectHero
	if ispre then
		mySelectHero = nil
	end
	GF.OpenWnd("UIActSagaSel",{sid = sid,wishHero = wishHero,preview = ispre,mySelectHero = mySelectHero,inWishUpHeroPoolMap = self._inWishUpHeroPoolMap})
end

function UIActNewYellSagaSow:SetLogItem(item,itemdata,itempos)
	local textTrans = self:FindWndTrans(item,"UIText")
	if textTrans then
		local rewardStr
		local itemType,itemId,itemNum
		local reward = string.split(itemdata.reward,",")
		for i,v in ipairs(reward) do
			v = string.split(v,"=")
			itemType = tonumber(v[1])
			itemId = tonumber(v[2])
			itemNum = tonumber(v[3])
			local name = gModelGeneral:GetCommonItemName({itemType = itemType,itemId = itemId})
			if name then
				local str = name .. "*" .. itemNum
				if not rewardStr then
					rewardStr = str
				else
					rewardStr = rewardStr .. "," .. str
				end
			end
		end
		local str = string.replace(ccClientText(20318),itemdata.playerName,rewardStr)
		self:SetWndText(textTrans,str)
		self:InitTextModeWithLanguage(textTrans)
	end
end

function UIActNewYellSagaSow:ShowWnd()
	if self._page == UIActNewYellSagaSow.TYPE_WALLVIEW then
		self._page3PageId = nil
	end
	self:RefreshView()
end

function UIActNewYellSagaSow:CreateImmobilization(trans,itemdata)
	for i = 1,3 do
		local data = itemdata[i]
		local showGift = data ~= nil
		local giftTrans = self:FindWndTrans(trans,"Gift"..i)
		if giftTrans and showGift then
			self:CreateGift(giftTrans,data)
		end
		CS.ShowObject(giftTrans,showGift)
	end
end

function UIActNewYellSagaSow:OnDrawCustomCell(list,item,itemdata,itempos)
	local Custom = self:FindWndTrans(item,"Custom")
	local Immobilization = self:FindWndTrans(item,"Immobilization")
	local isSel = itemdata.isSel
	CS.ShowObject(Custom,isSel)
	CS.ShowObject(Immobilization,not isSel)
	local height = item.sizeDelta.y
	if isSel then
		self:CreateCustom(Custom,itemdata)
		LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
	else
		self:CreateImmobilization(Immobilization,itemdata)
		LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
	end
end

function UIActNewYellSagaSow:OnDrawRankCell(list,item,itemdata,itempos)
	local RankImgTrans = self:FindWndTrans(item,"RankImg")
	local NameTrans = self:FindWndTrans(item,"Name")
	local ScoreTrans = self:FindWndTrans(item,"Score")
	local rank = itemdata.rank
	local name = itemdata.name
	local score = itemdata.score
	local playerId = itemdata.playerId
	local myPlayerId = gModelPlayer:GetPlayerId()
	local color = myPlayerId == playerId and "lightGreen" or "white"
	name = LUtil.FormatColorStr(name,color)
	self:SetWndText(NameTrans,name)
	self:SetWndText(ScoreTrans,score)
	local rankScoreImgList = self._rankScoreImgList
	local img = rankScoreImgList and rankScoreImgList[rank]
	if img and RankImgTrans then
		self:SetWndEasyImage(RankImgTrans,img)
	end
end

function UIActNewYellSagaSow:RefreshCallFunc()
	self:OnActivityConfigData()
	self:RefreshView()
	self:RefreshNeedList()
	self:RefreshMyRedPoint()
	self:SendRankReq()
end

function UIActNewYellSagaSow:OnActivityPageResp(pb,ret)
	local sid = pb.sid
	if sid ~= self._sid then return end
	local activityData = self._activityData
	if not activityData then
		activityData = {}
		self._activityData = activityData
	end
	local isEmpty = false
	local rewardList = self._rewardList
	if not rewardList then
		rewardList = {}
		self._rewardList = rewardList
		isEmpty = true
	end
	local wishHeroKeyList = self._wishHeroKeyList
	for i,v in ipairs(pb.pages or {}) do
		local pageData = gModelActivity:GenerateActivePageDataFromPb(v)
		local pageId = pageData.pageId
		activityData[pageId] = {
			sid = pageData.sid,
			pageId = pageId,
		}
		activityData[pageId].entry = {}
		for idx,val in ipairs(pageData.entry) do
			local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,val.pageId,val.entryId)
			if not entryCfg then return end
			local moreInfo = entryCfg.moreInfo
			local entryId = val.entryId
			local items = LxDataHelper.ParseItem(entryCfg.reward)
			local goalData = val.goalData
			local data = {
				entryId = entryId,
				pageId = pageId,
				title = entryCfg.name,
				desc = entryCfg.description,
				icon = entryCfg.icon,
				items = items,
				goalData = goalData,
				status  = goalData.status,
				MarketData = val.MarketData,
				moreInfo = moreInfo,
				sort = entryCfg.sort,
				jumpId = entryCfg.jumpId,
				jumpDesc = entryCfg.jumpDesc,
			}
			table.insert(activityData[pageId].entry, data)
			if pageId == 1 then
				local firstData = items[1]
				local heroType = firstData and firstData.itemType
				if heroType == LItemTypeConst.TYPE_HERO then
					local moreInfoList = string.split(moreInfo,"=")
					local wishHeroData = wishHeroKeyList[entryId]
					if wishHeroData then
						local rare = tonumber(moreInfoList[3]) or 0
						local report = tonumber(moreInfoList[4]) or 0
						wishHeroData.rare = rare
						wishHeroData.report = report
					end
				end
			elseif pageId == 8 and isEmpty then
				local rewardData = {}
				rewardData.index = entryId
				rewardData.reward = items
				local str = string.split(entryCfg.name,"~")
				local left = tonumber(str[1])
				local right = (str[2] and tonumber(str[2])) or left
				local rank = {}
				table.insert(rank,left)
				table.insert(rank,right)
				rewardData.rank = rank
				table.insert(self._rewardList,rewardData)
			end
		end
	end
	self:RefreshMyRedPoint()
	self:RefreshView()
	self:RefreshMyInfoDiv(self._aRank,self._aScore)
end

function UIActNewYellSagaSow:ClickWallBtnEvent(itemdata,refresh)
	local pageId = itemdata.pageId
	if self._page3PageId == pageId and not refresh then return end
	self._page3PageId = pageId
	self:RefreshUIWallBtnList()
	self:SetTargetInfo(itemdata,true)
end

function UIActNewYellSagaSow:OnActivityListResp(pb,ret)
	local sid = self._sid
	local activities = pb.activities
	for i, v in ipairs(activities) do
		if v.sid == sid then
			gModelActivity:ReqActivityConfigData(sid)
			break
		end
	end
end

function UIActNewYellSagaSow:ShowHeroInfo(heroRefId)
	local heroRef = gModelHero:GetHeroRef(heroRefId)
	if not heroRef then return end

	local raceId = heroRef.raceType
	local raceRef = gModelHero:GetHeroRaceRefByRefId(raceId)
	if not raceRef then return end

	local effectRef = gModelHero:GetHeroShowRefByRefId(heroRefId)
	if not effectRef then return end


	local heroName = ccLngText(effectRef.name)

	local myDropNum = self._myDropNum
	local mySelect = self._mySelect
	local wishHeroKeyList = self._wishHeroKeyList
	if mySelect and wishHeroKeyList and myDropNum then
		local selInfo = wishHeroKeyList[mySelect]
		if selInfo then
			local minNum = selInfo.minNum
			local last = minNum - myDropNum
			if last <= 0 then last = 1 end

			local enTextTrans,enNameTextTrans
			if gLGameLanguage:IsEnglishVersion() then
				enTextTrans = self.mGetHeroEnNumTxt
				enNameTextTrans = self.mGetHeroEnNameTxt
			elseif gLGameLanguage:IsGermanVersion() then
				enTextTrans = self.mGetHeroNumTxtDe
				enNameTextTrans = self.mGetHeroNameTxtDe
			elseif gLGameLanguage:IsFrenchVersion() then
				enTextTrans = self.mGetHeroNumTxtFr
				enNameTextTrans = self.mGetHeroNameTxtFr
			elseif gLGameLanguage:IsThaiVersion() then
				enTextTrans = self.mGetHeroNumTxtTh
				enNameTextTrans = self.mGetHeroNameTxtTh
			elseif gLGameLanguage:IsVietnamVersion() then
				enTextTrans = self.mGetHeroNumTxtVie
				enNameTextTrans = self.mGetHeroNameTxtVie
			elseif gLGameLanguage:IsKoreaRegion() then
				enTextTrans = self.mGetHeroNumTxtKo
				enNameTextTrans = self.mGetHeroNameTxtKo
			elseif gLGameLanguage:IsJapanRegion() then
				enTextTrans = self.mGetHeroNumTxtJa
				enNameTextTrans = self.mGetHeroNameTxtJa
			else
				enTextTrans = self.mGetHeroNumTxt
				enNameTextTrans = self.mGetHeroNameTxt
			end
			self:SetWndText(enTextTrans,last)
			CS.ShowObject(enTextTrans,true)

			self:SetWndText(enNameTextTrans,heroName)
			CS.ShowObject(enNameTextTrans,true)

			local config = self._config
			if config then
				local pos = config.numTxtPos
				if not string.isempty(pos) then
					self:SetAnchorPos(enTextTrans, LxDataHelper.ParseVector2NotEmpty(pos))
				end

				pos = config.nameTxtPos
				if not string.isempty(pos) then
					self:SetAnchorPos(enNameTextTrans, LxDataHelper.ParseVector2NotEmpty(pos))
				end
			end
		end
	end

	local star = heroRef.initStar
	local prefabName = effectRef.prefabName
	self:CreateHeroSpine(heroRefId,star,prefabName)
	local qualityIcon = heroRef.qualityIcon
	self:SetWndEasyImage(self.mHeroZZImg,qualityIcon,function() CS.ShowObject(self.mHeroZZImg,true) end)
	local raceImg = raceRef.icon
	self:SetWndEasyImage(self.mHeroRaceImg,raceImg,function() CS.ShowObject(self.mHeroRaceImg,true) end)

	local quality = gModelHero:GetHeroQualityByRefId(heroRefId,star)
	self:SetWndText(self.mHeroName,heroName)
	local qualityRef = gModelItem:GetQualityRef(quality)
	if not qualityRef then return end
	local heroMsgNameBg = qualityRef.heroMsgNameBg
	self:SetWndEasyImage(self.mHeroQuaImg,heroMsgNameBg,function() CS.ShowObject(self.mHeroQuaImg,true) end)

	local trans = self.mStageHeroIcon
	local instanceID = trans:GetInstanceID()
	local Icon = self:FindWndTrans(trans,"Root")
	local commonInfo = {
		instanceID = instanceID,
		trans = Icon,
		itemType = LItemTypeConst.TYPE_HERO,
		itemId = heroRefId,
		itemNum = -1,
	}
	self:CreateCommonIcon(commonInfo)
	self:SetWndClick(Icon,function()
		self:OpenActivitySel()
	end)
end

function UIActNewYellSagaSow:MovePage()
	self:TweenSeq_UIListAutoMove(self._moveKey,self._logCellList,self._logCellH,0.5,nil,function()
		local oneTrans = self._logCellList[1]
		local first = UIActNewYellSagaSow.SHOW_LOG_CELL_NUM - 1
		for i = 1, first do
			self._logCellList[i] = self._logCellList[i+1]
		end
		self._logCellList[UIActNewYellSagaSow.SHOW_LOG_CELL_NUM] = oneTrans

		local endTrans = self._logCellList[first]
		oneTrans.localPosition = Vector2.New(endTrans.localPosition.x,endTrans.localPosition.y - self._logCellH)
		local list = gModelScroll:GetScrollInfoList(self._logKey,self._sid,ModelScroll.GET_ALL_INFO,true)
		local index = self._logIndex + 1
		if index > #list then
			index = 1
		end
		self._logIndex = index
		local log = list[index]
		self:SetLogItem(self._logCellList[4],log)

		self:SetItemAlpha(self._logCellList[4],1)
	end)
end

function UIActNewYellSagaSow:ChnageScrollPos(poPos)
	local logCellList = self._logCellList
	if not logCellList then return end
	for i, v in ipairs(logCellList) do
		local y = poPos - ((i - 1) * self._logCellH)
		v.anchoredPosition = Vector2.New(v.anchoredPosition.x,y)
	end
end

function UIActNewYellSagaSow:RefreshPaeanView()
	self:SetWndText(self.mRuleTitle,ccClientText(16804))
	self:SetWndText(self.mRewardTitle,ccClientText(16805))

	local page4Info = self._page4Info
	if page4Info then
		local descIcon5 = page4Info.descIcon5
		self:SetWndEasyImage(self.mPaeanViewTitle,descIcon5)
		self:InitStarList(page4Info.ruleIcon,page4Info.tipsTitle)
		self:SetWndText(self.mContent,page4Info.tipsDescription)
		self:SetWndEasyImage(self.mCellBg_1,page4Info.desBgBig)
		self:SetWndEasyImage(self.mCellBg_2,page4Info.desBgSmall)
		self:SetWndEasyImage(self.mCellBg_3,page4Info.desBgSmall)

		local itemId = page4Info.itemId
		local num = gModelItem:GetNumByRefId(itemId)
		local iconPath = gModelItem:GetItemImgByRefId(itemId)
		self:SetWndText(self.mDropNum,num)
		self:SetWndEasyImage(self.mDropIcon,iconPath)

		local getIcon = self:FindWndTrans(self.mPaeanViewGetBtn,"icon")
		self:SetImageEx(getIcon,page4Info.sourceIcon)
		local getText = self:FindWndTrans(self.mPaeanViewGetBtn,"text")
		local str = ccClientText(16806)
		self:SetWndText(getText,str)

		local topColor = page4Info.tipsTitleColor1
		local bottomColor = page4Info.tipsTitleColor2
		if not string.isempty(topColor) then
			self:SetColorGradient(self.mRuleTitle,topColor,bottomColor)
			self:SetColorGradient(self.mRewardTitle,topColor,bottomColor)
		end

		local reward = page4Info.rewardShow
		local items = LxDataHelper.ParseItem(reward)
		local showList ={}
		for k,v in ipairs(items) do
			local data = {
				itemId = v.itemId,
				itemNum = -1,
				itemType = v.itemType,
			}
			table.insert(showList,data)
		end

		local uiIconEasyList = self._iconList
		if not uiIconEasyList then
			uiIconEasyList = UIIconEasyList:New()
			self._iconList = uiIconEasyList
			uiIconEasyList:Create(self, self.mPaeanViewItemList)
		end
		uiIconEasyList:RefreshList(showList)
	end
end

function UIActNewYellSagaSow:CreateWallBtnList()
	local list = self._page3Info or {}
	local uiWallBtnList = self._uiWallBtnList
	if uiWallBtnList then
		uiWallBtnList:RefreshList(list)
	else
		uiWallBtnList = self:GetUIScroll("uiWallBtnList")
		self._uiWallBtnList = uiWallBtnList
		uiWallBtnList:Create(self.mWallBtnList,list,function(...) self:OnDrawWallBtnCell(...) end)
	end
	local refreshList = false
	if self._page3PageId == nil then
		self:ClickWallBtnEvent(list[1] or {},true)
		refreshList = true
	else
		for i,v in ipairs(list) do
			if v.pageId == self._page3PageId then
				self:ClickWallBtnEvent(v,true)
				refreshList = true
				break
			end
		end
	end
	if refreshList then
		self:RefreshUIWallBtnList()
	end
end

function UIActNewYellSagaSow:GetCommonExpendType(itemdata)
	local expendType = itemdata.expendType
	if not expendType or expendType == 0 then
		local expend2 = itemdata.expend2
		local expend2List = string.split(expend2,"=")
		local len = #expend2List
		local isFree = expend2List[1] and expend2List[1] == "-1" or false
		if isFree then
			expendType = UIActNewYellSagaSow.TYPE_BUY_FREE
		else
			if len > 1 then
				expendType = UIActNewYellSagaSow.TYPE_BUY_ITEM
			else
				expendType = UIActNewYellSagaSow.TYPE_BUY_RMB
			end
		end
	end
	return expendType
end

function UIActNewYellSagaSow:SetColorGradient(tran,top,bottom)
	local topColor = LUtil.ColorByHex_6(top)
	local bottomColor = LUtil.ColorByHex_6(bottom)
	LxUiHelper.SetTextColorGradient(tran,topColor,topColor,bottomColor,bottomColor)
end

function UIActNewYellSagaSow:CreateSelGiftList(trans,list,maxList, canScroll)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		local listType = maxList and UIItemList.WRAP
		uiList:Create(trans,list,function(...) self:OnDrawItemCell(...) end,listType)
		if listType then
			uiList:EnableScroll(canScroll or true,true)
		end
	end
end

function UIActNewYellSagaSow:StarCountDown()
	local lastTime = self._endTime - GetTimestamp()
	if lastTime < 0 then
		self:SetWndText(self.mCountDonwTxt,ccClientText(14301))
		self:TimerStop(self._timerKey)
		self._isEnd = true
	else
		local timeStr = LUtil.FormatTimespanCn(lastTime)
		--timeStr = LUtil.FormatColorStr(timeStr,"green")
		timeStr = string.replace(ccClientText(11640),timeStr)
		self:SetWndText(self.mCountDonwTxt,timeStr)
	end
end

function UIActNewYellSagaSow:RefreshCallBtn()
	local page1Info = self._page1Info
	if not page1Info then return end
	self._callPayInfo = {}
	local callInfo = page1Info.callInfo
	local callBtnList = self._callBtnList
	local freeNum = page1Info.freeNum
    local btnTextList = self._btnTextList
	for callNum,callData in pairs(callInfo) do
		local callBtnInfo = callBtnList[callNum]
		if callBtnInfo then
			local isHaveFree = freeNum > 0 and callNum == UIActNewYellSagaSow.CALL_ONE or false
			local showPayDiv = not isHaveFree
			local divTrans = callBtnInfo.div
			CS.ShowObject(divTrans,showPayDiv)
			if showPayDiv then
				local selPayRefId,selRefIdNum
				for idx,val in ipairs(callData) do
					local itemId,itemNum = val.itemId,val.itemNum
					local haveNum = gModelItem:GetNumByRefId(itemId)
					if haveNum >= itemNum and not selPayRefId then
						selPayRefId = itemId
						selRefIdNum = itemNum
					end
				end
				if not selPayRefId then
					local len = #callData
					selPayRefId = callData[len].itemId
					selRefIdNum = callData[len].itemNum
				end
				self._callPayInfo[callNum] = selPayRefId
				local iconTrans,numTrans = callBtnInfo.iconTrans,callBtnInfo.numTrans
				self:SetWndText(numTrans,selRefIdNum)
				local icon = gModelItem:GetItemIconByRefId(selPayRefId)
				self:SetWndEasyImage(iconTrans,icon)
			else
				self._callPayInfo[callNum] = ModelItem.ITEM_DIAMOND
			end
			local btnNameTxtId = isHaveFree and 20802 or callBtnInfo.btnNameTxtId
            local btnNameStr = ccClientText(btnNameTxtId)
            if btnTextList and #btnTextList > 0 then
                if callNum == UIActNewYellSagaSow.CALL_ONE then
                    btnNameStr = isHaveFree and btnTextList[1] or btnTextList[2]
                else
                    btnNameStr = btnTextList[3]
                end
            end
			self:SetWndText(callBtnInfo.btnNameTrans,btnNameStr)
		end
	end
end

function UIActNewYellSagaSow:GetHistory()
	local list = LWnd.GetHistory(self)
	local wndArgList = list.wndArgList
	wndArgList.sid = self._sid
	wndArgList.page = self._page
	wndArgList.func = self._func
	return list
end

function UIActNewYellSagaSow:SetTargetInfo(itemdata,changePageId)
	local img = itemdata.pageBg
	if img then self:SetWndEasyImage(self.mWallViewBg,img) end
	self:InitTargetList(changePageId)
end

function UIActNewYellSagaSow:OnTimer(key)
	if key == self._timerKey then
		self:StarCountDown()
	elseif key == self._logSlideTime then
		self:MovePage()
	end
end

function UIActNewYellSagaSow:RefreshUIWallBtnList()
	local uiWallBtnList = self._uiWallBtnList
	if uiWallBtnList then
		local uiList = uiWallBtnList:GetList()
		uiList:RefreshList()
	end
end

function UIActNewYellSagaSow:ChangeCustomList(customList,status)
	local list = {}
	for i,v in ipairs(customList or {}) do
		v.status = status
		table.insert(list,v)
	end
	return list
end

function UIActNewYellSagaSow:SetItemAlpha(item,alpha)
	if not item then return end
	local text = self:FindWndTrans(item,"UIText")
	local canvasGroup = self:GetCanvasGroup(text)
	if canvasGroup then
		canvasGroup.alpha = alpha
	end
end

function UIActNewYellSagaSow:InitStarList(starImg,arrowImg)
	local list = {self.mStar_1,self.mStar_2,self.mStar_3,self.mStar_4,}
	for i,v in ipairs(list) do
		self:SetWndEasyImage(v,starImg)
	end
	list = {self.mArrow_1,self.mArrow_2,self.mArrow_3,self.mArrow_4}
	for i,v in ipairs(list) do
		self:SetWndEasyImage(v,arrowImg)
	end
end

function UIActNewYellSagaSow:OnClickBotBtnEvent(btnInfo)
	local page = btnInfo.page
	if page == self._page then return end
	self._page = page
	if page == UIActNewYellSagaSow.TYPE_STAGEVIEW and self._initRank then
		self._initRank = false
	end
	self:ShowWnd()
end

function UIActNewYellSagaSow:SetImageEx(tran,img,needNativeSize)
	if LxUiHelper.IsImgPathValid(img) then
		CS.ShowObject(tran,false)
		self:SetWndEasyImage(tran,img,function ()
			if CS.IsValidObject(tran) then
				CS.ShowObject(tran,true)
			end
		end,needNativeSize)
	end
end

function UIActNewYellSagaSow:RefreshNeedList()
	local uiNeedList = self._uiNeedList
	if not uiNeedList then return end
	local uiList = uiNeedList:GetList()
	uiList:RefreshList()
end

function UIActNewYellSagaSow:RefreshBtnStatus()
	for k,v in pairs(self._pageBtnList) do
		local sel = self._page == v.page
		CS.ShowObject(v.notSelBtnRoot,not sel)
		CS.ShowObject(v.btnNameRoot,not sel)
		CS.ShowObject(v.selBtnRoot,sel)
		CS.ShowObject(v.selBtnNameRoot,sel)
		CS.ShowObject(v.selImg,sel)
	end
end

function UIActNewYellSagaSow:ShowWishUpHero()
	local page1Info = self._page1Info
	local wishUpHero = page1Info.wishUpHero

	local show = not string.isempty(wishUpHero)
	CS.ShowObject(self.mWishiUpHero, show)
	if not show then return end
	if not self._activityData then return end

	local pageData = self._activityData[UIActNewYellSagaSow.TYPE_GIFT_POOL]
	if not (pageData and pageData.entry) then return end

	local wishUpHeroList = string.split(wishUpHero, ';')
	local poolIdList = {}
	for k,v in ipairs(wishUpHeroList) do
		local poolId = tonumber(v)
		poolIdList[poolId] = true
	end

	local heroIdList = {}
	for k,v in ipairs(pageData.entry) do
		local poolId = v.entryId
		if poolIdList[poolId] then
			local items = v.items[1]
			if items.itemType == LItemTypeConst.TYPE_HERO then
				table.insert(heroIdList, items.itemId)
			end
		end
	end

	local scrollList = self._wishUpHeroScrollList
	if(scrollList)then
		scrollList:RefreshList(heroIdList)
	else
		scrollList = self:GetUIScroll("_wishUpHeroScrollList")
		scrollList:Create(self.mWishUpHero,heroIdList,function (...) self:OnDrawWishUpHeroSkill(...) end)
		scrollList:EnableScroll(false)
	end
end

function UIActNewYellSagaSow:RefreshStageView()
	local page1Info = self._page1Info
	if not page1Info then return end
	if not self._initRank then
		self._initRank = true
		self:SendRankReq()
	end
	local callNum = self._callNum or 0
	local last = self._goldTimes - callNum
	local str = string.replace(ccClientText(20809),last)
	self._lastTime = last
	self:SetWndText(self.mSurplusTxt,str)
	self:RefreshCallBtn()
	local mySelect = self._mySelect or 0
	local mySelectHero = self._mySelectHero
	local isSel = mySelect ~= 0
	local effKey = "fx_xyzh_guanghuan"
	local effKey1 = "fx_xyzh_jiahao"
	if isSel then
		self:DestroyWndEffectByKey(effKey)
		self:DestroyWndEffectByKey(effKey1)
		self:ShowHeroInfo(mySelectHero)
	else
		self:CreateWndEffect(self.mStageEffRoot,effKey,effKey,100)
		self:CreateWndEffect(self.mStageAddBtn,effKey1,effKey1,100,false,false,5)
	end
	CS.ShowObject(self.mSelDiv,isSel)
	CS.ShowObject(self.mSelHeroBtn,not isSel)


	--[[
        1. 新增key控制召唤界面是否显示“up英雄”
        --# key=wishUpShow；1=显示，0=不显示，没有key默认显示
    ]]
	local wishUpShow = page1Info.wishUpShow or 1
	local showWishUpHero = wishUpShow == 1
	CS.ShowObject(self.mWishiUpHero, showWishUpHero)
	if showWishUpHero then
		self:ShowWishUpHero()
	end
end

function UIActNewYellSagaSow:GetRankList()
	local list = {}
	local rankList = self:GetRankServerDataList()
	if rankList then
		local showRankNum = UIActNewYellSagaSow.SHOW_RANKNUM
		local insNum = 0
		local rank
		for k,v in ipairs(rankList) do
			rank = v.rank
			if rank <= showRankNum then
				insNum = insNum + 1
				table.insert(list,{
					name = v.info._name,
					rank = rank,
					score = v.score,
					playerId = v.info._playerId,
				})
			end
		end
		if insNum < showRankNum then
			for i = insNum + 1,showRankNum do
				table.insert(list,{
					name = ccClientText(20868),
					rank = i,
					score = 0,
					playerId = "-1",
				})
			end
		end
	end
	return list
end

function UIActNewYellSagaSow:OnDrawNeedItemCell(list,item,itemdata,itempos)
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
end

function UIActNewYellSagaSow:InitTargetList(changePageId)
	local list = self:GetTargetList()
	local uiTargetList = self._uiTargetList
	if uiTargetList then
		if changePageId then
			uiTargetList:RefreshList(list,false)
			local uiList = uiTargetList:GetList()
			uiList:RefreshList(UIListWrap.RefreshMode.Solid)
		else
			uiTargetList:RefreshData(list)
		end
	else
		uiTargetList = self:GetUIScroll("uiTargetList")
		self._uiTargetList = uiTargetList
		uiTargetList:Create(self.mTargetList,list,function(...) self:OnDrawTargetCell(...) end,UIItemList.WRAP,false)
		uiTargetList:EnableLoadAnimation(true, 0.03, 1, 2)
		local uiList = uiTargetList:GetList()
		uiList:RefreshList(UIListWrap.RefreshMode.Solid)
	end
end

function UIActNewYellSagaSow:PlayArrowBtnAni()
	if self.isPlayEffect then return  end
	self.isPlayEffect = not self.isPlayEffect
	local seqTween
	self:TweenSeqKill(self._effTimerKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._effTimerKey,function(seq)
			local showTime = 0.2
			local mRankArrowBtn = self.mRankArrowBtn
			local mRankBg = self.mRankBg
			local curRankArrowPos = mRankArrowBtn.localPosition
			local curRankBgPos = mRankBg.localPosition
			local arrowWidth = mRankArrowBtn.rect.width/2
			local rankBgWidth = mRankBg.rect.width
			local curRankBgPosX = curRankBgPos.x
			local arrowX,rankBgX,rotateZ
			if curRankBgPosX < -320 then
				arrowX,rankBgX = screenWidth - rankBgWidth - arrowWidth,self._rankBgX + rankBgWidth
				rotateZ = 0
			else
				arrowX,rankBgX = screenWidth - arrowWidth,self._rankBgX - rankBgWidth
				rotateZ = 180
			end
			printInfoNR("arrowX,rankBgX,rotateZ = ",arrowX,rankBgX,rotateZ)
--[[			local tween = mRankArrowBtn:DOLocalMove(Vector2(-arrowX,curRankArrowPos.y),showTime)
			seq:Join(tween)]]
			local tween = mRankArrowBtn:DOLocalRotate(Vector3(0,0,rotateZ),showTime)
			seq:Join(tween)
			tween = mRankBg:DOLocalMove(Vector2(rankBgX,curRankBgPos.y),showTime)
			seq:Join(tween)
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self._arrowX = self.mRankArrowBtn.localPosition.x
		self._rankBgX = self.mRankBg.localPosition.x
		self:TweenSeqKill(self._effTimerKey)
		self.isPlayEffect = not self.isPlayEffect
	end)
end

function UIActNewYellSagaSow:IsBuyNumEmpty(itemdata)
	local buyNum = itemdata.buyNum
	return buyNum > 0
end

function UIActNewYellSagaSow:InitData()
	self._func = self:GetWndArg("func")
	self._sid = self:GetWndArg("sid")
    if not self._sid then
        local subpage= self:GetWndArg("subPage") --支持跳转
        if subpage then
            self._sid = gModelActivity:GetSidByUniqueJump(subpage)
        end
    end
	local page = self:GetWndArg("page")
	page = page or UIActNewYellSagaSow.TYPE_STAGEVIEW
	self._page = page
	self._lastView = nil
	self._page3PageId = nil
	self._pageBtnList = {
		[UIActNewYellSagaSow.TYPE_STAGEVIEW] = {
			page = UIActNewYellSagaSow.TYPE_STAGEVIEW,
			btnRoot = self.mStageBtn,
			notSelBtnRoot = self.mStageIcon,
			selBtnRoot = self.mStageSelIcon,
			btnNameRoot = self.mStageBtnName,
			selBtnNameRoot = self.mStageBtnSelName,
			btnName = ccClientText(),
			root = self.mStageView,
			bgTrans = self.mStageViewBg,
			selImg = self.mStageSel,
			func = function() self:RefreshStageView() end,
		},
		[UIActNewYellSagaSow.TYPE_GIFTVIEW] = {
			page = UIActNewYellSagaSow.TYPE_GIFTVIEW,
			btnRoot = self.mGiftBtn,
			notSelBtnRoot = self.mGiftIcon,
			selBtnRoot = self.mGiftSelIcon,
			btnNameRoot = self.mGiftBtnName,
			selBtnNameRoot = self.mGiftBtnSelName,
			btnName = ccClientText(),
			root = self.mGiftView,
			bgTrans = self.mGiftViewBg,
			selImg = self.mGiftSel,
			func = function() self:RefreshGiftView() end,
		},
		[UIActNewYellSagaSow.TYPE_WALLVIEW] = {
			page = UIActNewYellSagaSow.TYPE_WALLVIEW,
			btnRoot = self.mWallBtn,
			notSelBtnRoot = self.mWallIcon,
			selBtnRoot = self.mWallSelIcon,
			btnNameRoot = self.mWallBtnName,
			selBtnNameRoot = self.mWallBtnSelName,
			btnName = ccClientText(),
			root = self.mWallView,
			bgTrans = self.mWallViewBg,
			selImg = self.mWallSel,
			func = function() self:RefreshWallView() end,
		},
		[UIActNewYellSagaSow.TYPE_PAEANVIEW] = {
			page = UIActNewYellSagaSow.TYPE_PAEANVIEW,
			btnRoot = self.mPaeanBtn,
			notSelBtnRoot = self.mPaeanIcon,
			selBtnRoot = self.mPaeanSelIcon,
			btnNameRoot = self.mPaeanBtnName,
			selBtnNameRoot = self.mPaeanBtnSelName,
			btnName = ccClientText(),
			root = self.mPaeanView,
			bgTrans = self.mPaeanViewBg,
			selImg = self.mPaeanSel,
			func = function() self:RefreshPaeanView() end,
		},
	}
	self._callBtnList = {
		[UIActNewYellSagaSow.CALL_ONE] = {
			callType = UIActNewYellSagaSow.CALL_ONE,
			btnTrans = self.mOneCallBtn,
			btnNameTrans = self.mOneCallBtnName,
			div = self.mOnePayDiv,
			iconTrans = self.mOnePayIcon,
			numTrans = self.mOnePayNum,
			btnNameTxtId = 20800,
		},
		[UIActNewYellSagaSow.CALL_TEN] = {
			callType = UIActNewYellSagaSow.CALL_TEN,
			btnTrans = self.mTenCallBtn,
			btnNameTrans = self.mTenCallBtnName,
			div = self.mTenPayDiv,
			iconTrans = self.mTenPayIcon,
			numTrans = self.mTenPayNum,
			btnNameTxtId = 20801,
		},
	}
	self._arrowX = self.mRankArrowBtn.localPosition.x
	self._rankBgX = self.mRankBg.localPosition.x

    self._myRankNewDivY = self.mMyRankNewMask.localPosition.y
	self._myRankNewDivHeight = self.mMyRankNewMask.rect.height

	self._rankScoreImgList = {
		[1] = "public_num_1",
		[2] = "public_num_2",
		[3] = "public_num_3",
	}
end

function UIActNewYellSagaSow:ShowReportEvent()
	local mySelect = self._mySelect
	if mySelect <= 0 then return end
	local wishHeroKeyList = self._wishHeroKeyList
	if not wishHeroKeyList then return end
	local wishHeroSelData = wishHeroKeyList[mySelect]
	if not wishHeroSelData then return end
	local report = wishHeroKeyList[mySelect].report
	if not report then return end
	printInfoNR("=========== 战报id = " .. report)
	--gModelGeneral:RecordHistroyWndList()
	--gLFightManager:ClearNonBattleWnd(LCombatTypeConst.COMBAT_BATTLE_VIDEO_SIMULATION,nil)
	self._func = nil
	--gModelBattle:OnClickShamBattle(report,function()
	--	FireEvent(EventNames.OPEN_HISTROY_WND)
	--end)
	gModelBattle:OnClickShamBattle(report)
end

function UIActNewYellSagaSow:InitRankList(listTrans,emptyTxtTrans)
	local list = self:GetRankList()
	local isEmpty = #list < 1
	CS.ShowObject(emptyTxtTrans,isEmpty)
	local key = listTrans:GetInstanceID()
	local uiRankList = self:FindUIScroll(key)
	if uiRankList then
		uiRankList:RefreshList(list)
	else
		uiRankList = self:GetUIScroll(key)
		uiRankList:Create(listTrans,list,function(...) self:OnDrawRankCell(...) end)
	end
end

function UIActNewYellSagaSow:GetRankServerDataList()
	return gModelRank:GetRankListInfo(UIActNewYellSagaSow.TYPE_RANK,self._rankId)
end

function UIActNewYellSagaSow:CreateHeroSpine(heroRefId,star,prefabName)
	local uiHeroObjList = self._uiHeroObjList
	if not uiHeroObjList then
		uiHeroObjList = {}
		self._uiHeroObjList = uiHeroObjList
	end
	local newUIHeroObj = uiHeroObjList[heroRefId]
	local oldUIHeroObj = self._curUIHeroObj
	if oldUIHeroObj and newUIHeroObj ~= oldUIHeroObj then
		oldUIHeroObj:ShowHero(false)
	end
	if not newUIHeroObj then
		newUIHeroObj = LUIHeroObject:New(self)
		uiHeroObjList[heroRefId] = newUIHeroObj
		self._curUIHeroObj = newUIHeroObj
		newUIHeroObj:Create(self.mHeroSpPos,heroRefId,prefabName)
		newUIHeroObj:SetScale(2)
		--newUIHeroObj:SetClickFunc(function(...) self:OnClickHeroSpine(...) end)
		newUIHeroObj:SetHeroData(nil,heroRefId,star,nil,true)
		newUIHeroObj:ShowHero(true)
		newUIHeroObj:StartLoad()
	else
		self._curUIHeroObj = newUIHeroObj
		newUIHeroObj:SetHeroData(nil,heroRefId,star,nil,true)
		newUIHeroObj:ShowHero(true)
	end
end

function UIActNewYellSagaSow:OnDrawWallBtnCell(list,item,itemdata,itempos)
	local Icon = self:FindWndTrans(item,"Icon")
	local UIText = self:FindWndTrans(item,"UIText")
	local SelIcon = self:FindWndTrans(item,"SelIcon")
	local SelUIText = self:FindWndTrans(item,"SelUIText")
	local redPoint = self:FindWndTrans(item,"redPoint")
	local Btn = self:FindWndTrans(item,"Btn")
	local pageId = itemdata.pageId
	local btnName = itemdata.btnName
	local btnImg = itemdata.btnImg
	local pageBg = itemdata.pageBg
	local showSel = self._page3PageId == pageId

	self:SetWndText(UIText,btnName)
	self:SetWndEasyImage(Icon,btnImg)

	CS.ShowObject(SelIcon,showSel)
	CS.ShowObject(SelUIText,showSel)

	self:SetWndText(SelUIText,btnName)
	self:SetWndEasyImage(SelIcon,btnImg)

	self:SetWndClick(Btn,function()
		self:ClickWallBtnEvent(itemdata)
	end)
	local showRedPoint = self:GetWallRedPointStatusByPageId(pageId)
	CS.ShowObject(redPoint,showRedPoint)
end

function UIActNewYellSagaSow:AddItemEvent(refId)
    printInfoNR("======= refId = " .. refId)
    gModelGeneral:OpenGetWayWnd({itemId = refId,srcWnd = self:GetWndName()})
end

function UIActNewYellSagaSow:InitCustomList()
	local list = self:GetCustomList()
	local uiSelGiftList = self._uiSelGiftList
	if uiSelGiftList then
		uiSelGiftList:RefreshData(list)
	else
		uiSelGiftList = self:GetUIScroll("uiSelGiftList")
		self._uiSelGiftList = uiSelGiftList
		uiSelGiftList:Create(self.mSelGiftList,list,function(...) self:OnDrawCustomCell(...) end,UIItemList.WRAP)
		uiSelGiftList:EnableLoadAnimation(true, 0.03, 1, 2)
		local uiList = uiSelGiftList:GetList()
		uiList:RefreshList(UIListWrap.RefreshMode.Solid)
	end
end

function UIActNewYellSagaSow:CreateTime()
	self:TimerStop(self._timerKey)
	self:TimerStart(self._timerKey,1,false,-1)
end

function UIActNewYellSagaSow:RefreshWallView()
	self:CreateWallBtnList()
end

function UIActNewYellSagaSow:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mProbBtn,function()
		local probInfo = self._probInfo
		if not probInfo then return end
		local title,desc = probInfo.title,probInfo.desc
		GF.OpenWnd("UIBzTips",{title = title,text = desc,bTransWarp = true})
	end)
	for k,v in pairs(self._pageBtnList) do
		self:SetWndClick(v.btnRoot,function()
			self:OnClickBotBtnEvent(v)
		end,LSoundConst.CLICK_PAGE_COMMON)
	end
	for k,v in pairs(self._callBtnList) do
		self:SetWndClick(v.btnTrans,function()
			self:CallEvent(v.callType)
		end)
	end
	self:SetWndClick(self.mSelHeroBtn,function() self:OpenActivitySel() end)
	self:SetWndClick(self.mChangeSelHeroBtn,function() self:OpenActivitySel() end)
	self:SetWndClick(self.mLogBtn,function()
		if not self._sid then return	end
		GF.OpenWnd("UIYellLog",{sid = self._sid,callType = 3,maxNum = self._journalNumMax})
	end)
	self:SetWndClick(self.mPreViewBtn,function() self:ShowReportEvent() end)
	self:SetWndClick(self.mPaeanViewExchBtn,function() self:GoToExchFunc() end)
	self:SetWndClick(self.mPaeanViewGetBtn,function() self:OpenGetWayWnd() end)
	self:SetWndClick(self.mPaeanItemBg,function() self:OpenGetWayWnd() end)
	self:SetWndClick(self.mRankBg,function() self:OpenRankWnd() end)
	self:SetWndClick(self.mRankArrowBtn,function() self:PlayArrowBtnAni() end)


	self:SetWndClick(self.mRankBgBtn,function() self:OpenRankWnd() end)
	self:SetWndClick(self.mMyRankNewDivBtn,function() self:OpenRankWnd() end)
	self:SetWndClick(self.mRankNewArrowBtnBg,function() self:OnClickRankNewArrowBtnBgFunc() end)
end

function UIActNewYellSagaSow:SendRankReq()
	if not self._rankId then return end
	if not self._sid then return end
	gModelRank:OnRankReq(UIActNewYellSagaSow.TYPE_RANK,self._rankId,1,25,self._sid)--排行榜请求
end

function UIActNewYellSagaSow:OnClickRankNewArrowBtnBgFunc()
    if self._runRankNewArrowStatus then return end
    self:RunRankNewArrowAni()
end

function UIActNewYellSagaSow:CommonBuyEvent(itemdata)
	local expendType = self:GetCommonExpendType(itemdata)
	local pageId,entryId = itemdata.pageId,itemdata.entryId
	local expend2 = itemdata.expend2
	local expend2Info =  string.split(expend2,"=")
	if expend2 == "" then
		expendType = UIActNewYellSagaSow.TYPE_BUY_FREE
	end
	local itemId = tonumber(expend2Info[2])
	local callFunc
	local setTextStr
	local isFreeBuy = expendType == UIActNewYellSagaSow.TYPE_BUY_FREE
	if expendType == UIActNewYellSagaSow.TYPE_BUY_FREE then
		callFunc = function()
			gModelActivity:OnActivityMarkeyBuyReq(self._sid,pageId,entryId)
		end
		setTextStr = ccClientText(11913)
	elseif expendType == UIActNewYellSagaSow.TYPE_BUY_ITEM then
		callFunc = function()
			local dia = gModelItem:GetNumByRefId(itemId)
			local itemName = gModelItem:GetNameByRefId(itemId)
			local value = tonumber(expend2Info[3])
			-- 钻石购买
			local func = function()
				if dia >= value then
					gModelActivity:OnActivityMarkeyBuyReq(self._sid,pageId,entryId)
				else
					gModelGeneral:OpenGetWayWnd({itemId = itemId})
				end
			end
			GF.OpenWnd("UIOrdinTip",{refId = 110005,func = func,para = {value .. itemName}, consume = {value, itemId}})
		end
		setTextStr = tonumber(expend2Info[3])
	elseif expendType == UIActNewYellSagaSow.TYPE_BUY_RMB then
		local expendId = tonumber(expend2Info[1])
		--local rmb = gModelPay:GetRMBValueByWelfareId(expendId)
		setTextStr =gModelPay:GetShowByWelfareId(expendId) -- string.replace(ccClientText(15601),rmb)
		callFunc = function()
			gModelPay:GiftPayCtrl(entryId,expendId,ModelPay.PAY_TYPE_ACTIVITY,nil,self._sid,pageId)
		end
	end
	local buyNum = itemdata.buyNum
	local buyCountText = string.replace(ccClientText(23803), buyNum)
	local showItemList
	if itemdata.isSel then
		showItemList = itemdata.getItemList
	else
		showItemList = itemdata.fixReward
	end
	GF.OpenWnd("UIGiftBuyPop", {
		title = itemdata.title,
		desc = buyCountText,
		payStr = setTextStr,
		payItemId = not isFreeBuy and itemId or nil,
		payFunc = callFunc,
		itemList = showItemList,
	})
end

function UIActNewYellSagaSow:InitRankRewardList(listTrans,list)
	local key = listTrans:GetInstanceID()
	local uiRewardList = self:FindUIScroll(key)
	if uiRewardList then
		uiRewardList:RefreshList(list)
	else
		uiRewardList = self:GetUIScroll(key)
		uiRewardList:Create(listTrans,list,function(...) self:OnDrawRewardCell(...) end)
	end
	local enable = #list > 3
	uiRewardList:EnableScroll(enable,true)
end

function UIActNewYellSagaSow:OnDrawTargetCell(list,item,itemdata,itempos)
	local height = item.sizeDelta.y
	LxUiHelper.SetSizeWithCurAnchor(item, 1, height)


	local DescTxt = self:FindWndTrans(item,"DescTxt")
	local NotDescTxt = self:FindWndTrans(item,"NotDescTxt")
	local Txt = self:FindWndTrans(item,"Txt")
	local rewardList = self:FindWndTrans(item,"RewardList")
	local btn = self:FindWndTrans(item,"btn")
	local text = self:FindWndTrans(btn,"text")

	local DiscountImg = self:FindWndTrans(item,"DiscountImg")
	local DiscountTxt = self:FindWndTrans(DiscountImg,"DiscountTxt")
	CS.ShowObject(DiscountImg,false)

	local Show = self:FindWndTrans(item,"Show")

	local items = itemdata.items
	self:CreateSelGiftList(rewardList,items)

	self:SetWndText(Txt,itemdata.title)
	local status = itemdata.status
	local isGet = status == 2
	local txt = ""
	local showEff = false
	local effKey = item:GetInstanceID()
	self:DestroyWndEffectByKey(effKey)
	if not isGet then
        local btnImg = "public_btn_2_1"
		if status == 0 then
			local jumpDesc = itemdata.jumpDesc
			txt = jumpDesc ~= "" and jumpDesc or ccClientText(12217)
		elseif status == 1 then
            btnImg = "public_btn_2_2"
			showEff = true
			txt = ccClientText(12207)
			self:CreateWndEffect(btn,UIActNewYellSagaSow.BTN_EFFECT_NAME,effKey,100,false,false,10)
		end
		self:SetWndText(text,txt)
        self:SetBtnImageAndMat(btn,btnImg,text)
		--self:SetImageActorState(btn,status)
	end
	CS.ShowObject(Show,isGet)
	CS.ShowObject(btn,not isGet)

	local schedules = itemdata.goalData.schedules[1]
	local goal,schedule = schedules.goal,schedules.schedule
	local str = schedule .. "/" .. goal
	local finsh = schedule == goal or false
	self:SetWndText(NotDescTxt,str)
	CS.ShowObject(NotDescTxt,not finsh)
	self:SetWndText(DescTxt,str)
	CS.ShowObject(DescTxt,finsh)
	self:SetWndClick(btn,function() self:OnClickEntry(itemdata) end)
end

function UIActNewYellSagaSow:BuyClick(itemdata,isSel)
	local canBuy = self:IsBuyNumEmpty(itemdata)
	if not canBuy then
		GF.ShowMessage(ccClientText(20811))
		return
	end
	if isSel then
		local fixReward = itemdata.fixReward or {}
		local costomGiftList = itemdata.customGiftList or {}
		local getItemList = itemdata.getItemList or {}
		local fixLen,costomLen,getItemLen = #fixReward,#costomGiftList,#getItemList
		local isSelFull = fixLen + costomLen == getItemLen
		local firstData = costomGiftList[1]
		if not isSelFull and firstData then
			GF.OpenWnd("UICumSelectNew",{
				sid = self._sid,pageId = firstData.pageId,entryId = firstData.entryId,
											 itemIndex = firstData.index,giftData = firstData,title = firstData.title,})
			return
		end
	end
	self:CommonBuyEvent(itemdata)
end

function UIActNewYellSagaSow:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if self._sid ~= sid then return end
		self:OnActivityConfigData()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (...) self:OnActivityListResp(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (...) self:OnActivityPageResp(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivitySelectDropGiftResp, function() self:RefreshCallFunc() end)
	self:WndNetMsgRecv(LProtoIds.ActivityDropGiftResp, function() self:RefreshCallFunc() end)
	self:WndEventRecv(EventNames.RANK_UPDATE_END,function (rankType,rankRefId)
		if rankRefId ~= self._rankId then return end
		if self._page ~= UIActNewYellSagaSow.TYPE_STAGEVIEW then return end
		self:RefreshRank()
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function (rankType,rankRefId)
		self:RefreshNeedList()
		if self._page == UIActNewYellSagaSow.TYPE_STAGEVIEW then
			self:RefreshCallBtn()
		elseif self._page == UIActNewYellSagaSow.TYPE_PAEANVIEW then
			self:RefreshPaeanView()
		end
	end)
	self:WndNetMsgRecv(LProtoIds.ScrollResp,function (...) self:RefreshLogCellList() end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function ()
		gModelActivity:ReqActivityConfigData(self._sid)
		gModelActivity:OnActivityPageReq(self._sid)
	end)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function ()
		GF.CloseWndByName("UIActNewYellSaga")
		self._func = nil
	end)
end

function UIActNewYellSagaSow:RefreshLogCellList()
	self:TimerStop(self._logSlideTime)
	local list = gModelScroll:GetScrollInfoList(self._logKey,self._sid,ModelScroll.GET_ALL_INFO,true)
	local len = #list
	local showLog = len > 0
	CS.ShowObject(self.mLogSuper,showLog)
	if not showLog then return end
	local logCellList = self._logCellList
	if not logCellList then
		self:InitLogCellList()
	end
	local logIndex = 0
	for i,v in ipairs(logCellList) do
		local log = list[i]
		if log then
			self:SetLogItem(v,log,i)
			logIndex = logIndex + 1
		end
		CS.ShowObject(v,log ~= nil)
	end
	self._logIndex = logIndex
	if len == 2 then
		local item = logCellList[1]
		self:SetItemAlpha(item,0.6)
	elseif len > 2 then
		local item = logCellList[1]
		self:SetItemAlpha(item,0.3)
		item = logCellList[2]
		self:SetItemAlpha(item,0.6)
		item = logCellList[3]
		self:SetItemAlpha(item,0.8)
	end
	local poPos = UIActNewYellSagaSow.LOG_CELL_STAR_POS
	if logIndex == 1 then
		poPos = UIActNewYellSagaSow.LOG_CELL_STAR_POS
	elseif logIndex == 2 then
		poPos = 0
	else
		if logIndex > 3 then
			--[[			if not self:IsTimerExist(self._logSlideTime)then
                            self:TimerStart(self._logSlideTime,5,false,-1)
                        end]]

			self:InitLogCellList(true)
			printInfoNR("=== 定时器开启")
			self:TimerStart(self._logSlideTime,5,false,-1)
			return
		end
	end
	self:ChnageScrollPos(poPos)
end

function UIActNewYellSagaSow:RefreshRankBgDiv()
	self:InitRankList(self.mRankList,self.mEmptyListTxt)
end

function UIActNewYellSagaSow:OpenRankWnd()
--[[	local sid = self._sid
	local func = self._func
	local page = self._page
	self._func = nil
	GF.CloseWndByName("UIActNewYellSaga")
	GF.OpenWndBottom("UIRkPop",{refId = self._rankId,sid = self._sid,page = 1,rewardList = self._rewardList,callFunc = function()
		GF.OpenWnd("UIActNewYellSaga",{sid = sid})
		GF.OpenWnd("UIActNewYellSagaSow",{sid = sid,page = page,func = func})
	end})
	self:WndClose()]]
	GF.OpenWndBottom("UIRkPop",{refId = self._rankId,sid = self._sid,page = 1,rewardList = self._rewardList})
end

function UIActNewYellSagaSow:GetTargetList()
	local tSortList = {
		[0] = 2,
		[1] = 1,
		[2] = 3,
	}
	local list = {}
	if self._page3PageId then
		local activityData = self._activityData
		local pageData = activityData and activityData[self._page3PageId]
		if pageData then
			local entryList = pageData and pageData.entry
			if entryList then
				for i,v in ipairs(entryList) do
					table.insert(list,v)
				end
				table.sort(list,function(a,b)
					local status1,status2 = a.goalData.status,b.goalData.status
					if status1 == status2 then
						return a.sort < b.sort
					else
						return tSortList[status1] < tSortList[status2]
					end
				end)
			end
		end
	end
	return list
end

function UIActNewYellSagaSow:OpenGetWayWnd()
	local page4Info = self._page4Info
	if not page4Info then return end
	local itemId = page4Info.itemId
	gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = self:GetWndName()})
end

function UIActNewYellSagaSow:GetPayType(expendType,expend2)
	local txt,itemId
	local showIconImg = false
	if expendType == UIActNewYellSagaSow.TYPE_BUY_FREE then
		txt = ccClientText(11913)
	elseif expendType == UIActNewYellSagaSow.TYPE_BUY_ITEM then
		showIconImg = true
		local expend2Info =  string.split(expend2,"=")
		txt = expend2Info[3]
		itemId = tonumber(expend2Info[2])
	elseif expendType == UIActNewYellSagaSow.TYPE_BUY_RMB then
		--local rmb = gModelPay:GetRMBValueByWelfareId(tonumber(expend2))
		txt = gModelPay:GetShowByWelfareId(tonumber(expend2)) -- string.replace(ccClientText(15601),rmb)
	end
	return txt,showIconImg,itemId
end

function UIActNewYellSagaSow:InitLogCellList(reset)
	local initLogCellTransPosList = self._initLogCellTransPosList
	if not initLogCellTransPosList then
		initLogCellTransPosList = {}
		self._initLogCellTransPosList = initLogCellTransPosList
	end
	local logCellList = self._logCellList
	if not logCellList then
		logCellList = {}
		local cell
		local trans = self.mLogSuper
		for i = 1,UIActNewYellSagaSow.SHOW_LOG_CELL_NUM do
			cell = self:FindWndTrans(trans,"LogCell"..i)
			table.insert(initLogCellTransPosList,cell.anchoredPosition)
			table.insert(logCellList,cell)
		end
		self._logCellList = logCellList
	elseif logCellList and reset then
		logCellList = {}
		local cell
		local trans = self.mLogSuper
		for i = 1,UIActNewYellSagaSow.SHOW_LOG_CELL_NUM do
			cell = self:FindWndTrans(trans,"LogCell"..i)
			cell.anchoredPosition = initLogCellTransPosList[i]
			table.insert(logCellList,cell)
		end
		self._logCellList = logCellList
	end
end

function UIActNewYellSagaSow:RunRankNewArrowAni()
    self._runRankNewArrowStatus = true
    local effKey = self._arrowEffKey
    local seqTween
    self:TweenSeqKill(effKey)
	local time = 0.5
    local arrowEndTrans
    local changeArrowStatus
    local moveMyRankNewDivPosY
	local changeMyRankBgFromAlpha,changeMyRankBgToAlpha,changeRankBgNewHeight,changeArrowImgRotationZ,changAlphaTime
    local arrowStatus = self._arrowStatus
    if arrowStatus == UIActNewYellSagaSow.ARROW_SHRINK_STATUS then
        changeArrowStatus = UIActNewYellSagaSow.ARROW_UNFOLD_STATUS
        arrowEndTrans = self.mBgMaxArrowRoot
		moveMyRankNewDivPosY = 0
		changeMyRankBgFromAlpha = 0
		changeMyRankBgToAlpha = 1
		changeRankBgNewHeight = self._myRankNewDivHeight - 20
		changeArrowImgRotationZ = 0
		changAlphaTime = time
    elseif arrowStatus == UIActNewYellSagaSow.ARROW_UNFOLD_STATUS then
        changeArrowStatus = UIActNewYellSagaSow.ARROW_SHRINK_STATUS
        arrowEndTrans = self.mBgMinArrowRoot
		moveMyRankNewDivPosY = -self._myRankNewDivY
		changeMyRankBgFromAlpha = 1
		changeMyRankBgToAlpha = 0
		changeRankBgNewHeight = -self._myRankNewDivHeight + 20
		changeArrowImgRotationZ = 180
		changAlphaTime = time - 0.2
    end
    if not seqTween then
        seqTween = self:TweenSeqCreate(effKey,function(seq)
            local showArrowPosY = arrowEndTrans.localPosition.y
            local moveArrowTween = self.mRankNewArrowBtnBg:DOLocalMoveY(showArrowPosY,time)
            seq:Append(moveArrowTween)

			local myRankNewDivTrans = self.mMyRankNewDiv
			local canvasGroup = self:GetCanvasGroup(myRankNewDivTrans)
			local changeCanvasGroup = YXTween.TweenFloat(changeMyRankBgFromAlpha, changeMyRankBgToAlpha, changAlphaTime, function(ival)
				canvasGroup.alpha = ival
			end):SetEase(EaseInQuad)
			seq:Join(changeCanvasGroup)
			local changeRankNewDivPos = myRankNewDivTrans:DOLocalMoveY(moveMyRankNewDivPosY,time)
			seq:Join(changeRankNewDivPos)

			local mRankBgNew = self.mRankBgNew
			local curWidth = mRankBgNew.rect.width
			local curHeight = mRankBgNew.rect.height
			local newHeight = curHeight + changeRankBgNewHeight
			local changeRankBgHeightTween = YXTween.TweenFloat(curHeight, newHeight, time, function(ival)
				mRankBgNew.sizeDelta = Vector2.New(curWidth,ival)
			end):SetEase(EaseInQuad)
			seq:Join(changeRankBgHeightTween)

			local changeArrowImgRotationTween = self.mRankNewArrowImg:DORotate(Vector3.New(0, 0, changeArrowImgRotationZ), time)
			seq:Join(changeArrowImgRotationTween)

            return seq
        end)
    end
    seqTween:OnComplete(function()
        self._arrowStatus = changeArrowStatus
        self:TweenSeqKill(effKey)
        self._runRankNewArrowStatus = false
    end)
    seqTween:PlayForward()
end

function UIActNewYellSagaSow:OnDrawWishUpHeroSkill(list,item,itemdata,itempos)
	local Icon = self:FindWndTrans(item,"Hero")

	local iconPath = gModelHero:GetHeroIcon(itemdata,5)
	if LxUiHelper.IsImgPathValid(iconPath) then
		self:SetWndEasyImage(Icon, iconPath)
	end

	self:SetWndClick(item,function()
		self:OnClickWishUpHero()
	end)
end

function UIActNewYellSagaSow:RefreshGiftView()
	local activityData = self._activityData
	if not activityData then return end
	self:InitCustomList()
end

function UIActNewYellSagaSow:CreateCommonIcon(data)
	local instanceID = data.instanceID
	local trans = data.trans
	local itemType,itemId,itemNum = data.itemType, data.itemId, data.itemNum
	local baseClass = self._uiCommonList[instanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiCommonList[instanceID] = baseClass
		baseClass:Create(trans)
	end
	baseClass:SetCommonReward(itemType,itemId,itemNum)
	local showNum = itemNum > 0
	baseClass:EnableShowNum(showNum)
	baseClass:DoApply()
end

function UIActNewYellSagaSow:GetWallRedPointStatusByPageId(pageId)
	local status = false
	local activityData = self._activityData
	if not activityData then return status end
	local pageDataList = activityData[pageId]
	if pageDataList then
		for idx,val in ipairs(pageDataList.entry) do
			if val.status == 1 then
				status = true
				break
			end
		end
	end
	return status
end

function UIActNewYellSagaSow:GetCustomList()
	local list = {}
	local activityData = self._activityData
	if activityData then
		local sortFunc = function(a,b)
			local sellOut1,sellOut2 = a.sellOut,b.sellOut
			if sellOut1 ~= sellOut2 then
				return sellOut1 > sellOut2
			else
				return a.sort < b.sort
			end
		end

		local sid = self._sid
		local giftOptional = self._giftOptional or ModelActivity.GIFTOPTIONAL_0
		local selList = {}
		local pageId = ModelActivity.MODEL_NEWHEROCALL_TYPE_GIFT_SEL
		local pageData,entryList
		if gModelActivity:CheckGiftoptionalStatus(sid,giftOptional,pageId) then
			pageData = activityData[pageId] or {}
			entryList = pageData.entry or {}
			for i,v in ipairs(entryList) do
				local MarketData = v.MarketData
				local customListStr = string.split(MarketData.customList,"|")
				local customList = LxDataHelper.ParseItem(MarketData.customList)
				local len = #customListStr
				local customGiftList = LxDataHelper.ParseItem(MarketData.customGift) or {}
				local entryId = v.entryId
				local title = v.title
				local items = v.items
				local getItemList = {}
				table.insert(getItemList,items[1])
				local personal,personalGoal = MarketData.personal,MarketData.personalGoal
				local buyNum = personalGoal - personal
				local sellOut = buyNum > 0 and 1 or 0
				for idx = 1,len do
					local curData = customGiftList[idx]
					if not curData then
						customGiftList[idx] = {
							isEmpty = true,
							itemId = 0,
							itemNum = -1,
						}
					else
						table.insert(getItemList,curData)
					end
					customGiftList[idx].pageId = pageId
					customGiftList[idx].entryId = entryId
					customGiftList[idx].title = title
					customGiftList[idx].index = idx
					customGiftList[idx].selList = customList
					customGiftList[idx].MarketData = MarketData
					customGiftList[idx].isSel = true
					customGiftList[idx].canSel = buyNum > 0
				end
				table.insert(selList,{
					isSel = true,
					customGiftList = customGiftList,
					fixReward = items,
					entryId = entryId,
					sort = v.sort,
					title = title,
					pageId = pageId,
					icon = v.icon,
					personal = personal,
					personalGoal = personalGoal,
					buyNum = buyNum,
					expend1 = MarketData.expend1,
					expend2 = MarketData.expend2,
					expendType = MarketData.expendType,
					sellOut = sellOut,
					discount = MarketData.discount,
					getItemList = getItemList,
				})
			end
			table.sort(selList,sortFunc)
		end

		local shopList = {}
		pageId = ModelActivity.MODEL_NEWHEROCALL_TYPE_GIFT_SHOP
		if gModelActivity:CheckGiftoptionalStatus(sid,giftOptional,pageId) then
			local player = gModelPlayer:GetPlayerLv()
			local shopAllList = {}
			pageData = activityData[pageId] or {}
			entryList = pageData.entry or {}
			for i,v in ipairs(entryList) do
				local moreInfo = string.split(v.moreInfo,";")
				local showLv = moreInfo[2]
				local needShowLv = showLv and tonumber(showLv) or 0 --显示等级
				local ins = player >= needShowLv
				if ins then
					local valuePercent = moreInfo[3]
					local typeId = tonumber(moreInfo[4])		-- 类型ID=礼包卡底资源图=售卖文本字色=售卖文本描边色
					local MarketData = v.MarketData
					local personal,personalGoal = MarketData.personal,MarketData.personalGoal
					local buyNum = personalGoal - personal
					local sellOut = buyNum > 0 and 1 or 0

					local commonGiftList = {}
					for k,v in ipairs(v.items) do
						local curData = {
							itemId = v.itemId,
							itemType = v.itemType,
							itemNum = v.itemNum,
							notShowTips = true, --点击不显示道具tips，直接打开详情弹窗
						}

						table.insert(commonGiftList,curData)
					end

					table.insert(shopAllList,{
						fixReward = v.items,
						entryId = v.entryId,
						sort = v.sort,
						title = v.title,
						pageId = pageId,
						expend1 = MarketData.expend1,
						expend2 = MarketData.expend2,
						personal = personal,
						personalGoal = personalGoal,
						buyNum = buyNum,
						entryId = v.entryId,
						sellOut = sellOut,
						moreInfo = v.moreInfo,
						showLv = showLv,
						valuePercent = valuePercent,
						typeId = typeId,
						desc = v.desc,
						expendType = MarketData.expendType,
						commonGiftList = commonGiftList,
					})
				end
			end
			table.sort(shopAllList,sortFunc)

			local index = 1
			for i,v in ipairs(shopAllList) do
				local indexList = shopList[index]
				if not indexList then
					indexList = {}
					shopList[index] = indexList
				end
				table.insert(indexList,v)
				if i % 3 == 0 then
					index = index + 1
				end
			end
		end

		for i,v in ipairs(selList) do
			table.insert(list,v)
		end
		for i,v in ipairs(shopList) do
			table.insert(list,v)
		end
	end
	return list
end

function UIActNewYellSagaSow:OnActivityConfigData()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then return end
	local configDataList = self._configDataList
	if not configDataList then
		configDataList = {}
		self._configDataList = configDataList
	end
	local pageBtnList = self._pageBtnList

	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	local moreInfo = JSON.decode(activityData.moreInfo)

	self._aRank = tonumber(moreInfo.ascoreCond_8)
	self._aScore = tonumber(moreInfo.ascore_8)

	-- 显示需要的道具列表
	local showItemList = {}
	local showItem = string.split(moreInfo.showItem,";")
	for i,v in ipairs(showItem) do
		--v = string.split(v,"=")
		local refId = v
		table.insert(showItemList,{
			refId = tonumber(refId)
		})
	end
	self:InitNeedList(showItemList)

	local config = webData.config
	self._giftOptional = config.giftOptional

	self._config = config
	self:SetWndText(self.mCanGetTxt,config.tipsText)
	-- 底部栏按钮的名字和图标
	local btnIcon = string.split(config.btnIcon,";")
	for i,v in ipairs(btnIcon) do
		v = string.split(v,"=")
		local btnIdx = tonumber(v[1])
		local pageInfo = pageBtnList[btnIdx]
		if pageInfo then
			local btnName = v[2]
			local btnImg = v[3]
			local selBtnImg = v[4]
			self:SetWndEasyImage(pageInfo.notSelBtnRoot,btnImg)
			self:SetWndEasyImage(pageInfo.selBtnRoot,selBtnImg)
			self:SetWndText(pageInfo.btnNameRoot,btnName)
			self:SetWndText(pageInfo.selBtnNameRoot,btnName)
		end
	end

	self._journalNumMax = config.journalNumMax

	if not self._changeImg then
		self:SetWndEasyImage(self.mStageViewBg,config.activityPartyBgBig2)
		self:SetWndEasyImage(self.mGiftViewBg,config.activityPartyBgBig3)
		self:SetWndEasyImage(self.mWallViewBg,config.activityPartyBgBig4)
		self:SetWndEasyImage(self.mPaeanViewBg,config.activityPartyBgBig5)

		self:SetWndEasyImage(self.mGiftTitleImg,config.activityPartyText2,nil,true)
		self:SetWndEasyImage(self.mWallTitleImg,config.activityPartyText3,nil,true)
		self:SetWndEasyImage(self.mPaeanViewTitle,config.activityPartyText4,nil,true)

		self._changeImg = true
	end

	local numImgTrans
	if gLGameLanguage:IsEnglishVersion() then
		numImgTrans = self.mGetHeroNumImage
	elseif gLGameLanguage:IsGermanVersion() then
		numImgTrans = self.mGetHeroNumImageDe
	elseif gLGameLanguage:IsFrenchVersion() then
		numImgTrans = self.mGetHeroNumImageDe
	elseif gLGameLanguage:IsThaiVersion() then
		numImgTrans = self.mGetHeroNumImageTh
	elseif gLGameLanguage:IsJapanRegion() then
		numImgTrans = self.mGetHeroNumImageJa
	else
		numImgTrans = self.mGetHeroNumImage
	end
	CS.ShowObject(numImgTrans, true)
	local imagePos = config.imagePos
	if not string.isempty(imagePos) then
		self:SetAnchorPos(numImgTrans, LxDataHelper.ParseVector2NotEmpty(imagePos))
	end

	local btnText = string.split(config.btnText,"=")
    self._btnTextList = {}
    for i,v in ipairs(btnText) do
        table.insert(self._btnTextList,v)
    end

	-- 第3页分页标签列表
	local btnIcon3List = {}
	self._page3ChangeBgStatus = {} 				-- 图片替换状态
	local btnIcon3 = string.split(config.btnIcon3,";")
	for i,v in ipairs(btnIcon3) do
		v = string.split(v,"=")
		local pageId = tonumber(v[1])
		table.insert(btnIcon3List,{
			pageId = pageId, 					-- pageId
			btnName = v[2],						-- 按钮名字
			btnImg = v[3],						-- 按钮图标
			pageBg = v[4],						-- 对应的背景图
		})
		self._page3ChangeBgStatus[pageId] = false
	end
	self._page3Info = btnIcon3List

	-- 第1页数据
	self._page1Info = {}
	local callOne,callTen = {},{}
	local callInfo = {}
	callOne = LxDataHelper.ParseItem_3List(moreInfo.oneExpend,"|")
	callTen = LxDataHelper.ParseItem_3List(moreInfo.tenExpend,"|")
	-- 单次召唤
	--local oneExpend = string.split(moreInfo.oneExpend,"|")
	--for i,v in ipairs(oneExpend) do
	--	v = string.split(v,"=")
	--	table.insert(callOne,{
	--		itemType = tonumber(v[1]),
	--		itemId = tonumber(v[2]),
	--		itemNum = tonumber(v[3]),
	--	})
	--end
	-- 10次召唤
	--local tenExpend = string.split(moreInfo.tenExpend,"|")
	--for i,v in ipairs(tenExpend) do
	--	v = string.split(v,"=")
	--	table.insert(callTen,{
	--		itemType = tonumber(v[1]),
	--		itemId = tonumber(v[2]),
	--		itemNum = tonumber(v[3]),
	--	})
	--end
	callInfo[UIActNewYellSagaSow.CALL_ONE] = callOne
	callInfo[UIActNewYellSagaSow.CALL_TEN] = callTen
	self._page1Info.callInfo = callInfo

	local goodsOne = LxDataHelper.ParseItem_3List(moreInfo.goodsOne) --string.split(moreInfo.goodsOne,"=")
	self._page1Info.goodsOne = goodsOne
	--self._page1Info.goodsOne = {
	--	itemType = tonumber(goodsOne[1]),
	--	itemId = tonumber(goodsOne[2]),
	--	itemNum = tonumber(goodsOne[3]),
	--}

	local freeNum = moreInfo.freeNum
	local goodsTen =LxDataHelper.ParseItem_3List(moreInfo.goodsTen) -- string.split(moreInfo.goodsTen,"=")
	self._page1Info.goodsTen = goodsTen
	--self._page1Info.goodsTen = {
	--	itemType = tonumber(goodsTen[1]),
	--	itemId = tonumber(goodsTen[2]),
	--	itemNum = tonumber(goodsTen[3]),
	--}
	self._page1Info.freeNum = freeNum
	self._page1Info.nextRefreshTimeOfFreeNum = moreInfo.nextRefreshTimeOfFreeNum
	self._page1Info.nextRefreshTimeOfCallNum = moreInfo.nextRefreshTimeOfCallNum
	local wishUpHero = config.wishUpHero
	self._page1Info.wishUpHero = wishUpHero
	self._page1Info.wishUpTips = config.wishUpTips


--[[
	1. 新增key控制召唤界面是否显示“up英雄”
	--# key=wishUpShow；1=显示，0=不显示，没有key默认显示
]]
	self._page1Info.wishUpShow = config.wishUpShow or 1

	self._mySelect = moreInfo.mySelect
	self._mySelectHero = moreInfo.mySelectHero
	self._myDropNum = moreInfo.myDropNum
	self._freeNum = freeNum
	self._callNum = moreInfo.callNum
	self._rankId = moreInfo.rankId
	self._goldTimes = moreInfo.goldTimes

	self._showRankBgNew = moreInfo.showRankBgNew

	self:SetWndText(self.mGiftDescTxt,config.tips2)

	--处理概率提升英雄
	local wishUpHeroPoolKeyList = {}
	local wishUpValueRate = 1
	local poolId
	if not string.isempty(wishUpHero) then
		local wishUpHeroList = string.split(wishUpHero, ';')
		for k,v in ipairs(wishUpHeroList) do
			poolId = tonumber(v)
			wishUpHeroPoolKeyList[poolId] = true
		end

		local wishUpValue = config.wishUpValue or 0
		wishUpValueRate = 1 - wishUpValue
	end

	local inWishUpHeroPoolMap = {}
	local wishHeroList = {}
	local wishHeroKeyList = {}
	local wishHero = string.split(moreInfo.wishHero,";")
	local isInPool
	for i,v in ipairs(wishHero) do
		v = string.split(v,"=")
		poolId = tonumber(v[1])
		local minNum = tonumber(v[2])
		isInPool = wishUpHeroPoolKeyList[poolId] ~= nil
		if isInPool then
			minNum = minNum * wishUpValueRate
			inWishUpHeroPoolMap[poolId] = true
		end

		local data = {
			poolId = poolId,
			minNum = minNum,
			isInPool = isInPool,
		}
		wishHeroKeyList[poolId] = data
		table.insert(wishHeroList,data)
	end
	self._wishHeroList = wishHeroList
	self._inWishUpHeroPoolMap = inWishUpHeroPoolMap
	if not self._wishHeroKeyList then
		self._wishHeroKeyList = wishHeroKeyList
	end

	self._probInfo = {
		desc = config.desc,
		title = activityData.title,
	}

	self._page4Info = {
		descIcon5 = moreInfo.descIcon5,
		ruleIcon = moreInfo.ruleIcon,
		tipsDescription = config.tipsDescription,
		tipsTitle = moreInfo.tipsTitle,
		desBgBig = moreInfo.desBgBig,
		desBgSmall = moreInfo.desBgSmall,
		tipsTitleColor1 = moreInfo.tipsTitleColor1,
		tipsTitleColor2 = moreInfo.tipsTitleColor2,
		rewardShow = moreInfo.rewardShow,
		itemId = tonumber(moreInfo.itemId),
		shopId = moreInfo.shopId,
		sourceIcon = moreInfo.sourceIcon,
	}

    self._itemId = moreInfo.itemId

	local endTime = activityData.endTime
	if endTime == 0 then
		-- 永久生效
		self:SetWndText(self.mCountDonwTxt,"")
	else
		self._endTime = endTime
		self:CreateTime()
	end

	self:RefreshNumLimit()
end

function UIActNewYellSagaSow:OnDrawItemCell(list,item,itemdata,itempos)
	local Icon = self:FindWndTrans(item,"itemRoot/Icon")
	local itemNum = self:FindWndTrans(item,"itemNum")
	local Shift = self:FindWndTrans(item,"Shift")
	local Eff = self:FindWndTrans(item,"Eff")

	local itemType = itemdata.itemType
	local showShift = itemType ~= nil
	CS.ShowObject(Shift,showShift)
	local instanceID = Icon:GetInstanceID()
	local commonInfo = {
		instanceID = instanceID,
		trans = Icon,
		itemType = itemdata.itemType,
		itemId = itemdata.itemId,
		itemNum = -1,
	}
	self:CreateCommonIcon(commonInfo)
	local num = itemdata.itemNum
	local showNum = num > 0
	CS.ShowObject(itemNum,showNum)
	self:SetWndText(itemNum,LUtil.NumberCoversion(num))

	local notShowTips = itemdata.notShowTips --点击不显示道具tips
	if notShowTips then
		return
	end

	local isSel = itemdata.isSel
	local canSel = itemdata.canSel
	local status = itemdata.status
	self:SetWndClick(Icon,function()
		local notShowMsg = status ~= nil and status or false
		if not notShowMsg then
			if isSel and canSel then
				GF.OpenWnd("UICumSelectNew",{sid = self._sid,pageId = itemdata.pageId,entryId = itemdata.entryId,
												 itemIndex = itemdata.index,giftData = itemdata,title = itemdata.title,})
			else
				gModelGeneral:ShowCommonItemTipWnd(itemdata)
			end
		else
			--GF.ShowMessage(ccClientText(20811))

			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		end
	end)
end

function UIActNewYellSagaSow:GoToExchFunc()
	local sid = self._sid
	local page = self._page
	local func = self._func
	GF.CloseWndByName("UIActNewYellSaga")
	self._func = nil
	GF.OpenWndBottom("UIDian",{page = ModelShop.ACTIVITY,subPage = sid,func = function()
		local activityData = gModelActivity:GetActivityBySid(sid)
		if activityData then
			if activityData.status ~= 3 then
				GF.OpenWnd("UIActNewYellSaga",{sid = sid})
				GF.OpenWnd("UIActNewYellSagaSow",{sid = sid,page = page,func = func})
			else
				GF.ShowMessage(ccClientText(14301))
			end
		end
	end})
	self:WndClose()
end

function UIActNewYellSagaSow:GetCanvasGroup(trans)
	local canvasGroup = trans:GetComponent(typeofCanvasGroup)
	if not canvasGroup then
		canvasGroup = trans.gameObject:AddComponent(typeofCanvasGroup)
	end
	return canvasGroup
end

function UIActNewYellSagaSow:RefreshMyInfoDiv(rank,score)
	local rankNumTxt = ""
	local scoreNumTxt = ""
	local isEmpty = false
	if rank and score then
		if rank == -1 then
			rankNumTxt = ccClientText(20868)
		else
			rankNumTxt = rank
		end
		scoreNumTxt = LUtil.NumberCoversion(score)
		local rewardList = self._rewardList
		if rewardList then
			local selfAward
			local rankInfo,left,right
			for i,v in ipairs(rewardList) do
				rankInfo = v.rank
				left = rankInfo[1]
				right = rankInfo[2]
				if left <= rank and rank <= right then
					selfAward = v.reward
				end
			end
			if selfAward then
				local len = #selfAward
				local isShowMore = len > 3
				local showUIList = isShowMore and self.mRankRewardMoreList or self.mRankRewardList
				local hideUIList = isShowMore and self.mRankRewardList or self.mRankRewardMoreList
				CS.ShowObject(showUIList,true)
				CS.ShowObject(hideUIList,false)
				self:InitRankRewardList(showUIList,selfAward)
			else
				isEmpty = true
			end
		else
			isEmpty = true
		end
	else
		isEmpty = true
		rankNumTxt = ccClientText(20868)
		scoreNumTxt = 0
	end
	self:SetWndText(self.mMyRankNewNum,rankNumTxt)
	self:SetWndText(self.mMyScoreNewNum,scoreNumTxt)

	CS.ShowObject(self.mRankRewardDiv,not isEmpty)
	CS.ShowObject(self.mRankNotRewardDiv,isEmpty)
end

function UIActNewYellSagaSow:OnWndRefresh()
	local page = self:GetWndArg("page")
	page = page or UIActNewYellSagaSow.TYPE_STAGEVIEW
	self._page = page
	self:ShowWnd()
end

function UIActNewYellSagaSow:InitTxt()
	self:SetWndText(self.mLogBtnName,ccClientText(20804))
	self:SetWndText(self.mProbBtnName,ccClientText(20805))
	self:SetWndText(self.mPreViewBtnName,ccClientText(20806))
	self:SetWndText(self.mStageSelHeroDesc,ccClientText(20807))
	self:SetWndText(self.mEmptyListTxt,ccClientText(20808))
	self:SetWndText(self.mReturnBtnName, ccClientText(20812))
	--self:SetWndText(self.mCanGetTxt, ccClientText(20813))
--[[	local uiHyperText = UIHyperText:New()
	uiHyperText:Create(self.mLookMoreTxt)
	local skillTitle = ccClientText(20803)
	skillTitle = uiHyperText:AddHyper(skillTitle,{func = function()
		self:OpenRankWnd()
	end})
	self:SetWndText(self.mLookMoreTxt,skillTitle)]]

	self:SetWndText(self.mLookMoreTxt,ccClientText(20803))

	local text = self:FindWndTrans(self.mPaeanViewExchBtn,"text")
	if text then
		self:SetWndText(text,ccClientText(13265))
	end

	self:SetWndText(self.mRankNewTxt,ccClientText(20863))
	self:SetWndText(self.mRankNewEmptyListTxt,ccClientText(20808))
	self:SetWndText(self.mMyRankNewDesc,ccClientText(20864))
	self:SetWndText(self.mMyScoreNewDesc,ccClientText(20865))
	self:SetWndText(self.mMyRankRewardDesc,ccClientText(20866))
	self:SetWndText(self.mRankNotRewardDesc,ccClientText(20869))
	self:SetWndText(self.mRankNotRewardLookDesc,ccClientText(20867))
end

function UIActNewYellSagaSow:InitNeedList(list)
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

function UIActNewYellSagaSow:OnClickWishUpHero()
	if not self._page1Info then return end
	local wishUpTips = self._page1Info.wishUpTips
	if not wishUpTips or wishUpTips == 0 then return end

	local title = self._probInfo.title
	GF.OpenWnd("UIBzTips",{title = title,text = wishUpTips,bTransWarp = true})
end

function UIActNewYellSagaSow:OnClickEntry(itemdata)
	local status = itemdata.status
	if status == 0 then
		if self._isEnd then
			local str =ccClientText(14301) --"活动已结束"
			GF.ShowMessage(str)
			return
		end
		local jumpId = tonumber(itemdata.jumpId)
		if jumpId and jumpId > 0 then
			printInfoNR("jumpId = "..jumpId)
			local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId,true)
			if isOpen then
				self._func = nil
				gModelFunctionOpen:Jump(jumpId,nil,function()
					if self._sid then
						gModelActivity:OnActivityPageReq(self._sid)
					end
				end)
			end
		else
			GF.ShowMessage(ccClientText(14303)) --"任务未完成，无法领取"
		end
	elseif status == 1 then
		local sid = self._sid
		local pageId = itemdata.pageId
		local entryId = itemdata.entryId
		gModelActivity:OnActivityReceiveGoalReq(sid,pageId,entryId)
	elseif status == 2 then
		GF.ShowMessage(ccClientText(12208))
	end
end

function UIActNewYellSagaSow:RefreshRankBgNewDiv()
	self:InitRankList(self.mRankNewList,self.mRankNewEmptyListTxt)
end

function UIActNewYellSagaSow:CreateCustom(trans,itemdata)
	local OverImg = self:FindWndTrans(trans,"OverImg")

	local FixReward = self:FindWndTrans(trans,"FixReward")
	local itemRoot = self:FindWndTrans(FixReward,"itemRoot")
	local itemNum = self:FindWndTrans(FixReward,"itemNum")

	local RewardList = self:FindWndTrans(trans,"RewardList")

	local BuyBtn = self:FindWndTrans(trans,"BuyBtn")
	local Eff = self:FindWndTrans(BuyBtn,"Eff")
	local RedPoint = self:FindWndTrans(BuyBtn,"RedPoint")
	local AutoDiv = self:FindWndTrans(BuyBtn,"AutoDiv")
	local Image = self:FindWndTrans(AutoDiv,"Image")
	local BuyBtnTxt = self:FindWndTrans(AutoDiv,"Txt")
	local DiscountImg = self:FindWndTrans(trans,"DiscountImg")
	local DiscountTxt = self:FindWndTrans(DiscountImg,"DiscountTxt")

	local TitleImg = self:FindWndTrans(trans,"TitleImg")
	local Txt = self:FindWndTrans(trans,"TxtBg/Txt")

	local CountDownTxt = self:FindWndTrans(trans,"CountDownTxt")

	self:SetWndEasyImage(TitleImg,itemdata.icon)
	self:SetWndText(Txt,itemdata.title)

	local buyNum = itemdata.buyNum
	local buyCountText = string.replace(ccClientText(20810), buyNum)
	self:SetWndText(CountDownTxt,buyCountText)

	local instanceID = FixReward:GetInstanceID()
	local fixReward = itemdata.fixReward[1]
	local commonInfo = {
		instanceID = instanceID,
		trans = itemRoot,
		itemType = fixReward.itemType,
		itemId = fixReward.itemId,
		itemNum = -1,
	}
	self:CreateCommonIcon(commonInfo)
	self:SetWndText(itemNum,LUtil.NumberCoversion(fixReward.itemNum))

	local isEmpty = buyNum < 1
	local show = not isEmpty

	self:SetWndClick(FixReward, function()
--[[		if isEmpty then
			GF.ShowMessage(ccClientText(20811))
		else
			gModelGeneral:ShowCommonItemTipWnd(fixReward)
		end]]
		gModelGeneral:ShowCommonItemTipWnd(fixReward)
	end)

	local customGiftList = self:ChangeCustomList(itemdata.customGiftList,isEmpty)
	self:CreateSelGiftList(RewardList,customGiftList)


	CS.ShowObject(OverImg,isEmpty)
	CS.ShowObject(BuyBtn,show)
	CS.ShowObject(CountDownTxt,show)

	local expendType = itemdata.expendType
	local expend2 = itemdata.expend2
	local txt,showIconImg,itemId = self:GetPayType(expendType,expend2)
	if showIconImg and itemId then
		local icon = gModelItem:GetItemImgByRefId(itemId)
		self:SetWndEasyImage(Image,icon)
	end
	CS.ShowObject(Image,showIconImg)
	self:SetWndText(BuyBtnTxt,txt)

	local effKey = trans:GetInstanceID()
	self:DestroyWndEffectByKey(effKey)
	local isFree = expendType == UIActNewYellSagaSow.TYPE_BUY_FREE
	if isFree then
		if show then
			self:CreateWndEffect(Eff,UIActNewYellSagaSow.BTN_EFFECT_NAME,effKey,100,false,false,10)
		end
		CS.ShowObject(RedPoint,show)
	end
	CS.ShowObject(RedPoint,show and isFree)

	local discount = itemdata.discount
	local showDis = discount > 0
	if showDis then
		self:SetWndText(DiscountTxt, discount.."%")
	end
	CS.ShowObject(DiscountImg,showDis)

	self:SetWndClick(BuyBtn, function()
		self:BuyClick(itemdata,true)
	end, LSoundConst.CLICK_BUTTON_COMMON)
end

function UIActNewYellSagaSow:RefreshView()
	self:RefreshBtnStatus()
	local page = self._page
	local btnInfo = self._pageBtnList and self._pageBtnList[page]
	if btnInfo then
		if self._lastView then
			CS.ShowObject(self._lastView,false)
		end
		local root = btnInfo.root
		self._lastView = root
		CS.ShowObject(self._lastView,true)
		local func = btnInfo.func
		if func then func() end
	end
end

function UIActNewYellSagaSow:RefreshRank()
	local showRankType = self._showRankBgNew or UIActNewYellSagaSow.USE_NEW_RANK
	local showRankBgNew = showRankType == 1
	CS.ShowObject(self.mRankBg,not showRankBgNew)
	CS.ShowObject(self.mRankBgNew,showRankBgNew)
	if showRankBgNew then
		self:RefreshRankBgNewDiv()
	else
		self:RefreshRankBgDiv()
	end
end

function UIActNewYellSagaSow:OnDrawRewardCell(list,item,itemdata,itempos)
	local IconTrans = self:FindWndTrans(item,"CommonUI/Icon")
	local NumTxtTrans = self:FindWndTrans(item,"NumTxt")
	local itemType,itemId,itemNum = itemdata.itemType,itemdata.itemId,itemdata.itemNum
	local instanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(IconTrans)
	baseClass:SetCommonReward(itemType,itemId,itemNum)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()
	self:SetWndText(NumTxtTrans,LUtil.NumberCoversion(itemNum))

	self:SetWndClick(IconTrans,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
end
------------------------------------------------------------------
return UIActNewYellSagaSow


