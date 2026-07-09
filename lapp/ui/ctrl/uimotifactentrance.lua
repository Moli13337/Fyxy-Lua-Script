---
--- Created by BY.
--- DateTime: 2023/10/30 18:23:19
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMotifActEntrance:LWnd
local UIMotifActEntrance = LxWndClass("UIMotifActEntrance", LWnd)

UIMotifActEntrance.ACTIVITY_TYPE_SECTION = 1				--时间区间
UIMotifActEntrance.ACTIVITY_TYPE_SERVICE = 2				--开服时间
UIMotifActEntrance.ACTIVITY_TYPE_REGISTER = 3				--注册时间
UIMotifActEntrance.ACTIVITY_TYPE_FOREVER = 4				--永久有效


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMotifActEntrance:UIMotifActEntrance()
	self._timeKey = "UIMotifActEntrance_timeKey"
	self._entryList = {}
	self._imgList = {}
	self._spineNameList = {}
	self._tweenKey = "_tweenKey"
	self._timeList = {}
	self._redTrList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMotifActEntrance:OnWndClose()
	if self._itemPool then
		self._itemPool:Destroy()
		self._itemPool = nil
	end
	if self._itemMapPool then
		self._itemMapPool:Destroy()
		self._itemMapPool = nil
	end
	if not string.isempty(self._dataMusicName) then
		gLGameAudio:OnCloseWndMusic(self:GetWndName())
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMotifActEntrance:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMotifActEntrance:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
-----------------------------对象池-------------------------------------

-----------------------------计时器-------------------------------------
function UIMotifActEntrance:OnTimer(key)
	if(key == self._timeKey)then
		self:SetTime()
		self:SetItemTime()
	end
end

