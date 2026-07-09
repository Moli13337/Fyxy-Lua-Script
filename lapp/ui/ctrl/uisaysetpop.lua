---
--- Created by BY.
--- DateTime: 2023/10/2 16:57:05
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISaySetPop:LWnd
local UISaySetPop = LxWndClass("UISaySetPop", LWnd)
local typeLayoutElement = typeof(UnityEngine.UI.LayoutElement)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISaySetPop:UISaySetPop()
    self._checkmarkList = {}
    self._uiList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISaySetPop:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISaySetPop:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISaySetPop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()

    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
end

function UISaySetPop:ListItem(list, item, itemdata, itempos)
    local titleText = self:FindWndTrans(item, "TitleBg/Image/TitleText")
    local root1 = self:FindWndTrans(item, "Root1")
    local root2 = self:FindWndTrans(item, "Root2")

    local type = itemdata.type
    local title = itemdata.title

    self:SetWndText(titleText, title)
    CS.ShowObject(root1, type == 1)
    CS.ShowObject(root2, type ~= 1)
    if type == 1 then
        self:SetRootItem1(item, itemdata)
    elseif type ~= 1 then
        self:SetRootItem2(item, itemdata)
    end
end

function UISaySetPop:Cell1ListItem(list, item, itemdata, itempos)
    local checkmark = self:FindWndTrans(item, "Toggle/Background/Checkmark")
    local toggleText = self:FindWndTrans(item, "Toggle/ToggleText")

    self._checkmarkList[itemdata.type] = checkmark
    --local bool = self._toggleList[itemdata.type]
    if itemdata[1] == 1007 then
        printInfoN2("--","--")
    end
    local bool = gModelChat:GetChatSetValue(itemdata.type)

    local txt = ccLngText(itemdata.txt)

    CS.ShowObject(checkmark, bool)
    self:SetWndText(toggleText, txt)
    self:SetWndClick(item, function()
        self:OnClickToggle(itemdata.type)
    end)
end

function UISaySetPop:SetRootItem2(item, itemdata)
    local root2 = self:FindWndTrans(item, "Root2")
    local cellList2 = self:FindWndTrans(root2, "CellList2")

    local InstanceID = item:GetInstanceID()
    local type = itemdata.type

    local list = gModelChat:GetChatSetRefByType(type)
    local uiList = self:GetUIScroll(InstanceID)
    if not uiList:GetList() and cellList2 then
        uiList:Create(cellList2, list, function(...)
            self:Cell1ListItem(...)
        end)
        local len = #list
        if len > 0 then
            local hang = math.ceil(len / 2)
            local height = hang * 30 + (hang - 1) * 26
            --LxUiHelper.SetSizeWithCurAnchor(item,1,len*30)
            local layoutcell = cellList2:GetComponent(typeLayoutElement)
            layoutcell.preferredHeight = height
            local layoutEle = item:GetComponent(typeLayoutElement)
            layoutEle.preferredHeight = height + 70
        end
    end
end

function UISaySetPop:OnClickConfirm()
    --local toggleList = self._toggleList or {}
    --local str = ""
    --for i, v in pairs(toggleList) do
    --    if string.isempty(str)then
    --        str = string.format("%s=%s",i,v == true and "1" or "0")
    --    else
    --        str = string.format("%s|%s=%s",str,i,v == true and "1" or "0")
    --    end
    --end
    self:GetPriovinceIsReq()
    local gradeNewValue = gModelChat:GetIsShowGrade() or false
    local isChange = self._gradeOldValue ~= gradeNewValue
    --for i, v in pairs(toggleList) do
    --	if i == 15 and v~= bool then
    --		bGrade15 = true
    --		break
    --	end
    --end
    --LPlayerPrefs.SetChatSetServerList(str)
    FireEvent(EventNames.ON_CHAT_SET_CHANGE)
    if isChange then
        FireEvent(EventNames.ON_CHAT_SET_CHANGE_GRADE)
    end
    local args = "16="
    local index = gModelChat:GetChatSetValue(16) and 1 or 0
    --local index = 0
    --for i, v in pairs(toggleList) do
    --	if i == 16 then
    --		index = v and 1 or 0
    --		break
    --	end
    --end
    args = args .. index
    gModelChat:ChatSetReq(args)
    self:WndClose()
