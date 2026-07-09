---
--- Created by BY.
--- DateTime: 2023/10/8 21:24:23
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISevoxDail:LWnd
local UISevoxDail = LxWndClass("UISevoxDail", LWnd)
local typeofRectTransform = typeof(CS.RectTransform)
local YXUIPointUtil = CS.YXUIPointUtil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISevoxDail:UISevoxDail()
	---@type UIIconEasyList
	self._uiItemList = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISevoxDail:OnWndClose()
	if self._uiItemList then
		self._uiItemList:Destroy()
		self._uiItemList = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISevoxDail:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISevoxDail:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitScrollView()
	--self:SetPos()
	self:SetWndClick(self.mMask,function () self:WndClose() end)

	self:TimerStart(self._delayTimer,0,false,1)
end

function UISevoxDail:SetPos()
	local follow = self:GetWndArg("root")
	local target = self.mRoot:GetComponent(typeofRectTransform)
	--local camera = gLGameUI:GetCSUICamera()
	--
	--local screenPos =camera:WorldToScreenPoint(follow.position)+ self._offset
	--local UScreen = UnityEngine.Screen;
	--local x =screenPos.x
	--local min = 0
	--local max = UScreen.width- target.rect.width
	--if x< min then
	--	x = min
	--elseif x> max then
	--	x = max
	--end
	--local y = screenPos.y-65
	--local z = screenPos.z
	----print(string.format("x: %s,y: %s,z %s",x,y,z))
	--local targetPos = camera:ScreenToWorldPoint(Vector3(x,y,z))
	--target.position = targetPos

	local canvasRect =LGameUI.GetUICanvasRoot()
	local targetPos=YXUIPointUtil.GetScreenPoint(canvasRect,follow)

	local canvasRectTran = canvasRect:GetComponent(typeofRectTransform)
	local area = canvasRectTran.rect
	local min = -area.width/2
	local max = area.width/2- target.rect.width

	local pos = Vector3.New(targetPos.x,targetPos.y,0)+ self._offset

	if pos.x <min then
		pos.x = min
	elseif pos.x>max then
		pos.x = max
	end

	target.localPosition = pos

end

function UISevoxDail:OnTimer(key)
	self:SetPos()
end

function UISevoxDail:InitScrollView()
	local itemList = self:GetWndArg("itemsList")
	local status = self:GetWndArg("status")

	--CS.ShowObject(self.mNotReceived,status == 0)
	CS.ShowObject(self.mReceived,status == 2)

	local t ={}
	for k,v in ipairs(itemList) do
		local itemType = v.itemType or v.type
		local itemNum = v.itemNum or v.count
		local itemId = v.itemId or v.refId
		local effect = v.effect
		if itemType == 2 then
			for i=1,itemNum do
				local data = {
					itemType = itemType,
					itemId = itemId,
					itemNum = 1,
					effect = effect
				}
				table.insert(t,data)
			end
		else
			table.insert(t,{
				itemType = itemType,
				itemId = itemId,
				itemNum = itemNum,
				effect = effect
			})
		end
	end

	local uiItemList = self._uiItemList
	if not uiItemList then
		uiItemList = UIIconEasyList:New()
		self._uiItemList  = uiItemList
		uiItemList:Create(self, self.mItemList)
	end

	local cnt = #t
	if cnt>3 then
		uiItemList:EnableScroll(true,true)
	end

	uiItemList:RefreshList(t, true)

	if cnt == 1 then
		self._offset = self._offsetList[1]
	else
		local index = cnt > #self._offsetList and #self._offsetList or cnt
		self._offset = self._offsetList[index]
	end

	local NotReceived = self.mNotReceived:GetComponent(typeofRectTransform)
	NotReceived.localPosition = Vector3.New(NotReceived.localPosition.x * cnt,NotReceived.localPosition.y,0)

	local Received = self.mReceived:GetComponent(typeofRectTransform)
	Received.localPosition = Vector3.New(Received.localPosition.x * cnt,Received.localPosition.y,0)
end

function UISevoxDail:InitData()
	self._offsetList =
	{
		[1] = Vector3(-53,90,0),
		[2] = Vector3(-94,90,0),
		[3] = Vector3(-137,90,0)
	}
	self._delayTimer = "_delayTimer"

	local itemFunc = function(refId,num) gModelGeneral:OpenItemInfoTip(refId,num) end
	local heroFunc = function() end
	local equipFunc = function(refId) gModelGeneral:OpenEquipInfoTip(refId,nil,1,true) end
	self._funcList = {
		[1] = itemFunc,
		[2] = heroFunc,
		[3] = equipFunc,
	}
end
------------------------------------------------------------------
return UISevoxDail


