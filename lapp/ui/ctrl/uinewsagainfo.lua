---
--- Created by Administrator.
--- DateTime: 2023/10/15 14:28:38
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UINewSagaInfo:LWnd
local UINewSagaInfo = LxWndClass("UINewSagaInfo", LWnd)

local Time = Time
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local LUISkillCtrl = LxRequire("LApp.UI.Display.LUISkillCtrl")
---@type LUIDrawingCtrl
local LUIDrawingCtrl = LxRequire("LApp.UI.Display.LUIDrawingCtrl")
local YXUIPointUtil = CS.YXUIPointUtil
local typeScrollRect = typeof(CS.ScrollRect)

UINewSagaInfo.BTN_TYPE_ATTR = 1
UINewSagaInfo.BTN_TYPE_STAR = 2
UINewSagaInfo.BTN_TYPE_SKILL = 3
UINewSagaInfo.BTN_TYPE_OUTFIT = 4
UINewSagaInfo.BTN_TYPE_RUNE = 5
UINewSagaInfo.BTN_TYPE_EQUIP = 6
UINewSagaInfo.BTN_TYPE_PET = 7

UINewSagaInfo.DATA_TYPE_ATTR = 1
UINewSagaInfo.DATA_TYPE_OUTFIT = 2
UINewSagaInfo.DATA_TYPE_RUNEANDTALENT = 3
UINewSagaInfo.DATA_TYPE_EQUIP = 4

UINewSagaInfo.MAX_GRADE_NUM = 6
UINewSagaInfo.MAX_OUTFIT_NUM = 4
UINewSagaInfo.MAX_RUNE_NUM = 2
UINewSagaInfo.MAX_TALENT_NUM = 2
UINewSagaInfo.MAX_EQUIP_NUM = 4

UINewSagaInfo.AUTO_BTN_WEAR = 1  --一键穿戴装备
UINewSagaInfo.AUTO_BTN_UNLOAD = 2--一键卸下装备

UINewSagaInfo.ATTR_SHOW_DEF = {
    LAttrConst.Atk,
    LAttrConst.MaxHP,
    LAttrConst.Def,
    LAttrConst.Speed,
}

UINewSagaInfo.STATUS_OPT_0 = 0                -- 开始
UINewSagaInfo.STATUS_OPT_1 = 1                -- 满星满等级
UINewSagaInfo.STATUS_OPT_2 = 2                -- 满星不满等级
UINewSagaInfo.STATUS_OPT_3 = 3                -- 不满星满等级(去升星)
UINewSagaInfo.STATUS_OPT_4 = 4                -- 升阶
UINewSagaInfo.STATUS_OPT_5 = 5                -- 升级
UINewSagaInfo.STATUS_OPT_6 = 6                -- 升星
UINewSagaInfo.STATUS_OPT_7 = 7                -- 满星提示
UINewSagaInfo.STATUS_OPT_8 = 8                -- 伙伴已满级（卓越及以上可以通过共鸣继续提升等级）
UINewSagaInfo.STATUS_OPT_9 = 9                -- 共鸣
UINewSagaInfo.STATUS_OPT_10 = 10            -- 为试用英雄

UINewSagaInfo.PAGE_COMMON = 1            -- 页显示，常规页
UINewSagaInfo.PAGE_AWAKEN = 2            -- 页显示，觉醒页n

-- 点击时 未解锁的提示文本
UINewSagaInfo.ShowText = {
    [1] = 20173,
    [2] = 20174,
    [3] = 20175,
}
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UINewSagaInfo:UINewSagaInfo()
    ---@type table<string,LUIHeroObject>
    self._uiHeroObjList = nil
    self._uiLiHuiObjList = nil
    self._uiHeroCacheCnt = 0
    self._uiLiHuiCacheCnt = 0

    ---@type LUIHeroObject
    self._curUIHeroObj = nil
    self._curUILiHuiObj = nil            -- 当前立绘
    ---@type LUISkillCtrl
    self._uiSkillCtrl = nil
    self._uiDrawingCtrl = nil

    self._loopHeroObjTimerKey = 1119
    self._tryHeroPageDescTimeKey = "_tryHeroPageDescTimeKey"

    ---@type table<number, CommonIcon>
    self._commonUIList = {}

    self._awakenTreeList = {}
    self._awakenTreeTransList = {}

    self._showUpPowerAniKey = "_showUpPowerAniKey"

    self._trySpiritHeroNoActTimeKey = "_trySpiritHeroNoActTimeKey"
    self._trySpiritHeroActTimeKey = "_trySpiritHeroActTimeKey"

    --self:SetHideBottom()
    self:SetHideHurdle()
    self:SetHideTop()
    self:SetHideBottom()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UINewSagaInfo:OnWndClose()
    self:ClearCommonIconList(self._commonUIList)

    self._curUIHeroObj = nil
    LUtil.ClearHashTable(self._uiHeroObjList)
    self._uiHeroObjList = nil

    --这个是从列表器拿出来的，列表进行删除就好了
    self._curUILiHuiObj = nil
    LUtil.ClearHashTable(self._uiLiHuiObjList)
    self._uiLiHuiObjList = nil

    FireEvent(EventNames.ON_WND_HERO_INFO_CLOSE)

    if self._callFunc then
        self._callFunc()
    end
    gModelHero:ClearUpStarSelHeroList()
    gModelHero:ClearUpLvTreeSelHeroList()
    GF.CloseWndByName("UIOrdinBulletSay")

    if self._isUp then
        gModelResonance:OnResonanceInfoReq()
    end

    gLGameAudio:StopSingleSound()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UINewSagaInfo:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UINewSagaInfo:OnStart()
    LWnd.OnStart(self)

    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    if self._isEnus then
        local gameobjectTran = CS.FindTrans(self.mGameObject_Bottom, "GameObject")
        self:SetAnchorPos(gameobjectTran, Vector2.New(-135, -88.2))
    end

    if self._isVie then
        self:SetAnchorPos(self.mLvBeforeTxt, Vector2.New(0, 0))
        self:SetAnchorPos(self.mLvArrow, Vector2.New(66, 0))
        self:SetAnchorPos(self.mLvAfterTxt, Vector2.New(141.8, 0))

        self:SetAnchorPos(self.mAtkAddBeforeTxt, Vector2.New(0, 0))
        self:SetAnchorPos(self.mAtkArrow, Vector2.New(66, 0))
        self:SetAnchorPos(self.mAtkAddAfterTxt, Vector2.New(141.8, 0))
    end

    self:CreateWndSpine(self.mPolymorphicSpine, "ui_hero_btn_xingtai_2", "ui_hero_btn_xingtai_2", false, function(dpTrans)
        dpTrans._displayTrans.sizeDelta = Vector2.New(0, 0)
    end)

    self:InitEffList()
    self:InitData()
    self:InitText()
    self:InitEvent()
    self:InitMsg()

    self:InitTabData()
    self:InitTabList()

    self:UpdatePetLinkRed()
    self:RefreshShow()
    self:RefreshHeroLoveInfo()
    CS.ShowObject(self.mCommentBtn,gModelFunctionOpen:CheckIsShow(10303006))


    --self:ChangeBotBtn(self._btnIndex, true)
    --必须切两次 才能正确设置_btnIndex 
    self:OnClickTab(UINewSagaInfo.BTN_TYPE_EQUIP)  --刷一次数据 才能正常显示红点的数据
    self:OnClickTab(UINewSagaInfo.BTN_TYPE_STAR)
    self:OnClickTab(UINewSagaInfo.BTN_TYPE_ATTR)

    GF.CloseWndByName("UIEqWear")
end

function UINewSagaInfo:OnHeroTreeResetResp(pb)
    gModelHero:ClearUpLvTreeSelHeroList()
    --self:RefreshAwakenView()
end

function UINewSagaInfo:OnClickBadgeBtn()
    GF.OpenWnd("UIBadgeWear",{
        refId = self._refId,
        id = self._id,
        career = self._career,
        race = self._race,
        cbFunc = function()
            if not self:IsWndValid() then return end
            self:RefreshBadgeDiv()
        end
    })
end

--function UINewSagaInfo:OnClickTreePoint(treePointRefId)
--	if self._curSelectTreePointId == treePointRefId then
--		return
--	end
--
--	local oldSelectTreePointId = self._curSelectTreePointId
--	local treePointTransList   = self._awakenTreeTransList[self._treePbName]
--	local oldPointInfo = treePointTransList[oldSelectTreePointId]
--	if oldPointInfo then
--		CS.ShowObject(oldPointInfo.selectIcon, false)
--	end
--
--	local curPointInfo = treePointTransList[treePointRefId]
--	if curPointInfo then
--		CS.ShowObject(curPointInfo.selectIcon, true)
--	end
--
--	self:ShowPrepositionPointEff(false, oldSelectTreePointId)
--	self:ShowPrepositionPointEff(true, treePointRefId)
--
--	self._curSelectTreePointId = treePointRefId
--	self:RefreshAwakenDetails()
--end

function UINewSagaInfo:OnClickAwakenSkillSelect(skillId)

    --[[	if self._isTryHero then
            GF.ShowMessage(ccClientText(10088))
            return
        end]]

    local treePointRefId = self._curSelectTreePointId
    if not treePointRefId then
        printInfoNR("self._curSelectTreePointId is a nil")
        return
    end

    local heroTreePointInfo = self._heroTreeInfoList[treePointRefId]
    if not heroTreePointInfo then
        printInfoNR("self._heroTreeInfoList[treePointRefId] is a nil, treePointRefId = " .. treePointRefId)
        return
    end

    local isActivate = heroTreePointInfo.isActivate
    if not isActivate then
        GF.ShowMessage(ccClientText(20154))
        return
    end

    if self._curSelectTreePointSkillId == skillId then
        return
    end

    local heroId = self._id
    local pointRefId = treePointRefId
    gModelHero:OnHeroTreePointSelectSkillReq(heroId, pointRefId, skillId)
end

function UINewSagaInfo:CutHero(curIndex)
    if self._curUIHeroObj and not self._curUIHeroObj:IsDpValid() then
        return
    end
    local index = self._heroIndex
    if not index then
        return
    end
    local cnt = #self._cutHeroList

    --local lastNum = gModelHero:GetLastNum()
    local newIndex = index + curIndex
    if newIndex <= 0 then
        newIndex = cnt
    elseif newIndex > cnt then
        newIndex = 1
    end
    self:CutHeroRefresh(newIndex)
end

function UINewSagaInfo:OnLinkPetCell(list, item, itemdata, itempos)
    local IconHead = self:FindWndTrans(item, "CommonUI/IconHead")
    local IconBg = self:FindWndTrans(item, "CommonUI/IconBg")
    local RedPoint = self:FindWndTrans(item, "CommonUI/RedPoint")
    local Icon = self:FindWndTrans(item, "CommonUI/Icon")
    local ImgMask = self:FindWndTrans(item, "ImgMask")
    local TxtMask = self:FindWndTrans(item, "ImgMask/TxtMask")
    CS.ShowObject(IconBg, false)
    CS.ShowObject(Icon, false)
    CS.ShowObject(ImgMask, false)
    CS.ShowObject(IconHead, false)
    CS.ShowObject(RedPoint, false)
    if itemdata.petId then
        --链接宠物
        CS.ShowObject(Icon, true)
        local instanceId = item:GetInstanceID()
        local commonUIList = self._commonUIList
        local uiIconClass = commonUIList[instanceId]
        if not uiIconClass then
            uiIconClass = CommonIcon:New()
            commonUIList[instanceId] = uiIconClass
            uiIconClass:Create(Icon)
            self:SetIconClickScale(Icon, true)
        end
        uiIconClass:SetPetDataSet(itemdata.petId)
        uiIconClass:SetShowGouImg(false)
        uiIconClass:DoApply()
    else
        if itemdata.ref.num <= self.allStarLv then
            --可连接
            CS.ShowObject(IconBg, true)
            CS.ShowObject(IconHead, true)
            CS.ShowObject(RedPoint, self.petLinkRed)
        else
            --未解锁
            CS.ShowObject(IconBg, true)
            CS.ShowObject(ImgMask, true)
            local str = string.replace(ccClientText(43772), itemdata.ref.num) --ccClientText(43729)
            self:SetWndText(TxtMask, str)
        end
    end
    self:SetWndClick(item, function()
        if itemdata.ref.num > self.allStarLv then
            GF.OpenWnd("UIPeMinWin")
            return
        end
        if itemdata.petId then
            GF.OpenWnd("UIPeView", { refId = itemdata.petId, playerId = gModelPlayer:GetPlayerId(), showBtn = true, heroId = self._id })
            return
        end
        GF.OpenWnd("UISagaLinkPe", { heroId = self._id })

    end)
end

function UINewSagaInfo:OnClickUpStarEvent()
    if self._sendMsg then
        return
    end
    if self._isLimit then
        local limitStar = string.replace(ccClientText(14724), self._upStarLimit)
        GF.ShowMessage(limitStar)
    else
        local data = self._selectHeroList
        if table.isempty(data) then
            GF.ShowMessage(ccClientText(14425))
        else
            local id = self._id
            if id and data then
                local appointedlist, rangelist, rangItemList = data.appointList, data.rangList, data.rangItemList
                local appNeedInfo, rangNeedInfo, itemNeedInfo = data.appNeedInfo, data.rangNeedInfo, data.itemNeedInfo
                for i, v in ipairs(appointedlist) do
                    local needNum = appNeedInfo[i].needNum
                    local selNum = table.keysize(v)
                    if selNum < needNum then
                        GF.ShowMessage(ccClientText(10054))
                        return
                    end
                end
                for i, v in ipairs(rangelist) do
                    local selItemNum = 0
                    local temp = rangItemList[i] or {}
                    for itemId, _v in pairs(temp) do
                        selItemNum = selItemNum + _v
                    end
                    local needNum = rangNeedInfo[i].needNum
                    local selHeroNum = 0
                    for selRangHeroId, val in pairs(v) do
                        selHeroNum = selHeroNum + 1
                    end
                    local selNum = selHeroNum + selItemNum
                    if selNum < needNum then
                        GF.ShowMessage(ccClientText(10054))
                        return
                    end
                end
                for i, v in ipairs(itemNeedInfo) do
                    local itemRefId, needNum = v.itemRefId, v.needNum
                    local haveNum = gModelItem:GetNumByRefId(itemRefId)
                    if haveNum < needNum then
                        gModelGeneral:OpenGetWayWnd({ itemId = itemRefId })
                        return
                    end
                end
                local upStarFunc = function()
                    self._sendMsg = true
                    gModelHero:CheckHeroHightHero(appointedlist, rangelist, function()
                        --gModelHero:OnHeroUpStarReqByHeroInfoWnd(id,appointedlist,rangelist,rangItemList,true)
                        local list = {
                            { id = id, appointedlist = appointedlist, rangelist = rangelist, rangItemList = rangItemList }
                        }
                        gModelHero:OnHeroUpStarReq(list)
                    end, function()
                        self._sendMsg = false
                    end, id)
                end
                if gModelHeroExtra:CheckUpStarIsSelRare(rangelist, rangItemList, rangNeedInfo) then
                    local winData = { refId = 10046, func = upStarFunc }
                    gModelGeneral:OpenUIOrdinTips(winData)
                else
                    upStarFunc()
                end
            end
        end
    end
end

function UINewSagaInfo:OnClickShareTwitter()
    local isShow, link = gModelPlayer:CheckShowTwitterLink()
    if not isShow then
        return
    end

    if gModelPlayer:CheckReceiveSpecialDailyShareRewardGet() then
        gModelPlayer:OnReceiveSpecialDailyReq(ModelPlayer.RECEIVE_SPECIAL_DAILY_SHARE)
    end

    CS.UApplication.OpenURL(link)
end

function UINewSagaInfo:InitTabList()
    local uiList = self:GetUIScroll("UINewSagaInfo")
    uiList:Create(self.mTabScroll, self._tabData, function(...)
        self:OnDrawTab(...)
    end)
    self._tabUiList = uiList

end

function UINewSagaInfo:RefreshAttrPage(netWork)
    self:TimerStop(self._trySpiritHeroNoActTimeKey)
    self:TimerStop(self._trySpiritHeroActTimeKey)
    self:CreateAttrList(netWork)
    self:CreateGradeList()
    local refId = self._refId
    local isSpiritHero = gModelSpiritHero:CheckIsSpiritHero(refId)
    if isSpiritHero then
        self:RefreshSpiritHeroAttrDiv()
    else
        self:RefreshCommonAttrDiv()
    end
    CS.ShowObject(self.mCommonAttrRaceDiv, not isSpiritHero)
    CS.ShowObject(self.mSpecialAttrRaceDiv, isSpiritHero)
end

function UINewSagaInfo:RefreshShiftAwakenBtn()
    CS.ShowObject(self.mShiftAwakenRedPoint, false)

    self:RefreshTopLeftList()
    ---- qx:与英雄的品质挂钩，品质不足隐藏入口
    local isShowAwaken = self:GetHeroAwakenIsOpen()
    CS.ShowObject(self.mShiftAwakenBtn, isShowAwaken)
    if not isShowAwaken then
        return
    end

    local isOpen = gModelFunctionOpen:CheckIsOpened(10306001)
    local awakenLockStr = ""
    local limitShow = not isOpen
    local id = self._id
    local serverData = gModelHero:GetHeroServerDataById(id)
    local heroAwaken = gModelHero:GeConfigByKey("heroAwaken")
    local limitStar
    if limitShow then
        --- 功能未开启 : 显示未解锁
        isShowAwaken = false
        awakenLockStr = ccClientText(26656)
    else
        if serverData then
            local star = serverData.star
            isShowAwaken = star >= heroAwaken
        else
            isShowAwaken = false
            awakenLockStr = ccClientText(26656)
        end
    end
    self:SetWndText(self.mAwakenLockTxt, awakenLockStr)

    if limitShow then
        CS.ShowObject(self.mAwakenLockTxt, true)
        CS.ShowObject(self.mShiftAwakenIcon, false)
        CS.ShowObject(self.mShiftAwakenLvlText, false)
        --self:ChangeAwakenIcon(0)
        return
    end
    if not serverData then
        return
    end
    local star = serverData.star
    local showShiftAwakenRed = false
    local showLockTxt = false
    local awakenLv = 0
    local showMaxLv = false
    local useStar = limitStar or heroAwaken
    if star >= useStar then
        if not self._isTryHero then
            showShiftAwakenRed = gModelHero:CheckHeroAwakenTreeActivateOrUpLv(id)
        end

        local curLv, maxLv = gModelHero:GetTreePointsLvlData(id)
        awakenLv = curLv

        showMaxLv = curLv >= maxLv

        if not showMaxLv then
            self:SetWndText(self.mShiftAwakenLvlText, curLv)
        end
    else
        --- 星级不足，显示解锁条件
        --awakenLockStr = string.replace(ccClientText(26672),heroAwaken)
        awakenLockStr = ccClientText(26656)
        showLockTxt = true
    end
    self:SetWndText(self.mAwakenLockTxt, awakenLockStr)

    --self:ChangeAwakenIcon(awakenLv)

    CS.ShowObject(self.mAwakenLockTxt, showLockTxt)
    CS.ShowObject(self.mShiftAwakenIcon, showMaxLv)
    CS.ShowObject(self.mShiftAwakenLvlText, not showMaxLv)
    CS.ShowObject(self.mShiftAwakenRedPoint, showShiftAwakenRed)
    self:RefreshHeroName()
end

function UINewSagaInfo:OnHeroWaitRefresh()

end

function UINewSagaInfo:GetAttrList(netWork)
    local list = {}
    local attrList = self:GetHeroInfoByType(UINewSagaInfo.DATA_TYPE_ATTR, netWork) or {}
    for i, v in ipairs(UINewSagaInfo.ATTR_SHOW_DEF) do
        local value = attrList[v] or 0
        table.insert(list, {
            refId = v,
            value = math.floor(value + 0.5),
        })
    end
    return list
end

function UINewSagaInfo:Refresh(click)
    local btnIndex = self._btnIndex
    local showAttrTip = self._showTip[btnIndex] or false
    CS.ShowObject(self.mAttrTipBtn, showAttrTip)
    local func
    for k, v in pairs(self._botBtnTransList) do
        local sel = btnIndex == v.index
        self:CheckIsOpen(v.index)
        CS.ShowObject(v.textTrans, sel)
        CS.ShowObject(v.NoTextTrans, not sel)
        if sel then
            func = v.func
        end
        CS.ShowObject(v.rootImg, sel)
        if v.page then
            CS.ShowObject(v.page, sel)
        end
    end
    if func then
        func(click)
    end
    self._curSelectTreePointId = nil
    self:RefreshAwakenPage()
    self:RefreshGolemBtn()
    self:RefreshHeroBattleRankBtn()

    self:RefreshBtnShow()
    self:RefreshBadgeDiv()
end

function UINewSagaInfo:OnClickLike()
    self:CreateWndEffect(self.mLoveBtn, "fx_ui_xihuan", "fx_ui_xihuan", 100, nil, nil, 30)
    local heroRefId = self._refId
    if not heroRefId then
        return
    end
    gModelHeroBook:OnHeroForLoveReq(heroRefId)
    self._sendLoveEvent = true
end

function UINewSagaInfo:RefreshHeroByIndex(heroIndex)
    if not self:IsWndValid() then
        return
    end
    if heroIndex then
        local heroData = self._cutHeroList[heroIndex]
        --local data = gModelHero:GetHeroBagPos(heroIndex)
        if not table.isempty(heroData) then
            self:RefreshHeroData(heroData, heroIndex)
        end
    end
    if self._isChangeSkin then
        self._isChangeSkin = false
    end
end

function UINewSagaInfo:CheckShowSkinBtn()
    local heroStarRef = gModelHero:GetStarRefById(self._id) -- gModelHero:GetHeroStarById(starId)	-- 星级表
    local skinEffectId = heroStarRef.skinEffectId
    local showSkinBtn = not string.isempty(skinEffectId)

    --判断下 是否有高形态 self._refId

    local effectId = heroStarRef.effectId

    --这里判断下 是否要插入数据
    local skins = gModelHero:GetPolymorphism(effectId)

    showSkinBtn = showSkinBtn or not (skins == nil)
    return showSkinBtn
end
function UINewSagaInfo:CreateDisplay()
    local effRef, showEffId, star = self:GetHeroEffectRef()
    if not showEffId then
        return
    end
    if not effRef then
        return
    end
    local x, y = gModelHeroBook:GetHeroPosByRefIdAndType(showEffId, "heroDrawingPos1")
    if x and y then
        self.mHeroLiHuiPos.anchoredPosition = Vector3.New(x, y, 0)
        self.mHeroLiHuiEffPos.anchoredPosition = Vector3.New(x, y, 0)
    end

    local prefabName = effRef.prefabName
    local heroDrawing = effRef.heroDrawing
    local effId = effRef.refId
    self:CreateSpine(prefabName, star, effId)
    self:CreateLiHui(heroDrawing, effRef)
end

function UINewSagaInfo:RefreshStarPage()
    CS.ShowObject(self.mStarView, self._curAwakenShowType == UINewSagaInfo.PAGE_COMMON)
    self:RefreshStarView()
    self:RefreshSpiritHeroAttrDiv()
end

function UINewSagaInfo:OnClickTab(index)
    --if self._tabIndex == index then return end
    if self._tabIndex ~= index and self.isClickSound then
        gLGameAudio:StopSingleSound()
    end
    local oldIndex = self._tabIndex
    self._tabIndex = index;
    self:SetWndTabStatus(self._tabList[oldIndex], 1)
    self:SetWndTabStatus(self._tabList[index], 0)

    self:ChangeBotBtn(index)
end

function UINewSagaInfo:OnClickBattleRankBtnFunc()
    local heroRefId = self._refId
    if not heroRefId then
        return
    end
    GF.OpenWnd("UISagaFightArrayRk", { heroRefId = heroRefId })
end

--- 饰品
function UINewSagaInfo:RefreshBadgeDiv()
    local redPoint = false
    local isOpen = gModelBadge:CheckBadgeOpen()
    if isOpen then
        local heroId = self._id
        if heroId and gModelBadge:CheckIsCanWear(heroId) then
            redPoint = gModelBadge:GetBadgeWearRed(heroId)
        else
            isOpen = false
        end
    end
    CS.ShowObject(self.mBadgeDiv,isOpen)
    CS.ShowObject(self.mBadgeRp,redPoint)
end

function UINewSagaInfo:RefreshAttrActLink()
    self:RefreshSpiritHeroActPageTime()
    self:TimerStop(self._trySpiritHeroActTimeKey)
    if self._isTryHero then
        self:TimerStart(self._trySpiritHeroActTimeKey, 1, false, -1)
    end
    local spiritLinkId = self:GetSpiritHeroId()
    local showIcon = spiritLinkId ~= nil
    CS.ShowObject(self.mAttrSpecialLinkHeroRoot, showIcon)
    if not showIcon then
        return
    end
    self:CreateLinkHeroIcon(self.mAttrSpecialLinkHeroRoot, spiritLinkId)
    -- self:CreateLinkHeroIcon(self.mAttrSpecialLinkHeroRoot, self._id)
end

--function UINewSagaInfo:RefreshAwakenView()
--	if true then return end
--
--	local id = self._id
--	local serverData = gModelHero:GetHeroServerDataById(id)
--	if not serverData then return end
--	local treeInfo	= serverData.treeInfo
--	if not treeInfo then
--		printInfoNR("treeInfo is a nil")
--		return
--	end
--
--	local treeRefId	= treeInfo.treeRefId
--	if treeRefId == 0 then return end
--	self._treeRefId = treeRefId
--
--	local heroTreeInfoList	= gModelHero:GetServerHeroTreeInfoByHeroId(self._id)
--	if not heroTreeInfoList then return end
--	self._heroTreeInfoList	= heroTreeInfoList
--
--	local curSelectTreePointId, sortIndex
--	if not self._curSelectTreePointId then
--		curSelectTreePointId, sortIndex = self:GetDefaultSelectTreePoint()
--	end
--
--	self:RefreshAwakenTree()
--	self:RefreshAwakenDetails()
--
--	local curAllLv,maxLv = gModelHero:GetTreePointsLvlData(id)
--	local pandectProgressStr = string.replace(ccClientText(20150),curAllLv, maxLv)
--	self:SetWndText(self.mAwakenPandectProgressText, pandectProgressStr)
--
--	--local heroName = gModelHero:GetHeroNameByRefId(serverData.refId,serverData.star)
--
--	local shiftBtnIconPath = self:GetShiftAwakenBgIconPath()
--	if LxUiHelper.IsImgPathValid(shiftBtnIconPath) then
--		self:SetWndEasyImage(self.mShiftUpStarBtn, shiftBtnIconPath)
--	end
--
--	if curSelectTreePointId then
--		self:OnClickTreePoint(curSelectTreePointId)
--	end
--
--	self._activateAwakenHeroList = gModelHero:GetActivateHeroList()
--	local isShowAwakenCutArrow = #self._activateAwakenHeroList > 1
--	CS.ShowObject(self.mAwakenLeftBtn, isShowAwakenCutArrow)
--	CS.ShowObject(self.mAwakenRightBtn, isShowAwakenCutArrow)
--end

--function UINewSagaInfo:RefreshAwakenTree()
--	local treeRefId = self._treeRefId
--	if not self._treeRefId then
--		return
--	end
--
--	local treeRef = gModelHero:GetHeroTreeRef(treeRefId)
--	if not treeRef then
--		printInfoNR("GameTable.CharacterTreeRef[refId] is a nil, refId = "..treeRefId)
--		return
--	end
--
--	local treePbName = treeRef.treePb
--	self._treePbName = treePbName
--	local awakenTreeList = self._awakenTreeList
--
--	local awakenTreeTrans = awakenTreeList[treePbName]
--	if not awakenTreeTrans then
--		self:CreateWndPrefab(self.mAwakenTree, treePbName, treePbName, function(prefabTrans)
--			self._awakenTreeList[treePbName] = prefabTrans
--			self:CreateAwakenTree(prefabTrans, treePbName)
--			self:SendGuideReadyEvent(self:GetWndName())
--		end, CS.RES_UI_HERO_AWAKEN_TREE)
--	else
--		self:CreateAwakenTree(awakenTreeTrans, treePbName)
--	end
--
--	for k,v in pairs(awakenTreeList) do
--		CS.ShowObject(v, k == treePbName)
--	end
--end

