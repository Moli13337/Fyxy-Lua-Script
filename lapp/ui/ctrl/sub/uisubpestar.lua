---
--- Created by Administrator.
--- DateTime: 2024/6/13 15:00:57
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPeStar:LChildWnd
local UISubPeStar = LxWndClass("UISubPeStar", LChildWnd)
local typeofCanvas = typeof(UnityEngine.Canvas)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPeStar:UISubPeStar()
	self.linkPos = {
		{[3]=3},
		{[2]=2,[4]=4},
		{[1]=1,[3]=3,[5]=5},
		{[1]=1,[2]=2,[4]=4,[5]=5},
		{[1]=1,[2]=2,[3]=3,[4]=4,[5]=5}
	}
	self._commonUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPeStar:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPeStar:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPeStar:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:OnAddClick()
	self.argList = self:GetWndArgList()
	self.listLeng = self.argList.allPet and #self.argList.allPet or 0
	self:InitLinkData()
	self:OnUpdatePet()
end
function UISubPeStar:OnUpStar()
	---@type StructPet
	local pet = gModelPet:GetPetById(self.argList.refId)
	if not pet:IsCanUpStar(true) then return end
	gModelPet:OnPetUpSatrReq(self.argList.refId)
end

function UISubPeStar:OnShare()
	local data = {
        root = self.mBtnShare,
        shareType = ModelChat.CHAT_SHARE_41,
        shareData = tostring(self.argList.refId),
    }

    gModelGeneral:OpenShareTip(data)
end


function UISubPeStar:OnSkillDesc()
	---@type StructPet
	local pet = gModelPet:GetPetById(self.argList.refId)
	local desc,conditionDesc,isCondition = pet:GetLinkSkillDesc()
	self:SetWndText(self.mTxtLinkDesc,desc or "")
	self:SetWndText(self.mTxtLinkCond,conditionDesc or "")
	CS.ShowObject(self.mTxtLinkCond,isCondition)

	local petStarCfg = pet:GetPetStarCfg(0)
	local attrAdd = petStarCfg.attrChangeAdd
	local attrStar = pet._star
	while((pet._star>petStarCfg.rankNow and petStarCfg.rankNext>0) or attrAdd<=0) do
		petStarCfg = GameTable.MagicPetStarRef[petStarCfg.rankNext]
		attrAdd = petStarCfg.attrChangeAdd>0 and petStarCfg.attrChangeAdd or attrAdd
		attrStar = petStarCfg.rankNow
	end
	local nexStarCfg = pet:GetPetStarCfg(pet._star+1)
	local nexAttrAdd
	if nexStarCfg and nexStarCfg.attrChangeAdd>0 and pet._star>=attrStar then
		nexAttrAdd = " <color=#139057>(+"..(nexStarCfg.attrChangeAdd-attrAdd).."%)</color>"
	end
	local color = (pet._star>=attrStar and pet.isActive) and "#D2730F" or "#C81212"
	self:SetWndText(self.mTxtWholeAttr,string.replace(ccClientText(43714),color,nexAttrAdd and attrAdd.."%"..nexAttrAdd or attrAdd.."%"))
	self:SetWndText(self.mTxtWholeCond,string.replace(ccClientText(43713),attrStar))
	CS.ShowObject(self.mTxtWholeCond,pet._star~=attrStar or not pet.isActive)
end
function UISubPeStar:OnRightClick()
	self.argList.index = self.argList.index+1
	self.argList.refId = self.argList.allPet[self.argList.index].refId
	self:InitLinkData()
	self:OnUpdatePet()
	FireEvent(EventNames.PET_INFO_CHANGE)
end

function UISubPeStar:OnUpdateUpStarCost()
	local petInfo = gModelPet:GetPetById(self.argList.refId)
	local starCfg = petInfo:GetPetStarCfg()
	CS.ShowObject(self.mSlider.transform,starCfg.rankNext>0 and true or false)
	CS.ShowObject(self.mBtnCommon,starCfg.rankNext>0 and true or false)
	CS.ShowObject(self.mTxtFull,starCfg.rankNext<0 and true or false)
	self:SetWndButtonText(self.mBtnCommon,petInfo.isActive and ccClientText(43736) or ccClientText(43737))
	if starCfg.rankNext<0 then
		self:SetWndText(self.mTxtFull,ccClientText(43738))
		return
	end
	local cost = petInfo.isActive and GameTable.MagicPetStarRef[starCfg.rankNext].upNeed or starCfg.upNeed
	local costItem = LxDataHelper.ParseItem_4(cost)
	if costItem then
		local hasNum = gModelItem:GetNumByRefId(costItem.itemId)
		self.mSlider.value = hasNum/costItem.itemNum
		self:SetWndText(self.mTxtProBar,LUtil.NumberCoversion(hasNum).."/"..costItem.itemNum)
	end
