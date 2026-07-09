---
--- Created by LCM.
--- DateTime: 2024/3/17 15:14:37
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubReeContract:LChildWnd
local UISubReeContract = LxWndClass("UISubReeContract", LChildWnd)

---- 0：不显示颜色
---- 1：显示颜色
UISubReeContract.SHOW_COLOR_HERONAME_CELL = 1
UISubReeContract.SHOW_COLOR_HERONAME_CARD = 1
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubReeContract:UISubReeContract()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubReeContract:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubReeContract:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubReeContract:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:CreateWndEffect(self.mLinkEff,"fx_ui_xhyx_qiyuelianjie","fx_ui_xhyx_qiyuelianjie",100)
	self:CreateWndEffect(self.mUnLinkEff,"fx_ui_xhyx_qiyueduankai","fx_ui_xhyx_qiyueduankai",100)
	self:InitText()
	self:InitEmptyList()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitHeroList()
	self:RefreshView()
end

function UISubReeContract:OnDrawStarCell(list,item,itemdata,itempos)
	local StarTrans = self:FindWndTrans(item,"Star")
	self:SetWndEasyImage(StarTrans,itemdata.img)
end

function UISubReeContract:CreateSpine(trans,data,isLeft)
	local spineName = gModelHero:GetHeroPrefabNameByServerData(data)
	if not spineName then return end
	local refId = data.refId
	local curSpineKey,newSpineKey
	if isLeft then
		curSpineKey = self._curLeftSpineKey

		newSpineKey = refId .. "left"
	else
		curSpineKey = self._curRightSpineKey

		newSpineKey = refId .. "right"
	end
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
end

function UISubReeContract:RefreshShowSelHeroLeftDiv(data)
	if not data then return end
	local parentTrans = self.mLeftDiv
	self:RefreshCommonShowData(parentTrans,data,true)

	local QualityImgTrans = self:FindWndTrans(parentTrans,"QualityImg")
	local qualityIcon = self:GetQualityImg(data)
	if qualityIcon then
		self:SetWndEasyImage(QualityImgTrans,qualityIcon,function()
			CS.ShowObject(QualityImgTrans,true)
		end)
	else
		CS.ShowObject(QualityImgTrans,false)
	end
end

function UISubReeContract:RefreshCommonShowData(trans,data,isLeft)
	local RaceImgTrans = self:FindWndTrans(trans,"RaceImg")
	local SelDivTrans = self:FindWndTrans(trans,"SelDiv")
	local HeroNameTxtTrans = self:FindWndTrans(SelDivTrans,"HeroNameTxt")
	local HeroSpTrans = self:FindWndTrans(SelDivTrans,"HeroSp")
	local LvTxtTrans = self:FindWndTrans(SelDivTrans,"LvTxt")
	local StarListTrans = self:FindWndTrans(SelDivTrans,"StarList")
	local newStar = self:FindWndTrans(SelDivTrans, "NewStar")

	if data.star > 10 then
		self:SetTextTile(newStar, data.star - 10)
	else
		self:InitStarList(StarListTrans,data.star)
	end
	CS.ShowObject(StarListTrans, data.star <= 10)
	CS.ShowObject(newStar, data.star > 10)

	isLeft = isLeft and true or false

	local refId = data.refId
	local star = data.star

	local raceType = gModelHero:GetHeroType(refId)
	local raceImg = gModelHero:GetRaceImgByRefId(raceType)
	self:SetWndEasyImage(RaceImgTrans,raceImg,function()
		CS.ShowObject(RaceImgTrans,true)
	end)

	local heroName
	if UISubReeContract.SHOW_COLOR_HERONAME_CARD == 0 then
		heroName = gModelHero:GetHeroNameByRefId(refId,star)
	elseif UISubReeContract.SHOW_COLOR_HERONAME_CARD == 1 then
		-- heroName = gModelHero:GetColoredHeroName(refId,star)
		heroName = gModelHero:GetHeroNameByRefId(refId,star)
	end
	self:SetWndText(HeroNameTxtTrans,heroName)

	self:CreateSpine(HeroSpTrans,data,isLeft)

	local lvStr = string.replace(ccClientText(31211),data.level)
	self:SetWndText(LvTxtTrans,lvStr)
	CS.ShowObject(SelDivTrans,true)
