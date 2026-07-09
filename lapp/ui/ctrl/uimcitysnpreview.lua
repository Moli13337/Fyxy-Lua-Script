---
--- Created by BY.
--- DateTime: 2023/10/10 16:26:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMCitySnPreview:LWnd
local UIMCitySnPreview = LxWndClass("UIMCitySnPreview", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMCitySnPreview:UIMCitySnPreview()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMCitySnPreview:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMCitySnPreview:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMCitySnPreview:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIMCitySnPreview:InitEvent()
	self:SetWndClick(self.mBtnClose,function ()self:WndClose() end)
end
function UIMCitySnPreview:SetSkinInfo()
	local refId = self._refId
	local ref = gModelPlayerSpace:GetOneNightSkinRefByRefId(refId)
	self:SetWndEasyImage(self.mSkinImg,ref.previewPicture)
	CS.ShowObject(self.mSkinImg,true)
	self:SetWndEasyImage(self.mTitleImg,ref.nameIcon,nil,true)
	CS.ShowObject(self.mTitleImg,true)
end

function UIMCitySnPreview:UIDragOnDrag(dragKey,eventData)
	local trans = self.mSkinImg
	local _w = self._w
	local pos = trans.localPosition
	local mX = pos.x
	if(pos.x <= -_w) then
		mX = -_w
	elseif (pos.x >= _w)then
		mX = _w
	end
	trans.localPosition = Vector3.New(mX, self._initY, pos.z)
end
function UIMCitySnPreview:RefreshData()
	self:SetSkinInfo()
	local refId = self._refId

	local func = nil
	local curSkin = gModelPlayer:GetMainCitySkin() or 0
	local isAct = gModelPlayerSpace:GetMainCitySkinByRefId(refId)
	local isUse = refId == curSkin
	local btnStr = ""
	if not isUse then
		local ref = gModelPlayerSpace:GetOneNightSkinRefByRefId(refId)
		local free = ref.free or 0
		if not isAct and free == 0 then
			local item = LxDataHelper.ParseItem_3(ref.item)
			local bagNum = gModelItem:GetNumByRefId(item.itemId)
			local isActivate = bagNum >= item.itemNum

			local itemId = item and item.itemId
			local itemNum = item and item.itemNum
			if isActivate then
				btnStr = ccClientText(30304)
				func = function()
					local bool = gModelFunctionOpen:CheckIsOpened(21005004,true)
					if not bool then return end
					local data = { refId = itemId, num = itemNum }
					gModelItem:OnItemUseReq({data})
				end
			else
				btnStr = ccClientText(30305)
				func = function()
					gModelGeneral:CheckItemEnough(itemId,itemNum,true,self:GetWndName())
				end
			end
		else
			btnStr = ccClientText(30302)
			func = function()
				gModelPlayerSpace:OnMainCitySkinChangeReq(refId)
				local musicList = gModelOneNight:GetMusicList()
				for i, v in pairs(musicList) do
					if(v.activateSkin == refId)then
						gModelOneNight:SetBackgroundMusic(v.refId)
					end
				end
			end
		end
	end

	CS.ShowObject(self.mUseImg,isUse)
	CS.ShowObject(self.mBtnGo,not isUse)
	self:SetWndText(self.mGoText,btnStr)
	self:InitTextLineWithLanguage(self.mGoText, -30)
	self:InitTextSizeWithLanguage(self.mGoText, -2)

	self:SetWndClick(self.mBtnGo,function ()
		if func then func() end
	end)
end
function UIMCitySnPreview:InitMessage()
	self:WndNetMsgRecv(LProtoIds.MainCitySkinChangeResp,function(pb)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.ItemUseResp,function(pb)
		GF.ShowMessage(ccClientText(30308))
		self:RefreshData()
	end)
end
function UIMCitySnPreview:InitCommand()
	--self:SetWndText(self.mCloseText,ccClientText(30205))

	local refId = self:GetWndArg("refId")
	self._refId = refId

	self._initY = self.mSkinImg.localPosition.y
	local sW = self.mSkinImg.rect.width
	local pW = self.mPop.rect.width
	self._w = (sW - pW)/2
	self:InitDrag()
	self:RefreshData()
end

function UIMCitySnPreview:InitDrag()--拖动
	self:UIDragSetItem("MainCitySkinPreview","AniRoot/SkinImg",CS.YXUIDrag.DragMode.DragOrigin)
end
------------------------------------------------------------------
return UIMCitySnPreview