function UIMotifActEntrance:OnActivityConfigData()
	local _sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(_sid)
	if not activityData then return end
	local data = activityData.config
	local signImage,headline,headlinePos,signHelpTips,signHelpTipsPos,timePos,themeType,themelistPos,themelistScope
	= data.signImage,data.headline,data.headlinePos,data.signHelpTips,data.signHelpTipsPos,data.timePos,data.themeType,data.themelistPos,data.themelistScope
	local bgAdjustPara,timeTxt,timeTxtPos,headline2,headlinePos2,closeBtn,closeText
	= data.bgAdjustPara,data.timeTxt,data.timeTxtPos,data.headline2,data.headlinePos2,data.closeBtn,data.closeText
	local bottomImg,templateTimeShow,bottomImg2,bgAnchorType
	= data.bottomImg,data.templateTimeShow,data.bottomImg2,data.bgAnchorType
	self._title = gModelActivity:GetLngNameByActivitySid(_sid)
	self._signHelpTips = signHelpTips
	self._themeType = themeType
	self._pageConfig = data
	if not string.isempty(closeBtn) then
		local paint
		local arr = string.split(closeBtn,"=")
		local anchorType = tonumber(arr[1]) or 0
		local imgStr = arr[2]
		local posStr = arr[3]
		if not posStr then
			posStr = arr[2]
			imgStr = arr[1]
			anchorType = 5
		end
		if LxUiHelper.IsImgPathValid(imgStr) then
			paint = self.mBtnClose
			self:SetWndEasyImage(paint,imgStr,function ()
				CS.ShowObject(paint,true)
			end ,true)
		end
		if anchorType >= 1 and anchorType <= 9 and paint then
			local anchorV = self._anchors[anchorType]
			self:SetTrAnchors(paint,anchorV)
		end
		if not string.isempty(posStr) and paint then
			local pos = LxDataHelper.ParseVector2NotEmpty3(posStr)
			self:SetAnchorPos(paint, pos)
		end
	else
		CS.ShowObject(self.mBtnClose,true)
	end
	if not string.isempty(closeText) then
		local paint = self.mCloseText
		local arr = string.split(closeText,"=")
		local text = arr[1]
		local posStr = arr[2]
		self:SetWndText(paint,text)
		CS.ShowObject(paint,true)
		if not string.isempty(posStr)then
			local pos = LxDataHelper.ParseVector2NotEmpty3(posStr)
			self:SetAnchorPos(paint, pos)
		end
	end
	if not string.isempty(signImage) then
		if themeType == 2 or themeType == 3 then
			local arr = string.split(signImage,"|")
			local dis = 0
			local wh = 0
			for i, v in ipairs(arr) do
				local img = self:GetImgItemNew(i)
				local oldDis = dis
				if themeType == 2 then
					self:SetWndEasyImage(img,v,function ()
						img.sizeDelta = Vector2.New(640,1400)
						self:SetTrAnchors(img,Vector2.New(0,0.5))
						self:SetAnchorPos(img, Vector2.New(oldDis,0))
					end)
					dis = dis + 640
					if wh < img.sizeDelta.y then
						wh = img.sizeDelta.y
					end
					if wh < img.sizeDelta.x then
						wh = img.sizeDelta.x
					end
				elseif themeType == 3 then
					self:SetWndEasyImage(img,v,function ()
						self:SetTrAnchors(img,Vector2.New(0.5,1))
						self:SetAnchorPos(img, Vector2.New(0,-oldDis))
					end ,true)
					dis = dis + img.sizeDelta.y
					if wh < img.sizeDelta.x then
						wh = img.sizeDelta.x
					end
				end
			end
			local sizeX = themeType == 2 and dis or wh
			local sizeY = themeType == 3 and dis or wh
			self.mEntranceMag.sizeDelta = Vector2.New(sizeX,sizeY)
			local v2 = themeType == 2 and Vector2.New(0,0.5) or Vector2.New(0.5,1)
			if LOG_INFO_ENABLED then
				printInfoN("[UIMotifActEntrance]map mEntranceMag v2 "..tostring(v2))
			end
			self:SetTrAnchors(self.mEntranceMag,v2)
			self:InitDragData(dis)
		elseif LxUiHelper.IsImgPathValid(signImage) then
			local paint = self.mBgImage
			CS.ShowObject(paint,true)
			local isNativeSize = false
			if themeType == 1 and not string.isempty(bgAdjustPara)then
				isNativeSize = true
				local arr = string.split(bgAdjustPara,"=")
				paint.localScale = Vector2.New(tonumber(arr[1]),tonumber(arr[1]))
				local pos = LxDataHelper.ParseVector2NotEmpty3(arr[2])
				self:SetAnchorPos(paint, pos)
				self:SetWndEasyImage(paint,signImage,nil,isNativeSize)
			else
				self:SetWndEasyImage(paint,signImage)
			end
			if not string.isempty(bgAnchorType)then
				local anchorType = tonumber(bgAnchorType)
				if anchorType >= 1 and anchorType <= 9 then
					local anchorV = self._anchors[anchorType]
					self:SetTrAnchors(paint,anchorV)
				end
			end
		end
	end

	if LxUiHelper.IsImgPathValid(headline) then
		local trans = self.mTitleImg
		CS.ShowObject(trans,true)
		self:SetWndEasyImage(trans,headline,nil,true)
		if not string.isempty(headlinePos) then
			local pos = LxDataHelper.ParseVector2NotEmpty3(headlinePos)
			self:SetAnchorPos(trans, pos)
		end
	end
	if LxUiHelper.IsImgPathValid(headline2) then
		local trans = self.mTitleImg2
		CS.ShowObject(trans,true)
		self:SetWndEasyImage(trans,headline2,nil,true)
		if not string.isempty(headlinePos2) then
			local pos = LxDataHelper.ParseVector2NotEmpty3(headlinePos2)
			self:SetAnchorPos(trans, pos)
		end
	end
	if not string.isempty(signHelpTips) then
		local trans = self.mBtnHelp
		CS.ShowObject(trans,true)
		if not string.isempty(signHelpTipsPos) then
			local pos = LxDataHelper.ParseVector2NotEmpty3(signHelpTipsPos)
			self:SetAnchorPos(trans, pos)
		end
	end
	if not string.isempty(timePos) then
		local pos = LxDataHelper.ParseVector2NotEmpty3(timePos)
		self:SetAnchorPos(self.mTimeBg, pos)
	end
	if not string.isempty(templateTimeShow)then
		if tonumber(templateTimeShow) == -1 then
			CS.ShowObject(self.mTimeBg,false)
			self._templateTimeShow = tonumber(templateTimeShow)
		end
	end
	if not string.isempty(data.music) then
		if gLGameAudio then
			self._dataMusicName = data.music
			gLGameAudio:OnPlayWndMusic(data.music,self:GetWndName())
		end
	end

	if not string.isempty(timeTxt) then
		CS.ShowObject(self.mTimeBg2,true)
		self:SetWndText(self.mTimeText2,timeTxt)
		if not string.isempty(timeTxtPos) then
			local pos = LxDataHelper.ParseVector2NotEmpty3(timeTxtPos)
			self:SetAnchorPos(self.mTimeBg2, pos)
		end
	end

	CS.ShowObject(self.mEntranceMag,themeType <= 3)
	CS.ShowObject(self.mEntryListH,themeType == 4)
	CS.ShowObject(self.mEntryListW,themeType == 5)
	if themeType > 3 then
		local mEntryList = themeType == 5 and self.mEntryListW or self.mEntryListH
		if not string.isempty(themelistPos) then
			local pos = LxDataHelper.ParseVector2NotEmpty3(themelistPos)
			self:SetAnchorPos(mEntryList, pos)
		end
		if not string.isempty(themelistScope) then
			local arr = string.split(themelistScope,";")
			local a1,a2 = tonumber(arr[1]),tonumber(arr[2])
			mEntryList.sizeDelta = Vector2.New(a1,a2)
			--self.mItemRootH.sizeDelta = Vector2.New(a1,a2)
			--self.mItemRootW.sizeDelta = Vector2.New(a1,a2)
		end
	end
	if not string.isempty(bottomImg) then
		local arr = string.split(bottomImg,"=")
		if LxUiHelper.IsImgPathValid(arr[1]) then
			local img = self.mBottomImg
			self:SetWndEasyImage(img,arr[1],function ()
				CS.ShowObject(img,true)
				if not string.isempty(arr[2]) then
					local sizeV2 = LxDataHelper.ParseVector2NotEmpty(arr[2])
					img.sizeDelta = sizeV2
				end
				if not string.isempty(arr[3]) then
					local pos = LxDataHelper.ParseVector2NotEmpty(arr[3])
					self:SetAnchorPos(img, pos)
				end
				local anchorType = arr[4] and tonumber(arr[4]) or 0
				if anchorType >= 1 and anchorType <= 9 then
					local anchorV = self._anchors[anchorType]
					self:SetTrAnchors(img,anchorV)
				end
			end)
		end
	end
	if not string.isempty(bottomImg2) then
		local arr = string.split(bottomImg2,"=")
		if LxUiHelper.IsImgPathValid(arr[1]) then
			local img = self.mBottomImg2
			self:SetWndEasyImage(img,arr[1],function ()
				CS.ShowObject(img,true)
				if not string.isempty(arr[2]) then
					local sizeV2 = LxDataHelper.ParseVector2NotEmpty(arr[2])
					img.sizeDelta = sizeV2
				end
				if not string.isempty(arr[3]) then
					local pos = LxDataHelper.ParseVector2NotEmpty(arr[3])
					self:SetAnchorPos(img, pos)
				end
				local anchorType = arr[4] and tonumber(arr[4]) or 0
				if anchorType >= 1 and anchorType <= 9 then
					local anchorV = self._anchors[anchorType]
					self:SetTrAnchors(img,anchorV)
				end
			end)
		end
	end

	gModelActivity:OnActivityPageReq(_sid)

	self:SetSpine()
