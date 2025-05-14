local lpeg = require("lpeg")
local ffi = require("ffi")
local P, S, R, C, Cp, Cmt, Cg, Ct, V = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.Cp, lpeg.Cmt, lpeg.Cg, lpeg.Ct, lpeg.V
local sub, find, insert, concat, byte = string.sub, string.find, table.insert, table.concat, string.byte
local utf8_1 = R "\0\127"
local utf8_2 = R "\194\223" * R "\128\191"
local utf8_3 = R "\224\239" * R "\128\191" * R "\128\191"
local utf8_4 = R "\240\247" * R "\128\191" * R "\128\191" * R "\128\191"
local utf8_char = utf8_1 + utf8_2 + utf8_3 + utf8_4
local patt = lpeg.C(utf8_char) * lpeg.Cp()

ffi.cdef [[
  typedef unsigned char uint8_t;
  typedef unsigned int  uint32_t;
  typedef struct emoji_trie_node {
    void* children[128];    // только ASCII символы для кодов emoji :smile: и т.п.
    uint8_t is_end;
    char unicode[9];        // максимум U+10FFFF в hex + \0
  } emoji_trie_node;
]]

local trie = {}

-- Hardcoded emoji codes previously in emoji_codes table
-- ["::"] = "",
local codes = {
    [":duck:"] = "1f986",
    [":pill:"] = "1f48a",
    [":key:"] = "1f511",
    [":ship:"] = "1f6a2",
    [":kiss:"] = "1f48b",
    [":egg:"] = "1f95a",
    [":dash:"] = "1F4A8",
    [":)"] = "1f642",
    ["-_-"] = "1f611",
    [">_<"] = "1f623",
    ["^_^"] = "1f60a",
    [":bear:"] = "1f43b",
    [":feet:"] = "1f43e",
    ["(:"] = "1f643",
    [":wolf:"] = "1f43a",
    [":boom:"] = "1f4a5",
    [":d"] = "1f600",
    [":("] = "1f641",
    [":p"] = "1f61b",
    [":sad:"] = "1f625",
    ["0_0"] = "1f633",
    [":o"] = "1f62e",
    [":b"] = "1f601",
    [":|"] = "1f610",
    [":gem:"] = "1f48e",
    [":rage:"] = "1F621",
    [":u1fae8:"] = "1f632",
    [":sob:"] = "1F62D",
    [":zzz:"] = "1F634",
    [">~<"] = "1f616",
    [":cold:"] = "1f976",
    [":fyp:"] = "1f92f",
    [":hot:"] = "1f975",
    [":imp:"] = "1f47f",
    [":mage:"] = "1f9d9",
    [":love:"] = "1f970",
    [":what:"] = "1f928",
    [":zany:"] = "1f92a",
    [";)"] = "1f609",
    [":*"] = "1f618",
    [":zap:"] = "26a1",
    [":rofl:"] = "1f923",
    [":xd:"] = "1f606",
    ["b)"] = "1f60e",
    [":heart_eyes:"] = "1f60d",
    [":clown:"] = "1f921",
    ["<3"] = "2764",
    [":fuck:"] = "1F595",
    [":cat:"] = "1F63A",
    [":yum:"] = "1f60b",
    [":fire:"] = "1f525",
    [":-:"] = "1f44e",
    [":+:"] = "1f44d",
    [":ok:"] = "1f44c",
    [":joy:"] = "1f602",
    [":c"] = "1F97A",
    [":angry:"] = "1f620",
    [":cool:"] = "1F192",
    [":sleep:"] = "1f634",
    [":poo:"] = "1f4a9",
    [":ghost:"] = "1f47b",
    [":alien:"] = "1f47d",
    [":rocket:"] = "1f680",
    [":star:"] = "2b50",
    [":u1f92d:"] = "1f92d",
    [":la:"] = "1f1e6",
    [":lb:"] = "1f1e7",
    [":lc:"] = "1f1e8",
    [":ld:"] = "1f1e9",
    [":le:"] = "1f1ea",
    [":lf:"] = "1f1eb",
    [":lg:"] = "1f1ec",
    [":lh:"] = "1f1ed",
    [":li:"] = "1f1ee",
    [":lj:"] = "1f1ef",
    [":lk:"] = "1f1f0",
    [":ll:"] = "1f1f1",
    [":lm:"] = "1f1f2",
    [":ln:"] = "1f1f3",
    [":lo:"] = "1f1f4",
    [":lp:"] = "1f1f5",
    [":lq:"] = "1f1f6",
    [":lr:"] = "1f1f7",
    [":ls:"] = "1f1f8",
    [":lt:"] = "1f1f9",
    [":lu:"] = "1f1fa",
    [":lv:"] = "1f1fb",
    [":lw:"] = "1f1fc",
    [":lx:"] = "1f1fd",
    [":ly:"] = "1f1fe",
    [":lz:"] = "1f1ff",
    [":na:"] = "30-20e3",
    [":nb:"] = "31-20e3",
    [":nc:"] = "32-20e3",
    [":nd:"] = "33-20e3",
    [":ne:"] = "34-20e3",
    [":nf:"] = "35-20e3",
    [":ng:"] = "36-20e3",
    [":nh:"] = "37-20e3",
    [":ni:"] = "38-20e3",
    [":nj:"] = "39-20e3",
    [":umbrella:"] = "2614",
    [":afk:"] = "1f4a4",
    [":blue_heart:"] = "1f499",
    [":monorail:"] = "1f69d",
    [":train:"] = "1f682",
    [":train2:"] = "1f686",
    [":station:"] = "1f689",
    [":metro:"] = "1f687",
    [":parachute:"] = "1fa82",
    [":airplane:"] = "2708",
    [":helicopter:"] = "1f681",
    [":sailboat:"] = "26f5",
    [":speedboat:"] = "1f6a4",
    [":motor_boat:"] = "1f6e5",
    [":ferry:"] = "26f4",
    [":anchor:"] = "2693",
    [":busstop:"] = "1f68f",
    [":fuelpump:"] = "26fd",
    [":flag_white:"] = "1f3f3",
    [":flag_black:"] = "1f3f4",
    [":red_flag:"] = "1f6a9",
    [":milky_way:"] = "1f30c",
    [":earth_asia:"] = "1f30f",
    [":world_map:"] = "1f5fa",
    [":compass:"] = "1f9ed",
    [":mountain:"] = "26f0",
    [":volcano:"] = "1f30b",
    [":mount_fuji:"] = "1f5fb",
    [":camping:"] = "1f3d5",
    [":motorway:"] = "1f6e3",
    [":desert:"] = "1f3dc",
    [":stadium:"] = "1f3df",
    [":houses:"] = "1f3d8",
    [":cityscape:"] = "1f3d9",
    [":house:"] = "1f3e0",
    [":church:"] = "26ea",
    [":kaaba:"] = "1f54b",
    [":mosque:"] = "1f54c",
    [":synagogue:"] = "1f54d",
    [":office:"] = "1f3e2",
    [":hospital:"] = "1f3e5",
    [":hotel:"] = "1f3e8",
    [":love_hotel:"] = "1f3e9",
    [":school:"] = "1f3eb",
    [":factory:"] = "1f3ed",
    [":wedding:"] = "1f492",
    [":japan:"] = "1f5fe",
    [":fountain:"] = "26f2",
    [":foggy:"] = "1f301",
    [":sunrise:"] = "1f305",
    [":hotsprings:"] = "2668",
    [":barber:"] = "1f488",
    [":luggage:"] = "1f9f3",
    [":chair:"] = "1fa91",
    [":toilet:"] = "1f6bd",
    [":shower:"] = "1f6bf",
    [":bathtub:"] = "1f6c1",
    [":sponge:"] = "1f9fd",
    [":razor:"] = "1fa92",
    [":safety_pin:"] = "1f9f7",
    [":broom:"] = "1f9f9",
    [":basket:"] = "1f9fa",
    [":cloud:"] = "2601",
    [":tornado:"] = "1f32a",
    [":new_moon:"] = "1f311",
    [":full_moon:"] = "1f315",
    [":moon_face:"] = "1f31a",
    [":sun_face:"] = "1f31e",
    [":star2:"] = "1f31f",
    [":stars:"] = "1f320",
    [":comet:"] = "2604",
    [":cyclone:"] = "1f300",
    [":rainbow:"] = "1f308",
    [":snowflake:"] = "2744",
    [":snowman:"] = "26c4",
    [":droplet:"] = "1f4a7",
    [":ocean:"] = "1f30a",
    [":two_hearts:"] = "1f495",
    [":heartbeat:"] = "1f493",
    [":heartpulse:"] = "1f497",
    [":cupid:"] = "1f498",
    [":gift_heart:"] = "1f49d",
    [":anger:"] = "1f4a2",
    [":peace:"] = "262e",
    [":cross:"] = "271d",
    [":menorah:"] = "1f54e",
    [":yin_yang:"] = "262f",
    [":ophiuchus:"] = "26ce",
    [":aries:"] = "2648",
    [":taurus:"] = "2649",
    [":gemini:"] = "264a",
    [":cancer:"] = "264b",
    [":virgo:"] = "264d",
    [":libra:"] = "264e",
    [":scorpius:"] = "264f",
    [":capricorn:"] = "2651",
    [":aquarius:"] = "2652",
    [":pisces:"] = "2653",
    [":infinity:"] = "267e",
    [":no_entry:"] = "26d4",
    [":name_badge:"] = "1f4db",
    [":no_bell:"] = "1f515",
    [":no_smoking:"] = "1f6ad",
    [":underage:"] = "1f51e",
    [":question:"] = "2753",
    [":trident:"] = "1f531",
    [":biohazard:"] = "2623",
    [":warning:"] = "26a0",
    [":beginner:"] = "1f530",
    [":recycle:"] = "267b",
    [":chart:"] = "1f4b9",
    [":customs:"] = "1f6c3",
    [":restroom:"] = "1f6bb",
    [":play_pause:"] = "23ef",
    [":track_next:"] = "23ed",
    [":rewind:"] = "23ea",
    [":repeat:"] = "1f501",
    [":repeat_one:"] = "1f502",
    [":cinema:"] = "1f3a6",
    [":symbols:"] = "1f523",
    [":check_mark:"] = "2714",
    [":red_circle:"] = "1f534",
    [":red_square:"] = "1f7e5",
    [":clock1:"] = "1f550",
    [":clock2:"] = "1f551",
    [":clock3:"] = "1f552",
    [":clock4:"] = "1f553",
    [":clock5:"] = "1f554",
    [":clock6:"] = "1f555",
    [":clock7:"] = "1f556",
    [":clock8:"] = "1f557",
    [":clock9:"] = "1f558",
    [":clock10:"] = "1f559",
    [":clock11:"] = "1f55a",
    [":clock12:"] = "1f55b",
    [":clock130:"] = "1f55c",
    [":clock230:"] = "1f55d",
    [":clock330:"] = "1f55e",
    [":clock430:"] = "1f55f",
    [":clock530:"] = "1f560",
    [":clock630:"] = "1f561",
    [":clock730:"] = "1f562",
    [":clock830:"] = "1f563",
    [":clock930:"] = "1f564",
    [":clock1030:"] = "1f565",
    [":clock1130:"] = "1f566",
    [":clock1230:"] = "1f567",
    [":redcode:"] = "1f6c8",
    [":smiley:"] = "1f603",
    [":smile:"] = "1f604",
    [":sweat:"] = "1f605",
    [":kissing:"] = "1f617",
    [":hugging:"] = "1f917",
    [":starstruck:"] = "1f929",
    [":thinking:"] = "1f914",
    [":salut:"] = "1f64c",
    [":muted:"] = "1f636",
    [":ring:"] = "1F48D",
    [":dotted:"] = "1FAE5",
    [":rolleye:"] = "1f644",
    [":smirk:"] = "1f60f",
    [":zipper:"] = "1f910",
    [":hushed:"] = "1f62f",
    [":sleepy:"] = "1f62a",
    [":tired:"] = "1f62b",
    [":relieved:"] = "1f60c",
    [":drooling:"] = "1f924",
    [":pensive:"] = "1f614",
    [":money:"] = "1f911",
    [":astonished:"] = "1f632",
    [":pained:"] = "1f61e",
    [":worried:"] = "1f61f",
    [":triumph:"] = "1f624",
    [":frowning:"] = "1f626",
    [":anguished:"] = "1f627",
    [":fearful:"] = "1f628",
    [":weary:"] = "1f629",
    [":grimacing:"] = "1f62c",
    [":anxious:"] = "1f630",
    [":scream:"] = "1f631",
    [":dizzy:"] = "1f635",
    [":woozy:"] = "1f974",
    [":swear:"] = "1f92c",
    [":bandage:"] = "1f915",
    [":nauseated:"] = "1f922",
    [":vomit:"] = "1f92e",
    [":tissue:"] = "1f927",
    [":party:"] = "1f973",
    [":albert:"] = "1f9d4",
    [":cowboy:"] = "1f920",
    [":lying:"] = "1f925",
    [":shush:"] = "1f92b",
    [":monocle:"] = "1f9d0",
    [":horns:"] = "1f608",
    [":goblin:"] = "1f47a",
    [":skull:"] = "1f480",
    [":alienm:"] = "1f47e",
    [":robot:"] = "1f916",
    [":smile_cat:"] = "1f63a",
    [":joy_cat:"] = "1f639",
    [":smirk_cat:"] = "1f63c",
    [":scream_cat:"] = "1f640",
    [":monkey:"] = "1f412",
    [":tiger:"] = "1f405",
    [":giraffe:"] = "1f992",
    [":raccoon:"] = "1f99d",
    [":mouse:"] = "1f401",
    [":swan:"] = "1f9a2",
    [";p"] = "1f61c",
    [":hamster:"] = "1f439",
    [":rabbit:"] = "1f407",
    [":koala:"] = "1f428",
    [":panda:"] = "1f43c",
    [":zebra:"] = "1f993",
    [":horse:"] = "1f40e",
    [":unicorn:"] = "1f984",
    [":chicken:"] = "1f414",
    [":pig_nose:"] = "1f43d",
    [":monkey2:"] = "1f435",
    [":gorilla:"] = "1f98d",
    [":orangutan:"] = "1f9a7",
    [":guide_dog:"] = "1f9ae",
    [":poodle:"] = "1f429",
    [":tiger2:"] = "1f42f",
    [":leopard:"] = "1f406",
    [":racehorse:"] = "1f40e",
    [":rhinoceros:"] = "1f98f",
    [":sheep:"] = "1f411",
    [":camel:"] = "1f42b",
    [":llama:"] = "1f999",
    [":kangaroo:"] = "1f998",
    [":sloth:"] = "1f9a5",
    [":skunk:"] = "1f9a8",
    [":badger:"] = "1f9a1",
    [":elephant:"] = "1f418",
    [":mouse2:"] = "1f42d",
    [":hedgehog:"] = "1f994",
    [":rabbit2:"] = "1f430",
    [":chipmunk:"] = "1f43f",
    [":lizard:"] = "1f98e",
    [":crocodile:"] = "1f40a",
    [":turtle:"] = "1f422",
    [":snake:"] = "1f40d",
    [":dragon:"] = "1f409",
    [":sauropod:"] = "1f995",
    [":otter:"] = "1f9a6",
    [":shark:"] = "1f988",
    [":dolphin:"] = "1f42c",
    [":whale:"] = "1f433",
    [":whale2:"] = "1f40b",
    [":blowfish:"] = "1f421",
    [":shrimp:"] = "1f990",
    [":squid:"] = "1f991",
    [":octopus:"] = "1f419",
    [":lobster:"] = "1f99e",
    [":shell:"] = "1f41a",
    [":turkey:"] = "1f983",
    [":eagle:"] = "1f985",
    [":parrot:"] = "1f99c",
    [":flamingo:"] = "1f9a9",
    [":peacock:"] = "1f99a",
    [":penguin:"] = "1f427",
    [":baby_chick:"] = "1f424",
    [":butterfly:"] = "1f98b",
    [":snail:"] = "1f40c",
    [":mosquito:"] = "1f99f",
    [":cricket:"] = "1f997",
    [":beetle:"] = "1f41e",
    [":scorpion:"] = "1f982",
    [":spider:"] = "1f577",
    [":spider_web:"] = "1f578",
    [":microbe:"] = "1f9a0",
    [":genie:"] = "1f9de",
    [":zombie:"] = "1f9df",
    [":tooth:"] = "1f9b7",
    [":tongue:"] = "1f445",
    [":brain:"] = "1f9e0",
    [":footprints:"] = "1f463",
    [":skier:"] = "26f7",
    [":woman:"] = "1f469",
    [":person:"] = "1f464",
    [":child:"] = "1f466",
    [":older_woman:"] = "1f475",
    [":older_man:"] = "1f474",
    [":princess:"] = "1f478",
    [":prince:"] = "1f934",
    [":turban:"] = "1f473",
    [":beard:"] = "1f9d4",
    [":angel:"] = "1f47c",
    [":santa:"] = "1f385",
    [":detective:"] = "1f575",
    [":guardsman:"] = "1f482",
    [":superhero:"] = "1f9b8",
    [":fairy:"] = "1f9da",
    [":vampire:"] = "1f9db",
    [":merperson:"] = "1f9dc",
    [":no_good:"] = "1f645",
    [":massage:"] = "1f486",
    [":haircut:"] = "1f487",
    [":walking:"] = "1f6b6",
    [":runner:"] = "1f3c3",
    [":dancer:"] = "1f483",
    [":golfer:"] = "1f3cc",
    [":surfer:"] = "1f3c4",
    [":rowboat:"] = "1f6a3",
    [":swimmer:"] = "1f3ca",
    [":bicyclist:"] = "1f6b4",
    [":selfie:"] = "1f933",
    [":muscle:"] = "1f4aa",
    [":right:"] = "1f449",
    [":left:"] = "1f448",
    [":elf:"] = "1f9dd",
    [":halo:"] = "1f607",
    [":open_hands:"] = "1f450",
    [":hheart:"] = "1f49f",
    [":handshake:"] = "1f91d",
    [":nails:"] = "1f485",
    [":dancers:"] = "1f46f",
    [":balloon:"] = "1f388",
    [":fireworks:"] = "1f386",
    [":sparkler:"] = "1f387",
    [":sparkles:"] = "2728",
    [":bamboo:"] = "1f38d",
    [":dolls:"] = "1f38e",
    [":flags:"] = "1f38f",
    [":wind_chime:"] = "1f390",
    [":rice_scene:"] = "1f391",
    [":ribbon:"] = "1f380",
    [":ticket:"] = "1f3ab",
    [":thread:"] = "1f9f5",
    [":eyeglasses:"] = "1f453",
    [":goggles:"] = "1f97d",
    [":lab_coat:"] = "1f97c",
    [":necktie:"] = "1f454",
    [":shirt:"] = "1f455",
    [":jeans:"] = "1f456",
    [":shorts:"] = "1f9e6",
    [":scarf:"] = "1f9e3",
    [":gloves:"] = "1f9e4",
    [":socks:"] = "1f9e6",
    [":dress:"] = "1f457",
    [":kimono:"] = "1f458",
    [":briefs:"] = "1fa72",
    [":bikini:"] = "1f459",
    [":purse:"] = "1f45b",
    [":handbag:"] = "1f45c",
    [":pouch:"] = "1f45d",
    [":mans_shoe:"] = "1f45e",
    [":flat_shoe:"] = "1f97f",
    [":high_heel:"] = "1f460",
    [":sandal:"] = "1f461",
    [":crown:"] = "1f451",
    [":billed_cap:"] = "1f9e2",
    [":womans_hat:"] = "1f452",
    [":tophat:"] = "1f3a9",
    [":lipstick:"] = "1f484",
    [":soccer:"] = "26bd",
    [":baseball:"] = "26be",
    [":softball:"] = "1f94e",
    [":basketball:"] = "1f3c0",
    [":volleyball:"] = "1f3d0",
    [":football:"] = "1f3c8",
    [":8ball:"] = "1f3b1",
    [":bowling:"] = "1f3b3",
    [":ice_skate:"] = "26f8",
    [":canoe:"] = "1f6f6",
    [":goal_net:"] = "1f945",
    [":ice_hockey:"] = "1f3d2",
    [":lacrosse:"] = "1f94d",
    [":ping_pong:"] = "1f3d3",
    [":badminton:"] = "1f3f8",
    [":tennis:"] = "1f3be",
    [":medal:"] = "1f3c5",
    [":trophy:"] = "1f3c6",
    [":video_game:"] = "1f3ae",
    [":joystick:"] = "1f579",
    [":game_die:"] = "1f3b2",
    [":teddy_bear:"] = "1f9f8",
    [":mahjong:"] = "1f004",
    [":chess_pawn:"] = "265f",
    [":spades:"] = "2660",
    [":clubs:"] = "2663",
    [":hearts:"] = "2665",
    [":diamonds:"] = "1f3c7",
    [":speaker:"] = "1f508",
    [":sound:"] = "1f509",
    [":loud_sound:"] = "1f50a",
    [":notes:"] = "1f3b6",
    [":microphone:"] = "1f3a4",
    [":headphones:"] = "1f3a7",
    [":saxophone:"] = "1f3b7",
    [":trumpet:"] = "1f3ba",
    [":guitar:"] = "1f3b8",
    [":banjo:"] = "1f3b9",
    [":violin:"] = "1f3bb",
    [":radio:"] = "1f4fb",
    [":unlock:"] = "1f513",
    [":old_key:"] = "1f5dd",
    [":hammer:"] = "1f528",
    [":wrench:"] = "1f527",
    [":brick:"] = "1f9f1",
    [":oil_drum:"] = "1f6e2",
    [":alembic:"] = "2697",
    [":test_tube:"] = "1f9ea",
    [":petri_dish:"] = "1f9eb",
    [":syringe:"] = "1f489",
    [":microscope:"] = "1f52c",
    [":telescope:"] = "1f52d",
    [":scales:"] = "2696",
    [":chains:"] = "26d3",
    [":toolbox:"] = "1f9f0",
    [":magnet:"] = "1f9f2",
    [":shield:"] = "1f6e1",
    [":dagger:"] = "1f5e1",
    [":telephone:"] = "260e",
    [":pager:"] = "1f4df",
    [":phone:"] = "1f4de",
    [":calling:"] = "1f4f2",
    [":female:"] = "2640",
    [":smoking:"] = "1f6ac",
    [":coffin:"] = "1f9ff",
    [":battery:"] = "1f50b",
    [":computer:"] = "1f4bb",
    [":printer:"] = "1f5a8",
    [":keyboard:"] = "1f5ae",
    [":trackball:"] = "1f5b2",
    [":minidisc:"] = "1f4bd",
    [":abacus:"] = "1f9ee",
    [":clapper:"] = "1f3ac",
    [":satellite:"] = "1f4e1",
    [":camera:"] = "1f4f7",
    [":mag_right:"] = "1f50e",
    [":candle:"] = "1f56f",
    [":diya_lamp:"] = "1fa94",
    [":flashlight:"] = "1f526",
    [":green_book:"] = "1f4d7",
    [":blue_book:"] = "1f4d8",
    [":books:"] = "1f4da",
    [":notebook:"] = "1f4d3",
    [":ledger:"] = "1f4d2",
    [":scroll:"] = "1f4dc",
    [":newspaper:"] = "1f4f0",
    [":bookmark:"] = "1f516",
    [":label:"] = "1f3f7",
    [":moneybag:"] = "1f4b0",
    [":dollar:"] = "1f4b5",
    [":pound:"] = "1f4b7",
    [":receipt:"] = "1f9fe",
    [":envelope:"] = "1f4e7",
    [":email:"] = "1f4e9",
    [":inbox_tray:"] = "1f4e5",
    [":package:"] = "1f4e6",
    [":mailbox:"] = "1f4eb",
    [":postbox:"] = "1f4ee",
    [":ballot_box:"] = "1f5f3",
    [":pencil2:"] = "1f4dd",
    [":black_nib:"] = "1f58b",
    [":paintbrush:"] = "1f58c",
    [":crayon:"] = "1f58d",
    [":briefcase:"] = "1f4bc",
    [":calendar:"] = "1f4c6",
    [":card_index:"] = "1f4c7",
    [":bar_chart:"] = "1f4ca",
    [":clipboard:"] = "1f4cb",
    [":pushpin:"] = "1f4cc",
    [":paperclip:"] = "1f4ce",
    [":scissors:"] = "1f4ba",
    [":hourglass:"] = "231b",
    [":watch:"] = "1f38f",
    [":stopwatch:"] = "1f502",
    [":pizza:"] = "1f355",
    [":hamburger:"] = "1f354",
    [":fries:"] = "1f35f",
    [":hotdog:"] = "1f32d",
    [":popcorn:"] = "1f37f",
    [":bacon:"] = "1f953",
    [":cooking:"] = "1f373",
    [":waffle:"] = "1f9c7",
    [":pancakes:"] = "1f95e",
    [":butter:"] = "1f9c8",
    [":bread:"] = "1f35e",
    [":croissant:"] = "1f950",
    [":pretzel:"] = "1f968",
    [":bagel:"] = "1f96f",
    [":sandwich:"] = "1f96a",
    [":burrito:"] = "1f32f",
    [":dumpling:"] = "1f95f",
    [":bento:"] = "1f371",
    [":rice_ball:"] = "1f359",
    [":curry:"] = "1f35b",
    [":ramen:"] = "1f35c",
    [":oyster:"] = "1f9aa",
    [":sushi:"] = "1f363",
    [":fish_cake:"] = "1f365",
    [":moon_cake:"] = "1f96e",
    [":falafel:"] = "1f9c6",
    [":spaghetti:"] = "1f35d",
    [":icecream:"] = "1f366",
    [":shaved_ice:"] = "1f367",
    [":ice_cream:"] = "1f368",
    [":doughnut:"] = "1f369",
    [":cookie:"] = "1f36a",
    [":birthday:"] = "1f382",
    [":cupcake:"] = "1f9c1",
    [":candy:"] = "1f36c",
    [":lollipop:"] = "1f36d",
    [":dango:"] = "1f361",
    [":custard:"] = "1f36e",
    [":honey_pot:"] = "1f36f",
    [":coffee:"] = "1f375",
    [":champagne:"] = "1f37e",
    [":wine_glass:"] = "1f377",
    [":cocktail:"] = "1f378",
    [":beers:"] = "1f37b",
    [":chopsticks:"] = "1f962",
    [":spoon:"] = "1f944",
    [":amphora:"] = "1f3fa",
    [":kiwi_fruit:"] = "1f95d",
    [":coconut:"] = "1f965",
    [":grapes:"] = "1f347",
    [":melon:"] = "1f348",
    [":watermelon:"] = "1f349",
    [":tangerine:"] = "1f34a",
    [":lemon:"] = "1f34b",
    [":banana:"] = "1f34c",
    [":pineapple:"] = "1f34d",
    [":mango:"] = "1f96d",
    [":apple:"] = "1f34e",
    [":peach:"] = "1f351",
    [":cherries:"] = "1f352",
    [":strawberry:"] = "1f353",
    [":tomato:"] = "1f345",
    [":eggplant:"] = "1f346",
    [":hot_pepper:"] = "1f336",
    [":mushroom:"] = "1f344",
    [":avocado:"] = "1f951",
    [":cucumber:"] = "1f952",
    [":broccoli:"] = "1f966",
    [":potato:"] = "1f954",
    [":garlic:"] = "1f9c4",
    [":onion:"] = "1f9c5",
    [":carrot:"] = "1f955",
    [":chestnut:"] = "1f330",
    [":peanuts:"] = "1f95c",
    [":bouquet:"] = "1f490",
    [":rosette:"] = "1f3f5",
    [":hibiscus:"] = "1f33a",
    [":sunflower:"] = "1f33b",
    [":blossom:"] = "1f33c",
    [":tulip:"] = "1f337",
    [":shamrock:"] = "1f340",
    [":seedling:"] = "1f331",
    [":palm_tree:"] = "1f334",
    [":cactus:"] = "1f335",
    [":maple_leaf:"] = "1f341",
    [":leaves:"] = "1f343",
    [":automobile:"] = "1f697",
    [":police_car:"] = "1f693",
    [":blue_car:"] = "1f699",
    [":minibus:"] = "1f690",
    [":trolleybus:"] = "1f68e",
    [":ambulance:"] = "1f691",
    [":truck:"] = "1f69a",
    [":tractor:"] = "1f69c",
    [":skateboard:"] = "1f6f9",
    [":motorcycle:"] = "1f3cd",
    [":racing_car:"] = "1f3ce",
    [":light_rail:"] = "1f688"
}
local function build_trie()
    for emcode, unicode in pairs(codes) do
        local current = trie
        for i = 1, #emcode do
            local char = emcode:sub(i, i)
            if not current[char] then
                current[char] = {}
            end
            current = current[char]
        end
        current.is_end = true
        current.code = emcode
        current.unicode = unicode
    end
