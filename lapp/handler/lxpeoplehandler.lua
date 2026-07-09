local LxBaseHandler = require("LApp.handler.LxBaseHandler")
---@class LxPeopleHandler:LxBaseHandler
local LxPeopleHandler = classX("LxPeopleHandler", LxBaseHandler)

function LxPeopleHandler:Initialize()
    LxBaseHandler.Initialize(self)
end

function LxPeopleHandler:Dispose()
    LxBaseHandler.Dispose(self)
end

function LxPeopleHandler:ClearHandler()
    LxBaseHandler.ClearHandler(self)
end

function LxPeopleHandler:InitOk()
end

-- 完成登录后
function LxPeopleHandler:LoginOk()
    -- 拉取玩家详细数据
end

function LxPeopleHandler:InitHandler()
    --- 居民数据变更
    self:AddMsgHandler(LxProtoIds.PeopleAcceptResp, self.OnPeopleAcceptResp, self)
    --- 通知前端居民赠礼可领取
    self:AddMsgHandler(LxProtoIds.PeopleGiftAppearResp, self.OnPeopleGiftAppearResp, self)
    --- 民心奖励领取下发
    self:AddMsgHandler(LxProtoIds.PeopleGiftResp, self.OnPeopleGiftResp, self)
    --- 民心技能数据
    self:AddMsgHandler(LxProtoIds.PeoplePopularSkillResp, self.OnPeoplePopularSkillResp, self)
    --- 通知前端已触发的问答
    self:AddMsgHandler(LxProtoIds.PeopleQuestionAppearResp, self.OnPeopleQuestionAppearResp, self)
    --- 获得问答奖励
    self:AddMsgHandler(LxProtoIds.PeopleFinishQuestionResp, self.OnPeopleFinishQuestionResp, self)
    --- 居民触发通知
    self:AddMsgHandler(LxProtoIds.PeopleStateChangeResp, self.OnPeopleStateChangeResp, self)
end
--- 接纳流民
--- @param refIds table <number, number> v = 流民refId
function LxPeopleHandler:PeopleAcceptReq(refIds)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.PeopleAcceptReq)
    for _, v in ipairs(refIds) do
        table.insert(proto.refId, v)
    end

    SendMessage(LxProtoIds.PeopleAcceptReq, proto)
end
--- 领取民心奖励
--- @param refId number 居民赠礼表refId
function LxPeopleHandler:PeopleGiftReq(refId)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.PeopleGiftReq)
    proto.refId = refId
    SendMessage(LxProtoIds.PeopleGiftReq, proto)
end
--- 使用民心技能
--- @param refId number 技能id
function LxPeopleHandler:PeoplePopularSkillReq(refId)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.PeoplePopularSkillReq)
    proto.refId = refId
    SendMessage(LxProtoIds.PeoplePopularSkillReq, proto)
end
--- 领取居民问答奖励
--- @param refId number 居民问答表refId
--- @param answer number 答案
function LxPeopleHandler:PeopleFinishQuestionReq(refId, answer)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.PeopleFinishQuestionReq)
    proto.refId = refId
    proto.answer = answer
    SendMessage(LxProtoIds.PeopleFinishQuestionReq, proto)
end

function LxPeopleHandler:OnPeopleAcceptResp(pb)
    local peopleM = ModuleCenter.People
    local num = 0
    local refIdList = {}
    local follow = false
    for _, v in ipairs(pb.peopleObj) do
        table.insert(refIdList,v.refId)
        num = num + 1
        local oldPeople = peopleM:GetPeopleObj(v.refId)

        peopleM:SetPeopleObj(v)
        peopleM:ClearHomelessObj(v.refId)
        local newPeople = peopleM:GetPeopleObj(v.refId)
        if(oldPeople == nil)then
            follow = true
            CtrlCenter.City:PeopleRecruitChange(v.refId)
        else
            if(oldPeople.building ~= newPeople.building)then
                follow = false
            end
        end


    end
    FireEvent(EventNames.PEOPLE_INFO_CHANGE)
    if(follow)then
        table.sort(refIdList, function(a,b)
            return a < b
        end)
        CtrlCenter.City:FollowPeople(refIdList[1])
    end

    --for i, v in ipairs(pb.peopleObj) do
    --    if(GameTable.PeopleRef[v.refId] == nil)then
    --        return
    --    end
    --end
    --CtrlCenter.City:NewPeoples(num)
end
function LxPeopleHandler:OnPeopleGiftAppearResp(pb)
    ModuleCenter.People:SetGiftAppear(pb)
    FireEvent(EventNames.PEOPLE_GIFT_APPEAR)
end
function LxPeopleHandler:OnPeopleGiftResp(pb)
    ModuleCenter.People:RemoveGiftAppear()
    ModuleCenter.People:SetNextGiftTime(pb.second)
    local itemData = {}
    local itemType = ThingType.Item
    for _,v in ipairs(pb.rewardInfo.items or {}) do
        local rewardStr = string.format("%d=%d=%d", itemType, v.refId, v.num)
        table.insert(itemData, rewardStr)
    end
    FireEvent(EventNames.PEOPLE_GIFT_APPEAR_REWARD, itemData)
    FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.PeopleReward, pb.rewardInfo)
end
function LxPeopleHandler:OnPeoplePopularSkillResp(pb)
    ModuleCenter.People:SetSkillObj(pb.skill)
    FireEvent(EventNames.PEOPLE_SKILL_CHANGE, pb.skill.refId)
    FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.PeopleReward, pb.rewardInfo)
    CtrlCenter.City:UsePeopleSkill(pb.skill.refId)
end
function LxPeopleHandler:OnPeopleQuestionAppearResp(pb)
    ModuleCenter.People:SetQuestions(pb.questions)
    FireEvent(EventNames.PEOPLE_QUESTION_APPEAR)
end
function LxPeopleHandler:OnPeopleFinishQuestionResp(pb)
    ModuleCenter.People:RemoveQuestion(pb.refId)
    FireEvent(EventNames.PEOPLE_QUESTION_APPEAR, pb.rewardInfo)
end
function LxPeopleHandler:OnPeopleStateChangeResp(pb)
    if(ModuleCenter.Story:IsNewbieRunning())then
        --正在剧情中
        return
    end
    if IsOpenPanel(UiNames.PeopleNoticePop) then

    else
        ShowPanel(UiNames.PeopleNoticePop, {noticeId = pb.noticeId, peopleObj = pb.people})
    end

    local noticeRef = GameTable.PeopleNoticeRef[pb.noticeId]
    if noticeRef.type == PeopleNoticeType.Dead or noticeRef.type == PeopleNoticeType.Escape then
        ModuleCenter.People:ClearPeopleObj(pb.people.refId)
        CtrlCenter.City:DeletePeople(pb.people.refId)
    end
    if(noticeRef.type == PeopleNoticeType.Sick)then
        CtrlCenter.City:PeopleGotoHospital()
    end
    if(noticeRef.type == PeopleNoticeType.Recover)then
        CtrlCenter.City:PeopleOutHospital(pb.people.refId)
        --有人从医院出来的时候再检查一下有没有生病的居民，如果有，就去医院
        CtrlCenter.City:PeopleGotoHospital()
    end
    FireEvent(EventNames.PEOPLE_STATE_CHANGE, pb.noticeId)
    FireEvent(EventNames.PEOPLE_INFO_CHANGE)
end
return LxPeopleHandler