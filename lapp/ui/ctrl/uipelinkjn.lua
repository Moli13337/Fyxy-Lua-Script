---
--- Created by Administrator.
--- DateTime: 2024/6/13 15:19:48
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeLinkJN:LWnd
local UIPeLinkJN = LxWndClass("UIPeLinkJN", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeLinkJN:UIPeLinkJN()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeLinkJN:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeLinkJN:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeLinkJN:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isJapaness = gLGameLanguage:IsJapanVersion()

    self.refId = self:GetWndArg("refId")
    self:SetWndText(self.mTxtDesc, ccClientText(43735))
    self:SetWndText(self.mCloseTip, ccClientText(10103))
    self:SetWndText(self.mCloseTip_jap, ccClientText(10103))
    self:SetWndText(self.mTxtTitle, ccClientText(43734))
    CS.ShowObject(self.mCenterView_Jap, false)
    CS.ShowObject(self.mCenterView, false)
    if self._isJapaness then
        self:SetWndText(self.mTxtDesc_Jap, ccClientText(43735))
        self:SetWndText(self.mTxtTitle_Jap, ccClientText(43734))
        CS.ShowObject(self.mCenterView_Jap, true)
    else
        CS.ShowObject(self.mCenterView, true)
    end

    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
    self:UpdateAttrs()
end

function UIPeLinkJN:OnDrawSkillCell(list, item, itemdata, itempos)
    local AttrName = self:FindWndTrans(item, "AttrName")
    local AttrValue = self:FindWndTrans(item, "AttrValue")
    local skillCfg = GameTable.SnakeSkillRef[itemdata.skillId]
    local petInfo = gModelPet:GetPetById(self.refId)
    local star = petInfo._star
    self:SetWndText(AttrName, skillCfg and "<color=#d2730f>Lv." .. itemdata.skillILv .. "</color>：" .. ccLngText(skillCfg.description) or "")
    self:SetWndText(AttrValue, star < itemdata.rankNow and string.replace(ccClientText(43713), itemdata.rankNow) or (petInfo.isActive and ccClientText(43724) or ccClientText(43763)))
    self:SetXUITextTransColor(AttrValue, (petInfo.isActive and star >= itemdata.rankNow) and "259c43ff" or "c81212ff")
    local height = LxUiHelper.FindXTextCtrl(AttrName).preferredHeight
    local height2 = LxUiHelper.FindXTextCtrl(AttrValue).preferredHeight
    local sizeDel = item.sizeDelta
    sizeDel.y = (height + height2)-->88 and height+ height2 or 88
    item.sizeDelta = sizeDel
end
function UIPeLinkJN:UpdateAttrs()
    local petStarCfg = gModelPet.petStarCfg[self.refId]
    local skills = {}
    local skillMap = {}
    local count = #petStarCfg
    for i = 0, count do
        local value = petStarCfg[i]
        if value.skillId and value.skillId > 0 and not skillMap[value.skillId] then
            table.insert(skills, value)
            skillMap[value.skillId] = true
        end
    end

    if not self._uiList then
        local uiAttrList = self:GetUIScroll("PetLvAttrList")

        if self._isJapaness then
            self._uiList = uiAttrList:Create(self.mListSkill_Jap, skills, function(...)
                self:OnDrawSkillCell(...)
            end, UIItemList.SUPER)
        else
            self._uiList = uiAttrList:Create(self.mListSkill, skills, function(...)
                self:OnDrawSkillCell(...)
            end)
        end
    else
        self._uiList:RefreshData(skills, true)
        self._uiList:DrawAllItems()
    end
end

------------------------------------------------------------------
return UIPeLinkJN