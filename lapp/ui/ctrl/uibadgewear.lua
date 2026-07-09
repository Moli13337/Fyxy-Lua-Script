---
--- Created by Administrator.
--- DateTime: 2025/9/12 10:09:36
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBadgeWear:LWnd
local UIBadgeWear = LxWndClass("UIBadgeWear", LWnd)
------------------------------------------------------------------

local YXUIPointUtil = CS.YXUIPointUtil

---@type LUIHeroObject
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")

---@type LUIDrawingCtrl
local LUIDrawingCtrl = LxRequire("LApp.UI.Display.LUIDrawingCtrl")

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBadgeWear:UIBadgeWear()
	---@type table<string,LUIHeroObject>
	self._uiLiHuiObjList = nil

	---@type LUIHeroObject
	self._curUILiHuiObj = nil            -- 当前立绘

	self._uiLiHuiCacheCnt = 0

	---@type number 当前灵魂页，对应 BadgePositionRef
	self._curBadgePage = 1

	self._uiDrawingCtrl = nil

	self.oneKeyState = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBadgeWear:OnWndClose()
	self._curUILiHuiObj = nil
	LUtil.ClearHashTable(self._uiLiHuiObjList)
	self._uiLiHuiObjList = nil

	if self._uiDrawingCtrl then
		self._uiDrawingCtrl:Destroy()
		self._uiDrawingCtrl = nil
	end

	local cbFunc = self._cbFunc
	self._cbFunc = nil
	if cbFunc then
		cbFunc()
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBadgeWear:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBadgeWear:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitWearTrans()
	self:InitText()
	self:InitConfigData()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshCutInfo()
	self:RefreshViewShow()
	self:RefreshView()
	FireEvent(EventNames.CHANGE_MAIN_BTN,4)
end

function UIBadgeWear:RefreshHeroByIndex(heroIndex)
	if not self:IsWndValid() then return end
	if not heroIndex or heroIndex < 1 then return end

	local heroData = self._cutHeroList[heroIndex]
	if not heroData then return end

	self:RefreshHeroData(heroData, heroIndex)
end

function UIBadgeWear:OnClickHeroRaceImg()
	CS.ShowObject(self.mTypeImgMask, true)
	self:ShowRaecKeZhiInfo()
end

function UIBadgeWear:OnMsgXXXXX()
end

function UIBadgeWear:OnEventXXXXX()
end

function UIBadgeWear:CreateStarList(star)
	local img,showNum = gModelHero:GetHeroStarImg(star)
	local list = {}
	for i = 1, showNum do
		table.insert(list, { show = true, img = img })
	end

	local uiStarList = self._uiStarList
	if uiStarList then
		uiStarList:RefreshList(list)
	else
		uiStarList = self:GetUIScroll("uiStarList")
		self._uiStarList = uiStarList
		uiStarList:Create(self.mStarList, list, function(...)
			self:OnDrawStarCell(...)
		end)
	end
end

function UIBadgeWear:RefreshHeroData(data,curIndex)
	--LResRelease.WebglRelease()
	LxResUtil.RunUnusedAssetUnload()

	local id = data.id
	self._refId = data.refId
	self._id = id
	self._heroIndex = curIndex
	self._serverData = data
	self:RefreshViewShow()
	self:RefreshView()
end

function UIBadgeWear:RefreshView()
	self.oneKeyState = 0
	local id = self._id
	if not id then return end

	local talentTransInfoList = self._talentTransInfoList
	local badges = gModelBadge:GetHeroWearBadges(id) or {}

	local badgeType = LItemTypeConst.TYPE_BADGE
	local page = self._curBadgePage

	local hasCanwear = gModelBadge:HasCanWearBadge(id)
	local hasBadge = nil
	---@type boolean 空位
	local voidPos = false
	local hasWear = false
	for i,v in ipairs(talentTransInfoList) do
		local RootTrans = v.RootTrans
		local badgeId = badges[i]
		hasBadge = badgeId ~= nil
		local isOpen,str = true,""
		local isEmpty = false
		local showRp = false
		if hasBadge then
			local baseClass = self:GetCommonIcon(RootTrans)
			baseClass:Create(RootTrans)
			baseClass:SetCommonReward(badgeType,badgeId)
			baseClass:EnableShowNum(false)
			baseClass:SetNoShowLv(false)
			baseClass:DoApply()
			hasWear = true
		else
			isOpen,str = gModelBadge:IsLockBadgeSlot(id,page,i)
			if isOpen then
				isEmpty = true
				showRp = hasCanwear
				voidPos = true
			end
		end

		CS.ShowObject(v.redPoint,showRp)
		self:SetWndText(v.LockTxt,str)
		CS.ShowObject(v.LockDiv,not isOpen)
		CS.ShowObject(v.Empty,isEmpty)
		CS.ShowObject(RootTrans,hasBadge)
		self:SetWndClick(v.IconTrans,function()
			self:OnClickBadgeIcon(i,badgeId,isOpen,str)
		end)
	end
	local oneKeyState = 0
	if voidPos and hasCanwear then--一键穿戴
		oneKeyState = 1
	elseif hasWear and (not voidPos or not hasCanwear) then
		oneKeyState = 2
	end
	self.oneKeyState = oneKeyState
	CS.ShowObject(self.mBtnWear,oneKeyState == 0 or oneKeyState == 1)
	CS.ShowObject(self.mBtnUnWear,oneKeyState == 2)
	self:SetRed(self.mBtnWear,gModelBadge:GetBadgeWearRed(id))