end
function UISubPeStar:OnUpdateArrow()
	CS.ShowObject(self.mBtnLeft,self.argList.index>1)
    CS.ShowObject(self.mBtnRight,self.argList.index<self.listLeng)
end

function UISubPeStar:OnAddClick()
	self:SetWndClick(self.mBtnLeft,function()
		self:OnLeftClick()
	end)

	self:SetWndClick(self.mBtnRight,function()
		self:OnRightClick()
	end)

	self:SetWndClick(self.mBtnShare,function()
		self:OnShare()
	end)

	self:SetWndClick(self.mBtnCommon,function()
		self:OnUpStar()
	end)
	self:SetWndClick(self.mBtnAttrHelp,function()
		GF.OpenWnd("UIPeLinkJN",{refId = self.argList.refId})
	end)

	self:WndEventRecv(EventNames.On_Item_Change,function ()
		self:OnUpdateUpStarCost()
	end)
	self:WndNetMsgRecv(LProtoIds.PetLinkResp,function() self:OnUpdateLinkHero() end)
	self:WndNetMsgRecv(LProtoIds.PetOneKeyLinkResp,function() self:OnUpdateLinkHero() end)

	self:WndEventRecv(EventNames.PET_CHANGE_LEVEL,function ()
		local pet = gModelPet:GetPetById(self.argList.refId)
		self:SetWndText(self.mTxtLevel,string.replace(ccClientText(43766),pet._level,pet.maxLevel))
	end)
	self:WndEventRecv(EventNames.PET_CHANGE_STAR,function ()
		self:OnUpdateUpStarCost()
		self:OnUpdateStar()
		self:OnSkillDesc()
		self:OnUpdateAttr()
		self:OnUpdateLinkHero()
		self:OnUpdateRed()
	end)
end

function UISubPeStar:InitLinkData()
	local starCfgs = gModelPet.petStarCfg[self.argList.refId]
	self.linkCfg = {}
	local leng = #starCfgs
	for i = 0, leng do
		local cfg = starCfgs[i]
		if cfg.link and cfg.link >0 then table.insert(self.linkCfg,cfg) end
	end
end

function UISubPeStar:OnUpdateAttr()
	---@type StructPet
	local pet = gModelPet:GetPetById(self.argList.refId)
	local attrs = {}
	self.nexStarAttr = {}
	self.curStarAttr = {}
	if pet.isActive then
		local lvAttr = pet:GetLvAttr(true)
		local starAttr = pet:GetStarAttr(true)
		local attrStr = not string.isempty(lvAttr) and lvAttr..(not string.isempty(starAttr) and ","..starAttr or "") or starAttr
		local equipAttr = pet:GetEquipAttr(true)
		attrs = LUtil.GetTwoCommonAttrAddSortList(LUtil.ConvertCommonAttrStrToList(attrStr),LUtil.ConvertCommonAttrStrToList(equipAttr))
		local curStarCfg = pet:GetPetStarCfg()
		if curStarCfg.rankNext>0 then
			self.curStarAttr = LUtil.ConvertCommonAttrStrToMap(starAttr)
			self.nexStarAttr = LUtil.ConvertCommonAttrStrToMap(GameTable.MagicPetStarRef[curStarCfg.rankNext].attr) or {}
		end
	else--未激活
		local starCfg = pet:GetPetStarCfg()
		self.nexStarAttr =LUtil.ConvertCommonAttrStrToMap(starCfg.attr)
		for refId, attr in pairs(self.nexStarAttr) do
			for type, attrNum in pairs(attr or {}) do
				table.insert(attrs,{attrRefId = refId,attrType = type,attrNum=0})
			end
		end
	end
	local uiAttrList = self._uiAttrList
	self.curAttrAdd = gModelPet:GetTotalAttrAdd()
	if uiAttrList then
		uiAttrList:RefreshList(attrs)
	else
		uiAttrList = self:GetUIScroll("favorAttrList")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,attrs,function(...) self:OnDrawAttrCell(...) end)
	end
