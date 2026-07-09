---
--- Created by Administrator.
--- DateTime: 2023/10/8 16:43:19
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubVideoEntrance:LChildWnd
local UISubVideoEntrance = LxWndClass("UISubVideoEntrance", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubVideoEntrance:UISubVideoEntrance()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubVideoEntrance:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubVideoEntrance:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubVideoEntrance:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self:InitEvent()
	self:InitMessage()
	self:SetStaticContent()
	self._curType = gLGameLanguage:IsForeignRegion() and 2 or 1

	self:ShowTabList()

	self:RefreshContent()

	gModelOneNight:AddRecord("100001",3)
end
function UISubVideoEntrance:OnClickSkin(itemdata)
	GF.OpenWnd("UIMCitySnPreview",{refId = itemdata.refId})
end
function UISubVideoEntrance:MainCitySkinListItem(list,item,itemdata,itempos)
	local root = self:FindWndTrans(item,"Root")
	local image = self:FindWndTrans(root,"Image")
	local nameText = self:FindWndTrans(root,"NameText")
	local useTag = self:FindWndTrans(root,"UseTag")
	local useText = self:FindWndTrans(root,"UseTag/UseText")
	local maskLock = self:FindWndTrans(root,"MaskLock")
	local lockText = self:FindWndTrans(root,"MaskLock/LockText")
	local redPoint = self:FindWndTrans(root,"redPoint")

	local curSkin = gModelPlayer:GetMainCitySkin() or 1001
	local isAct = gModelPlayerSpace:GetMainCitySkinByRefId(itemdata.refId)
	local isUse = itemdata.refId == curSkin
	local itemStr = itemdata.item
	local free = itemdata.free or 0
	local haveItem = not string.isempty(itemStr)
	local isFree = free == 1 and haveItem
	local isItemA = false
	if not isAct and haveItem then
		local aItem = LxDataHelper.ParseItem_3(itemStr)
		local aBagNum = gModelItem:GetNumByRefId(aItem.itemId)
		isItemA = aBagNum >= aItem.itemNum
	end

	self:SetWndEasyImage(image,itemdata.icon)
	self:SetWndText(nameText,ccLngText(itemdata.name))
	CS.ShowObject(useTag,isUse or isFree)
	if isFree then
		self:SetWndText(useText,ccClientText(22860))
	elseif isUse then
		self:SetWndText(useText,ccClientText(30306))
	end

	local showMaskLock = not isAct and not isItemA and not isFree
	CS.ShowObject(maskLock,showMaskLock)
	if showMaskLock then
		self:SetWndText(lockText,ccClientText(30307))
	end
	CS.ShowObject(redPoint,isItemA)
	self:SetWndClick(root,function ()
		self:OnClickSkin(itemdata)
	end)
end

function UISubVideoEntrance:OpenMusic(itemdata)
	gModelOneNight:OnClickMusic(itemdata.refId)

	local uiList = self:FindUIScroll("musicList")
	if uiList then
		uiList:DrawAllItems(false)
	end

	GF.OpenWnd("UIHeartMusic",{itemdata = itemdata})
end

function UISubVideoEntrance:OpenVideo(itemdata)


	gModelOneNight:OnClickVideo(itemdata.refId)

	local uiList = self:FindUIScroll("videoList")
	if uiList then
		uiList:DrawAllItems(false)
	end

	if itemdata.download == 0 then
		GF.OpenWnd("UIHeartVdo",{itemdata= itemdata})
	else
		local isCached = gModelOneNight:IsVideoResCached(itemdata.videoRes)
		if isCached then
			GF.OpenWnd("UIHeartVdo",{itemdata= itemdata})
		else
			local size =string.format("%0.2f",itemdata.rom /1024)

			local para =
			{
				refId = 260001,
				para = {size},
				func = function()
					self:StartDownload(itemdata)
				end
			}

			gModelGeneral:OpenUIOrdinTips(para)
		end
	end


end

function UISubVideoEntrance:OnDrawFigure(list,item,itemdata,itempos)
    local AniRoot = self:FindWndTrans(item,"AniRoot")
    local AniRootIcon = self:FindWndTrans(AniRoot,"icon")
    local AniRootUIText = self:FindWndTrans(AniRoot,"UIText")
    local UITextImage = self:FindWndTrans(AniRootUIText,"Image")
    local AniRootTag = self:FindWndTrans(AniRoot,"tag")
    local AniRootNewTag = self:FindWndTrans(AniRoot,"newTag")



    local isUsingRefId = gModelOneNight:GetLoginFigure()
	local isShowTag = isUsingRefId == itemdata.refId
	CS.ShowObject(AniRootTag,isShowTag)
	if isShowTag then
		self:SetWndEasyImage(AniRootTag, "public_txt_16_1",nil, true)
	end

	self:SetWndText(AniRootUIText,ccLngText(itemdata.title))

	self:SetWndEasyImage(AniRootIcon,itemdata.res)

	self:SetWndClick(AniRoot,function ()
		self:OpenLoginRole(itemdata)
	end)

    local isOld = gModelOneNight:IsRecorded(itemdata.refId,3)

    CS.ShowObject(AniRootNewTag,not isOld)

end

function UISubVideoEntrance:StartDownload(itemdata)
	gModelOneNight:DownloadVideoRes(itemdata)
end

function UISubVideoEntrance:OpenLoginRole(itemdata)

	gModelOneNight:AddRecord(itemdata.refId,3)

	GF.OpenWnd("UIHeartPreview",{itemdata = itemdata})

	local list = self:FindUIScroll("figureList")
	if list then
		list:DrawAllItems(false)
	end
end


function UISubVideoEntrance:ShowVideoList()


	self:SetWndText(self.mTitle,ccClientText(26103))

	local dataList = gModelOneNight:GetVideoList()
	local videoList = self:FindUIScroll("videoList")
	if not videoList then
		videoList = self:GetUIScroll("videoList")
		videoList:Create(self.mVideoList,dataList,function (...) self:OnDrawVideo(...) end,UIItemList.SUPER_GRID)
		videoList:DrawAllItems(true)
	else
		videoList:RefreshList(dataList)
		videoList:DrawAllItems(false)
	end
end

function UISubVideoEntrance:SetStaticContent()
	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)
	local isMainSkin = gModelFunctionOpen:CheckIsOpened(21005004)
	local _typeDataList = {
		{
			name = ccClientText(26100),--"视频",
			type = 1,
			isShow = not gLGameLanguage:IsUSARegion(), --海外屏蔽一千零一夜录像
		},
		{
			name = ccClientText(26101),--"音乐",
			type = 2,
		},
		{
			name = ccClientText(26102),--"登录形象",
			type = 3,
		},
		{
			name = ccClientText(30300),--"主城皮肤",
			type = 4,
			isShow = isMainSkin,
		}
	}
	local list = {}
	for i, v in ipairs(_typeDataList) do
		table.insert(list,v)
	end
	self._typeDataList = list
	self:SetTextTile(self.mToggle,ccClientText(26113))
