---
--- Created by By.
--- DateTime: 2023/10/18 15:09:28
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UI_CTDevEnvironment:LWnd
local UI_CTDevEnvironment = LxWndClass("UI_CTDevEnvironment", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UI_CTDevEnvironment:UI_CTDevEnvironment()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UI_CTDevEnvironment:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UI_CTDevEnvironment:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UI_CTDevEnvironment:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:RegEvent()
	self:InitEnvData()
	self:RefreshUI()
end

function UI_CTDevEnvironment:ShowListInfo()
	local _uiList = self._uiEvnDataList
	if(_uiList)then
		_uiList:RefreshList(self._listData)
	else
		_uiList = self:GetUIScroll("_uiEvnDataList")
		_uiList:Create(self.mUISuperList,self._listData,function (...) self:DrawListItem(...) end,UIItemList.SUPER_GRID)
		self._uiEvnDataList = _uiList
		_uiList:EnableScroll(true,false)
	end
	_uiList:DrawAllItems()
end

function UI_CTDevEnvironment:RefreshUI()
	self:ShowNowUseInfo()
	self:ShowListInfo()
end

function UI_CTDevEnvironment:OnClickItem(itemData)
	self._selTid = itemData.tid
	self._id = itemData.id
	self._uiEvnDataList:DrawAllItems()
	LDevEnvironment.SetEnvironment(self._selTid, self._id)
end

function UI_CTDevEnvironment:InitEnvData()
	local envDataList = LDevEnvironment.datalist or {}
	local showData = {}
	local envMap = {}
	for k,v in ipairs(envDataList) do
		local titleData = {type=0,name=v.title}
		table.insert(showData, titleData)
		local items = {}
		local tid = v.tid
		local tags = v.tags
		for m, n in ipairs(v.ids)  do
			local idx = m % 4
			if idx == 1 then
				items = {}
				table.insert(showData, {type=1, items=items})
			end
			table.insert(items, {tid=tid, id=tonumber(n) or 0, tag=tags[m] or ""})
		end
		envMap[tid] = v
	end

	self._listData = showData

	local mapData = envMap[LDevEnvironment.tid]
	self._curInfoStr = ""
	if mapData then
		local bMatch
		local idx
		for k,v in ipairs(mapData.ids or {}) do
			if LGameSettings.platformId == tonumber(v) then
				idx = k
				bMatch = true
				break
			end
		end
		if bMatch then
			self._curInfoStr = "当前环境设置: "..tostring(mapData.title).."  packageid="..tostring(LGameSettings.platformId).."-"..tostring(mapData.tags[idx])
			self._selTid = LDevEnvironment.tid
			self._id = LGameSettings.platformId
		end
	end
end

function UI_CTDevEnvironment:DrawListItem(list, item, itemdata, itempos)
	local item = self:FindWndTrans(item,"AniRoot")

	local itemTransList = {}
	for k=1, 4 do
		local tmp = self:FindWndTrans(item, "Item"..k)
		if tmp then
			table.insert(itemTransList, tmp)
		end
	end
	local textTrans = self:FindWndTrans(item, "UIText")

	local useIdx = 0
	if itemdata.type == 0 then
		CS.ShowObject(textTrans,  true)
		self:SetWndText(textTrans, itemdata.name)
		useIdx = 0
	else
		CS.ShowObject(textTrans,  false)

		for k,v in ipairs(itemdata.items) do
			local tmpTrans = itemTransList[k]
			local selTrans = self:FindWndTrans(tmpTrans, "sel")
			local textTrans = self:FindWndTrans(tmpTrans, "text")
			CS.ShowObject(tmpTrans, true)
			CS.ShowObject(selTrans, v.id == self._id and v.tid ==  self._selTid)
			self:SetWndText(textTrans, tostring(v.id).."-"..tostring(v.tag))
			self:SetWndClick(tmpTrans, function()
				self:OnClickItem(v)
			end)
			useIdx = k
		end
	end

	for k=useIdx + 1, 4 do
		local tmp = itemTransList[k]
		if tmp then
			CS.ShowObject(tmp, false)
		end
	end
end

function UI_CTDevEnvironment:ShowNowUseInfo()
	self:SetWndText(self.mCurContent, self._curInfoStr)
end

function UI_CTDevEnvironment:RegEvent()
	self:SetWndClick(self.mClose, function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mClear, function ()
		LDevEnvironment.ClearEnvironment()
		self._selTid = nil
		self._id = nil
		self._uiEvnDataList:DrawAllItems()
	end)
end
------------------------------------------------------------------
return UI_CTDevEnvironment