--function UINewSagaInfo:CreateAwakenTree(treeTrans)
--	local heroTreeInfoList	= self._heroTreeInfoList
--	if not heroTreeInfoList then return end
--
--	local pointListTrans	= self:FindWndTrans(treeTrans, "ScrollRect/Content/PointList")
--	for k,v in pairs(heroTreeInfoList) do
--		self:OnDrawAwakenTreePointCell(pointListTrans,v,k)
--	end
--end

--function UINewSagaInfo:OnDrawAwakenTreePointCell(parentRoot,itemdata,itempos)
--	local treePbName = self._treePbName
--	if not treePbName then
--		return
--	end
--
--	local list = self._awakenTreeTransList[treePbName]
--	if not list then
--		self._awakenTreeTransList[treePbName] = {}
--		list = self._awakenTreeTransList[treePbName]
--	end
--
--	local treePointRefId	= itemdata.treePointRefId
--	local info 				= list[treePointRefId]
--	if not info then
--		local pointRef			= gModelHero:GetHeroTreePointRef(treePointRefId)
--		local treePbNode		= pointRef.treePbNode
--		local pointTrans 		= self:FindWndTrans(parentRoot, treePbNode)
--		if not pointTrans then
--			printInfoNR("trans not find, transName = "..treePbNode)
--			return
--		end
--
--		info = {
--			pointTrans		= pointTrans,
--			commonBgTrans	= self:FindWndTrans(pointTrans, "CommonBg"),
--			coverBgTrans	= self:FindWndTrans(pointTrans, "CoverBg"),
--			commonIcon		= self:FindWndTrans(pointTrans, "CommonIcon"),
--			coverIcon		= self:FindWndTrans(pointTrans, "CoverIcon"),
--			selectIcon		= self:FindWndTrans(pointTrans, "SelectIcon"),
--			upIcon			= self:FindWndTrans(pointTrans, "UpIcon"),
--			newIcon			= self:FindWndTrans(pointTrans, "NewIcon"),
--			skillTrans		= self:FindWndTrans(pointTrans, "Skill/Root/SkillIcon"),
--		}
--
--		list[treePointRefId] = info
--	end
--
--	local isTryHero			= self._isTryHero
--	local pointTrans		= info.pointTrans
--	local isActivate 		= itemdata.isActivate or false
--	local canActivate		= itemdata.canActivate or false
--	local canLvlUp			= itemdata.canLvlUp or false
--	local isSelect			= treePointRefId == self._curSelectTreePointId
--	local showActivate		= canActivate and canLvlUp and not isTryHero
--	local showLvUp			= isActivate and canLvlUp and not isTryHero
--
--	CS.ShowObject(info.commonBgTrans, not isActivate)
--	CS.ShowObject(info.commonIcon, not isActivate)
--	CS.ShowObject(info.coverBgTrans, isActivate)
--	CS.ShowObject(info.coverIcon, isActivate)
--	CS.ShowObject(info.selectIcon, isSelect)
--	CS.ShowObject(info.upIcon, showLvUp)
--
--	local showNewIcon = showActivate and not isTryHero
--	if not showNewIcon and not isTryHero then
--		--只不满足激活材料这条件时，也显示New
--		showNewIcon = not isActivate and canActivate and not canLvlUp and itemdata.needCon ~= true
--	end
--	CS.ShowObject(info.newIcon, showNewIcon)
--
--	self:SetWndClick(pointTrans, function()
--		self:OnClickTreePoint(treePointRefId)
--	end)
--
--	--可激活特效
--	self:SetAwakenPointEffShow(showActivate, "ui_yingxiongjuexing_kejihuo", pointTrans)
--
--	--激活特效
--	local isCurActivatePoint = not isTryHero and self._showAwakenPointActivateEff == treePointRefId
--	self:SetAwakenPointEffShow(isCurActivatePoint, "ui_yingxiongjuexing_jihuo", pointTrans)
--
--	local isCurUpLvPoint = not isTryHero and self._showAwakenPointUpLvEff == treePointRefId
--	self:SetAwakenPointEffShow(isCurUpLvPoint, "ui_yingxiongjuexing_shengji", pointTrans)
--
--	local pointType 		= itemdata.pointType
--	local effName			= pointType == ModelHero.TREE_POINT_TYPE_ATTR and "ui_yingxiongjuexing_qianzhi" or "ui_yingxiongjuexing_qianzhi_2"
--	self:SetAwakenPointEffShow(false, effName, pointTrans)
--
--	--技能图标
--	if pointType == ModelHero.TREE_POINT_TYPE_SKILL and info.skillTrans then
--		local skillIconList = self._skillIconList
--		if not skillIconList then
--			skillIconList = {}
--			self._skillIconList = skillIconList
--		end
--
--		local skillIconTrans = info.skillTrans
--		local skillId = itemdata.skillId
--		local haveSkill = skillId and skillId > 0
--		local InstanceID = skillIconTrans:GetInstanceID()
--		local baseClass = skillIconList[InstanceID]
--		if not baseClass then
--			baseClass = SkillIcon:New(self)
--		end
--
--		if not haveSkill then
--			baseClass:SetShowIcon(false,false)
--			baseClass:SetSkillInfo(nil,nil,nil,1)
--			baseClass:ShowLvl(false)
--			baseClass:Create(skillIconTrans,0,function()
--				if not isActivate then
--					GF.ShowMessage(ccClientText(20154))
--					return
--				end
--				self:OnClickSkillSelect(treePointRefId)
--			end)
--			baseClass:SetIconAndIconBgGray(false)
--		else
--			baseClass:SetSkillInfo(nil,false,nil,1)
--			baseClass:ShowLvl(false)
--			baseClass:ShowLock(false)
--			baseClass:Create(skillIconTrans,skillId,function()
--				self:OnClickSkillSelect(treePointRefId)
--			end)
--			baseClass:SetIconAndIconBgGray(false)
--		end
--	end
--end

function UINewSagaInfo:SetAwakenPointEffShow(isShow, effName, pointTrans)
    local InstanceID = pointTrans:GetInstanceID()
    local effKey = effName .. InstanceID
    if isShow then
        self:CreateWndEffect(pointTrans, effName, effKey, 100, false, false, 26)
    else
        self:DestroyWndEffectByKey(effKey)
    end
end

function UINewSagaInfo:RefreshTopLeftList()
    CS.ShowObject(self.mShiftAwakenDiv, false)
    CS.ShowObject(self.mShiftAwakenBtn, false)
    if PRODUCT_G_VER == 1 then
        if not gModelFunctionOpen:CheckIsOpened(50500010, true) then
            -- CS.ShowObject(self.mTopLeftList, false)
            return
        end
    end
    local isShow = false
    local showAwaken = self:GetHeroAwakenIsOpen()
    CS.ShowObject(self.mShiftAwakenDiv, showAwaken)
    CS.ShowObject(self.mShiftAwakenBtn, showAwaken)
    isShow = showAwaken
    -- CS.ShowObject(self.mTopLeftList, isShow)
end

function UINewSagaInfo:RefreshCommonAttrDiv()
    local refId, id = self._refId, self._id
    local serData = gModelHero:GetHeroServerDataById(id)
    local heroRef = gModelHero:GetHeroRef(refId)                -- 英雄表
    if not serData or not heroRef then
        return
    end

    local star = serData.star
    local lv = serData.lv
    local grade = serData.grade
    local classType = heroRef.classType                -- 阶级数据
    local classId = gModelHero:ConvertToHeroGradeId(classType, grade)    -- 阶级Id
    local classRef = gModelHero:GetHeroClassById(classId)    -- 阶级表
    local needLv = classRef.needLevel                -- 升到下一阶的等级需求
    local needStar = classRef.needStar                -- 升到下一阶的星级需求
    local needItem = classRef.needItem                -- 升到下一阶的道具需求
    local maxStar = heroRef.maxStar                    -- 星级上限
    local starUpLevellimit = heroRef.starUpLevellimit        -- 可升级的最高等级
    local heroStarRef = gModelHero:GetStarRefById(id)    -- 星级表
    local isResonance = serData.isResonance

    local tmpLv = needLv - lv
    if tmpLv > 5 then
        tmpLv = 5
    end
    if tmpLv < 0 then
        tmpLv = 5
    end
    self._upLv = tmpLv
    local optType
    local showDesc = false
    local showOptBtn = true
    local temp = string.replace(ccClientText(10063), tmpLv)
    local lvStr

    self:StopTryHeroPageDescTime()
    if self._isTryHero then
        optType = UINewSagaInfo.STATUS_OPT_10
        showDesc = true
        showOptBtn = false
        local maxLv = heroStarRef.maxLevel            -- 等级上限
        if lv > maxLv then
            maxLv = gModelResonance:GetResonanceMaxLv()
        end
        lv = string.format("<color=#%s>%s</color>/%s", "ffd265", lv, maxLv)
        lvStr = string.replace(ccClientText(10011), lv)
        self:StartTryHeroPageDescTime()
    elseif isResonance == 1 then
        optType = UINewSagaInfo.STATUS_OPT_9
        showDesc = true
        self:SetWndText(self.mAttrPageDesc, ccClientText(14723))
        local maxLv = gModelResonance:GetResonanceMaxLv()
        lv = string.format("<color=#%s>%s</color>/%s", "ffd265", lv, maxLv)
        lvStr = string.replace(ccClientText(10011), lv)
        self:SetWndButtonText(self.mUpLvBtn, temp)
        showOptBtn = false
    else
        local maxLevel = heroStarRef.maxLevel            -- 等级上限
        lvStr = string.format("Lv：<color=#%s>%s</color>/%s", "ffd265", lv, maxLevel)
        optType = self:GetOptStatus(star, maxStar, lv, maxLevel, needLv, needStar)
        if starUpLevellimit <= lv then
            optType = UINewSagaInfo.STATUS_OPT_8
        end
        if optType == UINewSagaInfo.STATUS_OPT_1 or optType == UINewSagaInfo.STATUS_OPT_3 then
            local text = ccClientText(10004)
            if optType == UINewSagaInfo.STATUS_OPT_3 then
                if needStar == -1 then
                    text = ccClientText(10051)
                    needStar = star + 1
                else
                    text = ccClientText(10025)
                end
                text = string.replace(text, needStar)
            else
                showDesc = true
            end
            self:SetWndText(self.mAttrPageDesc, text)
        end
    end
    self:SetWndText(self.mLvTxt, lvStr)
    self._optType = optType

    CS.ShowObject(self.mAttrBotBtnRedPoint, false)
    CS.ShowObject(self.mUpLvBtnRedPoint, false)
    local needItemList = {}
    CS.ShowObject(self.mUpLvBtn_2, false)
    if optType == UINewSagaInfo.STATUS_OPT_1 then
        showOptBtn = false
    elseif optType == UINewSagaInfo.STATUS_OPT_3 then
        self:SetWndButtonText(self.mUpLvBtn, ccClientText(10003))
    elseif optType == UINewSagaInfo.STATUS_OPT_4 then
        self._needItemList = {}
        self:SetWndButtonText(self.mUpLvBtn, ccClientText(10002))
        if not string.isempty(needItem) then
            local show = true
            local list = string.split(needItem, ",")
            for i, v in ipairs(list) do
                local data = string.split(v, "=")
                local _itype, _refId, _num = tonumber(data[1]), tonumber(data[2]), tonumber(data[3])
                local have = gModelItem:GetNumByRefId(_refId)
                if show then
                    show = have >= _num
                end
                table.insert(self._needItemList, { refId = _refId, num = _num, have = have })
                table.insert(needItemList, { itemId = _refId, itemNum = _num, itemType = _itype })
            end
            CS.ShowObject(self.mAttrBotBtnRedPoint, show)
            CS.ShowObject(self.mUpLvBtnRedPoint, show)
        end
    elseif optType == UINewSagaInfo.STATUS_OPT_5 then
        local isEnoughUp_100 = false

        self._needItemList = {}

        local itemRefIdList = { 101001, 104001 }
        local haveGold, haveExp = gModelItem:GetNumByRefId(itemRefIdList[1]), gModelItem:GetNumByRefId(itemRefIdList[2])
        local needGold, needExp, addLv
        if lv >= 100 then
            needGold, needExp, addLv = gModelHero:GetUpNumLvPayItem(id, lv, classId, grade, lv + 1)
            self:GetCurCanUpCostItem()
        else
            -- 这里判断是否可以直接升级到100  --判断经验
            local maxGrade, isStarLimit = gModelHeroExtra:GetMaxGradeByClassType(classType, grade, star)
            local tempclassId = gModelHero:ConvertToHeroGradeId(classType, maxGrade)
            --计算玩tempclassId 计算下是否满足当前的星级
            local maxLv = gModelHero:GetHeroUpLvLastNode(classType)

            local starType = gModelHero:GetHeroStarType(refId, serData.form) or 0
            local starId = gModelHero:GetStarId(starType, star)
            if starId then
                ---@type V_HeroStarRef
                local tempStarRef = gModelHero:GetHeroStarById(starId)
                if tempStarRef and tempStarRef.maxLevel > maxLv and tempStarRef.maxLevel <= 100 then
                    maxLv = tempStarRef.maxLevel
                end
            end

            --先判断经验  和金币 够不够
            local tempneedGold, tempneedExp, tempaddLv = gModelHero:GetUpNumLvPayItem(id, lv, tempclassId, maxGrade, maxLv, true)
            --判断经验
            local tempItem = 0
            if haveExp >= tempneedExp and (tempaddLv + lv) >= maxLv then
                if haveGold >= tempneedGold then
                    local tClassRef = gModelHero:GetHeroClassById(tempclassId)    -- 阶级表
                    if star < tClassRef.needStar then
                        tempclassId = tempclassId - 1
                    end
                    --钱够了 判断下升阶段要用的消耗
                    local tempNeedItem = gModelHero:GetHeroClassByIdToTargetIdCostItem(classId, tempclassId)
                    local gradeGold = tempNeedItem[101001] or 0
                    gradeGold = gradeGold + tempneedGold
                    --加上金钱的部分
                    if haveGold >= gradeGold then
                        local gradeItem = tempNeedItem[100110] or 0
                        local haveGradeItem = gModelItem:GetNumByRefId(100110)
                        if haveGradeItem >= gradeItem then
                            isEnoughUp_100 = true
                            tempItem = gradeItem
                        end
                    end
                    tempneedGold = gradeGold
                end
            end

            if isEnoughUp_100 then
                --处理下所需要的消耗
                self:GetCurCanUp100CostItem(tempneedGold, tempneedExp, tempItem, maxLv)
                local str = string.replace(ccClientText(10095), maxLv)
                self:SetWndButtonText(self.mUpLvBtn_2, str)
                CS.ShowObject(self.mUpLvBtn_2, true)
            end
            needGold, needExp, addLv = gModelHero:GetUpNumLvPayItem(id, lv, classId, grade)
        end

        local isShowRedPoint = haveGold >= needGold and haveExp >= needExp
        CS.ShowObject(self.mAttrBotBtnRedPoint, isShowRedPoint)
        CS.ShowObject(self.mUpLvBtnRedPoint, isShowRedPoint)
        self._upLv = addLv
        local needList = { needGold, needExp }
        for i, v in ipairs(itemRefIdList) do
            local num = needList[i]
            table.insert(self._needItemList, { refId = v, num = num })
            table.insert(needItemList, { itemId = v, itemNum = num, itemType = LItemTypeConst.TYPE_ITEM })
        end
        local str = string.replace(ccClientText(10063), addLv)
        self:SetWndButtonText(self.mUpLvBtn, str)
    elseif optType == UINewSagaInfo.STATUS_OPT_8 then
        showOptBtn = false
        showDesc = true
        self:SetWndText(self.mAttrPageDesc, ccClientText(10078))
    end
    CS.ShowObject(self.mUpLvBtn, showOptBtn)
    CS.ShowObject(self.mAttrPageDesc, showDesc)
    self:CreateUpLvNeedItem(needItemList)
end

function UINewSagaInfo:InitText()
    self:SetWndText(self:FindWndTrans(self.mReturnBotBtn, "UIText"), ccClientText(30205))
    self:SetTextTile(self.mNewCommentBtn, ccClientText(20104))
    self:SetWndText(self.mPreviewBtnName, ccClientText(20100))
    self:SetWndText(self.mStoryBtnName, ccClientText(21737))
    self:SetWndText(self.mSkinBtnName, ccClientText(20102))
    self:SetWndText(self.mShareBtnName, ccClientText(20103))
    self:SetWndText(self.mCommentBtnName, ccClientText(20104))
    self:SetWndText(self.mLockBtnName, ccClientText(20105))
    self:SetWndText(self.mRebirthBtnName, ccClientText(20106))
    self:SetWndText(self.mShareTwitterText, ccClientText(21180))
    self:SetWndText(self.mPolymorphicBtnName, ccClientText(20171))
    self:SetWndText(self.mPhotograph_Txt, ccClientText(20181))
    self:SetWndText(self.mMotherBtnText, ccClientText(41303))

    self:SetWndText(self.mHuaYuanBtnName, ccClientText(20216))
    -- self:SetTextTile(self.mCrystalShardBtn,ccClientText(34700))--晶石【G公共支持】删除伙伴晶石功能相关数据

    --self:SetWndText(self.mAttrBotBtnName,ccClientText(20107))
    --self:SetWndText(self.mStarBotBtnName,ccClientText(20108))
    --self:SetWndText(self.mSkillBotBtnName,ccClientText(20109))
    --self:SetWndText(self.mOutfitBotBtnName,ccClientText(20110))
    --self:SetWndText(self.mRuneBotBtnName,ccClientText(20111))
    --
    --self:SetWndText(self.mAttrBotBtnNoSelName,ccClientText(20107))
    --self:SetWndText(self.mStarBotBtnNoSelName,ccClientText(20108))
    --self:SetWndText(self.mSkillBotBtnNoSelName,ccClientText(20109))
    --self:SetWndText(self.mOutfitBotBtnNoSelName,ccClientText(20110))
    --self:SetWndText(self.mRuneBotBtnNoSelName,ccClientText(20111))

    for k, v in pairs(self._botBtnTransList) do
        self:SetWndText(v.textTrans, v.title)
        self:SetWndText(v.NoTextTrans, v.title)

        self:InitTextLineWithLanguage(v.textTrans, -50)
        self:InitTextLineWithLanguage(v.NoTextTrans, -50)
    end

    self:SetWndText(self.mTopLeftDesc, ccClientText(26635))
    self:InitTextLineWithLanguage(self.mTopLeftDesc, -30)
    local addSize = -2
    if gLGameLanguage:IsFrenchVersion() then
        addSize = -4
    end
    self:InitTextSizeWithLanguage(self.mTopLeftDesc, addSize)

    self:SetWndText(self.mLvLimitTxt, ccClientText(10023))
    self:SetWndText(self.mAtkBoldAddTxt, ccClientText(10024))
    self:SetWndText(self.mSkillPageDesc, ccClientText(20112))
    self:SetWndText(self.mRuneSkillName, ccClientText(20113))
    self:SetWndText(self.mDiv1NoWearRune, ccClientText(20114))
    self:SetWndText(self.mDiv2NoWearRune, ccClientText(20114))
    self:SetWndButtonText(self.mRuneShopBtn, ccClientText(13239))

    --self:SetWndButtonText(self.mRuneSkillPreBtn,ccClientText(13205))
    self:SetWndButtonText(self.mRuneSkillPreBtn, ccClientText(13278))
    self:SetWndButtonText(self.mRuneUpgradeBtn, ccClientText(13203))
    self:SetWndText(self.mKeZhiGuanXiTxt, ccClientText(10080))
    self:SetWndText(self.mRunePageDesc, ccClientText(10087))
    self:SetWndText(self.mShiftAwakenBtnText, ccClientText(20137))

    self:SetWndText(self.mActSpecialRaceAttrDesc, ccClientText(31206))
    self:SetWndText(self.mActSpecialRaceStarDesc, ccClientText(31232))
    self:SetWndText(self.mNoActSpecialAttrDescTxt, ccClientText(31230))
    self:SetWndText(self.mNoActSpecialStarDescTxt, ccClientText(31230))
    self:SetWndButtonText(self.mAttrPageGoToBtn, ccClientText(31231))
    self:SetWndButtonText(self.mStarPageGoToBtn, ccClientText(31231))

    self:SetWndText(self.mGolemBtnText, ccClientText(33265))
    self:SetWndText(self.mBattleRankBtnName, ccClientText(35002))

    self:SetWndText(self.mTxtClose, ccClientText(30205))

    self:SetWndButtonText(self.mPetViewBtn, ccClientText(43752))

    local isShowTwitterLink = gModelPlayer:CheckShowTwitterLink()
    CS.ShowObject(self.mBtnShareTwitter, isShowTwitterLink)

    self:SetWndText(self.mBadgeBtnText,ccClientText(47500))
end

function UINewSagaInfo:OnClickShiftUpStarEvent()
    self:SetAwakenPageShow(UINewSagaInfo.PAGE_COMMON)
end

function UINewSagaInfo:GetHeroInfoByType(gType, netWork)
    local heroAttrList, heroWearEquipList, heroWearRuneList, heroWearTalentList, heroWearOutfitList = gModelHero:GetHeroAttrAndEquipInfoById(self._id, not self._showMapping)
    local isEmptyAttrList = table.isempty(heroAttrList)
    local rep = isEmptyAttrList and self._autoAttr
    if self._autoAttr then
        self._autoAttr = false
    end
    if rep then
        gModelHero:OnHeroAttributeReq(self._id)
    else
        if gType == UINewSagaInfo.DATA_TYPE_ATTR then
            return heroAttrList
        elseif gType == UINewSagaInfo.DATA_TYPE_EQUIP then
            return heroWearEquipList
        elseif gType == UINewSagaInfo.DATA_TYPE_RUNEANDTALENT then
            return heroWearRuneList, heroWearTalentList
        end
    end
end

function UINewSagaInfo:CheckShowBattleRankBtn()
    local showBattleCamp = false
    local heroRefId = self._refId
    if heroRefId then
        local isHave = gModelRank:CheckIsHeroHaveRankCamp(heroRefId)
        if isHave then
            local funcId = 11903400
            --showBattleCamp = gModelFunctionOpen:CheckIsShow(funcId)
            local isOpen = gModelFunctionOpen:CheckIsOpened(funcId)
            if isOpen then
                showBattleCamp = true
            else
                local isShow = gModelFunctionOpen:CheckIsShow(funcId)
                if isShow then
                    showBattleCamp = true
                end

            end
        end

        return showBattleCamp
    end
end

function UINewSagaInfo:OnClickSkillSelect(treePointRefId)
    GF.OpenWnd("UISagaAwakenJNSelect", {
        heroId = self._id,
        pointRefId = treePointRefId,
    })
end

function UINewSagaInfo:CreateGradeList()
    local list = self:GetGradeList()
    local uiGradeList = self._uiGradeList
    if uiGradeList then
        uiGradeList:RefreshList(list)
    else
        uiGradeList = self:GetUIScroll("uiGradeList")
        self._uiGradeList = uiGradeList
        uiGradeList:Create(self.mGradeList, list, function(...)
            self:OnDrawGradeCell(...)
        end)
    end
end

function UINewSagaInfo:GetDefaultSelectTreePoint()
    local id = self._id
    local serverData = gModelHero:GetHeroServerDataById(id)
    if not serverData then
        return nil
    end

    local bigRefId
    local bigSort
    local isActivate
    for k, v in pairs(self._heroTreeInfoList) do
        isActivate = v.isActivate
        if ((not isActivate and v.canActivate) or isActivate) and v.canLvlUp then
            local refId = k
            local ref = gModelHero:GetHeroTreePointRef(refId)
            if not ref then
                printInfoNR("GameTable.CharacterTreePointRef[refId] is a nil, refId = " .. refId)
                break
            end

            local sort = ref.sort
            if not bigSort or sort > bigSort then
                --默认选最大id的节点
                bigRefId = refId
                bigSort = sort
            end
        end
    end

    if bigRefId then
        return bigRefId, bigSort
    end

    local treeInfo = serverData.treeInfo
    local points = treeInfo.points
    for k, v in ipairs(points) do
        local refId = v.pointRefId
        local ref = gModelHero:GetHeroTreePointRef(refId)
        if not ref then
            printInfoNR("GameTable.CharacterTreePointRef[refId] is a nil, refId = " .. refId)
            break
        end

        local sort = ref.sort
        if not bigSort or sort > bigSort then
            --默认选最大id的节点
            bigRefId = refId
            bigSort = sort
        end
    end

    if not bigRefId then
        local treeRefId = self._treeRefId
        local treeRef = gModelHero:GetHeroTreeRef(treeRefId)
        bigRefId = treeRef.initPoint
        bigSort = 1
    end

    return bigRefId, bigSort
end

function UINewSagaInfo:OnDragHeroSpineEnd(heroObj, beginPos, endPos)
    if self._curUIHeroObj == nil then
        return
    end
    if self._curUIHeroObj ~= heroObj then
        return
    end
    local beginX = beginPos.x
    local endX = endPos.x
    if beginX - endX > 20 then
        self:CutHero(1)
    elseif beginX - endX < -20 then
        self:CutHero(-1)
    end
end

