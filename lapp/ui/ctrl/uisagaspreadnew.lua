---
--- Created by LCM.
--- DateTime: 2024/3/15 15:12:07
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaSpreadNew:LWnd
local UISagaSpreadNew = LxWndClass("UISagaSpreadNew", LWnd)

local YXUIPointUtil = CS.YXUIPointUtil
local YXTouchManager = CS.YXTouchManager

UISagaSpreadNew.DATA_TYPE_ATTR = 1
UISagaSpreadNew.DATA_TYPE_OUTFIT = 2
UISagaSpreadNew.DATA_TYPE_RUNEANDTALENT = 3
UISagaSpreadNew.DATA_TYPE_EQUIP = 4

UISagaSpreadNew.MAX_OUTFIT_NUM = 4
UISagaSpreadNew.MAX_RUNE_NUM = 2
UISagaSpreadNew.MAX_TALENT_NUM = 2

UISagaSpreadNew.TYPE_OPEN_NORMAL = 1
UISagaSpreadNew.TYPE_OPEN_BOSSTOWER = 3
UISagaSpreadNew.TYPE_OPEN_TACTICAL_TRAINING = 4 --战术训练

UISagaSpreadNew.SKILL_NORMAL = 1            -- 普通技能
UISagaSpreadNew.SKILL_AWAKEN = 2            -- 觉醒技能

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaSpreadNew:UISagaSpreadNew()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaSpreadNew:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaSpreadNew:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaSpreadNew:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitText()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    CS.ShowObject(self.mShareBtn, self._share)
    self:RefreshViewFunc()
    
    self:RefreshHeroBookBgSize()
    CS.ShowObject(self.mMask, true)
end