end

function UIBadgeWear:RemoveTheOlderCacheLH(exceptHero)
	local olderObj = nil
	local minTime = 0
	local olderKey = nil
	for k, v in pairs(self._uiLiHuiObjList) do
		if not v:IsShow() and v ~= exceptHero and (not olderObj or v:GetLastHideTime() < minTime) then
			olderObj = v
			minTime = v:GetLastHideTime()
			olderKey = k
		end
	end
	if olderObj then
		self._uiLiHuiObjList[olderKey] = nil
		self._uiLiHuiCacheCnt = self._uiLiHuiCacheCnt - 1
		olderObj:Destroy()
	end
end

function UIBadgeWear:InitConfigData()
	---@type number 是否显示左右切换按钮,默认不显示
	local badgeShowCutHero = gModelHero:GeConfigByKey("badgeShowCutHero")
	if not badgeShowCutHero then
		badgeShowCutHero = 0
		if LOG_INFO_ENABLED then
			printInfoNR("HeroConfigRef 配置 badgeShowCutHero 显示左右切换按钮，1为显示，默认为0（不显示）")
		end
	end
	self._badgeShowCutHero = badgeShowCutHero == 1
end

function UIBadgeWear:OnClickBtnOpt(bWear)
	if self.oneKeyState == 0 then return end
	local cmd = bWear and 1 or 3
	gModelBadge:BadgeWearReq(cmd,self._id,nil)
end

function UIBadgeWear:OnClickBadgeIcon(index,badgeId,isOpen,str)
	if not isOpen then
		GF.ShowMessage(str)
		return
	end
	if badgeId then --已装配
		GF.OpenWnd("UIBrandTips",{
			from = true,
			refId = badgeId,
			index=index,
			heroId= self._id
		})
	else--可装配
		GF.OpenWnd("UIBrandWearPop",{
			heroId = self._id,
			index = index
		})
	end
end

function UIBadgeWear:InitTalentTransInfo(item)
	local CommonUITrans = self:FindWndTrans(item,"CommonUI")
	local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")
	local Lock = self:FindWndTrans(IconTrans,"Lock")
	CS.ShowObject(Lock,false)

	local ImgSel = self:FindWndTrans(CommonUITrans,"ImgSel")
	CS.ShowObject(ImgSel,false)

	local redPoint = self:FindWndTrans(CommonUITrans,"redPoint")
	CS.ShowObject(redPoint,false)

	return {
		IconTrans = IconTrans,
		RootTrans = self:FindWndTrans(IconTrans,"Root"),
		Empty = self:FindWndTrans(IconTrans,"Empty"),
		LockDiv = Lock,
		LockTxt = self:FindWndTrans(Lock,"LockMask/LockTxt"),
		redPoint = redPoint,
		ImgSel = ImgSel,
	}
end

function UIBadgeWear:OnClickCutHero(optNum)
	if not self:IsWndValid() then return end
	local index = self._heroIndex
	if not index then return end

	local cnt = #self._cutHeroList
	local newIndex = index + optNum
	if newIndex <= 0 then
		newIndex = cnt
	elseif newIndex > cnt then
		newIndex = 1
	end
	self:RefreshHeroByIndex(newIndex)
end

function UIBadgeWear:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnWear,function() self:OnClickBtnOpt(true) end)
	self:SetWndClick(self.mBtnUnWear,function() self:OnClickBtnOpt() end)
	self:SetWndClick(self.mLeftBtn,function() self:OnClickCutHero(-1) end)
	self:SetWndClick(self.mRightBtn,function() self:OnClickCutHero(1) end)
	self:SetWndClick(self.mBtnBook,function() self:OnClickBook() end)

	self:SetWndClick(self.mHeroRaceImg, function() self:OnClickHeroRaceImg() end)
	self:SetWndClick(self.mTypeImgMask, function() CS.ShowObject(self.mTypeImgMask, false) end)
end

