---
--- Created by Administrator.
--- DateTime: 2023/10/30 10:35:47
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIChaFack:LWnd
local UIChaFack = LxWndClass("UIChaFack", LWnd)

UIChaFack.CHAMPION = 1
UIChaFack.PEAK = 2

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIChaFack:UIChaFack()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIChaFack:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIChaFack:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIChaFack:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:OnWndRefresh()

	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)
	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)

	self:WndNetMsgRecv(LProtoIds.PinnaclePaceStateResp,function ()
		if self._wndType == UIChaFack.CHAMPION then
			return
		end

		self:RefreshUI()
	end)

	self:WndNetMsgRecv(LProtoIds.WeekChampStateResp,function ()
		if self._wndType == UIChaFack.PEAK then
			return
		end

		self:RefreshUI()
	end)
end

function UIChaFack:SetCountDown()
	-- 【G公共支持】删除跨服天梯和跨服周冠玩法
	-- local endTime = gModelCrossServer:GetEndTime()
	-- if self._wndType == UIChaFack.PEAK then
		local endTime = gModelArena:GetPeakEndTime()
	-- end
	local timeLeft = endTime - GetTimestamp()
	if timeLeft< 0 then
		self:WndClose()
	else
		local timeStr = LUtil.FormatTimespanNumber(timeLeft)
		local str = ccClientText(20506)
		str = string.replace(str,timeStr)
		self:SetWndText(self.mTimeInfo,str)
	end
end

function UIChaFack:OnClickFindBack()
	-- 【G公共支持】删除跨服天梯和跨服周冠玩法
	-- if self._wndType == UIChaFack.CHAMPION then
	-- 	self:FindBackChampion()
	-- elseif self._wndType == UIChaFack.PEAK then
		self:FindBackArena()
	-- end
end

function UIChaFack:RefreshUI()
	local itemList = self._itemList
	if not itemList then
		itemList= self:GetUIScroll("itemList")
		itemList:Create(self.mItemList,self._itemdataList,function (...) self:OnDrawCell(...) end)
	end

	self:TimerStop(self._countDownKey)
	self:TimerStart(self._countDownKey,1,false,-1)
end

function UIChaFack:OnWndRefresh()
	self:InitWndPara()
	self:RefreshUI()
end

-- function UIChaFack:FindBackChampion()
-- 	local canFindBack = gModelCrossServer:CheckCanFindBack()
-- 	if not canFindBack then
-- 		printInfoN(string.format("canFindBack %s",canFindBack))
-- 		return
-- 	end

-- 	local itemNeed =self._costPrice.itemNum
-- 	local itemId = self._costPrice.itemId
-- 	local itemOwn = gModelItem:GetNumByRefId(itemId)
-- 	if itemOwn<itemNeed then
-- 		gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = self:GetWndName()})
-- 		return
-- 	end
-- 	local para =
-- 	{
-- 		refId = 150006,
-- 		para = {self._findRet},
-- 		func = function ()
-- 			gModelCrossServer:OnWeekChampGuessBackReq()
-- 			GF.CloseWndByName("UIChaFack")
-- 		end
-- 	}

-- 	gModelGeneral:OpenUIOrdinTips(para)
-- end

function UIChaFack:FindBackArena()
	local canFindBack = gModelArena:CheckCanFindBack()
	if not canFindBack then
		printInfoN(string.format("canFindBack %s",canFindBack))
		return
	end

	local itemNeed =self._costPrice.itemNum
	local itemId = self._costPrice.itemId
	local itemOwn = gModelItem:GetNumByRefId(itemId)
	if itemOwn<itemNeed then
		gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = self:GetWndName()})
		return
	end
	local para =
	{
		refId = 150006,
		para = {self._findRet},
		func = function ()
			gModelArena:OnPinnacleGuessBackReq()
			GF.CloseWndByName("UIChaFack")
		end
	}

	gModelGeneral:OpenUIOrdinTips(para)
end

