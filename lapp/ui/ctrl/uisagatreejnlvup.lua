---
--- Created by LCM.
--- DateTime: 2024/3/27 22:09:39
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaTreeJNLvUp:LWnd
local UISagaTreeJNLvUp = LxWndClass("UISagaTreeJNLvUp", LWnd)
UISagaTreeJNLvUp.TYPE_VIEW_AWAKEN = 1
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaTreeJNLvUp:UISagaTreeJNLvUp()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaTreeJNLvUp:OnWndClose()
    gModelHero:ClearUpLvTreeSelHeroList()

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaTreeJNLvUp:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaTreeJNLvUp:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
    self:SetWndText(self.mCloseTips,ccClientText(10103))
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end
------------------------- List -------------------------


function UISagaTreeJNLvUp:GetAwakenSkillList(skillInfo,extraData)
    if not skillInfo then return {} end
    extraData = extraData or {}
    local list = {}
    local skill = skillInfo.skill
    for i,v in ipairs(skill) do
        table.insert(list,{
            skillId = v,
            skillType = ModelHero.TYPE_AWAKEN_SKILL_DEFAULT,
        })
    end
    return list
end

function UISagaTreeJNLvUp:RefreshView()
    local viewType = self._viewType
    if viewType == UISagaTreeJNLvUp.TYPE_VIEW_AWAKEN then
        CS.ShowObject(self.mAwakenView,true)
        self:RefreshAwakenView()
    end
end

function UISagaTreeJNLvUp:InitMsg()

    self:WndNetMsgRecv(LProtoIds.HeroTreePointSelectSkillResp,function(pb) self:OnHeroTreePointSelectSkillResp(pb) end)
	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UISagaTreeJNLvUp:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UISagaTreeJNLvUp:RefreshAwakenView()
    self:CreateCommonTitleEff()
    self:SetTitleImg("heroup_txt_2",function()
    end)

    local heroId = self:GetWndArg("heroId")
    if not heroId then return end

    local heroServerData = gModelHero:GetHeroServerDataById(heroId)
    if not heroServerData then return end

    self._heroId = heroId
    self._heroServerData = heroServerData

--[[    local awakenTreePointId = self:GetWndArg("awakenTreePointId")
    if not awakenTreePointId then return end

    local treeInfo = gModelHero:GetServerHeroTreePointInfo(heroId,awakenTreePointId)
    if not treeInfo then return end

    local ref = gModelHero:GetHeroTreePointLvRef(treeInfo.lvRefId)
    if not ref then return end

    local skillId = treeInfo.skillId
    local skillRef = gModelHero:GetSkillByStarId(skillId)
    if skillRef then
        local nameText = ccLngText(skillRef.name)
        local str = string.replace(ccClientText(20156), nameText)
        self:SetXUITextText(self.mAwakenTxt, str)
    end

    local skillInfo = gModelHeroExtra:GetHeroTreeSkillList(ref)
    self:InitAwakenSkillList(skillInfo)]]

    local actLvRefId = self:GetWndArg("actLvRefId")
    if not actLvRefId or actLvRefId < 1 then return end

    local ref = gModelHero:GetHeroTreePointLvRef(actLvRefId)
    if not ref then return end

    local pointRefId = self:GetWndArg("pointRefId")
    if not pointRefId then return end

    self._pointRefId = pointRefId

    local skill = ref.skill
    if skill and skill ~= "" then
        local curSelSkill
        if pointRefId and pointRefId > 0 then
            ---@type StructHeroTreeInfo
            local treeInfo = heroServerData.treeInfo
            if treeInfo and treeInfo.pointMap[pointRefId] then
                ---@type StructHeroTreePointInfo
                local point = treeInfo.pointMap[pointRefId]
                curSelSkill = point.skillId
            end
        end
        self._curSelSkill = curSelSkill
        local list = {}
        local tSkill = string.split(skill,"|")
        local isCanChangeSkill = #tSkill > 1
        for i,v in ipairs(tSkill) do
            table.insert(list,{
                skillId = checknumber(v),
                canChangeSkill = isCanChangeSkill,
            })
        end
        self:InitAwakenSkillList(list)
    end
end

