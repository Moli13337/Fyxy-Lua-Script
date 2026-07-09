---
--- Created by Administrator.
--- DateTime: 2023/10/25 23:08:18
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaBookRelationSy:LWnd
local UISagaBookRelationSy = LxWndClass("UISagaBookRelationSy", LWnd)

UISagaBookRelationSy.JB_STATUS_NOACT = 0         -- 未激活
UISagaBookRelationSy.JB_STATUS_CANRECEIVE = 1       -- 领取奖励
UISagaBookRelationSy.JB_STATUS_RECEIVE = 2       -- 已经领取奖励
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaBookRelationSy:UISagaBookRelationSy()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaBookRelationSy:OnWndClose()
	FireEvent(EventNames.ON_COMMON_BARRAGE_STATUS, false)
	GF.CloseWndByName("UIOrdinBulletSay")
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaBookRelationSy:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaBookRelationSy:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitMsg()
	self:InitEvent()
	self:InitCommon()
	self:InitCommonBarrageWnd()
end


function UISagaBookRelationSy:InitMsg()
	self:WndNetMsgRecv(LProtoIds.RelationChangeInfoResp,function (...) self:UpdateView(true) end)

end


function UISagaBookRelationSy:CreateHeroRelationAttrList(refId, attrType, network)
	local list = self:GetHeroRelationAttrList(refId, attrType)

	local uiHeroRelationAttrList = self._uiHeroRelationAttrList
	if uiHeroRelationAttrList then
		uiHeroRelationAttrList:RefreshList(list)
		local uiList = uiHeroRelationAttrList:GetList()
		uiList:DrawAllItems()
	else
		uiHeroRelationAttrList = self:GetUIScroll("uiHeroRelationAttrList")
		self._uiHeroRelationAttrList = uiHeroRelationAttrList
		uiHeroRelationAttrList:Create(self.mList, list, function(...)
			self:OnDrawHeroRelationAddAttrCell(...)
		end, UIItemList.SUPER)
	end
	local index
	for i,v in ipairs(list) do
		if v.status == UISagaBookRelationSy.JB_STATUS_CANRECEIVE then
			index = i
			break
		end
	end
	if index then
		local uiList = uiHeroRelationAttrList:GetList()
		uiList:MoveToPos(index)
	end
	self:DelaySendFinish(0.2)
end


function UISagaBookRelationSy:OnClickBtn(groupRefId,refId)
	gModelHeroBook:OnHeroRelationActiveReq(groupRefId, refId)
end


function UISagaBookRelationSy:OpenBarrageShow()
	if self._showRelationViewBarrage then
		FireEvent(EventNames.CHANGE_COMMON_BARRAGE_INFO, {
			heroRefId = self._refId,
			barrageType = ModelHeroBook.BARRAGE_TYPE_HERORELATION
		})
	else
		FireEvent(EventNames.ON_COMMON_BARRAGE_STATUS, false)
	end
	CS.ShowObject(self.mRelationBarrageMask, not self._showRelationViewBarrage)
end

function UISagaBookRelationSy:UpdateView(netWork)
	local refId =  self._refId
	local conf = gModelHeroBook:GetHeroRelationRefByRefId(refId)
	local info = gModelHeroBook:GetRelationInfoByRefId(refId)


	self:SetWndText(self.mRelationName,ccLngText(conf.name))

	local selfPrefabName = conf.selfPrefabName

	local relationHeroKeyList = {}
	local relationHero = string.split(conf.relationHero,"|")
	for idx,val in ipairs(relationHero) do
		local heroRefId = tonumber(val)
		relationHeroKeyList[heroRefId] = heroRefId
	end

	local heroesKey = info.heroesKey
	self:CreateWndPrefab(self.mHeroRelationImg, selfPrefabName, key, function(prefabTrans)
		local heroNum = 0;
		for k, v in pairs(relationHeroKeyList) do
			local heroTrans = self:FindWndTrans(prefabTrans, v)
			local isGray = not heroesKey[v]
			self:SetWndImageGray(heroTrans, isGray)
			heroNum = heroNum + 1
			local nameBg = self:FindWndTrans(prefabTrans,  "HeroNameBg".. v)
			if nameBg then
				local nameTxt =  self:FindWndTrans(nameBg,  "HeroName")
				local str = gModelHero:GetHeroNameByRefId(tonumber(v))
				str =  LUtil.FormatColorStr(str,isGray and "lightGrey" or "yellow_2")
				self:SetWndText(nameTxt,str)
				self:SetWndClick(nameBg,function ()
					--详情打开
					gModelGeneral:OpenHeroStarPre({ refId = v})
				end)
			end

		end

		local blackNum = conf.relationHeroNum - heroNum
		if blackNum > 0 then
			for i = 1,blackNum do
				local blackTran = self:FindWndTrans(prefabTrans, "black"..i)
				if blackTran then
					self:SetWndClick(blackTran,function ()
						local str = ccClientText(10131)
						GF.ShowMessage(str)
					end)
				end
			end
		end


	end, CS.RES_UI_HEROBOOK1)

	local hasHeros = #info.heroes
	self:SetWndText(self.mProTxt,hasHeros.. "/".. conf.relationHeroNum)
	LxUiHelper.SetProgress(self.mProImg,hasHeros / conf.relationHeroNum )


	local id = self._refId

	local  r = gModelHeroBook:CheckJBSJStatusByRefId(id);
	self:DestroyWndEffectByKey("fx_baoxiang_paiweisai02")


	local config = gModelHeroBook:GetHeroRelationRefByRefId(id)
	local info = gModelHeroBook:GetRelationInfoByRefId(id)
	local isRec = info.isRec

	if not isRec then
		self:SetWndEasyImage(self.mBoxImg,"callhero_bar_3")
	else
		self:SetWndEasyImage(self.mBoxImg,"callhero_bar_4")
	end


	if not isRec and r then
		self:CreateWndEffect(self.mBoxEff,"fx_baoxiang_paiweisai01","fx_baoxiang_paiweisai02",100)
	end



	self:CreateHeroRelationAttrList(self._refId,conf.attrType,netWork)


end



function UISagaBookRelationSy:InitText()
	self:SetWndText(self.mHeroRelationStoryBtnTxt,ccClientText(19716))
	self:SetWndText(self.mHeroRelationCommentBtnTxt,ccClientText(19717))
	self:SetWndText(self.mTxt2,ccClientText(19711))
	self:SetWndText(self.mTxt1,ccClientText(19778))
	--self:SetWndText(self.mReturnTxt,ccClientText(30205))
	self:SetWndText(self.mTxtClose,ccClientText(30205))
	self:SetWndText(self.mRelationBarrageBtnTxt,ccClientText(10145))
	self:SetWndText(self.mShareTwitterText,ccClientText(21180))
end


function UISagaBookRelationSy:GetHeroRelationAttrList(refId, attrType)
	local attrList = {}
	local relationAttrRefList = gModelHeroBook:GetHeroRelationAttrRefListByRelationType(attrType)
	local serverData = gModelHeroBook:GetRelationInfoByRefId(refId)
	if not relationAttrRefList and not serverData then
		return attrList
	end
	local heroes = serverData.heroes or {}
	local heroLen = #heroes
	local activeNumKeyList = serverData.activeNumKeyList or {}
	for k, v in pairs(relationAttrRefList) do
		local relationAttrRefId = v.refId
		local need = v.need
		local status
		local isAct = heroLen >= need
		if isAct then
			status = activeNumKeyList[relationAttrRefId] and UISagaBookRelationSy.JB_STATUS_RECEIVE or UISagaBookRelationSy.JB_STATUS_CANRECEIVE
		else
			status = UISagaBookRelationSy.JB_STATUS_NOACT
		end

		local attrList_1 = {}
		local attr = string.split(v.attr,",")
		for idx,val in ipairs(attr) do
			local valList = string.split(val,"=")
			local attrRefId,nType,value = tonumber(valList[1]),tonumber(valList[2]),tonumber(valList[3])
			table.insert(attrList_1,{
				refId = attrRefId,
				numType = nType,
				value = value,
			})
		end
		local data = {
			refId = relationAttrRefId,
			attrList =attrList_1,
			need = need,
			attrType = v.type,
			status = status,
			groupRefId = refId,
		}
		table.insert(attrList, data)
	end
	table.sort(attrList, function(a, b)
		return a.need < b.need
	end)
	return attrList
end


function UISagaBookRelationSy:InitCommonBarrageWnd()
	local cd = gModelChat:GetChatConfigRefByKey("textShowSpeed")
	local colorList = gModelHero:GetBarrageColorList()
	gModelHeroBook:OpenCommonBarrage({
		cd = cd,
		colorList = colorList,
		barrageType = ModelHeroBook.BARRAGE_TYPE_HEROCOMMENT,
		heroRefId = self._refId,
		autoRun = false,
	})
end

function UISagaBookRelationSy:InitEvent()
	--返回按钮
	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mHeroRelationStoryBtn, function()
		local key = self._refId
		local serverData = gModelHeroBook:GetRelationInfoByRefId(key)
		local curHeroNum = serverData and #serverData.heroes or 0
		gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"2-2-1-1",key,curHeroNum,0)
		--GF.OpenWndUp("UIRelationSy", { relationRefId = key })
		GF.OpenWndUp("UISagaBookRelationPop", {refId = key})
	end)
	self:SetWndClick(self.mHeroRelationCommentBtn, function()
		local key = self._refId
		local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_3)
		if not sensitive then
			GF.ShowMessage(ccClientText(30800))
			return
		end
		local serverData = gModelHeroBook:GetRelationInfoByRefId(key)
		local curHeroNum = serverData and #serverData.heroes or 0
		gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"2-2-1-2",key,curHeroNum,0)
		GF.OpenWndTop("UIRelationBulletSaySendPop", { relationRefId = key })
	end)

	self:SetWndClick(self.mBoxEff,function ()

		local id = self._refId
		local config = gModelHeroBook:GetHeroRelationRefByRefId(id)
		local info = gModelHeroBook:GetRelationInfoByRefId(id)
		if not info.isRec and gModelHeroBook:CheckJBSJStatusByRefId(id) then
			self:DestroyWndEffectByKey("fx_baoxiang_paiweisai02")
			self:CreateWndEffect(self.mBoxEff,"fx_baoxiang_paiweisai02","fx_baoxiang_paiweisai02",100)

			gModelHeroBook:OnHeroRelationReceiveRewardReq(id)
		else
			local root = self.mBoxEff
			local itemList = config.rewardList
			GF.OpenWnd("UIringBoxDetail",{root,itemList})
		end

	end)

	self:SetWndClick(self.mRelationBarrageBtn, function()
		self._showRelationViewBarrage = not self._showRelationViewBarrage
		gModelHeroBook:SetRelationBarrageStatus(self._showRelationViewBarrage)
		self:OpenBarrageShow()
	end)

	self:SetWndClick(self.mBtnShareTwitter, function (...)
		self:OnClickShareTwitter()
	end)


