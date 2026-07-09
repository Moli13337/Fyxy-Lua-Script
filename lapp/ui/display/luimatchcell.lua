---@class LUIMatchCell
local LUIMatchCell = LxClass("LUIMatchCell", nil)
local typeofBtObjectView = typeof(CardEHT.BtObjectView)

function LUIMatchCell:LUIMatchCell()


end


function LUIMatchCell:Create(para)
    local root = para.root
    local obj = para.obj
    ---@type LWnd
    local wnd = para.wnd
    self._wnd = wnd
    --self._seqCom = self._wnd:GetSeqCom()


    local tran = obj.transform
    self.tran = tran
    CS.SetParentTrans(tran,root)
    tran.anchoredPosition = para.anchorPos

    local item = tran
    local effectDown = self._wnd:FindWndTrans(item,"effectDown")
    local spineRoot = self._wnd:FindWndTrans(item,"spineRoot")
    local icon = self._wnd:FindWndTrans(item,"icon")
    local effectUp = self._wnd:FindWndTrans(item,"effectUp")
    self._selTran = self._wnd:FindWndTrans(item,"sel")
    CS.ShowObject(self._selTran,false)

    self._effectDown = effectDown
    self._spineRoot = spineRoot
    self._effectUp = effectUp
    self._iconTran = icon



    local instanceId = self:GetInstanceId()

    self._tipEffectKey = instanceId.."tip"
    self._clearEffectKey = instanceId.."clear"
    self._iconEffectKey = instanceId.."icon"
    self._bombUseEffKey = instanceId.."bombUse"
    self._starBulletEffKey = instanceId.."starBullet"
    self._itemCreateEffKey = instanceId.."itemCreate"


    local resPara= self:GetResInfo(para.data)

    CS.ShowObject(icon,resPara.resType == 1)
    CS.ShowObject(spineRoot,resPara.resType == 2)

    self._resPara = resPara
    if resPara.resType == 1 then
        CS.ShowObject(icon,false)
        wnd:SetWndEasyImage(icon,resPara.resName,function ()
            CS.ShowObject(icon,true)
        end ,true)
    elseif resPara.resType == 2 then
        local showPara =
        {
            resName = resPara.resName,
            ani = resPara.idleAni,
            isLoop = true
        }
        self:ShowEffect(self._iconEffectKey,self._spineRoot,showPara)
    end


    local cell = self


    CS.SetOnBeginDrag(obj.gameObject,function (...)

        self:SetLastSibling()

        para.onBeginDrag(cell,...)
    end)

    CS.SetOnDrag(obj.gameObject,function (...)
        para.onDrag(cell,...)
    end)

    CS.SetOnEndDrag(obj.gameObject,function (...)
        para.onEndDrag(cell,...)
    end)

    CS.SetPointerDown(obj.gameObject,function (...)
        para.onPointerDown(cell,...)
    end)

    CS.SetPointerUp(obj.gameObject,function (...)
        para.onPointerUp(cell,...)
    end)

    -- 【C宠物系统】删掉宠物系统相关
    -- self:SetPosInfo(para.pos)

    if para.isCreateItem then
        CS.ShowObject(self._spineRoot,false)
        self:ShowItemCreateEff()
    else
        CS.ShowObject(self._spineRoot,true)
    end
end

-- 【C宠物系统】删掉宠物系统相关
-- function LUIMatchCell:SetPosInfo(pos)
--     ---{x,y}
--     self._pos = pos
--     self.tran.name = "item_".. gModelPetFight:GetIndexByPos(pos)
-- end

function LUIMatchCell:ShowSel(curPos)
    local show = curPos and curPos.x == self._pos.x and curPos.y == self._pos.y

    CS.ShowObject(self._selTran,show)
end

function LUIMatchCell:GetPosInfo()
    return self._pos
end

function LUIMatchCell:GetAnchoredPos()
    return self.tran.anchoredPosition
end

function LUIMatchCell:SetLastSibling()
    self.tran:SetAsLastSibling()
end

function LUIMatchCell:GetInstanceId()
    return tostring(self.tran:GetInstanceID())
end

