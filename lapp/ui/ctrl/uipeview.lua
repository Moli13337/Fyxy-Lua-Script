---
--- Created by Administrator.
--- DateTime: 2024/6/13 15:22:44
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeView:LWnd
local UIPeView = LxWndClass("UIPeView", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeView:UIPeView()
	self._commonUIList = {}
	self.heroList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeView:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeView:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeView:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self.refId = self:GetWndArg("refId")
	local pet = self:GetWndArg("pet")
	self.playerId = self:GetWndArg("playerId")
	local showBtn = self:GetWndArg("showBtn")--是否显示卸载、替换按钮
	self.fromHeroId = self:GetWndArg("heroId")--打开英雄
	self.isPreview = self:GetWndArg("isPreview")--预览-满星满级
	if pet then 
		self.petInfo = pet 
	else
		self.petInfo = gModelPet:GetPetById(self.refId) or StructPet:New(GameTable.MagicPetRef[self.refId])
	end
	if self.isPreview then
		self.petInfo = nil
		self.petInfo = StructPet:New(GameTable.MagicPetRef[self.refId])
		self.petInfo._level = self.petInfo.maxLevel
		self.petInfo._star = self.petInfo:GetMaxStar()
		self.petInfo.isActive = true
	end
	CS.ShowObject(self.mBtnUn,showBtn)
	CS.ShowObject(self.mBtnReplace,showBtn)
	self:AddEventMsg()
	self:InitPanel()
	self:OnUpdateStar()
	self:OnSkillDesc()
	if self.isPreview then self:OnUpateLinkList() end
	if self.playerId and not self.isPreview then gModelPet:OnPetCheckReq(self.playerId,self.refId) end
end
function UIPeView:InitPanel()
	local petCfg = GameTable.MagicPetRef[self.refId]
	local pet = self.petInfo
	self:SetWndText(self.mTxtName,petCfg and ccLngText(petCfg.name) or "")
	self:SetWndText(self.mTxtLevel,"Lv."..pet._level)
	self:SetWndText(self.mTxtTitleAttr,ccClientText(43715))
	self:SetWndText(self.mTxtTitleLink,ccClientText(43759))
	self:SetWndText(self.mLblBiaoti,ccClientText(43752))
	self:SetWndButtonText(self.mBtnUn,ccClientText(43778))
	self:SetWndButtonText(self.mBtnReplace,ccClientText(43779))
	local qualityIcon = GameTable.RarityRef[petCfg.quality]

    self:SetWndEasyImage(self.mImgType, qualityIcon.qualityText)
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
end

function UIPeView:AddEventMsg()
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mImgMask,function() self:WndClose() end)
	self:SetWndClick(self.mImgAttrHelp,function() GF.OpenWnd("UIPeLinkJN",{refId = self.refId}) end)
	self:SetWndClick(self.mBtnUn,function()
		self:WndClose()
		self:OnUnEquip() end)
	self:SetWndClick(self.mBtnReplace,function()
		self:WndClose()
		GF.OpenWnd("UISagaLinkPe", { heroId = self.fromHeroId }) end)
	self:WndNetMsgRecv(LProtoIds.PetCheckResp, function(pb)
		self.heroList = {}
        for _1, value in ipairs(pb.hero) do
			local hero = StructHero:New()
        	hero:CreateByPb(value)
			table.insert(self.heroList,hero)
		end
		self:OnUpateLinkList()
    end)
end

function UIPeView:OnUpdateStar()
	gModelPet:SetStar(self.mImgStar,self.refId,self.petInfo._star,function(starPath)
		self:SetWndEasyImage(self.mImgStar, starPath)
	end)

end

function UIPeView:OnLinkHeroCell(list,item,itemdata,index)
	local IconBg = self:FindWndTrans(item,"CommonUI/IconBg")
	local Icon = self:FindWndTrans(item,"CommonUI/Icon")
	local ImgMask = self:FindWndTrans(item,"ImgMask")
	local TxtMask = self:FindWndTrans(item,"ImgMask/TxtMask")
	---@type StructPet
	local pet = self.petInfo
	local heroInfo = self.heroList[index]
	-- if self.isMe then
	-- 	local heroId = pet:GetPetLinkHeroId(itemdata.link)
	-- 	heroInfo = gModelHero:GetHeroById(heroId)
	-- end
	CS.ShowObject(IconBg,false)
	CS.ShowObject(Icon,false)
	CS.ShowObject(ImgMask,false)
	if heroInfo then --链接英雄
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
		uiIconClass:SetHeroDataSet(heroInfo:GetServerData())
		uiIconClass:SetNoShowLv(false)
		uiIconClass:SetShowGouImg(false)
		uiIconClass:DoApply()
	else
		if pet.isActive and pet._star>= itemdata.rankNow then--可连接
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
		if heroInfo  then
			local heroData = heroInfo:GetServerData()
			gModelHero:ReqShowHeroTip(self.playerId,heroData)
		end
    end)
end

function UIPeView:OnUnEquip()
	local heroIds = {}
	for _, hero in ipairs(self.heroList) do
		if hero._id ~= self.fromHeroId then
			table.insert(heroIds,hero._id)
		end
	end
	gModelPet:OnPetLinkReq(self.refId,heroIds)
end
function UIPeView:OnUpateLinkList()
	local heros = {}
	self.selectData = heros
	local starCfgs = gModelPet.petStarCfg[self.refId]
	local index = 0
	for _, value in pairs(starCfgs or {}) do
		if value.link>0 then
			index = index+1
			table.insert(heros,value)
		end
	end
	self:CreateUIScrollImpl(nil,self.mListHero,self.selectData,function(...) self:OnLinkHeroCell(...) end)
end

function UIPeView:OnSkillDesc()
	---@type StructPet
	local pet = self.petInfo
	local petStarCfg = pet:GetPetStarCfg()
	local curSkillId = petStarCfg.skillId
	local skillStar = pet._star
	while(curSkillId <=0 and petStarCfg.rankNext>0) do
		petStarCfg = GameTable.MagicPetStarRef[petStarCfg.rankNext]
		curSkillId = petStarCfg.skillId
		skillStar = petStarCfg.rankNow
	end
	local skillCfg = GameTable.SnakeSkillRef[curSkillId]
	if skillCfg then
		local desc = "<color=#d2730f>Lv."..petStarCfg.skillILv.."</color>："..ccLngText(skillCfg.description)
		self:SetWndText(self.mTxtLinkDesc,desc)
		self:SetWndText(self.mTxtLinkCond,string.replace(ccClientText(43713),skillStar))
	end
	CS.ShowObject(self.mTxtLinkCond,pet._star~=skillStar or not pet.isActive)

end

------------------------------------------------------------------
return UIPeView