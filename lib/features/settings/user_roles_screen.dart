import 'package:flutter/material.dart';
import '../../../../core/storage/db_helper.dart';
import '../../core/constants/app_colors.dart';
import 'add_role_screen.dart';

class UserRolesScreen extends StatefulWidget {
  const UserRolesScreen({super.key});

  @override
  State<UserRolesScreen> createState() => _UserRolesScreenState();
}

class _UserRolesScreenState extends State<UserRolesScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await DBHelper.getAllUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  // Returns UI details based on role name
  Map<String, dynamic> _getRoleStyling(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return {
          'icon': Icons.business_center_outlined,
          'color': Colors.blue,
          'desc': 'Full access to all features',
        };
      case 'manager':
        return {
          'icon': Icons.manage_accounts_outlined,
          'color': Colors.orange,
          'desc': 'Manage sales and reports',
        };
      case 'cashier':
        return {
          'icon': Icons.point_of_sale_outlined,
          'color': Colors.amber,
          'desc': 'Only billing access',
        };
      case 'salesperson':
        return {
          'icon': Icons.person_outline,
          'color': Colors.deepOrange,
          'desc': 'Billing and customers',
        };
      default:
        return {
          'icon': Icons.badge_outlined,
          'color': Colors.grey,
          'desc': 'Custom permissions',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary ?? Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "User Roles & Permissions",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      "Roles",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        ..._users.asMap().entries.map((entry) {
                          int index = entry.key;
                          var user = entry.value;
                          var style = _getRoleStyling(user['role']);

                          return Column(
                            children: [
                              _buildRoleItem(
                                icon: style['icon'],
                                iconColor: style['color'],
                                title:
                                    user['role'], // Or user['name'] if you prefer
                                subtitle: style['desc'],
                              ),
                              if (index < _users.length - 1)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  indent: 60,
                                  color: Colors.grey.shade100,
                                ),
                            ],
                          );
                        }),

                        const Divider(height: 1, thickness: 1),

                        // ADD ROLE BUTTON
                        InkWell(
                          onTap: () async {
                            final added = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddRoleScreen(),
                              ),
                            );
                            if (added == true)
                              _loadUsers(); // Refresh list if new role added
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  "Add Role",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Permissions Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _buildRoleItem(
                      icon: Icons.security,
                      iconColor: Colors.indigo,
                      title: "Permissions",
                      subtitle: "Manage what each role can access",
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRoleItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
