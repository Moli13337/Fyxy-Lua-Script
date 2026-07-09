---
--- Created by wzz.
--- DateTime: 2024/7/8 21:50:37
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishIllustrated:LWnd
local UIFishIllustrated = LxWndClass("UIFishIllustrated", LWnd)

local TabDataList = {
	--- 羁绊
	[2] = { onIcon = "fish_btn_icon_8", offIcon = "fish_btn_icon_8", title = ccClientText(44218), index = 1 },
	--- 鱼场
	[1] = { onIcon = "fish_btn_icon_7", offIcon = "fish_btn_icon_7", title = ccClientText(44219), index = 2 },
}

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishIllustrated:UIFishIllustrated()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishIllustrated:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishIllustrated:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishIllustrated:OnStart()
	LWnd.OnStart(self)
	self:InitUI()



	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitData()
	self:InitTexts()
	self:InitEvents()
	self:InitTabList()

	self:InitView1()
	self:InitView2()

	self:Refresh()
end

-- 底部tab列表 item
function UIFishIllustrated:OnDrawTab(list, item, itemData, index)
	self:SetWndTabText(item, itemData.title, nil, true)
	self:SetWndTabStatus(item, self._curView == itemData.index and 0 or 1)

	self:SetWndClick(item, function(...)
		if self._curView == itemData.index then
			return
		end
		self._curView = itemData.index

		self:Refresh()
	end)

	local offTrans = CS.FindTrans(item, "Off")
	local onTrans = CS.FindTrans(item, "On")
	local text1 = CS.FindTrans(item, "Off/Text")
	local text2 = CS.FindTrans(item, "On/Text")
	self:SetWndEasyImage(offTrans, itemData.offIcon)
	self:SetWndEasyImage(onTrans, itemData.onIcon)

	if itemData.index == 1 then
		self:SetRed(item, gModelFish:HadRedIllustrated())
	else
		self:SetRed(item, gModelFish:HadRedIllustratedFish())
	end
	if self.jpj then
		self:SetAnchorPos(text1,Vector2.New(0,-18))
		self:SetAnchorPos(text2,Vector2.New(0,-18))
	end
end

-- 初始界面化文本
function UIFishIllustrated:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(44214))
	self:SetWndText(self.mTxtClose, ccClientText(42010))
end

-- 刷新列表1
function UIFishIllustrated:RefreshList1()
	local dataList = gModelFish:GetIllustratedRefList(self._curTab)
	if not self._uiList1 then
		local uiList = self:GetUIScroll("mList1")
		self._uiList1 = uiList
		uiList:Create(self.mList1, dataList, function(...)
			self:OnDrawListItem1(...)
		end, UIItemList.SUPER_GRID)
	else
		self._uiList1:ResetList(dataList)
		self._uiList1:DrawAllItems()
	end
end

-- endregion ----------------------------------------------------


-- region view2 ----------------------------------------------------


-- 初始界面化view2
function UIFishIllustrated:InitView2()
	self:SetTextTile(self.mBtnTotalAttr, ccClientText(44220))
	self:SetWndClick(self.mBtnTotalAttr, function() self:OnClickTotalAttr() end)
end

-- 刷新界面2
function UIFishIllustrated:RefreshView2()
	self:RefreshList2()
end

-- 点击鱼场item
function UIFishIllustrated:OnClickFishItem(itemData)
	GF.OpenWnd("UIFishIllustratedDetail", { refId = itemData.refId, refList = itemData.refList })
end

-- 初始化数据
function UIFishIllustrated:InitData()
	self._curView = 1
end

-- 初始化item列表
function UIFishIllustrated:OnDrawIitem(uilist, root, data)
	if not uilist then
		uilist = {}
		uilist.lock = CS.FindTrans(root, "lock")
		uilist.itemRoot = CS.FindTrans(root, "itemRoot")
	end

	local itemData = { itemId = data.refId, itemType = CommonIcon.ICON_TYPE_FISH }
	self:CreateCommonIconImpl(uilist.itemRoot, itemData, {showNum = false, clickFunc = function()
		GF.OpenWnd("UIFishTips", { refId = data.refId, isTips = true })
	end})
	CS.ShowObject(uilist.lock, data.lock)
	return uilist
end

-- 点击tab
function UIFishIllustrated:OnClickTab(index)
	if self._curTab == index then
		return
	end
	self._curTab = index
	self:RefreshTab()
	self:RefreshView1()
end

-- 刷新tab
function UIFishIllustrated:RefreshTab()
	self:SetWndButtonGray(self.mTab1, self._curTab ~= 0)
	self:SetWndButtonGray(self.mTab2, self._curTab ~= 1)
	self:SetRed(self.mTab1, gModelFish:HadRedIllustratedByType(0))
	self:SetRed(self.mTab2, gModelFish:HadRedIllustratedByType(1))
end

-- 刷新界面
function UIFishIllustrated:Refresh()
	if self._curView == 1 then
		self:RefreshView1()
	else
		self:RefreshView2()
	end

	CS.ShowObject(self.mView1, self._curView == 1)
	CS.ShowObject(self.mView2, self._curView == 2)

	self._bottomTabList:DrawAllItems()
end

-- 刷新界面1
function UIFishIllustrated:RefreshView1()
	self:RefreshList1()
	self:RefreshTab()
end

-- region view1 ----------------------------------------------------