end
-----------------------------点击事件-------------------------------------

-----------------------------对象池-------------------------------------
function UIMotifActEntrance:GetItemNew(entryId,root)
	local itemNew = self._entryList[entryId]
	if itemNew then return itemNew end
	itemNew = self._itemPool:GetObj()
	local itemRoot = root or self.mEntranceMag
	itemNew.transform:SetParent(itemRoot.transform, false)
	CS.ShowObject(itemNew,true)
	self._entryList[entryId] = itemNew
	return itemNew
end

function UIMotifActEntrance:ListItem(list,item,itemdata,itempos)
	local entryCfg = itemdata.entryCfg

	local instanceID = item:GetInstanceID()
	local root = self:GetItemNew(instanceID,item)

	--local root = self:FindWndTrans(item,"EntryItem")
	local templateScope = entryCfg.templateScope
	if not string.isempty(templateScope) then
		local size = string.split(templateScope,";")
		LxUiHelper.SetSizeWithCurAnchor(item,1,tonumber(size[2]))
		LxUiHelper.SetSizeWithCurAnchor(item,2,tonumber(size[1]))
		if root then
			LxUiHelper.SetSizeWithCurAnchor(root,1,tonumber(size[2]))
			LxUiHelper.SetSizeWithCurAnchor(root,2,tonumber(size[1]))
		end
	end

	self:SetEntryItem(root,itemdata,entryCfg)
end

function UIMotifActEntrance:OnTryTcpReconnect()
	self:WndClose()
end

function UIMotifActEntrance:RefreshReplayBtn()
	CS.ShowObject(self.mReplayBtn,false)
	local actdata = gModelActivity:GetActivityBySid(self._sid)
	if not actdata then
		return
	end
	local moreInfo = JSON.decode(actdata.moreInfo)
	if not moreInfo then
		return
	end

	local video = moreInfo.video
	if string.isempty(video) then
		return
	end

	local temps = string.split(video,"=")
	local pos = LxDataHelper.ParseVector2(temps[3])

	CS.ShowObject(self.mReplayBtn,true)
	self:SetAnchorPos(self.mReplayBtn,pos)
end
function UIMotifActEntrance:SetTime()
	local _timeKey = self._timeKey
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	local endTime = activityData.endTime
	if endTime <= 0 then
		self:TimerStop(_timeKey)
		self:SetWndText(self.mTimeText,ccClientText(18404))
		CS.ShowObject(self.mTimeBg,true)
		return
	end
	local time = GetTimestamp()
	local timespan = endTime - time
	local  timeStr = ""
	if(timespan < 0)then
		timeStr = ccClientText(14301)
		self:TimerStop(_timeKey)
	else
		local _enterTime = self._enterTime
		local timeF = _enterTime and _enterTime or ccClientText(18400)
		timeStr = LUtil.FormatTimespanCn(timespan)
		timeStr = string.replace(timeF,timeStr)
	end
	self:SetWndText(self.mTimeText,timeStr)
	CS.ShowObject(self.mTimeBg,true)
end
-----------------------------计时器-------------------------------------

-----------------------------拖动-------------------------------------
function UIMotifActEntrance:InitDragData(max)
	self._max = max
	self:InitDrag()
