---
--- Created by Administrator.
--- DateTime: 2023/10/21 14:27:24
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubSagaBookNew:LChildWnd
local UISubSagaBookNew = LxWndClass("UISubSagaBookNew", LChildWnd)

local YAOHUI_QUALITY = 100--耀辉
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubSagaBookNew:UISubSagaBookNew()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubSagaBookNew:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubSagaBookNew:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubSagaBookNew:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitText()
    self:InitData()
    self:InitEvent()
    self:InitMsg()
    self:InitCommonListRect()
    self:InitHeroRaceTypeList()
    self:InitCareerTypeList()
    self:RefreshHeroBookListView(false)
end

function UISubSagaBookNew:InitHeroBookList(isTop, findIndex)
    local heroList = self:GetHeroBookList()
    local uiHeroList = self._uiHeroList
    if uiHeroList then
        uiHeroList:RefreshList(heroList)
        if isTop then
            local uiList = uiHeroList:GetList()
            uiList:MoveToPos(1)
        else
            uiHeroList:DrawAllItems()
        end
    else
        uiHeroList = self:GetUIScroll("uiHeroList")
        self._uiHeroList = uiHeroList
        uiHeroList:Create(self.mHeroSpQuaMapList, heroList, function(...)
            self:OnDrawHeroSpCell(...)
        end, UIItemList.SUPER)
    end
    local isempty = #heroList < 1
    CS.ShowObject(self.mNoRecord4, isempty)

    local index = 0
    local titleIndx = 0
    for i, v in ipairs(heroList) do
        if index ~= 0 then
            break
        end
        if not v.showQuaDiv then
            for idx, heroInfo in ipairs(v.heroList) do
                local refId = heroInfo.refId
                local status = gModelHeroBook:FindIsNewActHeroInfoByRefId(refId, true)
                if status then
                    index = i
                    if heroList[i-1].showQuaDiv then index = i-1 end
                    break
                end
            end
        end
    end
    if index == 0 then
        for i, v in ipairs(heroList) do
            if index ~= 0 then
                break
            end
            if not v.showQuaDiv then
                for idx, heroInfo in ipairs(v.heroList) do
                    local refId = heroInfo.refId
                    local rstatus = gModelHeroBook:CheckHeroBookInfoStatusByRefId(refId)
                    if rstatus then
                        index = i
                        if heroList[i-1].showQuaDiv then index = i-1 end
                        break
                    end
                end
            end
        end
    end
    if index ~= 0 then
        uiHeroList:MoveToPos(index)
    end


end

function UISubSagaBookNew:InitEvent()
    self:SetWndClick(self.mHelpBtn, function()
        GF.OpenWndUp("UIBzTips", { refId = 71 })
    end)

    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end)

    --self:SetWndClick(self.mRelationtBtn,function()
    --	GF.OpenWndUp("UISagaBookRelation")
    --end)

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

end

function UISubSagaBookNew:InitMsg()
    self:WndNetMsgRecv(LProtoIds.BookChangeInfoResp, function(...)
        self:RefreshHeroBookListView(false)
    end)

    self:WndNetMsgRecv(LProtoIds.RelationChangeInfoResp, function(...)
        self:UpdateRedPoint()
    end)
end

function UISubSagaBookNew:RefreshHeroBookListView(isTop)
    self:InitHeroBookList(isTop)
    self:UpdateRedPoint()
end

function UISubSagaBookNew:InitHeroRaceTypeList()
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
            self:RefreshHeroBookListView(true)
        end,
        checkSelFunc = function(raceType)
            if not self:IsWndValid() then
                return
            end
            return self._raceType == raceType
        end,
        checkRedPointFunc = function(raceType)
            if not self:IsWndValid() then
                return
            end
            return self:CheckRaceTypeRedPointStatus(raceType)
        end,
    }
    self._uiHeroRcaeList = self:GetUIHeroRaceList(data)
end

