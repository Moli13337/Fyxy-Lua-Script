---
--- Created by Administrator.
--- DateTime: 2023/10/24 14:12:51
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubValentinesDayPrige:LChildWnd
local UISubValentinesDayPrige = LxWndClass("UISubValentinesDayPrige", LChildWnd)

UISubValentinesDayPrige.HERO_REF_ID = 1
UISubValentinesDayPrige.HERO_IMG = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubValentinesDayPrige:UISubValentinesDayPrige()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubValentinesDayPrige:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubValentinesDayPrige:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubValentinesDayPrige:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubValentinesDayPrige:ListItem(list,item, itemdata, itempos)
	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local icon = CS.FindTrans(item,"Icon")
	local nameText = CS.FindTrans(item,"NameText")
	local desText = CS.FindTrans(item,"DesScroll/DesText")

	self:SetWndEasyImage(icon,entryCfg1.icon)
	self:SetWndText(nameText,entryCfg1.name)
	local str = string.gsub(entryCfg1.description,"\\n","\n")
	self:SetWndText(desText,str)
end

function UISubValentinesDayPrige:RefreshData()
	local list = self._entry or {}
	if self._uiCellList then
		self._uiCellList:RefreshList(list)
	else
		self._uiCellList = self:GetUIScroll("privileList")
		self._uiCellList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)
		self._uiCellList:EnableScroll(true,false)
	end
end

function UISubValentinesDayPrige:InitEvent()

end

function UISubValentinesDayPrige:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
end

function UISubValentinesDayPrige:InitCommand()
	self._sid = self:GetWndArg("sid")
	local entry = self:GetWndArg("entry")
	self._pageId = entry[1].pageId
	self._entry = entry

	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config

	local path = data.privilegeHeroBgImage
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mBg, path)
	end

	path = data.privilegeHeroPopImage
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mPopImage, path)
	end

	local privilegeHero,privilegeHeroPos,privilegeHeroTxt,privilegeHeroTxtImage,privilegeHeroTxtImagePos
	= data.privilegeHero,data.privilegeHeroPos,data.privilegeHeroTxt,data.privilegeHeroTxtImage,data.privilegeHeroTxtImagePos
	if not string.isempty(privilegeHero) then
		local paintTr
		local dropHeroArr = string.split(privilegeHero,"=")
		local tempType = tonumber(dropHeroArr[1])
		if tempType == UISubValentinesDayPrige.HERO_IMG then
			local imagePath = dropHeroArr[2] or dropHeroArr[1]
			if LxUiHelper.IsImgPathValid(imagePath) then
				paintTr = self.mHeroImage
				self:SetWndEasyImage(paintTr,imagePath,nil,true)
			end
		else
			local effRefId = tonumber(dropHeroArr[2] or dropHeroArr[1])
			local ref = gModelHero:GetShowEffectById(effRefId)
			paintTr = self.mHeroPaint
			self:CreateWndSpine(paintTr,ref.heroDrawing,"privilegeHero",false,function(dpSpine)
				dpSpine:SetScale(0.8)
			end)
		end

		CS.ShowObject(paintTr,true)
		if not string.isempty(privilegeHeroPos) then
			local pos = LxDataHelper.ParseVector2NotEmpty2(privilegeHeroPos)
			self:SetAnchorPos(paintTr, pos)
		end
	end


	if not string.isempty(privilegeHeroTxt) then
		local str = string.gsub(privilegeHeroTxt,"\\n","\n")
		self:SetWndText(self.mDesText,str)
		CS.ShowObject(self.mDesTextBg, true)
	end

	if LxUiHelper.IsImgPathValid(privilegeHeroTxtImage) then
		self:SetWndEasyImage(self.mTextImg,privilegeHeroTxtImage,nil,true)
		local privilegeHeroTxtImagePosArr = string.split(privilegeHeroTxtImagePos,"|")
		self.mTextImg.anchoredPosition = Vector3(tonumber(privilegeHeroTxtImagePosArr[1]),tonumber(privilegeHeroTxtImagePosArr[2]),0)
		CS.ShowObject(self.mTextImg, true)
	end
	self:RefreshData()
end

--#####################################################################################################################
--# Common ############################################################################################################
--#####################################################################################################################
function UISubValentinesDayPrige:ResetData(pb)
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



------------------------------------------------------------------
return UISubValentinesDayPrige