-- 初始界面化view1
function UIFishIllustrated:InitView1()
	self:SetWndButtonText(self.mTab1, ccClientText(44215))
	self:SetWndButtonText(self.mTab2, ccClientText(44216))


	self:SetWndClick(self.mTab1, function() self:OnClickTab(0) end)
	self:SetWndClick(self.mTab2, function() self:OnClickTab(1) end)


	local showBtn1 = false
	local dataList = gModelFish:GetIllustratedRefList(0)
	if dataList and #dataList > 0 then
		showBtn1 = true
	end
	CS.ShowObject(self.mTab1,showBtn1)

	local showBtn2 = false
	dataList = gModelFish:GetIllustratedRefList(1)
	if dataList and #dataList > 0 then
		showBtn2 = true
	end
	CS.ShowObject(self.mTab2,showBtn2)

	if not (showBtn1 and showBtn2) then
		CS.ShowObject(self.mTab1.parent,false)
	end

	self._curTab = 0
end

-- 点击总属性
function UIFishIllustrated:OnClickTotalAttr()
	local attrList = {}
	for k, v in ipairs(gModelFish:GetFishHandbookAttrList()) do
		local value = gModelFish:CheckAttrValue(v.refId, v.type,  v.value)
		attrList[k] = {
			attrRefId = v.refId,
			attrType = v.type,
			attrNum = value
		}
	end
	GF.OpenWnd("UISdAttrOverView", {attrList = attrList })
end

-- 点击激活
function UIFishIllustrated:OnClickBtnActive(refId)
	gModelFish:FishFetterActiveReq(refId)
end

-- 绘制列表item项
function UIFishIllustrated:OnDrawListItem1(list, item, itemData, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			bg        = CS.FindTrans(item, "Bg"),
			txtTitle  = CS.FindTrans(item, "Bg/TxtTitle"),
			attrList  = CS.FindTrans(item, "AttrList"),
			hadActive = CS.FindTrans(item, "HadActive"),
			btnActive = CS.FindTrans(item, "BtnActive"),
			itemList  = CS.FindTrans(item, "ItemList"),
		}
		self:SetComponentCache(instanceID, itemCache)
		self:SetWndButtonText(itemCache.btnActive, ccClientText(44217))
	end

	local ref = itemData
	local dataList, canActive, hadActive = gModelFish:GetActiveIllustratedDataList(ref.refId)

	self:SetWndText(itemCache.txtTitle, ccLngText(ref.name))
	self:SetWndEasyImage(itemCache.bg, ref.bg)

	gModelFish:DrawAttrList(self, itemCache.attrList, { strAttr = ref.attr })

	self:SetComList(itemCache.itemList, dataList, function(...) return self:OnDrawIitem(...) end)
	CS.ShowObject(itemCache.hadActive, hadActive)
	CS.ShowObject(itemCache.btnActive, canActive)
	if canActive then
		self:CreateWndEffect(itemCache.btnActive,"fx_anniu_01",instanceID,70,nil,nil,nil,nil,nil,true)
	end

	if canActive then
		self:SetWndClick(itemCache.btnActive, function()
			self:OnClickBtnActive(ref.refId)
		end)
	end
end

-- 刷新列表2
function UIFishIllustrated:RefreshList2()
	if not self._uiList2 then
		local uiList = self:GetUIScroll("mList2")
		self._uiList2 = uiList
		local dataList = gModelFish:GetillustratedFishRefList()
		uiList:Create(self.mList2, dataList, function(...)
			self:OnDrawListItem2(...)
		end, UIItemList.SUPER_GRID)
	else
		self._uiList2:DrawAllItems()
	end
end

-- 绘制列表item项
function UIFishIllustrated:OnDrawListItem2(list, item, itemData, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			aniRoot  = CS.FindTrans(item, "AniRoot"),
			txtTitle = CS.FindTrans(item, "AniRoot/TxtTitle"),
			lock     = CS.FindTrans(item, "AniRoot/Lock"),
		}
		self:SetComponentCache(instanceID, itemCache)
	end

	local refId = itemData.refId      -- 鱼场id
	local refList = itemData.refList  -- 鱼场物品配置列表
	local ref = gModelFish:GetRef(refId) -- 鱼场物品配置
	local unLockNum = 0
	local showRed = false
	for _, v in ipairs(refList) do
		if gModelFish:GetFishHandbookObjObj(v.refId) then
			unLockNum = unLockNum + 1
		end
		if not showRed and gModelFish:HadRedByFishRefId(v.refId) then
			showRed = true
		end
	end
	self:SetRed(itemCache.aniRoot, showRed)

	local numMax = #refList
	self:SetTextTile(itemCache.lock, ccClientText(44221, unLockNum, numMax))

	if ref then
		self:SetWndText(itemCache.txtTitle, ccLngText(ref.name))
		self:SetWndEasyImage(itemCache.aniRoot, ref.cell)
	end

	self:SetWndClick(item, function()
		self:OnClickFishItem(itemData)
	end)
end

-- 初始事件
function UIFishIllustrated:InitEvents()
	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end)

	self:WndEventRecv(EventNames.FISH_BASE_INFO, function(...) self:Refresh(...) end)
end

-- 底部tab列表
function UIFishIllustrated:InitTabList()
	local uiList = self:GetUIScroll("UIFishIllustrated")
	uiList:Create(self.mTabScroll, TabDataList, function(...)
		self:OnDrawTab(...)
	end)
	self._bottomTabList = uiList
end

-- endregion ----------------------------------------------------


------------------------------------------------------------------
return UIFishIllustrated