---
--- Created by LCM.
--- DateTime: 2024/3/30 20:55:57
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReUpClass:LWnd
local UIReUpClass = LxWndClass("UIReUpClass", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReUpClass:UIReUpClass()
    self._effectKey = "paly"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReUpClass:OnWndClose()
	if self._skillIconList then
		LUtil.ClearHashTable(self._skillIconList)
		self._skillIconList = nil
	end
    self:TweenSeqKill(self._effectKey)

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReUpClass:OnCreate()
	LWnd.OnCreate(self)
	self._skillIconList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReUpClass:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
    self:SetWndEasyImage(self.mTitleImg,"rune_txt_6")
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
    self:PlayEffect()
end

function UIReUpClass:CreateEffect(trans,effectName,effectKey,effectSize)
    effectKey = effectKey or trans:GetInstanceID()
    effectSize = effectSize or 100
    self:CreateWndEffect(trans,effectName,effectKey,effectSize,false,false)
end

function UIReUpClass:CreateClassDiv(data)
	self:SetWndText(self.mClassName,ccClientText(24833))
	if not data then return end
	local curStarNum = data.curStarNum
	local nextStarNum = data.nextStarNum
	self:CreateStarList(self.mBeforeStarList,curStarNum)
	self:CreateStarList(self.mLaterStarList,nextStarNum)
end

function UIReUpClass:CreateAttrCell(item,itemdata)
    local rootTrans = self:FindWndTrans(item,"Root")
	local AttrIconTrans = self:FindWndTrans(rootTrans,"AttrIcon")
	local AttrNameTrans = self:FindWndTrans(rootTrans,"AttrName")
	local AttrBeforeNumTrans = self:FindWndTrans(rootTrans,"AttrBeforeNum")
	local AttrLaterNumTrans = self:FindWndTrans(rootTrans,"AttrLaterNum")
	local attrRefId = itemdata.attrRefId
	local attrType = itemdata.attrType
	local beforeAttrVal = itemdata.beforeAttrVal
	local laterAttrVal = itemdata.laterAttrVal
	local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
	self:SetWndEasyImage(AttrIconTrans,attrIcon)
	local attrName = gModelHero:GetAttributeNameById(attrRefId)
	self:SetWndText(AttrNameTrans,attrName)
	local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,beforeAttrVal)
	self:SetWndText(AttrBeforeNumTrans,value)
	local nextValue = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,laterAttrVal)
	self:SetWndText(AttrLaterNumTrans,nextValue)
    self:SaveAttrEffectTransList(rootTrans)
end

function UIReUpClass:CreateRuneIcon(data)
	local trans = self.mRuneRoot
	local key = trans:GetInstanceID()
	local baseClass = self:GetCommonIcon(key)
	baseClass:Create(trans)
	baseClass:SetRuneData(data)
	baseClass:DoApply()
    self._runeRootEffectTrans = trans
end

function UIReUpClass:CreateStarList(trans,starNum)
	local list = {}
	for i = 1,starNum do
		table.insert(list,{
			show = true,
		})
	end

	local isNotStar = starNum == 0
	if isNotStar then
		local NoClassTxt = self:FindWndTrans(trans,"NoClassTxt")
		self:SetWndText(NoClassTxt,ccClientText(24923))
	end

	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawStarCell(...) end)
	end
end

function UIReUpClass:GetClassAndLevelList()
	local list = {}
	local preRune,newRune = self._preRune,self._newRune
	if preRune and newRune then
		local starData,levelData = {},{}
		local curClazzRefId = preRune.clazzRefId
		local newClazzRefId = newRune.clazzRefId
		local curClassRef = gModelRune:GetInitRuneQuenchingClassRefByRefId(curClazzRefId)
		local newClassRef = gModelRune:GetInitRuneQuenchingClassRefByRefId(newClazzRefId)
		--local curUpQuality = curClassRef and curClassRef.upQuality or preRune.refId
		local curUpQuality = preRune.refId
		local newUpQuality = newRune.refId
		local curStar,nextStar = gModelRune:GetShowStarByRefId(curUpQuality),gModelRune:GetShowStarByRefId(newUpQuality)
		starData.curStarNum = curStar
		starData.nextStarNum = nextStar

		local curClazzRefId = preRune.clazzRefId
		local nextClazzRefId = newRune.clazzRefId
		local curLevelRef = GameTable.MagicRuneQuenchingClassRef[curClazzRefId]
		local nextLevelRef = GameTable.MagicRuneQuenchingClassRef[nextClazzRefId]
		local curLevelNum = curLevelRef and curLevelRef.runeClass or 1
		local nextLevelNum = nextLevelRef and nextLevelRef.runeClass or 1
		levelData.curLevelNum = curLevelNum
		levelData.nextLevelNum = nextLevelNum

		table.insert(list,starData)
		table.insert(list,levelData)
	end
	return list
end

function UIReUpClass:OnDrawStarCell(list,item,itemdata,itempos)
	local star = self:FindWndTrans(item,"Star")
	CS.ShowObject(star,itemdata.show)