end
build_trie()

local bit = require("bit")
local function hexToChar(hex)
    local code = tonumber(hex, 16)
    if not code then return nil end
    local buf = ffi.new("uint8_t[4]")
    local len = 0
    if code <= 0x7F then
        buf[0] = code
        len = 1
    elseif code <= 0x7FF then
        buf[0] = 0xC0 + bit.rshift(code, 6)
        buf[1] = 0x80 + bit.band(code, 0x3F)
        len = 2
    elseif code <= 0xFFFF then
        buf[0] = 0xE0 + bit.rshift(code, 12)
        buf[1] = 0x80 + bit.band(bit.rshift(code, 6), 0x3F)
        buf[2] = 0x80 + bit.band(code, 0x3F)
        len = 3
    elseif code <= 0x10FFFF then
        buf[0] = 0xF0 + bit.rshift(code, 18)
        buf[1] = 0x80 + bit.band(bit.rshift(code, 12), 0x3F)
        buf[2] = 0x80 + bit.band(bit.rshift(code, 6), 0x3F)
        buf[3] = 0x80 + bit.band(code, 0x3F)
        len = 4
    end
    return ffi.string(buf, len)
end
-- Замена кодов на эмодзи


local function replaceEmojiCodes(text)
    local result, i, len = {}, 1, #text
    while i <= len do
        -- Поддержка :uXXXX: формата
        if text:sub(i, i + 1) == ":u" then
            local end_pos = text:find(":", i + 2, true)
            if end_pos then
                local hex = text:sub(i + 2, end_pos - 1)
                local char = hexToChar(hex)
                if char then
                    table.insert(result, char)
                    i = end_pos + 1
                    goto continue
                end
            end
        end

        -- Поиск в trie
        do
            local current, j, last_pos, last_unicode = trie, i
            while j <= len do
                local c = text:sub(j, j)
                current = current[c]
                if not current then break end
                if current.is_end then
                    last_pos, last_unicode = j, current.unicode
                end
                j = j + 1
            end
            if last_pos then
                local char = hexToChar(last_unicode)
                if char then
                    table.insert(result, char)
                    i = last_pos + 1
                    goto continue
                end
            end
        end

        -- Просто символ
        table.insert(result, text:sub(i, i))
        i = i + 1
        ::continue::
    end
    return table.concat(result)
