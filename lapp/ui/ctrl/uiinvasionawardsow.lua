---
--- Created by Administrator.
--- DateTime: 2023/10/26 19:46:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIInvasionAwardSow:LWnd
local UIInvasionAwardSow = LxWndClass("UIInvasionAwardSow", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIInvasionAwardSow:UIInvasionAwardSow()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIInvasionAwardSow:OnWndClose()
	self:ClearCommonIconList(self._commonIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIInvasionAwardSow:OnCreate()
	LWnd.OnCreate(self)

	self._commonIconList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIInvasionAwardSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:InitUIEvent()
	self._curPage = 1
	self:RefreshUI()
end

function UIInvasionAwardSow:OnDrawAll(list,item,itemdata,itempos)

	local bg = self:FindWndTrans(item,"bg")
	local bgTitle = self:FindWndTrans(bg,"title")
	local bgSlider = self:FindWndTrans(bg,"Slider")
	--local SliderBackground = self:FindWndTrans(bgSlider,"Background")
	local SliderFillArea = self:FindWndTrans(bgSlider,"FillArea")
	local FillAreaFill = self:FindWndTrans(SliderFillArea,"Fill")
	--local FillImage = self:FindWndTrans(FillAreaFill,"Image")
	local bgProgress = self:FindWndTrans(bg,"progress")
	local bgItemList = self:FindWndTrans(bg,"itemList")
	--local itemListItemPool = self:FindWndTrans(bgItemList,"ItemPool")
	local bgButton = self:FindWndTrans(bg,"button")
	local buttonText = self:FindWndTrans(bgButton,"text")
	--local bgMask = self:FindWndTrans(bg,"mask")




	local instanceId = item:GetInstanceID()
	local uiRewardList = self._commonIconList[instanceId]
	if not uiRewardList then
		uiRewardList = UIIconEasyList:New()
		self._commonIconList[instanceId] = uiRewardList
		uiRewardList:Create(self, bgItemList)
		uiRewardList:SetIconParentPath("itemRoot/CommonUI/Icon")
	end
	local rewardList =gModelInvasion:GetBossRewardShow(itemdata.refId)
	uiRewardList:RefreshList(rewardList)


	local needHurt = tonumber(itemdata.needHurt)
	local str2 = LUtil.NumberCoversion(needHurt)

	local str = string.replace(self._descForm2,str2)
	self:SetWndText(bgTitle,str)

	local allHurt  = self._bossData.allHurt
	local str1 = LUtil.NumberCoversion(tonumber(allHurt))
	str = string.format("(%s/%s)",str1,str2)
	self:SetWndText(bgProgress,str)
	self:InitTextSizeWithLanguage(bgProgress, -2)

	local percent = 0
	if needHurt > 0 then
		percent = tonumber(allHurt) / needHurt
	end

	percent = Mathf.Clamp(percent,0,1)
	LxUiHelper.SetProgress(bgSlider,percent)

	local state = gModelInvasion:GetBossRewardState(itemdata.refId)

	local str =ccClientText( 21036)--"前 往")
	local btnState = 0
	local edgeColor = "black"
	if state == ModelQuest.TASK_FINNISH then
		str =ccClientText( 18504)--"领取")
		btnState = 1
	elseif state == ModelQuest.TASK_REWARDED then
		str =ccClientText( 12214)--"已完成")
		btnState = 2
	elseif state == ModelQuest.TASK_UNFINISH then
		btnState = 0
	end

	if btnState == 0 then
		edgeColor= "blue"
	elseif btnState == 1 then
		edgeColor= "yellow"
	elseif btnState == 2 then
		edgeColor= "grey"
	end


	self:SetImageActorState(bgButton,btnState)
	self:SetTextOutLineByColor(buttonText,edgeColor)
	self:SetWndText(buttonText,str)
	self:SetImageActorState(FillAreaFill,1)
	self:SetWndClick(bgButton,function ()
		self:OnClickItem(itemdata)
	end)
end

function UIInvasionAwardSow:OnClickAll()

end

function UIInvasionAwardSow:ShowSingleReward()
	local str =ccClientText(21035)-- "每次挑战达到对应值即可获得奖励"
	self:SetWndText(self.mTipText,str)

	local uiList = self._singleUIList
	if not uiList then
		uiList = self:GetUIScroll("singleList")
		uiList:Create(self.mSingleRList,self._singleList,function (...) self:OnDrawSingle(...) end,UIItemList.SUPER)
		self._singleUIList = uiList
	end

	CS.ShowObject(self.mSingleRList,true)
	CS.ShowObject(self.mAllRList,false)
end

function UIInvasionAwardSow:ShowAllReward()

	local str =ccClientText(21035)-- "每次挑战达到对应值即可获得奖励"
	self:SetWndText(self.mTipText,str)

	local uiList = self._allUIList
	if not uiList then
		uiList = self:GetUIScroll("allList")
		uiList:Create(self.mAllRList,self._allList,function (...) self:OnDrawAll(...) end,UIItemList.SUPER)
		self._allUIList = uiList
	end

	CS.ShowObject(self.mSingleRList,false)
	CS.ShowObject(self.mAllRList,true)
end