function UISagaSpreadNew:CreateSkillIcon(trans, itemdata, skillType, extraData)
    local SkillIconTrans = self:FindWndTrans(trans, "SkillIcon")
    local baseClass = SkillIcon:New(self)
    baseClass:ShowLock(false)
    local func = extraData.func
    local skillId = itemdata.skillId
    if skillType == UISagaSpreadNew.SKILL_NORMAL then
        local openClass = itemdata.openClass
        local grade = itemdata.grade
        if skillId then
            baseClass:SetSkillInfo(grade, false, openClass, 1)
            baseClass:Create(SkillIconTrans, skillId, function()
                if func then
                    func()
                end
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
    elseif skillType == UISagaSpreadNew.SKILL_AWAKEN then
        local isLock = itemdata.isLock
        baseClass:ShowLock(isLock)
        local talentData = itemdata.talentData
        if not isLock then
            baseClass:ShowAdd(talentData == nil)
        else
            baseClass:ShowAdd(false)
        end
        baseClass:Create(SkillIconTrans, skillId, function()
            if func then
                func()
            end
        end)
    end
end

function UISagaSpreadNew:RefreshNormalView()
    local heroInfo = self:GetNormalHeroInfo()
    self:RefreshHeroInfo(heroInfo)
    self:InitAttrList(self:GetHeroInfoByType(UISagaSpreadNew.DATA_TYPE_ATTR) or {})
    self:InitSkillList(self:GetNormalSkillList())
    -- self:InitOutfitList(self:GetNormalHeroOutfitList())
    self:InitRuneAndGiftList(self:GetNormalRuneList())
    self:RefreshPotencyDiv(self:GetNormalHeroPotencyInfo())
    self:InitEquipList(self:GetNormalHeroEquipList())
    self:UpdatePetList()
    -- self:RefreshSorceryCardDiv(self:GetSorceryCardInfo())
    self:RefreshGolemDiv(self:GetGolemList())
    -- 【G公共支持】删除伙伴晶石功能相关数据
    -- self:RefreshCrystalDiv()
    self:InitBadgeList()
end

function UISagaSpreadNew:OnDrawOutfitActivityStatusCell(list, item, itemdata, itempos)
    local ActivityImgTrans = self:FindWndTrans(item, "ActivityImg")
    local isAct = itemdata.isAct
    if isAct then
        local img = itemdata.img
        self:SetWndEasyImage(ActivityImgTrans, img)
    end
    CS.ShowObject(ActivityImgTrans, isAct)
end

function UISagaSpreadNew:OnClickSkill(itemdata)
    -- if self._wndType == UISagaSpreadNew.TYPE_OPEN_BOSSTOWER then
    --     self:ShowBossTowerSkillInfo(itemdata)
    if self._wndType == UISagaSpreadNew.TYPE_OPEN_TACTICAL_TRAINING then
        self:ShowMonsterSkillInfo(itemdata)
    else
        self:ShowNormalSkillInfo(itemdata)
    end
end

function UISagaSpreadNew:GetNormalSkillList()
    local list = {}
    local heroData = self._heroData
    if not heroData then
        return
    end
    local refId, star = heroData.refId, heroData.star
    local heroSkillIdList = gModelHero:GetSkillListByRefIdAndStar(refId, star, self._form)
    for i = 1, 4 do
        local skillData = heroSkillIdList[i]
        local data = {
            grade = heroData.grade,
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

function UISagaSpreadNew:GetGolemList()
    local golemList = self:GetWndArg("golemList")
    return golemList
end

function UISagaSpreadNew:InitEvent()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mShareBtn, function()
        self:OnClickShareBtnFunc()
    end)
    self:SetWndClick(self.mOutfitBg, function()
        self:ShowOutfitSultWnd()
    end)
    self:SetWndClick(self.mHeroZZImg, function()
        GF.OpenWndTop("UISagaQualitySow")
    end)
    self:SetWndClick(self.mHeroRaceImg, function()
        CS.ShowObject(self.mTypeImgMask, true)
        self:ShowRaecKeZhiInfo()
    end)
    self:SetWndClick(self.mTypeImgMask, function()
        CS.ShowObject(self.mTypeImgMask, false)
    end)
    self:SetWndClick(self.mAwakenIcon, function()
        if not self._heroData then
            return
        end
        local heroId = self._heroId
        if not heroId then
            return
        end

        GF.OpenWnd("UISagaAwakenAttr", {
            heroId = heroId,
            heroData = self._heroData,
            treeInfo = self:GetWndArg("treeInfo")
        })
    end)
end

function UISagaSpreadNew:ShowNormalSkillInfo(itemdata)
    local skillId, index = itemdata.skillId, itemdata.index
    local heroData = self._heroData
    if not heroData then
        return
    end
    gModelGeneral:OpenHeroSkillWnd({ curSkillId = skillId, curSkillIdx = index, heroData = heroData })
end

function UISagaSpreadNew:OnClickGolemFunc(itemdata)
   local isEmpty = itemdata.isEmpty
   if isEmpty then
       GF.ShowMessage(ccClientText(33268))
       return
   end
   --- 魔偶属性详情界面
   gModelGolem:OpenGolemInfoTip({
       viewType = 2,
       golemData = itemdata.serverData,
   })
end
function UISagaSpreadNew:OnDrawPetCell(list, item, itemdata, itempos)
    local RootTrans = self:FindWndTrans(item, "Root")
    local pet = itemdata
    local petInfo = pet.GetServerData and pet:GetServerData() or {}
    local petId = petInfo.refId
    local InstanceID = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(RootTrans)
    if petInfo.refId then
        baseClass:SetPetInfoSet(petInfo)
    else
        baseClass:SetPetDataSet(petId, petInfo.star)
    end
    baseClass:DoApply()

    self:SetWndClick(RootTrans, function()
        if petId then
            GF.OpenWnd("UIPeView", { refId = petId, pet = pet, playerId = self._playerId })
        end
    end)
end

function UISagaSpreadNew:InitBossTowerData()
    -- self._bossTowerHeroRefId = self:GetWndArg("bossTowerHeroRefId")
    -- self._sid = self:GetWndArg("sid")
    -- self._bossTowerRef = gModelBossTower:GetBossTowerHeroRefByRefId(self._bossTowerHeroRefId)
    -- self._bossTowerServerData = self:GetWndArg("bossTowerServerData")
    -- self._playerId = self:GetWndArg("playerId")
    -- if string.isempty(self._playerId) then
    --     self._playerId = gLGameLogin:GetPlayerId()
    -- end
end

function UISagaSpreadNew:GetMonsterOutfitList()
    local list = {}
    for i = 1, UISagaSpreadNew.MAX_OUTFIT_NUM do
        local data = {
            refId = i,
            ishave = false,
            index = i,
            outfitList = {},
        }
        table.insert(list, data)
    end
    return list
end

function UISagaSpreadNew:InitOutfitActivityStatusList(list)
    local refId = self._heroData and self._heroData.refId
    --local actList = gModelOutfit:GetOutfitSetActList(list,refId)
    -- local actList = gModelOutfit:GetOutfitZSActList(list, refId)
    local actList = {}
    local uiOutfitActivityStatusList = self._uiOutfitActivityStatusList
    if uiOutfitActivityStatusList then
        uiOutfitActivityStatusList:RefreshList(actList)
    else
        uiOutfitActivityStatusList = self:GetUIScroll("uiOutfitActivityStatusList")
        self._uiOutfitActivityStatusList = uiOutfitActivityStatusList
        uiOutfitActivityStatusList:Create(self.mOutfitActivityStatusList, actList, function(...)
            self:OnDrawOutfitActivityStatusCell(...)
        end)
    end
end

function UISagaSpreadNew:OnDrawStarCell(list, item, itemdata, itempos)
    local Star = self:FindWndTrans(item, "Star")
    if Star then
        self:SetWndEasyImage(Star, itemdata.img, function()
            CS.ShowObject(Star, itemdata.show)
        end)
    end
end

function UISagaSpreadNew:InitAttrList(attrList)
    local list = self:GetAttrList(attrList)
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

function UISagaSpreadNew:ShowMonsterSkillInfo(itemdata)
    local skillId, index = itemdata.skillId, itemdata.index
    local monsterData = self._heroData
    if not monsterData then
        return
    end

    local heroId = self._heroData.refId
    local star = monsterData.star or 0
    local heroData = {
        refId = heroId,
        grade = gModelHero:GetClassGradeByRefIdAndStar(heroId, star)
    }
    gModelGeneral:OpenHeroSkillWnd({ curSkillId = skillId, curSkillIdx = index, heroData = heroData })
end
function UISagaSpreadNew:GetSorceryCardInfo()
    local sorceryCardInfo =  self:GetWndArg("sorceryCardInfo")
	local heroData = self._heroData
	if not heroData then return end
	if sorceryCardInfo then
		local data = {
			refId = heroData.refId,
			star = heroData.star,
			sorceryCardInfo = sorceryCardInfo
		}
		return data
	end
    local sorceryCardId = heroData.sorceryCardId
    local sorceryCardLevel = heroData.sorceryCardLevel
    if sorceryCardId and sorceryCardLevel then
        local data = {
            refId = heroData.refId,
            star = heroData.star,
            sorceryCardInfo = {
                scRefId = sorceryCardId,
                level = sorceryCardLevel,
            }
        }
        return data
    end


end

------------------------- List -------------------------
function UISagaSpreadNew:InitStarList(star)
    local list = {}
    local img, showNum = gModelHero:GetHeroStarImg(star)

    if star > 10 then
        CS.ShowObject(self.mHightStar, true)
        CS.ShowObject(self.mStarList, false)

        self:SetWndText(self.mHightStarText, star - 10)
    else
        CS.ShowObject(self.mHightStar, false)
        CS.ShowObject(self.mStarList, true)

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
end

function UISagaSpreadNew:RefreshBossTowerView()
    -- local heroInfo = self:GetBossTowerHeroInfo()
    -- self:RefreshHeroInfo(heroInfo)
    -- gModelBossTower:OnBossTowerHeroPowerReq(self._sid, self._bossTowerHeroRefId, self._playerId)
end

--【G公共支持】删除伙伴晶石功能相关数据
-- function UISagaSpreadNew:RefreshCrystalDiv()
-- 	local heroData = self._heroData
-- 	local crystalContent = self._crystalContent
-- 	local heroStar = heroData.star
-- 	local heroSheetId = (crystalContent and crystalContent.refId) or heroData.crystalSheet or 101
-- 	local isOpen = gModelCrystalShard:CheckIsStarOpen(heroStar)
-- 	if(isOpen)then
-- 		local quality = gModelCrystalShard:GetMapQuality(heroSheetId)
-- 		local sheetData = {
-- 			id = heroSheetId,
-- 			refId = heroSheetId,
-- 			type = 1,
-- 			quality = quality,
-- 			crystalContent = crystalContent
-- 		}
-- 		local itemBg = self:FindWndTrans(self.mCrystalItemDiv,"IconBg")
-- 		local itemIcon = self:FindWndTrans(self.mCrystalItemDiv,"Icon")
-- 		local itemNameTxt = self:FindWndTrans(self.mCrystalItemDiv,"NameTxt")
-- 		local itemBgPath,itemPath,itemName =gModelCrystalShard:GetMapIconPathByItemData(sheetData)
-- 		local qualityRef = gModelItem:GetQualityRef(quality)
-- 		local nameColor = qualityRef.nameColor
-- 		local nameStr = string.format("<color=#%s>%s</color>", nameColor, ccLngText(itemName))
-- 		self:SetWndText(itemNameTxt,nameStr)
-- 		self:SetWndEasyImage(itemBg,itemBgPath)
-- 		self:SetWndEasyImage(itemIcon,itemPath)

-- 		self:SetWndClick(self.mCrystalItemDiv, function()
-- 			GF.OpenWnd("WndCrystalShardDrawingsDetails", { itemData = sheetData,showShopBtn = false })
-- 		end)
-- 	end
-- 	CS.ShowObject(self.mCrystalItemDiv,isOpen)
-- 	CS.ShowObject(self.mNotCrystalShardDiv,not isOpen)
-- end

function UISagaSpreadNew:InitGolemSuitList(list)
    local uiGolemSuitList = self._uiGolemSuitList
    if uiGolemSuitList then
        uiGolemSuitList:RefreshList(list)
    else
        uiGolemSuitList = self:GetUIScroll("uiGolemSuitList")
        self._uiGolemSuitList = uiGolemSuitList
        uiGolemSuitList:Create(self.mGolemSuitList, list, function(...)
            self:OnDrawGolemSuitCell(...)
        end)
    end
end

--function UISagaSpreadNew:CreateQMDJList(closeGrade, heroRefId)
--    local list = {}
--    local closeLv = gModelHeroBook:GetHeroCloseLv(heroRefId)
--    for i = 1, closeLv do
--        local actStar = closeGrade >= i
--        table.insert(list, { actStar = actStar })
--    end
--    local uiQmDJList = self._uiQmDJList
--    if uiQmDJList then
--        uiQmDJList:RefreshList(list)
--    else
--        uiQmDJList = self:GetUIScroll("uiQmDJList")
--        self._uiQmDJList = uiQmDJList
--        uiQmDJList:Create(self.mQmDJList, list, function(...)
--            self:OnDrawQmDJCell(...)
--        end)
--    end
--end

function UISagaSpreadNew:OnDrawQmDJCell(list, item, itemdata, itempos)
    local StarTrans = self:FindWndTrans(item, "Star")
    if StarTrans then
        local actStar = not itemdata.actStar
        self:SetWndImageGray(StarTrans, actStar)
    end
end

function UISagaSpreadNew:OnDrawGiftCell(list, item, itemdata, itempos)
    local RootTrans = self:FindWndTrans(item, "Root")
    local isLock = itemdata.isLock
    local skillId = itemdata.skillId
    local talentData = itemdata.talentData
    local index = itemdata.index

    if self._playerId ~= gModelPlayer:GetPlayerId() then
        isLock = false
    end

    self:CreateSkillIcon(RootTrans, itemdata, UISagaSpreadNew.SKILL_AWAKEN, {
        func = function()
            if isLock then
                GF.ShowMessage(ccClientText(10135))
            else
                if skillId == index then
                    GF.ShowMessage(ccClientText(10136))
                else
                    if talentData then
                        local ref = gModelRune:GetSkillInfoByRefId(talentData)
                        if talentData then
                            --[[                         local lv = ref.skillLevel
                                                     local other = { lv = lv }
                                                     GF.OpenWndTop("UIJNInfo", { skillId = skillId, other = other })]]
                            local initSkillId
                            local typeList = gModelRune:GetSkillTypeListBySkillType(ref.skillType)
                            if typeList and #typeList > 0 then
                                initSkillId = typeList[1].skillId
                            end
                            gModelGeneral:OpenSkillWnd({ curSkillId = skillId, initSkillId = initSkillId, wndType = 12 })
                            return
                        end
                    end
                    GF.ShowMessage(ccClientText(10136))
                end
            end
        end
    })
end
------------------------- List -------------------------

--region 根据content的内容调整背景页 --------------------------------------------------------------------------------
--五个控件的显示隐藏用新的方法调用
function UISagaSpreadNew:ShowOrHideContentTran(tran, isShow)
    CS.ShowObject(tran, isShow)
    self:RefreshHeroBookBgSize()
end

function UISagaSpreadNew:GetBossTowerRuneListAndTalentList(pb)
    -- local bossTowerRef = self._bossTowerRef
    -- if not bossTowerRef then
    --     return {}, {}
    -- end
    -- local monsterRefId = bossTowerRef.attr
    -- local monsterRef = gModelHero:GetMonsterAttrByRefId(monsterRefId)
    -- local bossTowerServerData = self._bossTowerServerData
    -- local lv
    -- if bossTowerServerData then
    --     lv = bossTowerServerData.breakLv
    -- end
    -- if not lv then
    --     if monsterRef then
    --         lv = monsterRef.lv
    --     else
    --         lv = 0
    --     end
    -- end
    -- local star = monsterRef and monsterRef.starLv or 0

    -- local heroInfo = {
    --     lv = lv,
    --     star = star,
    -- }

    -- local runeList = pb.runelist or {}
    -- local tRuneList = self:GetRuneRefInfo(runeList, heroInfo)

    -- local talentList = pb.talentList or {}
    -- local tTalentList = self:GetGiftRefInfo(talentList, heroInfo)

    return {}, {}
end

function UISagaSpreadNew:InitEquipList(list)
    if self._uiEquipList then
        self._uiEquipList:RefreshList(list)
    else
        self._uiEquipList = self:GetUIScroll("uiOutfitList")
        self._uiEquipList:Create(self.mEquipList, list, function(...)
            self:OnDrawEquipCell(...)
        end)
    end
end

function UISagaSpreadNew:RefreshBossTowerRaceKeZhiInfo()
    -- local bossTowerRef = self._bossTowerRef
    -- if not bossTowerRef then
    --     return
    -- end
    -- if bossTowerRef then
    --     local canvasRect = LGameUI.GetUICanvasRoot()
    --     if not self._changePos then
    --         local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect, self.mTypeImgBg)
    --         self.mTypeImgBg.localPosition = targetPos - Vector3.New(0, 0, 0)
    --         self._changePos = true
    --     end
    --     local heroRefId = bossTowerRef.type
    --     local raceType = gModelHero:GetHeroType(heroRefId)
    --     if raceType then
    --         local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
    --         if raceRef then
    --             local restrainDetailsEff = raceRef.restrainDetailsEff
    --             local isEmpty = string.isempty(restrainDetailsEff)
    --             local str = ""
    --             if not isEmpty then
    --                 local heroRaceImage = raceRef.heroRaceImage
    --                 self:SetWndEasyImage(self.mTypeKeZhiImg, heroRaceImage, function()
    --                     CS.ShowObject(self.mTypeKeZhiImg, true)
    --                 end, true)
    --             else
    --                 CS.ShowObject(self.mTypeKeZhiImg, not isEmpty)
    --                 str = ccClientText(31233)
    --             end
    --             CS.ShowObject(self.mTypeKZImgDiv, not isEmpty)
    --             CS.ShowObject(self.mNoHaveKeZhiTxtDiv, isEmpty)

    --             local name = string.replace(ccClientText(10079), ccLngText(raceRef.name))
    --             self:SetWndText(self.mRaceTypeName, name)

    --             self:SetWndText(self.mNoHaveKeZhiTxt, str)
    --         end
    --     end
    -- end