end



local utf8_length = ffi.new("uint8_t[256]")
for i = 0, 127 do utf8_length[i] = 1 end
for i = 192, 223 do utf8_length[i] = 2 end
for i = 224, 239 do utf8_length[i] = 3 end
for i = 240, 247 do utf8_length[i] = 4 end

local function utf8next(str, i)
    local c = string.byte(str, i)
    local len = utf8_length[c]
    if not len then return nil end
    return str:sub(i, i + len - 1), i + len
end

local function utf8codepoint(s, i)
    i = i or 1
    local c1 = string.byte(s, i)
    local len = utf8_length[c1]
    if not len then return nil end
    if len == 1 then
        return c1, 1
    elseif len == 2 then
        local c2 = string.byte(s, i + 1)
        return ((c1 - 192) * 64 + (c2 - 128)), 2
    elseif len == 3 then
        local c2 = string.byte(s, i + 1)
        local c3 = string.byte(s, i + 2)
        return ((c1 - 224) * 4096 + (c2 - 128) * 64 + (c3 - 128)), 3
    else
        local c2 = string.byte(s, i + 1)
        local c3 = string.byte(s, i + 2)
        local c4 = string.byte(s, i + 3)
        return ((c1 - 240) * 262144 + (c2 - 128) * 4096 + (c3 - 128) * 64 + (c4 - 128)), 4
    end