function UIBadgeWear:InitMsg()
	-- self:WndEventRecv(EventNames.xxxxx,function (...) self:OnEventXXXXX() end)
	-- self:WndNetMsgRecv(LProtoIds.xxxxx,function(...) self:OnMsgXXXXX(...) end)
	self:WndEventRecv(EventNames.BADGE_BAG_UPDATE_WEAR,function() self:RefreshView() end)
	self:WndEventRecv(EventNames.BADGE_BAG_UPDATE,function() self:RefreshView() end)
end

function UIBadgeWear:ShowRaecKeZhiInfo()
	local canvasRect = LGameUI.GetUICanvasRoot()
	if not self._changePos then
		local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect, self.mTypeImgBg)
		self.mTypeImgBg.localPosition = targetPos - Vector3.New(0, 50, 0)
		self._changePos = true
	end
	local refId = self._refId
	local raceType = gModelHero:GetHeroType(refId)
	if raceType then
		local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
		if raceRef then
			local heroRaceImage = raceRef.heroRaceImage
			local hasRaceImg = not string.isempty(heroRaceImage)
			local str = ""
			if hasRaceImg then
				self:SetWndEasyImage(self.mTypeKeZhiImg, heroRaceImage, function()
					CS.ShowObject(self.mTypeKeZhiImg, true)
				end, true)
			else
				CS.ShowObject(self.mTypeKeZhiImg, false)
				str = ccClientText(31233)
			end
			CS.ShowObject(self.mTypeKZImgDiv, hasRaceImg)
			CS.ShowObject(self.mNoHaveKeZhiTxtDiv, not hasRaceImg)

			self:SetWndText(self.mRaceTypeName,string.replace(ccClientText(10079), ccLngText(raceRef.name)))

			self:SetWndText(self.mNoHaveKeZhiTxt, str)
		end
	end
end

function UIBadgeWear:GetHeroPosById(heroId)
	for i, v in ipairs(self._cutHeroList) do
		if v.id == heroId then
			return i
		end
	end
	return 1
end

function UIBadgeWear:RefreshViewShow()
	local serverData = self._serverData
	if not serverData then return end

	local refId = serverData.refId
	local heroRef = gModelHero:GetHeroRef(refId)
	if not heroRef then return end

	local raceRef = gModelHero:GetHeroRaceRefByRefId(heroRef.raceType)
	if not raceRef then return end

	local id = serverData.id
	local effRef = gModelHero:GetHeroEffectRefById(id)
	if not effRef then return end

	local skinBg = effRef.skinBg
	if string.isempty(skinBg) then
		skinBg = effRef.heroBg
	end
	self:SetWndEasyImage(self.mHeroEffectBg,skinBg)

	self:SetWndEasyImage(self.mHeroBg,raceRef.heroBg,function()
		CS.ShowObject(self.mHeroBg,true)
	end)

	self:SetWndEasyImage(self.mHeroRaceImg,raceRef.icon,function()
		CS.ShowObject(self.mHeroRaceImg,true)
	end)

	self:SetWndEasyImage(self.mHeroZZImg,heroRef.qualityIcon,function()
		CS.ShowObject(self.mHeroZZImg,true)
	end)

	self:SetWndText(self.mNickName,ccLngText(effRef.nickName))
	local nameColor = gModelItem:GetColorByQualityId(heroRef.quality, true)
	if nameColor then
		self:SetXUITextTransColor(self.mNickName,nameColor)
	end

	local heroName = gModelHeroExtra:GetHeroSetName(serverData)
	self:SetWndText(self.mHeroName, heroName)

	local star = serverData.star
	local isHighStar = star > 10
	if isHighStar then
		self:SetWndText(self.mHightStarNewHeroInforText, star - 10)
	else
		self:CreateStarList(star)
	end
	CS.ShowObject(self.mStarList,not isHighStar)
	CS.ShowObject(self.mHightStarNewHeroInfo,isHighStar)

	self:CreateLiHui(effRef)
end

function UIBadgeWear:InitWearTrans()
	local talentTransInfoList = {}
	local talentTransList = {self.mTalent1,self.mTalent2,self.mTalent3,self.mTalent4,
							 self.mTalent5,self.mTalent6,self.mTalent7,self.mTalent8}
	for i,v in ipairs(talentTransList) do
		table.insert(talentTransInfoList,self:InitTalentTransInfo(v))
	end
	self._talentTransInfoList = talentTransInfoList
end

function UIBadgeWear:InitText()
	self:SetWndText(self.mTxtClose,ccClientText(42010))
	self:SetWndButtonText(self.mBtnWear,ccClientText(47512))
	self:SetWndButtonText(self.mBtnUnWear,ccClientText(47515))
	self:SetWndText(self.mTxtName,ccClientText(47578))
	self:SetWndText(self.mBtnBookName,ccClientText(47579))
end

