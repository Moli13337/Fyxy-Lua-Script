---
--- Created by Administrator.
--- DateTime: 2023/10/8 17:55:28
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGameSpread:LWnd
local UIGameSpread = LxWndClass("UIGameSpread", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGameSpread:UIGameSpread()
	self._commonUIList = {}
	self._tagTabTrList = {}
	self._iconHeroClsList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGameSpread:OnWndClose()
	self:SaveLocalTagList()
	self:ClearCommonIconList(self._commonUIList)
	self:ClearCommonIconList(self._iconHeroClsList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGameSpread:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGameSpread:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	self:InitStaticContent()

	-- self._isShowWXShare = gLSdkImpl:CallMethod(LSdkMethod.IsSupportShareChannel,LShareConst.CHANNEL_WX)
	-- self._isShowWeiBoShare = gLSdkImpl:CallMethod(LSdkMethod.IsSupportShareChannel,LShareConst.CHANNEL_WB)
	-- self._isShowDouyinShare = gLSdkImpl:CallMethod(LSdkMethod.IsSupportShareChannel,LShareConst.CHANNEL_DY)
	-- self._isShowKaKaoShare = gLSdkImpl:CallMethod(LSdkMethod.IsSupportShareChannel,LShareConst.KOREA_KAKAO)
	-- self._isShowFaceBookShare = gLSdkImpl:CallMethod(LSdkMethod.IsSupportShareChannel,LShareConst.FOREIGN_FACE_BOOK)
	self._isShowMadFun = gLSdkImpl:CallMethod(LSdkMethod.IsSupportShareChannel,LShareConst.SCENE_MADFUN)


	-- CS.ShowObject(self.mWeChatBtn, self._isShowWXShare)
	-- CS.ShowObject(self.mPYQBtn, self._isShowWXShare)

	-- CS.ShowObject(self.mWeiboBtn, self._isShowWeiBoShare)

	-- CS.ShowObject(self.mDYHomeBtn, self._isShowDouyinShare)
	-- CS.ShowObject(self.mDYContactBtn, self._isShowDouyinShare)

	-- CS.ShowObject(self.mKoKaoBtn, self._isShowKaKaoShare)
	-- CS.ShowObject(self.mFaceBookBtn, self._isShowFaceBookShare)
	CS.ShowObject(self.mShareBtn, self._isShowMadFun)

	if self._sid then
		gModelActivity:ReqActivityConfigData(self._sid)
	else
		self:OnActivityConfigData()
	end
end

function UIGameSpread:RefreshTagList(isTab)
	local _tagTab = self._tagTab or 1
	--local refs = gModelPlayer:GetRolePlayerHeadListByType(ModelPlayerSpace.ROLE_TAG)
	local refs={}
	local useList = self._setTagList or self:GetLocalTagList() or gModelPlayer:GetPlayerTags()
	self._setTagList = useList
	local _useList = {}
	for i, v in pairs(useList) do
		_useList[v] = i
	end
	self._useList = _useList
	local list = {}
	for i, v in pairs(refs) do
		if _tagTab == v.subType then
			table.insert(list,v)
		end
	end
	table.sort(list,function (a,b)
		return a.refId < b.refId
	end)
	local _uiListSuper = self._uiListSuper
	if _uiListSuper then
		_uiListSuper:RefreshList(list)
		_uiListSuper:DrawAllItems()
	else
		_uiListSuper = self:GetUIScroll("mTagSuper_UISubAreaCompile_")
		self._uiListSuper = _uiListSuper
		_uiListSuper:Create(self.mTagSuper,list,function (...) self:TagListItem(...) end,UIItemList.SUPER_GRID)
		_uiListSuper:EnableScroll(true,false)
	end
	if isTab then
		_uiListSuper:MoveToPos(1)
	end
end

function UIGameSpread:HeroListItem(list,item, itemdata, itempos)
	local heroTrans = CS.FindTrans(item,"Root/HeroIcon")
	local nameText=CS.FindTrans(item,"NameText")
	local addTrans = CS.FindTrans(item,"BtnAdd")

	local heroId = itemdata.id
	CS.ShowObject(addTrans,false)
	CS.ShowObject(heroTrans,heroId)
	CS.ShowObject(nameText,heroId)
	if(not heroId)then
		self:SetWndClick(addTrans, function (...)
			self:OnClickBattleArrShow()
		end)
		return
	end
	local name = gModelHero:GetColoredHeroName(itemdata.refId,itemdata.star)
	self:SetWndText(nameText,name)
	self:InitTextShowWithLanguage(nameText,nameText)

	local InstanceID = item:GetInstanceID()
	local baseClass = self._iconHeroClsList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._iconHeroClsList[InstanceID] = baseClass
		baseClass:Create(heroTrans)
		self:SetIconClickScale(heroTrans, true)
	end
	itemdata.level=itemdata.lv
	baseClass:SetHeroDataSet(itemdata)
	baseClass:DoApply()

	self:SetWndClick(heroTrans,function()
		gModelHero:ReqShowHeroTip(self._playerId,itemdata,nil,nil,nil,self._serverId)
	end)
end

function UIGameSpread:ClickShareBtn()

end

function UIGameSpread:OnClickItemTag(itemdata,isUse)
	local setTagNum = gModelPlayer:GetRoleConfigRefByKey("setTagNum")
	local isWar = not isUse
	local refId = itemdata.refId

	local isUp = isWar
	local useList = self._setTagList or self:GetLocalTagList() or gModelPlayer:GetPlayerTags()
	local list = {}
	for i = 1, setTagNum do
		local id = useList[i]
		if id and id ~= 0 then
			if not isWar and id == refId then
				list[i] = 0
			else
				list[i] = id
			end
		else
			if isWar and isUp then
				isUp = false
				list[i] = refId
			else
				list[i] = 0
			end
		end
	end
	if isUp then
		GF.ShowMessage(string.replace(ccClientText(21177),setTagNum))
		return
	end

	self._setTagList = list
	self:RefreshTagItems()
	self:RefreshTagList()
end

function UIGameSpread:OnDrawChangeBgBtnCell(list,item,itemdata,itempos)
	local SelImg = self:FindWndTrans(item,"SelImg")
	local Head = self:FindWndTrans(item,"Head")

	local index = itemdata.index
	local show = index == self._selIndex or false
	CS.ShowObject(SelImg,show)

	self:SetWndEasyImage(Head,itemdata.btnBgImg)

	self:SetWndClick(Head,function()
        LxUiHelper.FilterScrollItem(self.mChangeBgList,itempos-1)
		self:ChangeShow(itemdata)
	end)
end


--#####################################################################################################################
--## Tag ##############################################################################################################
--#####################################################################################################################
function UIGameSpread:RefreshTagTabList()
	--local list = gModelPlayer:GetRoleAdventureImageTypeRef(ModelPlayerSpace.ROLE_TAG)
	local list = { }

	local _TagTabScroll = self._TagTabScroll
	if _TagTabScroll then
		_TagTabScroll:RefreshList(list)
	else
		_TagTabScroll = self:GetUIScroll("mTagTabScroll_UISubAreaCompile_")
		self._TagTabScroll = _TagTabScroll
		_TagTabScroll:Create(self.mTagTabScroll,list,function (...) self:TagTabListItem(...) end)
	end

	if self._tagTab then
		self:OnClickTagTab(self._tagTab)
	else
		self:OnClickTagTab(list[1].type)
	end
end

function UIGameSpread:InitData()
	self._sid = self:GetWndArg("sid")
	self._shareTagText = self:GetWndArg("shareTagText")
	self._shareTag = self:GetWndArg("shareTag")

	local playerName = gModelPlayer:GetPlayerName()
	self:SetWndText(self.mPlayerName,playerName)
end

function UIGameSpread:TagListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"HeadUI")
	local tagBg = self:FindWndTrans(root,"TagBg")
	local tagText = self:FindWndTrans(root,"TagBg/TagText")
	local isTrue = self:FindWndTrans(root,"IsTrueBg/IsTrue")

	local tagTextStr = LUtil.FormatColorStr(ccLngText(itemdata.name),"#"..itemdata.tagColour)
	local _useList = self._useList or {}
	local isUse = _useList[itemdata.refId]

	self:SetWndEasyImage(tagBg, itemdata.tagBg)
	self:SetWndText(tagText, tagTextStr)
	CS.ShowObject(isTrue,isUse)
	self:SetWndClick(root,function ()
		self:OnClickItemTag(itemdata,isUse)
	end)
end

function UIGameSpread:RefreshTagItems()
	local setTagNum = gModelPlayer:GetRoleConfigRefByKey("zoneTagNum")
	local tagList = self._setTagList or self:GetLocalTagList() or gModelPlayer:GetPlayerTags()
	self._setTagList = tagList

	for i = 1, setTagNum do
		local item = self:FindWndTrans(self.mTagItemRoot,"TagItem"..i)
		local refId = tagList[i] or 0
		self:SetTagItemList(item,refId,i)
	end
end

function UIGameSpread:InitEvent()
	self:SetWndClick(self.mReturnBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mWeChatBtn,function()
		--GF.ShowMessage(ccClientText(20837))
		self:SaveImg(LShareConst.SCENE_WX_PY)
	end)
	self:SetWndClick(self.mPYQBtn,function()
		--GF.ShowMessage(ccClientText(20838))
		self:SaveImg(LShareConst.SCENE_WX_PYQ)
	end)
	self:SetWndClick(self.mWeiboBtn,function()
		self:SaveImg(LShareConst.SCENE_WB_HOME)
	end)
	self:SetWndClick(self.mDYHomeBtn,function()
		self:SaveImg(LShareConst.SCENE_DY_HOME)
	end)
	self:SetWndClick(self.mDYContactBtn,function()
		--GF.ShowMessage(ccClientText(20838))
		self:SaveImg(LShareConst.SCENE_DY_PY)
	end)

	self:SetWndClick(self.mKoKaoBtn,function()
		self:SaveImg(LShareConst.SCENE_KOREA_KAKAO)
	end)

	self:SetWndClick(self.mFaceBookBtn,function()
		self:SaveImg(LShareConst.SCENE_FACE_BOOK)
	end)

	self:SetWndClick(self.mTwitterBtn,function()
		self:SaveImg(LShareConst.SCENE_TWITTER)
	end)

	self:SetWndClick(self.mCopyBtn,function()
        self:CopyFunc()
	end)
	self:SetWndClick(self.mSaveBtn,function()
		self:SaveImg()
	end)

	self:SetWndClick(self.mBtnTag,function()
		self:OnClickTag()
	end)
	self:SetWndClick(self.mTagCompileBg,function()
		self:OnClickCloseTag()
	end)
	self:SetWndClick(self.mBtnTagMagClose,function()
		self:OnClickCloseTag()
	end)
	self:SetWndClick(self.mShareBtn,function()
		self:SaveImg(LShareConst.SCENE_MADFUN)
	end)
end

function UIGameSpread:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
        self:ResetData(pb)
    end)

	self:WndNetMsgRecv(LProtoIds.GetFormationShowResp,function (...)
		self:InitHeroList(...)
	end)

	self:WndEventRecv(EventNames.INVITE_SCREEN_SHOT_OK,function ()
		--self:SetDivPos(false)
	end)
