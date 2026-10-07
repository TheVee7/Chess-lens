/// Parsed result of Stockfish UCI info lines.
class UciInfo {
  final int depth;
  final int? score;       // centipawns (from engine's perspective)
  final int? mate;        // mate in N (signed)
  final int multiPv;
  final List<String> pv;  // principal variation (UCI moves)
  final int? nodes;
  final int? nps;

  const UciInfo({
    required this.depth,
    this.score,
    this.mate,
    this.multiPv = 1,
    this.pv = const [],
    this.nodes,
    this.nps,
  });
}

/// Parses raw UCI output lines from Stockfish.
class UciParser {
  UciParser._();

  /// Parse a single `info` line. Returns null if it isn't an info line.
  static UciInfo? parseInfoLine(String line) {
    if (!line.startsWith('info ')) return null;

    final tokens = line.trim().split(RegExp(r'\s+'));

    int depth = 0;
    int? scoreCp;
    int? scoreMate;
    int multiPv = 1;
    List<String> pv = [];
    int? nodes;
    int? nps;

    for (int i = 1; i < tokens.length; i++) {
      switch (tokens[i]) {
        case 'depth':
          if (i + 1 < tokens.length) depth = int.tryParse(tokens[++i]) ?? 0;
          break;
        case 'multipv':
          if (i + 1 < tokens.length) multiPv = int.tryParse(tokens[++i]) ?? 1;
          break;
        case 'score':
          if (i + 1 < tokens.length) {
            i++;
            if (tokens[i] == 'cp' && i + 1 < tokens.length) {
              scoreCp = int.tryParse(tokens[++i]);
            } else if (tokens[i] == 'mate' && i + 1 < tokens.length) {
              scoreMate = int.tryParse(tokens[++i]);
            }
          }
          break;
        case 'nodes':
          if (i + 1 < tokens.length) nodes = int.tryParse(tokens[++i]);
          break;
        case 'nps':
          if (i + 1 < tokens.length) nps = int.tryParse(tokens[++i]);
          break;
        case 'pv':
          pv = tokens.sublist(i + 1);
          i = tokens.length; // consume rest
          break;
      }
    }

    // skip lines without useful data
    if (depth == 0 && scoreCp == null && scoreMate == null) return null;

    return UciInfo(
      depth: depth,
      score: scoreCp,
      mate: scoreMate,
      multiPv: multiPv,
      pv: pv,
      nodes: nodes,
      nps: nps,
    );
  }

  /// Parse a `bestmove` line. Returns the best move UCI string, or null.
  static String? parseBestMove(String line) {
    if (!line.startsWith('bestmove ')) return null;
    final parts = line.trim().split(RegExp(r'\s+'));
    return parts.length >= 2 ? parts[1] : null;
  }
}
