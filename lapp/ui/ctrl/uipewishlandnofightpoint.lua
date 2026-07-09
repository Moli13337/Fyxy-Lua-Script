---
--- Created by Administrator.
--- DateTime: 2024/6/11 14:37:11
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeWishLandNoFightPoint:LWnd
local UIPeWishLandNoFightPoint = LxWndClass("UIPeWishLandNoFightPoint", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeWishLandNoFightPoint:UIPeWishLandNoFightPoint()
	---@type StructPetDreamLandPointData
	self._pointData = nil

	self._cdTimerKey = "_cdTimerKey"

	self._cdInfos = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeWishLandNoFightPoint:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeWishLandNoFightPoint:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeWishLandNoFightPoint:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:ReqPointCheck()
end

function UIPeWishLandNoFightPoint:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

end


function UIPeWishLandNoFightPoint:InitOutputItemList(listTrans,list)
	list = list or {}
	local key = listTrans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(listTrans,list,function(...) self:OnDrawOutputItemCell(...) end)
	end
end


---@param rewardList table<StructRewardItem> 奖励物品列表
function UIPeWishLandNoFightPoint:GetCommonRewardList(rewardList,sortItemMap)
	local list = {}
	---@param v StructRewardItem
	for i,v in ipairs(rewardList) do
		table.insert(list,{
			itemId = v.itemId,
			numStr = LUtil.NumberCoversion(v.count)
		})
	end
	table.sort(list,function(a, b)
		local sortA = sortItemMap[a.itemId] or 0
		local sortB = sortItemMap[b.itemId] or 0
		return sortA < sortB
	end)
	return list
end

function UIPeWishLandNoFightPoint:OnDrawOutputItemCell(list, item, itemdata, itempos)
	local IconDiv = self:FindWndTrans(item,"IconDiv")
	local Icon = self:FindWndTrans(IconDiv,"Icon")
	local Num = self:FindWndTrans(item,"Num")

	local icon = gModelItem:GetItemIconByRefId(itemdata.itemId)
	self:SetWndEasyImage(Icon,icon,function() CS.ShowObject(Icon,true) end,true)

	self:SetWndText(Num,itemdata.numStr)
end

function UIPeWishLandNoFightPoint:OnDrawPlayerOutputCell(list, item, itemdata, itempos)
	local OutputDiv = self:FindWndTrans(item,"OutputDiv")

	local OutputTxt = self:FindWndTrans(OutputDiv,"OutputTxt")
	local OutputItemList = self:FindWndTrans(OutputDiv,"OutputItemList")

	if itemdata.isNeedCD then
		table.insert(self._cdInfos,{
			cdData = itemdata.cdData,
			txtTrans = OutputTxt,
		})
	end

	self:SetWndText(OutputTxt,itemdata.txt)
	self:InitOutputItemList(OutputItemList,itemdata.list)
end

function UIPeWishLandNoFightPoint:InitText()
	self:SetWndText(self.mLblBiaoti,ccClientText(43325))
end


function UIPeWishLandNoFightPoint:OnTimer(key)
	if key == self._cdTimerKey then
		self:OnCdTimer()
	end
end


function UIPeWishLandNoFightPoint:InitPlayerOutputList(list)
	self._cdInfos = {}
	local uiList = self:FindUIScroll("mPlayerOutputList")
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mPlayerOutputList")
		uiList:Create(self.mPlayerOutputList, list, function(...) self:OnDrawPlayerOutputCell(...) end)
	end
end

function UIPeWishLandNoFightPoint:ReqPointCheck()
	gModelPetDreanLand:OnPetDreamLandPointCheckReq(self._refId,self._pointId)
end

function UIPeWishLandNoFightPoint:InitMsg()
	self:WndNetMsgRecv(LProtoIds.PetDreamLandPointCheckResp,function(...) self:OnPetDreamLandPointCheckResp(...) end)
end

function UIPeWishLandNoFightPoint:OnClickXXXBtnFunc()
end

function UIPeWishLandNoFightPoint:OnCdTimer()
	for i,v in ipairs(self._cdInfos) do
		local cdData = v.cdData
		local timeLeft = GetTimestamp() - cdData.startTime
		timeLeft = math.floor(timeLeft)
--[[		self:SetWndText(v.txtTrans,string.replace(cdData.txtStr,
				LUtil.FormatTimespanNumber(timeLeft)))]]
		self:SetWndText(v.txtTrans,string.replace(cdData.txtStr,
				LUtil.FormatTimeStr1(timeLeft)))

		if timeLeft % self._petDreamlandTime == 0 then
			--- 超出时间不更新
			local petDreamlandTimeMax = self._petDreamlandTimeMax
			if petDreamlandTimeMax and petDreamlandTimeMax > 0 and petDreamlandTimeMax - timeLeft > 0 then
				self:ReqPointCheck()
			end
		end
	end
end

function UIPeWishLandNoFightPoint:OnPetDreamLandPointCheckResp(pb)
	local refId = pb.refId
	if refId ~= self._refId then return end

	---@type StructPetDreamLandPointData
	local pointData = gModelPetDreanLand:GetPetDreamLandPointData(pb.pointData)

	self:SetWndText(self.mPlayerName,pointData:GetServerAndPlayerName())

	self:RefreshPlayerInfoDiv(pointData)
end

function UIPeWishLandNoFightPoint:OnEventXXXXX()
end

---@param pointData StructPetDreamLandPointData
function UIPeWishLandNoFightPoint:RefreshPlayerInfoDiv(pointData)
	local spineName = pointData:GetShowPlayerInfoFigureSpine()
	if spineName then
		---@param dpSpine LDisplaySpine
		self:CreateWndSpine(self.mPlayerSpineRoot,spineName,spineName,false,function(dpSpine)

		end)
	end


	local sortItemMap = {}

	local list = {}
	--- 产出效率
	local refData = gModelPetDreanLand:GetSplitPetDreamlandRefByRefId(self._refId)
	if refData then
		local showWeekHappy = false
		local isWeekOpen = gModelPetDreanLand:CheckIsOpenWeeken()
		if isWeekOpen then
			showWeekHappy = LUtil.CheckIsWeekend(GetTimestamp())
		end

		local weekenBuffNum = 0
		if showWeekHappy then
			weekenBuffNum = gModelPetDreanLand:GetpetDreamlandWeekenBuff() / 100
		end

		local petDreamlandBuff = gModelPetDreanLand:GetPetDreamlandBuffByVip(pointData:GetVipLevel())
		--- 新增战区产出
		local value = gModelPetDreanLand:GetCurBigFightIdPetDreamlandRewardValue() or {}


		local rewardList = {}
		for i,v in ipairs(refData.showRewardList) do
			--- （1+VIP额外加成比例+周末狂欢）
			local itemNum = (1 + petDreamlandBuff + weekenBuffNum) * v.itemNum
			local rate = value[i] or 1
			itemNum = itemNum * rate
			itemNum = math.floor(itemNum)
			local numStr = string.replace(ccClientText(43303),LUtil.NumberCoversion(itemNum))
			table.insert(rewardList,{
				itemId = v.itemId,
				numStr = numStr
			})

			sortItemMap[v.itemId] = i
		end
		table.insert(list,{
			list = rewardList,
			txt = ccClientText(43302),
		})
	end

	--- 占领时间
	table.insert(list,{
		list = {},
		txt = "",
		isNeedCD = true,
		cdData = {
			txtStr = ccClientText(43342),
			startTime = pointData.starOccupyTime,
		}
	})

	--- 当前获得
	table.insert(list,{
		list = self:GetCommonRewardList(pointData.itemList,sortItemMap),
		txt = ccClientText(43317),
	})

	self:InitPlayerOutputList(list)

	self:OnCdTimer()
	self:TimerStop(self._cdTimerKey)
	self:TimerStart(self._cdTimerKey,1,false,-1)
end


function UIPeWishLandNoFightPoint:InitData()
	---@type number
	self._refId = self:GetWndArg("refId")

	---@type StructPetDreamLandPointData
	self._pointData = self:GetWndArg("pointData")

	self._pointId = self._pointData.id

	self._petDreamlandTime = gModelPetDreanLand:GetConfigPetDreamlandTime() or 60

	self._petDreamlandTimeMax = gModelPetDreanLand:GetPetDreamlandTimeMax()
end

------------------------------------------------------------------
return UIPeWishLandNoFightPoint