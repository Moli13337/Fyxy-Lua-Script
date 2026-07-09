---
--- Created by Administrator.
--- DateTime: 2023/10/24 16:03:55
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UINewJNTip:LWnd
local UINewJNTip = LxWndClass("UINewJNTip", LWnd)
local CS = CS
local typeof = typeof
local typeScrollRect = typeof(CS.ScrollRect)

UINewJNTip.MAX_SKILL_NUM = 5

UINewJNTip.NORMAL = 1                --英雄技能
UINewJNTip.SIMPLE = 2
UINewJNTip.RUNESKILL = 3            --符文技能
UINewJNTip.GUILDSKILL = 4            --公会技能
UINewJNTip.AWAKEN_SKILL = 5            --觉醒技能
UINewJNTip.HEROCORE_SKILL = 6        --核心技能
UINewJNTip.SORCERYCARD_SKILL = 7	--奎特牌技能
-- UINewJNTip.CRYSTAL_SKILL = 8	    --魔晶技能【G公共支持】删除伙伴晶石功能相关数据
UINewJNTip.HIDE_LEVEL = 9        --隐藏等级技能
-- UINewJNTip.PET_SKILL = 10	    --宠物技能技能【C宠物系统】删掉宠物系统相关
UINewJNTip.COMMON_SKILL = 11        --通用展示技能
UINewJNTip.SKILL_GIFT = 12        -- 天赋技能

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UINewJNTip:UINewJNTip()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UINewJNTip:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UINewJNTip:OnCreate()
    LWnd.OnCreate(self)
    self._skillIcon = nil
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UINewJNTip:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    
    self:InitText()
    self:InitEvent()

    local wndType = self:GetWndArg("wndType") or UINewJNTip.NORMAL
    self._wndType = wndType
    if wndType == UINewJNTip.NORMAL then
        self:InitData()
    elseif wndType == UINewJNTip.SIMPLE then
        self:RefreshUI_Simple()
    elseif wndType == UINewJNTip.RUNESKILL then
        self:RefreshRuneSkill()
    elseif wndType == UINewJNTip.GUILDSKILL then
        self:InitBtnDate()
    elseif wndType == UINewJNTip.AWAKEN_SKILL then
        self:InitBtnDate()
    elseif wndType == UINewJNTip.HEROCORE_SKILL then
        self:InitHreoCoreData()
        elseif wndType == UINewJNTip.SORCERYCARD_SKILL then
        	self:InitSorceryCard()
        -- 【G公共支持】删除伙伴晶石功能相关数据
        -- elseif wndType == UINewJNTip.CRYSTAL_SKILL then
        -- 	self:InitBtnDate()
    elseif wndType == UINewJNTip.HIDE_LEVEL then
        self:RefreshUI_SimpleHide()
        -- 【C宠物系统】删掉宠物系统相关
        -- elseif wndType == UINewJNTip.PET_SKILL then
        -- 	self:InitPetData()
    elseif wndType == UINewJNTip.COMMON_SKILL then
        self:InitCommonData()
    elseif wndType == UINewJNTip.SKILL_GIFT then
        self:InitCommonData()
    end
    self:RefreshView()

    local csScrollRect = self.mAniRootScroll.gameObject:GetComponent(typeScrollRect)
    if csScrollRect then
        csScrollRect.enabled = gLGameLanguage:IsForeignVersion()
    end
end

function UINewJNTip:ClickBtnEvent(skillId)
    if skillId == self._curSkillId then
        return
    end
    self._curSkillId = skillId
    local uiBtnList = self._uiBtnList
    if uiBtnList then
        local uiList = uiBtnList:GetList()
        uiList:RefreshList()
    end
    self:RefreshView()
end

function UINewJNTip:InitEvent()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UINewJNTip:InitText()
    self:SetWndText(self.mSkillDescTitle, ccClientText(20126))
    self:SetWndText(self.mStatusDescTitle, ccClientText(20127))
    self:SetWndText(self.mUpDescTitle, ccClientText(20128))
end
function UINewJNTip:ShowSkillTipList(curSkillRef)
    local styleTip = ""
    if curSkillRef then
        styleTip = ccLngText(curSkillRef.styleTip)
    end
    local styleList = {}
    local styleTipList = string.split(styleTip, "|")
    for i, v in ipairs(styleTipList) do
        table.insert(styleList, { name = v })
    end
    self:CreateStyleTipList(styleList)