end

function UISubReeContract:RefreshView()
	local isNotSel = self._curSelSpiritHeroId == nil
	if isNotSel then
		self:RefreshShowNoSelHeroDiv()
	else
		self:RefreshShowSelHeroDiv()
	end
	CS.ShowObject(self.mShowNoSelHeroDiv,isNotSel)
	CS.ShowObject(self.mShowSelHeroDiv,not isNotSel)
end

function UISubReeContract:InitText()
	self:SetWndText(self.mDescTxt,ccClientText(31205))
	self:SetWndText(self.mNoSelDesc,ccClientText(31205))
	self:SetWndButtonText(self.mStopLinkBtn,ccClientText(31210))
end

function UISubReeContract:RefreshCurSelSpiritHeroData()
	local curSelSpiritHeroId = self._curSelSpiritHeroId
	if not curSelSpiritHeroId then return end
	self._curSelSpiritHeroData = gModelHero:GetHeroServerDataById(curSelSpiritHeroId)
end

function UISubReeContract:OnSpiritHeroUnlinkReq()
	local curSelSpiritHeroId = self._curSelSpiritHeroId
	if not curSelSpiritHeroId then return end
	local curSelSpiritHeroData = self._curSelSpiritHeroData
	local curSelRelieveLinkHeroId = gModelSpiritHero:GetSpiritHeroLinkId(curSelSpiritHeroData)
	local curSelRelieveLinkHeroServerData = gModelHero:GetHeroServerDataById(curSelRelieveLinkHeroId)
	local sendMsgFunc = function()
		if not self:IsWndValid() then return end
		local mappingOtherHero = gModelResonance:GetMappingOtherId(curSelSpiritHeroId)
		if(mappingOtherHero)then
			local para = {
				refId = 10050,
				func = function()
					gModelSpiritHero:OnSpiritHeroUnlinkReq(curSelSpiritHeroId)
				end,
			}
			gModelGeneral:OpenUIOrdinTips(para)
			return
		end
		gModelSpiritHero:OnSpiritHeroUnlinkReq(curSelSpiritHeroId)
	end
	gModelSpiritHero:HandRelieveLinkPop(curSelSpiritHeroData,curSelRelieveLinkHeroServerData,sendMsgFunc,self:GetWndName())
end

function UISubReeContract:OnClickChangeBtnFunc()
	self:OnClickAddImgFunc()
end

function UISubReeContract:RefreshShowSelHeroRightDiv(selSpiritHeroData,spiritHeroData)
	local parentTrans = self.mRightDiv
	local SelDivTrans = self:FindWndTrans(parentTrans,"SelDiv")
	local NoSelDivTrans = self:FindWndTrans(parentTrans,"NoSelDiv")
	local changeBtnTrans = self:FindWndTrans(parentTrans,"changeBtn")
	local QualityImgTrans = self:FindWndTrans(parentTrans,"QualityImg")
	local isSelLinkHero = selSpiritHeroData ~= nil
	if isSelLinkHero then
		self:RefreshCommonShowData(parentTrans,selSpiritHeroData)
	else
		local RaceImgTrans = self:FindWndTrans(parentTrans,"RaceImg")
		CS.ShowObject(RaceImgTrans,false)
		CS.ShowObject(QualityImgTrans,false)
		self:RefreshNoSelHeroDiv(NoSelDivTrans,spiritHeroData)
	end
	CS.ShowObject(SelDivTrans,isSelLinkHero)
	CS.ShowObject(changeBtnTrans,isSelLinkHero)
	CS.ShowObject(NoSelDivTrans,not isSelLinkHero)

	local useData = selSpiritHeroData or spiritHeroData
	local qualityIcon = self:GetQualityImg(useData)
	--- cxl：没有选择时隐藏品质
	if isSelLinkHero and qualityIcon then
		self:SetWndEasyImage(QualityImgTrans,qualityIcon,function()
			CS.ShowObject(QualityImgTrans,true)
		end)
	else
		CS.ShowObject(QualityImgTrans,false)
	end

	self:SetWndClick(changeBtnTrans,function()
		self:OnClickChangeBtnFunc()
	end)
