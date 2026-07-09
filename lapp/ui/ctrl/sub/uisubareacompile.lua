---
--- Created by BY.
--- DateTime: 2023/10/25 14:22:51
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
local typeofCanvas = typeof(UnityEngine.Canvas)
---@class UISubAreaCompile:LChildWnd
local UISubAreaCompile = LxWndClass("UISubAreaCompile", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubAreaCompile:UISubAreaCompile()
    self._uiHeroIconClsList = {}
    self._iconHeroClsList = {}
    self._tabList = {}
    self._tabRedList = {}
    self._compileTweenKey = "compileTweenKey"
    self._tagTabTrList = {}
    self._tagTabRedList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubAreaCompile:OnWndClose()
    self:ClearCommonIconList(self._uiHeroIconClsList)
    self:ClearCommonIconList(self._iconHeroClsList)
    self:TweenSeqKill(self._compileTweenKey)
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubAreaCompile:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubAreaCompile:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()

    self._isRegionDiff = gLGameLanguage:IsForeignRegion()
    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self.jpj = gLGameLanguage:IsJapanVersion()
    self._isVie =gLGameLanguage:IsVieVersion()
    self:InitMessage()
    self:InitCommand()
    self:InitEvent()
    self:InitText()
    self:RefreshHeadRed()
    self:UpdateCanvas()
    if gLGameLanguage:IsJapanRegion() then
        if PRODUCT_G_VER~=0 then
            CS.ShowObject(self.mTitleImg,false)
        end
    end
end
-- function UISubAreaCompile:OnClickBadge(index)
--     local _playerInfo = self._playerInfo
--     local badges = _playerInfo.badge
--     local badge = badges[index]
--     if badge and badge > 0 then
--         gModelPlayerSpace:OnPersonaliseOtherInfoReq(_playerInfo._name, _playerInfo._playerId, badge)
--     else
--         GF.ShowMessage(ccClientText(21149))
--     end
-- end
function UISubAreaCompile:OnClickTagTab(type)
    local _tagTabTrList = self._tagTabTrList or {}
    local _type = self._tagTab
    if _type then
        self:SetWndTabStatus(_tagTabTrList[_type], LWnd.StateOff)
    end
    self:SetWndTabStatus(_tagTabTrList[type], LWnd.StateOn)
    self._tagTab = type
    self:RefreshTagList(true)
    --gModelPlayerSpace:OnPersonaliseClickInfoReq({string.format("%s-%s",ModelPlayerSpace.ROLE_TAG,type)})
end

function UISubAreaCompile:RefreshData()
    local player = nil
    local _currInfo = gModelPlayerSpace:GetCurrSpaceInfo()
    if _currInfo then
        self._isMe = _currInfo.isMe
        if _currInfo.isMe then
            _currInfo = self:GetMePlayerInfo(_currInfo)
        end
        player = _currInfo.playerInfo
    else
        return
    end

    self:SetHeadIcon({
        trans = self.mHeadIcon,
        icon = gModelPlayer:GetPlayerHead(),
        headFrame = gModelPlayer:GetPlayerHeadFrame(),
        level = player._grade,
    })

    local sexIcon, guildName, areaName, age, signature, title, badge
    --sexIcon = player.sex == 1 and "role_zone_ui_man" or "role_zone_ui_woman"
    sexIcon = gModelPlayer:GetDefaultIcon()
    guildName = player._guildName == "" and ccClientText(21105) or player._guildName
    areaName = ccClientText(11116)
    if player._province > 0 then
        local pRef = gModelPlayerSpace:GetRoleProvinceListRefByRefId(player._province)
        local pRefName = ccLngText(pRef.name)
        local city = player._city
        if gLGameLanguage:IsKoreaRegion() or not city or city == 0 then
            --海外多语言改动：韩国不显示 地区
            areaName = pRefName
        else
            local cRef = gModelPlayerSpace:GetRoleCityListRefByRefId(player._city)
            if not cRef then
                areaName = pRefName
            else
                areaName = string.replace(ccClientText(21142), pRefName, ccLngText(cRef.name))
            end
        end
    end
    if not player.age then
        player.age = 0
    end
    -- local ageRef = gModelPlayerSpace:GetRoleAgeListRefByRefId(player.age)
    age = player.age == 0 and ccClientText(21186) or player.age
    signature = (player.signature == "" or player.disallowTalk == 1) and ccClientText(21109) or player.signature
    title = player.title or 0
    -- badge = player.badge
    
    self:SetWndText(self.mVipTex, string.replace(ccClientText(11942),player._vipLevel))
    -- if player._vipLevel >= 0 then
    --     local vipLvRef = gModelVip:GetRefByVipLv(player._vipLevel)
    --     if vipLvRef then
    --         local mainInterface = vipLvRef.mainInterface
    --         --local typeface = vipLvRef.typeface
    --         if not string.isempty(mainInterface) then
    --             local arr = string.split(mainInterface, "=")
    --             if LxUiHelper.IsImgPathValid(arr[1]) then
    --                 self:SetWndEasyImage(self.mVipImg, arr[1], nil, true)
    --                 if not string.isempty(arr[2]) then
    --                     local pos = LxDataHelper.ParseVector2NotEmpty3(arr[2])
    --                     self:SetAnchorPos(self.mVipImg, pos)
    --                 end
    --             end
    --         end
    --         --if not string.isempty(typeface) then
    --         --	local arr = string.split(typeface,"|")
    --         --	local topColor = LUtil.ColorByHex_6(arr[1])
    --         --	local bottomColor = LUtil.ColorByHex_6(arr[2])
    --         --	LxUiHelper.SetTextColorGradient(self.mVipNum,topColor,topColor,bottomColor,bottomColor)
    --         --	if not string.isempty(arr[3]) then
    --         --		local pos = LxDataHelper.ParseVector2NotEmpty3(arr[3])
    --         --		self:SetAnchorPos(self.mVipNum, pos)
    --         --	end
    --         --end
    --     end
    -- end

    self:SetWndText(self.mNameText, player._name)

    if self._isEnus then
        local uiText = LxUiHelper.FindXTextCtrl(self.mNameText)
        local width = uiText.preferredWidth
        self.mNameClick.sizeDelta = Vector2.New(width + 30, self.mNameClick.rect.height)
    end
    self:SetWndText(self.mServerTex, gLGameLogin:GetServerShotNameById(player._serverId))
    --todo 这块为空  后面排查下原因 现在 先去后面那块改板子先
    --local width = self.mServerText_1.preferredWidth
    --local width = self.mServerText.preferredWidth
    local width = 0
    -- self.mServerBg.sizeDelta = Vector2.New(width + 30, 24)
    -- self.mServerBg.anchoredPosition = Vector2.New(width + 120, 0)
    -- self.mPowerBg.anchoredPosition = Vector2.New(width + 295, 0)
    self:SetWndEasyImage(self.mSexImg, sexIcon)
    CS.ShowObject(self.mSexImg, false)

    -- local powerStr = LUtil.FormatPowerShowStr(player._power)
    --self:SetWndText(self.mPowerTex,powerStr)

    local powerStr = LUtil.PowerNumberCoversion(player._power)
    self:SetWndText(self:FindWndTrans(self.mPowerBg, "PowerText"), powerStr)

    self:SetWndText(self.mGuildNameText, guildName)
    self:SetWndText(self.mAreaNameText, areaName)
    self:SetWndText(self.mAgeNameText, age)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.mAreaNameText)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.mAgeNameText)
    -- LxTimer.DelayTimeCall(function ()
    -- 	local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)
    -- 	local layG = self.mAreaTextObj:GetComponent(typeHorizontalLayoutGroup)
    -- 	layG.enabled = false
    -- 	layG.enabled = true
    --     local layG = self.mAgeTextObj:GetComponent(typeHorizontalLayoutGroup)
    -- 	layG.enabled = false
    -- 	layG.enabled = true
    -- end, 0.05, true)
    self:SetWndText(self.mSignatureText, signature)
    local uiText = LxUiHelper.FindXTextCtrl(self.mSignatureText)
    local height = uiText.preferredHeight + 30
    if height > 75 then
        self.mSignatureBg.sizeDelta = Vector2.New(self.mSignatureBg.sizeDelta.x, height)
    end
    if not self._figure or self._figure ~= player._figure then
        self:SetRolePaint(self.mSpine, player._figure)
    end
    self._figure = player._figure
    CS.ShowObject(self.mTitleImg, true)
    if gLGameLanguage:IsJapanRegion() then
        if PRODUCT_G_VER~=0 then
            CS.ShowObject(self.mTitleImg,false)
            CS.ShowObject(self.mTitleBg,false)
        end
    end
    if title and title > 0 then
        local titleRef = gModelPlayer:GetRolePlayerHeadRefByRefId(title)
        if not titleRef then
            printInfoNR("GameTable.SnakeRolePlayerHeadRef[refId] is not find, refId = " .. title)
        else
            self:SetWndEasyImage(self.mTitleImg, titleRef.icon, nil, true)
        end
    else
        self:SetWndEasyImage(self.mTitleImg, "role_titile_0", nil, true)
    end

    -- for i, v in pairs(self._medalList) do
    --     local data = badge[i]
    --     self:SetMedalIcon(v, data)
    -- end
    local setTagNum = gModelPlayer:GetRoleConfigRefByKey("zoneTagNum") or 0
    for i = 1, setTagNum do
        local item = self:FindWndTrans(self.mTagItemRoot, "TagItem" .. i)
        local refId = player.tag[i] or 0
        self:SetTagItemList(item, refId, i)
    end