function UINewSagaInfo:RebirthEvent()
    if self._sendMsg then
        return
    end
    local heroId = self._id
    local serData = gModelHero:GetHeroServerDataById(heroId)                    -- 服务器数据
    if not serData then
        return
    end
    local isCombat = serData.isCombat
    if isCombat == 1 then
        gModelFormation:OnHeroRemoveFormationReq(heroId, 4, LGameUI.UI_SORTLAYER_UIBOTTOM, true)
    else
        local isResonance = serData.isResonance
        if isResonance == 1 then
            GF.ShowMessage(ccClientText(14444))
        else
            local lock = serData.lock
            if lock == 1 then
                GF.ShowMessage(ccClientText(14445))
            else
                local lv = serData.lv
                local heroLevelRebornMin = GameTable.CharacterConfigRef["heroLevelRebornMin"]
                if lv < heroLevelRebornMin then
                    local str = string.replace(ccClientText(14446), heroLevelRebornMin)
                    GF.ShowMessage(str)
                else
                    if gModelSpiritHero:CheckIsSpiritHero(serData.refId) then
                        GF.ShowMessage(ccClientText(14444))
                        return
                    end
                    local showTips = false
                    local num = gModelHero:GetReborunNum()
                    if GameTable.CharacterConfigRef["heroLevelRebornNum"] ~= -1 then
                        if num >= GameTable.CharacterConfigRef["heroLevelRebornNum"] then
                            GF.ShowMessage(ccClientText(14429))
                        else
                            showTips = true
                        end
                    else
                        showTips = true
                    end
                    if showTips then
                        local wndId = 50904
                        if self._isOpenDay then
                            wndId = 50905
                        end
                        local func = function()
                            if not self:IsWndValid() then
                                return
                            end
                            gModelHero:OnHeroRebornReq(heroId)
                            self._sendMsg = true
                        end
                        local leftFunc = function()

                        end
                        local itemList = {}
                        table.insert(itemList, {
                            heroData = {
                                id = heroId,
                                refId = serData.refId,
                                star = serData.star,
                                level = 1,
                                skin = serData.skin,
                                isResonance = isResonance,
                            },
                            itype = LItemTypeConst.TYPE_HERO
                        })
                        local tempList = gModelHero:GetPayItemNum(serData)
                        for i, v in ipairs(tempList) do
                            if v.itype == 2 then
                                for index = 1, v.num do
                                    table.insert(itemList, { itemId = v.refId, count = v.num, itype = v.itype })
                                end
                            else
                                table.insert(itemList, { itemId = v.refId, count = v.num, itype = v.itype or 1, id = v.id })
                            end
                        end
                        local chongshengData = gModelHeroSpirit:GetChongshengData()
                        if chongshengData then
                            local rebornNeed = chongshengData.rebornNeed
                            local curData = rebornNeed[num + 1]
                            if not curData then
                                curData = rebornNeed[#rebornNeed]
                            end
                            local needRefId, needNum = curData.refId, curData.num
                            local name = gModelItem:GetNameByRefId(needRefId)
                            local para = needNum .. name
                            gModelGeneral:OpenUIOrdinTips({
                                refId = wndId,
                                itemList = itemList,
                                func = func,
                                leftFunc = leftFunc,
                                closeFunc = leftFunc,
                                para = { para },
                                consume = { needNum, needRefId },
                            })
                        end
                    end
                end
            end
        end
    end
end

function UINewSagaInfo:GetHeroPosById(heroId)
    for k, v in ipairs(self._cutHeroList) do
        if v.id == heroId then
            return k
        end
    end
    return 1
end

function UINewSagaInfo:OnHeroListChange()
    if self._isTryHero then
        local serverData = gModelHero:GetHeroServerDataById(self._id)
        if not serverData then
            --限时伙伴到期，关闭界面
            self:WndClose()
        end
    end
end

function UINewSagaInfo:RefreshEquipPage(netWork, click)
    local equipList = self:GetHeroInfoByType(UINewSagaInfo.DATA_TYPE_EQUIP, netWork) or {}
    local wearEquipNum = 0
    local wearRedPoints, strongerRedPoints = false, false
    local canExtensionRedpoints = false
    for i = 1, UINewSagaInfo.MAX_EQUIP_NUM do
        local instanceId = self["mEquipRoot" .. i]:GetInstanceID()
        local commonUI = self:FindWndTrans(self["mEquipRoot" .. i], "CommonUI")
        local equipNameTex = self:FindWndTrans(self["mEquipRoot" .. i], "EquipName")
        local root = self:FindWndTrans(commonUI, "Root")
        local redPoint = self:FindWndTrans(self["mEquipRoot" .. i], "redPoint")
        local wearRedPoint, strongerRedPoint = false, false
        local canExtensionRedpoint = false

        self:SetIconClickScale(commonUI, true)
        self:SetWndClick(commonUI, function()
            if self._isTryHero then
                GF.ShowMessage(ccClientText(10088))
                return
            end
            if equipList[i] then
                local refId = equipList[i]:GetRefId()
                local id = equipList[i]:GetId()
                local equipRef = gModelEquip:GetEquipRefByRefId(refId)
                local isSpecial = equipRef.quality >= 7
                --GF.OpenWndBottom("UIEqExtension",{tabIndex=3,refId=refId,id=id,equip=equipList[i]})

                gModelGeneral:OpenEquipInfoTip(equipList[i]:GetRefId(), self._id, 2, false, nil, nil, nil, nil, isSpecial, equipList[i])
                --gModelGeneral:OpenEquipInfoTip(equipList[i]:GetRefId(), self._id, 2, false)
                --gModelGeneral:OpenEquipInfoTip(equipList[i]:GetRefId(), self._id, 2, false)
            else
                GF.OpenWndUp("UIEqWear", { heroId = self._id, part = i, refId = nil })
            end
        end)

        if not self._commonUIList[instanceId] then
            self._commonUIList[instanceId] = CommonIcon:New()
            self._commonUIList[instanceId]:Create(root)
        end
        local t = equipList[i]
        self._commonUIList[instanceId]:SetEquipIcon(equipList[i] and equipList[i]:GetRefId() or nil, nil, i)
        self._commonUIList[instanceId]:DoApply()
        self._commonUIList[instanceId]._curIconCls._iconInst.transform.localScale = Vector3.New(0.87, 0.87, 0.87)

        if equipList[i] == nil and gModelEquip:GetWearRedPointByPart(i) then
            wearRedPoint = true
            wearRedPoints = true

            self._commonUIList[instanceId]:SetEquipExtension(0)
        end
        if equipList[i] ~= nil then
            wearEquipNum = wearEquipNum + 1
            --gModelEquip:GetEquipRefByRefId(equipList[i]:GetRefId())
            if gModelEquip:GetStrongerEquipByPart(equipList[i], i) ~= nil then
                strongerRedPoint = true
                strongerRedPoints = true
            end
        end

        if equipList[i] ~= nil then

            local quality = gModelEquip:GetEquipQualityByRefId(equipList[i]:GetRefId())
            if quality and quality >= 7 then
                self._commonUIList[instanceId]:SetEquipExtension(equipList[i]:GetLevel())
            else
                self._commonUIList[instanceId]:SetEquipExtension(0)
            end

            canExtensionRedpoint = gModelEquip:GetEquipCanExtensionRedpoint(equipList[i])

            if canExtensionRedpoint then
                canExtensionRedpoints = true
            end
        else
            self._commonUIList[instanceId]:SetEquipExtension(0)
        end

        CS.ShowObject(redPoint, wearRedPoint or strongerRedPoint or canExtensionRedpoint)
        CS.ShowObject(equipNameTex, equipList[i] ~= nil)
        self:SetWndText(equipNameTex, ccLngText(equipList[i] and gModelEquip:GetNameByRefId(equipList[i]:GetRefId()) or ""))
    end
    local changeList, refIdList, isChange = gModelEquip:GetAutoWearEquip(equipList)
    wearRedPoints = isChange
    CS.ShowObject(self.mAutoWearEquipRedPoint, wearRedPoints)
    CS.ShowObject(self.mOutfitBotBtnRedPoint, wearRedPoints or strongerRedPoints)
    local equipRedpoint = CS.FindTrans(self._tabList[UINewSagaInfo.BTN_TYPE_EQUIP], "redPoint")
    CS.ShowObject(equipRedpoint, wearRedPoints or strongerRedPoints or canExtensionRedpoints)

    --local isOneKeyUnload = wearEquipNum >= 1 and not strongerRedPoints and not wearRedPoints
    -- 只判断自身的红点
    local isOneKeyUnload = wearEquipNum >= 1 and not wearRedPoints
    local btnStr = isOneKeyUnload and ccClientText(11328) or ccClientText(11327)
    local btnImg = isOneKeyUnload and "public_btn_3_3" or "public_btn_3_2"
    self:SetWndButtonText(self.mAutoWearEquipBtn, btnStr)
    self:SetWndButtonImg(self.mAutoWearEquipBtn, btnImg)
    self._autoWearEquipBtnType = isOneKeyUnload and UINewSagaInfo.AUTO_BTN_UNLOAD or UINewSagaInfo.AUTO_BTN_WEAR
end

function UINewSagaInfo:GetCurCanUpCostItem()
    local refId, id = self._refId, self._id
    local serverData = gModelHero:GetHeroServerDataById(id)
    local heroRef = gModelHero:GetHeroRef(refId)                -- 英雄表
    local lv, grade = serverData.lv, serverData.grade
    local classType = heroRef.classType                -- 阶级数据
    local classId = gModelHero:ConvertToHeroGradeId(classType, grade)    -- 阶级Id
    local heroStarRef = gModelHero:GetStarRefById(id)    -- 星级表
    local maxLevel = heroStarRef.maxLevel            -- 等级上限
    local needGold, needExp, addLv = gModelHero:GetUpNumLvPayItem(id, lv, classId, grade, maxLevel, true)
    if addLv >= 3 then
        local UpLv = lv + addLv
        local tempStr = string.replace(ccClientText(10095), UpLv)
        self:SetWndButtonText(self.mUpLvBtn_2, tempStr)
        CS.ShowObject(self.mUpLvBtn_2, true)

        local data = {
            curLv = lv,
            upLv = UpLv,
            needGold = needGold,
            needExp = needExp,
            heroId = self._id,
            addLv = addLv,
            isOneClick = false,
        }

        self._curCanUpCostItem = data
    end

    --printInfoN2("UINewSagaInfo--needGold--needExp--addLv", needGold .. "--" .. needExp .. "--" .. addLv)
end

function UINewSagaInfo:SendThinkingData(key)
    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_DETAIL, key, self._refId, self._id)
end

function UINewSagaInfo:RefreshSpiritStarRaceDiv()
    local id = self._id
    if not id then
        return
    end
    local serData = gModelHero:GetHeroServerDataById(id)
    if not serData then
        return
    end
    local isLink = gModelSpiritHero:CheckSpiritHeroIsHaveLink(serData)
    if isLink then
        self:RefreshStarActLink()
    else
        self:RefreshStarNoActLink()
    end
    CS.ShowObject(self.mNoActSpecialRaceStarDiv, not isLink)
    CS.ShowObject(self.mActSpecialRaceStarDiv, isLink)
end

function UINewSagaInfo:InitData()
    self._refId = self:GetWndArg("refId")
    self._id = self:GetWndArg("id")
    --self._heroIndex = self:GetWndArg("index")
    self._career = self:GetWndArg("career")
    self._race = self:GetWndArg("race")

    self:RefreshCutInfo()

    self._sendMsg = false
    self._lockHero = false
    self._isFirstOpen = true
    self._autoAttr = true
    self._curOptIndex = 1                                        -- 当前操作按钮
    self._btnIndex = UINewSagaInfo.BTN_TYPE_ATTR
    self._needItemList = {}
    self._selectHeroList = {}
    self._upStarPageRedPointList = {}
    self._curOutfitList = {}
    self._heroUpStarLimit = gModelHeroSpirit:GetUpStarLimit()
    self._resonanceLevel = gModelResonance:GetResonanceLv()
    self._runeTransList = { self.mDiv1Rune, self.mDiv2Rune }
    self._runeRedPointList = { self.mDiv1RuneRedPoint, self.mDiv2RuneRedPoint }
    self._talentTransList = { self.mTianFu1, self.mTianFu2 }
    self._talentRedPointList = { self.mTianFu1RedPoint, self.mTianFu2RedPoint }
    self._isOpenDay = not gModelFunctionOpen:CheckServerOpen(GameTable.CharacterConfigRef["heroLevelRebornFree"], true) -- gLGameLogin:IsNew(GameTable.CharacterConfigRef["heroLevelRebornFree"])
    self._changePos = false
    self._showMoreBtn = true
    self._botBtnFunctionOpenList = {
        [UINewSagaInfo.BTN_TYPE_RUNE] = {
            functionId = 16100003,
            lockTrans = self:FindWndTrans(self.mRuneBotBtn, "LockImg"),
            IconTrans = self:FindWndTrans(self.mRuneBotBtn, "Icon")
        }
    }
    self._botBtnTransList = {
        [UINewSagaInfo.BTN_TYPE_ATTR] = {
            root = self.mAttrBotBtn,
            rootImg = self:FindWndTrans(self.mAttrBotBtn, "SelIcon"),
            textTrans = self.mAttrBotBtnName,
            NoTextTrans = self.mAttrBotBtnNoSelName,
            title = ccClientText(20107),
            index = UINewSagaInfo.BTN_TYPE_ATTR,
            page = self.mAttrPage,
            func = function()
                self:RefreshAttrPage()
                self:RefreshSkillPage()
            end,
        },
        [UINewSagaInfo.BTN_TYPE_STAR] = {
            root = self.mStarBotBtn,
            rootImg = self:FindWndTrans(self.mStarBotBtn, "SelIcon"),
            textTrans = self.mStarBotBtnName,
            NoTextTrans = self.mStarBotBtnNoSelName,
            title = ccClientText(20108),
            index = UINewSagaInfo.BTN_TYPE_STAR,
            page = self.mStarPage,
            func = function()
                self:RefreshStarPage()
            end,
        },
        [UINewSagaInfo.BTN_TYPE_SKILL] = {
            root = self.mSkillBotBtn,
            rootImg = self:FindWndTrans(self.mSkillBotBtn, "SelIcon"),
            textTrans = self.mSkillBotBtnName,
            NoTextTrans = self.mSkillBotBtnNoSelName,
            title = ccClientText(20109),
            index = UINewSagaInfo.BTN_TYPE_SKILL,
            page = self.mSkillPage,
            func = function()
                self:RefreshSkillPage()
            end,
        },
        -- [UINewSagaInfo.BTN_TYPE_OUTFIT] = {
        --     root = self.mOutfitBotBtn,
        --     rootImg = self:FindWndTrans(self.mOutfitBotBtn, "SelIcon"),
        --     textTrans = self.mOutfitBotBtnName,
        --     NoTextTrans = self.mOutfitBotBtnNoSelName,
        --     title = ccClientText(20110),
        --     index = UINewSagaInfo.BTN_TYPE_OUTFIT,
        --     page = self.mOutfitPage,
        --     func = function()
        --         self:RefreshOutfitPage(nil, true)
        --     end,
        -- },
        [UINewSagaInfo.BTN_TYPE_EQUIP] = {
            root = self.mOutfitBotBtn,
            rootImg = self:FindWndTrans(self.mOutfitBotBtn, "SelIcon"),
            textTrans = self.mOutfitBotBtnName,
            NoTextTrans = self.mOutfitBotBtnNoSelName,
            title = ccClientText(20110),
            index = UINewSagaInfo.BTN_TYPE_EQUIP,
            page = self.mEquipPage,
            func = function()
                self:RefreshEquipPage(nil, true)
            end,
        },
        [UINewSagaInfo.BTN_TYPE_PET] = {
            title = ccClientText(43700),
            index = UINewSagaInfo.BTN_TYPE_PET,
            page = self.mPetPage,
            func = function()
                self:OnRefreshPetPage()
            end,
        },
        [UINewSagaInfo.BTN_TYPE_RUNE] = {
            root = self.mRuneBotBtn,
            rootImg = self:FindWndTrans(self.mRuneBotBtn, "SelIcon"),
            textTrans = self.mRuneBotBtnName,
            NoTextTrans = self.mRuneBotBtnNoSelName,
            title = ccClientText(20111),
            index = UINewSagaInfo.BTN_TYPE_RUNE,
            page = self.mRunePage,
            func = function(click)
                self:RefreshRunePage(nil, click)
            end,
        },
    }
    self._outfitTransList = {
        self.mOutfitRoot1,
        self.mOutfitRoot2,
        self.mOutfitRoot3,
        self.mOutfitRoot4,
    }
    self._outfitActivityTransList = {
        self.mTypeActivity1,
        self.mTypeActivity2,
        self.mTypeActivity3,
        self.mTypeActivity4,
    }
    self._outfitActivityEffTransList = {
        self.mTypeActivityEff1,
        self.mTypeActivityEff2,
        self.mTypeActivityEff3,
        self.mTypeActivityEff4,
    }
    self._outfitMaskTransList = {
        self.mTypeMask1,
        self.mTypeMask2,
        self.mTypeMask3,
        self.mTypeMask4,
    }
    self._showTip = {
        [UINewSagaInfo.BTN_TYPE_ATTR] = true,
        [UINewSagaInfo.BTN_TYPE_STAR] = true,
        --[UINewSagaInfo.BTN_TYPE_OUTFIT] = true,
        [UINewSagaInfo.BTN_TYPE_RUNE] = true,
    }

    self._tryHeroPageDescList = {
        [UINewSagaInfo.BTN_TYPE_ATTR] = {
            descTrans = self.mAttrPageDesc,
            key = 10084,
        },
        [UINewSagaInfo.BTN_TYPE_STAR] = {
            descTransList = { self.mStarPageDesc, self.mAwakenPageDesc, },
            keyList = { 10083, 10085 },
        },
    }

    self._curAwakenShowType = UINewSagaInfo.PAGE_COMMON
    self._curSelectTreePointId = nil
    self._heroTreeInfoList = {}
    self._curSelectTreePointSkillId = nil
    self._awakenSelectHeroList = {}
    self._awakenUpLvPageRedPointList = {}

    self._isForeign = gLGameLanguage:IsForeignRegion()
    self._isForeignVersion = gLGameLanguage:IsForeignVersion()

    self:RefreshTryHeroState()
end

function UINewSagaInfo:OnClickAwakenEvent()
    local showAwaken = false
    if not gModelFunctionOpen:CheckIsOpened(10306001, true) then
        return
    end
    local id = self._id
    local serverData = gModelHero:GetHeroServerDataById(id)
    if serverData then
        local heroAwaken = gModelHero:GeConfigByKey("heroAwaken")
        local star = serverData.star
        showAwaken = star >= heroAwaken
    end
    if showAwaken then
        self._curSelectTreePointId = nil
        --self:SetAwakenPageShow(UINewSagaInfo.PAGE_AWAKEN)
        local para = {
            heroId = self._id,
            career = self._career,
            race = self._race,
        }
        GF.OpenWnd("UISagaTree", para)
    end
end

function UINewSagaInfo:RefreshTryHeroPageDescTimeFunc()
    local timeValue = self._heroEndTime - GetTimestamp()
    if timeValue < 0 then
        self:StopTryHeroPageDescTime()
        return
    end

    local timeStr = LUtil.FormatTimespanToMin2(timeValue)

    local btnIndex = self._btnIndex
    local textKey, pageDescTrans
    local data = self._tryHeroPageDescList[btnIndex]
    if not data then
        return
    end

    if btnIndex == UINewSagaInfo.BTN_TYPE_STAR then
        local starPageType = self._curAwakenShowType
        textKey = data.keyList[starPageType]
        pageDescTrans = data.descTransList[starPageType]
    else
        textKey = data.key
        pageDescTrans = data.descTrans
    end

    if textKey then
        timeStr = ccClientText(textKey, timeStr)
    end

    if pageDescTrans then
        self:SetWndText(pageDescTrans, timeStr)
    end
end

function UINewSagaInfo:OnDrawUpStarNeedItemCell(list, item, itemdata, itempos)
    local itype = itemdata.itype or LItemTypeConst.TYPE_HERO
    local key = itemdata.key
    local needRefId, needNum = itemdata.needRefId, itemdata.needNum
    local index = itemdata.index
    local instanceId = item:GetInstanceID()
    local selNum = 0
    local CommonUI = self:FindWndTrans(item, "CommonUI")
    local NumTxt = self:FindWndTrans(item, "NumTxt")
    local redPoint = self:FindWndTrans(item, "redPoint")

    if itempos == 2 then
        printInfoN2("--", "--")
    end
    if CommonUI then
        local commonUIList = self._commonUIList
        if not commonUIList then
            commonUIList = {}
            self._commonUIList = commonUIList
        end
        local baesClass = commonUIList[instanceId]
        if not baesClass then
            baesClass = CommonIcon:New(self)
            commonUIList[instanceId] = baesClass
            baesClass:Create(CS.FindTrans(CommonUI, "Root"))
        end
        if key == "item" then
            selNum = gModelItem:GetNumByRefId(needRefId)
            baesClass:SetCommonReward(itype, needRefId, needNum or 1)
            baesClass:ShowNeedNumStatus(true, true)
        else
            local selectHeroList = self._selectHeroList or {}
            local needStar = itemdata.needStar
            if key == "appoint" then
                local appointList = selectHeroList.appointList or {}
                local appList = appointList[index] or {}
                selNum = table.keysize(appList)
                baesClass:SetHeroDataSet({ id = needRefId, refId = needRefId, star = needStar, level = 1,hideTree = true })
            else
                local rangList = selectHeroList.rangList or {}
                local appList = rangList[index] or {}
                selNum = table.keysize(appList)
                baesClass:SetRaceData({ id = needRefId, refId = needRefId, star = needStar, race = needRefId, needNum = needNum, num = selNum,hideTree = true })
            end
            local showMask = selNum ~= needNum
            baesClass:SetShowMaskOnly(showMask)
            baesClass:SetNoShowLv(true)
        end
        baesClass:EnableShowNum(false)
        baesClass:DoApply()

        self:SetWndClick(CommonUI, function()
            if key == "item" then
                gModelGeneral:OpenGetWayWnd({ itemId = needRefId, srcWnd = self:GetWndName() })
            else
                local id = self._id
                local needStar = itemdata.needStar
                local tab = {}
                if key == "appoint" then
                    tab = { refId = needRefId, num = needNum, star = needStar, race = -1, selHeorId = id,
                            selHeroList = self._selectHeroList.appointList[index],
                            func = function(appointList)
                                if not self:IsWndValid() then
                                    return
                                end
                                local _selNum = table.keysize(appointList)
                                if not table.isempty(appointList) then
                                    --[[								local oldData = self._selectHeroList.appointList[index] or {}
                                                                   for _k,_v in pairs(oldData) do
                                                                       local b = gModelHero:IsHeroIdSel(_k)
                                                                       if b then
                                                                           gModelHero:SetSelHeroId(_k)
                                                                       end
                                                                   end]]
                                    local tempList = {}
                                    self._selectHeroList.appointList[index] = tempList
                                    for _k, _v in pairs(appointList) do
                                        --gModelHero:SetSelHeroId(_k)
                                        tempList[_v] = _v
                                    end
                                else
                                    self._selectHeroList.appointList[index] = appointList
                                end
                                if NumTxt then
                                    local colorStr = self:GetColorStr(needRefId, needNum, itype, _selNum)
                                    self:SetWndText(NumTxt, colorStr)
                                end
                                baesClass:ShowMaskOnly(_selNum ~= needNum)
                                if redPoint then
                                    local showRed = _selNum < needNum
                                    if showRed then
                                        local dataList = gModelHero:FilterHero(needRefId, needStar, nil, id, {})
                                        local tempLen = table.keysize(dataList)
                                        local tempNum = needNum - _selNum
                                        showRed = tempLen >= tempNum
                                    end
                                    CS.ShowObject(redPoint, showRed)
                                end
                            end }
                elseif key == "range" then
                    --应该是只有  1 和 2 的情况
                    local otherIndex = index == 1 and 2 or 1

                    tab = { refId = needRefId, num = needNum, star = needStar, race = needRefId,
                            selHeorId = id, selHeroList = self._selectHeroList.rangList[index], selItemList = table.clone(self._selectHeroList.rangItemList[index]),
                            selfItemOtherList = table.clone(self._selectHeroList.rangItemList[otherIndex]),
                            func = function(rangList, rangItemList)
                                if not self:IsWndValid() then
                                    return
                                end
                                self._selectHeroList.rangItemList[index] = {}
                                local _selNum = table.keysize(rangList)
                                for k, v in pairs(rangItemList) do
                                    if v > 0 then
                                        self._selectHeroList.rangItemList[index][k] = v
                                    else
                                        self._selectHeroList.rangItemList[index][k] = nil
                                    end
                                    _selNum = _selNum + v
                                end
                                if not table.isempty(rangList) then
                                    --[[								   local oldData = self._selectHeroList.rangList[index] or {}
                                                                      for _k,_v in pairs(oldData) do
                                                                          local b = gModelHero:IsHeroIdSel(_k)
                                                                          if b then
                                                                              gModelHero:SetSelHeroId(_k)
                                                                          end
                                                                      end]]
                                    local tempList = {}
                                    self._selectHeroList.rangList[index] = tempList
                                    for _k, _v in pairs(rangList) do
                                        --gModelHero:SetSelHeroId(_k)
                                        tempList[_v] = _v
                                    end
                                else
                                    self._selectHeroList.rangList[index] = rangList
                                end
                                if NumTxt then
                                    local colorStr = self:GetColorStr(needRefId, needNum, itype, _selNum)
                                    self:SetWndText(NumTxt, colorStr)
                                end
                                baesClass:ShowMaskOnly(_selNum ~= needNum)
                                for idxNum, idxData in ipairs(self._appSelHeroList) do
                                    if not self._selectHeroList then
                                        break
                                    end
                                    local appointList = self._selectHeroList.appointList[idxNum] or {}
                                    local appRedPointTrans = self._upStarPageRedPointList[idxNum]
                                    local curSelNum, haveSelNum = 0, table.keysize(idxData)
                                    local appData = self._appHeroList[idxNum]
                                    local appNeedNum = appData.needNum
                                    for idxKey, idxVal in pairs(idxData) do
                                        if rangList[idxKey] then
                                            curSelNum = curSelNum + 1
                                        end
                                    end
                                    local isShow = curSelNum < haveSelNum
                                    local selListLen = table.keysize(appointList)
                                    if selListLen ~= 0 then
                                        isShow = selListLen < appNeedNum
                                        if isShow then
                                            local tempNeedNum = appNeedNum - selListLen
                                            local tempFilterList = gModelHero:FilterHero(appData.needRefId, appData.needStar, nil, id, {})
                                            local tempFileterNum = table.keysize(tempFilterList)
                                            isShow = tempFileterNum >= tempNeedNum
                                        end
                                    else
                                        local tempFilterList = gModelHero:FilterHero(appData.needRefId, appData.needStar, nil, id, {})
                                        local tempFileterNum = table.keysize(tempFilterList)
                                        isShow = tempFileterNum >= appNeedNum
                                    end
                                    CS.ShowObject(appRedPointTrans, isShow)
                                end
                                if redPoint then
                                    local redShow = _selNum ~= needNum
                                    if redShow then
                                        local dataList = gModelHero:FilterHero(needRefId, needStar, needRefId, id, {})
                                        local len = table.keysize(dataList)
                                        local tempNum = needNum - _selNum
                                        redShow = len >= tempNum
                                    end
                                    CS.ShowObject(redPoint, redShow)
                                end
                            end
                    }
                end
                GF.OpenWnd("UISagaSelect", tab)
            end
        end)
    end
    if NumTxt then
        local colorStr = self:GetColorStr(needRefId, needNum, itype, selNum)
        self:SetWndText(NumTxt, colorStr)
    end
    if redPoint then
        local canCompound = itemdata.canCompound
        if canCompound ~= nil then
            if key == "appoint" then
                table.insert(self._upStarPageRedPointList, redPoint)
            end
            if key == "appoint" then
                local show = selNum < needNum
                if show then
                    local data = self._appSelHeroList[index] or {}
                    local dataNum = table.keysize(data)
                    show = dataNum >= needNum
                end
                CS.ShowObject(redPoint, show)
            else
                CS.ShowObject(redPoint, canCompound)
            end
        else
            CS.ShowObject(redPoint, false)
        end
    end
end

function UINewSagaInfo:ShowPrepositionPointEff(isShow, treePointRefId)
    local heroTreePointInfo = self._heroTreeInfoList[treePointRefId]
    if not heroTreePointInfo then
        return
    end

    local isShowEff = isShow
    if isShowEff then
        isShowEff = false
        if not heroTreePointInfo.isActivate then
            if not heroTreePointInfo.canActivate and heroTreePointInfo.needConType == ModelHero.TREE_CON_TYPE_LVL then
                isShowEff = true
            end
        end
    end

    local ref = gModelHero:GetHeroTreePointRef(treePointRefId)
    if not ref then
        printInfoNR("GameTable.CharacterTreePointRef[refId] is a nil, refId = " .. treePointRefId)
        return
    end

    local front = ref.front
    if not front or front <= 0 then
        return
    end

    local treePointTransList = self._awakenTreeTransList[self._treePbName]
    local frontPointInfo = treePointTransList[front]
    if not frontPointInfo then
        return
    end

    local frontHeroTreePointInfo = self._heroTreeInfoList[front]
    if not frontHeroTreePointInfo then
        return
    end

    local pointTrans = frontPointInfo.pointTrans
    local pointType = frontHeroTreePointInfo.pointType
    local effName = pointType == ModelHero.TREE_POINT_TYPE_ATTR and "ui_yingxiongjuexing_qianzhi" or "ui_yingxiongjuexing_qianzhi_2"
    self:SetAwakenPointEffShow(isShowEff, effName, pointTrans)
end

function UINewSagaInfo:RefreshSpiritHeroAttrDiv()
    local id = self._id
    if not id then
        return
    end
    local serData = gModelHero:GetHeroServerDataById(id)
    if not serData then
        return
    end
    local isResonance = serData.isResonance
    local lv = serData.lv
    local lvStr
    local starRef = gModelHero:GetStarRefById(id) --  gModelHero:GetHeroStarRefByHeroRefIdAndStar(serData.refId, serData.star)
    if self._isTryHero then
        local maxLv = starRef and starRef.maxLevel or 0            -- 等级上限
        if lv > maxLv then
            maxLv = gModelResonance:GetResonanceMaxLv()
        end
        --lv = string.format("<color=#%s>%s</color>/%s", LUtil.GetResonanceColor(isResonance), lv, maxLv)
        lv = string.format("<color=#%s>%s</color>/%s", "ffd265", lv, maxLv)
        lvStr = "Lv：" .. lv
    elseif isResonance == 1 then
        local maxLv = gModelResonance:GetResonanceMaxLv()
        --lv = string.format("<color=#%s>%s</color>/%s", LUtil.GetResonanceColor(isResonance), lv, maxLv)
        lv = string.format("<color=#%s>%s</color>/%s", "ffd265", lv, maxLv)
        lvStr = "Lv：" .. lv
    else
        local maxLv = starRef and starRef.maxLevel or 0            -- 等级上限  #ffd265
        --local _lv = string.format("<color=#%s>%s</color>/%s", LUtil.GetResonanceColor(isResonance), lv, maxLv)
        lv = string.format("<color=#%s>%s</color>/%s", "ffd265", lv, maxLv)
        --lvStr = string.replace(ccClientText(10011), lv)
        lvStr = "Lv：" .. lv
    end
    self:SetWndText(self.mLvTxt, lvStr)

    local isLink = gModelSpiritHero:CheckSpiritHeroIsHaveLink(serData)
    if isLink then
        self:RefreshAttrActLink()
    else
        self:RefreshAttrNoActLink()
    end
    CS.ShowObject(self.mNoActSpecialRaceAttrDiv, not isLink)
    CS.ShowObject(self.mActSpecialRaceAttrDiv, isLink)
