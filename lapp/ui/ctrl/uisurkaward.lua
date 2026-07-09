---
--- Created by Administrator.
--- DateTime: 2023/10/6 15:27:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISuRkAward:LWnd
local UISuRkAward = LxWndClass("UISuRkAward", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISuRkAward:UISuRkAward()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISuRkAward:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISuRkAward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISuRkAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()
	self:InitUIEvent()
	self:RefreshList()
end

function UISuRkAward:ShowSelfReward(itemdata)

	local item = self.mAwardRank
	local Bg = self:FindWndTrans(item,"Bg")
	local Image = self:FindWndTrans(item,"Image")
	local title = self:FindWndTrans(item,"title")
	local RankIcon = self:FindWndTrans(item,"RankIcon")
	local RankText = self:FindWndTrans(item,"RankText")
	local RankBg = self:FindWndTrans(item,"RankBg")
	local emptyTip = self:FindWndTrans(item,"emptyTip")
	local itemList = self:FindWndTrans(item,"itemList")



	self:SetWndText(title,ccClientText(25169))

	local isEmpty = itemdata == nil

    CS.ShowObject(emptyTip,isEmpty)
	if isEmpty then
		self:SetWndText(emptyTip,ccClientText(25170))
		CS.ShowObject(RankText,false)
		CS.ShowObject(RankBg,false)
		CS.ShowObject(RankIcon,false)
		CS.ShowObject(itemList,false)
	else
		local range = itemdata.range
		local showIcon= range.left<= 3
		CS.ShowObject(RankIcon,showIcon)
		CS.ShowObject(RankText,not showIcon)
		CS.ShowObject(RankBg,not showIcon)
		CS.ShowObject(itemList,true)


		if showIcon then
			local iconPath = gModelGeneral:GetRankIcon(range.left)
			self:SetWndClick(RankIcon,iconPath)
		else
            local format = "#a1#~#a2#"
            if range.left == range.right then
                format = "#a1#"
            end
			local str = string.replace(format,range.left,range.right)
			self:SetWndText(RankText,str)
		end

		local reward = itemdata.reward
		local intanceId = itemList:GetInstanceID()
		local list = self:FindUIScroll(intanceId)
		if not list  then
			list= self:GetUIScroll(intanceId)
			list:Create(itemList,reward,function (...) self:OnDrawItem(...) end)
		else
			list:RefreshList(reward)
		end
	end
end

function UISuRkAward:OnDrawItem(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootItemRoot = self:FindWndTrans(AniRoot,"itemRoot")
	local itemNum = self:FindWndTrans(item,"itemNum")

	self:SetWndText(itemNum,itemdata.itemNum)

	self:CreateCommonIconImpl(AniRootItemRoot,itemdata,{showNum = false})
end

function UISuRkAward:OnDrawRank(list,item,itemdata,itempos)
	local Bg = self:FindWndTrans(item,"Bg")
	local RankText = self:FindWndTrans(item,"RankText")
	local RankBg = self:FindWndTrans(item,"RankBg")
	local RankIcon = self:FindWndTrans(item,"RankIcon")
	local itemList = self:FindWndTrans(item,"itemList")

	local range = itemdata.range
	local showIcon= range.left<= 3
	CS.ShowObject(RankIcon,showIcon)
	CS.ShowObject(RankText,not showIcon)
	CS.ShowObject(RankBg,not showIcon)


	if showIcon then
		local iconPath = gModelGeneral:GetRankIcon(range.left)
		self:SetWndEasyImage(RankIcon,iconPath)
	else
		local str = ""
		if range.left== range.right then
			str = tostring(range.left)
		else
			str = string.replace("#a1#~#a2#",range.left,range.right)
		end
		self:SetWndText(RankText,str)
	end

	local reward = itemdata.reward
	local intanceId = itemList:GetInstanceID()
	local list = self:FindUIScroll(intanceId)
	if not list  then
		list= self:GetUIScroll(intanceId)
		list:Create(itemList,reward,function (...) self:OnDrawItem(...) end)
	else
		list:RefreshList(reward)
	end


end

function UISuRkAward:RefreshList()
	local dataList,selfType,selfRank = gModelSimuFight:GetRankRewardList(self._curType)

	local selfReward = nil
	local rewardList = {}
	if dataList then
		for k,v in ipairs(dataList) do
			local data = {}
			local range = LxDataHelper.ParseRange(v.rank)
			data.range = range
			local totalReward = {}

			local reward = LxDataHelper.ParseItem(v.rewardServer)
			if reward then
				for k1,v1 in ipairs(reward) do
					table.insert(totalReward,v1)
				end
			end

			reward = LxDataHelper.ParseItem(v.rewardSelfSpecial)
			if reward then
				for k1,v1 in ipairs(reward) do
					table.insert(totalReward,v1)
				end
			end
			reward = LxDataHelper.ParseItem(v.rewardSelf)
			if reward then
				for k1,v1 in ipairs(reward) do
					table.insert(totalReward,v1)
				end
			end

			data.reward = totalReward
			table.insert(rewardList,data)


			if selfType == self._curType then
				if selfRank>= range.left and selfRank <= range.right then
					selfReward = data
				end
			end

		end
	end

	self:ShowSelfReward(selfReward)

	local uiList = self:FindUIScroll("rankList")
	if  not uiList then
		uiList = self:GetUIScroll("rankList")
		uiList:Create(self.mAwardList,rewardList,function (...) self:OnDrawRank(...) end)
	else
		local listCom = uiList:GetList()
		listCom:SetContentPosition(0,1)
		uiList:RefreshList(rewardList)
	end
	uiList:EnableScroll(true,false)
end

function UISuRkAward:SetStaticContent()
	local str = ccClientText(25168) --"殿堂奖励"
	self:SetWndText(self.mLblBiaoti,str)
	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)

	local tabDataList=
	{
		[1] =
		{
			type = 1,
			name =ccLngText(gModelSimuFight:GetPara("groupName1")),
		},
		[2] =
		{
			type = 2,
			name =ccLngText(gModelSimuFight:GetPara("groupName2")),
		},
	}

	self._curType = self:GetWndArg("groupType") or 1
	local tabList = self:GetUIScroll("tabList")
	tabList:Create(self.mTabScroll,tabDataList,function (...) self:OnDrawTab(...) end)
end

function UISuRkAward:OnClickTab(itemdata)
	if self._curType == itemdata.type then
		return
	end

	self._curType = itemdata.type

	local list = self:FindUIScroll("tabList")
	if list then
		list:DrawAllItems(false)
	end

	self:RefreshList()
end

function UISuRkAward:OnDrawTab(list,item,itemdata,itempos)
	local BtnTab = self:FindWndTrans(item,"BtnTab")

	self:SetWndTabText(BtnTab,itemdata.name, -4)
	local isSelect = itemdata.type == self._curType
	local state = isSelect and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(BtnTab,state)
	self:SetWndClick(item,function () self:OnClickTab(itemdata) end)

end

function UISuRkAward:InitUIEvent()
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
	self:SetWndClick(self.mMask,function () self:WndClose() end)
end


------------------------------------------------------------------
return UISuRkAward


