---
--- Created by LCM.
--- DateTime: 2024/3/24 14:26:40
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaTreeJN:LWnd
local UISagaTreeJN = LxWndClass("UISagaTreeJN", LWnd)

--- 装配
UISagaTreeJN.TYPE_VIEW_EQUIP = 1

--- 英雄详细界面预览
UISagaTreeJN.TYPE_VIEW_PREVIEW = 2

--- 英雄 refId 预览
UISagaTreeJN.TYPE_VIEW_HEROPREVIEW = 3

--- 英雄觉醒树 HeroTreePointLvRef 的 type 字段
UISagaTreeJN.TYPE_VIEW_SKILLPREVIEW = 4

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaTreeJN:UISagaTreeJN()
    self._initTargetIndex = true
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaTreeJN:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaTreeJN:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaTreeJN:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
    self:RefreshView()
end

function UISagaTreeJN:GetBotBtnList(skillInfoList)
    if not skillInfoList then return {} end
    local curPointLvRef
    local botBtnList = {}
    for i,v in ipairs(skillInfoList) do
        curPointLvRef = gModelHero:GetHeroTreePointLvRef(v.lvRefId)
        if curPointLvRef then
            table.insert(botBtnList,{
                btnName = ccClientText(37602) .. i,
                botIndex = i,
                curPointLvRef = curPointLvRef,
                serverData = v,
            })
        end
    end
    return botBtnList
end

