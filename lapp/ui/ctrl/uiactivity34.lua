---
--- Created by Administrator.
--- DateTime: 2025/12/26 18:55:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActivity34:LWnd
local UIActivity34 = LxClass("UIActivity34", LWnd)
------------------------------------------------------------------
local dataKeys = {"titleText","text"}
--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActivity34:UIActivity34()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActivity34:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActivity34:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActivity34:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
end

function UIActivity34:InitDescList(list)
	---@type UIItemList
	local uiDescList = self._uiDescList
	if uiDescList then
		uiDescList:RefreshList(list)
	else
		uiDescList = self:GetUIScroll("uiDescList")
		uiDescList:Create(self.mDescList, list, function(...) self:OnDrawDescCell(...) end)
	end
	uiDescList:EnableScroll(true)
end

function UIActivity34:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
end

function UIActivity34:OnClickXXXXFunc(itemdata)
end

function UIActivity34:OnDrawDescCell(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			Title = self:FindWndTrans(item,"TitleImg/Title"),
			Desc = self:FindWndTrans(item,"Desc"),
		}
		self:SetComponentCache(instanceID, itemCache)
	end
	self:SetWndText(itemCache.Title,itemdata[dataKeys[1]])
	self:SetWndText(itemCache.Desc,itemdata[dataKeys[2]])
end

function UIActivity34:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end


function UIActivity34:InitData()
	local sid = self:GetWndArg("sid")
	local subPage = self:GetWndArg("subPage")
	if subPage then
		sid = gModelActivity:GetSidByUniqueJump(subPage)
	end
	if not sid then
		self:WndClose()
		return
	end
	self._sid = sid
	gModelActivity:ReqActivityConfigData(sid)

	local openStatus = self:GetWndArg("openStatus")
	if openStatus and openStatus == 1 then
		LPlayerPrefs.SetActivity34AutoOpen(1)
	end
	LPlayerPrefs.SetActivity34Time(GetTimestamp())
	FireEvent(EventNames.ON_REFRESH_ACTIVITY_MODEL_34)
end

function UIActivity34:OnClickXXXBtnFunc()
end

function UIActivity34:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	local actWebData = gModelActivity:GetWebActivityDataById(sid)
	if not actWebData then return end

	local config = actWebData.config
	if not config then return end

	local list = {}
	local tempStr
	local textNume = config.textNume or 3
	for i = 1,textNume do
		local showData = {}
		for idx,key in ipairs(dataKeys) do
			tempStr = key .. i
			showData[key] = config[tempStr] or ""
		end
		table.insert(list,showData)
	end
	self:InitDescList(list)
end

function UIActivity34:InitText()
	self:SetWndText(self.mCloseTip,ccClientText(10103))
end

------------------------------------------------------------------
return UIActivity34