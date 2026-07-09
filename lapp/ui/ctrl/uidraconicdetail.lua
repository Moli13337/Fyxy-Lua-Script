---
--- Created by wzz.
--- DateTime: 2024/9/25 21:30:47
---
------------------------------------------------------------------

-- 底部tab列表
local TabList = {
	[2] = { funcId = 1, title = ccClientText(41087), icon = "draconic_tab1" },
	[1] = { funcId = 2, title = ccClientText(41086), icon = "draconic_tab2" },
}

local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder

local LWnd = LWnd
---@class UIDraconicDetail:LWnd
local UIDraconicDetail = LxWndClass("UIDraconicDetail", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDraconicDetail:UIDraconicDetail()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDraconicDetail:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDraconicDetail:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDraconicDetail:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()
	self._isVie = gLGameLanguage:IsVieVersion()
	self:InitData()
	self:InitTexts()
	self:InitEvents()
	self:InitEffect()
	self:RefreshEmptyTips()
	self:Refresh()
end

-- 刷新界面
function UIDraconicDetail:Refresh()
	local refId   = self._refId
	local starNum = gModelDraconic:GetSpeechStar(refId)
	local starMax = gModelDraconic:GetStarMax(refId)
	local ref     = gModelDraconic:GetDraconicRef(refId)

	self:SetWndText(self.mTxtTitle, ccLngText(ref.name))
	self:DrawStar(self.mStarRoot, starNum, starMax)

	if self._curFuncId == 1 then
		self:RefreshView1()
	elseif self._curFuncId == 2 then
		self:RefreshView2()
	end
	self:RefreshTabList()

	CS.ShowObject(self.mView1, self._curFuncId == 1)
	CS.ShowObject(self.mView2, self._curFuncId == 2)
end

--region 界面1 ---------------------------------------------

-- 刷新界面1
function UIDraconicDetail:RefreshView1()
	local refId = self._refId
	local ref   = gModelDraconic:GetDraconicRef(refId)

	-- 卡片
	local param = {
		refId = refId,
	}
	gModelDraconic:DrawCard(self, self.mTopCard, param)
	self:SetTextTile(self.mAttachTips2, ccClientText(41090, ccLngText(ref.name)))

	self:RefreshAttr()
	self:RefreshCost()

	local data = {}
	data.refId = refId
	data.txtTips = ccClientText(41088)
	data.txtTips2 = ""
	data.btnTipsFunc = function()
		self:ShowDraconicTipsWnd()
	end

	gModelDraconic:DrawSkillTemplate(self, self.mSkill1, data)

	local attachRefId = gModelDraconic:GetAttachRefId(refId)
	local attachRefIdList = gModelDraconic:GetCanAttachRefIdList(refId)

	local isFix = #attachRefIdList == 1
	local data = nil
	if isFix or attachRefId > 0 then
		-- 固定附魂
		data = {}
		local refId2 = attachRefId
		if isFix and attachRefId == 0 then
			refId2 = attachRefIdList[1]
			data.lock = true
		end

		local ref2   = gModelDraconic:GetDraconicRef(refId2)
		data.refId   = refId2
		data.txtTips = ccLngText(ref2.name)

		if data.lock then
			data.txtTips2 = ccClientText(41095, ccLngText(ref2.name))
		else
			local per     = gModelDraconic:GetAttachTriggerRate(attachRefId)
			data.txtTips2 = ccClientText(41091, per)
		end


		data.btnTipsFunc = function()
			self:OpenAttachTipsWnd(refId2)
		end

		gModelDraconic:DrawSkillTemplate(self, self.mSkill2, data)
	end

	CS.ShowObject(self.mAttach, #attachRefIdList > 1 and attachRefId == 0)
	CS.ShowObject(self.mSkill2, data ~= nil)
end

-- 属性列表 item
function UIDraconicDetail:OnDrawAttrItem(uiList, item, data)
	if not uiList then
		uiList      = {}
		uiList.icon = CS.FindTrans(item, "AttrIcon")
		uiList.txt  = CS.FindTrans(item, "AttrValue")
		uiList.name = CS.FindTrans(item, "AttrName")
		uiList.add  = CS.FindTrans(item, "AttrAdd")
	end

	local iconPath = gModelHero:GetAttributeIconById(data.attrId)
	self:SetWndEasyImage(uiList.icon, iconPath)

	local val = gModelHero:GetAttributeValueNoNameByIdAndVal(data.attrId, data.type, data.value)
	self:SetWndText(uiList.txt, val)

	local name = gModelHero:GetAttributeNameById(data.attrId)
	self:SetWndText(uiList.name, name)

	self:SetWndText(uiList.add, data.addValue and "+" .. data.addValue or "")

	if self._isVie then
		self:InitTextSizeWithLanguage(uiList.name,-4)
		self:SetAnchorPos(uiList.txt,Vector2.New(10,0))
	end

	return uiList
end

-- 底部列表 item
function UIDraconicDetail:OnDrawTabItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			item = item
		}
		self:SetComponentCache(instanceID, itemCache)
	end

	self:SetWndTabText(itemCache.item, ccLngText(itemdata.title))
	self:SetWndTabIcon(itemCache.item, itemdata.icon)
	self:SetWndClick(itemCache.item, function() self:OnClickTab(itemdata.funcId) end)

	local state = self._curFuncId == itemdata.funcId and LWnd.StateOn or LWnd.StateOff
	local attachRefId = gModelDraconic:GetAttachRefId(self._refId)
	if attachRefId == -1 and itemdata.funcId == 2 then
		state = LWnd.StateLock
	end

	self:SetWndTabStatus(itemCache.item, state, itempos)

	local showRed = false
	if itemdata.funcId == 1 then
		showRed = gModelDraconic:CanActiveOrUpStar(self._refId, false)
	else
		showRed = gModelDraconic:CanAttach(self._refId)
	end
	self:SetRed(itemCache.item, showRed)
end

-- 刷新消耗
function UIDraconicDetail:RefreshCost()
	local refId    = self._refId
	local starNum  = gModelDraconic:GetSpeechStar(refId)
	local costItem = gModelDraconic:GetUpStarCostRef(refId, starNum)
	local isMax    = costItem == nil
	local btnStr   = ""
	if starNum == -1 then
		btnStr = ccClientText(41033)
	elseif isMax then
		-- 满星
	else
		btnStr = ccClientText(41032)
	end

	if not isMax then
		self:DrawItem(self.mBtnUpCostItem, costItem)

		local refId = costItem.refId
		local haveNum = gModelItem:GetNumByRefId(refId)
		local needNum = costItem.count
		local color = "139057"
		if haveNum < needNum then
			color = "c81212"
		end
		needNum = string.replace(ccClientText(41035), color, LUtil.NumberCoversion(haveNum), needNum)
		self:SetWndText(self.mBtnUpCostNum, needNum)
	end

	CS.ShowObject(self.mCostRoot, not isMax)
	CS.ShowObject(self.mUpMax, isMax)

	self:SetWndButtonText(self.mBtnUp, btnStr)
	self:SetRed(self.mBtnUp, gModelDraconic:CanActiveOrUpStar(refId))
end

-- 绘制星星
function UIDraconicDetail:DrawStar(trans, starNum, starMax)
	local instanceID = trans:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {}
		for i = 1, 10 do
			itemCache[i] = {}
			itemCache[i].star = CS.FindTrans(trans, "star" .. i)
			itemCache[i].gray = CS.FindTrans(trans, "star" .. i .. "/gray")
		end
		self:SetComponentCache(instanceID, itemCache)
	end

	for i, v in ipairs(itemCache) do
		if i > starMax then
			CS.ShowObject(v.star, false)
		else
			CS.ShowObject(v.star, true)
			CS.ShowObject(v.gray, i > starNum)
		end
	end
end

-- 打开附魂提示界面
function UIDraconicDetail:OpenAttachTipsWnd(refId)
	GF.OpenWnd("UIDraconicAttachTips", { attachRefId = refId, refId = self._refId })
end

-- 初始事件
function UIDraconicDetail:InitEvents()
	self:SetWndClick(self.mCloseBtn, function() self:WndClose() end)
	self:SetWndClick(self.mBtnUp, function(...) self:OnClickBtnUp() end)
	self:SetWndClick(self.mBtnAttach, function(...) self:OnClickBtnAttach() end)
	self:SetWndClick(self.mAttachAdd, function(...) self:OnClickBtnAttach() end)

	self:WndEventRecv(EventNames.DRACONIC_INFO_RETURN, function(...) self:Refresh(...) end)
	self:WndEventRecv(EventNames.On_Item_Change, function(...) self:RefreshCost(...) end)
end

-- 初始化数据
function UIDraconicDetail:InitData()
	self._refId = self:GetWndArg("refId")
	self._curFuncId = TabList[2].funcId
end

-- 显示龙魂提示界面
function UIDraconicDetail:ShowDraconicTipsWnd()
	local refId = self._refId
	local starNum = gModelDraconic:GetSpeechStar(refId)

	local attachUpRef
	local attachRefId = gModelDraconic:GetAttachRefId(refId)
	if attachRefId > 0 then
		local starNum = gModelDraconic:GetSpeechStar(attachRefId)
		attachUpRef = gModelDraconic:GetUpStarRef(attachRefId, starNum)
	end

	GF.OpenWnd("UIDraconicTips", { refId = refId, starNum = starNum, attachUpRef = attachUpRef })
end

-- 播放动画
function UIDraconicDetail:InitEffect()
	self:CreateWndEffect(self.mAttachEff, "fx_ui_longwenfuhun", "fx_ui_longwenfuhun", 100)
end

-- 点击tab
function UIDraconicDetail:OnClickTab(funcId)
	if funcId == self._curFuncId then
		return
	end

	local attachRefId = gModelDraconic:GetAttachRefId(self._refId)
	if attachRefId == -1 then
		GF.ShowMessage(ccClientText(41094))
		return
	end

	self._curFuncId = funcId

	self:Refresh()
end

-- 初始界面化文本
function UIDraconicDetail:InitTexts()
	self:SetWndText(self.mTxtClose, ccClientText(42010))
	self:SetTextTile(self.mUpMax, ccClientText(41031))
	self:SetWndText(self.mAttachTips2, ccClientText(40911))

	self:SetWndText(self.mTxtAttachTips, ccClientText(41096))

	local ref = gModelDraconic:GetDraconicRef(self._refId)
	self:SetWndText(self.mAttachTips1, ccClientText(40912, ccLngText(ref.name)))
end

-- 刷新属性
function UIDraconicDetail:RefreshAttr()
	local curAttrList  = {}
	local nextAttrList = {}
	local refId        = self._refId
	local starNum      = gModelDraconic:GetSpeechStar(refId)
	local costItem     = gModelDraconic:GetUpStarCostRef(refId, starNum)
	if starNum == -1 then
		-- 未激活
		starNum = -1
		curAttrList = gModelDraconic:GetSpeechBaseAttr(refId, 0)
		nextAttrList = {}
	elseif costItem == nil then
		-- 满星
		curAttrList = gModelDraconic:GetSpeechBaseAttr(refId, starNum)
		nextAttrList = {}
	else
		curAttrList = gModelDraconic:GetSpeechBaseAttr(refId, starNum)
		nextAttrList = gModelDraconic:GetSpeechBaseAttr(refId, starNum + 1)
	end

	local addMap = {}
	for k, v in ipairs(nextAttrList) do
		addMap[v.attrId] = v
	end

	for _, v in ipairs(curAttrList) do
		if addMap[v.attrId] then
			v.addValue = addMap[v.attrId].value - v.value
		end
	end

	self:SetComList(self.mAttrList, curAttrList, function(...) return self:OnDrawAttrItem(...) end)
end

-- endregion 界面1 ---------------------------------------------


--region 界面2 ---------------------------------------------

-- 刷新界面2
function UIDraconicDetail:RefreshView2()
	local refId = self._refId
	local ref   = gModelDraconic:GetDraconicRef(refId)

	-- 卡片
	local param = {
		refId = refId,
	}
	gModelDraconic:DrawCard(self, self.mTopCardMain, param)

	local attachRefId = gModelDraconic:GetAttachRefId(refId)
	local refId2 = attachRefId
	local attachRefIdList = gModelDraconic:GetCanAttachRefIdList(refId)

	local isFix = #attachRefIdList == 1

	if attachRefId == 0 and isFix then
		refId2 = attachRefIdList[1]
	end

	local showTemplate = false
	if refId2 > 0 then
		-- 显示附魂
		local data = {}
		data.refId = refId2
		data.txtTips = ccClientText(41088)
		data.txtTips2 = ""
		data.lock = attachRefId == 0
		if attachRefId > 0 then
			local per     = gModelDraconic:GetAttachTriggerRate(attachRefId)
			data.txtTips2 = ccClientText(41091, per)
		end

		data.btnTipsFunc = function()
			self:OpenAttachTipsWnd(refId2)
		end

		gModelDraconic:DrawSkillTemplate(self, self.mAttachSkill, data)
		showTemplate = true

		local param = {
			refId = refId2,
		}
		gModelDraconic:DrawCard(self, self.mTopCardAttach, param)

		local starNum = gModelDraconic:GetSpeechStar(refId2)
		local starMax = gModelDraconic:GetStarMax(refId2)
		local ref     = gModelDraconic:GetDraconicRef(refId2)

		local color   = gModelItem:GetColorStringByQualityId(ref.quality)
		local name    = ccClientText(41021, color, ccLngText(ref.name))
		self:SetWndText(self.mTxtAttachName, name)
		self:DrawStar(self.mAttachStarRoot, starNum, starMax)
	end
	local showAdd = not isFix and attachRefId == 0
	CS.ShowObject(self.mAttachSkill, showTemplate)
	CS.ShowObject(self.mAttachStarRoot, showTemplate)
	CS.ShowObject(self.mTxtAttachName.parent, showTemplate)
	CS.ShowObject(self.mAttachMask, isFix and attachRefId == 0)
	CS.ShowObject(self.mAttachAdd, showAdd)
	CS.ShowObject(self.mTopCardAttach, not showAdd)

	CS.ShowObject(self.mNoRecord2, not showTemplate)

	local str = attachRefId == 0 and ccClientText(41092) or ccClientText(41093)
	self:SetWndButtonText(self.mBtnAttach, str)

	CS.ShowObject(self.mAttachEff, attachRefId > 0)
end

-- 绘制item
function UIDraconicDetail:DrawItem(mItem, itemdata)
	local refId = itemdata.refId
	local instanceID = mItem:GetInstanceID()
	local baseClass, isNew = self:GetCommonIcon(instanceID)
	if isNew then
		baseClass:Create(mItem)
	end

	baseClass:SetCommonReward(itemdata.type, refId, itemdata.count)
	self:SetWndClick(mItem, function()
		gModelGeneral:OpenGetWayWnd({ itemId = refId })
	end)
	baseClass:EnableShowNum(false)
	baseClass:EnableShowBg(false)
	baseClass:DoApply()
end

-- 刷新空列表
function UIDraconicDetail:RefreshEmptyTips()
	local text = self.mEmptyText
	local emptyList = self:GetCommonEmptyList("_empty")
	local data =
	{
		refId = 42000,
		IntroTran = text,
		--TextBgTran,
		--IconTran,
		--GetBtn,
		--GetBtnText
		--ButtonRoot,
	}
	emptyList:RefreshUI(data)
end

-- 点击附魂
function UIDraconicDetail:OnClickBtnAttach()
	local refId = self._refId

	local starNum = gModelDraconic:GetSpeechStar(refId)
	if starNum == -1 then
		GF.ShowMessage(ccClientText(40905))
		return
	end

	local attachRefId = gModelDraconic:GetAttachRefId(refId)
	if attachRefId > 0 then
		gModelDraconic:DraconicLinkReq(refId, 0)
		return
	end


	local attachRefIdList = gModelDraconic:GetCanAttachRefIdList(refId)
	if #attachRefIdList > 1 then
		GF.OpenWnd("UIDraconicAttachSelect", { refId = refId })
		return
	end

	local attachRefId = gModelDraconic:GetAttachRefId(refId)
	local linkRefId = 0
	if attachRefId == 0 then
		linkRefId = attachRefIdList[1]
		local starNum = gModelDraconic:GetSpeechStar(linkRefId)
		if starNum == -1 then
			GF.ShowMessage(ccClientText(40905))
			gModelGeneral:OpenGetWayWnd({ itemId = linkRefId })
			return
		end
	end

	local mainAttachRefId = gModelDraconic:GetMainAttachRefId(linkRefId)
	if mainAttachRefId > 0 then
		local ref = gModelDraconic:GetDraconicRef(mainAttachRefId)
		GF.ShowMessage(ccClientText(40913, ccLngText(ref.name)))
		return
	end

	if gModelDraconic:HadUsedCheckAllFormations(linkRefId) then
		local ref = gModelDraconic:GetDraconicRef(linkRefId)
		gModelGeneral:OpenUIOrdinTips({
			refId = 52003,
			para = {ccLngText(ref.name)},
			func = function()
				gModelDraconic:DraconicLinkReq(refId, linkRefId)
			end,
		})
		return
	end

	gModelDraconic:DraconicLinkReq(refId, linkRefId)
end

-- 刷新底部列表
function UIDraconicDetail:RefreshTabList()
	self._uiTabItemList = {}
	local uiTabList = self:FindUIScroll("mTabScroll")
	if not uiTabList then
		uiTabList = self:GetUIScroll("mTabScroll")
		uiTabList:Create(self.mTabScroll, TabList, function(...) self:OnDrawTabItem(...) end)
	else
		uiTabList:DrawAllItems()
	end
end

-- 点击升级
function UIDraconicDetail:OnClickBtnUp()
	if not gModelDraconic:CanActiveOrUpStar(self._refId, true) then
		return
	end
	gModelDraconic:DraconicRankUpReq(self._refId)
end

function UIDraconicDetail:OnWndRefresh()
	self:InitData()
	self:RefreshEmptyTips()
	self:Refresh()
end

-- endregion 界面2 ---------------------------------------------


------------------------------------------------------------------
return UIDraconicDetail