function UISubSagaBookNew:InitCareerTypeList()
    local list = self:GetCareerTypeList()
    local uiCareerTypeList = self._uiCareerTypeList
    if uiCareerTypeList then
        uiCareerTypeList:RefreshList(list)
    else
        uiCareerTypeList = self:GetUIScroll("uiCareerTypeList")
        self._uiCareerTypeList = uiCareerTypeList
        uiCareerTypeList:Create(self.mCareerTypeList, list, function(...)
            self:OnDrawCareerTypeCell(...)
        end)
    end
end

function UISubSagaBookNew:CheckRaceTypeRedPointStatus(raceType)
    if not raceType then
        return false
    end
    local showRedPoint = false
    for k, v in pairs(GameTable.CharacterRef) do
        if showRedPoint then
            break
        end
        if raceType == UIHeroRaceList.ALL_RACE_REFID or v.raceType == raceType then
            showRedPoint = gModelHeroBook:CheckHeroBookInfoStatusByRefId(k)
        end
    end
    return showRedPoint
end

function UISubSagaBookNew:InitEmptyList()
    local data = {
        refId = 10005,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
        GetBtnText = self.mEmptyBtnText,
        GetBtn = self.mEmptyBtn
    }

    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UISubSagaBookNew:InitCommonListRect()
    local raceMax = self.mHeroSpQuaMapList.offsetMax
    local raceMin = self.mHeroSpQuaMapList.offsetMin
    self._commonPosList = {
        topPosX = raceMax.x,
        topPosY = raceMax.y,
        botPosX = raceMin.x,
        botPosY = raceMin.y,
    }
end

function UISubSagaBookNew:UpdateRedPoint()
    local red = self:FindWndTrans(self.mRelationtBtn, "RedPoint")
    local isRed = gModelHeroBook:CheckRelationInfoStatus()
    CS.ShowObject(red, isRed)
end

--function UISubSagaBookNew:InitHeroBookList(isTop)
--	local heroList = self:GetHeroBookList()
--	local uiHeroList = self._uiHeroList
--	if uiHeroList then
--		uiHeroList:RefreshList(heroList)
--		if isTop then
--			local uiList = uiHeroList:GetList()
--			uiList:MoveToPos(1)
--		else
--			uiHeroList:DrawAllItems()
--		end
--	else
--		uiHeroList = self:GetUIScroll("uiHeroList")
--		self._uiHeroList = uiHeroList
--		uiHeroList:Create(self.mHeroSpQuaMapList, heroList, function(...)
--			self:OnDrawHeroSpCell(...)
--		end, UIItemList.SUPER)
--	end
--	local isempty = #heroList < 1
--	CS.ShowObject(self.mNoRecord2,isempty)
--	local index = 0
--	for i,v in ipairs(heroList) do
--		if index ~= 0 then break end
--		if not v.showQuaDiv then
--			for idx,heroInfo in ipairs(v.heroList) do
--				local refId = heroInfo.refId
--				local status = gModelHeroBook:FindIsNewActHeroInfoByRefId(refId,true)
--				if status then
--					index = i
--					break
--				end
--			end
--		end
--	end
--	if index == 0 then
--		for i,v in ipairs(heroList) do
--			if index ~= 0 then break end
--			if not v.showQuaDiv then
--				for idx,heroInfo in ipairs(v.heroList) do
--					local refId = heroInfo.refId
--					local rstatus = gModelHeroBook:CheckHeroBookInfoStatusByRefId(refId)
--					if rstatus then
--						index = i
--						break
--					end
--				end
--			end
--		end
--	end
--	if index ~= 0 then
--		uiHeroList:MoveToPos(index)
--	end
--end