end

function UISagaSpreadNew:OnDrawRuneCell(list, item, itemdata, itempos)
    local RootTrans = self:FindWndTrans(item, "Root")
    local MaskTrans = self:FindWndTrans(item, "Mask")
    local MaskTxtTrans = self:FindWndTrans(MaskTrans, "MaskTxt")
    CS.ShowObject(MaskTrans, false)

    local InstanceID = item:GetInstanceID()
    local isLock, unlockTxt = itemdata.isLock, itemdata.unlockTxt
    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(RootTrans)
    baseClass:SetRuneData(itemdata)
    baseClass:SetRuneLock(isLock, unlockTxt)
    baseClass:DoApply()

    if self._playerId ~= gModelPlayer:GetPlayerId() then
        isLock = false
    end

    self:SetWndClick(RootTrans, function()
        if isLock then
            GF.ShowMessage(ccClientText(10139))
        else
            if itemdata.id ~= nil then
                local data = { runeData = itemdata }
                gModelGeneral:OpenRuneInfoTip(data)
            else
                GF.ShowMessage(ccClientText(10140))
            end
        end
    end)
end

function UISagaSpreadNew:RefreshHeroLv(lv)
    local lvStr = string.replace(ccClientText(14701), lv)
    self:SetWndText(self.mLvTxt, lvStr)
end


------------------------- CreateFunc -------------------------

function UISagaSpreadNew:CreateSp(refId, star, skin)
    local effRef = self:GetEffRef(refId, star, skin)
    if not effRef then
        return
    end

    local prefabName = effRef.prefabName
    self:CreateWndSpine(self.mHeroSPPos, prefabName, prefabName, false, function(dpSpine)
        --dpSpine:SetScale(2)
    end)
end

function UISagaSpreadNew:GetNormalHeroEquipList()
    local equipList = self:GetHeroInfoByType(UISagaSpreadNew.DATA_TYPE_EQUIP) or {}
    local list = {}
    for i = 1, UISagaSpreadNew.MAX_OUTFIT_NUM do
        list[i] = {}
        if equipList[i] then
            list[i] = equipList[i]
        end
    end
    return list
end

function UISagaSpreadNew:OnDrawSkillCell(list, item, itemdata, itempos)
    local RootTrans = self:FindWndTrans(item, "Root")
    self:CreateSkillIcon(RootTrans, itemdata, UISagaSpreadNew.SKILL_NORMAL, {
        func = function()
            self:OnClickSkill(itemdata)
        end
    })
end

function UISagaSpreadNew:RefreshHeroBookBgSize()
    local contentCount = 5

    if self.mSkillDiv.gameObject.activeSelf then
        contentCount = contentCount - 1
    end

    if self.mOutfitDiv.gameObject.activeSelf then
        contentCount = contentCount - 1
    end

    if self.mEquipDiv.gameObject.activeSelf then
        contentCount = contentCount - 1
    end

    if self.mRuneAndGiftDiv.gameObject.activeSelf then
        contentCount = contentCount - 1
    end

    if self.mPotencyDiv.gameObject.activeSelf then
        contentCount = contentCount - 1
    end

    if contentCount > 0 then
        local x = 596
        local y = 1012 - 120 * contentCount
        local linkPet = 120
        self.mHeroBookBg.sizeDelta = Vector2.New(x, y + linkPet)

        local posy = -50 * contentCount

        self.mMoveContent.anchoredPosition = Vector2.New(0, posy)

    end
end

------------------------- RefreshFunc -------------------------

function UISagaSpreadNew:RefreshHeroPower(power)

    local powerStr = LUtil.FormatPowerShowStr(power, 130, 150) --LUtil.FormatCoversionHurtNumSpriteText(power,false, nil, 22)
    self:SetWndText(self.mPowerNumTxt, powerStr)
end

function UISagaSpreadNew:ShowOutfitSultWnd()
    local heroData = self._heroData
    local refId = heroData and heroData.refId
    local outfitType = gModelHero:GetHeroOutfitTypeByHeroRefId(refId)
    if outfitType == 0 then
        return
    end
    local outfitList = self._curOutfitList or {}
    GF.OpenWnd("WndOutfitSultShowNew", { heroData = heroData, outfitList = outfitList })
end

function UISagaSpreadNew:CheckIsUnLockPos(unLockType, needCondition, heroServerData)
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

function UISagaSpreadNew:OnDrawOutfitCell(list, item, itemdata, itempos)
    local RootTrans = self:FindWndTrans(item, "Root")
    local EffRootTrans = self:FindWndTrans(item, "EffRoot")

    local InstanceID = item:GetInstanceID()
    local effKey = InstanceID
    self:DestroyWndEffectByKey(effKey)
    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(RootTrans)
    local ishave = itemdata.ishave
    if ishave then
        baseClass:SetOutfitData(itemdata)
        local outfitHeroRefId = itemdata.heroRefId
        local refId = self._heroData and self._heroData.refId
        if outfitHeroRefId == refId then
            self:CreateWndEffect(EffRootTrans, "fx_ui_zhuanshuzhuangbei", effKey, 100, false, false, 21)
        end
    else
        baseClass:SetCommonReward(LItemTypeConst.TYPE_OUTFIT, itemdata.refId, nil)
    end
    self:SetIconClickScale(RootTrans, true)
    self:SetWndClick(RootTrans, function()
        local heroData = self._heroData
        if ishave then
            gModelGeneral:OpenOutfitInfoTip({ heroData = heroData, curSerData = itemdata, outfitType = 2 }, true)
        else
            GF.ShowMessage(ccClientText(10138))
        end
    end)
    baseClass:DoApply()
end

------------------------- RefreshViewFunc -------------------------

function UISagaSpreadNew:RefreshViewFunc()
    local wndType = self._wndType
    -- if wndType == UISagaSpreadNew.TYPE_OPEN_BOSSTOWER then
    --     self:RefreshBossTowerView()
    if wndType == UISagaSpreadNew.TYPE_OPEN_TACTICAL_TRAINING then
        self:RefreshTacticalTrainingView()
    else
        self:RefreshNormalView()
    end
end

