---
--- Created by Administrator.
--- DateTime: 2026/4/15 14:13:45
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActivityLosslessConvertPop:LWnd
local UIActivityLosslessConvertPop = LxClass("UIActivityLosslessConvertPop", LWnd)
------------------------------------------------------------------
UIActivityLosslessConvertPop.LEFT_HERO_DIV = 1
UIActivityLosslessConvertPop.RIGHT_HERO_DIV = 2
--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActivityLosslessConvertPop:UIActivityLosslessConvertPop()
	self._selectHeroId = nil
	self._selectHeroData = nil
	self._selectHeroIndex = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActivityLosslessConvertPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActivityLosslessConvertPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActivityLosslessConvertPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	local _cfg = self:GetWndArg("cfg")
	self._cfg = _cfg
	self._sid = self:GetWndArg("sid")
	self._pageId = self:GetWndArg("pageId")
	self.isClickConfirm = false
	local heroIds = _cfg.heroId
	local maxConvertStar = _cfg.heroStar
	self._maxConvertStar = maxConvertStar
	self:InitMessageEvent()
	self:InitBtnEvent()
	self:InitHeroMap(heroIds)
	self:InitStaticTxt()
	self:InitEmptyList()
	self:RefreshView()
end

--region initialize the message event
function UIActivityLosslessConvertPop:InitMessageEvent()
	self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp, function()
		self:OnActSpecialOpResp()--转换返回
	end)
	self:WndNetMsgRecv(LProtoIds.HeroRemoveFormationResp,function() self:RefreshView() end)
	self:WndNetMsgRecv(LProtoIds.HeroLockResp,function() self:RefreshView() end)
end

function UIActivityLosslessConvertPop:OnActSpecialOpResp()
	self.isClickConfirm = false
	GF.ShowMessage(ccClientText(14433))
	self:RefreshView()
end
--endregion
--region initialize the click event of button
function UIActivityLosslessConvertPop:InitBtnEvent()
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mConvertBtn,function()
		self:OnClickConvertBtn()--转换按钮
	end)
	self:SetWndClick(self.mCancelBtn,function()
		self:OnClickCancelBtn() --取消转换按钮
	end)
	self:SetWndClick(self.mConfirmBtn,function()
		self:OnClickConfirmBtn() --储存/确定转换按钮
	end)
end
function UIActivityLosslessConvertPop:OnClickConvertBtn()
	local _selectHeroData = self._selectHeroData
	local seleHeroId = _selectHeroData:GetId()
	local lock, isCombat = _selectHeroData:GetLockStatus(), _selectHeroData:GetCombatStatus()
	if isCombat == 1 then
		local noOpenSelWndList = {}
		local wndInst = GF.FindFirstWndByName("WndHeroSpirit")
		if wndInst then
			noOpenSelWndList["WndHeroSelect"] = "WndHeroSelect"
		end
		gModelFormation:OnHeroRemoveFormationReq(seleHeroId, nil, LGameUI.UI_SORTLAYER_UIBOTTOM, true, noOpenSelWndList)
	elseif lock == 1 then
		gModelHeroSpirit:HeroUnLockOpt({ heroId = seleHeroId })
	else
		GF.ShowMessage(ccClientText(14431))
		self:ShowConvertBtn()
	end
end
function UIActivityLosslessConvertPop:OnClickCancelBtn()
	self:ShowConvertBtn(true)
end
function UIActivityLosslessConvertPop:OnClickConfirmBtn()
	if(not self._selectHeroId)then
		return
	end

	self.isClickConfirm = true
	--//活动153 英雄转换 args格式说明 id|heroRefId; 说明[id=英雄唯一id,heroRefId=转换的英雄RefId]
	local refId = self._convertData:GetRefId()
	local str = string.replace("#a1#|#a2#", self._selectHeroId, refId)
	gModelActivity:OnActivitySpecialOpReq(self._sid,0,0,0,str,ModelActivity.LOSSLESS_CONVERT_OPS)
end
function UIActivityLosslessConvertPop:ShowConvertBtn(b)
	if(self.isClickConfirm)then
		return
	end
	CS.ShowObject(self.mConvertBtn,b)
	CS.ShowObject(self.mConfirmBtnGroup,not b)
	CS.ShowObject(self.mRightDiv,not b)
	CS.ShowObject(self.mRightHide,b)