end
function UIMotifActEntrance:RefreshData()
	local _themeType = self._themeType
	local _pages = self._pages
	local _sid = self._sid
	if not _pages or not _themeType then
		return
	end
	local activityData = gModelActivity:GetActivityBySid(_sid)
	if not activityData then
		self:WndClose()
		return
	end
	local moreInfo = JSON.decode(activityData.moreInfo)
	local openList = moreInfo.openList or {}
	local _openList = {}
	for i, v in ipairs(openList) do
		local templateId = tonumber(v[1])
		_openList[templateId] = v
	end
	self._openList = _openList

	local pageData = _pages[1]
	if not pageData then
		self:WndClose()
		return
	end
	local entry = pageData.entry
	local list = {}
	for i, v in ipairs(entry) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(_sid,v.pageId,v.entryId)
		v.entryCfg = entryCfg
		table.insert(list,v)
	end

	if _themeType <= 3 then
		for i, v in ipairs(entry) do
			local item = self:GetItemNew(v.entryId)
			local entryCfg = v.entryCfg
			local templateCoord = entryCfg.templateCoord
			local templateScope = entryCfg.templateScope
			if not string.isempty(templateCoord) then
				local pos = LxDataHelper.ParseVector2NotEmpty3(templateCoord)
				self:SetAnchorPos(item, pos)
			end
			if not string.isempty(templateScope) then
				local size = string.split(templateScope,";")
				item.sizeDelta = Vector2.New(tonumber(size[1]),tonumber(size[2]))
			end
			self:SetEntryItem(item,v,entryCfg)
		end
		if not self._isOneMove and (_themeType == 2 or _themeType == 3) then
			self._isOneMove = true
			local iEntry,sTime = nil,0
			for i, v in ipairs(list) do
				local templateId = v.entryCfg.templateId
				local openData = _openList[templateId]
				if openData then
					local type = tonumber(openData[2])
					if type ~= UIMotifActEntrance.ACTIVITY_TYPE_FOREVER then
						local time = GetTimestamp()
						local startTime = tonumber(openData[3])
						local endTime = tonumber(openData[4])
						if startTime <= time and time <= endTime and sTime < startTime then
							sTime = startTime
							iEntry = v
						end
					elseif not iEntry then
						iEntry = v
					end
				end
			end
			if iEntry then
				local entryCfg = iEntry.entryCfg
				local templateCoord = entryCfg.templateCoord
				local pos = LxDataHelper.ParseVector2NotEmpty3(templateCoord)
				local initPos,entryPos = Vector2(0,0),Vector2(0,0)
				local popW,popH = self._W,self._H
				local entW,entH = self.mEntranceMag.rect.width,self.mEntranceMag.rect.height
				if _themeType == 2 then
					local x = - entW/2 - pos.x

					if x < - (entW/2 + popW/2) then
						x = - (entW/2 + popW/2)
					elseif x > - popW/2 then
						x = - popW/2
					end
					entryPos = Vector2.New(x,0)
				elseif _themeType == 3 then
					local y = - entH/2 - pos.y

					if y < - (popH/2 + entH/2) then
						y = - (popH/2 + entH/2)
					elseif y > - entH/2 then
						y = - entH/2
					end
					entryPos = Vector2.New(0,y)
				end
				self:SetToweenMove(initPos,entryPos)
			end
		end
	else
		if not self._isOneMove then
			self._isOneMove = true
			table.sort(list,function (a,b)
				local aTemplateId = a.entryCfg.templateId
				local bTemplateId = b.entryCfg.templateId
				local aOpenData = _openList[aTemplateId]
				local bOpenData = _openList[bTemplateId]
				local aBOpen = aOpenData and 1 or 0
				local bBOpen = bOpenData and 1 or 0
				if aBOpen ~= bBOpen then
					return aBOpen > bBOpen
				end
				if aOpenData and bOpenData then
					local aType = tonumber(aOpenData[2])
					local bType = tonumber(bOpenData[2])
					if aType ~= UIMotifActEntrance.ACTIVITY_TYPE_FOREVER or bType ~= UIMotifActEntrance.ACTIVITY_TYPE_FOREVER then
						local time = GetTimestamp()
						local aStartTime = tonumber(aOpenData[3])
						local bStartTime = tonumber(bOpenData[3])
						local aEndTime = tonumber(aOpenData[4])
						local bEndTime = tonumber(bOpenData[4])
						local aIsOpen = (aStartTime <= time and time <= aEndTime) and 1 or 0
						local bIsOpen = (bStartTime <= time and time <= bEndTime) and 1 or 0
						if aIsOpen ~= bIsOpen then
							return aIsOpen > bIsOpen
						end
						return aStartTime > bStartTime
					end
				end
				return a.entryId < b.entryId
			end)
		end
		local _uiList = self._uiList
		if _uiList then
			_uiList:RefreshList(list)
		else
			local mEntryList = _themeType == 5 and self.mEntryListW or self.mEntryListH
			_uiList = self:GetUIScroll("mEntryList_UIMotifActEntrance")
			_uiList:Create(mEntryList,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
			self._uiList = _uiList
			_uiList:EnableScroll(true,_themeType == 5)
		end
		_uiList:DrawAllItems()
	end
end

function UIMotifActEntrance:ResetData(pb)
	local _pages = self._pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		_pages[page.pageId] = page
	end
	self._pages = _pages


	self:RefreshData()
end
--设置立绘
function UIMotifActEntrance:SetSpine()
	local LH = self._pageConfig.LH
	local LHOverturn = self._pageConfig.LHOverturn == 1
	local LHPos = self._pageConfig.LHPos

	local isHaveSpine = not string.isempty(LH)

	if isHaveSpine then
		CS.ShowObject(self.mLiHui_2, true)

		local spinekey = self.mLiHui_2:GetInstanceID()
		local spine = self:FindWndSpineByKey(spinekey)

		if not spine then
			self:CreateWndSpine(self.mLiHui_2, LH, spinekey, false, function(dpSpine)
				--dpSpine:PlayAnimationSolid("animation", true)
			end)
		else

		end

		local x_OverTurn = LHOverturn and -1 or 1

		self.mLiHui_2.localScale = Vector2(x_OverTurn, 1)
		local pos = string.split(LHPos, ",")
		self.mLiHui_2.localPosition = Vector2.New(tonumber(pos[1]), tonumber(pos[2]))
	end
end

-----------------------------方法-------------------------------------

-----------------------------方法-------------------------------------

-----------------------------点击事件-------------------------------------
function UIMotifActEntrance:OnClickHelp()
	local content = self._signHelpTips or ""
	local title = self._title or ""
	GF.OpenWnd("UIBzTips",{title = title,text = content})
end
function UIMotifActEntrance:InitCommand()
	--self:SetWndText(self.mCloseText,ccClientText(30205))
	self._anchors = {
		[1] = Vector2(0,1),
		[2] = Vector2(0.5,1),
		[3] = Vector2(1,1),
		[4] = Vector2(0,0.5),
		[5] = Vector2(0.5,0.5),
		[6] = Vector2(1,0.5),
		[7] = Vector2(0,0),
		[8] = Vector2(0.5,0),
		[9] = Vector2(1,0),
	}
	local _sid = self:GetWndArg("sid")
	if not _sid then
		local uniqueJump = self:GetWndArg("subPage")
		_sid = gModelActivity:GetSidByUniqueJump(uniqueJump)
	end
	if not _sid then
		local dataList = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_ACTIVITY_TYPE_85)
		if dataList[1] then
			_sid = dataList[1].sid
		end
	end
	if not _sid then
		self:WndClose()
		return
	end
	self._sid = _sid


	self:RefreshReplayBtn()
	local isPlay = self:PlayVideo()

	CS.ShowObject(self.mAniRoot,not isPlay)

	local itempool = UIObjPool:New()
	itempool:Create(self.mTemplates,self.mEntryItem)
	self._itemPool = itempool
	local itemMappool = UIObjPool:New()
	itemMappool:Create(self.mTemplates,self.mMapImg)
	self._itemMapPool = itemMappool

	self._W,self._H = self.mPop.rect.width,self.mPop.rect.height
	gModelActivity:ReqActivityConfigData(_sid)
