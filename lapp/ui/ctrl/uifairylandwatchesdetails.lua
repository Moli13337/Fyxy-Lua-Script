---
--- Created by Administrator.
--- DateTime: 2021/3/29 15:56:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFairylandWatchesDetails:LWnd
local UIFairylandWatchesDetails = LxWndClass("UIFairylandWatchesDetails", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFairylandWatchesDetails:UIFairylandWatchesDetails()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFairylandWatchesDetails:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFairylandWatchesDetails:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFairylandWatchesDetails:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitEvent()
	self:InitMsg()
	self:InitData()
end


--####################################################################################################################
--### Server #########################################################################################################
--####################################################################################################################
function UIFairylandWatchesDetails:OnActivityResp(pb,ret)
	if self._sid ~= pb.sid then return end

	self:RefreshUI()
end

function UIFairylandWatchesDetails:SetWayItem(list, item, itemdata, itempos)
	local intro = self:FindWndTrans(item,"intro")
	local BtnBlue3 = self:FindWndTrans(item,"BtnBlue3")

	local name = itemdata.title
	local jumpId = itemdata.jumpId
	local jumpDesc = itemdata.jumpDesc
	local moreInfo = itemdata.moreInfo

	if string.isempty(moreInfo) then
		moreInfo = 1
	end

	local isShow =  tonumber(moreInfo) == 1
	CS.ShowObject(item, isShow)
	if not isShow then return end

	self:SetWndText(intro,name)
	local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId,false)
	self:SetWndButtonText(BtnBlue3, jumpDesc)
	self:SetWndButtonGray(BtnBlue3,not isOpen)

	self:SetWndClick(BtnBlue3,function()
		if not gModelFunctionOpen:CheckIsOpened(jumpId,true) then
			return
		end

		gModelFunctionOpen:Jump(jumpId, self:GetWndName())
		self:WndClose()
	end)
end

--####################################################################################################################
--### Common #########################################################################################################
--####################################################################################################################
function UIFairylandWatchesDetails:ResetActivePageData(pb)
	for k, v in ipairs(pb.pages) do
		if v.pageId == ModelActivity.FAIRYLAND_BOSS_DROP then --道具掉落
			local page= gModelActivity:GenerateActivePageDataFromPb(v)
			if page then
				self._activityPageData = {}
				for p,q in ipairs(page.entry) do
					local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,q.pageId,q.entryId)
					if not entryCfg then
						return
					end
					local data = {
						entryId = q.entryId,
						pageId  = q.pageId,
						title   = entryCfg.name,		-- 名称
						--icon 	= entryCfg.icon,		-- 图标
						--desc	= entryCfg.description,	-- 描述
						jumpId  = entryCfg.jumpId,		-- 前往id
						jumpDesc = entryCfg.jumpDesc,	-- 跳转按钮文本
						moreInfo = entryCfg.moreInfo,
					}

					table.insert(self._activityPageData, data)
				end
			end
			break
		end
	end

	table.sort(self._activityPageData, function(a, b)
		return a.entryId < b.entryId
	end)
end

function UIFairylandWatchesDetails:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	gModelActivity:OnActivityPageReq(self._sid)
end

function UIFairylandWatchesDetails:InitEvent()
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end)

	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIFairylandWatchesDetails:InitData()
	self._func = self:GetWndArg("func")
	self._sid = self:GetWndArg("sid")

	gModelActivity:ReqActivityConfigData(self._sid)
end


function UIFairylandWatchesDetails:OnActivityPageResp(pb,ret)
	if self._sid ~= pb.sid then return end

	self:ResetActivePageData(pb)
	self:RefreshUI()
end

function UIFairylandWatchesDetails:RefreshUI()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then
		return
	end

	self._activityData = gModelActivity:GetActivityBySid(self._sid)
	self._cfgDataMoreInfo = webData.config
	local cfg = self._cfgDataMoreInfo

	self:SetWndText(self.mTitle, cfg.InformationBtntext)
	self:SetWndText(self.mTopDesc, cfg.dropInformation)

	local dataList = self._activityPageData
	local itemList = self:FindUIScroll("UIItemList")
	if not itemList then
		itemList = self:GetUIScroll("UIItemList")
		itemList:Create(self.mWayList,dataList,function (...) self:SetWayItem(...)  end)
		itemList:EnableScroll(true,false)
	else
		itemList:RefreshList(dataList)
	end
end

function UIFairylandWatchesDetails:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb) self:OnActivityPageResp(pb) end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function ()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
end


------------------------------------------------------------------
return UIFairylandWatchesDetails


