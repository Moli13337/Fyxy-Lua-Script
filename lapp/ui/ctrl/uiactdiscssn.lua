---
--- Created by Administrator.
--- DateTime: 2023/10/19 16:44:21
---
---活动42-皮肤礼包
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActDiscsSn:LWnd
local UIActDiscsSn = LxWndClass("UIActDiscsSn", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActDiscsSn:UIActDiscsSn()
	self._starList = {}
	self._timeList = {}
	self._pageData = {}
	self._uiIconEasyList = {}
	self._uiCommonList = {}
	self._spineKeyList = {}
	self._giftTransList = {}
	self._uiRewardList = {}
	self._effectKeyList ={}
	self._heroEffectKeyList ={}
	self._key = 1
	self._giftIndex = 1
	self._distance = 150
	self._endTime = 0
	self._moveTime = 0.25
	self._bDrag = true
	self._bMove = true
	self._timeKey = "timeKey"
	self._dragKey = "_dragKey"
	self._moveKey = "_moveKey"
	self._timeSoundKey = "_timeSoundKey"


	self._needLoadSpineCnt = 0
	self._curLoadSpineCnt = 0
	---@type LDisplaySpine[]
	self._loadSpineTransList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActDiscsSn:OnWndClose()
	self:ClearCommonIconList(self._uiIconEasyList)
	self._uiIconEasyList = {}

	self:ClearCommonIconList(self._uiCommonList)
	self._uiCommonList = {}

	if self._uiRewardList then
		for k, v in pairs(self._uiRewardList) do
			v:Destroy()
		end
		self._uiRewardList = {}
	end

	for k,v in pairs(self._effectKeyList) do
		self:DestroyWndEffectByKey(v)
	end
	self._effectKeyList={}

	for k,v in pairs(self._heroEffectKeyList) do
		self:DestroyWndEffectByKey(v)
	end
	self._heroEffectKeyList={}


	self._starList = {}
	self._timeList = {}
	self._pageData = {}
	self._giftTransList = {}

	if self._func then self._func() end

	if self.layoutTimer1 then
        LxTimer.DelayTimeStop(self.layoutTimer1)
        self.layoutTimer1 = nil
    end

	if self.layoutTimer2 then
        LxTimer.DelayTimeStop(self.layoutTimer2)
        self.layoutTimer2 = nil
    end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActDiscsSn:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActDiscsSn:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isEnus = gLGameLanguage:IsEnglishVersion() or gLGameLanguage:IsVieVersion()
	self._isVie =gLGameLanguage:IsVieVersion()


	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	self:RefreshForeign()
end

function UIActDiscsSn:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb) self:OnActivityListResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb) self:OnActivityPageResp(pb) end)

	self:WndEventRecv(EventNames.On_Item_Change,function ()
		self:RefreshDate()
	end)

	self:WndEventRecv(EventNames.REFRESH_SKIN_INFO,function ()
		self:RefreshDate()
	end)


end

function UIActDiscsSn:InitStarScroll()
	if self._giftLen <= 1 then return end

	local _uiList = self:GetUIScroll("starList")
	_uiList:Create(self.mStarScroll,self._pageData,function (...) self:StarListItem(...) end)
end

function UIActDiscsSn:ResetActivePageData(pb)
	local activityPage
	for i, v in ipairs(pb.pages) do
		if v.pageId == 1 then
			activityPage=gModelActivity:GenerateActivePageDataFromPb(v)
			break
		end

	end

	if not activityPage then return end

	self._giftIndex = 1
	self._pageData = {}

	for k,v in pairs(activityPage.entry) do
		local entryCfg  = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		if entryCfg then
			local moreInfo = string.split(entryCfg.moreInfo, '|')
			local marketData 	= v.MarketData
			local personal 		= marketData.personal; -- 已使用个人限购次数
			local personalGoal	= marketData.personalGoal; -- 个人可购买次数
			local haveCount		= personalGoal - personal
			local expend2 		= tonumber(entryCfg.expend2)
			local expend1		= entryCfg.expend1

			local payStr
			local payItemId
			if not string.isempty(expend1) then
				local payItemData   = string.split(expend1 or "", '=')
				payItemId		= payItemData[2]
				if not payItemId then
					if self._isForeign then
						payStr = gModelPay:GetShowByWelfareId(expend1)
					else
						payStr	= expend1
					end
				else
					payStr	= payItemData[3]
				end
			end

			local heroSpineData = string.split(moreInfo[1], '=')
			local titleIconData = string.split(moreInfo[2], '=')
			local bgImgData 	= string.split(moreInfo[3], '=')
			local showLookBtn   = 0
			if not string.isempty(moreInfo[4])then
				local arr = string.split(moreInfo[4],"=")
				showLookBtn = tonumber(arr[1])
			end

			local bottomBtnIcon = moreInfo[5]
			local data =
			{
				entryId = v.entryId,
				pageId = v.pageId,
				id 		= entryCfg.id,
				name = entryCfg.name,
				skinName = entryCfg.skinName,
				description = entryCfg.description,
				reward = LxDataHelper.ParseItem(entryCfg.reward),
				expend1 = expend1,
				expend2 = expend2,
				expend3 = entryCfg.expend3,
				expend2Str = gModelPay:GetShowByWelfareId(expend2),
				payItemId = payItemId,
				payStr  = payStr,
				heroRefId = tonumber(heroSpineData[1]),
				spinePos = heroSpineData[2],
				titleIcon = titleIconData[1],
				titlePos = titleIconData[2],
				bgImgPath = bgImgData[1],
				bgImgPos = bgImgData[2],
				showLookBtn = showLookBtn == 0,
				bottomBtnIcon = bottomBtnIcon,
				sort = entryCfg.sort,
				canBuy = haveCount > 0,
				cMoreInfo = moreInfo,
			}
			table.insert(self._pageData, data)
		end
	end

	table.sort(self._pageData, function(a, b)
		if a.canBuy ~= b.canBuy then
			return a.canBuy
		end

		return a.sort < b.sort
	end)

	for k,v in ipairs(self._pageData) do
		if self._oldEntryId == v.entryId then
			self._giftTabIndex = k
		end
	end
end

--#####################################################################################################################
--## Content1 #########################################################################################################
--#####################################################################################################################
function UIActDiscsSn:InitDataContent1()
	local config = self._config
	local rewardBg,btnImg,tabImg,choseImg,timeTipTxt
	= config.rewardBg,config.btnImg,config.tabImg,config.choseImg,config.timeTipTxt


	if LxUiHelper.IsImgPathValid(rewardBg) then
		self._rewardBg = rewardBg
	end
	if LxUiHelper.IsImgPathValid(btnImg) then
		self._btnImg = btnImg
	end
	if LxUiHelper.IsImgPathValid(tabImg) then
		self._tabImg = tabImg
	end

	self._choseImg = choseImg

end

--设置形象
function UIActDiscsSn:SetSpine(paintTans, heroRefId, spinePos)
	local effRef = gModelHero:GetShowEffectById(heroRefId)
	if self._themeType == 2 then
		effRef = gModelHero:GetHeroShowRefByRefId(heroRefId)
	else
		effRef = gModelHero:GetShowEffectById(heroRefId)
	end
	--local effRef = gModelHero:GetShowEffectById(heroRefId)
	--if not effRef then
	--	return
	--end

	local heroDrawing = effRef.heroDrawing

	local InstanceID = paintTans:GetInstanceID()
	local spine = heroDrawing
	local key = "spine"..InstanceID..spine
	if(self._oldSpine and self._oldSpine ~= spine and self._oldKey and self._oldKey ~= key)then
		for k,v in pairs(self._spineKeyList) do
			local oldSpine = self:FindWndSpineByKey(k)
			if oldSpine then
				local oldSpineTrans = oldSpine:GetDisplayTrans()
				CS.ShowObject(oldSpineTrans, false)
			end
		end
	end


	local newSpine = self:FindWndSpineByKey(key)
	if not newSpine then
		self:CreateWndSpine(paintTans,spine,key,false,function(dpSpine)
			local dpTrans = dpSpine:GetDisplayTrans()
			dpTrans.anchorMin = Vector2.New(0.5,0.5)
			dpTrans.anchorMax = Vector2.New(0.5,0.5)
			--dpSpine:SetFlipX(ref.flip == 1)
			dpSpine:SetScale(0.5)
			if not (string.isempty(spinePos) or spinePos == "0") then
				local showIconPos = string.split(spinePos,",")
				dpTrans.localPosition = Vector2.New(tonumber(showIconPos[1]),tonumber(showIconPos[2]))
			end

			dpSpine:SetRaycastTarget(false)
		end)

		self._spineKeyList[key] = true
	else
		local newSpineTrans = newSpine:GetDisplayTrans()
		CS.ShowObject(newSpineTrans, true)
	end

	self._oldKey = key
	self._oldSpine = spine
end


function UIActDiscsSn:OnClickLook(heroRefId,lookType)

	local sid = self._sid

	local heroSkinCloseFunc
	if self._func then
		heroSkinCloseFunc = self._func
	else
		heroSkinCloseFunc = function()
			GF.OpenWnd("UIActDiscsSn",{sid = sid})
		end
	end

	--gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_SKIN,"open",3,"模板42皮肤优惠购")

	if self._themeType == 1 then
		gModelGeneral:OpenHeroSkin({skinRefId = heroRefId,preview = true, backFunc = heroSkinCloseFunc})
		self._func = nil
		self:WndClose()
	else
		gModelGeneral:OpenHeroSimpleTip(heroRefId,true)
	end
end

