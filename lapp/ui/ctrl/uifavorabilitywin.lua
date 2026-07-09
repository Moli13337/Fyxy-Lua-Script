---
--- Created by Administrator.
--- DateTime: 2024/4/18 18:17:38
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFavorabilityWin:LWnd
local UIFavorabilityWin = LxWndClass("UIFavorabilityWin", LWnd)

local typeofRenderer = typeof(UnityEngine.Renderer)
local typeofCanvas = typeof(UnityEngine.Canvas)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFavorabilityWin:UIFavorabilityWin()
	self._careerType = 0
	self._raceType = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFavorabilityWin:OnWndClose()
	LWnd.OnWndClose(self)
    self._rendererList = nil
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFavorabilityWin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFavorabilityWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    
    if self._isEnus then
        self:SetAnchorPos(self.mImgFlag, Vector2.New(50, -135))
    end 
    
	self:SetWndText(self.mTxtFavor,ccClientText(41305))
	self:SetWndText(self.mTxtTitleAttr,ccClientText(18223))
	self:SetWndText(self.mTextTitle,ccClientText(41306))
	self:SetWndText(self.mTxtReturn,ccClientText(41102))
	self:InitMessage()
	self:OnUpdateLeveExp()
	self:UpdateAttrs()
	self:InitHeroShenList()
	self:InitRaceTypeList()
	self:InitCareerTypeList()
    self:SetHideTop(true)
    self:SetHideBottom(true)
    self:InitLoveLvOrder()
end

function UIFavorabilityWin:InitHeroShenList()
    CS.ShowObject(self.mHeroShenList, true)
    self.heroItemRed = {}
    local allListData = self:GetHeroList()
    local uiHeroShenList = self._uiHeroShenList
    if not uiHeroShenList then
        uiHeroShenList = self:GetUIScroll("mFavorHeroList")
        self._uiHeroShenList = uiHeroShenList
        uiHeroShenList:Create(self.mHeroShenList, allListData, function(...)
            self:OnDrawHeroShenCell(...)
        end, UIItemList.SUPER_GRID, false)
        local superList = uiHeroShenList:GetList()
        superList:EnableLoadAnimation(true)
        superList:SetLoadAnimationScale(0.2, 0.15)
        superList:RefreshList()
    else
        uiHeroShenList:RefreshList(allListData)

        local superList = uiHeroShenList:GetList()
        -- if self._saveHeroNum and self._saveHeroNum == heroNum then
        --     superList:DrawAllItems(false)
        -- else
        --     superList:MoveToPos(1, 0)
        --     superList:DrawAllItems(true)
        -- end
            superList:MoveToPos(1, 0)
            superList:DrawAllItems(true)
    end
end
function UIFavorabilityWin:OnUpdateLeveExp()
	local refs = GameTable.CharacterFavorabilityAttrRef
	local nexLoveExp = refs[gModelHero._loveTotalLevel].exp
	if refs[gModelHero._loveTotalLevel+1] then --下级
		nexLoveExp = refs[gModelHero._loveTotalLevel+1].exp
	end
	self:CreateWndEffect(self.mEffectLove,"fx_haogandu_yeti","haogandulove_yeti",100,nil,nil,nil,nil,nil,true)
	self:CreateWndEffect(self.mImgLove,"fx_haogandu","haogandulove",100,nil,nil,nil,nil,nil,true,nil,function()
        if not self._rendererList then
            local rendererList = self.mEffectLove:GetComponentsInChildren(typeofRenderer, true)
            self._rendererList = rendererList:ToTable()
        end-- 初0.25
        local temp = (gModelHero._loveTotalValue/nexLoveExp)*0.4
        for k,v in ipairs(self._rendererList) do
            local material = v.material
            if material then
                material.mainTextureOffset = Vector2(0,0.26-temp)
            end
        end
    end)
	self:SetWndText(self.mTxtLv,gModelHero._loveTotalLevel)
	self:SetWndText(self.mTxtProgress,gModelHero._loveTotalValue.."/"..nexLoveExp)
end
function UIFavorabilityWin:PlayRaceBtnAni()

    local isShow = self._showRaceBtnList
    CS.ShowObject(self.mLine1, not isShow)
    CS.ShowObject(self.mLine2, isShow)
    CS.ShowObject(self.mUnfoldBtn, not isShow)
	local sizeY = isShow and -583 or -533
    local size = Vector2.New(self.mHeroShenList.sizeDelta.x, sizeY)
    self.mHeroShenList.sizeDelta = size
end

function UIFavorabilityWin:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local numType,refId,value = itemdata.type,itemdata.refId,itemdata.value
	local target = itemdata.target
	if AttrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon)
	end

	if AttrName then
		local name = gModelHero:GetAttributeNameById(refId)
		self:SetWndText(AttrName,name)
	end

	if AttrValue then

		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
		self:SetWndText(AttrValue,"+"..valueStr)
	end
end

