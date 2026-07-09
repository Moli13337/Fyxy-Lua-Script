---
--- Created by BY.
--- DateTime: 2023/10/27 14:48:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPerity:LWnd
local UIPerity = LxWndClass("UIPerity", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPerity:UIPerity()
	self._tabTransList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPerity:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPerity:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPerity:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitTrans()
	self:InitCommand()
end

function UIPerity:InitTrans()
	self._typeString = {
		[ModelPlayer.PERSONALITY_HEAD_IMAGE] = ccClientText(13104),
		[ModelPlayer.PERSONALITY_HEAD_FRAME] = ccClientText(13105) ,  --
		[ModelPlayer.PERSONALITY_DESIGNATION] = ccClientText(13106) ,  --
		[ModelPlayer.PERSONALITY_APPEARANCE] = ccClientText(13107) ,  --
	}
	self._downCountKey = "self._downCountKey"

	self:SetWndText(self.mTitleText,ccClientText(13102))
	self:SetWndButtonText(self.mGoToButton,ccClientText(13247))
	self:SetWndText(self.mAppearanceAttributeText,ccClientText(13108))
	self:SetWndText(self.mOpenConditionText,ccClientText(13110))
end
--跳转
function UIPerity:OnClickGoTo()
    local jump = self._jump
    if(jump and jump ~= "")then
        if(gModelFunctionOpen:CheckIsOpened(jump,true))then
            gModelFunctionOpen:Jump(jump,self:GetWndName())
        end
    end
end
-------------------------------------------------------------------------------------

function UIPerity:ChangeFigurbChildImage(trans,bool)
	if bool then
		self:SetWndTabStatus(trans, LWnd.StateOn)
	else
		self:SetWndTabStatus(trans, LWnd.StateOff)
	end
end

function UIPerity:SetCurTime(curTime,trans)
	self._curTime = curTime
	self._curTimeTrans = trans
end
--------------------------------------cell------------------------------
-- 头像列表
function UIPerity:InitHeadImageList()
	self._headList = self:GetHeadImageList(ModelPlayer.PERSONALITY_HEAD_IMAGE)
	self._headImageBtnList = {}
	if(self._heroIconList)then
		self._heroIconList:RefreshData(self._headList)
	else
		self._heroIconList = self:GetUIScroll("_heroIconList")
		self._heroIconList:Create(self.mHeadImageList,self._headList,function (...) self:OnDrawHeadImageCell(...) end, UIItemList.WRAP)
	end
	self:ClickHeadImageBtnEvent(1)
end
-- 点击形象Item
function UIPerity:ClickFigureBtnEvent(index)
	self:ChangeClickBtnHitImage(index,self._heroBtnList)
	local heroImage = self._heroImageList[index]
	self:ChangePlayerFigure(heroImage)
	self:ChangeSaveBtnText(heroImage)
end

-- 加载英雄spine
function UIPerity:LoadHeroSpine(prefabName)
	if not prefabName then
		return
	end
	self:DestroyHeroSpine()
	self:CreateWndSpine(self.mSpinePos,prefabName,prefabName,false,function()
		local spine = self:FindWndSpineByKey(prefabName)
		if spine then
			spine:SetAnimationCompleteFunc(function()
				spine:PlayAnimation(0,"idle",true)
			end)
			spine:SetScale(2.5)
			self._lastHero = spine
		end
	end)
end

function UIPerity:OnDrawTitleCell(list,item, itemdata, itempos)
	local btnTrans = CS.FindTrans(item,"Designation")
	local Bg = CS.FindTrans(btnTrans,"Bg")
	local TextAndImage = CS.FindTrans(btnTrans,"TextAndImage")
	local DesignationImage = CS.FindTrans(TextAndImage,"DesignationImage")
	local AttributeText = CS.FindTrans(TextAndImage,"AttributeText")
	local ConditionText = CS.FindTrans(TextAndImage,"ConditionText")
	local Icon = CS.FindTrans(btnTrans,"Icon")
	local Use = CS.FindTrans(Icon,"IsUse")
	local IsGet = CS.FindTrans(Use,"IsGet")
	local NotGet = CS.FindTrans(Use,"NotGet")
	local Hit = CS.FindTrans(Icon,"Hit")
	local ref = itemdata.ref
	local index = itempos
	local isValid = itemdata.isValid
	local refId = ref.refId
	local description = ccLngText(ref.description)
	local imageStr = ref.icon
	local attList = gModelPlayer:GetTitleAttributes(refId) or {}
	local str = self:GetAttributesStringByID(attList)
	self._titleBtnList[index] = btnTrans
	self:SetWndEasyImage(DesignationImage,imageStr)
	self:SetWndText(ConditionText,description)
	self:SetWndText(AttributeText,str)
	CS.ShowObject(Use,true)
	local _playerTitle = gModelPlayer:GetPlayerTitle()
	CS.ShowObject(IsGet,_playerTitle == refId)
	CS.ShowObject(Hit,index == self._currIndex)

	if isValid then
		CS.ShowObject(NotGet,false)
		self:SetWndImageGray(Bg,false)
		self:SetWndImageGray(DesignationImage,false)
		self:SetXUITextColor(self:FindWndText(AttributeText),LUtil.ColorByHex("139057FF"))
		self:SetXUITextColor(self:FindWndText(ConditionText),LUtil.ColorByHex("734f22ff"))
	else
		CS.ShowObject(NotGet,_playerTitle ~= refId)
		self:SetWndImageGray(Bg,true)
		self:SetWndImageGray(DesignationImage,true)
		self:SetXUITextColor(self:FindWndText(AttributeText),LUtil.ColorByHex("7f8186FF"))
		self:SetXUITextColor(self:FindWndText(ConditionText),LUtil.ColorByHex("7f8186FF"))
	end
	self:SetWndClick(item,function()
		self:ClickTitleBtnEvent(index)
	end)
end

function UIPerity:SetInfoSort(ref,useId)
	local list = {}
	for i, v in pairs(ref) do
		local index = self._info[v.refId]
		local headImage = {
			ref = v,
			isValid = index and true or false,
			isUse = useId == v.refId
		}
		table.insert(list,headImage)
	end
	table.sort(list,function (a,b)
		if(a.isUse ~= b.isUse)then--使用中的排前面
			return a.isUse == true
		end
		if(a.isValid ~= b.isValid)then--解锁的排前面
			return a.isValid == true
		end
		return a.ref.sort < b.ref.sort
	end)
	return list
end

function UIPerity:InitEvent()
	--self:WndEventRecv(EventNames.CLOSE_CURRENT_WND,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBgImage,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	-- 保存
	self:SetWndClick(self.mSaveButton,function() self:OnSaveInit() end)
	self:SetWndClick(self.mSaveButton1,function() self:OnSaveInit() end)
    self:SetWndClick(self.mGoToButton,function()
        self:OnClickGoTo()
    end)
end

function UIPerity:ChangeTime(loseTime)
	if loseTime and self._curTime and self._curTimeTrans then
		self._curTime = self._curTime - loseTime
		if self._curTime > 0 then
			local str
			if(self._curTime < 60)then
				str = ccClientText(13101) .. LUtil.FormatTimespanCn(self._curTime)
			else
				str = ccClientText(13101) .. LUtil.FormatTimespanToMin(self._curTime)
			end
			self:SetWndText(self._curTimeTrans ,str)   -- 有效期时间
		else
			self:TimerStop(self._downCountKey)
			gModelPlayer:OnPersonaliseInfoReq(self._typeTab)
		end
	end
	return self._curTime
end

function UIPerity:InitInfo()
	self._currIndex = 0
	-- 已加载的英雄spine的ID
	self._lastHeroFigureId = nil
	self:SetWndButtonText(self.mSaveButton,ccClientText(13115))
end

function UIPerity:ChangeTab(btnItem,bool)
	if bool then
		self:SetWndTabStatus(btnItem, LWnd.StateOn)
	else
		self:SetWndTabStatus(btnItem, LWnd.StateOff)
	end
end

-- 更新称号属性
function UIPerity:ChangePlayerTitle(title)
	self:DestroyHeroSpine()
	local ref = title.ref
	local isValid = title.isValid
	CS.ShowObject(self.mTitleExhibition,true)
	CS.ShowObject(self.mGoToButton,not isValid)
	CS.ShowObject(self.mSaveButton,isValid)
	local attList = gModelPlayer:GetTitleAttributes(ref.refId) or {}
	local str = self:GetAttributesStringByID(attList)
	self:SetWndEasyImage(self.mTitleImage,ref.icon)

	-- 称号属性，有效期时间显示
	local TitleTimeText
	if not string.isempty(str) then
		self:SetWndText(self.mAttributeText,str)
		CS.ShowObject(self.mTitleExhibitionText1,false)
		CS.ShowObject(self.mTitleExhibitionText2,true)
		CS.ShowObject(self.mTitleTimeText1, false)
		CS.ShowObject(self.mTitleTimeText2, true)
		TitleTimeText = self.mTitleTimeText2
	else
		CS.ShowObject(self.mTitleExhibitionText1,true)
		CS.ShowObject(self.mTitleExhibitionText2,false)
		CS.ShowObject(self.mTitleTimeText1, true)
		CS.ShowObject(self.mTitleTimeText2, false)
		TitleTimeText = self.mTitleTimeText1
	end
	self:SetExpireTimeText(TitleTimeText,ref.refId)
end
-- 打开个人形象页签
function UIPerity:OnClickFigureTab()
	self:InitOpen()
	CS.ShowObject(self.mPersonalitySpine,true)
	CS.ShowObject(self.mPersonalitySpineBg,true)
	CS.ShowObject(self.mPersonalityOther,false)
	CS.ShowObject(self.mPersonalityOtherBg,false)

	local list = gModelPlayer:GetRoleAdventureImageTypeRef()
	if self._uiVisualizeList then
		self._uiVisualizeList:RefreshList(list)
	else
		self._uiVisualizeList = self:GetUIScroll("uiVisualizeList")
		self._uiVisualizeList:Create(self.mVisualizeTypeScroll,list,function (...) self:VisualizeTypeListItem(...) end)
	end
	local type = self._visualizeType or list[1].type
	self:OnClickVisualizeTab(type)
end

function UIPerity:DestroyHeroSpine()
	if self._lastHero then
		self._lastHero:Destroy()
		self._lastHero = nil
	end
end

function UIPerity:OnClickVisualizeTab(type)
	if self._visualizeType then
		self:ChangeTab(self._tabTransList[self._visualizeType],false)
	end
	self:ChangeTab(self._tabTransList[type],true)
	self._visualizeType = type
	self:OnClickFigurbChildType(type)
end

function UIPerity:OnClickTab(type)
	local _typeTab = self._typeTab
	if(_typeTab ~= type)then
		self:InitInfo()
	end
	if(_typeTab > 0)then
		local trans =self._typeTabList[_typeTab]
		self:ChangeTab(trans,false)
	end
	local trans =self._typeTabList[type]
	self:ChangeTab(trans,true)
	self._typeTab = type
	self:ResetData()
end

function UIPerity:FigurbCellList(list,item, itemdata, itempos)
	local btnTrans = CS.FindTrans(item,"HeadUI")
	local HeadBg = CS.FindTrans(btnTrans,"HeadBg")
	local Mask = CS.FindTrans(HeadBg,"Mask")
	local HeadImage = CS.FindTrans(Mask,"HeadImage")
	local Icon = CS.FindTrans(btnTrans,"Icon")
	local Mask = CS.FindTrans(Icon,"Mask")
	local Hit = CS.FindTrans(Icon,"Hit")
	local Use = CS.FindTrans(Icon,"Use")
	local IsUse = CS.FindTrans(Use,"IsUse")
	local NoUse = CS.FindTrans(Use,"NoUse")
	local ref = itemdata.ref
	local index = itempos
	local isValid = itemdata.isValid
	local refId = ref.refId
	local imageStr = ref.icon
	self._heroBtnList[index] = btnTrans
	local _playerFigure = gModelPlayer:GetPlayerFigure()
	self:SetWndEasyImage(HeadImage,imageStr)
	CS.ShowObject(Use,true)
	CS.ShowObject(IsUse,_playerFigure == refId)
	CS.ShowObject(Hit,itempos == self._currIndex)
	if isValid then
		CS.ShowObject(Mask,false)
		self:SetWndImageGray(HeadImage,false)
	else
		CS.ShowObject(Mask,true)
		self:SetWndImageGray(HeadImage,true)
	end
	self:SetWndClick(btnTrans,function()
		self:ClickFigureBtnEvent(index)
	end)
end
-------------------------------item----------------------------------
-- 点击头像Item
function UIPerity:ClickHeadImageBtnEvent(index)
	self:ChangeClickBtnHitImage(index,self._headImageBtnList)
	local hero = self._headList[index]
	self:ChangeHeadImage(hero)
	self:ChangeSaveBtnText(hero)
end
--使用物品激活
function UIPerity:UseActiveItem(refId,type)
	local ref = type == ModelPlayer.PERSONALITY_APPEARANCE and gModelPlayer:GetRoleAdventureImage(refId) or gModelPlayer:GetHeadIconRef(refId)
	if not ref then
		return false
	end

	local activation = ref.activation
	if activation then
		local str = string.split(activation,"=") or {}
		if #str >= 2 then
			local type = tonumber(str[1])
			local itemId = tonumber(str[2])
			local num = gModelItem:GetNumByRefId(itemId)
			if num > 0 then
				local info = {}
				table.insert(info,{refId = itemId,num = 1})
				gModelItem:OnItemUseReq(info)		 --向服务器发送物品使用请求
				return true
			else
				return false
			end
		end
	end

	return false
end

function UIPerity:ChangeSelectItemImage(trans,bool)
	local hit = CS.FindTrans(trans,"Icon/Hit")
	CS.ShowObject(hit,bool)
end
-- 打开头像页签
function UIPerity:OnClickHeadTab()
	self:InitOpen()
	CS.ShowObject(self.mHeadExhibition,true)
	CS.ShowObject(self.mSaveButton,true)
	CS.ShowObject(self.mHeadImageList,true)
	self:InitHeadImageList()
end
-- 保存
function UIPerity:OnSaveInit()
	local _typeTab = self._typeTab
	local item = self._OnSaveItem
	local ref = item.ref
	local isUse = item.isUse
	local isValid = item.isValid
	if(isUse)then
		local string = self._typeString[_typeTab] or ""
		GF.ShowMessage(ccClientText(13250) .. string)
	elseif(not isValid)then
		if self:UseActiveItem(ref.refId,_typeTab) then
			return
		end
		local jump = ref.jump
		if(jump ~= 0)then
			self._jump = jump
			self:OnClickGoTo()
			return
		end
		GF.ShowMessage(ccClientText(13248))
	else
		gModelPlayer:OnPersonaliseChangeReq(_typeTab,ref.refId)
	end
end

-- 设置有效期时间文本
function UIPerity:SetExpireTimeText(trans,refID)
	local expireTime =self._info[refID] and self._info[refID].createTime
	local expTime =self._info[refID] and self._info[refID].expireTime
	--local timeCount = gModelPlayer:GetHeadTime(refID)  -- 没有填有效时间即为永久
	self:TimerStop(self._downCountKey)
	if expireTime and expTime and tonumber(expTime) > 0 then
		local time = GetTimestamp()
		local useTime = (tonumber(expireTime+expTime)/1000)-time
		if useTime <= 0 then
			return
		end
		local str = ccClientText(13101) .. LUtil.FormatTimespanToMin(useTime)
		self:SetWndText(trans,str)   -- 有效期时间
		CS.ShowObject(trans,true)
		self:SetCurTime(useTime,trans)
		self:TimerStart(self._downCountKey,1,false,-1)
	else
		CS.ShowObject(trans,false)
		self:SetCurTime(nil,nil)
	end
end

-- 头像框列表
function UIPerity:InitHeadFrameList()
	self._headFrameList = self:GetHeadImageList(ModelPlayer.PERSONALITY_HEAD_FRAME)
	self._headFrameBtnList = {}
	if(self._uiHeadFrameList)then
		self._uiHeadFrameList:RefreshList(self._headFrameList)
	else
		self._uiHeadFrameList = self:GetUIScroll("_uiHeadFrameList")
		self._uiHeadFrameList:Create(self.mHeadFrameList,self._headFrameList,function (...) self:OnDrawHeadFrameCell(...) end, UIItemList.WRAP)
	end
	self:ClickHeadFrameBtnEvent(1)
	local iconId = gModelPlayer:GetPlayerHead()
	local icon = gModelPlayer:GetHeadIcon(iconId)
	CS.ShowObject(self.mHeadExhibitionMask,true)
	self:SetWndEasyImage(self.mExhibitionHeadImage,icon)
end

--打开个人形象页签:
function UIPerity:OnClickFigurbChildType(typeEnum)
	self._heroBtnList = {}
	local ref = gModelPlayer:GetRoleAdventureImageRefListByType(typeEnum)
	local useId = gModelPlayer:GetPlayerFigure()
	self._heroImageList = self:SetInfoSort(ref,useId)
	if(self._uiHeroImageList)then
		self._uiHeroImageList:RefreshList(self._heroImageList)
	else
		self._uiHeroImageList = self:GetUIScroll("_uiHeroImageList")
		self._uiHeroImageList:Create(self.mHeroHeadImageList,self._heroImageList,function (...) self:FigurbCellList(...) end, UIItemList.WRAP)
	end
	self:ClickFigureBtnEvent(1)
end

function UIPerity:ResetData()
	local _typeTab = self._typeTab
	self._info = gModelPlayer:GetPersonaliseInfo(_typeTab)
	if(not self._info) then
		gModelPlayer:OnPersonaliseInfoReq(_typeTab)
		return
	end
	if _typeTab == ModelPlayer.PERSONALITY_HEAD_IMAGE then
		self:OnClickHeadTab()
	elseif _typeTab == ModelPlayer.PERSONALITY_HEAD_FRAME then
		self:OnClickHeadFrameTab()
	elseif _typeTab == ModelPlayer.PERSONALITY_DESIGNATION then
		self:OnClickTitleTab()
	elseif _typeTab == ModelPlayer.PERSONALITY_APPEARANCE then
		self:OnClickFigureTab()
	end
end

function UIPerity:VisualizeTypeListItem(list,item, itemdata, itempos)
	local btnTab = CS.FindTrans(item,"BtnTab2_1")
	self._tabTransList[itemdata.refId] = btnTab
	self:SetWndTabText(btnTab,ccLngText(itemdata.name))
	self:SetWndTabStatus(btnTab, 1)
	self:SetWndClick(item,function  ()
		self:OnClickVisualizeTab(itemdata.type)
	end)
end

function UIPerity:ChangeTab(trans,bool)
	self:SetWndTabStatus(trans, bool and 0 or 1)
end
-- 打开头像框页签
function UIPerity:OnClickHeadFrameTab()
	self:InitOpen()
	CS.ShowObject(self.mHeadExhibition,true)
	CS.ShowObject(self.mHeadFrame,true)
	CS.ShowObject(self.mSaveButton,true)
	CS.ShowObject(self.mHeadFrameList,true)
	self:InitHeadFrameList()
end
-- 打开称号页签
function UIPerity:OnClickTitleTab()
	self:InitOpen()
	CS.ShowObject(self.mTitleExhibition,true)
	CS.ShowObject(self.mSaveButton,true)
	CS.ShowObject(self.mDesignationList,true)
	self:DesignationList()
end

function UIPerity:ChangeSaveBtnText(item)
	self._OnSaveItem = item
	local isValid = item.isValid
	local saveStr = ccClientText(13120)
	if(isValid)then
		saveStr = ccClientText(13115)
	end
	self:SetWndButtonText(self.mSaveButton1,saveStr)
end

function UIPerity:TabListItem(list,item, itemdata, itempos)
	local btnItem = CS.FindTrans(item,"BtnItem")
	self._typeTabList[itemdata.type] = btnItem
	self:SetWndTabText(btnItem,itemdata.title)
	self:SetWndTabStatus(btnItem, LWnd.StateOff)
	self:SetWndClick(btnItem,function() self:OnClickTab(itemdata.type) end,LSoundConst.CLICK_PAGE_COMMON)
end

function UIPerity:ChangeClickBtnHitImage(index,curBtnList)
	local btnList = curBtnList
	local btn = btnList[index]
	self._currIndex = index
	if self._curClickTrans then
		self:ChangeSelectItemImage(self._curClickTrans,false)
	end
	if(not btn)then
		return
	end
	self._curClickTrans = btn
	self:ChangeSelectItemImage(btn,true)
end

function UIPerity:InitMsg()
	self:WndNetMsgRecv(LProtoIds.PersonaliseInfoResp, function(pb)
		self:ResetData()
	end)
	self:WndNetMsgRecv(LProtoIds.PersonaliseChangeResp, function(pb)
		self:ResetData()
		GF.ShowMessage(self._typeString[self._typeTab] .. ccClientText(10346) )
	end)
	self:WndNetMsgRecv(LProtoIds.PersonaliseUpdateResp, function(pb)
		self:ResetData()
	end)
end

-- 称号列表
function UIPerity:DesignationList()
	self._titleList = self:GetHeadImageList(ModelPlayer.PERSONALITY_DESIGNATION)
	self._titleBtnList = {}
	if(self._uiDesignationList)then
		self._uiDesignationList:RefreshList(self._titleList)
	else
		self._uiDesignationList = self:GetUIScroll("_uiDesignationList")
		self._uiDesignationList:Create(self.mDesignationList,self._titleList,function (...) self:OnDrawTitleCell(...) end, UIItemList.WRAP)
	end
	self:ClickTitleBtnEvent(1)
end

function UIPerity:OnDrawHeadImageCell(list,item, itemdata, itempos)
	local btnTrans = CS.FindTrans(item,"HeadUI")
	local HeadBg = CS.FindTrans(btnTrans,"HeadBg")
	local Mask = CS.FindTrans(HeadBg,"Mask")
	local SelImg = CS.FindTrans(Mask,"HeadImage")
	local Icon = CS.FindTrans(btnTrans,"Icon")
	local Mask = CS.FindTrans(Icon,"Mask")
	local Use = CS.FindTrans(Icon,"Use")
	local IsUse = CS.FindTrans(Use,"IsUse")
	local NoUse = CS.FindTrans(Use,"NoUse")
	local Hit = CS.FindTrans(Icon,"Hit")

	local ref = itemdata.ref
	local index = itempos
	local isValid = itemdata.isValid
	local refId = ref.refId
	local imageStr = ref.icon
	self._headImageBtnList[index] = btnTrans
	local _playerHead = gModelPlayer:GetPlayerHead()

	self:SetWndEasyImage(SelImg,imageStr)
	CS.ShowObject(Use,true)
	CS.ShowObject(IsUse,_playerHead == refId)
	CS.ShowObject(Hit,itempos == self._currIndex)
	if isValid then
		CS.ShowObject(Mask,false)
		self:SetWndImageGray(SelImg,false)
	else
		CS.ShowObject(Mask,true)
		self:SetWndImageGray(SelImg,true)
	end
	self:SetWndClick(item,function()
		self:ClickHeadImageBtnEvent(index)
	end)
end
-- 获取属性
function UIPerity:GetAttributesStringByID(attList)
	local str = ""
	local index = 1
	for i, v in ipairs(attList) do
		local attRef = gModelHero:GetAttributeRefById(v[1])
		local attName = ccLngText(attRef.name)
		local attType = v[2]
		local value = attType == 1 and v[3] or (tonumber(v[3]) * 100 ) .. "%"
		if index > 1 and index%2 == 0 then
			str = str .."   " .. attName .. ":" .. value .. "\n"
		else
			str = str .. attName .. ":" ..value
		end
		index = index + 1
	end
	return str
end
---------------------------------------------------------------
-- 根据类型获取对应表中全部数据
function UIPerity:GetHeadImageList(type)
	local ref

	local useId
	if type == ModelPlayer.PERSONALITY_HEAD_IMAGE then
		useId = gModelPlayer:GetPlayerHead()
		ref = gModelPlayer:GetRolePlayerHeadListByType(1)
	elseif type == ModelPlayer.PERSONALITY_HEAD_FRAME then
		useId = gModelPlayer:GetPlayerHeadFrame()
		ref = gModelPlayer:GetRolePlayerHeadListByType(2)
	elseif type == ModelPlayer.PERSONALITY_DESIGNATION then
		useId = gModelPlayer:GetPlayerTitle()
		ref = gModelPlayer:GetRolePlayerHeadListByType(3)
	end

	return self:SetInfoSort(ref,useId)
end
-- 点击称号Item
function UIPerity:ClickTitleBtnEvent(index)
	self:ChangeClickBtnHitImage(index,self._titleBtnList)
	local title = self._titleList[index]
	self:ChangePlayerTitle(title)
	self:ChangeSaveBtnText(title)
	self._jump = title.ref.jump
end
-------------------------------页签----------------------------------
function UIPerity:InitOpen()
	CS.ShowObject(self.mPersonalitySpine,false)
	CS.ShowObject(self.mPersonalitySpineBg,false)
	CS.ShowObject(self.mPersonalityOther,true)
	CS.ShowObject(self.mPersonalityOtherBg,true)
	CS.ShowObject(self.mTitleExhibition,false)
	CS.ShowObject(self.mHeadExhibition,false)
	CS.ShowObject(self.mSaveButton,false)
	CS.ShowObject(self.mHeadFrame,false)
	CS.ShowObject(self.mHeadFrameList,false)
	CS.ShowObject(self.mDesignationList,false)
	CS.ShowObject(self.mHeadImageList,false)
	CS.ShowObject(self.mGoToButton,false)
end

-- 更新个人形象
function UIPerity:ChangePlayerFigure(figureId)
	local ref = figureId.ref
	self:SetWndText(self.mAppearanceAttributeText1,ccLngText(ref.attrDesc))
	self:SetWndText(self.mOpenConditionText1,ccLngText(ref.description))

    if not self._lastHeroFigureId or self._lastHeroFigureId ~= figureId then
        self:LoadHeroSpine(ref.spine)
        self._lastHeroFigureId = figureId
    end
end

function UIPerity:InitCommand()
	local list = {
		{type = 1,title = self._typeString[1]},
		{type = 2,title = self._typeString[2]},
		{type = 3,title = self._typeString[3]},
		{type = 4,title = self._typeString[4]},
	}
	self._typeTabList = {}
	self._typeTab = 0
	local _uiTabList = self:GetUIScroll("_uiTabList")
	_uiTabList:Create(self.mTypeBtnList,list,function (...) self:TabListItem(...) end)

	local startType = self:GetWndArg("page") or ModelPlayer.PERSONALITY_HEAD_IMAGE
	self:OnClickTab(startType)

end
-- 点击头像框Item
function UIPerity:ClickHeadFrameBtnEvent(index)
	self:ChangeClickBtnHitImage(index,self._headFrameBtnList)
	local headFrame = self._headFrameList[index]
	self:ChangeHeadFrame(headFrame)
	self:ChangeSaveBtnText(headFrame)
end

function UIPerity:OnTimer(key)
	if key == self._downCountKey then
		self:ChangeTime(1)
	end
end

function UIPerity:OnDrawHeadFrameCell(list,item, itemdata, itempos)
	local btnTrans = CS.FindTrans(item,"HeadFrame")
	local eff = CS.FindTrans(item,"HeadFrame/Eff")
	local HeadFrameImage = CS.FindTrans(btnTrans,"HeadFrameImage")
	local Icon = CS.FindTrans(btnTrans,"Icon")
	local Mask = CS.FindTrans(Icon,"Mask")
	local Use = CS.FindTrans(Icon,"Use")
	local UseHeadFrame = CS.FindTrans(Use,"UseHeadFrame")
	local NoHeadFrame = CS.FindTrans(Use,"NoHeadFrame")
	local Hit = CS.FindTrans(Icon,"Hit")

	local ref = itemdata.ref
	local index = itempos
	local isValid = itemdata.isValid
	local refId = ref.refId
	local imageStr = ref.icon
	local instanceId = item:GetInstanceID()
	self._headFrameBtnList[index] = btnTrans

	local _playerHeadFrame = gModelPlayer:GetPlayerHeadFrame()
	self:SetWndEasyImage(HeadFrameImage,imageStr)
	local isEff = ref.effect and ref.effect ~= ""
	CS.ShowObject(eff,isEff)
	if isEff then
		self:CreateWndEffect(eff,ref.effect,instanceId,100)
	end

	CS.ShowObject(Use,true)
	CS.ShowObject(UseHeadFrame,_playerHeadFrame == refId)
	CS.ShowObject(Hit,index == self._currIndex)
	if isValid then
		CS.ShowObject(Mask,false)
		--self:SetWndImageGray(HeadFrameImage,false)
	else
		CS.ShowObject(Mask,true)
		--self:SetWndImageGray(HeadFrameImage,true)
	end
	self:SetWndClick(item,function()
		self:ClickHeadFrameBtnEvent(index)
	end)
end
--------------------------------更新展示-------------------------------------------
-- 更新头像
function UIPerity:ChangeHeadImage(hero)
	self:DestroyHeroSpine()
	local ref = hero.ref
	local isValid = hero.isValid
	CS.ShowObject(self.mHeadExhibitionMask,true)
	self:SetWndEasyImage(self.mExhibitionHeadImage,ref.icon)
	self:SetWndText(self.mPlayNameText,ccLngText(ref.name))
	self:SetWndText(self.mConditionText,ccLngText(ref.description))
	self:SetExpireTimeText(self.mTimeText,ref.refId)

	if not isValid then
		self:SetWndButtonText(self.mSaveButton,ccClientText(13246))
	else
		self:SetWndButtonText(self.mSaveButton,ccClientText(13115))
	end
end

-- 更新头像框
function UIPerity:ChangeHeadFrame(headFrame)
	self:DestroyHeroSpine()
	local ref = headFrame.ref
	local isValid = headFrame.isValid
	CS.ShowObject(self.mHeadFrameImage,true)
	self:SetWndEasyImage(self.mHeadFrameImage,ref.icon)
	local isEff = ref.effect and ref.effect ~= ""
	CS.ShowObject(self.mHeadFrameEff,isEff)
	if isEff then
		self:CreateWndEffect(self.mHeadFrameEff,ref.effect,"HeadFrameEff",100)
	end
	self:SetWndText(self.mPlayNameText,ccLngText(ref.name))
	self:SetWndText(self.mConditionText,ccLngText(ref.description))
	self:SetExpireTimeText(self.mTimeText,ref.refId)

	if not isValid then
	   self:SetWndButtonText(self.mSaveButton,ccClientText(13246))
	else
		self:SetWndButtonText(self.mSaveButton,ccClientText(13115))
	end
end
-------------------------------------------------------------------
return UIPerity