end


function UIGameSpread:SaveLocalTagList()
	local _setTagList = self._setTagList or {}
	local str = ""
	for k,v in ipairs(_setTagList) do
		if v ~= 0 then
			str = str.."|"..v
		end
	end

	LPlayerPrefs.SetGameShareTagList(str)
end

function UIGameSpread:SetDivPos(isShot)
	if not self._showUIMessage and self._isShowLineup then
		local heroDivPos = isShot and self._heroDivImgPos.SHOT or self._heroDivImgPos.COMMON
		self:SetAnchorPos(self.mHeroDivImage,heroDivPos)

		local heroListPos = isShot and self._heroListPos.SHOT or self._heroListPos.COMMON
		self:SetAnchorPos(self.mHeroListScroll,heroListPos)
	end
end

function UIGameSpread:ChangeShow(itemdata)
	if not itemdata then return end
	local index = itemdata.index
	if index == self._selIndex then return end
	self._selIndex = index
	local bgImg = itemdata.bgImg
	self._showImg = bgImg
	self:SetWndEasyImage(self.mBg,bgImg)
	-- local bgTextImg = itemdata.bgTextImg
	-- local showBgTextTrans = not string.isempty(bgTextImg)
	-- if showBgTextTrans then
		-- self:SetWndEasyImage(self.mBgTxtImg,bgTextImg)
	-- end
	-- CS.ShowObject(self.mBgTxtImg,showBgTextTrans)
	self:RefreshChangeBgList()
