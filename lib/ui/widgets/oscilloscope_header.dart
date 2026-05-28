import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OscilloscopeHeader extends StatelessWidget {
  const OscilloscopeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        Text(
          'SCROLLING OSCILLOSCOPE',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.grey[400],
          ),
        ),
        Text(
          'TIME DOMAIN HISTORY',
          style: GoogleFonts.orbitron(
            fontSize: 9,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