end
function UISubPeStar:OnWndRefresh()
	LChildWnd.OnWndRefresh(self)
	self:InitLinkData()
	self:OnUpdatePet()
end
function UISubPeStar:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local AttrAdd = self:FindWndTrans(item,"AttrAdd")
	local numType,refId,value = itemdata.attrType,itemdata.attrRefId,itemdata.attrNum
	if AttrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon)
	end

	if AttrName then
		local name = gModelHero:GetAttributeNameById(refId)
		self:SetWndText(AttrName,name)
	end

	if AttrValue then
		local addVal = math.floor(value*self.curAttrAdd*0.01)
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value+addVal)
		self:SetWndText(AttrValue,"+"..valueStr)
	end
	self:SetWndText(AttrAdd,"")
	--local pos = AttrValue.anchoredPosition
	if AttrAdd and self.nexStarAttr[refId] and self.nexStarAttr[refId][numType] then
		local curStarAttrVal = self.curStarAttr[refId] and self.curStarAttr[refId][numType] or 0
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,self.nexStarAttr[refId][numType]- curStarAttrVal)
		self:SetWndText(AttrAdd,"+"..valueStr)
		--pos.x = 115
	else
		--pos.x = 135
	end
	--AttrValue.anchoredPosition = pos

end

function UISubPeStar:OnUpdateLinkHero()
	local linkNum = #self.linkCfg
	local indexs = self.linkPos[linkNum]
	local indx = 0
	---@type StructPet
	local pet = gModelPet:GetPetById(self.argList.refId)
	for i = 1, 5 do
		local link = self.mHeros:GetChild(i-1)
		CS.ShowObject(link,indexs[i] and true,false)
		if indexs[i] then
			indx = indx+1
			local cfg = self.linkCfg[indx]
			local Icon = self:FindWndTrans(link,"CommonUI/Icon")
			local ImgMask = self:FindWndTrans(link,"CommonUI/ImgMask")
			local ImgLink = self:FindWndTrans(link,"ImgLink")
			local IconBg = self:FindWndTrans(link,"CommonUI/IconBg")
			local TxtMask = self:FindWndTrans(ImgMask,"TxtMask")
			local heroId = pet:GetPetLinkHeroId(cfg.link)
			local hasHero = not string.isempty(heroId)
			CS.ShowObject(Icon,hasHero)
			CS.ShowObject(ImgMask, not pet.isActive or pet._star<cfg.rankNow )
			CS.ShowObject(IconBg,not hasHero)
			CS.ShowObject(ImgLink,not not hasHero)
			local instanceId = link:GetInstanceID()
			if hasHero then
				local commonUIList = self._commonUIList
				local uiIconClass = commonUIList[instanceId]
				if not uiIconClass then
					uiIconClass = CommonIcon:New()
					commonUIList[instanceId] = uiIconClass
					uiIconClass:Create(Icon)
					self:SetIconClickScale(Icon, true)
				end
				uiIconClass:SetHeroPlayer(heroId)
				uiIconClass:SetNoShowLv(false)
				uiIconClass:SetShowGouImg(false)
				uiIconClass:DoApply()
				local petCfg = GameTable.MagicPetRef[self.argList.refId]
				local qualityRef = GameTable.RarityRef[petCfg.quality]
				self:CreateWndEffect(ImgLink,qualityRef.petFx,instanceId,100,false,false,nil,nil,nil,nil,nil,nil,0)
			else

				if pet.isActive and pet._star>= cfg.rankNow then
					CS.ShowObject(TxtMask,false)
					self:SetWndEasyImage(IconBg,"public_item_bg_add")
				else
					CS.ShowObject(TxtMask,true)
					self:SetWndEasyImage(IconBg,"public_item_bg_lock")
					local str = cfg.rankNow==0 and ccClientText(43729) or string.replace(ccClientText(43728),cfg.rankNow)
					self:SetWndText(TxtMask,str)
				end
			end
			self:SetWndLongClick(link,function()
				if hasHero then
					local hero = gModelHero:GetHeroById(heroId)
					gModelHero:ReqShowHeroTip("", hero:GetServerData())
				end
			end)
			self:SetWndClick(link,function()
				if pet.isActive and pet._star>= cfg.rankNow then
					GF.OpenWnd("UIPeLinkPop",{refId = self.argList.refId})
				end
			end)
		end
	end