function UISubSagaBookNew:OnDrawHeroSpCell(list, item, itemdata, itempos)
    local showQuaDiv = itemdata.showQuaDiv or false
    local QualityDiv = self:FindWndTrans(item, "QualityDiv")
    if QualityDiv then
        if showQuaDiv then
            local QualityImg = self:FindWndTrans(QualityDiv, "QualityImg")
            if QualityImg then
                local quaName = ""
                local quality = itemdata.quality
                if quality then
                    local qualityRef = gModelItem:GetQualityRef(quality)
                    quaName = qualityRef and ccLngText(qualityRef.heroQualityName) or ""
                end
                if quality == YAOHUI_QUALITY then quaName = ccClientText(19792) end
                -- 星辉少女的描述
                --[[
                if itemdata.raceType == 6 then
                    quaName = ccClientText(1010401)
                end
                ]]
                --local color = gModelItem:GetColorByQualityId(quality)
                local str = string.replace(ccClientText(19701), quaName)

                local isForeign = self._isForeign
                local QualityTxt = self:FindWndTrans(QualityImg, "QualityTxt")
                local QualityTxtEn = self:FindWndTrans(QualityImg, "QualityTxtEn")
                local isShow = not isForeign
                if QualityTxt then
                    CS.ShowObject(QualityTxt, isShow)
                    if isShow then
                        self:SetWndText(QualityTxt, str)
                        --if color then
                        --	self:SetXUITextTransColor(QualityTxt, color)
                        --end
                    end
                end

                isShow = isForeign
                if QualityTxtEn then
                    CS.ShowObject(QualityTxtEn, isShow)
                    if isShow then
                        self:SetWndText(QualityTxtEn, str)
                        local heroBookTagColorList = gModelItem:GetHeroBookTagColorListByQuality(quality)
                        local colorGradientDefault = self._colorGradientDefault
                        if not table.isempty(heroBookTagColorList) then
                            self:SetXUITextTransColor(QualityTxtEn, colorGradientDefault)
                            self:SetTextTransColorGradient(QualityTxtEn, heroBookTagColorList[1], heroBookTagColorList[2])
                        elseif color then
                            self:SetXUITextTransColor(QualityTxtEn, color)
                            self:SetTextTransColorGradient(QualityTxtEn, colorGradientDefault, colorGradientDefault)
                        end
                    end
                end
            end
        end
        CS.ShowObject(QualityDiv, showQuaDiv)
        --[[		LxUiHelper.SetSizeWithCurAnchor(item, 1, 60)]]
    end
    local HeroMapList = self:FindWndTrans(item, "HeroMapList")
    if HeroMapList then
        CS.ShowObject(HeroMapList, not showQuaDiv)
        if not showQuaDiv then
            self:CreateHeroCardList(HeroMapList, itemdata.heroList)

        end
    end

    local height = showQuaDiv and 48 or 310
    LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
end

function UISubSagaBookNew:GetCareerTypeList()
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

function UISubSagaBookNew:OnClickCareerTypeFunc(refId)
    if self._careerType == refId then
        return
    end
    self._careerType = refId

    local uiCareerTypeList = self._uiCareerTypeList
    if not uiCareerTypeList then
        return
    end
    local uiList = uiCareerTypeList:GetList()
    uiList:RefreshList()
    self:RefreshHeroBookListView(true)
end

function UISubSagaBookNew:ClickHeroCard(itemdata, ignore)

    local refId = itemdata.refId
    local serverData = gModelHeroBook:GetHeroInfoByHeroRefId(refId)
    if serverData then
        local isActive = serverData.isActive
        local haveHero = isActive and 1 or 0
        local status = gModelHeroBook:CheckBookInfoStatusByRefId(refId)
        local haveRed = status and 1 or 0
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK, "2-1-1", refId, haveHero, haveRed)
    end

    local para = {
        refId = refId,
        list = self._heroBookList,
        heroKeyList = self._heroBookKeyList,
        showTab = true
    }

    gModelGeneral:OpenHeroStarPre(para)

    --GF.OpenWnd("UISagaBookDetail",{heroRefId = refId,heroList = self._heroBookList , heroKeyList = self._heroBookKeyList , showTab = true})

    --self:ShowHeroInfo(refId,ignore)
end

