// lib/services/player_espn_id_service.dart

class PlayerESPNIdService {
  // Map of player names to ESPN IDs
  static final Map<String, String> _playerESPNIds = {
    // Example mappings - you would expand this
    "Tre Harris": "4567048",
  "Malaki Starks": "4685530",
  "Kenneth Grant": "4894654",
  "Derrick Harmon": "4432830",
  "Walter Nolen": "4685503",
  "Omarion Hampton": "4685382",
  "Tyler Booker": "4685263",
  "Emeka Egbuka": "4567750",
  "Luther Burden III": "4685278",
  "Donovan Ezeiruaku": "4683848",
  "Grey Zabel": "4693346",
  "Josh Conerly Jr": "4685326",
  "Jaxson Dart": "4689114",
  "Shavon Revel Jr": "5095865",
  "Maxwell Hairston": "4688931",
  "Trey Amos": "4574689",
  "Nic Scourton": "4833355",
  "Azareye'h Thomas": "4685596",
  "Donovan Jackson": "4431553",
  "Aireontae Ersery": "4429693",
  "Benjamin Morrison": "4816107",
  "Jayden Higgins": "4877706",
  "Tyleik Williams": "4431615",
  "TreVeyon Henderson": "4432710",
  "Landon Jackson": "4432715",
  "TJ Sanders": "4684527",
  "Mason Taylor": "4808766",
  "Carson Schwesinger": "4876017",
  "Jack Sawyer": "4431590",
  "JT Tuimoloau": "4566154",
  "Darius Alexander": "4426542",
  "Jonah Savaiinaea": "4819257",
  "Alfred Collins": "4430835",
  "Elijah Arroyo": "4678006",
  "Quinshon Judkins": "4685702",
  "Xavier Watts": "4431005",
  "Kaleb Johnson": "4819231",
  "Princely Umanmielen": "4429166",
  "Marcus Mbow": "4686362",
  "Omarr Norman-Lott": "4591008",
  "Darien Porter": "4430330",
  "Wyatt Milum": "4431463",
  "Jaylin Noel": "4586312",
  "Jack Bech": "4603186",
  "Jalen Royals": "5082630",
  "Cameron Williams": "4685590",
  "Demetrius Knight": "4427729",
  "Jordan Burch": "4428996",
  "Josaiah Stewart": "4682983",
  "Cameron Skattebo": "4432734",
  "Jalen Milroe": "4430737",
  "Isaiah Bond": "4808839",
  "Elic Ayomanor": "4883647",
  "Joshua Farmer": "4611993",
  "Harold Fannin Jr": "5083076",
  "Deone Walker": "4831989",
  "Ozzy Trapilo": "4432595",
  "Bradyn Swinson": "4431424",
  "Jared Wilson": "4599198",
  "Shemar Turner": "4432804",
  "Kevin Winston Jr": "4685617",
  "Jared Ivey": "4605478",
  "Tate Ratledge": "4429035",
  "Charles Grant": "4694505",
  "Dylan Sampson": "5081397",
  "Ashton Gillotte": "4684432",
  "Kyle Kennard": "4432333",
  "Terrance Ferguson": "4432721",
  "Andrew Mukuba": "4602197",
  "Gunnar Helm": "4686728",
  "Tyler Shough": "4360689",
  "Oluwafemi Oladejo": "4876057",
  "Quinn Ewers": "4889929",
  "Chris Paul Jr": "4602943",
  "Anthony Belton": "4873706",
  "Will Howard": "4429955",
  "Jacob Parrish": "4912847",
  "Tai Felton": "4565185",
  "Savion Williams": "4431487",
  "Zah Frazier": "4572685",
   "Travis Hunter": "4685415",
  "Abdul Carter": "4725996",
  "Mason Graham": "4873232",
  "Ashton Jeanty": "4890973",
  "Cameron Ward": "4688380",
  "Will Campbell": "4685298",
  "Armand Membou": "4789907",
  "Jalon Walker": "4685597",
  "Tetairoa McMillan": "4685472",
  "Tyler Warren": "4431459",
  "Will Johnson": "4685408",
  "Kelvin Banks Jr": "4685260",
  "Colston Loveland": "4723086",
  "Shedeur Sanders": "4432762",
  "Jahdae Barron": "4430925",
  "Mykel Williams": "4685623",
  "Shemar Stewart": "4685562",
  "Jihaad Campbell": "4685287",
  "Matthew Golden": "4701936",
  "Mike Green": "4683188",
  "James Pearce Jr": "5081394",
  "Nick Emmanwori": "4869523",
  "Josh Simmons": "4685360",
  "Billy Bowman Jr": "4431194",
  "Danny Stutsman": "4683215",
  "Tez Johnson": "4608810",
  "Barrett Carter": "4597703",
  "Tory Horton": "4572489",
  "Kyle Williams": "4613202",
  "Denzel Burke": "4432668",
  "Emery Jones Jr": "4685736",
  "Saivion Jones": "4603189",
  "Jonas Sanker": "4683813",
  "Miles Frazier": "4608890",
  "Lathan Ransom": "4429110",
  "Kyle McCord": "4433971",
  "Ty Robinson": "4569586",
  "Logan Brown": "4570075",
  "Bhayshul Tuten": "4882093",
  "CJ West": "4686308",
  "David Walker": "5085355",
  "Aeneas Peebles": "4565311",
  "Xavier Restrepo": "4431353",
  "Zy Alexander": "4696821",
  "RJ Harvey Jr": "4568490",
  "Jalen Travis": "4892240",
  "Quincy Riley": "4428350",
  "Nohl Williams": "4610705",
  "Dylan Fairchild": "4646773",
  "DJ Giddens": "4874509",
  "Vernon Broughton": "4429040",
  "Smael Mondon Jr": "4431573",
  "Tyler Baron": "4692555",
  "Jordan Phillips": "4837188",
  "Dorian Strong": "4568703",
  "Jalen Rivers": "4429010",
  "Damien Martinez": "4808830",
  "Devin Neal": "4682652",
  "Jaylin Lane": "4602667",
  "Jordan James": "4685397",
  "Kobe King": "4588300",
  "JJ Pegues": "4430896",
  "Jeffrey Bassa": "4602389",
  "Ollie Gordon II": "4711533",
  "Elijah Roberts": "4690795",
  "Brashard Smith": "4596602",
  "Dillon Gabriel": "4427238",
  "Barryn Sorrell": "4683643",
  "Jamaree Caldwell": "5089178",
  "Dont'e Thornton": "4432775",
  "Jaylen Reed": "4432758",
  "Jackson Slater": "4876319",
  "Sebastian Castro": "4426882",
  "Upton Stout": "4565200",
  "Ajani Cornelius": "4696203",
  "Trevor Etienne": "4685350",
  "Que Robinson": "4692048",
  "Cobee Bryant": "4429324",
  "Malachi Moore": "4692024",
  "Jaylin Smith": "4594277",
  "Pat Bryant": "4600981",
  "Antwaun Powell-Ryland": "4429009",
  "Hollin Pierce": "4698119",
  "Jarquez Hunter": "4710341",
  "Ty Hamilton": "4431118",
  "Jack Kiser": "4427716",
  "Jah Joyner": "4430111",
  "Cody Simon": "4429071",
  "Rylie Mills": "4430838",
  "Mitchell Evans": "4683243",
  "Tyrion Ingram-Dawkins": "4629149",
  "Carson Vinson": "4769895",
  "Chase Lundt": "4427843",
  "Riley Leonard": "4683423",
  "Kaimon Rucker": "4433904",
  "Chimere Dike": "4431268",
  "Caleb Rogers": "4433889",
  "Jordan Hancock": "4596480",
  "Tommi Hill": "4431550",
  "Jake Briningstool": "4431196",
  "Oronde Gadsden II": "4595342",
  "Kalel Mullings": "4429121",
  "Mello Dotson": "4431356",
  "Luke Kandra": "4430116",
  "Kobe Hudson": "4429056",
  "Caleb Ransaw": "4683347",
  "Howard Cross III": "4426992",
  "Seth McLaughlin": "4429187",
  "Jamon Dumas-Johnson": "4569680"
  };
  
  // Get ESPN ID for a player
  static String? getESPNId(String playerName) {
    // Try direct match first
    if (_playerESPNIds.containsKey(playerName)) {
      return _playerESPNIds[playerName];
    }
    
    // Try normalized name (lowercase, no periods)
    String normalizedName = playerName.toLowerCase().replaceAll('.', '');
    
    for (var entry in _playerESPNIds.entries) {
      String entryNormalized = entry.key.toLowerCase().replaceAll('.', '');
      if (entryNormalized == normalizedName) {
        return entry.value;
      }
      
      // Try partial match (for cases like "J.J. McCarthy" vs "J.J McCarthy")
      if (entryNormalized.contains(normalizedName) || 
          normalizedName.contains(entryNormalized)) {
        return entry.value;
      }
    }
    
    // No match found
    return null;
  }
  
  // Build ESPN image URL from player ID
  static String buildESPNImageUrl(String espnId) {
    return "https://a.espncdn.com/combiner/i?img=/i/headshots/college-football/players/full/$espnId.png";
  }
  
  // Get image URL directly from player name
  static String? getPlayerImageUrl(String playerName) {
    String? espnId = getESPNId(playerName);
    if (espnId != null) {
      return buildESPNImageUrl(espnId);
    }
    return null;
  }
}