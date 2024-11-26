import 'package:flutter/material.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  final String title = "Home Page";

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State Variables
  String? selectedShareOption; // Paylaşım seçimi için
  List<String> options = []; // Seçenekler için

  //Going Profile Page Function
  Future<void> _goProfile() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
      ),
    );
  }

  //Adding Decision Function
  void addDecision() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        // Controller for adding a new option
        final TextEditingController optionController = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "New Decision",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Decision Title Input
                    const TextField(
                      decoration: InputDecoration(
                        labelText: "Decision Title",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Decision Details Input
                    const TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "Details",
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Sharing Options
                    const Text(
                      "Share With",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Friends"),
                            value: "friends",
                            groupValue: selectedShareOption,
                            onChanged: (value) {
                              setModalState(() {
                                selectedShareOption = value;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Nearby"),
                            value: "nearby",
                            groupValue: selectedShareOption,
                            onChanged: (value) {
                              setModalState(() {
                                selectedShareOption = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Options Section
                    const Text(
                      "Options",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Column(
                      children: [
                        for (int i = 0; i < options.length; i++)
                          ListTile(
                            title: Text(options[i]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setModalState(() {
                                  options.removeAt(i); // Remove option
                                });
                              },
                            ),
                          ),
                        TextField(
                          controller: optionController,
                          decoration: const InputDecoration(
                            labelText: "Add an option",
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              setModalState(() {
                                options.add(value); // Add option
                                optionController.clear();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (optionController.text.isNotEmpty) {
                              setModalState(() {
                                options.add(optionController.text);
                                optionController.clear();
                              });
                            }
                          },
                          child: const Text("Add Option",),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Confirm Button
                    ElevatedButton(
                      onPressed: () {
                        // Save decision logic goes here
                        Navigator.pop(context); // Close bottom sheet
                        saveDecision();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Save Decision",
                        style: TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void saveDecision(){

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            onPressed: _goProfile,
            icon: const Icon(Icons.person,size: 35,),
            tooltip: 'Profile Icon',
          )
        ],
      ),
      body: Stack(
        children: [
          // Bottom left floating button
          Positioned(
            bottom: 20, // Adjust distance from the bottom
            left: 20, // Adjust distance from the left
            child: ElevatedButton(
              onPressed: () => addDecision(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(10),
              ),
              child: const Icon(
                Icons.add,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