end

function UIGameSpread:RefreshChangeBgList()
	local uiChangeBgList = self._uiChangeBgList
	if not uiChangeBgList then return end
	local uiList = uiChangeBgList:GetList()
	uiList:RefreshList()
end

function UIGameSpread:SaveImg(saveType)
	local list = {self.mShotDiv,self.mMaskBg}

	if self._isShowLabel then
		table.insert(list, self.mTagItemRoot)
	end

	if self._isShowLineup then
		table.insert(list, self.mHeroDiv)
	end

	local isShare = false
	local shareData
	local str = "保存图片"
	local showImg = self._showImg

	local reqShare = false
	if saveType and saveType > 0 then
		isShare = self._isShowDouyinShare or self._isShowWeiBoShare or self._isShowWXShare or self._isShowKaKaoShare or self._isShowFaceBookShare or self._isShowMadFun
		shareData = {shareScene=saveType,  shareLocation="GameShareActivity40", tags={shareTagText= self._shareTagText, shareTag= self._shareTag}}
		str = LShareConst.TA_ATTR_MAP[saveType] or ""
		reqShare = true

		if saveType == LShareConst.SCENE_TWITTER then
			self:OpenTwitterUrl()
		end
	else
		reqShare = not self._onlySave
	end
	if reqShare and self._sid then
		gModelActivity:OnActivityInvitationReq(4, self._sid)
	end

	--self:SetDivPos(true)

	gLGameUI:CaptureUIScreen(self:GetWndTrans(),list,isShare, shareData,function()
		if not self:IsWndValid() then return end
		self:RefreshGameLogoImg()
	end)

	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_INVITE,"分享邀请码",str,showImg)