function UIActDiscsSn:RefreshDateNew()
	self._needLoadSpineCnt = 0
	self._curLoadSpineCnt = 0
	self._loadSpineTransList = {}

	local itemdata = self._pageData[self._giftIndex]
	if not itemdata then return end

	local root	 	= self.mContent2
	local topRoot	= self.mRootNewTopContent
	-- local bgImg2 = self:FindWndTrans(root, "BgImg/BgImg2")
	local heroImg = self:FindWndTrans(root,"HeroImg")
	local heroBg = self:FindWndTrans(root,"HeroBg")
	local heroHd = self:FindWndTrans(root,"HeroHd")
	local heroSpine = self:FindWndTrans(root,"HeroSpine")
	-- local nameText = self:FindWndTrans(self.mNameBgNew,"NameText")
	local titleBg = self._isEnus and self.mTitleBgNew_En  or self.mTitleBgNew
	CS.ShowObject(titleBg,true)
	if self.jpj then
		self.mTitleBgNew.sizeDelta = Vector2.New(400,33)
		self:SetAnchorPos(self.mTitleBgNew,Vector2.New(-103,-180))
	end
	local titleText = self:FindWndTrans(titleBg,"TitleText")
	local roleSpine = self:FindWndTrans(self.mItemBgNew, "RoleSpine")
	local roleSpineRoot = self:FindWndTrans(self.mItemBgNew, "RoleSpine/Root")
	local look = self:FindWndTrans(self.mItemBgNew, "RoleSpine/Look")
	local lookText = self:FindWndTrans(look, "Text")

	local originalText = self:FindWndTrans(topRoot,"OriginalText")
	local originalItemText = self:FindWndTrans(topRoot,"OriginalItemText")

	local btnPay = self:FindWndTrans(topRoot,"BtnPay")
	local payText = self:FindWndTrans(btnPay,"PayText")
	local maskPay = self:FindWndTrans(topRoot,"MaskPay")
	local timeBg = self:FindWndTrans(topRoot,"TimeBg")
	local timeText = self:FindWndTrans(timeBg,"TimeText")
	local titleImg = self:FindWndTrans(topRoot, "TitleImg")
	local discountBg = self:FindWndTrans(btnPay, "DiscountBgNew")
	local discountText = self:FindWndTrans(discountBg, "DiscountText")
	local fogObj = self:FindWndTrans(root, "FogObj")

	local InstanceID = root:GetInstanceID()

	local heroRefId = itemdata.heroRefId
	local spinePos  = itemdata.spinePos

	local effRef = gModelHero:GetShowEffectById(heroRefId)
	local skinSpineBg = effRef.skinSpineBg
	local hasSpineBg = not string.isempty(skinSpineBg)
	self._needLoadSpineCnt = hasSpineBg and 2 or 1

	self:SetSpineNew(heroSpine, heroRefId, spinePos, 1)

	self:SetWndText(lookText, ccClientText(29802))
	--self:SetWndText(self.mTipsText, ccClientText(29803))
	-- self:SetSpineBgEffect(heroHd)

	if not string.isempty(effRef.prefabName) then
		self:DestroyWndSpineByKey("prefabName")
		self:CreateWndSpine(roleSpineRoot, effRef.prefabName, "prefabName", false)
	end
	if not string.isempty(effRef.skinSpineHd) then
		self:DestroyWndSpineByKey("skinSpineHd")
		self:CreateWndSpine(heroHd, effRef.skinSpineHd, "skinSpineHd", false)
		CS.ShowObject(heroHd, true)
	else
		CS.ShowObject(heroHd, false)
	end
	if hasSpineBg then
		self:DestroyWndSpineByKey("skinSpineBg")
		self:CreateWndSpine(heroBg, skinSpineBg, "skinSpineBg", false,function(spine)
			spine:SetVisible(false)
			self:UpdateSpineLoadCnt(spine)
		end)


		CS.ShowObject(heroBg, true)
		CS.ShowObject(heroImg, false)
	elseif not string.isempty(effRef.skinBg) then
		self:SetWndEasyImage(heroImg, effRef.skinBg)
		CS.ShowObject(heroBg, false)
		CS.ShowObject(heroImg, true)
	else
		self:SetWndEasyImage(heroImg, effRef.heroBg)
		CS.ShowObject(heroBg, false)
		CS.ShowObject(heroImg, true)
	end

	if not string.isempty(effRef.attrAll) then
		self:SetAttr(self.mAddObj1, effRef.attrAll, true)
		CS.ShowObject(self.mAddObj1, true)
	else
		CS.ShowObject(self.mAddObj1, false)
	end
	if not string.isempty(effRef.attr) then
		self:SetAttr(self.mAddObj2, effRef.attr, false)
		CS.ShowObject(self.mAddObj2, true)
	else
		CS.ShowObject(self.mAddObj2, false)
	end

	local str = itemdata.skinName or itemdata.name
	-- self:SetWndText(nameText,str)
	if self._btnImg then
		self:SetWndEasyImage(btnPay,self._btnImg)
	end

	local path = itemdata.bgImgPath
	local isValidPath = LxUiHelper.IsImgPathValid(path)
	if isValidPath then
		self:SetWndEasyImage(bgImg2,path, nil, true);
		local bgImgPos = itemdata.bgImgPos
		if not string.isempty(bgImgPos) then
			self:SetAnchorPos(bgImg2, LxDataHelper.ParseVector2NotEmpty(bgImgPos))
		end
	end
	CS.ShowObject(bgImg2, isValidPath)

	str =  itemdata.description
	local isShowTitleBg = not (string.isempty(str) or str == "0")
	CS.ShowObject(titleBg, isShowTitleBg)
	if isShowTitleBg then
		self:SetWndText(titleText,str)

		local addSize = -2
		if gLGameLanguage:IsJapanRegion() then
			addSize = -4
		end
		self:InitTextSizeWithLanguage(titleText, addSize)
	end

	local itemList = itemdata.reward
	self:InitItemList(itemList)

	local expend3 = itemdata.expend3
	local isShowDiscount = not string.isempty(expend3)
	CS.ShowObject(discountBg, isShowDiscount)
	if isShowDiscount then
		self:SetWndText(discountText, ccClientText(expend3))
		self:InitTextSizeWithLanguage(discountText, -4)
	end

	local moreData = itemdata.cMoreInfo
	if moreData[8] and not string.isempty(moreData[8]) and moreData[8] ~= '0' then
		local info = string.split(moreData[8], ";")
		for i = 1, 5 do
			local tran = CS.FindTrans(fogObj, "Fog" .. i)
			local v = info[i]
			if v then
				local fogData = string.split(v, "=")
				self:SetWndEasyImage(tran, fogData[1], nil, true)
				self:SetAnchorPos(tran, LxDataHelper.ParseVector(fogData[2]))
				CS.ShowObject(tran, true)
			else
				CS.ShowObject(tran, false)
			end
		end
		CS.ShowObject(fogObj, true)
	else
		CS.ShowObject(fogObj, false)
	end

	if moreData[2] and not string.isempty(moreData[2]) and moreData[2] ~= '0' then
		local data = string.split(moreData[2], "=")
		self:SetWndEasyImage(titleImg, data[1], nil, true)
		self:SetAnchorPos(titleImg, LxDataHelper.ParseVector(data[2]))
	end

	if moreData[4] and not string.isempty(moreData[4]) then
		-- local arr = string.split(moreData[4],"=")
		local isShowLook = moreData[4] == "0"
		CS.ShowObject(look, isShowLook)
		-- local lookType = arr[2] or "1"
		self:SetWndClick(roleSpine, function()
			if not isShowLook then
				return
			end
			-- if lookType == "1" then
				local data = {
					skinRefId = heroRefId,
					preview = true,
				}
				gModelGeneral:OpenHeroSkin(data)
			-- else
			-- 	gModelGeneral:OpenHeroSimpleTip(effRef.heroType,true)
			-- end
		end)
	end

	local canBuy = itemdata.canBuy
	CS.ShowObject(maskPay,not canBuy)
	CS.ShowObject(btnPay,canBuy)
	-- CS.ShowObject(timeBg,canBuy)
	if not canBuy then
		CS.ShowObject(originalText,false)
		CS.ShowObject(originalItemText,false)
		return
	end

	str = itemdata.expend2Str
	self:SetWndText(payText,str)

	str = itemdata.payStr
	if not string.isempty(str) then
		local isItemPay = itemdata.payItemId ~= nil
		CS.ShowObject(originalText,not isItemPay)
		CS.ShowObject(originalItemText,isItemPay)
		if not isItemPay then
			if not gLGameLanguage:IsJapanRegion() then
				--str = string.replace(ccClientText(14902),str)
			end

			str = string.replace(ccClientText(14907),str)
			self:SetWndText(originalText,str)
		else
			local payItemId = itemdata.payItemId
			if payItemId then
				local icon = gModelItem:GetItemIconByRefId(tonumber(payItemId))
				local Image = self:FindWndTrans(originalItemText,"Image")
				self:SetWndEasyImage(Image,icon)
			end
			self:SetWndText(originalItemText, str)
		end
	else
		CS.ShowObject(originalText,false)
		CS.ShowObject(originalItemText,false)
	end

	-- self._timeList[InstanceID] = {
	-- 	text = timeText,
	-- 	bg   = timeBg,
	-- }
	-- if not self:IsTimerExist(self._timeKey) then
	-- 	self:TimerStart(self._timeKey,1,false,-1)
	-- end
	-- self:SetTime()

	local entryId = itemdata.entryId
	local pageId  = itemdata.pageId
	local expend2 = itemdata.expend2
	self:SetWndClick(btnPay,function ()
		self._clickBuy = true
		gModelPay:GiftPayCtrl(entryId,expend2,ModelPay.PAY_TYPE_ACTIVITY,0,self._sid,pageId)
	end)