end


function UISubVideoEntrance:OnDrawType(list,item,itemdata,itempos)
	local isShow = itemdata.isShow ~= false
	if isShow == false then
		CS.ShowObject(item, false)
		return
	end
	local BtnTab = self:FindWndTrans(item,"BtnTab")

	self:SetWndTabText(BtnTab,itemdata.name)
	local isSel = self._curType == itemdata.type
	local state = isSel and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(BtnTab,state)
	self:SetWndTabTextLine(BtnTab, -30)
	self:SetWndClick(BtnTab,function ()
		self:OnClickType(itemdata.type)
	end)


end

function UISubVideoEntrance:RefreshContent()
	local _curType = self._curType
	CS.ShowObject(self.mVideoList,_curType == 1)
	CS.ShowObject(self.mMusicList,_curType == 2)
	CS.ShowObject(self.mFigureList,_curType == 3)
	CS.ShowObject(self.mMainCitySkinSuper,_curType == 4)

	CS.ShowObject(self.mToggle,_curType == 3)

	if _curType == 1 then
		self:ShowVideoList()
	elseif _curType == 2 then
		self:ShowMusicList()
	elseif _curType == 3 then
		self:ShowFigureList()
	elseif _curType == 4 then
		self:RefreshMainCitySkin()
	end
