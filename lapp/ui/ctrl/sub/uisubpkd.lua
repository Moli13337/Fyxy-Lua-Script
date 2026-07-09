---
--- Created by Administrator.
--- DateTime: 2023/10/6 21:03:15
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPkD:LChildWnd
local UISubPkD = LxWndClass("UISubPkD", LChildWnd)
UISubPkD.PAGE_BUY = 1				--档位购买
UISubPkD.PAGE_ELITE = 2			--普通版
UISubPkD.PAGE_ADVANCE = 3			--豪华版
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPkD:UISubPkD()
	self.pages = {}
	self._getBtnEff = "fx_anniu_02"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPkD:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPkD:OnCreate()
	LChildWnd.OnCreate(self)
	self._uiCommonList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPkD:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

--领取奖励后，弹奖励获得弹窗
function UISubPkD:OnActivityABCDRewardResp(pb)
	if pb.sid ~= self._sid then return end

	local reward = pb.itemList
	local itemList = {}
	for k,v in ipairs(reward) do
		local tab = {
			itype = tonumber(v.type),
			itemId = tonumber(v.itemId),
			count = tonumber(v.count),
		}
		table.insert(itemList, tab)
	end

	local isShowPassReward = not table.isempty(self._passRewardItemList)
	if isShowPassReward and not self._needShowGift then
		GF.OpenWnd("UIPkAward",{
			itemList = itemList,
			passItemList = self._passRewardItemList,
			passDesc = ccClientText(15813),
			btnTextList = {ccClientText(10102), ccClientText(15812)},
			func = function() self:OnClickBuyAdvance() end,
		})
	else
		gModelWndPop:TryOpenPopWnd("UIAward", {itemList = itemList})
	end
end

function UISubPkD:OnClickOneKeyGet(entryId)--一键领取
	local list ={}
	local checkList = {}
	local getEntryIdList = {}
	local bGuys = self._bGuys
	local advanceList = self.pages[UISubPkD.PAGE_ADVANCE].entry

	for i, v in ipairs(self.pages[UISubPkD.PAGE_ELITE].entry) do
		local curEntryId   = v.entryId
		local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,curEntryId)
		local status = v.goalData.status
		local cfgMoreInfo = string.split(entryCfg1.moreInfo, '=')
		local classIndex =tonumber(cfgMoreInfo[1])	--礼包档次
		local curBGuy  = bGuys[classIndex]
		local isBuy    = curBGuy == "1"

		if(status==1)then
			local data1 = { sid = self._sid,pageId = v.pageId,entryId = curEntryId}
			table.insert(list,data1)
			table.insert(checkList,data1)
			getEntryIdList[curEntryId] = true
		elseif not isBuy and status == 2 then
			getEntryIdList[curEntryId] = true
		end

		if isBuy then
			local advanceData = advanceList[i]
			local status2 = advanceData.goalData.status
			if status2 == 1 then
				local data2 = { sid = self._sid,pageId = advanceData.pageId,entryId = advanceData.entryId}
				table.insert(list,data2)
			end
		end
	end

	--检测是否要显示礼包购买弹窗
	self._needShowGift,self._getGiftTypeList = self:CheckNeedShowGiftPop(checkList)

	--检测是否显示战令奖励弹窗
	self._passRewardItemList = self:GetShowPassRewardList(getEntryIdList)

	gModelActivity:OnActivityReceiveGoalListReq(list)
end