end

function UINewSagaInfo:GetHeroAwakenIsOpen()
    --- 先做功能开启判断
    local isOpen = gModelFunctionOpen:CheckIsOpened(10306001)
    if not isOpen then
        return false
    end

    local id = self._id
    local serverData = gModelHero:GetHeroServerDataById(id)
    local heroAwaken = gModelHero:GeConfigByKey("heroAwaken")
    local maxStar = gModelHero:GetMaxStarByRefId(self._refId)
    local curStar = serverData and serverData.star or maxStar
    local status = curStar >= heroAwaken
    return status
end

--重连
function UINewSagaInfo:OnTcpReconnect()
    gModelHero:OnHeroAttributeReq(self._id)
end

-- function UINewSagaInfo:RefreshSorceryCard()
-- 	local mappingData = self._mappingData
-- 	local sourceHeroId = mappingData and mappingData.sourceHeroId or nil
-- 	local showMappingGroup = (sourceHeroId and sourceHeroId~=0) and true or false
-- 	if(showMappingGroup)then
-- 		self:SetCardMappingDisplay(sourceHeroId)
-- 	end
-- 	local bool = gModelFunctionOpen:CheckIsOpened(28000000)
-- 	CS.ShowObject(self.mBtnKCard,bool or showMappingGroup)
-- 	CS.ShowObject(self.mCardAddIcon,not showMappingGroup)
-- 	CS.ShowObject(self.mCardMappingGroup,showMappingGroup)
-- 	if not bool then return end
-- 	local _serverData = self._serverData
-- 	if not _serverData then return end
-- 	local heroRef  = gModelHero:GetHeroRef(_serverData.refId)
-- 	local showSlotQuality = tonumber(gModelSorceryCard:GetSorceryCardConfigRefByKey("showSlotQuality"))
-- 	local bool = heroRef.quality >= showSlotQuality
-- 	CS.ShowObject(self.mBtnKCard,bool or showMappingGroup)
-- 	if not bool then return end
-- 	local star = _serverData.star
-- 	local unlockHeroStar = tonumber(gModelSorceryCard:GetSorceryCardConfigRefByKey("unlockHeroStar"))
-- 	local isShowSorceryCard = star >= unlockHeroStar
-- 	CS.ShowObject(self.mBtnKCard,isShowSorceryCard or showMappingGroup)
-- 	if not isShowSorceryCard then return end
-- 	CS.ShowObject(self.mMaskKCard,false)
-- 	local id = self._id
-- 	if isShowSorceryCard then
-- 		local heroKeys = gModelSorceryCard:GetHeroKeys()
-- 		local wearId = heroKeys[id]
-- 		CS.ShowObject(self.mCardFrame,wearId and wearId > 0 and  not showMappingGroup)
-- 		if wearId and wearId > 0 then
-- 			local cardRef = gModelSorceryCard:GetSorceryCardRefByRefId(wearId)
-- 			local themeRef = gModelSorceryCard:GetSorceryCardThemeRefByRefId(cardRef.theme)
-- 			self:SetWndEasyImage(self.mCardFrame,themeRef.cardFrame,nil,true)
-- 			self:SetWndEasyImage(self.mCardIcon,cardRef.icon,nil,true)
-- 		end
-- 	else
-- 		CS.ShowObject(self.mCardFrame,false)
-- 	end
-- end

function UINewSagaInfo:RefreshSorceryCard()
    -- local mappingData = self._mappingData
    -- local sourceHeroId = mappingData and mappingData.sourceHeroId or nil
    -- local showMappingGroup = (sourceHeroId and sourceHeroId~=0) and true or false
    -- if(showMappingGroup)then
    -- 	self:SetCardMappingDisplay(sourceHeroId)
    -- end
    local bool = gModelFunctionOpen:CheckIsOpened(28000000)
    CS.ShowObject(self.mBtnKCard, bool)
    if not bool then
        return
    end
    self:SetWndEasyImage(self.mCardFrame, "card_di_1", nil, true)
    local _serverData = self._serverData
    if not _serverData then
        return
    end
    local heroRef = gModelHero:GetHeroRef(_serverData.refId)
    local showSlotQuality = tonumber(gModelSorceryCard:GetSorceryCardConfigRefByKey("showSlotQuality"))
    local bool = heroRef.quality >= showSlotQuality
    CS.ShowObject(self.mBtnKCard, bool)
    if not bool then
        return
    end
    local star = _serverData.star
    local unlockHeroStar = tonumber(gModelSorceryCard:GetSorceryCardConfigRefByKey("unlockHeroStar"))
    local isShowSorceryCard = star >= unlockHeroStar
    CS.ShowObject(self.mBtnKCard, isShowSorceryCard)
    if not isShowSorceryCard then
        return
    end
    CS.ShowObject(self.mMaskKCard, false)
    local id = self._id
    if isShowSorceryCard then
        local heroKeys = gModelSorceryCard:GetHeroKeys()
        local wearId = heroKeys[id]
        -- CS.ShowObject(self.mCardFrame,wearId and wearId > 0)
        CS.ShowObject(self.mCardIcon, wearId and wearId > 0)
        CS.ShowObject(self.mCardAddIcon, not (wearId and wearId > 0))
        CS.ShowObject(self.mMaskKCard, not (wearId and wearId > 0))
        if wearId and wearId > 0 then
            local cardRef = gModelSorceryCard:GetSorceryCardRefByRefId(wearId)
            -- local themeRef = gModelSorceryCard:GetSorceryCardThemeRefByRefId(cardRef.theme)
            self:SetWndEasyImage(self.mCardFrame, cardRef.frameRes, nil, true)
            self:SetWndEasyImage(self.mCardIcon, cardRef.icon, nil, true)
        end
    else
        -- CS.ShowObject(self.mCardFrame,false)
    end
end

function UINewSagaInfo:ChangeAwakenIcon(lv)
    local iconPath = gModelHero:GetAwakenIconPathByLvl(lv, true)
    self:SetWndEasyImage(self.mShiftAwakenBtn, iconPath, function()
        CS.ShowObject(self.mShiftAwakenBtn, true)
    end)
end

function UINewSagaInfo:UpdatePetTabbarState()
    local item = self._tabList[UINewSagaInfo.BTN_TYPE_PET]
    if not item then
        return false
    end
    local heroSerData = gModelHero:GetHeroServerDataById(self._id)
    local linkStar = GameTable.MagicPetConfigRef.petHeroStar
    local isOpen = gModelFunctionOpen:CheckIsOpened(21006000)
    local isShowPet = isOpen and gModelHero:GetHeroInitQualityByRefId(heroSerData.refId) >= 6
    CS.ShowObject(item, isShowPet)
    self:SetWndTabStatus(item, heroSerData.star >= linkStar and 1 or 2)
    return heroSerData.star >= linkStar and isOpen
end

function UINewSagaInfo:CreateSpine(prefabName, star, effId)
    if not prefabName then
        return
    end
    local uiHeroObjList = self._uiHeroObjList
    if not uiHeroObjList then
        uiHeroObjList = {}
        self._uiHeroObjList = uiHeroObjList
    end
    if self._uiSkillCtrl then
        self._uiSkillCtrl:Destroy()
        self._uiSkillCtrl = nil
    end
    local newUIHeroObj = uiHeroObjList[prefabName]

    local oldUIHeroObj = self._curUIHeroObj
    if oldUIHeroObj and newUIHeroObj ~= oldUIHeroObj then
        oldUIHeroObj:ShowHero(false)
    end

    if not newUIHeroObj then
        newUIHeroObj = LUIHeroObject:New(self)
        newUIHeroObj:SetRectMatch(true)
        uiHeroObjList[prefabName] = newUIHeroObj
        self._curUIHeroObj = newUIHeroObj
        newUIHeroObj:Create(self.mHeroSpinePos, prefabName, prefabName)
        newUIHeroObj:SetScale(1)
        --newUIHeroObj:SetClickFunc(function(...)
        --    self:OnClickHeroSpine(...)
        --end)
        newUIHeroObj:SetDragFunc(function(...)
            self:OnDragHeroSpineEnd(...)
        end)
        newUIHeroObj:SetHeroData(nil, self._refId, star, effId, true)
        newUIHeroObj:ShowHero(true)
        newUIHeroObj:StartLoad()

        self._uiHeroCacheCnt = self._uiHeroCacheCnt + 1
        if self._uiHeroCacheCnt > 4 then
            self:RemoveTheOlderCacheHeroObj(newUIHeroObj)
        end
    else
        self._curUIHeroObj = newUIHeroObj
        newUIHeroObj:SetHeroData(nil, self._refId, star, effId, true)
        newUIHeroObj:ShowHero(true)
    end
    self:StartHeroObjRunTimer()
end

function UINewSagaInfo:StartHeroObjRunTimer()
    if self:IsTimerExist(self._loopHeroObjTimerKey) then
        return
    end
    self:TimerStart(self._loopHeroObjTimerKey, 0, false, -1)
end

function UINewSagaInfo:RemoveTheOlderCacheHeroObj(exceptHero)
    local olderObj = nil
    local minTime = 0
    local olderKey = nil
    for k, v in pairs(self._uiHeroObjList) do
        if not v:IsShow() and v ~= exceptHero and (not olderObj or v:GetLastHideTime() < minTime) then
            olderObj = v
            minTime = v:GetLastHideTime()
            olderKey = k
        end
    end
    if olderObj then
        self._uiHeroObjList[olderKey] = nil
        self._uiHeroCacheCnt = self._uiHeroCacheCnt - 1
        olderObj:Destroy()
    end
end

function UINewSagaInfo:OnDrawRuneSkillCell(list, item, itemdata, itempos)
    local skillData = gModelRune:GetSkillInfoByRefId(itemdata)
    if not skillData then
        return
    end
    local skill = tonumber(skillData.SkillId)
    local Root = self:FindWndTrans(item, "CommonUI/Root")
    if Root then
        local SkillIconTrans = self:FindWndTrans(Root, "SkillIcon")
        local baseClass = SkillIcon:New(self)
        baseClass:Create(SkillIconTrans, skill, function()
            --[[            local lv = skillData.skillLevel
                        local other = {lv = lv}
                        GF.OpenWndTop("UIJNInfo",{skillId = skill,other = other})]]
            local skillType = skillData.skillType
            local refId = skillData.refId
            gModelRune:OpenNewRuneSkillWnd(refId, skillType)
        end)
    end
    local skillRef = gModelHero:GetSkillByStarId(skill)
    local Name = self:FindWndTrans(item, "Name")
    if Name then
        local skillName = skillRef and ccLngText(skillRef.name) or ""
        self:SetWndText(Name, skillName)
        self:InitTextModeWithLanguage(Name)

        local quality = skillData.quality
        local qualityRef = GameTable.RarityRef[quality + 2]
        self:SetXUITextTransColor(Name, qualityRef.nameColor)

    end
end

function UINewSagaInfo:OnClickAwakenPandectEvent()
    local heroId = self._id
    GF.OpenWnd("UISagaAwakenAttr", {
        heroId = heroId,
    })
end

function UINewSagaInfo:OnDrawStarPageStarCell(list, item, itemdata, itempos)
    self:SetWndEasyImage(item, itemdata.img)
end

function UINewSagaInfo:UpOpt(func)
    local gotoUp, lackRefId = true
    for i, v in ipairs(self._needItemList) do
        local tRefId = v.refId
        local haveNum = gModelItem:GetNumByRefId(tRefId)
        if haveNum < v.num then
            gotoUp = false
            lackRefId = tRefId
            break
        end
    end
    if gotoUp then
        if func then
            func()
        end
    else
        gModelGeneral:OpenGetWayWnd({ itemId = lackRefId })
    end
end

function UINewSagaInfo:GetCurCanUp100CostItem(gold, exp, item, maxLv)
    local id = self._id
    local serverData = gModelHero:GetHeroServerDataById(id)
    local lv = serverData.lv
    local addLv = maxLv - lv
    self._curCanUpCostItem = {
        curLv = lv,
        upLv = maxLv,
        needGold = gold,
        needExp = exp,
        needitem = item,
        heroId = id,
        addLv = addLv,
        isOneClick = true,
    }
end

function UINewSagaInfo:RefreshSpiritHeroActPageTime()
    local transRoot
    if self._btnIndex == UINewSagaInfo.BTN_TYPE_ATTR then
        transRoot = self.mActSpecialRaceAttrTimeTxt
    elseif self._btnIndex == UINewSagaInfo.BTN_TYPE_STAR then
        transRoot = self.mActSpecialRaceStarTimeTxt
    end
    local timeValue = self._heroEndTime - GetTimestamp()
    local isEndTime = timeValue < 0
    CS.ShowObject(transRoot, not isEndTime)
    if isEndTime then
        self:TimerStop(self._trySpiritHeroActTimeKey)
        self:SetWndText(transRoot, "")
        return
    end
    local timeStr = LUtil.FormatTimespanToMin2(timeValue)
    timeStr = string.replace(ccClientText(31207), timeStr)
    self:SetWndText(transRoot, timeStr)
end

function UINewSagaInfo:RefreshPage()
    if self._btnIndex == UINewSagaInfo.BTN_TYPE_ATTR then
        self:RefreshAttrPage(true)
        self:RefreshSkillPage()
    elseif self._btnIndex == UINewSagaInfo.BTN_TYPE_EQUIP then
        self:RefreshEquipPage(true)
    elseif self._btnIndex == UINewSagaInfo.BTN_TYPE_RUNE then
        self:RefreshRunePage(true)
    elseif self._btnIndex == UINewSagaInfo.BTN_TYPE_STAR then
        self:RefreshStarPage()
    end

    self:RefreshAwakenPage()
    self:CheckRedPoint(true)
end

function UINewSagaInfo:StopTryHeroPageDescTime()
    self:TimerStop(self._tryHeroPageDescTimeKey)
end

function UINewSagaInfo:CreateAttrList(netWork)
    local list = self:GetAttrList(netWork)
    local uiAttrList = self._uiAttrList
    if uiAttrList then
        uiAttrList:RefreshList(list)
    else
        uiAttrList = self:GetUIScroll("uiAttrList")
        self._uiAttrList = uiAttrList
        uiAttrList:Create(self.mAttrList, list, function(...)
            self:OnDrawAttrCell(...)
        end)
    end
end

function UINewSagaInfo:OnClickUpLvEvent()
    if self._sendMsg then
        return
    end
    local optType = self._optType
    local id = self._id
    if optType == 3 then
        --self:ChangeBotBtn(UINewSagaInfo.BTN_TYPE_STAR)
        self:OnClickTab(UINewSagaInfo.BTN_TYPE_STAR)
    elseif optType == 4 then
        local func = function()
            GF.OpenWnd("UIUpde", { id = id, func = function()
                self._sendMsg = true
            end })
        end
        self:UpOpt(func)
    elseif optType == 5 then
        local func = function()
            self._sendMsg = true
            gModelHero:OnHeroUpLevelReq(id, self._upLv)
        end
        self:UpOpt(func)
    end
end

function UINewSagaInfo:CreateStarList(star)
    local list = {}
    local img, showNum = gModelHero:GetHeroStarImg(star)
    for i = 1, showNum do
        table.insert(list, {
            show = true,
            img = img
        })
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

--endregion --------------------------------------------------------------------------------------

--region 构建tab部分 --------------------------------------------------------------------------------
function UINewSagaInfo:InitTabData()
    self._tabData = {
        --- 爱宠
        [1] = { onIcon = "pet_btn_icon_2", offIcon = "pet_btn_icon_2", tabBtnInfo = self._botBtnTransList[UINewSagaInfo.BTN_TYPE_PET] },
        --- 刻印
        [2] = { onIcon = "hero_btn_5", offIcon = "hero_btn_5", tabBtnInfo = self._botBtnTransList[UINewSagaInfo.BTN_TYPE_RUNE] },
        --- 装备
        [3] = { onIcon = "hero_btn_4", offIcon = "hero_btn_4", tabBtnInfo = self._botBtnTransList[UINewSagaInfo.BTN_TYPE_EQUIP] },
        --- 技能
        --[3] = { onIcon = "hero_btn_3", offIcon = "hero_btn_3", tabBtnInfo = self._botBtnTransList[UINewSagaInfo.BTN_TYPE_SKILL] },
        --- 升星
        [4] = { onIcon = "hero_btn_2", offIcon = "hero_btn_2", tabBtnInfo = self._botBtnTransList[UINewSagaInfo.BTN_TYPE_STAR] },
        --- 升级
        [5] = { onIcon = "hero_btn_1", offIcon = "hero_btn_1", tabBtnInfo = self._botBtnTransList[UINewSagaInfo.BTN_TYPE_ATTR] },
    }
    self._tabList = {}
    self._tabIndex = UINewSagaInfo.BTN_TYPE_ATTR
end

--设置英雄的显隐
function UINewSagaInfo:SetSkinBtnState()
    local effRef = self:GetHeroEffectRef()

    local showSkin = gModelHeroExtra:CheckIsOpenSkin()
    if showSkin then
        local skinType = effRef.skinType
        showSkin = skinType and skinType > 0
    end

    CS.ShowObject(self.mSkinBtn, showSkin)
end

---- 魔偶
function UINewSagaInfo:GetHeroGolemIsOpen()
    local status = false
    local id = self._id
    local serverData = id and gModelHero:GetHeroServerDataById(id)
    if serverData then
        status = gModelGolem:CheckHeroIsShowEntranceByHeroServerData(serverData)
    end
    return status
end

function UINewSagaInfo:CreateUpStarNeedItemList(itemData)
    self._upStarPageRedPointList = {}
    self._appHeroList = {}
    local list = {}
    for i, v in ipairs(itemData) do
        for key, val in pairs(v) do
            for idx, data in ipairs(val) do
                data.key = key
                if key == "appoint" then
                    table.insert(self._appHeroList, data)
                end
                data.index = idx
                table.insert(list, data)
            end
        end
    end
    local uiUpStarNeedItemList = self._uiUpStarNeedItemList
    if uiUpStarNeedItemList then
        uiUpStarNeedItemList:RefreshList(list)
    else
        uiUpStarNeedItemList = self:GetUIScroll("uiUpStarNeedItemList")
        self._uiUpStarNeedItemList = uiUpStarNeedItemList
        uiUpStarNeedItemList:Create(self.mUpStarNeedItemList, list, function(...)
            self:OnDrawUpStarNeedItemCell(...)
        end)
    end
end

function UINewSagaInfo:UpdateInteractBtnRed()
    local heroRefId = gModelHero:GetHeroEffectRefById(self._id).heroType
    local effectList = gModelHero:GetHeroEffectListByRefId(heroRefId) or {}
    local redImg = self.mMotherRedPoint
    for i, v in pairs(effectList) do
        local show = gModelHero:GetFavorabilityInteractRed(v.refId, true) or gModelHero:GetFavorabilityInteractRed(v.refId)
        if show then
            CS.ShowObject(redImg, show)
            return
        end
    end
    CS.ShowObject(redImg, false)
end

function UINewSagaInfo:InitNotRefreshWnd()
    local wndList = {
        ["UIReRecastNew"] = true,
        ["UIGolemMain"] = true,
    }
    local isHave = false
    for k, v in pairs(wndList) do
        if isHave then
            break
        end
        local wndInst = GF.FindFirstWndByName(k)
        isHave = wndInst ~= nil
    end
    if isHave then
        self._refreshView = true
    end
    return isHave
end

function UINewSagaInfo:CreateRuneAndTalent(netWork, click)
    local showRedPoint = false
    local heroServerData = gModelHero:GetHeroServerDataById(self._id)
    if not heroServerData then
        CS.ShowObject(self.mRuneBotBtnRedPoint, showRedPoint)
        return
    end

    local runeRefIdList = { 1001, 1002 }
    local runeTransList = self._runeTransList
    local runeRedPointList = self._runeRedPointList
    local runeSkillTransList = { self.mDiv1RuneSkillList, self.mDiv2RuneSkillList }
    local runeNoSkillTxtTransList = { self.mDiv1NoWearRune, self.mDiv2NoWearRune }
    local runeList, talentList = self:GetHeroInfoByType(UINewSagaInfo.DATA_TYPE_RUNEANDTALENT, netWork)
    runeList = runeList or {}
    for i = 1, UINewSagaInfo.MAX_RUNE_NUM do
        local runeRefId = runeRefIdList[i]
        local isLock = true
        local runePosRef = GameTable.MagicRunePosRef[runeRefId]
        local unlock = runePosRef.unlock
        local unlockTxt = ccLngText(runePosRef.text)
        unlock = string.split(unlock, ",")

        local msgTxt
        local unlockTag = true
        for k, unlockInfo in ipairs(unlock) do
            local tempUnlock = string.split(unlockInfo, "=")
            unlockTag = unlockTag and self:CheckIsUnLockPos(tempUnlock[1], tempUnlock[2], heroServerData)

            local selectType = tonumber(tempUnlock[1])
            --拼接提示信息
            if k == 1 then
                msgTxt = string.replace(ccClientText(UINewSagaInfo.ShowText[selectType]), tempUnlock[2])
            else
                msgTxt = msgTxt .. ccClientText(20178) .. string.replace(ccClientText(UINewSagaInfo.ShowText[selectType]), tempUnlock[2])
            end
        end

        isLock = isLock and not unlockTag
        msgTxt = msgTxt .. ccClientText(20176)
        --printInfoN2("cjh------------UINewSagaInfo--", "修改 unlock  条件配置" .. msgTxt)
        local isWear = false
        local trans = runeTransList[i]
        local runeData = runeList[i]
        local redPointTrans = runeRedPointList[i]
        local serverData = {}
        if runeData then
            isWear = true
            serverData = runeData:GetServerData()
            runeData = gModelRune:GetRuneDataById(serverData.id)
            serverData = gModelRune:GetServerDataById(serverData.id)
        end
        local serId = serverData.id or i
        local showRuneRedPoint = false
        if not isLock then
            if not serverData.id then
                local noWearNum = gModelRune:GetNoWearRuneNum()
                showRuneRedPoint = noWearNum > 0
            end
        end
        local Mask = self:FindWndTrans(trans, "Mask")
        if Mask then
            local MaskTxt = self:FindWndTrans(Mask, "MaskTxt")
            local maskTxt = ""
            if isLock then
                maskTxt = unlockTxt
                serverData = {}
            end
            self:SetWndText(MaskTxt, maskTxt)
            self:InitTextSizeWithLanguage(MaskTxt, -2)
            self:InitTextModeWithLanguage(MaskTxt)
        end
        CS.ShowObject(Mask, isLock)
        if not showRedPoint and showRuneRedPoint then
            showRedPoint = showRuneRedPoint
        end
        CS.ShowObject(redPointTrans, showRuneRedPoint and not self._isTryHero and not self._showMapping)
        local skillIdList = serverData.skillId
        self:CreateRuneSkillList(skillIdList, runeSkillTransList[i], runeNoSkillTxtTransList[i], isWear)
        local data = {
            id = serId,
            playerId = serverData.playerId,
            refId = serverData.refId,
            heroId = serverData.heroId,
            skillId = skillIdList,
            attrId = serverData.attrId,
            recast = serverData.recast,
            nextSkillId = serverData.nextSkillId,
            nextAttrId = serverData.nextAttrId,
        }
        self:SetWndClick(trans, function()
            if isLock then
                GF.ShowMessage(msgTxt)
            else
                if serId == i then
                    if self._isTryHero then
                        GF.ShowMessage(ccClientText(10088))
                        return
                    end
                    if (self._showMapping) then
                        GF.ShowMessage(string.replace(ccClientText(38426), ccClientText(38407)))
                        return
                    end
                    GF.OpenWnd("UIReWear", { runeId = serId, heroId = self._id, pos = i, wearList = runeList })
                else
                    local RuneInfo = {
                        openWay = not self._showMapping and 2 or nil,
                        runeData = serverData,
                        leftFunc = function()
                            gModelRune:OnRuneUnloadReq(self._id, serId, i)
                        end,
                        rightFunc = function()
                            GF.OpenWnd("UIReWear", { runeId = serId, heroId = self._id, pos = i, wearList = runeList })
                        end
                    }
                    gModelGeneral:OpenRuneInfoTip(RuneInfo)
                end
            end
        end)
        local InstanceID = trans:GetInstanceID()
        local baseClass = self._commonUIList[InstanceID]
        if not baseClass then
            baseClass = CommonIcon:New()
            self._commonUIList[InstanceID] = baseClass
            baseClass:Create(CS.FindTrans(trans, "Root"))
            self:SetIconClickScale(trans, true)
        end
        baseClass:SetRuneData(serverData)
        baseClass:SetRuneLock(isLock, unlockTxt)
        baseClass:DoApply()
    end

    local talentBaseIconList = self._talentBaseIconList
    if not talentBaseIconList then
        talentBaseIconList = {}
        self._talentBaseIconList = talentBaseIconList
    end

    local talentRefIdList = { 2001, 2002 }
    local talentTransList = self._talentTransList
    local talentRedPointList = self._talentRedPointList
    local talentNameTransList = { self.mTianFu1Name, self.mTianFu2Name }
    local talentMaskTransList = { self.mTianFu1Mask, self.mTianFu2Mask }
    talentList = talentList or {}
    for i = 1, UINewSagaInfo.MAX_TALENT_NUM do


        local pos = i + 2
        local talentRefId = talentRefIdList[i]
        local isLock = true
        local runePosRef = GameTable.MagicRunePosRef[talentRefId]
        local unlock = runePosRef.unlock
        local unlockTxt = ccLngText(runePosRef.text)

        local msgTxt

        unlock = string.split(unlock, ",")

        local unlockTag = true

        for k, unlockInfo in ipairs(unlock) do
            local tempUnlock = string.split(unlockInfo, "=")
            unlockTag = unlockTag and self:CheckIsUnLockPos(tonumber(tempUnlock[1]), tonumber(tempUnlock[2]), heroServerData)
            local selectType = tonumber(tempUnlock[1])
            --拼接提示信息
            if k == 1 then
                msgTxt = string.replace(ccClientText(UINewSagaInfo.ShowText[selectType]), tempUnlock[2])
            else
                msgTxt = msgTxt .. ccClientText(20178) .. string.replace(ccClientText(UINewSagaInfo.ShowText[selectType]), tempUnlock[2])
            end
        end
        msgTxt = msgTxt .. ccClientText(20177)

        isLock = isLock and not unlockTag
        --printInfoN2("cjh------------UINewSagaInfo--", "修改 unlock  条件配置")
        local talentData = talentList[pos]
        local skillId = i
        local showTalentRedPoint = false
        if isLock then
            self:SetWndText(talentNameTransList[i], unlockTxt)
        else
            local talentName = ""
            if talentData then
                if not showRedPoint then
                    showRedPoint = gModelRune:IsEnoughUp(talentData)
                end
                local ref = gModelRune:GetSkillInfoByRefId(talentData)
                skillId = tonumber(ref.SkillId)
                local skillRef = gModelHero:GetSkillByStarId(skillId)
                if skillRef then
                    talentName = ccLngText(skillRef.name)
                end
            else
                talentName = ccClientText(13252)
                local haveRuneItemNum = gModelItem:GetBagRuneItemAllNum()
                local studyNum = self:GetTalentStatus(talentList)
                haveRuneItemNum = haveRuneItemNum - studyNum
                if not showRedPoint then
                    showRedPoint = haveRuneItemNum > 0
                end
            end
            self:SetWndText(talentNameTransList[i], talentName)
            showTalentRedPoint = true
        end
        self:InitTextModeWithLanguage(talentNameTransList[i])
        CS.ShowObject(talentMaskTransList[i], not self._showMapping)
        local talentRedPoint = talentRedPointList[i]
        if showTalentRedPoint then
            if talentData then
                showTalentRedPoint = gModelRune:IsEnoughUp(talentData)
            else
                local haveRuneItemNum = gModelItem:GetBagRuneItemAllNum()
                local studyNum = self:GetTalentStatus(talentList)
                haveRuneItemNum = haveRuneItemNum - studyNum
                showTalentRedPoint = haveRuneItemNum > 0
            end
        end
        if not showRedPoint and showTalentRedPoint then
            showRedPoint = showTalentRedPoint
        end
        CS.ShowObject(talentRedPoint, showTalentRedPoint and not self._isTryHero)
        local trans = talentTransList[i]
        local key = trans:GetInstanceID()
        local baseClass = talentBaseIconList[key]
        if not baseClass then
            baseClass = SkillIcon:New(self)
            talentBaseIconList[key] = baseClass
        end
        baseClass:ShowLock(isLock)
        if not isLock then
            baseClass:ShowAdd(talentData == nil)
        else
            baseClass:ShowAdd(false)
        end
        baseClass:Create(trans, skillId, function()
            if isLock then
                GF.ShowMessage(msgTxt)
            else
                if skillId == i then
                    if self._isTryHero then
                        GF.ShowMessage(ccClientText(10088))
                        return
                    end
                    if (self._showMapping) then
                        GF.ShowMessage(string.replace(ccClientText(38426), ccClientText(38408)))
                        return
                    end
                    local heroRef = gModelHero:GetHeroRef(self._refId)
                    if heroRef then
                        local heroJob = heroRef.careerType
                        GF.OpenWnd("UITaltRealize", { HeroJob = heroJob, heroId = self._id, pos = pos, talentList = talentList, refId = self._refId })
                    end
                else
                    if self._isTryHero or self._showMapping then
                        local ref = gModelRune:GetSkillInfoByRefId(talentData)
                        local skillType = ref.skillType
                        local refId = ref.refId
                        gModelRune:OpenNewRuneSkillWnd(refId, skillType)
                    else
                        GF.OpenWnd("UITaltUp", { HeroId = self._id, pos = pos, TalentId = talentData })
                    end
                end
            end
        end)
    end
    if click then
        showRedPoint = false
    end
    CS.ShowObject(self.mRuneBotBtnRedPoint, showRedPoint)