function UISagaTreeJN:RefreshViewHeroPreview()
    local heroRefId = self:GetWndArg("heroRefId")
    if not heroRefId then return end

    local treeRefId 	= gModelHero:GetHeroAwakenByRefId(heroRefId)
    if not treeRefId then return end

    local treePointList = gModelHero:GetHeroTreePointList(treeRefId)
    if not treePointList then return end

    local skillInfoList = {}
    for k,v in ipairs(treePointList) do
        local treePointRefId = v.refId
        local data = gModelHero:GetHeroTreePointLvList(treePointRefId)
        if data.pointType == ModelHero.TREE_POINT_TYPE_SKILL then
            local lvList = data.lvList
            local firstLvRef = lvList[#lvList] --默认满级
            local lvRefId = firstLvRef.refId
            local curPointLvRef = gModelHero:GetHeroTreePointLvRef(lvRefId)
            local skillList = {}
            local skillInfo = gModelHeroExtra:GetHeroTreeSkillList(curPointLvRef)
            for idx,val in ipairs(skillInfo.skill) do
                table.insert(skillList,val)
            end
            for idx,val in ipairs(skillInfo.extraSkill) do
                table.insert(skillList,val)
            end
            table.insert(skillInfoList,{
                lvRefId = lvRefId,
                treePointRefId = treePointRefId,
                isActivate = true,
                curSelectSkillId = skillList[1],
                skillList = skillList,
            })
        end
    end

    local botBtnList = self:GetBotBtnList(skillInfoList)

    self:GetTargetIndex(botBtnList)

    self:InitSkillLvBtnList(botBtnList)
end

function UISagaTreeJN:RefreshViewPreview()
    self:InitHeroTreeSkillInfo()
end

function UISagaTreeJN:OnDrawSkillPreLvCell(list,item,itemdata,itempos)
    local SelTrans = self:FindWndTrans(item,"Sel")
    local LvTxtTrans = self:FindWndTrans(item,"LvTxt")
    local BtnTrans = self:FindWndTrans(item,"Btn")
    local skillLv = itemdata.skillLv
    local isSel = skillLv == self._skillPreLv
    CS.ShowObject(SelTrans,isSel)
    self:SetWndText(LvTxtTrans,skillLv)
    self:SetWndClick(BtnTrans,function()
        self:OnClickSkillPreLvFunc(itemdata)
    end)
end

function UISagaTreeJN:InitText()
    self:SetWndText(self.mSkillActViewShowBgTxt,ccClientText(37610))
    self:SetWndText(self.mSkillPreViewShowBgTxt,ccClientText(37604))
    self:SetWndText(self.mShowSkillActDesc,ccClientText(37611))
end

function UISagaTreeJN:GetSkillPreLvList()
end

function UISagaTreeJN:InitHeroTreeSkillInfo()
    local heroServerData = self:GetWndArg("heroServerData")
    if not heroServerData then return {} end
    self._heroServerData = heroServerData
    self:RefreshHeroTreeSkillInfo()
end

function UISagaTreeJN:GetSkillPreList()
end


------------------------- List -------------------------
function UISagaTreeJN:InitSkillActList(list)
    list = list or {}
    local uiSkillActList = self._uiSkillActList
    if uiSkillActList then
        uiSkillActList:RefreshList(list)
    else
        uiSkillActList = self:GetUIScroll("uiSkillActList")
        self._uiSkillActList = uiSkillActList
        uiSkillActList:Create(self.mSkillActList,list,function(...) self:OnDrawSkillActCell(...) end)
    end
    local enable = #list > 4
    uiSkillActList:EnableScroll(enable)
end

function UISagaTreeJN:OnDrawSkillActCell(list,item,itemdata,itempos)
    local SkillIconTrans = self:FindWndTrans(item,"Skill/SkillIcon")
    local SPImgTrans = self:FindWndTrans(item,"SPImg")
    local NameTextTrans = self:FindWndTrans(item,"NameText")
    local DescTextTrans = self:FindWndTrans(item,"DescDiv/DescText")
    local SelectBgTrans = self:FindWndTrans(item,"SelectBg")
    local BtnRootTrans = self:FindWndTrans(item,"BtnRoot")

    local isPointAct = itemdata.isPointAct
    local skillId = itemdata.skillId
    local baseClass = SkillIcon:New(self)
    if skillId then
        local curSelTreePointId = itemdata.curSelTreePointId
        baseClass:SetSkillInfo(nil,false,nil,1)
        baseClass:Create(SkillIconTrans,skillId,function()
            local skillList = gModelHero:GetTreePointSkillIdList(curSelTreePointId, itempos)
            if not table.isempty(skillList) then
                local firstSkillId = skillList[1]
                gModelGeneral:OpenSkillWnd({
                    skill = firstSkillId,
                    curSkillId = skillId,
                    wndType = 5,
                    pointActivate = isPointAct,
                })
            end
        end)
    else
        baseClass:SetShowIcon(false,false)
        baseClass:SetSkillInfo(nil,nil,nil,1)
        baseClass:Create(SkillIconTrans,0,function() end)
        baseClass:SetIconAndIconBgGray(false)
    end

    local skillRef = gModelHero:GetSkillByStarId(skillId)
    if skillRef then
        local skillName = ccLngText(skillRef.name)
        self:SetWndText(NameTextTrans,skillName)
        local description = ccLngText(skillRef.description)
        description = string.gsub(description, "30e005", "139057")
        self:SetWndText(DescTextTrans,description)
    end

    local isShowExtraSkillAct = false
    local isExtraSkillGrayBtn = false
    local skillType = itemdata.skillType
    local isExtra = skillType == ModelHero.TYPE_AWAKEN_SKILL_EXTRA
    if isExtra then
        if isPointAct then
            local isExtraSkillAct = itemdata.isExtraSkillAct
            if not isExtraSkillAct then
                isShowExtraSkillAct = true
            end
        else
            isShowExtraSkillAct = true
            isExtraSkillGrayBtn = true
        end
    end
    if isExtra then
        local SPNameTrans = self:FindWndTrans(SPImgTrans,"SPName")
        self:SetWndText(SPNameTrans,ccClientText(37617))
    end
    CS.ShowObject(SPImgTrans,isExtra)

    local showHeroPreview = self._viewType == UISagaTreeJN.TYPE_VIEW_HEROPREVIEW
    if showHeroPreview then
        isShowExtraSkillAct = false
    end

    local isShowSelectBg = not isShowExtraSkillAct
    if isShowSelectBg then
        local isSel = itemdata.isSel
        local BgTrans = self:FindWndTrans(SelectBgTrans,"Bg")
        CS.ShowObject(BgTrans,isPointAct)
        local SelectYesIconTrans = self:FindWndTrans(SelectBgTrans,"SelectIcon")
        CS.ShowObject(SelectYesIconTrans,isSel)

        local LockImgTrans = self:FindWndTrans(SelectBgTrans,"LockImg")
        CS.ShowObject(LockImgTrans,not isPointAct)


        self:SetWndClick(SelectBgTrans,function()
            self:OnClickHeroAwakenSkillSelectFunc(itemdata)
        end)
    end
    if isShowExtraSkillAct then
        local BtnYellow3Trans = self:FindWndTrans(BtnRootTrans,"BtnYellow3")
        local redPointTrans = self:FindWndTrans(BtnRootTrans,"redPoint")

        self:SetWndButtonText(BtnYellow3Trans,ccClientText(37600))

        --local areaOpen = gModelFunctionOpen:CheckAreaOpen(10306003)
        local areaOpen = false
        --local extraSkillIsOpen = not areaOpen and true or gModelFunctionOpen:CheckIsOpened(10306003)
        local extraSkillIsOpen = not areaOpen and true or false

        local showBtnGray = not extraSkillIsOpen or isExtraSkillGrayBtn
        self:SetWndButtonGray(BtnYellow3Trans,showBtnGray)

        self:SetWndClick(BtnYellow3Trans,function()
            if(not extraSkillIsOpen)then
--[[                local extraOpenDesc = gModelFunctionOpen:GetOpenTips(10306003)
                GF.ShowMessage(extraOpenDesc)]]
            else
                self:OnClickHeroAwakenSkillBtnFunc(itemdata)
            end
        end)
    end
    CS.ShowObject(SelectBgTrans,isShowSelectBg)
    CS.ShowObject(BtnRootTrans,isShowExtraSkillAct)
end

function UISagaTreeJN:RefreshHeroSkillPreviewList(itemdata)
    if not itemdata then return end
    local serverData = itemdata.serverData
    if not serverData then return end

    local treePointRefId = serverData.treePointRefId
    local typeList= gModelHero:GetHeroTreePointLvList(treePointRefId)
    if not typeList then return end

    local list = {}
    local refId,ref,skillInfo,skill,extraSkill
    local lvList = typeList.lvList
    for i,v in ipairs(lvList) do
        refId = v.refId
        ref = gModelHero:GetHeroTreePointLvRef(refId)
        if ref then
            skillInfo = gModelHeroExtra:GetHeroTreeSkillList(ref)
            skill = skillInfo.skill or {}
            extraSkill = skillInfo.extraSkill or {}
            if #skill > 0 or #extraSkill > 0 then
                local skillList = {}
                for idx,val in ipairs(skill) do
                    table.insert(skillList,{
                        skillId = val,
                        skillType = ModelHero.TYPE_AWAKEN_SKILL_DEFAULT,
                        curSelTreePointId = treePointRefId,
                    })
                end
                for idx,val in ipairs(extraSkill) do
                    table.insert(skillList,{
                        skillId = val,
                        skillType = ModelHero.TYPE_AWAKEN_SKILL_EXTRA,
                        curSelTreePointId = treePointRefId,
                    })
                end
                table.insert(list,{
                    skillList = skillList,
                    skillLv = ref.lv,
                })
            end
        end
    end
    self._skillPreLv = nil
    self:InitSkillPreLvList(list)
end

function UISagaTreeJN:OnClickSkillPreLvFunc(itemdata)
    if self._skillPreLv == itemdata.skillLv then return end
    self._skillPreLv = itemdata.skillLv
    self:InitSkillPreList(itemdata.skillList)
    local uiSkillPreLvList = self._uiSkillPreLvList
    if uiSkillPreLvList then
        local uiList = uiSkillPreLvList:GetList()
        uiList:RefreshList()
    end
end

function UISagaTreeJN:InitSkillPreList(list)
    list = list or {}
    local uiSkillPreList = self._uiSkillPreList
    if uiSkillPreList then
        uiSkillPreList:RefreshList(list)
    else
        uiSkillPreList = self:GetUIScroll("uiSkillPreList")
        self._uiSkillPreList = uiSkillPreList
        uiSkillPreList:Create(self.mSkillPreList,list,function(...) self:OnDrawSkillPreCell(...) end)
    end
end

function UISagaTreeJN:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mSkillActShowBgCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mSkillPreViewShowBgCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mActHelpBtn,function() self:OnClickActHelpBtnFunc() end)
end

