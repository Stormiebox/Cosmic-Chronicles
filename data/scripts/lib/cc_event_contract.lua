local NewsSchema = include("cosmicvaultnews_schema")

local ChronicleEventContract = {}

local function key(eventId, suffix)
    if type(eventId) ~= "string" or eventId == "" then return nil, "invalid_event_id" end
    local hash, hashError = NewsSchema.StableHash(eventId)
    if not hash then return nil, hashError end
    return "cc_event_v2_" .. hash .. "_" .. suffix, nil
end

function ChronicleEventContract.Begin(eventId, eventType, expectedCount)
    if type(eventType) ~= "string" or eventType == ""
            or type(expectedCount) ~= "number" or expectedCount < 1
            or expectedCount % 1 ~= 0 then return nil, "invalid_arguments" end
    local statusKey, keyError = key(eventId, "status")
    if not statusKey then return nil, keyError end
    local sector = Sector()
    sector:setValue(statusKey, "materializing")
    sector:setValue(assert(key(eventId, "type")), eventType)
    sector:setValue(assert(key(eventId, "expected")), expectedCount)
    sector:setValue(assert(key(eventId, "actual")), 0)
    sector:setValue(assert(key(eventId, "error")), nil)
    return true, nil
end

function ChronicleEventContract.Tag(entity, eventId, eventType)
    if not valid(entity) then return nil, "invalid_entity" end
    entity:setValue("cc_event_id", eventId)
    entity:setValue("cc_event_type", eventType)
    return entity:getValue("cc_event_id") == eventId
        and entity:getValue("cc_event_type") == eventType, nil
end

function ChronicleEventContract.Complete(eventId, actualCount)
    if type(actualCount) ~= "number" or actualCount < 1 or actualCount % 1 ~= 0 then
        return nil, "invalid_count"
    end
    local sector = Sector()
    sector:setValue(assert(key(eventId, "actual")), actualCount)
    sector:setValue(assert(key(eventId, "status")), "succeeded")
    return true, nil
end

function ChronicleEventContract.Fail(eventId, errorText)
    local sector = Sector()
    sector:setValue(assert(key(eventId, "error")), tostring(errorText or "spawn_failed"))
    sector:setValue(assert(key(eventId, "status")), "failed")
    return true, nil
end

function ChronicleEventContract.Get(eventId)
    local statusKey, keyError = key(eventId, "status")
    if not statusKey then return nil, keyError end
    local sector = Sector()
    local status = sector:getValue(statusKey)
    if status == nil then return nil, "missing" end
    return {
        eventId = eventId,
        eventType = sector:getValue(assert(key(eventId, "type"))),
        status = status,
        expectedCount = tonumber(sector:getValue(assert(key(eventId, "expected")))) or 0,
        actualCount = tonumber(sector:getValue(assert(key(eventId, "actual")))) or 0,
        lastError = sector:getValue(assert(key(eventId, "error"))),
    }, nil
end

function ChronicleEventContract.Key(eventId, suffix)
    return key(eventId, suffix)
end

return ChronicleEventContract
