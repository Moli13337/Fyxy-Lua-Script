---
--- Created by BY.
--- DateTime: 2023/2/13 18:34:50
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISorceryCardSpeedSet:LWnd
local UISorceryCardSpeedSet = LxWndClass("UISorceryCardSpeedSet", LWnd)
local typeLayoutElement = typeof(UnityEngine.UI.LayoutElement)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISorceryCardSpeedSet:UISorceryCardSpeedSet()
	self._heroIconList = {}
	self.isTipsList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISorceryCardSpeedSet:OnWndClose()
	self:ClearCommonIconList(self._heroIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISorceryCardSpeedSet:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISorceryCardSpeedSet:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UISorceryCardSpeedSet:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty1")
	emptyList:RefreshUI(data)
end

function UISorceryCardSpeedSet:InitEvent()
	self:SetWndClick(self.mBgImage,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function ()self:WndClose() end)
end
function UISorceryCardSpeedSet:SetRoot1(item,itemdata,itempos)
	local titleText = self:FindWndTrans(item,"TitleText")
	local buffMar = self:FindWndTrans(item,"BuffMar")
	local btnHelp = self:FindWndTrans(item,"BtnHelp")
	local groupMar = self:FindWndTrans(item,"GroupMar")

	if self._isEnus then
		self:SetAnchorPos(buffMar,Vector2.New(155,-13.7))
	end


	local tag = string.split(ccLngText(itemdata.tag),"|")
	local cardDetail = string.split(itemdata.cardDetail,",")
	for i = 1, 3 do
		local itemCell = self:FindWndTrans(groupMar,"Item"..i)
		self:CardListItem(itemCell,cardDetail[i],i,itempos)
	end
	for i = 1, 3 do
		local itemCell = self:FindWndTrans(buffMar,"Buff"..i)
		self:BuffListItem(itemCell,tag[i],i,itempos)
	end

	self:SetWndText(titleText,ccLngText(itemdata.name))
	self:SetWndClick(btnHelp, function()
		self:OnClickTips(itempos)
	end)
end
function UISorceryCardSpeedSet:BuffListItem(item, itemdata, itempos,layer)
	if not item then return end
	CS.ShowObject(item,itemdata)
	if not itemdata then return end
	local buffText = self:FindWndTrans(item,"BuffText")
	self:SetWndText(buffText,itemdata)

	local uiText = LxUiHelper.FindXTextCtrl(buffText)
	local width = uiText.preferredWidth
	--LxUiHelper.SetSizeWithCurAnchor(item,2,width + 22)
	local layoutElement = self:FindCommonComponent(item,typeLayoutElement)
	layoutElement.preferredWidth = width + 22
end

function UISorceryCardSpeedSet:SetRoot2(item,itemdata)
	local desTitleText = self:FindWndTrans(item,"DesTitleText")
	local desText = self:FindWndTrans(item,"DesText")

	self:SetWndText(desTitleText,ccClientText(29568))
	self:SetWndText(desText,ccLngText(itemdata.effectTxt))
	local uiText = LxUiHelper.FindXTextCtrl(desText)
	local height = uiText.preferredHeight
	return height
end

function UISorceryCardSpeedSet:RefreshData()
	local list = self:GetCardGroupByTheme()
	self._cellList = list
	local uiList = self._uiList

	local len = #list
	CS.ShowObject(self.mNoRecord3,len <= 0)
	if len <= 0 then
		self:CreateEmptyShow(10006)
	end
	if uiList then
		uiList:RefreshList(list)
		uiList:DrawAllItems()
	else
		uiList = self:GetUIScroll("mCellSuper_UISorceryCardSpeedSet")
		self._uiList = uiList
		uiList:Create(self.mCellSuper,list,function(...) self:ListItem(...) end,UIItemList.SUPER)
		uiList:EnableScroll(true,false)
	end
end
function UISorceryCardSpeedSet:OnClickWearCard(cardRefId,heroId)
	GF.OpenWnd("UISorceryCardSpeedHero",{refId = cardRefId,heroId = heroId})
end

function UISorceryCardSpeedSet:ListItem(list,item, itemdata, itempos)
	local image = CS.FindTrans(item, "Image")
	local root1 = self:FindWndTrans(item,"Root1")
	local root2 = self:FindWndTrans(item,"Root2")

	-- local isTips = itemdata.isTips
	local isTips = self.isTipsList[itempos]
	self:SetRoot1(root1,itemdata,itempos)
	CS.ShowObject(root2,isTips)
	if isTips then
		local height = self:SetRoot2(root2,itemdata)
		LxUiHelper.SetSizeWithCurAnchor(root2,1,height + 70)
		LxUiHelper.SetSizeWithCurAnchor(item,1,height + 280 + 70)
		image.sizeDelta = Vector2.New(552, height + 280 + 70)
	else
		LxUiHelper.SetSizeWithCurAnchor(item,1,280)
		image.sizeDelta = Vector2.New(552, 280)
	end
end
function UISorceryCardSpeedSet:InitMessage()
	self:WndNetMsgRecv(LProtoIds.SorceryCardWearResp,function(pb) self:RefreshData() end)
	self:WndNetMsgRecv(LProtoIds.SorceryCardUnloadResp,function(pb) self:RefreshData() end)
end
function UISorceryCardSpeedSet:CardListItem(item, itemdata, itempos,layer)
	if not item then return end
	CS.ShowObject(item,itemdata)
	if not itemdata then return end
	local heroRoot = self:FindWndTrans(item,"HeroBg/HeroRoot")
	local lock = self:FindWndTrans(item,"HeroBg/Lock")
	local cardFrame = self:FindWndTrans(item,"CardBg")
	local cardIcon = self:FindWndTrans(item,"CardIcon")
	local nameText = self:FindWndTrans(item,"NameText")

	local InstanceID = item:GetInstanceID()
	local cardList = gModelSorceryCard:GetCardList()
	local cardId = tonumber(itemdata)
	local cardInfo = cardList[cardId]
	local heroId = cardInfo and cardInfo.heroId or "0"
	local isHero = tonumber(heroId) > 0
	local cardRef = gModelSorceryCard:GetSorceryCardRefByRefId(cardId)

	CS.ShowObject(heroRoot,isHero)
	CS.ShowObject(lock,not cardInfo)
	self:SetWndEasyImage(cardIcon,cardRef.icon)
	self:SetWndEasyImage(cardFrame,cardRef.frameRes)
	self:SetWndText(nameText,ccLngText(cardRef.name))
	if isHero then
		local baseClass = self._heroIconList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New(self)
			self._heroIconList[InstanceID] = baseClass
			baseClass:Create(heroRoot)
		end
		baseClass:SetHeroPlayer(heroId)
		baseClass:DoApply()
	end
	self:SetWndClick(item,function ()
		if cardInfo then
			self:OnClickWearCard(cardId,heroId)
		end
	end)
	self:SetWndClick(cardIcon,function ()
		local curLv = cardInfo and cardInfo.level or 0
		local skillGroup = cardRef.skillGroup
		local skillRef,skillLock = gModelSorceryCard:GetSorceryCardSkillRef(skillGroup,curLv)
		local argList = {
			skill = skillRef.skill,
			wndType = 7,
			cardId = cardId,
			skillGroup = skillRef.group,
			cardLevel = curLv
		}
		gModelGeneral:OpenSkillWnd(argList)
	end)
end

function UISorceryCardSpeedSet:OnClickTips(itempos)
	local list = self._cellList
	if not list then return end
	-- list[itempos].isTips = not list[itempos].isTips
	if not self.isTipsList[itempos] then
		self.isTipsList[itempos] = false
	end
	self.isTipsList[itempos] = not self.isTipsList[itempos]
	local len = #list
	self._cellList = list
	local _uiList = self._uiList
	if _uiList then
		if itempos == len then
			_uiList:MoveToPos(itempos)
		else
			_uiList:DrawItemByIndex(itempos)
		end
	end
end
function UISorceryCardSpeedSet:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(29559))
	self:SetWndText(self.mDesText,ccClientText(29560))

	self:RefreshData()
end

function UISorceryCardSpeedSet:GetCardGroupByTheme(theme)
	local cardList = gModelSorceryCard:GetCardList()
	local actList = {}
	local theme = theme or 0
	local list = gModelSorceryCard:GetSorceryCardRecomGroupRefByTheme(theme)
	for i, v in ipairs(list) do
		local isAct = false
		local cardDetail = string.split(v.cardDetail,",")
		for j, k in ipairs(cardDetail) do
			if cardList[tonumber(k)] then
				isAct = true
				break
			end
		end
		if isAct then
			table.insert(actList,v)
		end
	end
	return actList
end
------------------------------------------------------------------
return UISorceryCardSpeedSet