function UISagaTreeJNLvUp:CreateCommonTitleEff(effName)
    effName = effName or "fx_ui_shengxing_1"
    self:CreateWndEffect(self.mShowEffRoot,effName,effName,100,false,false,
            nil,function(dpTrans)
        dpTrans.gameObject:SetActive(true)
        CS.ShowObject(self.mShowEffRoot,true)
    end)
end

function UISagaTreeJNLvUp:InitData()
    local viewType = self:GetWndArg("viewType") or UISagaTreeJNLvUp.TYPE_VIEW_AWAKEN
    self._viewType = viewType
end

function UISagaTreeJNLvUp:OnHeroTreePointSelectSkillResp(pb)
    self._curSelSkill = pb.skillId
    local uiAwakenSkillList = self._uiAwakenSkillList
    if uiAwakenSkillList then
        local uiList = uiAwakenSkillList:GetList()
        uiList:RefreshList()
    end
end

function UISagaTreeJNLvUp:InitAwakenSkillList(list,extraData)
    --local list = self:GetAwakenSkillList(skillInfo,extraData)
    local uiAwakenSkillList = self._uiAwakenSkillList
    if uiAwakenSkillList then
        uiAwakenSkillList:RefreshList(list)
    else
        uiAwakenSkillList = self:GetUIScroll("uiAwakenSkillList")
        self._uiAwakenSkillList = uiAwakenSkillList
        uiAwakenSkillList:Create(self.mAwakenSkillList,list,function(...) self:OnDrawAwakenSkillCell(...) end)
    end
end

function UISagaTreeJNLvUp:OnDrawAwakenSkillCell(list,item,itemdata,itempos)
    local CommonUITrans = self:FindWndTrans(item,"CommonUI")
    local RootTrans = self:FindWndTrans(CommonUITrans,"Root")
    local SkillIconTrans = self:FindWndTrans(RootTrans,"SkillIcon")


    local skillId = itemdata.skillId
    local baseClass = SkillIcon:New(self)
    if skillId then
        baseClass:SetSkillInfo(nil,false,nil,1)
        baseClass:Create(SkillIconTrans,skillId,function()
            local skillData = gModelHero:GetSkillByStarId(skillId)
            if not skillData then return end

            local heroData = gModelHero:GetHeroServerDataById(self._heroId)
            if not heroData then return end

            gModelGeneral:OpenSkillWnd({
                wndType = 5,
                curSkillId = skillId,
                skill = skillId,
                pointActivate = true,
            })
        end)
    else
        baseClass:SetShowIcon(false,false)
        baseClass:SetSkillInfo(nil,nil,nil,1)
        baseClass:Create(SkillIconTrans,0,function() end)
        baseClass:SetIconAndIconBgGray(false)
    end

    local Name = self:FindWndTrans(item,"Name")
    local name = ""
    local skillRef = skillId and GameTable.SnakeSkillRef[skillId]
    if skillRef then
        name = ccLngText(skillRef.name)
    end
    self:SetWndText(Name,name)

    local SelectBg = self:FindWndTrans(item,"SelectBg")
    local canChangeSkill = itemdata.canChangeSkill
    if canChangeSkill then
        local SelectYesIcon = self:FindWndTrans(SelectBg,"SelectYesIcon")
        CS.ShowObject(SelectYesIcon,self._curSelSkill == skillId)
        self:SetWndClick(SelectBg,function()
            self:OnClickSkillSelBg(itemdata)
        end)
    end
    CS.ShowObject(SelectBg,canChangeSkill)
end


function UISagaTreeJNLvUp:OnClickSkillSelBg(itemdata)
    local skillId = itemdata.skillId
    if self._curSelSkill == skillId then return end

    local heroId = self._heroId
    gModelHero:OnHeroTreePointSelectSkillReq(heroId,self._pointRefId,skillId)
end

function UISagaTreeJNLvUp:SetTitleImg(img,func)
    self:SetWndEasyImage(self.mTitle,img,function()
        if func then func() end
        CS.ShowObject(self.mTitle,true)
    end, true)
end

------------------------- List -------------------------

------------------------------------------------------------------
return UISagaTreeJNLvUp