end

function UIGameSpread:OpenTwitterUrl()
	local isShow, link = gModelPlayer:CheckShowTwitterLink()
	if not isShow then
		return
	end

	CS.UApplication.OpenURL(link)
	--local url = "https://twitter.com/intent/tweet?url=%s&text=%s"
	--url = string.replace(url, "", self._shareTextWindow)
	--CS.UApplication.OpenURL(url)
end

function UIGameSpread:OnActivityConfigData()
	local activityWebData
	local config
	if self._sid then
		activityWebData = gModelActivity:GetWebActivityDataById(self._sid)
	end

	if activityWebData then
		config = activityWebData.config
	else
		--未开活动的时候
		config = GameTable.ShareAccessInviteConfigRef[1]
	end

	if not config then return end

	local playerName = gModelPlayer:GetPlayerName()
	local serverName = gLGameLogin:GetServerName()


	local weixinShow = config.weixinShow or 0
	local isShowWeiXin = weixinShow == 1
	if self._isShowWXShare then
		CS.ShowObject(self.mWeChatBtn, isShowWeiXin)
	end
	if self._isShowWeiBoShare then
		CS.ShowObject(self.mWeiboBtn, isShowWeiXin)
	end
	if self._isShowDouyinShare then
		CS.ShowObject(self.mDYHomeBtn, isShowWeiXin)
		CS.ShowObject(self.mDYContactBtn, isShowWeiXin)
	end


	---- 2023/3/2 推特只需要显示到网页，直接活动配置表控制
	local showTwitter = config.showTwitter or 0
	CS.ShowObject(self.mTwitterBtn, showTwitter == 1)

    local showLabel = config.showCopy or 1
    -- CS.ShowObject(self.mCopyBtn, showLabel == 1)

	local shareUiMessage = config.shareUiMessage or 1
	local showUIMessage = shareUiMessage == 1
	self._showUIMessage = showUIMessage

	--CS.ShowObject(self.mListBg,showUIMessage)

	CS.ShowObject(self.mGameLogoImg,showUIMessage)
	-- CS.ShowObject(self.mMaskBg,showUIMessage)

	local onlySave
	local invitationCode = ""
	local codeImage = config.codeImage
	local yqmStr
	local downloadText = ccLngText(config.downloadText) or ""

	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if activityData then
		local moreInfo = JSON.decode(activityData.moreInfo)
		invitationCode = moreInfo.invitationCode
		self._yqmNum = invitationCode
		local shareText = config.shareText
		shareText = string.replace(shareText,playerName,serverName,invitationCode)
		self._yqmNumStr = shareText

		local strCode
		local inNum = 4
		local strCodeLen = string.len(invitationCode)
		local len = math.ceil(strCodeLen / inNum)
		for i = 1,len do
			local startNum,endNum = (i - 1)*inNum + 1,i * inNum
			local tStr = string.sub(invitationCode, startNum, endNum)
			if strCode then
				strCode = strCode .. " " .. tStr
			else
				strCode = tStr
			end
		end

		yqmStr = string.replace(ccClientText(20827),strCode)

		codeImage = moreInfo.codeImage

		local logo = moreInfo.logo
		self._logoImg = logo
		onlySave = moreInfo.onlySave or 0
		downloadText = config.downloadText or ""
	end

	if LxUiHelper.IsImgPathValid(codeImage) then
		self:SetWndEasyImage(self.mCodeImg,codeImage,function()
			CS.ShowObject(self.mCodeImg,true)
		end)
	end

	local isShowYQM = not string.isempty(yqmStr)
	if gLGameLanguage:IsJapanRegion() then
		isShowYQM = false
	end
	if isShowYQM then
		self:SetWndText(self.mPlayerYQM,yqmStr)
	end
	CS.ShowObject(self.mYQMBg, isShowYQM)


	local showLog = config.showLog or 0
	self._isShowLog = showUIMessage or showLog
	if self._isShowLog then
		self:RefreshGameLogoImg()
	end

	local shareTextWindow = config.shareTextWindow
	if not string.isempty(shareTextWindow) then
		if not self._sid then
			shareTextWindow = ccLngText(shareTextWindow)
		end
		shareTextWindow = string.replace(shareTextWindow,playerName,serverName,invitationCode)
	end
	self._shareTextWindow = shareTextWindow or ""

	local isOnlaySave = onlySave == 1
	self._onlySave = isOnlaySave