function LUIMatchCell:GetResInfo(data)
    local para = nil
    if data.item ==2 then
        local ref =GameTable.Match3GameItemRef[6]

        para = {
            resType = ref.resType,
            resName = ref.resName,
            idleAni = "idle"..data.type,
            triggerAni = "show"
        }
    elseif data.item == 3 then
        local ref =GameTable.Match3GameItemRef[7]

        local bulletRes = nil
        if data.type == 1 then
            bulletRes = "fx_ui_sanxiao_hong_bullet"
        elseif data.type == 2 then
            bulletRes = "fx_ui_sanxiao_lv_bullet"
        elseif data.type == 3 then
            bulletRes = "fx_ui_sanxiao_lan_bullet"
        elseif data.type == 4 then
            bulletRes = "fx_ui_sanxiao_zi_bullet"
        elseif data.type == 5 then
            bulletRes = "fx_ui_sanxiao_huang_bullet"
        end

        para = {
            resType = ref.resType,
            resName = ref.resName,
            idleAni = "idle"..data.type,
            triggerAni = "attack"..data.type,
            bulletRes = bulletRes
        }
    else
        local ref =GameTable.Match3GameItemRef[data.type]
        para = {
            resType = ref.resType,
            resName = ref.resName,
        }
    end

    return para

end



function LUIMatchCell:HideEffect(key)
    local spine = self._wnd:FindWndSpineByKey(key)
    if spine then
        spine:SetVisible(false)
    end
end

function LUIMatchCell:ShowEffect(key,root,para)
    local resName = para.resName
    local ani = para.ani
    local isLoop = para.isLoop
    local aniEndCall = para.aniEndCall
    local spine = self._wnd:FindWndSpineByKey(key)
    if spine then
        spine:SetVisible(true)
        if not string.isempty(ani) then
            spine:PlayAnimation(0,ani,isLoop)
            spine:SetAnimationCompleteFunc(aniEndCall)
        end
    else
        self._wnd:CreateWndSpine(root,resName,key,nil,function (spine)
            if not string.isempty(ani) then
                spine:PlayAnimation(0,ani,isLoop)
                spine:SetAnimationCompleteFunc(aniEndCall)
                spine:SetRaycastTarget(false)
            end
        end,nil,true)
    end
end

function LUIMatchCell:ShowTipEffect()
    local para = {
        resName = "Sanxiaotishi",
        ani = "show",
        isLoop = true
    }
    self:ShowEffect(self._tipEffectKey,self._effectDown,para)
end

function LUIMatchCell:HideTipEffect()
    self:HideEffect(self._tipEffectKey)
end

function LUIMatchCell:ShowClearEffect(endFunc)
    local para = {
        resName = "Sanxiaoxiaochu",
        ani = "show",
        isLoop = false
    }
    self:ShowEffect(self._clearEffectKey,self._effectUp,para)

    self:HideShow()

    local timePara = {
        loopcnt = 1,
        interval = 0.4,
        key = "clearKey"..self:GetInstanceId(),
        timescale = true,
        func = endFunc
    }

    self._wnd:TimerStartImpl(timePara)
end



function LUIMatchCell:ShowBombTrigger(endFunc)
    local para = {
        resName = self._resPara.resName,
        ani = self._resPara.triggerAni,
        isLoop = false,
        aniEndCall = function(ani)
            if ani == self._resPara.triggerAni then
                if endFunc then
                    endFunc()
                end
            end
        end
    }
    CS.ShowObject(self._spineRoot,true)
    self:ShowEffect(self._iconEffectKey,self._spineRoot,para)

    local effectPara =
    {
        trans = self._effectUp,
        effName = "fx_ui_sanxiao_zhadan_shiyong",
        effKey = self._bombUseEffKey,
    }
    self._wnd:CreateWndEffectImpl(effectPara)
end



