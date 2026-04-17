import Foundation

// Pre-authored walking tours bundled with the app.
// Audio files are synthesized via ElevenLabs and placed in
// WalkingTours/{tourId}/{waypointId}/content.m4a (and nav.m4a).

enum AuthoredWalkingTours {

    static var all: [WalkingTour] {
        [huntingtonBradmoor, mccrillis, rockCreekTrails]
    }

    // MARK: - Tour 1: Huntington Terrace & Bradmoor

    static let huntingtonBradmoor = WalkingTour(
        id: "huntington-bradmoor",
        title: "Postwar Dreams on Quiet Streets",
        creatorName: "Aly Mahmoud",
        creatorIsLocal: true,
        description: "A neighborhood history walk through two mid-century Bethesda subdivisions built on the promise of the American Dream.",
        tags: ["history", "neighborhood", "architecture"],
        mode: .walking,
        waypoints: [
            WalkingWaypoint(
                id: "hb-01-starting-point",
                order: 1,
                lat: 38.99340,
                lng: -77.11880,
                title: "Where Farmland Became Neighborhoods",
                description: "The intersection of Huntington Parkway and Bradmoor Drive",
                triggerRadiusMeters: 30,
                contentAudioFile: "content.m4a",
                navAudioFile: nil,
                narrationText: """
                You're standing at the corner of Huntington Parkway and Bradmoor Drive, in the heart of what was, until about 1948, farmland and small estates. Everything you see around you — every house, every sidewalk, every mature oak — exists because of a specific moment in American history.

                After World War Two, millions of GIs came home to a country that had almost no housing for them. Congress passed the GI Bill, which guaranteed home loans with zero down payment. The FHA loosened lending standards. And developers, sensing the biggest market opportunity of the century, started buying up agricultural land on the edges of cities and turning it into subdivisions.

                Montgomery County was ground zero for this transformation in the Washington area. Between 1945 and 1960, the county's population more than doubled. The farmland where you're standing was carved into quarter-acre lots, and modest three-bedroom homes went up almost overnight.

                These weren't luxury homes. They were starter houses — affordable, practical, and built to a pattern. But they represented something enormous: the first generation of mass homeownership in American history. Walk with me and I'll show you what that looked like, and what it's become.
                """,
                navInstructionText: nil
            ),
            WalkingWaypoint(
                id: "hb-02-colonial-revival",
                order: 2,
                lat: 38.99410,
                lng: -77.11320,
                title: "The Colonial Revival Pattern Book",
                description: "Huntington Terrace's original homes",
                triggerRadiusMeters: 30,
                contentAudioFile: "content.m4a",
                navAudioFile: "nav.m4a",
                narrationText: """
                Look at the houses on this block. The ones that haven't been heavily renovated show you exactly what postwar homebuilders thought Americans wanted: Colonial Revival and Cape Cod styles. Brick fronts. Shuttered windows. A centered front door, sometimes with a little portico. These designs reached back to an imagined colonial past — a visual language that said stability, tradition, permanence.

                The irony is that there was nothing traditional about what was happening here. These neighborhoods were a radical experiment in social engineering. The FHA didn't just guarantee loans — it published design standards that builders had to follow. Lot sizes, setbacks, street widths, even the relationship between the house and the garage were specified in federal manuals.

                If you look carefully, you can spot the original homes versus the renovated ones. The originals are modest — maybe 1,200 square feet, single-story or a story and a half with dormers. They sit low on their lots. The renovations and teardown rebuilds are dramatically larger, often pushing the setback limits. That contrast tells the story of how Bethesda changed from an affordable suburb to one of the most expensive zip codes in America.
                """,
                navInstructionText: "Head east along Huntington Terrace. You'll walk past several original Cape Cod homes. The street curves gently — keep following it for about two blocks."
            ),
            WalkingWaypoint(
                id: "hb-03-bradmoor",
                order: 3,
                lat: 38.99720,
                lng: -77.11940,
                title: "Bradmoor: Selling the English Countryside",
                description: "Bradmoor Drive's ranch homes and split-levels",
                triggerRadiusMeters: 30,
                contentAudioFile: "content.m4a",
                navAudioFile: "nav.m4a",
                narrationText: """
                Welcome to Bradmoor Drive. Notice how the name sounds — Bradmoor. It's meant to evoke the English countryside, rolling moors, something genteel and landed. Mid-century subdivision developers were masters of aspirational naming. The lots were a quarter acre, not a country estate, but the name did its work.

                The homes here tend to be slightly later than Huntington Terrace — more 1950s than late '40s — and you can see it in the architecture. Instead of Colonial Revival, you get ranch-style ramblers and split-levels. These were the cutting-edge house designs of the Eisenhower era. The rambler said "modern, open, California-influenced." The split-level said "we solved the problem of fitting more house on a small lot."

                Both styles shared a new relationship with the car. Look at the garages and driveways. In Huntington Terrace, garages were often detached, almost an afterthought. Here on Bradmoor, the garage is integrated into the house — sometimes it's the most prominent feature of the facade. The car had gone from luxury to necessity in a single decade, and the house adapted.
                """,
                navInstructionText: "Turn around and head north on Bradmoor Drive. Walk about three blocks, past the bend in the road."
            ),
            WalkingWaypoint(
                id: "hb-04-burning-tree",
                order: 4,
                lat: 38.99760,
                lng: -77.12100,
                title: "In the Shadow of Burning Tree",
                description: "The exclusive club that shaped the neighborhood",
                triggerRadiusMeters: 30,
                contentAudioFile: "content.m4a",
                navAudioFile: "nav.m4a",
                narrationText: """
                You can't see it from here, but less than two miles west of us is the Burning Tree Club — one of the most exclusive private golf clubs in America. It's been men-only since it opened in 1922, and its membership has included presidents Eisenhower, Nixon, Ford, and George H.W. Bush. The name comes from a Native American practice of setting fire to hollow trees to smoke out game.

                Burning Tree matters to this neighborhood's story because exclusive institutions like it defined the social geography of Bethesda. When these subdivisions were built in the late '40s and '50s, they existed in a carefully layered hierarchy. The country club set lived on large lots closer to the clubs. The new middle-class subdivisions — where you're walking — were nearby enough to share the prestige of the area code, but modest enough that a returning GI on an FHA loan could afford them.

                That layering still shapes property values today. A house on Bradmoor Drive might sell for one and a half million dollars. A house on one of the estates near Burning Tree could be ten or fifteen million. Same zip code. Same schools. Completely different economic universe.
                """,
                navInstructionText: "Continue along the street. Look up — we're about to enter the canopy."
            ),
            WalkingWaypoint(
                id: "hb-05-canopy",
                order: 5,
                lat: 38.99270,
                lng: -77.11450,
                title: "The Accidental Urban Forest",
                description: "Seventy years of tree growth",
                triggerRadiusMeters: 30,
                contentAudioFile: "content.m4a",
                navAudioFile: "nav.m4a",
                narrationText: """
                Stop for a moment and look up. The tree canopy over this street is extraordinary — a cathedral ceiling of oak, tulip poplar, and beech that arcs sixty or seventy feet above the pavement. These trees are the same age as the houses, more or less. When the developers cleared the farmland and built the subdivision, they planted saplings along the streets and in the yards. Seventy-five years later, those saplings are giants.

                Montgomery County deserves credit for protecting them. The county's forest conservation law and tree protection ordinances are among the strongest in the country. You can't cut down a significant tree on your property without a permit, and if you do cut one, you often have to plant replacements or pay into a tree fund.

                The result is that neighborhoods like this one have become accidental urban forests. The canopy provides measurable benefits — cooler summer temperatures, stormwater absorption, carbon sequestration, habitat for birds and pollinators. A street with a mature canopy can be ten degrees cooler than a street without one.

                But there's a tension. Every time a modest postwar home is torn down and replaced with a larger house, the construction often damages or removes mature trees. The new house might plant new ones, but it takes fifty years to grow a canopy tree. What you're walking under right now is irreplaceable on any human timescale.
                """,
                navInstructionText: "Head south toward where the neighborhood meets the newer construction. You'll notice the houses start to change."
            ),
            WalkingWaypoint(
                id: "hb-06-evolution",
                order: 6,
                lat: 38.99180,
                lng: -77.11100,
                title: "Teardown Nation",
                description: "Where original homes meet their replacements",
                triggerRadiusMeters: 30,
                contentAudioFile: "content.m4a",
                navAudioFile: "nav.m4a",
                narrationText: """
                Look around this block and you can see Bethesda's transformation in a single glance. On one side, an original postwar home — maybe 1,400 square feet, brick, low to the ground, the kind of house a young family with a GI Bill mortgage could afford in 1952. On the other side, its replacement — 5,000 square feet, towering over the lot, every inch of the buildable envelope filled.

                This is the teardown cycle, and it's been reshaping inner suburbs like Bethesda for two decades. The economics are simple: in a neighborhood where the land alone is worth a million dollars, a modest 1950s house is essentially worthless as a structure. A developer buys it, demolishes it, and builds the largest possible new home. The new house sells for two or three million.

                What's lost? The human scale of the original neighborhoods. The architectural modesty that made them feel like real places rather than displays of wealth. And often the trees — mature canopy that took decades to grow.

                What's gained? Modern insulation, plumbing, and electrical systems. Open floor plans that work for how families actually live now. And undeniably more space.

                Whether that trade is worth it depends on what you think neighborhoods are for. Are they investments to be maximized? Or are they communities with a character worth preserving? That's the question Bethesda is still answering, one teardown at a time.

                Thank you for walking with me. I hope you'll look at these quiet streets a little differently now.
                """,
                navInstructionText: nil
            ),
        ],
        createdAt: Date(timeIntervalSince1970: 1744761600), // 2025-04-16
        updatedAt: Date(timeIntervalSince1970: 1744761600),
        isAuthored: true
    )

