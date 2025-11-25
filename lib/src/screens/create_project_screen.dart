import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:TaskVerse/generated/l10n/app_localizations.dart';
import 'dart:math';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _planController = TextEditingController();

  String? _ownerId;
  final Set<String> _memberIds = {};
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final l10n = AppLocalizations.of(context)!;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020), 
      lastDate: DateTime(2101),
      helpText: l10n.selectDate,
    );
    if (picked != null && picked != (isStartDate ? _startDate : _endDate)) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _generateProjectCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  void _showMemberSelectionDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final allUsers = await FirebaseFirestore.instance.collection('users').get();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.selectProjectMembers),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allUsers.docs.length,
                  itemBuilder: (context, index) {
                    final userDoc = allUsers.docs[index];
                    final userData = userDoc.data();
                    final displayName = userData['displayName'] ?? userData['email'] ?? userDoc.id;
                    final isSelected = _memberIds.contains(userDoc.id);

                    return CheckboxListTile(
                      title: Text(displayName),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _memberIds.add(userDoc.id);
                          } else {
                            _memberIds.remove(userDoc.id);
                          }
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text(l10n.done),
              onPressed: () {
                setState(() {}); // Re-render the main screen to show selected members
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newProject),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final projectCode = _generateProjectCode();
                await FirebaseFirestore.instance.collection('projects').add({
                  'title': _titleController.text,
                  'description': _descriptionController.text,
                  'plan': _planController.text,
                  'ownerId': _ownerId,
                  'members': _memberIds.toList(),
                  'startDate': _startDate != null ? Timestamp.fromDate(_startDate!) : null,
                  'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
                  'code': projectCode,
                  'createdAt': Timestamp.now(),
                  'createdBy': FirebaseAuth.instance.currentUser?.uid,
                });
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: l10n.projectTitle),
              validator: (value) => value!.isEmpty ? l10n.pleaseEnterProjectTitle : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: l10n.projectDescription),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _planController,
              decoration: InputDecoration(labelText: l10n.projectPlan),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('users').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return DropdownButtonFormField<String>(
                  value: _ownerId,
                  decoration: InputDecoration(labelText: l10n.projectOwner),
                  items: snapshot.data!.docs.map((doc) {
                    final userData = doc.data() as Map<String, dynamic>;
                    final displayName = userData['displayName'] ?? userData['email'] ?? doc.id;
                    return DropdownMenuItem(value: doc.id, child: Text(displayName));
                  }).toList(),
                  onChanged: (value) => setState(() => _ownerId = value),
                  validator: (value) => value == null ? l10n.pleaseSelectOwner : null,
                );
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(l10n.projectMembers),
              subtitle: Text(_memberIds.isEmpty ? l10n.noMembersSelected : l10n.membersSelected(_memberIds.length)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showMemberSelectionDialog,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(l10n.startDate),
                    subtitle: Text(_startDate == null ? l10n.selectADate : DateFormat.yMMMd().format(_startDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text(l10n.endDate),
                    subtitle: Text(_endDate == null ? l10n.selectADate : DateFormat.yMMMd().format(_endDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