end

function UISagaBookRelationSy:InitCommon()
	self._refId =  self:GetWndArg("RefId")
	self:OpenBarrageShow()
	self:UpdateView(false)

	local isShowTwitterLink = gModelPlayer:CheckShowTwitterLink()
	CS.ShowObject(self.mBtnShareTwitter, isShowTwitterLink)
end

function UISagaBookRelationSy:OnDrawHeroRelationAddAttrCell(list, item, itemdata, itempos)
	local status = itemdata.status
	--local need = itemdata.need
	local refId = itemdata.refId
	local groupRefId = itemdata.groupRefId
	local attrList = itemdata.attrList or {}
	local showAct = status ~= UISagaBookRelationSy.JB_STATUS_NOACT


	local condition = self:FindWndTrans(item,"Condition")
	--颜色
	local str = ccClientText(19738)
	if showAct then

		local str1 =  LUtil.FormatColorStr(itemdata.need, "lightGreen" )
		str = string.replace(str,str1)
		str =   LUtil.FormatColorStr(str, "storyActive")
	else
		str = string.replace(str,itemdata.need)
		str = LUtil.FormatColorStr(str, "storyUnActive" )

	end

	self:SetWndText(condition,str)

	local star =  self:FindWndTrans(item,"Star")
	self:SetWndEasyImage(star, showAct and "risk_star_10" or "risk_star_9")

	for i=1,3 do
		local attr = self:FindWndTrans(item,"Attr" .. i)
		local attrData = attrList[i]
		CS.ShowObject(attr,attrData ~= nil)
		if attrData then
			local attrConf = GameTable.RoleAttrRef[attrData.refId]
			local attrImg = self:FindWndTrans(attr,"AttrIcon")
			self:SetWndEasyImage(attrImg,attrConf.icon)
			local attrNameTxt = self:FindWndTrans(attr,"AttrName")
			local attrNameStr=ccLngText(attrConf.name)
			attrNameStr =  LUtil.FormatColorStr(attrNameStr,showAct and "storyActive" or "storyUnActive")
			self:SetWndText(attrNameTxt,attrNameStr)
			local attrValue = self:FindWndTrans(attr,"AttrValue")
			local strValue = gModelHero:GetAttributeValueNoNameByIdAndVal(attrData.refId,attrData.numType,attrData.value)
			--strValue =  LUtil.FormatColorStr(strValue,showAct and "lightGreen" or "lightBlue")
			strValue =  LUtil.FormatColorStr(strValue,showAct and "storyActive" or "storyUnActive")
			self:SetWndText(attrValue,strValue)

		end
	end

	local btnSub = self:FindWndTrans(item,"Btn")
	CS.ShowObject(btnSub,status ~= UISagaBookRelationSy.JB_STATUS_RECEIVE)
	local btnRed = self:FindWndTrans(btnSub,"RedPoint")
	CS.ShowObject(btnRed,status == UISagaBookRelationSy.JB_STATUS_CANRECEIVE)
	local actImg =  self:FindWndTrans(item,"ActImg")
	CS.ShowObject(actImg,status == UISagaBookRelationSy.JB_STATUS_RECEIVE)


	local btnStr = status ==UISagaBookRelationSy.JB_STATUS_CANRECEIVE and ccClientText(19741) or ccClientText(19742)
	self:SetWndButtonText(btnSub,btnStr )
	self:SetWndButtonGray(btnSub,status == UISagaBookRelationSy.JB_STATUS_NOACT)

	self:SetWndClick(btnSub,function ()
		gModelHeroBook:OnHeroRelationActiveReq(groupRefId,refId)
	end)
end


function UISagaBookRelationSy:OnClickShareTwitter()
	local isShow, link = gModelPlayer:CheckShowTwitterLink()
	if not isShow then
		return
	end

	if true then
		return
	end

	if gModelPlayer:CheckReceiveSpecialDailyShareRewardGet() then
		gModelPlayer:OnReceiveSpecialDailyReq(ModelPlayer.RECEIVE_SPECIAL_DAILY_SHARE)
	end

	CS.UApplication.OpenURL(link)
end


------------------------------------------------------------------
return UISagaBookRelationSy


