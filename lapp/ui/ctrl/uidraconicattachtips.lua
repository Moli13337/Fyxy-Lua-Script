---
--- Created by wzz.
--- DateTime: 2024/9/27 15:29:16
---
------------------------------------------------------------------

local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder

local TabDataList = {
	[1] = { tabName = ccClientText(41098) },
	[2] = { tabName = ccClientText(41099) },
}

local LWnd = LWnd
---@class UIDraconicAttachTips:LWnd
local UIDraconicAttachTips = LxWndClass("UIDraconicAttachTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDraconicAttachTips:UIDraconicAttachTips()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDraconicAttachTips:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDraconicAttachTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDraconicAttachTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isEnus = gLGameLanguage:IsForeignVersion()

	self.jpj = gLGameLanguage:IsJapanVersion()

	self._isVie = gLGameLanguage:IsVieVersion()
	self._curTabIndex = 1
	self._mainRefId = self:GetWndArg("refId")
	self._refId = self:GetWndArg("attachRefId")
	self._starNum = gModelDraconic:GetSpeechStar(self._refId)
	self._mainStarNum = gModelDraconic:GetSpeechStar(self._refId)
	self._initView = {}

	self:InitTexts()
	self:InitEvents()
	self:InitTab()
	self:Refresh()
end

-- 初始事件
function UIDraconicAttachTips:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
end

-- 刷新星级列表
function UIDraconicAttachTips:RefresList2()
	if not self._uiList2 then
		local uiList = self:GetUIScroll("mList2")
		self._uiList2 = uiList

		local list = gModelDraconic:GetUpStarRefList(self._refId)
		local dataList = {}
		local pos = 1
		for k, v in pairs(list) do
			table.insert(dataList, v)
		end
		table.sort(dataList, function(a, b)
			return a.refId < b.refId
		end)
		for k, v in ipairs(dataList) do
			if v.rankNow == self._mainStarNum then
				pos = k
			end
		end

		uiList:Create(self.mList2, dataList, function(...)
			self:OnDrawListItem2(...)
		end, UIItemList.SUPER, true)

		uiList:MoveToPos(pos)
	end
end

-- 技能template
function UIDraconicAttachTips:DrawSkillTemplate(trans, data)
	local instanceID = trans:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			txtSkillDesc = CS.FindTrans(trans, "txtSkillDesc"),
			img1= CS.FindTrans(trans, "top/Img1"),
			txtSkillLev  = CS.FindTrans(trans, "top/Img1/txtSkillLev"),
			skillBg      = CS.FindTrans(trans, "top/1/skillBg"),
			skillIcon    = CS.FindTrans(trans, "top/1/skillIcon"),
			lock         = CS.FindTrans(trans, "top/1/lock"),
			txtTips      = CS.FindTrans(trans, "top/Img2/txtTips"),
			txtTips2     = CS.FindTrans(trans, "top/Img2/txtTips2"),
			skillFlag    = CS.FindTrans(trans, "top/Img2/skillFlagRoot/skillFlag"),
			skillFlagRoot    = CS.FindTrans(trans, "top/Img2/skillFlagRoot"),
			btnTips      = CS.FindTrans(trans, "top/btnTips"),
		}
		self:SetComponentCache(instanceID, itemCache)
	end
	if self._isEnus then
		self:SetAnchorPos(itemCache.img1,Vector2.New(-130,-60))
	end
	if self._isVie then
		self:SetAnchorPos(itemCache.skillFlagRoot,Vector2.New(305,0))
	end
	local refId = data.refId

	self:SetWndText(itemCache.txtTips, data.txtTips or "")
	self:SetWndText(itemCache.txtTips2, data.txtTips2 or "")

	-- 技能标签
	gModelDraconic:DrawSkillFlag(self, itemCache.skillFlag, refId)

	-- 技能图标
	local ref = gModelDraconic:GetDraconicRef(refId)
	self:SetWndEasyImage(itemCache.skillBg, ref.skillbg)
	self:SetWndEasyImage(itemCache.skillIcon, ref.skillIcon)
	CS.ShowObject(itemCache.lock, data.lock == true)

	local starNum = gModelDraconic:GetSpeechStar(refId)
	self:SetWndText(itemCache.txtSkillLev, ccClientText(41036, starNum + 1))

	local upRef = gModelDraconic:GetUpStarRef(refId, math.max(0, starNum))
	local skillRef = GameTable.SnakeSkillRef[upRef.skillId]
	self:SetWndText(itemCache.txtSkillDesc, "           " .. ccLngText(skillRef.description))
	LayoutRebuilder.ForceRebuildLayoutImmediate(itemCache.txtSkillDesc)


	CS.ShowObject(itemCache.btnTips, false)
end