end

function UISubReeContract:RefreshNoSelHeroDiv(trans,data)
	local AddImgTrans = self:FindWndTrans(trans,"AddImg")
	local NoSelDescTrans = self:FindWndTrans(trans,"NoSelDesc")

	self:SetWndText(NoSelDescTrans,ccClientText(31212))

	self:SetWndClick(AddImgTrans,function()
		self:OnClickAddImgFunc()
	end)
end

function UISubReeContract:OnHeroChangeResp(pb)
	local spiritHeroList = self:GetHeroList()
	if not spiritHeroList then return end
	local spiritHeroIdList = {}
	for i,v in ipairs(spiritHeroList) do
		spiritHeroIdList[v.id] = true
	end
	local isNeedRefreshView = false
	local datas = pb.change
	for i,v in ipairs(datas) do
		if v.syncType == 2 then
			for idx,heroId in ipairs(v.ids) do
				if not isNeedRefreshView then
					isNeedRefreshView = spiritHeroIdList[heroId] ~= nil
				end
				if heroId == self._curSelSpiritHeroId then
					self._curSelSpiritHeroId = nil
				end
			end
		end
	end
	if not isNeedRefreshView then return end
	self:RefreshView()
	self:InitHeroList()
end

function UISubReeContract:InitHeroList(refreshList)
    local list = self:GetHeroList()
    local uiHeroList = self._uiHeroList
    if uiHeroList then
		if refreshList then
			uiHeroList:RefreshList(list)
		else
			uiHeroList:RefreshData(list)
		end
    else
        uiHeroList = self:GetUIScroll("uiHeroList")
        self._uiHeroList = uiHeroList
        uiHeroList:Create(self.mHeroList,list,function(...) self:OnDrawHeroCell(...) end,UIItemList.WRAP)
    end
	local isEmpty = #list < 1
	CS.ShowObject(self.mNoRecord2,isEmpty)
end

function UISubReeContract:OnClickHelpBtnFunc()
	GF.OpenWnd("UIBzTips",{refId = 142})
end

function UISubReeContract:OnClickAddImgFunc()
	GF.OpenWnd("UIContractSaga",{
		spiritHeroId = self._curSelSpiritHeroId
	})
end

function UISubReeContract:OnClickStopLinkBtnFunc()
	local curSelSpiritHeroData = self._curSelSpiritHeroData
	if not curSelSpiritHeroData then return end
	local isSpiritHeroToLink = gModelSpiritHero:CheckSpiritHeroIsHaveLink(curSelSpiritHeroData)
	if isSpiritHeroToLink then
		self:OnSpiritHeroUnlinkReq()
	end
end

function UISubReeContract:InitMsg()

	self:WndNetMsgRecv(LProtoIds.SpiritHeroLinkResp,function(pb) self:OnSpiritHeroLinkResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.SpiritHeroUnlinkResp,function(pb) self:OnSpiritHeroUnlinkResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.HeroChangeResp,function(pb) self:OnHeroChangeResp(pb) end)


	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UISubReeContract:OnSpiritHeroLinkResp()
	self:RefreshCurSelSpiritHeroData()
	self:RefreshView()
	self:InitHeroList()
end

function UISubReeContract:OnDrawHeroCell(list,item,itemdata,itempos)
    local CommonUITrans = self:FindWndTrans(item,"CommonUI")
    local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")
    local NameTrans = self:FindWndTrans(item,"Name")
	local isLink = CS.FindTrans(item, "IsLink")
	local isSelect = CS.FindTrans(item, "IsSelect")

	local id = itemdata.id
	local refId = itemdata.refId
	local star = itemdata.star

	local isSel = self._curSelSpiritHeroId and self._curSelSpiritHeroId == id or false

	local instanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(IconTrans)
	local herodata = {
		trans = IconTrans,
		id = id,
		refId = refId,
		star = star,
		level = itemdata.level,
		skin = itemdata.skin,
		isResonance = itemdata.resonance,
		-- selected = isSel
	}
	baseClass:SetHeroDataSet(herodata)
	-- baseClass:SetSignStatus(gModelSpiritHero:CheckSpiritHeroIsHaveLink(itemdata))
	baseClass:DoApply()

	self:SetTextTile(isLink, ccClientText(31224))
	CS.ShowObject(isLink, gModelSpiritHero:CheckSpiritHeroIsHaveLink(itemdata))
	CS.ShowObject(isSelect, isSel)

	self:SetWndClick(IconTrans,function()
		self:OnClickHeroFunc(itemdata,itempos)
	end)

	local heroName
	if UISubReeContract.SHOW_COLOR_HERONAME_CELL == 0 then
		heroName = gModelHero:GetHeroNameById(id)
	elseif UISubReeContract.SHOW_COLOR_HERONAME_CELL == 1 then
		heroName = gModelHero:GetColoredHeroName(refId,star)
	end
	self:SetWndText(NameTrans,heroName)
