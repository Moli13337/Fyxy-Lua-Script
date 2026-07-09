---@class PrivilegeCom
local PrivilegeCom = LxClass("PrivilegeCom",nil)
local YXTouchManager = CS.YXTouchManager
local typeLayoutElement = typeof(UnityEngine.UI.LayoutElement)


function PrivilegeCom:PrivilegeCom()

end

---@param wnd LWnd
function PrivilegeCom:Create(tran,type,wnd,noClickEmpty)
    if not CS.IsValidObject(tran) then
        return
    end
    local list = gModelBackflow:GetPrivilegesTypeListByType(type)

    CS.ShowObject(tran,list)
    if not list then
        return
    end

    local text = wnd:FindWndTrans(tran,"Root/name")
    if text then
        wnd:SetWndText(text, ccClientText(23515))


    end
    wnd:SetWndClick(tran, function ()
        self:ShowPriviTips(tran,type,wnd)
    end)

    self:ShowPriviTips(tran,type,wnd,true)

    wnd:EnableClickNotUICall()

    if noClickEmpty then
        return
    end
    wnd.OnClickNotUI = function(wnd,name)
        if name == "BtnPrivile" then
            return
        end
        local tip = wnd:FindWndTrans(tran,"tips")
        CS.ShowObject(tip,false)
    end
end

function PrivilegeCom:ShowPriviTips(btnTran,type,holdWnd,delayClose)
    local list = gModelBackflow:GetPrivilegesTypeListByType(type)
    if not list then
        return
    end

    local strList = {}
    for i, v in ipairs(list) do
        local ref = GameTable.SysBuffRef[tonumber(v.sysbuff)]
        table.insert(strList,ccLngText(ref.desc))
    end

    local desc = table.concat(strList,"\n")
    local tipTran = holdWnd:FindWndTrans(btnTran,"tips")
    local text = holdWnd:FindWndTrans(tipTran,"UIText")
    holdWnd:SetWndText(text,desc)
    local textCom = holdWnd:FindWndText(text)
    local preferredWidth = textCom.preferredWidth
    preferredWidth = math.min(preferredWidth,400)

    local layoutElement = holdWnd:FindCommonComponent(text,typeLayoutElement)
    layoutElement.preferredWidth = preferredWidth


    CS.ShowObject(tipTran,true)
    local canvasGroup = holdWnd:GetCanvasGroup(tipTran)
    canvasGroup.alpha = 1
    if not delayClose then
        return
    end

    local seqCom = holdWnd:GetSeqCom()
    local seq = seqCom:CreateSeq("delayHideTip")
    seq:AppendInterval(2)

    local tween = canvasGroup:DOFade(0,0.5)
    seq:Append(tween)
    seq:OnComplete(function ()
        seqCom:DeleteSeq("delayHideTip")
        CS.ShowObject(tipTran,false)
    end)
    seq:PlayForward()
end

function PrivilegeCom:Destroy()

end


return PrivilegeCom