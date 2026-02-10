// lib/views/contracts_mtm_dashboard/widgets/view_side_toggle.dart
import 'package:flutter/material.dart';

import '../../../data/models/contracts_mtm/contracts_mtm_dashboard_vm.dart';

class ViewSideToggle extends StatelessWidget {
  final DashboardViewSide value;
  final ValueChanged<DashboardViewSide> onChanged;

  const ViewSideToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DashboardViewSide>(
      segments: const [
        ButtonSegment(
          value: DashboardViewSide.manual,
          label: Text('Manual'),
          icon: Icon(Icons.edit),
        ),
        ButtonSegment(
          value: DashboardViewSide.system,
          label: Text('System'),
          icon: Icon(Icons.memory),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
