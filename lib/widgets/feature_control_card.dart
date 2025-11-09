import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/security_service.dart';

class FeatureControlCard extends StatefulWidget {
  final String title;
  final double value;
  final Function(double) onChanged;
  final IconData icon;

  const FeatureControlCard({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  State<FeatureControlCard> createState() => _FeatureControlCardState();
}

class _FeatureControlCardState extends State<FeatureControlCard> {
  final SecurityService _securityService = SecurityService();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      height: 140,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D131C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF27323A),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
          // Título y texto descriptivo agrupados
          Column(
            children: [
              // Título en la parte superior
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Texto descriptivo en el medio
              Text(
                l10n.translate('security.sensitivity.description'),
                style: const TextStyle(
                  color: Color(0xFF8FA39A),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Botones de sensibilidad en la parte inferior
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón Baja
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                    onTap: () {
                      widget.onChanged(0.0);
                      _securityService.setSensitivityLevel("BAJA");
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.value == 0.0 ? const Color(0xFFa3b5e0) : const Color(0xFF121827),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.value == 0.0 ? const Color(0xFF9BE7C9) : const Color(0xFF27323A),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          l10n.translate('security.sensitivity.low'),
                          style: TextStyle(
                            color: widget.value == 0.0 ? const Color(0xFF061B17) : const Color(0xFF9BE7C8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),
                ),
                // Botón Media
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                    onTap: () {
                      widget.onChanged(0.5);
                      _securityService.setSensitivityLevel("NORMAL");
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.value == 0.5 ? const Color(0xFFa3b5e0) : const Color(0xFF121827),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.value == 0.5 ? const Color(0xFF9BE7C9) : const Color(0xFF27323A),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          l10n.translate('security.sensitivity.normal'),
                          style: TextStyle(
                            color: widget.value == 0.5 ? const Color(0xFF061B17) : const Color(0xFF9BE7C8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),
                ),
                // Botón Alta
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                    onTap: () {
                      widget.onChanged(1.0);
                      _securityService.setSensitivityLevel("ALTA");
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.value == 1.0 ? const Color(0xFFa3b5e0) : const Color(0xFF121827),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.value == 1.0 ? const Color(0xFF9BE7C9) : const Color(0xFF27323A),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          l10n.translate('security.sensitivity.high'),
                          style: TextStyle(
                            color: widget.value == 1.0 ? const Color(0xFF061B17) : const Color(0xFF9BE7C8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