end

function UINewSagaInfo:SetPolymorphicBtnState()
    --直接使用英雄ID 做判断
    local refId = self._refId

    local polymorphism = gModelHero:GetPolymorphism(refId)
    local isShow = gModelFunctionOpen:CheckIsShow(10309000)
    CS.ShowObject(self.mPolymorphicBtn, not (polymorphism == nil) and isShow)

end

function UINewSagaInfo:OnDrawNeedItemCell(list, item, itemdata, itempos)
    local InstanceID = item:GetInstanceID()
    local itemId, itemType, itemNum = itemdata.itemId, itemdata.itemType, itemdata.itemNum
    local CommonUI = self:FindWndTrans(item, "CommonUI")

    if CommonUI then
        --local commonUIList = self._commonUIList
        --if not commonUIList then
        --    commonUIList = {}
        --    self._commonUIList = commonUIList
        --end
        --local baseClass = commonUIList[InstanceID]
        --if not baseClass then
        --    baseClass = CommonIcon:New()
        --    commonUIList[InstanceID] = baseClass
        --    baseClass:Create(CS.FindTrans(CommonUI, "Root"))
        --end
        --baseClass:SetCommonReward(itemType, itemId, itemNum)
        --baseClass:EnableShowNum(false)
        --baseClass:HideClassImg(true)
        --baseClass:DoApply()


        local ItemIcon = self:FindWndTrans(CommonUI, "ItemIcon")
        local icon = gModelItem:GetItemIconByRefId(itemId)
        self:SetWndEasyImage(ItemIcon, icon)

        self:SetWndClick(CommonUI, function()
            gModelGeneral:OpenGetWayWnd({ itemId = itemId })
        end)
    end
    local NumTxt = self:FindWndTrans(item, "NumTxt")
    if NumTxt then
        local colorStr = self:GetColorStr(itemId, itemNum, LItemTypeConst.TYPE_ITEM)
        self:SetWndText(NumTxt, colorStr)
    end
end

function UINewSagaInfo:OnDrawStarCell(list, item, itemdata, itempos)
    local Star = self:FindWndTrans(item, "Star")
    if Star then
        self:SetWndEasyImage(Star, itemdata.img, function()
            CS.ShowObject(Star, true)
        end)
    end
end

function UINewSagaInfo:InitMsg()
    self:WndEventRecv(EventNames.NET_ERROR_CODE, function(code, error, argList)
        self._isClick = false
        self._sendMsg = false
    end)
    self:WndNetMsgRecv(LProtoIds.HeroUpStarResp, function(pb, ret)
        self._sendMsg = false
        self._needItemList = {}
        GF.ShowMessage(ccClientText(10019))
        local type = pb.type
        if type == 0 then
            local tab = { optType = 1, id = self._id }
            GF.OpenWnd("UISagaUpOpt", tab)
        end
        if self._btnIndex == UINewSagaInfo.BTN_TYPE_STAR then
            self:RefreshShow(true)
            self:RefreshStarPage()
        end
        self:RefreshGolemBtn()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroUpLevelResp, function()
        self._needItemList = {}
        self._sendMsg = false
        if not self._isUp then
            self._isUp = true
        end
        LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_LVUP_COMMON)
        self:CreateWndEffect(self.mHeroEffPos, "fx_ui_shengji_hero", "fx_ui_shengji_hero", 50, false, false, 6)
        if self._btnIndex == UINewSagaInfo.BTN_TYPE_ATTR then
            self:RefreshShow(true)
            self:RefreshAttrPage(true)
        end
    end)
    self:WndNetMsgRecv(LProtoIds.HeroUpGradeResp, function()
        self._needItemList = {}
        self._sendMsg = false
        if self._btnIndex == UINewSagaInfo.BTN_TYPE_ATTR then
            self:RefreshShow(true)
            self:RefreshAttrPage()
        end
    end)
    self:WndNetMsgRecv(LProtoIds.HeroAttributeResp, function(pb, ret)
        local isHave = self:InitNotRefreshWnd()
        if isHave then
            return
        end
        if pb.playerId == gLGameLogin:GetPlayerId() then
            self:RefreshPage()
        end
    end)
    self:WndEventRecv(EventNames.On_Item_Change, function()
        local isHave = self:InitNotRefreshWnd()
        if isHave then
            return
        end
        self:RefreshPage()
    end)

    self:WndEventRecv(gModelEquip.EventArgs.StrengthChange, function(...)
        self:RefreshPage()
    end)

    self:WndEventRecv(EventNames.UP_STAR_REFRESH_CLOTH, function()
        self:CreateDisplay()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroRebornResp, function(pb)
        self._sendMsg = false
        local heroId = pb.heroId
        if self._id == heroId then
            self:RefreshAttrPage()
        end
    end)
    self:WndNetMsgRecv(LProtoIds.RefreshDataResp, function()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroRemoveFormationResp, function()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroSkinSelectResp, function()
        self._isChangeSkin = true
    end)
    self:WndNetMsgRecv(LProtoIds.PowerShowResp, function(pb, ret)
        local showType = pb.type
        if showType == 2 then
            local _powers = pb.powers
            for i, v in ipairs(_powers) do
                local key = v.key
                if key == self._id then
                    local power = v.power
                    local powerstr = LUtil.PowerNumberCoversion(power)
                    self:SetWndText(self.mPowerNumTxt, powerstr)
                end
            end
        end
    end)
    self:WndNetMsgRecv(LProtoIds.RuneUpTalentSkillResp, function(pb, ret)
        local isHave = self:InitNotRefreshWnd()
        if isHave then
            return
        end
        if self._btnIndex == UINewSagaInfo.BTN_TYPE_RUNE then
            self:RefreshRunePage(true)
        end
    end)
    self:WndNetMsgRecv(LProtoIds.HeroLockResp, function()
        self:RefreshShow()
        if self._btnIndex == UINewSagaInfo.BTN_TYPE_STAR then
            gModelHero:ClearUpStarSelHeroList()
            gModelHero:ClearUpLvTreeSelHeroList()
            self._selectHeroList.appointList = nil
            self._selectHeroList.appNeedInfo = nil
            self._selectHeroList.rangList = nil
            self._selectHeroList.rangItemList = nil
            self._selectHeroList.rangNeedInfo = nil
            self._selectHeroList.itemNeedInfo = nil
            self:RefreshStarPage()
        end
    end)
    self:WndNetMsgRecv(LProtoIds.HeroBookRewardResp, function()
        self:RefreshStoryRedPoint()
    end)
    self:WndNetMsgRecv(LProtoIds.GeneralAttributeChangeResp, function()
        gModelHero:OnHeroAttributeReq(self._id)
    end)
    self:WndEventRecv(EventNames.ON_OPENOUTFITOPT_EVENT, function()
        local isHave = self:InitNotRefreshWnd()
        if isHave then
            return
        end
        self:RefreshPage()
    end)
    --self:WndNetMsgRecv(LProtoIds.HeroLoveInfoResp, function(pb)
    --    -- 喜欢英雄
    --    local heroLoveInfo = gModelHeroBook:GetGeneralHeroLoveInfoFromPb(pb.heroLoveInfo)
    --    local heroRefId = heroLoveInfo.heroRefId
    --    if self._refId ~= heroRefId then
    --        return
    --    end
    --    self:RefreshLoveInfoView(heroLoveInfo)
    --end)

    self:WndNetMsgRecv(LProtoIds.HeroTreeResetResp, function(pb)
        self:OnHeroTreeResetResp(pb)
    end)

    self:WndNetMsgRecv(LProtoIds.HeroTreePointActiveResp, function(pb)
        self:OnHeroTreePointActiveResp(pb)
    end)

    self:WndNetMsgRecv(LProtoIds.HeroPowerChangeResp, function(pb)
        self:OnHeroPowerChangeResp(pb)
    end)
    self:WndEventRecv(EventNames.ON_HERO_LIST_CHANGE, function()
        self:OnHeroListChange()
        self:OnRefreshPetPage()
    end)

    self:WndEventRecv(EventNames.REFRESH_OUTFITOPT_BAG, function()
        if not self._refreshView then
            return
        end
        --self:RefreshOutfitPage(true)
        self:RefreshPage()
        self:RefreshGolemBtn()
    end)
    self:WndNetMsgRecv(LProtoIds.SorceryCardWearResp, function()
        self:RefreshSorceryCard()
    end)
    self:WndNetMsgRecv(LProtoIds.SorceryCardUnloadResp, function()
        self:RefreshSorceryCard()
    end)
    --self:WndNetMsgRecv(LProtoIds.SorceryCardSwitchResp,function() self:RefreshSorceryCard() end)
    self:WndNetMsgRecv(LProtoIds.SorceryCardUpgradeResp, function()
        self:RefreshSorceryCard()
    end)

    -- 【G公共支持】删除伙伴晶石功能相关数据
    -- self:WndEventRecv(EventNames.ON_CLICK_CHANGEBTN,function()
    -- 	self:RefreshCrystalShard()
    -- end)

    self:WndNetMsgRecv(LProtoIds.HeroSetNameResp, function()
        self:RefreshHeroName()
    end)

    self:WndNetMsgRecv(LProtoIds.HeroFormSwitchResp, function()
        self:OnChangeForm()
    end)

    self:WndNetMsgRecv(LProtoIds.HeroListResp, function()
        self:RefreshCutInfo()
        --self._cutHeroList = gModelHero:FilterHeroList(self._career,self._race)
    end)
    self:WndNetMsgRecv(LProtoIds.HeroChangeResp, function()
        self:RefreshCutInfo()
        --self._cutHeroList = gModelHero:FilterHeroList(self._career,self._race)
    end)
    self:WndNetMsgRecv(LProtoIds.EquipWearResp, function()
        self:RefreshEquipPage(true)
    end)
    self:WndNetMsgRecv(LProtoIds.EquipUnloadResp, function()
        self:RefreshEquipPage(true)
    end)

    self:WndNetMsgRecv(LProtoIds.RuneCompoundResp, function()
        self:CheckRedPoint()
        if self._btnIndex == UINewSagaInfo.BTN_TYPE_RUNE then
            self:RefreshRuneUpgradeBtnRP()
        end
    end)
    self:WndEventRecv(EventNames.PET_CHANGE_LEVEL, function()
        self:OnRefreshPetPage()
    end)
    self:WndEventRecv(EventNames.PET_CHANGE_STAR, function()
        self:OnRefreshPetPage()
    end)
    self:WndEventRecv(EventNames.PET_CHANGE_LINK, function()
        self:OnRefreshPetPage()
    end)

end

function UINewSagaInfo:RefreshSkillPage()
    self:CreateSkillList()
end

function UINewSagaInfo:ChangeBotBtn(btnIndex, init)
    if not init then
        if self._btnIndex == btnIndex then
            return
        end
    end
    self._btnIndex = btnIndex
    CS.ShowObject(self.mLeftBtn, self._btnIndex ~= UINewSagaInfo.BTN_TYPE_PET)
    CS.ShowObject(self.mRightBtn, self._btnIndex ~= UINewSagaInfo.BTN_TYPE_PET)
    gModelHero:ClearUpStarSelHeroList()
    gModelHero:ClearUpLvTreeSelHeroList()
    self:Refresh()
end

function UINewSagaInfo:CreateSkillList()
    local list = self:GetSkillList()
    local uiSkillList = self._uiSkillList
    if uiSkillList then
        uiSkillList:RefreshList(list)
    else
        uiSkillList = self:GetUIScroll("uiSkillList")
        self._uiSkillList = uiSkillList
        uiSkillList:Create(self.mSkillList, list, function(...)
            self:OnDrawSkillCell(...)
        end)
    end
end

function UINewSagaInfo:CheckShowRebirthALock()
    local limitShowBtn = gModelHero:GeConfigByKey("limitShowBtn")
    if not limitShowBtn then
        if LOG_INFO_ENABLED then
            printInfoNR("试用英雄屏蔽按钮,默认是0，不屏蔽重生和锁定按钮，字段名为 limitShowBtn")
        end
        limitShowBtn = 0
    end
    local show = false
    if limitShowBtn == 0 then
        show = true
    else
        show = not self._isTryHero
    end

    return show
end

function UINewSagaInfo:GetSpiritHeroId()
    local id = self._id
    if not id then
        return
    end
    local serData = gModelHero:GetHeroServerDataById(id)
    if not serData then
        return
    end
    local spiritLinkId = gModelSpiritHero:GetSpiritHeroLinkId(serData)
    return spiritLinkId
end

function UINewSagaInfo:GetCurForm()
    local herodata = gModelHero:GetHeroById(self._id)
    return herodata and herodata:GetForm() or 0
end

function UINewSagaInfo:OnChangeForm()
    self:RefreshShow()
    self:Refresh()
end
--endregion --------------------------------------------------------------------------------------


------------------------------------------------------------
---母汤
function UINewSagaInfo:ClickMotherBtn()

    --拿下表现的部分
    local heroRefId = gModelHero:GetHeroEffectRefById(self._id).refId

    --GF.OpenWnd("UIFavorabilityInteract", { heroRefId = self._refId })
    GF.OpenWnd("UIFavorabilityInteract", { heroRefId = heroRefId })
end

function UINewSagaInfo:OnResetNameBtnFunc()
    local id = self._id
    if not id then
        return
    end
    local serverData = gModelHero:GetHeroServerDataById(id)
    if not serverData then
        return
    end
    GF.OpenWnd("UISagaResetName", {
        heroData = serverData,
    })
end

function UINewSagaInfo:RefreshLoveInfoView(serverData)
    local love = serverData.love
    local allLoveNum = serverData.allLoveNum
    CS.ShowObject(self.mLoveImg, love)
    CS.ShowObject(self.mNoLoveImg, not love)
    self:SetTextTile(self.mLoveBtn, allLoveNum)
end

function UINewSagaInfo:RefreshStoryRedPoint()
    --local id = self._id
    --local serverData = gModelHero:GetHeroServerDataById(id)
    --if not serverData then return end
    --local refId = serverData.refId
    --local status = gModelHeroBook:CheckBookStoryStatusByRefId(refId)
    --CS.ShowObject(self.mStoryBtnRedPoint,status)
end

function UINewSagaInfo:OnDrawTab(list, item, itemData, index)

    local name = itemData.tabBtnInfo.title
    self:SetWndTabText(item, name, nil, true)
    self:SetWndTabStatus(item, 1)
    self._tabList[itemData.tabBtnInfo.index] = item
    self:SetWndClick(item, function(...)
        if itemData.tabBtnInfo.index == UINewSagaInfo.BTN_TYPE_PET and not self:UpdatePetTabbarState() then
            GF.ShowMessage(string.replace(ccClientText(43777), GameTable.MagicPetConfigRef.petHeroStar))
            return
        end
        self:OnClickTab(itemData.tabBtnInfo.index)
    end)
    local offTrans = CS.FindTrans(item, "Off")
    local onTrans = CS.FindTrans(item, "On")
    self:SetWndEasyImage(offTrans, itemData.offIcon)
    self:SetWndEasyImage(onTrans, itemData.onIcon)
    if itemData.tabBtnInfo.index == UINewSagaInfo.BTN_TYPE_PET then
        self:UpdatePetTabbarState()
    end
end

function UINewSagaInfo:OnClickShare()
    local data = {
        root = self.mShareBtn,
        shareType = ModelChat.CHATSHARE_HERO,
        shareData = self._id,
    }
    gModelGeneral:OpenShareTip(data)
end

function UINewSagaInfo:OnClickHeroSpine(heroObj)
    if self._curUIHeroObj == nil then
        return
    end
    if self._curUIHeroObj ~= heroObj then
        return
    end
    local spine = self._curUIHeroObj:GetDpObject()
    if not spine then
        return
    end
    local nowPlayAniName = spine:GetCurTrackEntryName()
    if nowPlayAniName == nil or nowPlayAniName == "idle" then
        local panelPlayEff = heroObj:RandomOneSkill()
        if not panelPlayEff then
            heroObj:PlayAttackAni()
            return
        end

        local skillCtr = self._uiSkillCtrl
        if skillCtr then
            skillCtr:Destroy()
            skillCtr = nil
        end

        skillCtr = LUISkillCtrl:New(self)
        self._uiSkillCtrl = skillCtr

        skillCtr:InitData(heroObj, panelPlayEff, self.mHeroEffPos, 0, 12, 100)
        skillCtr:PreLoadPlaySkill()
    end
end

function UINewSagaInfo:OnTimer(key)
    if key == self._loopHeroObjTimerKey then
        local time = Time.unscaledTime
        --printInfoN("timer ---------------------------"..time)
        if self._curUIHeroObj then
            self._curUIHeroObj:OnRun(time)
        end
        if self._uiSkillCtrl then
            self._uiSkillCtrl:OnRun(time)
        end
    elseif key == self._tryHeroPageDescTimeKey then
        self:RefreshTryHeroPageDescTimeFunc()
    elseif key == self._trySpiritHeroNoActTimeKey then
        self:RefreshSpiritHeroNotActPageTime()
    elseif key == self._trySpiritHeroActTimeKey then
        self:RefreshSpiritHeroActPageTime()
    end
end

function UINewSagaInfo:StartTryHeroPageDescTime(endTime)
    if not endTime then
        endTime = self._heroEndTime
    end

    if not endTime or endTime <= 0 then
        return
    end

    self._heroEndTime = endTime
    self:RefreshTryHeroPageDescTimeFunc()
    self:TimerStart(self._tryHeroPageDescTimeKey, 1, false, -1)
end

function UINewSagaInfo:CreateLinkHeroIcon(trans, id)
    local iconTrans = self:FindWndTrans(trans, "CommonIcon/Icon")
    local instanceId = trans:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceId)
    baseClass:Create(iconTrans)
    baseClass:SetHeroPlayer(id)
    baseClass:DoApply()
    self:SetWndClick(iconTrans, function()
        self:OnClickGoToBtnFunc()
    end)
end

-- 【G公共支持】删除伙伴晶石功能相关数据
-- 显示魔晶入口
-- function UINewSagaInfo:RefreshCrystalShard()
-- 	local isOpen = gModelCrystalShard:CheckEntranceIsOpen(self._id)
-- 	local showRP = isOpen and gModelCrystalShard:CheckHeroRP(self._id) or false
-- 	local rpTrans = self:FindWndTrans(self.mCrystalShardBtn,"RedPoint")
-- 	local isTry = self._isTryHero
-- 	CS.ShowObject(rpTrans, showRP)
-- 	CS.ShowObject(self.mCrystalShardBtn, isOpen and isTry~=true)
-- end

function UINewSagaInfo:RefreshHeroName()
    local id = self._id
    if not id then
        return
    end
    local serverData = gModelHero:GetHeroServerDataById(id)
    if not serverData then
        return
    end
    local heroName = gModelHeroExtra:GetHeroSetName(serverData)
    self:SetWndText(self.mHeroName, heroName)
    self:SetWndText(self.mShiftUpStarText, heroName)
    --[[	local pageType = self._curAwakenShowType or UINewSagaInfo.PAGE_COMMON
        if pageType == UINewSagaInfo.PAGE_COMMON then
        else
        end]]
end

function UINewSagaInfo:GetGradeList()
    local list = {}
    local id = self._id
    local serverData = gModelHero:GetHeroServerDataById(id)
    if not serverData then
        return list
    end
    local refId = serverData.refId
    local heroRef = gModelHero:GetHeroRef(refId)
    if not heroRef then
        return list
    end
    local classType = heroRef.classType
    local grade = serverData.grade
    local refList = {}
    for k, v in pairs(GameTable.CharacterClassRef) do
        if v.grade ~= 0 and v.type == classType then
            table.insert(refList, v)
        end
    end
    table.sort(refList, function(a, b)
        return a.grade < b.grade
    end)
    for i = 1, UINewSagaInfo.MAX_GRADE_NUM do
        local refData = refList[i]
        local haveData = refData ~= nil or false
        -- -1代表没有开启
        local garde = refData and refData.grade or -1
        local act = garde <= grade and garde ~= -1
        local data = {
            grade = garde,
            needLevel = refData and refData.needLevel or -1,
            haveData = haveData,
            act = act,
        }
        table.insert(list, data)
    end
    return list
end

----觉醒
function UINewSagaInfo:RefreshAwakenPage()
    local isShowAwaken = self._curAwakenShowType == UINewSagaInfo.PAGE_AWAKEN
    --CS.ShowObject(self.mLiHuiClick, not isShowAwaken)
    CS.ShowObject(self.mLiHuiClick, false)
    CS.ShowObject(self.mAwakenView, isShowAwaken)
    self:RefreshShiftAwakenBtn()

    if isShowAwaken then
        --self:RefreshAwakenView()
        self:SendGuideAwaken()
    end
end

function UINewSagaInfo:ShowRaecKeZhiInfo()
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
            local restrainDetailsEff = raceRef.restrainDetailsEff
            local isEmpty = string.isempty(restrainDetailsEff)
            local str = ""
            if not isEmpty then
                local heroRaceImage = raceRef.heroRaceImage
                self:SetWndEasyImage(self.mTypeKeZhiImg, heroRaceImage, function()
                    CS.ShowObject(self.mTypeKeZhiImg, true)
                end, true)
            else
                CS.ShowObject(self.mTypeKeZhiImg, not isEmpty)
                str = ccClientText(31233)
            end
            CS.ShowObject(self.mTypeKZImgDiv, not isEmpty)
            CS.ShowObject(self.mNoHaveKeZhiTxtDiv, isEmpty)

            local name = string.replace(ccClientText(10079), ccLngText(raceRef.name))
            self:SetWndText(self.mRaceTypeName, name)

            self:SetWndText(self.mNoHaveKeZhiTxt, str)
        end
    end
end

function UINewSagaInfo:OnClickAwakenHelpBtn()
    local helpId = 120
    GF.OpenWnd("UIBzTips", { refId = helpId })
end

function UINewSagaInfo:RefreshHeroCVName(heroRefId)
    local cvName = gModelHero:GetHeroCVName(heroRefId)
    local isShow = not string.isempty(cvName)
    CS.ShowObject(self.mCVNameBg, isShow and false)
    if not isShow then
        return
    end

    local cvNameStr = string.replace(ccClientText(19786), cvName)
    self:SetWndText(self.mCVNameTxt, cvNameStr)
end

function UINewSagaInfo:ShowBtnKCard(bool)
    local showBtnKCard = bool
    local mappingData = self._mappingData
    local showMappingGroup = false
    if (mappingData) then
        local sourceHeroId = mappingData.sourceHeroId
        if (sourceHeroId and sourceHeroId ~= 0) then
            showBtnKCard = true
            self:SetCardMappingDisplay(sourceHeroId)
            showMappingGroup = true
        end
    end
    CS.ShowObject(self.mCardMappingGroup, showMappingGroup)
    CS.ShowObject(self.mCardMappingGroup, showMappingGroup)
    CS.ShowObject(self.mCardMappingGroup, showMappingGroup)
    CS.ShowObject(self.mBtnKCard, showBtnKCard)
end

function UINewSagaInfo:OnClickAwakenUpLvEvent()
    local treePointRefId = self._curSelectTreePointId
    if not treePointRefId then
        printInfoNR("self._curSelectTreePointId is a nil")
        return
    end

    local heroTreePointInfo = self._heroTreeInfoList[treePointRefId]
    if not heroTreePointInfo then
        printInfoNR("self._heroTreeInfoList[treePointRefId] is a nil, treePointRefId = " .. treePointRefId)
        return
    end

    local canLvlUp = heroTreePointInfo.canLvlUp
    local needCon = heroTreePointInfo.needCon
    if not canLvlUp and needCon then
        local limitStar = ""
        local upLvlConType = heroTreePointInfo.upLvlNeedConType
        local upLvlCondition = heroTreePointInfo.upLvlNeedActivateCon
        if upLvlConType == ModelHero.TREE_LV_CON_TYPE_LVL then
            limitStar = string.replace(ccClientText(20143), upLvlCondition)
        elseif upLvlConType == ModelHero.TREE_LV_CON_TYPE_STAR then
            limitStar = string.replace(ccClientText(20146), upLvlCondition)
        elseif upLvlConType == ModelHero.TREE_LV_CON_TYPE_RESONANCE then
            limitStar = string.replace(ccClientText(20153), upLvlCondition)
        end
        GF.ShowMessage(limitStar)
        return
    end

    local data = self._awakenSelectHeroList
    if table.isempty(data) then
        GF.ShowMessage(ccClientText(14425))
        return
    end

    local id = self._id
    if not (id and data) then
        printInfoNR("id and data have a nil")
        return
    end

    local appointedlist, rangelist, rangItemList = data.appointList, data.rangList, data.rangItemList
    local appNeedInfo, rangNeedInfo, itemNeedInfo = data.appNeedInfo, data.rangNeedInfo, data.itemNeedInfo
    for i, v in ipairs(appointedlist) do
        local needNum = appNeedInfo[i].needNum
        local selNum = table.keysize(v)
        if selNum < needNum then
            GF.ShowMessage(ccClientText(10054))
            return
        end
    end

    for i, v in ipairs(rangelist) do
        local selItemNum = 0
        local temp = rangItemList[i] or {}
        for _k, _v in pairs(temp) do
            selItemNum = selItemNum + _v
        end
        local needNum = rangNeedInfo[i].needNum
        local selNum = table.keysize(v) + selItemNum
        if selNum < needNum then
            GF.ShowMessage(ccClientText(10054))
            return
        end
    end

    for i, v in ipairs(itemNeedInfo) do
        local itemRefId, needNum = v.itemRefId, v.needNum
        local haveNum = gModelItem:GetNumByRefId(itemRefId)
        if haveNum < needNum then
            gModelGeneral:OpenGetWayWnd({ itemId = itemRefId })
            return
        end
    end

    self._showAwakenPointActivateEff = nil
    self._showAwakenPointUpLvEff = nil
    local canActivate = not heroTreePointInfo.isActivate
    if canActivate then
        self._showAwakenPointActivateEff = treePointRefId
    else
        self._showAwakenPointUpLvEff = treePointRefId
    end

    local list = {
        id = id,
        pointRefId = treePointRefId,
        appointedlist = appointedlist,
        rangelist = rangelist,
        rangItemList = rangItemList
    }
    gModelHero:OnHeroTreePointUpLvReq(list)
