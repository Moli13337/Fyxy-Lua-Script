---
--- Created by Administrator.
--- DateTime: 2023/10/24 19:41:03
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubSecret:LChildWnd
local UISubSecret = LxWndClass("UISubSecret", LChildWnd)

UISubSecret.STATE_COMMON = 0
UISubSecret.STATE_CAN_GET= 1
UISubSecret.STATE_RECEIVE = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubSecret:UISubSecret()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubSecret:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubSecret:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubSecret:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitMsg()
	self:RefreshUI()

end


function UISubSecret:OnClickActivity(itemdata)
	local sid = itemdata.sid
    gLxTKData:OnWebActivityClick(itemdata)

	local moreInfo = JSON.decode(itemdata.moreInfo)
	--local webData = gModelActivity:GetWebActivityDataById(sid)
	if moreInfo then
		--local config 	= webData.config
		local annieTips = moreInfo.annieJump or 0
		if annieTips == 1 then
			local link = moreInfo.link
			if not string.isempty(link) then
				CS.UApplication.OpenURL(link)
				return
			end
		end
	end

	if gLGameLanguage:IsAmericaRegion() then
		--暂时只有欧美地区
		GF.OpenWnd("UISecretAwardPop", {sid = sid})
	else
		GF.OpenWnd("UISecop",{sid = sid})
	end
end

function UISubSecret:InitData()
	self._activitySidList = {}
end

function UISubSecret:RefreshUI()
	local has,activityList = gModelActivity:HasActivitySix()

	for k,v in ipairs(activityList) do
		self._activitySidList[v.sid] = true
	end

	local uiList = self._uiList
	if not uiList then
		uiList = self:GetUIScroll("activityList")
		self._uiList = uiList
		uiList:Create(self.mUISuperList,activityList,function (...) self:OnDrawActivity(...) end,UIItemList.SUPER)
	else
		uiList:RefreshList(activityList)
	end
	uiList:DrawAllItems(false)
end

--function UISubSecret:OnAwake()
--	self:DelaySendFinish(0.5)
--end

function UISubSecret:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb) self:OnActivityListResp(pb) end)
end

function UISubSecret:OnActivityListResp(pb)
	local activities = pb.activities
	for i, v in ipairs(activities) do
		local sid = v.sid
		if self._activitySidList[sid] then
			self:RefreshUI()
			break
		end
	end
end

function UISubSecret:OnDrawActivity(list,item,itemdata,itempos)

	local Image = self:FindWndTrans(item,"Image")
	local UIText = self:FindWndTrans(item,"UIText")
	local newTag = self:FindWndTrans(item,"newTag")
	local redPoint = self:FindWndTrans(item,"redPoint")

	local sid = itemdata.sid
	local isNewActivity = gModelActivity:IsActivityNew(sid,true)
	CS.ShowObject(newTag,isNewActivity)

	local data = JSON.decode(itemdata.moreInfo)

	local receive = data.receive
	local click   = data.click
	local getState
	if receive == true then
		getState = self.STATE_RECEIVE
	elseif click == true then
		getState = self.STATE_CAN_GET
	else
		getState = self.STATE_COMMON
	end

	local isShowRed = false
	if not isNewActivity then
		if getState == self.STATE_CAN_GET then
			isShowRed = true
		elseif getState == self.STATE_COMMON then
			if gLGameLanguage:IsJapanVersion() then
				isShowRed = false
			else
				isShowRed = not gModelActivity:IsClickActivityRed(sid)
			end
		end
	end
	CS.ShowObject(redPoint, isShowRed)

	local image  = data.image
	if gLGameLanguage:IsForeignRegion() and data.imageEnglish then
		image = data.imageEnglish
	end

	self:SetWndEasyImage(Image,image, nil, true)
	self:SetWndClick(item, function()
		gModelActivity:CheckActivityClickRed(true, sid)
		gModelActivity:AddRecord(itemdata.sid,GetTimestamp(),true)
		CS.ShowObject(newTag,false)

		if isShowRed then
			if getState == self.STATE_COMMON  then
				CS.ShowObject(redPoint,false)
			end
			gModelActivity:RefreshActTypeRed({id = sid,isNet = true})
		end

		self:OnClickActivity(itemdata, isShowRed)
	end)
end



------------------------------------------------------------------
return UISubSecret