function UIFavorabilityWin:InitMessage()
	self:WndEventRecv(EventNames.FAVORABILITY_EXP_UPDATE,function ()
		self:OnUpdateLeveExp()
		self:InitHeroShenList()
        self:UpdateAttrs()
	end)

	self:SetWndClick(self.mReturnBtn,function() self:WndClose() end)
	self:SetWndClick(self.mUnfoldBtn, function()
        -- 展开按钮
        if not self._showRaceBtnList then
            self._showRaceBtnList = true
            self:PlayRaceBtnAni()
        end
    end)
    self:SetWndClick(self.mPackBtn, function()
        -- 收起按钮
        if self._showRaceBtnList then
            self._showRaceBtnList = false
            self:PlayRaceBtnAni()
        end
    end)
    self:SetWndClick(self.mShowAllBtn, function()
        -- 收起按钮
        if self._showRaceBtnList then
            self._showRaceBtnList = false
            self:PlayRaceBtnAni()
        end
    end)
    self:SetWndClick(self.mImgHelp, function()
		GF.OpenWnd("UIBzTips",{refId = 161})
    end)
    self:SetWndClick(self.mImgFlag, function()
		GF.OpenWnd("UIFavorabilityAttr")
    end)
    self:SetWndClick(self.mImgLoveBtn, function()
		GF.OpenWnd("UIFavorabilityAttr")
    end)
end

function UIFavorabilityWin:GuideScrollToIndex(index)
    local uiHeroShenList = self._uiHeroShenList
    if not uiHeroShenList then
        return nil
    end
    local list = uiHeroShenList:GetList()
    list:MoveToPos(index)
    self:DelaySendFinish(0.2)
end

function UIFavorabilityWin:InitRaceTypeList()
    local data = {
        wndClass = self,
        listTrans = self.mHeroRaceList,
        showType = UIHeroRaceList.TYPE_NORMAL,
        callbackFunc = function(raceType)
            if not self:IsWndValid() then
                return
            end
            if raceType == self._raceType then
                return
            end
            self._raceType = raceType
            self:InitHeroShenList()
        end,
        checkSelFunc = function(raceType)
            if not self:IsWndValid() then
                return
            end
            return self._raceType == raceType
        end,
    }
    self:GetUIHeroRaceList(data)
end
function UIFavorabilityWin:InitLoveLvOrder()
    local canvas = self.mTxtLv:GetComponent(typeofCanvas)
    if not canvas then
        canvas = self.mTxtLv.gameObject:AddComponent(typeofCanvas)
    end
    canvas.overrideSorting = true
    canvas.sortingLayerName = self:GetWndSortLayer()
    canvas.sortingOrder = self:GetWndSortOrder()+2
end
function UIFavorabilityWin:UpdateAttrs()
	local curlist = gModelHero:GetTotalLoveAttrs(nil,true)
	local uiAttrList = self._uiAttrList
	if uiAttrList then
		uiAttrList:RefreshList(curlist)
	else
		uiAttrList = self:GetUIScroll("favorAttrList")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,curlist,function(...) self:OnDrawAttrCell(...) end)
	end
end

function UIFavorabilityWin:InitCareerTypeList()
    local list = self:GetCareerTypeList()
    local uiCareerTypeList = self._uiCareerTypeList
    if uiCareerTypeList then
        uiCareerTypeList:RefreshList(list)
    else
        uiCareerTypeList = self:GetUIScroll("FavorCareerList")
        self._uiCareerTypeList = uiCareerTypeList
        uiCareerTypeList:Create(self.mCareerTypeList, list, function(...)
            self:OnDrawCareerTypeCell(...)
        end)
    end
end
function UIFavorabilityWin:OnClickCareerTypeFunc(refId)
    if self._careerType == refId then
        return
    end
    self._careerType = refId
	self:InitHeroShenList()

    local uiCareerTypeList = self._uiCareerTypeList
    if not uiCareerTypeList then
        return
    end
    local uiList = uiCareerTypeList:GetList()
    uiList:RefreshList()
end
function UIFavorabilityWin:GetHeroList()
    local allListData = {}
	local refs = GameTable.CharacterRef
    local curTimeSpan = GetTimestamp()
	for k,v in pairs(refs) do
        local isOpen = gModelHero:GetHeroActShowState(v.refId,curTimeSpan)
		local bAdd = isOpen and (self._careerType == 0 or v.careerType == self._careerType) and (self._raceType == 0 or v.raceType == self._raceType)
		if v.maxFavorability and v.maxFavorability>0 and bAdd then
			table.insert(allListData,v)
		end
	end

	table.sort(allListData,function (a,b)
		local aState = gModelHero:IsActiveHeroEffRefId(a.refId) and 1 or 2
		local bState = gModelHero:IsActiveHeroEffRefId(b.refId) and 1 or 2
		if aState ~= bState then
			return aState<bState
		else
			if a.quality~=b.quality then
				return a.quality>b.quality
			else
				return a.refId<b.refId
			end
		end
	end)
	return allListData