function UISagaTreeJN:RefreshView()
    local viewType = self._viewType

    local showEquipView = viewType == UISagaTreeJN.TYPE_VIEW_EQUIP
    local showPreview = viewType == UISagaTreeJN.TYPE_VIEW_PREVIEW
    local showHeroPreview = viewType == UISagaTreeJN.TYPE_VIEW_HEROPREVIEW
    local showSkillPreview = viewType == UISagaTreeJN.TYPE_VIEW_SKILLPREVIEW

    if showEquipView then
        self:RefreshViewEquip()
    elseif showPreview then
        self:RefreshViewPreview()
    elseif showHeroPreview then
        showEquipView = true
        self:RefreshViewHeroPreview()
    elseif showSkillPreview then
        showPreview = true
        self:RefreshViewSkillPreview()
    end
    CS.ShowObject(self.mSkillActView,showEquipView)
    CS.ShowObject(self.mSkillPreView,showPreview)
end

function UISagaTreeJN:OnClickSkillLvBtnFunc(itemdata)
    if self._botIndex == itemdata.botIndex then return end
    local viewType = self._viewType
    local showEquipView = viewType == UISagaTreeJN.TYPE_VIEW_EQUIP
    local showPreview = viewType == UISagaTreeJN.TYPE_VIEW_PREVIEW
    local showHeroPreview = viewType == UISagaTreeJN.TYPE_VIEW_HEROPREVIEW
    local showSkillPreview = viewType == UISagaTreeJN.TYPE_VIEW_SKILLPREVIEW

    if showEquipView then
        local serverData = itemdata.serverData
        if serverData and (not serverData.isActivate) then
            GF.ShowMessage(ccClientText(20154))
            return
        end
    end

    self._botIndex = itemdata.botIndex

    local uiSkillLvBtnList = self._uiSkillLvBtnList
    if uiSkillLvBtnList then
        local uiList = uiSkillLvBtnList:GetList()
        uiList:RefreshList()
    end

    if showEquipView then
        self:RefreshSkillActList(itemdata)
    elseif showPreview then
        self:RefreshSkillPreList(itemdata)
    elseif showHeroPreview then
        self:RefreshHeroPreviewSkillActList(itemdata)
    elseif showSkillPreview then
        self:RefreshHeroSkillPreviewList(itemdata)
    end