end

local emoji_set = {}
local function add_range(set, start, stop)
    for i = start, stop do set[i] = true end
end
add_range(emoji_set, 0x1F600, 0x1F64F)
add_range(emoji_set, 0x1F300, 0x1F5FF)
add_range(emoji_set, 0x1F680, 0x1F6FF)
add_range(emoji_set, 0x2600, 0x26FF)
add_range(emoji_set, 0x2700, 0x27BF)
add_range(emoji_set, 0x1F900, 0x1F9FF)
add_range(emoji_set, 0x1FA70, 0x1FAFF)
add_range(emoji_set, 0x1F1E6, 0x1F1FF)

local function isEmoji(char)
    local code = utf8codepoint(char)
    return code and emoji_set[code] or false
end

-- local function utf8next(str, i)
--     local char, next_i = patt:match(str, i)
--     if not char then return nil end
--     return char, next_i
-- end


local popular_emojis = {
    -- Эмоции и лица
    ":u263a:", ":u1f600:", ":u1f601:", ":u1f602:", ":u1f603:", ":u1f604:", ":u1f605:",
    ":u1f606:", ":u1f607:", ":u1f608:", ":u1f609:", ":u1f60a:", ":u1f60b:", ":u1f60c:",
    ":u1f60d:", ":u1f60e:", ":u1f60f:", ":u1f610:", ":u1f611:", ":u1f612:", ":u1f613:",
    ":u1f614:", ":u1f615:", ":u1f616:", ":u1f617:", ":u1f618:", ":u1f619:", ":u1f61a:",
    ":u1f61b:", ":u1f61c:", ":u1f61d:", ":u1f61e:", ":u1f61f:", ":u1f620:", ":u1f621:",
    ":u1f622:", ":u1f623:", ":u1f624:", ":u1f625:", ":u1f626:", ":u1f627:", ":u1f628:",
    ":u1f629:", ":u1f62a:", ":u1f62b:", ":u1f62c:", ":u1f62d:", ":u1f62e:", ":u1f62f:",
    ":u1f630:", ":u1f631:", ":u1f632:", ":u1f633:", ":u1f634:", ":u1f635:", ":u1f636:",
    ":u1f637:", ":u1f638:", ":u1f639:", ":u1f63a:", ":u1f63b:", ":u1f63c:", ":u1f63d:",
    ":u1f63e:", ":u1f63f:", ":u1f640:", ":u1f641:", ":)", ":u1f643:", ":u1f644:",
    ":u1f910:", ":u1f911:", ":u1f912:", ":u1f913:", ":u1f914:", ":u1f915:", ":u1f916:",
    ":u1f917:", ":u1f920:", ":u1f921:", ":u1f922:", ":u1f923:", ":u1f924:", ":u1f925:",
    ":u1f926:", ":u1f927:", ":u1f928:", ":u1f929:", ":u1f92a:", ":u1f92b:", ":u1f92c:",
    ":u1f92d:", ":u1f92e:", ":u1f92f:", ":u1f930:", ":u1f973:", ":u1f974:", ":u1f975:",
    ":u1f976:", ":u1f978:", ":u1f979:", ":u1f97a:", ":u1f9d0:", ":u1f9d1:", ":u1f9d2:",
    ":u1f9d3:", ":u1f9d4:", ":u1f9d5:", ":u1f9d6:", ":u1f9d7:", ":u1f9d8:", ":u1f9d9:",
    ":u1f9da:", ":u1f9db:", ":u1f9dc:", ":u1f9dd:", ":u1f9de:", ":u1f9df:", ":u1f9e0:",
    ":u1f9e1:", ":u1f9e2:", ":u1f9e3:", ":u1f9e4:", ":u1f9e5:", ":u1f9e6:", ":u2764:",
    ":u1f47b:", ":u1f47d:", ":u1f47e:", ":u1f47f:", ":u1f480:", ":u1f4a9:", ":u1f595:",
    -- Новые эмоции (Unicode 15.1)
    ":u1faf0:", ":u1faf1:", ":u1faf2:", ":u1faf3:", ":u1faf4:", ":u1faf5:", ":u1faf6:",


    -- Жесты
    ":u1f44d:", ":u1f44e:", ":u1f44f:", ":u1f64c:", ":u1f64f:", ":u1f91d:", ":u1f44a:",
    ":u1f91b:", ":u1f91c:", ":u1f91e:", ":u1f590:", ":u1f596:", ":u1f918:", ":u1f919:",
    ":u1f448:", ":u1f449:", ":u1f446:", ":u1f447:", ":u1f485:", ":u1f933:",
    ":u1f4aa:", ":u1f9b5:", ":u1f9b6:", ":u1f44c:", ":u1f91f:", ":u1f450:", ":u1f932:",
    ":u1f64b:", ":u1f64d:", ":u1f64e:", ":u1f487:", ":u1f486:", ":u1f491:",
    ":u1f489:", ":u1f48a:", ":u1f48b:", ":u1f48c:", ":u1f48d:", ":u1f48e:", ":u1f48f:",
    ":u1f490:", ":u1f492:", ":u1f493:", ":u1f494:", ":u1f495:", ":u1f496:",
    ":u1f497:", ":u1f498:", ":u1f499:", ":u1f49a:", ":u1f49b:", ":u1f49c:", ":u1f49d:",

    -- Природа
    ":u1f436:", ":u1f431:", ":u1f437:", ":u1f42d:", ":u1f439:", ":u1f430:", ":u1f43a:",
    ":u1f42b:", ":u1f418:", ":u1f42f:", ":u1f428:", ":u1f43b:", ":u1f43c:", ":u1f43e:",
    ":u1f983:", ":u1f414:", ":u1f413:", ":u1f423:", ":u1f424:", ":u1f425:", ":u1f426:",
    ":u1f427:", ":u1f54a:", ":u1f985:", ":u1f986:", ":u1f989:", ":u1f9a2:", ":u1f9a5:",
    ":u1f9a6:", ":u1f9a7:", ":u1f9a8:", ":u1f9a9:", ":u1f99a:", ":u1f99c:",
    ":u1f9b2:", ":u1f9b3:", ":u1f40d:", ":u1f422:", ":u1f98e:", ":u1f996:",
    ":u1f995:", ":u1f419:", ":u1f41a:", ":u1f40c:", ":u1f98b:", ":u1f41b:", ":u1f41c:",
    ":u1f41d:", ":u1f41e:", ":u1f997:", ":u1f577:", ":u1f578:", ":u1f982:", ":u1f99f:",
    ":u1f99e:", ":u1f9a0:", ":u1f9a1:", ":u1f9a3:", ":u1f9a4:", ":u1f9aa:",
    ":u1f9ab:", ":u1f9ac:", ":u1f9ad:", ":u1f9ae:", ":u1f9af:",

    -- Еда и напитки
    ":u1f355:", ":u1f354:", ":u1f35f:", ":u1f357:", ":u1f356:", ":u1f32d:", ":u1f32e:",
    ":u1f32f:", ":u1f36f:", ":u1f37c:", ":u1f37a:", ":u1f37b:", ":u1f942:", ":u1f943:",
    ":u1f964:", ":u1f9c3:", ":u1f9c4:", ":u1f9c0:", ":u1f95a:", ":u1f373:", ":u1f958:",
    ":u1f372:", ":u1f963:", ":u1f957:", ":u1f37d:", ":u1f96a:", ":u1f371:",
    ":u1f35e:", ":u1f950:", ":u1f956:", ":u1f968:", ":u1f96f:", ":u1f95e:", ":u1f9c7:",
    ":u1f9c8:", ":u1f9c9:", ":u1f9c2:", ":u1f36d:", ":u1f36e:", ":u1f36c:", ":u1f370:",
    ":u1f382:", ":u1f967:", ":u1f9c1:", ":u1f37e:", ":u1f37f:", ":u1f9c5:", ":u1f95b:",
    ":u1f95c:", ":u1f95d:", ":u1f95f:", ":u1f960:", ":u1f961:", ":u1f962:", ":u1f965:",

    -- Транспорт
    ":u1f697:", ":u1f695:", ":u1f699:", ":u1f68c:", ":u1f68e:", ":u1f3ce:", ":u1f693:",
    ":u1f69a:", ":u1f692:", ":u1f6f4:", ":u1f6f5:", ":u1f68b:", ":u1f69d:", ":u1f6fa:",
    ":u1f6b2:", ":u1f6f9:", ":u1f680:", ":u1f6f0:", ":u1f6ce:", ":u1f6d1:", ":u1f6d2:",
    ":u1f6e0:", ":u1f6e1:", ":u1f6e2:", ":u1f6f6:", ":u1f6f8:", ":u1f6aa:", ":u1f6ac:",
    ":u1f6b6:", ":u1f6b9:", ":u1f6ba:", ":u1f6bb:", ":u1f6bc:", ":u1f6bd:", ":u1f6be:",
    ":u1f6a2:", ":u1f6a3:", ":u1f6a4:", ":u1f6a5:", ":u1f6a6:", ":u1f6a7:", ":u1f6a8:",

    -- Символы
    ":u1f4af:", ":u1f4a2:", ":u1f4a3:", ":u1f4a4:", ":u1f4a5:", ":u1f4a6:", ":u1f4a7:",
    ":u1f4a8:", ":u1f4ab:", ":u1f4ac:", ":u1f4ad:", ":u1f4ae:",
    ":u1f534:", ":u1f535:", ":u1f7e0:", ":u1f7e1:", ":u1f7e2:", ":u1f7e3:", ":u1f7e4:",
    ":u1f7e5:", ":u1f7e6:", ":u1f7e7:", ":u1f7e8:", ":u1f7e9:", ":u1f7ea:", ":u1f7eb:",
    ":u1f4f4:", ":u1f4f5:", ":u1f4f6:", ":u1f4f7:", ":u1f4f9:", ":u1f4fa:", ":u1f4fb:",

    -- Активности
    ":u1f3c0:", ":u1f3c8:", ":u1f3be:", ":u1f3cd:", ":u1f3c2:", ":u1f3ca:", ":u1f3c4:",
    ":u1f6f3:", ":u1f3c7:", ":u1f3c6:", ":u1f947:", ":u1f948:", ":u1f949:", ":u1f3cf:",
    ":u1f3d3:", ":u1f3f8:", ":u1f94a:", ":u1f94b:", ":u1f945:", ":u1f94c:",

    -- Предметы
    ":u1f4f1:", ":u1f4da:", ":u1f4d6:", ":u1f4bb:", ":u1f4bc:", ":u1f4bd:", ":u1f4be:",
    ":u1f4bf:", ":u1f4c0:", ":u1f4dd:", ":u1f50f:", ":u1f513:", ":u1f512:", ":u1f511:",
    ":u1f516:", ":u1f506:", ":u1f4a1:", ":u1f526:", ":u1f527:", ":u1f529:", ":u1f52a:",
    ":u1f52b:", ":u1f52c:", ":u1f52d:", ":u1f52e:", ":u1f52f:", ":u1f530:", ":u1f531:",
    ":u1f532:", ":u1f533:", ":u1f536:", ":u1f537:", ":u1f538:",
    ":u1f539:", ":u1f53a:", ":u1f53b:", ":u1f53c:", ":u1f53d:", ":u1f549:", ":u1f54b:",
    ":u1f54c:", ":u1f54d:", ":u1f550:", ":u1f551:", ":u1f552:", ":u1f553:",
    ":u1f554:", ":u1f555:", ":u1f556:", ":u1f557:", ":u1f558:", ":u1f559:", ":u1f55a:",
    ":u1f55b:", ":u1f55c:", ":u1f55d:", ":u1f55e:", ":u1f55f:", ":u1f560:", ":u1f561:",
    ":u1f562:", ":u1f563:", ":u1f564:", ":u1f565:", ":u1f566:", ":u1f567:",

    -- Погода
    ":u2600:", ":u2601:", ":u2602:", ":u2614:", ":u26c4:", ":u1f324:", ":u1f325:",
    ":u1f326:", ":u1f327:", ":u1f328:", ":u1f329:", ":u1f32a:", ":u1f32b:", ":u1f32c:",
    ":u2744:", ":u2603:", ":u1f525:", ":u26a1:", ":u2604:", ":u1f308:", ":u1f30a:",
    ":u1f30b:", ":u1f30c:", ":u1f30d:", ":u1f30e:", ":u1f30f:", ":u1f311:", ":u1f312:",
    ":u1f313:", ":u1f314:", ":u1f315:", ":u1f316:", ":u1f317:", ":u1f318:", ":u1f319:",
    ":u1f31a:", ":u1f31b:", ":u1f31c:", ":u1f31d:", ":u1f31e:", ":u1f31f:",

    -- Музыка
    ":u1f3b5:", ":u1f3b6:", ":u1f3b7:", ":u1f3b8:", ":u1f3b9:", ":u1f3ba:", ":u1f3bb:",
    ":u1f3bc:", ":u1f3bd:", ":u1f399:", ":u1f39a:", ":u1f39b:", ":u1f39e:", ":u1f39f:",
    ":u1f3a4:", ":u1f3a7:", ":u1f3a8:", ":u1f3a9:", ":u1f3aa:", ":u1f3ab:", ":u1f3ac:",
    ":u1f3ad:", ":u1f3ae:", ":u1f3af:", ":u1f3b0:", ":u1f3b1:", ":u1f3b2:", ":u1f3b3:",
    ":u1f3b4:", ":u1f3bf:",

    -- Растения
    ":u1f330:", ":u1f331:", ":u1f332:", ":u1f333:", ":u1f334:", ":u1f335:", ":u1f337:",
    ":u1f338:", ":u1f339:", ":u1f33a:", ":u1f33b:", ":u1f33c:", ":u1f33d:", ":u1f33e:",
    ":u1f33f:", ":u1f340:", ":u1f341:", ":u1f342:", ":u1f343:", ":u1f344:", ":u1f345:",
    ":u1f346:", ":u1f347:", ":u1f348:", ":u1f349:", ":u1f34a:", ":u1f34b:", ":u1f34c:",
    ":u1f34d:", ":u1f34e:", ":u1f34f:", ":u1f350:", ":u1f351:", ":u1f352:", ":u1f353:"
}

local code_to_text = {}
for text, code in pairs(codes) do
    code_to_text[":u" .. code .. ":"] = text
end

-- Создаем новую таблицу с замененными значениями
local new_popular_emojis = {}
for _, emoji in ipairs(popular_emojis) do
    new_popular_emojis[#new_popular_emojis + 1] = code_to_text[emoji] or emoji
end

return {
    replace = replaceEmojiCodes,
    isEmoji = isEmoji,
    utf8next = utf8next,
    popular = new_popular_emojis
}
