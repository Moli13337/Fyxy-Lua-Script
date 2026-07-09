---
--- Created by Administrator.
--- DateTime: 2024/5/21 16:03:45
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISdIntegralPre:LWnd
local UISdIntegralPre = LxWndClass("UISdIntegralPre", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISdIntegralPre:UISdIntegralPre()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISdIntegralPre:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISdIntegralPre:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISdIntegralPre:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:RefreshView()
end

function UISdIntegralPre:OnDrawShowRewardCell(list, item, itemdata, itempos)
	local UIText = self:FindWndTrans(item,"UIText")
	self:SetWndText(UIText,itemdata.grad)

	local Icon = self:FindWndTrans(item,"CommonUI/Icon")
	local gradReward = itemdata.gradReward
	local instanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(gradReward.itemType,gradReward.itemId,gradReward.itemNum)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()

	self:SetWndClick(Icon,function()
		gModelGeneral:ShowCommonItemTipWnd(gradReward)
	end)
end



function UISdIntegralPre:GetRewardList()
	local list = {}
	local refList = gModelHalidom:GetHalidomLuckyRewards()
	for i,v in ipairs(refList) do
		table.insert(list,{
			titleStr = string.replace(ccClientText(41511),v.lv),
			rewardList = v.refData
		})
	end
	return list
end

function UISdIntegralPre:RefreshJackpot()
	--- 默认为当前的进度
	local jackpotLv = gModelHalidom:GetHalidomJackpotLv()

	local isMaxLv = gModelHalidom:CheckIsMaxJackpotLv()
	local curNum = gModelHalidom:GetHalidomDrawCnt()

	local num = 0
	if isMaxLv then
		num = gModelHalidom:GetHalidomRewardLvNum(jackpotLv)
	else
		num = gModelHalidom:GetHalidomRewardLvNum(jackpotLv + 1)
	end

	if curNum > num then curNum = num end
	local progress = curNum / num
	self:SetWndText(self.mJackpotNum,string.replace(ccClientText(41518),curNum,num))

	local slider = self:UIProgressFind(self.mJackpotSlider, "mJackpotSlider", progress)
	slider:SetUIProgress(progress)

	local showStr = ""
	if isMaxLv then
		showStr = ccClientText(41535)
	else
		showStr = string.replace(ccClientText(41546),num,jackpotLv + 1)
	end
	self:SetWndText(self.mJackpotFullTxt,showStr)

--[[	local isMaxLv = gModelHalidom:CheckIsMaxJackpotLv()
	local jackpotLv = gModelHalidom:GetHalidomJackpotLv()
	jackpotLv = isMaxLv and jackpotLv or jackpotLv + 1
	local num = gModelHalidom:GetHalidomRewardLvNum(jackpotLv)
	local progress = 1
	local curNum = isMaxLv and num or gModelHalidom:GetHalidomDrawCnt()
	if not isMaxLv then
		progress = curNum / num
	end
	self:SetWndText(self.mJackpotNum,string.replace(ccClientText(41518),curNum,num))
	local slider = self:UIProgressFind(self.mJackpotSlider, "mJackpotSlider", progress)
	slider:SetUIProgress(progress)

	CS.ShowObject(self.mJackpotFullTxt,isMaxLv)]]
end

function UISdIntegralPre:InitText()
	self:SetWndText(self.mLblBiaoti,ccClientText(41533))
	self:SetWndText(self.mJackpotFullTxt,ccClientText(41535))
end


function UISdIntegralPre:InitShowRewardList(trans,list)
	local instanceID = trans:GetInstanceID()
	local uiList = self:FindUIScroll(instanceID)
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(instanceID)
		uiList:Create(trans, list, function(...) self:OnDrawShowRewardCell(...) end)
	end
end

function UISdIntegralPre:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mMaskBg,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UISdIntegralPre:RefreshView()
	self:InitRewardList()
	self:RefreshJackpot()
end

function UISdIntegralPre:InitMsg()
end

function UISdIntegralPre:OnDrawRewardCell(list, item, itemdata, itempos)
	local Title = self:FindWndTrans(item,"TopDiv/Title")
	local RewardList = self:FindWndTrans(item,"RewardList")
	local MinRewardList = self:FindWndTrans(item,"MinRewardList")
	local rewardList = itemdata.rewardList

	local isMore = #rewardList > 4
	local useTrans = isMore and RewardList or MinRewardList
	local hideTrans = isMore and MinRewardList or RewardList
	CS.ShowObject(useTrans,true)
	CS.ShowObject(hideTrans,false)

	self:SetTextTile(Title,itemdata.titleStr)
	self:InitShowRewardList(useTrans,rewardList)
end

function UISdIntegralPre:InitRewardList()
	local list = self:GetRewardList()
	local uiList = self:FindUIScroll("mRewardList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mRewardList")
		uiList:Create(self.mRewardList, list, function(...) self:OnDrawRewardCell(...) end)
	end
end

------------------------------------------------------------------
return UISdIntegralPre