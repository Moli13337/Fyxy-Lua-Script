---
--- Created by Administrator.
--- DateTime: 2023/10/23 18:11:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaBookRelation:LWnd
local UISagaBookRelation = LxWndClass("UISagaBookRelation", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaBookRelation:UISagaBookRelation()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaBookRelation:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaBookRelation:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaBookRelation:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()

	self:RefreshRelationListView(true)

end

function UISagaBookRelation:GetRelationList()
	local list = {}
	local serverList = gModelHeroBook:GetSortRelationInfoList()
	local refList = gModelHeroBook:GetHeroRelationRefList()
	for i, v in ipairs(serverList) do
		--[[        local data = v
                local refId = v.refId
                local refData = refList[refId]
                if refData then
                    local relationHeroKeyList = refData.relationHeroKeyList
                    local relationHeroList = refData.relationHeroList
                    data.relationHeroList = relationHeroList
                    data.relationHeroKeyList = relationHeroKeyList
                    data.listPrefabName = refData.listPrefabName
                    data.selfPrefabName = refData.selfPrefabName
                    data.bgList = refData.bgList
                    data.name = refData.name
                    data.rewardList = refData.rewardList
                    data.attrType = refData.attrType
                end
                table.insert(list,data)]]
		local data = table.clone(v)
		local refId = data.refId
		local refData = refList[refId]
		if refData then
			data.listPrefabName = refData.listPrefabName
			data.selfPrefabName = refData.selfPrefabName
			local relationHeroKeyList = refData.relationHeroKeyList
			local relationHeroList = refData.relationHeroList
			data.relationHeroList = relationHeroList
			data.relationHeroKeyList = relationHeroKeyList
			data.name = refData.name
			data.relationHeroNum = refData.relationHeroNum
		end
		table.insert(list, data)
	end
	return list
end

function UISagaBookRelation:RefreshRelationListView(needJump)
	if not self._selRelationRefId then
		self._selRelationRefId = 0
	end
	self:InitRelationList(needJump)
	--if self._page == ModelHeroBook.HEROJB_IDX then
	--	FireEvent(EventNames.ON_ENTER_HERO_CHAIN) --进入羁绊，触发指引
	--end
end

function UISagaBookRelation:InitMsg()
	self:WndNetMsgRecv(LProtoIds.RelationChangeInfoResp,function (...) self:RefreshRelationListView() end)
end

function UISagaBookRelation:InitRelationList(needJump)
	local list = self:GetRelationList()
	local uiRelationList = self._uiRelationList
	if uiRelationList then
		uiRelationList:RefreshData(list)
	else
		uiRelationList = self:GetUIScroll("uiRelationList")
		self._uiRelationList = uiRelationList
		uiRelationList:Create(self.mRelationList, list, function(...)
			self:OnDrawRelationCell(...)
		end, UIItemList.SUPER)
	end

	if needJump then
		local index = 0
		for i,v in ipairs(list) do
			local status = gModelHeroBook:CheckHeroRelationInfoStatusByRefId(v.refId)
			if status then
				index = i
				break
			end
		end

		if index ~= 0 then
			uiRelationList:MoveToPos(index - 1)
		end
	end
end

function UISagaBookRelation:SetHeroRelationNameAndNum(nameTrans,relationName,numTxtTrans,heroes,relationHeroList)
	self:SetWndText(nameTrans,relationName)
	heroes = heroes or {}
	local curHeroNum = #heroes
	relationHeroList = relationHeroList or {}
	local allHeroNum = relationHeroList
	local str = string.format("(%s/%s)",curHeroNum,allHeroNum)
	self:SetWndText(numTxtTrans,str)
end

function UISagaBookRelation:ClickRelationCard(key, init)
	local serverData = gModelHeroBook:GetRelationInfoByRefId(key)
	if serverData then
		local status = gModelHeroBook:CheckHeroRelationInfoStatusByRefId(key)
		local haveRed = status and 1 or 0
		local actNum = #serverData.heroes
		gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"2-2-1",key,actNum,haveRed)
	end

	GF.OpenWndUp("UISagaBookRelationSy",{ RefId = key })
end

function UISagaBookRelation:CreateRelationItem(trans, key, itemdata)
	local relationHeroKeyList = itemdata.relationHeroKeyList
	local heroesKey = itemdata.heroesKey
	--服务器数据没有下来
	if relationHeroKeyList then
		for k, v in pairs(relationHeroKeyList) do
			local heroTrans = self:FindWndTrans(trans, v)
			local isGray = not heroesKey[v]
			self:SetWndImageGray(heroTrans, isGray)
		end
	end
	local redPoint = self:FindWndTrans(trans,"redPoint")
	if redPoint then
		local status = gModelHeroBook:CheckHeroRelationInfoStatusByRefId(key)
		CS.ShowObject(redPoint,status)
	end
	local HeroBookName2Trans = self:FindWndTrans(trans,"HeroBookName2")
	if HeroBookName2Trans then
		local NameTxt = self:FindWndTrans(HeroBookName2Trans,"NameTxt")
		local NumTxt = self:FindWndTrans(HeroBookName2Trans,"NumTxt")
		self:SetHeroRelationNameAndNum(NameTxt,ccLngText(itemdata.name),NumTxt,itemdata.heroes,itemdata.relationHeroNum)
	end
	self:SetWndClick(trans, function()
		self:ClickRelationCard(key, true)
	end)
end


function UISagaBookRelation:InitText()
	self:SetWndText(self.mAddBtnTxt, ccClientText(19747))
	self:SetWndText(self.mReturnTxt,ccClientText(30205))
end


function UISagaBookRelation:InitEvent()
	self:SetWndClick(self.mHelpBtn,function()
		GF.OpenWndUp("UIBzTips",{refId = 82})
	end)

	self:SetWndClick(self.mReturnBtn,function()
		self:WndClose()
	end)

	self:SetWndClick(self.mAddBtn,function()
		gModelHeroBook:OpenRelationHeroAddAttrWnd()
	end)

end

function UISagaBookRelation:OnDrawRelationCell(list, item, itemdata, itempos)
	local Root = self:FindWndTrans(item, "Root")
	if Root then
		local key = itemdata.refId
		local listPrefabName = itemdata.listPrefabName
		if not listPrefabName then
			listPrefabName = "TestRelationIcon"
		end
		LxResUtil.DestroyChildImmediate(Root)
		self:CreateWndPrefab(Root, listPrefabName, key, function(prefabTrans)
			local width = prefabTrans.sizeDelta.x
			local height = prefabTrans.sizeDelta.y + 20
			LxUiHelper.SetSizeWithCurAnchor(item, 0, width)
			LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
			LxUiHelper.SetSizeWithCurAnchor(Root, 0, width)
			LxUiHelper.SetSizeWithCurAnchor(Root, 1, height)
			self:CreateRelationItem(prefabTrans, key, itemdata)

			self:SendGuideReadyEvent(self:GetWndName())
		end, CS.RES_UI_HEROBOOK1)
	end
end


------------------------------------------------------------------
return UISagaBookRelation