end

function UIReUpClass:SaveAttrEffectTransList(root)
    local rootTransList = self._rootTransList
    if not rootTransList then
        rootTransList = {}
        self._rootTransList = rootTransList
    end
    table.insert(rootTransList,root)
end

function UIReUpClass:CreateAttrEffect(trans,effectSize,effectKey)
    if not trans then return end
    self:CreateEffect(trans,"fx_ui_shengxing_3",effectKey,effectSize)
end

function UIReUpClass:GetUpClassAttrList()
	local list = {}
	local preRune,newRune = self._preRune,self._newRune
	if not preRune or not newRune then return list end

	local curAttrId = preRune.attrId
	local newAttrId = newRune.attrId
	list = gModelRune:GetRuneUpAttrList(curAttrId, false)

	return list
end

function UIReUpClass:OnDrawSkillCell(list,item,itemdata,itempos)
    local rootTrans = self:FindWndTrans(item,"Root")
	local SkillRoot = self:FindWndTrans(rootTrans,"SkillRoot")
	local SkillIconTrans = self:FindWndTrans(SkillRoot,"SkillIcon")
	local SkillName = self:FindWndTrans(rootTrans,"SkillName")
	local skillIconList = self._skillIconList
	if not skillIconList then
		skillIconList = {}
		self._skillIconList = skillIconList
	end
	local runeSkillRefId = itemdata
	local isHaveSkill = runeSkillRefId ~= nil
	local skillData = gModelRune:GetSkillInfoByRefId(runeSkillRefId)
	local skillRefId = skillData and skillData.SkillId
	local InstanceID = item:GetInstanceID()
	local baseClass = skillIconList[InstanceID]
	if not baseClass then
		baseClass = SkillIcon:New(self)
	end
	baseClass:ShowWenHao(not isHaveSkill)
	baseClass:Create(SkillIconTrans,skillRefId,function()
		if not skillData then return end
		local skillType = skillData.skillType
		gModelRune:OpenNewRuneSkillWnd(runeSkillRefId,skillType)
	end)
	local skillNameStr,color
	if skillRefId then
		local skillRef = gModelHero:GetSkillByStarId(skillRefId)
		if skillRef then
			skillNameStr = ccLngText(skillRef.name)
			local quality = skillData.quality + 2
			color = gModelItem:GetColorByQualityId(quality)
		end
	else
		skillNameStr = ccClientText(24839)
		color = LUtil.GetColorByKey("black")
	end
	if color then
		self:SetXUITextTransColor(SkillName,color)
	end
	self:SetWndText(SkillName,skillNameStr)
    self:SaveIconEffectTransList(rootTrans)
end

function UIReUpClass:InitUpClassAttrList()
	local list = self:GetUpClassAttrList()
	local uiUpClassAttrList = self._uiUpClassAttrList
	if uiUpClassAttrList then
		uiUpClassAttrList:RefreshList(list)
	else
		uiUpClassAttrList = self:GetUIScroll("uiUpClassAttrList")
		self._uiUpClassAttrList = uiUpClassAttrList
		uiUpClassAttrList:Create(self.mUpClassAttrList,list,function(...) self:OnDrawUpClassAttrCell(...) end)
	end
	local isEmpty = #list < 1
	CS.ShowObject(self.mUpClassAttrList,not isEmpty)
end

function UIReUpClass:OnDrawUpClassAttrCell(list,item,itemdata,itempos)
	self:CreateAttrCell(item,itemdata)
end

function UIReUpClass:GetSkillList()
	local beforeSkillList,laterSkillList = {},{}
	local preRune,newRune = self._preRune,self._newRune
	if not preRune or not newRune then return beforeSkillList,laterSkillList end
	local preSkillId,newSkillId = preRune.skillId,newRune.skillId
	local preSkillIdList,newSkillIdList = {},{}
	for i,v in ipairs(preSkillId) do
		preSkillIdList[v] = v
	end
	for i,v in ipairs(newSkillId) do
		newSkillIdList[v] = v
	end
	local isSame = true
	for k,v in pairs(newSkillIdList) do
		if not isSame then break end
		isSame = preSkillIdList[k] ~= nil
	end
	if not isSame then
		beforeSkillList,laterSkillList = preSkillId,newSkillId
	end
	return beforeSkillList,laterSkillList
end

function UIReUpClass:CreateTitleEffect()
    CS.ShowObject(self.mEffRoot,true)
    self:CreateEffect(self.mEffRoot,"fx_ui_shengxing_1")
end

function UIReUpClass:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIReUpClass:CreateClassAndLevelDiv()
	local list = self:GetClassAndLevelList()
    self:SaveAttrEffectTransList(self.mClassDiv)
    self:SaveAttrEffectTransList(self.mLvDiv)
	self:CreateClassDiv(list[1])
	self:CreateLevelDiv(list[2])
end

