-- namespace PirateAttack

if onClient() then

function PirateAttack.onPiratesGenerated(id)
    if getLanguage() == "en" then
        local lines = {
            -- Vanilla Lines
            "Eject all your cargo and we will spare you - hahaha just kidding. You're as good as dead.",
            "We'll give you fired rounds for your cargo. Sounds like an equivalent exchange to me.",
            "Kill 'em all, let their god sort them out!",
            "Maybe next time you'll pay our generous fee for protection.",
            "Don't save any ammo! The salvage will pay for it.",
            "Surrender or be destroyed!",
            "Is this really worth our time? It doesn't matter, we'd be idiots to pass up on free loot.",
            "Hah, they won't stand a chance.",
            "Do you think this is a game?",
            
            -- Cosmic Series Custom Lore & Easter Eggs
            "Hand over the overhauled tech, or we'll turn your ship into space dust!",
            "Did Stormbox send you? Doesn't matter, you're dead either way!",
            "The Ascendants won't save you out here!",
            "Look at all that shiny armor. I can't wait to melt it down!",
            "We heard there's a bounty on your head. We're here to collect!",
            "Your shields look weak. Let's test them with a barrage of plasma!",
            "The Eclipse is coming, but we'll end your misery first!",
            "Another merchant stumbling into our trap. How predictable.",
            "Drop your coaxials and we might let your escape pods go. Maybe.",
            "I'm going to enjoy picking through your wreckage for spare parts.",
            "The war heat is rising, and so are my profits!",
            "You can't outrun our upgraded hyperdrives!",
            "Prepare to be boarded! Oh wait, I'd rather just blow you up.",
            "This sector belongs to us now! Pay the toll with your life!",
            "Your ship's design is obsolete. Let me help you dismantle it.",
            "We don't negotiate with prey.",
            "I need a new reactor, and yours looks like a perfect fit.",
            "The Syndicate sends their regards. And a volley of torpedoes!",
            "I hope you enjoyed the Cosmic Symphony, because this is your final movement!",
            "We're going to turn your dreadnought into a scrapyard!",
            "Your distress signal is being jammed. Scream all you want, no one is coming.",
            "I smell fear. Or maybe that's just your plasma vents leaking.",
            "Another sacrifice for the pirate lords!",
            "You picked the wrong day to fly through this sector!",
            "I don't care if you're a diplomat or a scavenger. Out here, everyone bleeds the same.",
            "The dark monoliths hunger for energy, and we hunger for your credits!",
            "You're trespassing in our hunting grounds. Prepare to be hunted.",
            "I heard they updated the combat mechanics. Let's see how long you last!",
            "We've been tracking your warp signature across three sectors. It ends here.",
            "Surrender your vessel and we might just eject you into the void instead of vaporizing you.",
            "I've been waiting for a good fight all cycle. Don't disappoint me!",
            "Don't bother powering up your weapons. This will be over before you can lock on.",
            "You're carrying illegal contraband. The penalty is death, and we are the executioners.",
            "Your shields are already failing! Cut the reactor and we'll make it quick!",
            "We've got you boxed in. Dump the cargo or we vent your atmosphere!",
            "Target their thrusters first! I want this one disabled, not vaporized!",
            "Nobody jumps into our territory without paying the toll. The toll is everything you own.",
            "I hear the local militia is light-years away. You're entirely on your own.",
            "You think that hull armor will save you? My cannons will rip it to shreds!",
            "Don't bother sending a distress signal. We jammed those frequencies an hour ago.",
            "A fat transport ship wandering alone? Must be my lucky cycle.",
            "Strip their turrets, board the vessel, and sell the crew to the syndicate!",
            "Let's crack this ship open like a geode and see what shiny rocks are inside.",
            "Your ship is a disgrace to engineering. Let me put it out of its misery.",
            "You're outnumbered and outgunned. Make this easy on both of us.",
            "We're the true masters of the Cosmic War!",
            "Did you really think you could sneak past our sensors?",
            "I'm going to mount your captain's chair in my quarters!",
            "Your crew will make excellent slaves in the outer rim.",
            "We don't need the Chronicles to remember us. We write our own history!",
            "The only good merchant is a dead merchant.",
            "I'm going to blow a hole in your hull so big, I could fly a cruiser through it!",
            "Your cargo manifests are ours now.",
            "This ambush was brought to you by the finest pirates in the galaxy!",
            "Don't try to bribe us. We want everything you have, including your lives.",
            "The faction militaries are too weak to stop us. What chance do you have?",
            "I'm going to enjoy watching your ship tear itself apart.",
            "We're the apex predators of the cosmos.",
            "Your journey ends here, traveler.",
            "May the void have mercy on your soul, because we won't.",
        }

        local pirate = Entity(id)
        if valid(pirate) then
            displaySpeechBubble(pirate, randomEntry(lines))
        end
    end
end

end
