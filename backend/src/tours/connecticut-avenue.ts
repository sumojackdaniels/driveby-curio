// Hand-authored tour: Bethesda → Farragut Square down Connecticut Avenue.
//
// This is the first end-to-end test tour for DriveByCurio. The narration is
// hand-written; audio is pre-synthesized via ElevenLabs and committed under
// backend/audio-cache/ keyed by tour_id + waypoint_id, so the running service
// just streams files from disk.
//
// Coordinates were picked to sit ON the actual Connecticut Avenue corridor
// (not on side streets) so a GPX-driven simulator drive will trip the trigger
// circles in the right order. trigger_radius_m is intentionally generous
// (~250m) because the GPX sample density and CLLocationManager filtering in
// the sim are coarser than reality.

import type { Tour } from "./types";

export const connecticutAvenue: Tour = {
  id: "connecticut-avenue",
  title: "From Streetcar Suburb to Federal City",
  subtitle: "Bethesda to Dupont Circle through 130 years of Washington's northwest",
  region: "Bethesda, MD → Washington, DC",
  duration_minutes: 25,
  distance_km: 12,
  cover_image_url: null, // TODO: tour cover art for Now Playing artwork slot — using a placeholder for milestone 1
  author: "DriveByCurio",
  waypoints: [
    {
      id: "01-bethesda-metro",
      order: 1,
      lat: 38.98473,
      lng: -77.09425,
      title: "Bethesda's Railroad Beginnings",
      subject: "Bethesda Metro · Wisconsin & Old Georgetown",
      trigger_radius_m: 250,
      narration_text:
        "Welcome to From Streetcar Suburb to Federal City. You're standing where Bethesda began — not as a town, but as a whistle-stop. " +
        "Until the 1870s, this was nothing but Maryland farmland. Then the Metropolitan Branch of the Baltimore and Ohio Railroad came through, " +
        "and a tiny station appeared at the crossing of the Georgetown Pike and the road to Rockville. The station took its name from a small " +
        "Presbyterian meeting house up the road, called Bethesda — Hebrew for 'house of mercy.' The name stuck. The town grew up around the rails. " +
        "For the next half century, Bethesda was a quiet farm village whose biggest export was milk for the federal city seven miles south. " +
        "We're going to drive that seven miles now — down Connecticut Avenue, through neighborhoods that did not exist when the railroad first arrived, " +
        "and into a Washington that has been completely reshaped by the trip we're about to take.",
    },
    {
      id: "02-chevy-chase-circle",
      order: 2,
      lat: 38.96762,
      lng: -77.07434,
      title: "Senator Newlands and the First Streetcar Suburb",
      subject: "Chevy Chase Circle · The DC line",
      trigger_radius_m: 250,
      narration_text:
        "You're crossing into the District of Columbia at Chevy Chase Circle. This circle, and everything around it for a mile in any direction, " +
        "is the work of one man with a very specific plan. His name was Francis Newlands — a senator from Nevada, and a real estate speculator. " +
        "In 1890 his Chevy Chase Land Company quietly bought up about seventeen hundred acres of farmland straddling the DC-Maryland line. " +
        "The land was useless to commuters because no road ran out this far. So Newlands built one. He paid to extend Connecticut Avenue from Florida Avenue " +
        "all the way out here, and then he laid streetcar tracks down the middle of it. The streetcars ran on his power, generated at his own dam on " +
        "Rock Creek. Then he sold the lots. This was the first true streetcar suburb in the Washington region, and one of the first in America. " +
        "It is also worth saying clearly: the deeds Newlands wrote barred the lots from being sold to Black residents or Jewish residents for decades. " +
        "Those covenants were the foundation of the neighborhood you're about to drive through, and they are part of how we got here.",
    },
    {
      id: "03-chevy-chase-dc",
      order: 3,
      lat: 38.95960,
      lng: -77.06960,
      title: "A Suburb Designed Around a Train",
      subject: "Chevy Chase, DC · Connecticut Avenue",
      trigger_radius_m: 220,
      narration_text:
        "You're now on the Connecticut Avenue Newlands built. Look at the shape of the neighborhood around you. " +
        "The houses face the avenue. The shops, when there are shops, are clustered tight at corners. The whole place is sized for someone walking " +
        "two blocks to a streetcar stop. Streetcar suburbs aren't laid out for cars — they're laid out for a five-minute walk. " +
        "That's why everything feels close together compared to the postwar suburbs further out. " +
        "The streetcars themselves stopped running here in 1935, replaced by buses, and the tracks were paved over. But the bones of the streetcar " +
        "neighborhood are still here: the spacing, the corner stores, the front porches turned toward the avenue. You're driving through a " +
        "piece of urban design that's older than the automobile and was never really meant for one.",
    },
    {
      id: "04-van-ness",
      order: 4,
      lat: 38.94370,
      lng: -77.06310,
      title: "The Mount Vernon Seminary and a New University",
      subject: "Van Ness · UDC and Soviet Embassy hill",
      trigger_radius_m: 250,
      narration_text:
        "Up on your right is the campus of the University of the District of Columbia — the city's public university, founded in 1976 by " +
        "merging three older institutions, including DC Teachers College. But there's an older story on this hill. " +
        "Until the Second World War, this was the Mount Vernon Seminary, a girls' boarding school founded in 1875. In 1942 the federal government " +
        "took the entire campus by eminent domain and handed it to the Navy, which used the buildings to house WAVES — the women's naval reserve — " +
        "doing classified codebreaking work for the rest of the war. After the war the Navy never gave the campus back. The seminary moved away. " +
        "And just up the hill from where you are now, the Soviet Union eventually built one of the largest embassies in Washington — " +
        "deliberately placed on the highest ground in northwest DC, with a clear electromagnetic line of sight to half the federal city below. " +
        "The CIA was not pleased.",
    },
    {
      id: "05-cleveland-park",
      order: 5,
      lat: 38.93540,
      lng: -77.05810,
      title: "Grover Cleveland's Summer White House",
      subject: "Cleveland Park",
      trigger_radius_m: 220,
      narration_text:
        "This neighborhood is named for a president who hated the actual White House. " +
        "In 1886 Grover Cleveland — recently married, miserable in the swampy Washington summer — bought a stone farmhouse out here on what was then " +
        "open countryside, three miles outside the city. He called it Red Top, after its red-painted roof. He commuted into the White House by carriage " +
        "for the rest of the season, and he kept doing it every summer for the rest of his presidency. " +
        "The house itself is gone — it burned down in 1927 — but Red Top put this hilltop on the map. Within a decade, real estate developers were " +
        "selling lots up here under the name 'Cleveland Park.' The name is the only thing left of the president's escape from the city he governed.",
    },
    {
      id: "06-woodley-park-zoo",
      order: 6,
      lat: 38.92960,
      lng: -77.04940,
      title: "Olmsted Designed the Zoo",
      subject: "National Zoo · Woodley Park",
      trigger_radius_m: 250,
      narration_text:
        "Down to your right, in the valley of Rock Creek, is the National Zoological Park. " +
        "It is one of only two zoos in America designed by Frederick Law Olmsted Junior, son of the man who designed Central Park. " +
        "The Zoo was founded in 1889, partly because the Smithsonian was running out of room for the live buffalo someone had given it as a gift. " +
        "Olmsted laid the grounds out to follow the natural contours of Rock Creek — winding paths, no straight lines, the animals' enclosures " +
        "tucked into the woods rather than gridded onto a parade ground. It's why the zoo feels like a forest you wander through and not a park you " +
        "march across. " +
        "By the way — admission has always been free. That was a deliberate decision in the founding charter. The Zoo belongs to the public, " +
        "not to the people who can afford a ticket.",
    },
    {
      id: "07-taft-bridge",
      order: 7,
      lat: 38.92130,
      lng: -77.04690,
      title: "The Lions of the Taft Bridge",
      subject: "Taft Bridge · Calvert Street",
      trigger_radius_m: 200,
      narration_text:
        "You're crossing the Taft Bridge — high above Rock Creek. When it opened in 1907, it was the largest unreinforced concrete structure in " +
        "the world. The four lions guarding the abutments are originals, sculpted by Roland Hinton Perry. They were cast in concrete, painted to " +
        "look like bronze, and by the 1990s they were so weather-eaten that they had to be completely recast from molds taken before they crumbled. " +
        "Halfway across the span, on the right side, you can spot the Cuban Friendship Urn — a marble urn carved from a single block of Cuban marble " +
        "and given to the United States in 1928, before everything went sideways between the two countries. It survived the wreck of the battleship " +
        "Maine, was sent to Havana, and then sent back as a gift. It has been quietly sitting on this bridge for almost a hundred years.",
    },
    {
      id: "08-dupont-circle",
      order: 8,
      lat: 38.90970,
      lng: -77.04320,
      title: "Where the Streetcars All Came Together",
      subject: "Dupont Circle",
      trigger_radius_m: 220,
      narration_text:
        "Welcome to Dupont Circle — the southern terminus of the streetcar line you've been riding the whole way down from Bethesda. " +
        "From the 1890s through the 1920s, this was the western edge of fashionable Washington. Robber barons and senators and mining magnates all built " +
        "enormous Beaux-Arts mansions facing the circle. Most of them are gone now, demolished or carved into apartments and embassies, " +
        "but a few survive — the Patterson House, the Walsh-McLean mansion that's now the Indonesian Embassy, the Anderson House on Massachusetts. " +
        "The Dupont Circle Metro station, which is the busy entrance you can see at the north end of the circle, sits directly on top of the old streetcar " +
        "tunnel that ran under here for decades. When Metro was built in the 1970s, the engineers just reused the existing tunnel for the new subway. " +
        "Even the trains follow the lines Newlands paid to lay down.",
    },
    {
      id: "09-farragut-square",
      order: 9,
      lat: 38.90200,
      lng: -77.03940,
      title: "Arrival at the Federal City",
      subject: "Farragut Square",
      trigger_radius_m: 250,
      narration_text:
        "Last stop. Farragut Square — and you have officially arrived in the federal city. " +
        "From here you can walk three blocks south to Pennsylvania Avenue and the White House. The square is named for Admiral David Farragut, " +
        "the Union naval commander who said 'Damn the torpedoes' at the Battle of Mobile Bay. The bronze statue at the center was cast from the " +
        "metal of the propeller of his flagship, the USS Hartford. " +
        "Stop and think about the drive you just made. Seven miles, a hundred and thirty years. From a railroad whistle-stop in a milk-farming " +
        "Maryland village, through a senator's speculative real estate scheme, past a girls' boarding school the Navy seized, past a president's " +
        "summer hideaway, over a bridge older than the automobile, and into the heart of the capital. " +
        "Every neighborhood you drove through was made by the streetcar — and the streetcar was made because Francis Newlands wanted to sell lots. " +
        "That is more or less how Washington's northwest exists. Thanks for riding along.",
    },
  ],
};