end

function UIActDiscsSn:MovePage(moveX,moveTime)
	local seqTween
	self:TweenSeqKill(self._moveKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._moveKey,function(seq)
			for i, v in ipairs(self._rootList) do
				CS.ShowObject(v,true)
				local vec = Vector2.New(v.localPosition.x + moveX,v.localPosition.y)
				local tweener = v:DOLocalMove(vec,moveTime)
				seq:Join(tweener)
			end
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._moveKey)
		self._bMove = true
		local keyi = self._key == 1 and 2 or 1
		CS.ShowObject(self._rootList[keyi],false)
		self:DragSetGiftScroll(self._oldIndex, self._giftTabIndex, true)
	end)
end

function UIActDiscsSn:SetItemTypeTwo(item,itemdata)
	if not itemdata then return end

	self._oldEntryId = itemdata.entryId

	local InstanceID = item:GetInstanceID()

	local BgImg = self:FindWndTrans(item,"BgImg")
	local BgImgBgImg2 = self:FindWndTrans(BgImg,"BgImg2")
	local BgImgHeroSpine = self:FindWndTrans(BgImg,"HeroSpine")
	local BgImgTypeOne = self:FindWndTrans(BgImg,"typeOne")
	local rewardBg = self:FindWndTrans(BgImgTypeOne,"Image")
	local BgImgTypeTwo = self:FindWndTrans(BgImg,"typeTwo")
	local typeTwoTitle = self:FindWndTrans(BgImgTypeTwo,"title")
	local typeTwoIntro = self:FindWndTrans(BgImgTypeTwo,"intro")
	local typeTwoImage = self:FindWndTrans(BgImgTypeTwo,"Image")
	local ImageItemScroll = self:FindWndTrans(typeTwoImage,"ItemScroll")
	local typeTwoPreciewTxt = self:FindWndTrans(BgImgTypeTwo,"preciewTxt")
	local OriginalText = self:FindWndTrans(item,"OriginalText")
	--local OriginalTextImage = self:FindWndTrans(OriginalText,"Image")
	local OriginalItemText = self:FindWndTrans(item,"OriginalItemText")
	--local OriginalItemTextImage = self:FindWndTrans(OriginalItemText,"Image")
	--local OriginalItemTextImage = self:FindWndTrans(OriginalItemText,"Image")
	local BtnPay = self:FindWndTrans(item,"BtnPay")
	local BtnPayPayText = self:FindWndTrans(BtnPay,"PayText")
	--local BtnPayPayItemText = self:FindWndTrans(BtnPay,"PayItemText")
	--local PayItemTextImage = self:FindWndTrans(BtnPayPayItemText,"Image")
	local wearTag = self:FindWndTrans(item,"wearTag")
	local MaskPay = self:FindWndTrans(item,"MaskPay")
	local TimeBg = self:FindWndTrans(item,"TimeBg")
	local TimeBgTimeText = self:FindWndTrans(TimeBg,"TimeText")


	CS.ShowObject(BgImgTypeOne,false)
	CS.ShowObject(BgImgTypeTwo,true)
	CS.ShowObject(BgImgBgImg2,false)

	if rewardBg and self._rewardBg then
		self:SetWndEasyImage(rewardBg,self._rewardBg)
	end
	if self._btnImg then
		self:SetWndEasyImage(BtnPay,self._btnImg)
	end
	local heroRefId = itemdata.heroRefId
	local spinePos  = itemdata.spinePos
	self:SetSpine(BgImgHeroSpine,heroRefId, spinePos)

	local hyperText = self:GetUIHyperText(typeTwoPreciewTxt)
	local str =ccClientText(17423) --"详情预览"
	str= hyperText:AddHyper(str,{func = function () self:OnClickLook(heroRefId) end})
	self:SetWndText(typeTwoPreciewTxt,str)
	local itemList = itemdata.reward
	self:CreateUIScrollImpl(nil,ImageItemScroll,itemList,function (...)
		self:OnDrawReward(...)
	end)


	local path = itemdata.titleIcon
	local isValidPath = LxUiHelper.IsImgPathValid(path)
	if isValidPath then
		self:SetWndEasyImage(typeTwoTitle,path, nil, true);
		local titlePos = itemdata.titlePos
		if not string.isempty(titlePos) then
			self:SetAnchorPos(typeTwoTitle, LxDataHelper.ParseVector2NotEmpty(titlePos))
		end
	end
	CS.ShowObject(typeTwoTitle, isValidPath)

	isValidPath = LxUiHelper.IsImgPathValid(self._introPath)
	if isValidPath then
		self:SetWndEasyImage(typeTwoIntro,self._introPath,nil,true)
		if self._introPos then
			self:SetAnchorPos(typeTwoIntro,self._introPos)
		end
	end
	CS.ShowObject(typeTwoIntro, isValidPath)

	isValidPath = LxUiHelper.IsImgPathValid(self._singleImage)
	if isValidPath then
		self:SetWndEasyImage(BgImg,self._singleImage,nil,true)
	end

	if not self._isShowGiftScroll then
		self:ChangeStarList(itemdata.id)
	end

	CS.ShowObject(wearTag,false)

	local canBuy = itemdata.canBuy
	CS.ShowObject(MaskPay,not canBuy)
	CS.ShowObject(BtnPay,canBuy)
	CS.ShowObject(TimeBg,canBuy)
	if not canBuy then
		CS.ShowObject(OriginalText,false)
		CS.ShowObject(OriginalItemText,false)
		return
	end

	str = itemdata.expend2Str
	self:SetWndText(BtnPayPayText,str)

	str = itemdata.payStr
	if not string.isempty(str) then
		local isItemPay = itemdata.payItemId ~= nil
		CS.ShowObject(OriginalText,not isItemPay)
		CS.ShowObject(OriginalItemText,isItemPay)
		if not isItemPay then
			str = string.replace(ccClientText(14902),str)
			str = string.replace(ccClientText(14907),str)
			self:SetWndText(OriginalText,str)
		else
			local payItemId = itemdata.payItemId
			if payItemId then
				local icon = gModelItem:GetItemIconByRefId(tonumber(payItemId))
				local Image = self:FindWndTrans(OriginalItemText,"Image")
				self:SetWndEasyImage(Image,icon)
			end
			self:SetWndText(OriginalItemText, str)
		end
	else
		CS.ShowObject(OriginalText,false)
		CS.ShowObject(OriginalItemText,false)
	end

	local entryId = itemdata.entryId
	local pageId  = itemdata.pageId
	local expend2 = itemdata.expend2
	self:SetWndClick(BtnPay,function ()
		self._clickBuy = true
		gModelPay:GiftPayCtrl(entryId,expend2,ModelPay.PAY_TYPE_ACTIVITY,0,self._sid,pageId)
	end)

	self._timeList[InstanceID] = {
		text = TimeBgTimeText,
		bg   = TimeBg,
	}
	if not self:IsTimerExist(self._timeKey) then
		self:TimerStart(self._timeKey,1,false,-1)
	end
	self:SetTime()

end

function UIActDiscsSn:MoveRoot(index)
	local _giftLen = self._giftLen
	if _giftLen <= 1 then
		return
	end
	local _key,_giftIndex,width,_rootList = self._key,self._giftIndex,self.mAniRoot.rect.width,self._rootList
	local move
	local _rootKey = _key == 1 and 2 or 1
	if index == 1 then
		move = width
		_giftIndex = _giftIndex - 1
		if _giftIndex < 1 then
			_giftIndex = _giftLen
		end
	elseif index == 2 then
		move = - width
		_giftIndex = _giftIndex + 1
		if _giftIndex > _giftLen then
			_giftIndex = 1
		end
	end
	_rootList[_rootKey].localPosition = Vector2.New(_rootList[_key].localPosition.x - move,_rootList[_rootKey].localPosition.y)

	self._giftIndex = _giftIndex
	self._key = _rootKey
	self._oldIndex  = self._giftTabIndex
	self._giftTabIndex     = _giftIndex
	self:RefreshDate()
	self:MovePage(move,self._moveTime)
end

function UIActDiscsSn:UpdateSpineLoadCnt(spine)
	table.insert(self._loadSpineTransList,spine)
	self._curLoadSpineCnt = self._curLoadSpineCnt + 1
	if self._curLoadSpineCnt >= self._needLoadSpineCnt then
		self:ShowHeroSpineInfo()
	end
end

function UIActDiscsSn:ChangeGiftImageNew(trans,bool)
	if not trans then return end

	local selImage = self:FindWndTrans(trans,"SelImage")
	CS.ShowObject(selImage,bool)
end

function UIActDiscsSn:OnDrawReward(list,item,itemdata,itempos)
	local Root = self:FindWndTrans(item,"Root")
	local RootItem = self:FindWndTrans(Root,"item")
	local itemIcon = self:FindWndTrans(RootItem,"Icon")
	--local RootEff = self:FindWndTrans(Root,"Eff")

	self:CreateCommonIconImpl(itemIcon,itemdata)
end

function UIActDiscsSn:UIDragTryOnEnd(dragKey,eventData)
	self.mViewMove.transform.localPosition = Vector2.New(0,0)
	self._bDrag = true
end

function UIActDiscsSn:GetNextIndex(addValue)
	local index = self._giftTabIndex + addValue
	local maxIndex = self._giftLen
	if index < 1 then
		return maxIndex
	elseif index > maxIndex then
		return 1
	else
		return index
	end
