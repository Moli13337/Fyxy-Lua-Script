---
--- Created by BY.
--- DateTime: 2023/10/25 10:18:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPop3Gift:LWnd
local UIPop3Gift = LxWndClass("UIPop3Gift", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPop3Gift:UIPop3Gift()
	self._starList = {}
	self._moveKey = "_moveKey"
	self._distance = 150
	self._moveTime = 0.25
	self._bDrag = true
	self._uiIconEasyList = {}
	self._timeList = {}
	self._key = 1
	self._giftIndex = 1
	self._timeKey = "timeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPop3Gift:OnWndClose()
	self:ClearCommonIconList(self._uiIconEasyList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPop3Gift:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPop3Gift:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	--self:DoWndStartScale(0,self.mAniRoot)
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	self:InitDrag()
end
--------------------------------------拖动---------------------------------
function UIPop3Gift:InitDrag()--拖动
	self:UIDragSetItem("sssss","Pop/ViewMove",CS.YXUIDrag.DragMode.DragOrigin)
end

function UIPop3Gift:StarListItem(list,item,itemdata,itempos)
	self._starList[itemdata.id] = item
end

function UIPop3Gift:SetGiftInfo(root,gift)
	local InstanceID = root:GetInstanceID()
	local bgImg = CS.FindTrans(root,"BgImg")
	local heroSpine = CS.FindTrans(root,"BgImg/HeroSpine")
	local showIcon = CS.FindTrans(root,"BgImg/HeroSpine/ShowIcon")

	local nameBg = CS.FindTrans(root,"BgImg/NameBg")
	local btnLook = CS.FindTrans(root,"BgImg/NameBg/BtnLook")
	local nameText = CS.FindTrans(root,"BgImg/NameBg/NameText")

	self:InitTextSizeWithLanguage(nameText,-6)

	local titleImg = CS.FindTrans(root,"BgImg/TitleImg")
	local titleBg = CS.FindTrans(root,"BgImg/TitleBg")
	local titleText = CS.FindTrans(root,"BgImg/TitleBg/TitleText")

	local itemScroll = CS.FindTrans(root,"BgImg/Image/ItemScroll")

	local originalText = CS.FindTrans(root,"OriginalText")
	local originalItemText = CS.FindTrans(root,"OriginalItemText")

	local btnPay = CS.FindTrans(root,"BtnPay")
	local payText = CS.FindTrans(root,"BtnPay/PayText")
	local payItemText = CS.FindTrans(root,"BtnPay/PayItemText")
	local payItemIcon = CS.FindTrans(root,"BtnPay/PayItemText/Image")
	local maskPay = CS.FindTrans(root,"MaskPay")
	local timeBg = CS.FindTrans(root,"TimeBg")
	local timeText = CS.FindTrans(root,"TimeBg/TimeText")

	local specialGiftRef = gift.specialGiftRef
	local popupGiftRef = gift.ref

	self:SetWndEasyImage(bgImg,specialGiftRef.bgIcon)
	local showIconArr = string.split(specialGiftRef.showIcon,"=")
	CS.ShowObject(showIcon,showIconArr[1] == "1")
	if showIconArr[1] == "1" then
		self:SetWndEasyImage(showIcon,showIconArr[2])
		local showIconPos = string.split(specialGiftRef.showIconPos,",")
		showIcon.localPosition = Vector2.New(tonumber(showIconPos[1]),tonumber(showIconPos[2]))
		showIcon.localScale = Vector3(specialGiftRef.showIconSize,specialGiftRef.showIconSize,specialGiftRef.showIconSize)
		local bFilp = specialGiftRef.flip == 1
		self._skeleton.ScaleX = (bFilp and -1 or 1)
	else
		self:SetSpine(heroSpine,showIconArr[2],specialGiftRef)
	end
	local isShowName = ccLngText(specialGiftRef.jumpDesc) ~= ""
	CS.ShowObject(nameBg,isShowName)
	if isShowName then
		local jumpPos = string.split(specialGiftRef.jumpPos,",")
		nameBg.localPosition = Vector2.New(tonumber(jumpPos[1]),tonumber(jumpPos[2]))
		self:SetWndClick(btnLook,function ()
			local jump = string.split(specialGiftRef.jump,"=")
			if jump[1] == "1" then
				gModelFunctionOpen:Jump(tonumber(jump[2]),self:GetWndName())
			elseif jump[1] == "2" then
				local skins = jump[2]
				local list = {}
				local skinArr = string.split(skins,"|")
				for i, v in ipairs(skinArr) do
					table.insert(list,tonumber(v))
				end
				gModelGeneral:OpenHeroSkin({skinRefIds = list,preview = true})
				self:WndClose()
			elseif jump[1] == "3" then
				gModelGeneral:OpenHeroStarPre({refId = tonumber(jump[2])})
			elseif jump[1] == "4" then

				--gModelBattle:OnClickShamBattle(tonumber(jump[2]),function()
				--	FireEvent(EventNames.OPEN_HISTROY_WND)
				--end)
				--self:WndClose()
				gModelBattle:OnClickShamBattle(tonumber(jump[2]))
			end
		end)
		self:SetWndText(nameText,ccLngText(specialGiftRef.jumpDesc))
	end

	self:SetWndEasyImage(titleImg,specialGiftRef.titleIcon)
	local titleIconPos = string.split(specialGiftRef.titleIconPos,",")
	titleImg.localPosition = Vector2.New(tonumber(titleIconPos[1]),tonumber(titleIconPos[2]))
	local showDescPos = string.split(specialGiftRef.showDescPos,",")
	titleBg.localPosition = Vector2.New(tonumber(showDescPos[1]),tonumber(showDescPos[2]))
	self:SetWndText(titleText,ccLngText(specialGiftRef.showDesc))

	local itemList = LxDataHelper.ParseItem(popupGiftRef.reward)
	local uiIconEasyList = self._uiIconEasyList[InstanceID]
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		self._uiIconEasyList[InstanceID] = uiIconEasyList
		uiIconEasyList:Create(self, itemScroll)
		uiIconEasyList:SetIconClickPath("Root/CommonUI/Icon")
		uiIconEasyList:SetIconParentPath("Root/CommonUI/Icon")
	end
	uiIconEasyList:RefreshList(itemList)

	local isGift = gModelPopupGift:GetSpecialGiftListById(specialGiftRef.showGroup,gift.id)

	self:ChangeStarList(gift.id)
	CS.ShowObject(maskPay,not isGift)
	CS.ShowObject(btnPay,isGift)
	CS.ShowObject(timeBg,isGift)
	if not isGift then
		CS.ShowObject(originalText,false)
		CS.ShowObject(originalItemText,false)

		return
	end

	local originalPrice = string.split(specialGiftRef.originalPrice,"=")
	local originalPriceType = originalPrice[1]
	local isShowItem = originalPriceType == "2"
	CS.ShowObject(originalText,not isShowItem)
	CS.ShowObject(originalItemText,isShowItem)
	local originalStr = originalPrice[2]
	if originalPriceType == "1" then
		originalStr = string.replace(ccClientText(14902),originalStr)
	elseif originalPriceType == "3" then
		--计费点
		originalStr = gModelPay:GetShowByWelfareId(tonumber(originalStr))
	end
	self:SetWndText(originalText,string.replace(ccClientText(14907),originalStr))
	self:SetWndText(originalItemText,string.replace(ccClientText(14907),"      "..originalStr))

	CS.ShowObject(payItemText,popupGiftRef.buyType == ModelPopupGift.BUYTYPE_JEWEL)
	CS.ShowObject(payText,popupGiftRef.buyType ~= ModelPopupGift.BUYTYPE_JEWEL)
	local payStr = ""
	if(popupGiftRef.buyType == ModelPopupGift.BUYTYPE_JEWEL)then
		local item = LxDataHelper.ParseItem_3(popupGiftRef.expend)
		local icon = gModelItem:GetItemIconByRefId(item.itemId)
		self:SetWndEasyImage(payItemIcon,icon)
		payStr = item.itemNum
	elseif(popupGiftRef.buyType == ModelPopupGift.BUYTYPE_MONEY)then
		--local money = gModelPay:GetRMBValueByWelfareId(tonumber(popupGiftRef.expend))
		payStr =gModelPay:GetShowByWelfareId(tonumber(popupGiftRef.expend)) -- string.replace(ccClientText(14902),money)
	elseif(popupGiftRef.buyType == ModelPopupGift.BUYTYPE_FREE)then
		payStr = ccClientText(14903)
	end
	self:SetWndText(payText,payStr)
	self:SetWndText(payItemText,payStr)

	self._timeList[InstanceID] = {text = timeText,showGroup = specialGiftRef.showGroup,id = gift.id}
	if not self:IsTimerExist(self._timeKey) then
		self:TimerStart(self._timeKey,1,false,-1)
	end
	self:SetTime()

	self:SetWndClick(btnPay,function ()
		self:OnClickPay(specialGiftRef.showGroup,gift.id)
	end)
end

function UIPop3Gift:InitMessage()
	self:WndNetMsgRecv(LProtoIds.PopupGiftNowListResp,function (...)
		self:RefreshDate()
	end)
end

function UIPop3Gift:OnTimer(key)
	self:SetTime()
end

function UIPop3Gift:InitCommand()
	local id = self:GetWndArg("id")
	local showGroup = self:GetWndArg("showGroup")
	self._gifts = gModelPopupGift:GetSpecialGiftListByKey(showGroup)
	local list = self._gifts
	self._giftLen = #list
	if self._giftLen > 1 then
		local _uiList = self:GetUIScroll("starList")
		_uiList:Create(self.mStarScroll,list,function (...) self:StarListItem(...) end)
	end

	self._rootList = {
		self.mRoot1,
		self.mRoot2,
	}
	self:RefreshDate()
end

function UIPop3Gift:UIDragTryOnEnd(dragKey,eventData)
	self.mViewMove.transform.localPosition = Vector2.New(0,0)
	self._bDrag = true
end

function UIPop3Gift:ChangeStarList(id)
	for i, v in pairs(self._starList) do
		local on = CS.FindTrans(v,"OnImage")
		CS.ShowObject(on,i == id)
	end
end

function UIPop3Gift:MovePage(moveX,moveTime)
	local seqTween
	self:TweenSeqKill(self._moveKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._moveKey,function(seq)
			for i, v in ipairs(self._rootList) do
				CS.ShowObject(v,true)
				local vec = Vector2.New(v.localPosition.x + moveX,v.localPosition.y)
				local tweener = v:DOLocalMove(vec,moveTime)
				seq:Join(tweener)
			end
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._moveKey)
		self._bMove = true
		local keyi = self._key == 1 and 2 or 1
		CS.ShowObject(self._rootList[keyi],false)
	end)
end
--------------------------------------设置---------------------------------
function UIPop3Gift:MoveRoot(index)
	local _giftLen = self._giftLen
	if _giftLen <= 1 then
		return
	end
	local _key,_giftIndex,width,_rootList = self._key,self._giftIndex,self.mPop.rect.width,self._rootList
	local move
	local _rootKey = _key == 1 and 2 or 1
	if index == 1 then
		move = width
		_giftIndex = _giftIndex - 1
		if _giftIndex < 1 then
			_giftIndex = _giftLen
		end
	elseif index == 2 then
		move = - width
		_giftIndex = _giftIndex + 1
		if _giftIndex > _giftLen then
			_giftIndex = 1
		end
	end
	_rootList[_rootKey].localPosition = Vector2.New(_rootList[_key].localPosition.x - move,_rootList[_rootKey].localPosition.y)

	self._giftIndex = _giftIndex
	self._key = _rootKey
	self:RefreshDate()
	self:MovePage(move,self._moveTime)
end

--点击购买
function UIPop3Gift:OnClickPay(showGroup,id)
	local _gift = gModelPopupGift:GetSpecialGiftListById(showGroup,id)
	if not _gift then
		return
	end
	local ref = _gift.ref
	if(ref.buyType == ModelPopupGift.BUYTYPE_MONEY)then
		ModelPay:GiftPayCtrl(_gift.id,tonumber(ref.expend),ModelPay.PAY_TYPE_GIFT,ModelPay.PAY_GIFT_POPUPGIFT)
		return
	elseif(ref.buyType == ModelPopupGift.BUYTYPE_FREE)then
		gModelPopupGift:OnPopupGiftBuyReq(_gift.id)
		return
	end
	local item = LxDataHelper.ParseItem_3(ref.expend)
	local num = gModelItem:GetNumByRefId(item.itemId)
	if(num < item.itemNum)then
		local wndName = self:GetWndName()
		gModelGeneral:OpenGetWayWnd({itemId = item.itemId,srcWnd = wndName})
		return
	end
	gModelPopupGift:OnPopupGiftBuyReq(_gift.id)
end

--设置形象
function UIPop3Gift:SetSpine(paintTans,prefabName,ref)
	if not ref then
		return
	end
	local spine = prefabName
	local key = "spine"..self._key
	if(self._oldSpine and self._oldSpine ~= spine and self._oldKey and self._oldKey == key)then
		self:DestroyWndSpineByKey(key)
	end
	self:CreateWndSpine(paintTans,spine,key,false,function(dpSpine)
		local dpTrans = dpSpine:GetDisplayTrans()
		dpTrans.anchorMin = Vector2.New(0.5,0.5)
		dpTrans.anchorMax = Vector2.New(0.5,0.5)
		dpSpine:SetFlipX(ref.flip == 1)
		dpSpine:SetScale(ref.showIconSize)
		local showIconPos = string.split(ref.showIconPos,",")
		dpTrans.localPosition = Vector2.New(tonumber(showIconPos[1]),tonumber(showIconPos[2]))
		dpSpine:SetRaycastTarget(false)
	end)
	self._oldKey = key
	self._oldSpine = spine
end

function UIPop3Gift:RefreshDate()
	if not self._gifts or #self._gifts <= 0 then
		self:WndClose()
		return
	end
	self:SetGiftInfo(self._rootList[self._key],self._gifts[self._giftIndex])
end

function UIPop3Gift:SetTime()
	local time = GetTimestamp()
	for i, v in pairs(self._timeList) do
		local gift = gModelPopupGift:GetSpecialGiftListById(v.showGroup,v.id)
		if gift then
			local timespan = gift.endTime/1000 - time
			local timeStr = LUtil.FormatTimespanCn(timespan,{hTextId = 10371})
			self:SetWndText(v.text,string.replace(ccClientText(11637),timeStr))
		end
	end
end

function UIPop3Gift:UIDragOnDrag(dragKey,eventData)
	local moveX = self.mViewMove.transform.localPosition.x
	if(not self._bDrag)then
		return
	end
	if(moveX > self._distance )then
		self:MoveRoot(1)
		self._bDrag = false
	elseif(moveX < - self._distance)then
		self:MoveRoot(2)
		self._bDrag = false
	end
end

function UIPop3Gift:InitEvent()
	self:SetWndClick(self.mCloseBtn, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end
------------------------------------------------------------------
return UIPop3Gift