function UISubSagaBookNew:GetHeroBookList()
    self:RefreshHeroRaceTypeList()
    self._heroBookList = {}
    self._heroBookKeyList = {}
    local heroIndex = 0
    local curRaceType = self._raceType
    local allRaceType = curRaceType == 0
    local curCareerType = self._careerType
    local allCareerType = curCareerType == 0
    local raceType, careerType
    local list = {}
    local yaoshiTitle = nil
    local isRusRegion = gLGameLanguage:IsRussiaRegion()
    local isRusLng = gLGameLanguage:IsRussiaVersion()
    local isRus = isRusRegion or isRusLng
    local resType = LPlayerPrefs.GetIsForceSensitiveRes()
    local isIgnore = resType > 0
    local curTimeSpan = GetTimestamp()
    for k, v in pairs(GameTable.CharacterRef) do
        local refId = v.refId
        raceType = v.raceType
        careerType = v.careerType
        local ins = (allRaceType or curRaceType == raceType) and (allCareerType or curCareerType == careerType)
        local isShow = gModelHero:GetHeroActShowState(refId,curTimeSpan)
        if ins and isShow then
            local quality = v.quality
            if v.superHero and v.superHero>0 then--耀世
                quality = YAOHUI_QUALITY
            end
            local listInfo = list[quality]
            if not listInfo then
                listInfo = {}
                listInfo.quality = quality
                listInfo.heroList = {}
                listInfo.raceType = raceType
                list[quality] = listInfo
            end
            local heroList = listInfo.heroList
            if not heroList then
                heroList = {}
                listInfo.heroList = listInfo
            end
            local data = {
                raceType = v.raceType,
                careerType = v.careerType,
                refId = refId,
                quality = v.quality,
                order= v.order
            }
            if isRus then
                local isActive = gModelHeroBook:FindHeroInfoStatusByHeroRefId(refId)
                if isIgnore and not isActive then

                else
                    table.insert(heroList, data)
                end
            else
                table.insert(heroList, data)
            end
        end
    end

    local sortList = {}
    for k, v in pairs(list) do
        table.insert(sortList, v)
    end
    table.sort(sortList, function(a, b)
        return a.quality > b.quality
    end)

    local cardMaxNum = self._cardMaxNum
    local qualityList = {}
    local tList = {}
    for k, v in ipairs(sortList) do
        local quality = v.quality
        local heroList = v.heroList or {}
        local listLen = #heroList
        local isHave = listLen > 0
        if isHave then
            local quaInfo = qualityList[quality]
            if not quaInfo then
                qualityList[quality] = true
                table.insert(tList, {
                    quality = quality,
                    showQuaDiv = true,
                    raceType = v.raceType
                })
            end
            table.sort(heroList, function(a, b)
                --local raceType1, raceType2 = a.raceType, b.raceType
                --if raceType1 ~= raceType2 then
                --    --raceType 取下rank部分
                --    local rank1 = gModelHero:GetHeroRaceRefRank(raceType1)
                --    local rank2 = gModelHero:GetHeroRaceRefRank(raceType2)
                --    return rank1 < rank2
                --else
                --    local careerType1, careerType2 = a.careerType, b.careerType
                --    if careerType1 ~= careerType2 then
                --        return careerType1 < careerType2
                --    else
                --        return a.refId < b.refId
                --    end
                --end

                return a.order>b.order
            end)
            local maxRow = math.ceil(listLen / cardMaxNum)
            for idx = 1, maxRow do
                local tHeroList = {}
                for num = 1, cardMaxNum do
                    local index = (idx - 1) * cardMaxNum + num
                    local data = heroList[index]
                    if data then
                        heroIndex = heroIndex + 1
                        local refId = data.refId
                        table.insert(tHeroList, data)
                        table.insert(self._heroBookList, refId)
                        self._heroBookKeyList[refId] = heroIndex
                    end
                end
                table.insert(tList, {
                    heroList = tHeroList
                })
            end
        end
    end
    return tList