end
function UIActDiscsSn:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:OnClickClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mLeftBtn, function(...) self:OnClickGiftDirectionBtn(-1) end)
	self:SetWndClick(self.mRightBtn, function(...) self:OnClickGiftDirectionBtn(1) end)

	self:SetWndClick(self.mCloseBtnNew, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIActDiscsSn:RefreshDate(isShow)
	local item = self._rootList[self._key]
	local itemdata = self._pageData[self._giftIndex]
	if self._themeType == 2 then
		self:SetItemTypeTwo(item,itemdata)
	else
		self:SetGiftInfo(item,itemdata)
		if isShow then
			CS.ShowObject(item, true)
		end
	end

	--self:SetGiftInfo(self._rootList[self._key],self._pageData[self._giftIndex])
end

function UIActDiscsSn:ShowHeroSpineInfo()
	for i,spineDp in ipairs(self._loadSpineTransList) do
		spineDp:PlayAnimationSolid("idle")
		spineDp:SetVisible(true)
	end
end

function UIActDiscsSn:RefreshShowItem()
	local giftIndex = self._giftIndex
	local _pageDatas = self._pageData or {}
	local pageData = _pageDatas[giftIndex]
	if not pageData then return end

	self._needLoadSpineCnt = 0
	self._curLoadSpineCnt = 0
	self._loadSpineTransList = {}

	local mContent3 = self.mContent3
	local heroBg = self:FindWndTrans(mContent3,"HeroBg")
	local heroSpine = self:FindWndTrans(mContent3,"HeroSpine")
	local discountText = self:FindWndTrans(mContent3,"DiscountBg/DiscountText")
	local textImg = self:FindWndTrans(mContent3,"TextImg")
	local desText = self:FindWndTrans(mContent3,"DesImg/DesText")
	local btnLook = self:FindWndTrans(mContent3,"BtnLook")
	local lookText = self:FindWndTrans(btnLook,"LookText")
	local lookIcon = self:FindWndTrans(btnLook,"Icon")
	local rewardMg = self:FindWndTrans(mContent3,"RewardMg")
	local btnBuy = self:FindWndTrans(mContent3,"BtnBuy")
	local buyText = self:FindWndTrans(mContent3,"BtnBuy/BuyText")
	local maskPay = self:FindWndTrans(mContent3,"MaskPay")

	local data = self._config
	local moreInfo = pageData.cMoreInfo
	local scale = moreInfo[6] and tonumber(moreInfo[6]) or 1
	local discountStr = moreInfo[8] or ""

	if LxUiHelper.IsImgPathValid(pageData.bgImgPath) then
		self:SetWndEasyImage(heroBg,pageData.bgImgPath,function () CS.ShowObject(heroBg,true) end)
	end


	if not string.isempty(pageData.heroRefId)then
		self._needLoadSpineCnt = 1
		CS.ShowObject(heroSpine,true)
		self:SetSpineNew(heroSpine, pageData.heroRefId, pageData.spinePos,scale)
	end
	self:SetWndText(discountText,discountStr)
	if LxUiHelper.IsImgPathValid(pageData.titleIcon) then
		self:SetWndEasyImage(textImg,pageData.titleIcon,function () CS.ShowObject(textImg,true) end)
	end
	if not string.isempty(pageData.description)then
		self:SetWndText(desText,pageData.description)
	end
	if LxUiHelper.IsImgPathValid(data.priviewBtnBg) then
		self:SetWndEasyImage(btnLook,data.priviewBtnBg,nil,true)
	end
	if LxUiHelper.IsImgPathValid(data.priviewBtn) then
		self:SetWndEasyImage(lookIcon,data.priviewBtn,nil,true)
	end
	if not string.isempty(data.priviewBtnTxt)then
		self:SetWndText(lookText,data.priviewBtnTxt)
	end
	if not string.isempty(data.priviewBtnPos)then
		local pos = LxDataHelper.ParseVector2NotEmpty(data.priviewBtnPos)
		self:SetAnchorPos(btnLook, pos)
	end
	CS.ShowObject(btnLook,pageData.showLookBtn)
	if not string.isempty(pageData.expend2Str)then
		self:SetWndText(buyText,pageData.expend2Str)
	end
	CS.ShowObject(rewardMg,pageData.reward)
	if pageData.reward then
		for i = 1, 4 do
			local item = self:FindWndTrans(rewardMg,"RewardBg"..i)
			local reward = pageData.reward[i]
			self:RewardItemIconList(item,reward,i)
		end
	end
	CS.ShowObject(btnBuy,pageData.canBuy)
	CS.ShowObject(maskPay,not pageData.canBuy)

	if pageData.showLookBtn then
		self:SetWndClick(btnLook,function ()
			local arr = string.split(moreInfo[4],"=")
			local lookType = arr[2] or "1"
			local heroEffRefId = pageData.heroRefId
			local heroEffRef = gModelHero:GetShowEffectById(heroEffRefId)
			if not heroEffRef then return end
			if lookType == "1" then
				gModelGeneral:OpenHeroSkin({skinRefId = heroEffRefId,preview = true, backFunc = function ()
					local sid = self._sid
					GF.OpenWnd("UIActDiscsSn",{sid = sid})
				end})
			else
				local heroRefId = heroEffRef.heroType
				gModelGeneral:OpenHeroSimpleTip(heroRefId,true)
			end
		end)
	end
	self:SetWndClick(btnBuy,function ()
		local entryId,expend2,pageId,canBuy = pageData.entryId,pageData.expend2,pageData.pageId,pageData.canBuy
		if not canBuy then return end
		gModelPay:GiftPayCtrl(entryId,expend2,ModelPay.PAY_TYPE_ACTIVITY,0,self._sid,pageId)
	end)

	local oldGiftIndex = self._oldGiftIndex
	if oldGiftIndex == giftIndex then return end
	self._heroEffRefId = pageData.heroRefId
	self:PlayHeroSound()
	--self:TimerStop(self._timeSoundKey)
	--self:TimerStart(self._timeSoundKey,10,false,-1)
	self._oldGiftIndex = giftIndex
end

function UIActDiscsSn:SetGiftInfo(root, itemdata)
	if not itemdata then return end

	self._oldEntryId = itemdata.entryId

	local InstanceID = root:GetInstanceID()

	local bgRoot = self:FindWndTrans(root,"BgImg")

	local bgImg2 = self:FindWndTrans(bgRoot, "BgImg2")
	local heroSpine = self:FindWndTrans(bgRoot,"HeroSpine")

	local typeRoot = self:FindWndTrans(bgRoot,"typeOne")
	local rewardBg = self:FindWndTrans(typeRoot,"Image")
	local typeTwoRoot = self:FindWndTrans(bgRoot,"typeTwo")

	CS.ShowObject(typeRoot,true)
	CS.ShowObject(typeTwoRoot,false)

	if rewardBg and self._rewardBg then
		self:SetWndEasyImage(rewardBg,self._rewardBg)
	end
	local btnLook = self:FindWndTrans(typeRoot,"NameBg/BtnLook")
	local nameText = self:FindWndTrans(typeRoot,"NameBg/NameText")
	self:InitTextSizeWithLanguage(nameText,-6)

	local path = "TitleBg"
	if gLGameLanguage:IsForeignVersion() then
		path = "TitleBgEn"
	end

	local titleBg = self:FindWndTrans(typeRoot,path)
	local titleText = self:FindWndTrans(titleBg,"TitleText")
	local titleImg = self:FindWndTrans(titleBg,"TitleImg")

	local itemScroll = self:FindWndTrans(typeRoot,"Image/ItemScroll")

	local originalText = self:FindWndTrans(root,"OriginalText")
	local originalItemText = self:FindWndTrans(root,"OriginalItemText")

	local btnPay = self:FindWndTrans(root,"BtnPay")
	local payText = self:FindWndTrans(root,"BtnPay/PayText")

	--local maskPay = self:FindWndTrans(root,"MaskPay")
	local timeBg = self:FindWndTrans(root,"TimeBg")
	local timeText = self:FindWndTrans(root,"TimeBg/TimeText")
	local wearTag = self:FindWndTrans(root,"wearTag")

	local heroRefId = itemdata.heroRefId
	local spinePos  = itemdata.spinePos
	self:SetSpine(heroSpine,heroRefId, spinePos)
	if self._btnImg then
		self:SetWndEasyImage(btnPay,self._btnImg)
	end

	local isShowLookBtn = itemdata.showLookBtn
	CS.ShowObject(btnLook, isShowLookBtn)
	if isShowLookBtn then
		--local sid = self._sid
		--
		--local heroSkinCloseFunc
		--if self._func then
		--	heroSkinCloseFunc = self._func
		--else
		--	heroSkinCloseFunc = function()
		--		GF.OpenWnd("UIActDiscsSn",{sid = sid})
		--	end
		--end
		self:SetWndClick(btnLook,function ()
			--数数打点
			--gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_SKIN,"open",3,"模板42皮肤优惠购")
			--
			--gModelGeneral:OpenHeroSkin({skinRefId = heroRefId,preview = true, backFunc = heroSkinCloseFunc})
			--self._func = nil
			--self:WndClose()

			self:OnClickLook(heroRefId)
		end)
	end


	local str =itemdata.name
	self:SetWndText(nameText,str)

	local path = itemdata.titleIcon
	local isValidPath = LxUiHelper.IsImgPathValid(path)
	if isValidPath then
		self:SetWndEasyImage(titleImg,path, nil, true);
		local titlePos = itemdata.titlePos
		if not string.isempty(titlePos) then
			self:SetAnchorPos(titleImg, LxDataHelper.ParseVector2NotEmpty(titlePos))
		end
	end
	CS.ShowObject(titleImg, isValidPath)

	path = itemdata.bgImgPath
	isValidPath = LxUiHelper.IsImgPathValid(path)
	if isValidPath then
		self:SetWndEasyImage(bgImg2,path, nil, true);
		local bgImgPos = itemdata.bgImgPos
		if not string.isempty(bgImgPos) then
			self:SetAnchorPos(bgImg2, LxDataHelper.ParseVector2NotEmpty(bgImgPos))
		end
	end
	CS.ShowObject(bgImg2, isValidPath)

	str =  itemdata.description
	local isShowTitleBg = not (string.isempty(str) or str == "0")
	CS.ShowObject(titleBg, isShowTitleBg)
	if isShowTitleBg then
		self:SetWndText(titleText,str)
	end



	local itemList = itemdata.reward
	local uiIconEasyList = self._uiIconEasyList[InstanceID]
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		self._uiIconEasyList[InstanceID] = uiIconEasyList
		uiIconEasyList:Create(self, itemScroll)
		uiIconEasyList:SetIconClickPath("Root/CommonUI/Icon")
		uiIconEasyList:SetIconParentPath("Root/CommonUI/Icon")
	end
	uiIconEasyList:RefreshList(itemList)

	--local isSkinItem,code,skinRefId
	--for k,v in ipairs(itemList) do
	--	isSkinItem,code,skinRefId = gModelHero:GetSkinStateByItemId(v)
	--	if isSkinItem then
	--		break
	--	end
	--end

	if not self._isShowGiftScroll then
		self:ChangeStarList(itemdata.id)
	end



	local isSkinItem,code,skinRefId
	for k,v in ipairs(itemList) do
		isSkinItem,code,skinRefId = gModelHero:GetSkinStateByItemId(v)
		if isSkinItem then
			break
		end
	end
	CS.ShowObject(wearTag,false)

	if code == 1 then
		local canBuy = itemdata.canBuy
		--CS.ShowObject(maskPay,not canBuy)
		CS.ShowObject(btnPay,canBuy)
		CS.ShowObject(timeBg,canBuy)
		if not canBuy then
			CS.ShowObject(originalText,false)
			CS.ShowObject(originalItemText,false)
			return
		end

		str = itemdata.expend2Str
		self:SetWndText(payText,str)

		str = itemdata.payStr
		if not string.isempty(str) then
			local isItemPay = itemdata.payItemId ~= nil
			CS.ShowObject(originalText,not isItemPay)
			CS.ShowObject(originalItemText,isItemPay)
			if not isItemPay then
				str = string.replace(ccClientText(14902),str)
				str = string.replace(ccClientText(14907),str)
				self:SetWndText(originalText,str)
			else
				local payItemId = itemdata.payItemId
				if payItemId then
					local icon = gModelItem:GetItemIconByRefId(tonumber(payItemId))
					local Image = self:FindWndTrans(originalItemText,"Image")
					self:SetWndEasyImage(Image,icon)
				end
				self:SetWndText(originalItemText, str)
			end
		else
			CS.ShowObject(originalText,false)
			CS.ShowObject(originalItemText,false)
		end

		local entryId = itemdata.entryId
		local pageId  = itemdata.pageId
		local expend2 = itemdata.expend2
		self:SetWndClick(btnPay,function ()
			self._clickBuy = true
			gModelPay:GiftPayCtrl(entryId,expend2,ModelPay.PAY_TYPE_ACTIVITY,0,self._sid,pageId)
		end)

		self._timeList[InstanceID] = {
			text = timeText,
			bg   = timeBg,
		}
		if not self:IsTimerExist(self._timeKey) then
			self:TimerStart(self._timeKey,1,false,-1)
		end
		self:SetTime()
	else

		self:TimerStop(self._timeKey)

		local isWear = false
		local str = nil
		if code == 2 then
			str = ccClientText(17422)
		elseif code == 3 then
			str = ccClientText(17421)
		elseif code == 4 then
			isWear = true
		end

		self:SetWndText(payText,str)
		self:SetWndClick(btnPay,function ()
			gModelHero:ActiveOrWearSkin(skinRefId)
		end)
		CS.ShowObject(btnPay,not isWear)
		CS.ShowObject(wearTag,isWear)
		CS.ShowObject(originalText,false)
		CS.ShowObject(originalItemText,false)
		CS.ShowObject(timeBg,false)
	end