end
function UISubAreaCompile:OnClickCompile()
    --GF.OpenWnd("UISagaCoreActivity")
    local isCompile = self._isCompile
    CS.ShowObject(self.mCompileModel, not isCompile)
    self._isCompile = not isCompile
    if not isCompile then
        self:RefreshNameCompileWidth()
        self:SetTween()
    else
        self:TweenSeqKill(self._compileTweenKey)
    end
    self:RefreshData()
    self:SetWndText(self.mCompileText, not isCompile and ccClientText(21161) or ccClientText(21110))
end

-- function UISubAreaCompile:SetMedalIcon(root, medalId)
--     local medalBg = CS.FindTrans(root, "MedalBg")
--     local medalImg = CS.FindTrans(root, "MedalImg")

--     CS.ShowObject(medalBg, not medalId)
--     CS.ShowObject(medalImg, medalId)
--     if medalId then
--         local UIText = self:FindWndTrans(medalImg, "UIText")

--         local rankStr = ""
--         local medalRef = gModelPlayer:GetRolePlayerHeadRefByRefId(medalId)
--         if medalRef then
--             self:SetWndEasyImage(medalImg, medalRef.icon)

--             local type = medalRef.type
--             local refId = medalRef.refId
--             if type == 5 then
--                 local isType5Rank = gModelPlayer:IsRoleCrossGradingRankType(refId)
--                 if isType5Rank then
--                     rankStr = gModelPlayer:GetRankSeasonStr(refId)
--                 end
--             end