--[[	self:SetWndEasyImage(self.mGameLogoImg,logo,function()
		CS.ShowObject(self.mGameLogoImg,true)
	end,true)]]

	local shareImage = string.split(config.shareImage,";")
	local shareImageBtn = string.split(config.shareImageBtn,";")
	local shareImageText = string.split(config.shareImageText,";")

	local list = {}
	for i,v in ipairs(shareImage) do
		table.insert(list,{
			bgImg = v,
			bgTextImg = shareImageText[i],
			btnBgImg = shareImageBtn[i],
			index = i,
		})
	end


	self:SetWndText(self.mDescTxt,downloadText)
	self:InitTextLineWithLanguage(self.mDescTxt, -30)

	if not self._selIndex then
        local randNum = math.random(1,#list)
		local first = list[randNum]
		self:ChangeShow(first)
	end
	self:InitChangeBgList(list)

	local showLabel = config.showLabel or 0
	self._isShowLabel = showLabel == 1
	CS.ShowObject(self.mBtnTag, self._isShowLabel)
	CS.ShowObject(self.mTagItemRoot, self._isShowLabel)
	if self._isShowLabel then
		self:RefreshTagItems()
	end

	local showLineup = config.showLineup or 0
	local isShowLineup = showLineup == 1
	self._isShowLineup = isShowLineup
	CS.ShowObject(self.mHeroDiv, isShowLineup)
	if isShowLineup then
		self._heroDivImgPos = {
			COMMON = Vector2.New(0, 208),
			SHOT = Vector2.New(0, 22),
		}

		self._heroListPos = {
			COMMON = Vector2.New(0, 204),
			SHOT = Vector2.New(0, 18),
		}

		local playerId = gModelPlayer:GetPlayerId()
		self._playerId = playerId
		self._serverId = gModelPlayer:GetServerId()
		gModelPlayer:OnGetFormationShowReq(playerId)
	end


	if self._sid then
		-- gModelActivity:OnActivityPageReq(self._sid)
	end
end

function UIGameSpread:InitStaticContent()
	self:SetWndText(self.mTagText,ccClientText(21170))
	self:SetWndText(self.mTagMagCloseText,ccClientText(24206))
end

function UIGameSpread:ResetData(pb)
    local sid = pb.sid
    if self._sid ~= sid then return end
    for i,v in ipairs(pb.pages) do
        local pageId = v.pageId
        if pageId == 3 then
            local page = gModelActivity:GenerateActivePageDataFromPb(v)
            local entry = page.entry or {}
            for idx,val in ipairs(entry) do
                local status = val.goalData.status
                local canGet = status == 1
                if canGet then
                    gModelActivity:OnActivityReceiveGoalReq(self._sid,pageId,val.entryId)
                end
            end
        end
    end
end

function UIGameSpread:InitText()
	self:SetWndText(self.mWeChatBtnName,ccClientText(20818))
	self:SetWndText(self.mPYQBtnName,ccClientText(20819))
	self:SetWndText(self.mSaveBtnName,ccClientText(20820))
	self:SetWndText(self.mCopyBtnName,ccClientText(20856))

	self:SetWndText(self.mWeiboBtnName,ccClientText(20858))
	self:SetWndText(self.mDYHomeBtnName,ccClientText(20859))
	self:SetWndText(self.mDYContactBtnName,ccClientText(20860))
	self:SetWndText(self.mKoKaoBtnName, ccClientText(20861))
	self:SetWndText(self.mFaceBookBtnName, ccClientText(20862))
	self:SetWndText(self.mTwitterBtnName, ccClientText(21180))
	self:SetWndText(self:FindWndTrans(self.mReturnBtn, "TxtClose"), ccClientText(30205))
	self:SetWndText(self:FindWndTrans(self.mShareBtn, "Text"), ccClientText(17979))
end

function UIGameSpread:InitChangeBgList(list)
	local uiChangeBgList = self._uiChangeBgList
	if uiChangeBgList then
		uiChangeBgList:RefreshList(list)
	else
		uiChangeBgList = self:GetUIScroll("uiChangeBgList")
		self._uiChangeBgList = uiChangeBgList
		uiChangeBgList:Create(self.mChangeBgList,list,function(...) self:OnDrawChangeBgBtnCell(...) end)
		uiChangeBgList:EnableScroll(true)
	end
end

function UIGameSpread:OnClickCloseTag()
	CS.ShowObject(self.mTagCompileMag,false)
	CS.ShowObject(self.mBtnTag, true)
end

function UIGameSpread:GetLocalTagList()
	local tagList = string.split(LPlayerPrefs.gameShareTagList, '|')
	local resultList = {}
	for k,v in ipairs(tagList) do
		table.insert(resultList, tonumber(v))
	end

	if table.isempty(resultList) then
		return nil
	end

	return resultList
end

function UIGameSpread:TagTabListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local btnTab = self:FindWndTrans(root,"BtnTab2")

	self:SetWndTabText(btnTab,ccLngText(itemdata.name))
	self:SetWndTabStatus(btnTab,LWnd.StateOff)
	self._tagTabTrList[itemdata.type] = btnTab
	self:SetWndClick(root,function ()
		self:OnClickTagTab(itemdata.type)
	end)
end

function UIGameSpread:CopyFunc()
    local str = self._yqmNumStr
    if string.isempty(str) then return end
    if LNativeHelper.CopyToClipboard(str) then
        --LNativeHelper.ShowToast(str)
        GF.ShowMessage(ccClientText(20846))
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_INVITE,"分享邀请码","复制邀请码2",str)
    end