end

---@param spineDp LDisplaySpine
function UIActDiscsSn:OnClickSpineFunc(spineDp,heroRefId)
	-- local sid = self._sid
	-- local heroSkinCloseFunc
	-- if self._func then
	-- 	heroSkinCloseFunc = self._func
	-- else
	-- 	heroSkinCloseFunc = function()
	-- 		GF.OpenWnd("UIActDiscsSn",{sid = sid})
	-- 	end
	-- end

	local spineTrans = spineDp:GetSpineTrans()
	self:UpdateSpineLoadCnt(spineDp)

	self:SetWndClick(spineTrans,function ()
		--数数打点
		--gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_SKIN,"open",3,"模板42皮肤优惠购")

		-- gModelGeneral:OpenHeroSkin({skinRefId = heroRefId,preview = true, backFunc = heroSkinCloseFunc})
		gModelGeneral:OpenHeroSkin({skinRefId = heroRefId,preview = true})
		-- self._func = nil
		-- self:WndClose()
	end)
end

function UIActDiscsSn:RefreshContent2()
	local list = self._pageData
	self._giftLen = #list

	local giftScrollBg = self:FindWndTrans(self.mRootNewTopContent, "GiftScrollBg")
	local giftScrollBgHeight = 515
	if self._giftLen < 4 then
		giftScrollBgHeight = giftScrollBgHeight - (4 - self._giftLen) * 107
	end
	LxUiHelper.SetSizeWithCurAnchor(giftScrollBg,1,giftScrollBgHeight)

	if(self._uiGiftNewList)then
		self._uiGiftNewList:RefreshList(list)
	else
		self._uiGiftNewList = self:GetUIScroll("GiftScrollNew")
		self._uiGiftNewList:Create(self.mGiftScrollNew,list,function (...) self:GiftListItemNew(...) end,UIItemList.NORMAL)
		self._uiGiftNewList:EnableScroll(true,false)
	end

	self:OnClickGiftNew(self._giftTabIndex)

	CS.ShowObject(self.mContent1, false)
	CS.ShowObject(self.mContent2, true)

	local config = self._config
	local tip,tipPos = config.tip,config.tipPos
	if not string.isempty(tip)  then
		local tipStr =gModelActivity:GetLngNameById(tip)
		self:SetWndText(self.mTipsText,tipStr)
	end

	if not string.isempty(tipPos) then
		local posStr=string.split(tipPos,",")

		local pos = Vector2.New(checknumber(posStr[1]),checknumber(posStr[2]))
		self:SetAnchorPos(self.mTipsText,pos)
	end
end

