/// Parsed result of Stockfish UCI info lines.
class UciInfo {
  final int depth;
  final int? score;       // centipawns (from engine's perspective)
  final int? mate;        // mate in N (signed)
  final int multiPv;
  final List<String> pv;  // principal variation (UCI moves)
  final int? nodes;
  final int? nps;
  final bool isLowerbound;
  final bool isUpperbound;

  const UciInfo({
    required this.depth,
    this.score,
    this.mate,
    this.multiPv = 1,
    this.pv = const [],
    this.nodes,
    this.nps,
    this.isLowerbound = false,
    this.isUpperbound = false,
  });

  bool get isBound => isLowerbound || isUpperbound;
}

/// Parses raw UCI output lines from Stockfish.
class UciParser {
  UciParser._();

  /// Parse a single `info` line. Returns null if it isn't an info line or contains no search info.
  /// Never throws.
  static UciInfo? parseInfoLine(String line) {
    try {
      final trimmed = line.trim();
      if (!trimmed.startsWith('info ')) return null;

      final tokens = trimmed.split(RegExp(r'\s+'));
      if (tokens.length < 2) return null;

      // Handle "info string ..." lines gracefully
      if (tokens.length >= 2 && tokens[1] == 'string') {
        return null;
      }

      int depth = 0;
      int? scoreCp;
      int? scoreMate;
      int multiPv = 1;
      List<String> pv = [];
      int? nodes;
      int? nps;
      bool isLowerbound = false;
      bool isUpperbound = false;

      for (int i = 1; i < tokens.length; i++) {
        final token = tokens[i];
        switch (token) {
          case 'depth':
            if (i + 1 < tokens.length) {
              depth = int.tryParse(tokens[++i]) ?? depth;
            }
            break;
          case 'multipv':
            if (i + 1 < tokens.length) {
              multiPv = int.tryParse(tokens[++i]) ?? multiPv;
            }
            break;
          case 'score':
            if (i + 1 < tokens.length) {
              final type = tokens[++i];
              if (type == 'cp' && i + 1 < tokens.length) {
                scoreCp = int.tryParse(tokens[++i]);
              } else if (type == 'mate' && i + 1 < tokens.length) {
                scoreMate = int.tryParse(tokens[++i]);
              }
            }
            break;
          case 'lowerbound':
            isLowerbound = true;
            break;
          case 'upperbound':
            isUpperbound = true;
            break;
          case 'nodes':
            if (i + 1 < tokens.length) {
              nodes = int.tryParse(tokens[++i]);
            }
            break;
          case 'nps':
            if (i + 1 < tokens.length) {
              nps = int.tryParse(tokens[++i]);
            }
            break;
          case 'pv':
            if (i + 1 < tokens.length) {
              pv = tokens.sublist(i + 1);
            }
            i = tokens.length; // consume the rest as PV moves
            break;
          default:
            // Ignore unrecognized UCI tokens (e.g. hashfull, tbhits, time, seldepth)
            break;
        }
      }

      // Skip lines without useful depth, score, or mate data
      if (depth == 0 && scoreCp == null && scoreMate == null) return null;

      return UciInfo(
        depth: depth,
        score: scoreCp,
        mate: scoreMate,
        multiPv: multiPv,
        pv: pv,
        nodes: nodes,
        nps: nps,
        isLowerbound: isLowerbound,
        isUpperbound: isUpperbound,
      );
    } catch (_) {
      return null;
    }
  }

  /// Parse a `bestmove` line. Returns the best move UCI string, or null.
  /// Never throws.
  static String? parseBestMove(String line) {
    try {
      final trimmed = line.trim();
      if (!trimmed.startsWith('bestmove')) return null;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[1] != '(none)') {
        return parts[1];
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