end

function UIGameSpread:OnClickTagTab(type)
	local _tagTabTrList = self._tagTabTrList or {}
	local _type = self._tagTab
	if _type then
		self:SetWndTabStatus(_tagTabTrList[_type],LWnd.StateOff)
	end
	self:SetWndTabStatus(_tagTabTrList[type],LWnd.StateOn)
	self._tagTab = type
	self:RefreshTagList(true)
end

function UIGameSpread:RefreshGameLogoImg()
	if not self._isShowLog then
		return
	end

	local logo = self._logoImg

	local pngPath = LGameSettings.platformLogoPng
	if (not LPlatformUtil.IsAssetFileExist(pngPath)) and not string.isempty(logo) then
		pngPath = "etc/" .. logo .. ".png"
	end

	printInfoNR("====== pngPath = " .. pngPath)
	if (not LPlatformUtil.IsAssetFileExist(pngPath)) then
		return
	end

	local uiPngTexture = self.mGameLogoImg:GetComponent("YXTextureImage")
	uiPngTexture.isNativeSize = true
	uiPngTexture.isColorReset = true
	uiPngTexture:SetImageFromFullPath(CS.StreamingPath() .. pngPath)
end

--#####################################################################################################################
--## HeroDiv ##########################################################################################################
--#####################################################################################################################
function UIGameSpread:InitHeroList(pb)
	local _combatHeroData = gModelGeneral:SetCombatHeroData(pb.heroData)
	local list = {}
	local heros = _combatHeroData._heros
	local grids = _combatHeroData._grids
	self.combatHeroData = _combatHeroData
	local _heros = {}
	for i, v in ipairs(heros) do
		local pos = grids[i]
		_heros[pos] = v
	end
	for i = 1, 5 do
		local hero = _heros[i] or {}
		table.insert(list,hero)
	end

	local _uiHeroList = self._uiHeroList
	if(_uiHeroList)then
		_uiHeroList:RefreshList(list)
	else
		_uiHeroList = self:GetUIScroll("_uiHeroIconList")
		_uiHeroList:Create(self.mHeroListScroll,list,function (...) self:HeroListItem(...) end)
		self._uiHeroList = _uiHeroList
	end
