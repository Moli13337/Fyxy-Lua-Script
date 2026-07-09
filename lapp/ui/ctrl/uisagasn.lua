---
--- Created by Administrator.
--- DateTime: 2023/10/27 17:40:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaSn:LWnd
local UISagaSn = LxWndClass("UISagaSn", LWnd)

local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
local Time = Time
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
---@type LUIDrawingCtrl
local LUIDrawingCtrl = LxRequire("LApp.UI.Display.LUIDrawingCtrl")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaSn:UISagaSn()
    ---@type table<string,LUIHeroObject>
    self._uiHeroObjList = nil            -- spine列表
    self._uiHeroLiHuiList = nil        -- 立绘列表
    ---@type LUIHeroObject
    self._curUIHeroObj = nil            -- 当前spine
    self._curUILiHuiObj = nil            -- 当前立绘
    ---@type LUISkillCtrl
    self._uiSkillCtrl = nil

    ---@type LUIDrawingCtrl
    self._uiDrawingCtrl = nil

    self._loopHeroObjTimerKey = 1119
    self._isUnfold = true--是否展开折叠
    self.tweenTime = 0.3
    self._autoPlayAni = "autoPlayAni"
    self._heroImgFrameDefaultPath = "public_frame_4_1"
    self._heroImgFrameEffName = "Shiguangyiguixuanzhong"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaSn:OnWndClose()
    if self._uiSkillCtrl then
        self._uiSkillCtrl:Destroy()
        self._uiSkillCtrl = nil
    end
    if self._uiDrawingCtrl then
        self._uiDrawingCtrl:Destroy()
        self._uiDrawingCtrl = nil
    end

    self._curUIHeroObj = nil
    self._curUILiHuiObj = nil

    LUtil.ClearHashTable(self._uiHeroObjList)
    self._uiHeroObjList = nil

    LUtil.ClearHashTable(self._uiHeroLiHuiList)
    self._uiHeroLiHuiList = nil

    self:ClearAllTime()
    if self._func then
        self._func(self._heroId)
    end
    FireEvent(EventNames.ON_CHAT_SHOW, true)
    
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaSn:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaSn:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self:CreateWndEffect(self.mEffect, "fx_shiguangyigui", "fx_shiguangyigui", 100, false, false, 10)

    self._isVie = gLGameLanguage:IsVieVersion()
    FireEvent(EventNames.ON_CHAT_SHOW, false)
    self:SetWndText(self.mWearBtnTxt, ccClientText(17405))
    self:SetWndText(self.mFightPreBtnTxt, ccClientText(17404))
    self:SetWndText(self.mSkinPerBtnTxt, ccClientText(17418))
    self:SetWndText(self.mTxtClose, ccClientText(30205)) --返回
    self:InitEvent()
    self:InitMsg()
    self:OnWndRefresh()
end

function UISagaSn:RefreshCurLHState()
    if not self._selSkinRefId then
        return
    end
    if not self._curUILiHuiObj then
        return
    end
    local bCalm = self:CheckIsPlayCalm()
    local curUILiHuiObj = self._curUILiHuiObj
    if bCalm then
        curUILiHuiObj:PlayCalmAni()
    else
        curUILiHuiObj:PlayIdleAni()
    end
    ---@type LDisplaySpine
    local spineDP = curUILiHuiObj and curUILiHuiObj:GetDisplaySpine()
    if spineDP and spineDP:IsDpValid() then
        --local parseLHKPDrawingAllAge = gModelHeroExtra:GetParseLHDrawingAllAges(self._selSkinRefId)
        local parseLHKPDrawingAllAge = gModelHeroExtra:GetLHDrawingAllAgesDataByPrefabName(spineDP:GetSpineName())
        self:CreateHeroJDImgShow(parseLHKPDrawingAllAge,spineDP:GetDisplayTrans(),bCalm)
    end
    if LOG_INFO_ENABLED then
        if bCalm then
            printInfoNR2("英雄皮肤：", "播放动画：calm")
        else
            printInfoNR2("英雄皮肤：", "播放动画：idle")
        end
    end
end

function UISagaSn:RefreshHeroCVName()
    local cvName = gModelHero:GetHeroCVName(self._selSkinRefId)
    local isShow = not string.isempty(cvName)
    CS.ShowObject(self.mCVNameBg, isShow)
    if not isShow then
        return
    end

    local cvNameStr = string.replace(ccClientText(19786), cvName)
    self:SetWndText(self.mCVNameTxt, cvNameStr)
end

function UISagaSn:OnTimer(key)
    if key == self._loopHeroObjTimerKey then
        local time = Time.unscaledTime
        if self._curUIHeroObj then
            self._curUIHeroObj:OnRun(time)
        end
        if self._uiSkillCtrl then
            self:TimerStop(self._autoPlayAni)
            self._uiSkillCtrl:OnRun(time)
            local isWait = self._uiSkillCtrl._isWait
            if not isWait then
                self._uiSkillCtrl:Destroy()
                self._uiSkillCtrl = nil
                self:AutoPlayAni()
            end
        end
    elseif key == self._autoPlayAni then
        self:OnClickHeroSpine(self._curUIHeroObj)
    end
end

function UISagaSn:SetSkinItem()
    for k, v in ipairs(self._skinItemData) do
        local itemTran = self._skinTran[k]

        --
        local isShow = true
        if v.itemDataPosIndex == 1 or v.itemDataPosIndex == self._maxItemCount then
            isShow = false
        else
            if v.itemDataIndex <= 0 or v.itemDataIndex > self._dataLen then
                isShow = false
            end
        end
        local data = self._skinData[v.itemDataIndex]
        --获取数据
        if data then
            self:OnDrawSkinCell(nil, itemTran, data, v.itemDataTranIndex)
            --超出数据也不显示
            CS.ShowObject(itemTran, isShow)
        end
    end
end