end

function UISubSagaBookNew:CreateHeroCardList(trans, list)
    for i = 1, self._cardMaxNum do
        local heroTransName = "HeroCard" .. i
        local heroCardTrans = self:FindWndTrans(trans, heroTransName)
        if heroCardTrans then
            local data = list[i]
            local showCard = data ~= nil
            if showCard then
                self:CreateCard(heroCardTrans, data)
            end
            CS.ShowObject(heroCardTrans, showCard)
        end
    end
end

function UISubSagaBookNew:InitText()
    self:SetWndText(self.mReturnTxt, ccClientText(30205))
    self:SetWndText(self.mRelationTxt, ccClientText(19746))

    self:InitEmptyList()
end

function UISubSagaBookNew:InitData()
    self._raceType = 0
    self._careerType = self:GetWndArg("careerType") or 0            -- 职业
    self._cardMaxNum = 3
    self._moreHeroNum = 5
end

function UISubSagaBookNew:OnDrawCareerTypeCell(list, item, itemdata, itempos)
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

function UISubSagaBookNew:PlayRaceBtnAni()
    local isShow = self._showRaceBtnList
    CS.ShowObject(self.mLine1, not isShow)
    CS.ShowObject(self.mLine2, isShow)
    CS.ShowObject(self.mUnfoldBtn, not isShow)
    CS.ShowObject(self.mDi, not isShow)
    CS.ShowObject(self.mDi1, isShow)

    local commonPosList = self._commonPosList
    if not commonPosList then
        self:InitCommonListRect()
        commonPosList = self._commonPosList
    end
    local topPosX, botPosX = commonPosList.topPosX, commonPosList.botPosX

    local topPosY = isShow and -250 or -250
    local botPosY = isShow and 238 or 178.5
    self.mHeroSpQuaMapList.offsetMax = Vector2(topPosX, topPosY)
    self.mHeroSpQuaMapList.offsetMin = Vector2(botPosX, botPosY)
end

