---
--- Created by wzz.
--- DateTime: 2024/6/24 20:06:19
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBlockMiniGameLevel:LWnd
local UIBlockMiniGameLevel = LxWndClass("UIBlockMiniGameLevel", LWnd)
local typeOfSkeletonGraphic = typeof(Spine.Unity.SkeletonGraphic)
local LDisplaySpine = LDisplaySpine

local typeofCanvas = typeof(UnityEngine.Canvas)
local ColorBlack = Color.black
local ColorWhite = Color.white

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBlockMiniGameLevel:UIBlockMiniGameLevel()
	self._model = gModelBlockMiniGame
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBlockMiniGameLevel:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBlockMiniGameLevel:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBlockMiniGameLevel:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isVie = gLGameLanguage:IsVieVersion()
	gModelRedPoint:SetRedPointClicked(ModelRedPoint.BLOCKMINIGAME)

	self:InitTexts()
	self:InitEvents()
	self:InitList()
	self:InitSlider()

	self:Refresh()
	self:RefreshForeign()
end

-- 刷新界面
function UIBlockMiniGameLevel:Refresh()
	local passMaxLev = gModelBlockMiniGame:GetPassMaxLev()
	self:SetWndText(self.mTxtPass, ccClientText(43519, passMaxLev))

	local refList, min, max = gModelBlockMiniGame:GetCurAwardList()

	local LUtil = LUtil
	local totalW = self._sliderSize.x
	local curW = 0
	local AwardState = gModelBlockMiniGame.AwardState
	for i, ref in ipairs(refList) do
		local tab = self._sliderUiList[i]

		self:SetWndText(tab.lev, ref.num)

		local itemData = LUtil.GetRefItemData(ref.reward)
		local param = {
			showNum = true,
			clickFunc = function() self:OnClickAward(itemData, ref, refList) end,
		}

		self:CreateCommonIconImpl(tab.itemRoot, itemData, param)

		-- tab.root.anchoredPosition = Vector2((ref.num - min) / (max - min)  * w - 25, 0)

		local statue = gModelBlockMiniGame:GetAwardStatus(ref.refId)
		if statue == AwardState.CanGet or statue == AwardState.HadGet then
			curW = curW + totalW * 0.25
		else
			local pre = refList[i - 1] and refList[i - 1].num or 0
			if passMaxLev >= pre and passMaxLev < ref.num then
				curW = curW + totalW * 0.25 * (passMaxLev - pre) / (ref.num - pre)
			end
		end

		CS.ShowObject(tab.canGet, statue == AwardState.CanGet)
		CS.ShowObject(tab.hadGet, statue == AwardState.HadGet)
	end

	self.mImgSlider.sizeDelta = Vector2(curW, self._sliderSize.y)
end

-- 将列表一行一个划成一行多个
-- 例如：{1，2，3，4，5，6}改成{{1,2,3}, {4,5,6}}
function UIBlockMiniGameLevel:ChangeLineNum(list, one_line_num)
	local new_list = {}
	local tab = {}
	local amount = 0
	for k, v in ipairs(list) do
		if amount == 0 then
			tab = {}
		end
		table.insert(tab, v)
		amount = amount + 1

		if amount == one_line_num then
			amount = 0
			table.insert(new_list, tab)
		elseif k == #list then
			table.insert(new_list, tab)
		end
	end
	return new_list
end