end
--endregion

--region initialize the convertible hero table
function UIActivityLosslessConvertPop:InitHeroMap(heroIds)
	local groupStr = string.split(heroIds,",")
	local dShowHero = {}
	for i, v in ipairs(groupStr) do
		local heroes = string.split(v,"=")
		if(not dShowHero[heroes[1]])then
			for j = 1, 2 do
				local j2 = j == 1 and 2 or 1
				dShowHero[tonumber(heroes[j])] = tonumber(heroes[j2])
			end
		end
	end
	self._dShowHero = dShowHero
end
--endregion
--region initialize static text
function UIActivityLosslessConvertPop:InitStaticTxt()
	if(self._cfg.heroConvertTxt1)then
		self:SetWndText(self.mTitleTxt,ccLngText(self._cfg.heroConvertTxt1))--冰火转换
		self:SetWndText(self.mNoSelDesc,ccLngText(self._cfg.heroConvertTxt2))--活动期间可进行无损转换
	end
	self:SetWndButtonText(self.mConvertBtn,ccClientText(14403))--转换
	self:SetWndButtonText(self.mCancelBtn,ccClientText(29545))--取消
	self:SetWndButtonText(self.mConfirmBtn,ccClientText(20820))--保存
end
--endregion
--region initialize an empty list
function UIActivityLosslessConvertPop:InitEmptyList()
	local data = {
		refId = 10005,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end
--endregion
--region refresh the ui view
function UIActivityLosslessConvertPop:RefreshView()
	self:RefreshHeroList()
	self:SetSelHeroDiv()
end
--endregion
--region set up the hero selection group
function UIActivityLosslessConvertPop:SetSelHeroDiv()
	local selectHeroId = self._selectHeroId
	local isSele = selectHeroId and selectHeroId ~= 0
	--CS.ShowObject(self.mShowSelHeroDiv, isSele)
	CS.ShowObject(self.mConvertBtnGroup, isSele)
	CS.ShowObject(self.mLeftHide, not isSele)
	CS.ShowObject(self.mLeftDiv, isSele)
	--CS.ShowObject(self.mShowNoSelHeroDiv,not isSele)
	if(not isSele)then
		return
	end
	self:RefreshShowSelHeroDiv()
end
function UIActivityLosslessConvertPop:RefreshShowSelHeroDiv()
	self:ShowConvertBtn(true)

	local _selectHeroData = self._selectHeroData
	if not _selectHeroData then return end
	self:SetShowHeroDiv(_selectHeroData,1)

	local convertId = self._dShowHero[_selectHeroData:GetRefId()]

	local convertData = StructHero:New()
	convertData:CreateByPb(_selectHeroData:GetPb())
	convertData._refId = convertId
	self._convertData = convertData
	self:SetShowHeroDiv(convertData,2)
end
---@param heroData StructHero
---@param type number :1.left,2.rifht
function UIActivityLosslessConvertPop:SetShowHeroDiv(heroData,type)
	if not heroData then return end
	local isLeft = type == UIActivityLosslessConvertPop.LEFT_HERO_DIV
	local parentTrans = isLeft and self.mLeftDiv or self.mRightDiv
	local raceImgTrans = self:FindWndTrans(parentTrans,"RaceImg")
	local heroDivTrans = self:FindWndTrans(parentTrans,"HeroDiv")
	local HeroNameTxtTrans = self:FindWndTrans(heroDivTrans,"HeroNameTxt")
	local HeroSpTrans = self:FindWndTrans(heroDivTrans,"HeroSp")
	local LvTxtTrans = self:FindWndTrans(heroDivTrans,"LvTxt")
	local StarListTrans = self:FindWndTrans(heroDivTrans,"StarList")
	local newStar = self:FindWndTrans(heroDivTrans, "NewStar")
	local qualityImgTrans = self:FindWndTrans(parentTrans,"QualityImg")

	local star = heroData:GetStar()
	local refId = heroData:GetRefId()
	local level = heroData:GetLv()

	local maxConvertStar = self._maxConvertStar
	if star > maxConvertStar then
		self:SetTextTile(newStar, star - maxConvertStar)
	else
		self:InitStarList(StarListTrans, star)
	end
	CS.ShowObject(StarListTrans, star <= maxConvertStar)
	CS.ShowObject(newStar, star > maxConvertStar)

	local raceType = gModelHero:GetHeroType(refId)
	local raceImg = gModelHero:GetRaceImgByRefId(raceType)
	self:SetWndEasyImage(raceImgTrans,raceImg,function()
		CS.ShowObject(raceImgTrans,true)
	end)

	local heroName = gModelHero:GetHeroNameByRefId(refId,star)
	self:SetWndText(HeroNameTxtTrans,heroName)
	self:CreateSpine(HeroSpTrans,heroData,isLeft)
	local lvStr = string.replace(ccClientText(31211),level)
	self:SetWndText(LvTxtTrans,lvStr)

	local qualityIcon = self:GetQualityImg(heroData)
	if qualityIcon then
		self:SetWndEasyImage(qualityImgTrans,qualityIcon,function()
			CS.ShowObject(qualityImgTrans,true)
		end)
	else
		CS.ShowObject(qualityImgTrans,false)
	end
end
function UIActivityLosslessConvertPop:CreateSpine(trans,data,isLeft)
	--local spineName = gModelHero:GetHeroPrefabNameByServerData(data)
	local id = data:GetId()
	local refId = data:GetRefId()
	local star = data:GetStar()
	local spineName, effRef
	local curSpineKey,newSpineKey
	if isLeft then
		effRef = gModelHero:GetHeroEffectRefById(id)
		curSpineKey = self._curLeftSpineKey
		newSpineKey = refId .. "left"
	else
		local effectId = gModelHero:GetHeroEffectId(refId, nil, star)
		effRef = gModelHero:GetShowEffectById(effectId)
		curSpineKey = self._curRightSpineKey
		newSpineKey = refId .. "right"
	end
	spineName = effRef.prefabName
	if not spineName then return end
	if curSpineKey and curSpineKey ~= newSpineKey then
		local curPb = self:FindWndSpineByKey(curSpineKey)
		if curPb then
			CS.ShowObject(curPb:GetDisplayTrans(),false)
		end
	end
	local newSpine = self:FindWndSpineByKey(newSpineKey)
	if newSpine then
		CS.ShowObject(newSpine:GetDisplayTrans(),true)
	else
		self:CreateWndSpine(trans,spineName,newSpineKey,false,function(spine)
			spine:PlayAnimation(0,"idle",true)
			spine:SetScale(1.3)
		end)
	end
	if isLeft then
		self._curLeftSpineKey = newSpineKey
	else
		self._curRightSpineKey = newSpineKey
	end
	self:SetWndImageGray()
end

function UIActivityLosslessConvertPop:GetStarList(star)
	local list = {}
	local img,temp,index = LUtil.GetHeroStarImg(star)
	for i = 1,temp do
		table.insert(list,{
			img = img,
		})
	end
	return list
end
function UIActivityLosslessConvertPop:InitStarList(trans,star)
	local list = self:GetStarList(star)
	local key = trans:GetInstanceID()
	local uiStarTrans = self:FindUIScroll(key)
	if uiStarTrans then
		uiStarTrans:RefreshList(list)
	else
		uiStarTrans = self:GetUIScroll(key)
		uiStarTrans:Create(trans,list,function(...) self:OnDrawStarCell(...) end)
	end
end
function UIActivityLosslessConvertPop:OnDrawStarCell(list,item,itemdata,itempos)
	local StarTrans = self:FindWndTrans(item,"Star")
	self:SetWndEasyImage(StarTrans,itemdata.img)
end
function UIActivityLosslessConvertPop:GetQualityImg(data)
	local refId = data.refId
	local ref = gModelHero:GetHeroRef(refId)
	if not ref then return end
	return ref.qualityIcon
end
--endregion
--region initialize the hero list
function UIActivityLosslessConvertPop:RefreshHeroList()
	local list = self:GetHeroList()
	if(list and table.keysize(list)>0 and not self._selectHeroId)then
		for i, v in ipairs(list) do
			local lock, isCombat = v:GetLockStatus(), v:GetCombatStatus()
			if(lock~=1 and isCombat~=1)then
				self._selectHeroId = list[i]:GetId()
				break
			end
		end
	end
	local uiHeroList = self._uiHeroList
	if uiHeroList then
		uiHeroList:RefreshData(list)
	else
		uiHeroList = self:GetUIScroll("uiHeroList")
		self._uiHeroList = uiHeroList
		uiHeroList:Create(self.mHeroList,list,function(...) self:OnDrawHeroCell(...) end,UIItemList.WRAP)
	end

	local isEmpty = #list < 1
	CS.ShowObject(self.mHeroList, not isEmpty)
	CS.ShowObject(self.mNoRecord2, isEmpty)
end
--region
function UIActivityLosslessConvertPop:OnDrawHeroCell(list,item,itemdata,itempos)
	local CommonUITrans = self:FindWndTrans(item,"CommonUI")
	local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")

	local isSelect = CS.FindTrans(item, "IsSelect")
	local lockImg = CS.FindTrans(item, "LockImg")

	local id = itemdata:GetId()
	local refId = itemdata:GetRefId()
	local star = itemdata:GetStar()
	local level = itemdata:GetLv()
	local skin = itemdata:GetSkin()

	local isSel = self._selectHeroId and self._selectHeroId == id or false

	local instanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(IconTrans)
	local heroData = {
		trans = IconTrans,
		id = id,
		refId = refId,
		star = star,
		level = level,
		skin = skin,
		-- selected = isSel
	}
	if(isSel)then
		self._selectHeroId = id
		self._selectHeroData = itemdata
		self._selectHeroIndex = itempos
	end
	local lock, isCombat = itemdata:GetLockStatus(), itemdata:GetCombatStatus()
	local imgPath
	local bShowLock = isCombat == 1 or lock == 1
	if(isCombat == 1)then
		imgPath = "heropalace_icon_1"
	elseif(lock == 1)then
		imgPath = "public_lock_1"
	end

	baseClass:SetHeroDataSet(heroData)
	baseClass:DoApply()
	baseClass:ShowMaskOnly(bShowLock)
	if(imgPath)then
		self:SetWndEasyImage(lockImg,imgPath)
	end
	CS.ShowObject(lockImg, imgPath)
	CS.ShowObject(isSelect, isSel)

	self:SetWndClick(IconTrans,function()
		if(star<=self._maxConvertStar)then
			self:OnClickHeroFunc(itemdata,itempos)
		else
			GF.ShowMessage(string.replace(ccClientText(14463),self._maxConvertStar))-- 仅支持10星一下女仆进行无损转换
		end
	end)

	--local heroName = gModelHero:GetHeroNameById(id)
end
function UIActivityLosslessConvertPop:OnClickHeroFunc(itemdata,itempos)
	local id = itemdata:GetId()
	local lock, isCombat = itemdata:GetLockStatus(), itemdata:GetCombatStatus()

	if isCombat == 1 then
		local noOpenSelWndList = {}
		local wndInst = GF.FindFirstWndByName("WndHeroSpirit")
		if wndInst then
			noOpenSelWndList["WndHeroSelect"] = "WndHeroSelect"
		end
		gModelFormation:OnHeroRemoveFormationReq(id, nil, LGameUI.UI_SORTLAYER_UIBOTTOM, true, noOpenSelWndList)
		return
	elseif lock == 1 then
		gModelHeroSpirit:HeroUnLockOpt({ heroId = id })
		return
	end
	local oldHeroIndex = self._selectHeroId
	if oldHeroIndex == id then return end

	self._selectHeroId = id
	self._selectHeroData = itemdata
	self._selectHeroIndex = itempos

	self:RefreshView()
end
function UIActivityLosslessConvertPop:GetHeroList()
	local heroList = gModelHero:GetHeroList()
	local resultList = {}
	for i, v in pairs(heroList) do
		local refId = tonumber(v:GetRefId())
		if(self._dShowHero[refId])then
			table.insert(resultList,v)
		end
	end
	table.sort(resultList,function(a,b)
		return a:GetRefId() > b:GetRefId()
	end)
	return resultList
end
--endregion

------------------------------------------------------------------
return UIActivityLosslessConvertPop