end

function UISubVideoEntrance:InitEvent()
	self:WndEventRecv(EventNames.REFRESH_THEME_USING,function (type)
		if type == self._curType then
			self:RefreshContent()
		end
	end)

	local isAuto = LPlayerPrefs.autoUseLoginRole == "1"
	self:SetWndToggleValue(self.mToggle,isAuto)

	self:SetWndToggleDelegate(self.mToggle,function (value)
		local v = value and "1" or "0"
		LPlayerPrefs.SetAutoUseLoginRole(v)
	end)
end

function UISubVideoEntrance:ShowTabList()

	local typeList = self:FindUIScroll("typeList")
	if not typeList then
		typeList = self:GetUIScroll("typeList")
		typeList:Create(self.mTypeList,self._typeDataList,function (...) self:OnDrawType(...) end)
	else
		typeList:RefreshList(self._typeDataList)
	end
end

function UISubVideoEntrance:OnDrawVideo(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootIcon = self:FindWndTrans(AniRoot,"icon")
	local AniRootLock = self:FindWndTrans(AniRoot,"lock")
	local lockImage = self:FindWndTrans(AniRootLock,"Image")
	local AniRootUIText = self:FindWndTrans(AniRoot,"UIText")
	local AniRootNewTag = self:FindWndTrans(AniRoot,"newTag")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")


	local isOpen = gModelFunctionOpen:CheckOpenCondition(itemdata.open)
	CS.ShowObject(AniRootLock,not isOpen)
	CS.ShowObject(AniRootImage,isOpen)

	local isOld = gModelOneNight:IsVideoPlayed(itemdata.refId)
	CS.ShowObject(AniRootNewTag,not isOld and isOpen)

	self:SetWndText(AniRootUIText,ccLngText(itemdata.title))
	self:SetWndEasyImage(AniRootIcon,itemdata.res)

	self:SetWndClick(AniRoot,function ()
		if not isOpen then
			GF.ShowMessage(ccLngText(itemdata.openDesc))
			return
		end

		self:OpenVideo(itemdata)
	end)

	CS.ShowObject(AniRootUIText,isOpen)
end

function UISubVideoEntrance:OnClickType(type)
	if self._curType == type then
		return
	end

	self._curType = type
	local typeList = self:FindUIScroll("typeList")
	if typeList then
		typeList:DrawAllItems(false)
	end

	self:RefreshContent()
end
function UISubVideoEntrance:RefreshMainCitySkin()
	self:SetWndText(self.mTitle,ccClientText(30300))

	local list = gModelPlayerSpace:GetOneNightSkinRef()
	local curSkin = gModelPlayer:GetMainCitySkin()
	table.sort(list,function (a,b)
		local aIsItemA = 0
		local bIsItemA = 0
		if not string.isempty(a.item) then
			local aItem = LxDataHelper.ParseItem_3(a.item)
			local aBagNum = gModelItem:GetNumByRefId(aItem.itemId)
			aIsItemA = aBagNum >= aItem.itemNum and 1 or 0
		end
		if not string.isempty(b.item) then
			local bItem = LxDataHelper.ParseItem_3(b.item)
			local bBagNum = gModelItem:GetNumByRefId(bItem.itemId)
			bIsItemA = bBagNum >= bItem.itemNum and 1 or 0
		end
		if aIsItemA ~= bIsItemA then
			return aIsItemA > bIsItemA
		end
		local aIsAct = gModelPlayerSpace:GetMainCitySkinByRefId(a.refId) and 1 or 0
		local bIsAct = gModelPlayerSpace:GetMainCitySkinByRefId(b.refId) and 1 or 0
		if aIsAct ~= bIsAct then
			return aIsAct > bIsAct
		end
		local aIsSkin = a.refId == curSkin and 1 or 0
		local bIsSkin = b.refId == curSkin and 1 or 0
		if aIsSkin ~= bIsSkin then
			return aIsSkin > bIsSkin
		end
		return a.range < b.range
	end)

	local _mainCitySkinList = self._mainCitySkinList
	if _mainCitySkinList then
		_mainCitySkinList:RefreshList(list)
		_mainCitySkinList:DrawAllItems()
	else
		_mainCitySkinList = self:GetUIScroll("_mainCitySkinList_UISubVideoEntrance")
		self._mainCitySkinList = _mainCitySkinList
		_mainCitySkinList:Create(self.mMainCitySkinSuper,list,function (...) self:MainCitySkinListItem(...) end,UIItemList.SUPER)
	end
end

function UISubVideoEntrance:ShowFigureList()
	self:SetWndText(self.mTitle,ccClientText(26105))
	local curRefId = gModelOneNight:GetLoginFigure()
	gModelOneNight:AddRecord(curRefId,3)


	local dataList = gModelOneNight:GetLoginRoleList()
	local figureList = self:FindUIScroll("figureList")
	if not figureList then
		figureList = self:GetUIScroll("figureList")
		figureList:Create(self.mFigureList,dataList,function (...) self:OnDrawFigure(...) end,UIItemList.SUPER_GRID)
		figureList:DrawAllItems(true)
	else
		figureList:RefreshList(dataList)
		figureList:DrawAllItems(false)
	end

end
function UISubVideoEntrance:InitMessage()
	self:WndNetMsgRecv(LProtoIds.MainCitySkinListResp,function(pb) self:RefreshMainCitySkin() end)
	self:WndNetMsgRecv(LProtoIds.MainCitySkinChangeResp,function(pb) self:RefreshMainCitySkin() end)
	self:WndNetMsgRecv(LProtoIds.ItemUseResp,function(pb) self:RefreshMainCitySkin() end)
end

function UISubVideoEntrance:OnDrawMusic(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootIcon = self:FindWndTrans(AniRoot,"icon")
	local AniRootLock = self:FindWndTrans(AniRoot,"lock")
	local lockImage = self:FindWndTrans(AniRootLock,"Image")
	local AniRootUIText = self:FindWndTrans(AniRoot,"UIText")
	local AniRootNewTag = self:FindWndTrans(AniRoot,"newTag")

	local isOld = gModelOneNight:IsMusicPlayed(itemdata.refId)
	CS.ShowObject(AniRootNewTag,not isOld)
	CS.ShowObject(AniRootLock,false)

	self:SetWndText(AniRootUIText,ccLngText(itemdata.title))
	self:SetWndEasyImage(AniRootIcon,itemdata.res)

	self:SetWndClick(AniRoot,function ()
		self:OpenMusic(itemdata)
	end)
end

function UISubVideoEntrance:ShowMusicList()
	self:SetWndText(self.mTitle,ccClientText(26104))

	local dataList = gModelOneNight:GetMusicList()
	local musicList = self:FindUIScroll("musicList")
	if not musicList then
		musicList = self:GetUIScroll("musicList")
		musicList:Create(self.mMusicList,dataList,function (...) self:OnDrawMusic(...) end,UIItemList.SUPER_GRID)
		musicList:DrawAllItems(true)
	else
		musicList:RefreshList(dataList)
		musicList:DrawAllItems(false)
	end

end
------------------------------------------------------------------
return UISubVideoEntrance


