---
--- Created by BY.
--- DateTime: 2023/10/7 15:59:59
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISupleGetWay:LWnd
local UISupleGetWay = LxWndClass("UISupleGetWay", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISupleGetWay:UISupleGetWay()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISupleGetWay:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISupleGetWay:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISupleGetWay:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISupleGetWay:ListItem(list, item, itemdata, itempos)
	local name = self:FindWndTrans(item,"Name")
	local desc = self:FindWndTrans(item,"Desc")
	local gotoBtn = self:FindWndTrans(item,"GotoBtn")
	local buyBtn = self:FindWndTrans(item,"BuyBtn")
	local redPoint = self:FindWndTrans(item,"BuyBtn/redPoint")

	CS.ShowObject(redPoint,false)
	local jumpId,guyType = itemdata.jumpId,itemdata.guyType
	self:SetWndText(name,itemdata.name)
	self:SetWndText(desc,itemdata.des)
	local btnStr = ccClientText(22208)
	if guyType and guyType == 10 then
		btnStr = ccClientText(22214)
		CS.ShowObject(redPoint,true)
	end
	self:SetWndButtonText(gotoBtn,btnStr)
	self:SetWndButtonText(buyBtn,btnStr)
	CS.ShowObject(gotoBtn,jumpId)
	CS.ShowObject(buyBtn,guyType)

	self:SetWndClick(gotoBtn,function ()
		gModelFunctionOpen:Jump(jumpId,self:GetWndName())
	end)
	self:SetWndClick(buyBtn,function ()
		local shopResetUse = self._shopResetUse
		if not shopResetUse then
			printInfoNR("config.shopResetUse is a nil")
			return
		end
		local item = LxDataHelper.ParseItem_3(shopResetUse)
		local itemNum = item.itemNum
		local itemId  = item.itemId
		local name = gModelItem:GetNameByRefId(itemId)

		local isEnough = gModelGeneral:CheckItemEnough(itemId,itemNum,true,self:GetWndName())
		if not isEnough then
			return
		end
		gModelGeneral:OpenUIOrdinTips({refId = 110018,para = {itemNum..name},func = function()
			gModelActivity:OnActivitySpecialOpReq(self._sid,ModelActivity.CHN_SUPPERZZLE,-1,guyType)
		end, consume={itemNum,itemId} })
	end)
end

function UISupleGetWay:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
end

function UISupleGetWay:RefreshList()
	local activityDataS = gModelActivity:GetActivityBySid(self._sid)
	if not activityDataS then
		return
	end
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityData then
		return
	end
	local data = activityData.config

	local dataS = JSON.decode(activityDataS.moreInfo)
	local diamondBuyCount = dataS.diamondBuyCount or 0

	local list = {}
	if diamondBuyCount > 0 and not string.isempty(self._shopResetUse) then
		local description = data.countBuyPriceDec or ""
		local des = string.replace(description,diamondBuyCount)
		table.insert(list,{name = data.countBuyPriceTitle,des = des,guyType = 10})
	end

	local haveEntryList = {}
	for i, v in ipairs(self._source) do
		local entryId = v.entryId
		if not haveEntryList[entryId] then
			haveEntryList[entryId] = true
			local cfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,entryId)
			table.insert(list,{name = cfg.name,des = cfg.description,jumpId = cfg.jumpId})
		end
	end

	local uiList = self._uiList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("wayCell")
		uiList:Create(self.mWayList,list,function (...) self:ListItem(...) end)
	end
end

function UISupleGetWay:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(19800))
	self._sid = self:GetWndArg("sid")
	local item = self:GetWndArg("item") or ""		--"道具图标|道具框"
	local itemName = self:GetWndArg("itemName")
	local itemDes = self:GetWndArg("itemDes")
	self._source = self:GetWndArg("source")
	local num = self:GetWndArg("num")

	local WebData = gModelActivity:GetWebActivityDataById(self._sid)
	local dataWeb = WebData.config
	self._shopResetUse = dataWeb.shopResetUse

	local itemStr = string.split(item,"|")
	self:SetWndEasyImage(self.mItemIcon,itemStr[1])
	self:SetWndEasyImage(self.mItemBg,itemStr[2])
	self:SetWndText(self.mItemName,itemName)
	self:SetWndText(self.mItemDesc,itemDes)
	self:SetWndText(self.mNumText,string.replace(ccClientText(22207),num))

	--local uiList = self:GetUIScroll("wayCell")
	--uiList:Create(self.mWayList,cell,function (...) self:ListItem(...) end)
	self:RefreshList()
end

function UISupleGetWay:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp,function (pb)
		local opType = pb.opType
		if opType == 10 then
			GF.ShowMessage(ccClientText(22215))
			self:RefreshList()
		end
	end)
end

function UISupleGetWay:OnTryTcpReconnect()
	self:WndClose()
end
------------------------------------------------------------------
return UISupleGetWay


