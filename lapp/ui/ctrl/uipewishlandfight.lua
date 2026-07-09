---
--- Created by Administrator.
--- DateTime: 2024/6/11 15:20:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeWishLandFight:LWnd
local UIPeWishLandFight = LxWndClass("UIPeWishLandFight", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeWishLandFight:UIPeWishLandFight()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeWishLandFight:OnWndClose()
	gModelPetDreanLand:OpenPetDreamLandReportResult()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeWishLandFight:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeWishLandFight:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:CreateWndEffect(self.mTextEffRoot,"fx_ui_shengxing_1","fx_ui_shengxing_1",100,false,false)
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UIPeWishLandFight:OnDrawResultCell(list, item, itemdata, itempos)
	local OutputDiv = self:FindWndTrans(item,"OutputDiv")
	local OutputTxt = self:FindWndTrans(OutputDiv,"OutputTxt")
	local OutputItemList = self:FindWndTrans(OutputDiv,"OutputItemList")

	self:SetWndText(OutputTxt,itemdata.txt)

	self:InitOutputItemList(OutputItemList,itemdata.list)
end



function UIPeWishLandFight:GetResultList()
	local list = {}
	--- 据点名字
	table.insert(list,{
		list = {},
		txt = string.replace(ccClientText(43349),gModelPetDreanLand:GetPetDreamlandName(self._refId)),
	})

	local showWeekHappy = false
	local isWeekOpen = gModelPetDreanLand:CheckIsOpenWeeken()
	if isWeekOpen then
		showWeekHappy = LUtil.CheckIsWeekend(GetTimestamp())
	end

	--- 产出效率
	local refData = gModelPetDreanLand:GetSplitPetDreamlandRefByRefId(self._refId)
	if refData then
		local weekenBuffNum = 0
		if showWeekHappy then
			weekenBuffNum = gModelPetDreanLand:GetpetDreamlandWeekenBuff() / 100
		end
		--- 新增战区产出
		local value = gModelPetDreanLand:GetCurBigFightIdPetDreamlandRewardValue() or {}
		local petDreamlandBuff = gModelPetDreanLand:GetVIPPetDreamlandBuff()
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
		end
		table.insert(list,{
			list = rewardList,
			txt = ccClientText(43302),
		})
	end

	--- 是否开启特权
	if gModelPetDreanLand:CheckHasVIPPrivilege() then
		table.insert(list,{
			list = {},
			txt = string.replace(ccClientText(43351),gModelPetDreanLand:GetVIPPetDreamlandBuffStr()),
		})
	else
		local notVipPet = gModelPetDreanLand:GetNotVIPPetDreamland()
		local str = string.replace(ccClientText(43351),notVipPet)
		local unlockStr = string.replace(ccClientText(43375),gModelPetDreanLand:GetNotVipPetDreamlandVip())
		table.insert(list,{
			list = {},
			txt = string.replace(ccClientText(43376),str,unlockStr),
		})
	end

	--- 是否开启周末狂欢
	--- 2024/6/26：不是周末这个不会显示的
	if isWeekOpen and showWeekHappy then
		table.insert(list,{
			list = {},
			txt = string.replace(ccClientText(43352),gModelPetDreanLand:GetpetDreamlandWeekenBuff(true))
		})
	end
	return list
end

function UIPeWishLandFight:InitResultList()
	local list = self:GetResultList()
	local uiList = self:FindUIScroll("mResultList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mResultList")
		uiList:Create(self.mResultList, list, function(...) self:OnDrawResultCell(...) end)
	end
end

function UIPeWishLandFight:InitData()
	self._refId = self:GetWndArg("refId")

	---@type StructPetDreamLandPointData
	self._pointData = self:GetWndArg("pointData")
end

function UIPeWishLandFight:OnDrawOutputItemCell(list, item, itemdata, itempos)
	local Icon = self:FindWndTrans(item,"IconDiv/Icon")
	local Num = self:FindWndTrans(item,"Num")
	local itemId = itemdata.itemId
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(Icon,icon,function()
		CS.ShowObject(Icon,true)
	end,true)
	self:SetWndText(Num,itemdata.numStr)
end

function UIPeWishLandFight:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIPeWishLandFight:RefreshView()
	self:InitResultList()
end





function UIPeWishLandFight:InitOutputItemList(listTrans,list)
	local key = listTrans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(listTrans, list, function(...) self:OnDrawOutputItemCell(...) end)
	end
end

function UIPeWishLandFight:InitMsg()
end

function UIPeWishLandFight:InitText()
	self:SetWndText(self.mCloseTip, ccClientText(17003))
end




------------------------------------------------------------------
return UIPeWishLandFight