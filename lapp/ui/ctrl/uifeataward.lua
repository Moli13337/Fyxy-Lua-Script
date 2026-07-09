---
--- Created by Administrator.
--- DateTime: 2023/10/23 11:49:14
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFeatAward:LWnd
local UIFeatAward = LxWndClass("UIFeatAward", LWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFeatAward:UIFeatAward()
	---@type table<number,UIIconEasyList>
	self._uiListTbl = {}
	self._getBtnEffName = "fx_anniu_02"
	self._effList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFeatAward:OnWndClose()
	if self._uiList then
		self._uiList:OnWndClose()
	end

	if self._uiListTbl then
		local uiListTbl = self._uiListTbl
		for k,v in pairs(uiListTbl) do
			v:Destroy()
			uiListTbl[k] = v
		end
		self._uiListTbl = nil
	end


	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFeatAward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFeatAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isVie = gLGameLanguage:IsVieVersion()

	
	self:InitData()
	self:InitEvent()
	self:InitMessage()
	--self:InitContent()

    self:SetWndText(self.mDescText, ccClientText(18900))
	self:InitTextSizeWithLanguage(self.mDescText, -2)

	if self._isVie then
		self:InitTextLineWithLanguage(self.mDescText,30)
	else
		self:InitTextLineWithLanguage(self.mDescText, -60)
	end


	self:SetWndText(self.mButtomDesc, ccClientText(19532))
end

function UIFeatAward:InitEvent()
	self:SetWndClick(self.mMask, function(...) self:WndClose() end)

end

function UIFeatAward:OnClickGet(refId)--领取
	gModelAchievement:OnAchievementTreasureBoxReq(refId)
end

--#####################################################################################################################
--## Content ##########################################################################################################
--#####################################################################################################################
function UIFeatAward:InitContent()
	local rewardList = gModelAchievement:GetAchievementLvlCfgList()
	self._rewardMaxNum = #rewardList

	if(self._uiList)then
		self._uiList:RefreshData(rewardList)
	else
		self._uiList = self:GetUIScroll("cell")
		self._uiList:Create(self.mRewardList,rewardList,function (...) self:ListItem(...) end, UIItemList.WRAP)
		--self._uiList:EnableLoadAnimation(true, 0.03, 1, )
	end

	local list= self._uiList:GetList()
	local index = self:GetCurJumpIndex()

	if(index>=self._rewardMaxNum - 3)then
		index = self._rewardMaxNum - 3
	end

	list:RefreshList(UIListWrap.RefreshMode.Custom,index - 1)
end

function UIFeatAward:InitMessage()
	self:WndEventRecv(EventNames.ON_ACHIEVEMENT_LVL_CHANGE,function (...) self:ResetData() end)
	gModelAchievement:OnAchievementTreasureBoxReq(0)
end

function UIFeatAward:GetCurJumpIndex()
	for i = 1,self._curLvl do
		if self._canGetLvlRefIdList[i] then
			return i
		end
	end

	return math.max(self._curLvl, 1)
end

function UIFeatAward:OnClickHaveGet()
	GF.ShowMessage(ccClientText(19538))
end

function UIFeatAward:InitData()
	self._wireIconPath = {
		COMMON = "bar_warorder_1",
		BRIGHT = "bar_warorder_2",
	}

	self._curLvl 	= gModelAchievement:GetCurAchievementLvl()
	local curExp	= gModelAchievement:GetCurAchievementLvlExp()
	local lvlCfg	= gModelAchievement:GetAchievementLvlCfgByLvl(self._curLvl)
	if not lvlCfg then
		printInfoNR("QuestAchvLvRef, cfg is not find , refId = "..self._curLvl)
		return
	end

	local schedule 	= tonumber(curExp)
	local goal 		= lvlCfg.exp
	local progress =0
	if goal>0 then
		progress = schedule/goal
	else
		progress = 1
	end
	self._progress = progress

	self._canGetLvlRefIdList = {}
	self._rewardMaxNum = 0
	self._wireRate = {
		WIRE1 = 0.47,
		WIRE2 = 0.53,
	}
end

function UIFeatAward:OnClickNotGet()
	GF.ShowMessage(ccClientText(19515))
end

function UIFeatAward:ResetData()
	self._canGetLvlRefIdList = gModelAchievement:GetCanGetLvlRefIdList()
	self:InitContent()
end

function UIFeatAward:InitItemList(root,itemList)
	local instanceId = root:GetInstanceID()
	local uiList = self._uiListTbl[instanceId]
	if not uiList then
		uiList = UIIconEasyList:New(self)
		self._uiListTbl[instanceId] = uiList
		uiList:Create(self, root)
		uiList:SetShowNum(true)
		uiList:SetIconParentPath("itemRoot/Icon")
		uiList:SetShowExtraNum(false, "itemNum")
        --local maxNum = #itemList
        --uiList:EnableScroll(maxNum >= 2,true)
	end
	uiList:RefreshList(itemList)
end

function UIFeatAward:ListItem(list,item, itemdata, itempos)
	local wire  	= self:FindWndTrans(item,"Wire")
	local wire1 	= self:FindWndTrans(wire,"Wire1")
	local slider1	= self:FindWndTrans(wire,"Wire1")
	local line1		= self:FindWndTrans(wire1,"Line")
	local wire2 	= self:FindWndTrans(wire,"Wire2")
	local slider2	= self:FindWndTrans(wire,"Wire2")
	local line2		= self:FindWndTrans(wire2,"Line")
	local imageTrans = self:FindWndTrans(wire, "Image")
	local numText 	= self:FindWndTrans(wire,"NumBg/NumText")
	local rewardList = self:FindWndTrans(item,"RewardList")
	local getBtn 	= self:FindWndTrans(item,"GetBtn")
	local notGetBtn = self:FindWndTrans(item,"NotGetBtn")
	local completeImg = self:FindWndTrans(item, "CompleteImg")
	local instance  = item:GetInstanceID()

	local showWire1 = itempos ~= 1
	local showWire2 = itempos ~= self._rewardMaxNum
	CS.ShowObject(wire1,showWire1)
	CS.ShowObject(wire2,showWire2)

	local refId = itemdata.refId
	local rewards = gModelAchievement:GetLvlRewardList(refId)
	if rewards then
		self:InitItemList(rewardList,rewards)
	end

	local fun = function()self:OnClickNotGet(itemdata.jumpId) end
	local isComplete = itempos <= self._curLvl
	local nextLvl	 = self._curLvl + 1
	local isCur		 = itempos == self._curLvl
	local isNext 	 = itempos == nextLvl
	local notHaveLvl = itempos > nextLvl
	local canGet 	 = self._canGetLvlRefIdList[refId]


	if isComplete then
		if canGet then
			fun = function()self:OnClickGet(refId) end
		else
			fun = function()self:OnClickHaveGet() end
		end
	end
	local value
	if showWire1 then
		if isComplete then
			value = 1
		elseif notHaveLvl then
			value = 0
		else
			value = math.max(self._progress - self._wireRate.WIRE2, 0) / self._wireRate.WIRE1
		end
		LxUiHelper.SetProgress(slider1,value)
	end

	if showWire2 then
		if itempos < self._curLvl then
			value = 1
		elseif notHaveLvl or isNext then
			value = 0
		else
			value = math.min(self._progress/self._wireRate.WIRE2, 1)
		end
		LxUiHelper.SetProgress(slider2,value)
	end


--[[	local levelStr = string.replace(ccClientText(19507), itempos)
	if itempos < 100 then
		levelStr = string.replace(ccClientText(19530), levelStr)
	else
		levelStr = string.replace(ccClientText(19531), levelStr)
	end
	self:SetWndText(numText, levelStr)]]
	local str = string.replace(ccClientText(19530),itemdata.expValue)
	self:SetWndText(numText,str)

	local isShowGet = canGet and isComplete
	CS.ShowObject(getBtn, isShowGet)
	CS.ShowObject(notGetBtn,not canGet and not isComplete)
	CS.ShowObject(completeImg, not canGet and isComplete)

	if canGet then
		self:SetWndButtonText(getBtn, ccClientText(19512))
		self:SetWndClick(getBtn,fun)
	else
		--self:SetWndButtonText(notGetBtn, ccClientText(isComplete and 19513 or 19514))
		self:SetWndButtonGray(notGetBtn, isComplete)
		self:SetWndClick(notGetBtn,fun)
	end

	if isShowGet and not self._effList[instance] then
		self:CreateWndEffect(getBtn,self._getBtnEffName,instance,100,false,false,0,nil,100)
		self._effList[instance] = true
	end
end

function UIFeatAward:OnAchievementItemReturn(list,item,itemdata,itemPos)
	if not itemdata then
		return
	end
	local refId = itemdata:GetRefId()
	local key = "achievement"..tostring(refId)
	self:DestroyWndEffectByKey(key)
end


------------------------------------------------------------------
return UIFeatAward