--             local badgeOutsideSize = medalRef.badgeOutsideSize
--             if badgeOutsideSize == 0 then
--                 badgeOutsideSize = 60
--                 printInfoNR(refId .. "配置 badgeOutsideSize = 0，默认" .. badgeOutsideSize)
--             end
--             badgeOutsideSize = badgeOutsideSize / 100
--             printInfoNR("badgeOutsideSize = " .. badgeOutsideSize)
--             medalImg.localScale = Vector3(badgeOutsideSize, badgeOutsideSize, badgeOutsideSize)
--         end
--         self:SetWndText(UIText, rankStr)
--     end
-- end
function UISubAreaCompile:SetTagItemList(item, itemdata, itempos)
    CS.ShowObject(item, true)
    --local posRef = gModelPlayerSpace:GetRoleTagPosByRefId(itempos)
    local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(itemdata)
    local btnAdd = self:FindWndTrans(item, "BtnAdd")
    local numText = self:FindWndTrans(item, "BtnAdd/NumText")
    local tagItem = self:FindWndTrans(item, "TagItem")
    local tagText = self:FindWndTrans(item, "TagItem/TagText")

    local isCompile = self._isCompile
    CS.ShowObject(btnAdd, false)
    CS.ShowObject(tagItem, false)
    self:SetWndText(numText, itempos)
    --local posArr = string.split(posRef.zoneTagPos,"|")
    --item.localPosition = Vector2.New(tonumber(posArr[1]),tonumber(posArr[2]))
    if self._isMe then
        self:SetWndClick(item, function()
            if ref then
                self._tagTab = ref.subType
            end
            self:OnClickTag()
            --GF.OpenWnd("UIChaePop",{startType = ModelPlayerSpace.ROLE_TAG})
        end)
    end
    --local size = posRef.zoneTagSize
    --	item.localScale = Vector2.New(size,size)
    if not ref then
        CS.ShowObject(btnAdd, true and self._isMe and isCompile)
        return
    end
    CS.ShowObject(tagItem, true)

    self:SetWndEasyImage(tagItem, ref.tagBg)
    self:SetWndText(tagText, LUtil.FormatColorStr(ccLngText(ref.name), "#" .. ref.tagColour))
    self:InitTextLineWithLanguage(tagText, -30)
end
function UISubAreaCompile:RefreshTagTabRed()
    if not self._isMe then
        return
    end
    local _tagTabRedList = self._tagTabRedList
    --local redList = gModelPlayerSpace:GetRedPointListByType(ModelPlayerSpace.ROLE_TAG)
    --屏蔽个性标签相关的请求
    local redList = nil
    if redList then
        local trueList = {}
        for i, v in pairs(redList) do
            if v then
                local tagRef = gModelPlayer:GetRolePlayerHeadRefByRefId(i)
                trueList[tagRef.subType] = true
            end
        end
        for i, v in pairs(_tagTabRedList) do
            CS.ShowObject(v, trueList[i])
        end
    end
end
function UISubAreaCompile:OnClickServerBg()
    local _currInfo = gModelPlayerSpace:GetCurrSpaceInfo()
    local player = _currInfo.playerInfo
    local serverName = gLGameLogin:GetServerShotNameById(player._serverId)
    GF.ShowMessage(string.replace(ccClientText(21167), serverName))
end

function UISubAreaCompile:RefreshNameCompileWidth()
    local uiText = LxUiHelper.FindXTextCtrl(self.mNameText)
    local width = uiText.preferredWidth
    self.mCompileName.sizeDelta = Vector2.New(width + 80, self.mCompileName.rect.height)
    -- self.mNameBg.sizeDelta = Vector2.New(width + 80, self.mNameBg.rect.height)

end
function UISubAreaCompile:InitHeroList(pb)
    local _combatHeroData = gModelGeneral:SetCombatHeroData(pb.heroData)
    local list = {}
    local heros = _combatHeroData._heros
    local grids = _combatHeroData._grids
    self.combatHeroData = _combatHeroData
    local _heros = {}
    for i, v in ipairs(heros) do
        local pos = grids[i]
        _heros[pos] = v
    end
    for i = 1, 6 do
        local hero = _heros[i] or {}
        table.insert(list, hero)
    end

    local _uiHeroList = self._uiHeroList
    if (_uiHeroList) then
        _uiHeroList:RefreshList(list)
    else
        _uiHeroList = self:GetUIScroll("_uiHeroIconList")
        _uiHeroList:Create(self.mHeroListScroll, list, function(...)
            self:HeroListItem(...)
        end)
        self._uiHeroList = _uiHeroList
    end
end

function UISubAreaCompile:TagTabListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local btnTab = self:FindWndTrans(root, "BtnTab2")
    local redPoint = self:FindWndTrans(root, "redPoint")

    self:SetWndTabText(btnTab, ccLngText(itemdata.name))
    self:SetWndTabStatus(btnTab, LWnd.StateOff)
    self._tagTabTrList[itemdata.type] = btnTab
    self._tagTabRedList[itemdata.type] = redPoint
    self:SetWndClick(root, function()
        self:OnClickTagTab(itemdata.type)
    end)
end
function UISubAreaCompile:OnClickAge()
    GF.OpenWnd("UIAreaAgeSet")
end

function UISubAreaCompile:OnClickItemTag(itemdata, isUse)
    local setTagNum = gModelPlayer:GetRoleConfigRefByKey("setTagNum")
    local isWar = not isUse
    local refId = itemdata.refId

    local isUp = isWar
    local useList = gModelPlayer:GetPlayerTags()
    local list = {}
    for i = 1, setTagNum do
        local id = useList[i]
        if id then
            if not isWar and id == refId then
                list[i] = "0=" .. i
            else
                list[i] = id .. "=" .. i
            end
        else
            if isWar and isUp then
                isUp = false
                list[i] = refId .. "=" .. i
            else
                list[i] = "0=" .. i
            end
        end
    end
    if isUp then
        GF.ShowMessage(string.replace(ccClientText(21177), setTagNum))
        return
    end

    gModelPlayerSpace:OnPersonaliseChangeTotalReq(nil, nil, nil, nil, nil, list)
end

