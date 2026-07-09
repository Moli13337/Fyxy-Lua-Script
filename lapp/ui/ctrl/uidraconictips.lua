---
--- Created by wzz.
--- DateTime: 2024/9/27 17:08:31
---
------------------------------------------------------------------

local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder

local LWnd = LWnd
---@class UIDraconicTips:LWnd
local UIDraconicTips = LxWndClass("UIDraconicTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDraconicTips:UIDraconicTips()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDraconicTips:OnWndClose()
    LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDraconicTips:OnCreate()
    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDraconicTips:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    if self._isEnus or self._isVie then
        self:InitTextLineWithLanguage(self.mTxtSkillDesc1, 35)

        self:SetAnchorPos(self.mSkillFlagRoot, Vector2.New(130, 155.4))
        CS.ShowObject(self.mTxtSkillName, false)
    else
        CS.ShowObject(self.mTxtSkillName, true)
    end

    self.jpj = gLGameLanguage:IsJapanVersion()

    if self.jpj then
        self:SetAnchorPos(self.mSkillFlagRoot, Vector2.New(130, 155.4))
        CS.ShowObject(self.mTxtSkillName, false)
    end
    
    self:InitData()
    self:InitTexts()
    self:InitEvents()
    self:Refresh()
end

-- 刷新属性
function UIDraconicTips:RefreshAttr()
    local curAttrList = {}
    local refId = self._refId
    local starNum = self._starNum
    if starNum == -1 then
        -- 未激活
        curAttrList = gModelDraconic:GetSpeechBaseAttr(refId, 0)
    else
        curAttrList = gModelDraconic:GetSpeechBaseAttr(refId, starNum)
    end

    self:SetComList(self.mAttrList, curAttrList, function(...)
        return self:OnDrawAttrItem(...)
    end)
end

-- 星级列表 item
function UIDraconicTips:OnDrawStarListItem(list, item, itemdata, itempos)
    local instanceID = item:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {}
        itemCache.txtDesc = CS.FindTrans(item, "TxtDesc")
        local list = {}
        local list2 = {}
        for i = 1, 10 do
            list[i] = CS.FindTrans(item, "starRoot/star" .. i)
            list2[i] = CS.FindTrans(item, "starRoot/star" .. i .. "/gray")
        end
        itemCache.starList = list
        itemCache.starList2 = list2
        self:SetComponentCache(instanceID, itemCache)
    end

    local starNum = itemdata.rankNow
    local gray = self._starNum < starNum

    local strDesc = ccLngText(itemdata.effectExtraDesc)
    if gray then
        strDesc = string.gsub(strDesc, "<color.->", "")
        strDesc = string.gsub(strDesc, "</color>", "")
        strDesc = "<color=#5f6d7b>" .. strDesc .. "</color>"
    end

    self:SetWndText(itemCache.txtDesc, strDesc)
    LayoutRebuilder.ForceRebuildLayoutImmediate(item)

    -- 星星
    if starNum then
        if starNum <= 5 then
            for i = 1, 5 do
                CS.ShowObject(itemCache.starList[i], i <= starNum)
                CS.ShowObject(itemCache.starList2[i], gray)
            end
            for i = 6, 10 do
                CS.ShowObject(itemCache.starList[i], false)
            end
        else
            for i = 1, 5 do
                CS.ShowObject(itemCache.starList[i], false)
            end
            for i = 6, 10 do
                CS.ShowObject(itemCache.starList[i], i <= starNum)
                CS.ShowObject(itemCache.starList2[i], gray)
            end
        end
    end
end

-- 刷新星级列表
function UIDraconicTips:RefreshStarList()
    if not self._uiList then
        local uiList = self:GetUIScroll("mList")
        self._uiList = uiList

        local list = gModelDraconic:GetUpStarRefList(self._refId)
        local dataList = {}
        for k, v in pairs(list) do
            if k > 0 then
                dataList[k] = v
            end
        end
        uiList:Create(self.mList, dataList, function(...)
            self:OnDrawStarListItem(...)
        end, UIItemList.SUPER, true)
    else
        self._uiList:DrawAllItems()
    end
end

-- 界面刷新
function UIDraconicTips:Refresh()
    local refId = self._refId
    local starNum = self._starNum
    local ref = gModelDraconic:GetDraconicRef(refId)
    local upRef = gModelDraconic:GetUpStarRef(refId, math.max(0, starNum))
    local skillRef = GameTable.SnakeSkillRef[upRef.skillId]

    -- 卡片
    local param = {
        refId = refId,
        showType = true,
        starNum = starNum,
        showName = true,
    }

    gModelDraconic:DrawCard(self, self.mDraconicCard, param)

    --
    local color = gModelItem:GetColorStringByQualityId(ref.quality)
    local strName = ccClientText(41021, color, ccLngText(ref.name))
    self:SetWndText(self.mTxtSkillName, strName)

    -- 属性
    self:RefreshAttr()

    -- 技能标签
    gModelDraconic:DrawSkillFlag(self, self.mSkillFlag, refId)

    -- 技能图标
    self:SetWndEasyImage(self.mSkillBg, ref.skillbg)
    self:SetWndEasyImage(self.mSkillIcon, ref.skillIcon)

    self:SetWndText(self.mTxtSkillLev, ccClientText(41036, starNum + 1))
    self:SetWndText(self.mTxtSkillDesc1, "           " .. ccLngText(skillRef.description))
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.mTxtSkillDesc1)

    -- 附魂
    self:RefreshAttach()

    -- 调整窗口大小
    self:AdjustWndSize()

    self:RefreshStarList()
