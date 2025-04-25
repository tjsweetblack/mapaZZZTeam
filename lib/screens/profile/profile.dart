import 'package:auth_bloc/logic/cubit/auth_cubit.dart';
import 'package:auth_bloc/routing/routes.dart';
import 'package:auth_bloc/screens/profile/rewards.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController; // Will be removed from UI
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isUpdating = false; // State for showing loading during save
  bool _isEditingInfo = false; // State for toggling edit mode

  // State variables for dropdowns, since TextFormFields are not used for them when editing is enabled
  String? _selectedBirthday;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameController =
        TextEditingController(); // Still needed to read initial data
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Function to handle updating profile information in Firestore
  void _updateProfile(String userId) async {
    if (!mounted) return; // Check if widget is still mounted

    setState(() => _isUpdating = true);
    try {
      // Get the current values from controllers and state variables
      final String updatedFirstName = _firstNameController.text.trim();
      final String updatedLastName = _lastNameController.text.trim();
      final String updatedPhoneNumber = _phoneController.text.trim();
      // Email is read-only, username is removed from UI, birthday and gender from state

      // Prepare the data to update
      Map<String, dynamic> updateData = {
        'name': '$updatedFirstName $updatedLastName'
            .trim(), // Combine first and last name
        'phoneNumber': updatedPhoneNumber,
        // Only include birthday and gender if a value is selected
        if (_selectedBirthday != null && _selectedBirthday != 'Selecione')
          'birthday': _selectedBirthday,
        if (_selectedGender != null && _selectedGender != 'Selecione')
          'gender': _selectedGender,
        // Note: Username is removed from UI and not updated here
        // Note: Email is read-only and not updated here
      };

      // Remove fields from updateData if the corresponding UI was removed (e.g., username)
      // or if the selected value is the default 'Selecione' and you want to remove it from Firestore
      // if the field exists. This requires checking existing data or having a clear policy.
      // For simplicity here, we only add if a non-'Selecione' value is selected.

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(updateData);

      await Future.delayed(
          const Duration(milliseconds: 500)); // Simulate a small network delay

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.green, // Use green for success
              content: Text('Perfil atualizado com sucesso!',
                  style: TextStyle(color: Colors.white))),
        );
        // Exit editing mode after successful save
        setState(() {
          _isEditingInfo = false;
        });
      }
    } catch (e) {
      print('Error updating profile: $e'); // Log the error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.redAccent, // Use red for error
              content: Text('Erro ao atualizar perfil: $e',
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
      return 'Novinho'; // 0 to 69 points
    }
  }

  // Function to update the rank in Firestore if it's different
  void _updateRankInFirestore(
      String userId, String currentRank, String? existingRank) {
    // Check if the calculated rank is different from the one in the database
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

  @override
  Widget build(BuildContext context) {
    final authCubit = context.watch<AuthCubit>();
    final user = authCubit.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: const Center(
            child: Text("No user logged in", style: TextStyle(fontSize: 18))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.black), // Black back arrow
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('',
            style: TextStyle(color: Colors.black)), // Empty title
        centerTitle: false,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Colors.black)); // Black indicator
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.black))); // Black text
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
                child: Text('No user data found.',
                    style: TextStyle(color: Colors.black))); // Black text
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          final points = userData['points'] as int? ?? 0;
          final progress = points /
              300.0; // Progress towards 'Fiscal Confiável' (300 points) or adjust target if needed

          // Determine the current rank based on points
          final String currentRank = _getRank(points);
          // Get the existing rank from Firestore data
          final String? existingRank = userData['rank'] as String?;

          // --- Add the rank check and update logic here ---
          // Use addPostFrameCallback to avoid calling update during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateRankInFirestore(user.uid, currentRank, existingRank);

            // Also populate text controllers and dropdown state once after data is fetched
            if (_firstNameController.text.isEmpty && mounted) {
              _firstNameController.text =
                  userData['name']?.split(' ').first ?? '';
              _lastNameController.text =
                  userData['name']?.split(' ').last ?? '';
              _usernameController.text =
                  userData['username'] ?? ''; // Populate but hide in UI
              _emailController.text = userData['email'] ?? '';
              _phoneController.text = userData['phoneNumber'] ?? '';

              // Populate dropdown state variables
              _selectedBirthday = userData['birthday'] as String?;
              _selectedGender = userData['gender'] as String?;

              // Trigger a rebuild to show initial data in fields if not editing
              setState(() {}); // Empty setState to trigger rebuild
            }
          });
          // --- End rank check and update logic ---

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(
                            userData['photoURL'] ??
                                'https://cdn4.iconfinder.com/data/icons/glyphs/24/icons_user-512.png',
                          ),
                        ),
                        // Edit profile picture icon - consider implementing this functionality
                        // Container(
                        //   decoration: BoxDecoration(
                        //     shape: BoxShape.circle,
                        //     color: Colors.red,
                        //     border: Border.all(color: Colors.white, width: 1),
                        //   ),
                        //   padding: const EdgeInsets.all(4.0),
                        //   child: const Icon(Icons.edit,
                        //       color: Colors.white, size: 16),
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.military_tech,
                            color: Colors.black, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          currentRank, // Display the dynamic rank here
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16, // Slightly smaller font size
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: LinearProgressIndicator(
                      value: progress.clamp(
                          0.0, 1.0), // Progress value based on points
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.red),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_border,
                            color: Colors.black, size: 16),
                        const SizedBox(width: 4),
                        Text('${points} pontos', // Display actual points
                            style:
                                TextStyle(color: Colors.black, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RewardsPage()));
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.redeem, color: Colors.red, size: 16),
                          SizedBox(width: 4),
                          Text('Reivindicar prêmios',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Information Fields
                  // First Name and Last Name are always shown
                  _buildTextField("Primeiro nome", _firstNameController,
                      labelTextColor: Colors.black87,
                      readOnly: !_isEditingInfo), // Read-only when not editing
                  _buildTextField("Sobrenome", _lastNameController,
                      labelTextColor: Colors.black87,
                      readOnly: !_isEditingInfo), // Read-only when not editing

                  // Username, Birthday, and Gender are shown only when editing
                  if (_isEditingInfo) ...[
                    // Username field (now visible only in edit mode)
                    _buildTextField("Nome de usuário", _usernameController,
                        labelTextColor: Colors.black87,
                        readOnly:
                            !_isEditingInfo), // Read-only when not editing

                    // Birthday Dropdown (now visible only in edit mode)
                    _buildDropdown(
                        "Aniversário",
                        const [
                          'Selecione',
                          '01/01/1990',
                          '15/05/1995'
                        ], // Add actual items
                        labelTextColor: Colors.black87,
                        initialValue: _selectedBirthday, // Set initial value
                        onChanged: (newValue) {
                      setState(() {
                        _selectedBirthday = newValue;
                      });
                    }, enabled: _isEditingInfo // Enable only when editing
                        ),
                    // Gender Dropdown (now visible only in edit mode)
                    _buildDropdown(
                        "Gênero",
                        const [
                          'Selecione',
                          'Masculino',
                          'Feminino',
                          'Outro'
                        ], // Add actual items
                        labelTextColor: Colors.black87,
                        initialValue: _selectedGender, // Set initial value
                        onChanged: (newValue) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    }, enabled: _isEditingInfo // Enable only when editing
                        ),
                  ],

                  // Email and Phone Number are always shown
                  _buildTextField("Email", _emailController,
                      keyboardType: TextInputType.emailAddress,
                      labelTextColor: Colors.black87,
                      readOnly: true), // Email is always read-only
                  _buildTextField("Número de telefone", _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixText: '+244 ', // Corrected Angola country code
                      suffixIcon: const Icon(Icons.arrow_drop_down,
                          color: Colors.black87),
                      labelTextColor: Colors.black87,
                      readOnly: !_isEditingInfo), // Read-only when not editing

                  const SizedBox(height: 32),

                  // Toggle Edit/Save Button
                  ElevatedButton(
                    onPressed: _isUpdating
                        ? null // Disable button while updating
                        : _isEditingInfo
                            ? () => _updateProfile(user.uid) // Save Changes
                            : () {
                                // Change All Info
                                setState(() {
                                  _isEditingInfo = true;
                                });
                              },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEditingInfo
                          ? Colors.green
                          : Colors.red, // Green for Save, Red for Edit
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: _isUpdating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isEditingInfo
                                ? 'Salvar Alterações'
                                : 'Alterar Todas as Informações', // Button text changes
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16)),
                  ),

                  const SizedBox(height: 16),
                  // Logout Button (remains)
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        await authCubit.signOut();
                        if (context.mounted) {
                          // Ensure any ongoing async operations are cancelled or handled
                          // before navigating and removing routes.
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            Routes.loginScreen,
                            (route) => false,
                          );
                        }
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.black87, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String labelText, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      String? prefixText,
      Widget? suffixIcon,
      Color? labelTextColor,
      bool readOnly = false // Added readOnly parameter
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black),
        readOnly: readOnly, // Use the readOnly parameter
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: labelTextColor ?? Colors.black87),
          prefixText: prefixText,
          suffixIcon: suffixIcon,
          prefixStyle: const TextStyle(color: Colors.black),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black38),
            borderRadius: BorderRadius.circular(5), // Rounded corners
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(5), // Rounded corners
          ),
          // Add disabled border style if needed for clarity when readOnly is true
          disabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(5),
          ),
          // You might want to add filled: true, fillColor: Colors.white if the container isn't providing a white background
        ),
      ),
    );
  }

  Widget _buildDropdown(String labelText, List<String> items,
      {Color? labelTextColor,
      String? initialValue, // Added initialValue parameter
      ValueChanged<String?>? onChanged, // Added onChanged parameter
      bool enabled = true // Added enabled parameter
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: TextStyle(color: labelTextColor ?? Colors.black87),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                  color: enabled
                      ? Colors.black38
                      : Colors.grey), // Grey border when disabled
              borderRadius: BorderRadius.circular(5),
              color: Colors
                  .white, // Ensure white background for dropdown container
            ),
            child: DropdownButtonFormField<String>(
              value: initialValue, // Use the initialValue parameter
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child:
                      Text(item, style: const TextStyle(color: Colors.black)),
                );
              }).toList(),
              onChanged: enabled
                  ? onChanged
                  : null, // Use the onChanged parameter, disable when not enabled
              dropdownColor: Colors.white, // White background for dropdown menu
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                border: InputBorder.none, // Remove default underline
                isDense: true, // Make it a bit more compact vertically
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12), // Adjust padding
                suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.black87),
              ),
              iconDisabledColor:
                  Colors.grey, // Grey out dropdown icon when disabled
            ),
          ),
        ],
      ),
    );
  }
}