end

function UINewJNTip:RefreshAwakenSkill()
    local curSkillId = self._curSkillId
    local skillRef = GameTable.SnakeSkillRef[curSkillId]
    if not skillRef then
        return
    end
    self:ShowSkillInfo(skillRef)

    CS.ShowObject(self.mUpSkillDiv, false)
end

function UINewJNTip:InitSorceryCard()
	local group = self:GetWndArg("skillGroup")
	self._curSkillId = self:GetWndArg("skill")

	local cardSkillRefs = gModelSorceryCard:GetSorceryCardSkillRefByGroup(group)
	local list = {}
	for i, v in ipairs(cardSkillRefs) do
		table.insert(list,{skillId = v.skill,level = v.level})
	end
	self:InitBtnList(list)
end

function UINewJNTip:RefreshRuneSkillBtnList()
    local skillList = self._skillList
    local btnList = {}
    for i, v in ipairs(skillList or {}) do
        local skillRef = GameTable.SnakeSkillRef[v]
        if skillRef then
            table.insert(btnList, {
                level = skillRef.level,
                skillId = skillRef.refId,
            })
        end
    end
    self:InitBtnList(btnList)
end

function UINewJNTip:InitData()
    self._curSkillId = self:GetWndArg("curSkillId")
    print(self._curSkillId)
    self._nowSkillId = self._curSkillId
    local curSkillIdx = self:GetWndArg("curSkillIdx")
    self._curSkillIdx = curSkillIdx
    local heroData = self:GetWndArg("heroData")
    self._heroData = heroData
    local refId, star = heroData.refId, heroData.star
    local heroRef = gModelHero:GetHeroRef(refId)
    if not heroRef then
        return
    end
    self._heroRef = heroRef
    local initStar = heroRef.initStar
    local skillList = gModelHero:GetSkillListByRefIdAndStar(refId, initStar)
    local skillInfo = skillList and skillList[curSkillIdx]
    local initSkillId = skillInfo and skillInfo.skillId
    local needGrade = skillInfo and skillInfo.openClass
    if not initSkillId and not needGrade then
        return
    end
    self._needGrade = needGrade
    local allSkillList = {}
    local btnList = {}
    local tSkillId = initSkillId
    local index = 0
    while (tSkillId ~= -1 and index <= UINewJNTip.MAX_SKILL_NUM) do
        local skillRef = GameTable.SnakeSkillRef[tSkillId]
        if skillRef then
            index = index + 1
            table.insert(allSkillList, skillRef)
            table.insert(btnList, {
                level = skillRef.level,
                skillId = skillRef.refId,
            })
            tSkillId = skillRef.nextLv
        else
            break
        end
    end
    self:InitBtnList(btnList)

    --local styleTip = ""
    local curSkillRef = GameTable.SnakeSkillRef[self._curSkillId]
    self:ShowSkillTipList(curSkillRef)
    --if curSkillRef then
    --	styleTip = ccLngText(curSkillRef.styleTip)
    --	printInfoNR("curSkillRef.styleTip = ",styleTip)
    --end
    --local styleList = {}
    --local styleTipList = string.split(styleTip,"|")
    --for i,v in ipairs(styleTipList) do
    --	table.insert(styleList,{name = v})
    --end
    --self:CreateStyleTipList(styleList)