end
function UISaySetPop:SetRootItem1(item, itemdata)
    local root1 = self:FindWndTrans(item, "Root1")
    local cellList1 = self:FindWndTrans(root1, "CellList1")
    local root1Text = self:FindWndTrans(root1, "Root1Text")


    --item itemsuper拿出来  --中间元素判断是否为英语地区
    local item1 = self._isEnus and self:FindWndTrans(root1, "SetMag/Item1_enus") or self:FindWndTrans(root1, "SetMag/Item1")
    local item1Img = self._isEnus and self:FindWndTrans(root1, "SetMag/Item1_enus/Image") or self:FindWndTrans(root1, "SetMag/Item1/Image")
    local item1Super = self._isEnus and self:FindWndTrans(root1, "SetMag/Laye/ItemSuper3_enus") or self:FindWndTrans(root1, "SetMag/Laye/ItemSuper3")
    local item1Text = self._isEnus and self:FindWndTrans(root1, "SetMag/Item1_enus/UIText") or self:FindWndTrans(root1, "SetMag/Item1/UIText")

    local item2 = self._isEnus and self:FindWndTrans(root1, "SetMag/Item2_enus") or self:FindWndTrans(root1, "SetMag/Item2")
    local item2Img = self._isEnus and self:FindWndTrans(root1, "SetMag/Item2_enus/Image") or self:FindWndTrans(root1, "SetMag/Item2/Image")
    local item2Super = self._isEnus and self:FindWndTrans(root1, "SetMag/Laye/ItemSuper2_enus") or self:FindWndTrans(root1, "SetMag/Laye/ItemSuper2")
    local item2Text = self._isEnus and self:FindWndTrans(root1, "SetMag/Item2_enus/UIText") or self:FindWndTrans(root1, "SetMag/Item2/UIText")

    local item3 = self._isEnus and self:FindWndTrans(root1, "SetMag/Item3_enus") or self:FindWndTrans(root1, "SetMag/Item3")
    local item3Img = self._isEnus and self:FindWndTrans(root1, "SetMag/Item3_enus/Image") or self:FindWndTrans(root1, "SetMag/Item3/Image")
    local item3Super = self._isEnus and self:FindWndTrans(root1, "SetMag/Laye/ItemSuper1_enus") or self:FindWndTrans(root1, "SetMag/Laye/ItemSuper1")
    local item3Text = self._isEnus and self:FindWndTrans(root1, "SetMag/Item3_enus/UIText") or self:FindWndTrans(root1, "SetMag/Item3/UIText")

    CS.ShowObject(item1, true)
    CS.ShowObject(item2, true)
    CS.ShowObject(item3, true)

    local type = itemdata.type

    self._item1Super = item1Super
    self._item2Super = item2Super
    self._item3Super = item3Super
    self._item1Text = item1Text
    self._item2Text = item2Text
    self._item3Text = item3Text
    self:SetWndText(root1Text, ccClientText(34501))
    self:SetItemSuperDes()

    local list = gModelChat:GetChatSetRefByType(type)
    local uiList = self:GetUIScroll("cellList1")
    uiList:Create(cellList1, list, function(...)
        self:Cell1ListItem(...)
    end)
    local len = #list
    local height = len * 30 + (len - 1) * 26
    local layoutcell = cellList1:GetComponent(typeLayoutElement)
    layoutcell.preferredHeight = height
    local layoutEle = item:GetComponent(typeLayoutElement)
    layoutEle.preferredHeight = height + 235

    self:SetWndClick(item1, function()
        self:SetItemSuper(1, item1Super)

        printInfoN2("cjh---------setpop-------", "----------------1------")
    end)
    self:SetWndClick(item2, function()
        self:SetItemSuper(2, item2Super)

        printInfoN2("cjh---------setpop-------", "----------------2------")
    end)
    self:SetWndClick(item3, function()
        self:SetItemSuper(3, item3Super)

        printInfoN2("cjh---------setpop-------", "----------------3------")
    end)