function UISubAreaCompile:OnClickInvite()
    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_INVITE, "打开分享界面", "一键邀请")

    local activityData = gModelActivity:GetSpecialActivity(ModelActivity.INVITE_ACTIVITY)
    local sid
    if activityData then
        sid = activityData.sid
    end

    GF.OpenWnd("UIGameSpread", {
        sid = sid,
    })
end
function UISubAreaCompile:HeroListItem(list, item, itemdata, itempos)
    local heroTrans = CS.FindTrans(item, "Root/HeroIcon")
    local nameText = CS.FindTrans(item, "NameText")
    local addTrans = CS.FindTrans(item, "BtnAdd")

    CS.ShowObject(addTrans, self._isMe)
    CS.ShowObject(heroTrans, itemdata.id)
    CS.ShowObject(nameText, itemdata.id)
    if (not itemdata.id) then
        self:SetWndClick(addTrans, function(...)
            self:OnClickBattleArrShow()
        end)
        return
    end
    --local name = gModelHero:GetColoredHeroName(itemdata.refId, itemdata.star)
    local name = gModelHeroExtra:GetHeroSetName(itemdata, true)
    self:SetWndText(nameText, name)
    self:InitTextShowWithLanguage(nameText, nameText)

    local InstanceID = item:GetInstanceID()
    local baseClass = self._iconHeroClsList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        self._iconHeroClsList[InstanceID] = baseClass
        baseClass:Create(heroTrans)
        self:SetIconClickScale(heroTrans, true)
    end
    itemdata.level = itemdata.lv
    baseClass:SetHeroDataSet(itemdata)
    baseClass:DoApply()

    self:SetWndClick(heroTrans, function()
        gModelHero:ReqShowHeroTip(self._playerInfo._playerId, itemdata, nil, nil, nil, self._playerInfo._serverId)
    end)
end
function UISubAreaCompile:RefreshBaoWuView()
    local list = gModelDraconic:GetActiveStarRefIdList()

    local dataList = {}
    local DraconicSuitRankRef = GameTable.DraconicSuitRankRef
    local DraconicRef = GameTable.DraconicRef
    for k, v in ipairs(list) do
        local upRef = DraconicSuitRankRef[v]
        local ref = DraconicRef[upRef.type]
        dataList[k] = { ref = ref, upRef = upRef }
    end
    table.sort(dataList, gModelDraconic.SortDraconicList)

    local s = #dataList == 0 and ccLngText(GameTable.EmptyTipsRef[23005].text) or ""
    self:SetWndText(self.mNoText, s)
    local uiTreasureList = self._uiTreasureList
    if uiTreasureList then
        uiTreasureList:RefreshList(dataList)
    else
        uiTreasureList = self:GetUIScroll("uiTreasureList")
        self._uiTreasureList = uiTreasureList
        uiTreasureList:Create(self.mBaowuListScroll, dataList, function(...)
            self:OnTreasureCell(...)
        end, UIItemList.WRAP)
    end
    -- CS.ShowObject(self.mNoRecord2, not haveTreasure)
end
function UISubAreaCompile:OnClickArea()
    GF.OpenWndUp("UIAreaAreaSet")
end
function UISubAreaCompile:OnClickCharacterSet(type)
    GF.OpenWnd("UIChaePop", { startType = type })
end
-----------------------------------------------------------------------------------------
function UISubAreaCompile:OnClickTab(type)
    -- if true then return end
    if self._type then
        if self._type == type then
            return
        end
    end
    self._type = type
    for i, v in ipairs(self._tabList) do
        local on = self:FindWndTrans(v, "On")
        local off = self:FindWndTrans(v, "Off")
        CS.ShowObject(on, i == type)
        CS.ShowObject(off, i ~= type)
    end
    CS.ShowObject(self.mHeroListScroll, type == 1)
    CS.ShowObject(self.mBaowuMar, type == 2)
    CS.ShowObject(self.mCompileHero, type == 1)
    if type == 2 and not self._isOneRefreshBao then
        self._isOneRefreshBao = true
        self:RefreshBaoWuView()
    end
end
--设置立绘
function UISubAreaCompile:SetRolePaint(paintTans, figure)
    if (figure) then
        ---@type V_SnakeRoleAdventureImageRef
        local ref = gModelPlayer:GetRoleAdventureImage(figure)
        if (not ref) then
            return
        end
        CS.ShowObject(paintTans, true)
        local spine = self:FindWndSpineByKey("spineKey")
        if (spine) then
            self:DestroyWndSpineByKey("spineKey")
        end
        local paintFlip = ref.paintFlip == 1
        local paintMultiple = ref.paintMultiple
        self:CreateWndSpine(paintTans, ref.paint, "spineKey", false, function(dpSpine)
            dpSpine:SetScale(paintMultiple)
            dpSpine:SetFlipX(paintFlip)
            local dpTrans = dpSpine:GetDisplayTrans()
            if dpTrans then
                dpTrans.anchorMin = Vector2.New(0.5, 0.5)
                dpTrans.anchorMax = Vector2.New(0.5, 0.5)

                local rolePaint = ref.rolePaint
                if not string.isempty(rolePaint) then
                    local posArr = string.split(rolePaint, ",")
                    dpTrans.localPosition = Vector2(checknumber(posArr[1]), checknumber(posArr[2]))
                end

                dpSpine:PlayAnimationSolid("idle", true)
                self:SetWndClick(self.mSpine, function()
                    self:SetRunSpineAin("spineKey")
                end)
                if self._isMe then
                    self:SetWndLongClick(dpTrans, function()
                        FireEvent(EventNames.ON_ZONE_SPINE)
                    end)
                end
            end
        end)
    else
        CS.ShowObject(paintTans, false)
    end
end