end
function UINewJNTip:InitBtnList(list)
    local index = 1
    local _curSkillId = self._curSkillId or 1
    for i, v in ipairs(list) do
        if v.skillId == _curSkillId then
            index = i
            break
        end
    end
    local uiBtnList = self._uiBtnList
    if uiBtnList then
        uiBtnList:RefreshList(list)
    else
        uiBtnList = self:GetUIScroll("uiBtnList")
        self._uiBtnList = uiBtnList
        uiBtnList:Create(self.mBtnList, list, function(...)
            self:OnDrawBtnCell(...)
        end)
        uiBtnList:EnableScroll(#list > 3, true)
    end
    local uiList = uiBtnList:GetList()
    uiList:DelayScrollTo(index, UIListEasy.SCROLL_CENTER)
end
function UINewJNTip:RefreshSorceryCardSkill()
	local group = self:GetWndArg("skillGroup")
	local cardId = self:GetWndArg("cardId")

	local ref = gModelSorceryCard:GetSorceryCardRefByRefId(cardId)
	local cardLv = self:GetWndArg("cardLevel")

	local curSkillId = self._curSkillId
	local skillRef = GameTable.SnakeSkillRef[curSkillId]
	if not skillRef then return end
	self:ShowSkillInfo(skillRef)

	local cardSkillRefs = gModelSorceryCard:GetSorceryCardSkillRefByGroup(group)
	local selRef = cardSkillRefs[1]
	for i, v in ipairs(cardSkillRefs) do
		if curSkillId == v.skill then
			selRef = v
			break
		end
	end

	local unlockLevel = selRef.unlockLevel
	local str = ""
	if cardLv <= 0 then
		str = string.replace(ccClientText(29552),ccLngText(ref.name), unlockLevel)
	else
		str = string.replace(ccClientText(29553),ccLngText(ref.name),unlockLevel)
	end
	CS.ShowObject(self.mUpSkillDiv,true)
	self:SetWndText(self.mUpSkillDescTxt,str)

	local unlockBg =self._isEnus and  self:FindWndTrans(self.mSkillInfo,"UnLockBg_Enus") or  self:FindWndTrans(self.mSkillInfo,"UnLockBg")
	local unlockTxt = self:FindWndTrans(unlockBg,"UnLockLv")

	local showUnlock = cardLv < unlockLevel
	CS.ShowObject(unlockBg,showUnlock)
	if showUnlock then
		local str = string.replace(ccClientText(10022),unlockLevel)
		self:SetWndText(unlockTxt,str)
	end
end

function UINewJNTip:ShowGuildSkillInfo(curSkillRef, grade, openGrade)
    local skillId = curSkillRef.refId
    local skillIconTrans = CS.FindTrans(self.mSkillInfo, "SkillIcon")
    local baseClass = self._skillIcon
    if not baseClass then
        baseClass = SkillIcon:New(self)
        self._skillIcon = baseClass
    end
    baseClass:SetSkillInfo(nil, false, nil, 1)
    baseClass:Create(skillIconTrans, skillId)

    local name = ccLngText(curSkillRef.name)
    self:SetWndText(self.mNameTxt, name)

    local skillType = curSkillRef.type
    local skillTypeDesc = skillType == 1 and ccClientText(10039) or ccClientText(10040)
    self:SetWndText(self.mTypeTxt, skillTypeDesc)

    local description2 = ccLngText(curSkillRef.description2)
    self:SetWndText(self.mLengQueTxt, description2)

    local description = ccLngText(curSkillRef.description)
    self:SetWndText(self.mSkillDescTxt, description)
    --printInfoN2("cjh--ShowGuildSkillInfo--description", description)
    local stateDes = ccLngText(curSkillRef.stateDes)
    local isEmpty = stateDes == ""
    CS.ShowObject(self.mStatusDescDiv, not isEmpty)
    if not isEmpty then
        self:SetWndText(self.mStatusDescTxt, stateDes)
    end

    local unlockBg = self:FindWndTrans(self.mSkillInfo, "UnLockBg")
    local unlockTxt = self:FindWndTrans(unlockBg, "UnLockLv")

    local showUnlock = grade < openGrade
    if showUnlock then
        local str = string.replace(ccClientText(10022), openGrade)
        self:SetWndText(unlockTxt, str)
    end

    self:InitTextLineWithLanguage(unlockTxt, -40)
    CS.ShowObject(unlockBg, showUnlock)


end

function UINewJNTip:ShowSkillInfo(curSkillRef, grade, openGrade)
    local skillId = curSkillRef.refId
    local skillIconTrans = CS.FindTrans(self.mSkillInfo, "SkillIcon")
    local baseClass = self._skillIcon
    if not baseClass then
        baseClass = SkillIcon:New(self)
        self._skillIcon = baseClass
    end
    baseClass:ShowLvl(not self._hideLvl)
    baseClass:SetSkillInfo(grade, false, openGrade, 1, self._wndType == UINewJNTip.GUILDSKILL)
    baseClass:Create(skillIconTrans, skillId)

    if self._wndType == UINewJNTip.AWAKEN_SKILL then
        local isActivate = self._pointActivate and skillId <= self._nowSkillId
        baseClass:SetIconAndIconBgGray(not isActivate)
    end

    local name = ccLngText(curSkillRef.name)
    self:SetWndText(self.mNameTxt, name)


    -- local quality = self:GetWndArg("quality")
    -- if quality then
    --     local qualityRef =  GameTable.RarityRef[quality]
    --     self:SetXUITextTransColor(Name,qualityRef.nameColor)
    -- end

    local skillType = curSkillRef.type
    local skillTypeDesc = skillType == 1 and ccClientText(10039) or ccClientText(10040)
    self:SetWndText(self.mTypeTxt, skillTypeDesc)

    local description2 = ccLngText(curSkillRef.description2)
    self:SetWndText(self.mLengQueTxt, description2)

    local description = ccLngText(curSkillRef.description)
    if self.mSkillDescTxt==nil then
        --printInfoN2("cjh--ShowSkillInfo--", "mSkillDescTxt==nil")

    else
        self:SetWndText(self.mSkillDescTxt, description)

    end
    --self:SetWndText(self.mSkillDescTxt,description..description..description..description..description..description..description..description..description..description..description)
    --printInfoN2("cjh--ShowSkillInfo--description", description)

    local stateDes = ccLngText(curSkillRef.stateDes)
    local isEmpty = stateDes == ""
    CS.ShowObject(self.mStatusDescDiv, not isEmpty)
    if not isEmpty then
        self:SetWndText(self.mStatusDescTxt, stateDes)
    end

end

function UINewJNTip:CreateStyleTipList(list)
    local len = #list
    CS.ShowObject(self.mStyleTipDiv, len ~= 0)
    local uiStyleTipList = self._uiStyleTipList
    if uiStyleTipList then
        uiStyleTipList:RefreshList(list)
    else
        uiStyleTipList = self:GetUIScroll("uiStyleTipList")
        self._uiStyleTipList = uiStyleTipList
        uiStyleTipList:Create(self.mStyleTipList, list, function(...)
            self:OnDrawStyleTipCell(...)
        end)
    end

    uiStyleTipList:EnableScroll(true, true)
end

function UINewJNTip:CheckUIElementIsNull()

end

function UINewJNTip:RefreshCurSkillIdView()
    local curSkillRef = GameTable.SnakeSkillRef[self._curSkillId]
    self:ShowSkillTipList(curSkillRef)
    self:ShowSkillInfo(curSkillRef)
    CS.ShowObject(self.mUpSkillDiv, false)
end

function UINewJNTip:InitHreoCoreData()
    local _iSkillId = self:GetWndArg("skill")
    self._curSkillId = self:GetWndArg("curSkillId")
    self._nowSkillId = self._curSkillId
    local btnList = {}
    local tSkillId = _iSkillId
    local index = 0
    while (tSkillId ~= -1 and index <= UINewJNTip.MAX_SKILL_NUM) do
        local skillRef = GameTable.SnakeSkillRef[tSkillId]
        if skillRef then
            index = index + 1
            table.insert(btnList, {
                level = skillRef.level,
                skillId = skillRef.refId,
            })
            tSkillId = skillRef.nextLv
        else
            break
        end
    end
    self:InitBtnList(btnList)
    local curSkillRef = GameTable.SnakeSkillRef[self._curSkillId]
    self:ShowSkillTipList(curSkillRef)
end

-- 【C宠物系统】删掉宠物系统相关
-- function UINewJNTip:InitPetData()
-- 	self._curSkillId = self:GetWndArg("curSkillId")
-- 	self._nowSkillId = self._curSkillId
-- 	local petData = self:GetWndArg("petData")
-- 	local initSkillId = self:GetWndArg("initSkillId")
-- 	self._petData = petData
-- 	local petRef = gModelPetSpace:GetPetConfigByTypeAndKey(ModelPetSpace.MagicPetRef, petData.refId)
-- 	if(not petRef)then
-- 		return
-- 	end
-- 	local skillRef = GameTable.SnakeSkillRef
-- 	local btnList = {}
-- 	local skillData= skillRef[initSkillId]
-- 	repeat
-- 		table.insert(btnList,{
-- 			level = skillData.level,
-- 			skillId = skillData.refId,
-- 		})
-- 		initSkillId = skillData.nextLv
-- 		skillData = skillRef[initSkillId]
-- 	until( not skillData )
-- 	self:InitBtnList(btnList)
-- 	local curSkillRef = GameTable.SnakeSkillRef[self._curSkillId]
-- 	self:ShowSkillTipList(curSkillRef)
-- 	self:ShowSkillInfo(curSkillRef)
-- end

function UINewJNTip:InitCommonData()
    self._curSkillId = self:GetWndArg("curSkillId")
    self._nowSkillId = self._curSkillId
    local initSkillId = self:GetWndArg("initSkillId")
    local skillRef = GameTable.SnakeSkillRef
    local btnList = {}
    while true do
        local skillData = skillRef[initSkillId]
        if (skillData) then
            table.insert(btnList, {
                level = skillData.level,
                skillId = skillData.refId,
            })
            initSkillId = skillData.nextLv
        else
            break
        end
    end
    self:InitBtnList(btnList)
    local curSkillRef = GameTable.SnakeSkillRef[self._curSkillId]
    self:ShowSkillTipList(curSkillRef)
    self:ShowSkillInfo(curSkillRef)
end
function UINewJNTip:RefreshUI_SimpleHide()
    self._hideLvl = true
    self:RefreshUI_Simple()
end

function UINewJNTip:Refresh()
    local heroRef = self._heroRef
    if not heroRef then
        return
    end

    local curSkillId = self._curSkillId
    local heroData = self._heroData
    local grade = heroData.grade
    --local refId,star = heroData.refId,heroData.star

    local skillRef = GameTable.SnakeSkillRef[curSkillId]
    if not skillRef then
        return
    end

    --local skillList,skillIdKeyList = gModelHero:GetSkillListByRefIdAndStar(refId,star)
    --if not skillIdKeyList then return end
    local needGrade = self._needGrade

    self:ShowSkillInfo(skillRef, grade, needGrade)

    --local skillIconTrans = CS.FindTrans(self.mSkillInfo,"SkillIcon")
    --local baseClass = self._skillIcon
    --if not baseClass then
    --	baseClass = SkillIcon:New(self)
    --	self._skillIcon = baseClass
    --end
    --baseClass:SetSkillInfo(nil,false,nil,1)
    --baseClass:Create(skillIconTrans,curSkillId)
    --
    --local name = ccLngText(skillRef.name)
    --self:SetWndText(self.mNameTxt,name)
    --
    --local skillType = skillRef.type
    --local skillTypeDesc = skillType == 1 and ccClientText(10039) or ccClientText(10040)
    --self:SetWndText(self.mTypeTxt,skillTypeDesc)
    --
    --local description2 = ccLngText(skillRef.description2)
    --self:SetWndText(self.mLengQueTxt,description2)
    --
    --local description = ccLngText(skillRef.description)
    --self:SetWndText(self.mSkillDescTxt,description)
    --
    --local stateDes = ccLngText(skillRef.stateDes)
    --local isEmpty = stateDes == ""
    --CS.ShowObject(self.mStatusDescDiv,not isEmpty)
    --if not isEmpty then
    --	self:SetWndText(self.mStatusDescTxt,stateDes)
    --end

    --[[	local str = ""
        local initStar,maxStar = heroRef.initStar,heroRef.maxStar
        local starType = heroRef.starType
        -- 当需要的阶级高于英雄的阶级时，显示激活条件
        if needGrade > grade then
            local needLv = 0
            local classType = heroRef.classType
            local classId = gModelHero:ConvertToHeroGradeId(classType,needGrade - 1)
            local classRef = gModelHero:GetHeroClassById(classId)
            if classRef then needLv = classRef.needLevel end
            str = string.replace(ccClientText(10064),needLv)
        else
            local tSkillList = {}
            for i = initStar,maxStar do
                local tempStarId = gModelHero:GetStarId(starType,i)
                local tempRef = gModelHero:GetHeroStarById(tempStarId)
                if tempRef then
                    table.insert(tSkillList,tempRef)
                end
            end
            local maxId,skillMaxStar
            for i,v in ipairs(tSkillList) do
                local temp = string.split(v.skillGroup,",")
                local selData = temp[self._curSkillIdx]
                local selDataList = string.split(selData,"=")
                local tSkillId,tNeedGrade = tonumber(selDataList[1]),tonumber(selDataList[2])
                if tSkillId > curSkillId then
                    maxId = tSkillId
                    skillMaxStar = v.star
                    break
                end
            end
            if maxId and skillMaxStar then
                str = ccClientText(10043)
                str = string.replace(str,skillMaxStar)
            else
                str = ccClientText(10044)
            end
        end]]

    local str = ""
    if needGrade > grade and self._nowSkillId == curSkillId then
        str = string.replace(ccClientText(10042), needGrade)
    else
        local unNeedStar = skillRef.unNeedStar
        if unNeedStar == -1 then
            str = ccClientText(10044)
        else
            str = string.replace(ccClientText(10043), skillRef.unNeedStar)
        end
    end
    if self.mUpSkillDescTxt==nil then
        printInfoN2("cjh-----","mUpSkillDescTxt==nil")
    else
        self:SetWndText(self.mUpSkillDescTxt, str)

    end
end

function UINewJNTip:RefreshUI_Simple()

    local skillId = self:GetWndArg("curSkillId")
    local skillRef = gModelSkill:GetSkillRef(skillId)

    self:ShowSkillTipList(skillRef)
    self:ShowSkillInfo(skillRef)
    CS.ShowObject(self.mUpSkillDiv, false)
    CS.ShowObject(self.mBtnList, false)

    local extraInfo = self:GetWndArg("extraInfo")
    local show = not string.isempty(extraInfo)
    CS.ShowObject(self.mExtraInfo, show)
    if show then
        self:SetWndText(self.mExtraInfo, extraInfo)
    end
end

function UINewJNTip:RefreshGuildSkill()
    local curSkillId = self._curSkillId
    local skillRef = GameTable.SnakeSkillRef[curSkillId]
    if not skillRef then
        return
    end
    local grade = self:GetWndArg("grade")
    local guildSkillRef = gModelGuild:GetGuildSkillRefBySkill(curSkillId)
    local needGrade = guildSkillRef.needLevel
    self:ShowGuildSkillInfo(skillRef, grade, needGrade)
    local jobName = gModelGuild:GetGuildSkillJobRefNameByJobType(guildSkillRef.job)
    local str = ""
    if needGrade > grade and self._nowSkillId == curSkillId then
        str = string.replace(ccClientText(13313), jobName, needGrade)
    else
        local unNeedStar = skillRef.unNeedStar
        if unNeedStar == -1 then
            str = ccClientText(10044)
        else

            str = string.replace(ccClientText(13315), jobName, needGrade)
        end
    end
    CS.ShowObject(self.mUpSkillDiv, true)
    self:SetWndText(self.mUpSkillDescTxt, str)
end

function UINewJNTip:InitBtnDate()
    local _iSkillId = self:GetWndArg("skill")
    self._curSkillId = self:GetWndArg("curSkillId")
    self._nowSkillId = self._curSkillId
    self._pointActivate = self:GetWndArg("pointActivate")
    local btnList = {}
    local tSkillId = _iSkillId
    local index = 0
    while (tSkillId ~= -1 and index <= UINewJNTip.MAX_SKILL_NUM) do
        local skillRef = GameTable.SnakeSkillRef[tSkillId]
        if skillRef then
            index = index + 1
            table.insert(btnList, {
                level = skillRef.level,
                skillId = skillRef.refId,
            })
            tSkillId = skillRef.nextLv
        else
            break
        end
    end
    if #btnList > 1 then
        self:InitBtnList(btnList)
    end
    local curSkillRef = GameTable.SnakeSkillRef[self._curSkillId]
    self:ShowSkillTipList(curSkillRef)
end

--【G公共支持】删除伙伴晶石功能相关数据
-- function UINewJNTip:RefreshCrystalSkill()
-- 	local curSkillId = self._curSkillId
-- 	local skillRef = GameTable.SnakeSkillRef[curSkillId]
-- 	if not skillRef then return end
-- 	self:ShowSkillInfo(skillRef)

-- 	local upSkillDesStr = gModelCrystalShard:GetSkillUpDesBySkillId(curSkillId)
-- 	self:SetWndText(self.mUpSkillDescTxt,upSkillDesStr)
-- 	self:SetWndText(self.mUpDescTitle,ccClientText(34767))
-- 	CS.ShowObject(self.mUpSkillDiv, true)
-- end

-- 【C宠物系统】删掉宠物系统相关
-- function UINewJNTip:RefreshPetSkill()
-- 	local curSkillId = self._curSkillId
-- 	local skillRef = GameTable.SnakeSkillRef[curSkillId]
-- 	if not skillRef then return end
-- 	local str = ""
-- 	self:ShowSkillInfo(skillRef)
-- 	local unNeedStar = skillRef.unNeedStar
-- 	if unNeedStar == -1 then
-- 		str = ccClientText(37993)
-- 	else
-- 		str = string.replace(ccClientText(37992),skillRef.unNeedStar)
-- 	end
-- 	self:SetWndText(self.mUpSkillDescTxt,str)
-- 	CS.ShowObject(self.mUpSkillDiv, true)
-- 	CS.ShowObject(self.mUpDescTitle, true)
-- end

function UINewJNTip:RefreshCommonSkill()
    local curSkillId = self._curSkillId
    local skillRef = GameTable.SnakeSkillRef[curSkillId]
    if not skillRef then
        return
    end
    local str = ""
    self:ShowSkillInfo(skillRef)
    local unNeedStar = skillRef.unNeedStar
    if unNeedStar == -1 then
        str = ccClientText(37993)
    else
        str = string.replace(ccClientText(37996), skillRef.unNeedStar)
    end
    self:SetWndText(self.mUpSkillDescTxt, str)
    CS.ShowObject(self.mUpSkillDiv, true)
    CS.ShowObject(self.mUpDescTitle, true)
end

function UINewJNTip:OnDrawBtnCell(list, item, itemdata, itempos)
    local skillId = itemdata.skillId
    local sel = skillId == self._curSkillId
    local BtnTab1 = self:FindWndTrans(item, "BtnTab1")
    if BtnTab1 then
        local str = string.replace(ccClientText(20125), itemdata.level)
        self:SetWndTabText(BtnTab1, str)
        local status = sel and 0 or 1
        self:SetWndTabStatus(BtnTab1, status)
        self:SetWndClick(BtnTab1, function()
            self:ClickBtnEvent(skillId)
        end)
    end
    local SelImg = self:FindWndTrans(item, "SelImg")
    if SelImg then
        CS.ShowObject(SelImg, skillId == self._nowSkillId)
    end
end

function UINewJNTip:RefreshRuneSkill()
    local skillList = self:GetWndArg("skillList")
    self._skillList = skillList

    self._curSkillId = self:GetWndArg("curSkillId")
    self._nowSkillId = self._curSkillId

    self:RefreshRuneSkillBtnList()
end

function UINewJNTip:OnDrawStyleTipCell(list, item, itemdata, itempos)
    local name = itemdata.name
    local Name = self:FindWndTrans(item, "Name")
    if Name then
        self:SetWndText(Name, name)
    end
end

function UINewJNTip:RefreshHeroCoreSkill()
    local curSkillId = self._curSkillId
    local skillRef = GameTable.SnakeSkillRef[curSkillId]
    if not skillRef then
        return
    end
    self:ShowSkillInfo(skillRef)

    CS.ShowObject(self.mUpSkillDiv, false)
end

function UINewJNTip:RefreshView()
    local wndType = self._wndType
    if wndType == UINewJNTip.NORMAL then
        CS.ShowObject(self.mUpSkillDiv, true)
        self:Refresh()
    elseif wndType == UINewJNTip.RUNESKILL then
        self:RefreshCurSkillIdView()
    elseif wndType == UINewJNTip.GUILDSKILL then
        self:RefreshGuildSkill()
    elseif wndType == UINewJNTip.AWAKEN_SKILL then
        self:RefreshAwakenSkill()
    elseif wndType == UINewJNTip.HEROCORE_SKILL then
        self:RefreshHeroCoreSkill()
        elseif wndType == UINewJNTip.SORCERYCARD_SKILL then
        	self:RefreshSorceryCardSkill()
        --【G公共支持】删除伙伴晶石功能相关数据
        -- elseif wndType == UINewJNTip.CRYSTAL_SKILL then
        -- 	self:RefreshCrystalSkill()
        -- 【C宠物系统】删掉宠物系统相关
        -- elseif wndType == UINewJNTip.PET_SKILL then
        -- 	self:RefreshPetSkill()
    elseif wndType == UINewJNTip.COMMON_SKILL then
        self:RefreshCommonSkill()
    elseif wndType == UINewJNTip.SKILL_GIFT then
        self:RefreshCurSkillIdView()
    end
end
------------------------------------------------------------------
return UINewJNTip