---@param effRef V_HeroEffectRef
function UIBadgeWear:CreateLiHui(effRef)
	if not effRef then return end

	local uiLiHuiObjList = self._uiLiHuiObjList
	if not uiLiHuiObjList then
		uiLiHuiObjList = {}
		self._uiLiHuiObjList = uiLiHuiObjList
	end
	if self._uiDrawingCtrl then
		self._uiDrawingCtrl:Destroy()
		self._uiDrawingCtrl = nil
	end

	local heroDrawing = effRef.heroDrawing

	local action = nil
	---@type LUIHeroObject
	local newUILiHui = uiLiHuiObjList[heroDrawing]
	local curUILiHui = self._curUILiHuiObj
	self._curUILiHuiObj = nil

	if curUILiHui and newUILiHui ~= curUILiHui then
		curUILiHui:ShowHero(false)
	end

	if not newUILiHui then
		newUILiHui = LUIHeroObject:New(self)
		uiLiHuiObjList[heroDrawing] = newUILiHui
		self._uiLiHuiCacheCnt = self._uiLiHuiCacheCnt + 1
		self._curUILiHuiObj = newUILiHui
		newUILiHui:Create(self.mHeroLiHuiPos, heroDrawing, heroDrawing)
		newUILiHui:SetHeroBgParams({
			effRef = effRef,
			lihuiBgTrans = self.mHeroLiHuiBgPos,
			lihuiHdTrans = self.mHeroLiHuiHdPos,
		})
		newUILiHui:SetRectMatch(true)
		newUILiHui:ShowHero(true)

		local scale = 0
		if scale and scale > 0 then
			newUILiHui:SetScale(scale)
		end
		newUILiHui:SetClickFunc(function()
			self.isClickSound = true
			action = gModelHero:GetHeroClickAction(effRef.refId)
			if action and action ~= "" then
				newUILiHui:PlayAni(action, false, nil, nil, true, LSpineAniConst.idle)
				local actionSound = gModelHero:GetHeroClickSound(effRef.refId)
				if actionSound and actionSound ~= "" then
					gLGameAudio:StopSingleSound()
					gLGameAudio:PlaySingleSound(actionSound, function() end)
				end
			end
		end)
		newUILiHui:SetLoadedFunction(function()
			local displaySpine = newUILiHui:GetDpObject()
			if displaySpine then
				displaySpine:SetRaycastTarget(true)
			end
		end)
		newUILiHui:StartLoad()
		if self._uiLiHuiCacheCnt > 4 then
			self:RemoveTheOlderCacheLH(newUILiHui)
		end
	else
		self._curUILiHuiObj = newUILiHui
		newUILiHui:ShowHero(true)
	end

	local uiDrawCtrl = LUIDrawingCtrl:New()
	self._uiDrawingCtrl = uiDrawCtrl
	uiDrawCtrl:SetHeroObject(newUILiHui)
	uiDrawCtrl:SetEffectInfo(self.mHeroLiHuiEffPos, 1, 6, 100)
	uiDrawCtrl:InitHeroEffectInfo(effRef.refId)
	uiDrawCtrl:StartPlay()
end

function UIBadgeWear:OnDrawStarCell(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
	    itemCache = {
			Star = self:FindWndTrans(item, "Star"),
	    }
	    self:SetComponentCache(instanceID, itemCache)
	end
	local Star = itemCache.Star
	self:SetWndEasyImage(Star, itemdata.img, function() CS.ShowObject(Star, true) end)
end

function UIBadgeWear:RefreshCutInfo()
	local sortHeroInfo = gModelHero:GetNewHeroSortList(self._career, self._race)
	local sortHeros = sortHeroInfo and sortHeroInfo.sortHeros or {}
	local cutHeroList = {}
	for i,v in ipairs(sortHeros) do
		if gModelBadge:CheckIsCanWear(v.id) then
			table.insert(cutHeroList,v)
		end
	end

	self._cutHeroList = cutHeroList
	local heroIndex = self:GetHeroPosById(self._id)
	self._heroIndex = heroIndex
	self._serverData = cutHeroList[heroIndex]

	local showCutBtn = false
	if self._badgeShowCutHero then
		showCutBtn = #cutHeroList > 0
	end
	CS.ShowObject(self.mLeftBtn,showCutBtn)
	CS.ShowObject(self.mRightBtn,showCutBtn)
end

function UIBadgeWear:OnClickBook()
	if not gModelFunctionOpen:CheckIsOpened(37000002,true) then return end
	gModelFunctionOpen:Jump(37000002,self:GetWndName())
end

function UIBadgeWear:InitData()
	self._refId = self:GetWndArg("refId")
	self._id = self:GetWndArg("id")
	self._career = self:GetWndArg("career")
	self._race = self:GetWndArg("race")
	self._cbFunc = self:GetWndArg("cbFunc")
	CS.ShowObject(self.mBtnBook,gModelFunctionOpen:CheckIsShow(37000002))
end

------------------------------------------------------------------
return UIBadgeWear