end
function UIMotifActEntrance:InitEvent()
	--self:SetWndClick(self.mBg, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose2, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end,LSoundConst.CLICK_ERROR_COMMON)

	self:SetWndClick(self.mReplayBtn,function () self:PlayVideo(true) end)
end

function UIMotifActEntrance:OpenAwakeSkill(para)
	local numList = LxDataHelper.ParseNumber_Sign(para,',')

	gModelHeroExtra:OpenHeroTreeSkillPreviewWnd({heroTreePointLvList = numList,})
end

function UIMotifActEntrance:PlayVideo(isClick)
	local actdata = gModelActivity:GetActivityBySid(self._sid)
	if not actdata then
		return
	end
	local moreInfo = JSON.decode(actdata.moreInfo)
	if not moreInfo then
		return
	end

	local video = moreInfo.video
	if string.isempty(video) then
		return
	end

	if not isClick then
		local lookVideo = moreInfo.lookVideo
		if lookVideo and tonumber(lookVideo) == 1 then
			return
		end
	end

	GF.OpenUIGue("UIActVdoPy",{sid = self._sid,video = video,isNotLook = self:IsNotLooked()})
	return true
end
function UIMotifActEntrance:UIDragOnDrag(dragKey,eventData)
	if dragKey ~= "EntranceMag" then return end
	local initW = self._W or 640
	local initH = self._H or 1136
	local trans = self.mEntranceMag
	local _themeType = self._themeType
	if not _themeType then return end
	local _max = self._max or 1280
	local pos = trans.anchoredPosition
	local mX,mY = 0,0
	if _themeType == 2 and _max > initW then
		_max = _max - initW
		mX = pos.x
		if pos.x <= -_max then
			mX = -_max
		elseif pos.x >= 0 then
			mX = 0
		end
	elseif _themeType == 3 and _max > initH then
		_max = _max - initH
		mY = pos.y
		if pos.y <= 0 then
			mY = 0
		elseif pos.y >= _max then
			mY = _max
		end
	end
	trans.anchoredPosition = Vector2.New(mX, mY)
end
function UIMotifActEntrance:InitDrag()--拖动
	self:UIDragSetItem("EntranceMag","AniRoot/Pop/EntranceMag",CS.YXUIDrag.DragMode.DragOrigin)
end

---活动入口视频
function UIMotifActEntrance:IsNotLooked()
	local actdata = gModelActivity:GetActivityBySid(self._sid)
	if not actdata then
		return
	end
	local moreInfo = JSON.decode(actdata.moreInfo)
	if not moreInfo then
		return
	end
	local lookVideo = moreInfo.lookVideo
	return lookVideo and tonumber(lookVideo) == 0
end

function UIMotifActEntrance:SetStaticContent()
	local str = ccClientText(38100)
	self:SetTextTile(self.mReplayBtn,str)
