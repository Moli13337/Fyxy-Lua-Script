---
--- Created by BY.
--- DateTime: 2023/10/19 11:10:58
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubLuckPrige:LChildWnd
local UISubLuckPrige = LxWndClass("UISubLuckPrige", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubLuckPrige:UISubLuckPrige()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubLuckPrige:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubLuckPrige:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubLuckPrige:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubLuckPrige:InitEvent()

end

function UISubLuckPrige:RefreshData()
	local list = self._entry or {}
	if self._uiCellList then
		self._uiCellList:RefreshList(list)
	else
		self._uiCellList = self:GetUIScroll("privileList")
		self._uiCellList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)
		self._uiCellList:EnableScroll(true,false)
	end
end

function UISubLuckPrige:ListItem(list,item, itemdata, itempos)
	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local icon = CS.FindTrans(item,"Icon")
	local nameText = CS.FindTrans(item,"NameText")
	local desText = CS.FindTrans(item,"DesText")

	self:SetWndEasyImage(icon,entryCfg1.icon)
	self:SetWndText(nameText,entryCfg1.name)
	local str = string.gsub(entryCfg1.description,"\\n","\n")
	self:SetWndText(desText,str)
end

function UISubLuckPrige:ResetData(pb)
	local sid = pb.sid
	if(self._sid ~= sid)then
		return
	end
	for i, v in ipairs(pb.pages) do
		if self._pageId == v.pageId then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			self._entry = page.entry
			break
		end
	end
	self:RefreshData()
end

function UISubLuckPrige:InitCommand()
	self._sid = self:GetWndArg("sid")
	local entry = self:GetWndArg("entry")
	self._pageId = entry[1].pageId
	self._entry = entry

	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config

	local privilegeHero,privilegeHeroPos,privilegeHeroTxt,privilegeHeroTxtImage,privilegeHeroTxtImagePos
	= data.privilegeHero,data.privilegeHeroPos,data.privilegeHeroTxt,data.privilegeHeroTxtImage,data.privilegeHeroTxtImagePos
	local newImage,newImageFrame2
	= data.newImage2,data.newImageFrame2
	if LxUiHelper.IsImgPathValid(newImage) then
		local paint = self.mTopBg
		self:SetWndEasyImage(paint,newImage,function ()
			CS.ShowObject(paint,true)
		end ,true)
	end
	if not string.isempty(newImageFrame2) then
		local arr = string.split(newImageFrame2,"=")
		if LxUiHelper.IsImgPathValid(arr[1]) then
			self:SetWndEasyImage(self.mTopImg,arr[1])
		end
		if LxUiHelper.IsImgPathValid(arr[2]) then
			self:SetWndEasyImage(self.mBottonImg,arr[2])
		end
		if LxUiHelper.IsImgPathValid(arr[3]) then
			self:SetWndEasyImage(self.mCentreImg,arr[3])
		end
	end
	if not string.isempty(privilegeHero) then
		local paint
		local arr = string.split(privilegeHero,"=")
		if arr[1] == "1" then
			paint = self.mHeroImg
			self:SetWndEasyImage(paint,arr[2],nil,true)
		elseif arr[1] == "2" then
			paint = self.mHeroPaint
			self:CreateWndSpine(paint,arr[2],"privilegeHero")
		elseif tonumber(privilegeHero) > 0 then
			local ref = gModelHero:GetShowEffectById(tonumber(privilegeHero))
			if ref then
				paint = self.mHeroPaint
				self:CreateWndSpine(paint,ref.heroDrawing,"privilegeHero",false,function(dpSpine)
					dpSpine:SetScale(0.8)
				end)
			end
		end
		if paint and not string.isempty(privilegeHeroPos) then
			CS.ShowObject(paint,true)
			local pos = LxDataHelper.ParseVector2NotEmpty2(privilegeHeroPos)
			self:SetAnchorPos(paint, pos)
		end
	end
	if privilegeHeroTxt and privilegeHeroTxt ~= "" then
		local str = string.gsub(privilegeHeroTxt,"\\n","\n")
		self:SetWndText(self.mDesText,str)
	end
	if LxUiHelper.IsImgPathValid(privilegeHeroTxtImage) then
		local paint = self.mTextImg
		self:SetWndEasyImage(paint,privilegeHeroTxtImage,function ()
			CS.ShowObject(paint,true)
		end ,true)
		if paint and not string.isempty(privilegeHeroTxtImagePos) then
			local pos = LxDataHelper.ParseVector2NotEmpty2(privilegeHeroTxtImagePos)
			self:SetAnchorPos(paint, pos)
		end
	end
	self:RefreshData()
end

function UISubLuckPrige:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
end
------------------------------------------------------------------
return UISubLuckPrige