end

function UISagaTreeJN:OnClickHeroAwakenSkillSelectFunc(itemdata)
    local isPointAct = itemdata.isPointAct
    if not isPointAct then
        GF.ShowMessage(ccClientText(37601))
        return
    end

    if itemdata.isSel then return end

    local showHeroPreview = self._viewType == UISagaTreeJN.TYPE_VIEW_HEROPREVIEW
    if showHeroPreview then
        GF.ShowMessage(ccClientText(20160))
        return
    end

    local skillId = itemdata.skillId

    local heroId = self._heroId
    gModelHero:OnHeroTreePointSelectSkillReq(heroId,itemdata.curSelTreePointId,skillId)
end

function UISagaTreeJN:RefreshSkillPreList(itemdata)
    if not itemdata then return end

    local serverData = itemdata.serverData
    if not serverData then return end

    local treePointRefId = serverData.treePointRefId
    local typeList= gModelHero:GetHeroTreePointLvList(treePointRefId)
    if not typeList then return end

    local list = {}
    local refId,ref,skillInfo,skill,extraSkill
    local lvList = typeList.lvList
    for i,v in ipairs(lvList) do
        refId = v.refId
        ref = gModelHero:GetHeroTreePointLvRef(refId)
        if ref then
            skillInfo = gModelHeroExtra:GetHeroTreeSkillList(ref)
            skill = skillInfo.skill or {}
            extraSkill = skillInfo.extraSkill or {}
            if #skill > 0 or #extraSkill > 0 then
                local skillList = {}
                for idx,val in ipairs(skill) do
                    table.insert(skillList,{
                        skillId = val,
                        skillType = ModelHero.TYPE_AWAKEN_SKILL_DEFAULT,
                        curSelTreePointId = treePointRefId,
                    })
                end
                for idx,val in ipairs(extraSkill) do
                    table.insert(skillList,{
                        skillId = val,
                        skillType = ModelHero.TYPE_AWAKEN_SKILL_EXTRA,
                        curSelTreePointId = treePointRefId,
                    })
                end
                table.insert(list,{
                    skillList = skillList,
                    skillLv = ref.lv,
                })
            end
        end
    end
    self._skillPreLv = nil
    self:InitSkillPreLvList(list)
