---
--- Created by Administrator.
--- DateTime: 2024/6/13 14:21:37
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPeLink:LChildWnd
local UISubPeLink = LxWndClass("UISubPeLink", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPeLink:UISubPeLink()
	self._commonUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPeLink:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPeLink:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPeLink:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self._isVie = gLGameLanguage:IsVieVersion()
	
	self:SetWndClick(self.mImgHelp, function()
		GF.OpenWnd("UIBzTips",{refId = 170})
    end)
	self:SetWndClick(self.mBtnAttr,function()
		gModelPet:OnPetOneKeyLinkReq()
	end)
	self:WndNetMsgRecv(LProtoIds.PetLinkResp,function() self:OnUpdateList() end)
	self:WndNetMsgRecv(LProtoIds.PetOneKeyLinkResp,function() self:OnUpdateList() end)
	self:WndEventRecv(EventNames.PET_CHANGE_STAR,function()
		self:OnUpdateList()
	 end)
	self:WndEventRecv(EventNames.PET_CHANGE_LEVEL,function()
		self:OnUpdateList()
	 end)
	self:RegisterRedPointFunc(ModelRedPoint.GARDEN_PET_LINK,function(isShow) 
		CS.ShowObject(self.mImgLinkRed,isShow) 
	end)
	self:SetWndText(self.mTxtAttr,ccClientText(43727))
	self:SetWndText(self.mTxtDesc,ccClientText(43726))
	self:OnUpdateList()
	
	self:RefreshForeign()
end

function UISubPeLink:OnUpdateList()
	local cfgs = GameTable.MagicPetRef
	local petList = {}
	for _, value in pairs(cfgs or {}) do
		table.insert(petList,value)
	end
	self:PetSort(petList)
	local uiPetList = self._uiPetList
	if not uiPetList then
        uiPetList = self:GetUIScroll("mLinkListPet")
        self._uiPetList = uiPetList
        uiPetList:Create(self.mListPet, petList, function(...)
            self:OnDrawPetCell(...)
        end, UIItemList.SUPER_GRID, false)
    else
        uiPetList:RefreshList(petList)
		local superList = uiPetList:GetList()
		superList:DrawAllItems()
	end
end

function UISubPeLink:OnHeroCell(list,item,itemdata,itempos)
	local IconBg = self:FindWndTrans(item,"IconBg")
	local Icon = self:FindWndTrans(item,"Icon")
	local ImgMask = self:FindWndTrans(item,"ImgMask")
	local TxtMask = self:FindWndTrans(item,"ImgMask/TxtMask")
	---@type StructPet
	local pet = gModelPet:GetPetById(itemdata.type)
	local heroId = pet:GetPetLinkHeroId(itemdata.link)
	CS.ShowObject(IconBg,false)
	CS.ShowObject(Icon,false)
	CS.ShowObject(ImgMask,false)
	if not string.isempty(heroId) then
		CS.ShowObject(Icon,true)
		local instanceId = item:GetInstanceID()
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
	else
		if pet.isActive and pet._star>= itemdata.rankNow then
			self:SetWndEasyImage(IconBg,"public_item_bg_add")
			CS.ShowObject(IconBg,true)
		else
			self:SetWndEasyImage(IconBg,"public_item_bg_1")
			CS.ShowObject(IconBg,true)
			CS.ShowObject(ImgMask,true)
			local str = itemdata.rankNow==0 and ccClientText(43729) or string.replace(ccClientText(43728),itemdata.rankNow)
			self:SetWndText(TxtMask,str)
		end
	end

	self:SetWndClick(item, function()
		if pet.isActive and pet._star>= itemdata.rankNow then
			GF.OpenWnd("UIPeLinkPop",{refId = itemdata.type})
		end
    end)
	self:SetWndLongClick(item,function()
		if not string.isempty(heroId) then
			GF.OpenWnd("UISagaSpreadNew",{ refId = heroId})
		end
	end)
end

function UISubPeLink:RefreshForeign()
	if self._isVie then
		self:InitTextLineWithLanguage(self.mTxtAttr,0)
	end
end

function UISubPeLink:OnUpdatePetList(item,uiList,pet,index)
	local heros = {}
	local starCfgs = gModelPet.petStarCfg[pet._petRefId]
	for _, value in pairs(starCfgs or {}) do
		if value.link>0 then table.insert(heros,value) end
	end

	if CS.IsWebGL() then
		table.sort(heros, function(a, b)
			return a.link < b.link
		end)
	end

	self:CreateUIScrollImpl(nil,uiList,heros,function(...) self:OnHeroCell(...) end)
end
function UISubPeLink:PetSort(petList)
	table.sort(petList,function (a,b)
		local aPet = gModelPet:GetPetById(a.refId)
		local bPet = gModelPet:GetPetById(b.refId)
		local aState = aPet:GetPetState()
		local bState = bPet:GetPetState()
		local aCfg = aPet:GetPetConfig()
		local bCfg = bPet:GetPetConfig()
		if aState ~= bState then
			return aState<bState
		else
			if aCfg.quality ~= bCfg.quality then
				return aCfg.quality > bCfg.quality
			else
				if aPet._level ~= bPet._level then
					return aPet._level<bPet._level
				else
					return aCfg.refId<bCfg.refId
				end
			end
		end
	end)
end
function UISubPeLink:OnDrawPetCell(list, item, itemdata, itempos)
	CS.ShowObject(item,true)
    local aniRootTrans = self:FindWndTrans(item, "AniRoot")
    local TxtName = self:FindWndTrans(aniRootTrans, "TxtName")
    local ImgNameBg = self:FindWndTrans(aniRootTrans, "ImgBg/ImgNameBg")
    local PetHero = self:FindWndTrans(aniRootTrans, "PetHero")
    local IconBg = self:FindWndTrans(aniRootTrans, "PetHero/IconBg")
    local Icon = self:FindWndTrans(aniRootTrans, "PetHero/Icon")
    local StarFull = self:FindWndTrans(aniRootTrans, "PetHero/StarFull")
    local ImgStar = self:FindWndTrans(aniRootTrans, "PetHero/ImgStar")
    local TxtLevel = self:FindWndTrans(aniRootTrans, "PetHero/TxtLevel")
    local ImgMask = self:FindWndTrans(aniRootTrans, "PetHero/ImgMask")
    local ListHero = self:FindWndTrans(aniRootTrans, "ListHero")
	---@type StructPet
	local pet = gModelPet:GetPetById(itemdata.refId)
	self:SetWndText(TxtName,ccLngText(itemdata.name))
	self:SetWndEasyImage(ImgNameBg, "public_cell_17_"..itemdata.quality, function()
		CS.ShowObject(ImgNameBg, true)
	end, true)
	local qualityCfg = GameTable.RarityRef[itemdata.quality]
	self:SetWndEasyImage(IconBg, qualityCfg.iconBg, function()
		CS.ShowObject(IconBg, true)
	end)
	self:SetWndEasyImage(Icon, itemdata.icon, function()
		CS.ShowObject(Icon, true)
	end)

	local starImg = gModelPet:GetStarPath(pet._star)
	local starCfg = pet:GetPetStarCfg()
	if starCfg.rankNext<=0 then
		self:SetWndEasyImage(StarFull,"hero_icon_star5")
		CS.ShowObject(StarFull,true and pet.isActive)
		CS.ShowObject(ImgStar,false)
	else
		CS.ShowObject(StarFull,false)
		CS.ShowObject(ImgStar,true and pet.isActive)
		self:SetWndEasyImage(ImgStar,starImg)
		local del = ImgStar.sizeDelta
		local num = (pet._star>0 and pet._star%5==0) and 5 or pet._star%5
		del.x = 40*num
		ImgStar.sizeDelta = del
	end
	self:SetWndText(TxtLevel,pet._level)
	CS.ShowObject(TxtLevel,pet.isActive)
	CS.ShowObject(ImgMask,not pet.isActive)
	self:OnUpdatePetList(item,ListHero,pet,itempos)

    self:SetWndClick(PetHero,function()
		if pet.isActive then
			GF.OpenWnd("UIPeView",{refId = itemdata.refId,playerId = gLGameLogin:GetPlayerId()})
		else
			gModelGeneral:OpenGetWayWnd({ itemId = itemdata.refId })
		end
	end)
end
------------------------------------------------------------------
return UISubPeLink