end
function UISaySetPop:GetPriovinceIsReq()
    local curPriovince = gModelPlayer:GetProvince()
    local curCity = gModelPlayer:GetCity()

    local _province = self._province or curPriovince
    local _city = self._city or 0
    local _ageId = self._ageId

    if (_province and _province ~= curPriovince) or (_city > 0 and _city ~= curCity) then
        local _provinceCount = gModelPlayerSpace:GetProvinceCount() or 0
        local num = gModelChat:GetChatConfigRefByKey("provinceChangeLimit")
        if _provinceCount >= num and not self._isOneTps then
            self._isOneTps = true
            GF.ShowMessage(string.replace(ccClientText(11534), num))
        elseif _provinceCount < num then
            gModelPlayerSpace:OnPositionChangeReq(1, _province, _city)
        end
    end
    if _ageId and gModelPlayer:GetPlayerAgeRefId() ~= _ageId then
        gModelPlayerSpace:OnPlayerChangeInfoReq(2, tostring(_ageId))
    end
end
function UISaySetPop:InitMessage()
    --self:WndNetMsgRecv(LProtoIds.CrusadeAgainstInfoResp,function(pb)
    --	self:RefreshPhysical()
    --	self:RefreshData()
    --end)
    self:WndEventRecv(EventNames.SENSITIVE_REGULATE, function()
        local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_1)
        if sensitive then
            return
        end
        self:CloseAir()
    end)
end

function UISaySetPop:InitEvent()
    self:SetWndClick(self.mBgImage, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mBtnConfirm, function()
        self:OnClickConfirm()
    end)
end
function UISaySetPop:InitCommand()

    self._gradeOldValue = gModelChat:GetChatSetValue(15) or false

    self:SetWndText(self.mLblBiaoti, ccClientText(34500))
    self:SetWndButtonText(self.mBtnConfirm, ccClientText(34506))

    --local chatSetServerList = LPlayerPrefs.chatSetServerList or ""
    --local arr = string.split(chatSetServerList,"|")
    --local toggleList = {}
    --for i, v in ipairs(arr) do
    --    local as = string.split(v,"=")
    --    if as[2] then
    --        toggleList[tonumber(as[1])] = as[2] == "1"
    --    end
    --end
    --self._toggleList = toggleList

    local list = {
        { type = 1, title = ccClientText(34502) },
        { type = 2, title = ccClientText(34503) },
        { type = 6, title = ccClientText(34512) },
        { type = 3, title = ccClientText(34504) },
        { type = 4, title = ccClientText(34505) },
        { type = 5, title = ccClientText(34511) },
    }


    --【L聊天系统】聊天设置功能优化（客户端）
    --http://192.168.16.2:3002/issues/398
    local showList = {}
    for k, v in ipairs(list) do
        local childListData = gModelChat:GetChatSetRefByType(v.type)
        local isShow = true
        if v.type == 1 then
            isShow =not gLGameLanguage:IsForeignRegion()
        end

        if childListData and #childListData > 0 and isShow then
            table.insert(showList, v)
        end
    end

    local uiList = self:GetUIScroll("mCellSuper2")
    uiList:Create(self.mCellSuper2, showList, function(...)
        self:ListItem(...)
    end)
    uiList:EnableScroll(true, false)
end

function UISaySetPop:RefreshData()

end

function UISaySetPop:SetItemSuperDes()
    local _province = self._province or gModelPlayer:GetProvince()
    local _city = self._city or gModelPlayer:GetCity()
    local _ageId = self._ageId or gModelPlayer:GetPlayerAgeRefId() or 0
    local ageId = tonumber(_ageId) <= 0 and 0 or tonumber(_ageId)
    local pRef = gModelPlayerSpace:GetRoleProvinceListRefByRefId(_province)
    local cRef = gModelPlayerSpace:GetRoleCityListRefByRefId(_city)
    -- local aRef = gModelPlayerSpace:GetRoleAgeListRefByRefId(ageId)
    local provinceStr = pRef and ccLngText(pRef.name) or ccClientText(11116)
    local areaStr = cRef and ccLngText(cRef.name) or ccClientText(11116)
    local ageStr = ageId == 0 and ccClientText(21186) or ageId
    ageStr = tonumber(_ageId) <= 0 and ageStr or string.replace(ccClientText(34510), ageStr)

    self:SetWndText(self._item1Text, string.replace(ccClientText(34507), provinceStr))
    self:SetWndText(self._item2Text, string.replace(ccClientText(34508), areaStr))
    self:SetWndText(self._item3Text, string.replace(ccClientText(34509), ageStr))
