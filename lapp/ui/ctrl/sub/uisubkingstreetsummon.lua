---
--- Created by BY.
--- DateTime: 2023/10/6 17:30:19
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubKingStreetSummon:LChildWnd
local UISubKingStreetSummon = LxWndClass("UISubKingStreetSummon", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubKingStreetSummon:UISubKingStreetSummon()
	self._rankTabList = {}
	self._uiIconEasyList = {}
	self._uiCommonList = {}
	self._timeKey = "UISubKingStreetSummon_timeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubKingStreetSummon:OnWndClose()
	self:ClearCommonIconList(self._uiIconEasyList)
	self:ClearCommonIconList(self._uiCommonList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubKingStreetSummon:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubKingStreetSummon:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
--------------------------------------------设置排行begin------------------------------------------------
function UISubKingStreetSummon:SetRankInfo2()
	local rankId = self._dataW_RankId
	local _reqRankId = self._rankId
	if not string.isempty(rankId) and not _reqRankId then
		local rankIdArr = string.split(rankId,"|")
		for i, v in ipairs(rankIdArr) do
			local arr = string.split(v,"=")
			local _rankId = tonumber(arr[1])
			_reqRankId = _rankId
			self._rankPageId = tonumber(arr[2])
			break
		end
	end
	self._rankId = _reqRankId
	gModelRank:OnRankReq(2,_reqRankId,1,3,self._sid)
	CS.ShowObject(self.mRankBg2,true)
end
function UISubKingStreetSummon:ListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local itemBg = self:FindWndTrans(root,"ItemBg")
	local itemIcon = self:FindWndTrans(itemBg,"ItemIcon")
	--local itemAdd = self:FindWndTrans(itemBg,"ItemAdd")
	local itemText = self:FindWndTrans(itemBg,"ItemText")

	local itemId = itemdata.itemId
	local icon,iconBg = gModelItem:GetItemImgByRefId(itemId)
	local itemNum = gModelItem:GetNumByRefId(itemId)

	self:SetWndEasyImage(itemIcon,icon)
	self:SetWndText(itemText,LUtil.NumberCoversion(itemNum))

	self:SetWndClick(root,function ()
		local wndName = self._modelWndName[self._modelId]
		gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = wndName})
	end)
end
function UISubKingStreetSummon:OnClickClose()
	local wndName = self._modelWndName[self._modelId]
	GF.CloseWndByName(wndName)
