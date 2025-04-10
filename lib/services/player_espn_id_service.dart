// lib/services/player_espn_id_service.dart
import 'package:flutter/foundation.dart';

class PlayerESPNIdService {
  // Map of player names to ESPN IDs
  static final Map<String, String> _playerESPNIds = {
    // Example mappings - you would expand this
    "Tyleik Williams": "4431615",
    "Travis Hunter": "4685720",
    "Abdul Carter": "4685721",
    "Mason Graham": "4685722",
    "Ashton Jeanty": "4685723",
    "Cameron Ward": "4685724",
    "Will Campbell": "4685725",
    "Armand Membou": "4685726",
    "Jalon Walker": "4685727",
    "Tetairoa McMillan": "4685728",
    "Tyler Warren": "4685729",
    "Will Johnson": "4685730",
    "Kelvin Banks Jr": "4685731",
    "Colston Loveland": "4685732",
    "Shedeur Sanders": "4685733",
    "Jahdae Barron": "4685734",
    "Mykel Williams": "4685735",
    "Shemar Stewart": "4685736",
    "Jihaad Campbell": "4685737",
    "Matthew Golden": "4685738",
    "Mike Green": "4685739",
    "James Pearce Jr": "4685740",
    "Nick Emmanwori": "4685741",
    "Josh Simmons": "4685742",
    "Malaki Starks": "4685743",
    "Kenneth Grant": "4685744",
    "Derrick Harmon": "4685745",
    "Walter Nolen": "4685746",
    "Omarion Hampton": "4685747",
    "Tyler Booker": "4685748",
    "Emeka Egbuka": "4685749",
    "Luther Burden III": "4685750",
    "Donovan Ezeiruaku": "4685751",
    "Grey Zabel": "4685752",
    "Josh Conerly Jr": "4685753",
    "Jaxson Dart": "4685754",
    "Shavon Revel Jr": "4685755",
    "Maxwell Hairston": "4685756",
    "Trey Amos": "4685757",
    "Nic Scourton": "4685758",
    "Azareye'h Thomas": "4685759",
    "Donovan Jackson": "4685760",
    "Aireontae Ersery": "4685761",
    "Benjamin Morrison": "4685762",
    "Jayden Higgins": "4685763",
    "Tyleik Williams": "4431615",
    "TreVeyon Henderson": "4685764",
    "Landon Jackson": "4685765",
    "TJ Sanders": "4685766",
    "Mason Taylor": "4685767",
    "Carson Schwesinger": "4685768",
    "Jack Sawyer": "4685769",
    "JT Tuimoloau": "4685770",
    "Darius Alexander": "4685771",
    "Jonah Savaiinaea": "4685772",
    "Alfred Collins": "4685773",
    "Elijah Arroyo": "4685774",
    "Quinshon Judkins": "4685775",
    "Xavier Watts": "4685776",
    "Kaleb Johnson": "4685777",
    "Princely Umanmielen": "4685778",
    "Marcus Mbow": "4685779",
    "Omarr Norman-Lott": "4685780",
    "Darien Porter": "4685781",
    "Tre Harris": "4685782",
    "Wyatt Milum": "4685783",
    "Jaylin Noel": "4685784",
    "Jack Bech": "4685785",
    "Jalen Royals": "4685786",
    "Cameron Williams": "4685787",
    "Demetrius Knight": "4685788",
    "Jordan Burch": "4685789",
    "Josaiah Stewart": "4685790",
    "Cameron Skattebo": "4685791",
    "Jalen Milroe": "4685792",
    "Isaiah Bond": "4685793",
    "Elic Ayomanor": "4685794",
    "Joshua Farmer": "4685795",
    "Harold Fannin Jr": "4685796",
    "Deone Walker": "4685797",
    "Ozzy Trapilo": "4685798",
    "Bradyn Swinson": "4685799",
    "Jared Wilson": "4685800",
    "Shemar Turner": "4685801",
    "Kevin Winston Jr": "4685802",
    "Jared Ivey": "4685803",
    "Tate Ratledge": "4685804",
    "Charles Grant": "4685805",
    "Dylan Sampson": "4685806",
    "Ashton Gillotte": "4685807",
    "Kyle Kennard": "4685808",
    "Terrance Ferguson": "4685809",
    "Andrew Mukuba": "4685810",
    "Gunnar Helm": "4685811",
    "Tyler Shough": "4685812",
    "Oluwafemi Oladejo": "4685813",
    "Quinn Ewers": "4685814",
    "Chris Paul Jr": "4685815",
    "Anthony Belton": "4685816",
    "Will Howard": "4685817",
    "Jacob Parrish": "4685818",
    "Tai Felton": "4685819",
    "Savion Williams": "4685820",
    "Zah Frazier": "4685821",
    "Billy Bowman Jr": "4685822",
    "Danny Stutsman": "4685823",
    "Tez Johnson": "4685824",
    "Barrett Carter": "4685825",
    "Tory Horton": "4685826",
    "Kyle Williams": "4685827",
    "Denzel Burke": "4685828",
    "Emery Jones Jr": "4685829",
    "Saivion Jones": "4685830",
    "Jonas Sanker": "4685831",
    "Miles Frazier": "4685832",
    "Lathan Ransom": "4685833",
    "Kyle McCord": "4685834",
    "Ty Robinson": "4685835",
    "Logan Brown": "4685836",
    "Bhayshul Tuten": "4685837",
    "CJ West": "4685838",
    "David Walker": "4685839",
    "Aeneas Peebles": "4685840",
    "Xavier Restrepo": "4685841",
    "Zy Alexander": "4685842",
    "RJ Harvey Jr": "4685843",
    "Jalen Travis": "4685844",
    "Quincy Riley": "4685845",
    "Nohl Williams": "4685846",
    "Dylan Fairchild": "4685847",
    "DJ Giddens": "4685848",
    "Vernon Broughton": "4685849",
    "Smael Mondon Jr": "4685850",
    "Tyler Baron": "4685851",
    "Jordan Phillips": "4685852",
    "Dorian Strong": "4685853",
    "Jalen Rivers": "4685854",
    "Damien Martinez": "4685855",
    "Devin Neal": "4685856",
    "Jaylin Lane": "4685857",
    "Jordan James": "4685858",
    "Kobe King": "4685859",
    "JJ Pegues": "4685860",
    "Jeffrey Bassa": "4685861",
    "Ollie Gordon II": "4685862",
    "Elijah Roberts": "4685863",
    "Brashard Smith": "4685864",
    "Dillon Gabriel": "4685865",
    "Barryn Sorrell": "4685866",
    "Jamaree Caldwell": "4685867",
    "Dont'e Thornton": "4685868",
    "Jaylen Reed": "4685869",
    "Jackson Slater": "4685870",
    "Sebastian Castro": "4685871",
    "Upton Stout": "4685872",
    "Ajani Cornelius": "4685873",
    "Trevor Etienne": "4685874",
    "Que Robinson": "4685875",
    "Cobee Bryant": "4685876",
    "Malachi Moore": "4685877",
    "Jaylin Smith": "4685878",
    "Pat Bryant": "4685879",
    "Antwaun Powell-Ryland": "4685880",
    "Hollin Pierce": "4685881",
    "Jarquez Hunter": "4685882",
    "Ty Hamilton": "4685883",
    "Jack Kiser": "4685884",
    "Jah Joyner": "4685885",
    "Cody Simon": "4685886",
    "Rylie Mills": "4685887",
    "Mitchell Evans": "4685888",
    "Tyrion Ingram-Dawkins": "4685889",
    "Carson Vinson": "4685890",
    "Chase Lundt": "4685891",
    "Riley Leonard": "4685892",
    "Kaimon Rucker": "4685893",
    "Chimere Dike": "4685894",
    "Caleb Rogers": "4685895",
    "Jordan Hancock": "4685896",
    "Tommi Hill": "4685897",
    "Jake Briningstool": "4685898",
    "Oronde Gadsden II": "4685899",
    "Kalel Mullings": "4685900",
    "Mello Dotson": "4685901",
    "Luke Kandra": "4685902",
    "Kobe Hudson": "4685903",
    "Caleb Ransaw": "4685904",
    "Howard Cross III": "4685905",
    "Seth McLaughlin": "4685906",
    "Jamon Dumas-Johnson": "4685907",
    "Justin Walley": "4685908",
    "Isaac TeSlaa": "4685909",
    "Clay Webb": "4685910",
    "Jackson Hawes": "4685911",
    "Kyle Monangai": "4685912",
    "Jake Majors": "4685913",
    "Bilhal Kone": "4685914",
    "Tahj Brooks": "4685915",
    "Nick Nash": "4685916",
    "Tonka Hemingway": "4685917"
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