function UIChaFack:InitWndPara()
	-- 【G公共支持】删除跨服天梯和跨服周冠玩法
	-- self._wndType = self:GetWndArg("wndType") or UIChaFack.CHAMPION
	-- if self._wndType == UIChaFack.CHAMPION then
	-- 	self._findCnt  = gModelCrossServer:GetFindBackCoin()
	-- 	local costRatio = gModelCrossServer:GetChampionPara("guessPayRatio")
	-- 	local expend = gModelCrossServer:GetChampionPara("guessReturnExpend")
	-- 	local numList = LxDataHelper.ParseNumber_Sign(expend,'=')
	-- 	local findRet = costRatio * self._findCnt
	-- 	findRet =  findRet - math.floor(findRet) < 0.001 and math.floor(findRet) or math.ceil(findRet)
	-- 	self._findRet = findRet

	-- 	local price =numList[3] * findRet
	-- 	price =price - math.floor(price) < 0.001 and math.floor(price) or math.ceil(price)
	-- 	self._costPrice =
	-- 	{
	-- 		itemId = numList[4],
	-- 		itemNum = price
	-- 	}

	-- 	self._costRatio = costRatio

	-- elseif self._wndType ==UIChaFack.PEAK then
		self._findCnt = gModelArena:GetFindBackCoin()
		-- local costRatio = gModelArena:GetArenaPara("GuessPayRatio")
		local costRatio = 0
		-- local expend = gModelArena:GetArenaPara("GuessReturnExpend")
		local expend = 0
		local numList = LxDataHelper.ParseNumber_Sign(expend,'=')
		local findRet = costRatio * self._findCnt
		findRet =  findRet - math.floor(findRet) < 0.001 and math.floor(findRet) or math.ceil(findRet)
		self._findRet = findRet

		local price =numList[3] * findRet
		price =price - math.floor(price) < 0.001 and math.floor(price) or math.ceil(price)
		self._costPrice =
		{
			itemId = numList[4],
			itemNum = price
		}

		self._costRatio = costRatio
	-- end



end

function UIChaFack:InitData()
	local cfg =
	{
		--[1] =
		--{
		--	type = 1,
		--	bgPath = "actionarena_bg_mid_1",
		--	btnStr =ccClientText(20502), -- "免费找回"),
		--	tipStr =ccClientText(20503), --  "不要灰心，请收下这\n份来自魔镜的礼物",
		--},
		[1] =
		{
			bgPath = "actionarena_bg_mid_2",
			btnStr =ccClientText(20504), --  "钻石找回",
			tipStr =ccClientText(20503), --  "不要灰心，请收下这\n份来自魔镜的礼物",

		}
	}

	self._itemdataList = cfg

	self._countDownKey = "_countDownKey"
end

function UIChaFack:OnDrawCell(list,item,itemdata,itempos)
	local bg = self:FindWndTrans(item,"bg")
	local getBtn = self:FindWndTrans(item,"getBtn")
	local tipText = self:FindWndTrans(item,"tipText")
	local findInfo = self:FindWndTrans(item,"findInfo")
	local cost = self:FindWndTrans(item,"cost")
	local costIcon = self:FindWndTrans(cost,"icon")
	local costNum = self:FindWndTrans(cost,"num")

	self:SetWndEasyImage(bg,itemdata.bgPath)
	self:SetWndButtonText(getBtn,itemdata.btnStr)
	self:SetWndText(tipText,itemdata.tipStr)
	-- 【G公共支持】删除跨服天梯和跨服周冠玩法
	-- local str =ccClientText(20505) --"可找回%s:<#feefa7>%s</color>"
	-- local itemId = gModelCrossServer:GetGuessCoinId()
	-- local itemName =gModelItem:GetNameByRefId(itemId)

	-- CS.ShowObject(cost,true)

	-- local itemId = self._costPrice.itemId
	-- self:SetWndText(costNum,self._costPrice.itemNum)
	-- local itemImg = gModelItem:GetItemImgByRefId(itemId)
	-- self:SetWndEasyImage(costIcon,itemImg)
	-- str= string.replace(str,itemName,self._findRet)

	-- self:SetWndText(findInfo,str)

	self:SetWndClick(getBtn,function ()
		self:OnClickFindBack()
	end)
end

function UIChaFack:SetStaticContent()
	local str =ccClientText(20500) --"竞猜补给"
	self:SetWndText(self.mTitle,str)
end

------------------------------------------------------------------
return UIChaFack