function UISubPkD:ListItem(list,item, itemdata, itempos)
	local isShowItem = itemdata ~= nil
	CS.ShowObject(item, isShowItem)
	if not isShowItem then return end

	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local entryCfg2 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId2,itemdata.entryId2)
	if not entryCfg1 or not entryCfg2 then
		return
	end
	local numText = CS.FindTrans(item,"NumText")
	local rewardList1 = CS.FindTrans(item,"RewardList1")
	local rewardList2 = CS.FindTrans(item,"RewardList2")
	local btnBlue3 = CS.FindTrans(item, "BtnBlue3")
	local btnYellow3 = CS.FindTrans(item, "BtnYellow3")
	local payBtnEff = CS.FindTrans(btnYellow3,"Eff")
	local getImage = CS.FindTrans(item,"GetImage")
	local image = CS.FindTrans(item,"Image")

	local cfgMoreInfo = string.split(entryCfg1.moreInfo, '=')
	local moreInfoIndex =tonumber(cfgMoreInfo[1])	--礼包档次
	local curTypeIndex = tonumber(cfgMoreInfo[2])	--难度序号
	local iconStr = entryCfg1.icon
	local getIconPath = self._getIconPath
	local InstanceID = item:GetInstanceID()
	local reward1List = LxDataHelper.ParseItem(entryCfg1.reward)
	if(reward1List)then
		for i, v in ipairs(reward1List) do
			v.index = 1
			v.moreInfoIndex = moreInfoIndex
		end
	end
	local uiList = self:GetUIScroll(InstanceID.."A")
	if(uiList:GetList())then
		uiList:RefreshList(reward1List)
	else
		uiList:Create(rewardList1,reward1List,function (...) self:RewardListItem(...) end)
	end
	local uiList1 = self:GetUIScroll(InstanceID.."B")
	local reward2List = LxDataHelper.ParseItem(entryCfg2.reward)
	if(reward2List)then
		for i, v in ipairs(reward2List) do
			v.index = 2
			v.moreInfoIndex = moreInfoIndex
		end
	end
	if(uiList1:GetList())then
		uiList1:RefreshList(reward2List)
	else
		uiList1:Create(rewardList2,reward2List,function (...) self:RewardListItem(...) end)
	end
	local entryId = itemdata.entryId
	local status1 = itemdata.goalData.status
	local status2 = itemdata.goalData2.status
	local bGuy = tonumber(self._bGuys[moreInfoIndex])==1
	local fun = function()self:OnClickGoOn(tonumber(entryCfg1.jumpId)) end
	local btnStr = ccClientText(15804)
	local isGray = false
	local isShowGetEff = false
	local hideBtn
	local payBtn
	if(status1 == 1)then
		payBtn = btnYellow3
		hideBtn = btnBlue3
		btnStr = ccClientText(15802)
		isShowGetEff = true
		fun = function()self:OnClickOneKeyGet(entryId) end
	elseif(status1 == 2)then
		payBtn = btnYellow3
		hideBtn = btnBlue3
		btnStr = ccClientText(15803)
		if(status2 == 2)then
			btnStr = ccClientText(15807)
			isGray = true
			fun = nil
		elseif(bGuy)then
			isShowGetEff = true
			fun = function()self:OnClickOneKeyGet(entryId) end
		else
			fun = function()self:OnClickBuyAdvance(moreInfoIndex) end
		end
	else
		payBtn = btnBlue3
		hideBtn = btnYellow3
	end

	CS.ShowObject(getImage,isGray)
	CS.ShowObject(payBtn,not isGray)
	CS.ShowObject(hideBtn,false)

	self:SetWndEasyImage(image,iconStr)
	self:SetWndButtonText(payBtn,btnStr)
	if LxUiHelper.IsImgPathValid(getIconPath) then
		self:SetWndEasyImage(getImage, getIconPath, nil ,true)
	end

	local str = string.gsub(entryCfg1.name,"\\n","\n")
	self:SetWndText(numText,str)
	if(fun)then
		self:SetWndClick(payBtn,fun)
	end

	local instanceId = item:GetInstanceID()
	local effKey = self._getBtnEff..instanceId
	self:DestroyWndEffectByKey(effKey)

	if isShowGetEff then
		self:CreateWndEffect(payBtnEff,self._getBtnEff,effKey,100,false,false)
	end
	CS.ShowObject(payBtnEff,isShowGetEff)
end

function UISubPkD:OnClickHelp()--点击帮助
	local _sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(_sid)
	if not activityData then
		return
	end
	local data = activityData.config
	local title = gModelActivity:GetLngNameByActivitySid(_sid)
	local content = data.helpTipsContent
	GF.OpenWnd("UIBzTips",{title= title,text = content})
end

