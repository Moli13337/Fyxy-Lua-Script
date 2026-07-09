---
--- Created by Administrator.
--- DateTime: 2023/10/11 16:46:45
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFlandBossStrategy:LWnd
local UIFlandBossStrategy = LxWndClass("UIFlandBossStrategy", LWnd)

UIFlandBossStrategy.NORMAL = 1
UIFlandBossStrategy.INVASION = 2
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFlandBossStrategy:UIFlandBossStrategy()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFlandBossStrategy:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFlandBossStrategy:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFlandBossStrategy:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitData()
    self:InitEvent()
    self:InitMsg()
    self:SetContent()

    self:SetWndText(self.mTitleText, ccClientText(18739))
    self:SetWndText(self.mDescTitleText, ccClientText(18742))
    self:SetWndText(self.mDesText, self._desc)
end

function UIFlandBossStrategy:OnDrawNormalSkill(list, item, itemdata, itempos)
    local skillId = tonumber(itemdata)

    local skillIconTrans = CS.FindTrans(item, "Skill/SkillIcon")
    if skillIconTrans then
        local baseClass = SkillIcon:New(self)
        baseClass:SetSkillInfo(nil, false, nil, 1)
        baseClass:ShowLvl(false)
        baseClass:ShowLock(false)
        baseClass:Create(skillIconTrans, skillId, function()
            self:OnClickNormalSkill(skillId)
        end)
        baseClass:SetIconAndIconBgGray(false)
    end

    local skillRef = gModelHero:GetSkillByStarId(skillId)
    if not skillRef then
        return
    end

    local nameText = CS.FindTrans(item, "NameText")
    if nameText then
        self:SetWndText(nameText, ccLngText(skillRef.name))
    end

    local descText = CS.FindTrans(item, "DescText")

    if descText then
        local descStr = ccLngText(skillRef.description)
        descStr = string.gsub(descStr, "30e005", "139057")
        self:SetWndText(descText, descStr)
    end
    LayoutRebuilder.ForceRebuildLayoutImmediate(descText)
    LayoutRebuilder.ForceRebuildLayoutImmediate(item)
end

function UIFlandBossStrategy:InitEvent()
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mBgImage, function()
        self:WndClose()
    end)
end

local typeScrollRect = typeof(CS.ScrollRect)
function UIFlandBossStrategy:OnDrawInvasionSkill(list, item, itemdata, itempos)
    local Image = self:FindWndTrans(item, "Image")
    local Skill = self:FindWndTrans(item, "Skill")
    local SkillSkillIcon = self:FindWndTrans(Skill, "SkillIcon")
    local NameText = self:FindWndTrans(item, "NameText")
    --local DescText = self:FindWndTrans(item,"DescText")

    local scroll = CS.FindTrans(item, "DescScroll")
    local viewport = CS.FindTrans(scroll, "Viewport")
    local content = CS.FindTrans(viewport, "Content")
    local DescText = CS.FindTrans(content, "DescText")

    local skillId = tonumber(itemdata)

    local skillIconTrans = CS.FindTrans(item, "Skill/SkillIcon")
    if skillIconTrans then
        local data = {
            trans = SkillSkillIcon,
            level = 1,
            refId = skillId,
            tipFunc = function()
                --GF.OpenWnd("UINewJNTip",{curSkillId = skillId,wndType = 2})
                gModelGeneral:OpenSkillWnd({ curSkillId = skillId, wndType = 2 })
            end,
        }
        local skillIcon = SkillIcon:New(self)
        skillIcon:Show(data)
    end

    local skillRef = gModelSkill:GetSkillRef(skillId)
    if not skillRef then
        return
    end
    self:SetWndText(NameText, ccLngText(skillRef.name))

    local descStr = ccLngText(skillRef.description)
    descStr = string.gsub(descStr, "30e005", "139057")
    self:SetWndText(DescText, descStr)

    local delayFrame = function()
        LxTimer.DelayFrameCall(function()
            local height = DescText.rect.height
            local scrollTrans = scroll.gameObject:GetComponent(typeScrollRect)

            scrollTrans.vertical = height > 75

        end, 1)
    end
    delayFrame()

end

function UIFlandBossStrategy:RefreshSkillList()
    local heroSkillIdList = self._skillDataList

    local skillScrollList = self._skillScrollList
    if (skillScrollList) then
        skillScrollList:RefreshList(heroSkillIdList)
    else
        skillScrollList = self:GetUIScroll("_skillScroll")
        skillScrollList:Create(self.mSkillScroll, heroSkillIdList, function(...)
            self:SkillListItem(...)
        end)
        skillScrollList:EnableScroll(true)
    end
end

function UIFlandBossStrategy:SetContent()
    self:RefreshSkillList()
end

function UIFlandBossStrategy:SkillListItem(...)
    self:OnDrawInvasionSkill(...)
    --if self._wndType == UIFlandBossStrategy.NORMAL then
    --	self:OnDrawNormalSkill(...)
    --else
    --	self:OnDrawInvasionSkill(...)
    --end
end

function UIFlandBossStrategy:InitData()
    --self._pageId = ModelActivity.FAIRYLAND_BOSS	--挑战配置
    --self._sid = self:GetWndArg("sid")
    self._desc = self:GetWndArg("desc")
    self._skill = self:GetWndArg("skill")

    self._wndType = self:GetWndArg("wndType") or UIFlandBossStrategy.NORMAL

    if self._wndType == UIFlandBossStrategy.NORMAL then
        self._skillDataList = string.split(self._skill, ',')
    else
        self._skillDataList = self:GetWndArg("skillDataList")
    end

end

function UIFlandBossStrategy:OnClickNormalSkill(skillId)
    local skillData = gModelHero:GetSkillByStarId(skillId)
    if not skillData then
        return
    end

    local lv = skillData.level
    local other = { lv = lv }
    GF.OpenWndTop("UIJNInfo", { skillId = skillId, other = other })
end

function UIFlandBossStrategy:InitMsg()
    self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN, function()
        self:WndClose()
    end)
    self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP, function()
        self:WndClose()
    end)
end

------------------------------------------------------------------
return UIFlandBossStrategy