function UIReUpClass:PlayEffect()
    local seqTween
    self:TweenSeqKill(self._effectKey)
    if not seqTween then
        seqTween = self:TweenSeqCreate(self._effectKey,function(seq)
            local showTopTime = 0.2
            local showAttrTime = 0.1
            seq:AppendCallback(function ()
                self:CreateTitleEffect()
            end)
            seq:AppendInterval(showTopTime)

            seq:AppendCallback(function ()
                LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_UPGRADE_COMMON)
            end)
            seq:AppendInterval(showTopTime)

            local runeRootEffectTrans = self._runeRootEffectTrans
            if runeRootEffectTrans then
                seq:AppendCallback(function ()
                    self:CreateIconEffect(runeRootEffectTrans,150)
                    CS.ShowObject(self.mTitleImg,true)
                    CS.ShowObject(runeRootEffectTrans,true)
                end)
                seq:AppendInterval(showAttrTime)
            end

            local rootTransList = self._rootTransList
            if rootTransList then
                for i,v in ipairs(rootTransList) do
                    seq:AppendCallback(function ()
                        self:CreateAttrEffect(v)
                        CS.ShowObject(v,true)
                    end)
                    seq:AppendInterval(showAttrTime)
                end
            end

            local skillTransList = self._skillTransList
            if skillTransList then
                for i,v in ipairs(skillTransList) do
                    seq:AppendCallback(function ()
						local SkillEffRoot = self:FindWndTrans(v,"SkillEffRoot")
                        self:CreateIconEffect(SkillEffRoot,160)
                        CS.ShowObject(v,true)
                    end)
                    seq:AppendInterval(showAttrTime)
                end
            end
            return seq
        end)
    end
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(self._effectKey)
    end)
end

function UIReUpClass:InitData()
	local openType = self:GetWndArg("openType")
	if not openType then
		openType = UIReUpClass.TYPE_UP_LEVEL
	end
	self._openType = openType
	self._preRune = self:GetWndArg("preRune")
	self._newRune = self:GetWndArg("newRune")
end

function UIReUpClass:InitQuenchingList(list)
	list = list or {}
	local uiQuenchingList = self._uiQuenchingList
	if uiQuenchingList then
		uiQuenchingList:RefreshList(list)
	else
		uiQuenchingList = self:GetUIScroll("uiQualityList")
		self._uiQuenchingList = uiQuenchingList
		uiQuenchingList:Create(self.mQuenchAttrList,list,function(...) self:OnDrawQuenchingAttrCell(...) end)
	end
end

function UIReUpClass:InitText()
	self:SetTextTile(self.mType1TextTitle,ccClientText(24818))
	self:SetTextTile(self.mTextTitle,ccClientText(24819))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
end

function UIReUpClass:SaveIconEffectTransList(root)
    local skillTransList = self._skillTransList
    if not skillTransList then
        skillTransList = {}
        self._skillTransList = skillTransList
    end
    table.insert(skillTransList,root)
end

function UIReUpClass:CreateIconEffect(trans,effectSize,effectKey)
    if not trans then return end
    self:CreateEffect(trans,"fx_ui_shengxing_4",effectKey,effectSize)
end

function UIReUpClass:InitMsg()
end

function UIReUpClass:CreateLevelDiv(data)
	self:SetWndText(self.mLvName,ccClientText(24853))
	if not data then return end
	self:SetWndText(self.mLvBeforeNum,data.curLevelNum)
	self:SetWndText(self.mLvLaterNum,data.nextLevelNum)
end

function UIReUpClass:CreateSkillList(trans,list)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawSkillCell(...) end)
	end
end

function UIReUpClass:OnDrawQuenchingAttrCell(list,item,itemdata,itempos)
	self:CreateAttrCell(item,itemdata)
end

function UIReUpClass:InitSkillList()
	local beforeSkillList,laterSkillList = self:GetSkillList()
	local beforeNum = #beforeSkillList
	local laterNum = #laterSkillList
	local isNoUpSkill = beforeNum == 0 or laterNum == 0
	CS.ShowObject(self.mRuneSkillDiv,not isNoUpSkill)
	if isNoUpSkill then return end
	self:CreateSkillList(self.mBeforeSkillList,beforeSkillList)
	self:CreateSkillList(self.mLaterSkillList,laterSkillList)
end

function UIReUpClass:RefreshView()
	local preRune,newRune = self._preRune,self._newRune
	if not preRune or not newRune then return end
	self:CreateRuneIcon(newRune)
	self:CreateClassAndLevelDiv()
	local list = gModelRune:GetUpClassAllAttrList(preRune,newRune)
	self:InitQuenchingList(list)
	self:InitUpClassAttrList()
	self:InitSkillList()
	local clazzRefId = preRune.clazzRefId
	local classRef = gModelRune:GetInitRuneQuenchingClassRefByRefId(clazzRefId)
	if classRef then
		local desc = ccLngText(classRef.desc)
		self:SetWndText(self.mDescTxt,desc)
	end
	CS.ShowObject(self.mStarImg,true)
end
------------------------------------------------------------------
return UIReUpClass