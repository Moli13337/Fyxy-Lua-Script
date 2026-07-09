---
--- Created by ly.
--- DateTime: 2023/10/8 15:49:55
---
---活动77等级礼包
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubActUpdeGift:LChildWnd
local UISubActUpdeGift = LxWndClass("UISubActUpdeGift", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubActUpdeGift:UISubActUpdeGift()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubActUpdeGift:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubActUpdeGift:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubActUpdeGift:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitMessage()
	self:InitData()
end



function UISubActUpdeGift:InitItemList(dataList)
	if(self._itemUIList)then
		self._itemUIList:RefreshList(dataList)
	else
		self._itemUIList = self:GetUIScroll("itemList")
		self._itemUIList:Create(self.mItemList,dataList,function(...) self:SetUpItem(...) end, UIItemList.WRAP,false)
	end


	local list= self._itemUIList:GetList()   --定位
	local index = self._completeIndex - 1
	if(index < 4)then
		index = 0
	else
		index = index - 2
	end
	list:RefreshList(UIListWrap.RefreshMode.Custom,index)
	self:MoveListPos(self._completeIndex)
end

function UISubActUpdeGift:InitMessage()

	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function(...)
		self:OnActivityConfigData(...)
	end)

	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (...)
		self:OnActivityPageResp(...)
		if self._markIndex~=0 then
			self:MoveListPos(self._markIndex)
		end
	end)

	self:WndNetMsgRecv(LProtoIds.ActivityResp,function()
		self:AssignTop()
	end)
	self:WndNetMsgRecv(LProtoIds.PlayerChangeResp,function (...)
		gModelActivity:OnActivityPageReq(self._sid)
	end)

end



function UISubActUpdeGift:OnActivityConfigData(data,sid)
	if sid ~= self._sid then return end
	self:AssignTop()
	gModelActivity:OnActivitySpecialOpReq(self._sid,1,nil,ModelActivity.CANCEL_RED_POINT, "1")
	gModelActivity:OnActivityPageReq(self._sid)

end

function UISubActUpdeGift:InitData()
	self._sid = self:GetWndArg("sid")
	gModelActivity:ReqActivityConfigData(self._sid)
	self._markIndex=0
end

function UISubActUpdeGift:SetUpGrid(list,item,itemdata,itempos)
	local aniRoot=self:FindWndTrans(item,"Root")
	local root=self:FindWndTrans(aniRoot,"Icon")
	local mask=self:FindWndTrans(aniRoot,"Mask")

	local isShowMask=self._isMask
	self:CreateCommonIconImpl(root,itemdata)

	CS.ShowObject(root,not isShowMask)
	CS.ShowObject(mask,isShowMask)

	if self._showAll then
		isShowMask=false
		CS.ShowObject(root,not isShowMask)
		CS.ShowObject(mask,isShowMask)
	end




end


function UISubActUpdeGift:SetUpItem(list,item,itemdata,itempos)
	local lvNum=self:FindWndTrans(item,"Lv/LvNum")                    --等级
	local receiveBtn=self:FindWndTrans(item,"ReceiveBtn")		     --领取按钮
	local receivedImg=self:FindWndTrans(item,"ReceivedImg")          --完成 图标
	local gridList=self:FindWndTrans(item,"GridList")


	CS.ShowObject(receiveBtn,false)
	CS.ShowObject(receivedImg,false)
	self:SetWndClick(receiveBtn,function() end)

	self:SetWndText(lvNum,ccClientText(29402, itemdata.moreInfo))

	local instanceID=item:GetInstanceID()
	local _gridList = self:FindUIScroll(instanceID)

	local rewardData=itemdata.reward

	self._isMask= itemdata.moreInfo >= self._maskLeve and itemdata.id>6  --特殊处理


	if (_gridList) then
		_gridList:RefreshList(rewardData)
	else
		_gridList = self:GetUIScroll(instanceID)
		_gridList:Create(gridList,rewardData,function(...) self:SetUpGrid(...) end)
		_gridList:RefreshList(rewardData)
	end
	_gridList:DrawAllItems()
	_gridList:EnableScroll(false,false)

	if not itemdata.buyState then
		CS.ShowObject(receivedImg,true)
		return
	end


	local lockState= itemdata.lockState
	local items = LxDataHelper.ParseItem_3(itemdata.expend2)
	self:SetWndButtonGray(receiveBtn,not lockState)

	CS.ShowObject(receiveBtn,true)

	if lockState then

		local value=items.itemNum
		self:SetWndButtonText(receiveBtn,value)
		local str=string.replace(ccClientText(29403),itemdata.moreInfo)

		local func = function()

			local num = gModelItem:GetNumByRefId(ModelItem.ITEM_DIAMOND)
			num = tonumber(num)
			local isEnough=value-num < 0

			if isEnough then
				gModelActivity:OnActivityMarkeyBuyReq(self._sid,self.pageId,itemdata.id)
			else
				gModelGeneral:OpenGetWayWnd({itemId = items.itemId})
			end
			self._markIndex=itemdata.entryId
		end

		local priceItemName = gModelItem:GetNameByRefId(items.itemId)
		local costStr = value .. priceItemName

		self:SetWndClick(receiveBtn,function()
			local para =
			{
				refId = 50401,
				func=func,
				para ={costStr,str},
				consume = {items.itemNum, items.itemId},
			}

			gModelGeneral:OpenUIOrdinTips(para)
		end)




	else
		self:SetWndButtonText(receiveBtn,ccClientText(29401))
		self:SetWndClick(receiveBtn,function() end)
	end



end


function UISubActUpdeGift:AssignTop()                        --设置顶部数据
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	local activityMoreInfo = JSON.decode(activityData.moreInfo)
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then return end
	local data = webData.config

	local path = data.image
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mImage,path)
	end

	path = data.descIconA
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mDescIconA,path,function() CS.ShowObject(self.mDescIconA,true) end, true)
	end

	--帮助按钮
	CS.ShowObject(self.mHelpTipsBtn,data.helpTips == 1)
	self:SetWndClick(self.mHelpTipsBtn,function()
		GF.OpenWnd("UIBzTips",{title= activityData.title,text = data.helpTipsContent})
	end)



end

function UISubActUpdeGift:FreshView(page)

	local dataList = {}
	page = gModelActivity:GenerateActivePageDataFromPb(page)

	local canInsLockNum = 2
	local recordLockNum = 0

	local lockList={}
	local playerLv=gModelPlayer:GetPlayerLv()
	self._maskLeve=0
	self._isMask=false
	for k,v in ipairs(page.entry) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		self.pageId=v.pageId
		if entryCfg then
			local buyState=v.MarketData.personalGoal-v.MarketData.personal>0
			if buyState then
				local moreInfo=entryCfg.moreInfo
				local lockState= playerLv < moreInfo
				local rewards = LxDataHelper.ParseItem(entryCfg.reward)
				local data={
					id=entryCfg.id,
					name=entryCfg.name,
					expend2=entryCfg.expend2,
					moreInfo=moreInfo,
					reward=rewards,
					lockState=not lockState,
					entryId=v.entryId,
					sort=v.sort,
					buyState=buyState,
					invisibleState=false, --未解锁的下一个
				}
				if lockState then
					if recordLockNum < canInsLockNum then
						table.insert(lockList,data)
						table.insert(dataList,data)
						recordLockNum = recordLockNum + 1
					end
				else
					table.insert(dataList,data)
				end

			end
		end
	end


	if #lockList>1 then
		local index=#dataList-#lockList
		index=index+1
		for i = index, #dataList do
			dataList[index].invisibleState=true
			dataList[index].reward.itemCover=true
			dataList[index].reward.itemId=110113
			dataList[index].reward.itemNum=nil
		end
	end

	table.sort(dataList,function(a, b) return a.sort < b.sort end)

	local masklist={}
	self._completeIndex=0
	local index=0
	for i, v in pairs(dataList) do

		if v.moreInfo > playerLv then
			table.insert(masklist,v)
		else
			index=index+1
		end

		if v.lockState then
			self._completeIndex=i
		end

	end

	self._index=index

	table.sort(masklist,function(a,b)
		if a.moreInfo < b.moreInfo then
			return true
		end
	end)
	self._showAll=false
	if #masklist >2 then
		self._maskLeve=masklist[3].moreInfo  --特殊处理 屏蔽第三个往后
	else
		self._showAll=true
	end

	self._rewardList=dataList
	self:InitItemList(dataList)



end
function UISubActUpdeGift:OnActivityPageResp(pb,ret)
	local sid = pb.sid
	if sid ~= self._sid then return end
	local page
	for i, v in ipairs(pb.pages) do
		page = gModelActivity:GenerateActivePageDataFromPb(v)
		break
	end
	if not page then return end
	self._pageId = page.pageId
	self:FreshView(page)
end

function UISubActUpdeGift:MoveListPos(index)

	local list= self._itemUIList:GetList()   --定位

	local index = index - 1

	if(index < 4)then
		index = 0
	else
		index = index - 2
	end

	list:RefreshList(UIListWrap.RefreshMode.Custom,index)
end
------------------------------------------------------------------
return UISubActUpdeGift

