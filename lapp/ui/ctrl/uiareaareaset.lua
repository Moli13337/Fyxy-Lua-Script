---
--- Created by BY.
--- DateTime: 2023/10/2 17:39:18
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAreaAreaSet:LWnd
local UIAreaAreaSet = LxWndClass("UIAreaAreaSet", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAreaAreaSet:UIAreaAreaSet()
    self._ageList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAreaAreaSet:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAreaAreaSet:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAreaAreaSet:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()

    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
    CS.ShowObject(self.mAreaImage, not self._isEnus)
    CS.ShowObject(self.mAreaImage_enus, self._isEnus)
    CS.ShowObject(self.mProvinceImage, not self._isEnus)
    CS.ShowObject(self.mProvinceImage_enus, self._isEnus)
end

function UIAreaAreaSet:OnClickCut(type)
    local uiListt
    local list = {}
    self._type = type
    CS.ShowObject(self.mProvinceSuper, false)
    CS.ShowObject(self.mAreaSuper, false)
    CS.ShowObject(self.mProvinceSuper_enus, false)
    CS.ShowObject(self.mAreaSuper_enus, false)
    local listBool = false
    if type == 1 then
        uiListt = self._isEnus and self.mProvinceSuper_enus or self.mProvinceSuper
        list = gModelPlayerSpace:GetRoleProvinceListRef()
        local is1 = self._is1 or false
        self._is1 = not is1
        listBool = not is1
    else
        uiListt = self._isEnus and self.mAreaSuper_enus or self.mAreaSuper
        local _provinceId = self._provinceId or self._oldProvince
        if _provinceId == 0 then
            GF.ShowMessage(ccClientText(11524))
            return
        end
        list = gModelPlayerSpace:GetRoleCityListRef(_provinceId)
        local is2 = self._is2 or false
        self._is2 = not is2
        listBool = not is2
    end
    CS.ShowObject(uiListt, listBool)

    local uiList = self._ageList[self._type]
    if uiList then
        uiList:RefreshList(list)
        local _uiListSuper = uiList:GetList()
        _uiListSuper:DrawAllItems()
    else
        local uiList = self:GetUIScroll("ageList" .. self._type)
        uiList:Create(uiListt, list, function(...)
            self:ListItem(...)
        end, UIItemList.SUPER)
        self._ageList[self._type] = uiList
    end
end

function UIAreaAreaSet:RefreshArea()
    local isShow = self._isShowArea
    CS.ShowObject(self.mArea, isShow)
    if not isShow then
        return
    end

    self:SetWndText(self.mAreaText, ccClientText(21136))
    self:SetWndText(self.mAreaText_enus, ccClientText(21136))

    local _city = gModelPlayer:GetCity()
    local cRef = gModelPlayerSpace:GetRoleCityListRefByRefId(_city)
    self:SetWndText(self.mAreaDesText, cRef and ccLngText(cRef.name) or ccClientText(11116))
    self:SetWndText(self.mAreaDesText_enus, cRef and ccLngText(cRef.name) or ccClientText(11116))
    self._oldCity = _city
end

function UIAreaAreaSet:ListItem(list, item, itemdata, itempos)
    local img = CS.FindTrans(item, "SelImg")
    local text = CS.FindTrans(item, "UIText")

    local id = self._type == 1 and self._provinceId or self._cityId
    CS.ShowObject(img, id == itemdata.refId)
    local str = ccLngText(itemdata.name)
    if id == itemdata.refId then
        str = LUtil.FormatColorStr(str, "white")
    end
    self:SetWndText(text, str)
    self:SetWndClick(item, function()
        self:OnClickArea(itemdata)
    end)
end

function UIAreaAreaSet:InitMessage()
    self:WndNetMsgRecv(LProtoIds.PositionChangeResp, function(...)
        GF.ShowMessage(ccClientText(21147))
        self:WndClose()
    end)
end

function UIAreaAreaSet:InitCommand()
    self:SetWndText(self.mLblBiaoti, ccClientText(21137))
    self:SetWndButtonText(self.mBtnYellow2, ccClientText(21130))
    self:SetWndText(self.mDesText, ccClientText(21140))

    --self._isShowArea = not gLGameLanguage:IsKoreaRegion()	--海外多语言改动：韩国地区不显示
    self._isShowArea = not gLGameLanguage:IsForeignRegion()    --海外多语言改动：--只有中国区域显示
    self:RefreshArea()
    self:RefreshProvince()
end

function UIAreaAreaSet:OnClickClose()
    if not self._provinceId or (self._oldProvince == self._provinceId and self._oldCity == self._cityId) then
        self:WndClose()
        return
    end
    gModelGeneral:OpenUIOrdinTips({ refId = 50008, leftFunc = function()
        self:WndClose()
    end, func = function()
        self:OnClickReq()
    end }, true)
end

function UIAreaAreaSet:OnClickArea(ref)
    if not self._type then
        return
    end
    local refId = ref.refId
    if self._type == 1 then
        self._provinceId = refId
        self:SetWndText(self.mProvinceDesText, ccLngText(ref.name))
        self:SetWndText(self.mProvinceDesText_enus, ccLngText(ref.name))
        CS.ShowObject(self.mProvinceSuper, false)
        CS.ShowObject(self.mProvinceSuper_enus, false)
        if self._isShowArea then
            local list = gModelPlayerSpace:GetRoleCityListRef(self._provinceId)
            local item = list[1]
            self._cityId = item.refId
            self:SetWndText(self.mAreaDesText, ccLngText(item.name))
            self._is2 = false
        end
    else
        self._cityId = refId
        self:SetWndText(self.mAreaDesText, ccLngText(ref.name))
        self:SetWndText(self.mAreaDesText_enus, ccLngText(ref.name))
        CS.ShowObject(self.mAreaSuper, false)
        CS.ShowObject(self.mAreaSuper_enus, false)
        self._is2 = false
    end
end

function UIAreaAreaSet:OnClickReq()
    if (not self._provinceId and not self._cityId) or (self._oldProvince == self._provinceId and self._oldCity == self._cityId) then
        self:WndClose()
        return
    end
    if not self._type then
        return
    end
    local _provinceCount = gModelPlayerSpace:GetProvinceCount() or 0
    local num = gModelChat:GetChatConfigRefByKey("provinceChangeLimit")
    if (_provinceCount >= num) then
        GF.ShowMessage(string.replace(ccClientText(11534), num))
        return
    end
    local _provinceId = self._provinceId or self._oldProvince
    local _cityId = self._cityId or 0
    gModelPlayerSpace:OnPositionChangeReq(1, _provinceId, _cityId)
end

function UIAreaAreaSet:RefreshProvince()
    self:SetWndText(self.mProvinceText, ccClientText(21135))
    self:SetWndText(self.mProvinceText_enus, ccClientText(21135))

    if gLGameLanguage:IsKoreaRegion() then
        CS.ShowObject(self.mProvinceText, false)
    end

    local _province = gModelPlayer:GetProvince()
    local pRef = gModelPlayerSpace:GetRoleProvinceListRefByRefId(_province)
    self:SetWndText(self.mProvinceDesText, pRef and ccLngText(pRef.name) or ccClientText(11116))
    self:SetWndText(self.mProvinceDesText_enus, pRef and ccLngText(pRef.name) or ccClientText(11116))
    self._oldProvince = _province

    if not self._isShowArea then
        self:SetAnchorPos(self.mProvince, Vector2.New(268, -198))
    end
end

function UIAreaAreaSet:InitEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:OnClickClose()
    end)
    self:SetWndClick(self.mBtnClose, function(...)
        self:OnClickClose()
    end)
    self:SetWndClick(self.mBtnProvince, function(...)
        self:OnClickCut(1)
    end)
    self:SetWndClick(self.mBtnArea, function(...)
        self:OnClickCut(2)
    end)
    self:SetWndClick(self.mBtnYellow2, function(...)
        self:OnClickReq()
    end)

    self:SetWndClick(self.mBtnProvince_enus, function(...)
        self:OnClickCut(1)
    end)
    self:SetWndClick(self.mBtnArea_enus, function(...)
        self:OnClickCut(2)
    end)
end
------------------------------------------------------------------
return UIAreaAreaSet