end
function UISubKingStreetSummon:RefreshData()
	local sid = self._sid
	local pages = self.pages
	local _turnTableEnum = self._turnTableEnum
	if not sid or not _turnTableEnum or not pages then return end
	local pageEntry = pages[_turnTableEnum]
	if not pageEntry then return end
	local activityDataS = gModelActivity:GetActivityBySid(sid)
	local activityDataW = gModelActivity:GetWebActivityDataById(sid)
	if not activityDataS or not activityDataW then return end
	--------------------------------------后端数据------------------------------------------------
	local dataS = JSON.decode(activityDataS.moreInfo)
	local freeNum = dataS.freeNum or 0				--免费次数
	local callNum = dataS.callNum or 0				--钻石购买次数
	local dropNumToday = dataS.dropNumToday or 0	--今天总掉落次数
	local myDropNum = dataS.myDropNum or 0			--保底次数
	local mySelect = dataS.mySelect					--我的选择
	self._freeNum,self._callNum,self._dropNumToday = freeNum,callNum,dropNumToday
	----------------------------------------------------------------------------------------------
	--------------------------------------配置数据------------------------------------------------
	local dataW = activityDataW.config
	local callBtnTxt = dataW.callBtnTxt
	local callLimitTips = dataW.callLimitTips
	local callMaxNum = dataW.callMaxNum
	local diaCallLimitTips = dataW.diaCallLimitTips
	local goldTimes = dataW.goldTimes
	self._callCurrencyBar = dataW.callCurrencyBar

	local rankId = dataW.rankId
	local wishHero = dataW.wishHero
	self._dataW_RankId = rankId


	----------------------------------------------------------------------------------------------
	if not string.isempty(callBtnTxt) then
		local _callBtnTxt = string.split(callBtnTxt,"=")
		local btnOneStr = freeNum > 0 and _callBtnTxt[1] or _callBtnTxt[2]
		self:SetWndText(self.mOneText,btnOneStr)
		self:SetWndText(self.mTenText,_callBtnTxt[3])
	end
	if not string.isempty(callLimitTips) then
		CS.ShowObject(self.mCallNumBg,true)
		self:SetWndText(self.mCallNumText,string.replace(callLimitTips,dropNumToday,callMaxNum))
	end
	if not string.isempty(diaCallLimitTips) then
		self:SetWndText(self.mTipsText,string.replace(diaCallLimitTips,goldTimes - callNum))
	end

	self:RefreshBtnText()
	self:RefreshItem()
	if self._numImgTrans then
		CS.ShowObject(self._numImgTrans,mySelect and mySelect>0)
	end

	if self._enNameTextTrans then
		CS.ShowObject(self._enNameTextTrans,mySelect and mySelect>0)
	end
	--self:SetRankInfo(rankId)
	if not mySelect then return end
	local _itemData
	for i, v in ipairs(pageEntry.entry) do
		local entryId = v.entryId
		if mySelect == entryId then
			_itemData = v
			break
		end
	end
	local guaNum = 0
	if not string.isempty(wishHero)then
		local wishHeroArr = string.split(wishHero,";")
		for i, v in ipairs(wishHeroArr) do
			local arr = string.split(v,"=")
			local id = tonumber(arr[1])
			if id == mySelect then
				guaNum = tonumber(arr[2])
			end
		end
	end
	self._mySelect = mySelect
	local guaNum = guaNum - myDropNum

	if self._enTextTrans then
		CS.ShowObject(self._enTextTrans, true)
		self:SetWndText(self._enTextTrans,guaNum <= 1 and ccClientText(24725)or guaNum)
	end

	CS.ShowObject(self.mSelEff,not _itemData)
	if _itemData then
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,_itemData.pageId,_itemData.entryId)
		local reward = LxDataHelper.ParseItem_3(entryCfg.reward)

		reward.trans = self.mSelIcon
		reward.instanceID = "UISubKingStreetSummon_instanceID"
		self:CreateCommonIcon(reward)
	else
		self:CreateWndEffect(self.mSelEff,"fx_ui_shou","mSelEff",100)
	end
end
function UISubKingStreetSummon:OnClickDetails()
	GF.OpenWnd("UIProlicPop",{sid = self._sid})
end
function UISubKingStreetSummon:InitEvent()
	self:SetWndClick(self.mBtnHelp,function (...)self:OnClickHelp() end)
	self:SetWndClick(self.mBtnOne,function (...)self:OnClickOneTen(1) end)
	self:SetWndClick(self.mBtnTen,function (...)self:OnClickOneTen(10) end)
	self:SetWndClick(self.mBtnLog,function (...)self:OnClickLog() end)
	self:SetWndClick(self.mBtnShop, function() self:OnClickShop() end)
	self:SetWndClick(self.mBtnDetails,function () self:OnClickDetails() end)
	self:SetWndClick(self.mBtnSelBg,function () self:OnClickSel() end)
	self:SetWndClick(self.mBtnRankDes,function () self:OnClickRank() end)
	self:SetWndClick(self.mRankBg2,function () self:OnClickRank() end)
end
function UISubKingStreetSummon:SetTime()
	local _para = self._para
	self._isWndCall = false
	if _para then
		GF.OpenWndTop("UIYellSagaAward",_para)
		self._para = nil
		return
	end