function UIInvasionAwardSow:ShowTab()
	local uiList = self:GetUIScroll("tabList")
	uiList:Create(self.mTabList,self._tabDataList,function (...) self:OnDrawTab(...) end)
end

function UIInvasionAwardSow:RefreshUI()
	self:ShowTab()
	local singleList,allList = gModelInvasion:GetCurBossReward()
	self._bossData = gModelInvasion:GetBossData()
	self._singleList = singleList
	self._allList = allList
	if self._curPage == 1 then
		self:ShowSingleReward()
	else
		self:ShowAllReward()
	end
end

function UIInvasionAwardSow:OnDrawTab(list,item,itemdata,itempos)
	local BtnTab1 = self:FindWndTrans(item,"BtnTab1")

	local addSize = -2
	local addLine = -30
	if gLGameLanguage:IsThaiVersion() then
		addSize = -4
		addLine = -50
	end

	if gLGameLanguage:IsVieVersion() then
		addSize = -4
		addLine = 0
	end

	self:SetWndTabText(BtnTab1,itemdata.name, addSize, addLine)
	self:SetWndClick(BtnTab1,itemdata.func)

	local isSelect = itempos == self._curPage
	local state = isSelect and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(BtnTab1,state)
end

function UIInvasionAwardSow:ShowPage(page)
	if self._curPage == page then
		return
	end
	self._curPage = page
	if self._curPage == 1 then
		self:ShowSingleReward()
	else
		self:ShowAllReward()
	end

	local uiList = self:GetUIScroll("tabList")
	uiList:DrawAllItems()
end

function UIInvasionAwardSow:OnDrawSingle(list,item,itemdata,itempos)
	local bg = self:FindWndTrans(item,"bg")
	local bgTitle = self:FindWndTrans(bg,"title")
	local bgSlider = self:FindWndTrans(bg,"Slider")
	--local SliderBackground = self:FindWndTrans(bgSlider,"Background")
	local SliderFillArea = self:FindWndTrans(bgSlider,"FillArea")
	local FillAreaFill = self:FindWndTrans(SliderFillArea,"Fill")
	--local FillImage = self:FindWndTrans(FillAreaFill,"Image")
	local bgProgress = self:FindWndTrans(bg,"progress")
	local bgItemList = self:FindWndTrans(bg,"itemList")
	--local itemListItemPool = self:FindWndTrans(bgItemList,"ItemPool")
	--local bgButton = self:FindWndTrans(bg,"button")
	--local buttonText = self:FindWndTrans(bgButton,"text")
	--local bgMask = self:FindWndTrans(bg,"mask")



	local instanceId = item:GetInstanceID()
	local uiRewardList = self._commonIconList[instanceId]
	if not uiRewardList then
		uiRewardList = UIIconEasyList:New()
		self._commonIconList[instanceId] = uiRewardList
		uiRewardList:Create(self, bgItemList)
		uiRewardList:SetIconParentPath("itemRoot/CommonUI/Icon")
	end
	local rewardList =gModelInvasion:GetBossRewardShow(itemdata.refId)
	uiRewardList:RefreshList(rewardList)


	local maxHurt = tonumber(self._bossData.hurt)
	local percent = 0
	local needHurt = tonumber(itemdata.needHurt)
	if needHurt> 0 then
		percent = maxHurt/needHurt
	end

	LxUiHelper.SetProgress(bgSlider,percent)

	local hurt = LUtil.NumberCoversion(needHurt)
	local str1 = LUtil.NumberCoversion(maxHurt)
	local str = string.format("(%s/%s)",str1,hurt)
	self:SetWndText(bgProgress,str)
	self:InitTextSizeWithLanguage(bgProgress, -2)

	local str = string.replace(self._descForm1,hurt)
	self:SetWndText(bgTitle,str)
	self:InitTextSizeWithLanguage(bgTitle, -4)
	self:SetImageActorState(FillAreaFill,1)


end

function UIInvasionAwardSow:InitUIEvent()
	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)
end

function UIInvasionAwardSow:SetStaticContent()
	local str =ccClientText(21033)--  "挑战奖励"
	self:SetWndText(self.mTitle,str)
end

function UIInvasionAwardSow:OnClickItem(itemdata)
	local state = gModelInvasion:GetBossRewardState(itemdata.refId)
	if state == ModelQuest.TASK_UNFINISH then
	elseif state == ModelQuest.TASK_FINNISH then
		gModelInvasion:OnAlienInvasionBossReq({type = 3,rewardRefId = itemdata.refId})
	elseif state == ModelQuest.TASK_REWARDED then

		local str =ccClientText(11209)-- "奖励已领取")
		GF.ShowMessage(str)
	end
end

function UIInvasionAwardSow:InitData()
	self._descForm1 =ccClientText(21031)-- "单场对BOSS造成%s伤害")
	self._descForm2 =ccClientText(21032)-- "全服累计造成%s伤害"

	self._tabDataList =
	{
		[1] = {
			name =ccClientText(21033),-- "挑战奖励",
			func = function()
				self:ShowPage(1)
			end
		},

		[2] = {
			name =ccClientText(21034),-- "全服奖励",
			func = function()
				self:ShowPage(2)
			end
		}
	}
end
------------------------------------------------------------------
return UIInvasionAwardSow