--- 弃用，改成统一显示
function UISagaSn:GetHeroSkinList1()
    local list = {}

    if self._dataList then
        for i, v in ipairs(self._dataList) do
            local refId = v.refId
            local data = table.clone(v)
            local serverData = self._hasSkin[refId]
            if serverData then
                data = table.clone(serverData)
            end
            table.insert(list, data)
        end
    else
        local skinRefIdList = self._skinRefIdList
        for i, v in ipairs(skinRefIdList) do
            local refId = v.refId
            local data
            local serverData = self._hasSkin[refId]
            if serverData then
                data = table.clone(serverData)
            else
                if self._skinRefId then
                    serverData = gModelHero:GetHeroSkinInfoByRefId(refId)
                    if not serverData then
                        serverData = {
                            refId = refId,
                            endTime = -1,
                        }
                    end
                    data = table.clone(serverData)
                    data.isPre = true
                else
                    data = { refId = refId }
                end
            end
            table.insert(list, data)
        end
    end
    self._dataList = list

    if not self._init then
        self._init = true
        if not self._preShowInitSkin then

            --- 已装备皮肤——可解锁皮肤——已解锁皮肤——未解锁皮肤
            table.sort(list, function(skin1, skin2)
                local skinRefId1, skinRefId2 = skin1.refId, skin2.refId
                local endTime1, endTime2 = skin1.endTime, skin2.endTime
                if skinRefId1 == self._wearSkin then
                    return true
                elseif skinRefId2 == self._wearSkin then
                    return false
                else

                    --这里判断下 1 或者2 的 是否有
                    local skins1 = gModelHero:GetPolymorphism(skinRefId1)

                    if skins1 then
                        for k, v in ipairs(skins1) do
                            if v.refId == self._wearSkin then
                                return true
                            end
                        end
                    end

                    local skins2 = gModelHero:GetPolymorphism(skinRefId2)

                    if skins2 then
                        for k, v in ipairs(skins2) do
                            if v.refId == self._wearSkin then
                                return false
                            end
                        end
                    end

                    local heroRefId1
                    local effRef1 = gModelHero:GetShowEffectById(skinRefId1)
                    if effRef1 then
                        heroRefId1 = effRef1.heroType
                    end
                    local status1 = gModelHero:CheckOpenSkinItemStatus(skinRefId1, heroRefId1) and self._wearSkin ~= skinRefId1 and 1 or 0
                    local status2 = gModelHero:CheckOpenSkinItemStatus(skinRefId2, heroRefId1) and self._wearSkin ~= skinRefId2 and 1 or 0
                    if status1 ~= status2 then
                        return status1 > status2
                    end
                    if endTime1 and endTime2 then
                        if endTime1 == -1 and endTime2 == -1 then
                            return skinRefId1 < skinRefId2
                        elseif endTime1 == -1 then
                            return true
                        elseif endTime2 == -1 then
                            return false
                        else
                            return skinRefId1 < skinRefId2
                        end
                    else
                        if endTime1 then
                            return true
                        elseif endTime2 then
                            return false
                        else
                            return skinRefId1 < skinRefId2
                        end
                    end
                end
            end)
        end
    end

    --[[
    --- http://192.168.16.2:3002/issues/1168
    2. 皮肤道具->【预览】打开的界面中（UISagaSn）
    --# 有多形态的，把多形态也显示进去（是否置灰，根据是否激活显示）
    --# 若未获得英雄，基础形态置灰显示；若获得英雄正常显示
    --# 若未激活皮肤，皮肤置灰显示；若激活皮肤正常显示]]
    --if not self._isPre then
    --这里插入数据的部分
    local templist = table.clone(list)
    --  计算插入位置的偏移值
    local offsetPos = 1

    for k, data in ipairs(list) do
        --这里判断下 是否要插入数据
        local skins = gModelHero:GetPolymorphism(data.refId)

        if skins then
            for j, skin in ipairs(skins) do
                local skindataRefId = skin.refId

                local skindata = { refId = skin.refId }

                local serverData = self._hasSkin[skindataRefId]

                if serverData then
                    skindata = table.clone(serverData)
                end
                if skindata then
                    table.insert(templist, k + offsetPos, skindata)

                    offsetPos = offsetPos + 1
                end
            end
        end

    end
    list = templist

    --end
end

function UISagaSn:MoveSkinTran(index)
    if self._curSelectIndex == index then
        return
    end

    if self._isMoveTween then
        return
    end

    self._curSelectIndex = index

    local isNotTween = false
    local curSelectPosIndex = self._skinItemData[index].itemDataPosIndex

    local moveIndex = self._midPosIndex - curSelectPosIndex

    if moveIndex < 0 then
        self:MoveLeft(-moveIndex, isNotTween)
    else
        self:MoveRight(moveIndex, isNotTween)
    end


end

function UISagaSn:GetHeroSkinList()
    local list = {}
    local heroRefId = self._refId
    if heroRefId and heroRefId > 0 then
        --- 原皮
        table.insert(list, {
            refId = heroRefId,
            endTime = -1,
        })
        local skinRefId = self._skinRefId
        local isPre = self._isPre
        local skins = gModelHero:GetPolymorphism(heroRefId)
        if skins and #skins > 0 then
            for i, v in ipairs(skins) do
                local serverData = self._hasSkin[v.refId]
                if serverData then
                    table.insert(list, serverData)
                else
                    if self:CheckIsHasSkinId(v.refId) then
                        table.insert(list, {
                            refId = v.refId,
                            isPre = true,
                        })
                    end
                end
            end
        end
        local skinList = gModelHero:GetHeroSkinListByHeroRefId(heroRefId)
        if skinList and #skinList > 0 then
            for i, refId in ipairs(skinList) do
                local serverData = self._hasSkin[refId]
                if serverData then
                    table.insert(list, serverData)
                else
                    if self:CheckIsHasSkinId(refId)then
                        table.insert(list, {
                            refId = refId,
                            isPre = true,
                        })
                    end
                end
            end
        end
    end
    return list
end

function UISagaSn:CheckIsHasSkinId(refId)
    if not gModelHeroExtra:NeedCheckResType() then return true end
    if not self:CheckIsPlayCalm(refId) or (self._isPre and self._skinRefId == refId) then
        return true
    end
    local effectRef = gModelHero:GetShowEffectById(refId)
    if not effectRef then
        return false
    end
    local jumpItemList = string.split(effectRef.jumpItem, "|")
    if jumpItemList and #jumpItemList > 0 then
        for i,v in ipairs(jumpItemList) do
            local haveNum = gModelItem:GetNumByRefId(checknumber(v))
            if haveNum and haveNum > 0 then
                return true
            end
        end
    end
    return false
end

------------------------------------------------------------------
--- 定时器相关
------------------------------------------------------------------
function UISagaSn:CreateTimer(refId, endTime, trans)
    self:SetTimeStr(refId, endTime, trans)
    self:ClearTimer(refId)
    self._timerList[refId] = LxTimer.LoopTimeCall(function()
        self:SetTimeStr(refId, endTime, trans)
    end, 1, false, -1)
end

function UISagaSn:StartHeroObjRunTimer()
    if self:IsTimerExist(self._loopHeroObjTimerKey) then
        return
    end
    self:TimerStart(self._loopHeroObjTimerKey, 0, false, -1)
end

function UISagaSn:GetTimeStr(times)
    local str
    if times > 86400 then
        local day = math.floor(times / 86400)
        local hour = math.floor(times / 3600) % 24
        str = day .. ccClientText(10304) .. hour .. ccClientText(10305)
    elseif times > 3600 then
        local hour = math.floor(times / 3600)
        local min = math.floor(times / 60) % 60
        str = hour .. ccClientText(10305) .. min .. ccClientText(10306)
    else
        local min = math.floor(times / 60)
        local sec = math.floor(times) % 60
        str = min .. ccClientText(10306) .. sec .. ccClientText(10355)
    end
    return str
end

function UISagaSn:GetHistory()
    local list = LWnd.GetHistory(self)
    local wndArgList = list.wndArgList
    wndArgList.id = self._heroId
    wndArgList.func = self._func
    wndArgList.skinRefId = self._skinRefId
    wndArgList.preview = self._isPre
    wndArgList.curHeroIndex = self._curHeroIndex
    wndArgList.refId = self._refId
    return list
end

function UISagaSn:CreateSpine(prefabName, star, effId)
    --if not prefabName then
    --    return
    --end
    --local uiHeroObjList = self._uiHeroObjList
    --if not uiHeroObjList then
    --    uiHeroObjList = {}
    --    self._uiHeroObjList = uiHeroObjList
    --end
    --if self._uiSkillCtrl then
    --    self._uiSkillCtrl:Destroy()
    --    self._uiSkillCtrl = nil
    --end
    --local newUIHeroObj = uiHeroObjList[prefabName]
    --
    --local oldUIHeroObj = self._curUIHeroObj
    --if oldUIHeroObj and newUIHeroObj ~= oldUIHeroObj then
    --    oldUIHeroObj:ShowHero(false)
    --end
    --
    --if not newUIHeroObj then
    --    newUIHeroObj = LUIHeroObject:New(self)
    --    newUIHeroObj:SetRectMatch(true)
    --    uiHeroObjList[prefabName] = newUIHeroObj
    --    self._curUIHeroObj = newUIHeroObj
    --    newUIHeroObj:Create(self.mHeroSpinePos, prefabName, prefabName)
    --    newUIHeroObj:SetScale(1)
    --
    --    --newUIHeroObj:SetDragFunc(function(...)
    --    --    self:OnDragHeroSpineEnd(...)
    --    --end)
    --    newUIHeroObj:SetHeroData(nil, self._refId, star, effId, true)
    --    newUIHeroObj:ShowHero(true)
    --    newUIHeroObj:StartLoad()
    --
    --    --self._uiHeroCacheCnt = self._uiHeroCacheCnt + 1
    --    --if self._uiHeroCacheCnt > 4 then
    --    --    self:RemoveTheOlderCacheHeroObj(newUIHeroObj)
    --    --end
    --else
    --    self._curUIHeroObj = newUIHeroObj
    --    newUIHeroObj:SetHeroData(nil, self._refId, star, effId, true)
    --    newUIHeroObj:ShowHero(true)
    --end
end

function UISagaSn:SetOtherHeroInfo()
    local refId = self._refId
    local heroRef = gModelHero:GetHeroRef(refId)
    --设置信息
    local careerRef = gModelHero:GetCareerRefByRefId(heroRef.careerType)
    if not careerRef then return end

    local qualityRef = gModelItem:GetQualityRef(heroRef.quality)
    if not qualityRef then return end

    --local effRef = gModelHero:GetHeroEffectRefById(self._heroId)

    local effRef = gModelHero:GetShowEffectById(self._selSkinRefId)
    if not effRef then
        local effId = gModelHero:GetHeroEffectByRefId(refId, self._star)
        effRef = gModelHero:GetShowEffectById(effId)
    end
    if not effRef then return end

    local raceRef = gModelHero:GetHeroRaceRefByRefId(heroRef.raceType)
    if not raceRef then return end

    local nickName = ccLngText(effRef.nickName)
    self:SetWndText(self.mNameTxt, nickName)
    self:SetXUITextTransColor(self.mNameTxt, qualityRef.nameColor)

    self._callHeroDesc = ccLngText(effRef.callDesc)
    self:SetWndText(self.mJobTxt, string.replace("#a1# <color=#139056>[#a2#]</color>", ccLngText(careerRef.name), ccLngText(effRef.location)))

    --- 英雄品质图标
    self:SetWndEasyImage(self.mHeroQualityImg, heroRef.qualityIcon, function()
        CS.ShowObject(self.mHeroQualityImg, true)
    end)

    --- 英雄种族图标
    self:SetWndEasyImage(self.mHeroRaceImg, raceRef.icon)

    --小人信息
    --local prefabname = effRef.prefabName
    --local effId = effRef.refId
    --self:CreateSpine(prefabname, star, effId)   --
    CS.ShowObject(self.mHeroSpinePos,false)--
end

function UISagaSn:CheckIsPlayCalm(selSkinRefId)
    --- 2024/6/20：http://192.168.16.2:3002/issues/753
    --return false
    selSkinRefId = selSkinRefId or self._selSkinRefId
    local bCalm = false
    if self._isFromBook then
        bCalm = gModelHeroExtra:CheckBookIsCalm(selSkinRefId)
    else
        if not self._hasSkin[selSkinRefId] then
            if self._isPre then
                if not gModelHero:GetHeroSkinInfoByRefId(selSkinRefId) then
                    bCalm = true
                end
            else
                if gModelHero:GetOriginId(selSkinRefId) then
                    -- 是形态的
                    bCalm = true
                elseif gModelHero:CheckHeroRefIdHasSkinId(selSkinRefId) then
                    -- 有这个皮肤且未解锁
                    bCalm = true
                elseif not gModelHeroBook:FindHeroInfoStatusByHeroRefId(selSkinRefId) then
                    --- 未获得英雄
                    bCalm = true
                end
            end
        end
    end
    return bCalm
end

function UISagaSn:SetSibling()
    local itemTran = self._skinTran[self._curSelectIndex]

    itemTran:SetSiblingIndex(self._maxItemCount)
end

function UISagaSn:ChangeBg(refId, init)

    if self._effectRefIdMapItempos then
        local itempos = self._effectRefIdMapItempos[refId]

        if itempos and itempos ~= self._curSelectIndex then
            self:MoveSkinTran(itempos)
        end
    end

    self._selSkinRefId = refId
    local effectRef = gModelHero:GetShowEffectById(self._selSkinRefId)
    if not effectRef then
        return
    end
    local heroBg = effectRef.skinBg
    if string.isempty(effectRef.skinBg) then
        heroBg = effectRef.heroBg
    end
    self:SetWndEasyImage(self.mHeroBg, heroBg, function()
        CS.ShowObject(self.mHeroBg, true)
    end)

    local previewReport = effectRef.previewReport
    self._previewReport = previewReport
    printInfoNR("==== 战报id = " .. previewReport .. ",皮肤refId = " .. refId .. ",预制体名字 = " .. effectRef.prefabName)
    --CS.ShowObject(self.mFightPreBtn, previewReport ~= 0)
    CS.ShowObject(self.mFightPreBtn, false)

    self:RefreshUpstarInfo(refId)

    self:TimerStop(self._autoPlayAni)
    self:CreateHeroSpine()
    self:CreateLiHui()
    if not init then
        for k, v in pairs(self._selImgList) do
            local show = false
            if k == refId then
                show = true
            end
            CS.ShowObject(v, show)
        end
    end
    self:ChangeBtnTxt()
    self:RefreshHeroCVName()
end

function UISagaSn:RefreshUpstarInfo(SkinRefId)
    local skinEndTime = gModelHero:CheckHeroHadSkin(SkinRefId) --检测已激活
    local hadSkin = skinEndTime and skinEndTime == "-1"
    local skinInfo = {}
    local Comsume = {}
    local showUpStarComsu = true
    local starRefId = 0
    if hadSkin then
        skinInfo = gModelHero:GetHeroSkinInfoByRefId(SkinRefId)
        starRefId = skinInfo.starRefId
    else
        skinInfo = gModelSkinBook:GetSkinUpStarInfoBySkinRefId(SkinRefId)
        starRefId = skinInfo.RefId
    end
    if starRefId ~= nil and starRefId > 0 then
        Comsume = gModelSkinBook:GetSkinUpStarComsumeByRefId(starRefId)
        local UpStarCfg = gModelSkinBook:GetSkinUpStarConfig(starRefId)
        local attr = UpStarCfg.Attr
        local attrAll = UpStarCfg.AttrAll
        local isEmptyStr = string.isempty(attr)
        local isEmptyAllStr = string.isempty(attrAll)
        local allEmpty = isEmptyStr and isEmptyAllStr
        local allHave = (not isEmptyStr) and (not isEmptyAllStr)
        local isMaxLevel = true
        local curComsume = {}
        if Comsume then
            curComsume = Comsume[1]
            isMaxLevel = false
        end
        showUpStarComsu = not isMaxLevel
        local str = ""
        local showUpIcon = false
        if not isMaxLevel then
            local haveNum = gModelItem:GetNumByRefId(ModelItem.ITEM_SKIN_DEBRIS)
            if haveNum < curComsume.itemNum then
                str = "<color=#ff7676>"..haveNum.."/"..curComsume.itemNum.."</color>"
            else
                str = haveNum.."/"..curComsume.itemNum
                showUpIcon = true
            end
            self:SetWndText(self.mSkinPieceStr, str)
        end
        CS.ShowObject(self.mUpStarIcon, not isMaxLevel and showUpIcon)
        if isMaxLevel then
            self:SetWndText(self.mUpStarBtnTxt, ccClientText(41064))
        else
            self:SetWndText(self.mUpStarBtnTxt, ccClientText(10001))
        end
        local btnImgPath = isMaxLevel and "public_btn_ash_8_1" or "public_btn_3_2"
        self:SetWndEasyImage(self.mUpStarBtn, btnImgPath)

        --显示一条则显示底下一条的判断
        if allHave then
            self:InitAttr(attr,false,starRefId)
            self:InitAttr(attrAll, true,starRefId)
        elseif not isEmptyStr then
            self:InitAttr(attr,false,starRefId)
        elseif not isEmptyAllStr then
            self:InitAttr(attrAll, true,starRefId)
        end
        local num = gModelPower:GetMainCityPower()
        self._OldPlayerPower = tonumber(num)
        CS.ShowObject(self.mAttrGroup, true)
        CS.ShowObject(self.mAttrBg, not allEmpty)
        CS.ShowObject(self.mAttrAllBg, allHave)
        CS.ShowObject(self.mUpStarBtn, allHave and hadSkin and not self._isPre and self._heroId ~= nil and not self.isFromBook)
        CS.ShowObject(self.mSkinPieceDiv,  hadSkin and showUpStarComsu and not self._isPre and self._heroId ~= nil and not self.isFromBook)
        LayoutRebuilder.ForceRebuildLayoutImmediate(self.mSkinPieceDiv)
        if not self._isUnfold then
            self:OnFoldOrUnfold()
        end
    else
        CS.ShowObject(self.mAttrGroup, false)
        CS.ShowObject(self.mSkinPieceDiv,  false)
        CS.ShowObject(self.mUpStarBtn, false)
    end
end


function UISagaSn:OnWndRefresh()
    if self._uiList then
        local uiList = self._uiList:GetList()
        if uiList then
            uiList:RemoveAll()
        end
        self:WndRemoveScrllByKey("skinList")
        self._uiList = nil
    end

    self:InitData()

    local showCutBtn = self._curHeroIndex ~= nil
    self._showCutBtn = showCutBtn

    self:Refresh()
end

function UISagaSn:Refresh(refreshList)
    if #self._skinRefIdList <= 0 then
        printInfoNR("============================== 检查配置")
    else
        self:InitHeroSkinList(refreshList)
    end
end

function UISagaSn:ClearTimer(refId)
    local timerList = self._timerList
    local timer = timerList[refId]
    if timer then
        LxTimer.LoopTimeStop(timer)
        timerList[refId] = nil
    end
end

function UISagaSn:AutoPlayAni()
    local skinAutoPlayAniTime = gModelHero:GeConfigByKey("skinAutoPlayAniTime")
    if skinAutoPlayAniTime == nil then
        skinAutoPlayAniTime = 2
    end
    if self:IsTimerExist(self._autoPlayAni) then
        return
    end
    self:TimerStart(self._autoPlayAni, skinAutoPlayAniTime, false, -1)
end

function UISagaSn:InitEvent()
    self:SetWndClick(self.mCloseBtn, function()
        if self._backFunc then
            self._backFunc(self._curHeroIndex)
        end
        FireEvent(EventNames.REFRESH_SKIN_INFO)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    
    self:SetWndClick(self.mWearBtn, function()
        local status = self._wearStatus            -- 0:前往获取，1:穿戴，2:穿戴中，3:前往穿戴
        if status == 0 then
            local effectRef = gModelHero:GetShowEffectById(self._selSkinRefId)
            if not effectRef then
                return
            end
            local jumpItemList = string.split(effectRef.jumpItem, "|")
            local firstItemRefId, openItemRefId
            for i, v in ipairs(jumpItemList) do
                local itemRefId = tonumber(v)
                local haveNum = gModelItem:GetNumByRefId(itemRefId)
                if i == 1 and not firstItemRefId then
                    firstItemRefId = itemRefId
                end
                if haveNum > 0 then
                    openItemRefId = itemRefId
                    break
                end
            end
            if openItemRefId then
                local itemRef = gModelItem:GetRefByRefId(openItemRefId)
                if not itemRef then
                    return
                end
                local typeDate = string.split(itemRef.typeDate, "=")
                local skinRefId, heroRefId = tonumber(typeDate[1]), tonumber(typeDate[3])
                local heroEffRef = gModelHero:GetShowEffectById(skinRefId)
                if not heroEffRef then
                    return
                end
                local func = function()
                    gModelHero:SetNeedHeroPowerTips(true, self._heroId)
                    local info = {}
                    table.insert(info, { refId = openItemRefId, num = 1 })
                    gModelItem:OnItemUseReq(info)
                end
                gModelGeneral:OpenUIOrdinTips({ refId = 10011, para = { ccLngText(itemRef.name), gModelHero:GetHeroNameByRefId(heroRefId), ccLngText(heroEffRef.skinName) }, func = func }, true)
            elseif firstItemRefId then
                gModelGeneral:OpenGetWayWnd({ itemId = firstItemRefId, srcWnd = self:GetWndName() }, LGameUI.UI_SORTLAYER_UIUP)
            end

            local star = effectRef.needStar
            if star > 0 then
                GF.ShowMessage(string.replace(ccClientText(17430), star))
            end

        elseif status == 1 then
            gModelHero:OnHeroSkinSelectReq(self._heroId, self._selSkinRefId)
        elseif status == 2 then
            GF.ShowMessage(ccClientText(17409))
        elseif status == 3 then
            self:WndClose()

            gModelFunctionOpen:Jump(10300000)
        end
    end)
    self:SetWndClick(self.mFightPreBtn, function()
        if self._previewReport then

            gModelBattle:OnClickShamBattle(self._previewReport)
        end
    end)
    self:SetWndClick(self.mSkinPerBtn, function()
        GF.OpenWndTop("UISnAddAttr", { heroRefId = self._refId })
    end)
    self:SetWndClick(self.mLiHuiClick, function()
        GF.OpenWndUp("UISagaLiHuiSow", { selSkinRefId = self._selSkinRefId })
    end)
    self:SetWndClick(self.mBtnHide, function()
        local isHide = self._isHide or false
        CS.ShowObject(self.mUIMag, isHide)
        --CS.ShowObject(self.mHeroSpinePos, isHide)
        CS.ShowObject(self.mNameDiv, isHide)
        CS.ShowObject(self.mEffectPb, isHide)
        CS.ShowObject(self.mHeroPb, isHide)
        self._isHide = not isHide
    end)

    self:SetWndClick(self.mUpStarBtn, function()
        self:OnClickUpStarEvent()
    end)
    self:SetWndClick(self.mBtnFold, function()
        self:OnFoldOrUnfold()
    end)

end

function UISagaSn:OnClickUpStarEvent()
    local skinInfo = gModelHero:GetHeroSkinInfoByRefId(self._selSkinRefId)
    local isMaxLevel = skinInfo and skinInfo.starLevel == 5
    if isMaxLevel then
        GF.ShowMessage(ccClientText(41064))--41064 已满星
        return
    end
    gModelSkinBook:OnSkinUpStarReq(self._selSkinRefId)
end


function UISagaSn:ChangeBtnTxt()
    local wearStatus = 1
    local color = "yellow"
    local btnStr = ccClientText(17405)

    local isShow_2_Txt = false
    if self._skinRefId then
        btnStr = ccClientText(17411)
        wearStatus = 3
    elseif self._selSkinRefId == self._wearSkin then
        btnStr = ccClientText(17409)
        wearStatus = 2
        color = "grey"
    elseif not self._hasSkin[self._selSkinRefId] then
        isShow_2_Txt = true
        btnStr = ccClientText(17410)
        wearStatus = 0
    end
    if wearStatus == 2 then

        self:SetWndEasyImage(self.mWearBtn, "public_btn_ash_8_1")
    else
        self:SetWndEasyImage(self.mWearBtn, "public_btn_3_2")
    end
    CS.ShowObject(self.mWearBtnTxt, not isShow_2_Txt)
    CS.ShowObject(self.mWearBtnTxt_2, isShow_2_Txt)

    self:SetWndText(self.mWearBtnTxt, btnStr)
    self:SetWndText(self.mWearBtnTxt_2, btnStr)
    self._wearStatus = wearStatus
end

function UISagaSn:InitMsg()
    self:WndNetMsgRecv(LProtoIds.HeroSkinSelectResp, function()
        if self._isPre then return end
        self:GetHeroSkinData()
        self:InitHeroSkinList()
        self:RefreshCurLHState()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroSkinUseResp, function(pb, ret)
        if self._isPre then
            return
        end
        if pb.shinId == self._selSkinRefId then
            gModelHero:OnHeroSkinSelectReq(self._heroId, self._selSkinRefId)
        end
        self:GetHeroSkinData()
        self:InitHeroSkinList()
    end)
    self:WndNetMsgRecv(LProtoIds.RefreshDataResp, function()
        if self._isPre then
            return
        end
        self:GetHeroSkinData()
        self:InitHeroSkinList()
    end)

    self:WndNetMsgRecv(LProtoIds.HeroSkinUpStarResp, function(pb)
        self:OnHeroSkinUpStarResp(pb)
    end)

    self:WndNetMsgRecv(LProtoIds.ItemChangeResp, function()
        self:RefreshUpstarInfo(self._selSkinRefId)
    end)
end

function UISagaSn:OnHeroSkinUpStarResp(pb)
    self._starRefId = pb.skin.starRefId
    GF.OpenWnd("UISkinUpOpt", {
        heroRefId = self._heroId,
        starRefId = self._starRefId,
        heroOldPower = self.heroOldPower,
        playerPower = self._OldPlayerPower,
    })
    self:InitHeroSkinList()
end

function UISagaSn:OnHeroListResp()
    GF.OpenWnd("UISkinUpOpt", {
        heroRefId = self._heroId,
        starRefId = self._SelSkinInfo.starRefId,
        heroPowerStr = self.heroOldPower,
        playerPower = self._oldPower,
    })
    --self:GetHeroSkinData()
    self:InitHeroSkinList()
end

function UISagaSn:InitHeroSkinList(refreshList)
    if refreshList then
        self:ClearAllTime()
    end
    local list = self:GetHeroSkinList()
    self._selImgList = {}

    if not self._initSkinListRoot then
        self._initSkinListRoot = true
        self:SetSkinListData(list)

        self:InitCommonData()
        self:InitCommon()
        self:SetSkinItem()

        local showSkin = self._gotoSkin or self._wearSkin
        self:ChangeBg(showSkin)
    else
        --这里刷新下面板的数据就可以
        self:SetSkinListData(list)
        self:SetSkinItem()
        local showSkin = self._selSkinRefId or self._wearSkin
        --self:ChangeBg(showSkin)
        self:RefreshUpstarInfo(showSkin)
    end
end

function UISagaSn:InitData()
    local refId = self:GetWndArg("refId")
    local star = self:GetWndArg("star")
    self._heroId = self:GetWndArg("id")
    self._func = self:GetWndArg("func")
    self._isFromBook = self:GetWndArg("isFromBook")
    self._init = false
    self._skinRefId = self:GetWndArg("skinRefId")            -- 用于做表现用
    self._isPre = self:GetWndArg("preview")                    -- 预览
    --self._curHeroIndex = self:GetWndArg("curHeroIndex")
    self._backFunc = self:GetWndArg("backFunc")
    local skinRefIds = self:GetWndArg("skinRefIds")            -- 皮肤id列表
    self._gotoSkin = self:GetWndArg("gotoSkin")
    self._hideActivityImg = self:GetWndArg("hideActivityImg") --隐藏激活图标和黑色遮罩
    self._selSkinRefId = nil
    self._wearStatus = 1            -- 0:前往获取，1:穿戴，2:穿戴中，3:前往穿戴
    self._spineKey = nil            -- 战斗小人key
    self._lihuiKey = nil            -- 立绘key
    self._timerList = {}
    self._selImgList = {}
    self._wearSkin = nil
    self._skinRefIdList = {}
    self._hasSkin = {}
    self._dataList = nil
    local num = gModelPower:GetMainCityPower()
    self._OldPlayerPower = tonumber(num)
    self:RefreshCutHeroInfo()

    if skinRefIds then
        self._skinRefId = skinRefIds[1]
    end

    if not self._skinRefId then
        self._refId = refId
        self._star = star
        self:RefreshHeroIdInfo()
    else
        self._wearSkin = self._skinRefId
        local effectRef = gModelHero:GetShowEffectById(self._skinRefId)
        refId = effectRef.heroType
        local ref = gModelHero:GetHeroRef(refId)
        self._refId = refId
        self._star = ref.initStar
        local preShowInitSkin = gModelHero:GeConfigByKey("preShowInitSkin")
        if preShowInitSkin == nil then
            preShowInitSkin = 1
        end
        local showpreShowInitSkin = preShowInitSkin == 1
        if showpreShowInitSkin then
            table.insert(self._skinRefIdList, { refId = refId })
        end
        self._preShowInitSkin = showpreShowInitSkin
        if skinRefIds then
            for i, v in ipairs(skinRefIds) do
                table.insert(self._skinRefIdList, { refId = v })
            end
        else
            table.insert(self._skinRefIdList, { refId = self._skinRefId })
        end

        local skins = gModelHero:GetPolymorphism(refId)
        if skins and #skins > 0 then
            if gModelHeroBook:FindHeroInfoStatusByHeroRefId(refId) then
                self._hasSkin[refId] = { refId = refId, endTime = "-1" }            -- 默认皮肤
            end
            for i, v in ipairs(skins) do
                local tempData = gModelHero:GetHeroSkinInfoByRefId(v.refId)
                if tempData then
                    self._hasSkin[v.refId] = tempData
                end
            end
        end

        self:ChangeBtnTxt()
        if self._isPre then
            CS.ShowObject(self.mWearBtn, false)
            CS.ShowObject(self.mFightPreBtn, false)
            CS.ShowObject(self.mUpStarBtn, false)
            CS.ShowObject(self.mSkinPieceDiv, false)
        else
            CS.ShowObject(self.mWearBtn, true)
            CS.ShowObject(self.mFightPreBtn, false)
        end
    end

    self:SetOtherHeroInfo()
    local iconPath = gModelItem:GetItemIconByRefId(ModelItem.ITEM_SKIN_DEBRIS)
    self:SetWndEasyImage(self.mSkinPieceIcon, iconPath)
end

function UISagaSn:RefreshCutHeroInfo()
    local career = self:GetWndArg("career")
    local race = self:GetWndArg("race")
    if not career or not race then
        return
    end
    self._cutHeroList = gModelHero:FilterSkinHeroList(career, race)
    self._curHeroIndex = 1
    for k, v in ipairs(self._cutHeroList) do
        if self._heroId == v.id then
            self._curHeroIndex = k
        end
    end
end

function UISagaSn:RefreshHeroIdInfo()
    self._skinRefIdList = {}
    local refId = self._refId
    local star = self._star
    local heroRef = gModelHero:GetHeroRef(refId)
    if not star then

        star = heroRef.initStar
    end
    self._refId = refId
    self._star = star

    local starRef = gModelHero:GetHeroStarRef(refId, nil, star)
    local skinEffectId = starRef.skinEffectId or ""
    skinEffectId = string.split(skinEffectId, "|")
    table.insert(self._skinRefIdList, { refId = tonumber(starRef.effectId) })
    for i, v in ipairs(skinEffectId) do
        table.insert(self._skinRefIdList, { refId = tonumber(v) })
    end

    self:GetHeroSkinData()
    CS.ShowObject(self.mWearBtn, self._heroId ~= nil and not self.isFromBook)


end


function UISagaSn:InitAttr(attr, isAll,starRefId)
    local skinEndTime = gModelHero:CheckHeroHadSkin(self._selSkinRefId) --检测已激活
    local hadSkin = skinEndTime and skinEndTime == "-1"
    local UpStarRefId = starRefId
    local addStrType = ""
    if hadSkin then
        addStrType = ccClientText(20108)
        UpStarRefId = starRefId + 1
    else
        addStrType = ccClientText(46122)
    end
    local CurAttrInfo = gModelSkinBook:GetSkinUpStarConfig(starRefId)
    local upStarInfo = gModelSkinBook:GetSkinUpStarConfig(UpStarRefId)
    local isMaxLevel = true
    if CurAttrInfo and CurAttrInfo.lv < 5 then  --未满级
        isMaxLevel = false
    end
    local UpStarStr = ""
    --这里加多个值就可以 导出先
    local str = isAll and ccClientText(17429) or ccClientText(17403)
    str = string.replace(str, "")
    local constAttrStr = ""
    if isMaxLevel then
        constAttrStr = "%s <color=#139057>+%s </color>"
    else
        constAttrStr = "%s <color=#139057>+%s </color>".."(".. addStrType.." <color=#139057>+%s </color>" ..")"
    end

    local AttrTransRoot = {}
    local emptyStrArr = {
        [1] = "",
        [2] = "",
        [3] = "",
    }
    if isAll then
        self:SetWndText(self.mAttrTittle2, str)
        AttrTransRoot = self.mAttrAllBg
        UpStarStr = isMaxLevel and emptyStrArr or upStarInfo.AttrAll
    else
        self:SetWndText(self.mAttrTittle1, str)
        AttrTransRoot = self.mAttrBg
        UpStarStr = isMaxLevel and emptyStrArr or upStarInfo.Attr
    end
    local StrArr = {}
    local attrs = LxDataHelper.ParseAttrList(attr)
    for i, v in ipairs(attrs) do
        local attrRefId = v.refId
        local attrName = gModelHero:GetAttributeNameById(attrRefId)
        local attrStr = ""
        if hadSkin then
            attrStr = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId, v.type, v.value)
        else
            attrStr = "0"
        end
        table.insert(StrArr,{
            attrName = attrName,
            attrStr  = attrStr
        })
    end
    UpStarStr = isMaxLevel and emptyStrArr or LxDataHelper.ParseAttrList(UpStarStr)
    for i, v in ipairs(UpStarStr) do
        local attrStr = gModelHero:GetAttributeValueNoNameByIdAndVal(v.refId, v.type, v.value)
        local tempStr = string.format(constAttrStr, StrArr[i].attrName,StrArr[i].attrStr,attrStr)
        local txtTrans = self:FindWndTrans(AttrTransRoot,"AttrTxtBg"..i.."/".."AttrTxt"..i)
        self:SetWndText(txtTrans, tempStr)
    end
end

-- 创建立绘
function UISagaSn:CreateLiHui()
    local selSkinRefId = self._selSkinRefId
    local effectRef = gModelHero:GetShowEffectById(selSkinRefId)
    if not effectRef then
        return
    end

    local x, y = gModelHeroBook:GetHeroPosByRefIdAndType(selSkinRefId, "heroDrawingPos2")
    if x and y then
        self.mHeroLiHui.anchoredPosition = Vector3.New(x, y, 0)
        self.mHeroLiHuiEff.anchoredPosition = Vector3.New(x, y, 0)
    end

    if self._uiDrawingCtrl then
        self._uiDrawingCtrl:Destroy()
        self._uiDrawingCtrl = nil
    end

    local uiHeroLiHuiList = self._uiHeroLiHuiList
    if not uiHeroLiHuiList then
        uiHeroLiHuiList = {}
        self._uiHeroLiHuiList = uiHeroLiHuiList
    end
    local heroDrawing = effectRef.heroDrawing

    ---@type LUIHeroObject
    local newUILiHuiObj = uiHeroLiHuiList[heroDrawing]

    local oldUILiHuiObj = self._curUILiHuiObj
    if oldUILiHuiObj then
        if newUILiHuiObj == oldUILiHuiObj then
            self:RefreshCurLHState()
            return
        end
        oldUILiHuiObj:ShowHero(false)
    end

    --local bCalm = self:CheckIsPlayCalm()

    if not newUILiHuiObj then
        newUILiHuiObj = LUIHeroObject:New(self)
        uiHeroLiHuiList[heroDrawing] = newUILiHuiObj

        self._curUILiHuiObj = newUILiHuiObj
        newUILiHuiObj:Create(self.mHeroLiHui, heroDrawing, heroDrawing)
        newUILiHuiObj:SetHeroBgParams({
            effRef = effectRef,
            lihuiBgTrans = self.mHeroLiHuiBg,
            lihuiHdTrans = self.mHeroLiHuiHd,
        })
        newUILiHuiObj:SetRectMatch(true)
        newUILiHuiObj:ShowHero(true)
        newUILiHuiObj:SetLoadedFunction(function()
            self:RefreshCurLHState()
        end)

        --local scale = effectRef.pos2Scale
        local scale = 0
        if scale and scale > 0 then
            newUILiHuiObj:SetScale(scale)
        end

        newUILiHuiObj:StartLoad()
    else
        self._curUILiHuiObj = newUILiHuiObj
        newUILiHuiObj:ShowHero(true)
        self:RefreshCurLHState()
    end
    local uiDrawCtrl = LUIDrawingCtrl:New()
    self._uiDrawingCtrl = uiDrawCtrl
    uiDrawCtrl:SetHeroObject(newUILiHuiObj)
    uiDrawCtrl:SetEffectInfo(self.mHeroLiHuiEff, 0, 3, 100)
    uiDrawCtrl:InitHeroEffectInfo(selSkinRefId)
    --uiDrawCtrl:SetCalmState(bCalm)
    uiDrawCtrl:StartPlay()
end

function UISagaSn:InitCommon()
    -- 设置位置过去
    for k, v in ipairs(self._skinItemData) do
        if v.itemDataPosIndex > 0 then
            local itemTran = self._skinTran[k]
            local posTran = self._skinPosTran[v.itemDataPosIndex]

            itemTran.position = posTran.position
            itemTran.localRotation = posTran.localRotation
        end
    end

    self:SetSibling()
end

function UISagaSn:SetItemPos(moveIndex)
    self._isMoveTween = true
    self:SetItemPosTween(moveIndex)
    self:SetSibling()
end

function UISagaSn:SetItemPosTween(moveIndex)
    local tweenSeq = YXTween.TweenSequenceIns()

    local moveTime = 0.2 + (moveIndex - 1) * 0.1

    for k, v in ipairs(self._skinItemData) do
        local itemTran = self._skinTran[k]
        local posTran = self._skinPosTran[v.itemDataPosIndex]

        if v.isMoveRemote then
            CS.ShowObject(itemTran, false)
        end

        itemTran.localRotation = posTran.localRotation
        local tranMoveTween = itemTran:DOMove(posTran.position, moveTime)

        tweenSeq:Insert(0, tranMoveTween)
    end

    tweenSeq:OnComplete(function()
        self:SetSkinItem()
        self._isMoveTween = false
    end)

    tweenSeq:PlayForward()
end


-- 创建spine
function UISagaSn:CreateHeroSpine()
    local selSkinRefId, refId, star = self._selSkinRefId, self._refId, self._star
    local effectRef = gModelHero:GetShowEffectById(selSkinRefId)
    if not effectRef then
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

    local prefabName = effectRef.prefabName
    local newUIHeroObj = uiHeroObjList[prefabName]
    local oldUIHeroObj = self._curUIHeroObj
    if oldUIHeroObj and newUIHeroObj ~= oldUIHeroObj then
        oldUIHeroObj:ShowHero(false)
        self:SetOtherHeroInfo()
    end

    self:StartHeroObjRunTimer()
    self:AutoPlayAni()
end

function UISagaSn:MoveLeft(moveIndex, isNotTween)
    --位置的左移
    for i = 1, self._maxItemCount do
        local skinItemData = self._skinItemData[i]
        local itemDataPosIndex = skinItemData.itemDataPosIndex
        self._skinItemData[i]. itemDataOldPosIndex = itemDataPosIndex
        local oldItemDataPosIndex = self._skinItemData[i]. itemDataOldPosIndex
        local isMoveRemote = false

        local oldIndexLeft = self._leftPosIndex[itemDataPosIndex]

        itemDataPosIndex = itemDataPosIndex - moveIndex

        if itemDataPosIndex <= 0 then
            itemDataPosIndex = itemDataPosIndex + self._maxItemCount
        end

        local newIndexLeft = self._leftPosIndex[itemDataPosIndex]

        --同左或者同右false
        if (oldIndexLeft and newIndexLeft) or ((not oldIndexLeft) and (not newIndexLeft)) then
        else
            isMoveRemote = true
        end

        --这里判断出于正常的轮转
        local temp_Index = self._midPosIndex - moveIndex
        local temp_1 = self._midPosIndex - temp_Index
        local temp_2 = self._midPosIndex + temp_Index

        if oldItemDataPosIndex > temp_1 and oldItemDataPosIndex <= temp_2 then
            isMoveRemote = false
        end


        --
        self._skinItemData[i].isMoveRemote = isMoveRemote

        self._skinItemData[i].itemDataPosIndex = itemDataPosIndex

        if isMoveRemote then
            --刷新数据索引  拿到中间的数据 算偏移
            local curSelectItem = self._skinItemData[self._curSelectIndex]
            local curSelectItemDataIndex = curSelectItem.itemDataIndex

            --左边偏移使用-
            local offset = itemDataPosIndex - self._midPosIndex

            self._skinItemData[i].itemDataIndex = curSelectItemDataIndex + offset
        end
    end

    self:SetItemPos(moveIndex)
end

function UISagaSn:SetSkinListData(list)
    --数据处理部分
    self._skinData = list
    self._dataLen = #self._skinData
end

function UISagaSn:OnFoldOrUnfold()
    self._isUnfold = not self._isUnfold
    self:SetWndText(self.mTxtIsShow, ccClientText(txtCode))
    if self._isUnfold then
        --显示
        --self:PlayShowTween()
        self:FoldDoTween(true)
    else
        --self:PlayHideTween()
        self:FoldDoTween()
    end
end

function UISagaSn:FoldDoTween(isShow)
    local alpha = isShow and 1 or 0
    local tweenSeq = YXTween.TweenSequenceIns()
    local rotaTween = self.mBtnFoldImg:DOLocalRotate(Vector3.New(0, 0, isShow and -90 or 90), self.tweenTime):SetEase(DG.Tweening.Ease.Linear)
    local AllBgCgTween = self.mAttrBgCg:DOFade(alpha, 0.15):SetEase(DG.Tweening.Ease.Linear)
    tweenSeq:Append(rotaTween)
    tweenSeq:Append(AllBgCgTween)
    tweenSeq:OnComplete(function()
        self._foldTween = nil
    end)
    self._foldTween = tweenSeq
    tweenSeq:PlayForward()
end


function UISagaSn:CutHero(optNum)
    local curHeroIndex = self._curHeroIndex
    if not curHeroIndex then
        return
    end
    local newIndex = curHeroIndex + optNum

    local cnt = #self._cutHeroList
    if newIndex < 1 then
        newIndex = cnt
    elseif newIndex > cnt then
        newIndex = 1
    end

    local heroData = self._cutHeroList[newIndex]
    if not table.isempty(heroData) then
        local id = heroData.id
        self._heroId = id
        self._refId = gModelHero:GetRefIdById(id)
        self._curHeroIndex = newIndex
        self._star = nil
        self._dataList = nil
        self._init = false
        self._selSkinRefId = nil
        self:RefreshHeroIdInfo()
        self:Refresh(true)
    end
end

function UISagaSn:MoveRight(moveIndex, isNotTween)
    for i = 1, self._maxItemCount do
        local skinItemData = self._skinItemData[i]
        local itemDataPosIndex = skinItemData.itemDataPosIndex
        self._skinItemData[i]. itemDataOldPosIndex = itemDataPosIndex
        local oldItemDataPosIndex = self._skinItemData[i]. itemDataOldPosIndex
        local isMoveRemote = false

        local oldIndexLeft = self._leftPosIndex[itemDataPosIndex]

        itemDataPosIndex = itemDataPosIndex + moveIndex

        if itemDataPosIndex > self._maxItemCount then
            itemDataPosIndex = itemDataPosIndex - self._maxItemCount
        end

        local newIndexLeft = self._leftPosIndex[itemDataPosIndex]

        --同左或者同右false
        if (oldIndexLeft and newIndexLeft) or ((not oldIndexLeft) and (not newIndexLeft)) then
        else
            isMoveRemote = true
        end


        --这里判断出于正常的轮转
        local temp_Index = self._midPosIndex - moveIndex
        local temp_1 = self._midPosIndex - temp_Index
        local temp_2 = self._midPosIndex + temp_Index

        if oldItemDataPosIndex >= temp_1 and oldItemDataPosIndex < temp_2 then
            isMoveRemote = false
        end


        --
        self._skinItemData[i].isMoveRemote = isMoveRemote

        self._skinItemData[i].itemDataPosIndex = itemDataPosIndex

        if isMoveRemote then
            --刷新数据索引  拿到中间的数据 算偏移
            local curSelectItem = self._skinItemData[self._curSelectIndex]
            local curSelectItemDataIndex = curSelectItem.itemDataIndex

            --左边偏移使用-
            local offset = itemDataPosIndex - self._midPosIndex

            self._skinItemData[i].itemDataIndex = curSelectItemDataIndex + offset
        end
    end

    self:SetItemPos(moveIndex)
end

function UISagaSn:OnClickHeroSpine(heroObj)
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

    end
end

function UISagaSn:SendThinkingData()

end

--region 列表部分--重置 --------------------------------------------------------------------------------

function UISagaSn:InitCommonData()
    self._skinItemData = {}
    self._skinPosTran = {}
    self._skinTran = {}
    local dataLen = self._dataLen
    local checkIdx = 4
    local subIdx = 3
    if dataLen > checkIdx then
        subIdx = subIdx - (dataLen - checkIdx)
        checkIdx = dataLen
    end
    local tempIdx
    for i = 1, 7 do
        local skinItemData = {}
        --5 6 7  1 2 3 4
        if i <= checkIdx then
            skinItemData.itemDataIndex = i
            skinItemData.itemDataPosIndex = i + subIdx
        else
            skinItemData.itemDataIndex = 0
            skinItemData.itemDataPosIndex = i - checkIdx
        end
        skinItemData.itemDataOldPosIndex = 0
        skinItemData.isMoveRemote = false
        skinItemData.itemDataTranIndex = i  --用来标识是第几个控件的
        table.insert(self._skinItemData, skinItemData)

        --位置控件部分
        local posTranKey = "ItemTemplate_Pos_" .. i
        local posTran = self:FindWndTrans(self.mPosRoot, posTranKey)
        self._skinPosTran[i] = posTran

        --道具控件部分
        local itemTranKey = "ItemTemplate_" .. i
        local itemTran = self:FindWndTrans(self.mSkinRoot, itemTranKey)
        self._skinTran[i] = itemTran

        if skinItemData.itemDataPosIndex < 4 or skinItemData.itemDataPosIndex == 7 or skinItemData.itemDataPosIndex > self._dataLen then
            CS.ShowObject(itemTran, false)
        end
    end

    self._curSelectIndex = 1

    self._maxItemCount = 7

    --记录最左侧的部分
    self._leftPosIndex = { 1, 2, 3 }
    self._midPosIndex = 4
end

function UISagaSn:SetTimeStr(refId, endTime, trans)
    local curTime = GetTimestamp()
    local remainTime = endTime - curTime
    if remainTime < 0 then
        self:ShutdownTime(refId, trans)
    else
        local str = self:GetTimeStr(remainTime)
        self:SetWndText(trans, str)
    end
end

function UISagaSn:ClearAllTime()
    local timerList = self._timerList
    for k, v in pairs(timerList) do
        self:ClearTimer(k)
    end
    self._timerList = {}
end

function UISagaSn:ShutdownTime(refId, trans)
    self:SetWndText(trans, "")

    self:ClearAllTime()
    gModelGeneral:OnRefreshDataReq(ModelGeneral.REFRESHDATA_SKIN, refId)
end

--endregion --------------------------------------------------------------------------------------

function UISagaSn:OnDrawSkinCell(list, item, itemdata, itempos)
    local instanceId = item:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceId)
    if not itemCache then
        itemCache = {
            skinImgTrans = self:FindWndTrans(item, "skinImg"),
            defaultHeroImgFrame = self:FindWndTrans(item, "DefaultHeroImgFrame"),
            heroImgFrame = self:FindWndTrans(item, "HeroImgFrame"),
            qualityIcon = self:FindWndTrans(item, 'QualityIcon'),
            selImgTrans = self:FindWndTrans(item, "selImg"),
            selImgTrans2 = self:FindWndTrans(item, "selImg2"),
            WearImgTrans = self:FindWndTrans(item, "WearImg"),
            NoActivityImgTrans = self:FindWndTrans(item, "NoActivityImg"),
            NeedStar = self:FindWndTrans(item, "NeedStar"),
            SkinTimeTrans = self:FindWndTrans(item, "SkinTime"),
            ImageTrans = self:FindWndTrans(item, "Image"),
            ImageTrans_enus = self:FindWndTrans(item, "Image_enus"),
            BlackBgTrans = self:FindWndTrans(item, "BlackBg"),
            redPointTrans = self:FindWndTrans(item, "redPoint"),
            JDRoot = self:FindWndTrans(item, "JDRoot"),
            StarGroup = self:FindWndTrans(item, "StarGroup"),
        }
        self:SetComponentCache(instanceId,itemCache)
    end
    local skinImgTrans = itemCache.skinImgTrans
    local defaultHeroImgFrame = itemCache.defaultHeroImgFrame
    local heroImgFrame = itemCache.heroImgFrame
    local qualityIcon = itemCache.qualityIcon
    local selImgTrans = itemCache.selImgTrans
    local selImgTrans2 = itemCache.selImgTrans2
    local WearImgTrans = itemCache.WearImgTrans
    local NoActivityImgTrans = itemCache.NoActivityImgTrans
    local NeedStar = itemCache.NeedStar
    local SkinTimeTrans = itemCache.SkinTimeTrans
    local ImageTrans = itemCache.ImageTrans
    local ImageTrans_enus = itemCache.ImageTrans_enus
    local BlackBgTrans = itemCache.BlackBgTrans
    local redPointTrans = itemCache.redPointTrans
    local JDRoot = itemCache.JDRoot
    local StarGroup = itemCache.StarGroup

    local isPre = itemdata.isPre
    local effectRefId = itemdata.refId
    local effectRef = gModelHero:GetShowEffectById(effectRefId)

    local heroImgFramePath = self._heroImgFrameDefaultPath
    local skinQuality = effectRef and effectRef.skinQuality
    if not string.isempty(skinQuality) then
        self:SetWndEasyImage(qualityIcon, skinQuality, function()
            CS.ShowObject(qualityIcon, true)
        end, true)
    else
        CS.ShowObject(qualityIcon, false)
    end

    local isShowDefaultFrameIcon = heroImgFramePath == self._heroImgFrameDefaultPath

    local skinIcon = effectRef.skinIcon
    if not string.isempty(skinIcon) then
        self:SetWndEasyImage(defaultHeroImgFrame, skinIcon, nil, true)

    else

        if LOG_INFO_ENABLED then
            printInfo("skin------not effectRef.skinIcon ", effectRef.refId)
        end
    end

    local kuangTrans = isShowDefaultFrameIcon and defaultHeroImgFrame or heroImgFrame
    CS.ShowObject(defaultHeroImgFrame, isShowDefaultFrameIcon)
    CS.ShowObject(heroImgFrame, not isShowDefaultFrameIcon)

    local endTime = itemdata.endTime
    if ImageTrans then
        local SkinNameTrans
        if self._isEnus then
            CS.ShowObject(ImageTrans, false)
            CS.ShowObject(ImageTrans_enus, true)
            SkinNameTrans = self:FindWndTrans(ImageTrans_enus, "SkinName")
        else
            CS.ShowObject(ImageTrans, true)
            CS.ShowObject(ImageTrans_enus, false)
            SkinNameTrans = self:FindWndTrans(ImageTrans, "SkinName")
        end

        if SkinNameTrans then
            local name = ccLngText(effectRef.skinName)
            self:SetWndText(SkinNameTrans, name)
        end

        if gLGameLanguage:IsVieVersion() then
            self:InitTextLineWithLanguage(SkinNameTrans,0)
            self:InitTextSizeWithLanguage(SkinNameTrans,-2)
            LxUiHelper.SetSizeWithCurAnchor(SkinNameTrans,0,120)
            self:SetAnchorPos(SkinNameTrans,Vector2.New(0,10))
            ImageTrans.pivot = Vector2(0.5, 0)
            LxUiHelper.SetSizeWithCurAnchor(ImageTrans,1,50)
            self:SetAnchorPos(ImageTrans,Vector2.New(0,-100))
            self:SetAnchorPos(SkinNameTrans,Vector2.New(0,0))
        end
    end

    local isShowSel = effectRefId == self._selSkinRefId
    CS.ShowObject(selImgTrans, isShowDefaultFrameIcon and isShowSel)
    CS.ShowObject(selImgTrans2, not isShowDefaultFrameIcon and isShowSel)
    if not isShowDefaultFrameIcon then
        local frameEffKey = self._heroImgFrameEffName .. instanceId
        self:CreateWndSpine(selImgTrans2, self._heroImgFrameEffName, frameEffKey, false, nil)
    end
    local selImageTrans = isShowDefaultFrameIcon and selImgTrans or selImgTrans2
    self._selImgList[effectRefId] = selImageTrans

    local showMask = false
    local ishaveSkin = 0
    --if not self._isFromBook then
    if WearImgTrans then
        local showWearImg = false
        if not self._isFromBook then
            if isPre then
                showWearImg = not isPre and not self._hideActivityImg
            else
                showWearImg = self._wearSkin == effectRefId and not self._hideActivityImg
            end
        end
        CS.ShowObject(WearImgTrans, showWearImg)
    end

    local pastDue = false
    local showNoActImg = false
    if NoActivityImgTrans then
        local showNeedStar = false
        if isPre then
            local skinData = gModelHero:GetHeroSkinInfoByRefId(effectRefId)
            if skinData then
                local numEndTime = tonumber(skinData.endTime)
                if numEndTime ~= -1 then
                    ishaveSkin = numEndTime / 1000
                else
                    ishaveSkin = 1
                end
            end
            showNeedStar = skinData == nil
            pastDue = showNeedStar
            if showNeedStar then
                showMask = true
            end
        else
            if endTime then
                local numEndTime = tonumber(endTime)
                if numEndTime ~= -1 then
                    local skinTime = numEndTime / 1000
                    local curTime = GetTimestamp()
                    if skinTime <= curTime then
                        pastDue = true
                    end
                    ishaveSkin = skinTime
                else
                    ishaveSkin = 1
                end
            else
                pastDue = true
            end
            showNoActImg = pastDue and not self._hideActivityImg
            showNeedStar = showNoActImg
        end
        if effectRef.needStar and effectRef.needStar > 0 then
            self:SetWndText(NeedStar, string.replace(ccClientText(17430), effectRef.needStar))
        else
            self:SetWndText(NeedStar, "")
        end
        CS.ShowObject(NeedStar, showNeedStar)
    end
    CS.ShowObject(NoActivityImgTrans, showNoActImg)

    if redPointTrans then
        local showRedPoint = false
        if not isPre then
            local effRef = gModelHero:GetShowEffectById(effectRefId)
            if effRef then
                local heroRefId = effRef.heroType
                if heroRefId and heroRefId > 0 then
                    showRedPoint = gModelHero:CheckOpenSkinItemStatus(effectRefId, heroRefId) and self._wearSkin ~= effectRefId
                end
            end
        end
        CS.ShowObject(redPointTrans, showRedPoint)
    end

    local showBlack = pastDue and not self._hideActivityImg
    if BlackBgTrans then
        CS.ShowObject(BlackBgTrans, showBlack)
    end
    local starLevel = 0
    local skinData = gModelHero:GetHeroSkinInfoByRefId(effectRefId)
    if not showBlack and skinData then
        if skinData.starRefId ~= 0 then
            starLevel = skinData.starLevel
        end
    end
    for i = 1, 5 do
        local starTrans = self:FindWndTrans(StarGroup, "Star"..i)
        CS.ShowObject(starTrans, starLevel >= i)
    end

    local showJDRoot = false
    CS.ShowObject(JDRoot,showJDRoot)


    if skinImgTrans then
        local iconBig = effectRef.iconBig
        if showBlack then
            iconBig = gModelHeroExtra:GetShieldIconBig(iconBig,effectRef)
        end
        self:SetWndEasyImage(skinImgTrans, iconBig, function()
            CS.ShowObject(skinImgTrans, true)
        end)
    end

    if SkinTimeTrans then
        local timeStr = ""
        if endTime then
            local numEndTime = tonumber(endTime)
            if numEndTime > 0 then
                local skinTime = numEndTime / 1000
                local curTime = GetTimestamp()
                if skinTime > curTime then
                    timeStr = self:GetTimeStr(skinTime - curTime)
                    self:CreateTimer(effectRefId, skinTime, SkinTimeTrans)
                else
                    self:ClearTimer(effectRefId)
                end
            end
        end
        self:SetWndText(SkinTimeTrans, timeStr)
    end
    --end

    if not self._effectRefIdMapItempos then
        self._effectRefIdMapItempos = {}
    end
    self._effectRefIdMapItempos[effectRefId] = itempos
    if skinImgTrans then
        self:SetWndClick(skinImgTrans, function()
            self:MoveSkinTran(itempos)
            self:ChangeBg(effectRefId)
        end)
    end
end

function UISagaSn:GetHeroSkinData()
    local wearSkin, hasSkin
    local serverData = gModelHero:GetHeroServerDataById(self._heroId)
    if serverData then
        local effRef = gModelHero:GetHeroEffectRefById(self._heroId)
        wearSkin = effRef.refId
        local tempTab = gModelHero:GetHeroRefIdSkinListByHeroRefId(self._refId) or {}
        hasSkin = table.clone(tempTab)
        local initSkin = gModelHero:GetHeroEffectByRefId(self._refId, self._star)
        hasSkin[initSkin] = { refId = initSkin, endTime = "-1" }            -- 默认皮肤
    else
        wearSkin = self._refId
        hasSkin = {}
    end
    self._wearSkin = wearSkin
    if self._wearSkin == 0 then
        self._wearSkin = self._skinRefIdList[1]
    end
    self._hasSkin = hasSkin
    self._wearStatus = 1
    if not self._selSkinRefId then
        local refId = self._gotoSkin or self._wearSkin
        self:ChangeBg(refId, true)
    end
    self:ChangeBtnTxt()
end
------------------------------------------------------------------
return UISagaSn
