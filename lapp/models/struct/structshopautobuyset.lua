---
--- Created by BY.
--- DateTime: 2023/10/4 11:02:37
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructShopAutoBuySet
local StructShopAutoBuySet = LxClass("StructShopAutoBuySet", nil)
function StructShopAutoBuySet:StructShopAutoBuySet()

end

function StructShopAutoBuySet:CreateByPb(pb)
    --token_variant_auto_export
	self.shopId=pb.shopId
	local goodsId=pb.goodsId
	local list = {}
	for i, v in ipairs(goodsId) do
		table.insert(list,v)
	end
	self.goodsId = list
	self.open=pb.open
--token_variant_auto_export
end

function StructShopAutoBuySet:CreateByInfo(info)
	self.shopId = info.shopId
	for i, v in ipairs(info.goodsId) do
		self.goodsId:append(v)
	end
	self.open = info.open
end
return StructShopAutoBuySet