end

function UISubReeContract:OnSpiritHeroUnlinkResp()
	self:RefreshCurSelSpiritHeroData()
	self:RefreshView()
	self:InitHeroList()
end

function UISubReeContract:GetStarList(star)
	local list = {}
	local img,temp,index = LUtil.GetHeroStarImg(star)
	for i = 1,temp do
		table.insert(list,{
			img = img,
		})
	end
	return list
end

function UISubReeContract:InitData()
	self._curSelSpiritHeroId = nil
	self._curSelSpiritHeroData = nil
	self._curSelHeroIndex = nil
end

function UISubReeContract:RefreshShowSelHeroDiv()
	local curSelSpiritHeroData = self._curSelSpiritHeroData
	if not curSelSpiritHeroData then return end
	self:RefreshShowSelHeroLeftDiv(curSelSpiritHeroData)

	local spiritServerData
	local haveLink = gModelSpiritHero:CheckSpiritHeroIsHaveLink(curSelSpiritHeroData)
	if haveLink then
		local spiritLinkId = gModelSpiritHero:GetSpiritHeroLinkId(curSelSpiritHeroData)
		spiritServerData = gModelHero:GetHeroServerDataById(spiritLinkId)
	end
	self:RefreshShowSelHeroRightDiv(spiritServerData,curSelSpiritHeroData)
	CS.ShowObject(self.mStopLinkBtn,haveLink)
	CS.ShowObject(self.mLinkEff,haveLink)
	if haveLink then
		CS.ShowObject(self.mUnLinkEff,false)
	end
end

function UISubReeContract:InitStarList(trans,star)
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
------------------------- List -------------------------


function UISubReeContract:GetHeroList()
	return gModelSpiritHero:GetSpiritHeroList()
end

function UISubReeContract:GetQualityImg(data)
	local refId = data.refId
	local ref = gModelHero:GetHeroRef(refId)
	if not ref then return end
	return ref.qualityIcon
end

function UISubReeContract:RefreshShowNoSelHeroDiv()
end

function UISubReeContract:OnClickHeroFunc(itemdata,itempos)
	local id = itemdata.id
	if self._curSelSpiritHeroId == id then return end

	local oldHeroIndex = self._curSelHeroIndex
	self._curSelSpiritHeroId = id
	self._curSelSpiritHeroData = itemdata
	self._curSelHeroIndex = itempos

--[[	local uiHeroList = self._uiHeroList
	if uiHeroList then
		if oldHeroIndex then
			uiHeroList:DrawItemByIndex(oldHeroIndex)
		end
		uiHeroList:DrawItemByIndex(itempos)
	end]]

	self:InitHeroList()
	self:RefreshView()
end

function UISubReeContract:InitEvent()
    self:SetWndClick(self.mStopLinkBtn,function() self:OnClickStopLinkBtnFunc() end)
    self:SetWndClick(self.mHelpBtn,function() self:OnClickHelpBtnFunc() end)

	self:WndEventRecv("OnSpiritHeroUnlinkResp", function()
		CS.ShowObject(self.mUnLinkEff, false)
		CS.ShowObject(self.mUnLinkEff, true)
	end)
end

function UISubReeContract:InitEmptyList()
	local data = {
		refId = 10005,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

------------------------- List -------------------------

------------------------------------------------------------------
return UISubReeContract



