import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Explicitly import FirebaseAuth
import 'package:intl/intl.dart'; // For date formatting

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('', style: TextStyle(color: Colors.black)),
        centerTitle: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.black));
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

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          final points = userData['points'] as int? ?? 0;
          final String currentRank = _getRank(points);
          final String? existingRank = userData['rank'] as String?;

          // Only update controllers and state when data is first loaded or significantly changes
          if (!_initialDataLoaded) {
            _emailController.text = userData['email'] ?? '';
            _phoneController.text = userData['phoneNumber'] ?? '';

            String? fetchedBirthday = userData['birthday'] as String?;
            if (fetchedBirthday != null && fetchedBirthday.isNotEmpty) {
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
            _selectedGender = fetchedGender != null && fetchedGender.isNotEmpty
                ? fetchedGender
                : 'Selecione';

            _initialDataLoaded = true; // Mark as loaded
          }

          // Update rank in Firestore only if there's a discrepancy
          // This should ideally happen only once when the data stabilizes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateRankInFirestore(user.uid, currentRank, existingRank);
          });

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.red, width: 4), // Red border
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundImage: AssetImage(
                          _getImageForRank(currentRank),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      userData['name'] ?? 'Elisandro Franco',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // "Meu Rank" title
                  Center(
                    child: Text(
                      'Meu Rank',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rank icon + rank name
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events,
                            color: Colors.amber, size: 22), // Rank icon
                        const SizedBox(width: 6),
                        Text(
                          currentRank,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // "Meus Pontos" title
                  Center(
                    child: Text(
                      'Meus Pontos',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Star icon + points
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            color: Colors.amber, size: 22), // Star icon
                        const SizedBox(width: 6),
                        Text(
                          points.toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // E-mail Field (Read-only)
                  _buildTextField(
                    "E-mail",
                    _emailController,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true,
                    leadingIcon: Icons.email_outlined, // Email icon
                  ),
                  const SizedBox(height: 20),

                  // Telefone Field (Editable)
                  _buildTextField(
                    "Telefone",
                    _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixText: '(+244) ',
                    readOnly: false,
                    leadingIcon: Icons.phone_outlined, // Phone icon
                  ),
                  const SizedBox(height: 20),

                  // Gênero Dropdown
                  _buildDropdown(
                    "Gênero",
                    const ['Selecione', 'Masculino', 'Feminino', 'Outro'],
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
                    readOnly:
                        true, // Make it read-only so user taps to open picker
                    leadingIcon: Icons.calendar_today_outlined, // Calendar icon
                    onTap: () =>
                        _selectDate(context), // Open date picker on tap
                  ),

                  const SizedBox(height: 40),

                  // Salvar alterações Button
                  ElevatedButton(
                    onPressed: _isUpdating
                        ? null
                        : () => _saveAllChanges(
                            user.uid), // Call the consolidated save function
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10.0), // More rounded
                      ),
                    ),
                    child: _isUpdating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Salvar alterações',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper widget for TextFormFields
  Widget _buildTextField(String labelText, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      String? prefixText,
      IconData? leadingIcon, // Added leadingIcon parameter
      bool readOnly = false,
      VoidCallback? onTap // Added onTap for date picker
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      readOnly: readOnly,
      onTap: onTap, // Assign the onTap callback
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.black87),
        prefixText: prefixText,
        prefixIcon: leadingIcon != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Icon(leadingIcon, color: Colors.black54),
              )
            : null, // Use prefixIcon for leading icon
        prefixIconConstraints:
            BoxConstraints.tight(const Size(48, 24)), // Adjust icon spacing
        prefixStyle: const TextStyle(color: Colors.black),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black38),
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black38),
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12), // Adjust padding
      ),
    );
  }

  // Helper widget for DropdownButtonFormField
  Widget _buildDropdown(String labelText, List<String> items,
      {String? initialValue, ValueChanged<String?>? onChanged}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black38),
        borderRadius: BorderRadius.circular(10), // Rounded corners
        color: Colors.white,
      ),
      child: DropdownButtonFormField<String>(
        value: initialValue != null && items.contains(initialValue)
            ? initialValue
            : items
                .first, // Set initial value, default to first item if not found
        hint: Text(labelText, style: const TextStyle(color: Colors.black87)),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: const TextStyle(color: Colors.black)),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          border: InputBorder.none, // Remove default underline
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12), // Adjust padding
          icon: const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child:
                Icon(Icons.male_outlined, color: Colors.black54), // Gender icon
          ),
        ),
        icon: const Icon(Icons.arrow_drop_down,
            color: Colors.black87), // Default dropdown arrow
        iconDisabledColor: Colors.black38,
      ),
    );
  }
}