function UISubAreaCompile:InitCommand()
    self:SetWndText(self.mGuildText, ccClientText(21104))
    self:SetWndText(self.mAreaText, ccClientText(21106))
    self:SetWndText(self.mAgeText, ccClientText(21107))
    self:SetWndText(self.mCompileText, ccClientText(21110))
    self:SetWndText(self.mSeverDesText, ccClientText(21159))
    -- self:SetWndText(self.mTagText, ccClientText(21170))
    self:SetWndText(self.mInviteText, ccClientText(21179))
    self:SetWndText(self.mShareTwitterText, ccClientText(21180))
    self:SetWndText(self.mTagMagCloseText, ccClientText(24206))

    local isShow = gLGameLanguage:IsChinaRegion()
    local isRegionKo = gLGameLanguage:IsKoreaRegion()
    local isRegionJa = gLGameLanguage:IsJapanRegion()
    local isVie = gLGameLanguage:IsVietnamVersion()

    local isShowArea = isShow or isRegionKo
    local isShowAge = isShow or isRegionKo
    local isShowTwitterLink = false --gModelPlayer:CheckShowTwitterLink()
    local isShowInvite = gLGameLogin:IsOpenShareBusinessCard()

    if PRODUCT_G_VER == 2 and gLGameLanguage:IsJapanRegion() then
        isShowInvite = false
    end
    isShowArea = not self._isRegionDiff
    isShowAge = not self._isRegionDiff
    CS.ShowObject(self.mAreaObj, isShowArea)
    CS.ShowObject(self.mAgeObj, isShowArea)
    -- CS.ShowObject(self.mAreaText, isShowArea)
    -- CS.ShowObject(self.mAreaBg, isShowArea)
    -- CS.ShowObject(self.mAgeText, isShow)
    -- CS.ShowObject(self.mAgeBg, isShowAge)
    -- CS.ShowObject(self.mCompileArea, isShow)
    -- CS.ShowObject(self.mCompileAge, isShow)
    -- CS.ShowObject(self.mBtnInvite, isShowInvite)
    CS.ShowObject(self.mBtnShareTwitter, isShowTwitterLink)

    local _currInfo = gModelPlayerSpace:GetCurrSpaceInfo()
    --self._redPointList = gModelPlayerSpace:GetRedPointList()
    if _currInfo then
        self._isMe = _currInfo.isMe
        self._playerInfo = _currInfo.playerInfo
    else
        return
    end
    -- CS.ShowObject(self.mBtnTag, self._isMe)
    -- CS.ShowObject(self.mBtnCompile, self._isMe)
    CS.ShowObject(self.mBtnShare, self._isMe)

    local list = {
        { type = 1, title = ccClientText(21111) },
        { type = 2, title = ccClientText(21112) }
    }
    -- self._medalList = {
    --     [1] = self.mMedalIcon1,
    --     [2] = self.mMedalIcon2,
    --     [3] = self.mMedalIcon3,
    -- }

    -- local isMedalShow = gModelFunctionOpen:CheckIsShow(17601030)
    -- for i, v in pairs(self._medalList) do
    --     CS.ShowObject(v, isMedalShow)
    -- end
    -- CS.ShowObject(self.mCompileMedal, isMedalShow)

    local uiList = self:GetUIScroll("showTab")
    uiList:Create(self.mTabScroll, list, function(...)
        self:ListItem(...)
    end)
    self:OnClickTab(1)
    gModelPlayer:OnGetFormationShowReq(self._playerInfo._playerId)
    self:RefreshData()
    self:InitEmptyList()
    --CS.ShowObject(self.mMedal1Add,self._isMe)
    --CS.ShowObject(self.mMedal2Add,self._isMe)
    --CS.ShowObject(self.mMedal3Add,self._isMe)
    CS.ShowObject(self._tabRedList[1], gModelHero:GetHeroListChange() and self._isMe)

    -- local isBadgeShow = gModelFunctionOpen:CheckIsShow(17601020)
    -- CS.ShowObject(self.mBadgeMag, isBadgeShow)
    -- CS.ShowObject(self.mCompileMedal, isBadgeShow)
    local isTagShow = gModelFunctionOpen:CheckIsShow(17602000)
    CS.ShowObject(self.mTagItemRoot, isTagShow)
end
--设置头像
function UISubAreaCompile:SetHeadIcon(playerInfo)
    local baseClass = self._headBaseClass
    if baseClass then
        baseClass:SetHeadData(playerInfo)
        baseClass:RefreshUI()
    else
        baseClass = HeadIcon:New(self)
        baseClass:SetHeadData(playerInfo)
        baseClass:RefreshUI()
        self._headBaseClass = baseClass
    end
end
function UISubAreaCompile:RefreshTagList(isTab)
    local _tagTab = self._tagTab or 1
    --local refs = gModelPlayer:GetRolePlayerHeadListByType(ModelPlayerSpace.ROLE_TAG)

    local useList = gModelPlayer:GetPlayerTags()
    local _useList = {}
    for i, v in pairs(useList) do
        _useList[v] = i
    end
    self._useList = _useList
    local list = {}
    --for i, v in pairs(refs) do
    --	if _tagTab == v.subType then
    --		table.insert(list,v)
    --	end
    --end
    table.sort(list, function(a, b)
        return a.refId < b.refId
    end)
    local _uiListSuper = self._uiListSuper
    if _uiListSuper then
        _uiListSuper:RefreshList(list)
        _uiListSuper:DrawAllItems()
    else
        _uiListSuper = self:GetUIScroll("mTagSuper_UISubAreaCompile_")
        self._uiListSuper = _uiListSuper
        _uiListSuper:Create(self.mTagSuper, list, function(...)
            self:TagListItem(...)
        end, UIItemList.SUPER_GRID)
        _uiListSuper:EnableScroll(true, false)
    end
    if isTab then
        _uiListSuper:MoveToPos(1)
    end
