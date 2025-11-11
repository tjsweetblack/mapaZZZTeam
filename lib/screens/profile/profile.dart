import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Explicitly import FirebaseAuth
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthdayController;

  bool _isUpdating = false;

  String? _selectedGender;
  DateTime? _selectedBirthdayDate;

  // Track if initial data has been loaded to prevent constant controller updates
  bool _initialDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _birthdayController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  // Function to handle updating ALL profile information in Firestore
  void _saveAllChanges(String userId) async {
    if (!mounted) return;

    setState(() => _isUpdating = true);
    try {
      Map<String, dynamic> updateData = {
        'phoneNumber': _phoneController.text.trim(),
      };

      // Handle Birthday: Save formatted date or delete field if "Não definido"
      if (_selectedBirthdayDate != null) {
        updateData['birthday'] =
            DateFormat('dd/MM/yyyy').format(_selectedBirthdayDate!);
      } else {
        updateData['birthday'] = FieldValue.delete();
      }

      // Handle Gender: Save selected value or delete field if "Selecione"
      if (_selectedGender != null && _selectedGender != 'Selecione') {
        updateData['gender'] = _selectedGender;
      } else {
        updateData['gender'] = FieldValue.delete();
      }

      // Perform the update with merge option to only update specified fields
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(updateData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Perfil atualizado com sucesso!',
                  style: TextStyle(color: Colors.white))),
        );
      }
    } catch (e) {
      print('Error saving profile changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text('Erro ao salvar perfil: $e',
                  style: TextStyle(color: Colors.white))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  // Function to determine rank based on points
  String _getRank(int points) {
    if (points >= 300) {
      return 'Herói da Comunidade';
    } else if (points >= 150) {
      return 'Fiscal Confiável';
    } else if (points >= 70) {
      return 'Caçador de Mosquitos';
    } else {
      return 'Novinho(a)';
    }
  }

  // Function to update the rank in Firestore if it's different
  void _updateRankInFirestore(
      String userId, String currentRank, String? existingRank) {
    if (currentRank != existingRank) {
      print(
          'Rank mismatch: App calculated "$currentRank", Firestore has "$existingRank". Updating Firestore.');
      FirebaseFirestore.instance.collection('users').doc(userId).update({
        'rank': currentRank,
      }).then((_) {
        print('Rank updated successfully in Firestore.');
      }).catchError((error) {
        print('Error updating rank in Firestore: $error');
      });
    } else {
      print('Rank matches Firestore ("$currentRank"). No update needed.');
    }
  }

  // Function to get the correct image path based on the rank
  String _getImageForRank(String rank) {
    // These asset paths should exist in your project for the images to load correctly.
    // Replace with actual asset paths if different.
    switch (rank) {
      case 'Novinho(a)':
        return 'assets/images/nv.png';
      case 'Caçador de Mosquitos':
        return 'assets/images/cm.png';
      case 'Fiscal Confiável':
        return 'assets/images/fc.png';
      case 'Herói da Comunidade':
        return 'assets/images/hc.png';
      default:
        return 'assets/images/nv.png';
    }
  }

  // Function to show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdayDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedBirthdayDate = picked;
        _birthdayController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    } else {
      // If the user cancels the picker, and a date was previously selected, clear it
      // if (_selectedBirthdayDate != null) { // Only clear if it was previously set
      //   setState(() {
      //     _selectedBirthdayDate = null;
      //     _birthdayController.text = 'Não definido';
      //   });
      // }
      // Decided against this ^ for now, better to only clear explicitly.
      // The current behavior is that if you cancel, the previous value remains.
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: const Center(
            child: Text("No user logged in", style: TextStyle(fontSize: 18))),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF5722),
              Color(0xFFFF8A65),
              Colors.white,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Meu Perfil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child:
                                CircularProgressIndicator(color: Colors.black));
                      }
                      if (snapshot.hasError) {
                        return Center(
                            child: Text('Error: ${snapshot.error}',
                                style: const TextStyle(color: Colors.black)));
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        // This is a crucial part. If the user document doesn't exist,
                        // you should create a default one to avoid "No user data found."
                        // For now, I'll keep the message, but consider creating it.
                        return const Center(
                            child: Text(
                                'No user data found. Please ensure your user document exists.',
                                style: TextStyle(color: Colors.black)));
                      }

                      var userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final points = userData['points'] as int? ?? 0;
                      final String currentRank = _getRank(points);
                      final String? existingRank = userData['rank'] as String?;

                      // Only update controllers and state when data is first loaded or significantly changes
                      if (!_initialDataLoaded) {
                        _emailController.text = userData['email'] ?? '';
                        _phoneController.text = userData['phoneNumber'] ?? '';

                        String? fetchedBirthday =
                            userData['birthday'] as String?;
                        if (fetchedBirthday != null &&
                            fetchedBirthday.isNotEmpty) {
                          _birthdayController.text = fetchedBirthday;
                          try {
                            _selectedBirthdayDate =
                                DateFormat('dd/MM/yyyy').parse(fetchedBirthday);
                          } catch (e) {
                            _selectedBirthdayDate = null;
                          }
                        } else {
                          _birthdayController.text = 'Não definido';
                          _selectedBirthdayDate = null;
                        }

                        String? fetchedGender = userData['gender'] as String?;
                        _selectedGender =
                            fetchedGender != null && fetchedGender.isNotEmpty
                                ? fetchedGender
                                : 'Selecione';

                        _initialDataLoaded = true; // Mark as loaded
                      }

                      // Update rank in Firestore only if there's a discrepancy
                      // This should ideally happen only once when the data stabilizes
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _updateRankInFirestore(
                            user.uid, currentRank, existingRank);
                      });

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            // Profile Header Card
                            Container(
                              margin: const EdgeInsets.all(16.0),
                              padding: const EdgeInsets.all(24.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Profile Avatar with enhanced styling
                                  Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.red.shade400,
                                              Colors.red.shade600
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.red.withOpacity(0.3),
                                              blurRadius: 15,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 60,
                                          backgroundImage: AssetImage(
                                            _getImageForRank(currentRank),
                                          ),
                                          backgroundColor: Colors.transparent,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.amber,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 3),
                                          ),
                                          child: const Icon(
                                            Icons.emoji_events,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // User Name
                                  Text(
                                    userData['name'] ?? 'Elisandro Franco',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Rank and Points Row
                                  Row(
                                    children: [
                                      // Rank Card
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.amber.shade100,
                                                Colors.amber.shade50
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            border: Border.all(
                                                color: Colors.amber.shade200),
                                          ),
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.emoji_events,
                                                color: Colors.amber,
                                                size: 28,
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Meu Rank',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                currentRank,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Points Card
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.red.shade50,
                                                Colors.red.shade100
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            border: Border.all(
                                                color: Colors.red.shade100),
                                          ),
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Colors.red,
                                                size: 28,
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Meus Pontos',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                points.toString(),
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Profile Form Card
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              padding: const EdgeInsets.all(24.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Section Title
                                  const Text(
                                    'Informações Pessoais',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // E-mail Field (Read-only)
                                  _buildTextField(
                                    "E-mail",
                                    _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    readOnly: true,
                                    leadingIcon: Icons.email_outlined,
                                  ),
                                  const SizedBox(height: 20),

                                  // Telefone Field (Editable)
                                  _buildTextField(
                                    "Telefone",
                                    _phoneController,
                                    keyboardType: TextInputType.phone,
                                    prefixText: '(+244) ',
                                    readOnly: false,
                                    leadingIcon: Icons.phone_outlined,
                                  ),
                                  const SizedBox(height: 20),

                                  // Gênero Dropdown
                                  _buildDropdown(
                                    "Gênero",
                                    const [
                                      'Selecione',
                                      'Masculino',
                                      'Feminino',
                                      'Outro'
                                    ],
                                    initialValue: _selectedGender,
                                    onChanged: (newValue) {
                                      setState(() {
                                        _selectedGender = newValue;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Data de nascimento (Date Picker Field)
                                  _buildTextField(
                                    "Data de nascimento",
                                    _birthdayController,
                                    readOnly: true,
                                    leadingIcon: Icons.calendar_today_outlined,
                                    onTap: () => _selectDate(context),
                                  ),

                                  const SizedBox(height: 32),

                                  // Salvar alterações Button
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.red.shade400,
                                          Colors.red.shade600
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isUpdating
                                          ? null
                                          : () => _saveAllChanges(user.uid),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 18),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                      ),
                                      child: _isUpdating
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Salvar alterações',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Privacy Policy Link
                                  InkWell(
                                    onTap: () async {
                                      final Uri url = Uri.parse('https://ma-pa-zzz.tech/privacy-policy');
                                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                        debugPrint('Could not launch $url');
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16.0),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.privacy_tip_outlined,
                                            color: Colors.grey.shade700,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Política de Privacidade',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.open_in_new,
                                            color: Colors.grey.shade600,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for TextFormFields
  Widget _buildTextField(String labelText, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      String? prefixText,
      IconData? leadingIcon,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          prefixText: prefixText,
          prefixIcon: leadingIcon != null
              ? Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child:
                      Icon(leadingIcon, color: Colors.red.shade400, size: 20),
                )
              : null,
          prefixStyle: const TextStyle(color: Colors.black87),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade300, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  // Helper widget for DropdownButtonFormField
  Widget _buildDropdown(String labelText, List<String> items,
      {String? initialValue, ValueChanged<String?>? onChanged}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: initialValue != null && items.contains(initialValue)
            ? initialValue
            : items.first,
        hint: Text(labelText, style: TextStyle(color: Colors.grey.shade600)),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: const TextStyle(color: Colors.black87)),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                Icon(Icons.male_outlined, color: Colors.red.shade400, size: 20),
          ),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
        iconSize: 24,
      ),
    );
  }
}