function LUIMatchCell:ShowStarTrigger(bulletTarList,endFunc,reachCall)
    self._bulletPlayEndCall = endFunc
    self._bulletReachCall = reachCall
    local para = {
        resName = self._resPara.resName,
        ani = self._resPara.triggerAni,
        isLoop = false,
    }
    CS.ShowObject(self._spineRoot,true)
    self:ShowEffect(self._iconEffectKey,self._spineRoot,para)

    self._waitPlayMap = {}

    if #bulletTarList == 0 then

        local para = {
            key = self:GetInstanceId().."bulletEnd",
            loopcnt = 1,
            interval = 0,
            func = self._bulletPlayEndCall,
        }

        self._wnd:TimerStartImpl(para)
    else
        for k,v in ipairs(bulletTarList) do
            local effectKey = self:GetInstanceId().."bullet"..k
            local effPara = {
                trans = self._effectUp,
                effName = self._resPara.bulletRes,
                effKey = effectKey,
                endFunc = function(dpEff)
                    self:OnBulletLoaded(dpEff,v,effectKey)
                end
            }

            self._waitPlayMap[effectKey] = true

            self._wnd:CreateWndEffectImpl(effPara)
        end
    end




end

---@param dpEff LDisplayEffect
function LUIMatchCell:OnBulletLoaded(dpEff,tarPos,effectKey)
    local dpTrans = dpEff:GetDisplayTrans()
    dpTrans.position = self.tran.position
    local comp = dpTrans:GetComponent(typeofBtObjectView)
    if not comp then
        comp = dpTrans.gameObject:AddComponent(typeofBtObjectView)
    end
    local dis = Vector3.Distance(tarPos,dpTrans.position)
    local flyTime = dis/1
    comp:EnableAngle(true)
    comp.isPosWorld = true
    comp:StartMove(tarPos,flyTime,0)

    local para = {
        loopcnt = 1,
        interval = flyTime,
        key = effectKey,
        timescale = true,
        func = function()
            self:OnBulletReach(effectKey,tarPos)
        end
    }

    self._wnd:TimerStartImpl(para)
end

function LUIMatchCell:OnBulletReach(effectKey,tarPos)
    self._wnd:DestroyWndEffectByKey(effectKey)
    local effPara = {
        trans = self._effectUp,
        effName = "fx_ui_sanxiao_bullet_hit",
        effKey = effectKey,
        endFunc = function(dpEff)
            self:OnHitEffectLoaded(effectKey,dpEff,tarPos)
            if self._bulletReachCall then
                self._bulletReachCall()
            end

            printInfoN("hit effect loaded")
        end
    }
    self._wnd:CreateWndEffectImpl(effPara)
end

function LUIMatchCell:HideShow()
    CS.ShowObject(self._iconTran,false)
end

function LUIMatchCell:OnHitEffectLoaded(effectKey,dpEff,tarPos)
    local dpTrans = dpEff:GetDisplayTrans()
    dpTrans.position = tarPos
    local para = {
        loopcnt = 1,
        interval = 1,
        key = effectKey,
        timescale = true,
        func = function()
            self:OnBulletPlayEnd(effectKey)

            printInfoN("OnBulletPlayEnd")

        end
    }

    self._wnd:TimerStartImpl(para)

end

function LUIMatchCell:OnBulletPlayEnd(effectKey)
    self._wnd:DestroyWndEffectByKey(effectKey)
    self._waitPlayMap[effectKey] = nil
    if table.keysize(self._waitPlayMap) == 0 then
        if self._bulletPlayEndCall then
            self._bulletPlayEndCall()
        end
    end
end

function LUIMatchCell:ShowItemCreateEff()
    local effPara = {
        trans = self._effectUp,
        effName = "fx_ui_sanxiao_shengcheng",
        effKey = self._itemCreateEffKey,
    }
    self._wnd:CreateWndEffectImpl(effPara)

    local timePara = {
        interval = 1,
        loopcnt = 1,
        key = "delayShowItem"..self:GetInstanceId(),
        timescale = true,
        func= function()
            CS.ShowObject(self._spineRoot,true)
        end
    }

    self._wnd:TimerStartImpl(timePara)
end

function LUIMatchCell:OnRecycle()
    self._wnd:DestroyWndSpineByKey(self._iconEffectKey)
    self._wnd:DestroyWndSpineByKey(self._clearEffectKey)
    self._wnd:DestroyWndSpineByKey(self._tipEffectKey)
    self._wnd:DestroyWndEffectByKey(self._bombUseEffKey)
    self._wnd:DestroyWndEffectByKey(self._itemCreateEffKey)
end


return LUIMatchCell