end

function UISagaTreeJN:RefreshSkillActList(itemdata)
    if not itemdata then return end

    local curPointLvRef = itemdata.curPointLvRef
    if not curPointLvRef then return end

    local heroTreeServerData = self._heroTreeServerData
    if not heroTreeServerData then return end

    local serverData = itemdata.serverData
    if not serverData then return end

    local isActivate = serverData.isActivate
    local treePointRefId = serverData.treePointRefId
    local skillId = serverData.skillId
    local isSel
    local list = {}
    local skillInfo = gModelHeroExtra:GetHeroTreeSkillList(curPointLvRef)
    --- 当前等级技能id
    for i,v in ipairs(skillInfo.skill) do
        isSel = isActivate and skillId == v
        table.insert(list,{
            skillId = v,
            skillType = ModelHero.TYPE_AWAKEN_SKILL_DEFAULT,
            isPointAct = isActivate,
            curSelTreePointId = treePointRefId,
            isSel = isSel,
        })
    end
    self:InitSkillActList(list)
end


function UISagaTreeJN:InitMsg()



	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end


function UISagaTreeJN:RefreshHeroTreeSkillInfo(isForce)
    local heroServerData = self._heroServerData
    if not heroServerData then return {} end

    local heroTreeServerData = heroServerData.treeInfo
    if not heroTreeServerData then return {} end

    self._heroId = heroServerData.id
    self._heroServerData = heroServerData
    self._heroTreeServerData = heroTreeServerData

    local heroTreeInfoList = gModelHero:GetServerHeroTreeInfoByHeroId(heroServerData.id)
    if not heroTreeInfoList then return {} end

    local skillInfoList = {}
    local pointType
    for k,v in pairs(heroTreeInfoList) do
        pointType = v.pointType
        if pointType == ModelHero.TREE_POINT_TYPE_SKILL then
            table.insert(skillInfoList,v)
        end
    end

    table.sort(skillInfoList,function(a,b)
        return a.lvRefId < b.lvRefId
    end)

    self._skillInfoList = skillInfoList

    local botBtnList = self:GetBotBtnList(skillInfoList)

    self:GetTargetIndex(botBtnList)

    self:InitSkillLvBtnList(botBtnList,isForce)
end

function UISagaTreeJN:InitSkillPreLvList(list)
    list = list or {}
    local uiSkillPreLvList = self._uiSkillPreLvList
    if uiSkillPreLvList then
        uiSkillPreLvList:RefreshList(list)
    else
        uiSkillPreLvList = self:GetUIScroll("uiSkillPreLvList")
        self._uiSkillPreLvList = uiSkillPreLvList
        uiSkillPreLvList:Create(self.mSkillPreLvList,list,function(...) self:OnDrawSkillPreLvCell(...) end)
    end
    if not self._skillPreLv and list[1] then
        self:OnClickSkillPreLvFunc(list[1])
    end
end