end
function UISubKingStreetSummon:RefreshRank2(pb)
	local infos = pb.infos
	local list = {}
	for i, v in ipairs(infos) do
		local info = v.info
		local name = info.name
		local score = v.score
		local rank = v.rank
		local data = {
			rank = rank,
			name = name,
			score = score,
		}
		table.insert(list,data)
	end
	local len = #list
	for i = 1, 3 - len do
		table.insert(list,{rank = len + i})
	end
	local _uiRankList2 = self._uiRankList2
	if _uiRankList2 then
		_uiRankList2:RefreshList(list)
	else
		_uiRankList2 = self:GetUIScroll("mRankCellScroll_UISubKingStreetSummon")
		_uiRankList2:Create(self.mRankCellScroll,list,function (...) self:RankListItem2(...) end)
		self._uiRankList2 = _uiRankList2
	end
end
--------------------------------------------点击事件end--------------------------------------------------

function UISubKingStreetSummon:OnTimer(key)
	if(key == self._timeKey)then
		self:SetTime()
	end
end
--------------------------------------------兑换道具end--------------------------------------------------

function UISubKingStreetSummon:CreateSpine(key,ani,loop,spineName)
	local _dpSpine = self._dpSpine
	if not _dpSpine then
		self:CreateWndSpine(self.mHeroSpine,spineName,key,false,function (dpSpine)
			dpSpine:PlayAnimation(0,ani,loop)
			self._dpSpine = dpSpine
		end)
	else
		_dpSpine:PlayAnimation(0,ani,loop)
		if not loop then
			_dpSpine:SetAnimationCompleteFunc(function (ainName)
				if ainName == ani then
					_dpSpine:PlayAnimation(0,"idle",true)
				end
			end)
		end
	end
end
function UISubKingStreetSummon:ResetData(pb)
	if pb.sid ~= self._sid then return end
	local pages = self.pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		pages[v.pageId] = page
	end
	self.pages = pages
	self:RefreshData()
