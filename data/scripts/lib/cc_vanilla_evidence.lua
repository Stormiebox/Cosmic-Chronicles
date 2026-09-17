local VanillaEvidence = {}

VanillaEvidence.Milestones = {
    {milestoneId = "swoks", scriptPath = "data/scripts/player/story/swoksmission.lua",
        artifactNumber = 3, laterStoryAdvance = 2, credits = 150000, reputation = 10000},
    {milestoneId = "hermit", scriptPath = "data/scripts/player/story/hermitmission.lua",
        laterStoryAdvance = 3, credits = 75000, reputation = 5000},
    {milestoneId = "equipment_merchant", scriptPath = "data/scripts/player/story/buymission.lua",
        artifactNumber = 4, laterStoryAdvance = 4, credits = 50000, reputation = 5000},
    {milestoneId = "bottan", scriptPath = "data/scripts/player/story/bottanmission.lua",
        artifactNumber = 8, playerValue = "last_killed_bottan", laterStoryAdvance = 4,
        credits = 150000, reputation = 10000},
    {milestoneId = "ai", scriptPath = "data/scripts/player/story/aimission.lua",
        artifactNumber = 6, laterStoryAdvance = 4, credits = 200000, reputation = 15000},
    {milestoneId = "research", scriptPath = "data/scripts/player/story/researchmission.lua",
        artifactNumber = 2, laterStoryAdvance = 4, credits = 50000, reputation = 5000},
    {milestoneId = "scientist", scriptPath = "data/scripts/player/story/scientistmission.lua",
        artifactNumber = 7, playerValue = "last_killed_scientist", laterStoryAdvance = 4,
        credits = 400000, reputation = 25000},
    {milestoneId = "exodus", scriptPath = "data/scripts/player/story/exodusmission.lua",
        artifactNumber = 1, laterStoryAdvance = 4, credits = 100000, reputation = 5000},
    {milestoneId = "the_four", scriptPath = "data/scripts/player/story/the4mission.lua",
        artifactNumber = 5, playerValue = "last_killed_the4", laterStoryAdvance = 4,
        credits = 300000, reputation = 20000},
    {milestoneId = "cross_barrier", scriptPath = "data/scripts/player/story/crossthebarriermission.lua",
        laterStoryAdvance = 5, credits = 500000, reputation = 30000},
    {milestoneId = "guardian", scriptPath = "data/scripts/player/story/killguardianmission.lua",
        playerValue = "wormhole_guardian_destroyed", storyCompleted = true,
        credits = 1000000, reputation = 50000},
    {milestoneId = "collect_xsotan_technology",
        scriptPath = "data/scripts/player/story/collectxsotantechnology.lua",
        laterStoryAdvance = 4, credits = 100000, reputation = 10000},
    {milestoneId = "operation_exodus", scriptPath = "data/scripts/player/story/exodus.lua",
        artifactNumber = 1, laterStoryAdvance = 4, credits = 100000, reputation = 5000},
    {milestoneId = "artifact_delivery", scriptPath = "data/scripts/player/story/artifactdelivery.lua",
        playerValue = "last_killed_the4", credits = 50000, reputation = 5000},
    {milestoneId = "smuggler_retaliation",
        scriptPath = "data/scripts/player/story/smugglerretaliation.lua",
        playerValue = "last_killed_bottan", credits = 200000, reputation = 15000},
    {milestoneId = "organized_allies",
        scriptPath = "data/scripts/player/story/organizedallies.lua",
        laterStoryAdvance = 5, credits = 0, reputation = 0},
}

local byPath = {}
for _, milestone in ipairs(VanillaEvidence.Milestones) do
    byPath[milestone.scriptPath] = milestone
    byPath[milestone.scriptPath:gsub("^data/scripts/", "")] = milestone
end

function VanillaEvidence.GetByScriptPath(scriptPath)
    if type(scriptPath) ~= "string" then return nil end
    return byPath[scriptPath]
end

local function foundArtifacts(player)
    local loaded, missionUtility = pcall(include, "missionutility")
    if not loaded or not missionUtility or not missionUtility.detectFoundArtifacts then return {} end
    local ok, artifacts = pcall(missionUtility.detectFoundArtifacts, player)
    return ok and type(artifacts) == "table" and artifacts or {}
end

function VanillaEvidence.Evaluate(player, milestone, artifacts)
    if not player or type(milestone) ~= "table" then return nil, "invalid_arguments" end
    local evidence = {}
    local confirmed = false
    local storyAdvance = tonumber(player:getValue("story_advance")) or 0
    if milestone.playerValue and player:getValue(milestone.playerValue) then
        evidence.playerValue = milestone.playerValue
        confirmed = true
    end
    if milestone.storyCompleted and player:getValue("story_completed") then
        evidence.storyCompleted = true
        confirmed = true
    end
    if milestone.laterStoryAdvance and storyAdvance >= milestone.laterStoryAdvance then
        evidence.storyAdvance = storyAdvance
        confirmed = true
    end
    artifacts = artifacts or foundArtifacts(player)
    if milestone.artifactNumber and artifacts[milestone.artifactNumber] then
        evidence.artifactNumber = milestone.artifactNumber
        confirmed = true
    end
    return {confirmed = confirmed, evidence = evidence}, nil
end

function VanillaEvidence.CaptureBaseline(player)
    local baseline = {}
    local artifacts = foundArtifacts(player)
    for _, milestone in ipairs(VanillaEvidence.Milestones) do
        local result = VanillaEvidence.Evaluate(player, milestone, artifacts)
        if result and result.confirmed then
            baseline[milestone.milestoneId] = {
                state = "legacy_outcome_unknown",
                evidence = result.evidence,
            }
        end
    end
    return baseline
end

function VanillaEvidence.Validate()
    local seenIds, seenPaths = {}, {}
    for index, milestone in ipairs(VanillaEvidence.Milestones) do
        if type(milestone.milestoneId) ~= "string" or milestone.milestoneId == ""
                or seenIds[milestone.milestoneId]
                or type(milestone.scriptPath) ~= "string" or seenPaths[milestone.scriptPath]
                or type(milestone.credits) ~= "number" or milestone.credits < 0
                or type(milestone.reputation) ~= "number" or milestone.reputation < 0 then
            return nil, "invalid_milestone_" .. tostring(index)
        end
        seenIds[milestone.milestoneId] = true
        seenPaths[milestone.scriptPath] = true
    end
    return true, nil
end

return VanillaEvidence