end

function UINewSagaInfo:GetCurHero()
    return gModelHero:GetHeroById(self._id)
end

function UINewSagaInfo:CutHeroAni()
end

function UINewSagaInfo:GetRuneAndTalentRedPointStatus()
    local showRATRedPoint = false
    local id = self._id
    local heroServerData = gModelHero:GetHeroServerDataById(id)
    if not heroServerData then
        return showRATRedPoint
    end
    local heroAttrList, heroWearEquipList, heroWearRuneList, heroWearTalentList, heroWearOutfitList = gModelHero:GetHeroAttrAndEquipInfoById(id, true)

    if self:CheckIsOpen(UINewSagaInfo.BTN_TYPE_RUNE) then
        local runeRefIdList = { 1001, 1002 }
        heroWearOutfitList = heroWearOutfitList or {}
        heroWearRuneList = heroWearRuneList or {}
        heroWearTalentList = heroWearTalentList or {}
        for i = 1, UINewSagaInfo.MAX_RUNE_NUM do
            if showRATRedPoint then
                break
            end
            local runeRefId = runeRefIdList[i]
            local isLock = true
            local runePosRef = GameTable.MagicRunePosRef[runeRefId]
            local unlock = runePosRef.unlock

            unlock = string.split(unlock, ",")
            local unlockTag = true
            for k, unlockInfo in ipairs(unlock) do
                local tempUnlock = string.split(unlockInfo, "=")
                unlockTag = unlockTag and self:CheckIsUnLockPos(tempUnlock[1], tempUnlock[2], heroServerData)
            end
            isLock = isLock and not unlockTag
            --printInfoN2("cjh------------UINewSagaInfo--", "修改 unlock  条件配置")

            local runeData = heroWearRuneList[i]
            local serverData = {}
            if runeData then
                serverData = runeData:GetServerData()
            end
            local showRuneRedPoint = false
            if not isLock then
                if not serverData.id then
                    local noWearNum = gModelRune:GetNoWearRuneNum()
                    showRuneRedPoint = noWearNum > 0
                end
            end
            if not showRATRedPoint and showRuneRedPoint then
                showRATRedPoint = showRuneRedPoint
            end
        end

        local talentRefIdList = { 2001, 2002 }
        for i = 1, UINewSagaInfo.MAX_TALENT_NUM do
            local pos = i + 2
            local talentRefId = talentRefIdList[i]
            local isLock = true
            local runePosRef = GameTable.MagicRunePosRef[talentRefId]
            local unlock = runePosRef.unlock
            unlock = string.split(unlock, ",")
            local unlockTag = true
            for k, unlockInfo in ipairs(unlock) do
                local tempUnlock = string.split(unlockInfo, "=")
                unlockTag = unlockTag and self:CheckIsUnLockPos(tempUnlock[1], tempUnlock[2], heroServerData)
            end

            isLock = isLock and not unlockTag
            --printInfoN2("cjh------------UINewSagaInfo--", "修改 unlock  条件配置")
            local talentData = heroWearTalentList[pos]
            local showTalentRedPoint = false
            if not isLock then
                if talentData then
                    if not showRATRedPoint then
                        showRATRedPoint = gModelRune:IsEnoughUp(talentData)
                    end
                else
                    local haveRuneItemNum = gModelItem:GetBagRuneItemAllNum()
                    local studyNum = self:GetTalentStatus(heroWearTalentList)
                    haveRuneItemNum = haveRuneItemNum - studyNum

                    if not showRATRedPoint then
                        showRATRedPoint = haveRuneItemNum > 0
                    end
                end
                showTalentRedPoint = true
            end
            if showTalentRedPoint then
                if talentData then
                    showTalentRedPoint = gModelRune:IsEnoughUp(talentData)
                else
                    local haveRuneItemNum = gModelItem:GetBagRuneItemAllNum()
                    local studyNum = self:GetTalentStatus(heroWearTalentList)
                    haveRuneItemNum = haveRuneItemNum - studyNum
                    showTalentRedPoint = haveRuneItemNum > 0
                end
            end
            if not showRATRedPoint and showTalentRedPoint then
                showRATRedPoint = showTalentRedPoint
            end
        end
    end
    return showRATRedPoint
end

function UINewSagaInfo:OnRefreshPetPage()
    self:UpdatePetLinkRed()
    local list = {}
    local heroSerData = gModelHero:GetHeroServerDataById(self._id)
    local petList = heroSerData.petIds
    local refs = GameTable.MagicPetStarHeroNumRef
    self.allStarLv = gModelPet:GetTotalStar()
    self.isOneLink = false
    for index, value in ipairs(refs) do
        if value.num <= self.allStarLv then
            if not self.isOneLink then
                self.isOneLink = not petList[index]
            end
            table.insert(list, { ref = value, petId = petList[index] })
        else
            table.insert(list, { ref = value })
            break
        end
    end
    self:CreateUIScrollImpl(nil, self.mListPet, list, function(...)
        self:OnLinkPetCell(...)
    end)
    local str = self.isOneLink and 43727 or 43742
    self:SetWndButtonText(self.mPetAutoBtn, ccClientText(str))
end

function UINewSagaInfo:RefreshHeroLoveInfo()
    if self._refId then
        gModelHeroBook:OnHeroLoveInfoReq(self._refId)
    end
end

function UINewSagaInfo:ClickAutoWearEquipBtn()
    local equipList = self:GetHeroInfoByType(UINewSagaInfo.DATA_TYPE_EQUIP) or {}
    if self._autoWearEquipBtnType == UINewSagaInfo.AUTO_BTN_WEAR then
        --local refIdList = {}
        --local changeList = {}
        --for i = 1, UINewSagaInfo.MAX_EQUIP_NUM do
        --    -- if equipList[i] == nil then
        --    local equip = gModelEquip:GetStrongestEquipByPart(i)
        --    if equip ~= nil then
        --        if equipList[i] then
        --            if equipList[i]:GetScore() < equip:GetScore() then
        --                table.insert(changeList, equip)
        --            end
        --        else
        --            --table.insert(refIdList, equip:GetRefId())
        --            table.insert(refIdList, equip)
        --        end
        --    end
        --    -- end
        --end

        local changeList, refIdList, isChange = gModelEquip:GetAutoWearEquip(equipList)

        if isChange then
            gModelEquip:OnEquipWearReq(self._id, changeList, 1)
        end
        if #refIdList > 0 then
            gModelEquip:OnEquipWearReq(self._id, refIdList)
        else
            if not isChange then
                GF.ShowMessage(ccClientText(11342))
            end
        end
    elseif self._autoWearEquipBtnType == UINewSagaInfo.AUTO_BTN_UNLOAD then
        local refIdList = {}
        for i = 1, UINewSagaInfo.MAX_EQUIP_NUM do
            if equipList[i] ~= nil then
                table.insert(refIdList, equipList[i]._refId)
            end
        end
        gModelEquip:OnEquipUnloadReq(self._id, refIdList)
    end


end


--region CheckFunction --------------------------------------------------------------------------------
function UINewSagaInfo:CheckIsUnLockPos(unLockType, needCondition, heroServerData)
    unLockType = tonumber(unLockType)
    local condition = 0
    if unLockType == 1 then
        condition = heroServerData.lv
    elseif unLockType == 2 then
        condition = heroServerData.star
    elseif unLockType == 3 then
        condition = gModelPlayer:GetPlayerLv()
    end

    return condition >= tonumber(needCondition)
end

function UINewSagaInfo:RefreshRuneUpgradeBtnRP()
    --- 2024/7/15：http://192.168.16.2:3002/issues/861
    --- 复现步骤：1.在进行穿戴高阶符文卸下低阶符文时满足了可合成符文合成，少女按钮红点一直沒移除，其他地方又不出现红点
    --- 策划预期：印刻页入口和印刻合成按钮加上红点
    local isTryHero = self._isTryHero
    local showRuneUpgradeRP = false
    if not isTryHero then
        showRuneUpgradeRP = gModelRune:GetCompoundRuneNum()
    end
    CS.ShowObject(self.mRuneUpgradeBtnRP, showRuneUpgradeRP)
end
function UINewSagaInfo:OnClickGolemBtnFunc()
    if not gModelFunctionOpen:CheckIsOpened(ModelGolem.FUNCTIONOPEN_ID, true) then
        return
    end
    -- if not gModelGolem:CheckGolemIsOpen(true) then
    -- 	gModelHeroCore:OpenHeroCoreExplain()--潜能界面-弃
    -- 	return
    -- end
    local id = self._id
    local serverData = gModelHero:GetHeroServerDataById(id)
    if not serverData then
        return
    end
    --local index = gModelHero:GetHeroCorePosById(id)
    local extraData = {
        heroId = id,
        --index = index,
        career = self._career,
        race = self._race,
        callbackFunc = function(heroId)
            if not self:IsWndValid() then
                return
            end
            if not heroId then
                return
            end
            local pos = self:GetHeroPosById(heroId)
            self:CutHeroRefresh(pos)
        end,
    }
    gModelGolem:OpenGolemMain(extraData)
end

function UINewSagaInfo:RefreshStarView()
    self:TimerStop(self._trySpiritHeroNoActTimeKey)
    self:TimerStop(self._trySpiritHeroActTimeKey)

    local showRedPoint = false
    CS.ShowObject(self.mStarBotBtnRedPoint, showRedPoint)
    local id = self._id
    local serverData = gModelHero:GetHeroServerDataById(id)
    if not serverData then
        return
    end
    local refId = serverData.refId

    local isSpiritHero = gModelSpiritHero:CheckIsSpiritHero(refId)
    if isSpiritHero then
        self:RefreshSpiritStarRaceDiv()
    end
    CS.ShowObject(self.mSpecialStarRaceDiv, isSpiritHero)
    CS.ShowObject(self.mCommonStarRaceDiv, not isSpiritHero)

    local heroRef = gModelHero:GetHeroRef(refId)                -- 英雄表
    if not heroRef then
        return
    end
    local optType = 0                                        -- 操作按钮状态
    local curStar, isResonance, lv = serverData.star, serverData.isResonance, serverData.lv
    local nextStar = curStar + 1
    local maxStar = heroRef.maxStar                            -- 星级上限
    local curHeroStarRef = gModelHero:GetStarRefById(id)                -- 当前星级配置
    if not curHeroStarRef then
        return
    end
    local heroNextStarRef = gModelHero:GetStarRefById(id, nextStar)    -- 获取下一星级表
    if not heroNextStarRef then
        -- 如果下一星级表不存在，则获取当前的星级表
        --nextStarId = nextStarId - 1
        heroNextStarRef = curHeroStarRef -- gModelHero:GetStarRefById(id)
    end

    if self._isTryHero then
        optType = UINewSagaInfo.STATUS_OPT_10
    elseif maxStar == curStar then
        optType = 7
    end

    -------------------------------- 修改当前星级的星星 --------------------------------
    CS.ShowObject(self.mHightStarNewHeroInfo_Cur, false)
    CS.ShowObject(self.mHightStarNewHeroInfo_Next, false)
    CS.ShowObject(self.mHightStarNewHeroInfo_Max, false)

    local showNext = not (optType == 7 or optType == UINewSagaInfo.STATUS_OPT_10)

    local curStarImg, curStarLv = gModelHero:GetHeroStarImg(curStar)
    local nextStarImg, nextStarLv = gModelHero:GetHeroStarImg(nextStar)

    CS.ShowObject(self.mHightStarNewHeroInfo_Cur, curStar > 10)

    if curStar > 10 then
        self:SetWndText(self.mHightStarNewHeroInforText_Cur, curStar - 10)
    else
        self:CreateStarPageStarList(self.mStarCurList, curStarLv, curStarImg)
    end

    CS.ShowObject(self.mStarNextList, showNext)
    CS.ShowObject(self.mStarArrow, showNext)
    CS.ShowObject(self.mStarCurList, showNext)
    CS.ShowObject(self.mStarMaxList, not showNext)
    CS.ShowObject(self.mStarCurList, curStar <= 10 and showNext)
    if showNext then
        CS.ShowObject(self.mStarNextList, nextStar <= 10)
        CS.ShowObject(self.mHightStarNewHeroInfo_Next, nextStar > 10)
        if nextStar > 10 then
            self:SetWndText(self.mHightStarNewHeroInforText_Next, nextStar - 10)
        else
            self:CreateStarPageStarList(self.mStarNextList, nextStarLv, nextStarImg)
        end
    else
        CS.ShowObject(self.mHightStarNewHeroInfo_Cur, false)

        nextStarImg, nextStarLv = gModelHero:GetHeroStarImg(curStar)

        CS.ShowObject(self.mStarMaxList, curStar < 10)
        CS.ShowObject(self.mHightStarNewHeroInfo_Max, curStar > 10)

        if curStar > 10 then
            self:SetWndText(self.mHightStarNewHeroInforText_Max, curStar - 10)
        else
            self:CreateStarPageStarList(self.mStarMaxList, nextStarLv, nextStarImg)
        end
    end

    local curMaxLv = curHeroStarRef.maxLevel
    local maxLv = heroNextStarRef.maxLevel
    -- 攻血成长提升
    local lastHeroStarRef = gModelHero:GetStarRefById(id, curStar - 1)
    --local lastHeroStarRef = gModelHero:GetHeroStarById(lastStarId)
    if not lastHeroStarRef then
        lastHeroStarRef = curHeroStarRef -- gModelHero:GetHeroStarById(lastStarId + 1)
    end
    local curAtkVal = curHeroStarRef.atkVal
    local curHpVal = curHeroStarRef.maxhpVal
    local atkVal = heroNextStarRef.atkVal
    local hpVal = heroNextStarRef.maxhpVal
    local upAtkVal = (atkVal - curAtkVal) * 100
    local upHpVal = (hpVal - curHpVal) * 100
    self:SetWndText(self.mLvBeforeTxt, curMaxLv)
    local showArrow = not (optType == 7 or optType == UINewSagaInfo.STATUS_OPT_10)
    local nextLv = ""
    if optType == 7 or optType == UINewSagaInfo.STATUS_OPT_10 then
        curAtkVal, curHpVal = curAtkVal * 100, curHpVal * 100
        self:SetWndText(self.mAtkBoldAddTxt, ccClientText(10052))
        local str = curAtkVal .. "%" .. "/" .. curHpVal .. "%"
        self:SetWndText(self.mAtkAddBeforeTxt, str)
        self:SetWndText(self.mAtkAddAfterTxt, "")
    else
        nextLv = maxLv
        self:SetWndText(self.mAtkBoldAddTxt, ccClientText(10024))
        self:SetWndText(self.mAtkAddBeforeTxt, "")
        local str = upAtkVal .. "%" .. "/" .. upHpVal .. "%"
        self:SetWndText(self.mAtkAddAfterTxt, str)
    end
    CS.ShowObject(self.mLvArrow, showArrow)
    CS.ShowObject(self.mAtkArrow, showArrow)
    self:SetWndText(self.mLvAfterTxt, nextLv)

    self._selectHeroList = {}
    local fuse
    local itemData = { [1] = {}, [2] = {}, [3] = {} }
    local showStarBtn = not (optType == 7 or optType == UINewSagaInfo.STATUS_OPT_10)
    self:StopTryHeroPageDescTime()
    if optType == 7 then
        fuse = false
        self:SetWndText(self.mStarPageDesc, ccClientText(10009))
        CS.ShowObject(self.mStarPageDesc, true)
    elseif optType == UINewSagaInfo.STATUS_OPT_10 then
        fuse = false
        CS.ShowObject(self.mStarPageDesc, true)
        self:StartTryHeroPageDescTime()
    else
        local upStarLimit
        if maxStar < nextStar then
            upStarLimit = self._heroUpStarLimit[curStar]
        else
            upStarLimit = self._heroUpStarLimit[nextStar]
        end
        local showBtn = false
        if upStarLimit then
            local isLimit = self._resonanceLevel < upStarLimit
            self._isLimit = isLimit
            showBtn = not isLimit
            self._upStarLimit = upStarLimit
            if isLimit then
                local limitStar = string.replace(ccClientText(14724), upStarLimit)
                self:SetWndText(self.mStarPageDesc, limitStar)
            end
            CS.ShowObject(self.mStarPageDesc, isLimit)
            fuse = not isLimit
        else
            fuse = true
            showBtn = true
            self._isLimit = false
            CS.ShowObject(self.mStarPageDesc, false)
        end
        gModelHero:ClearUpStarSelHeroList()
        showStarBtn = showBtn
        CS.ShowObject(self.mUpStarBtn, showBtn)
        local fuse1, fuse2, fuse3 = true, true, true
        local upStarAppoint, upStarRange, upStarItem = curHeroStarRef.upStarAppoint, curHeroStarRef.upStarRange, curHeroStarRef.upStarItem
        local selHeroList = {}
        self._appSelHeroList = {}
        self._rangSelHeroList = {}
        if not self._selectHeroList.appointList then
            self._selectHeroList.appointList = {}
        end
        if not self._selectHeroList.appNeedInfo then
            self._selectHeroList.appNeedInfo = {}
        end
        if not string.isempty(upStarAppoint) then
            itemData[1].appoint = {}
            local appoint = string.split(upStarAppoint, ",")
            for i, v in ipairs(appoint) do
                if not self._selectHeroList.appointList[i] then
                    self._selectHeroList.appointList[i] = {}
                end
                v = string.split(v, "=")
                local needRefId, needStar, needNum = tonumber(v[1]), tonumber(v[2]), tonumber(v[3])
                if not self._selectHeroList.appNeedInfo[i] then
                    self._selectHeroList.appNeedInfo[i] = { needNum = needNum }
                end
                local dataList = gModelHero:FilterHero(needRefId, needStar, nil, id, {})
                local haveNum = table.keysize(dataList)
                local tempList = {}
                local aaa = 0
                for key, value in pairs(dataList) do
                    if aaa >= needNum then
                        break
                    end
                    tempList[key] = value
                    aaa = aaa + 1
                end
                table.insert(selHeroList, tempList)
                table.insert(self._appSelHeroList, dataList)
                local canCompound = haveNum >= needNum
                itemData[1].appoint[i] = {
                    needRefId = needRefId,
                    needStar = needStar,
                    needNum = needNum,
                    canCompound = canCompound
                }
                if fuse1 then
                    fuse1 = haveNum >= needNum
                end
                -- 自动填充
                local sortSelList = gModelHero:SortFillHeroList(dataList)
                if #sortSelList ~= 0 then
                    local selList = self._selectHeroList.appointList[i]
                    for selIdx, selHeroData in ipairs(sortSelList) do
                        if selIdx > needNum then
                            break
                        end
                        local autoSelId = selHeroData._id
                        selList[autoSelId] = autoSelId
                        gModelHero:SetSelHeroId(autoSelId)
                    end
                end
            end
        end
        if not self._selectHeroList.rangList then
            self._selectHeroList.rangList = {}
        end
        if not self._selectHeroList.rangItemList then
            self._selectHeroList.rangItemList = {}
        end
        if not self._selectHeroList.rangNeedInfo then
            self._selectHeroList.rangNeedInfo = {}
        end
        if not string.isempty(upStarRange) then
            itemData[2].range = {}
            local range = string.split(upStarRange, ",")

            --这里先解析下消耗 0 的 代表所有的少女
            self._condition = {}
            for i, v in ipairs(range) do
                v = string.split(v, "=")
                local needRefId, needStar, needNum = tonumber(v[1]), tonumber(v[2]), tonumber(v[3])

                self._condition[needRefId] = self._condition[needRefId] or {}

                self._condition[needRefId][needStar] = self._condition[needRefId][needStar] or 0

                self._condition[needRefId][needStar] = needNum + self._condition[needRefId][needStar]
            end

            local useRefIdNum = {}

            for i, v in ipairs(range) do
                if not self._selectHeroList.rangList[i] then
                    self._selectHeroList.rangList[i] = {}
                end
                if not self._selectHeroList.rangItemList[i] then
                    self._selectHeroList.rangItemList[i] = {}
                end
                v = string.split(v, "=")
                local needRefId, needStar, needNum = tonumber(v[1]), tonumber(v[2]), tonumber(v[3])

                --如果是需要0的话 那么就是要chekc所有的
                local checkNeedNum = 0
                if needRefId == 0 then
                    for k, v in pairs(self._condition) do
                        checkNeedNum = checkNeedNum + checknumber(v[needStar])
                    end

                elseif needRefId == 6 then
                    -- 计算三系列的消耗
                    -- 1   2  3

                    for k, v in pairs(self._condition) do
                        if k == 1 or k == 2 or k == 3 then
                            checkNeedNum = checkNeedNum + checknumber(v[needStar])
                        end
                    end
                elseif needRefId == 7 then
                    --计算光暗 两系的消耗  4  5
                    for k, v in pairs(self._condition) do
                        if k == 4 or k == 5 then
                            checkNeedNum = checkNeedNum + checknumber(v[needStar])
                        end
                    end

                else
                    -- 只需计算自己本身的消耗
                    for k, v in pairs(self._condition) do
                        if k == needRefId then
                            checkNeedNum = checkNeedNum + checknumber(v[needStar])
                        end
                    end
                end




                --needNum    == 0
                if not self._selectHeroList.rangNeedInfo[i] then
                    self._selectHeroList.rangNeedInfo[i] = {
                        needRefId = needRefId, needStar = needStar, needNum = needNum,
                    }
                end
                local dataList, yinghunItemList = gModelHero:FilterHero(needRefId, needStar, needRefId, id, {})
                local haveNum = table.keysize(dataList) + table.keysize(yinghunItemList)
                local selHeroNum = 0
                local rangList = {}
                for key, appData in pairs(self._selectHeroList.appointList) do
                    if not dataList[key] then
                        rangList[key] = appData
                    end
                end
                table.insert(self._rangSelHeroList, rangList)
                local canCompound
                if needStar <= ModelHero.AUTO_FILL_STAR then
                    -- 自动填充
                    local tempSelNum = 0
                    local sortSelList = gModelHero:SortFillHeroList(dataList)
                    if #sortSelList ~= 0 then
                        local selList = self._selectHeroList.rangList[i]
                        for selIdx, selHeroData in ipairs(sortSelList) do
                            if selIdx > needNum then
                                break
                            end
                            tempSelNum = tempSelNum + 1
                            local autoSelId = selHeroData._id
                            selList[autoSelId] = autoSelId
                            gModelHero:SetSelHeroId(autoSelId)
                        end
                    end
                    local showRed = tempSelNum < needNum
                    if showRed then
                        local sortSelLen = #sortSelList
                        showRed = sortSelLen >= needNum
                    end
                    canCompound = showRed
                else
                    haveNum = haveNum - selHeroNum

                    canCompound = haveNum >= checkNeedNum
                    --canCompound = haveNum >= needNum
                end
                if fuse2 then
                    fuse2 = canCompound
                end
                itemData[2].range[i] = { needRefId = needRefId, needStar = needStar, needNum = needNum, canCompound = canCompound }
            end
        end
        if not self._selectHeroList.itemNeedInfo then
            self._selectHeroList.itemNeedInfo = {}
        end
        if not string.isempty(upStarItem) then
            itemData[3].item = {}
            upStarItem = string.split(upStarItem, "=")
            local itype, itemRefId, num = tonumber(upStarItem[1]), tonumber(upStarItem[2]), tonumber(upStarItem[3])
            if not self._selectHeroList.itemNeedInfo[1] then
                self._selectHeroList.itemNeedInfo[1] = { itemRefId = itemRefId, needNum = num }
            end
            itemData[3].item[1] = { itype = itype, needRefId = itemRefId, needNum = num }
            local haveNum = gModelItem:GetNumByRefId(itemRefId)
            if fuse3 then
                fuse3 = haveNum >= num
            end
        end
        if fuse then
            fuse = fuse1 and fuse2 and fuse3
        end
    end

    if isSpiritHero then
        fuse = false
    end

    local isShowRed = true
    for k, v in ipairs(itemData[2].range or {}) do
        isShowRed = v.isShowRed
        if not isShowRed then
            break
        end
    end
    for k, v in ipairs(itemData[2].range or {}) do
        v.isShowRed = isShowRed
    end

    self:CreateUpStarNeedItemList(itemData)
    self:SetWndButtonText(self.mUpStarBtn, ccClientText(10001))

    CS.ShowObject(self.mUpStarBtn, showStarBtn)
    CS.ShowObject(self.mStarBotBtnRedPoint, fuse)

    -------------------------------- 不满足升星条件的提示--目前只提示207条件 --------------------------------
    --解析下  看下cfg

    local condition_ShowNeedHero = curHeroStarRef.upStar1
    CS.ShowObject(self.mNeedStarHeroTips, false)

    local isShow207 = showStarBtn
    if not string.isempty(condition_ShowNeedHero) then
        --不空在进行设置
        local condition_parse = string.split(condition_ShowNeedHero, ",")

        local count = tonumber(condition_parse[2])

        local condition_parse_1 = string.split(condition_parse[1], "=")

        local star = tonumber(condition_parse_1[3])

        --check 一下  不满足 就显示
        if not gModelHero:CheckHeroListIsEnoughtStarCount(gModelHero:GetHeroSortList(), star, count) then
            --如果没有满足  NeedStarHeroTips
            local showStr = string.replace(ccClientText(10182), count, star)
            self:SetWndText(self.mNeedStarHeroTips, showStr)
        else
            isShow207 = false
        end

    else
        isShow207 = false
    end
    CS.ShowObject(self.mNeedStarHeroTips, isShow207)
    --printInfoN2("cjh---------", "tets----------------------")
end

--function UINewSagaInfo:AwakenCutHero(curIndex)
--	if self._curUIHeroObj and not self._curUIHeroObj:IsDpValid() then return end
--	local heroList = self._activateAwakenHeroList
--	local heroIndex = self._heroIndex
--	if not heroIndex then return end
--	local index
--	for k,v in ipairs(heroList) do
--		if v.index == heroIndex then
--			index = k
--		end
--	end
--
--	if not index then
--		index = heroIndex
--	end
--
--	local lastNum = #heroList
--	local newIndex = index + curIndex
--	if newIndex <= 0 then
--		newIndex = lastNum
--	elseif newIndex > lastNum then
--		newIndex = 1
--	end
--	self._appointList = {}
--	self._rangList = {}
--	self._rangItemList = {}
--	self._needItemList = {}
--	gModelHero:ClearUpStarSelHeroList()
--	gModelHero:ClearUpLvTreeSelHeroList()
--	local newHeroData = heroList[newIndex]
--	local data = gModelHero:GetHeroBagPos(newHeroData.index)
--	if not table.isempty(data) then
--		self:RefreshHeroData(data, UINewSagaInfo.PAGE_AWAKEN)
--	end
--end

function UINewSagaInfo:RefreshHeroData(data, curIndex)
    --LResRelease.WebglRelease()
    LxResUtil.RunUnusedAssetUnload()

    local id = data.id
    --local curIndex = data.index
    --local refId = gModelHero:GetRefIdById(id)
    self._refId = data.refId
    self._id = id
    self._heroIndex = curIndex
    self._autoAttr = true
    self._curAwakenShowType = UINewSagaInfo.PAGE_COMMON
    self:RefreshTryHeroState()
    self:RefreshShow()
    self:Refresh()

    self:RefreshHeroLoveInfo()
    self:UpdatePetLinkRed()
    self:UpdatePetTabbarState()
end

function UINewSagaInfo:RemoveTheOlderCacheLH(exceptHero)
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

function UINewSagaInfo:OnClickGoToBtnFunc()
    local jumpId = 16503000
    local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId, true)
    if isOpen then
        -- gModelFunctionOpen:Jump(jumpId, self:GetWndName())
        GF.OpenWnd("UISagaReeNew", { page = 2 })
        GF.CloseWndByName("UINewSagaInfo")
        GF.CloseWndByName("UISaga")
        FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.CITY })
    end
