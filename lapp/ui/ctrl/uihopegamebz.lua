---
--- Created by Administrator.
--- DateTime: 2024/4/25 15:04:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeGameBz:LWnd
local UIHopeGameBz = LxWndClass("UIHopeGameBz", LWnd)
------------------------------------------------------------------

local UIBtnTabList = LXImport('LApp.UI.Common.UIBtnTabList')

--- 图片
UIHopeGameBz.ICON_TYPE_PIC = 1

--- spine
UIHopeGameBz.ICON_TYPE_SP = 2


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeGameBz:UIHopeGameBz()
	---@type UIBtnTabList
	self._uiBtnTabList = nil

	self._page = 1
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeGameBz:OnWndClose()
	if self._uiBtnTabList then
		self._uiBtnTabList:Destroy()
		self._uiBtnTabList = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeGameBz:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeGameBz:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitText()
	self:InitData()
	self:InitEvent()
	self:RefreshView()
end

function UIHopeGameBz:InitData()
	local mapId = gModelFastDreamTrip:GetDreamTripMapId()
	self._mapName = gModelFastDreamTrip:GetMapRefNameByMapId(mapId)

	local playerLv = gModelPlayer:GetPlayerLv()
	local lvList = gModelFastDreamTrip:GetMapLevelListByMapId(mapId)
	local len = #lvList

	local curIdx
	for i,v in ipairs(lvList) do
		if playerLv >= v.levelMin and playerLv <= v.levelMax then
			curIdx = i
			break
		end
	end
	if not curIdx then curIdx = 1 end
	local isMax = curIdx == 1

	self._mapIsMax = isMax

	local tabBtnList = {}
	table.insert(tabBtnList,lvList[curIdx])
	if not isMax then
		local nextLv = curIdx - 1
		table.insert(tabBtnList,lvList[nextLv])
	end
	self._tabBtnList = tabBtnList

	local showRandom = false
	local list = {}
	for k,v in pairs(GameTable.SailingHelpRef) do
		if v.theme == mapId then
			showRandom = v.random == 1
			--- 纯展示，不用计算
			local cRewardList = LUtil.ConvertCommonItemStrToList(v.reward)
			local rewardList = {}
			for idx,val in ipairs(cRewardList) do
				table.insert(rewardList,{
					itemType = val.itemType,
					itemId = val.itemId,
					itemNum = val.itemNum,
					showRandom = showRandom,
					numStr = showRandom and ccClientText(41409)
				})
			end
			table.insert(list,{
				refId = k,
				map = mapId,
				level = v.level,
				res = v.res,
				resType = v.resType or UIHopeGameBz.ICON_TYPE_PIC,
				name = ccLngText(v.name),
				desc = ccLngText(v.description),
				showRandom = showRandom,
				rewardList = rewardList
			})
		end
	end
	self._eventList = list
end

function UIHopeGameBz:GetEventList()
	local pageData = self._tabBtnList[self._page]
	if not pageData then return {} end

	local maxLv
	local curMapLv = pageData.level
	local list = {}
	for i,v in ipairs(self._eventList) do
		if v.level == curMapLv then
			table.insert(list,v)
		end
		if not maxLv then
			maxLv = v.level
		elseif maxLv < v.level then
			maxLv = v.level
		end
	end
	if #list < 1 and maxLv then
		printInfoNR("没有在玩法手册找到对应等级的数据，使用玩法手册的最大等级：" .. maxLv)
		for i,v in ipairs(self._eventList) do
			if v.level == maxLv then
				table.insert(list,v)
			end
		end
	end
	table.sort(list,function(a, b) return a.refId < b.refId end)
	return list
end

function UIHopeGameBz:RefreshTabBtn()
	if not self._uiBtnTabList then return end
	self._uiBtnTabList:RefreshTabScroll()
end

function UIHopeGameBz:OnDrawItemCell(list,item,itemdata,itempos)
	local Icon = self:FindWndTrans(item,"CommonUI/Icon")
	local InstanceID = Icon:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	baseClass:Create(Icon)
	self:SetIconClickScale(Icon, true)
	baseClass:SetCommonReward(itemdata.itemType,itemdata.itemId,itemdata.itemNum)
	baseClass:SetItemNumStr(itemdata.numStr)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()
	self:SetWndClick(Icon,function()
		local showRandom = itemdata.showRandom
		local showNum = showRandom and -1 or itemdata.itemNum
		local itemData = {
			itemType = itemdata.itemType,
			itemId = itemdata.itemId,
			itemNum = showNum,
		}
		gModelGeneral:ShowCommonItemTipWnd(itemData)
	end)