function UISagaTreeJN:InitSkillLvBtnList(list,isForce)
    list = list or {}
    local uiSkillLvBtnList = self._uiSkillLvBtnList
    if uiSkillLvBtnList then
        uiSkillLvBtnList:RefreshList(list)
    else
        uiSkillLvBtnList = self:GetUIScroll("uiSkillLvBtnList")
        self._uiSkillLvBtnList = uiSkillLvBtnList
        uiSkillLvBtnList:Create(self.mSkillLvBtnList,list,function(...) self:OnDrawSkillLvBtnCell(...) end)
    end

    local data
    if isForce then
        local oldBotIndex = self._botIndex
        if oldBotIndex and list[oldBotIndex] then
            data = list[oldBotIndex]
        elseif list[1] then
            data = list[1]
        end
    else
        if self._targetIndex then
            data = list[self._targetIndex]
            if not data then
                data = list[1]
            end
            self._targetIndex = nil
        elseif list[1] then
            data = list[1]
        end
    end
    if data then
        self._botIndex = nil
        self:OnClickSkillLvBtnFunc(data)
    end
end

function UISagaTreeJN:OnClickActHelpBtnFunc()
    GF.OpenWnd("UIBzTips",{refId = 901})
end

function UISagaTreeJN:OnDrawSkillPreCell(list,item,itemdata,itempos)
    local SkillIconTrans = self:FindWndTrans(item,"Skill/SkillIcon")
    local SPImgTrans = self:FindWndTrans(item,"SPImg")
    local NameTextTrans = self:FindWndTrans(item,"NameText")
    local DescTextTrans = self:FindWndTrans(item,"PreSkillDiv/DescText")

    local skillId = itemdata.skillId
    local baseClass = SkillIcon:New(self)
    baseClass:SetSkillInfo(nil,false,nil,1)
    baseClass:Create(SkillIconTrans,skillId,function()
        local curSelTreePointId = itemdata.curSelTreePointId
        if not curSelTreePointId then return end
        local skillList = gModelHero:GetTreePointSkillIdList(curSelTreePointId, itempos)
        if not table.isempty(skillList) then
            local firstSkillId = skillList[1]
            gModelGeneral:OpenSkillWnd({
                skill = firstSkillId,
                curSkillId = skillId,
                wndType = 5,
                pointActivate = true,
            })
        end
    end)

    local skillRef = gModelHero:GetSkillByStarId(skillId)
    if skillRef then
        local skillName = ccLngText(skillRef.name)
        self:SetWndText(NameTextTrans,skillName)
        local description = ccLngText(skillRef.description)
        description = string.gsub(description, "30e005", "139057")
        self:SetWndText(DescTextTrans,description)
    end
    local skillType = itemdata.skillType
    local isExtra = skillType == ModelHero.TYPE_AWAKEN_SKILL_EXTRA
    if isExtra then
        local SPNameTrans = self:FindWndTrans(SPImgTrans,"SPName")
        self:SetWndText(SPNameTrans,ccClientText(37617))
    end
    CS.ShowObject(SPImgTrans,isExtra)
end

function UISagaTreeJN:RefreshViewEquip()
    self:InitHeroTreeSkillInfo()
end

function UISagaTreeJN:GetTargetIndex(botBtnList)
    if not botBtnList then return end
    if self._initTargetIndex then
        local targetIndex
        local targetTreePointRefId = self:GetWndArg("targetTreePointRefId")
        if targetTreePointRefId then
            for i,v in ipairs(botBtnList) do
                if v.serverData.treePointRefId == targetTreePointRefId then
                    targetIndex = i
                end
            end
        end
        self._initTargetIndex = false
        self._targetIndex = targetIndex
    end
end

function UISagaTreeJN:InitData()
    self._viewType = self:GetWndArg("viewType") or UISagaTreeJN.TYPE_VIEW_PREVIEW
end