function UIActDiscsSn:OnDrawCommonItemCell(list,item,itemdata,itempos)
	local InstanceID = item:GetInstanceID()

	local itemRoot = self:FindWndTrans(item,"Root/CommonUI/Icon")
	local effTrans = self:FindWndTrans(item,"Root/Eff")

	local uiCommonList = self._uiCommonList
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(itemRoot)
	end
	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)

	self:SetWndClick(itemRoot,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
	baseClass:DoApply()

	local effName = self._itemEffect
	local show = itemdata.isShowEff and not string.isempty(effName)
	CS.ShowObject(effTrans, show)
	if show then
		local key = "DrawItem"..InstanceID
		table.insert(self._effectKeyList,key)
		self:CreateWndEffect(effTrans,effName,key,110,false,false,5)
	end

	self:SetWndClick(item,function ()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
end

function UIActDiscsSn:SetTime()
	if self._endTime <= 0 then
		for i, v in pairs(self._timeList) do
			CS.ShowObject(v.bg, false)
		end
		return
	end

	local time = GetTimestamp()
	local timespan = self._endTime - time

	local timeStr
	if timespan < 0 then
		timeStr = ccClientText(14301)
	elseif self._timeTipTxt then
		timeStr = LUtil.FormatTimespanCn(timespan,{hTextId = 10371})
		timeStr = string.replace(self._timeTipTxt,timeStr)
	else
		timeStr = LUtil.FormatTimespanCn(timespan,{hTextId = 10371})
		timeStr = string.replace(ccClientText(11637),timeStr)
	end

	for i, v in pairs(self._timeList) do
		self:SetWndText(v.text,timeStr)
		CS.ShowObject(v.bg, true)
	end
end

function UIActDiscsSn:JumpTargetGiftDelay(giftPos)
	if not self._uiGift1List then return end
	local list = self._uiGift1List:GetList()
	if(not list)then
		return
	end

	list:DelayScrollTo(giftPos,UIListEasy.SCROLL_CENTER)
end

function UIActDiscsSn:SetDecorationImg(item,decoration)
	local decorationArr = string.split(decoration,"|")
	for i, v in ipairs(decorationArr) do
		local arr = string.split(v,"=")
		if LxUiHelper.IsImgPathValid(arr[1]) then
			if i == 1 then
				self:SetWndEasyImage(item,arr[1],function ()
					CS.ShowObject(item,true)
					if not string.isempty(arr[2]) then
						local pos = LxDataHelper.ParseVector2NotEmpty(arr[2])
						self:SetAnchorPos(item, pos)
					end
				end,true)
			else
				local bg = self:FindWndTrans(item,"Decorate"..(i - 1))
				if bg then
					self:SetWndEasyImage(bg,arr[1],function ()
						CS.ShowObject(bg,true)
						if not string.isempty(arr[2]) then
							local pos = LxDataHelper.ParseVector2NotEmpty(arr[2])
							self:SetAnchorPos(bg, pos)
						end
					end,true)
				end
			end
		end
	end
end

--#####################################################################################################################
--## GiftScroll #######################################################################################################
--#####################################################################################################################
function UIActDiscsSn:InitGiftList()
	local list = self._pageData
	local pageNum = #list
	CS.ShowObject(self.mGiftScroll1,false)
	CS.ShowObject(self.mGiftScroll2,false)
	CS.ShowObject(self.mLeftBtn,false)
	CS.ShowObject(self.mRightBtn,false)

	if table.isempty(list) or pageNum < 2 then return end

	self._giftTransList = {}

	if(pageNum <= 5)then
		CS.ShowObject(self.mGiftScroll1,pageNum > 1)
		if(self._uiGift1List)then
			self._uiGift1List:RefreshList(list)
		else
			self._uiGift1List = self:GetUIScroll("GiftScroll")
			self._uiGift1List:Create(self.mGiftScroll1,list,function (...) self:GiftListItem(...) end)
		end
		self._uiGift1List:EnableScroll(false)
		self:OnClickGift(self._giftTabIndex, true)
	else
		CS.ShowObject(self.mLeftBtn,true)
		CS.ShowObject(self.mRightBtn,true)
		CS.ShowObject(self.mGiftScroll2,true)
		if(self._uiGift1List)then
			self._uiGift1List:RefreshList(list)
		else
			self._uiGift1List = self:GetUIScroll("GiftScroll1")
			self._uiGift1List:Create(self.mGiftScroll2,list,function (...) self:GiftListItem(...) end,UIItemList.NORMAL)
			self._uiGift1List:EnableScroll(true,true)
			self:JumpTargetGiftDelay(self._giftTabIndex)
		end

		self:OnClickGift(self._giftTabIndex)
	end
end

function UIActDiscsSn:RefreshContent3()
	local _pageData = self._pageData
	local mContent3 = self.mContent3

	local tabSuper = self:FindWndTrans(mContent3,"TabBg/TabSuper")

	local list = _pageData
	local uiList = self._uiList
	if uiList then
		uiList:RefreshList(list)
		uiList:DrawAllItems()
	else
		uiList = self:GetUIScroll("tabSuper")
		self._uiList = uiList
		uiList:Create(tabSuper,list,function (...) self:TabListItem(...)  end, UIItemList.SUPER)
	end
	self:RefreshShowItem()
end

function UIActDiscsSn:RewardItemList(item,itemdata,itempos)
	if not item or not itemdata then return end
	local bg = self:FindWndTrans(item,"Bg")
	local spine = self:FindWndTrans(item,"Spine")
	local image = self:FindWndTrans(item,"Image")

	local arr = string.split(itemdata,"=")
	if arr[1] == "1" then
		self:SetWndEasyImage(item,arr[2],nil,true)
		self:SetWndEasyImage(bg,arr[2],function () CS.ShowObject(bg,true) end)
		CS.ShowObject(image,true)
	elseif arr[1] == "2" then
		local spineName = arr[2]
		if not string.isempty(spineName)then
			CS.ShowObject(spine,true)
			self:CreateWndSpine(spine,spineName,spineName..itempos,false)
		end
	end
	if not string.isempty(arr[3]) then
		local pos = LxDataHelper.ParseVector2NotEmpty(arr[3])
		self:SetAnchorPos(item, pos)
	end
end

--#####################################################################################################################
--## Dragging #########################################################################################################
--#####################################################################################################################
function UIActDiscsSn:InitDrag()--拖动
	self:UIDragSetItem(self._dragKey,"AniRoot/Content1/ViewMove",CS.YXUIDrag.DragMode.DragOrigin)
end


--#####################################################################################################################
--## Content3 #########################################################################################################
--#####################################################################################################################
function UIActDiscsSn:InitDataContent3()
	local mContent3 = self.mContent3
	CS.ShowObject(mContent3,true)
	local tabBg = self:FindWndTrans(mContent3,"TabBg")
	local decorateBg = self:FindWndTrans(mContent3,"DecorateBg")
	local btnClose = self:FindWndTrans(mContent3,"BtnClose")
	local discountBg = self:FindWndTrans(mContent3,"DiscountBg")
	local desImg = self:FindWndTrans(mContent3,"DesImg")
	local rewardMg = self:FindWndTrans(mContent3,"RewardMg")
	local btnBuy = self:FindWndTrans(mContent3,"BtnBuy")
	local btnEff = self:FindWndTrans(btnBuy,"BtnEff")
	local timeBg = self:FindWndTrans(mContent3,"TimeBg")
	local timeText = self:FindWndTrans(timeBg,"TimeText")
	local eff = self:FindWndTrans(mContent3,"Eff")

	local data = self._config
	local btnImg3,goodsShowImg3,timeTipTxt3,timeTipTxtPos3,discountImage3,nameBg3,listBg3,decoration,showEffect,showEffectPos,buyBtnEff
	= data.btnImg3,data.goodsShowImg3,data.timeTipTxt3,data.timeTipTxtPos3,data.discountImage3,data.nameBg3,data.listBg3,data.decoration,data.showEffect,data.showEffectPos,data.buyBtnEff
	if LxUiHelper.IsImgPathValid(btnImg3) then
		self:SetWndEasyImage(btnBuy,btnImg3,function () CS.ShowObject(btnBuy,true) end,true)
	else
		CS.ShowObject(btnBuy,true)
	end
	if not string.isempty(buyBtnEff)then
		local arr = string.split(buyBtnEff,"=")
		if arr[1] == "1" then
			self:CreateWndEffect(btnEff,arr[2],"buyBtnEff",100)
		elseif arr[1] == "2" then
			self:CreateWndSpine(btnEff,arr[2],"buyBtnEff",false)
		end
	end
	local goodsShowImgArr = {}
	if not string.isempty(goodsShowImg3)then
		goodsShowImgArr = string.split(goodsShowImg3,"|")
	end
	for i = 1, 4 do
		local item = self:FindWndTrans(rewardMg,"RewardBg"..i)
		local itemImg = goodsShowImgArr[i]
		self:RewardItemList(item,itemImg,i)
	end
	if not string.isempty(timeTipTxt3)then
		self._timeTipTxt = timeTipTxt3
	end
	if not string.isempty(timeTipTxtPos3) then
		local pos = LxDataHelper.ParseVector2NotEmpty(timeTipTxtPos3)
		self:SetAnchorPos(timeBg, pos)
	end
	if LxUiHelper.IsImgPathValid(discountImage3) then
		self:SetWndEasyImage(discountBg,discountImage3,function () CS.ShowObject(discountBg,true) end,true)
	else
		CS.ShowObject(discountBg,true)
	end
	if LxUiHelper.IsImgPathValid(nameBg3) then
		self:SetWndEasyImage(desImg,nameBg3,function () CS.ShowObject(desImg,true) end)
	else
		CS.ShowObject(desImg,true)
	end
	if LxUiHelper.IsImgPathValid(listBg3) then
		self:SetWndEasyImage(tabBg,listBg3,function () CS.ShowObject(tabBg,true) end)
	else
		CS.ShowObject(tabBg,true)
	end
	if not string.isempty(decoration)then
		self:SetDecorationImg(decorateBg,decoration)
	end
	if not string.isempty(showEffect)then
		local arr = string.split(showEffect,"=")
		if arr[1] == "1" then
			self:CreateWndEffect(eff,arr[2],"showEffect",100)
		elseif arr[1] == "2" then
			self:CreateWndSpine(eff,arr[2],"showEffect",false)
		end
		if not string.isempty(showEffectPos)then
			local pos = LxDataHelper.ParseVector2NotEmpty(showEffectPos)
			self:SetAnchorPos(eff, pos)
		end
	end
	CS.ShowObject(btnClose,true)

	self:SetWndClick(btnClose,function ()
		self:WndClose()
	end)

	self._timeList["Content3"] = {
		text = timeText,
		bg   = timeBg,
	}
	if not self:IsTimerExist(self._timeKey) then
		self:TimerStart(self._timeKey,1,false,-1)
	end
	self:SetTime()
end

function UIActDiscsSn:StarListItem(list,item,itemdata,itempos)
	self._starList[itemdata.id] = item
end

function UIActDiscsSn:OnClickGiftDirectionBtn(changeValue)
	self._giftTabIndex = self:GetNextIndex(changeValue)
	self:OnClickGift(self._giftTabIndex, true)
end

--#####################################################################################################################
--## Content2 #########################################################################################################
--#####################################################################################################################
function UIActDiscsSn:InitDataContent2()
	local config = self._config

	local path  = config.imageTitle
	local pos	= config.imageTitlePos
	if LxUiHelper.IsImgPathValid(path) then
		-- self:SetWndEasyImage(self.mNameImageNew, path)
		if not string.isempty(pos) then
			-- self:SetAnchorPos(self.mNameBgNew, LxDataHelper.ParseVector2NotEmpty(pos))
		end
	end

	path = config.subtitleBg
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTitleBgNew, path)
		self:SetWndEasyImage(self.mTitleBgNew_En, path)
	end

	path = config.itemBg
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mItemBgNew, path)
		self:SetWndEasyImage(self.mTitleBgNew_En, path)
	end

	path = config.discountImage
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mDiscountBgNew, path)
	end

	self._itemEffect = config.itemEffect

	local bgEffect = config.bgEffect
	if not string.isempty(bgEffect) then
		local dataList = {}
		local bgEffectList = string.split(bgEffect, '|')
		for k,v in ipairs(bgEffectList) do
			local data = string.split(v, '=')
			local itemIndex = tonumber(data[1])
			dataList[itemIndex] = data[2]
		end

		self._heroBgEffectList = dataList
	end