end
function UISaySetPop:OnClickSuperItem(itemdata)
    local type = itemdata.type
    if type == 1 then
        self._province = itemdata.ref.refId
    elseif type == 2 then
        self._city = itemdata.ref.refId
    elseif type == 3 then
        self._ageId = itemdata.ref.refId
    end
    CS.ShowObject(self._item1Super, false)
    CS.ShowObject(self._item2Super, false)
    CS.ShowObject(self._item3Super, false)
    self._type = 0
    self:SetItemSuperDes()
end
function UISaySetPop:SetItemSuper(type, uiListSuper)
    local oldType = self._type or 0
    local curType = oldType ~= type and type or 0
    CS.ShowObject(self._item1Super, false)
    CS.ShowObject(self._item2Super, false)
    CS.ShowObject(self._item3Super, false)
    self._type = curType
    if curType == 0 then
        return
    end
    local list = {}
    local resultList = {}
    if type == 1 then
        list = gModelPlayerSpace:GetRoleProvinceListRef()
    elseif type == 2 then
        local _province = self._province or gModelPlayer:GetProvince()
        if not _province or _province == 0 then
            GF.ShowMessage(ccClientText(11524))
            return
        end
        list = gModelPlayerSpace:GetRoleCityListRef(_province)
    elseif type == 3 then
        list = gModelPlayerSpace:GetRoleAgeListRef()
    end
    for i, v in ipairs(list) do

        local data = {}
        data.ref = v
        data.type = type

        table.insert(resultList, data)
        v.type = type
    end

    CS.ShowObject(self._item1Super, curType == 1)
    CS.ShowObject(self._item2Super, curType == 2)
    CS.ShowObject(self._item3Super, curType == 3)

    local key = uiListSuper:GetInstanceID()
    local uiList = self._uiList[type]
    if uiList then
        uiList:RefreshList(resultList)
        uiList:DrawAllItems()
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(uiListSuper, resultList, function(...)
            self:SuperListItem(...)
        end, UIItemList.SUPER)
        self._uiList[type] = uiList
    end
end
function UISaySetPop:SuperListItem(list, item, itemdata, itempos)
    local img = CS.FindTrans(item, "SelImg")
    local text = CS.FindTrans(item, "UIText")

    local type = itemdata.type
    local selRefId = 0
    local str = ccLngText(itemdata.ref.name)
    if type == 1 then
        selRefId = self._province or gModelPlayer:GetProvince()
    elseif type == 2 then
        selRefId = self._city or gModelPlayer:GetCity()
    elseif type == 3 then
        selRefId = self._ageId or gModelPlayer:GetPlayerAgeRefId() or 0
        str = itemdata.ref.refId == 0 and ccClientText(21186) or itemdata.ref.refId
    end
    CS.ShowObject(img, selRefId == itemdata.ref.refId)
    if selRefId == itemdata.ref.refId then
        str = LUtil.FormatColorStr(str, "white")
    end
    self:SetWndText(text, str)
    self:SetWndClick(item, function()
        self:OnClickSuperItem(itemdata)

        --printInfoN2("cjh---------SuperListItem-------","----------------itemdata------"..itemdata[2])
    end)
end
function UISaySetPop:OnClickToggle(type)
    local checkmarkList = self._checkmarkList or {}
    --local toggleList = self._toggleList or {}

    local tr = checkmarkList[type]
    local bool = gModelChat:GetChatSetValue(type)
    if tr then
        CS.ShowObject(tr, not bool)
        gModelChat:SetChatSetValue(type, not bool)
    end
end
------------------------------------------------------------------
return UISaySetPop