end
function UIFavorabilityWin:OnDrawCareerTypeCell(list, item, itemdata, itempos)
    local RaceIconTrans = self:FindWndTrans(item, "RaceIcon")
    local SelImgTrans = self:FindWndTrans(item, "SelImg")
    local icon = itemdata.icon
    local refId = itemdata.refId
    local show = icon ~= nil
    local isSel = false
    if show then
        isSel = self._careerType == refId
        self:SetWndEasyImage(RaceIconTrans, icon)
    end
    CS.ShowObject(RaceIconTrans, show)
    CS.ShowObject(SelImgTrans, isSel)
    self:SetWndClick(RaceIconTrans, function()
        self:OnClickCareerTypeFunc(refId)
    end, LSoundConst.CLICK_PAGE_COMMON)
end

function UIFavorabilityWin:OnDrawHeroShenCell(list, item, itemdata, itempos)
    if self:IsWndClosed() then
        return
    end
    local aniRootTrans = self:FindWndTrans(item, "AniRoot")
    local QualityImgTrans = self:FindWndTrans(aniRootTrans, "QualityImg")
    local HeroMapImgTrans = self:FindWndTrans(aniRootTrans, "HeroMapImg")
    local HeroBgTrans = self:FindWndTrans(aniRootTrans, "HeroBg")
    local HeronNameTrans = self:FindWndTrans(aniRootTrans, "HeronName")
    local TxtLove = self:FindWndTrans(aniRootTrans, "TxtLove")
    local ImgLove = self:FindWndTrans(aniRootTrans, "ImgLove")

    if gLGameLanguage:IsJapanVersion() then
        LxUiHelper.SetSizeWithCurAnchor(HeronNameTrans,1,40)
    end

    local ImgMask = self:FindWndTrans(aniRootTrans, "ImgMask")
    local redPointTrans = self:FindWndTrans(aniRootTrans, "redPoint")

    local refId = itemdata.refId

    local effRef = GameTable.CharacterEffectRef[itemdata.refId]
	local loveLevel = gModelHero:GetHeroLoveLvByRefId(refId)
    local active = gModelHero:IsActiveHeroEffRefId(refId)
    local name = ccLngText(effRef.name)
    self:SetWndText(HeronNameTrans, name)
	self:SetWndText(TxtLove,loveLevel or 0)
    --self:InitTextShowWithLanguage(HeronNameTrans)
	CS.ShowObject(ImgMask,not active)
	CS.ShowObject(ImgLove,active)
	CS.ShowObject(TxtLove,active)

    local quality = itemdata.quality
    if quality then
        local listBgBig = gModelItem:GetListBgBigByQuality(quality)
        self:SetWndEasyImage(HeroBgTrans, listBgBig)
        local heorBook1Bg = gModelItem:GetHeorBook1BgByQuality(quality)
        self:SetWndEasyImage(QualityImgTrans, heorBook1Bg)
    end
    local iconBig = effRef and effRef.iconBig
    if iconBig then
        self:SetWndEasyImage(HeroMapImgTrans, iconBig, function()
            CS.ShowObject(HeroMapImgTrans, true)
        end, true)
    end

    self:SetWndClick(item, function()
		if not active then
			if effRef.skinType<=1 and (not effRef.needStar or effRef.needStar <= 1) then --1阶
				GF.ShowMessage(string.replace(ccClientText(41319),ccLngText(effRef.name)))
			else
				GF.ShowMessage(string.replace(ccClientText(41319),effRef.needStar..ccLngText(effRef.name)))
			end
		else
			local para =
			{
				refId = refId,
				showTab = true,
				selectIndex = 5
			}
			gModelGeneral:OpenHeroStarPre(para)
		end
    end)
    if not self.heroItemRed[refId] then
        self.heroItemRed[refId]= gModelHero:GetFavorabilityGiftRed(refId) and 1 or 0
    end
    CS.ShowObject(redPointTrans,self.heroItemRed[refId]>0)

end
function UIFavorabilityWin:GetCareerTypeList()
    local list = {}
    table.insert(list, {
        refId = UIHeroRaceList.ALL_RACE_REFID,
        icon = "public_race_0",
    })
    for k, v in pairs(GameTable.CharacterCareerRef) do
        table.insert(list, {
            refId = k,
            icon = v.jobIcon
        })
    end
    table.sort(list, function(a, b)
        return a.refId < b.refId
    end)
    local listLen = #list
    local allRaceNum = gModelHero:GetAllRaceNum()
    local loseNum = allRaceNum - listLen
    if loseNum > 0 then
        for i = 1, loseNum do
            table.insert(list, {
                show = false,
            })
        end
    end

    return list
end

function UIFavorabilityWin:GetGuideHeroIndex(refId)
    local uiHeroShenList = self._uiHeroShenList
    if not uiHeroShenList then
        self:DelaySendFinish(0.2)
        return nil
    end
    local list = uiHeroShenList:GetList()
    local datasize = list:GetDataSize()
    for k=1, datasize do
        local data = list:GetDataByIndex(k)
        if data and data.refId == refId then
            return k - 1
        end
    end
    return nil
end

------------------------------------------------------------------
return UIFavorabilityWin