end

function UINewSagaInfo:CheckRedPoint()
    local uplvBtnRedPoint, upStarBtnRedPoint, skillBtnRedPoint, outfitBtnRedPoint, runeBtnRedPoint = false, false, false, false, false

    local equipExtensionRedpoint = false
    local upEquipRedPoint = false
    local upAwakenRedPoint = false
    local awakenTreeRedPointShow = false
    local isTryHero = false
    local id = self._id
    local serverData = gModelHero:GetHeroServerDataById(id)
    if serverData then
        local refId, star, lv, grade = serverData.refId, serverData.star, serverData.lv, serverData.grade
        local nextStar = star + 1
        local heroRef = gModelHero:GetHeroRef(refId)                -- 英雄表
        local maxStar = heroRef.maxStar                    -- 星级上限
        local heroStarRef = gModelHero:GetStarRefById(id) -- gModelHero:GetHeroStarById(starId)	-- 星级表
        --local skinEffectId = heroStarRef.skinEffectId
        --local showSkinBtn = not string.isempty(skinEffectId)
        --if not self._showMoreBtn and showSkinBtn then
        --	CS.ShowObject(self.mSkinBtn,false)
        --else
        --	CS.ShowObject(self.mSkinBtn,showSkinBtn)
        --end

        --self._showSkinBtn = showSkinBtn
        --if showSkinBtn then
        local state = gModelHero:CheckHeroSkinIsUpImpl(id)
        CS.ShowObject(self.mSkinRedPoint, state)
        --end

        self:RefreshStoryRedPoint()

        isTryHero = serverData.isTry
        if not isTryHero then
            local haveGold, haveExp = gModelItem:GetNumByRefId(101001), gModelItem:GetNumByRefId(104001)
            local isResonance = serverData.isResonance

            local classType = heroRef.classType                -- 阶级数据
            local classId = gModelHero:ConvertToHeroGradeId(classType, grade)    -- 阶级Id
            local classRef = gModelHero:GetHeroClassById(classId)    -- 阶级表
            local needLv = classRef.needLevel                -- 升到下一阶的等级需求
            local needStar = classRef.needStar                -- 升到下一阶的星级需求
            local needItem = classRef.needItem                -- 升到下一阶的道具需求

            local maxLevel = heroStarRef.maxLevel            -- 等级上限
            local optType = self:GetOptStatus(star, maxStar, lv, maxLevel, needLv, needStar)
            local isSpiritHero = gModelSpiritHero:CheckIsSpiritHero(refId)
            if isResonance ~= 1 then
                if optType == 5 and not isSpiritHero then
                    local needGold, needExp, addLv = gModelHero:GetUpNumLvPayItem(id, lv, classId, grade, 1)
                    uplvBtnRedPoint = false
                    if needGold <= haveGold and needExp <= haveExp then
                        uplvBtnRedPoint = true
                    end
                elseif optType == 4 then
                    if not string.isempty(needItem) then
                        local itemList = {}
                        local list = string.split(needItem, ",")
                        for i, v in ipairs(list) do
                            v = string.split(v, "=")
                            local itemRefId, itemNum = tonumber(v[2]), tonumber(v[3])
                            itemList[itemRefId] = itemNum
                        end
                        uplvBtnRedPoint = true
                        for k, v in pairs(itemList) do
                            if not uplvBtnRedPoint then
                                break
                            end
                            local haveItem = gModelItem:GetNumByRefId(k)
                            uplvBtnRedPoint = v <= haveItem
                        end
                    end
                end
            end

            --星级页
            ----星级红点检测
            if maxStar ~= star then
                --gModelHero:ClearUpStarSelHeroList()
                local upStarAppoint = heroStarRef.upStarAppoint
                local upStarRange = heroStarRef.upStarRange
                local upStarItem = heroStarRef.upStarItem
                local fuse1, fuse2, fuse3 = true, true, true
                local data = {}
                if not string.isempty(upStarAppoint) then
                    local appoint = string.split(upStarAppoint, ",")
                    for _i, _v in ipairs(appoint) do
                        if not fuse1 then
                            break
                        end
                        _v = string.split(_v, "=")
                        local needHeroRefId, needHeroStar, needNum = tonumber(_v[1]), tonumber(_v[2]), tonumber(_v[3])
                        local dataList = gModelHero:FilterHero(needHeroRefId, needHeroStar, nil, id, {})
                        local haveNum = table.keysize(dataList)
                        local tempList = {}
                        local aaa = 0
                        for key, val in pairs(dataList) do
                            if aaa >= needNum then
                                break
                            end
                            tempList[key] = val
                            aaa = aaa + 1
                        end
                        table.insert(data, tempList)
                        fuse1 = haveNum >= needNum
                    end
                end
                if not string.isempty(upStarRange) then
                    local range = string.split(upStarRange, ",")

                    self._condition = {}
                    for i, v in ipairs(range) do
                        v = string.split(v, "=")
                        local needRefId, needStar, needNum = tonumber(v[1]), tonumber(v[2]), tonumber(v[3])

                        self._condition[needRefId] = self._condition[needRefId] or {}

                        self._condition[needRefId][needStar] = self._condition[needRefId][needStar] or 0

                        self._condition[needRefId][needStar] = needNum + self._condition[needRefId][needStar]
                    end

                    for _i, _v in ipairs(range) do
                        if not fuse2 then
                            break
                        end
                        _v = string.split(_v, "=")
                        local needHeroRefId, needHeroStar, needNum = tonumber(_v[1]), tonumber(_v[2]), tonumber(_v[3])
                        local dataList, yinghunItemList = gModelHero:FilterHero(needHeroRefId, needHeroStar, needHeroRefId, id, {})
                        local haveNum = table.keysize(dataList) + table.keysize(yinghunItemList)
                        local selNum = 0
                        for i, v in ipairs(data) do
                            for k, val in pairs(v) do
                                if dataList[k] then
                                    selNum = selNum + 1
                                end
                            end
                        end
                        haveNum = haveNum - selNum



                        --如果是需要0的话 那么就是要chekc所有的
                        local checkNeedNum = 0
                        if needHeroRefId == 0 then
                            for k, v in pairs(self._condition) do
                                checkNeedNum = checkNeedNum + checknumber(v[needHeroStar])
                            end

                        elseif needHeroRefId == 6 then
                            -- 计算三系列的消耗
                            -- 1   2  3

                            for k, v in pairs(self._condition) do
                                if k == 1 or k == 2 or k == 3 then
                                    checkNeedNum = checkNeedNum + checknumber(v[needHeroStar])
                                end
                            end
                        elseif needHeroRefId == 7 then
                            --计算光暗 两系的消耗  4  5
                            for k, v in pairs(self._condition) do
                                if k == 4 or k == 5 then
                                    checkNeedNum = checkNeedNum + checknumber(v[needStar])
                                end
                            end

                        else
                            -- 只需计算0 和自己本身的消耗
                            for k, v in pairs(self._condition) do
                                if k == needHeroRefId then
                                    checkNeedNum = checkNeedNum + checknumber(v[needHeroStar])
                                end
                            end
                        end

                        fuse2 = haveNum >= checkNeedNum
                    end
                end
                if not string.isempty(upStarItem) then
                    upStarItem = string.split(upStarItem, "=")
                    local itemRefId, num = tonumber(upStarItem[2]), tonumber(upStarItem[3])
                    local haveNum = gModelItem:GetNumByRefId(itemRefId)
                    fuse3 = haveNum >= num
                end
                upStarBtnRedPoint = fuse1 and fuse2 and fuse3
                local upStarLimit
                if maxStar < nextStar then
                    upStarLimit = self._heroUpStarLimit[star]
                else
                    upStarLimit = self._heroUpStarLimit[nextStar]
                end
                if upStarLimit then
                    -- 魔镜等级小于限制等级，显示文字隐藏按钮
                    local resonanceLevel = gModelResonance:GetResonanceLv()
                    if resonanceLevel < upStarLimit then
                        upStarBtnRedPoint = false
                    end
                end
                if gModelSpiritHero:CheckIsSpiritHero(refId) then
                    upStarBtnRedPoint = false
                end
            end

            ----觉醒红点检测
            awakenTreeRedPointShow = gModelHero:CheckHeroAwakenTreeActivateOrUpLv(id)

            local heroAttrList, heroWearEquipList, heroWearRuneList, heroWearTalentList, heroWearOutfitList = gModelHero:GetHeroAttrAndEquipInfoById(id)
            heroWearEquipList = heroWearEquipList or {}
            local equiplist = {}
            for k, v in pairs(heroWearEquipList) do
                if not equipExtensionRedpoint then
                    equipExtensionRedpoint = gModelEquip:GetEquipCanExtensionRedpoint(v)

                end

                equiplist[k] = v._refId
            end
            for index = 1, 4 do
                local curEquipData = equiplist[index]
                local equipRefId = gModelEquip:FindTypeEquipHeightScoreByType(index, curEquipData)            -- 0：没有装备
                if not curEquipData and equipRefId ~= 0 then
                    upEquipRedPoint = true
                    break
                elseif equipRefId ~= curEquipData and equipRefId ~= 0 then
                    upEquipRedPoint = true
                    break
                end
            end
        end
    end

    if not isTryHero then
        runeBtnRedPoint = self:GetRuneAndTalentRedPointStatus()

        --- 2024/7/15：http://192.168.16.2:3002/issues/861
        --- 复现步骤：1.在进行穿戴高阶符文卸下低阶符文时满足了可合成符文合成，少女按钮红点一直沒移除，其他地方又不出现红点
        --- 策划预期：印刻页入口和印刻合成按钮加上红点
        if not runeBtnRedPoint then
            runeBtnRedPoint = gModelRune:GetCompoundRuneNum()
        end
    end

    local curIndex = 0
    if uplvBtnRedPoint then
        curIndex = UINewSagaInfo.BTN_TYPE_ATTR
    elseif upStarBtnRedPoint then
        curIndex = UINewSagaInfo.BTN_TYPE_STAR
    elseif skillBtnRedPoint then
        curIndex = UINewSagaInfo.BTN_TYPE_SKILL
    elseif runeBtnRedPoint then
        curIndex = UINewSagaInfo.BTN_TYPE_RUNE
    elseif upEquipRedPoint then
        curIndex = UINewSagaInfo.BTN_TYPE_EQUIP
    end
    --CS.ShowObject(self.mAttrBotBtnRedPoint, uplvBtnRedPoint)
    --CS.ShowObject(self.mStarBotBtnRedPoint, upStarBtnRedPoint)
    --CS.ShowObject(self.mSkillBotBtnRedPoint, skillBtnRedPoint)
    --CS.ShowObject(self.mOutfitBotBtnRedPoint, upEquipRedPoint)
    --CS.ShowObject(self.mRuneBotBtnRedPoint, runeBtnRedPoint)

    local attrRedpoint = CS.FindTrans(self._tabList[UINewSagaInfo.BTN_TYPE_ATTR], "redPoint")

    local starRedpoint = CS.FindTrans(self._tabList[UINewSagaInfo.BTN_TYPE_STAR], "redPoint")

    --local skillRedpoint = CS.FindTrans(self._tabList[UINewSagaInfo.BTN_TYPE_SKILL], "redPoint")

    local runeRedpoint = CS.FindTrans(self._tabList[UINewSagaInfo.BTN_TYPE_RUNE], "redPoint")

    local equipRedpoint = CS.FindTrans(self._tabList[UINewSagaInfo.BTN_TYPE_EQUIP], "redPoint")

    CS.ShowObject(attrRedpoint, uplvBtnRedPoint or skillBtnRedPoint)
    CS.ShowObject(starRedpoint, upStarBtnRedPoint)
    --CS.ShowObject(skillRedpoint, skillBtnRedPoint)
    CS.ShowObject(runeRedpoint, runeBtnRedPoint)
    CS.ShowObject(equipRedpoint, upEquipRedPoint or equipExtensionRedpoint)

    --if curIndex ~= 0 and curIndex ~= UINewSagaInfo.BTN_TYPE_ATTR and self._isFirstOpen then

    local isInit = false
    if awakenTreeRedPointShow and self._isFirstOpen and not (uplvBtnRedPoint or upStarBtnRedPoint or skillBtnRedPoint or runeBtnRedPoint) then
        upAwakenRedPoint = awakenTreeRedPointShow
        --self._curAwakenShowType = UINewSagaInfo.PAGE_AWAKEN
        --curIndex = 1
        --isInit = true
    end

    if curIndex ~= 0 and self._isFirstOpen then
        self:ChangeBotBtn(curIndex, isInit)
    end

    self._isFirstOpen = false

    self:UpdateInteractBtnRed()
end

function UINewSagaInfo:OnClickKCard()
    local serverData = self._serverData
    local star = serverData.star
    local unlockHeroStar = tonumber(gModelSorceryCard:GetSorceryCardConfigRefByKey("unlockHeroStar"))
    if star < unlockHeroStar then
        GF.ShowMessage(string.replace(ccClientText(29502), unlockHeroStar))
        return
    end
    GF.OpenWnd("UIKCardEquip", { heroId = serverData.id })
end

function UINewSagaInfo:RefreshRunePage(netWork, click)
    local isTryHero = self._isTryHero
    CS.ShowObject(self.mRuneShopBtn, not isTryHero)

    CS.ShowObject(self.mRuneUpgradeBtn, not isTryHero)

    self:RefreshRuneUpgradeBtnRP()

    CS.ShowObject(self.mRuneSkillPreBtn, not isTryHero)
    CS.ShowObject(self.mRunePageDesc, isTryHero)
    local mappingData = self._mappingData
    local showMapping = false
    if (mappingData) then
        local sourceHeroId = mappingData.sourceHeroId
        showMapping = sourceHeroId and sourceHeroId ~= "0" and sourceHeroId ~= 0
    end
    CS.ShowObject(self.mRuneBotBtnGroup, not showMapping)
    CS.ShowObject(self.mMappingGroup, showMapping)
    if (mappingData) then
        local sourceHeroId = mappingData.sourceHeroId
        local heroData = gModelHero:GetHeroById(sourceHeroId)
        if (heroData) then
            local heroRefId = heroData:GetRefId()
            local heroEffRef = gModelHero:GetShowEffectById(heroRefId)
            local txtTrans = self:FindWndTrans(self.mMappingGroup, "DescTxt")
            local runeNameStr = ccClientText(38407) .. "&" .. ccClientText(38408)
            local descTxtStr = not self._showMapping and string.replace(ccClientText(38412), runeNameStr, runeNameStr) or ccClientText(38423)
            self:SetWndText(txtTrans, descTxtStr)
            local iconTrans = self:FindWndTrans(txtTrans, "Icon")
            self:SetWndEasyImage(iconTrans, heroEffRef.outfitIcon)
            local changeBtnTrans = self:FindWndTrans(txtTrans, "ChangeBtn")
            local changeBtnText = self:FindWndTrans(changeBtnTrans, "Text")
            local changeBtnStrId = not self._showMapping and 38424 or 38425
            self:SetWndText(changeBtnText, ccClientText(changeBtnStrId))
            self:SetWndClick(changeBtnTrans, function()
                if (self.clickMapping) then
                    return
                end
                self._showMapping = not self._showMapping
                self:RefreshRunePage()
                self.clickMapping = true
                LxTimer.DelayTimeCall(function()
                    self.clickMapping = false
                end, 0.1)
            end)
        end
    end
    self:CreateRuneAndTalent(netWork, click)
end

function UINewSagaInfo:CreateLiHui(heroDrawing, effRef)
    if not heroDrawing then
        return
    end
    local uiLiHuiObjList = self._uiLiHuiObjList
    if not uiLiHuiObjList then
        uiLiHuiObjList = {}
        self._uiLiHuiObjList = uiLiHuiObjList
    end
    if self._uiDrawingCtrl then
        self._uiDrawingCtrl:Destroy()
        self._uiDrawingCtrl = nil
    end
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
        --local scale = effRef.pos1Scale
        local scale = 0
        if scale and scale > 0 then
            newUILiHui:SetScale(scale)
        end
        newUILiHui:SetClickFunc(function()
            self.isClickSound = true
            action = gModelHero:GetHeroClickAction(effRef.refId)
            if action and action ~= "" then
                -- local spine = newUILiHui:GetDisplaySpine()
                -- spine:SetAnimationCompleteFunc(function(ainName)
                --     if ainName == action then
                --         spine:PlayAnimation(0, "idle", true)
                --     end
                -- end)
                -- spine:PlayAnimation(0,action,false)
                newUILiHui:PlayAni(action, false, nil, nil, true, LSpineAniConst.idle)
                local actionSound = gModelHero:GetHeroClickSound(effRef.refId)
                if actionSound and actionSound ~= "" then
                    gLGameAudio:StopSingleSound();
                    gLGameAudio:PlaySingleSound(actionSound, function()
                    end)
                end
            end
        end)
        newUILiHui:SetLoadedFunction(function()
            local _displaySpine = newUILiHui:GetDpObject()
            if _displaySpine then
                _displaySpine:SetRaycastTarget(true)
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

function UINewSagaInfo:GetTalentStatus(talentList)
    local studyNum = 0
    for k, v in pairs(talentList) do
        local tempRef = gModelRune:GetSkillInfoByRefId(v)
        local upItem = string.split(tempRef.upItem, ",")[1]
        if upItem then
            upItem = string.split(upItem, "=")
            local needRefId = tonumber(upItem[2])
            if needRefId then
                studyNum = studyNum + gModelItem:GetBagRuneItemByRefId(needRefId)
            end
        end
    end
    return studyNum
end

function UINewSagaInfo:GetColorStr(refId, num, itemType, selNum)
    local allNum
    if itemType == LItemTypeConst.TYPE_ITEM then
        allNum = gModelItem:GetNumByRefId(refId)
    else
        allNum = selNum
    end
    local color = "139057FF"
    if num > allNum then
        color = "c81212ff"
    end
    allNum = LUtil.NumberCoversion(allNum)
    num = LUtil.NumberCoversion(num)
    local str = string.replace(ccClientText(10065), color, allNum, num)
    return str
end

function UINewSagaInfo:RefreshCutInfo()
    --self._cutHeroList = gModelHero:FilterHeroList(self._career, self._race)
    local sortHeroInfo = gModelHero:GetNewHeroSortList(self._career, self._race)
    self._cutHeroList = sortHeroInfo and sortHeroInfo.sortHeros or {}
    self._heroIndex = self:GetHeroPosById(self._id)
end

function UINewSagaInfo:CheckIsOpen(page)
    local botBtnInfo = self._botBtnFunctionOpenList and self._botBtnFunctionOpenList[page]
    if not botBtnInfo then
        return
    end

    local showLock = false
    local functionId = botBtnInfo.functionId
    if functionId and functionId > 0 then
        showLock = not gModelFunctionOpen:CheckIsOpened(functionId)
    end
    CS.ShowObject(botBtnInfo.lockTrans, showLock)

    local color = Color.New(1, 1, 1, 1)
    if showLock then
        color = Color.New(0, 0, 0, 1)
    end
    self:SetWndImageColor(botBtnInfo.IconTrans, color)

    return not showLock
end

function UINewSagaInfo:CreateRuneSkillList(list, trans, emptyShowTrans, isWear)
    list = list or {}
    local InstanceID = trans:GetInstanceID()
    local uiList = self:FindUIScroll(InstanceID)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(InstanceID)
        uiList:Create(trans, list, function(...)
            self:OnDrawRuneSkillCell(...)
        end)
    end
    local showEmpty = #list <= 0
    local textId
    if not isWear then
        textId = 20114
    elseif showEmpty then
        textId = 20136
    end
    if textId then
        self:SetWndText(emptyShowTrans, ccClientText(textId))
    end
    CS.ShowObject(emptyShowTrans, showEmpty)
end

function UINewSagaInfo:RefreshStarActLink()
    self:RefreshSpiritHeroActPageTime()
    self:TimerStop(self._trySpiritHeroActTimeKey)
    if self._isTryHero then
        self:TimerStart(self._trySpiritHeroActTimeKey, 1, false, -1)
    end
    local spiritLinkId = self:GetSpiritHeroId()
    local showIcon = spiritLinkId ~= nil
    CS.ShowObject(self.mStarSpecialLinkHeroRoot, showIcon)
    if not showIcon then
        return
    end
    self:CreateLinkHeroIcon(self.mStarSpecialLinkHeroRoot, spiritLinkId)
end

function UINewSagaInfo:RefreshShow(netWork)
    local id = self._id
    --LogError("id = " .. id)
    if not netWork then
        gModelHero:FindHeroPowStateById(id)
    end
    local serverData = gModelHero:GetHeroServerDataById(id)
    if not serverData then
        return
    end
    local refId = serverData.refId
    local star = serverData.star
    self._serverData = serverData
    self:RefreshSorceryCard()
    --【G公共支持】删除伙伴晶石功能相关数据
    -- self:RefreshCrystalShard()--魔晶入口
    local heroRef = gModelHero:GetHeroRef(refId)
    if not heroRef then
        return
    end
    local raceId = heroRef.raceType
    local raceRef = gModelHero:GetHeroRaceRefByRefId(raceId)
    if not raceRef then
        return
    end
    local careerType = heroRef.careerType
    local careerRef = gModelHero:GetCareerRefByRefId(careerType)
    if not careerRef then
        return
    end
    --local effRef = gModelHero:GetHeroShowRefByRefId(refId, star)

    local effRef = gModelHero:GetHeroEffectRefById(self._id)
    if not effRef then
        return
    end

    local heroBg = effRef.skinBg
    if string.isempty(effRef.skinBg) then
        heroBg = effRef.heroBg
    end

    self:SetWndEasyImage(self.mHeroEffectBg, heroBg)

    if not netWork then
        local lock = serverData.lock
        self._lockHero = lock
        local lockImg = "hero_ui_lock"
        if lock == 1 then
            lockImg = "hero_ui_lock1"
        end
        self:SetWndEasyImage(self.mLockBtn, lockImg)
    end

    local qualityRef = gModelItem:GetQualityRef(heroRef.quality)
    if qualityRef then
    end

    --旧的图标的设置
    heroBg = raceRef.heroBg
    self:SetWndEasyImage(self.mHeroBg, heroBg, function()
        --CS.ShowObject(self.mHeroBg, true)
        CS.ShowObject(self.mHeroBg, false)
    end)
    local raceImg = raceRef.icon
    self:SetWndEasyImage(self.mHeroRaceImg, raceImg, function()
        CS.ShowObject(self.mHeroRaceImg, true)
    end)
    local qualityIcon = heroRef.qualityIcon
    self:SetWndEasyImage(self.mHeroZZImg, qualityIcon, function()
        CS.ShowObject(self.mHeroZZImg, true)
    end)

    local careerName, careerImg = ccLngText(careerRef.name), careerRef.jobIcon
    self:SetWndText(self.mJobName, careerName)
    self:SetWndEasyImage(self.mJobImg, careerImg)

    local power = serverData.fightPower
    --local powerstr = LUtil.FormatPowerShowStr(power, 130, 150)
    local powerstr = LUtil.PowerNumberCoversion(power)

    self:SetWndText(self.mPowerNumTxt, powerstr)

    local location = "[" .. ccLngText(effRef.location) .. "]"
    self:SetWndText(self.mJobEffTxt, location)

    local heroType = effRef.heroType
    local heroEffects, hasActive = gModelHero:GetHeroEffectListByRefId(heroType, true)
    local isFavor = heroRef.maxFavorability and heroRef.maxFavorability > 0 and heroEffects and hasActive
    local isOpenMother = gModelFunctionOpen:CheckIsOpened(21002100)
    CS.ShowObject(self.mMotherBtn, isFavor and isOpenMother)

    if not netWork then
        self:CreateDisplay()
    end

    self:CreateStarList(star)

    if star > 10 then
        CS.ShowObject(self.mStarList, false)
        CS.ShowObject(self.mHightStarNewHeroInfo, true)
        CS.ShowObject(self.mHightStarNewHeroInforText, true)
        self:SetWndText(self.mHightStarNewHeroInforText, star - 10)
    else
        CS.ShowObject(self.mStarList, true)
        CS.ShowObject(self.mHightStarNewHeroInfo, false)
    end

    local quality = gModelHero:GetHeroQualityByRefId(refId, star)
    --local heroName = ccLngText(effRef.name)
    --[[	local color = gModelItem:GetColorByQualityId(quality)
        if color then
            self:SetXUITextTransColor(self.mHeroName,color)
        end]]



    if not self._isForeign then
        qualityRef = gModelItem:GetQualityRef(quality)
    end

    self:RefreshHeroCVName(effRef.refId)

    if not qualityRef then
        return
    end
    --取消品质设置
    --local heroMsgNameBg = qualityRef.heroMsgNameBg
    --self:SetWndEasyImage(self.mHeroQuaImg, heroMsgNameBg, function()
    --    CS.ShowObject(self.mHeroQuaImg, true)
    --end)

    --新的别名设置 -- 根据品质设置颜色
    local nickName = ccLngText(effRef.nickName)
    self:SetWndText(self.mNickName, nickName)
    local heroRef = gModelHero:GetHeroRef(refId)
    local quality = heroRef.quality
    local qualityRef = gModelItem:GetQualityRef(quality)
    self:SetXUITextTransColor(self.mNickName, qualityRef.nameColor)
    ------- 7.18 cxl and fgc修改
    --local limitShowBtn = gModelHero:GeConfigByKey("limitShowBtn")
    --if not limitShowBtn then
    --    if LOG_INFO_ENABLED then
    --        printInfoNR("试用英雄屏蔽按钮,默认是0，不屏蔽重生和锁定按钮，字段名为 limitShowBtn")
    --    end
    --    limitShowBtn = 0
    --end
    --local show = false
    --if limitShowBtn == 0 then
    --    show = true
    --else
    --    show = not self._isTryHero
    --end
    --local show = self:CheckShowRebirthALock()
    --CS.ShowObject(self.mRebirthBtn, show)
    --CS.ShowObject(self.mLockBtn, show)

    self:CheckRedPoint()
    self:RefreshHeroName()
    self:RefreshBtnShow()

    self:SetPolymorphicBtnState()
    self:SetSkinBtnState()

end
function UINewSagaInfo:InitEvent()
    for k, v in pairs(self._botBtnTransList) do
        local sel = self._btnIndex == v.index
        CS.ShowObject(v.rootImg, sel)
        self:SetWndText(v.textTrans, v.title)
        CS.ShowObject(v.textTrans, sel)
        CS.ShowObject(v.NoTextTrans, not sel)
        self:SetWndClick(v.root, function()
            if self._btnIndex ~= v.index then
                self._curAwakenShowType = UINewSagaInfo.PAGE_COMMON
            end
            self:ChangeBotBtn(v.index)
        end)
    end
    self:SetWndClick(self.mReturnBotBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mPreviewBtn, function()
        self:SendThinkingData("1-4")
        gModelGeneral:OpenHeroStarPre({ refId = self._refId, form = self:GetCurForm() })
    end)
    self:SetWndClick(self.mStoryBtn, function()
        --self:SendThinkingData("1-1")
        --GF.OpenWnd("UISagaSy",{refId = self._refId})
        --GF.OpenWndUp("UISagaBookSyPop", { heroRefId = self._refId, index = 1 })
        --GF.OpenWndUp("UISagaBookDetail", { heroRefId = self._refId, index = 1 })
        gModelGeneral:OpenHeroStarPre({ refId = self._refId, showTab = true, selectIndex = 2 })
    end)

    self:SetWndClick(self.mSkinBtn, function()
        self:SendThinkingData("1-6")
        --gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_SKIN, "open", 1)
        --local para =
        --{
        --	refId = self._refId,
        --	id = self._id,
        --	curHeroIndex = self._heroIndex,
        --  	func = function(heroIndex) self:RefreshHeroByIndex(heroIndex) end
        --}
        --gModelGeneral:OpenHeroSkin(para)

        self:OpenHeroSkin()
    end)
    self:SetWndClick(self.mShareBtn, function()
        self:SendThinkingData("1-5")
        self:OnClickShare()
    end)
    self:SetWndClick(self.mCommentBtn, function()
        local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_3)
        if not sensitive then
            GF.ShowMessage(ccClientText(30800))
            return
        end
        self:SendThinkingData("1-2")
        GF.OpenWnd("UISagaComment", { refId = self._refId, id = self._id })
    end)
    self:SetWndClick(self.mNewCommentBtn, function()
        local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_3)
        if not sensitive then
            GF.ShowMessage(ccClientText(30800))
            return
        end
        self:SendThinkingData("1-2")
        GF.OpenWnd("UISagaComment", { refId = self._refId, id = self._id })
    end)
    self:SetWndClick(self.mLockBtn, function()
        if self._isTryHero then
            GF.ShowMessage(ccClientText(10094))
            return
        end
        local wndId = 10002
        local key = "1-7"
        if self._lockHero == 1 then
            wndId = 10003
            key = "1-8"
        end
        self:SendThinkingData(key)
        local func = function()
            gModelHero:OnHeroLockReq(self._id, self._lockHero)
        end
        gModelGeneral:OpenUIOrdinTips({ refId = wndId, func = func })
    end)
    self:SetWndClick(self.mRebirthBtn, function()
        if self._isTryHero then
            GF.ShowMessage(ccClientText(10093))
            return
        end
        self:SendThinkingData("1-3")
        self:RebirthEvent()
    end)
    self:SetWndClick(self.mLeftBtn, function()
        self:CutHero(-1)
    end)
    self:SetWndClick(self.mRightBtn, function()
        self:CutHero(1)
    end)
    self:SetWndClick(self.mUpLvBtn, function()
        self:OnClickUpLvEvent()
    end)

    self:SetWndClick(self.mUpLvBtn_2, function()
        if self._curCanUpCostItem then
            GF.OpenWnd("UINewSagaCurCanUpTips", { curCanUpCostItem = self._curCanUpCostItem })
        end
    end)

    self:SetWndLongClick(self.mUpLvBtn, function()
        if self._optType == 4 or self._optType == 5 then
            self:OnClickUpLvEvent()
        end
    end, 0.2, true)
    self:SetWndClick(self.mShiftAwakenBtn, function()
        self:OnClickAwakenEvent()
    end)
    self:SetWndClick(self.mUpStarBtn, function()
        self:OnClickUpStarEvent()
    end)
    self:SetWndClick(self.mAutoWearBtn, function()
        self:OnClickAutoWearEvent()
    end)
    self:SetWndClick(self.mRuneShopBtn, function()
        local functionId = gModelRune:GetConfig("talentShopJump")
        local isOpen = gModelFunctionOpen:CheckIsOpened(functionId, true)
        if isOpen then
            gModelFunctionOpen:Jump(functionId)
        end
    end)
    self:SetWndClick(self.mRuneUpgradeBtn, function()
        --[[        local refId = self._refId
                local id = self._id
                local index = self._heroIndex
                local func = self._callFunc
                local btnIndex = self._btnIndex
                GF.OpenWndBottom("UIEqCompound",{func = function()
                    GF.OpenWnd("UINewSagaInfo",{
                        refId = refId,
                        id = id,
                        index = index,
                        func = func,
                        btnIndex = btnIndex,
                        isFirstOpen = 0,
                    })
                end})]]

        GF.OpenWnd("UIMid", { page = 1 })
        self:WndClose()
    end)
    self:SetWndClick(self.mRuneSkillPreBtn, function()
        --GF.OpenWnd("UIReJNPreView")
        GF.OpenWnd("UIReJNRecommend", { refId = self._refId })
    end)
    self:SetWndClick(self.mTypeImgMask, function()
        CS.ShowObject(self.mTypeImgMask, false)
    end)
    self:SetWndClick(self.mShareMask, function()
        CS.ShowObject(self.mShareMask, false)
    end)
    self:SetWndClick(self.mAttrTipBtn, function()
        local btnIndex = self._btnIndex
        local showAttrTip = btnIndex == UINewSagaInfo.BTN_TYPE_ATTR or btnIndex == UINewSagaInfo.BTN_TYPE_STAR
        if showAttrTip then
            local serverData = gModelHero:GetHeroServerDataById(self._id)
            local career
            if serverData then
                career = gModelHero:GetHeroCareerType(serverData.refId)
            end
            GF.OpenWndUp("UINewSagaAttr", { id = self._id, career = career, heroData = serverData })
        else
            local helpId = btnIndex == UINewSagaInfo.BTN_TYPE_OUTFIT and 103 or 89
            GF.OpenWnd("UIBzTips", { refId = helpId })
        end
    end)
    self:SetWndClick(self.mMinArrowBtnClick, function()
        self:ChangeShowMaxBtnList(true)
    end)
    self:SetWndClick(self.mMaxArrowBtn, function()
        self:ChangeShowMaxBtnList(false)
    end)
    self:SetWndClick(self.mHeroZZImg, function()
        GF.OpenWnd("UISagaQualitySow")
    end)
    self:SetWndClick(self.mHeroRaceImg, function()
        CS.ShowObject(self.mTypeImgMask, true)
        self:ShowRaecKeZhiInfo()
    end)
    self:SetWndClick(self.mGradeDescMask, function()
        CS.ShowObject(self.mGradeDescMask, false)
    end)
    self:SetWndClick(self.mLiHuiClick, function()
        local serverData = gModelHero:GetHeroServerDataById(self._id)
        if not serverData then
            return
        end
        local effRef = gModelHero:GetHeroEffectRefById(self._id)
        --local skin = serverData.skin
        --local showRefId = skin ~= 0 and skin or gModelHero:GetHeroEffectByRefId(serverData.refId,serverData.star)
        local showRefId = effRef.refId
        GF.OpenWndUp("UISagaLiHuiSow", { selSkinRefId = showRefId })
    end)
    self:SetWndClick(self.mLoveBtn, function()
        self:OnClickLike()
    end)
    self:SetWndClick(self.mBtnShareTwitter, function(...)
        self:OnClickShareTwitter()
    end)
    self:SetWndClick(self.mShiftUpStarBtn, function()
        self:OnClickShiftUpStarEvent()
    end)
    self:SetWndClick(self.mAwakenPandectBtn, function()
        self:OnClickAwakenPandectEvent()
    end)
    self:SetWndClick(self.mUpAwakenBtn, function()
        self:OnClickAwakenUpLvEvent()
    end)
    self:SetWndClick(self.mAwakenHelpBtn, function()
        self:OnClickAwakenHelpBtn()
    end)
    --self:SetWndClick(self.mAwakenLeftBtn,function() self:AwakenCutHero(-1) end)
    --self:SetWndClick(self.mAwakenRightBtn,function() self:AwakenCutHero(1) end)
    self:SetWndClick(self.mFDJBtn, function()
        GF.OpenWnd("UISagaPotency")
    end)
    self:SetWndClick(self.mBtnKCard, function()
        self:OnClickKCard()
    end)
    self:SetWndClick(self.mAttrPageGoToBtn, function()
        self:OnClickGoToBtnFunc()
    end)
    self:SetWndClick(self.mStarPageGoToBtn, function()
        self:OnClickGoToBtnFunc()
    end)

    self:SetWndClick(self.mPolymorphicBtn, function()
        if not gModelFunctionOpen:CheckIsOpened(10309000, true) then
            return
        end
        gModelGeneral:OpenHeroStarPre({ refId = self._refId, showTab = true, selectIndex = 4 })
    end)

    -- 【G公共支持】删除伙伴晶石功能相关数据
    -- self:SetWndClick(self.mCrystalShardBtn,function()
    -- 	--gModelCrystalShard:SetHeroIdAndIndex(self._id,self._heroIndex)
    -- 	GF.OpenWnd("WndCrystalShardParent",{
    -- 		heroId = self._id,
    -- 		heroIndex = self._heroIndex,
    -- 		career = self._career,
    -- 		race = self._race,
    -- 	}) --魔晶系统
    -- end)

    self:SetWndClick(self.mGolemBtn, function()
        self:OnClickGolemBtnFunc()
    end)

    self:WndEventRecv(EventNames.ON_GUIDE_END, function()
        self:RefreshGolemEff()
    end)

    self:SetWndClick(self.mBattleRankBtn, function()
        self:OnClickBattleRankBtnFunc()
    end)

    self:SetWndClick(self.mResetNameBtn, function()
        self:OnResetNameBtnFunc()
    end)
    self:SetWndClick(self.mHeroQuaImg, function()
        self:OnResetNameBtnFunc()
    end)

    local bShowPhotoGraph = true
    if CS.IsWebGL() and LWxHelper.IsMiniGamePlatform() then
        bShowPhotoGraph = false
    end
    CS.ShowObject(self.mPhotograph_Btn,bShowPhotoGraph)
    self:SetWndClick(self.mPhotograph_Btn, function()
        local herodata = gModelHero:GetHeroById(self._id)
        local refId = herodata:GetRefId()

        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK, "2-1-1-5", refId, true, 0)
        GF.OpenWndTop("UISagaDisPy", { heroRefId = refId, sid = self._id })
    end)

    self:SetWndClick(self.mAutoWearEquipBtn, function()
        self:ClickAutoWearEquipBtn()
    end)

    self:SetWndClick(self.mMotherBtn, function()
        self:ClickMotherBtn()
    end)


    --返回按钮
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    --功能按鈕--跳轉花園
    self:SetWndClick(self.mHuaYuanBtn, function()
        GF.OpenWndBottom("UISagaSpirit", { page = 2 })
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mPetAutoBtn, function()
        if self.isOneLink then
            if self.petLinkRed then
                gModelPet:OnPetLinkByHeroReq(self._id, 1)
            else
                GF.ShowMessage(ccClientText(43776))
            end
        else
            gModelPet:OnPetLinkByHeroReq(self._id, 2)
        end
    end)

    self:SetWndClick(self.mPetViewBtn, function()
        GF.OpenWnd("UIPeMinWin")
    end)

    self:SetWndClick(self.mBadgeBtn,function() self:OnClickBadgeBtn() end)