end
function UISubKingStreetSummon:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function(pb)
		self:RefreshData()
		self:SetRankInfo2()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb)
		self:RefreshData()
		self:SetRankInfo2()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb) self:ResetData(pb) end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
	self:WndNetMsgRecv(LProtoIds.RankResp,function (pb)
		local sid = pb.activityId
		if(not sid or self._sid ~= sid)then return end
		self:RefreshRank2(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ItemChangeResp,function (pb)
		self:RefreshItem()
		self:RefreshBtnText()
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CALL_RETURN,function (para)
		local sid = para.sid
		if sid ~= self._sid then return end
		self._para = para
		if self._isWndCall then
			self:CreateWndEffect(self.mEff,self._callEff,"UISubKingStreetSummon_callEff",Vector3(100,120,100))
			self:CreateSpine("mHeroSpine","attack1",false)
			self:TimerStop(self._timeKey)
			self:TimerStart(self._timeKey,self._showResultTime or 1,true,1)
		else
			self:SetTime()
		end
	end)
end
--[[
function UISubKingStreetSummon:SetRankInfo(rankId)
	if not string.isempty(rankId) and  not self._isOne then
		local _rankIds = {}
		local rankIdArr = string.split(rankId,"|")
		for i, v in ipairs(rankIdArr) do
			local arr = string.split(v,"=")
			local data = {
				rankId = tonumber(arr[1]),
				pageId = tonumber(arr[2])
			}
			table.insert(_rankIds,data)
		end
		self._isOne = true
		local rankLen = #_rankIds
		CS.ShowObject(self.mRankBg,rankLen > 0)
		CS.ShowObject(self.mRankTabScroll,rankLen > 1)
		CS.ShowObject(self.mTitleText,rankLen == 1)
		if rankLen <= 0 then return end
		if rankLen == 1 then
			local _rankId = _rankIds[1].rankId
			self._rankId = _rankId
			self._rankPageId = _rankIds[1].pageId
			local ref = gModelRank:GetRankingRefData(_rankId)
			self:SetWndText(self.mTitleText,ccLngText(ref.nameTitle))
			self:RefreshRank()
			return
		end
		local _uiCellList = self:GetUIScroll("mRankTabScroll")
		_uiCellList:Create(self.mRankTabScroll,_rankIds,function (...) self:RankTabListItem(...) end)
		self:OnClickRankTab(_rankIds[1].rankId,_rankIds[1].pageId)
	end
	self:RefreshRank()
end
function UISubKingStreetSummon:RankTabListItem(list,item, itemdata, itempos)
	local btnTab = self:FindWndTrans(item,"BtnTab")

	local _rankId = itemdata.rankId
	local ref = gModelRank:GetRankingRefData(_rankId)
	self._rankTabList[_rankId] = btnTab

	self:SetWndTabText(btnTab,ccLngText(ref.nameTitle))
	self:SetWndTabStatus(btnTab, 1)
	self:SetWndClick(btnTab,function ()
		self:OnClickRankTab(_rankId,itemdata.pageId)
	end)
end
function UISubKingStreetSummon:OnClickRankTab(rankId,pageId)
	local _rankTabList = self._rankTabList
	local _rankId = self._rankId
	if _rankId then
		local trans = _rankTabList[_rankId]
		self:SetWndTabStatus(trans, 1)
	end
	local trans = _rankTabList[rankId]
	self:SetWndTabStatus(trans, 0)
	self._rankId = rankId
	self._rankPageId = pageId
	self:RefreshRank()
end
function UISubKingStreetSummon:RefreshRank(pb)
	local _rankId = self._rankId
	local _rankRewardId = self._rankPageId
	if not _rankId or not _rankRewardId then return end
	local pages = self.pages
	local sid = self._sid

	local page = pages[_rankRewardId]
	if not page then return end
	local activityDataS = gModelActivity:GetActivityBySid(sid)
	if not activityDataS then return end
	local dataS = JSON.decode(activityDataS.moreInfo)
	local score = dataS["ascore_".._rankRewardId]
	local rank = dataS["ascoreCond_".._rankRewardId]

	self:SetWndText(self.mMeStrText,rank > 0 and rank or ccClientText(26422))
	self:SetWndText(self.mDesStrText,string.replace(ccClientText(26423),score))

	local _rewardList = LxDataHelper.SevenParseRewardList(sid,page)
	local curRank = _rewardList[#_rewardList]
	for i, v in ipairs(_rewardList) do
		local rankArr = string.split(v.rank,",")
		if tonumber(rankArr[1]) <= rank and rank <= tonumber(rankArr[2]) then
			curRank = v
			break
		end
	end
	local award = curRank.reward
	local itemList = LxDataHelper.ParseItem(award)
	self:InitItemList("UISubKingStreetSummon_mAwardRoot",self.mAwardRoot,itemList)
end
function UISubKingStreetSummon:InitItemList(InstanceID,awardRoot,itemList)
	local uiIconEasyList = self._uiIconEasyList[InstanceID]
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		self._uiIconEasyList[InstanceID] = uiIconEasyList
		uiIconEasyList:Create(self, awardRoot)
		uiIconEasyList:EnableScroll(true,true)
	end
	uiIconEasyList:RefreshList(itemList)
end
--]]
--------------------------------------------设置排行end--------------------------------------------------

--------------------------------------------兑换道具begin------------------------------------------------
function UISubKingStreetSummon:RefreshItem()
	local callCurrencyBar = self._callCurrencyBar

	local _currency = callCurrencyBar
	local list = {}
	if not string.isempty(_currency) then
		local arr = string.split(_currency,"|")
		for i, v in ipairs(arr) do
			table.insert(list,{itemId = tonumber(v)})
		end
	end
	local _uiCellList = self._uiCellList
	if _uiCellList then
		_uiCellList:RefreshList(list)
	else
		_uiCellList = self:GetUIScroll("mItemScroll")
		_uiCellList:Create(self.mItemScroll,list,function (...) self:ListItem(...) end)
		self._uiCellList = _uiCellList
	end
end
function UISubKingStreetSummon:OnClickOneTen(num)
	if self._isWndCall then return end
	local _mySelect = self._mySelect
	if not _mySelect or _mySelect == 0 then
		local _guaRewardTxt = self._guaRewardTxt or ""
		GF.ShowMessage(string.replace(ccClientText(26804),_guaRewardTxt))
		return
	end
	local wndName = self._modelWndName[self._modelId]
	gModelActivity:GetCallDataBySid(self._sid,self._pageId,num == 1 and 1 or 2,wndName,nil,function ()
		self._isWndCall = true
	end)
end
function UISubKingStreetSummon:CreateCommonIcon(data)
	local instanceID = data.instanceID
	local trans = data.trans
	local itemType,itemId,itemNum = data.itemType, data.itemId, data.itemNum
	local baseClass = self._uiCommonList[instanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiCommonList[instanceID] = baseClass
		baseClass:Create(trans)
	end
	baseClass:SetCommonReward(itemType,itemId,itemNum)
	local showNum = itemNum > 0
	baseClass:EnableShowNum(showNum)
	baseClass:DoApply()
end
function UISubKingStreetSummon:RankListItem2(list,item, itemdata, itempos)
	local rankImg = self:FindWndTrans(item,"RankImg")
	local nameText = self:FindWndTrans(item,"NameText")
	local scoreText = self:FindWndTrans(item,"ScoreText")

	self:SetWndEasyImage(rankImg,"public_num_"..itempos)
	self:SetWndText(nameText,itemdata.name or ccClientText(26803))
	self:SetWndText(scoreText,itemdata.score or "")
end
function UISubKingStreetSummon:InitCommand()
	local sid = self:GetWndArg("sid")
	local entry = self:GetWndArg("entry")
	self.pages = self:GetWndArg("pages")
	self._pageId = entry[1].pageId

	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._modelId = modelId
	self._sid = sid
	local enum = self._modelEnumList[modelId]
	self._turnTableEnum = enum					--奖池表枚举
	--gModelActivity:ReqActivityConfigData(sid)
	self:OnActivityConfigData()
	self:SetRankInfo2()
end

function UISubKingStreetSummon:InitData()
	self._modelWndName = {
		[ModelActivity.MODEL_ACTIVITY_TYPE_68] = "UIActKingStreet",
	}
	self._modelEnumList = {
		[ModelActivity.MODEL_ACTIVITY_TYPE_68] = ModelActivity.KING_STREET_3,
	}

	self:SetWndText(self.mDetailsText,ccClientText(25913))
	self:SetWndText(self.mLogText,ccClientText(25914))
	self:SetWndText(self.mShopText,ccClientText(25915))
	self:SetWndText(self.mMeText,ccClientText(26421))
	self:SetWndText(self.mDesText,ccClientText(26802))
	self:SetWndText(self.mRwardText,ccClientText(26419))
	self:SetWndText(self.mRankDesText,ccClientText(26805))
	self:SetWndText(self.mRankLookText,ccClientText(26805))
end
function UISubKingStreetSummon:RefreshBtnText()
	local sid = self._sid
	if not sid then return end
	local activityDataW = gModelActivity:GetWebActivityDataById(sid)
	local dataW = activityDataW.config
	local costOne1,costOne2,costTen1,costTen2 = dataW.costOne1,dataW.costOne2,dataW.costTen1,dataW.costTen2
	local _costOne1 = LxDataHelper.ParseItem_3(costOne1)
	local _costOne2 = LxDataHelper.ParseItem_3(costOne2)
	local _costTen1 = LxDataHelper.ParseItem_3(costTen1)
	local _costTen2 = LxDataHelper.ParseItem_3(costTen2)
	local goldTimes = dataW.goldTimes

	--local bagDiaNum = gModelItem:GetNumByRefId(_costOne1.itemId)
	local bagItemNum = gModelItem:GetNumByRefId(_costOne2.itemId)
	local freeNum = self._freeNum
	local _callNum = self._callNum

	--local residueDisNum = goldTimes - _callNum

	CS.ShowObject(self.mOneCostText,freeNum < 1)
	if freeNum < 1 then
		local isItemCost = bagItemNum >= 1
		local oneCostStr = isItemCost and _costOne2.itemNum or _costOne1.itemNum
		local oneCostRefId = isItemCost and _costOne2.itemId or _costOne1.itemId
		local icon,iconBg = gModelItem:GetItemImgByRefId(oneCostRefId)
		self:SetWndText(self.mOneCostText,oneCostStr)
		self:SetWndEasyImage(self.mOneCostIcon,icon)
	end
	CS.ShowObject(self.mTenCostText,freeNum < 10)
	if freeNum < 10 then
		local isItemCost = bagItemNum >= 10
		local tenCostStr = isItemCost and _costTen2.itemNum or _costTen1.itemNum
		local tenCostRefId = isItemCost and _costTen2.itemId or _costTen1.itemId
		local icon,iconBg = gModelItem:GetItemImgByRefId(tenCostRefId)
		self:SetWndText(self.mTenCostText,tenCostStr)
		self:SetWndEasyImage(self.mTenCostIcon,icon)
	end
end


--------------------------------------------点击事件begin------------------------------------------------
function UISubKingStreetSummon:OnClickHelp()
	local _wishCallHelpTxt = self._wishCallHelpTxt or ""
	_wishCallHelpTxt = string.gsub(_wishCallHelpTxt,"\\n","\n")
	GF.OpenWnd("UIBzTips",{title = self._wishCallHelpTitle,text = _wishCallHelpTxt})
end
function UISubKingStreetSummon:OnClickRank()
	local sid = self._sid
	local _pages = self.pages
	local _rankRewardId = self._rankPageId
	local page =  _pages[_rankRewardId]
	local _modelId = self._modelId
	local _modelWndName = self._modelWndName
	if not page then return end
	local _rewardList = LxDataHelper.SevenParseRewardList(sid,page)
	GF.OpenWndBottom("UIRkPop",{refId = self._rankId,sid = sid,rewardList = _rewardList,callFunc = function()
		local wndName = _modelWndName[_modelId]
		GF.OpenWnd(wndName,{sid = sid,page = 1})
	end})
	self:OnClickClose()
end
function UISubKingStreetSummon:OnActivityConfigData()
	local _sid = self._sid
	if not self.pages then
		gModelActivity:OnActivityPageReq(_sid)
	end
	local activityData = gModelActivity:GetWebActivityDataById(_sid)
	local data = activityData.config
	local wishCallBg,guaTxt,guaRewardTxt,guaRewardTxtPos,callHeroImg,callHeroPos,callHeroTxt,callEffPos
	= data.wishCallBg,data.guaTxt,data.guaRewardTxt,data.guaRewardTxtPos,data.callHeroImg,data.callHeroPos,data.callHeroTxt,data.callEffPos
	self._wishCallHelpTitle,self._wishCallHelpTxt = data.wishCallHelpTitle,data.wishCallHelpTxt
	self._logTitle,self._logTips,self._logTimeTips = data.logTitle,data.logTips,data.logTimeTips
	self._guaRewardTxt = guaRewardTxt
	self._callEff = data.callEff
	self._showResultTime = data.showResultTime or 1
	local shopId = data.shopId

	CS.ShowObject(self.mBtnShop,shopId)
	if not string.isempty(callEffPos) then
		local pos = LxDataHelper.ParseVector2NotEmpty3(callEffPos)
		self:SetAnchorPos(self.mEff, pos)
	end
	if not string.isempty(callHeroImg) then
		local imgArr = string.split(callHeroImg,"=")
		local posParent
		if imgArr[1] == "1" then
			posParent = self.mHeroImg
			self:SetWndEasyImage(posParent,imgArr[2],nil,true)
		else
			posParent = self.mHeroSpine
			local spineName = imgArr[2]
			--self:CreateWndSpine(posParent,spineName,spineName.."UISubKingStreetSummon",false)
			self:CreateSpine("mHeroSpine","idle",true,spineName)
		end
		if imgArr[3] then
			local flip = tonumber(imgArr[3])
			posParent.localScale = Vector2.New(flip,1)
		end
		CS.ShowObject(posParent,true)
		if not string.isempty(callHeroPos) then
			local pos = LxDataHelper.ParseVector2NotEmpty3(callHeroPos)
			self:SetAnchorPos(posParent, pos)
		end
	end
	if not string.isempty(callHeroTxt) then
		local text = string.gsub(callHeroTxt,"\\n","\n")
		self:SetWndText(self.mHeroText,text)
	end
	if LxUiHelper.IsImgPathValid(wishCallBg) then
		CS.ShowObject(self.mBg,true)
		self:SetWndEasyImage(self.mBg,wishCallBg)
	end

	local numImgTrans, enTextTrans,enNameTextTrans
	if gLGameLanguage:IsEnglishVersion() then
		numImgTrans = self.mGetHeroNumImage
		enTextTrans = self.mGetHeroEnNumTxt
		enNameTextTrans = self.mGetHeroEnNameTxt
	elseif gLGameLanguage:IsGermanVersion() then
		numImgTrans = self.mGetHeroNumImageDe
		enTextTrans = self.mGetHeroNumTxtDe
		enNameTextTrans = self.mGetHeroNameTxtDe
	elseif gLGameLanguage:IsFrenchVersion() then
		numImgTrans = self.mGetHeroNumImageDe
		enTextTrans = self.mGetHeroNumTxtFr
		enNameTextTrans = self.mGetHeroNameTxtFr
	elseif gLGameLanguage:IsThaiVersion() then
		numImgTrans = self.mGetHeroNumImageTh
		enTextTrans = self.mGetHeroNumTxtTh
		enNameTextTrans = self.mGetHeroNameTxtTh
	elseif gLGameLanguage:IsKoreaVersion() then
		numImgTrans = self.mGetHeroNumImage
		enTextTrans = self.mGetHeroKoNumTxt
		enNameTextTrans = self.mGetHeroKoNameTxt
	elseif gLGameLanguage:IsVietnamVersion() then
		numImgTrans = self.mGetHeroNumImage
		enTextTrans = self.mGetHeroVieNumTxt
		enNameTextTrans = self.mGetHeroVieNameTxt
	else
		numImgTrans = self.mGetHeroNumImage
		enTextTrans = self.mGetHeroNumTxt
		enNameTextTrans = self.mGetHeroNameTxt
	end
	self._numImgTrans = numImgTrans
	self._enTextTrans = enTextTrans
	self._enNameTextTrans = enNameTextTrans

	local pos = data.guaImgPos
	if LxUiHelper.IsImgPathValid(guaTxt) then
		CS.ShowObject(numImgTrans, true)
		self:SetWndEasyImage(numImgTrans,guaTxt,nil,true)

		if not string.isempty(pos) then
			self:SetAnchorPos(numImgTrans, LxDataHelper.ParseVector2NotEmpty3(pos))
		end
	end

	pos = data.guaNumPos
	if not string.isempty(pos) then
		self:SetAnchorPos(enTextTrans, LxDataHelper.ParseVector2NotEmpty3(pos))
	end

	if not string.isempty(guaRewardTxt) then
		local parent = self._enNameTextTrans
		CS.ShowObject(parent,true)
		self:SetWndText(parent,guaRewardTxt)
		if not string.isempty(guaRewardTxtPos) then
			pos = LxDataHelper.ParseVector2NotEmpty3(guaRewardTxtPos)
			self:SetAnchorPos(parent, pos)
		end
		self:SetWndText(self.mSelTipsText,guaRewardTxt)
	end

	self:RefreshData()
end
function UISubKingStreetSummon:OnClickSel()
	GF.OpenWnd("UIActSummonCumSelect",{sid = self._sid,pages = self.pages})
end
function UISubKingStreetSummon:OnClickLog()
	local titleStr,tipsStr,timeStr = self._logTitle,self._logTips,self._logTimeTips
	GF.OpenWnd("UIYellLog",{sid = self._sid,callType = 3,titleStr = titleStr,tipsStr = tipsStr,timeStr = timeStr})
end
function UISubKingStreetSummon:OnClickShop()
	GF.OpenWndBottom("UIDian",{page = ModelShop.ACTIVITY,subPage = self._sid})
	self:OnClickClose()
end
------------------------------------------------------------------
return UISubKingStreetSummon