function UISagaTreeJN:RefreshHeroPreviewSkillActList(itemdata)
    if not itemdata then return end

    local curPointLvRef = itemdata.curPointLvRef
    if not curPointLvRef then return end

    local serverData = itemdata.serverData
    if not serverData then return end

    local isActivate = serverData.isActivate
    local curSelectSkillId = serverData.curSelectSkillId
    local treePointRefId = serverData.treePointRefId
    local skillId = serverData.skillId
    local isSel
    local list = {}
    local skillInfo = gModelHeroExtra:GetHeroTreeSkillList(curPointLvRef)
    --- 当前等级技能id
    for i,v in ipairs(skillInfo.skill) do
        isSel = isActivate and curSelectSkillId == v
        table.insert(list,{
            skillId = v,
            skillType = ModelHero.TYPE_AWAKEN_SKILL_DEFAULT,
            isPointAct = isActivate,
            curSelTreePointId = treePointRefId,
            isSel = isSel,
        })
    end
    self:InitSkillActList(list)
end

function UISagaTreeJN:OnDrawSkillLvBtnCell(list,item,itemdata,itempos)
    local BtnTab1Trans = self:FindWndTrans(item,"BtnTab1")
    local botIndex = itemdata.botIndex
    local isSel = botIndex == self._botIndex
    local bgState = isSel and LWnd.StateOn or LWnd.StateOff

    local viewType = self._viewType
    local showEquipView = viewType == UISagaTreeJN.TYPE_VIEW_EQUIP
    if showEquipView then
        local serverData = itemdata.serverData
        if serverData and (not serverData.isActivate) then
            bgState = LWnd.StateGray
        end
    end
    self:SetWndTabStatus(BtnTab1Trans,bgState)

    self:SetWndTabText(BtnTab1Trans,itemdata.btnName)
    self:SetWndClick(BtnTab1Trans,function()
        self:OnClickSkillLvBtnFunc(itemdata)
    end)
end

function UISagaTreeJN:RefreshViewSkillPreview()
    local heroTreePointLvList = self:GetWndArg("heroTreePointLvList")
    if not heroTreePointLvList then return end

    local skillInfoList = {}
    local data,lvList,skillInfo
    for i,v in ipairs(heroTreePointLvList) do
        data = gModelHero:GetHeroTreePointLvListByType(v)
        if data and data.pointType == ModelHero.TREE_POINT_TYPE_SKILL then
            lvList = data.lvList or {}
            local lvRefId = lvList[1].refId
            local curPointLvRef = gModelHero:GetHeroTreePointLvRef(lvRefId)
            skillInfo = gModelHeroExtra:GetHeroTreeSkillList(curPointLvRef)
            local skillList = {}
            for idx,val in ipairs(skillInfo.skill) do
                table.insert(skillList,{
                    skillId = val,
                    skillType = ModelHero.TYPE_AWAKEN_SKILL_DEFAULT,
                    curSelTreePointId = v,
                })
            end
            for idx,val in ipairs(skillInfo.extraSkill) do
                table.insert(skillList,{
                    skillId = val,
                    skillType = ModelHero.TYPE_AWAKEN_SKILL_DEFAULT,
                    curSelTreePointId = v,
                })
            end
            table.insert(skillInfoList,{
                lvRefId = lvRefId,
                treePointRefId = v,
                isActivate = true,
                curSelectSkillId = skillList[1],
                skillList = skillList,
            })
        end
    end

    table.sort(skillInfoList,function(a,b)
        return a.lvRefId < b.lvRefId
    end)

    local botBtnList = self:GetBotBtnList(skillInfoList)

    self:GetTargetIndex(botBtnList)

    self:InitSkillLvBtnList(botBtnList)
end

function UISagaTreeJN:OnClickHeroAwakenSkillBtnFunc(itemdata)
    local isPointAct = itemdata.isPointAct
    if not isPointAct then
        GF.ShowMessage(ccClientText(37601))
        return
    end
    local heroServerData = self._heroServerData
    if not heroServerData then return end

    gModelHero:ClearUpLvTreeSelHeroList()
end

------------------------- List -------------------------

------------------------------------------------------------------
return UISagaTreeJN