end
function UISubAreaCompile:OnClickPowerBg()
    local _currInfo = gModelPlayerSpace:GetCurrSpaceInfo()
    local player = _currInfo.playerInfo
    local power = player._power
    GF.ShowMessage(string.replace(ccClientText(21168), power))
end
function UISubAreaCompile:TagListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "HeadUI")
    local tagBg = self:FindWndTrans(root, "TagBg")
    local tagText = self:FindWndTrans(root, "TagBg/TagText")
    local isTrue = self:FindWndTrans(root, "IsTrueBg/IsTrue")

    local tagTextStr = LUtil.FormatColorStr(ccLngText(itemdata.name), "#" .. itemdata.tagColour)
    local _useList = self._useList or {}
    local isUse = _useList[itemdata.refId]

    self:SetWndEasyImage(tagBg, itemdata.tagBg)
    self:SetWndText(tagText, tagTextStr)
    CS.ShowObject(isTrue, isUse)
    self:SetWndClick(root, function()
        self:OnClickItemTag(itemdata, isUse)
    end)
end
--编辑按钮抖动
function UISubAreaCompile:SetTween()
    local tweens = self._wndTweenRotateList
    if not tweens then
        tweens = {}
        local list = {
            self.mCompileHead, self.mCompileName, self.mCompileArea, self.mCompileAge, self.mCompileSignature, self.mCompileTitle,
            self.mCompileSpine, self.mCompileHero
        }
        for i, v in ipairs(list) do
            local img = CS.FindTrans(v, "Image")
            table.insert(tweens, img)
        end
        self._wndTweenRotateList = tweens
    end
    local seqTween
    self:TweenSeqKill(self._compileTweenKey)
    if not seqTween then
        seqTween = self:TweenSeqCreate(self._compileTweenKey, function(seq)
            for i, v in ipairs(tweens) do
                local tweener = v.transform:DOLocalRotate(Vector3.New(0, 0, -5), 0.05):SetEase(DG.Tweening.Ease.InSine)
                seq:Join(tweener)
            end
            seq:AppendInterval(0.05)
            for i, v in ipairs(tweens) do
                local tweener = v.transform:DOLocalRotate(Vector3.New(0, 0, 5), 0.1):SetEase(DG.Tweening.Ease.InSine)
                seq:Join(tweener)
            end
            seq:AppendInterval(0.05)
            for i, v in ipairs(tweens) do
                local tweener = v.transform:DOLocalRotate(Vector3.New(0, 0, 0), 0.1):SetEase(DG.Tweening.Ease.InSine)
                seq:Join(tweener)
            end
            --seq:AppendInterval(0.5)
            return seq
        end)
    end
    seqTween:SetLoops(-1)
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(self._compileTweenKey)
    end)
end
function UISubAreaCompile:OnClickBattleArrShow()
    GF.OpenWnd("UIPerSagaSetPop", {
        combatHeroData = self.combatHeroData,
        callFun = function(...)
            local _playerId = self._playerInfo and self._playerInfo._playerId
            gModelPlayer:OnGetFormationShowReq(_playerId)
        end
    })
end
function UISubAreaCompile:RefreshTagTabList()

    --local list = gModelPlayer:GetRoleAdventureImageTypeRef(ModelPlayerSpace.ROLE_TAG)

    local list = nil
    local _TagTabScroll = self._TagTabScroll
    if _TagTabScroll then

        if not list then
            CS.ShowObject(_TagTabScroll, false)
        end

        _TagTabScroll:RefreshList(list)
    else
        _TagTabScroll = self:GetUIScroll("mTagTabScroll_UISubAreaCompile_")
        self._TagTabScroll = _TagTabScroll
        _TagTabScroll:Create(self.mTagTabScroll, list, function(...)
            self:TagTabListItem(...)
        end)
    end
    self:RefreshTagTabRed()
    if self._tagTab then
        self:OnClickTagTab(self._tagTab)
    else
        self:OnClickTagTab(list[1].type)
    end
end

function UISubAreaCompile:RefreshHeadRed()
    if not self._isMe then
        return
    end
    local headRed = gModelPlayerSpace:GetIsRedPointByType(ModelPlayerSpace.ROLE_HEAD)
    local headFrameRed = gModelPlayerSpace:GetIsRedPointByType(ModelPlayerSpace.ROLE_HEADFRAME)
    local titleRed = gModelPlayerSpace:GetIsRedPointByType(ModelPlayerSpace.ROLE_TITLE)
    local badgeRed = gModelPlayerSpace:GetIsRedPointByType(ModelPlayerSpace.ROLE_MEDAL)
    --local tagRed = gModelPlayerSpace:GetIsRedPointByType(ModelPlayerSpace.ROLE_TAG)

    local backgroundRed = gModelPlayerSpace:GetIsRedPointByType(ModelPlayerSpace.BACKGROUND)
    --local bubbleRed = gModelPlayerSpace:GetIsRedPointByType(ModelPlayerSpace.BUBBLE)


    --local headRedPoi = CS.FindTrans(self.mHeadIcon,"redPoint")
    local titleRedPoi = CS.FindTrans(self.mTitleBg, "redPoint")

    CS.ShowObject(self.mHeroRedPoint, headRed or headFrameRed or backgroundRed)
    CS.ShowObject(titleRedPoi, titleRed)
    CS.ShowObject(self.mBadgeRedPoint, badgeRed)
    -- CS.ShowObject(self.mTagRedPoint, tagRed)
    CS.ShowObject(self.mVipObj, gModelFunctionOpen:CheckIsOpened(15000010))

    self:RefreshTagTabRed()
end
function UISubAreaCompile:OnClickTag()
    CS.ShowObject(self.mTagCompileMag, true)
    self:RefreshTagTabList()

    FireEvent(EventNames.OPEN_WND_PART, "TagCompileMag")