    // MARK: - Tour 2: McCrillis Gardens

    static let mccrillis = WalkingTour(
        id: "mccrillis-gardens",
        title: "A Garden for All Seasons",
        creatorName: "Aly Mahmoud",
        creatorIsLocal: true,
        description: "A botanical walk through one of Bethesda's hidden gems — a five-acre shade garden designed to be beautiful twelve months a year.",
        tags: ["botanical", "garden", "nature"],
        mode: .walking,
        waypoints: [
            WalkingWaypoint(
                id: "mc-01-entrance",
                order: 1,
                lat: 39.00771,
                lng: -77.13975,
                title: "The Gift of a Garden",
                description: "McCrillis Gardens entrance",
                triggerRadiusMeters: 25,
                contentAudioFile: "content.m4a",
                navAudioFile: nil,
                narrationText: """
                Welcome to McCrillis Gardens, five acres of shade garden tucked into a residential neighborhood in Bethesda. Most people who live within a mile of here don't know it exists. That's part of its charm.

                This garden was the private passion of William and Virginia McCrillis, who bought the property in the 1940s and spent decades planting it. When William retired from the Department of the Interior in the 1970s, he donated the garden to the Maryland-National Capital Park and Planning Commission — the same agency that manages the county park system.

                What makes McCrillis special is that it's a shade garden. Most gardens you visit are designed around sun-loving plants — roses, perennials, vegetables. McCrillis is designed around the canopy. The mature trees overhead — oaks, tulip poplars, beeches — create a dappled woodland environment, and everything planted beneath them is chosen to thrive in partial shade.

                This means the garden speaks a different visual language than what you might be used to. Instead of big, showy blooms, you'll see subtle variations in leaf texture, shape, and color. Shade gardening is an art of nuance. Let me show you what I mean.
                """,
                navInstructionText: nil
            ),
            WalkingWaypoint(
                id: "mc-02-azaleas",
                order: 2,
                lat: 39.00790,
                lng: -77.14010,
                title: "The Azalea Collection",
                description: "McCrillis's signature plantings",
                triggerRadiusMeters: 20,
                contentAudioFile: "content.m4a",
                navAudioFile: "nav.m4a",
                narrationText: """
                McCrillis Gardens is renowned for its azalea collection — hundreds of plants representing dozens of varieties, both native and hybrid. In late April and early May, this area erupts in color: whites, pinks, corals, magentas, and a deep red that's almost purple.

                But I want to tell you something most visitors miss. There are two fundamentally different kinds of azaleas here. The native azaleas — species like the Pinxterbloom and the Flame Azalea — are deciduous. They lose their leaves in winter and tend to have looser, more open flowers with long stamens that stick out like whiskers. They evolved to attract butterflies and hummingbirds.

                The evergreen azaleas — the ones with those dense, compact flower clusters — are mostly Asian hybrids, descendants of plants collected in Japan and China. They keep their leaves year-round, which makes them useful as structural plants in the garden even in winter.

                William McCrillis collected both kinds obsessively. The Piedmont soil here — slightly acidic, well-drained but moisture-retentive — is perfect for azaleas. The same geology that made this area difficult farmland makes it ideal azalea territory. Sometimes the land knows what it wants to grow.
                """,
                navInstructionText: "Follow the path deeper into the garden, heading away from the entrance. The canopy will get thicker."
            ),
            WalkingWaypoint(
                id: "mc-03-specimen-trees",
                order: 3,
                lat: 39.00780,
                lng: -77.13860,
                title: "Reading the Giants",
                description: "Old-growth canopy trees",
                triggerRadiusMeters: 20,
                contentAudioFile: "content.m4a",
                navAudioFile: "nav.m4a",
                narrationText: """
                Look up. The large trees overhead aren't part of the McCrillis garden — they predate it by decades, maybe a century. These are remnant canopy trees from the forest that covered this part of Montgomery County before it was cleared for agriculture, and then for suburbs.

                You can roughly estimate a tree's age from its trunk diameter. For an oak in this climate, figure about four to five years per inch of diameter at chest height. That big white oak over there — if its trunk is three feet across, it could be a hundred and fifty years old. It was here before the McCrillis family. It was here before Bethesda was a suburb. It may have been here during the Civil War.

                A shade garden like McCrillis depends on these trees. They create the conditions that make everything else possible: the dappled light, the cooler temperatures, the moisture retention, the leaf litter that feeds the soil. If you removed the canopy, the shade garden would die within a few seasons. The big trees aren't decoration — they're infrastructure.

                This is why Montgomery County's tree protection ordinances matter so much. Each one of these old trees is an ecological engine that takes a century to build and an afternoon to destroy.
                """,
                navInstructionText: "Follow the path to the left, curving toward the western side of the garden. You'll pass beneath some of the largest canopy trees."
            ),
            WalkingWaypoint(
                id: "mc-04-shade-perennials",
                order: 4,
                lat: 39.00880,
                lng: -77.14160,
                title: "The Art of Leaves",
                description: "Shade perennials — hostas, ferns, and hellebores",
                triggerRadiusMeters: 20,
                contentAudioFile: "content.m4a",
                navAudioFile: "nav.m4a",
                narrationText: """
                This section is where shade gardening reveals itself as an art form. Look at the ground layer around you: hostas with leaves the size of dinner plates next to delicate maidenhair ferns. Bold-textured rodgersias beside lacy astilbe. Every planting is a composition in leaf shape, texture, and shade of green.

                Sun gardens are about flowers. Shade gardens are about foliage. And once you train your eye to see it, foliage is endlessly interesting. Count the shades of green around you right now — I'll bet you can find at least a dozen, from the blue-green of a hosta to the bright chartreuse of a Japanese forest grass to the deep emerald of a Christmas fern.

                The hellebores are particularly worth noticing. Those low plants with the leathery evergreen leaves are sometimes called Lenten roses because they bloom in late winter — February and March — when almost nothing else is flowering. Their blooms nod downward, so you have to lift them to see the face of the flower. It's a plant that rewards attention.

                That's the philosophy of this entire garden, really. It rewards attention. It's not trying to impress you from a distance. It's asking you to slow down, look closely, and notice the details.
                """,
                navInstructionText: "Turn back toward the south. Head downhill — you may hear water. The path slopes gently toward the lowest part of the garden."
            ),
            WalkingWaypoint(
                id: "mc-05-stream",
                order: 5,
                lat: 39.00700,
                lng: -77.14050,
                title: "Where Water Gathers",
                description: "The stream garden and moisture-loving plants",
                triggerRadiusMeters: 20,
                contentAudioFile: "content.m4a",
                navAudioFile: "nav.m4a",
                narrationText: """
                Every garden has a low point where water naturally collects, and in a well-designed garden, that's not a problem — it's an opportunity. This is McCrillis's stream garden, where moisture-loving plants thrive in the damp soil near the drainage channel.

                Japanese primroses, astilbe, ligularia, and native cardinal flower all grow here, taking advantage of soil that stays consistently moist. The ferns are especially lush in this microclimate — the combination of shade, moisture, and rich organic soil creates conditions that ferns have loved for four hundred million years. They were here before flowering plants existed.

                Water features do something else that's important in a garden: they change the soundscape. Even a small trickle of water creates white noise that masks road traffic, neighbors, airplanes. It's a psychological boundary as much as a physical one. Step into the sound of moving water and your nervous system downshifts. Garden designers have known this for thousands of years — the Persian word for an enclosed garden, "pairidaeza," is the root of our word "paradise."

                The McCrillis garden doesn't have a dramatic fountain or waterfall. It has what the land provides: a low spot where rainwater collects and moves. That restraint is part of what makes it feel authentic rather than constructed.
                """,
                navInstructionText: "Head back uphill toward the entrance. We'll end near where we started, with a different way of seeing the garden."
            ),
            WalkingWaypoint(
                id: "mc-06-seasonal",
                order: 6,
                lat: 39.00750,
                lng: -77.13900,
                title: "Designing for Twelve Months",
                description: "Why the best gardens never sleep",
                triggerRadiusMeters: 25,
                contentAudioFile: "content.m4a",
                navAudioFile: "nav.m4a",
                narrationText: """
                Before you leave, I want to share the most important idea in garden design — the one that separates a good garden from a great one. A great garden is designed for twelve months, not three.

                Most home gardens peak in June and look dead by November. McCrillis is different. Come here in February and the hellebores are blooming and the witch hazels are sending out their strange, spidery flowers. March brings the earliest bulbs — snowdrops and crocuses pushing through last year's leaves. April and May are the azalea season — the famous show. Summer is all about foliage texture and shade. Fall brings the changing canopy — maples and oaks turning gold and scarlet overhead while the evergreen understory stays green below.

                And winter — winter is when you see the bones of the garden. The branch structure of the deciduous trees. The bark of the crape myrtles. The persistent berries of the hollies. The frost on the hellebore leaves. A garden that's beautiful in January is a garden designed by someone who truly understood their craft.

                William McCrillis was that kind of gardener. He wasn't designing for a single spectacular weekend. He was designing for every walk, in every season, for decades. That's a kind of optimism I find deeply moving — the belief that beauty is worth building even if it takes longer than a lifetime to fully arrive.

                Thank you for walking through this garden with me. I hope you'll come back in a different season and see it again with fresh eyes.
                """,
                navInstructionText: nil
            ),
        ],
        createdAt: Date(timeIntervalSince1970: 1744761600),
        updatedAt: Date(timeIntervalSince1970: 1744761600),
        isAuthored: true
    )