function UISagaSpreadNew:GetHeroInfoByType(gType)
    local heroData = self._heroData
    if not heroData then
        return
    end
    ---@type StructHeroAttribute
    local heroAttr = self:GetWndArg("heroAttr")
    if heroAttr then
        if gType == UISagaSpreadNew.DATA_TYPE_ATTR then
            local attrs = {}
            for i,v in ipairs(heroAttr.attrs) do
                --table.insert(attrs,{
                --    refId = v.refId,
                --    value = v.value,
                --})
                attrs[v.refId] = v.value
            end
            return attrs
        elseif gType == UISagaSpreadNew.DATA_TYPE_OUTFIT then
            return {}
        elseif gType == UISagaSpreadNew.DATA_TYPE_RUNEANDTALENT then
            local talentSkills = {}
            for i,v in ipairs(heroAttr.talentSkills) do
                talentSkills[v.position] = v.skillId
            end
            return heroAttr.heroRunes, talentSkills
        elseif gType == UISagaSpreadNew.DATA_TYPE_EQUIP then
            local equips = heroAttr.equips
            table.sort(equips, function(a, b)
                return a._ref.type < b._ref.type
            end)
            return equips
        end
    end
    local id = heroData.id
    local heroAttrList, heroWearEquipList, heroWearRuneList, heroWearTalentList, heroWearOutfitList = gModelHero:GetHeroAttrAndEquipInfoById(id)
    if gType == UISagaSpreadNew.DATA_TYPE_ATTR then
        return heroAttrList
    elseif gType == UISagaSpreadNew.DATA_TYPE_OUTFIT then
        return heroWearOutfitList
    elseif gType == UISagaSpreadNew.DATA_TYPE_RUNEANDTALENT then
        return heroWearRuneList, heroWearTalentList
    elseif gType == UISagaSpreadNew.DATA_TYPE_EQUIP then
        return heroWearEquipList
    end
end

function UISagaSpreadNew:OnDrawGolemSuitCell(list, item, itemdata, itempos)
    local IconTrans = self:FindWndTrans(item, "Icon")
    self:SetWndEasyImage(IconTrans, itemdata.icon, function()
        CS.ShowObject(IconTrans, true)
    end)
    self:SetTextTile(item, itemdata.showNumTxt, nil, -2)
end

function UISagaSpreadNew:OnDrawEquipCell(list, item, itemdata, itempos)
    local RootTrans = self:FindWndTrans(item, "Root")
    local InstanceID = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(RootTrans)
    local refId = itemdata["GetRefId"] and itemdata:GetRefId() or itemdata.refId
    local ref = gModelEquip:GetEquipRefByRefId(refId)
    baseClass:SetEquipIcon(refId, nil, itempos)
    baseClass:DoApply()
    local lvl = itemdata["GetLevel"] and itemdata:GetLevel() or itemdata.level
    if refId and refId > 0 then
        local quality = ref.quality
        if quality and quality < 7 then
            lvl = 0
        end
    end
    if lvl ~= nil then
        baseClass:SetEquipExtension(lvl)
    end
    self:SetWndClick(RootTrans, function()
        if refId then
            local quality = ref.quality
            if quality and quality >= 7 then
                --判断是否为金装
                --gModelGeneral:RunOriginConfigCode(1008, {
                --    refId=refId,
                --    id=itemdata._id,
                --    equip=itemdata,
                --})

                gModelGeneral:OpenEquipInfoTip(refId, nil, 3, false, nil, nil, nil, nil, true, itemdata)
            else
                gModelGeneral:OpenEquipInfoTip(refId, nil, nil, true)

            end


        end
    end)
end