end

function UIHopeGameBz:RefreshView()
	self:InitTabBtnList()
end

function UIHopeGameBz:OnDrawEventCell(list,item,itemdata,itempos)
	local spineRoot = self:FindWndTrans(item,"spineRoot")
	local iconRoot = self:FindWndTrans(item,"iconRoot")
	local name = self:FindWndTrans(item,"name")
	local desc = self:FindWndTrans(item,"DescDiv/desc")
	local itemList = self:FindWndTrans(item,"itemList")

	local resType = itemdata.resType
	local res = itemdata.res
	if resType == UIHopeGameBz.ICON_TYPE_PIC then
		self:SetWndEasyImage(iconRoot,res,function()
			CS.ShowObject(iconRoot,true)
		end,true)
	else
		self:CreateWndSpine(spineRoot,res,spineRoot:GetInstanceID())
	end

	self:SetWndText(name,itemdata.name)
	self:SetWndText(desc,itemdata.desc)
	self:InitItemList(itemList,itemdata.rewardList,itemdata.showRandom)
end

function UIHopeGameBz:InitEventList()
	local list = self:GetEventList()
	local uiList = self:FindUIScroll("EventList")
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("EventList")
		uiList:Create(self.mEventList,list,function(...) self:OnDrawEventCell(...) end)
	end
	uiList:EnableScroll(true,false)
end

function UIHopeGameBz:InitText()
	self:SetWndText(self.mDesc1,ccClientText(41406))
	self:SetWndText(self.mDesc2,ccClientText(41407))
	self:SetWndText(self.mDesc3,ccClientText(41408))
	self:SetWndText(self.mLblBiaoti,ccClientText(20401))
	if self.jpj then
		self:SetAnchorPos(self.mDesc3,Vector2.New(200,257))
	end
end

function UIHopeGameBz:SetLockDesc(str)
	self:SetWndText(self.mLockDesc,str)
end

function UIHopeGameBz:InitItemList(listTrans,list)
	local key = listTrans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(listTrans,list,function(...) self:OnDrawItemCell(...) end)
	end
	uiList:EnableScroll(#list > 1,true)
end

function UIHopeGameBz:ChangeTabPage()
	local pageData = self._tabBtnList[self._page]
	if not pageData then return end

	self:SetWndText(self.mLvTxt,string.replace(ccClientText(41400),self._mapName,pageData.level))
	--self:SetWndText(self.mPowerTxt,string.replace(ccClientText(41401),LUtil.NumberCoversion(pageData.recommend)))
	self:SetWndText(self.mPowerTxt,ccClientText(41416))

	local showLock = false
	if self._mapIsMax then
		showLock = true
		CS.ShowObject(self.mLockImg,false)
		self:SetLockDesc(ccClientText(41405))
	else
		showLock = self._page ~= 1
		if showLock then
			self:SetLockDesc(string.replace(ccClientText(41402),pageData.levelMin))
		end
		CS.ShowObject(self.mLockImg,true)
	end
	CS.ShowObject(self.mLockDiv,showLock)
	self:InitEventList()
end

function UIHopeGameBz:InitTabBtnList()
	self:ChangeTabPage()

	local showTabBtn = #self._tabBtnList > 1
	CS.ShowObject(self.mTabBtnList,showTabBtn)

	if not showTabBtn then return end

	local btnStrList = {
		ccClientText(41403),
		ccClientText(41404)
	}

	local btnLen = #btnStrList
	local btnName
	local dataList = {}
	for i,v in ipairs(self._tabBtnList) do
		btnName = btnStrList[i] or btnStrList[btnLen]
		table.insert(dataList,{
			btnType = i,
			btnName = btnName,
			clickFunc = function(itemdata)
				self._page = itemdata.btnType
				self:ChangeTabPage()
			end,
			specialReduceSize = -4,
		})
	end

	---@type UIBtnTabList
	self._uiBtnTabList = UIBtnTabList:New()
	self._uiBtnTabList:SetData(self,self.mTabBtnList,dataList,self._page)
end

function UIHopeGameBz:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end)
end

------------------------------------------------------------------
return UIHopeGameBz