end

function UIActDiscsSn:JumpTargetGift(giftPos)
	if not self._uiGift1List then return end
	local list = self._uiGift1List:GetList()
	if(not list)then
		return
	end

	list:ScrollTo(giftPos)
end

function UIActDiscsSn:OnClickGift(itempos, needJump)
	if self._giftIndex > 0 then
		local trans = self._giftTransList[self._giftIndex]
		self:ChangeGiftImage(trans,false)
	end
	local trans = self._giftTransList[itempos]
	self:ChangeGiftImage(trans,true)
	self._giftIndex = itempos

	self:RefreshDate()

	if needJump and self._uiGift1List then
		self:JumpTargetGift(itempos)
	end
end

--#####################################################################################################################
--## Timer ############################################################################################################
--#####################################################################################################################
function UIActDiscsSn:OnTimer(key)
	if key == self._timeKey then
		self:SetTime()
	elseif key == self._timeSoundKey then
		self:PlayHeroSound()
	end
end

function UIActDiscsSn:OnActivityListResp(pb)
	local activities = pb.activities
	for i, v in ipairs(activities) do
		local sid = v.sid
		if self._sid == sid then
			self:InitData()
			self:RefreshView()
			break
		end
	end
end

function UIActDiscsSn:GiftListItemNew(list,item,itemdata,itempos)
	self._giftTransList[itempos] = item
	self:ChangeGiftImageNew(item,false)

	local RootTrans = self:FindWndTrans(item,"Root")
	local iconTrans = self:FindWndTrans(item,"Icon")
	local nameText = self:FindWndTrans(item,"NameText")
	local gouImageTrans = self:FindWndTrans(item, "GouImage")
	--local commonUI 	= self:FindWndTrans(RootTrans,"CommonUI")
	--local effTrans = self:FindWndTrans(RootTrans,"Eff")
	local InstanceID = item:GetInstanceID()

	local giftData = itemdata
	local giftName = giftData.name
	local bottomBtnIcon  = giftData.bottomBtnIcon

	if LxUiHelper.IsImgPathValid(bottomBtnIcon) then
		self:SetWndEasyImage(iconTrans,bottomBtnIcon)
	end

	local canBuy = giftData.canBuy
	self:SetWndImageGray(iconTrans, not canBuy)
	CS.ShowObject(gouImageTrans, not canBuy)

	self:SetWndText(nameText,giftName)
	self:InitTextLineWithLanguage(nameText, -30)
	self:InitTextSizeWithLanguage(nameText, -2)
	self:SetWndClick(item,function()

		if self._giftTabIndex ~= itempos then
			self._giftTabIndex = itempos
			self:OnClickGiftNew(itempos)

		end
	end)
end

function UIActDiscsSn:InitItemList(itemList)
	local root = self.mItemBgNew
	local firstItem = self:FindWndTrans(root, "FirstItem")
	local itemScroll = self:FindWndTrans(root,"ItemScroll")

	local InstanceID = root:GetInstanceID()
	local rewardNum = #itemList
	local firstReward = itemList[1]
	local resultReward = {}
	for i = 2, rewardNum do
		table.insert(resultReward, itemList[i])
	end

	-- self:OnDrawCommonItemCell(nil, firstItem, firstReward, 1)

	local rewardListKey = "uiRewardList"..InstanceID
	local uiRewardList = self._uiRewardList[rewardListKey]
	if uiRewardList then
		uiRewardList:RefreshData(itemList)
	else
		uiRewardList = self:GetUIScroll(rewardListKey)
		self._uiRewardList[rewardListKey] = uiRewardList
		uiRewardList:Create(itemScroll,itemList,function(...) self:OnDrawCommonItemCell(...) end)
		uiRewardList:EnableScroll(true,true)
	end
end

function UIActDiscsSn:SetSpineBgEffect(effTrans)
	--添加特效显示
	if not self._heroBgEffectList then return end

	local heroBgEffectName = self._heroBgEffectList[self._giftIndex]
	if string.isempty(heroBgEffectName) then
		CS.ShowObject(effTrans, false)
		return
	end

	local key = "HeroBgEff"..heroBgEffectName
	for k,v in pairs(self._heroEffectKeyList) do
		if k ~= key then
			local oldEff = self:FindWndEffectByKey(k)
			if oldEff then
				local dpTrans = oldEff:GetDisplayTrans()
				if CS.IsValidObject(dpTrans)  then
					--CS.ShowObject(dpTrans, false)
					oldEff:SetVisible(false)
				end
			end
		end
	end
	local dpEff = self:FindWndEffectByKey(key)
	if dpEff then
		local dpTrans = dpEff:GetDisplayTrans()
		if CS.IsValidObject(dpTrans)  then
			--CS.ShowObject(dpEff, true)
			dpEff:SetVisible(true)
		end
	else
		self:CreateWndEffect(effTrans,heroBgEffectName,key,50,false,false)
		self._heroEffectKeyList[key] = key
	end


	CS.ShowObject(effTrans, true)
end



function UIActDiscsSn:ChangeStarList(id)
	for i, v in pairs(self._starList) do
		local on = self:FindWndTrans(v,"OnImage")
		CS.ShowObject(on,i == id)
	end
end

function UIActDiscsSn:OnClickGiftNew(itempos)
	if self._giftIndex > 0 then
		local trans = self._giftTransList[self._giftIndex]
		self:ChangeGiftImageNew(trans,false)
	end
	local trans = self._giftTransList[itempos]
	self:ChangeGiftImageNew(trans,true)
	self._giftIndex = itempos

	self:RefreshDateNew()
end
function UIActDiscsSn:TabListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local iconBg = self:FindWndTrans(item,"IconBg")
	local icon = self:FindWndTrans(item,"Icon")
	local selImg = self:FindWndTrans(item,"SelImg")
	local text = self:FindWndTrans(item,"Text")

	local moreInfo = itemdata.cMoreInfo

	self:SetWndText(text,itemdata.name)
	if not string.isempty(moreInfo[5])then
		local arr = string.split(moreInfo[5],"=")
		if LxUiHelper.IsImgPathValid(arr[1]) then
			self:SetWndEasyImage(icon,arr[1],function ()
				CS.ShowObject(icon,true)
				if not string.isempty(arr[2])then
					icon.localScale = Vector2.New(tonumber(arr[2]),tonumber(arr[2]))
				end
			end)
		end
	end
	CS.ShowObject(selImg,itempos == self._giftIndex)
	if not string.isempty(moreInfo[9])then
		local arr = string.split(moreInfo[9],"=")
		if LxUiHelper.IsImgPathValid(arr[1]) then
			self:SetWndEasyImage(iconBg,arr[1],function ()
				CS.ShowObject(iconBg,true)
				if not string.isempty(arr[2])then
					iconBg.localScale = Vector2.New(tonumber(arr[2]),tonumber(arr[2]))
				end
			end)
		end
	end

	self:SetWndClick(item,function ()
		self:OnClickTab(itempos)
	end)
end

function UIActDiscsSn:InitData()
	local sid 				= self._sid
	local activityData 		= gModelActivity:GetActivityBySid(sid)
	if not activityData then return end

	self._endTime 			= tonumber(activityData.endTime)

	local activityWedData = gModelActivity:GetWebActivityDataById(sid)
	if not activityWedData then return end
	local config = activityWedData.config

	local showScene = config.showScene or 0
	if showScene == 1 then
		gModelActivity:OnActivitySpecialOpReq(sid, 1, nil, ModelActivity.CANCEL_RED_POINT, "1")
	end

	self._config = config
	local isNew = config.isNew or 0
	self._isNew = isNew

	self._themeType = config.theme or 1
	self._introPath = config.headline
	self._introPos = LxDataHelper.ParseVector2NotEmpty2(config.headlineCoord,"|")
	self._singleImage = config.singleImage
	local timeTipTxt = config.timeTipTxt
	if not string.isempty(timeTipTxt)then
		self._timeTipTxt = timeTipTxt
	end
	if isNew == 1 then
		self:InitDataContent2()
	elseif isNew == 0 then
		self:InitDataContent1()
	elseif isNew == 2 then
		self:InitDataContent3()
	else
		self:InitDataContent1()
	end
	if self._initDrag or isNew ~= 0 then return end
	self._initDrag = true
	self:InitDrag()
end

--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UIActDiscsSn:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:InitData()
	gModelActivity:OnActivityPageReq(self._sid)
end

function UIActDiscsSn:ChangeGiftImage(trans,bool)
	if not trans then
		return
	end
	local RootTrans = self:FindWndTrans(trans,"Root")
	if not RootTrans then
		RootTrans = trans
	end
	local selImage = self:FindWndTrans(RootTrans,"SelImage")

	local nameListRoot = self:FindWndTrans(trans, "NameList")
	local nameText = self:FindWndTrans(nameListRoot,"NameText")
	local SelNameText = self:FindWndTrans(nameListRoot,"SelNameText")

	local Image = self:FindWndTrans(RootTrans,"Image")
	if Image then
		local rotation = bool and Quaternion.Euler(0,0,0) or Quaternion.Euler(0,0,90)
		Image.localRotation = rotation

		local scale = bool and Vector3(1,1,1) or Vector3(0.8,0.8,0.8)
		RootTrans.localScale = scale
	end

	CS.ShowObject(selImage,bool)
	CS.ShowObject(nameText,not bool)
	CS.ShowObject(SelNameText,bool)