end

-- 调整窗口大小
function UIDraconicTips:AdjustWndSize()

    -- 正常显示文本、显示附魂，时的各ui初始值
    -- 变量名为：控件名_标识
    local Panel_H = 800
    local List_H = 225
    local List_Y = -180
    local Skill2_H = 127
    local Skill2_Y = 147
    local TxtSkillDesc_H = 90

    -- 文本增加的高度
    local txtAddH = self.mTxtSkillDesc1.rect.height - TxtSkillDesc_H

    -- 列表高度
    local listH = List_H

    -- 技能文本增加的高度
    local txtSkillAddH = 0
    if self.mSkill2.gameObject.activeSelf then
        txtSkillAddH = self.mSkill2.rect.height - Skill2_H
        self.mSkill2.anchoredPosition = Vector2(0, Skill2_Y + txtSkillAddH)
    else
        listH = List_H + 63
        txtSkillAddH = -55
    end

    LxUiHelper.SetSizeWithCurAnchor(self.mPanel, 1, Panel_H + txtAddH + txtSkillAddH)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.mPanel)

    LxUiHelper.SetSizeWithCurAnchor(self.mList, 1, listH)
    self.mList.anchoredPosition = Vector2(0, List_Y - txtAddH)


end

-- 初始化数据
function UIDraconicTips:InitData()
    self._refId = self:GetWndArg("refId")
    self._starNum = self:GetWndArg("starNum")
    self._tips = self:GetWndArg("tips")
    self._attachUpRef = self:GetWndArg("attachUpRef")
    self._attachUpRef = nil
end

-- 属性列表 item
function UIDraconicTips:OnDrawAttrItem(uiList, item, data)
    if not uiList then
        uiList = {}
        uiList.icon = CS.FindTrans(item, "AttrIcon")
        uiList.txt = CS.FindTrans(item, "AttrValue")
        uiList.name = CS.FindTrans(item, "AttrName")
    end

    local iconPath = gModelHero:GetAttributeIconById(data.attrId)
    self:SetWndEasyImage(uiList.icon, iconPath)

    local val = gModelHero:GetAttributeValueNoNameByIdAndVal(data.attrId, data.type, data.value)
    self:SetWndText(uiList.txt, val)

    local name = gModelHero:GetAttributeNameById(data.attrId)
    self:SetWndText(uiList.name, name)
    return uiList
end

-- 初始事件
function UIDraconicTips:InitEvents()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
end

-- 刷新附魂
function UIDraconicTips:RefreshAttach()
    local upRef = self._attachUpRef
    if upRef then
        local refId = upRef.type
        local starNum = upRef.rankNow
        local ref = gModelDraconic:GetDraconicRef(refId)
        local per = gModelDraconic:GetAttachTriggerRate(refId, starNum)
        local data = {}
        data.refId = refId
        data.txtTips = ccLngText(ref.name)
        data.txtTips2 = ccClientText(41091, per)

        gModelDraconic:DrawSkillTemplate(self, self.mSkill2, data)

        LayoutRebuilder.ForceRebuildLayoutImmediate(self.mTxtSkillDesc)
        LayoutRebuilder.ForceRebuildLayoutImmediate(self.mSkill2)
    end
    CS.ShowObject(self.mSkill2, upRef ~= nil)
end

-- 初始界面化文本
function UIDraconicTips:InitTexts()
    self:SetWndText(self.mCloseTip, ccClientText(10103))
    self:SetWndText(self.mTxtTips, ccClientText(41034))
end

------------------------------------------------------------------
return UIDraconicTips