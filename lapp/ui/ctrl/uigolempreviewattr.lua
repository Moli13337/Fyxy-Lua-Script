---
--- Created by LCM.
--- DateTime: 2023/2/28 18:15:10
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolemPreviewAttr:LWnd
local UIGolemPreviewAttr = LxWndClass("UIGolemPreviewAttr", LWnd)

UIGolemPreviewAttr.TYPE_VIEW_SINGLE = 1
UIGolemPreviewAttr.TYPE_VIEW_ALL = 2

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolemPreviewAttr:UIGolemPreviewAttr()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolemPreviewAttr:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolemPreviewAttr:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolemPreviewAttr:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

------------------------- List -------------------------
function UIGolemPreviewAttr:GetShowAttrList(attrType)
    if not self._golemInfo then return {},"" end

    local refId = gModelGolem:GetGolemRefIdByGolemInfo(self._golemInfo)
    local showAttrLv,showAttrTypeName
    local attrList = {}
    if attrType == ModelGolem.GOLEM_DIV_ATTR_PRIME then
        attrList = gModelGolem:GetGolemElementattrGroupIdListByRefId(refId) or {}
        showAttrTypeName = ccClientText(34843)

        local showPreAttrLv = gModelGolem:GetGolemConfigRefByKey("showPreAttrLv")
        if not showPreAttrLv then
            showPreAttrLv = 1
            if LOG_INFO_ENABLED then
                printInfoNR("GolemConfigRef 表格 showPreAttrLv 字段表示展示的主属性等级，没有配置默认是1")
            end
        end
        showAttrLv = showPreAttrLv
    else
        attrList = gModelGolem:GetGolemElementattrDeputyGroupIdListListByRefId(refId) or {}
        showAttrTypeName = ccClientText(34844)

        local showDeputyAttrLv = gModelGolem:GetGolemConfigRefByKey("showDeputyAttrLv")
        if not showDeputyAttrLv then
            showDeputyAttrLv = 1
            if LOG_INFO_ENABLED then
                printInfoNR("GolemConfigRef 表格 showDeputyAttrLv 字段表示展示的副属性等级，没有配置默认是1")
            end
        end
        showAttrLv = showDeputyAttrLv
    end

    local list = {}
    local tempList
    local attrGroupId,ref
    for i,v in ipairs(attrList) do
        attrGroupId = tonumber(v)
        ref = gModelGolem:GetGolemAttrRefByAttrGroupIdAndLv(attrGroupId,showAttrLv)
        if ref then
            tempList = gModelGolem:GetGolemAttrAttrListByRefId(ref.refId)
            for idx,val in ipairs(tempList) do
                table.insert(list,val)
            end
        end
    end
    return list,showAttrTypeName
end

function UIGolemPreviewAttr:RefreshView()
    if not self._golemInfo then return end
    self:InitShowAttrAllList()
end



function UIGolemPreviewAttr:GetShowAttrAllList()
    local list = {}
    local attrTypeList = {}
    if self._viewType == UIGolemPreviewAttr.TYPE_VIEW_SINGLE then
        table.insert(attrTypeList,self._attrType)
    else
        table.insert(attrTypeList,ModelGolem.GOLEM_DIV_ATTR_PRIME)
        table.insert(attrTypeList,ModelGolem.GOLEM_DIV_ATTR_DEPUTY)
    end

    local attrList,showAttrTypeName
    for i,v in ipairs(attrTypeList) do
        attrList,showAttrTypeName = self:GetShowAttrList(v)
        if #attrList > 0 then
            table.insert(list,{
                desc = showAttrTypeName,
                attrList = attrList,
            })
        end
    end
    return list
end

function UIGolemPreviewAttr:InitMsg()

	-- self:WndNetMsgRecv("xxx",function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIGolemPreviewAttr:InitData()
    self._viewType = self:GetWndArg("viewType") or UIGolemPreviewAttr.TYPE_VIEW_SINGLE

    self._golemInfo = self:GetWndArg("golemInfo")
    self._attrType = self:GetWndArg("attrType")

    local showArrow = self:GetWndArg("showArrow")
    if showArrow == nil then
        showArrow = true
    end
    local followRoot = self:GetWndArg("followRoot")
    local offsetPos = self:GetWndArg("offsetPos") or Vector3(0,0,0)
    if followRoot then
        local followRootPos = followRoot.position
        if showArrow then
            local arrowImgRootPos = self.mArrowImgRoot.position
            self.mArrowImgRoot.position = Vector3(followRootPos.x,arrowImgRootPos.y,arrowImgRootPos.z)
        end
        CS.ShowObject(self.mArrowImgRoot,showArrow)

        local followRootAnchorPos = followRoot.position
        self.mAniRoot.position = Vector3(self.mAniRoot.position.x,followRootAnchorPos.y + offsetPos.y,followRootAnchorPos.z)
    end
end


function UIGolemPreviewAttr:InitPreviewAttrList(trans,list)
    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans,list,function(...) self:OnDrawPreviewAttrCell(...) end)
    end
end

function UIGolemPreviewAttr:InitShowAttrAllList()
    local list = self:GetShowAttrAllList()
    local uiShowAttrAllList = self._uiShowAttrAllList
    if uiShowAttrAllList then
        uiShowAttrAllList:RefreshList(list)
    else
        uiShowAttrAllList = self:GetUIScroll("uiShowAttrAllList")
        self._uiShowAttrAllList = uiShowAttrAllList
        uiShowAttrAllList:Create(self.mShowAttrAllList,list,function(...) self:OnDrawShowAttrAllCell(...) end)
    end
end

function UIGolemPreviewAttr:OnDrawPreviewAttrCell(list,item,itemdata,itempos)
    local AttrIconTrans = self:FindWndTrans(item,"AttrIcon")
    local AttrNameTrans = self:FindWndTrans(item,"AttrName")
    local AttrValueTrans = self:FindWndTrans(item,"AttrValue")

    local attrRefId,attrType,attrNum = itemdata.attrRefId,itemdata.attrType,itemdata.attrNum

    local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
    self:SetWndEasyImage(AttrIconTrans,attrIcon)

    local attrName = gModelHero:GetAttributeNameById(attrRefId)
    self:SetWndText(AttrNameTrans,attrName)

    local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrNum)
    self:SetWndText(AttrValueTrans,value)
end

function UIGolemPreviewAttr:OnDrawShowAttrAllCell(list,item,itemdata,itempos)
    local TopDescTrans = self:FindWndTrans(item,"TopDiv/TopDesc")
    local PreviewAttrList = self:FindWndTrans(item,"CenterDiv/PreviewAttrList")

    self:SetWndText(TopDescTrans,itemdata.desc)
    self:InitPreviewAttrList(PreviewAttrList,itemdata.attrList)
end

function UIGolemPreviewAttr:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIGolemPreviewAttr



