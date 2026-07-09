---
--- Created by BY.
--- DateTime: 2023/10/25 14:36:03
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubCHNPrige:LChildWnd
local UISubCHNPrige = LxWndClass("UISubCHNPrige", LChildWnd)

UISubCHNPrige.HERO_IMG = 1
UISubCHNPrige.HERO_SPINE =2
UISubCHNPrige.HERO_REF_ID = 3
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubCHNPrige:UISubCHNPrige()
	self._privilegeHeroType = {
		["1"] = UISubCHNPrige.HERO_REF_ID,
		["2"] = UISubCHNPrige.HERO_IMG,
	}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubCHNPrige:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubCHNPrige:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubCHNPrige:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubCHNPrige:RefreshData()
	local list = self._entry or {}
	if self._uiCellList then
		self._uiCellList:RefreshList(list)
	else
		self._uiCellList = self:GetUIScroll("privileList")
		self._uiCellList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)
		self._uiCellList:EnableScroll(true,false)
	end
end

function UISubCHNPrige:ResetData(pb)
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

function UISubCHNPrige:InitEvent()

end

function UISubCHNPrige:InitCommand()
	local sid = self:GetWndArg("sid")
	local entry = self:GetWndArg("entry")
	self._pageId = entry[1].pageId
	self._entry = entry

	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._modelId = modelId

	self._privilegeHeroTypeList = {
		-- [ModelActivity.MODEL_CHN_CELEBRATE] = {
		-- 	[1] = UISubCHNPrige.HERO_REF_ID,
		-- 	[2] = UISubCHNPrige.HERO_IMG,
		-- },
        -- [ModelActivity.ACTIVITY_VALENTINES_DAY] = {
        --     [1] = UISubCHNPrige.HERO_REF_ID,
        --     [2] = UISubCHNPrige.HERO_IMG,
        -- },
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_64] = {
		-- 	[1] = UISubCHNPrige.HERO_SPINE,
		-- 	[2] = UISubCHNPrige.HERO_IMG,
		-- },
		-- [ModelActivity.FAIRY_FATHER_DAY] = {
		-- 	[1] = UISubCHNPrige.HERO_IMG,
		-- 	[2] = UISubCHNPrige.HERO_SPINE,
		-- },
	}

	self._sid = sid
	--gModelActivity:ReqActivityConfigData(sid)
	self:OnActivityConfigData()
end

function UISubCHNPrige:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
end

function UISubCHNPrige:ListItem(list,item, itemdata, itempos)
	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local icon = CS.FindTrans(item,"Icon")
	local nameText = CS.FindTrans(item,"NameText")
	local desText = CS.FindTrans(item,"DescScroll/DesText")

	self:SetWndEasyImage(icon,entryCfg1.icon,nil,true)
	self:SetWndText(nameText,entryCfg1.name)
	local str = string.gsub(entryCfg1.description,"\\n","\n")
	self:SetWndText(desText,str)
end

function UISubCHNPrige:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config

	local privilegeHero,privilegeHeroPos,privilegeHeroTxt,privilegeHeroTxtImage,privilegeHeroTxtImagePos,privilegeHeroTxtPos
	= data.privilegeHero,data.privilegeHeroPos,data.privilegeHeroTxt,data.privilegeHeroTxtImage,data.privilegeHeroTxtImagePos,data.privilegeHeroTxtPos
	local privilegeImage = data.privilegeImage or data.privilegeHeroBgImage
	if LxUiHelper.IsImgPathValid(privilegeImage) then
		CS.ShowObject(self.mBg,true)
		self:SetWndEasyImage(self.mBg,privilegeImage)
	end
	if not string.isempty(privilegeHero) then
		local privilegeHeroType = self._privilegeHeroTypeList[self._modelId]
		if not privilegeHeroType then
			privilegeHeroType = self._privilegeHeroType
		end
		local privilegeHeroArr = string.split(privilegeHero,"=")
		local type = tonumber(privilegeHeroArr[1])
		local paintTr
		local tempType
		if type then
			tempType = privilegeHeroType[type]
		end

		if tempType == UISubCHNPrige.HERO_REF_ID then
			paintTr = self.mHeroPaint
			local effRefId = tonumber(privilegeHeroArr[2])
			local ref = gModelHero:GetShowEffectById(effRefId)
			self:CreateWndSpine(paintTr,ref.heroDrawing,"privilegeHero",false,function(dpSpine)
				--dpSpine:SetScale(1)
			end)
		elseif tempType == UISubCHNPrige.HERO_SPINE then
			paintTr = self.mHeroPaint
			self:CreateWndSpine(paintTr,privilegeHeroArr[2],"privilegeHero",false,function(dpSpine)
				--dpSpine:SetScale(1)
			end)
		else
			paintTr = self.mHeroImg
			local imagePath = privilegeHeroArr[2] or privilegeHeroArr[1]
			if LxUiHelper.IsImgPathValid(imagePath) then
				self:SetWndEasyImage(paintTr,imagePath,nil,true)
			end
		end
		CS.ShowObject(paintTr,true)
		if not string.isempty(privilegeHeroPos) then
			local pos = LxDataHelper.ParseVector2NotEmpty3(privilegeHeroPos)
			self:SetAnchorPos(paintTr, pos)
		end
	end

	if privilegeHeroTxt and privilegeHeroTxt ~= "" then
		local str = string.gsub(privilegeHeroTxt,"\\n","\n")
		self:SetWndText(self.mDesText,str)
		CS.ShowObject(self.mDesBg,true)
		local arr = string.split(privilegeHeroTxtPos,"|")
		local isScale = arr[1] and arr[1] == "1"
		if isScale then
			self.mDesBg2.localScale = Vector2(-1,1)
		end
		if arr[2] then
			local pos = string.split(arr[2],",")
			self.mDesBg.anchoredPosition = Vector2(tonumber(pos[1]),tonumber(pos[2]))
		end
	end

	local privilegeTxtImage, privilegeTxtImagePos = data.privilegeTxtImage, data.privilegeTxtImagePos
	if not string.isempty(privilegeTxtImage) then
		privilegeHeroTxtImage = privilegeTxtImage
	end

	if not string.isempty(privilegeTxtImagePos) then
		privilegeHeroTxtImagePos = privilegeTxtImagePos
	end

	if LxUiHelper.IsImgPathValid(privilegeHeroTxtImage) then
		CS.ShowObject(self.mTextImg,true)
		self:SetWndEasyImage(self.mTextImg,privilegeHeroTxtImage,function()
			if not string.isempty(privilegeHeroTxtImagePos) then
				self:SetAnchorPos(self.mTextImg, LxDataHelper.ParseVector2NotEmpty3(privilegeHeroTxtImagePos))
			end
		end,true)
	end
	self:RefreshData()
end
------------------------------------------------------------------
return UISubCHNPrige


