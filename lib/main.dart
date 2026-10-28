import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'viewModel/visitor_view_model/visitor_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [

        ChangeNotifierProvider(
          create: (_) => VisitorViewModel()..fetchVisitors(),
        ),
      ],
      child: const App(),
    ),
  );
}
