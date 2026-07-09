---
--- Created by Administrator.
--- DateTime: 2023/10/20 11:30:55
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActSagaSel:LWnd
local UIActSagaSel = LxWndClass("UIActSagaSel", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActSagaSel:UIActSagaSel()
	---@type table<number,CommonIcon>
	self._heroIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActSagaSel:OnWndClose()
	self:ClearCommonIconList(self._heroIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActSagaSel:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActSagaSel:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndButtonText(self.mCancelBtn,ccClientText(10101))
	self:SetWndButtonText(self.mEnterBtn,ccClientText(10102))
	self:InitEvent()
	self:InitMsg()
	self:InitData()

	if self._isPre then
		self:SetWndText(self.mLblBiaoti,ccClientText(11649))
	else
		self:SetWndText(self.mLblBiaoti,ccClientText(11635))
	end
	self:SetWndText(self.mLongDescTxt,ccClientText(13266))

	local showBtn = not self._isPre
	CS.ShowObject(self.mCancelBtn,showBtn)
	CS.ShowObject(self.mEnterBtn,showBtn)
	self:InitHeroList()
	if self._sid then
		local pbData = gModelActivity:GetActivityPageBySid(self._sid)
		if pbData then
			self:OnActivityPageResp(pbData)
		else
			gModelActivity:OnActivityPageReq(self._sid)
		end
	end
end

function UIActSagaSel:InitEvent()
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mCancelBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mAllRaceBtn,function()
		self:TypeBtnEvent(0)
	end,LSoundConst.CLICK_PAGE_COMMON)

	self._typeBtbList = {
		self.mRaceBtn1,
		self.mRaceBtn2,
		self.mRaceBtn3,
		self.mRaceBtn4,
		self.mRaceBtn5,
	}

	for i,v in ipairs(self._typeBtbList) do
		self:SetWndClick(v,function()
			self:TypeBtnEvent(i)
		end,LSoundConst.CLICK_PAGE_COMMON)
	end

	self:SetWndClick(self.mEnterBtn,function()
		self:EnterEvent()
	end)
end

function UIActSagaSel:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (...) self:OnActivityPageResp(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivitySelectDropGiftResp,function (...)
		self:WndClose()
	end)
end

function UIActSagaSel:InitHeroList()
	local list = {}
	for i,v in ipairs(self._heroList or {}) do
		local refId = v.itemId
		local raceType = gModelHero:GetHeroRace(refId)
		local isIns = false
		if self._type == 0 then
			isIns = true
		elseif raceType == self._type then
			isIns = true
		end
		if isIns then
			table.insert(list,v)
		end
	end

--[[	if self._uiHeroList then
		self._uiHeroList:RefreshList(list)
	else
		self._uiHeroList = self:GetUIScroll("uiHeroList")
		self._uiHeroList:Create(self.mHeroList,list,function (...) self:OnDrawHeroMapCell(...) end,UIItemList.WRAP)
	end]]

	local uiList = self._uiHeroList
	if (not uiList) then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mHeroList)
		uiList:SetFuncOnItemDraw(function (...)
			self:OnDrawHeroMapCell(...)
		end)
		self._uiHeroList = uiList
	end
	uiList:RemoveAll()
	for i,v in ipairs(list) do
		local refId = v.itemId
		uiList:AddData(refId,v)
	end
	uiList:RefreshList()
end

function UIActSagaSel:TypeBtnEvent(index)
	if self._type == index then return end
	if index == 0 then
		CS.SetParentTrans(self.mRaceSelImg,self.mAllRaceBtn)
	else
		CS.SetParentTrans(self.mRaceSelImg,self._typeBtbList[index])
	end
	self._type = index
	self:InitHeroList()
end

function UIActSagaSel:EnterEvent()
	if not self._clickRefId then
		GF.ShowMessage(ccClientText(11646))
	else
		local wishKeyList = self._wishKeyList
		local selData = wishKeyList[self._clickRefId]
		if selData then
			gModelActivity:OnActivitySelectDropGiftReq(self._sid,selData.pageId,selData.entryId)
		end
	end