-- 绘制列表item项
function UIBlockMiniGameLevel:OnDrawListItem(list, item, itemData, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {}
		for i = 1, 8 do
			local root    = item:Find("bg/" .. i)
			local tab     = {}
			tab.root      = root
			tab.spine     = CS.FindTrans(root, "Spine")
			tab.lock      = CS.FindTrans(root, "Lock")
			tab.lockTips  = CS.FindTrans(root, "Lock/LockTips")
			tab.unLock    = CS.FindTrans(root, "UnLock")
			tab.target    = CS.FindTrans(root, "Target")
			tab.completed = CS.FindTrans(root, "Completed")
			tab.btnFight  = CS.FindTrans(root, "BtnFight")
			tab.btnFight  = CS.FindTrans(root, "BtnFight")

			itemCache[i]  = tab

			self:SetWndButtonText(tab.btnFight, ccClientText(43514))
			self:SetTextTile(tab.completed, ccClientText(43513))

			local obj = tab.lockTips.gameObject
			local wndCanvas = obj:GetComponent(typeofCanvas)
			if wndCanvas then
				wndCanvas.overrideSorting = true
				wndCanvas.sortingLayerName = self:GetWndSortLayer()
				wndCanvas.sortingOrder = self:GetWndSortOrder() + 100
			end
		end
		self:SetComponentCache(instanceID, itemCache)

	end

	for i = 1, 8 do
		self:DrawItem(itemCache[i], itemData[i])
	end
end

-- 初始事件
function UIBlockMiniGameLevel:InitEvents()
	self:SetWndClick(self.mCloseBtn, function() self:OnClickBtnBlack() end)
	self:SetWndClick(self.mBtnHelp, function() self:OnClickBtnHelp() end)

	self:WndEventRecv(EventNames.BLOCKMINIGAME_AWARD, function() self:OnReceiveAward() end)
end

-- 点击返回
function UIBlockMiniGameLevel:OnClickBtnBlack()
	self:Show(false)
	if PRODUCT_G_VER ~= 0 then
		if gLGameLanguage:CheckIsUseSpecialProduct() then
			local packId = gLGameLanguage:GetPackProductInfo()
			if packId == 1 then

			elseif packId == 2 then
			elseif packId == 3 then

				--打开页面
				GF.OpenWnd("UIOuttsList", { listRefId = 10101 })
				return
			end
		end
	end
	self:WndClose()

	GF.ChangeMap("LCityMap")

	GF.OpenWndBottom("UIOutts", { childIndex = 1 })
	FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.OUTSKIRTS })
end

-- 点击帮助
function UIBlockMiniGameLevel:OnClickBtnHelp()
	GF.OpenWnd("UIBlockMiniGameHelp")
end

function UIBlockMiniGameLevel:RefreshForeign()
	if self._isVie then
		self:InitTextSizeWithLanguage(self.mTxtTitle,-6)
	end
end

-- 初始化列表
function UIBlockMiniGameLevel:InitList()
	local uiList = self:GetUIScroll("mList")
	self._uiList = uiList

	local onePageNum = 8
	local dataList = self:ChangeLineNum(self._model:GetAllLevRef(), onePageNum)
	self._uiDataList = dataList
	uiList:Create(self.mList, dataList, function(...)
		self:OnDrawListItem(...)
	end, UIItemList.SUPER_GRID)


	local max = self._model:GetPassMaxLev()
	local pos = math.floor(max / 8)
	local index = max - pos * 8
	local offList = { 0, 0,-133, -224,-358, -452, -608,-719, -800}
	if index == 0 and pos > 0 then
		index = 8
		pos = pos - 1
	elseif index == 1 and pos > 0 then
		index = 9
		pos = pos - 1
	end

	self._uiList:MoveToPos(pos + 1, 0, offList[index] or 0)
end

-- 初始化进度条
function UIBlockMiniGameLevel:InitSlider()
	self._sliderUiList = {}
	for i = 1, 4 do
		local root = self["mItem" .. i]
		local itemRoot = CS.FindTrans(root, "itemRoot")
		local lev = CS.FindTrans(root, "Lev")
		local canGet = CS.FindTrans(root, "CanGet")
		local hadGet = CS.FindTrans(root, "HadGet")
		self._sliderUiList[i] = { itemRoot = itemRoot, lev = lev, root = root, canGet = canGet, hadGet = hadGet }
	end
	self._sliderSize = self.mImgSlider.sizeDelta
end

-- 领取奖励
function UIBlockMiniGameLevel:OnReceiveAward()
	self:Refresh()
end