function UISubPkD:ResetData(pb)
	local sid=pb.sid
	if(self._sid~=sid)then
		return
	end
	for i, v in ipairs(pb.pages) do
		local page=gModelActivity:GenerateActivePageDataFromPb(v)
		self.pages[v.pageId]=page
	end
	self:RefreshData(true)
end

function UISubPkD:TypeListItem(list, item, itemdata, itempos)
	local bgImage = CS.FindTrans(item, "Image")
	local coverImage = CS.FindTrans(item, "CoverImg")
	local numText = CS.FindTrans(item, "NumText")
	local redPoint = CS.FindTrans(item, "redPoint")
	local nameText = self._romeNum[itempos]
	local isSelectType = itempos == self._typeIndex
	local textColor = "ffffffff"
	if isSelectType then
		textColor = "734f22ff"
	end
	self:SetXUITextTransColor(numText, textColor)
	self:SetWndText(numText, nameText)
	CS.ShowObject(bgImage, not isSelectType)
	CS.ShowObject(coverImage,  isSelectType)
	local isShowRed = self._typeRedStatus[itempos] or false
	CS.ShowObject(redPoint, isShowRed)

	self:SetWndClick(item, function()
		self:OnClickType(itempos)
	end)
end

function UISubPkD:InitCommand()
	self._sid = self:GetWndArg("sid")
	self._typeIndex = self:GetWndArg("typeIndex") --难度序号
	local _sid = self._sid

	self._maxTypeNum = 1
	self._romeNum = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "VX", "X",}
	self._typeRedStatus = {}

	gModelActivity:ReqActivityConfigData(_sid)
end

function UISubPkD:RefreshTypeList()
	local isShowTypeList = self._maxTypeNum > 1
	CS.ShowObject(self.mTypeScroll, isShowTypeList)
	if not isShowTypeList then return end

	local dataList = {}
	for i = 1, self._maxTypeNum do
		table.insert(dataList, i)
	end

	if(self._uiTypeList)then
		self._uiTypeList:RefreshData(dataList)
	else
		self._uiTypeList = self:GetUIScroll("typeItemList")
		self._uiTypeList:Create(self.mTypeScroll,dataList,function (...) self:TypeListItem(...) end, UIItemList.NORMAL)
	end
end

function UISubPkD:RefreshData(needJump)
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	local data = JSON.decode(activityData.moreInfo)
	local buyPassNum = data.buyPassNum
	self._bGuys = string.split(buyPassNum,",")

	local _completeIndex = 0
	local schedule = 0
	local moreInfo = 10

	if not self._typeIndex then
		self._typeIndex = 1
	end

	local eliteList = {}
	local advanceList = {}
	if self.pages[UISubPkD.PAGE_ELITE] then
		eliteList = self.pages[UISubPkD.PAGE_ELITE].entry
	end
	if self.pages[UISubPkD.PAGE_ADVANCE] then
		advanceList = self.pages[UISubPkD.PAGE_ADVANCE].entry
	end

	local dataAList = {}
	self._typeRedStatus = {}
	self._grade = 1
	for i, v in ipairs(eliteList) do
		local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		local cfgMoreInfo = string.split(entryCfg1.moreInfo, '=')
		local moreInfoIndex =tonumber(cfgMoreInfo[1])	--礼包档次
		local curTypeIndex = tonumber(cfgMoreInfo[2])	--难度序号
		if curTypeIndex > self._maxTypeNum then
			self._maxTypeNum = curTypeIndex
		end

		if(moreInfo < moreInfoIndex)then break end

		local advanceData = advanceList[i]
		local status1 = v.goalData.status
		local status2 = advanceData.goalData.status
		local haveGet = status1 == 1 or (status2 == 1 and self._bGuys[moreInfoIndex]== "1")

		if self._typeRedStatus[curTypeIndex] == nil or haveGet then
			self._typeRedStatus[curTypeIndex] = haveGet
		end

		if curTypeIndex == self._typeIndex then
			v.goalData2 = advanceData.goalData
			v.moreInfo2 = advanceData.moreInfo
			v.pageId2 = advanceData.pageId
			v.entryId2 = advanceData.entryId
			table.insert(dataAList,v)
			self._grade = moreInfoIndex
			if(v.goalData.status == 0)then
				moreInfo = moreInfoIndex
			else
				_completeIndex = _completeIndex + 1
			end
			local scdle = tonumber(v.goalData.schedules[1].schedule)
			if(scdle > 0)then
				if(schedule<scdle)then
					schedule = scdle
				end
			end
		end
	end

	self:RefreshTypeList()

	CS.ShowObject(self.mUpRedImg,false)
	local isShowBuy = false
	for i = 1, self._grade do
		local guyId = self._bGuys[i]
		if(guyId == "0")then
			CS.ShowObject(self.mUpRedImg,true)
			local entry = self.pages[UISubPkD.PAGE_BUY].entry
			local data = entry[i]
			local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,data.pageId,data.entryId)
			local moreInfoArr = string.split(entryCfg1.moreInfo,"|")
			local str		  = moreInfoArr[2]
			self:SetWndText(self.mUpRedTxt,str)

			local expend2 = tonumber(entryCfg1.expend2)
			str = gModelPay:GetShowByWelfareId(expend2)
			self:SetWndButtonText(self.mBuyBtn,str)
			isShowBuy = true
			break
		end
	end
	CS.ShowObject(self.mBuyBtn,isShowBuy)
	CS.ShowObject(self.mShowImg,not isShowBuy)
	if(self._uiList)then
		self._uiList:RefreshData(dataAList)
	else
		self._uiList = self:GetUIScroll("cell")
		self._uiList:Create(self.mCellScroll,dataAList,function (...) self:ListItem(...) end, UIItemList.WRAP,false)
	end

	local list = self._uiList:GetList()
	--if needJump then
		local index = _completeIndex - 1
		if(index < 4)then
			index = 0

		end
		list:RefreshList(UIListWrap.RefreshMode.Custom,index)
	--else
	--	list:RefreshList(UIListWrap.RefreshMode.Solid)
	--end
	--list:SetLoadAnimationScale(1)
	--list:EnableLoadAnimation(true, 0, 1)
end

function UISubPkD:OnActivityConfigData()
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config

	local path,pos,text
	path = data.buttonIcon
	pos = data.buttonPosition
	if LxUiHelper.IsImgPathValid(path) then
		self:SetAnchorPos(self.mBuyBtn, LxDataHelper.ParseVector2NotEmpty(pos))
	end

	path = data.image
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTop,path,nil,true)
	end
	path = data.descIcon
	pos = data.descIconPosition
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTextImg,path,function ()
			CS.ShowObject(self.mTextImg,true)
		end,true)
		self:SetAnchorPos(self.mTextImg, LxDataHelper.ParseVector2NotEmpty(pos))
	end

	path = data.activateIcon
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mShowImg,path,nil,true)
	end

	self._getIconPath = data.getIcon

	local showHelp = data.helpTips == 1
	CS.ShowObject(self.mHelpBtn,showHelp)
	pos = data.helpTipsPosition
	if showHelp then
		self:SetAnchorPos(self.mHelpBtn, LxDataHelper.ParseVector2NotEmpty(pos))
	end
	text = data.listDesc
	if text then
		local listDescArr = string.split(text,"|")
		self:SetWndText(self.mText0,listDescArr[1])
		self:SetWndText(self.mText1,listDescArr[2])
		self:SetWndText(self.mText2,listDescArr[3])
		self._popDescStr = listDescArr[3]
	end

    text = ccClientText(156)
    if not string.isempty(text) then
        self._helpTipsContent = text
		self:SetWndText(self.mBuyTipsText, text)
		CS.ShowObject(self.mBuyTipsText, true)
		--CS.ShowObject(self.mBuyTipsBtn, true)
    end

	gModelActivity:OnActivityPageReq(self._sid)
end

function UISubPkD:RewardListItem(list, item, itemdata, itempos)
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local root = self:FindWndTrans(item,"itemRoot/Icon")
	local mask = self:FindWndTrans(item,"Mask")
	local itemNum = self:FindWndTrans(item,"itemNum")
	local EffTrans = self:FindWndTrans(item,"Eff")
	local showEff = true
	if(mask)then
		CS.ShowObject(mask,false)
	end
	if(not self._bGuys)then
		self._bGuys = {}
	end
	local bGuy = tonumber(self._bGuys[itemdata.moreInfoIndex])==1
	if(itemdata.index==2 and not bGuy)then
		showEff = false
		CS.ShowObject(mask,true)
	end
	if EffTrans then
		local show = false
		if itemdata.itemType == LItemTypeConst.TYPE_ITEM and showEff then
			LxResUtil.DestroyChildImmediate(EffTrans)
			local itemRef = gModelItem:GetRefByRefId(itemdata.itemId)
			local bgEff = itemRef and itemRef.bgEff or nil
			if not string.isempty(bgEff) then
				show = true
				local instanceId = item:GetInstanceID()
				self:CreateWndEffect(EffTrans,bgEff,instanceId,66,false,false)
			end
		end
		CS.ShowObject(EffTrans,show)
	end

	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
	end
	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
	baseClass:DoApply()
	self:SetIconClickScale(root, true)
	self:SetWndClick(root, function() gModelGeneral:ShowCommonItemTipWnd(itemdata) end)

	--self:SetWndText(itemNum,LUtil.NumberCoversion(itemCount))
end

function UISubPkD:OnClickType(posIndex)
	if posIndex == self._typeIndex then
		return
	end

	self._typeIndex = posIndex
	self:RefreshData()
end

function UISubPkD:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)

    self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)
        local activities = pb.activities
        for i, v in ipairs(activities) do
            local sid = v.sid
            if sid == self._sid then
                self:RefreshData()
                return
            end
        end
    end)

	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then
			return
		end
		self:OnActivityConfigData()
	end)

	self:WndEventRecv(EventNames.ON_WND_CLOSE,function (...) self:OnTargetWndClose(...) end)

	self:WndNetMsgRecv(LProtoIds.ActivityABCDRewardResp,function (pb)
		self:OnActivityABCDRewardResp(pb)
	end)
end

function UISubPkD:CheckNeedShowGiftPop(getList)
	local canBuyIndex
	for i = 1, self._grade do
		local guyId = self._bGuys[i]
		if(guyId == "0")then
			canBuyIndex = i
			break
		end
	end

	--礼包已购买
	if not canBuyIndex then
		return false,nil
	end

	local haveLast = false
	local getIndex
	local getLastData
	local typeIndexList = {}
	for k,v in ipairs(getList) do
		local entryCfg1 = gModelActivity:GetWebActivityEntryData(v.sid,v.pageId,v.entryId)
		local moreInfo  = string.split(entryCfg1.moreInfo, '=')
		local typeIndex = tonumber(moreInfo[1])

		typeIndexList[typeIndex] = true

		--检测是否跨阶级领取了奖励
		if getIndex and getIndex < typeIndex then
			haveLast = true
			break
		end

		if canBuyIndex <= typeIndex then
			getIndex = typeIndex
			getLastData = v
		end
	end

	if not getLastData or haveLast then
		return haveLast,typeIndexList
	end

	--检测是否领取了当前阶级的最后一个
	local nextEntryCfg1 = gModelActivity:GetWebActivityEntryData(getLastData.sid,getLastData.pageId,getLastData.entryId + 1)
	if not nextEntryCfg1 then
		--为最后一个，没有下一个了
		return true,typeIndexList
	end

	local nextMoreInfo  = string.split(nextEntryCfg1.moreInfo, '=')
	local nextTypeIndex = tonumber(nextMoreInfo[1])
	if nextTypeIndex > getIndex then
		haveLast = true
	end

	return haveLast,typeIndexList
end

function UISubPkD:OnClickGet(pageId, entryId)--领取
	gModelActivity:OnActivityReceiveGoalReq(self._sid,pageId,entryId)
end

function UISubPkD:InitEvent()
	self:SetWndClick(self.mHelpBtn, function(...) self:OnClickHelp() end)
	self:SetWndClick(self.mBuyBtn, function(...) self:OnClickBuyAdvance() end)
    self:SetWndClick(self.mBuyTipsBtn, function(...) self:OnClickByTips() end)
end

function UISubPkD:OnTargetWndClose(wndName)
	if wndName == "UIAward" and self._needShowGift then
		--重新开启滑动
		self:ShowGiftPop()
	end
end

---------------------------------------获得奖励弹窗----------------------------------------------
function UISubPkD:GetShowPassRewardList(getEntryIdList) --检测是否显示战令的特殊获得奖励弹窗
	local canBuyIndex
	for i = 1, self._grade do
		local guyId = self._bGuys[i]
		if(guyId == "0")then
			canBuyIndex = i
			break
		end
	end

	--礼包已购买
	if not canBuyIndex then
		return nil
	end

	local list = {}
	local buyIndexList = {}

	--可以领取的进阶版奖励
	for i, v in ipairs(self.pages[UISubPkD.PAGE_ADVANCE].entry) do
		local entryId = v.entryId
		if getEntryIdList[entryId] then
			local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,entryId)

			local moreInfo  = string.split(entryCfg1.moreInfo, '=')
			local buyIndex = tonumber(moreInfo[1])
			if(self._bGuys[buyIndex]=="0")then
				buyIndexList[buyIndex] = true

				local itemList = LxDataHelper.ParseItem(entryCfg1.reward)
				for p,q in ipairs(itemList) do
					local itemId = q.itemId
					if list[itemId] then
						local oldItemNum = list[itemId].itemNum
						list[itemId].itemNum = oldItemNum + q.itemNum
					else
						list[itemId] = q
					end
				end
			end
		end
	end

	--直购奖励
	for i, v in ipairs(self.pages[UISubPkD.PAGE_BUY].entry) do
		if buyIndexList[i] then
			local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
			local itemList = LxDataHelper.ParseItem(entryCfg1.reward)
			for p,q in ipairs(itemList) do
				local itemId = q.itemId
				if list[itemId] then
					local oldItemNum = list[itemId].itemNum
					list[itemId].itemNum = oldItemNum + q.itemNum
				else
					list[itemId] = q
				end
			end
		end
	end

	local resultList = {}
	for k,v in pairs(list) do
		table.insert(resultList, v)
	end

	return resultList
end

function UISubPkD:OnClickByTips()
    if not self._helpTipsContent then return end

    local title = gModelActivity:GetLngNameByActivitySid(self._sid)
    GF.OpenWnd("UIBzTips",{title= title,text = self._helpTipsContent})
end

------------------------------------------------------------------------------------------
function UISubPkD:OnClickGoOn(jimpId)--前往
	if not jimpId then
		printInfoNR("jimpId is a nil")
		return
	end

	local isOpen = gModelFunctionOpen:CheckIsOpened(jimpId,true)
	if isOpen then
		gModelFunctionOpen:Jump(jimpId, self:GetWndName())
	end
end

---------------------------------------引导礼包购买弹窗----------------------------------------------
function UISubPkD:ShowGiftPop() --显示礼包购买弹窗界面
	self._needShowGift = false
	local entry = self.pages[UISubPkD.PAGE_BUY].entry

	local defaultIndex = 1
	local typeList = self._getGiftTypeList
	for i, v in ipairs(self._bGuys) do
		if(v == "0" and (not typeList or typeList[i]))then
			defaultIndex = i
			break
		end
	end

	local itemdata = entry[defaultIndex]
	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local moreInfo = string.split(entryCfg1.moreInfo,"|")
	local reward1 = moreInfo[1]
	local expend2 = tonumber(entryCfg1.expend2)
	local buyBtnStr = gModelPay:GetShowByWelfareId(expend2)
	local descStr = self._popDescStr
	descStr = string.replace(ccClientText(15811), descStr)

	GF.OpenWnd("UIPkBuyPop",
			{sid = self._sid,entry = entry, reward1 = reward1,
			 descStr = descStr, buyBtnStr = buyBtnStr, defaultIndex = defaultIndex})
end

function UISubPkD:OnClickBuyAdvance(index)--购买进阶令
	local entry = self.pages[UISubPkD.PAGE_BUY].entry
	GF.OpenWnd("UIPkBuyPopBig",
			{sid = self._sid,entry = entry, grade = self._grade,
			 index = index, modelActivityType = ModelActivity.MODEL_PASSD})
end
------------------------------------------------------------------
return UISubPkD