    // MARK: - Tour 3: Rock Creek Park Trails

    static let rockCreekTrails = WalkingTour(
        id: "rock-creek-trails",
        title: "Where the City Disappears",
        creatorName: "Aly Mahmoud",
        creatorIsLocal: true,
        description: "A walk along Rock Creek from Boundary Bridge into a forest that makes you forget you're surrounded by a million people. New Deal bridges, fall-zone geology, and an urban wilderness.",
        tags: ["nature", "history", "neighborhood"],
        mode: .walking,
        waypoints: [
            WalkingWaypoint(
                id: "rc-01-boundary-bridge",
                order: 1,
                lat: 38.96698,
                lng: -77.05354,
                title: "Boundary Bridge",
                description: "Where Maryland meets the District — and the pavement meets the wild",
                triggerRadiusMeters: 30,
                contentAudioFile: "content.m4a",
                navAudioFile: nil,
                narrationText: """
                You're standing at Boundary Bridge, and the name is literal — the state line between Maryland and the District of Columbia runs right through here. Step ten feet south and you're in a national park. Step ten feet north and you're in Montgomery County.

                But there's a more dramatic boundary at work. Look south, past the bridge, into the trees. Within about two hundred yards, the suburban world you just drove through — the houses, the strip malls, the traffic — will completely vanish. You'll be in a forest gorge that looks and sounds like the Appalachian foothills. Rock Creek carved this valley over millions of years, cutting through bedrock to create a corridor of wildness that somehow survived the city growing up around it.

                Rock Creek Park was established in 1890 — just the third national park in American history, and the first inside a city. Congress set aside 1,700 acres because they could see what was coming: Washington was booming, and without protection, this creek valley would have been paved over like everything else.

                The bridge you're standing on has its own story. The original Boundary Bridge washed away in the devastating Rock Creek floods of the early 1930s. What you see now was built in 1934 by the Public Works Administration — one of Roosevelt's New Deal programs that put Americans back to work during the Depression. Five footbridges in this park were built by the PWA, and we'll see another one on this walk.

                Let's head south into the trees.
                """,
                navInstructionText: nil
            ),
            WalkingWaypoint(
                id: "rc-02-beach-drive",
                order: 2,
                lat: 38.96430,
                lng: -77.05180,
                title: "Beach Drive: The Road That Became a Trail",
                description: "Where cars used to go, walkers now own the road",
                triggerRadiusMeters: 30,
                contentAudioFile: "content.m4a",
                navAudioFile: "nav.m4a",
                narrationText: """
                You're walking on Beach Drive, and if it feels strange to walk down the middle of a paved road, that's the point. Three sections of Beach Drive in Rock Creek Park are now permanently closed to cars. This stretch is one of them. What was a commuter cut-through for decades is now the widest, smoothest walking and biking path in the District.

                The fight over Beach Drive lasted years. Commuters used it to bypass Connecticut Avenue traffic, turning a park road into a de facto highway. Conservationists argued that a road through the middle of a national park should serve the park, not the commute. During COVID, the road was temporarily closed and people flooded in — runners, families with strollers, cyclists, kids on scooters. The temporary closure became permanent.

                Look at the creek to your left. Rock Creek is a surprisingly serious waterway — it drains seventy-six square miles of Montgomery County and the District. After heavy rains it becomes a torrent, which is why those original bridges washed out in the 1930s. The creek is also an ecological corridor. Fish, birds, deer, foxes, and even the occasional coyote use this valley to move between the suburban parks of Maryland and the Potomac River.

                Notice the rock outcrops along the creek banks. We're approaching something geologically significant — a place where the earth changes underneath you. More on that at the next stop.
                """,
                navInstructionText: "Continue south on Beach Drive. The road curves gently with the creek. You'll walk about a quarter mile to the next stop."
            ),
            WalkingWaypoint(
                id: "rc-03-fall-zone",
                order: 3,
                lat: 38.96170,
                lng: -77.05020,
                title: "The Fall Zone",
                description: "Standing on the seam between two geologic worlds",
                triggerRadiusMeters: 30,
                contentAudioFile: "content.m4a",
                navAudioFile: "nav.m4a",
                narrationText: """
                Right about here, you're standing on one of the most important geologic boundaries on the East Coast. It's called the fall zone — or the fall line — and it's where the hard, ancient rock of the Piedmont Plateau meets the soft, young sediment of the Atlantic Coastal Plain.

                Look at the creek bed. Upstream, toward Maryland, the rocks are harder — metamorphic schist and gneiss, hundreds of millions of years old. Downstream, toward the Potomac, the ground softens into sand, gravel, and clay deposited by ancient seas. The fall zone is where the creek drops over that transition, creating the rapids and small cascades you can see and hear.

                This boundary shaped American history. Every major city on the East Coast — from Trenton to Richmond to Augusta — sits on the fall line. Why? Because the falls were the farthest point inland that ships could navigate. Goods had to be unloaded and portaged around the rapids, so trading posts, then towns, then cities grew up at those transfer points. Washington itself exists where it does partly because of the falls of the Potomac, just a few miles downstream from here.

                The geology also explains why Rock Creek cut such a deep valley. The creek is working through that hard Piedmont rock, which resists erosion — so instead of spreading out into a wide, gentle floodplain, the water carved a narrow gorge. That's why it feels like a mountain hollow in here, even though you're five miles from the White House.
                """,
                navInstructionText: "Keep heading south along Beach Drive. Look for a stone and concrete footbridge crossing the creek ahead — that's Rolling Meadow Bridge."
            ),
            WalkingWaypoint(
                id: "rc-04-rolling-meadow",
                order: 4,
                lat: 38.95870,
                lng: -77.04880,
                title: "Rolling Meadow Bridge",
                description: "A Depression-era bridge built to look like it grew here",
                triggerRadiusMeters: 30,
                contentAudioFile: "content.m4a",
                navAudioFile: "nav.m4a",
                narrationText: """
                This is Rolling Meadow Bridge, and it's a small masterpiece of a style called parkitecture — architecture designed to disappear into the landscape. Look at how it's built: concrete and local stone, with proportions that echo the boulders in the creek. The handrails were originally wood. Nothing about it screams "engineered structure." It looks like it could have grown here.

                Rolling Meadow Bridge was built in 1934 or '35 as part of the Public Works Administration program that also rebuilt Boundary Bridge where we started. The PWA hired local workers — many of them unemployed men desperate for any job during the Depression — to replace the bridges that the 1930s floods had destroyed.

                A government report from 1939 called these bridges an "advance in small-bridge design in our national parks." That matters because the design philosophy developed here — rustic materials, natural proportions, minimal visual impact — became the template for National Park architecture across the country. The stone-and-timber lodges in Yellowstone and Yosemite followed the same principles. Rock Creek Park was a testing ground.

                Meanwhile, just up the hill from here, the Civilian Conservation Corps — the CCC, another New Deal program — was building the bridle paths and hiking trails that became today's trail network. More than two miles of trail were constructed by young men in CCC camps. You're walking on their work.

                Take a moment on the bridge. Look upstream and downstream. The creek is framed perfectly from here — that's not an accident. These bridges were placed at scenic viewpoints. The engineers were designing experiences, not just infrastructure.
                """,
                navInstructionText: "Cross the bridge and continue south along the trail. The path gets more wooded and quieter here. About a quarter mile to our turnaround point."
            ),
            WalkingWaypoint(
                id: "rc-05-deep-woods",
                order: 5,
                lat: 38.95580,
                lng: -77.04780,
                title: "The Urban Wilderness",
                description: "A forest that makes you forget the city exists",
                triggerRadiusMeters: 35,
                contentAudioFile: "content.m4a",
                navAudioFile: "nav.m4a",
                narrationText: """
                Stop here and just listen for a moment.

                If you came at the right time — a weekday morning, or early on a weekend — you might hear almost nothing human. No traffic. No sirens. No airplanes on final approach to Reagan National. Just water over rocks, wind in canopy, and birds. The pileated woodpecker lives in these woods — that's the big one, the size of a crow, with a red crest like a cartoon. If you hear a rhythmic hammering that sounds way too loud, that's him.

                Theodore Roosevelt used to hike this exact stretch of trail. Not symbolically — literally. As president, he'd slip away from the White House with a few friends, ride out to Rock Creek Park, and scramble through the gorge. He called it his "point-to-point walk" — you picked a destination and went straight there, over or through whatever was in the way. Rock scrambles, creek crossings, fallen trees. His Secret Service detail reportedly hated it.

                Roosevelt's connection to this place matters because he later became the president most responsible for the national park system. Some historians argue that his afternoons bashing through Rock Creek Park helped shape his conservation philosophy. If a wild creek gorge could survive inside a national capital, then surely the great wildernesses of the West deserved protection too.

                Look at the trees around you. The oaks and tulip poplars here are sixty, eighty, some maybe a hundred years old. This forest has been regenerating since the park was established in 1890. Before that, much of this valley was cleared for mills — there were dozens of water-powered mills on Rock Creek in the 1800s. The forest you're standing in is a second-growth comeback story, and it's still getting older and wilder every year.

                This is our turnaround point. We'll head back north along the same route, but I have one more thing to show you.
                """,
                navInstructionText: "Turn around and head back north the way we came. We'll follow Beach Drive back toward Boundary Bridge. Enjoy the walk — you'll notice different things heading in this direction."
            ),
            WalkingWaypoint(
                id: "rc-06-return",
                order: 6,
                lat: 38.96550,
                lng: -77.05280,
                title: "The Creek's Future",
                description: "What it means to have wilderness inside a city",
                triggerRadiusMeters: 35,
                contentAudioFile: "content.m4a",
                navAudioFile: nil,
                narrationText: """
                As you walk these last few hundred yards back to Boundary Bridge, I want to leave you with something to think about.

                Rock Creek is getting cleaner. For most of the twentieth century, it was badly polluted — stormwater runoff carried fertilizers, motor oil, and sewage into the creek. Fish populations collapsed. Swimming, which was common here in the early 1900s, became unthinkable. But over the past two decades, Montgomery County and the District have invested hundreds of millions of dollars in stormwater management — bioswales, rain gardens, permeable pavement, stream restoration. The creek isn't pristine, but herring and shad have returned to spawn. That fish ladder at Peirce Mill, a couple miles downstream, helps them get past the dam. Life is coming back.

                At the same time, the park faces new pressures. Climate change is shifting rainfall patterns — more intense storms mean more flooding and erosion. Invasive species like English ivy, porcelain berry, and stilt grass are overwhelming native plants in places. And the park's popularity, especially since Beach Drive closed to cars, means more foot traffic on trails that weren't designed for it.

                But here's what strikes me most. You just walked less than two miles from a suburban parking lot, and you were in a forest gorge that felt genuinely wild. A million people live within ten miles of where you're standing, and almost none of them were in that gorge with you. Rock Creek Park is one of the great hidden landscapes of the Eastern United States — not because it's remote, but because it's so improbably close.

                Thank you for walking with me. Come back in a different season — this valley is a completely different place in every one of them.
                """,
                navInstructionText: nil
            ),
        ],
        createdAt: Date(timeIntervalSince1970: 1744761600), // 2025-04-16
        updatedAt: Date(timeIntervalSince1970: 1744761600),
        isAuthored: true
    )
}
