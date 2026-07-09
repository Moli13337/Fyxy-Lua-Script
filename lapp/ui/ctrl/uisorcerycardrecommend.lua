---
--- Created by BY.
--- DateTime: 2022/7/27 16:02:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISorceryCardRecommend:LWnd
local UISorceryCardRecommend = LxWndClass("UISorceryCardRecommend", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISorceryCardRecommend:UISorceryCardRecommend()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISorceryCardRecommend:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISorceryCardRecommend:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISorceryCardRecommend:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isEnus = gLGameLanguage:IsEnglishVersion()
	self._isVie = gLGameLanguage:IsVieVersion()
	self:InitEvent()
	self:InitCommand()
end

function UISorceryCardRecommend:InitEvent()
	self:SetWndClick(self.mBgImage,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function ()self:WndClose() end)

end

function UISorceryCardRecommend:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end
function UISorceryCardRecommend:SetRoot2(item,itemdata,parentItem)
	local desText = self:FindWndTrans(item,"DesBg/DesText")
	local cardText = self:FindWndTrans(item,"CardBg/CardText")
	local cardMag = self:FindWndTrans(item,"CardBg/CardMag")

	local _refId = self._refId
	local refId = itemdata.refId
	local cardDetail = string.split(itemdata.cardDetail,",")

	CS.ShowObject(item,_refId == refId)
	if _refId ~= refId then
		LxUiHelper.SetSizeWithCurAnchor(parentItem,1,50)
		return
	end
	self:SetWndText(desText,ccLngText(itemdata.effectTxt,true))
	self:SetWndText(cardText,ccClientText(29517))
	for i = 1, 3 do
		local card = self:FindWndTrans(cardMag,"Card"..i)
		self:SetCardItem(card,cardDetail[i])
	end
	local uiCardText = self:FindWndText(cardText)
	local height = uiCardText.preferredHeight
	LxUiHelper.SetSizeWithCurAnchor(parentItem,1,height + 50 + 28 + 258)
end
function UISorceryCardRecommend:SetTagItem(item,tagStr)
	if not item then return end
	CS.ShowObject(item,tagStr)
	if not tagStr then return end
	local tagText = self:FindWndTrans(item,"TagText")
	self:SetWndText(tagText,tagStr)
end
function UISorceryCardRecommend:SetCardItem(item,itemdata)
	if not item then return end
	CS.ShowObject(item,itemdata)
	if not itemdata then return end
	local icon = self:FindWndTrans(item,"Icon")
	local maskSeal = self:FindWndTrans(item,"MaskSeal")
	local maskLock = self:FindWndTrans(item,"MaskLock")
	local nameText = self:FindWndTrans(item,"NameText")

	if self._isEnus then
		self:InitTextSizeWithLanguage(nameText,-4)
	end

	local _cardList = self._cardList or {}
	local refId = tonumber(itemdata)
	local ref = gModelSorceryCard:GetSorceryCardRefByRefId(refId)
	if not ref then return end
	local themeRef = gModelSorceryCard:GetSorceryCardThemeRefByRefId(ref.theme)
	local _card = _cardList[refId]

	self:SetWndText(nameText,ccLngText(ref.name))
	if self._isVie then
		self:InitTextSizeWithLanguage(nameText,-2)
		self:InitTextCharacterWithLanguage(nameText,-8)
	end
	self:SetTextTile(maskSeal, ccClientText(29570))
	self:SetWndEasyImage(item,ref.frameRes)
	self:SetWndEasyImage(icon,ref.icon,nil,true)
	self:SetWndEasyImage(maskLock,themeRef.cardFrame,nil,false,false)
	self:SetWndEasyImage(maskSeal,themeRef.cardFrame,nil,false,false)
	self:SetWndClick(item,function ()
		self:OnClickCard(refId)
	end)
	CS.ShowObject(maskLock,false)
	CS.ShowObject(maskSeal,false)
	if not _card then
		local isUp = gModelSorceryCard:VerifyCardUpCost(refId,0)
		CS.ShowObject(maskLock,not isUp)
		CS.ShowObject(maskSeal,isUp)
	end
end
function UISorceryCardRecommend:InitCommand()
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:SetWndText(self.mLblBiaoti,ccClientText(29507))
	self:InitTextLineWithLanguage(self.mLblBiaoti, -30)
	self:InitTextSizeWithLanguage(self.mLblBiaoti, -4)
	self:SetWndText(self.mTipsText,ccClientText(29541,true))

	local refId = self:GetWndArg("refId")
	local cardList = gModelSorceryCard:GetCardList()
	if not cardList then end
	self._cardList = cardList
	local ref = gModelSorceryCard:GetSorceryCardRefByRefId(refId)
	if not ref then return end

	local linkCard = string.split(ref.linkCard,"|")
	local list = {}
	for i, v in ipairs(linkCard) do
		local gRefId = tonumber(v)
		local gRef = gModelSorceryCard:GetSorceryCardRecomGroupRefByRefId(gRefId)
		table.insert(list,gRef)
	end
	local len = #list
	CS.ShowObject(self.mNoRecord2,len <= 0)

	local uiList = self:GetUIScroll("")
	uiList:Create(self.mCellSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
	self._uiList = uiList

	if len <= 0 then
		self:CreateEmptyShow(10010)
	else
		self:OnClickRoot1(list[1])
	end
end
function UISorceryCardRecommend:SetRoot1(item,itemdata)
	local nameText = self:FindWndTrans(item,"Image/TrGroup/NameText")
	local tagGroup = self:FindWndTrans(item,"Image/TrGroup/Tag/TagGroup")
	local unfold = self:FindWndTrans(item,"Image/Unfold")
	local fewer = self:FindWndTrans(item,"Image/Fewer")

	local _refId = self._refId
	local refId = itemdata.refId
	local tag = string.split(ccLngText(itemdata.tag),"|")

	self:SetWndText(nameText,ccLngText(itemdata.name))
	for i = 1, 3 do
		local tagTr = self:FindWndTrans(tagGroup,"Tag"..i)
		local tagStr = tag[i]
		self:SetTagItem(tagTr,tagStr)
	end
	CS.ShowObject(unfold,_refId ~= refId)
	CS.ShowObject(fewer,_refId == refId)
	self:SetWndClick(item,function ()
		self:OnClickRoot1(itemdata)
	end)
end
function UISorceryCardRecommend:OnClickCard(refId)
	GF.OpenWnd("UISorceryCardUpLv",{refId = refId})
	self:WndClose()
end

function UISorceryCardRecommend:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local root1 = self:FindWndTrans(root,"Root1")
	local root2 = self:FindWndTrans(root,"Root2")

	self:SetRoot1(root1,itemdata)
	self:SetRoot2(root2,itemdata,item)
end

function UISorceryCardRecommend:OnClickRoot1(itemdata)
	local _refId = self._refId or 0
	self._refId = itemdata.refId == _refId and 0 or itemdata.refId
	self._uiList:DrawAllItems()
end
------------------------------------------------------------------
return UISorceryCardRecommend