function UISubSagaBookNew:CreateCard(trans, itemdata)
    local refId = itemdata.refId
    local quality = itemdata.quality

    local qualityRef = gModelItem:GetQualityRef(quality)
    local coverImg = self:FindWndTrans(trans, "CoverImg")
    local frameUrl = qualityRef.heorBook1Bg;
    --local isShowCoverBg =  LxUiHelper.IsImgPathValid(frameUrl)
    --if isShowCoverBg then
    --	self:SetWndEasyImage(coverImg, frameUrl or "herobook1_frame_" ..quality , nil, true)
    quality = quality > 7 and 7 or quality

    self:SetWndEasyImage(coverImg, "herobook1_frame_" .. quality, nil, true)
    --end
    local ActTag = self:FindWndTrans(trans, "ActTag")
    --获取下英雄数据
    local heroRef = gModelHero:GetHeroRef(refId)

    CS.ShowObject(ActTag, false)
    if heroRef then
        local timeSpan = heroRef.actShow

        if not string.isempty(timeSpan) then
            local curTimeSpan = GetTimestamp()
            local isShow = tonumber(timeSpan) <= curTimeSpan
            CS.ShowObject(ActTag, isShow)
            self:SetTextTile(ActTag, ccClientText(30213))
        else

        end
    end

    local RaceType = self:FindWndTrans(trans, "RaceType")
    if RaceType then
        local img = gModelHero:GetRaceImgByRefId(itemdata.raceType)
        if img then
            self:SetWndEasyImage(RaceType, img, function()
                CS.ShowObject(RaceType, true)
            end)
        end
    end

    local bg = self:FindWndTrans(trans, "Bg")
    if bg then
        self:SetWndEasyImage(bg, frameUrl)
    end

    local effRef = gModelHero:GetHeroShowRefByRefId(refId)

    local HeroIcon = self:FindWndTrans(trans, "HeroIcon")
    if HeroIcon then
        local heroBookIcon = effRef and effRef.iconBig
        if heroBookIcon then
            self:SetWndEasyImage(HeroIcon, heroBookIcon, function()
                CS.ShowObject(HeroIcon, true)
            end, true)
        end
    end

    local HeroName = self:FindWndTrans(trans, "HeroName")
    if HeroName then
        local name = gModelHero:GetHeroNameByRefId(refId)
        if name then

            self:SetWndText(HeroName, name)
        end
    end

    self:InitTextLineWithLanguage(HeroName, -40)
    self:InitTextSizeWithLanguage(HeroName, -2)

    local LoveList = self:FindWndTrans(trans, "LoveList")
    if LoveList then
        local ItemRoot = self:FindWndTrans(LoveList, "ItemRoot")
        if ItemRoot then
            local star = 0
            local serverData = gModelHeroBook:GetHeroInfoByHeroRefId(refId)
            if serverData then
                local isActive = serverData.isActive
                star = isActive and serverData.heroMaxStar or 0
            end
            --local showCloseLvNum = gModelHeroBook:GetOnlyShowCloseLvNum()
            --local closeLv = gModelHeroBook:GetHeroCloseLv(refId)
            --for i = 1,showCloseLvNum do
            --	local starTrans = self:FindWndTrans(ItemRoot, "Star" .. i)
            --	if starTrans then
            --		local isGray = star < i
            --		self:SetWndImageGray(starTrans, isGray)
            --
            --		local show = i <= closeLv
            --		CS.ShowObject(starTrans,show)
            --	end
            --end
        end
    end
    local redPoint = self:FindWndTrans(trans, "redPoint")
    if redPoint then
        local rstatus = gModelHeroBook:CheckHeroBookInfoStatusByRefId(refId)
        CS.ShowObject(redPoint, rstatus)
    end
    local Mask = self:FindWndTrans(trans, "Mask")
    if Mask then
        local isActive = gModelHeroBook:FindHeroInfoStatusByHeroRefId(refId)
        CS.ShowObject(Mask, not isActive)
    end

    --local effTrans = self:FindWndTrans(trans,"Eff")
    --if effTrans then
    --	LxResUtil.DestroyChildImmediate(effTrans)
    --	self:DestroyWndEffectByKey(refId)
    local status = gModelHeroBook:FindIsNewActHeroInfoByRefId(refId)  --特效先屏蔽
    --	if status then
    --		if qualityRef then
    --			local effName = qualityRef.heroBookListLock
    --			self:CreateWndEffect(effTrans,effName,refId,100,nil,nil,10)
    --		end
    --	end
    --	CS.ShowObject(effTrans,status)
    --end

    --if self._isForeign then
    --	local coverImg = self:FindWndTrans(trans, "CoverImg")
    --	local isShowCoverBg =  LxUiHelper.IsImgPathValid(heroBookListForward)
    --	if isShowCoverBg then
    --		self:SetWndEasyImage(coverImg, heroBookListForward, nil, true)
    --	end
    --	CS.ShowObject(coverImg, isShowCoverBg)
    --end
    --
    self:SetWndClick(trans, function()
        self:ClickHeroCard(itemdata)
    end)
end

function UISubSagaBookNew:CheckRaceTypeRedPointStatus(raceType)
    if not raceType then
        return false
    end
    local showRedPoint = false
    for k, v in pairs(GameTable.CharacterRef) do
        if showRedPoint then
            break
        end
        if raceType == UIHeroRaceList.ALL_RACE_REFID or v.raceType == raceType then
            showRedPoint = gModelHeroBook:CheckHeroBookInfoStatusByRefId(k)
        end
    end
    return showRedPoint
end

function UISubSagaBookNew:RefreshHeroRaceTypeList()
    --local FindUIHeroRaceList
    local uiHeroRaceList = self._uiHeroRcaeList
    if not uiHeroRaceList then
        return
    end
    uiHeroRaceList:RefreshHeroRaceList()
end

------------------------------------------------------------------
return UISubSagaBookNew