end

function UIActDiscsSn:UIDragOnDrag(dragKey,eventData)
	local moveX = self.mViewMove.transform.localPosition.x
	if(not (self._bDrag and self._bMove))then
		return
	end
	if(moveX > self._distance )then
		self:MoveRoot(1)
		self._bDrag = false
		self._bMove = false
	elseif(moveX < - self._distance)then
		self:MoveRoot(2)
		self._bDrag = false
		self._bMove = false
	end
end

function UIActDiscsSn:InitCommand()
	self._func = self:GetWndArg("func")
	self._sid = self:GetWndArg("sid")
	if not self._sid then
		local dataList = gModelActivity:GetActivityDataByModelId(ModelActivity.DISCOUNTS_SKIN)
		if dataList[1] then
			self._sid = dataList[1].sid
		else
			return
		end
	end
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end

	self._giftTabIndex = 1

	self._rootList =
	{
		self.mRoot1,
		self.mRoot2,
	}

	self._clickBuy = false
	self._isShowGiftScroll = false
	self._isForeign = gLGameLanguage:IsOtherLngRegion()
	self:SetWndText(self:FindWndTrans(self.mCloseBtnNew, "TxtClose"),ccClientText(41102))

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActDiscsSn:DragSetGiftScroll(oldIndex, newIndex, needJump)
	if oldIndex and oldIndex > 0 then
		local trans = self._giftTransList[oldIndex]
		self:ChangeGiftImage(trans,false)
	end
	local trans = self._giftTransList[newIndex]
	self:ChangeGiftImage(trans,true)

	if needJump and self._uiGift1List then
		self:JumpTargetGift(newIndex)
	end
end

function UIActDiscsSn:RefreshContent1()
	local list = self._pageData
	self._giftLen = #list

	self._isShowGiftScroll = self._giftLen > 1
	if self._isShowGiftScroll then
		self:InitGiftList()
	else
		self:InitStarScroll()
		self:RefreshDate(true)
	end

	CS.ShowObject(self.mContent1, true)
	CS.ShowObject(self.mContent2, false)
	CS.ShowObject(self.mAniRoot, true)
end
function UIActDiscsSn:OnClickTab(index)
	local uiList = self._uiList
	local giftIndex = self._giftIndex
	if not uiList then return end
	self._giftIndex = index
	if giftIndex then
		uiList:DrawItemByIndex(giftIndex)
	end
	uiList:DrawItemByIndex(index)
	self:RefreshShowItem()
end

function UIActDiscsSn:SetAttr(trans, attr, isAll)
	local title = CS.FindTrans(trans, "Title")
	local s = string.replace(isAll and ccClientText(17429) or ccClientText(17403), " ")
	self:SetWndText(title, s)
	attr = string.split(attr, ",")
	local constAttrStr = "#a1# <color=#68e6ac>+#a2#</color>"
	for i, v in ipairs(attr) do
		local addTrans = CS.FindTrans(trans, "Add" .. i)
		local icon = CS.FindTrans(addTrans, "Icon")
		local text = CS.FindTrans(addTrans, "Text")
        v = string.split(v, "=")
        local attrRefId, attrType, attrValue = tonumber(v[1]), tonumber(v[2]), tonumber(v[3])
        local attrName = gModelHero:GetAttributeNameById(attrRefId)
        local attrStr = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId, attrType, attrValue)
        local tempStr = string.replace(constAttrStr, attrName, attrStr)
		self:SetWndText(text, tempStr)
		local res = gModelHero:GetAttributeIconById(attrRefId)
		self:SetWndEasyImage(icon, res)
		CS.ShowObject(addTrans, true)
    end

	local layout = trans:GetComponent(typeof(UnityEngine.UI.HorizontalLayoutGroup))
	self.layoutTimer1 = LxTimer.DelayTimeCall(function()
		layout.enabled = false
		layout.enabled = true
		self.layoutTimer2 = LxTimer.DelayTimeCall(function()
			layout.enabled = false
			layout.enabled = true
		end, 0.1)
	end, 0.1)
end

function UIActDiscsSn:OnClickClose()
	if self._isNew ~= 0 then
		return
	end

	self:WndClose()
end

function UIActDiscsSn:PlayHeroSound()
	local heroEffRefId = self._heroEffRefId
	if not heroEffRefId then end
	local heroEffRef = gModelHero:GetShowEffectById(heroEffRefId)
	if not heroEffRef then return end
	gModelHero:PlayHeroRoleSound(heroEffRef.heroType, heroEffRefId)
end

function UIActDiscsSn:RewardItemIconList(item,itemdata,itempos)
	CS.ShowObject(item,itemdata)
	if not item or not itemdata then return end
	local icon = self:FindWndTrans(item,"Icon")
	local text = self:FindWndTrans(item,"Text")

	self:SetWndText(text,itemdata.itemNum)
	self:SetWndEasyImage(icon,gModelItem:GetItemIconByRefId(itemdata.itemId))
	self:SetWndClick(item,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
end

function UIActDiscsSn:OnActivityPageResp(pb)
	local sid = pb.sid
	if sid ~= self._sid then return end

	self:ResetActivePageData(pb)
	self:RefreshView()
end

function UIActDiscsSn:RefreshView()
	local viewType = self._isNew
	if viewType == 1 then
		self:RefreshContent2()
	elseif viewType == 0 then
		self:RefreshContent1()
	elseif viewType == 2 then
		self:RefreshContent3()
	end
end

function UIActDiscsSn:GiftListItem(list,item,itemdata,itempos)
	self._giftTransList[itempos] = item
	self:ChangeGiftImage(item,false)
	local RootTrans = self:FindWndTrans(item,"Root")
	local img = self:FindWndTrans(RootTrans,"Image")
	local icon = self:FindWndTrans(RootTrans,"Icon")
	local selImage = self:FindWndTrans(RootTrans,"SelImage")
	local selBg = self:FindWndTrans(RootTrans,"SelImage/Image")
	local nameListRoot = self:FindWndTrans(item, "NameList")
	local nameText = self:FindWndTrans(nameListRoot,"NameText")
	local SelNameText = self:FindWndTrans(nameListRoot,"SelNameText")
	--local rateText = self:FindWndTrans(RootTrans,"RateBg/RateText")
	--local eff = self:FindWndTrans(nameListRoot,"EffParent/Eff")
	local InstanceID = item:GetInstanceID()
	if img and self._tabImg then
		self:SetWndEasyImage(img,self._tabImg)
	end
	if self._choseImg then
		local arr = string.split(self._choseImg,"=")
		if arr[1] == "1" then
			CS.ShowObject(selBg,true)
			self:SetWndEasyImage(selBg,arr[2])
		else
			CS.ShowObject(selBg,false)
			self:CreateWndSpine(selImage,arr[2],InstanceID,false)
		end
	else
		CS.ShowObject(selBg,true)
	end
	local giftData = itemdata
	local giftName = giftData.name
	local bottomBtnIcon  = giftData.bottomBtnIcon

	if LxUiHelper.IsImgPathValid(bottomBtnIcon) then
		self:SetWndEasyImage(icon,bottomBtnIcon)
	end

	self:SetWndText(nameText,giftName)
	self:SetWndText(SelNameText,giftName)
	self:SetWndClick(item,function()
		self._giftTabIndex = itempos
		self:OnClickGift(itempos)
	end)
end

--设置形象
function UIActDiscsSn:SetSpineNew(paintTans, heroRefId, spinePos, scale)
	local effRef = gModelHero:GetShowEffectById(heroRefId)
	if not effRef then return end

	local heroDrawing = effRef.heroDrawing
	local InstanceID = paintTans:GetInstanceID()
	local spine = heroDrawing
	local key = "spine"..InstanceID..spine
	if(self._oldSpine and self._oldSpine ~= spine and self._oldKey and self._oldKey ~= key)then
		for k,v in pairs(self._spineKeyList) do
			local oldSpine = self:FindWndSpineByKey(k)
			if oldSpine then
				oldSpine:SetVisible(false)
			end
		end
	end

	local newSpine = self:FindWndSpineByKey(key)
	if not newSpine then
		self:CreateWndSpine(paintTans,spine,key,false,function(dpSpine)
			dpSpine:SetVisible(false)

			local dpTrans = dpSpine:GetDisplayTrans()
			dpTrans.anchorMin = Vector2.New(0.5,0.5)
			dpTrans.anchorMax = Vector2.New(0.5,0.5)
			--dpSpine:SetFlipX(ref.flip == 1)
			dpSpine:SetScale(scale or 0.5)
			if not (string.isempty(spinePos) or spinePos == "0") then
				local showIconPos = string.split(spinePos,",")
				dpTrans.localPosition = Vector2.New(tonumber(showIconPos[1]),tonumber(showIconPos[2]))
			end
			self:OnClickSpineFunc(dpSpine,heroRefId)
		end)
		self._spineKeyList[key] = true
	else
		newSpine:SetVisible(false)
		self:OnClickSpineFunc(newSpine,heroRefId)
	end

	self._oldKey = key
	self._oldSpine = spine
end
function UIActDiscsSn:RefreshForeign()
	if self._isVie then
		self.mAddObj1.localScale=Vector3.one * 0.85
		self.mAddObj2.localScale=Vector3.one * 0.85
	end
end
------------------------------------------------------------------
return UIActDiscsSn


