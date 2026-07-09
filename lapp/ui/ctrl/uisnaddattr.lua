---
--- Created by Administrator.
--- DateTime: 2023/10/13 18:04:40
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISnAddAttr:LWnd
local UISnAddAttr = LxWndClass("UISnAddAttr", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISnAddAttr:UISnAddAttr()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISnAddAttr:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISnAddAttr:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISnAddAttr:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitText()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    self:GetAttrData()

    self:GetAllSkinAttr()
end

function UISnAddAttr:GetAllSkinAttr()
    self._heroSkinList = gModelHero:GetHeroSkinList()

    --生效的部分
    local tempSkinList = {}
    if not self._heroSkinList then
        return {}
    end

    for k, v in pairs(self._heroSkinList) do
        if v.endTime == "-1" then
            table.insert(tempSkinList, v.starRefId)
        end
    end

    local tempAttr = {} -- 用id 为key 后面方便取值

    for k, v in ipairs(tempSkinList) do
        if v ~= 0 then
            local effectRef = ModelSkinBook:GetSkinUpStarConfig(v)

            local attrAll = effectRef.AttrAll

            if not string.isempty(attrAll) then
                local attrList = LxDataHelper.ParseAttrList(attrAll)
                for i, val in ipairs(attrList) do
                    local data = {
                        refId = val.refId,
                        numType = val.type,
                        value = val.value,
                    }
                    local key = data.refId + data.numType
                    if not tempAttr[key] then
                        tempAttr[key] = data
                    else
                        tempAttr[key].value = data.value + tempAttr[key].value
                    end
                end
            end
        end
    end

    return tempAttr

end

function UISnAddAttr:InitText()
    self:SetWndText(self.mTopTitle, ccClientText(17415))
    self:SetWndText(self.mCenterTitle, ccClientText(17416))
    self:SetWndText(self.mNoDescTxt, ccClientText(17417))
    --[[	local heroSkinDesc = gModelHero:GeConfigByKey("heroSkinDesc")
        self:SetWndText(self.mDescTxt,ccLngText(heroSkinDesc))]]

    self:SetWndText(self.mDescTxt, ccClientText(17419))
end

function UISnAddAttr:GetAttrData()
    local heroRefId = self._heroRefId
    if heroRefId then
        gModelHero:OnHeroSkinAllAttrReq(heroRefId)
    end
end

function UISnAddAttr:OnDrawSkinAttrCell(list, item, itemdata, itempos)
    local refId, numType, value = itemdata.refId, itemdata.numType, itemdata.value
    local IconTrans = self:FindWndTrans(item, "Icon")
    local attrNameTrans = self:FindWndTrans(item, "AttrName")
    local attrValueTrans = self:FindWndTrans(item, "AttrValue")

    if IconTrans then
        local icon = gModelHero:GetAttributeIconById(refId)
        self:SetWndEasyImage(IconTrans, icon, function()
            CS.ShowObject(IconTrans, true)
        end)
    end
    if attrNameTrans then
        local name = gModelHero:GetAttributeNameById(refId)
        local nameStr = string.replace(ccClientText(18315), name)
        self:SetWndText(attrNameTrans, nameStr)
    end

    if attrValueTrans then
        local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId, numType, value)
        self:SetWndText(attrValueTrans, valueStr)
    end
end

function UISnAddAttr:ShowAttrInfo(attrList)
    local isStrEmpty = string.isempty(attrList)
    --获取一个全局的部分
    local allAttr = self:GetAllSkinAttr()

    isStrEmpty = isStrEmpty and #allAttr==0
    local haveAttr = {}
    if not isStrEmpty then
        local list = {}
        attrList = string.split(attrList, ",")
        for i, v in ipairs(attrList) do
            v = string.split(v, "=")

            local data = {
                refId = tonumber(v[1]),
                numType = tonumber(v[2]),
                value = tonumber(v[3]),
            }

            local checkKey = data.refId + data.numType
            if allAttr[checkKey] then
                data.value = allAttr[checkKey].value + data.value

                haveAttr[checkKey] = true
            end

            table.insert(list, data)
        end

        --未拥有的
        for k, v in pairs(allAttr) do
            if not haveAttr[k] then
                table.insert(list, v)
            end
        end

        table.sort(list, function(a, b)
            if a.refId == b.refId then
                return a.numType < b.numType
            end

            return a.refId<b.refId
        end)

        self:InitAttrList(list)
    end

    CS.ShowObject(self.mNoDescDiv, isStrEmpty)
    CS.ShowObject(self.mAttrList, not isStrEmpty)
    print("============== ")
end

function UISnAddAttr:InitMsg()
    self:WndNetMsgRecv(LProtoIds.RefreshDataResp, function()
        self:GetAttrData()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroSkinAllAttrResp, function(pb, ret)
        self:ShowAttrInfo(pb.attr)
    end)
end

function UISnAddAttr:InitData()
    self._heroRefId = self:GetWndArg("heroRefId")
end

function UISnAddAttr:InitEvent()
    self:SetWndClick(self.mBg, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UISnAddAttr:InitAttrList(list)
    local uiList = self._uiList
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll("heroAttrList")
        self._uiList = uiList
        uiList:Create(self.mAttrList, list, function(...)
            self:OnDrawSkinAttrCell(...)
        end)
    end
end
------------------------------------------------------------------
return UISnAddAttr