-- 点击奖励
function UIBlockMiniGameLevel:OnClickAward(itemData, ref, refList)


	-- self._index = self._index or 0
	-- self._index = self._index + 1
	-- if self._index > 15 then
	-- 	self._index = 0
	-- end

	-- local max = self._index
	-- local pos = math.floor(max / 8)
	-- local index = max - pos * 8
	-- local offList = { 0, 0,-133, -224,-358, -452, -608,-719, -800}
	-- Log("OnClickAward", max, pos, index, offList[index])
	-- if index == 0 and pos > 0 then
	-- 	index = 8
	-- 	pos = pos - 1
	-- elseif index == 1 and pos > 0 then
	-- 	index = 9
	-- 	pos = pos - 1
	-- end

	-- self._uiList:MoveToPos(pos + 1, 0, offList[index] or 0)
	-- Log("OnClickAward11111", max, pos, index, offList[index])



	local AwardState = gModelBlockMiniGame.AwardState
	if gModelBlockMiniGame:GetAwardStatus(ref.refId) ~= AwardState.CanGet then
		gModelGeneral:ShowCommonItemTipWnd(itemData)
		return
	end

	-- 可以领取奖励
	local refIdList = {}
	for i, ref in ipairs(refList) do
		if gModelBlockMiniGame:GetAwardStatus(ref.refId) == AwardState.CanGet then
			table.insert(refIdList, ref.refId)
		end
	end

	gModelBlockMiniGame:BlockMiniGamePassRewardReq(refIdList)
end

-- 初始界面化文本
function UIBlockMiniGameLevel:InitTexts()
	self:SetWndText(self.mTxtTitle, ccClientText(43515))
	self:SetWndText(self.mTxtClose, ccClientText(30205))
end

-- 点击item
function UIBlockMiniGameLevel:OnClickItem(ref)
	GF.OpenWnd("UIBlockMiniGameLevelFight", { refId = ref.refId })
end

-- 列表item
function UIBlockMiniGameLevel:DrawItem(item, ref)
	CS.ShowObject(item.root, ref ~= nil)
	if not ref then
		return
	end

	if item.dpObj then
		item.dpObj:Destroy()
		item.dpObj = nil
	end

	local curRef = gModelBlockMiniGame:GetCurLevRef()
	local curLev = curRef.refId
	local lev = ref.refId
	CS.ShowObject(item.lock, curLev == lev)

	local openTips = false
	if curLev + 1 == lev and ref.desc ~= "" then
		openTips = true
		self:SetTextTile(item.lockTips, ccLngText(ref.desc))
	end
	CS.ShowObject(item.lockTips, openTips)

	local passMaxLev = gModelBlockMiniGame:GetPassMaxLev()
	local isPassMax = false
	if gModelBlockMiniGame:GetLevRef(lev + 1) == nil then
		local passMaxLev = gModelBlockMiniGame:GetPassMaxLev()
		isPassMax = passMaxLev == lev
	end

	local lock = curLev < lev
	CS.ShowObject(item.lock, lock)
	CS.ShowObject(item.unLock, not lock)
	CS.ShowObject(item.target, curLev == lev)
	CS.ShowObject(item.btnFight, curLev == lev and not isPassMax and passMaxLev ~= lev)
	CS.ShowObject(item.completed, (curLev > lev or isPassMax) or passMaxLev == lev)

	local strTitle = ccClientText(43512, lev)
	self:SetTextTile(item.lock, strTitle)
	self:SetTextTile(item.unLock, strTitle)

	self:SetWndClick(item.root, function()
		if not lock then
			self:OnClickItem(ref)
		end
	end)

	local heroEffectRef = self._model:GetHeroEffectRef(ref.pagodaBoss)
	local dp = LDisplaySpine:New()
	dp:CreateSpine(item.spine, heroEffectRef.prefabName, 1)
	dp:SetScale(1)
	dp:SetFlipX(false)
	dp:SetLoadedFunction(function()
		local trans = dp:GetDisplayTrans()
		local graphic = trans:GetComponent(typeOfSkeletonGraphic)
		if lock then
			graphic.color = ColorBlack
		else
			graphic.color = ColorWhite
		end
	end)
	dp:StartLoad()
	item.dpObj = dp
end

------------------------------------------------------------------
return UIBlockMiniGameLevel