-- 星级列表 item
function UIDraconicAttachTips:OnDrawStarListItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache         = {}
		itemCache.txtDesc = CS.FindTrans(item, "TxtDesc")
		local list        = {}
		local list2       = {}
		for i = 1, 10 do
			list[i] = CS.FindTrans(item, "starRoot/star" .. i)
			list2[i] = CS.FindTrans(item, "starRoot/star" .. i .. "/gray")
		end
		itemCache.starList = list
		itemCache.starList2 = list2
		self:SetComponentCache(instanceID, itemCache)
	end

	local starNum = itemdata.rankNow
	local gray = self._starNum < starNum

	local strDesc = ccLngText(itemdata.effectExtraDesc)
	if gray then
		strDesc = string.gsub(strDesc, "<color.->", "")
		strDesc = string.gsub(strDesc, "</color>", "")
		strDesc = "<color=#5f6d7b>" .. strDesc .. "</color>"
	end

	self:SetWndText(itemCache.txtDesc, strDesc)
	LayoutRebuilder.ForceRebuildLayoutImmediate(item)

	-- 星星
	if starNum then
		if starNum <= 5 then
			for i = 1, 5 do
				CS.ShowObject(itemCache.starList[i], i <= starNum)
				CS.ShowObject(itemCache.starList2[i], gray)
			end
			for i = 6, 10 do
				CS.ShowObject(itemCache.starList[i], false)
			end
		else
			for i = 1, 5 do
				CS.ShowObject(itemCache.starList[i], false)
			end
			for i = 6, 10 do
				CS.ShowObject(itemCache.starList[i], i <= starNum)
				CS.ShowObject(itemCache.starList2[i], gray)
			end
		end
	end
end

-- 星级列表 item
function UIDraconicAttachTips:OnDrawListItem2(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache          = {}
		itemCache.txtTips1 = CS.FindTrans(item, "txtTips1")
		itemCache.txtTips2 = CS.FindTrans(item, "txtTips2")
		itemCache.txtTips3 = CS.FindTrans(item, "txtTips3")
		local list         = {}
		local list2        = {}
		for i = 1, 10 do
			list[i] = CS.FindTrans(item, "txtTips1/starRoot/star" .. i)
			list2[i] = CS.FindTrans(item, "txtTips1/starRoot/star" .. i .. "/gray")
		end
		itemCache.starList = list
		itemCache.starList2 = list2
		self:SetComponentCache(instanceID, itemCache)
	end

	local starNum = itemdata.rankNow
	local per = gModelDraconic:GetAttachTriggerRate(itemdata.type, starNum)
	self:SetWndText(itemCache.txtTips1, ccClientText(40900))
	self:SetWndText(itemCache.txtTips2, ccClientText(40901, per))

	local strTips3 = ""
	if self._mainStarNum == starNum then
		strTips3 = ccClientText(40902)
	end
	self:SetWndText(itemCache.txtTips3, strTips3)

	-- 星星
	local starMax = gModelDraconic:GetStarMax(itemdata.type)
	for i, obj in ipairs(itemCache.starList) do
		CS.ShowObject(itemCache.starList2[i], i <= starMax)
		CS.ShowObject(obj, i <= starMax)
	end

	if starNum > 0 then
		for i, obj in ipairs(itemCache.starList) do
			CS.ShowObject(itemCache.starList2[i], i > starNum)
		end
	end
end

-- tab item
function UIDraconicAttachTips:OnDrawTabItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			root   = item,
			btnTab = CS.FindTrans(item, "BtnTab1"),

		}
		self:SetComponentCache(instanceID, itemCache)
	end
	local size1 = -2
	local line = 0
	if self.jpj then
		size1 = -4
	end
	self:SetWndTabStatus(itemCache.btnTab, self._curTabIndex ~= itempos and 1 or 0)
	self:SetWndTabText(itemCache.btnTab, itemdata.tabName,size1,line)
	self:SetWndClick(itemCache.btnTab, function()
		if self._curTabIndex == itempos then
			return
		end
		self._curTabIndex = itempos
		list:DrawAllItems()
		self:Refresh()
	end)
end

-- 刷新星级列表
function UIDraconicAttachTips:RefreshStarList()
	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList

		local list = gModelDraconic:GetUpStarRefList(self._refId)
		local dataList = {}
		for k, v in pairs(list) do
			if k > 0 then
				dataList[k] = v
			end
		end
		uiList:Create(self.mList, dataList, function(...)
			self:OnDrawStarListItem(...)
		end, UIItemList.SUPER, true)
	end
end

-- 初始tab
function UIDraconicAttachTips:InitTab()
	local uilist = self:GetUIScroll("mTabScroll")
	uilist:Create(self.mTabScroll, TabDataList, function(...)
		self:OnDrawTabItem(...)
	end)
end

-- 初始界面化文本
function UIDraconicAttachTips:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(41097))
	self:SetWndText(self.mCloseTip, ccClientText(10103))
end

-- 刷新界面
function UIDraconicAttachTips:Refresh()
	CS.ShowObject(self.mView1, self._curTabIndex == 1)
	CS.ShowObject(self.mView2, self._curTabIndex == 2)

	-- 卡片
	local param = {
		refId = self._refId,
		showName = true,
	}
	gModelDraconic:DrawCard(self, self.mDraconicCard, param)

	if self._curTabIndex == 1 and not self._initView[self._curTabIndex] then
		local data = {}
		data.refId = self._refId
		data.txtTips = ccClientText(41088)
		self:DrawSkillTemplate(self.mSkill, data)
		LayoutRebuilder.ForceRebuildLayoutImmediate(self.mSkill)

		local bgH = self.mView1.rect.height
		local skilH = self.mSkill.rect.height
		local listH = bgH - skilH
		LxUiHelper.SetSizeWithCurAnchor(self.mList, 1, listH)
		LayoutRebuilder.ForceRebuildLayoutImmediate(self.mList)
		self.mList.anchoredPosition = Vector2(0, -skilH)

		self:RefreshStarList()
	elseif not self._initView[self._curTabIndex] then
		self:RefresList2()
	end
	self._initView[self._curTabIndex] = true
end

------------------------------------------------------------------
return UIDraconicAttachTips