end

function UIActSagaSel:OnDrawHeroMapCell(list, item, itemdata, itempos, fromHeadTail)
	if self:IsWndClosed() then return end
	local aniRootTrans = CS.FindTrans(item,"AniRoot")
	local CoverTrans = CS.FindTrans(item,"Cover")
	local UpImgTrans = CS.FindTrans(item,"UpImg")
	local SelStatusTrans = CS.FindTrans(item,"SelStatus")
	local heroTrans = CS.FindTrans(aniRootTrans,"IconRoot")

	local itype,refId,count = itemdata.itemType, itemdata.itemId, itemdata.itemNum

	local isInPool = itemdata.isInPool or false
	CS.ShowObject(CoverTrans,isInPool)
	CS.ShowObject(UpImgTrans,isInPool)

	local instanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(heroTrans)
	baseClass:SetCommonReward(itype,refId,count)

	local showGou = self._clickRefId == refId
	--baseClass:SetShowGouImg(showGou)
	CS.ShowObject(SelStatusTrans,showGou)

	baseClass:DoApply()

	self:SetWndClick(aniRootTrans,function()
--[[		if self._clickRefId then
			self._clickRefId:ShowGouImg(false)
		end
		local clickBaseClass = heroIconList[instanceID]
		if clickBaseClass then
			clickBaseClass:ShowGouImg(true)
			self._clickRefId = clickBaseClass
		end]]

		-- 预览状态下不支持选中
		if self._isPre then return end
		local old = self._clickRefId
		if old == refId then return end

		--baseClass:ShowGouImg(true)
		self._clickRefId = refId
		self._uiHeroList:DrawItemByKey(refId)

		if old then
			if self._uiHeroList then
				self._uiHeroList:DrawItemByKey(old)
			end
		end
	end)

	self:SetWndLongClick(aniRootTrans,function()
		gModelGeneral:OpenHeroStarPre({refId = itemdata.itemId})
	end,0.5,false)
end

function UIActSagaSel:InitData()
	self._heroList = self:GetWndArg("heroList")
	self._isPre = self:GetWndArg("preview")
	self._sid = self:GetWndArg("sid")
	self._wishHero = self:GetWndArg("wishHero") or {}
	local mySelectHero = self:GetWndArg("mySelectHero")
	self._type = 0
	self._clickRefId = mySelectHero
	self._wishKeyList = {}

	self._inWishUpHeroPoolMap = self:GetWndArg("inWishUpHeroPoolMap") or {}
end

function UIActSagaSel:OnActivityPageResp(pb,ret)
	local sid = pb.sid
	if sid ~= self._sid then return end
	if not self._heroList then
		self._heroList = {}
	end
	local inWishUpHeroPoolMap = self._inWishUpHeroPoolMap or {}
	local isInPool
	local wishHero = self._wishHero
	for k,v in ipairs(pb.pages or {}) do
		local pageType = v.pageType
		if pageType == 5 then
			local dropPage = gModelActivity:GenerateActivePageDataFromPb(v)
			local pageId = dropPage.pageId
			local entry = dropPage and dropPage.entry or {}
			for _i,_v in ipairs(entry) do
				local entryId = _v.entryId
				if wishHero[entryId] then
					local items = _v.items
					for idx,val in ipairs(items) do
						local itype = val.type
						if itype == LItemTypeConst.TYPE_HERO then
							isInPool = inWishUpHeroPoolMap[entryId] ~= nil or false
							local itemId = val.itemId
							local tempData = {
								itemId = itemId,
								itemType = val.type,
								itemNum = tonumber(val.count),
								entryId = entryId,
								pageId = pageId,
								isInPool = isInPool,
							}
							table.insert(self._heroList,tempData)
							self._wishKeyList[itemId] = tempData
						end
					end
				end
			end
		end
	end
	self:InitHeroList()
end
------------------------------------------------------------------
return UIActSagaSel