function UISagaSpreadNew:GetMonsterSkillList()
    local list = {}
    local effectRef = self._heroEffectRef
    local monsterRef = self._monsterRef
    if not (effectRef and monsterRef) then
        return list
    end

    local heroRefId = effectRef.heroType
    local star = monsterRef.starLv
    local heroSkillIdList = gModelHero:GetSkillListByRefIdAndStar(heroRefId, star)
    local grade = gModelHero:GetClassGradeByRefIdAndStar(heroRefId, star)
    for i = 1, 4 do
        local skillData = heroSkillIdList[i]
        local data = {
            grade = grade,
            refId = heroRefId,
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

function UISagaSpreadNew:UpdatePetList()
    local isShow = gModelFunctionOpen:CheckIsShow(21006000)
    CS.ShowObject(self.mLinkPetDiv,isShow)
    if not isShow then return end

    local petInofs =  self._heroData and self._heroData.petInfos or {}
    local MaxLinkNum = GameTable.MagicPetStarHeroNumRef[#GameTable.MagicPetStarHeroNumRef].refId
    local list  = {}
    for i = 1, MaxLinkNum do
        table.insert(list,petInofs[i] or {})
    end
    self:InitPetList(list)
end

function UISagaSpreadNew:GetBossTowerOutfitList(pb)
    local list = {}
    -- local outfitList = pb.outfitList or {}
    -- for i = 1, UISagaSpreadNew.MAX_OUTFIT_NUM do
    --     local serverData = outfitList[i]
    --     local ishave = true
    --     if not serverData then
    --         ishave = false
    --         serverData = { refId = i }
    --     elseif type(serverData) ~= "table" then
    --         ishave = false
    --         serverData = { refId = i }
    --     end
    --     local data = table.clone(serverData)
    --     data.ishave = ishave
    --     data.index = i
    --     data.outfitList = outfitList
    --     table.insert(list, data)
    -- end
    return list
end
function UISagaSpreadNew:OnDrawBadgeCell(list, item, itemdata, itempos)
    local RootTrans = self:FindWndTrans(item, "Icon")
    local Lock = self:FindWndTrans(RootTrans, "Lock")
    local Empty = self:FindWndTrans(RootTrans, "Empty")
    local BadgeIcon = self:FindWndTrans(RootTrans, "BadgeIcon")
    local ComStar = self:FindWndTrans(RootTrans, "ComStar")

    local baseClass
    local info = itemdata
    local badgeStarRef = GameTable.BadgeStarRef[info.starRefId]
    if info and badgeStarRef then
        baseClass = self:GetCommonIcon(BadgeIcon)
        baseClass:Create(BadgeIcon)
        baseClass:SetCommonReward(LItemTypeConst.TYPE_BADGE, badgeStarRef.type)
        baseClass:EnableShowNum(false)
        baseClass:SetNoShowLv(false)
        baseClass._curIconCls:SetRhombusIcon(true,0)
        baseClass:DoApply()
        CS.ShowObject(ComStar,true)
        CS.ShowObject(Lock,false)
        self:SetComStar(ComStar,badgeStarRef.star,false,false)
    else
        CS.ShowObject(ComStar,false)
        self:DeleteCommonIcon(BadgeIcon)
        local isLock = info.lock
        CS.ShowObject(Empty,not isLock)
        CS.ShowObject(Lock,isLock)
    end
    self:SetWndClick(RootTrans,function()
        if not info or not badgeStarRef then return end
        GF.OpenWnd("UIBrandTips",{refId = badgeStarRef.type,noShowBtn = true})
    end)
end

function UISagaSpreadNew:GetNormalHeroPotencyInfo()
    local heroData = self._heroData
    if not heroData then
        return {}
    end
    local playerId = self._playerId
    local heroId = heroData.id
    local potencyInfo = {
        refId = heroData.refId,
        star = heroData.star,
        skin = heroData.skin,
        lv = heroData.lv or heroData.level,
        treeInfo = self:GetWndArg("treeInfo"), --gModelHero:GetHeroTreeByPlayerIdAndHeroId(playerId,heroId),
        playerId = playerId,
        id = heroId,
    }
    return potencyInfo
end

function UISagaSpreadNew:InitMsg()
    -- self:WndNetMsgRecv(LProtoIds.BossTowerHeroPowerResp, function(pb, ret)
    --     self:OnBossTowerHeroPowerResp(pb)
    -- end)

    self:WndNetMsgRecv(LProtoIds.HeroBookInfoResp, function(pb, ret)
        self:OnHeroBookInfoResp(pb)
    end)

    self:WndNetMsgRecv(LProtoIds.PowerShowResp, function(pb, ret)
        self:OnPowerShowResp(pb)
    end)
    -- self:WndNetMsgRecv(LProtoIds.PetCheckResp, function(pb, ret)
    --     local pet = StructPet:New()
    --     pet:CreateByPb(pb.pet)
    --     local list = {pet}
    --     self:InitPetList(list)
    -- end)
    self:WndNetMsgRecv(LProtoIds.PetCheckByHeroResp, function(pb, ret)
        local list = {}
        local MaxLinkNum = GameTable.MagicPetStarHeroNumRef[#GameTable.MagicPetStarHeroNumRef].refId
        for i = 1, MaxLinkNum do
            local data = pb.pet[i]
            local pet = {}
            if data then
                pet = StructPet:New()
                pet:CreateByPb(data)
            end
            table.insert(list, pet)
        end
        self:InitPetList(list)
    end)

    self:WndNetMsgRecv(LProtoIds.ChatShareResp, function(pb)
        if self._wndType == UISagaSpreadNew.TYPE_OPEN_NORMAL then
            self:WndClose()
        end
    end)
    -- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
    -- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UISagaSpreadNew:InitGiftList(list)
    list = list or {}
    local uiGiftList = self._uiGiftList
    if uiGiftList then
        uiGiftList:RefreshList(list)
    else
        uiGiftList = self:GetUIScroll("uiGiftList")
        self._uiGiftList = uiGiftList
        uiGiftList:Create(self.mGiftList, list, function(...)
            self:OnDrawGiftCell(...)
        end)
    end
end

function UISagaSpreadNew:ShowRaecKeZhiInfo()
    -- if self._wndType == UISagaSpreadNew.TYPE_OPEN_BOSSTOWER then
    --     self:RefreshBossTowerRaceKeZhiInfo()
    -- else
    self:RefrsehNormalRaceKeZhiInfo()
    -- end
end

function UISagaSpreadNew:SetOutfitActivitySuit(index, data)
    local outfitHeroRefId = data.heroRefId
    local refId = self._heroData and self._heroData.refId
    local isActivity = refId ~= nil and outfitHeroRefId == refId
    local outfitMaskTrans = self._outfitMaskTransList[index]
    CS.ShowObject(outfitMaskTrans, not isActivity)
end

function UISagaSpreadNew:OnDrawGolemCell(list,item,itemdata,itempos)
   local IconTrans = self:FindWndTrans(item,"CommonUI/Icon")
   local EmptyImgTrans = self:FindWndTrans(item,"EmptyImg")
   local BtnTrans = self:FindWndTrans(item,"Btn")
   local isEmpty = itemdata.isEmpty
   local key = IconTrans:GetInstanceID()
   local baseClass = self:GetCommonIcon(key)
   baseClass:Create(IconTrans)
   if isEmpty then
       baseClass:SetGolemData({
           --displayPos = gModelGolem:GetGolemLocationIconByRefId(itempos),
           golemDrawing = itempos,
       })
   else
       local serverData = itemdata.serverData
       baseClass:SetGolemData({
           refId = gModelGolem:GetGolemRefIdByGolemInfo(serverData),
           lvlRefId = gModelGolem:GetGolemLvlRefIdByGolemInfo(serverData),
           lvl = gModelGolem:GetGolemLvlByGolemInfo(serverData),
           displayPos = gModelGolem:GetGolemElementGolemDrawingIconByGolemInfo(serverData),
       })
   end
   baseClass:DoApply()
   CS.ShowObject(IconTrans,true)
   CS.ShowObject(EmptyImgTrans,false)


   self:SetWndClick(BtnTrans,function()
       self:OnClickGolemFunc(itemdata)
   end)
end

function UISagaSpreadNew:GetNormalRuneList()
    local heroData = self._heroData
    if not heroData then
        return {}, {}
    end
    local runeList, talentList = self:GetHeroInfoByType(UISagaSpreadNew.DATA_TYPE_RUNEANDTALENT)
    if not runeList then
        runeList = {}
    end
    if not talentList then
        talentList = {}
    end
    local heroInfo = {
        lv = heroData.lv or heroData.level,
        star = heroData.star,
    }
    local tRuneList = self:GetRuneRefInfo(runeList, heroInfo)
    local tTalentList = self:GetGiftRefInfo(talentList, heroInfo)
    return tRuneList, tTalentList
end

function UISagaSpreadNew:InitRuneList(list)
    list = list or {}
    local uiRuneList = self._uiRuneList
    if uiRuneList then
        uiRuneList:RefreshList(list)
    else
        uiRuneList = self:GetUIScroll("uiRuneList")
        self._uiRuneList = uiRuneList
        uiRuneList:Create(self.mRuneList, list, function(...)
            self:OnDrawRuneCell(...)
        end)
    end
end

function UISagaSpreadNew:InitText()
    self:SetWndText(self.mTitle, ccClientText(10181))
    self:SetWndButtonText(self.mShareBtn, ccClientText(10118))

    self:SetWndText(self.mKeZhiGuanXiTxt, ccClientText(10080))
    self:SetWndText(self.mSkillTitle, ccClientText(27100))
    -- self:SetWndText(self.mOutfitTitle, ccClientText(27101))
    self:SetWndText(self.mEquipTitle, ccClientText(27101))
    self:SetWndText(self.mLinkPetTitle, ccClientText(43700))
    self:SetWndText(self.mRuneAndGiftTitle, ccClientText(27102))
    self:SetWndText(self.mPotencyTitle, ccClientText(27107))

    self:SetWndText(self.mNoActElementTxt, ccClientText(27106))
    self:SetWndText(self.mLockPotencyTxt, ccClientText(27108))

    self:SetWndText(self.mElementTypeName, ccClientText(27103))
    self:SetWndText(self.mAwakenBtnText, ccClientText(27105))

    self:SetWndText(self.mSorceryCardTitle,ccClientText(29556))
    self:SetWndText(self.mGolemTitle, ccClientText(34802))

    self:SetWndText(self.mCardTitle, ccClientText(29556))
    self:SetWndText(self.mBadgeTitle, ccClientText(47500))

    -- 【G公共支持】删除伙伴晶石功能相关数据
    -- self:SetWndText(self.mCrystalTitle,ccClientText(34735))
    -- self:SetWndText(self.mLockCrystalTxt,ccClientText(34736))
end

------------------------- GetFunc -------------------------

function UISagaSpreadNew:GetEffRef(refId, star, skin)
    local showEffId
    if skin and skin > 0 then
        showEffId = skin
    else
        showEffId = gModelHero:GetHeroEffectByRefId(refId, star, self._form)
    end
    local effRef = gModelHero:GetShowEffectById(showEffId)
    return effRef
end

function UISagaSpreadNew:InitGolemList(list)
   local uiGolemList = self._uiGolemList
   if uiGolemList then
       uiGolemList:RefreshList(list)
   else
       uiGolemList = self:GetUIScroll("uiGolemList")
       self._uiGolemList = uiGolemList
       uiGolemList:Create(self.mGolemList,list,function(...) self:OnDrawGolemCell(...) end)
   end
end

function UISagaSpreadNew:GetAwakenSkillData(serverData)
    local skillId = serverData.skillId
    if skillId and skillId > 0 then
        local data = {
            skillId = skillId,
        }
        return data
    end

    return nil
end

function UISagaSpreadNew:GetBossTowerHeroPotencyInfo()
    local potencyInfo = {}
    return potencyInfo
end

function UISagaSpreadNew:InitRuneAndGiftList(runeList, giftList)
    self:InitRuneList(runeList)
    self:InitGiftList(giftList)
end

function UISagaSpreadNew:OnPowerShowResp(pb)
    if self._wndType ~= UISagaSpreadNew.TYPE_OPEN_NORMAL then
        return
    end
    if not self._heroId then
        return
    end
    local showType = pb.type
    if showType == 2 then
        local _powers = pb.powers
        for i, v in ipairs(_powers) do
            local key = v.key
            if key == self._heroId then
                local power = v.power
                self:RefreshHeroPower(power)
            end
        end
    end
end

-- 传入英雄星级 star，觉醒结构 treeInfo
function UISagaSpreadNew:RefreshAwakenShowDiv(info)
    local showAwakenDiv = info ~= nil
    if showAwakenDiv then
        local heroRefId = info.refId
        local maxStar = gModelHero:GetMaxStarByRefId(heroRefId)
        local heroAwaken = gModelHero:GeConfigByKey("heroAwaken")
        if maxStar >= heroAwaken then
            local curStar = info.star
            local showLvTxt = false
            local showLockTxt = false
            if heroAwaken <= curStar then
                local treeInfo = info.treeInfo
                local isHaveTree = treeInfo ~= nil and treeInfo.treeRefId ~= nil
                showAwakenDiv = isHaveTree
                if isHaveTree then
                    local points = treeInfo.points
                    local awakenSkillList = {}
                    for i, v in ipairs(points) do
                        local awakenSkill = self:GetAwakenSkillData(v)
                        if awakenSkill then
                            table.insert(awakenSkillList, awakenSkill)
                        end
                    end
                    local skillNum = awakenSkillList and #awakenSkillList or 0
                    isHaveTree = skillNum > 0
                    if isHaveTree then
                        showLvTxt = true
                    end

                    local curLv, maxLv = gModelHero:GetTreePointsCurLvAndMaxLv(treeInfo)
                    local iconPath = gModelHero:GetAwakenIconPathByLvl(curLv, true)
                    if LxUiHelper.IsImgPathValid(iconPath) then
                        self:SetWndEasyImage(self.mAwakenIcon, iconPath, function()
                            CS.ShowObject(self.mAwakenIcon, true)
                        end)
                    end
                    local isMaxLv = curLv >= maxLv
                    CS.ShowObject(self.mMaxAwakenIcon, isMaxLv)
                    CS.ShowObject(self.mAwakenLvText, not isMaxLv)
                    if not isMaxLv then
                        self:SetWndText(self.mAwakenLvText, curLv)
                        showLvTxt = true
                    end
                end
            else
                local iconPath = gModelHero:GetAwakenIconPathByLvl(0, true)
                self:SetWndEasyImage(self.mAwakenIcon, iconPath, function()
                    CS.ShowObject(self.mAwakenIcon, true)
                end)
                local coreLockStr = string.replace(ccClientText(26672), heroAwaken)
                self:SetWndText(self.mAwakenLockTxt, coreLockStr)
                showLockTxt = true
            end
            CS.ShowObject(self.mAwakenLvText, showLvTxt)
            CS.ShowObject(self.mAwakenLockTxt, showLockTxt)
        else
            showAwakenDiv = false
        end
    end
    CS.ShowObject(self.mAwakenIcon, showAwakenDiv)
    CS.ShowObject(self.mAwakenShowDiv, showAwakenDiv)
end

function UISagaSpreadNew:GetMonsterAttrByInfo(monsterAttr)
    local attrList = {
        [LAttrConst.Atk] = monsterAttr.Atk or 0,
        [LAttrConst.MaxHP] = monsterAttr.MaxHP or 0,
        [LAttrConst.Def] = monsterAttr.Def or 0,
        [LAttrConst.Speed] = monsterAttr.Speed or 0,
    }

    return attrList
end


------------------------- RefreshNormalView -------------------------

function UISagaSpreadNew:GetNormalHeroInfo()
    local heroData = self._heroData
    if not heroData then
        return {}
    end
    local heroInfo = {
        id = heroData.id,
        refId = heroData.refId,
        star = heroData.star,
        skin = heroData.skin,
        lv = heroData.lv or heroData.level,
        fightPower = heroData.fightPower
    }
    return heroInfo
end

function UISagaSpreadNew:InitSkillList(list)
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

function UISagaSpreadNew:InitNormalData()
    self._playerId = self:GetWndArg("playerId")
    local myPlayerId = gLGameLogin:GetPlayerId()
    if string.isempty(self._playerId) then
        self._playerId = myPlayerId
    end

    self._isMeHero = self._playerId == myPlayerId

    local heroData = self:GetWndArg("heroData")
    self._share = self:GetWndArg("share")
    self._shareFunc = self:GetWndArg("shareFunc")
    self._refId = self:GetWndArg("refId")
    self._star = self:GetWndArg("star")
    self._skin = self:GetWndArg("skin")
    self._serverId = self:GetWndArg("serverId")

    local badgeInfos = self:GetWndArg("badgeInfos")
    if not badgeInfos then
        ---@type StructHeroAttribute
        local heroAttr = self:GetWndArg("heroAttr")
        if heroAttr then
            badgeInfos = heroAttr.badgeWears or {}
        end
    end
    self._badgeInfos = badgeInfos

    -- self._crystalContent = self:GetWndArg("crystalContent")【G公共支持】删除伙伴晶石功能相关数据
    self._form = heroData.form
    if not self._serverId then
        self._serverId = gLGameLogin:GetServerId()
    end
    self._heroData = heroData
    if heroData then
        self._heroId = heroData.id
        gModelHero:FindHeroPowStateById(self._heroId)
        gModelHeroBook:OnHeroBookInfoReq(self._playerId, heroData.refId, self._serverId)
    end
    local petInofs =  heroData and heroData.petInfos
    if heroData and not petInofs then
        gModelPet:OnPetCheckByHeroReq(self._playerId, heroData.id)
    end

    local isShow = gModelFunctionOpen:CheckIsShow(28000000)
    CS.ShowObject(self.mCardDiv,isShow)

    local sorceryCardInfo = self:GetWndArg("sorceryCardInfo")
    if sorceryCardInfo and sorceryCardInfo.scRefId > 0 then
        local cardRef = gModelSorceryCard:GetSorceryCardRefByRefId(sorceryCardInfo.scRefId)
        self:SetWndEasyImage(self.mCardFrame, cardRef.frameRes)
        self:SetWndEasyImage(self.mCardIcon, cardRef.icon)
        CS.ShowObject(self.mCardIcon, true)

        self:SetWndClick(self.mCardIcon,function ()
            local skillLvRef = gModelSorceryCard:GetSorceryCardSkillRef(cardRef.skillGroup, sorceryCardInfo.level)
            local argList = {
                skill = skillLvRef.skill,
                wndType = 7,
                cardId = sorceryCardInfo.scRefId,
                skillGroup = cardRef.skillGroup,
                cardLevel = sorceryCardInfo.level
            }
            gModelGeneral:OpenSkillWnd(argList)
        end)
    else
        self:SetWndEasyImage(self.mCardFrame, "card_di_1")
        CS.ShowObject(self.mCardIcon, false)
    end
    -- if heroData and heroData.petIds and #heroData.petIds>0 then
        -- gModelPet:OnPetCheckReq(self._playerId,heroData.petIds[1])
    -- else
end

function UISagaSpreadNew:GetGiftRefInfo(giftServerList, heroInfo)
    giftServerList = giftServerList or {}
    local tTalentList = {}
    local talentRefIdList = self._talentRefIdList
    for i = 1, UISagaSpreadNew.MAX_TALENT_NUM do
        local pos = i + 2
        local talentRefId = talentRefIdList[i]
        local isLock = true
        local runePosRef = GameTable.MagicRunePosRef[talentRefId]
        local unlock = runePosRef.unlock
        local unlockTxt = ccLngText(runePosRef.text)

        unlock = string.split(unlock, ",")
        local unlockTag = true
        for k, unlockInfo in ipairs(unlock) do
            local tempUnlock = string.split(unlockInfo, "=")
            unlockTag = unlockTag and self:CheckIsUnLockPos(tempUnlock[1], tempUnlock[2], heroInfo)
        end
        isLock = isLock and not unlockTag

        if self._playerId ~= gModelPlayer:GetPlayerId() then
            isLock = false
        end

        local skillId = i
        local talentData = giftServerList[pos]
        if not isLock and talentData ~= nil then
            local ref = gModelRune:GetSkillInfoByRefId(talentData)
            skillId = tonumber(ref.SkillId)
        end
        local serverData = {
            isLock = isLock,
            skillId = skillId,
            index = i,
            unlockTxt = unlockTxt,
            talentData = talentData,
        }
        table.insert(tTalentList, serverData)
    end
    return tTalentList
end

function UISagaSpreadNew:OnDrawAttrCell(list, item, itemdata, itempos)
    local AttrIconTrans = self:FindWndTrans(item, "AttrIcon")
    local AttrValueTrans = self:FindWndTrans(item, "AttrValue")
    local refId, value = itemdata.refId, itemdata.value

    local ref = gModelHero:GetAttributeRefById(refId)
    if not ref then
        return
    end

    local icon = ref.icon
    self:SetWndEasyImage(AttrIconTrans, icon)

    local numType, saveNum
    if ref then
        numType, saveNum = ref.numType, ref.saveNum
    else
        numType, saveNum = 1, 0
    end
    if saveNum == 0 then
        value = math.floor(value + 0.5)
    else
        local tempPow = 10 ^ saveNum
        local temp = math.floor(value * tempPow + 0.5)
        value = temp / tempPow
    end
    if numType == 2 then
        value = value * 100 .. "%"
    end
    self:SetWndText(AttrValueTrans, value)
end
------------------------- RefreshBossTowerView -------------------------

function UISagaSpreadNew:GetBossTowerHeroInfo()
    -- local bossTowerRef = self._bossTowerRef
    -- if not bossTowerRef then
    --     return
    -- end
    -- local heroRefId = bossTowerRef.type
    -- local star = gModelBossTower:GetHeroStarByRefId(self._bossTowerHeroRefId)
    -- local bossTowerServerData = self._bossTowerServerData
    -- local lv
    -- if bossTowerServerData then
    --     lv = bossTowerServerData.breakLv
    -- end
    -- if not lv then
    --     local monsterRef = gModelHero:GetMonsterAttrByRefId(bossTowerRef.attr)
    --     if monsterRef then
    --         lv = monsterRef.lv
    --     else
    --         lv = 0
    --     end
    -- end
    -- local heroInfo = {
    --     refId = heroRefId,
    --     star = star,
    --     skin = 0,
    --     lv = lv,
    -- }
    return {}
end

function UISagaSpreadNew:InitBadgeList()
    local isOpen = gModelFunctionOpen:CheckIsOpened(37000001)
    local heroRef = self._heroData and gModelHero:GetHeroRef(self._heroData.refId)

    if not self._badgeInfos or not isOpen or GameTable.BadgeConfigRef.badgeShow > heroRef.maxStar then
        CS.ShowObject(self.mBadgeDiv,false)
        return
    end
    local list = self._badgeInfos
    if self._uiBadgeList then
        self._uiBadgeList:RefreshList(list)
    else
        self._uiBadgeList = self:GetUIScroll("uiBadgeList")
        self._uiBadgeList:Create(self.mBadgeList, list, function(...)
            self:OnDrawBadgeCell(...)
        end)
    end
end

------------------------- RefreshTacticalTrainingView -------------------------
function UISagaSpreadNew:GetMonsterHeroInfo()
    local refId = self._refId
    if LOG_INFO_ENABLED then
        printInfoNR("打印而已，莫慌      该怪物id =  " .. refId)
    end
    local monsterRef = self._monsterRef
    local effectRef = self._heroEffectRef
    if not (monsterRef and effectRef) then
        return
    end

    local heroType = effectRef.heroType

    local star, lv = monsterRef.starLv, monsterRef.lv

    local heroInfo = {
        refId = heroType,
        star = star,
        skin = 0,
        lv = lv,
        Atk = monsterRef.Atk,
        MaxHP = monsterRef.MaxHP,
        Def = monsterRef.Def,
        Speed = monsterRef.Speed,
        fightPower = monsterRef.monsterPower,
    }
    return heroInfo
end

function UISagaSpreadNew:RefrsehNormalRaceKeZhiInfo()
    local heroData = self._heroData
    if not heroData then
        return
    end
    local canvasRect = LGameUI.GetUICanvasRoot()
    if not self._changePos then
        local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect, self.mTypeImgBg)
        self.mTypeImgBg.localPosition = targetPos - Vector3.New(0, 0, 0)
        self._changePos = true
    end
    local refId = heroData.refId
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

function UISagaSpreadNew:RefreshPotencyDiv(info)
    local isOpen = false
    if not isOpen then
        --CS.ShowObject(self.mPotencyDiv, false)

        self:ShowOrHideContentTran(self.mPotencyDiv, false)
        return
    end

    info = info or {}
    local heroRefId = info.refId
    local showActPotencyDiv = heroRefId ~= nil
    if showActPotencyDiv then
        local maxStar = gModelHero:GetMaxStarByRefId(heroRefId)
        local heroAwaken = gModelHero:GeConfigByKey("heroAwaken")
        showActPotencyDiv = maxStar >= heroAwaken
    end
    if PRODUCT_G_VER == 1 then
        --ios 提审写死屏蔽
        showActPotencyDiv = false
    end
    CS.ShowObject(self.mActPotencyDiv, showActPotencyDiv)
    CS.ShowObject(self.mNotPotencyDiv, not showActPotencyDiv)
    if not showActPotencyDiv then
        return
    end
    --暂时屏蔽
    self:RefreshAwakenShowDiv(info)
end
function UISagaSpreadNew:InitPetList(list)
    if not list or #list == 0 then
        return
    end
    if self._uiLinkPetList then
        self._uiLinkPetList:RefreshList(list)
    else
        self._uiLinkPetList = self:GetUIScroll("uiLinPetList")
        self._uiLinkPetList:Create(self.mLinkPetList, list, function(...)
            self:OnDrawPetCell(...)
        end)
    end
end

function UISagaSpreadNew:RefreshHeroInfo(heroInfo)
    local refId, star, skin, lv = heroInfo.refId, heroInfo.star, heroInfo.skin, heroInfo.lv
    local fightPower = heroInfo.fightPower

    self:InitStarList(star)
    if fightPower then
        self:RefreshHeroPower(fightPower)
    end

    self:RefreshHeroLv(lv)

    local needShowShareSetName = gModelHero:GeConfigByKey("needShowShareSetName")
    if not needShowShareSetName then
        needShowShareSetName = 0
        if LOG_INFO_ENABLED then
            printInfoNR("打印而已，莫慌    如果分享英雄界面需要显示备注名，HeroConfigRef 表加 needShowShareSetName 字段，默认 0，不显示")
        end
    end
    local isShowSetName = needShowShareSetName == 1
    local name
    if isShowSetName then
        name = self:GetWndArg("heroSetName")
        if string.isempty(name) then
            name = gModelHero:GetHeroNameByRefId(refId, star, self._form)
        end
    else
        local id = heroInfo.id
        if id and gModelHeroExtra:CheckIsMyHero(id) then
            name = self:GetWndArg("heroSetName")
            if string.isempty(name) then
                local serverData = gModelHero:GetHeroServerDataById(id)
                if serverData then
                    name = gModelHeroExtra:GetHeroSetName(serverData)
                end
            end
        end
        if string.isempty(name) then
            name = gModelHero:GetHeroNameByRefId(refId, star, self._form)
        end
    end
    self:SetWndText(self.mHeroName, name)

    local ref = gModelHero:GetHeroRef(refId)
    if not ref then
        return
    end

    local qualityIcon = ref.qualityIcon
    self:SetWndEasyImage(self.mHeroZZImg, qualityIcon, function()
        CS.ShowObject(self.mHeroZZImg, true)
    end)

    local raceId = ref.raceType
    local raceRef = gModelHero:GetHeroRaceRefByRefId(raceId)
    if not raceRef then
        return
    end

    self:SetWndEasyImage(self.mHeroShareImg, raceRef.heroShareBg, function()
        CS.ShowObject(self.mHeroShareImg, true)
    end)

    self:SetWndEasyImage(self.mHeroRaceImg, raceRef.icon, function()
        CS.ShowObject(self.mHeroRaceImg, true)
    end)

    local careerType = ref.careerType
    local careerRef = gModelHero:GetCareerRefByRefId(careerType)
    if not careerRef then
        return
    end

    self:SetWndText(self.mJobName, ccLngText(careerRef.name))

    local effRef = self:GetEffRef(refId, star, skin)
    self._effRef = effRef
    if effRef then
        local location = "[" .. ccLngText(effRef.location) .. "]"
        self:SetWndText(self.mJobEffTxt, location)
    end

    self:CreateSp(refId, star, skin)
end

function UISagaSpreadNew:ShowBossTowerSkillInfo(itemdata)
    -- local skillId, index = itemdata.skillId, itemdata.index
    -- local bossTowerRef = self._bossTowerRef
    -- if not bossTowerRef then
    --     return
    -- end
    -- local monsterRefId = bossTowerRef.attr
    -- local monsterRef = gModelHero:GetMonsterAttrByRefId(monsterRefId)
    -- local star = monsterRef and monsterRef.starLv or 0
    -- local heroRefId = bossTowerRef.type
    -- local heroData = {
    --     refId = heroRefId,
    --     grade = gModelHero:GetClassGradeByRefIdAndStar(heroRefId, star)
    -- }
    -- gModelGeneral:OpenHeroSkillWnd({ curSkillId = skillId, curSkillIdx = index, heroData = heroData })
end

function UISagaSpreadNew:InitData()
    local wndType = self:GetWndArg("wndType")
    if not wndType then
        wndType = UISagaSpreadNew.TYPE_OPEN_NORMAL
    end
    self._wndType = wndType

    self._baseAttrList = { LAttrConst.Atk, LAttrConst.MaxHP, LAttrConst.Def, LAttrConst.Speed }
    self._runeRefIdList = { 1001, 1002 }
    self._talentRefIdList = { 2001, 2002 }
    self._classList = {}
    self._outfitMaskTransList = {
        self.mTypeMask1,
        self.mTypeMask2,
        self.mTypeMask3,
        self.mTypeMask4,
    }

    -- if wndType == UISagaSpreadNew.TYPE_OPEN_BOSSTOWER then
    --     self:InitBossTowerData()
    if wndType == UISagaSpreadNew.TYPE_OPEN_TACTICAL_TRAINING then
        self:InitMonsterData()
    else
        self:InitNormalData()
    end
end

function UISagaSpreadNew:OnHeroBookInfoResp(pb)
    local playerId = pb.playerId
    if self._playerId ~= playerId then
        return
    end
    local heroRefId = pb.heroRefId
    local heroData = self._heroData
    if not heroData then
        return
    end
    local refId = heroData.refId
    if refId ~= heroRefId then
        return
    end
    --local closeGrade = pb.closeGrade
    --self:CreateQMDJList(closeGrade, heroRefId)
end

function UISagaSpreadNew:InitOutfitList(list)
    local effRef = self._effRef
    local heroType = effRef.heroType
    local outfitType = gModelHero:GetHeroOutfitTypeByHeroRefId(heroType)
    local showSuit = outfitType ~= 0 and self._wndType ~= UISagaSpreadNew.TYPE_OPEN_BOSSTOWER
    if showSuit then
        --local heroRoundIcon = effRef.heroRoundIcon
        --self:SetWndEasyImage(self.mOutfitHeroIcon, heroRoundIcon, function()
        --    CS.ShowObject(self.mOutfitHeroIcon, true)
        --end)
        for k, v in ipairs(list) do
            self:SetOutfitActivitySuit(k, v)
        end
        self:InitOutfitActivityStatusList(list)
    end
    CS.ShowObject(self.mOutfitBg, showSuit)
    CS.ShowObject(self.mOutfitList, not showSuit)
    CS.ShowObject(self.mOutfitRightList, showSuit)

    local uiOutfitList = self._uiOutfitList
    if uiOutfitList then
        uiOutfitList:RefreshList(list)
    else
        uiOutfitList = self:GetUIScroll("uiOutfitList")
        self._uiOutfitList = uiOutfitList
        local outfitTrans = showSuit and self.mOutfitRightList or self.mOutfitList
        uiOutfitList:Create(outfitTrans, list, function(...)
            self:OnDrawOutfitCell(...)
        end)
    end
end

-- function UISagaSpreadNew:RefreshSorceryCardDiv(data)
--     CS.ShowObject(self.mSorceryCardDiv,false)
--     if not data then return end
--     local info = data.sorceryCardInfo
--     local refId = data.refId
--     local star = data.star
--     local heroRef  = gModelHero:GetHeroRef(refId)
--     local showSlotQuality = gModelSorceryCard:GetSorceryCardConfigRefByKey("showSlotQuality")
--     local bool = heroRef.quality >= showSlotQuality
--     if not bool then return end
--     CS.ShowObject(self.mSorceryCardDiv,true)
--     local root = self:FindWndTrans(self.mSorceryCardDiv,"Root")
--     local luck = self:FindWndTrans(root,"Luck")
--     local mask = self:FindWndTrans(root,"Mask")
--     local frame = self:FindWndTrans(root,"Frame")

--     local unlockHeroStar = gModelSorceryCard:GetSorceryCardConfigRefByKey("unlockHeroStar")
--     local bool = star >= unlockHeroStar
--     CS.ShowObject(luck,not bool)
--     CS.ShowObject(mask,bool)
--     CS.ShowObject(frame,bool)
--     self:SetWndClick(root,function ()
--         GF.ShowMessage(ccClientText(29558))
--     end)
--     if not bool then return end
--     local scRefId = info.scRefId
--     local level = info.level
--     local isWar = scRefId > 0 and level > 0
--     CS.ShowObject(mask,not isWar)
--     CS.ShowObject(frame,isWar)
--     self:SetWndClick(root,function ()
--         GF.ShowMessage(ccClientText(29557))
--     end)
--     if not isWar then return end
--     local icon = self:FindWndTrans(frame,"Icon")
--     local lvText = self:FindWndTrans(frame,"LVText")
--     local nameText = self:FindWndTrans(frame,"NameBg/NameText")

--     local cardRef = gModelSorceryCard:GetSorceryCardRefByRefId(scRefId)
--     local themeRef = gModelSorceryCard:GetSorceryCardThemeRefByRefId(cardRef.theme)
--     local lvStr = string.replace(ccClientText(29550),level)

--     self:SetWndEasyImage(frame,themeRef.cardFrame)
--     self:SetWndEasyImage(icon,cardRef.icon)
--     self:SetWndText(lvText,lvStr)
--     self:SetWndText(nameText,ccLngText(cardRef.name))

--     self:SetWndClick(root,function ()
--         local skillLvRef = gModelSorceryCard:GetSorceryCardSkillRef(cardRef.skillGroup,level)
--         local argList = {
--             skill = skillLvRef.skill,
--             wndType = 7,
--             cardId = scRefId,
--             skillGroup = cardRef.skillGroup,
--             cardLevel = level
--         }
--         gModelGeneral:OpenSkillWnd(argList)
--     end)
-- end

function UISagaSpreadNew:RefreshGolemDiv(golemList)
    local isShow = gModelFunctionOpen:CheckIsShow(ModelGolem.FUNCTIONOPEN_ID)
    CS.ShowObject(self.mGolemDiv,isShow)
    if not isShow then return end


   local suitList = gModelGolem:GetShareHeroGolemSuitShow(golemList)
   self:InitGolemSuitList(suitList)

   local showWearList = gModelGolem:GetShareHeroGolemList(golemList)
   self:InitGolemList(showWearList)
end

function UISagaSpreadNew:OnBossTowerHeroPowerResp(pb)
    -- if self._sid ~= pb.sid then
    --     return
    -- end
    -- local fightPower = tonumber(pb.power) or 0
    -- self:RefreshHeroPower(fightPower)

    -- local level = tonumber(pb.level) or 0
    -- self:RefreshHeroLv(level)

    -- local attrs = pb.attrs
    -- local attrList = {}
    -- for i, v in ipairs(attrs) do
    --     attrList[v.refId] = v.value
    -- end
    -- self:InitAttrList(attrList)
    -- self:InitSkillList(self:GetBossTowerSkillList())
    -- self:InitOutfitList(self:GetBossTowerOutfitList(pb))
    -- self:InitRuneAndGiftList(self:GetBossTowerRuneListAndTalentList(pb))
    -- self:RefreshPotencyDiv()
    -- self:RefreshSorceryCardDiv(self:GetSorceryCardInfo())
    -- self:RefreshGolemDiv(self:GetGolemList())
end

function UISagaSpreadNew:GetNormalHeroOutfitList()
    local outfitList = self:GetHeroInfoByType(UISagaSpreadNew.DATA_TYPE_OUTFIT) or {}
    local list = {}
    self._curOutfitList = outfitList or list
    if not outfitList then
        return list
    end
    for i = 1, UISagaSpreadNew.MAX_OUTFIT_NUM do
        local serverData = outfitList[i]
        local ishave = true
        if not serverData then
            ishave = false
            serverData = { refId = i }
        elseif type(serverData) ~= "table" then
            ishave = false
            serverData = { refId = i }
        end
        local data = table.clone(serverData)
        data.ishave = ishave
        data.index = i
        data.outfitList = outfitList
        table.insert(list, data)
    end
    return list
end

function UISagaSpreadNew:RefreshTacticalTrainingView()
    local heroInfo = self:GetMonsterHeroInfo()
    self._heroData = heroInfo
    self:RefreshHeroInfo(heroInfo)
    self:InitAttrList(self:GetMonsterAttrByInfo(heroInfo) or {})
    self:InitSkillList(self:GetMonsterSkillList())
    self:InitOutfitList(self:GetMonsterOutfitList())
    self:InitRuneAndGiftList(self:GetMonsterRuneList(heroInfo))
    self:RefreshPotencyDiv()
    -- self:RefreshSorceryCardDiv()
    self:RefreshGolemDiv()
    -- 【G公共支持】删除伙伴晶石功能相关数据
    -- self:RefreshCrystalDiv()
end

function UISagaSpreadNew:GetBossTowerSkillList()
    local list = {}
    -- local bossTowerRef = self._bossTowerRef
    -- if bossTowerRef then
    --     local heroRefId = bossTowerRef.type
    --     local star = gModelBossTower:GetHeroStarByRefId(self._bossTowerHeroRefId)
    --     local heroSkillIdList = gModelHero:GetSkillListByRefIdAndStar(heroRefId, star)
    --     for i = 1, 4 do
    --         local skillData = heroSkillIdList[i]
    --         local data = {
    --             grade = bossTowerRef.grade,
    --             refId = heroRefId,
    --             star = star,
    --             index = i,
    --         }
    --         if skillData then
    --             data.skillId = skillData.skillId
    --             data.openClass = skillData.openClass
    --         end
    --         table.insert(list, data)
    --     end
    -- end
    return list
end

function UISagaSpreadNew:GetAttrList(attrList)
    local list = {}
    local baseAttrList = self._baseAttrList
    for i, v in ipairs(baseAttrList) do
        table.insert(list, {
            refId = v,
            value = attrList[v] or 0,
        })
    end
    return list
end

function UISagaSpreadNew:GetMonsterRuneList(heroInfo)
    if not heroInfo then
        return {}, {}
    end
    local heroData = {
        lv = heroInfo.lv,
        star = heroInfo.star,
    }
    local tRuneList = self:GetRuneRefInfo({}, heroData)
    local tTalentList = self:GetGiftRefInfo({}, heroData)
    return tRuneList, tTalentList
end

function UISagaSpreadNew:InitMonsterData()
    self._refId = self:GetWndArg("refId")
    local monsterRef = gModelHero:GetMonsterAttrByRefId(self._refId)
    if not monsterRef then
        return
    end

    self._monsterRef = monsterRef
    local effectId = monsterRef.effectId
    local effRef = gModelHero:GetShowEffectById(effectId)
    self._heroEffectRef = effRef
end

function UISagaSpreadNew:GetRuneRefInfo(runeServerList, heroInfo)
    runeServerList = runeServerList or {}
    local tRuneList = {}
    local runeRefIdList = self._runeRefIdList
    for i = 1, UISagaSpreadNew.MAX_RUNE_NUM do
        local runeRefId = runeRefIdList[i]
        local isLock = true
        local runePosRef = GameTable.MagicRunePosRef[runeRefId]
        local unlock = runePosRef.unlock
        local unlockTxt = ccLngText(runePosRef.text)
        unlock = string.split(unlock, "=")
        local condition
        if tonumber(unlock[1]) == 1 then
            condition = heroInfo.lv
        else
            condition = heroInfo.star
        end
        if condition >= tonumber(unlock[2]) then
            isLock = false
        end
        local runeData = runeServerList[i]
        local serverData = {}
        if runeData then
            if runeData["GetServerData"] then
                serverData = runeData:GetServerData()
            else
                serverData = runeData.runeInfo
            end
        end
        if not serverData then
            serverData = runeData
        end
        if serverData then
            serverData.isLock = isLock and not runeData
            serverData.unlockTxt = unlockTxt
        end
        table.insert(tRuneList, serverData)

    end
    return tRuneList
end

function UISagaSpreadNew:OnClickShareBtnFunc()
    if self._shareFunc then
        self._shareFunc()
    end
end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UISagaSpreadNew