end

function UISubAreaCompile:OnTreasureCell(list, item, itemdata, itempos)
    local DraconicSkill = self:FindWndTrans(item, "DraconicSkill")

    local param = {
        showName = true,
        showType = true,
        showStar = true,
        upRefId = itemdata.upRef.refId,
    }
    gModelDraconic:DrawSkillItem(self, DraconicSkill, param)
    local type1 = CS.FindTrans(DraconicSkill, "typeRoot/type1")
    local type2 = CS.FindTrans(DraconicSkill, "typeRoot/type2")
    if self.jpj then
        CS.ShowObject(type1,false)
        CS.ShowObject(type2,false)
    end
    self:SetWndClick(item, function()
        GF.OpenWnd("UIDraconicUpStar", { refId = itemdata.ref.refId, starNum = itemdata.upRef.rankNow, tips = true })
    end)
end
function UISubAreaCompile:OnClickGuildBg()
    local _currInfo = gModelPlayerSpace:GetCurrSpaceInfo()
    local player = _currInfo.playerInfo
    local guildName = player._guildName == "" and ccClientText(21105) or string.replace(ccClientText(21169), player._guildName)
    GF.ShowMessage(guildName)
end

function UISubAreaCompile:InitMessage()
    self:WndNetMsgRecv(LProtoIds.GetFormationShowResp, function(...)
        self:InitHeroList(...)
    end)
    self:WndNetMsgRecv(LProtoIds.PlayerChangeInfoResp, function(...)
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.PositionChangeResp, function(...)
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.PersonaliseChangeTotalResp, function(...)
        self:RefreshData()
        self:RefreshTagList(...)
    end)
    self:WndNetMsgRecv(LProtoIds.PlayerReNameResp, function(...)
        self:RefreshData()
        self:RefreshNameCompileWidth()
    end)
    self:WndNetMsgRecv(LProtoIds.PersonaliseNewInfoResp, function(...)
        self:RefreshHeadRed(...)
    end)
    self:WndNetMsgRecv(LProtoIds.PersonaliseClickInfoResp, function(...)
        self:RefreshHeadRed(...)
    end)
    self:WndNetMsgRecv(LProtoIds.PlayerChangeResp, function(...)
        self:RefreshData(...)
    end)
    self:WndEventRecv(EventNames.ON_ZONE_HEROLIST, function()
        CS.ShowObject(self._tabRedList[1], gModelHero:GetHeroListChange() and self._isMe)
    end)

    self:WndEventRecv(EventNames.ON_WND_CLOSE, function()
        self:UpdateCanvas()
    end)
end

function UISubAreaCompile:InitText()
    self:SetWndText(self.mBaowuTitleText, ccClientText(11553))
    if self._isVie then
        self.mNameClick.sizeDelta=Vector2.New(156,27)
    end
end
function UISubAreaCompile:OnClickReName()
    GF.OpenWnd("UIPerReNameUI")
end
function UISubAreaCompile:OnClickCloseTag()
    CS.ShowObject(self.mTagCompileMag, false)
end

function UISubAreaCompile:InitEvent()
    if self._isMe then
        -- self:SetWndClick(self.mBtnTag, function()
        --     self:OnClickTag()
        -- end)
        self:SetWndClick(self.mTagCompileBg, function()
            self:OnClickCloseTag()
        end)
        self:SetWndClick(self.mBtnTagMagClose, function()
            self:OnClickCloseTag()
        end)
        self:SetWndClick(self.mBtnCompile, function()
            self:OnClickCompile()
        end)
        self:SetWndClick(self.mHeadClick, function(...)
            self:OnClickCharacterSet(ModelPlayerSpace.ROLE_HEAD)
        end)
        self:SetWndClick(self.mCompileHead, function(...)
            self:OnClickCharacterSet(ModelPlayerSpace.ROLE_HEAD)
        end)
        self:SetWndClick(self.mBtnShareTwitter, function(...)
            self:OnClickShareTwitter()
        end)
        -- self:SetWndClick(self.mBtnInvite, function()
        --     self:OnClickInvite()
        -- end)
        self:SetWndClick(self.mNameClick, function()
            self:OnClickReName()
        end)
        self:SetWndClick(self.mCompileName, function()
            self:OnClickReName()
        end)
        self:SetWndClick(self.mAreaBg, function()
            self:OnClickArea()
        end)
        self:SetWndClick(self.mCompileArea, function()
            self:OnClickArea()
        end)
        self:SetWndClick(self.mAgeBg, function()
            self:OnClickAge()
        end)
        self:SetWndClick(self.mCompileAge, function()
            self:OnClickAge()
        end)
        self:SetWndClick(self.mSignatureBg, function()
            self:OnClickSignature()
        end)
        self:SetWndClick(self.mCompileSignature, function()
            self:OnClickSignature()
        end)
        self:SetWndClick(self.mTitleBg, function()
            self:OnClickCharacterSet(ModelPlayerSpace.ROLE_TITLE)
        end)
        self:SetWndClick(self.mCompileTitle, function()
            self:OnClickCharacterSet(ModelPlayerSpace.ROLE_TITLE)
        end)
        -- self:SetWndClick(self.mCompileMedal, function()
        --     self:OnClickCharacterSet(ModelPlayerSpace.ROLE_MEDAL)
        -- end)
        self:SetWndClick(self.mCompileSpine, function()
            FireEvent(EventNames.ON_ZONE_SPINE)
        end)
        self:SetWndClick(self.mCompileHeroBtn, function()
            self:OnClickBattleArrShow()
        end)

        -- self:SetWndClick(self.mMedalIcon1, function()
        --     self:OnClickCharacterSet(ModelPlayerSpace.ROLE_MEDAL)
        -- end)
        -- self:SetWndClick(self.mMedalIcon2, function()
        --     self:OnClickCharacterSet(ModelPlayerSpace.ROLE_MEDAL)
        -- end)
        -- self:SetWndClick(self.mMedalIcon3, function()
        --     self:OnClickCharacterSet(ModelPlayerSpace.ROLE_MEDAL)
        -- end)
    else
        self:SetWndClick(self.mTitleBg, function()
            self:OnClickTitle()
        end)
        -- self:SetWndClick(self.mMedalIcon1, function()
        --     self:OnClickBadge(1)
        -- end)
        -- self:SetWndClick(self.mMedalIcon2, function()
        --     self:OnClickBadge(2)
        -- end)
        -- self:SetWndClick(self.mMedalIcon3, function()
        --     self:OnClickBadge(3)
        -- end)
    end
    self:SetWndClick(self.mServerBg, function()
        self:OnClickServerBg()
    end)
    self:SetWndClick(self.mPowerClick, function()
        self:OnClickPowerBg()
    end)
    self:SetWndClick(self.mGuildBg, function()
        self:OnClickGuildBg()
    end)
    self:SetWndClick(self.mVipClick, function()
        if gModelFunctionOpen:CheckIsOpened(15000010, true) then
            GF.OpenWndBottom("UIHuiYPay", { page = 1 })
        end
    end)
