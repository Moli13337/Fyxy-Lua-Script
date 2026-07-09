---
--- Created by LCM.
--- DateTime: 2024/3/4 14:50:16
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReSpRecast:LWnd
local UIReSpRecast = LxWndClass("UIReSpRecast", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReSpRecast:UIReSpRecast()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReSpRecast:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReSpRecast:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReSpRecast:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:Refresh()
end

function UIReSpRecast:OnOldClickAddBtnFunc(info,isSel)
	local itemId = info.itemId
	local selItemList = {}
	local data = {}
	if not isSel then
		data = {
			itemId = itemId,
			itemType = info.itemType,
			itemNum = info.itemNum,
		}
		selItemList[itemId] = data
	end
	self._selItemList = selItemList

	if isSel then
		self:RefreshView()
	else
		if self._func then
			self._func(data)
		end
		self:WndClose()
	end
end

function UIReSpRecast:RefreshView()
	for k,v in pairs(self._infoList) do
		self:CreateDiv(v)
	end
end

function UIReSpRecast:OnClickAddBtnFunc(info,isSel)
	local itemId = info.itemId
	local haveNum = gModelItem:GetNumByRefId(itemId)
	if haveNum < 1 then
		gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = self:GetWndName()})
		return
	end
	local selItemList = {}
	local data = {}
	if not isSel then
		data = {
			itemId = itemId,
			itemType = info.itemType,
			itemNum = info.itemNum,
		}
		selItemList[itemId] = data
	end
	self._selItemList = selItemList

	if isSel then
		self:RefreshView()
		if self._func then
			self._func()
		end
	else
		if self._func then
			self._func(data)
		end
		self:WndClose()
	end
end

function UIReSpRecast:InitData()
	self._func = self:GetWndArg("func")
	self._runeRefId = self:GetWndArg("runeRefId")
	local selItemData = self:GetWndArg("selItemData")
	local selItemList = {}
	if selItemData then
		local itemId = selItemData.itemId
		selItemList[itemId] = selItemData
	end
	self._isSel = selItemData ~= nil
	self._selItemList = selItemList
end

function UIReSpRecast:OnDrawDescCell(list,item,itemdata,itempos)
	local UIText = self:FindWndTrans(item,"UIText")
	self:SetWndText(UIText,itemdata.name)
	self:InitTextSizeWithLanguage(UIText, -2)
	self:InitTextLineWithLanguage(UIText, -21)
end

function UIReSpRecast:InitMsg()

end

function UIReSpRecast:ExitWnd()
	self:WndClose()
end

function UIReSpRecast:CreateDiv(info)
	local trans = info.trans
	local TitleTxtTrans = self:FindWndTrans(trans,"TitleTxt")
	local ImgTrans = self:FindWndTrans(trans,"Img")
	local ItemImgTrans = self:FindWndTrans(ImgTrans,"ItemImg")
	local ItemNameTrans = self:FindWndTrans(ImgTrans,"ItemName")
	local DescListTrans = self:FindWndTrans(trans,"DescList")
	local haveNumTrans = self:FindWndTrans(trans,"haveNum")
	local AddBtnTrans = self:FindWndTrans(trans,"AddBtn")
	local NoUseTxtTrans = self:FindWndTrans(trans,"NoUseTxt")

	self:InitDescList(DescListTrans,info.descList)

	self:SetWndText(TitleTxtTrans,ccClientText(info.textId))

	local itemId = info .itemId
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(ItemImgTrans,icon)

	local itemName = gModelItem:GetNameByRefId(itemId)
	self:SetWndText(ItemNameTrans,itemName)

	local haveNum = gModelItem:GetNumByRefId(itemId)
	local isEnough = haveNum > 0
	local color = isEnough and "lightGreen" or "lightRed"
	local haveNumStr = string.replace(ccClientText(24822),LUtil.FormatColorStr(haveNum,color))
	self:SetWndText(haveNumTrans,haveNumStr)

	local isSupper = info.isSupper
	CS.ShowObject(AddBtnTrans,isSupper)
	CS.ShowObject(NoUseTxtTrans,not isSupper)

	if isSupper then
		local isSel = self._selItemList[itemId] ~= nil
		local btnType = isSel and "red_1" or "yellow_1"
		local img = LUtil.GetBtnImg(btnType)
		self:SetWndButtonImg(AddBtnTrans,img)
		local btnName = isSel and ccClientText(24842) or ccClientText(24841)
		self:SetWndButtonText(AddBtnTrans,btnName)

		self:SetWndClick(AddBtnTrans,function()
			self:OnClickAddBtnFunc(info,isSel)
		end)
	else
		local str = string.replace(ccClientText(24825),itemName)
		self:SetWndText(NoUseTxtTrans,str)
	end


--[[	CS.ShowObject(AddBtnTrans,isEnough)
	CS.ShowObject(NoUseTxtTrans,not isEnough)
	if isEnough then
		local isSel = self._selItemList[itemId] ~= nil
		local btnType = isSel and "red_1" or "yellow_1"
		local img = LUtil.GetBtnImg(btnType)
		self:SetWndButtonImg(AddBtnTrans,img)

		local btnName = isSel and ccClientText(24842) or ccClientText(24841)
		self:SetWndButtonText(AddBtnTrans,btnName)

		self:SetWndClick(AddBtnTrans,function()
			self:OnClickAddBtnFunc(info,isSel)
		end)
	else
		local str = string.replace(ccClientText(24825),itemName)
		self:SetWndText(NoUseTxtTrans,str)
	end]]
end


function UIReSpRecast:InitEvent()
	self:SetWndClick(self.mMask,function() self:ExitWnd() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:ExitWnd() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIReSpRecast:Refresh()
	local runeRefId = self._runeRefId
	if not runeRefId then return end
	local luckyRecastItem,godRecastItem = gModelRune:GetLucItemAndGodItem(runeRefId)
	if not luckyRecastItem or not godRecastItem then return end
	self._infoList = {}
	local specialShowItem = gModelRune:GetSpecialShowItemList()
	local luckDiv = self.mLuckDiv
	local luckItemId = luckyRecastItem.itemId
	local isSupperLuck = luckItemId ~= nil
	if not isSupperLuck then
		luckItemId = specialShowItem[2] and specialShowItem[2].itemId
	end
	if luckItemId then
		local luckItemName = gModelItem:GetNameByRefId(luckItemId)
		local luckDescList = {
			{
				name = string.replace(ccClientText(24823),luckItemName),
			},
			{
				name = ccClientText(24824),
			},
		}
		local luckInfo = {
			itemId = luckItemId,
			itemType = luckyRecastItem.itemType,
			itemNum = luckyRecastItem.itemNum,
			textId = 24828,
			trans = luckDiv,
			descList = luckDescList,
			isSupper = isSupperLuck,
		}
		self._infoList[luckItemId] = luckInfo
	end
	local showLuckDiv = luckItemId ~= nil
	CS.ShowObject(luckDiv,showLuckDiv)

	local godDiv = self.mTianQiDiv
	local godItemId = godRecastItem.itemId
	local isSupperGod = godItemId ~= nil
	if not isSupperGod then
		godItemId = specialShowItem[1] and specialShowItem[1].itemId
	end
	if godItemId then
		local godItemName = gModelItem:GetNameByRefId(godItemId)
		local godDescList = {
			{
				name = string.replace(ccClientText(24826),godItemName),
			},
			{
				name = ccClientText(24827),
			},
		}
		local godInfo = {
			itemId = godItemId,
			itemType = godRecastItem.itemType,
			itemNum = godRecastItem.itemNum,
			textId = 24829,
			trans = godDiv,
			descList = godDescList,
			isSupper = isSupperGod,
		}
		self._infoList[godItemId] = godInfo
	end
	local showGodDiv = godItemId ~= nil
	CS.ShowObject(godDiv,showGodDiv)

	self:RefreshView()
end

function UIReSpRecast:InitDescList(trans,list)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawDescCell(...) end)
	end
end

------------------------------------------------------------------
return UIReSpRecast