end

function UINewSagaInfo:RefreshStarNoActLink()
    self:RefreshSpiritHeroNotActPageTime()
    self:TimerStop(self._trySpiritHeroNoActTimeKey)
    if self._isTryHero then
        self:TimerStart(self._trySpiritHeroNoActTimeKey, 1, false, -1)
    end
end

function UINewSagaInfo:CutHeroRefresh(newIndex)
    self._appointList = {}
    self._rangList = {}
    self._rangItemList = {}
    self._needItemList = {}
    gModelHero:ClearUpStarSelHeroList()
    gModelHero:ClearUpLvTreeSelHeroList()
    --local data = gModelHero:GetHeroBagPos(newIndex)
    local heroData = self._cutHeroList[newIndex]
    if not table.isempty(heroData) then
        self:RefreshHeroData(heroData, newIndex)
    end

    self:RefreshBtnShow()

end

function UINewSagaInfo:SendGuideAwaken()
    local serverData = gModelHero:GetHeroServerDataById(self._id)
    local career
    if serverData then
        career = gModelHero:GetHeroCareerType(serverData.refId)
    end

    if career then
        --为觉醒指引添加特殊消息发送
        FireEvent(EventNames.OPEN_WND_PART, "StarPage" .. career)
    end
end

function UINewSagaInfo:GetSkillList()
    local list = {}
    local id = self._id
    local serverData = gModelHero:GetHeroServerDataById(id)
    if not serverData then
        return list
    end
    local refId, star = serverData.refId, serverData.star
    local heroSkillIdList = gModelHero:GetSkillIdListById(id)
    for i = 1, 4 do
        local skillData = heroSkillIdList[i]
        local data = {
            grade = serverData.grade,
            refId = refId,
            star = star,
            index = i,
        }
        if skillData then
            data.skillId = skillData.skillId
            data.openClass = skillData.openClass
        end
        table.insert(list, data)
    end
    return list
end

function UINewSagaInfo:CreateUpLvNeedItem(list)
    local uiUpLvList = self._uiUpLvList
    if uiUpLvList then
        uiUpLvList:RefreshList(list)
    else
        uiUpLvList = self:GetUIScroll("uiUpLvList")
        self._uiUpLvList = uiUpLvList
        uiUpLvList:Create(self.mUpLvNeedItemList, list, function(...)
            self:OnDrawNeedItemCell(...)
        end)
    end

    if #list == 0 then
        CS.ShowObject(self.mUpLvNeedItemListBg, false)
    else
        CS.ShowObject(self.mUpLvNeedItemListBg, true)
    end
end

function UINewSagaInfo:OnHeroPowerChangeResp(pb)
    local powerChange = pb.powerChange
    local powerPre, powerNow = math.floor(powerChange.pre), math.floor(powerChange.now)

    local subValue = math.floor(powerNow - powerPre)
    if subValue <= 0 then
        return
    end

    local attrChange = pb.attrChange
    local attrDataList = {}
    local pre, now
    local preValue, nowValue
    local refId, showType
    local addNum
    for i, v in ipairs(attrChange) do
        pre, now = v.pre, v.now
        preValue, nowValue = pre.value, now.value

        refId = pre.refId
        showType = gModelHero:GetAttrShowType(refId)
        if showType == 2 then
            addNum = nowValue - preValue
        else
            addNum = math.floor(nowValue - preValue)
        end
        table.insert(attrDataList, {
            refId = pre.refId,
            addNum = addNum
        })
    end

    gModelGeneral:OpenHeroPowerTip(attrDataList, powerPre, subValue)
end
function UINewSagaInfo:SetCardMappingDisplay(sourceHeroId)
    local iconTrans = self:FindWndTrans(self.mCardMappingGroup, "Icon")
    local txtTrans = self:FindWndTrans(self.mCardMappingGroup, "Txt")
    local heroData = gModelHero:GetHeroById(sourceHeroId)
    local heroRefId = heroData:GetRefId()
    local heroEffRef = gModelHero:GetShowEffectById(heroRefId)
    self:SetWndEasyImage(iconTrans, heroEffRef.outfitIcon)
    self:SetWndText(txtTrans, ccClientText(38427))
end

---- 阵容排行按钮
function UINewSagaInfo:RefreshHeroBattleRankBtn()
    local showBattleCamp = self:CheckShowBattleRankBtn()
    CS.ShowObject(self.mBattleRankBtn, showBattleCamp)
end

function UINewSagaInfo:GetHeroEffectRef()
    local id = self._id
    local serverData = gModelHero:GetHeroServerDataById(id)
    if not serverData then
        return
    end
    --local refId,star = serverData.refId,serverData.star
    --local skin = serverData.skin
    --local showEffId
    --if skin and skin > 0 then
    --	showEffId = skin
    --else
    --	showEffId = gModelHero:GetHeroEffectByRefId(refId,star)
    --end
    local effRef = gModelHero:GetHeroEffectRefById(id)
    return effRef, effRef.refId, serverData.star
end

function UINewSagaInfo:HaveStrongEquip()
    return self._haveStrongEquip
end

function UINewSagaInfo:GetShiftAwakenBgIconPath()
    local serverData = gModelHero:GetHeroServerDataById(self._id)
    if not serverData then
        return nil
    end
    local refId = serverData.refId
    local star = serverData.star
    local quality = gModelHero:GetHeroQualityByRefId(refId, star)
    local ref = gModelItem:GetQualityRef(quality)
    if not ref then
        return nil
    end

    return ref.awakenNameBg
end

function UINewSagaInfo:OnDrawSkillCell(list, item, itemdata, itempos)
    local skillId, openClass = itemdata.skillId, itemdata.openClass
    local grade = itemdata.grade
    local refId, star, index = itemdata.refId, itemdata.star, itemdata.index
    local Root = self:FindWndTrans(item, "CommonUI/Root")
    if Root then
        local SkillIconTrans = self:FindWndTrans(Root, "SkillIcon")
        local baseClass = SkillIcon:New(self)
        if skillId then
            baseClass:SetSkillInfo(grade, false, openClass, 1)
            baseClass:Create(SkillIconTrans, skillId, function()
                local heroData = gModelHero:GetHeroServerDataById(self._id)
                gModelGeneral:OpenHeroSkillWnd({ curSkillId = skillId, curSkillIdx = index, heroData = heroData })
                --[[				local skillInfo = {
                                    grade = openClass,
                                    refId = refId,
                                    star = star,
                                }
                                GF.OpenWndTop("UIJNInfo",{
                                    skillId = skillId,
                                    heroData = skillInfo,
                                    needGrade = openClass,
                                    index = index
                                })]]
            end)
        else
            baseClass:SetShowIcon(false, false)
            baseClass:SetSkillInfo(nil, nil, nil, 1)
            baseClass:Create(SkillIconTrans, 0, function()
            end)
        end
        if not skillId then
            baseClass:SetIconAndIconBgGray(false)
        end
    end
    local SkillName = self:FindWndTrans(item, "SkillName")
    if SkillName then
        local name
        if skillId then
            local skillRef = gModelHero:GetSkillByStarId(skillId)
            if skillRef then
                name = ccLngText(skillRef.name)
            end
        else
            name = ccClientText(10149)
        end
        self:SetWndText(SkillName, name)
    end
end

function UINewSagaInfo:GetOptStatus(star, maxStar, lv, maxLevel, needLv, needStar)
    local optType = 0
    if star == maxStar then
        if lv == maxLevel then
            -- 满星满等级
            optType = 1
        else
            -- 满星不满等级,升级/升阶
            if needLv == lv and needStar <= star then
                -- 升阶
                optType = 4
            elseif needLv == lv and needStar > star then
                -- 升星界面
                optType = 3
            else
                -- 升级
                optType = 5
            end
        end
    else
        if lv == maxLevel then
            -- 等级达到最高则切换到升星界面
            optType = 3
        else
            -- 是否可以进阶
            if needLv == lv then
                -- 是否处于升阶状态
                optType = 4
            elseif needLv == lv and needStar > star then
                -- 升星界面
                optType = 3
            else
                -- 升级
                optType = 5
            end
        end
    end
    return optType
end

function UINewSagaInfo:RefreshAttrNoActLink()
    self:RefreshSpiritHeroNotActPageTime()
    self:TimerStop(self._trySpiritHeroNoActTimeKey)
    if self._isTryHero then
        self:TimerStart(self._trySpiritHeroNoActTimeKey, 1, false, -1)
    end
end

function UINewSagaInfo:RefreshTryHeroState()
    if not self._id then
        return
    end
    local serverData = gModelHero:GetHeroServerDataById(self._id)
    local endTime = serverData.endTime
    self._heroEndTime = endTime
    self._isTryHero = serverData.isTry
    self._mappingData = gModelResonance:CheckHeroInTargetMappingDict(self._id)
end

function UINewSagaInfo:OnDrawGradeCell(list, item, itemdata, itempos)
    local grade, needLevel, haveData, act = itemdata.grade, itemdata.needLevel, itemdata.haveData, itemdata.act
    if grade == -1 then
        grade = ""
    end
    local NoActImg = self:FindWndTrans(item, "NoActImg")
    if NoActImg then
        local NoGradeLv = self:FindWndTrans(NoActImg, "NoGradeLv")
        if NoGradeLv then
            self:SetWndText(NoGradeLv, grade)
        end
        CS.ShowObject(NoActImg, not act)
    end
    local NoOpenImg = self:FindWndTrans(item, "NoOpenImg")
    if NoOpenImg then
        CS.ShowObject(NoOpenImg, not haveData)
    end
    local GradeLv = self:FindWndTrans(item, "GradeLv")
    if GradeLv then
        self:SetWndText(GradeLv, grade)
        CS.ShowObject(GradeLv, act)
    end
    self:SetWndClick(item, function()
        if haveData then
            self:ShowGradeDescDiv(grade, needLevel)
        end
    end)


end

function UINewSagaInfo:RefreshBtnShow()
    self:RefreshCommonAttrDiv()
    --local show = self:CheckShowRebirthALock()
    --self._btnShowData = {
    --    [self.mBattleRankBtn] = self:CheckShowBattleRankBtn(),
    --    [self.mStoryBtn] = true,
    --    [self.mCommentBtn] = false,
    --    --[self.mRebirthBtn] = show,
    --    [self.mPreviewBtn] = false,
    --    [self.mShareBtn] = true,
    --    [self.mSkinBtn] = self:CheckShowSkinBtn(),
    --    [self.mLockBtn] = show,
    --}
    --
    --self._btnMoreShow = {
    --    [self.mPreviewBtn] = true,
    --    [self.mShareBtn] = true,
    --    [self.mSkinBtn] = true,
    --    [self.mLockBtn] = true,
    --}
    --
    --local showCnt = 0
    --for k, v in pairs(self._btnShowData) do
    --    local btn = k
    --    local show = v
    --    if not self._showMoreBtn and self._btnMoreShow[btn] then
    --        show = false
    --    end
    --    if show then
    --        showCnt = showCnt + 1
    --    end
    --
    --    CS.ShowObject(btn, show)
    --end

    --local viewLength = showCnt * 52 + (showCnt - 1) * 13.4 + 15
    --
    --local max = 460
    --viewLength = math.min(max, viewLength)
    --local bgLength = viewLength + 40
    --LxUiHelper.SetSizeWithCurAnchor(self.mHurdleBg, 1, bgLength)
    --LxUiHelper.SetSizeWithCurAnchor(self.mHurdleView, 1, viewLength)
    --
    --local scrollrect = self.mHurdleView:GetComponent(typeScrollRect)
    --scrollrect.enabled = self._showMoreBtn
end

function UINewSagaInfo:InitEffList()
    local list = {
        self.mTypeActivityEff1, self.mTypeActivityEff2, self.mTypeActivityEff3, self.mTypeActivityEff4,
    }
    local key
    for i, v in ipairs(list) do
        key = v:GetInstanceID()
        self:CreateWndEffect(v, "ui_fx_taozhuanglianxian", key, 100, false, false, 23)
    end
    self:CreateWndEffect(self.mTypeAllActivityEffRoot, "ui_fx_taozhuanglianxian_02", "ui_fx_taozhuanglianxian_02", 100, false, false, 24)
end

function UINewSagaInfo:RefreshGolemEff()
    local isOpen = gModelGolem:CheckGolemIsOpen()
    local show = false --isOpen and self:GetHeroGolemIsOpen() and not gModelGuide:IsGuideFinished(16201)
    if show then
        self:CreateWndEffect(self.mGolemBtn, 'fx_ui_shou_2', "golemEffect", 100, false, false, 22)
    else
        self:DestroyWndEffectByKey("golemEffect")
    end
end

function UINewSagaInfo:RefreshSpiritHeroNotActPageTime()
    local transRoot
    if self._btnIndex == UINewSagaInfo.BTN_TYPE_ATTR then
        transRoot = self.mSpecialAttrTimeTxt
    elseif self._btnIndex == UINewSagaInfo.BTN_TYPE_STAR then
        transRoot = self.mSpecialStarTimeTxt
    end
    local timeValue = self._heroEndTime - GetTimestamp()
    if timeValue < 0 then
        self:SetWndText(transRoot, "")
        self:TimerStop(self._trySpiritHeroNoActTimeKey)
        return
    end
    local timeStr = LUtil.FormatTimespanToMin2(timeValue)
    timeStr = string.replace(ccClientText(31207), timeStr)
    self:SetWndText(transRoot, timeStr)
end

function UINewSagaInfo:SetAwakenPageShow(showType)
    if showType == self._curAwakenShowType then
        return
    end

    self._curAwakenShowType = showType
    self:RefreshPage()
end
function UINewSagaInfo:UpdatePetLinkRed()
    self.petLinkRed = gModelPet:HeroLinkPetRedById(self._id)
    local petRedpoint = CS.FindTrans(self._tabList[UINewSagaInfo.BTN_TYPE_PET], "redPoint")
    CS.ShowObject(petRedpoint, self.petLinkRed)
    self:SetRed(self.mPetAutoBtn, self.petLinkRed)
end

function UINewSagaInfo:OpenHeroSkin()
    local para = {
        refId = self._refId,
        id = self._id,
        --curHeroIndex = self._heroIndex,
        career = self._career,
        race = self._race,
        func = function(heroId)
            if not self:IsWndValid() then
                return
            end
            local index = self:GetHeroPosById(heroId)
            self:RefreshHeroByIndex(index)
        end
    }
    gModelGeneral:OpenHeroSkin(para)
end

function UINewSagaInfo:RefreshGolemBtn()
    local showLockTxt = false
    local heroStruct = gModelHero:GetHeroById(self._id)
    local showGolemBtn = self:GetHeroGolemIsOpen() and gModelGolem:CheckHeroIsWearByHeroStruct(heroStruct)
    local isOpen, isShow = gModelGolem:CheckGolemIsOpen()
    local showRedpoint = false
    if isOpen then
        showRedpoint = gModelGolem:CheckHeroGolemStatusByHeroStruct(heroStruct)
    else
        showLockTxt = true
        self:SetWndText(self.mGolemLockTxt, ccClientText(26656))
    end
    CS.ShowObject(self.mGolemRedPoint, showRedpoint)
    CS.ShowObject(self.mGolemLockTxt, showLockTxt)
    CS.ShowObject(self.mGolemBtn, showGolemBtn and (isShow or isOpen))
    CS.ShowObject(self.mGolemDiv, showGolemBtn and (isShow or isOpen))
    self:RefreshTopLeftList()

    self:RefreshGolemEff()
end

function UINewSagaInfo:CreateStarPageStarList(trans, star, starImg)
    local key = trans:GetInstanceID()
    local list = {}
    for i = 1, star do
        table.insert(list, { img = starImg })
    end
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans, list, function(...)
            self:OnDrawStarPageStarCell(...)
        end)
    end
end

function UINewSagaInfo:OnHeroTreePointActiveResp(pb)
    gModelHero:ClearUpLvTreeSelHeroList()
    self:RefreshAwakenPage()
end

function UINewSagaInfo:OnDrawAttrCell(list, item, itemdata, itempos)
    local AttrIcon = self:FindWndTrans(item, "AttrIcon")
    local AttrName = self:FindWndTrans(item, "AttrName")
    local AttrValue = self:FindWndTrans(item, "AttrValue")
    local refId, value = itemdata.refId, itemdata.value
    if AttrIcon then
        local icon = gModelHero:GetAttributeIconById(refId)
        self:SetWndEasyImage(AttrIcon, icon, function()
            CS.ShowObject(AttrIcon, true)
        end)
    end
    if AttrName then
        local name = gModelHero:GetAttributeNameById(refId)
        self:SetWndText(AttrName, name)
    end
    if AttrValue then
        local val = gModelHero:GetAttributeValueNoNameByIdAndVal(refId, 1, value)
        self:SetWndText(AttrValue, val)
    end
end

function UINewSagaInfo:ChangeShowMaxBtnList(showMax)
    --local showBtnList = {self.mShareBtn,self.mCommentBtn,self.mLockBtn,self.mRebirthBtn}
    self._showMoreBtn = showMax
    --local showBtnList = {self.mShareBtn,self.mPreviewBtn}
    --if self._showSkinBtn then
    --	table.insert(showBtnList,self.mSkinBtn)
    --end
    --if not self._isTryHero then
    --	table.insert(showBtnList,self.mLockBtn)
    --end
    --
    --for i,v in ipairs(showBtnList) do
    --	CS.ShowObject(v,showMax)
    --end

    self:RefreshBtnShow()

    CS.ShowObject(self.mMinArrowBtn, not showMax)
    CS.ShowObject(self.mMaxArrowBtn, showMax)

    local content = self:FindWndTrans(self.mHurdleView, "content")
    if self._showMoreBtn then
        content.localPosition = Vector3(0, 0, 0)
    else
        content.localPosition = Vector3(0, -8.1, 0)
    end
    CS.ShowObject(content, false)
    CS.ShowObject(content, true)
end

function UINewSagaInfo:ShowGradeDescDiv(grade, needLevel)
    CS.ShowObject(self.mGradeDescMask, true)
    local canvasRect = LGameUI.GetUICanvasRoot()
    --local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect,self.mGradeDescDiv)
    --self.mGradeDescDiv.localPosition = targetPos - Vector3.New(0,0,0)
    local str = string.replace(ccClientText(20115), grade)
    self:SetWndText(self.mCurGradeDesc, str)
    if needLevel ~= -1 then
        str = string.replace(ccClientText(20116), needLevel, grade + 1)
    else
        str = ccClientText(20122)
    end
    self:SetWndText(self.mYaoqiuDesc, str)
end
------------------------------------------------------------------
return UINewSagaInfo