end

function UISubAreaCompile:InitEmptyList()
    local data = {
        refId = 18001,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end
function UISubAreaCompile:ListItem(list, item, itemdata, itempos)
    local on = self:FindWndTrans(item, "On")
    local onText = self:FindWndTrans(on, "UIText")
    local off = self:FindWndTrans(item, "Off")
    self:SetWndText(onText, itemdata.title)
    self:SetWndText(off, itemdata.title)
    local redPoint = CS.FindTrans(item, "redPoint")
    self._tabRedList[itemdata.type] = redPoint
    self._tabList[itemdata.type] = item
    self:SetWndClick(item, function()
        self:OnClickTab(itemdata.type)
    end)

end

function UISubAreaCompile:OnClickShareTwitter()
    local isShow, link = gModelPlayer:CheckShowTwitterLink()
    if not isShow then
        return
    end

    if gModelPlayer:CheckReceiveSpecialDailyShareRewardGet() then
        gModelPlayer:OnReceiveSpecialDailyReq(ModelPlayer.RECEIVE_SPECIAL_DAILY_SHARE)
    end

    CS.UApplication.OpenURL(link)
end

function UISubAreaCompile:UpdateCanvas()
    self:CreateWndEffect(self.mRoleEff, "fx_ui_geren_mingpian", eff, 100, false, false)
    local canvas = self.mRoleEff:GetComponent(typeofCanvas)
    canvas.sortingOrder = self:GetWndSortOrder() + 1
    local canvas = self.mHeadIcon:GetComponent(typeofCanvas)
    canvas.sortingOrder = self:GetWndSortOrder() + 2
    local canvas = self.mPowerBg:GetComponent(typeofCanvas)
    canvas.sortingOrder = self:GetWndSortOrder() + 2
    local canvas = self.mNameObj:GetComponent(typeofCanvas)
    canvas.sortingOrder = self:GetWndSortOrder() + 2
    local canvas = self.mVipObj:GetComponent(typeofCanvas)
    canvas.sortingOrder = self:GetWndSortOrder() + 2
end
function UISubAreaCompile:OnClickSignature()
    GF.OpenWnd("UIAreaSignatureSet")
end
function UISubAreaCompile:OnClickTitle()
    local _playerInfo = self._playerInfo
    local title = _playerInfo.title
    if title and title > 0 then
        GF.OpenWnd("UIPerSpreadPop", { StructPersonaliseInfo = { refId = title, playerName = _playerInfo._name } })
        --gModelPlayerSpace:OnPersonaliseOtherInfoReq(_playerInfo._name,_playerInfo._playerId,title)
    else
        GF.ShowMessage(ccClientText(21148))
    end
end
--更新玩家信息
function UISubAreaCompile:GetMePlayerInfo(_currInfo)
    local data = _currInfo.playerInfo
    data._head = gModelPlayer:GetPlayerHead()
    data._headFrame = gModelPlayer:GetPlayerHeadFrame()
    data._grade = gModelPlayer:GetPlayerLv()
    data._vipLevel = gModelPlayer:GetVipLevel()
    data._name = gModelPlayer:GetPlayerName()
    data._power = gModelPower:GetMainCityPower()
    data._figure = gModelPlayer:GetPlayerFigure()
    data.age = gModelPlayer:GetPlayerAgeRefId()
    data.signature = gModelPlayer:GetPlayerSignature()
    data.title = gModelPlayer:GetPlayerTitle()
    data.badge = gModelPlayer:GetBadge()
    data._province = gModelPlayer:GetProvince()
    data._city = gModelPlayer:GetCity()
    data.sex = gModelPlayer:GetPlayerSex()
    data.disallowTalk = 0
    data.tag = gModelPlayer:GetPlayerTags()
    return _currInfo
end
function UISubAreaCompile:SetRunSpineAin(key)
    local dpSpine = self:FindWndSpineByKey(key)
    if not dpSpine:IsDpValid() then
        return
    end
    if not dpSpine:GetAnimation("attack1") then
        return
    end
    local entryName = dpSpine:GetCurTrackEntryName()
    if entryName ~= "attack1" then
        dpSpine:PlayAnimation(0, "attack1", false)
        dpSpine:SetAnimationCompleteFunc(function(ainName)
            if ainName == "attack1" then
                dpSpine:PlayAnimation(0, "idle", true)
            end
        end)
    end
end
------------------------------------------------------------------
return UISubAreaCompile