end
-----------------------------拖动-------------------------------------

function UIMotifActEntrance:SetToweenMove(initPos,endPos)
	local key = self._tweenKey
	local transs = self.mEntranceMag
	local seqTween
	self:TweenSeqKill(key)
	if not seqTween then
		seqTween = self:TweenSeqCreate(key,function(seq)
			local moveTween = transs:DOLocalMove(endPos,0.7)
			seq:Append(moveTween)
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(key)
	end)
end
function UIMotifActEntrance:GetImgItemNew(id)
	local itemNew = self._imgList[id]
	if itemNew then return itemNew end
	itemNew = self._itemMapPool:GetObj()
	local itemRoot = self.mEntranceMag
	itemNew.transform:SetParent(itemRoot.transform, false)
	CS.ShowObject(itemNew,true)
	self._imgList[id] = itemNew
	return itemNew
end
function UIMotifActEntrance:RefreshTime()
	if self._templateTimeShow == -1 then return end
	local _sid = self._sid
	local _timeKey = self._timeKey
	local activityDatas = gModelActivity:GetActivityBySid(_sid)
	if not activityDatas then
		self:WndClose()
		return
	end
	local _endTime = activityDatas.endTime
	if(_endTime and _endTime > 0)then
		self:TimerStop(_timeKey)
		self:TimerStart(_timeKey,1,false,-1)
		self:SetTime()
	end
end
function UIMotifActEntrance:InitMessage()

	self:WndEventRecv(EventNames.ACT_VIDEO_PLAY_START,function ()
		CS.ShowObject(self.mAniRoot,true)
	end)

	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
		self:RefreshTime()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
		--local activity = pb.activity
		--if activity.sid ~= self._sid then return end
		self:RefreshTime()
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)
		--local activities = pb.activities
		--for i, v in ipairs(activities) do
		--	if v.sid == self._sid then
		self:RefreshTime()
		self:RefreshData()
		--		return
		--	end
		--end
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...)
		local sid = self._sid
		local redTrList = self._redTrList or {}
		for i, v in pairs(redTrList) do
			for j, k in pairs(v) do
				local isRed = gModelRedPoint:GetActivityRedPointPageEntry(sid,i,j)
				CS.ShowObject(k,isRed)
			end
		end
	end)

	self:WndEventRecv(EventNames.ON_ACT_PAGE_RED_CHANGE, function()
		local sid = self._sid
		local redTrList = self._redTrList or {}
		for i, v in pairs(redTrList) do
			for j, k in pairs(v) do
				local isRed = gModelRedPoint:GetActivityRedPointPageEntry(sid,i,j)
				CS.ShowObject(k,isRed)
			end
		end
	end)