end

function UIGameSpread:OnClickBattleArrShow()
	GF.OpenWnd("UIPerSagaSetPop",{
		combatHeroData = self.combatHeroData,
		callFun = function(...)
			local _playerId = self._playerId
			gModelPlayer:OnGetFormationShowReq(_playerId)
		end
	})
end

function UIGameSpread:SetTagItemList(item,itemdata,itempos)
	CS.ShowObject(item,true)
	local posRef = gModelPlayerSpace:GetRoleTagPosByRefId(itempos)
	local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(itemdata)
	local btnAdd = self:FindWndTrans(item,"BtnAdd")
	local numText = self:FindWndTrans(item,"BtnAdd/NumText")
	local tagItem = self:FindWndTrans(item,"TagItem")
	local tagText = self:FindWndTrans(item,"TagItem/TagText")

	CS.ShowObject(btnAdd,false)
	CS.ShowObject(tagItem,false)
	self:SetWndText(numText,itempos)
	self:SetWndClick(item,function ()
		if ref then
			self._tagTab = ref.subType
		end
		self:OnClickTag()
	end)

	local size = posRef.zoneTagSize
	item.localScale = Vector2.New(size,size)
	if not ref then
		return
	end
	CS.ShowObject(tagItem,true)

	self:SetWndEasyImage(tagItem,ref.tagBg)
	self:SetWndText(tagText,LUtil.FormatColorStr(ccLngText(ref.name),"#"..ref.tagColour))
	self:InitTextLineWithLanguage(tagText, -30)
end

function UIGameSpread:OnClickTag()
	CS.ShowObject(self.mTagCompileMag,true)
	CS.ShowObject(self.mBtnTag, false)
	self:RefreshTagItems()
	self:RefreshTagTabList()
end


------------------------------------------------------------------
return UIGameSpread


