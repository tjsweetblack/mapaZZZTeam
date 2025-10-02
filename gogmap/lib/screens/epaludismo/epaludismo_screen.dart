import 'package:flutter/material.dart';
import 'epaludismo_result_screen.dart'; // Assuming epaludismo_result_screen.dart is the file name

class EPaldudismoScreen extends StatefulWidget {
  const EPaldudismoScreen({super.key});

  @override
  State<EPaldudismoScreen> createState() => _EPaldudismoScreenState();
}

class _EPaldudismoScreenState extends State<EPaldudismoScreen> {
  final TextEditingController _symptomsController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _textFieldFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_textFieldFocus.hasFocus) {
      // Delay to allow keyboard to fully appear
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _textFieldFocus.hasFocus) {
          _scrollToButton();
        }
      });
    }
  }

  void _scrollToButton() {
    if (!mounted || !_scrollController.hasClients) return;

    // Calculate scroll position to show the button area
    final screenHeight = MediaQuery.of(context).size.height;
    final targetScrollPosition =
        screenHeight * 0.4; // Scroll to show button area

    _scrollController.animateTo(
      targetScrollPosition,
      duration: const Duration(milliseconds: 500), // Longer duration
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _scrollController.dispose();
    _textFieldFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).viewInsets.bottom -
                kToolbarHeight -
                MediaQuery.of(context).padding.top,
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.electric_meter,
                      size: 60,
                      color: Colors.red,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                const Text(
                  'É Paludismo?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 10),

                // Subtitle/Description
                const Text(
                  'Descreva seus sintomas detalhadamente para que nossa IA possa avaliar a probabilidade de malária.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 30),

                // Text Input Field
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: _symptomsController,
                      focusNode: _textFieldFocus,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Descrição',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Button
                ElevatedButton(
                  onPressed: () {
                    final String symptoms = _symptomsController.text;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MalariaResultScreen(
                              symptomsDescription: symptoms)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text(
                    'Iniciar avaliação',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),

                // AI Powered Text
                const Text(
                  'AI Powered',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