end
function UISubPeStar:OnLeftClick()
	self.argList.index = self.argList.index-1
	self.argList.refId = self.argList.allPet[self.argList.index].refId
	self:InitLinkData()
	self:OnUpdatePet()
	FireEvent(EventNames.PET_INFO_CHANGE)
end
function UISubPeStar:OnUpdatePet()
	local petCfg = GameTable.MagicPetRef[self.argList.refId]
	local pet = gModelPet:GetPetById(self.argList.refId)
	self:SetWndText(self.mTxtName,ccLngText(petCfg.name))
	self:SetWndText(self.mTxtLevel,string.replace(ccClientText(43766),pet._level,pet.maxLevel))
	self:SetWndText(self.mTxtTitleLink,ccClientText(43715))
	self:SetWndText(self.mTxtTitleAttr,ccClientText(43716))
	local qualityIcon = GameTable.RarityRef[petCfg.quality]

    self:SetWndEasyImage(self.mImgType, qualityIcon.qualityText, function()
        CS.ShowObject(self.mImgType, true)
    end)
	if petCfg and string.isempty(petCfg.spine) then
		self:SetWndEasyImage(self.mImgSpine,petCfg.icon,function()
			CS.ShowObject(self.mImgSpine,true)
			local img = self:FindWndImage(self.mImgSpine)
			img:SetNativeSize()
		end)
		CS.ShowObject(self.mPetSpine,false)
	else
		CS.ShowObject(self.mPetSpine,true)
		CS.ShowObject(self.mImgSpine,false)
		self:DestroyWndSpineByKey("PetDrawing")
		local dpSpine = self:CreateWndSpine(self.mPetSpine,petCfg.spine,"PetDrawing",true,function (dpLoaded)
			dpLoaded:PlayAnimation(0,"idle",true)
		end,true)
		dpSpine:StartLoad()
	end

	self:OnUpdateArrow()
	self:OnUpdateStar()
	self:OnSkillDesc()
	self:OnUpdateAttr()
	-- self:UpdateCost()
	self:OnUpdateUpStarCost()
	self:OnUpdateLinkHero()
	self:OnUpdateRed()
end

function UISubPeStar:OnUpdateStar()
	---@type StructPet
	local pet = gModelPet:GetPetById(self.argList.refId)
	local petStarCfg = pet:GetPetStarCfg()
	if petStarCfg.rankNext<=0 then
		CS.ShowObject(self.mImStarFull,true)
		CS.ShowObject(self.mStarLeft,false)
		CS.ShowObject(self.mStarRight,false)
		CS.ShowObject(self.mImgStarBg,false)
	else
		CS.ShowObject(self.mImStarFull,false)
		CS.ShowObject(self.mImgStarBg,true)
		CS.ShowObject(self.mStarLeft,true)
		CS.ShowObject(self.mStarRight,true)

		gModelPet:SetStar(self.mStarLeft,self.argList.refId,nil,function(starPath)
			if pet._star==0 then
				local del = self.mStarLeft.sizeDelta
				del.x = 40
				del.y = 40
				self.mStarLeft.sizeDelta = del
			end
			self:SetWndEasyImage(self.mStarLeft,starPath)
		end)

		local starCfg = GameTable.MagicPetStarRef[petStarCfg.rankNext]
		local nexStar = starCfg.rankNow
		local starPath = gModelPet:GetStarPath(nexStar)
		if starCfg.rankNext <=0 then
			starPath = "hero_icon_star5"
			local del = self.mStarRight.sizeDelta
			del.x = 88
			del.y = 44
			self.mStarRight.sizeDelta = del
		else
			local del = self.mStarRight.sizeDelta
			local num = (nexStar>0 and nexStar%5==0) and 5 or nexStar%5
			del.x = 40*num
			del.y = 40
			self.mStarRight.sizeDelta = del
		end
		self:SetWndEasyImage(self.mStarRight,starPath)

	end
end
function UISubPeStar:OnUpdateRed()
	local red = self:FindWndTrans(self.mBtnCommon,"redPoint")
	---@type StructPet
	local pet = gModelPet:GetPetById(self.argList.refId)
	CS.ShowObject(red,pet:IsCanUpStar())
end

------------------------------------------------------------------
return UISubPeStar