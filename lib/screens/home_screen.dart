import 'package:flutter/material.dart';

class Topic {
  final String topic;
  final String subtopic;
  final int count;
  final String category;

  Topic({
    required this.topic,
    required this.subtopic,
    required this.count,
    required this.category,
  });
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Topic>> _allTopicsFuture;
  List<Topic> _displayedTopics = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "All";

  // Selection state
  Set<Topic> _selectedTopics = {};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _allTopicsFuture = _fetchTopicsFromDatabase();
    _allTopicsFuture.then((topics) {
      setState(() {
        _displayedTopics = _filterAndSortTopics(topics);
      });
    });

    _searchController.addListener(() {
      _allTopicsFuture.then((topics) {
        setState(() {
          _displayedTopics = _filterAndSortTopics(topics);
        });
      });
    });
  }

  Future<List<Topic>> _fetchTopicsFromDatabase() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Topic(topic: "Math", subtopic: "Algebra", count: 12, category: "Science"),
      Topic(
        topic: "Physics",
        subtopic: "Mechanics",
        count: 8,
        category: "Science",
      ),
      Topic(
        topic: "Chemistry",
        subtopic: "Organic",
        count: 5,
        category: "Science",
      ),
      Topic(
        topic: "Biology",
        subtopic: "Genetics",
        count: 7,
        category: "Science",
      ),
      Topic(topic: "History", subtopic: "Medieval", count: 3, category: "Arts"),
      Topic(topic: "Art", subtopic: "Painting", count: 6, category: "Arts"),
    ];
  }

  List<Topic> _filterAndSortTopics(List<Topic> topics) {
    final filteredByCategory = _selectedCategory == "All"
        ? topics
        : topics.where((t) => t.category == _selectedCategory).toList();

    final filteredBySearch = filteredByCategory
        .where(
          (t) =>
              t.topic.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ||
              t.subtopic.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ),
        )
        .toList();

    filteredBySearch.sort((a, b) => a.count.compareTo(b.count));

    return filteredBySearch;
  }

  void _deleteSelectedTopics() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete ${_selectedTopics.length} topic(s)?"),
        content: Text("Are you sure you want to delete the selected topics?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _displayedTopics.removeWhere((t) => _selectedTopics.contains(t));
        _selectedTopics.clear();
        _selectionMode = false;
      });
    }
  }

  void _confirmSelection() {
    // Example action
    print("Confirmed ${_selectedTopics.length} topics");
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text("Topics List")),
      body: Column(
        children: [
          // Toolbar row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: <String>['All', 'Science', 'Arts']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                        _allTopicsFuture.then((topics) {
                          _displayedTopics = _filterAndSortTopics(topics);
                        });
                      });
                    }
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: screenWidth * 0.5,
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search...",
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: FutureBuilder<List<Topic>>(
              future: _allTopicsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error loading topics"));
                } else {
                  if (_displayedTopics.isEmpty) {
                    return const Center(child: Text("No topics found"));
                  }
                  return ListView.separated(
                    itemCount: _displayedTopics.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.grey.shade300, height: 1),
                    itemBuilder: (context, index) {
                      final topic = _displayedTopics[index];
                      final isSelected = _selectedTopics.contains(topic);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          topic.topic,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          topic.subtopic,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Checkbox(
                              value: isSelected,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (checked) {
                                setState(() {
                                  _selectionMode = true;
                                  if (checked == true) {
                                    _selectedTopics.add(topic);
                                  } else {
                                    _selectedTopics.remove(topic);
                                    if (_selectedTopics.isEmpty) {
                                      _selectionMode = false;
                                    }
                                  }
                                });
                              },
                            ),
                            Text(
                              "You have ${topic.count} remaining",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (_selectionMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedTopics.remove(topic);
                                if (_selectedTopics.isEmpty) {
                                  _selectionMode = false;
                                }
                              } else {
                                _selectedTopics.add(topic);
                              }
                            });
                          } else {
                            // Normal tap behavior
                            print("Opening ${topic.topic}");
                          }
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Delete FAB first
          if (_selectionMode && _selectedTopics.isNotEmpty)
            FloatingActionButton(
              onPressed: _deleteSelectedTopics,
              backgroundColor: Color.fromRGBO(228, 0, 80, 1),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
          const SizedBox(height: 12),
          // Confirm FAB below
          FloatingActionButton(
            onPressed: _selectedTopics.isNotEmpty ? _confirmSelection : null,
            backgroundColor: _selectedTopics.isNotEmpty
                ? Color.fromRGBO(112, 176, 228, 1)
                : Colors.grey.shade400,
            child: const Icon(Icons.check, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