end
function UIMotifActEntrance:SetEntryItem(item,itemdata,entryCfg)
	local _sid = self._sid
	if not item or not itemdata then return end
	CS.ShowObject(item,true)
	local icon1 = self:FindWndTrans(item,"Icon1")
	local icon2 = self:FindWndTrans(item,"Icon2")
	local icon3 = self:FindWndTrans(item,"Icon3")
	local icon4 = self:FindWndTrans(item,"Icon4")
	local icon5 = self:FindWndTrans(item,"Icon5")
	local spine = self:FindWndTrans(item,"Spine")
	local textImg = self:FindWndTrans(item,"TextImg")
	local nameText = self:FindWndTrans(item,"NameText")
	local nameText2 = self:FindWndTrans(item,"NameText2")
	local timeBg = self:FindWndTrans(item,"TimeBg")
	local timeText = self:FindWndTrans(item,"TimeBg/TimeText")
	local mask = self:FindWndTrans(item,"Mask")
	local luck = self:FindWndTrans(item,"Mask/Image")
	local eff = self:FindWndTrans(item,"Eff")
	local redPoint = self:FindWndTrans(item,"redPoint")

	local iconList = {
		icon1,icon2,icon3,icon4,icon5
	}
	local instanceID = item:GetInstanceID()
	local jumpId = entryCfg.jumpId or 0
	local eModel = entryCfg.eModel or 0
	local templateId = entryCfg.templateId
	local templateName = entryCfg.templateName
	local  templateTextMat = entryCfg.templateTextMat
	local templateName2 = entryCfg.templateName2
	local templateNameWide = entryCfg.templateNameWide
	local templateTitle = entryCfg.templateTitle
	local templateNameCoord = entryCfg.templateNameCoord
	local templateNameCoord2 = entryCfg.templateNameCoord2
	local templateIcon = entryCfg.templateIcon
	local templateIconSize = entryCfg.templateIconSize
	local templateIconCoord = entryCfg.templateIconCoord
	local templateRedCoord = entryCfg.templateRedCoord
	local templateHero = entryCfg.templateHero or 0
	local templateHeroCoord = entryCfg.templateHeroCoord
	local templateState = entryCfg.templateState
	local templateStateCoord = entryCfg.templateStateCoord
	local templateTipsCoord = entryCfg.templateTipsCoord
	local templateEffect = entryCfg.templateEffect
	local templateEffectCoord = entryCfg.templateEffectCoord
	local templateMoreInfo = entryCfg.moreInfo
	local anchorType = entryCfg.anchorType or 0

	local _openList = self._openList or {}
	local _openData = _openList[templateId]
	local isOpenActivity = false
	local activityData = nil

	if anchorType >= 1 and anchorType <= 9 then
		local anchorV = self._anchors[anchorType]
		self:SetTrAnchors(item,anchorV)
	end
	if not string.isempty(templateIcon)then
		local templateIconArr = string.split(templateIcon,"|")
		local size = {}
		if not string.isempty(templateIconSize)then
			local templateIconSize = string.split(templateIconSize,"|")
			for i, v in ipairs(templateIconSize) do
				if v ~= "0"then
					size[i] = LxDataHelper.ParseVector2NotEmpty(v)
				end
			end
		end
		for i, v in ipairs(templateIconArr) do
			local isNativeSize = not size[i]
			local iconRoot = iconList[i]
			if LxUiHelper.IsImgPathValid(v) then
				self:SetWndEasyImage(iconRoot,v,function()
					CS.ShowObject(iconRoot,true)
				end ,isNativeSize)
				if not isNativeSize then
					iconRoot.sizeDelta = size[i]
				end
				if i == 1 then
					self:SetWndEasyImage(mask,v,function()
						self:SetImageAlpha(mask,0.7)
					end,isNativeSize)

					if not isNativeSize then
						mask.sizeDelta = size[i]
					end
				end
			end
		end
	end
	if not string.isempty(templateIconCoord) then
		local templateIconCoordArr = string.split(templateIconCoord,"|")
		for i, v in ipairs(templateIconCoordArr) do
			local iconRoot = iconList[i]
			local pos = LxDataHelper.ParseVector2NotEmpty3(v)
			self:SetAnchorPos(iconRoot, pos)
			if i == 1 then
				self:SetAnchorPos(mask, pos)
			end
		end
	end
	if LxUiHelper.IsImgPathValid(templateName) then
		CS.ShowObject(textImg,true)
		self:SetWndEasyImage(textImg,templateName,nil,true)
	elseif not string.isempty(templateName) then
		CS.ShowObject(nameText,true)
		self:SetWndText(nameText,templateName)
		if not string.isempty(templateNameWide)then
			local wide = tonumber(templateNameWide) or 0
			nameText.sizeDelta = Vector2.New(wide,nameText.sizeDelta.y)
		end
	end

	if not string.isempty(templateTextMat) then
		self:SetWndTextMat(nameText, templateTextMat)
	end

	if not string.isempty(templateName2) then
		CS.ShowObject(nameText2,true)
		self:SetWndText(nameText2,templateName2)
		if not string.isempty(templateNameWide)then
			local wide = tonumber(templateNameWide) or 0
			nameText2.sizeDelta = Vector2.New(wide,nameText2.sizeDelta.y)
		end
		if not string.isempty(templateNameCoord2) then
			local pos = LxDataHelper.ParseVector2NotEmpty3(templateNameCoord2)
			self:SetAnchorPos(nameText2, pos)
		end
	end
	if not string.isempty(templateNameCoord) then
		local pos = LxDataHelper.ParseVector2NotEmpty3(templateNameCoord)
		self:SetAnchorPos(textImg, pos)
		self:SetAnchorPos(nameText, pos)
	end
	if not string.isempty(templateRedCoord) then
		local pos = LxDataHelper.ParseVector2NotEmpty3(templateRedCoord)
		self:SetAnchorPos(redPoint, pos)
	end
	local trlist = self._redTrList[itemdata.pageId] or {}
	trlist[itemdata.entryId] = redPoint
	self._redTrList[itemdata.pageId] = trlist
	local isRed = gModelRedPoint:GetActivityRedPointPageEntry(_sid,itemdata.pageId,itemdata.entryId)
	CS.ShowObject(redPoint,isRed)
	if not string.isempty(templateHero) then
		CS.ShowObject(spine,true)
		--local ref = gModelHero:GetShowEffectById(templateHero)
		--if ref then
		local arr = string.split(templateHero,"=")
		local prefabName = arr[1]
		local scale = tonumber(arr[2])
		local flie = tonumber(arr[3]) == 1
		local _spineName = self._spineNameList[instanceID]
		if _spineName ~= prefabName then
			self:DestroyWndSpineByKey(instanceID)
		end
		self:CreateWndSpine(spine,prefabName,instanceID,false,function(dpSpine)
			dpSpine:SetScale(scale)
			dpSpine:SetFlipX(flie)
			dpSpine:SetRaycastTarget(false)
			dpSpine:SetIgnoreTimeScale(true)
		end)
		self._spineNameList[instanceID] = prefabName
		--end
		if not string.isempty(templateHeroCoord) then
			local pos = LxDataHelper.ParseVector2NotEmpty3(templateHeroCoord)
			self:SetAnchorPos(spine, pos)
		end
	end

	if eModel > 0 then
		local list = gModelActivity:GetActivityDataByModelId(eModel)
		local len = #list
		if len > 0 then
			for i, v in ipairs(list) do
				local moreInfo = JSON.decode(v.moreInfo)
				if moreInfo and templateId == moreInfo.templateId then
					isOpenActivity = true
					activityData = v
					break
				end
			end
		end
	else
		isOpenActivity = true
	end
	local activityStatus = activityData and activityData.status or ModelActivity.STATUS_NO_SHOW
	CS.ShowObject(mask,activityStatus ~= ModelActivity.STATUS_VALID and eModel > 0)


	local timeStr = ""
	if _openData then
		timeStr = ccClientText(29200)
		local curTime = GetTimestamp()
		local endTime = _openData[4] and tonumber(_openData[4]) or 0
		local type = tonumber(_openData[2])
		--if activityStatus ~= ModelActivity.STATUS_INVALID then
		if type == UIMotifActEntrance.ACTIVITY_TYPE_FOREVER then
			timeStr = ""
		elseif activityStatus == ModelActivity.STATUS_VALID then
			local timespan = endTime - curTime
			timeStr = LUtil.FormatTimespanCn(timespan)
			timeStr = string.replace(ccClientText(29205),timeStr)
			local data = {
				endTime = endTime,
				timeText = timeText
			}
			self._timeList[itemdata.entryId] = data
		elseif endTime > 0 and endTime < curTime then

		else
			timeStr = templateState
		end
		--end
		CS.ShowObject(timeBg,true)
	else
		CS.ShowObject(timeBg,false)
	end
	self:SetWndText(timeText,timeStr)
	if not string.isempty(templateStateCoord)then
		local pos = LxDataHelper.ParseVector2NotEmpty3(templateStateCoord)
		self:SetAnchorPos(luck, pos)
	end
	if not string.isempty(templateTipsCoord)then
		if templateTipsCoord == -1 then
			CS.ShowObject(timeBg,false)
			self._timeList[itemdata.entryId] = nil
		else
			local pos = LxDataHelper.ParseVector2NotEmpty3(templateTipsCoord)
			self:SetAnchorPos(timeBg,pos)
		end
	end
	if not string.isempty(templateEffect) then
		CS.ShowObject(eff,true)
		self:CreateWndEffect(eff,templateEffect,instanceID,100)
		local pos = LxDataHelper.ParseVector2NotEmpty3(templateEffectCoord)
		self:SetAnchorPos(eff,pos)
	end
	local openHeroType,para = 0,0
	if not string.isempty(templateMoreInfo)then
		--local arr = string.split(templateMoreInfo,"|")
		--if not string.isempty(arr[1])then
		local heroArr = string.split(templateMoreInfo,"=")
		openHeroType = tonumber(heroArr[1])
		para = heroArr[2]
		--end
	end

	self:SetWndClick(item,function ()
		if openHeroType ~= 0 then
			if openHeroType == 1 then
				gModelGeneral:OpenHeroSkin({skinRefId = tonumber(para),preview = true})
			elseif openHeroType == 2 then
				gModelGeneral:OpenHeroSimpleTip(tonumber(para),true)
			elseif openHeroType == 3 then
				gModelBattle:OnClickShamBattle(tonumber(para))
			elseif openHeroType == 4 then
				self:OpenAwakeSkill(para)
			end
			return
		end
		if not isOpenActivity then
			if not _openData then
				GF.ShowMessage(ccClientText(29201))
				return
			end
			local activityDatas = gModelActivity:GetActivityBySid(_sid)
			local sTime = _openData[3] or "-1"
			local eTime = _openData[4] or "-1"
			local endTime = tonumber(eTime)
			local curTime = GetTimestamp()
			if tonumber(sTime) > activityDatas.endTime or activityDatas.startTime > endTime then
				GF.ShowMessage(entryCfg.templateTips)
				return
			elseif endTime > 0 and endTime < curTime then
				GF.ShowMessage(ccClientText(29201))
				return
			end
			local para = {
				templateName = templateTitle,
				reward = entryCfg.templateAward,
				openData = _openData,
				templateText = entryCfg.templateText
			}
			GF.OpenWnd("UIMotifActPreview",para)
			return
		end
		if activityData and activityData.status == ModelActivity.STATUS_INVALID then
			GF.ShowMessage(ccClientText(29201))
			return
		end
		if jumpId > 0 then
			local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId,true)
			if not isOpen then return end
			gModelFunctionOpen:Jump(jumpId,self:GetWndName())
			--self:WndClose()
			return
		end
		local func = gModelActivity:GetShowActivityFun(activityData.model)
		if func then
			--这里顺便进行红点是否点击取消的发送
			gModelActivity:OnActivitySpecialOpReq(activityData.sid,itemdata.pageId, itemdata.entryId, nil, "1",26)
			func(activityData,_sid)
		end
		-- if activityData.model == ModelActivity.MODEL_ACTIVITY_TYPE_84 then
		-- 	self:WndClose()
		-- end
	end)
end
function UIMotifActEntrance:SetItemTime()
	local _timeList = self._timeList or {}
	local curTime = GetTimestamp()
	for i, v in pairs(_timeList) do
		local endTime = v.endTime
		local timeText = v.timeText

		local timespan = endTime - curTime
		local timeStr = LUtil.FormatTimespanCn(timespan)
		timeStr = string.replace(ccClientText(29205),timeStr)

		self:SetWndText(timeText,timeStr)
	end
end



------------------------------------------------------------------
return UIMotifActEntrance


