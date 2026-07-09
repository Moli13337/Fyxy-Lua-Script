---
--- Created by LCM.
--- DateTime: 2024/3/17 20:43:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIContractSaga:LWnd
local UIContractSaga = LxWndClass("UIContractSaga", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIContractSaga:UIContractSaga()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIContractSaga:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIContractSaga:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIContractSaga:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEmptyList()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitHeroRaceList()
	self:InitHeroList()
end

function UIContractSaga:InitData()
	local spiritHeroId = self:GetWndArg("spiritHeroId")
	if spiritHeroId then
		self._spiritHeroData = gModelHero:GetHeroServerDataById(spiritHeroId)
	end
	self._spiritHeroId = spiritHeroId

	self._raceType = 0
	self._selHeroId = nil
	self._selHeroServerData = nil
end

function UIContractSaga:InitMsg()
	 self:WndNetMsgRecv(LProtoIds.SpiritHeroLinkResp,function(pb) self:OnSpiritHeroLinkResp(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIContractSaga:InitHeroRaceList()
	local data = {
		wndClass = self,
		listTrans = self.mHeroRaceList,
		ignoreRaceList = {
			[ModelSpiritHero.SPIRITHERO_RACE] = true,
		},
		showListBg = true,
		showType = UIHeroRaceList.TYPE_SHOWBG,
		callbackFunc = function(raceType)
			if not self:IsWndValid() then return end
			if raceType == self._raceType then return end
			self._raceType = raceType
			self:InitHeroList()
		end,
		checkSelFunc = function(raceType)
			if not self:IsWndValid() then return end
			return self._raceType == raceType
		end
	}
	self:GetUIHeroRaceList(data)
end

function UIContractSaga:InitHeroList(refreshData)
    local list = self:GetHeroList()
    local uiHeroList = self._uiHeroList
    if uiHeroList then
		if refreshData then
			uiHeroList:RefreshData(list)
		else
			uiHeroList:RefreshList(list)
		end
    else
        uiHeroList = self:GetUIScroll("uiHeroList")
        self._uiHeroList = uiHeroList
        uiHeroList:Create(self.mHeroList,list,function(...) self:OnDrawHeroCell(...) end,UIItemList.WRAP)
    end
	local isEmpty = #list < 1
	CS.ShowObject(self.mNoRecord2,isEmpty)
end
------------------------- List -------------------------
function UIContractSaga:GetHeroList()
	local list = gModelSpiritHero:GetCanSpiritHeroList(self._raceType)
	--local canSpiritHeroList = gModelSpiritHero:GetCanSpiritHeroList(self._raceType)
	return list
end

function UIContractSaga:InitText()
	self:SetWndText(self.mLblBiaoti,ccClientText(31215))
	self:SetWndText(self.mDescTxt,ccClientText(31213))
	self:SetWndButtonText(self.mGoToSpiritBtn,ccClientText(31214))
end

function UIContractSaga:InitEmptyList()
	local data = {
		refId = 10008,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIContractSaga:OnDrawHeroCell(list,item,itemdata,itempos)
    local CommonUITrans = self:FindWndTrans(item,"CommonUI")
    local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")
    local HeroNameTrans = self:FindWndTrans(item,"HeroName")
	local isLink = CS.FindTrans(item, "IsLink")
	local isSelect = CS.FindTrans(item, "IsSelect")

	local id = itemdata.id
	local refId = itemdata.refId
	local star = itemdata.star

	local isSel = self._selHeroId and self._selHeroId == id or false

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
		endTime = itemdata.endTime,
		isTry = itemdata.isTry,
		-- selected = isSel
	}
	baseClass:SetHeroDataSet(herodata)
	-- baseClass:OnlySetLinkStatus(gModelSpiritHero:CheckHeroIsHaveLink(itemdata))
	baseClass:DoApply()

	self:SetTextTile(isLink, ccClientText(31225))
	CS.ShowObject(isLink, gModelSpiritHero:CheckHeroIsHaveLink(itemdata))
	CS.ShowObject(isSelect, isSel)

	local heroName = gModelHero:GetHeroNameByRefId(refId,star)
	self:SetWndText(HeroNameTrans,heroName)

	self:SetWndClick(IconTrans,function()
		self:OnClickHeroIconFunc(itemdata)
	end)
end

function UIContractSaga:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mGoToSpiritBtn,function() self:OnClickGoToSpiritBtnFunc() end)
end

function UIContractSaga:OnClickGoToSpiritBtnFunc()
	if not self._spiritHeroId then return end
	local spiritHeroData = self._spiritHeroData
	if not spiritHeroData then return end
	if not self._selHeroId then
		GF.ShowMessage(ccClientText(31226))
		return
	end
	gModelSpiritHero:OnSpiritHeroViewReq(self._spiritHeroId,self._selHeroId)
--[[	local sendMsgFunc = function()
		if not self:IsWndValid() then return end
		gModelSpiritHero:OnSpiritHeroViewReq(self._spiritHeroId,self._selHeroId)
	end
	local selHeroServerData = self._selHeroServerData
	if not selHeroServerData then
		return
	end
	local isHaveLink = gModelSpiritHero:CheckSpiritHeroIsHaveLink(spiritHeroData)
	if isHaveLink then
		local relieveLinkHeroId = gModelSpiritHero:GetSpiritHeroLinkId(spiritHeroData)
		local relieveLinkHeroServerData = gModelHero:GetHeroServerDataById(relieveLinkHeroId)
		gModelSpiritHero:RelieveLinkPop(spiritHeroData,relieveLinkHeroServerData,sendMsgFunc,self:GetWndName())
	else
		sendMsgFunc()
	end]]
end

function UIContractSaga:OnClickHeroIconFunc(itemdata)
	local id = itemdata.id
	if self._selHeroId == id then return end
	local spiritHeroData = self._spiritHeroData
	if spiritHeroData then
		local spiritLinkId = gModelSpiritHero:GetSpiritHeroLinkId(spiritHeroData)
		if spiritLinkId and spiritLinkId == id then
			if LOG_INFO_ENABLED then
				printInfoNR("此英雄为当前虚空英雄所连接的英雄，文字id = 31234")
			end
			GF.ShowMessage(ccClientText(31234))
			return
		end
	end
	self._selHeroId = id
	self._selHeroServerData = itemdata
	self:InitHeroList(true)
end

function UIContractSaga:OnSpiritHeroLinkResp()
	self:WndClose()
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIContractSaga



