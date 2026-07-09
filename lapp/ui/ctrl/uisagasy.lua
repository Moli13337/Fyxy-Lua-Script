---
--- Created by Administrator.
--- DateTime: 2023/10/3 20:06:41
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaSy:LWnd
local UISagaSy = LxWndClass("UISagaSy", LWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaSy:UISagaSy()
	---@type LUIHeroObject
	self._curUIHeroObj = nil
	self._storyTransList = {}
	self._storyIndexList = {}
	self._setStoryList = {}

	self._jumpStoryIndexTime = "_jumpStoryIndexTime"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaSy:OnWndClose()

	local haveHero = gModelHeroBook:GetHeroIsActByRefId(self._refId)
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"伙伴故事close",self._refId,haveHero)

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaSy:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaSy:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	self:RefreshView(true)
end

function UISagaSy:OnDrawItemCell(list,item,itemdata,itempos)
	local ItemIcon = self:FindWndTrans(item,"ItemIcon")
	if ItemIcon then
		local refId = itemdata.itemRefId
		local icon = gModelItem:GetItemIconByRefId(refId)
		if icon then
			self:SetWndEasyImage(ItemIcon,icon)
		end
	end
	local ItemNum = self:FindWndTrans(item,"ItemNum")
	if ItemNum then
		self:SetWndText(ItemNum,itemdata.itemNum)
	end
end

function UISagaSy:RefreshList()
	local list = self:GetStoryList()
	self._storyDataList = list
	local canGetIndex, unlockIndex
	for i,v in ipairs(list) do
		if v.showReward then
			canGetIndex = i
			break
		elseif v.unLock then
			unlockIndex = i
		end
	end


	local uiStoryList = self._uiStoryList
	if uiStoryList then
		uiStoryList:RefreshData(list)
	else
		uiStoryList = self:GetUIScroll("uiStoryList")
		self._uiStoryList = uiStoryList
		uiStoryList:Create(self.mStoryList,list,function(...) self:OnDrawStoryListItem(...) end)
		uiStoryList:EnableScroll(true,false)
	end

	local index, openDesIndex
	if self._getRewardIndex then
		index = self._getRewardIndex
		openDesIndex = index
	elseif canGetIndex then
		index = canGetIndex
		openDesIndex = canGetIndex - 1
	elseif unlockIndex then
		index = unlockIndex
		openDesIndex = index
	end

	if openDesIndex then
		self:OnClickStoryCell(openDesIndex)
	end

	if index then
		self._jumpStoryIndex = index
		local timeKey = self._jumpStoryIndexTime
		self:TimerStop(timeKey)
		self:TimerStart(timeKey,0.1,false,1)
	end
	self._getRewardIndex = nil
end

function UISagaSy:OnDrawStarCell(list,item,itemdata,itempos)
	local Star = self:FindWndTrans(item,"Star")
	if Star then
		CS.ShowObject(Star,itemdata.show)
	end
end

function UISagaSy:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UISagaSy:OnDrawQMStarCell(list,item, itemdata, itempos)
	local Star = self:FindWndTrans(item,"Star")
	if Star then
		local actStar = not itemdata.actStar
		self:SetWndImageGray(Star,actStar)
	end
end

function UISagaSy:InitMsg()
	self:WndNetMsgRecv(LProtoIds.HeroBookRewardResp,function (pb)
		local heroRefId = pb.heroRefId
		if heroRefId == self._refId then
			self:RefreshView()
		end
	end)
end

function UISagaSy:InitData()
	self._refId = self:GetWndArg("refId")
end

function UISagaSy:RefreshView(init)
	local refId = self._refId
	local serverData = gModelHeroBook:GetHeroInfoByHeroRefId(refId)
	if not serverData then return end
	local heroRef = gModelHero:GetHeroRef(refId)
	if not heroRef then return end
	local closeGrade = serverData.heroMaxStar
	local closeLv = heroRef.closeLv
	local heroCloseRef = gModelHeroBook:GetHeroCloseLvRefByCloseTypeAndCloseGrade(closeLv,closeGrade)
	if not heroCloseRef then return end
	self:CreateQMDJList(closeGrade)
	local closeValue = serverData.closeValue
	local needLevel = heroCloseRef.needLevel
	local isMax = needLevel == ModelHeroBook.HEROCLOSELV_MAX
	local maxValue = isMax and 1 or needLevel
	local value = isMax and 1 or closeValue
	local uiSlider = self._uiSlider
	if not uiSlider then
		uiSlider = self:FindWndSlider(self.mMeBar)
		self._uiSlider = uiSlider
	end
	uiSlider.maxValue = maxValue
	uiSlider.value = value

	local showQMNum = not isMax
	local qmNumTrans = self.mQmNum
	if showQMNum then
		local str = string.replace(ccClientText(19713),closeValue,needLevel)
		self:SetWndText(qmNumTrans,str)
	end
	CS.ShowObject(qmNumTrans,showQMNum)

	self:RefreshList()
	if init then self:CreateSpine() end
end

function UISagaSy:InitText()
	self:SetWndText(self.mTitle,ccClientText(19723))
	self:SetWndText(self.mQmDJTxt,ccClientText(19705))
	self:SetWndText(self.mQmJDTxt,ccClientText(19706))
end

function UISagaSy:CreateSpine()
	local refId = self._refId
	local heroRef = gModelHero:GetHeroRef(refId)
	if not heroRef then return end
	local pbName = gModelHero:GetHeroPrefabNameByRefId(refId,heroRef.initStar)
	if not pbName then
		pbName = "Jianshi"
	end
	local spineSize = gModelHero:GeConfigByKey("StorySpineSize")
	if not spineSize then
		printInfoNR("HeroConfigRef表里没有StorySpineSize字段，如果需要控制spine的大小，请在HeroConfigRef表里添加StorySpineSize字段，当前默认为1")
		spineSize = 1
	end
	local newUIHeroObj = LUIHeroObject:New(self)
	newUIHeroObj:Create(self.mHeroPos,pbName,pbName)
	newUIHeroObj:SetScale(spineSize)
	newUIHeroObj:SetHeroData(refId, refId, nil, nil,true)
	newUIHeroObj:ShowHero(true)
	newUIHeroObj:StartLoad()
end

function UISagaSy:ChangeStoryCell(trans,bool,index)
	self._storyIndexList[index]=bool

	local image = self:FindWndTrans(trans,"Image")
	local topTrans = self:FindWndTrans(trans,"Info/Top")
	local upArrow = self:FindWndTrans(topTrans, "ToggleBtn/UpArrow")
	local downArrow = self:FindWndTrans(topTrans, "ToggleBtn/DownArrow")
	CS.ShowObject(upArrow, bool)
	CS.ShowObject(downArrow, not bool)
	if not bool then
		CS.ShowObject(image,false)
		return
	end
	CS.ShowObject(image,true)

	if not self._setStoryList[index] then
		self._setStoryList[index] = true
		local desText = self:FindWndTrans(trans,"Image/DesText")
		local data = self._storyDataList[index]
		if data then
			local dec = ccLngText(data.dec)
			self:SetWndText(desText,dec)
		end
	end
end

function UISagaSy:OnClickStoryCell(index)--点击资源获取
	local storyTransList 	= self._storyTransList
	local isShow 			= self._storyIndexList[index]
	local trans 			= storyTransList[index]
	self:ChangeStoryCell(trans,not isShow,index)

	local maxNum 			= #storyTransList
	if index >= maxNum and maxNum > 1 then	--只有最后一个上提一下
		self._jumpStoryIndex = index
		local timeKey = self._jumpStoryIndexTime
		self:TimerStop(timeKey)
		self:TimerStart(timeKey,0.1,false,1)
	end
end

function UISagaSy:CreateQMDJList(dj)
	local list = {}
	local heroRefId = self._refId
	local closeLv = gModelHeroBook:GetHeroCloseLv(heroRefId)
	for i = 1,closeLv do
		local actStar = dj >= i
		table.insert(list,{actStar = actStar})
	end
	local uiQMDJList = self._uiQMDJList
	if uiQMDJList then
		uiQMDJList:RefreshList(list)
	else
		uiQMDJList = self:GetUIScroll("uiQMDJList")
		self._uiQMDJList = uiQMDJList
		uiQMDJList:Create(self.mQmDJList,list,function(...) self:OnDrawQMStarCell(...) end)
	end
end

function UISagaSy:OnTimer(key)
	if key == self._jumpStoryIndexTime then
		local list = self._uiStoryList:GetList()
		if(not list)then return end
		list:ScrollToIndex(self._jumpStoryIndex)
	end
end


function UISagaSy:CreateItemList(trans,list)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawItemCell(...) end)
	end
end

function UISagaSy:GetStoryList()
	local list = {}
	local refId = self._refId
	local serverData = gModelHeroBook:GetHeroInfoByHeroRefId(refId)
	local heroRef = gModelHero:GetHeroRef(refId)
	if heroRef and serverData then
		local isActive = serverData.isActive
		local closeGrade = serverData.heroMaxStar
		local storyRewardsKey = serverData.storyRewardsKey or {}
		local heroStory = heroRef.heroStory
		if type(heroStory) == "string" then
			heroStory = tonumber(ccLngText(heroStory))
		end
		local storyRefList = gModelHeroBook:GetHeroStoryRefListByStoryType(heroStory)
		for k,v in pairs(storyRefList) do
			local data = {}
			local storyRefId = v.refId
			local isAct = storyRewardsKey[storyRefId] and true or false
			data.refId = storyRefId
			data.isActive = isActive
			data.isAct = isAct 											-- 已领取
			data.closeGrade = closeGrade
			local needLevel = v.needLevel
			data.needLevel = needLevel
			data.rewardList = v.rewardList
			data.decName = v.decName
			--local unLock = serverData.heroMaxStar >= needLevel
			local unLock = serverData.heroMaxStar  >= needLevel
			data.unLock = unLock 										-- 已解锁
			local showReward = unLock and (not isAct) and isActive and needLevel <= closeGrade
			data.showReward = showReward
			table.insert(list,data)
		end
	end
	table.sort(list,function(a,b)
		return a.needLevel < b.needLevel
	end)
	return list
end

function UISagaSy:CreateStarList(trans,star)
	local list = {}
	for i = 1,star do
		table.insert(list,{
			show = true,
		})
	end
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawStarCell(...) end)
	end
end

function UISagaSy:OnDrawStoryListItem(list,item, itemdata, itempos)
	self._storyTransList[itempos]=item

	local root = item
	local infoTrans = self:FindWndTrans(item,"Info")
	local topTrans = self:FindWndTrans(infoTrans,"Top")
	local toggleBtn = self:FindWndTrans(topTrans,"ToggleBtn")
	local StoryName = self:FindWndTrans(topTrans,"Image/StoryName")
	if StoryName then
		self:SetWndText(StoryName,ccLngText(itemdata.decName))
	end

	local showReward = itemdata.showReward
	local RewardDiv = self:FindWndTrans(topTrans,"RewardDiv")
	if RewardDiv then
		if showReward then
			local ItemList = self:FindWndTrans(RewardDiv,"ItemList")
			if ItemList then
				local rewardList = itemdata.rewardList
				self:CreateItemList(ItemList,rewardList)
			end
			local GetBtn = self:FindWndTrans(RewardDiv,"GetBtn")
			if GetBtn then
				self:SetWndClick(root,function()
					self._getRewardIndex = itempos
					gModelHeroBook:OnHeroBookRewardReq(self._refId,itemdata.refId)
				end)
			end
		end
		CS.ShowObject(RewardDiv,showReward)
	end

	local unLock,isAct = itemdata.unLock,itemdata.isAct

	local showLockDiv = not unLock
	local LockDiv = self:FindWndTrans(infoTrans,"LockDiv")
	if LockDiv then
		if showLockDiv then
			local AutoDiv = self:FindWndTrans(LockDiv,"AutoDiv")
			if AutoDiv then
				local DDTxt = self:FindWndTrans(AutoDiv,"DDTxt")
				if DDTxt then
					self:SetWndText(DDTxt,ccClientText(19730))
				end
				local StarList = self:FindWndTrans(AutoDiv,"StarList")
				if StarList then
					self:CreateStarList(StarList,itemdata.needLevel)
				end
				local HJSTxt = self:FindWndTrans(AutoDiv,"HJSTxt")
				if HJSTxt then
					self:SetWndText(HJSTxt,ccClientText(19731))
				end
			end
		end
		CS.ShowObject(LockDiv,showLockDiv)
	end

	local showNoLockDiv = not showLockDiv
	local showToggleBtn = showNoLockDiv and not showReward
	CS.ShowObject(toggleBtn, showToggleBtn)
	if showNoLockDiv then
		self:SetWndClick(toggleBtn, function(...)
			self:OnClickStoryCell(itempos)
		end)
	end
end
------------------------------------------------------------------
return UISagaSy